SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: reset_site_plan_credit_period(uuid, timestamp with time zone, timestamp with time zone, numeric, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_site_plan_credit_period(p_site_id uuid, p_period_start timestamp with time zone, p_period_end timestamp with time zone, p_allowance numeric, p_source text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; v_delta numeric;
BEGIN
  IF p_period_start IS NULL OR p_period_end IS NULL OR p_period_end <= p_period_start
    OR NOT isfinite(p_period_start) OR NOT isfinite(p_period_end)
    OR p_period_start > now() OR p_period_end <= now()
    OR p_allowance IS NULL OR p_allowance < 0 OR p_allowance::text IN ('NaN','Infinity','-Infinity')
    OR nullif(p_source,'') IS NULL THEN RAISE EXCEPTION 'Invalid current plan credit period'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'error','Billing record not found'); END IF;
  -- Legacy Stripe metadata proves the period END, not its start (month-end
  -- clamping can make end-minus-one-month inaccurate). Invoice replay of that
  -- same paid end must not refill consumed credits, even if its exact start differs.
  IF p_source LIKE 'stripe_invoice:%' AND b.plan_credit_source LIKE 'stripe%'
    AND b.plan_credit_source <> 'stripe_unverified' AND p_period_end <= b.plan_credit_period_end THEN
    RETURN jsonb_build_object('success',true,'outcome',CASE WHEN p_period_end < b.plan_credit_period_end THEN 'stale_period' ELSE 'not_due' END,
      'credits_granted',0,'credits_available',b.credits_available,'expired_credits',0);
  END IF;
  IF b.plan_credit_period_start IS NOT NULL AND p_period_start <= b.plan_credit_period_start
    AND NOT (p_source LIKE 'stripe_invoice:%' AND b.plan_credit_source IN ('signup','stripe_unverified')) THEN
    RETURN jsonb_build_object('success',true,'outcome',CASE WHEN p_period_start < b.plan_credit_period_start THEN 'stale_period' ELSE 'not_due' END,
      'credits_granted',0,'credits_available',b.credits_available,'expired_credits',0);
  END IF;
  v_delta := p_allowance - b.plan_credits_available;
  UPDATE public.billing SET plan_credits_available = p_allowance,
    credits_available = p_allowance + purchased_credits_available + legacy_credits_available,
    plan_credit_allowance = p_allowance,plan_credit_period_start = p_period_start,
    plan_credit_period_end = p_period_end,plan_credit_source = p_source,monthly_credits_used = 0,plan_credits_used = 0 WHERE id = b.id;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES (p_site_id,v_delta,'plan_credit_reset','Non-accumulating monthly plan allowance',
      jsonb_build_object('credit_bucket','plan','source',p_source,'period_start',p_period_start,
        'period_end',p_period_end,'allowance',p_allowance,'expired_credits',b.plan_credits_available));
  RETURN jsonb_build_object('success',true,'outcome','reset','credits_granted',p_allowance,
    'credits_available',p_allowance + b.purchased_credits_available + b.legacy_credits_available + b.trial_credits_available,
    'expired_credits',b.plan_credits_available);
END;
$$;


--
-- Name: reset_stuck_sending_messages(timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_stuck_sending_messages(p_cutoff timestamp with time zone, p_limit integer DEFAULT 500) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4228222($1,$2); END$_$;


--
-- Name: resolve_payout_request(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resolve_payout_request(p_payout_id uuid, p_status text, p_resolved_by uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_request public.payout_requests;
BEGIN
  IF p_status NOT IN ('completed', 'rejected') THEN
    RAISE EXCEPTION 'Invalid payout status';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.platform_user_roles pur
    WHERE pur.user_id = p_resolved_by
      AND pur.role IN ('super_admin', 'finance_admin')
  ) THEN
    RAISE EXCEPTION 'Resolver is not authorized';
  END IF;

  SELECT *
  INTO v_request
  FROM public.payout_requests
  WHERE id = p_payout_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout not found';
  END IF;
  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Payout is not pending';
  END IF;

  IF p_status = 'rejected' THEN
    PERFORM public.add_balance(
      v_request.site_id,
      v_request.requested_credits
    );
  END IF;

  UPDATE public.payout_requests
  SET status = p_status,
      resolved_at = now(),
      resolved_by = p_resolved_by
  WHERE id = p_payout_id
    AND status = 'pending'
  RETURNING * INTO v_request;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout is not pending';
  END IF;

  RETURN to_jsonb(v_request);
END;
$$;


--
-- Name: resume_instance_execution_on_user_action(uuid, uuid, boolean, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resume_instance_execution_on_user_action(p_requirement_id uuid, p_instance_id uuid, p_reopen_paused_plans boolean, p_action_id text, p_allow_terminal_reopen boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_plan record;
  v_step jsonb;
  v_item jsonb;
  v_steps jsonb;
  v_next_steps jsonb;
  v_next_items jsonb := '[]'::jsonb;
  v_failures jsonb;
  v_backlog jsonb;
  v_metadata jsonb;
  v_status text;
  v_action_uuid uuid;
  v_action_created_at timestamptz;
  v_trusted_action boolean := false;
  v_receipt_inserted integer := 0;
  v_external_revision bigint;
  v_execution_generation integer;
  v_generation integer;
  v_cleared boolean;
  v_resume boolean;
  v_plans_updated integer := 0;
  v_steps_cleared integer := 0;
  v_reopened_ids text[] := ARRAY[]::text[];
  v_now timestamptz := timezone('utc', now());
BEGIN
  IF NULLIF(btrim(p_action_id), '') IS NULL THEN
    RAISE EXCEPTION 'p_action_id is required';
  END IF;

  SELECT
    status,
    CASE WHEN jsonb_typeof(metadata) = 'object'
      THEN metadata ELSE '{}'::jsonb END,
    CASE WHEN jsonb_typeof(backlog) = 'object'
      THEN backlog ELSE '{}'::jsonb END,
    external_user_action_revision
  INTO
    v_status,
    v_metadata,
    v_backlog,
    v_external_revision
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'state', 'missing',
      'plans_updated', 0,
      'steps_cleared', 0,
      'reopened_item_ids', '[]'::jsonb,
      'external_user_action_revision', 0
    );
  END IF;
  IF v_status IN ('done', 'cancelled', 'canceled')
    AND NOT p_allow_terminal_reopen
  THEN
    RETURN jsonb_build_object(
      'state', 'guarded',
      'plans_updated', 0,
      'steps_cleared', 0,
      'reopened_item_ids', '[]'::jsonb,
      'external_user_action_revision', v_external_revision
    );
  END IF;
  SELECT log.id, log.created_at
  INTO v_action_uuid, v_action_created_at
  FROM public.instance_logs AS log
  WHERE log.id::text = p_action_id
    AND log.instance_id = p_instance_id
    AND log.log_type = 'user_action'
    AND log.trusted_user_action = true
    AND log.details->>'requirement_id' = p_requirement_id::text
  LIMIT 1;
  v_trusted_action := FOUND;
  IF NOT v_trusted_action AND NOT p_allow_terminal_reopen THEN
    RETURN jsonb_build_object(
      'state', 'untrusted',
      'plans_updated', 0,
      'steps_cleared', 0,
      'reopened_item_ids', '[]'::jsonb,
      'external_user_action_revision', v_external_revision
    );
  END IF;
  IF v_trusted_action THEN
    INSERT INTO public.requirement_user_action_receipts (
      requirement_id,
      action_id,
      action_created_at,
      revision
    ) VALUES (
      p_requirement_id,
      v_action_uuid,
      v_action_created_at,
      v_external_revision + 1
    )
    ON CONFLICT (requirement_id, action_id) DO NOTHING;
    GET DIAGNOSTICS v_receipt_inserted = ROW_COUNT;
  END IF;
  IF (v_trusted_action AND v_receipt_inserted = 0) OR (
    NOT v_trusted_action
    AND v_metadata->>'requirement_last_resume_action_id' = p_action_id
  ) THEN
    RETURN jsonb_build_object(
      'state', 'duplicate',
      'plans_updated', 0,
      'steps_cleared', 0,
      'reopened_item_ids', '[]'::jsonb,
      'external_user_action_revision', v_external_revision
    );
  END IF;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(v_backlog->'items') = 'array'
        THEN v_backlog->'items' ELSE '[]'::jsonb END
    ) WITH ORDINALITY
    ORDER BY ordinality
  LOOP
    IF v_trusted_action
      AND v_item->>'status' = 'needs_review'
      AND COALESCE(
        v_item->'review_quarantine'->>'active',
        'false'
      ) = 'true'
      AND v_action_created_at >
        public.requirement_quarantine_timestamp(v_item)
      AND COALESCE(
        NULLIF(
          v_item->'review_quarantine'->>'external_action_revision',
          ''
        )::bigint,
        v_external_revision
      ) <= v_external_revision
    THEN
      SELECT COALESCE(jsonb_object_agg(entry.key, entry.value), '{}'::jsonb)
      INTO v_failures
      FROM jsonb_each(
        CASE WHEN jsonb_typeof(v_item->'tool_failures') = 'object'
          THEN v_item->'tool_failures' ELSE '{}'::jsonb END
      ) AS entry(key, value)
      WHERE entry.key NOT LIKE 'judge\_%' ESCAPE '\';

      v_item := (
        v_item
        - 'tool_failures'
        - 'plan_cancellation_pending'
      ) || jsonb_build_object(
        'status', 'pending',
        'attempts', 0,
        'updated_at', v_now,
        'review_quarantine',
          v_item->'review_quarantine' || jsonb_build_object(
            'active', false,
            'released_at', v_now,
            'released_by_action_id', p_action_id,
            'external_action_revision', v_external_revision + 1
          )
      );
      IF v_failures <> '{}'::jsonb THEN
        v_item := v_item || jsonb_build_object(
          'tool_failures', v_failures
        );
      END IF;
      IF NOT COALESCE(v_item->'assumptions', '[]'::jsonb)
        @> jsonb_build_array(
          '[user-feedback] Reopened for mandatory execution and validation.'
        )
      THEN
        v_item := v_item || jsonb_build_object(
          'assumptions',
          COALESCE(v_item->'assumptions', '[]'::jsonb) ||
            jsonb_build_array(
              '[user-feedback] Reopened for mandatory execution and validation.'
            )
        );
      END IF;
      v_reopened_ids := array_append(v_reopened_ids, v_item->>'id');
    END IF;
    v_next_items := v_next_items || jsonb_build_array(v_item);
  END LOOP;

  v_execution_generation := CASE
    WHEN COALESCE(
      v_metadata->>'requirement_execution_generation',
      ''
    ) ~ '^[0-9]{1,9}$'
      THEN (v_metadata->>'requirement_execution_generation')::integer
    ELSE 0
  END;
  UPDATE public.requirements
  SET
    status = 'in-progress',
    backlog = CASE
      WHEN cardinality(v_reopened_ids) > 0
        THEN jsonb_set(v_backlog, '{items}', v_next_items, true)
      ELSE backlog
    END,
    backlog_revision = backlog_revision
      + CASE WHEN cardinality(v_reopened_ids) > 0 THEN 1 ELSE 0 END,
    external_user_action_revision = v_external_revision
      + CASE WHEN v_trusted_action THEN 1 ELSE 0 END,
    last_external_user_action_id = CASE
      WHEN v_trusted_action THEN p_action_id
      ELSE last_external_user_action_id
    END,
    metadata = (
      v_metadata - ARRAY[
        'cron_blocker_provenance',
        'cron_blocker_version',
        'cron_blocker_event_id',
        'cron_blocker_plan_id',
        'cron_blocker_step_id',
        'cron_blocker_generation'
      ]
    ) || jsonb_build_object(
      'cron_attempts', 0,
      'no_progress_cycles', 0,
      'cron_infrastructure_failure_cycles', 0,
      'requirement_execution_generation', v_execution_generation + 1,
      'requirement_last_resume_action_id', p_action_id,
      'requirement_last_resume_reopened_plans',
        p_reopen_paused_plans AND v_status IN ('blocked', 'on-review')
    ),
    updated_at = v_now
  WHERE id = p_requirement_id;

  FOR v_plan IN
    SELECT id, status, steps
    FROM public.instance_plans
    WHERE instance_id = p_instance_id
      AND metadata->>'requirement_id' = p_requirement_id::text
      AND (
        status IN ('pending', 'in_progress', 'active')
        OR (
          status = 'paused'
          AND p_reopen_paused_plans
          AND v_status IN ('blocked', 'on-review')
        )
      )
    ORDER BY id
    FOR UPDATE
  LOOP
    v_steps := CASE WHEN jsonb_typeof(v_plan.steps) = 'array'
      THEN v_plan.steps ELSE '[]'::jsonb END;
    v_next_steps := '[]'::jsonb;
    v_cleared := false;

    FOR v_step IN SELECT value FROM jsonb_array_elements(v_steps)
    LOOP
      IF COALESCE(v_step->>'status', 'pending')
        NOT IN ('completed', 'cancelled', 'canceled')
      THEN
        v_generation := CASE
          WHEN COALESCE(
            v_step->>'infrastructure_generation',
            ''
          ) ~ '^[0-9]{1,9}$'
            THEN (v_step->>'infrastructure_generation')::integer
          ELSE 0
        END;
        v_step := v_step || jsonb_build_object(
          'infra_retry_count', 0,
          'infra_retry_after', NULL,
          'infrastructure_error', NULL,
          'infrastructure_waiting', false,
          'infrastructure_kind', NULL,
          'infrastructure_failure_provenance', NULL,
          'infrastructure_correlation', NULL,
          'infrastructure_state', NULL,
          'infrastructure_circuit_open', false,
          'infrastructure_intervention_required', false,
          'infrastructure_product_retry_count', NULL,
          'infrastructure_generation', v_generation + 1
        );
        v_cleared := true;
        v_steps_cleared := v_steps_cleared + 1;
      END IF;
      v_next_steps := v_next_steps || jsonb_build_array(v_step);
    END LOOP;

    v_resume := v_plan.status = 'paused'
      AND p_reopen_paused_plans
      AND v_status IN ('blocked', 'on-review');
    IF v_cleared OR v_resume THEN
      UPDATE public.instance_plans
      SET
        steps = CASE WHEN v_cleared THEN v_next_steps ELSE v_steps END,
        status = CASE WHEN v_resume THEN 'in_progress' ELSE status END,
        completed_at = CASE WHEN v_resume THEN NULL ELSE completed_at END,
        updated_at = v_now
      WHERE id = v_plan.id;
      v_plans_updated := v_plans_updated + 1;
    END IF;
  END LOOP;

  UPDATE public.remote_instances
  SET status = 'running'
  WHERE id = p_instance_id
    AND status IN ('pending', 'paused');

  RETURN jsonb_build_object(
    'state', 'applied',
    'plans_updated', v_plans_updated,
    'steps_cleared', v_steps_cleared,
    'reopened_item_ids', to_jsonb(v_reopened_ids),
    'external_user_action_revision', v_external_revision + CASE WHEN v_trusted_action THEN 1 ELSE 0 END
  );
END;
$_$;

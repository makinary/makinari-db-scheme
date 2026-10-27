SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: record_embedding_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_embedding_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    site_id uuid NOT NULL,
    diagram_revision bigint NOT NULL,
    node_ids uuid[] DEFAULT '{}'::uuid[] NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    claimed_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    record_revision bigint DEFAULT 0 NOT NULL,
    CONSTRAINT record_embedding_jobs_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'processing'::text, 'completed'::text, 'failed'::text])))
);


--
-- Name: claim_record_embedding_jobs(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_record_embedding_jobs(p_record_id uuid, p_limit integer DEFAULT 5) RETURNS SETOF public.record_embedding_jobs
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  WITH candidates AS (
    SELECT j.id
    FROM public.record_embedding_jobs j
    WHERE j.record_id = p_record_id
      AND j.attempts < 5
      AND (
        j.status IN ('pending', 'failed')
        OR (
          j.status = 'processing'
          AND j.claimed_at < now() - interval '10 minutes'
        )
      )
    ORDER BY j.created_at
    FOR UPDATE SKIP LOCKED
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 5), 10))
  )
  UPDATE public.record_embedding_jobs j
  SET
    status = 'processing',
    attempts = j.attempts + 1,
    claimed_at = now(),
    last_error = NULL,
    updated_at = now()
  FROM candidates
  WHERE j.id = candidates.id
  RETURNING j.*;
END;
$$;


--
-- Name: claim_requirement_cron_candidates(integer, integer, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_requirement_cron_candidates(p_max_concurrent integer, p_ttl_seconds integer DEFAULT 7200, p_excluded_ids uuid[] DEFAULT '{}'::uuid[]) RETURNS SETOF jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_now timestamptz := now();
  v_scope_start CONSTANT timestamptz := '2026-09-01 00:00:00+00'::timestamptz;
  v_active integer;
  v_slots integer;
  v_requirement public.requirements%ROWTYPE;
  v_run_id text;
  v_expires_at timestamptz;
  v_stale_cutoff timestamptz := v_now - interval '30 minutes';
BEGIN
  IF p_max_concurrent IS NULL
    OR p_max_concurrent < 1
    OR p_max_concurrent > 100
  THEN
    RAISE EXCEPTION 'Maximum concurrent requirement runs must be between 1 and 100';
  END IF;
  IF p_ttl_seconds IS NULL
    OR p_ttl_seconds < 60
    OR p_ttl_seconds > 86400
  THEN
    RAISE EXCEPTION 'Requirement lock TTL must be between 60 and 86400 seconds';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('requirement-cron-global-capacity', 0)
  );

  -- Reclaim abandoned or frozen leases, but never evict a healthy workflow
  -- just because its creation date is outside the claim window.
  UPDATE public.requirements AS requirement
  SET
    cron_lock_expires_at = NULL,
    cron_lock_run_id = NULL,
    cron_lock_active = false,
    metadata = COALESCE(requirement.metadata, '{}'::jsonb) || jsonb_build_object(
      'requirement_execution_generation', CASE
        WHEN COALESCE(requirement.metadata->>'requirement_execution_generation', '') ~ '^[0-9]{1,9}$'
          THEN (requirement.metadata->>'requirement_execution_generation')::integer + 1
        ELSE 1 END
    )
  WHERE requirement.cron_lock_run_id IS NOT NULL
    AND (
      requirement.cron_lock_expires_at IS NULL
      OR requirement.cron_lock_expires_at <= v_now
      OR COALESCE(requirement.status, '') NOT IN ('backlog', 'in-progress')
      OR EXISTS (
        SELECT 1
        FROM public.remote_instances AS instance
        WHERE instance.id::text =
          requirement.metadata->>'runner_instance_id'
          AND instance.status = 'paused'
          AND instance.is_archived IS NOT TRUE
      )
      OR COALESCE((
        SELECT plan.status
        FROM public.instance_plans AS plan
        WHERE plan.instance_id::text =
          requirement.metadata->>'runner_instance_id'
          AND plan.status IN ('pending', 'in_progress', 'active', 'paused')
        ORDER BY plan.created_at DESC, plan.id DESC
        LIMIT 1
      ), '') = 'paused'
      OR (
        requirement.cron_lock_expires_at < v_now + pg_catalog.make_interval(
          secs => GREATEST(p_ttl_seconds - 1800, 0)
        )
        AND GREATEST(
          COALESCE(requirement.updated_at, '-infinity'::timestamptz),
          COALESCE((
            SELECT max(status.updated_at)
            FROM public.requirement_status AS status
            WHERE status.requirement_id = requirement.id
          ), '-infinity'::timestamptz),
          COALESCE((
            SELECT max(plan.updated_at)
            FROM public.instance_plans AS plan
            WHERE plan.metadata->>'requirement_id' = requirement.id::text
              OR plan.instance_id::text =
                requirement.metadata->>'runner_instance_id'
          ), '-infinity'::timestamptz)
        ) < v_stale_cutoff
      )
    );

  SELECT count(*)::integer
  INTO v_active
  FROM public.requirements
  WHERE cron_lock_expires_at > v_now
    AND cron_lock_active = true;

  v_slots := GREATEST(0, p_max_concurrent - v_active);
  IF v_slots = 0 THEN
    RETURN NEXT jsonb_build_object(
      'state', 'capacity_full',
      'active_runs', v_active
    );
    RETURN;
  END IF;

  v_expires_at := v_now + pg_catalog.make_interval(secs => p_ttl_seconds);

  FOR v_requirement IN
    SELECT requirement.*
    FROM public.requirements AS requirement
    WHERE requirement.created_at >= v_scope_start
      AND requirement.updated_at >= v_scope_start
      AND (
        requirement.status IN ('backlog', 'in-progress')
        OR (
          requirement.status = 'blocked'
          AND requirement.cron IS NOT NULL
        )
        OR (
          requirement.status IN ('on-review', 'done', 'cancelled')
          AND requirement.cron IS NOT NULL
        )
      )
      AND (
        requirement.cron_lock_expires_at IS NULL
        OR requirement.cron_lock_expires_at <= v_now
      )
      AND NOT (
        requirement.id = ANY(COALESCE(p_excluded_ids, '{}'::uuid[]))
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.remote_instances AS instance
        WHERE instance.id::text =
          requirement.metadata->>'runner_instance_id'
          AND instance.status = 'paused'
          AND instance.is_archived IS NOT TRUE
      )
      AND COALESCE((
        SELECT plan.status
        FROM public.instance_plans AS plan
        WHERE plan.instance_id::text =
          requirement.metadata->>'runner_instance_id'
          AND plan.status IN ('pending', 'in_progress', 'active', 'paused')
        ORDER BY plan.created_at DESC, plan.id DESC
        LIMIT 1
      ), '') <> 'paused'
    ORDER BY requirement.updated_at ASC NULLS FIRST, requirement.id ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED
  LOOP
    v_run_id := 'cron-' || pg_catalog.gen_random_uuid()::text;

    UPDATE public.requirements AS requirement
    SET
      cron_lock_expires_at = v_expires_at,
      cron_lock_run_id = v_run_id,
      cron_lock_active = false
    WHERE requirement.id = v_requirement.id
    RETURNING requirement.* INTO v_requirement;

    RETURN NEXT jsonb_build_object(
      'state', 'claimed',
      'requirement', to_jsonb(v_requirement),
      'run_id', v_run_id,
      'expires_at', v_expires_at
    );
  END LOOP;
END;
$_$;


--
-- Name: claim_setup_email_delivery(text, uuid, jsonb, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  r public.setup_email_delivery_receipts%ROWTYPE;
BEGIN
  IF p_operation_key IS NULL OR length(p_operation_key) NOT BETWEEN 1 AND 200
    OR p_site_id IS NULL OR p_claim_token IS NULL OR p_payload IS NULL
    OR jsonb_typeof(p_payload) <> 'object' THEN
    RAISE EXCEPTION 'Invalid setup email claim' USING ERRCODE = '22023';
  END IF;
  -- A replay returns its durable result even if configuration later changes.
  SELECT * INTO r FROM public.setup_email_delivery_receipts WHERE operation_key = p_operation_key FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NULL AND user_id IS NOT NULL;
    IF NOT FOUND THEN RETURN jsonb_build_object('outcome','site_unavailable'); END IF;
    INSERT INTO public.setup_email_delivery_receipts(operation_key,site_id,payload,claim_token)
      VALUES(p_operation_key,p_site_id,p_payload,p_claim_token)
      ON CONFLICT(operation_key) DO NOTHING RETURNING * INTO r;
    IF FOUND THEN RETURN jsonb_build_object('outcome','acquired'); END IF;
    SELECT * INTO r FROM public.setup_email_delivery_receipts WHERE operation_key = p_operation_key FOR UPDATE;
  END IF;
  IF r.site_id <> p_site_id OR r.payload <> p_payload THEN
    RETURN jsonb_build_object('outcome','conflict');
  END IF;
  RETURN jsonb_build_object('outcome',r.state,'receipt',r.receipt);
END;
$$;


--
-- Name: claim_site_subscription_checkout(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_site_subscription_checkout(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE v_token uuid := gen_random_uuid(); v_claim uuid;
BEGIN
  IF p_site_id IS NULL OR NOT EXISTS(SELECT 1 FROM public.sites WHERE id=p_site_id AND archived_at IS NULL)
  THEN RAISE EXCEPTION 'Invalid subscription checkout site'; END IF;
  INSERT INTO public.site_subscription_checkout_leases(site_id,token,lease_until)
    VALUES(p_site_id,v_token,clock_timestamp()+interval '5 minutes')
    ON CONFLICT(site_id) DO UPDATE SET token=EXCLUDED.token,lease_until=EXCLUDED.lease_until
      WHERE site_subscription_checkout_leases.lease_until <= clock_timestamp()
    RETURNING token INTO v_claim;
  IF v_claim IS NULL THEN RETURN jsonb_build_object('state','busy','token',NULL); END IF;
  RETURN jsonb_build_object('state','claimed','token',v_claim);
END;
$$;


--
-- Name: claim_stripe_sale_compensation(text, text, uuid, text, bigint, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_stripe_sale_compensation(p_session_id text, p_sale_reference text, p_order_id uuid, p_payment_intent_id text, p_amount_minor bigint, p_currency text, p_reason text, p_claim_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_effect public.stripe_sale_checkout_effects%ROWTYPE;
  v_inserted integer;
BEGIN
  INSERT INTO public.stripe_sale_checkout_effects (
    stripe_session_id, sale_reference, order_id, payment_intent_id,
    amount_minor, currency, settlement_status, rejection_reason,
    financial_status, fulfillment_status, compensation_status,
    compensation_claim_token, compensation_claimed_at
  )
  VALUES (
    p_session_id, p_sale_reference, p_order_id, p_payment_intent_id,
    p_amount_minor, lower(p_currency), 'rejected', p_reason,
    'not_required', 'not_required', 'processing', p_claim_token, now()
  )
  ON CONFLICT (stripe_session_id) DO NOTHING;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 1 THEN
    RETURN jsonb_build_object(
      'status', 'claimed',
      'claim_token', p_claim_token
    );
  END IF;

  SELECT * INTO v_effect
  FROM public.stripe_sale_checkout_effects
  WHERE stripe_session_id = p_session_id
  FOR UPDATE;

  IF v_effect.settlement_status = 'settled' THEN
    RETURN jsonb_build_object('status', 'not_allowed');
  END IF;
  IF v_effect.compensation_status = 'refunded' THEN
    RETURN jsonb_build_object(
      'status', 'refunded',
      'refund_id', v_effect.stripe_refund_id
    );
  END IF;
  IF v_effect.compensation_status = 'manual_review' THEN
    RETURN jsonb_build_object('status', 'manual_review');
  END IF;
  IF v_effect.compensation_status = 'processing'
    AND v_effect.compensation_claimed_at > now() - interval '10 minutes' THEN
    RETURN jsonb_build_object('status', 'in_progress');
  END IF;

  UPDATE public.stripe_sale_checkout_effects
  SET compensation_status = 'processing',
      compensation_claim_token = p_claim_token,
      compensation_claimed_at = now(),
      compensation_error = NULL,
      rejection_reason = p_reason,
      updated_at = now()
  WHERE stripe_session_id = p_session_id;
  RETURN jsonb_build_object(
    'status', 'claimed',
    'claim_token', p_claim_token
  );
END;
$$;


--
-- Name: claim_stripe_sale_fulfillment(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_stripe_sale_fulfillment(p_sale_id uuid, p_session_id text, p_claim_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_effect public.stripe_sale_checkout_effects%ROWTYPE;
  v_sale_status text;
  v_order_status text;
BEGIN
  SELECT * INTO v_effect
  FROM public.stripe_sale_checkout_effects
  WHERE stripe_session_id = p_session_id
  FOR UPDATE;

  IF NOT FOUND OR v_effect.settlement_status <> 'settled'
    OR v_effect.sale_id IS DISTINCT FROM p_sale_id THEN
    RAISE EXCEPTION 'Stripe fulfillment effect is not eligible';
  END IF;
  IF v_effect.fulfillment_status = 'not_required'
    OR v_effect.fulfillment_status = 'completed' THEN
    RETURN jsonb_build_object('status', v_effect.fulfillment_status);
  END IF;
  SELECT status INTO v_sale_status
  FROM public.sales
  WHERE id = p_sale_id
    AND stripe_checkout_session_id = p_session_id
  FOR UPDATE;
  IF NOT FOUND OR v_sale_status IN ('cancelled', 'refunded') THEN
    UPDATE public.stripe_sale_checkout_effects
    SET fulfillment_status = 'not_required',
        updated_at = now()
    WHERE stripe_session_id = p_session_id;
    RETURN jsonb_build_object('status', 'not_required');
  END IF;

  IF v_effect.order_id IS NOT NULL THEN
    SELECT status INTO v_order_status
    FROM public.sale_orders
    WHERE id = v_effect.order_id
      AND sale_id = p_sale_id
    FOR UPDATE;
    IF NOT FOUND OR v_order_status IN ('cancelled', 'refunded') THEN
      UPDATE public.stripe_sale_checkout_effects
      SET fulfillment_status = 'not_required',
          updated_at = now()
      WHERE stripe_session_id = p_session_id;
      RETURN jsonb_build_object('status', 'not_required');
    END IF;
  END IF;

  IF v_effect.fulfillment_status = 'processing'
    AND v_effect.fulfillment_claimed_at > now() - interval '10 minutes' THEN
    RETURN jsonb_build_object('status', 'in_progress');
  END IF;

  UPDATE public.stripe_sale_checkout_effects
  SET fulfillment_status = 'processing',
      fulfillment_claim_token = p_claim_token,
      fulfillment_claimed_at = now(),
      updated_at = now()
  WHERE stripe_session_id = p_session_id;
  RETURN jsonb_build_object(
    'status', 'claimed',
    'claim_token', p_claim_token
  );
END;
$$;

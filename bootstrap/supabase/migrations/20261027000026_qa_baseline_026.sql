SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: claim_stripe_webhook_event(text, text, jsonb, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_stripe_webhook_event(p_event_id text, p_event_type text, p_event_data jsonb, p_claim_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_event public.webhook_events%ROWTYPE;
  v_inserted integer;
  v_attempt_count integer;
BEGIN
  IF nullif(trim(p_event_id), '') IS NULL
    OR nullif(trim(p_event_type), '') IS NULL
    OR p_claim_token IS NULL THEN
    RAISE EXCEPTION 'Webhook claim parameters are required';
  END IF;

  INSERT INTO public.webhook_events (
    stripe_event_id,
    event_type,
    status,
    event_data,
    processed_at,
    error_message,
    claim_token,
    claimed_at,
    attempt_count
  )
  VALUES (
    p_event_id,
    p_event_type,
    'processing',
    coalesce(p_event_data, '{}'::jsonb)
      || jsonb_build_object('attempt_count', 1),
    NULL,
    NULL,
    p_claim_token,
    now(),
    1
  )
  ON CONFLICT (stripe_event_id) DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted = 1 THEN
    RETURN jsonb_build_object(
      'outcome', 'claimed',
      'claim_token', p_claim_token,
      'attempt_count', 1,
      'was_retry', false
    );
  END IF;

  SELECT *
  INTO v_event
  FROM public.webhook_events
  WHERE stripe_event_id = p_event_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Webhook event disappeared during claim';
  END IF;
  IF v_event.status = 'processed' THEN
    RETURN jsonb_build_object(
      'outcome', 'processed',
      'attempt_count', greatest(v_event.attempt_count, 1),
      'was_retry', true
    );
  END IF;
  IF v_event.status = 'processing'
    AND v_event.claimed_at > now() - interval '10 minutes' THEN
    RETURN jsonb_build_object(
      'outcome', 'in_progress',
      'attempt_count', greatest(v_event.attempt_count, 1),
      'was_retry', true
    );
  END IF;

  v_attempt_count := greatest(v_event.attempt_count, 0) + 1;
  UPDATE public.webhook_events
  SET event_type = p_event_type,
      status = 'processing',
      event_data = coalesce(v_event.event_data, '{}'::jsonb)
        || coalesce(p_event_data, '{}'::jsonb)
        || jsonb_build_object('attempt_count', v_attempt_count),
      processed_at = NULL,
      error_message = NULL,
      claim_token = p_claim_token,
      claimed_at = now(),
      attempt_count = v_attempt_count,
      updated_at = now()
  WHERE id = v_event.id;

  RETURN jsonb_build_object(
    'outcome', 'claimed',
    'claim_token', p_claim_token,
    'attempt_count', v_attempt_count,
    'was_retry', true
  );
END;
$$;


--
-- Name: claim_synced_objects_batch(uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_synced_objects_batch(p_site_id uuid, p_object_type text, p_objects jsonb) RETURNS TABLE(external_id text, status text, claimed_token uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
#variable_conflict use_column
DECLARE
  v_claim_token uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.synced_objects (
    external_id,
    site_id,
    object_type,
    status,
    provider,
    metadata,
    first_seen_at,
    process_count
  )
  SELECT
    item->>'external_id',
    p_site_id,
    p_object_type,
    'pending',
    NULLIF(item->>'provider', ''),
    COALESCE(item->'metadata', '{}'::jsonb),
    timezone('utc', now()),
    0
  FROM jsonb_array_elements(COALESCE(p_objects, '[]'::jsonb)) AS item
  WHERE NULLIF(item->>'external_id', '') IS NOT NULL
  ON CONFLICT (external_id, site_id, object_type) DO NOTHING;

  RETURN QUERY
  UPDATE public.synced_objects AS synced
  SET
    status = 'processing',
    claim_token = v_claim_token,
    claim_expires_at = timezone('utc', now()) + interval '15 minutes',
    updated_at = timezone('utc', now())
  WHERE synced.site_id = p_site_id
    AND synced.object_type = p_object_type
    AND synced.status IN ('pending', 'error')
    AND synced.external_id IN (
      SELECT DISTINCT item->>'external_id'
      FROM jsonb_array_elements(COALESCE(p_objects, '[]'::jsonb)) AS item
    )
  RETURNING synced.external_id, synced.status, synced.claim_token;
END;
$$;


--
-- Name: claim_workflow_run_execution(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer DEFAULT 3600) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_expires_at timestamp with time zone;
BEGIN
  IF p_claim_token IS NULL THEN
    RAISE EXCEPTION 'Claim token is required';
  END IF;
  IF p_lease_seconds IS NULL
    OR p_lease_seconds < 60
    OR p_lease_seconds > 7200
  THEN
    RAISE EXCEPTION 'Lease seconds must be between 60 and 7200';
  END IF;

  v_expires_at :=
    timezone('utc', now()) + make_interval(secs => p_lease_seconds);

  UPDATE public.workflow_runs
  SET
    status = 'in_progress',
    claim_token = p_claim_token,
    claimed_at = timezone('utc', now()),
    claim_expires_at = v_expires_at,
    completed_at = NULL,
    error_message = NULL,
    updated_at = timezone('utc', now())
  WHERE run_plan_id = p_run_plan_id
    AND (
      status = 'pending'
      OR (
        status = 'in_progress'
        AND claim_expires_at <= timezone('utc', now())
      )
    )
  RETURNING claim_expires_at INTO v_expires_at;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'busy');
  END IF;
  RETURN jsonb_build_object(
    'state', 'claimed',
    'claim_expires_at', v_expires_at
  );
END;
$$;


--
-- Name: cleanup_old_webhook_events(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_old_webhook_events(days_old integer DEFAULT 30) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_deleted_count integer;
BEGIN
  DELETE FROM public.webhook_events
  WHERE created_at < now() - make_interval(days => greatest(days_old, 1))
    AND status = 'processed';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$;


--
-- Name: clear_instance_plan_step_infrastructure_state(uuid, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clear_instance_plan_step_infrastructure_state(p_plan_id uuid, p_step_id text, p_event_id text, p_expected_generation integer DEFAULT 0) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_steps jsonb; v_step jsonb; v_step_index integer;
  v_generation integer; v_event_generation integer;
BEGIN
  SELECT CASE
    WHEN jsonb_typeof(steps) = 'array' THEN steps
    ELSE '[]'::jsonb
  END
  INTO v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'cleared', false);
  END IF;

  SELECT entry.value, (entry.ordinality - 1)::integer
  INTO v_step, v_step_index
  FROM jsonb_array_elements(v_steps)
    WITH ORDINALITY AS entry(value, ordinality)
  WHERE entry.value->>'id' = p_step_id
  LIMIT 1;
  IF v_step IS NULL THEN
    RETURN jsonb_build_object('state', 'missing', 'cleared', false);
  END IF;

  v_generation := CASE
    WHEN COALESCE(v_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  SELECT CASE
    WHEN COALESCE(details->>'generation', '') ~ '^[0-9]{1,9}$'
      THEN (details->>'generation')::integer
    ELSE 0
  END
  INTO v_event_generation
  FROM public.instance_plan_step_infrastructure_events
    WHERE plan_id = p_plan_id
      AND step_id = p_step_id
      AND event_id = p_event_id;
  IF FOUND THEN
    IF v_event_generation IS DISTINCT FROM v_generation
      OR v_event_generation::bigint IS DISTINCT FROM
        p_expected_generation::bigint + 1
    THEN
      RETURN jsonb_build_object(
        'state', 'stale', 'cleared', false, 'generation', v_generation
      );
    END IF;
    RETURN jsonb_build_object(
      'state', 'duplicate', 'cleared', true,
      'generation', v_event_generation
    );
  END IF;

  IF v_generation IS DISTINCT FROM p_expected_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'cleared', false,
      'generation', v_generation
    );
  END IF;

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
    'infrastructure_generation', v_generation + 1,
    'infrastructure_last_event_id', p_event_id
  );
  v_steps := jsonb_set(
    v_steps,
    ARRAY[v_step_index::text],
    v_step,
    false
  );

  UPDATE public.instance_plans
  SET steps = v_steps, updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  INSERT INTO public.instance_plan_step_infrastructure_events (
    plan_id,
    step_id,
    event_id,
    event_type,
    details
  )
  VALUES (
    p_plan_id,
    p_step_id,
    p_event_id,
    'success_clear',
    jsonb_build_object('generation', v_generation + 1)
  );

  RETURN jsonb_build_object(
    'state', 'applied',
    'cleared', true,
    'generation', v_generation + 1
  );
END;
$_$;


--
-- Name: commit_instance_context_memory(uuid, uuid, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, uuid, uuid[], text, public.vector); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.commit_instance_context_memory(p_instance_id uuid, p_site_id uuid, p_expected_cursor timestamp with time zone, p_expected_log_id uuid, p_start_at timestamp with time zone, p_end_at timestamp with time zone, p_end_log_id uuid, p_log_ids uuid[], p_summary text, p_embedding public.vector) RETURNS boolean
    LANGUAGE plpgsql
    SET search_path TO 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE v_cursor timestamptz; v_log_id uuid; v_actual_ids uuid[];
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.remote_instances WHERE id = p_instance_id AND site_id = p_site_id)
    OR p_end_at < p_start_at OR length(trim(p_summary)) = 0
    OR coalesce(array_length(p_log_ids, 1), 0) = 0 THEN RETURN false; END IF;
  INSERT INTO public.instance_context_state (instance_id, site_id) VALUES (p_instance_id, p_site_id)
    ON CONFLICT (instance_id) DO NOTHING;
  SELECT cursor_at, cursor_log_id INTO v_cursor, v_log_id FROM public.instance_context_state
    WHERE instance_id = p_instance_id AND site_id = p_site_id FOR UPDATE;
  IF v_cursor IS DISTINCT FROM p_expected_cursor OR v_log_id IS DISTINCT FROM p_expected_log_id OR
     (v_cursor IS NOT NULL AND (p_end_at, p_end_log_id) <= (v_cursor, v_log_id)) THEN RETURN false; END IF;
  -- Verify that the summary covers the exact contiguous log segment as of the
  -- locked cursor. Do not silently cross a pending user action or an unseen page.
  SELECT array_agg(l.id ORDER BY l.created_at, l.id) INTO v_actual_ids
    FROM public.instance_logs l
    WHERE l.instance_id = p_instance_id AND l.site_id = p_site_id
      AND l.log_type IN ('user_action','agent_action','tool_call','error',
                         'execution_summary','infrastructure','sandbox_test_failure')
      AND (v_cursor IS NULL OR (l.created_at, l.id) > (v_cursor, v_log_id))
      AND (l.created_at, l.id) <= (p_end_at, p_end_log_id);
  IF v_actual_ids IS DISTINCT FROM p_log_ids THEN RETURN false; END IF;
  IF EXISTS (SELECT 1 FROM public.instance_logs l
    WHERE l.id = ANY(p_log_ids) AND (l.details->>'status' = 'queued'
      OR l.details->>'streaming' = 'true')) THEN RETURN false; END IF;
  INSERT INTO public.instance_context_memories (instance_id, site_id, start_at, end_at, end_log_id, summary, embedding)
    VALUES (p_instance_id, p_site_id, p_start_at, p_end_at, p_end_log_id, p_summary, p_embedding);
  UPDATE public.instance_context_state SET cursor_at = p_end_at, cursor_log_id = p_end_log_id,
    revision = revision + 1, updated_at = now()
    WHERE instance_id = p_instance_id AND site_id = p_site_id;
  RETURN true;
END $$;


--
-- Name: complete_catalog_embedding_job(uuid, uuid, text, bigint, public.vector, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_source_hash text, p_source_revision bigint, p_embedding public.vector, p_model text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE v_job public.catalog_embedding_jobs%ROWTYPE; v_item uuid;
BEGIN
  IF p_embedding IS NULL OR vector_dims(p_embedding) <> 1536 OR p_model IS DISTINCT FROM 'openai/text-embedding-3-small'
    OR (p_embedding <#> p_embedding) >= 0 THEN
    RAISE EXCEPTION 'expected nonzero 1536-dimensional openai/text-embedding-3-small embedding' USING ERRCODE = '22023';
  END IF;
  SELECT j.catalog_item_id INTO v_item FROM public.catalog_embedding_jobs j WHERE j.id = p_job_id;
  IF NOT FOUND THEN RETURN false; END IF;
  -- Same item -> document -> job order as refresh; do not lock job before source row.
  PERFORM 1 FROM public.catalog_items WHERE id = v_item FOR NO KEY UPDATE;
  SELECT * INTO v_job FROM public.catalog_embedding_jobs WHERE id = p_job_id FOR UPDATE;
  IF NOT FOUND OR v_job.status <> 'leased' OR v_job.claim_token IS DISTINCT FROM p_claim_token
    OR v_job.lease_expires_at <= clock_timestamp() OR v_job.source_hash IS DISTINCT FROM p_source_hash
    OR v_job.source_revision IS DISTINCT FROM p_source_revision THEN RETURN false; END IF;
  UPDATE public.catalog_search_documents d SET embedding = p_embedding, embedding_model = p_model,
    embedding_source_hash = p_source_hash, indexed_at = now()
  WHERE d.catalog_item_id = v_job.catalog_item_id AND d.site_id = v_job.site_id
    AND d.source_hash = p_source_hash AND d.source_revision = p_source_revision;
  IF NOT FOUND THEN RETURN false; END IF;
  UPDATE public.catalog_embedding_jobs SET status = 'done', claim_token = NULL,
    lease_expires_at = NULL, last_error = NULL, updated_at = now() WHERE id = p_job_id;
  PERFORM public.catalog_search_bump_revision(v_job.site_id);
  RETURN true;
END $$;


--
-- Name: complete_credit_auto_top_up_attempt(uuid, uuid, uuid, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_customer_id text, p_amount_cents integer, p_currency text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; a public.credit_auto_top_up_attempts%ROWTYPE;
  v_grant jsonb; v_payment public.payments%ROWTYPE;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_stripe_payment_intent_id IS NULL OR p_stripe_payment_intent_id !~ '^pi_[A-Za-z0-9]+$'
    OR p_currency IS DISTINCT FROM 'usd' THEN
    RAISE EXCEPTION 'Invalid verified Stripe settlement';
  END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing record not found'; END IF;
  SELECT * INTO a FROM public.credit_auto_top_up_attempts
    WHERE site_id=p_site_id AND id=p_attempt_id FOR UPDATE;
  IF NOT FOUND OR a.stripe_customer_id IS DISTINCT FROM p_stripe_customer_id
    OR a.amount_cents IS DISTINCT FROM p_amount_cents
    OR a.stripe_payment_intent_id IS DISTINCT FROM p_stripe_payment_intent_id THEN
    RAISE EXCEPTION 'Stripe top-up settlement identity mismatch';
  END IF;
  IF a.status = 'succeeded' THEN
    RETURN jsonb_build_object('success',true,'outcome','duplicate','attempt_id',a.id);
  END IF;
  IF a.status <> 'pending' OR a.claim_token IS DISTINCT FROM p_claim_token THEN
    RAISE EXCEPTION 'Stale or terminal automatic top-up attempt';
  END IF;
  SELECT * INTO v_payment FROM public.payments WHERE transaction_id=p_stripe_payment_intent_id;
  IF FOUND AND (v_payment.site_id IS DISTINCT FROM p_site_id
    OR v_payment.status IS DISTINCT FROM 'completed'
    OR v_payment.transaction_type IS DISTINCT FROM 'credits_purchase'
    OR v_payment.credits IS DISTINCT FROM a.credits
    OR v_payment.amount IS DISTINCT FROM (a.amount_cents::numeric/100)) THEN
    RAISE EXCEPTION 'Stripe payment identity already used';
  END IF;
  v_grant := public.grant_purchased_site_credits(p_site_id,a.credits,p_stripe_payment_intent_id,
    jsonb_build_object('auto_top_up_attempt_id',a.id,'stripe_payment_intent_id',p_stripe_payment_intent_id));
  IF v_grant->>'outcome' IS DISTINCT FROM 'granted' THEN
    RAISE EXCEPTION 'Automatic top-up credit grant requires reconciliation';
  END IF;
  INSERT INTO public.payments(site_id,transaction_id,transaction_type,amount,currency,
    status,payment_method,credits,details)
  VALUES (p_site_id,p_stripe_payment_intent_id,'credits_purchase',a.amount_cents::numeric/100,
    'USD','completed','stripe',a.credits,jsonb_build_object(
      'auto_top_up_attempt_id',a.id,'stripe_payment_intent_id',p_stripe_payment_intent_id,
      'stripe_customer_id',a.stripe_customer_id));
  UPDATE public.credit_auto_top_up_attempts SET status='succeeded',finished_at=now() WHERE id=a.id;
  RETURN jsonb_build_object('success',true,'outcome','succeeded','attempt_id',a.id,'credits_granted',a.credits);
END;
$_$;

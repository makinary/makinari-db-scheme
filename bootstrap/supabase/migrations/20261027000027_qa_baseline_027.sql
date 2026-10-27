SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: complete_credit_auto_top_up_setup(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_credit_auto_top_up_setup(p_site_id uuid, p_token uuid, p_stripe_customer_id text, p_stripe_payment_method_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; s public.credit_auto_top_up_card_setups%ROWTYPE;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing unavailable'; END IF;
  SELECT * INTO s FROM public.credit_auto_top_up_card_setups WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR s.token IS DISTINCT FROM p_token THEN
    RETURN jsonb_build_object('outcome','obsolete');
  END IF;
  IF b.stripe_customer_id IS DISTINCT FROM p_stripe_customer_id OR s.stripe_customer_id IS DISTINCT FROM p_stripe_customer_id
    OR p_stripe_payment_method_id IS NULL OR p_stripe_payment_method_id !~ '^pm_[A-Za-z0-9]+$' THEN
    RAISE EXCEPTION 'Setup customer mismatch';
  END IF;
  IF s.status='completed' THEN
    IF s.stripe_payment_method_id IS DISTINCT FROM p_stripe_payment_method_id THEN RAISE EXCEPTION 'Setup identity conflict'; END IF;
    RETURN jsonb_build_object('outcome','duplicate');
  END IF;
  UPDATE public.credit_auto_top_up_card_setups SET status='completed',stripe_payment_method_id=p_stripe_payment_method_id,
    completed_at=now() WHERE site_id=p_site_id;
  PERFORM public.attach_credit_auto_top_up_payment_method_internal(p_site_id,p_stripe_payment_method_id,p_stripe_customer_id);
  -- Card authorization is NOT authorization to activate automatic purchases.
  UPDATE public.credit_auto_top_up_settings SET enabled=false WHERE site_id=p_site_id;
  RETURN jsonb_build_object('outcome','attached');
END;
$_$;


--
-- Name: complete_instance_plan_step_after_gate(uuid, text, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_instance_plan_step_after_gate(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_final_gate_approved boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_plan_status text;
  v_steps jsonb;
  v_step jsonb;
  v_step_index integer;
  v_generation integer;
  v_final boolean;
  v_completed_count integer;
BEGIN
  SELECT
    status,
    CASE WHEN jsonb_typeof(steps) = 'array' THEN steps ELSE '[]'::jsonb END
  INTO v_plan_status, v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'state', 'missing', 'persisted', false, 'final', false
    );
  END IF;
  IF v_plan_status IN ('paused', 'cancelled', 'failed') THEN
    RETURN jsonb_build_object(
      'state',
      CASE WHEN v_plan_status = 'paused' THEN 'guarded' ELSE 'terminal' END,
      'persisted', false,
      'final', false
    );
  END IF;

  SELECT entry.value, (entry.ordinality - 1)::integer
  INTO v_step, v_step_index
  FROM jsonb_array_elements(v_steps)
    WITH ORDINALITY AS entry(value, ordinality)
  WHERE entry.value->>'id' = p_step_id
  LIMIT 1;
  IF v_step IS NULL OR (
    SELECT count(*) FROM jsonb_array_elements(v_steps) AS entry(value)
    WHERE entry.value->>'id' = p_step_id
  ) <> 1 THEN
    RETURN jsonb_build_object(
      'state', 'missing', 'persisted', false, 'final', false
    );
  END IF;

  v_generation := CASE
    WHEN COALESCE(v_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  IF v_step->>'status' = 'completed'
    AND (
      v_generation IS NOT DISTINCT FROM p_expected_generation
      OR v_generation::bigint IS NOT DISTINCT FROM
        p_expected_generation::bigint + 1
    )
  THEN
    SELECT bool_and(
      entry.value->>'status' IN ('completed', 'cancelled', 'skipped')
    )
    INTO v_final
    FROM jsonb_array_elements(v_steps) AS entry(value);
    RETURN jsonb_build_object(
      'state', 'duplicate',
      'persisted', true,
      'final', COALESCE(v_final, false),
      'generation', v_generation
    );
  END IF;
  IF v_plan_status = 'completed' THEN
    RETURN jsonb_build_object(
      'state', 'terminal', 'persisted', false, 'final', true,
      'generation', v_generation
    );
  END IF;
  IF v_generation IS DISTINCT FROM p_expected_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale', 'persisted', false, 'final', false,
      'generation', v_generation
    );
  END IF;
  IF v_step->>'status' = 'cancelled' THEN
    RETURN jsonb_build_object(
      'state', 'terminal', 'persisted', false, 'final', false,
      'generation', v_generation
    );
  END IF;

  v_step := v_step || jsonb_build_object(
    'status', 'completed',
    'completed_at', timezone('utc', now()),
    'error_message', NULL,
    'infrastructure_generation', v_generation + 1
  );
  v_steps := jsonb_set(
    v_steps, ARRAY[v_step_index::text], v_step, false
  );
  SELECT
    bool_and(
      entry.value->>'status' IN ('completed', 'cancelled', 'skipped')
    ),
    count(*) FILTER (WHERE entry.value->>'status' = 'completed')
  INTO v_final, v_completed_count
  FROM jsonb_array_elements(v_steps) AS entry(value);

  IF COALESCE(v_final, false) AND NOT p_final_gate_approved THEN
    RETURN jsonb_build_object(
      'state', 'guarded',
      'persisted', false,
      'final', true,
      'generation', v_generation
    );
  END IF;

  UPDATE public.instance_plans
  SET
    steps = v_steps,
    status = CASE
      WHEN COALESCE(v_final, false) THEN 'completed'
      WHEN v_plan_status = 'pending' THEN 'in_progress'
      ELSE v_plan_status
    END,
    steps_completed = v_completed_count,
    progress_percentage = CASE
      WHEN jsonb_array_length(v_steps) = 0 THEN 0
      WHEN COALESCE(v_final, false) THEN 100
      ELSE round(
        (v_completed_count::numeric / jsonb_array_length(v_steps)) * 100
      )::integer
    END,
    completed_at = CASE
      WHEN COALESCE(v_final, false) THEN timezone('utc', now())
      ELSE NULL
    END,
    updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  RETURN jsonb_build_object(
    'state', 'applied',
    'persisted', true,
    'final', COALESCE(v_final, false),
    'generation', v_generation + 1
  );
END;
$_$;


--
-- Name: complete_marketplace_oauth(uuid, text, timestamp with time zone, text, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_marketplace_oauth(p_session_id uuid, p_encrypted_authorization text, p_expires_at timestamp with time zone, p_app_client_id_hash text, p_actor_user_id uuid, p_authorized_stores jsonb DEFAULT '[]'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.marketplace_oauth_sessions; connection_id uuid;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'OAuth backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO session FROM public.marketplace_oauth_sessions WHERE id=p_session_id FOR UPDATE;
  IF NOT FOUND OR session.user_id IS DISTINCT FROM p_actor_user_id OR session.status <> 'claimed'
    OR session.expires_at <= now() OR (p_expires_at IS NOT NULL AND p_expires_at <= now()) THEN
    RAISE EXCEPTION 'OAuth claim unavailable' USING ERRCODE='42501';
  END IF;
  PERFORM public.marketplace_assert_actor(session.site_id,p_actor_user_id,true);
  INSERT INTO public.marketplace_merchant_connections(oauth_session_id,site_id,provider,environment,country,
    credential_mode,app_client_id_hash,encrypted_authorization,token_expires_at,actor_user_id,authorized_stores)
  VALUES(session.id,session.site_id,session.provider,session.environment,session.country,session.credential_mode,
    p_app_client_id_hash,p_encrypted_authorization,p_expires_at,p_actor_user_id,p_authorized_stores) RETURNING id INTO connection_id;
  UPDATE public.marketplace_oauth_sessions SET status='completed',encrypted_context=NULL,finished_at=now() WHERE id=session.id;
  RETURN jsonb_build_object('connection_id',connection_id);
END;
$$;


--
-- Name: complete_migration_diagnostic(uuid, text, uuid, integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_migration_diagnostic(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text, p_result jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_lifecycle public.requirement_migration_lifecycle%ROWTYPE;
  v_diagnostic public.requirement_migration_diagnostics%ROWTYPE;
  v_decision text;
BEGIN
  IF p_token IS NULL OR jsonb_typeof(p_result) IS DISTINCT FROM 'object'
    OR octet_length(p_result::text) > 65536
    OR jsonb_typeof(p_result->'decision') IS DISTINCT FROM 'string'
    OR jsonb_typeof(p_result->'evidence') IS DISTINCT FROM 'array'
  THEN
    RAISE EXCEPTION 'Invalid migration diagnostic result' USING ERRCODE = '22023';
  END IF;
  v_decision := p_result->>'decision';
  IF v_decision NOT IN ('repair_candidate', 'missing_capability', 'needs_product_decision', 'constraint_conflict', 'unresolved')
    OR (v_decision <> 'unresolved' AND jsonb_array_length(p_result->'evidence') = 0)
    OR (v_decision = 'repair_candidate' AND EXISTS (
      SELECT 1 FROM unnest(ARRAY['hypothesis', 'instruction', 'verification']) AS fields(key)
      WHERE jsonb_typeof(p_result->key) IS DISTINCT FROM 'string' OR (p_result->>key) !~ '[^[:space:]]'
    ))
    OR (v_decision <> 'repair_candidate' AND (
      jsonb_typeof(p_result->'reason') IS DISTINCT FROM 'string' OR (p_result->>'reason') !~ '[^[:space:]]'
    ))
  THEN
    RAISE EXCEPTION 'Invalid migration diagnostic result' USING ERRCODE = '22023';
  END IF;
  v_lifecycle := public.lock_requirement_migration_diagnostic_scope(
    p_requirement_id, p_file, p_execution_generation, p_run_id, true);
  SELECT * INTO v_diagnostic FROM public.requirement_migration_diagnostics
    WHERE requirement_id = p_requirement_id AND file = p_file FOR UPDATE;
  IF NOT FOUND OR v_diagnostic.token IS DISTINCT FROM p_token
    OR v_diagnostic.execution_generation IS DISTINCT FROM p_execution_generation
    OR v_diagnostic.checksum IS DISTINCT FROM v_lifecycle.checksum
    OR v_diagnostic.specification_checksum IS DISTINCT FROM v_lifecycle.specification_checksum
  THEN
    RAISE EXCEPTION 'Migration diagnostic scope conflict' USING ERRCODE = '40001';
  END IF;
  IF v_diagnostic.state <> 'running' THEN
    IF v_diagnostic.state IN ('followup_ready', 'followup_assigned', 'exhausted')
      AND v_diagnostic.result = p_result THEN RETURN to_jsonb(v_diagnostic); END IF;
    RAISE EXCEPTION 'Migration diagnostic result already consumed' USING ERRCODE = '40001';
  END IF;
  UPDATE public.requirement_migration_diagnostics SET
    state = CASE WHEN v_decision = 'repair_candidate' THEN 'followup_ready' ELSE 'exhausted' END,
    result = p_result, updated_at = clock_timestamp()
    WHERE requirement_id = p_requirement_id AND file = p_file RETURNING * INTO v_diagnostic;
  RETURN to_jsonb(v_diagnostic);
END;
$$;


--
-- Name: complete_quotation_checkout(uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_quotation_checkout(p_quotation_id uuid, p_claim_id uuid, p_sale_id uuid, p_order_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  quotation_row public.quotations%ROWTYPE;
BEGIN
  SELECT *
  INTO quotation_row
  FROM public.quotations
  WHERE id = p_quotation_id
  FOR UPDATE;

  IF NOT FOUND
     OR p_claim_id IS NULL
     OR quotation_row.status <> 'sent'
     OR quotation_row.checkout_claim_id IS DISTINCT FROM p_claim_id THEN
    RETURN false;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.sales
    WHERE id = p_sale_id
      AND quotation_id = p_quotation_id
  ) OR NOT EXISTS (
    SELECT 1
    FROM public.sale_orders
    WHERE id = p_order_id
      AND sale_id = p_sale_id
      AND quotation_id = p_quotation_id
  ) THEN
    RETURN false;
  END IF;

  UPDATE public.quotations
  SET
    status = 'accepted',
    checkout_sale_id = p_sale_id,
    checkout_order_id = p_order_id,
    checkout_claim_id = NULL,
    checkout_claimed_at = NULL
  WHERE id = p_quotation_id;

  IF quotation_row.deal_id IS NOT NULL THEN
    UPDATE public.deals
    SET
      stage = 'closed_won',
      status = 'won',
      accepted_quotation_id = p_quotation_id,
      amount = quotation_row.total,
      sales_order_id = p_sale_id
    WHERE id = quotation_row.deal_id;
  END IF;

  RETURN true;
END;
$$;


--
-- Name: complete_sandbox_billing_observation(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_sandbox_billing_observation(p_sandbox_name text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.sandbox_billing_resources SET last_reconciled_at=clock_timestamp() WHERE sandbox_name=p_sandbox_name;
  RETURN jsonb_build_object('success',true);
END;
$$;


--
-- Name: complete_stripe_sale_compensation(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_refund_id text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.stripe_sale_checkout_effects
  SET compensation_status = 'refunded',
      stripe_refund_id = p_refund_id,
      compensation_claim_token = NULL,
      compensation_completed_at = now(),
      updated_at = now()
  WHERE stripe_session_id = p_session_id
    AND compensation_status = 'processing'
    AND compensation_claim_token = p_claim_token;
  RETURN FOUND;
END;
$$;


--
-- Name: complete_stripe_sale_fulfillment(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.stripe_sale_checkout_effects
  SET fulfillment_status = 'completed',
      fulfillment_claim_token = NULL,
      fulfillment_completed_at = now(),
      updated_at = now()
  WHERE stripe_session_id = p_session_id
    AND fulfillment_status = 'processing'
    AND fulfillment_claim_token = p_claim_token;
  RETURN FOUND;
END;
$$;


--
-- Name: complete_stripe_webhook_event(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_stripe_webhook_event(p_event_id text, p_claim_token uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.webhook_events
  SET status = 'processed',
      processed_at = now(),
      error_message = NULL,
      claim_token = NULL,
      updated_at = now()
  WHERE stripe_event_id = p_event_id
    AND status = 'processing'
    AND claim_token = p_claim_token;

  RETURN FOUND;
END;
$$;


--
-- Name: configure_credit_auto_top_up_settings_internal(uuid, boolean, numeric, numeric, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.configure_credit_auto_top_up_settings_internal(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_stripe_payment_method_id text DEFAULT NULL::text, p_state text DEFAULT 'ready'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; s public.credit_auto_top_up_settings%ROWTYPE;
  v_pm text;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_site_id IS NULL OR p_enabled IS NULL OR p_minimum_credits IS NULL
    OR p_target_credits IS NULL OR p_max_monthly_spend_cents IS NULL
    OR p_state IS NULL OR p_state NOT IN ('ready','paused')
    OR p_minimum_credits::text IN ('NaN','Infinity','-Infinity')
    OR p_target_credits::text IN ('NaN','Infinity','-Infinity')
    OR p_minimum_credits < 0 OR p_target_credits <= p_minimum_credits
    OR p_target_credits > 1000000 OR p_max_monthly_spend_cents NOT BETWEEN 100 AND 100000000
    OR (p_stripe_payment_method_id IS NOT NULL AND p_stripe_payment_method_id !~ '^pm_[A-Za-z0-9]+$')
  THEN RAISE EXCEPTION 'Invalid automatic credit top-up settings'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing record not found'; END IF;
  SELECT * INTO s FROM public.credit_auto_top_up_settings WHERE site_id=p_site_id FOR UPDATE;
  v_pm := coalesce(p_stripe_payment_method_id,s.stripe_payment_method_id);
  -- Paused settings may be disabled/reconfigured but NEVER unpaused here.
  -- New cards are registered through attach_credit_auto_top_up_payment_method
  -- after the service has checked their Stripe customer ownership.
  IF p_stripe_payment_method_id IS NOT NULL
    AND p_stripe_payment_method_id IS DISTINCT FROM s.stripe_payment_method_id
  THEN
    RAISE EXCEPTION 'Payment method must first be verified against the Stripe customer';
  END IF;
  IF p_enabled AND (v_pm IS NULL OR b.stripe_customer_id IS NULL) THEN
    RAISE EXCEPTION 'A verified Stripe customer and payment method are required';
  END IF;
  INSERT INTO public.credit_auto_top_up_settings
    (site_id,enabled,minimum_credits,target_credits,max_monthly_spend_cents,stripe_payment_method_id,state)
  VALUES (p_site_id,p_enabled,p_minimum_credits,p_target_credits,p_max_monthly_spend_cents,v_pm,p_state)
  ON CONFLICT (site_id) DO UPDATE SET
    enabled=excluded.enabled,minimum_credits=excluded.minimum_credits,
    target_credits=excluded.target_credits,max_monthly_spend_cents=excluded.max_monthly_spend_cents,
    stripe_payment_method_id=excluded.stripe_payment_method_id,
    state=CASE WHEN public.credit_auto_top_up_settings.state='paused' THEN 'paused'
      ELSE excluded.state END,updated_at=now();
  RETURN jsonb_build_object('success',true,'outcome','saved','site_id',p_site_id);
END;
$_$;

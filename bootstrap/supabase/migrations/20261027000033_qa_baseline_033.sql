SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: finish_icp_dispatch(uuid, uuid, jsonb, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_icp_dispatch(p_id uuid, p_run_id uuid, p_errors jsonb DEFAULT '[]'::jsonb, p_retry_after_seconds integer DEFAULT 300) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  d public.icp_dispatch_runs; r public.icp_mining;
  actual_processed bigint; actual_found bigint; failures integer; list_failures integer;
  cooldown integer; list_cooldown integer; has_errors boolean; has_retryable_errors boolean; stamp timestamptz;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(734210, 1);
  SELECT * INTO d FROM public.icp_dispatch_runs WHERE id = p_id FOR UPDATE;
  IF NOT FOUND OR p_run_id IS NULL OR d.run_id IS DISTINCT FROM p_run_id THEN RAISE EXCEPTION 'Dispatch run mismatch'; END IF;
  IF d.state = 'settled' THEN
    RETURN jsonb_build_object('success', true, 'next_eligible_at',
      (SELECT next_eligible_at FROM public.icp_dispatch_site_state WHERE site_id = d.site_id));
  END IF;
  IF d.state <> 'running' OR d.baseline_processed IS NULL OR d.baseline_found IS NULL THEN
    RAISE EXCEPTION 'Dispatch must be running to settle';
  END IF;
  IF jsonb_typeof(p_errors) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Dispatch errors must be an array'; END IF;
  SELECT * INTO r FROM public.icp_mining WHERE id = d.icp_mining_id AND site_id = d.site_id FOR UPDATE;
  IF NOT FOUND OR r.execution_run_id IS DISTINCT FROM p_run_id OR r.execution_workflow_id IS DISTINCT FROM d.workflow_id THEN
    RAISE EXCEPTION 'Dispatch execution ownership lost';
  END IF;
  IF r.execution_active THEN RAISE EXCEPTION 'Dispatch execution must checkpoint release before settlement'; END IF;
  actual_processed := r.processed_targets::bigint - d.baseline_processed;
  actual_found := r.found_matches::bigint - d.baseline_found;
  IF actual_processed IS NULL OR actual_found IS NULL OR actual_processed NOT BETWEEN 0 AND d.reserved_candidates
    OR actual_found NOT BETWEEN 0 AND d.reserved_matches OR actual_found > actual_processed THEN
    RAISE EXCEPTION 'Dispatch settlement exceeds reservation';
  END IF;
  stamp := clock_timestamp();
  has_errors := jsonb_array_length(p_errors) > 0;
  SELECT EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_errors) AS entry(value)
    WHERE jsonb_typeof(value) <> 'string'
      OR regexp_replace(lower(value #>> '{}'), '[_-]+', ' ', 'g') !~
        '(\mambiguous\s*(org|organization|organisation)\M|\m(organization|organisation|org)\M.*\mambiguous\M|\mcannot resolve organization identity\M)'
  ) INTO has_retryable_errors;
  SELECT CASE WHEN has_retryable_errors THEN least(consecutive_failures::bigint + 1, 2147483647)::integer ELSE 0 END
    INTO failures FROM public.icp_dispatch_site_state WHERE site_id = d.site_id FOR UPDATE;
  SELECT CASE WHEN has_retryable_errors THEN least(failure_count::bigint + 1, 2147483647)::integer ELSE 0 END
    INTO list_failures FROM public.icp_dispatch_list_state WHERE icp_mining_id = d.icp_mining_id FOR UPDATE;
  IF has_errors AND NOT has_retryable_errors THEN
    cooldown := 0;
    list_cooldown := 0;
  ELSE
    cooldown := least(21600, greatest(300, COALESCE(p_retry_after_seconds, 300),
      CASE WHEN has_retryable_errors THEN 300 * (2 ^ least(greatest(failures - 1, 0), 7))::integer ELSE 300 END));
    list_cooldown := least(21600, greatest(300, COALESCE(p_retry_after_seconds, 300),
      CASE WHEN has_retryable_errors THEN 300 * (2 ^ least(greatest(list_failures - 1, 0), 7))::integer ELSE 300 END));
  END IF;
  UPDATE public.icp_dispatch_runs SET state = 'settled', processed = actual_processed, found = actual_found,
    error = CASE WHEN has_errors THEN p_errors::text ELSE NULL END, updated_at = stamp WHERE id = d.id;
  UPDATE public.icp_dispatch_site_state SET consecutive_failures = failures,
    next_eligible_at = greatest(next_eligible_at, stamp + make_interval(secs => cooldown)) WHERE site_id = d.site_id;
  UPDATE public.icp_dispatch_list_state SET failure_count = list_failures,
    next_eligible_at = greatest(next_eligible_at, stamp + make_interval(secs => list_cooldown)) WHERE icp_mining_id = d.icp_mining_id;
  -- Keep ownership, idempotency, conservative candidate charging and budget day.
  RETURN jsonb_build_object('success', true, 'next_eligible_at',
    (SELECT next_eligible_at FROM public.icp_dispatch_site_state WHERE site_id = d.site_id));
END $$;


--
-- Name: finish_image_generation_reservation(uuid, text, uuid, integer, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_reason text, p_generation_id text, p_model text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE b public.billing%ROWTYPE; r public.image_generation_credit_reservations%ROWTYPE;
  v_charge numeric; v_refund numeric; v_trial numeric; v_plan numeric; v_legacy numeric; v_purchase numeric;
  v_restore_trial numeric; v_restore_plan numeric; v_same_period boolean; v_metadata jsonb;
BEGIN
  IF (p_reason IS NULL AND (p_count IS NULL OR p_count NOT BETWEEN 1 AND 4))
    OR (p_reason IS NOT NULL AND (p_count IS NOT NULL OR p_reason NOT IN ('not_dispatched','confirmed_admission_rejection')))
    OR (p_generation_id IS NOT NULL AND p_generation_id !~ '^[a-zA-Z0-9_-]{1,200}$')
    OR (p_model IS NOT NULL AND length(p_model)>128) THEN RAISE EXCEPTION 'Invalid image settlement'; END IF;
  PERFORM public.renew_site_plan_credits(p_site_id);
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Image billing record unavailable'; END IF;
  SELECT * INTO r FROM public.image_generation_credit_reservations WHERE site_id=p_site_id AND operation_id=p_operation_id FOR UPDATE;
  IF NOT FOUND OR r.dispatch_token IS DISTINCT FROM p_token THEN RAISE EXCEPTION 'Image reservation not owned'; END IF;
  IF r.state IN ('settled','released') THEN
    IF r.actual_count IS DISTINCT FROM p_count OR r.reason IS DISTINCT FROM p_reason
      OR r.generation_id IS DISTINCT FROM p_generation_id OR r.model IS DISTINCT FROM p_model THEN
      RAISE EXCEPTION 'Image settlement identity conflict'; END IF;
    RETURN jsonb_build_object('success',true,'state',r.state,'charged',r.charged);
  END IF;
  IF p_reason IS NULL AND (r.state NOT IN ('dispatched','pending') OR p_count>r.requested_count) THEN
    RAISE EXCEPTION 'Image settlement requires dispatch and valid output count'; END IF;
  IF p_reason='not_dispatched' AND r.state<>'reserved' THEN
    RAISE EXCEPTION 'Cannot release an uncertain dispatch'; END IF;
  v_charge:=coalesce(p_count,0)*0.1; v_refund:=r.amount-v_charge;
  -- Charge the original bucket order and return only the unused tail, never bought credit fabrication.
  v_trial:=r.trial_spent-least(r.trial_spent,v_charge);
  v_plan:=r.plan_spent-least(r.plan_spent,greatest(v_charge-r.trial_spent,0));
  v_legacy:=r.legacy_spent-least(r.legacy_spent,greatest(v_charge-r.trial_spent-r.plan_spent,0));
  v_purchase:=r.purchased_spent-least(r.purchased_spent,greatest(v_charge-r.trial_spent-r.plan_spent-r.legacy_spent,0));
  v_same_period:=b.plan_credit_period_start IS NOT DISTINCT FROM r.period_start
    AND b.plan_credit_period_end IS NOT DISTINCT FROM r.period_end;
  v_restore_trial:=CASE WHEN b.trial_converted_at IS NULL AND b.trial_started_at=r.trial_started_at
    AND b.trial_ends_at=r.trial_ends_at AND r.trial_ends_at>clock_timestamp() AND b.status='active'
    AND NOT EXISTS(SELECT 1 FROM public.sites WHERE id=r.site_id AND archived_at IS NOT NULL)
    THEN least(v_trial,greatest(50-b.trial_credits_available,0)) ELSE 0 END;
  v_restore_plan:=CASE WHEN v_same_period AND r.period_end>clock_timestamp() AND b.status='active'
    AND NOT EXISTS(SELECT 1 FROM public.sites WHERE id=r.site_id AND archived_at IS NOT NULL)
    THEN least(v_plan,greatest(b.plan_credit_allowance-greatest(b.plan_credits_used-v_plan,0)-b.plan_credits_available,0)) ELSE 0 END;
  v_metadata:=jsonb_build_object('operation_id',p_operation_id,'actual_count',p_count,'charged',v_charge,
    'reason',p_reason,'generation_id',p_generation_id,'model',p_model);
  IF v_refund>0 THEN
    UPDATE public.billing SET trial_credits_available=trial_credits_available+v_restore_trial,
      plan_credits_available=plan_credits_available+v_restore_plan,legacy_credits_available=legacy_credits_available+v_legacy,
      purchased_credits_available=purchased_credits_available+v_purchase,
      credits_available=credits_available+v_restore_trial+v_restore_plan+v_legacy+v_purchase,
      credits_used=greatest(coalesce(credits_used,0)-v_refund,0),
      monthly_credits_used=CASE WHEN v_same_period THEN greatest(monthly_credits_used-v_refund,0) ELSE monthly_credits_used END,
      plan_credits_used=CASE WHEN v_same_period THEN greatest(plan_credits_used-v_plan,0) ELSE plan_credits_used END WHERE id=b.id;
    INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
      VALUES(p_site_id,v_restore_trial+v_restore_plan+v_legacy+v_purchase,'image_generation_release','Unused image admission hold',
        v_metadata||jsonb_build_object('trial_restored',v_restore_trial,'plan_restored',v_restore_plan,
          'legacy_restored',v_legacy,'purchased_restored',v_purchase,
          'expired_trial',v_trial-v_restore_trial,'expired_plan',v_plan-v_restore_plan));
  END IF;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES(p_site_id,0,'image_generation_settlement','Image admission final settlement',v_metadata);
  UPDATE public.image_generation_credit_reservations SET state=CASE WHEN p_reason IS NULL THEN 'settled' ELSE 'released' END,
    actual_count=p_count,charged=v_charge,generation_id=p_generation_id,model=p_model,reason=p_reason,finished_at=clock_timestamp()
    WHERE site_id=p_site_id AND operation_id=p_operation_id;
  RETURN jsonb_build_object('success',true,'state',CASE WHEN p_reason IS NULL THEN 'settled' ELSE 'released' END,'charged',v_charge);
END $_$;


--
-- Name: finish_marketplace_action(uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_marketplace_action(p_action_id uuid, p_result text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE operation public.marketplace_actions; native_order public.sale_orders;
  integration public.marketplace_integrations; marketplace jsonb; state text; native_status text;
BEGIN
  IF NOT public.marketplace_is_backend() THEN
    RAISE EXCEPTION 'Marketplace actions require backend' USING ERRCODE = '42501';
  END IF;
  IF p_result IS NULL OR p_result NOT IN ('confirmed','failed','unknown') OR jsonb_typeof(p_metadata) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid marketplace operation result';
  END IF;
  SELECT * INTO operation FROM public.marketplace_actions WHERE id = p_action_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Marketplace action not found'; END IF;
  -- Same lock order as authoritative webhook reconciliation: order then action.
  SELECT * INTO native_order FROM public.sale_orders WHERE id = operation.order_id FOR UPDATE;
  SELECT * INTO operation FROM public.marketplace_actions WHERE id = p_action_id FOR UPDATE;
  IF operation.status IN ('confirmed','failed') OR (operation.status = 'unknown' AND p_result = 'failed') THEN
    RETURN jsonb_build_object('order_id',operation.order_id,'operation',jsonb_build_object('action',operation.action,'status',operation.status));
  END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id = native_order.marketplace_integration_id;
  marketplace := native_order.metadata->'marketplace'; state := marketplace->>'state';
  IF p_result = 'confirmed' THEN
    IF native_order.status <> 'cancelled' AND state <> 'completed' THEN
      state := CASE operation.action WHEN 'accept' THEN CASE WHEN state = 'ready' THEN 'ready' ELSE 'accepted' END
        WHEN 'ready' THEN 'ready' WHEN 'reject' THEN 'rejected' WHEN 'cancel' THEN 'cancelled' END;
    END IF;
    -- Preserve the latest provider metadata; the request snapshot may be stale.
    -- Derive authoritative transitions and capabilities from the claimed action.
    marketplace := marketplace||jsonb_build_object('provider',integration.provider,
      'external_order_id',native_order.external_order_id,'external_store_id',integration.external_store_id,
      'state',state,'delivery_mode',coalesce(native_order.metadata#>>'{marketplace,delivery_mode}','marketplace_managed'),'sync_status','confirmed',
      'capabilities',public.marketplace_capabilities(integration.provider,state,integration.manual_ready));
    native_status := public.marketplace_native_state(state,integration.provider);
    IF state IN ('accepted','ready','completed') AND marketplace->>'accepted_at' IS NULL THEN
      marketplace := marketplace||jsonb_build_object('accepted_at',now());
    END IF;
    UPDATE public.sale_order_items SET status = CASE WHEN native_status = 'cancelled' THEN 'cancelled'
      WHEN native_status = 'draft' THEN 'draft' WHEN state IN ('ready','completed') THEN 'completed' ELSE 'new' END
      WHERE sale_order_id = native_order.id;
    IF native_status = 'cancelled' THEN UPDATE public.shipments SET status = 'cancelled'
      WHERE sale_order_id = native_order.id AND marketplace_integration_id IS NOT NULL; END IF;
  ELSE
    marketplace := marketplace||jsonb_build_object('sync_status',CASE WHEN p_result = 'unknown' THEN 'unknown' ELSE 'confirmed' END);
    native_status := native_order.status;
  END IF;
  marketplace := marketplace||jsonb_build_object('operation',jsonb_build_object('action',operation.action,'status',p_result));
  UPDATE public.marketplace_actions SET status = p_result,finished_at = now() WHERE id = operation.id;
  UPDATE public.sale_orders SET status = native_status,metadata = metadata||jsonb_build_object('marketplace',marketplace),updated_at = now()
    WHERE id = native_order.id;
  UPDATE public.shipments SET
    status = CASE WHEN status IN ('delivered','cancelled') THEN status
      WHEN native_status = 'cancelled' THEN 'cancelled'
      WHEN status = 'pending' AND state IN ('accepted','ready') AND p_result = 'confirmed' THEN 'preparing'
      ELSE status END,
    metadata = coalesce(metadata,'{}'::jsonb)||jsonb_build_object('marketplace',
      coalesce(metadata->'marketplace','{}'::jsonb)||jsonb_build_object(
        'state',state,'sync_status',marketplace->>'sync_status','operation',marketplace->'operation')),
    updated_at = now()
    WHERE sale_order_id = native_order.id AND marketplace_integration_id = integration.id;
  RETURN jsonb_build_object('order_id',operation.order_id,'operation',jsonb_build_object('action',operation.action,'status',p_result));
END;
$$;


--
-- Name: finish_marketplace_provisioning(uuid, uuid, text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_marketplace_provisioning(p_integration_id uuid, p_batch_id uuid, p_result text, p_actor_user_id uuid, p_provider_batch_id text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Provisioning backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF NOT FOUND OR integration.merchant_connection_id IS NULL OR integration.provisioning_claim_id IS DISTINCT FROM p_batch_id
    OR p_batch_id IS NULL THEN RAISE EXCEPTION 'Provisioning claim unavailable'; END IF;
  PERFORM public.marketplace_assert_actor(integration.site_id,p_actor_user_id,true);
  IF p_result IS NULL OR p_result NOT IN ('confirmed','failed','unknown','pending') THEN RAISE EXCEPTION 'Invalid provisioning result'; END IF;
  IF integration.provisioning_status<>'pending' THEN RETURN to_jsonb(integration); END IF;
  -- A later transport failure is not proof that an earlier unknown provider
  -- mutation did not happen. Only authoritative event/status reconciliation or
  -- explicit confirmation may resolve this durable uncertainty.
  IF integration.provisioning_result='unknown' AND p_result='failed' THEN RETURN to_jsonb(integration); END IF;
  IF p_provider_batch_id IS NOT NULL THEN
    IF integration.provider_batch_id IS NOT NULL AND integration.provider_batch_id<>p_provider_batch_id THEN
      RAISE EXCEPTION 'Provider batch identity is immutable';
    END IF;
    UPDATE public.marketplace_integrations SET provider_batch_id=p_provider_batch_id WHERE id=integration.id;
  END IF;
  IF p_result IN ('pending','unknown') THEN
    UPDATE public.marketplace_integrations SET provisioning_result=CASE
      WHEN provisioning_result='unknown' THEN 'unknown' ELSE p_result END WHERE id=integration.id;
    SELECT * INTO integration FROM public.marketplace_integrations WHERE id=integration.id;
    RETURN to_jsonb(integration);
  END IF;
  RETURN public.apply_marketplace_provisioning(integration.id,CASE WHEN p_result='failed' THEN 'failed'
    WHEN integration.provisioning_operation='activate' THEN 'active' ELSE 'revoked' END);
END;
$$;


--
-- Name: finish_marketplace_webhook_registration(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_marketplace_webhook_registration(p_claim_id uuid, p_result text, p_secret_ciphertext text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE registration public.marketplace_webhook_registrations;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Webhook backend required' USING ERRCODE='42501'; END IF;
  IF p_result IS NULL OR p_result NOT IN ('ready','unknown') THEN RAISE EXCEPTION 'Invalid webhook registration result'; END IF;
  SELECT * INTO registration FROM public.marketplace_webhook_registrations WHERE claim_id=p_claim_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Webhook registration unavailable'; END IF;
  IF registration.status='ready' THEN RETURN; END IF;
  IF p_result='ready' THEN
    IF p_secret_ciphertext IS NULL THEN RAISE EXCEPTION 'Encrypted webhook secret required'; END IF;
    INSERT INTO public.marketplace_provider_webhook_keys(app_client_id_hash,provider,environment,country,integration_id,event,secret_ciphertext)
    VALUES(registration.app_client_id_hash,registration.provider,registration.environment,registration.country,
      registration.integration_id,registration.event,p_secret_ciphertext) ON CONFLICT DO NOTHING;
  END IF;
  UPDATE public.marketplace_webhook_registrations SET status=p_result,finished_at=now() WHERE claim_id=registration.claim_id;
END;
$$;


--
-- Name: finish_marketplace_webhook_registration_app(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_marketplace_webhook_registration_app(p_claim_id uuid, p_result text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE lease public.marketplace_webhook_registration_apps;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Webhook backend required' USING ERRCODE='42501'; END IF;
  IF p_result IS NULL OR p_result NOT IN ('ready','unknown') THEN RAISE EXCEPTION 'Invalid webhook app result'; END IF;
  SELECT * INTO lease FROM public.marketplace_webhook_registration_apps WHERE claim_id=p_claim_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Webhook app claim unavailable'; END IF;
  IF lease.status<>'running' THEN RETURN; END IF;
  UPDATE public.marketplace_webhook_registration_apps SET status=p_result,updated_at=now() WHERE claim_id=p_claim_id;
END;
$$;


--
-- Name: finish_provider_webhook_event(text, text, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_provider_webhook_event(p_provider text, p_event_id text, p_claim_token uuid, p_status text, p_error_message text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF p_status NOT IN ('completed', 'failed') THEN
    RAISE EXCEPTION 'Invalid provider webhook terminal status';
  END IF;

  UPDATE private.provider_webhook_events
  SET
    status = p_status,
    claim_token = NULL,
    claim_expires_at = NULL,
    completed_at = CASE
      WHEN p_status = 'completed' THEN timezone('utc', now())
      ELSE NULL
    END,
    last_error = CASE
      WHEN p_status = 'failed' THEN left(p_error_message, 2000)
      ELSE NULL
    END,
    updated_at = timezone('utc', now())
  WHERE provider = p_provider
    AND event_id = p_event_id
    AND status = 'processing'
    AND claim_token = p_claim_token;

  RETURN FOUND;
END;
$$;


--
-- Name: finish_site_subscription_checkout(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_site_subscription_checkout(p_site_id uuid, p_token uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  DELETE FROM public.site_subscription_checkout_leases WHERE site_id=p_site_id AND token=p_token;
  RETURN FOUND;
END;
$$;


--
-- Name: finish_workflow_run_execution(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_status text, p_error_message text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF p_status NOT IN ('pending', 'completed', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid workflow run terminal status';
  END IF;

  UPDATE public.workflow_runs
  SET
    status = p_status,
    claim_token = NULL,
    claimed_at = NULL,
    claim_expires_at = NULL,
    completed_at = CASE
      WHEN p_status IN ('completed', 'failed', 'cancelled')
        THEN timezone('utc', now())
      ELSE NULL
    END,
    error_message = p_error_message,
    updated_at = timezone('utc', now())
  WHERE run_plan_id = p_run_plan_id
    AND status = 'in_progress'
    AND claim_token = p_claim_token;
  RETURN FOUND;
END;
$$;


--
-- Name: generate_task_serial_id(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_task_serial_id(site_uuid uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16716($1); END$_$;


--
-- Name: get_auth_user_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_auth_user_id() RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16717(); END$$;


--
-- Name: get_my_accessible_sites(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_accessible_sites() RETURNS SETOF public.sites
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_3927106(); END$$;


--
-- Name: get_my_site_capabilities(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_site_capabilities(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    SET row_security TO 'off'
    AS $$
DECLARE
  r text;
  can_select boolean;
  can_insert boolean;
  can_update boolean;
  can_delete boolean;
BEGIN
  r := public.current_user_site_role(p_site_id);
  can_select := public.user_can(p_site_id, 'select');
  can_insert := public.user_can(p_site_id, 'insert');
  can_update := public.user_can(p_site_id, 'update');
  can_delete := public.user_can(p_site_id, 'delete');

  RETURN jsonb_build_object(
    'role', to_jsonb(r),
    'is_owner', coalesce(r = 'owner', false),
    'select', can_select,
    'insert', can_insert,
    'update', can_update,
    'delete', can_delete,
    'can_select', can_select,
    'can_insert', can_insert,
    'can_update', can_update,
    'can_delete', can_delete
  );
END;
$$;


--
-- Name: get_my_site_members(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_site_members(p_site_id uuid) RETURNS SETOF public.site_members
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_3880809($1); END$_$;


--
-- Name: get_performance_status(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_performance_status(command_id uuid) RETURNS TABLE(has_like boolean, has_dislike boolean, has_flag boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_16718($1); END$_$;

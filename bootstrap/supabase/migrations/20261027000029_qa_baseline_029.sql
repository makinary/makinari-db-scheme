SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: current_user_platform_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_user_platform_role() RETURNS text
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4106481(); END$$;


--
-- Name: current_user_site_role(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_user_site_role(p_site_id uuid) RETURNS text
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
DECLARE member_role text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NULL) THEN RETURN NULL; END IF;
  IF EXISTS (SELECT 1 FROM public.sites WHERE id = p_site_id AND user_id = auth.uid()) THEN RETURN 'owner'; END IF;
  SELECT sm.role::text INTO member_role FROM public.site_members sm
    WHERE sm.site_id = p_site_id AND sm.user_id = auth.uid() AND sm.status = 'active' AND public.site_member_has_effective_license(sm.id) LIMIT 1;
  IF member_role IS NULL THEN RETURN NULL; END IF;
  IF EXISTS (SELECT 1 FROM public.site_ownership WHERE site_id = p_site_id AND user_id = auth.uid()) THEN RETURN 'owner'; END IF;
  RETURN member_role;
END;
$$;


--
-- Name: debug_increment_visitor_sessions(uuid, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.debug_increment_visitor_sessions(p_visitor_id uuid, p_last_seen_timestamp bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16707($1,$2); END$_$;


--
-- Name: decrypt_token(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.decrypt_token(encrypted_value text, encryption_key text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16708($1,$2); END$_$;


--
-- Name: deduct_balance(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deduct_balance(p_site_id uuid, p_amount numeric) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_balance numeric;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be greater than zero';
  END IF;

  UPDATE public.billing
  SET account_balance = account_balance - p_amount,
      updated_at = now()
  WHERE site_id = p_site_id
    AND coalesce(account_balance, 0) >= p_amount
  RETURNING account_balance INTO v_balance;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Billing record not found or insufficient balance';
  END IF;

  RETURN v_balance;
END;
$$;


--
-- Name: deduct_credits(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deduct_credits(p_site_id uuid, p_credits numeric) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; v_regular numeric; v_balance numeric; v_result jsonb;
BEGIN
  IF p_credits IS NULL OR p_credits <= 0 OR p_credits::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Invalid credit deduction'; END IF;
  PERFORM public.renew_site_plan_credits(p_site_id);
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing record not found for site'; END IF;
  IF b.credits_available + coalesce(b.account_balance,0) < p_credits THEN RAISE EXCEPTION 'Insufficient total usable credits'; END IF;
  v_regular := least(b.credits_available,p_credits);
  v_balance := p_credits - v_regular;
  IF v_regular > 0 THEN
    v_result := public.deduct_credits(p_site_id,v_regular,'credit_usage','Regular credit usage','{}'::jsonb);
    IF NOT coalesce((v_result->>'success')::boolean,false) THEN RAISE EXCEPTION 'Regular credit deduction failed'; END IF;
  END IF;
  IF v_balance > 0 THEN
    UPDATE public.billing SET account_balance = account_balance - v_balance,
      credits_used = coalesce(credits_used,0) + v_balance,monthly_credits_used = monthly_credits_used + v_balance WHERE id = b.id;
  END IF;
  RETURN b.credits_available - v_regular;
END;
$$;


--
-- Name: deduct_credits(uuid, numeric, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deduct_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; v_trial numeric; v_plan numeric; v_legacy numeric; v_purchase numeric;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount::text IN ('NaN','Infinity','-Infinity')
    OR jsonb_typeof(p_metadata) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Invalid credit deduction'; END IF;
  -- Lazy renewal prevents stale included credits being spent before a daily job.
  PERFORM public.renew_site_plan_credits(p_site_id);
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'error','Billing record not found'); END IF;
  IF b.credits_available < p_amount THEN
    RETURN jsonb_build_object('success',false,'error','Insufficient credits','available',b.credits_available,'required',p_amount);
  END IF;
  v_trial := least(b.trial_credits_available,p_amount);
  v_plan := least(b.plan_credits_available,p_amount - v_trial);
  v_legacy := least(b.legacy_credits_available,p_amount - v_trial - v_plan);
  v_purchase := p_amount - v_trial - v_plan - v_legacy;
  UPDATE public.billing SET trial_credits_available = trial_credits_available - v_trial,
    plan_credits_available = plan_credits_available - v_plan,
    legacy_credits_available = legacy_credits_available - v_legacy,
    purchased_credits_available = purchased_credits_available - v_purchase,
    credits_available = credits_available - p_amount,credits_used = coalesce(credits_used,0) + p_amount,
    monthly_credits_used = monthly_credits_used + p_amount,plan_credits_used = plan_credits_used + v_plan WHERE id = b.id;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES (p_site_id,-p_amount,p_type,p_description,p_metadata || jsonb_build_object(
      'trial_credits_spent',v_trial,'plan_credits_spent',v_plan,'legacy_credits_spent',v_legacy,'purchased_credits_spent',v_purchase));
  RETURN jsonb_build_object('success',true,'remaining',b.credits_available - p_amount);
END;
$$;


--
-- Name: delete_command_cascade(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_command_cascade(command_uuid uuid) RETURNS json
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    deleted_counts JSON;
    temp_count INTEGER;
BEGIN
    -- Inicializar el objeto JSON de conteos
    deleted_counts := '{}';
    
    -- Borrar de agent_assets
    DELETE FROM agent_assets WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{agent_assets}', temp_count::text::jsonb);
    
    -- Borrar de agent_memories
    DELETE FROM agent_memories WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{agent_memories}', temp_count::text::jsonb);
    
    -- Borrar de agents
    DELETE FROM agents WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{agents}', temp_count::text::jsonb);
    
    -- Borrar de analysis
    DELETE FROM analysis WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{analysis}', temp_count::text::jsonb);
    
    -- Borrar de assets
    DELETE FROM assets WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{assets}', temp_count::text::jsonb);
    
    -- Borrar de billing
    DELETE FROM billing WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{billing}', temp_count::text::jsonb);
    
    -- Borrar de campaign_requirements
    DELETE FROM campaign_requirements WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaign_requirements}', temp_count::text::jsonb);
    
    -- Borrar de campaign_segments
    DELETE FROM campaign_segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaign_segments}', temp_count::text::jsonb);
    
    -- Borrar de campaign_subtasks
    DELETE FROM campaign_subtasks WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaign_subtasks}', temp_count::text::jsonb);
    
    -- Borrar de campaigns
    DELETE FROM campaigns WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaigns}', temp_count::text::jsonb);
    
    -- Borrar de content
    DELETE FROM content WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{content}', temp_count::text::jsonb);
    
    -- Borrar de conversations
    DELETE FROM conversations WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{conversations}', temp_count::text::jsonb);
    
    -- Borrar de debug_logs
    DELETE FROM debug_logs WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{debug_logs}', temp_count::text::jsonb);
    
    -- Borrar de experiment_segments
    DELETE FROM experiment_segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{experiment_segments}', temp_count::text::jsonb);
    
    -- Borrar de experiments
    DELETE FROM experiments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{experiments}', temp_count::text::jsonb);
    
    -- Borrar de external_resources
    DELETE FROM external_resources WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{external_resources}', temp_count::text::jsonb);
    
    -- Borrar de kpis
    DELETE FROM kpis WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{kpis}', temp_count::text::jsonb);
    
    -- Borrar de leads
    DELETE FROM leads WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{leads}', temp_count::text::jsonb);
    
    -- Borrar de messages
    DELETE FROM messages WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{messages}', temp_count::text::jsonb);
    
    -- Borrar de notifications
    DELETE FROM notifications WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{notifications}', temp_count::text::jsonb);
    
    -- Borrar de payments
    DELETE FROM payments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{payments}', temp_count::text::jsonb);
    
    -- Borrar de profiles
    DELETE FROM profiles WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{profiles}', temp_count::text::jsonb);
    
    -- Borrar de requirement_segments
    DELETE FROM requirement_segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{requirement_segments}', temp_count::text::jsonb);
    
    -- Borrar de requirements
    DELETE FROM requirements WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{requirements}', temp_count::text::jsonb);
    
    -- Borrar de sales
    DELETE FROM sales WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{sales}', temp_count::text::jsonb);
    
    -- Borrar de segments
    DELETE FROM segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{segments}', temp_count::text::jsonb);
    
    -- Borrar de session_events
    DELETE FROM session_events WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{session_events}', temp_count::text::jsonb);
    
    -- Borrar de settings
    DELETE FROM settings WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{settings}', temp_count::text::jsonb);
    
    -- Borrar de sites
    DELETE FROM sites WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{sites}', temp_count::text::jsonb);
    
    -- Borrar de tasks
    DELETE FROM tasks WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{tasks}', temp_count::text::jsonb);
    
    -- Borrar de transactions
    DELETE FROM transactions WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{transactions}', temp_count::text::jsonb);
    
    -- Borrar de visitor_sessions
    DELETE FROM visitor_sessions WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{visitor_sessions}', temp_count::text::jsonb);
    
    -- Borrar de visitors
    DELETE FROM visitors WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{visitors}', temp_count::text::jsonb);
    
    -- Finalmente, borrar el command
    DELETE FROM commands WHERE id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{commands}', temp_count::text::jsonb);
    
    RETURN deleted_counts;
END;
$$;


--
-- Name: delete_command_simple(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_command_simple(command_uuid uuid) RETURNS boolean
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    result JSON;
BEGIN
    SELECT delete_command_cascade(command_uuid) INTO result;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al borrar command %: %', command_uuid, SQLERRM;
        RETURN FALSE;
END;
$$;


--
-- Name: delete_instance_logs_batch(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_instance_logs_batch(p_instance_id uuid, p_limit integer) RETURNS bigint
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  n bigint;
BEGIN
  IF p_limit IS NULL OR p_limit < 1 THEN
    RAISE EXCEPTION 'p_limit must be >= 1';
  END IF;

  DELETE FROM public.instance_logs
  WHERE id IN (
    SELECT id
    FROM public.instance_logs
    WHERE instance_id = p_instance_id
    LIMIT p_limit
  );

  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END;
$$;


--
-- Name: delete_robot_instance_with_requirements(uuid, uuid[], text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_robot_instance_with_requirements(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4272425($1,$2,$3,$4,$5); END$_$;


--
-- Name: delete_secure_token(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_secure_token(p_site_id uuid, p_token_type text, p_identifier text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16711($1,$2,$3); END$_$;


--
-- Name: delete_site_safely(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_site_safely(site_id_param uuid) RETURNS boolean
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  RAISE EXCEPTION 'Site deletion is disabled. Archive the site from Settings with password verification.'
    USING ERRCODE = '0A000';
END;
$$;


--
-- Name: dispatch_harness_model_reservation(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dispatch_harness_model_reservation(p_session_id uuid, p_event_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_model_credit_reservations%ROWTYPE;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended('harness-model:'||p_session_id,0));
  SELECT * INTO r FROM public.harness_model_credit_reservations WHERE session_id=p_session_id AND event_id=p_event_id FOR UPDATE;
  IF NOT FOUND OR r.state NOT IN ('reserved','dispatched') THEN RETURN jsonb_build_object('success',false); END IF;
  UPDATE public.harness_model_credit_reservations SET state='dispatched' WHERE session_id=p_session_id AND event_id=p_event_id;
  RETURN jsonb_build_object('success',true);
END;
$$;


--
-- Name: dispatch_image_generation_reservation(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dispatch_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.image_generation_credit_reservations%ROWTYPE;
BEGIN
  PERFORM 1 FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  SELECT * INTO r FROM public.image_generation_credit_reservations WHERE site_id=p_site_id AND operation_id=p_operation_id FOR UPDATE;
  IF NOT FOUND OR r.dispatch_token IS DISTINCT FROM p_token OR r.state<>'reserved' THEN
    RETURN jsonb_build_object('success',false,'code','DISPATCH_NOT_CLAIMED'); END IF;
  UPDATE public.image_generation_credit_reservations SET state='dispatched',dispatched_at=clock_timestamp()
    WHERE site_id=p_site_id AND operation_id=p_operation_id;
  RETURN jsonb_build_object('success',true,'state','dispatched');
END $$;

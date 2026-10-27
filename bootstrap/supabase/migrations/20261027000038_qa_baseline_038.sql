SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: handle_campaign_deletion_orphans_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_campaign_deletion_orphans_only() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RAISE NOTICE 'Deleting campaign: % - %', OLD.id, OLD.title;
    
    -- Guardamos los requirement_ids que están asociados a esta campaña
    -- antes de eliminar las relaciones
    CREATE TEMP TABLE temp_campaign_requirements AS
    SELECT requirement_id 
    FROM public.campaign_requirements 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar las relaciones en campaign_requirements
    DELETE FROM public.campaign_requirements 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar solo los requirements que quedaron huérfanos
    -- (que no tienen ninguna otra campaña asociada)
    DELETE FROM public.requirements 
    WHERE id IN (
        SELECT tcr.requirement_id 
        FROM temp_campaign_requirements tcr
        LEFT JOIN public.campaign_requirements cr ON tcr.requirement_id = cr.requirement_id
        WHERE cr.requirement_id IS NULL
    );
    
    -- Limpiar tabla temporal
    DROP TABLE temp_campaign_requirements;
    
    -- Eliminar otros elementos relacionados
    DELETE FROM public.campaign_subtasks WHERE campaign_id = OLD.id;
    DELETE FROM public.campaign_segments WHERE campaign_id = OLD.id;
    DELETE FROM public.transactions WHERE campaign_id = OLD.id;
    
    RAISE NOTICE 'Campaign deletion completed for: %', OLD.id;
    
    RETURN OLD;
END;
$$;


--
-- Name: handle_command_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_command_insert() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    -- Ensure created_at and updated_at are set
    NEW.created_at = COALESCE(NEW.created_at, NOW());
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$;


--
-- Name: handle_command_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_command_update() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    -- Update the updated_at timestamp
    NEW.updated_at = NOW();
    
    -- If status is changing to completed/failed, set completion_date
    IF (OLD.status <> 'completed' AND OLD.status <> 'failed') AND 
       (NEW.status = 'completed' OR NEW.status = 'failed') THEN
        NEW.completion_date = NOW();
        
        -- Calculate duration if not provided
        IF NEW.duration IS NULL THEN
            NEW.duration = EXTRACT(EPOCH FROM (NOW() - OLD.created_at)) * 1000;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: handle_event_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_event_insert() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    -- Set created_at and updated_at timestamps
    NEW.created_at = COALESCE(NEW.created_at, NOW());
    NEW.updated_at = NOW();
    
    -- Ensure data is a valid JSONB
    IF NEW.data IS NULL THEN
        NEW.data = '{}'::jsonb;
    END IF;
    
    -- Ensure properties is a valid JSONB
    IF NEW.properties IS NULL THEN
        NEW.properties = '{}'::jsonb;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  referral_code_value TEXT;
  user_name TEXT;
BEGIN
  -- Extraer valores de metadatos de forma segura
  BEGIN
    referral_code_value := NEW.raw_user_meta_data ->> 'referral_code';
    user_name := NEW.raw_user_meta_data ->> 'name';
  EXCEPTION WHEN OTHERS THEN
    referral_code_value := NULL;
    user_name := NEW.email;
  END;
  
  -- Crear perfil de usuario
  BEGIN
    INSERT INTO public.profiles (
      id,
      email,
      name,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      COALESCE(user_name, NEW.email),
      NOW(),
      NOW()
    );
  EXCEPTION WHEN OTHERS THEN
    -- Si falla la creación del perfil, continuar
    NULL;
  END;
  
  -- Procesar código de referido si existe
  IF referral_code_value IS NOT NULL AND referral_code_value != '' THEN
    BEGIN
      PERFORM register_referral_code_use(referral_code_value, NEW.id);
    EXCEPTION WHEN OTHERS THEN
      -- Si falla el procesamiento del código, continuar
      NULL;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: handle_new_user_debug(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user_debug() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  referral_code_value TEXT;
  validation_result BOOLEAN;
  registration_result BOOLEAN;
BEGIN
  PERFORM log_debug('=== INICIO handle_new_user_debug ===');
  PERFORM log_debug('Usuario ID: ' || NEW.id::TEXT);
  PERFORM log_debug('Email: ' || NEW.email);
  PERFORM log_debug('Metadatos completos: ' || COALESCE(NEW.raw_user_meta_data::TEXT, 'NULL'));
  
  -- Extraer código de referido
  referral_code_value := NEW.raw_user_meta_data->>'referral_code';
  PERFORM log_debug('Código extraído: ' || COALESCE(referral_code_value, 'NULL'));
  PERFORM log_debug('Longitud del código: ' || COALESCE(LENGTH(referral_code_value)::TEXT, 'NULL'));
  
  BEGIN
    -- Crear perfil
    PERFORM log_debug('Creando perfil...');
    INSERT INTO public.profiles (
      id,
      email,
      name,
      avatar_url,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
      NEW.raw_user_meta_data->>'avatar_url',
      NOW(),
      NOW()
    );
    PERFORM log_debug('✅ Perfil creado exitosamente');
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_debug('❌ Error creando perfil: ' || SQLERRM);
  END;
  
  -- Procesar código de referido si existe
  IF referral_code_value IS NOT NULL AND referral_code_value != '' THEN
    PERFORM log_debug('Procesando código de referido: ' || referral_code_value);
    
    -- Validar código
    BEGIN
      SELECT validate_referral_code(referral_code_value) INTO validation_result;
      PERFORM log_debug('Resultado validación: ' || validation_result::TEXT);
      
      IF validation_result THEN
        -- Registrar uso
        PERFORM log_debug('Registrando uso del código...');
        SELECT register_referral_code_use(referral_code_value, NEW.id) INTO registration_result;
        PERFORM log_debug('Resultado registro: ' || registration_result::TEXT);
        
        IF registration_result THEN
          PERFORM log_debug('✅ Código de referido procesado exitosamente');
        ELSE
          PERFORM log_debug('❌ Falló el registro del código');
        END IF;
      ELSE
        PERFORM log_debug('❌ Código de referido inválido');
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      PERFORM log_debug('❌ Error procesando código de referido: ' || SQLERRM);
    END;
  ELSE
    PERFORM log_debug('No hay código de referido para procesar');
  END IF;
  
  PERFORM log_debug('=== FIN handle_new_user_debug ===');
  RETURN NEW;
END;
$$;


--
-- Name: handle_new_user_simple(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user_simple() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  referral_code_value TEXT;
BEGIN
  -- Solo procesar referral codes, sin crear perfil
  referral_code_value := NEW.raw_user_meta_data->>'referral_code';
  
  IF referral_code_value IS NOT NULL AND referral_code_value != '' THEN
    -- Registrar en una tabla de log para verificar que funciona
    INSERT INTO public.debug_logs (operation, user_id, details)
    VALUES (
      'referral_trigger_test',
      NEW.id,
      jsonb_build_object(
        'referral_code', referral_code_value,
        'email', NEW.email,
        'timestamp', NOW()
      )
    ) ON CONFLICT DO NOTHING;
    
    -- Intentar registrar el código
    PERFORM public.register_referral_code_use(referral_code_value, NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: handle_session_active_state(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_session_active_state() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF NEW.closed_at IS NOT NULL THEN
    NEW.is_active = FALSE;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: handle_session_events_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_session_events_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: handle_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: has_requirement_scope_authorization(uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_requirement_scope_authorization(p_requirement_id uuid, p_completed_at timestamp with time zone) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT p_requirement_id IS NOT NULL AND p_completed_at IS NOT NULL AND isfinite(p_completed_at)
    AND EXISTS (
      SELECT 1 FROM public.requirement_user_action_receipts receipt
      LEFT JOIN public.requirement_commands command
        ON command.requirement_id = receipt.requirement_id AND command.action_id = receipt.action_id
      WHERE receipt.requirement_id = p_requirement_id
        AND ((command.action_id IS NULL AND receipt.action_created_at >= p_completed_at)
          OR (command.applied_at IS NOT NULL AND command.applied_at >= p_completed_at))
    );
$$;


--
-- Name: hold_harness_model_credits(uuid, uuid, uuid, numeric, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hold_harness_model_credits(p_session_id uuid, p_site_id uuid, p_event_id uuid, p_amount numeric, p_requirement_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE b public.billing%ROWTYPE; r public.harness_model_credit_reservations%ROWTYPE;
  v_trial numeric; v_plan numeric; v_legacy numeric; v_purchase numeric;
BEGIN
  IF p_session_id IS NULL OR p_site_id IS NULL OR p_event_id IS NULL OR p_amount IS NULL OR p_amount<=0 OR p_amount>1000
    OR p_amount::text IN ('NaN','Infinity','-Infinity') THEN RAISE EXCEPTION 'Invalid model reservation'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('harness-model:'||p_session_id,0));
  PERFORM public.renew_site_plan_credits(p_site_id);
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false); END IF;
  SELECT * INTO r FROM public.harness_model_credit_reservations WHERE session_id=p_session_id AND event_id=p_event_id;
  IF FOUND THEN
    IF r.site_id<>p_site_id OR r.requirement_id IS DISTINCT FROM p_requirement_id OR r.amount<>p_amount THEN
      RAISE EXCEPTION 'Model reservation identity conflict'; END IF;
    RETURN jsonb_build_object('success',true,'state',r.state);
  END IF;
  IF EXISTS(SELECT 1 FROM public.harness_model_credit_reservations WHERE (session_id=p_session_id
    OR (p_requirement_id IS NOT NULL AND requirement_id=p_requirement_id)) AND state IN ('reserved','dispatched','pending')) THEN
    RETURN jsonb_build_object('success',false,'error','Prior model outcome requires reconciliation'); END IF;
  IF b.credits_available<p_amount THEN RETURN jsonb_build_object('success',false,'error','Insufficient credits'); END IF;
  v_trial:=least(b.trial_credits_available,p_amount);
  v_plan:=least(b.plan_credits_available,p_amount-v_trial);
  v_legacy:=least(b.legacy_credits_available,p_amount-v_trial-v_plan);
  v_purchase:=p_amount-v_trial-v_plan-v_legacy;
  UPDATE public.billing SET trial_credits_available=trial_credits_available-v_trial,
    plan_credits_available=plan_credits_available-v_plan,
    legacy_credits_available=legacy_credits_available-v_legacy,purchased_credits_available=purchased_credits_available-v_purchase,
    credits_available=credits_available-p_amount,credits_used=coalesce(credits_used,0)+p_amount,
    monthly_credits_used=monthly_credits_used+p_amount,plan_credits_used=plan_credits_used+v_plan WHERE id=b.id;
  INSERT INTO public.harness_model_credit_reservations(session_id,event_id,site_id,requirement_id,amount,
    plan_spent,legacy_spent,purchased_spent,period_start,period_end,trial_spent,trial_ends_at)
    VALUES(p_session_id,p_event_id,p_site_id,p_requirement_id,p_amount,v_plan,v_legacy,v_purchase,b.plan_credit_period_start,b.plan_credit_period_end,v_trial,b.trial_ends_at);
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES(p_site_id,-p_amount,'agent_model_reservation','OpenRouter admission hold (not final price)',jsonb_build_object(
      'session_id',p_session_id,'event_id',p_event_id,'requirement_id',p_requirement_id,
      'trial_credits_spent',v_trial,'plan_credits_spent',v_plan,'legacy_credits_spent',v_legacy,'purchased_credits_spent',v_purchase));
  RETURN jsonb_build_object('success',true,'state','reserved');
END;
$$;


--
-- Name: hold_image_generation_credits(uuid, text, text, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hold_image_generation_credits(p_site_id uuid, p_operation_id text, p_request_hash text, p_token uuid, p_count integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE b public.billing%ROWTYPE; r public.image_generation_credit_reservations%ROWTYPE;
  v_amount numeric; v_trial numeric; v_plan numeric; v_legacy numeric; v_purchase numeric;
BEGIN
  IF p_site_id IS NULL OR p_operation_id IS NULL OR p_operation_id !~ '^[a-f0-9]{64}$'
    OR p_request_hash IS NULL OR p_request_hash !~ '^[a-f0-9]{64}$' OR p_token IS NULL
    OR p_count IS NULL OR p_count NOT BETWEEN 1 AND 4 THEN RAISE EXCEPTION 'Invalid image reservation'; END IF;
  -- Shared renewal expires trial and renews only the current monthly annual window.
  PERFORM public.renew_site_plan_credits(p_site_id);
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'code','BILLING_UNAVAILABLE'); END IF;
  SELECT * INTO r FROM public.image_generation_credit_reservations WHERE site_id=p_site_id AND operation_id=p_operation_id;
  IF FOUND THEN
    IF r.request_hash<>p_request_hash OR r.requested_count<>p_count THEN
      RETURN jsonb_build_object('success',false,'code','IDEMPOTENCY_CONFLICT'); END IF;
    -- Even an undispatched hold is not a new authorization after a lost response.
    RETURN jsonb_build_object('success',true,'created',false,'state',r.state);
  END IF;
  v_amount:=p_count*0.1;
  IF b.credits_available<>b.trial_credits_available+b.plan_credits_available+b.legacy_credits_available+b.purchased_credits_available THEN
    RAISE EXCEPTION 'Image credit bucket aggregate mismatch'; END IF;
  IF b.credits_available<v_amount THEN RETURN jsonb_build_object('success',false,'code','INSUFFICIENT_CREDITS'); END IF;
  v_trial:=least(b.trial_credits_available,v_amount);
  v_plan:=least(b.plan_credits_available,v_amount-v_trial);
  v_legacy:=least(b.legacy_credits_available,v_amount-v_trial-v_plan);
  v_purchase:=v_amount-v_trial-v_plan-v_legacy;
  UPDATE public.billing SET trial_credits_available=trial_credits_available-v_trial,
    plan_credits_available=plan_credits_available-v_plan,legacy_credits_available=legacy_credits_available-v_legacy,
    purchased_credits_available=purchased_credits_available-v_purchase,credits_available=credits_available-v_amount,
    credits_used=coalesce(credits_used,0)+v_amount,monthly_credits_used=monthly_credits_used+v_amount,
    plan_credits_used=plan_credits_used+v_plan WHERE id=b.id;
  INSERT INTO public.image_generation_credit_reservations(site_id,operation_id,request_hash,dispatch_token,requested_count,
    amount,trial_spent,plan_spent,legacy_spent,purchased_spent,trial_started_at,trial_ends_at,period_start,period_end)
    VALUES(p_site_id,p_operation_id,p_request_hash,p_token,p_count,v_amount,v_trial,v_plan,v_legacy,v_purchase,
      b.trial_started_at,b.trial_ends_at,b.plan_credit_period_start,b.plan_credit_period_end);
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES(p_site_id,-v_amount,'image_generation_hold','Image generation admission hold',jsonb_build_object(
      'operation_id',p_operation_id,'requested_count',p_count,'trial_spent',v_trial,'plan_spent',v_plan,
      'legacy_spent',v_legacy,'purchased_spent',v_purchase));
  RETURN jsonb_build_object('success',true,'created',true,'state','reserved');
END $_$;

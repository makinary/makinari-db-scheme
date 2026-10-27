SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: original_16750(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16750(p_referral_code_id uuid, p_user_id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_use_record RECORD;
    v_result JSON;
BEGIN
    -- Insert the referral code use record
    INSERT INTO public.referral_code_uses (referral_code_id, user_id, used_at)
    VALUES (p_referral_code_id, p_user_id, NOW())
    RETURNING * INTO v_use_record;
    
    -- Increment the current_uses counter
    UPDATE public.referral_codes 
    SET current_uses = current_uses + 1
    WHERE id = p_referral_code_id;
    
    -- Return the created record as JSON
    SELECT json_build_object(
        'id', v_use_record.id,
        'referral_code_id', v_use_record.referral_code_id,
        'user_id', v_use_record.user_id,
        'used_at', v_use_record.used_at
    ) INTO v_result;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error and re-raise
        RAISE EXCEPTION 'Error processing referral code use: %', SQLERRM;
END;
$$;


--
-- Name: original_16751(uuid, character varying, numeric, character varying, character varying, jsonb, integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16751(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying DEFAULT 'success'::character varying, p_payment_method character varying DEFAULT 'credit_card'::character varying, p_details jsonb DEFAULT '{}'::jsonb, p_credits integer DEFAULT 0) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  -- Insert payment record
  INSERT INTO payments (
    site_id,
    transaction_type,
    amount,
    status,
    payment_method,
    details,
    credits
  ) VALUES (
    p_site_id,
    p_transaction_type,
    p_amount,
    p_status,
    p_payment_method,
    p_details,
    p_credits
  )
  RETURNING id INTO v_payment_id;
  
  -- Update credits in billing if successful payment
  IF p_status = 'success' AND p_credits > 0 THEN
    UPDATE billing
    SET credits_available = credits_available + p_credits
    WHERE site_id = p_site_id;
  END IF;
  
  RETURN v_payment_id;
END;
$$;


--
-- Name: original_16752(text, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16752(code_param text, user_id_param uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  referral_record RECORD;
  use_exists BOOLEAN;
  inserted_count INTEGER;
BEGIN
  -- Validar parámetros
  IF code_param IS NULL OR code_param = '' OR user_id_param IS NULL THEN
    RAISE NOTICE '❌ Parámetros inválidos: code=%, user_id=%', code_param, user_id_param;
    RETURN FALSE;
  END IF;
  
  -- Verificar si el código es válido
  IF NOT validate_referral_code(code_param) THEN
    RAISE NOTICE '❌ Código de referido inválido: %', code_param;
    RETURN FALSE;
  END IF;
  
  -- Obtener el registro del código de referido
  SELECT id, code, current_uses, max_uses INTO referral_record
  FROM public.referral_codes
  WHERE code = code_param AND is_active = true;
  
  IF NOT FOUND THEN
    RAISE NOTICE '❌ Código de referido no encontrado o inactivo: %', code_param;
    RETURN FALSE;
  END IF;
  
  -- Verificar si el usuario ya usó este código (con un SELECT FOR UPDATE para evitar race conditions)
  SELECT EXISTS(
    SELECT 1 FROM public.referral_code_uses 
    WHERE referral_code_id = referral_record.id AND user_id = user_id_param
    FOR UPDATE
  ) INTO use_exists;
  
  IF use_exists THEN
    RAISE NOTICE '⚠️ Usuario % ya usó el código %', user_id_param, code_param;
    RETURN FALSE;
  END IF;
  
  -- Intentar insertar el uso (esto fallará si ya existe debido a la constraint UNIQUE)
  BEGIN
    INSERT INTO public.referral_code_uses (referral_code_id, user_id)
    VALUES (referral_record.id, user_id_param);
    
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    IF inserted_count = 1 THEN
      -- Solo incrementar current_uses si realmente se insertó un nuevo registro
      UPDATE public.referral_codes
      SET current_uses = current_uses + 1,
          updated_at = NOW()
      WHERE id = referral_record.id;
      
      RAISE NOTICE '✅ Código de referido % usado exitosamente por usuario %', code_param, user_id_param;
      RETURN TRUE;
    ELSE
      RAISE NOTICE '⚠️ No se pudo insertar el uso del código %', code_param;
      RETURN FALSE;
    END IF;
    
  EXCEPTION 
    WHEN unique_violation THEN
      RAISE NOTICE '⚠️ Usuario % ya usó el código % (detectado por constraint)', user_id_param, code_param;
      RETURN FALSE;
    WHEN OTHERS THEN
      RAISE NOTICE '❌ Error registrando uso de código de referido: %', SQLERRM;
      RETURN FALSE;
  END;
END;
$$;


--
-- Name: original_16753(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16753() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'information_schema, public'
    AS $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT event_object_table, trigger_name
        FROM information_schema.triggers 
        WHERE trigger_name LIKE 'trigger_delete_protection_%'
        AND event_object_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', 
                      trigger_record.trigger_name, 
                      trigger_record.event_object_table);
        RAISE NOTICE 'Removed trigger from: %', trigger_record.event_object_table;
    END LOOP;
    
    RAISE NOTICE 'All delete protection triggers removed.';
END;
$$;


--
-- Name: original_16754(text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16754(p_table_name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'trigger_delete_protection_' || p_table_name;
    
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', trigger_name, p_table_name);
    
    RAISE NOTICE 'Removed delete protection trigger from table: %', p_table_name;
END;
$$;


--
-- Name: original_16758(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16758(command_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    UPDATE public.commands 
    SET performance = (performance & ~1) | 2  -- Quitar like y poner dislike
    WHERE id = command_id;
END;
$$;


--
-- Name: original_16759(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16759(command_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    UPDATE public.commands 
    SET performance = (performance & ~2) | 1  -- Quitar dislike y poner like
    WHERE id = command_id;
END;
$$;


--
-- Name: original_16764(uuid, text, text, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16764(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  encrypted_token TEXT;
  token_id UUID;
BEGIN
  -- Encrypt the token
  encrypted_token := encrypt_token(p_token_value, p_encryption_key);
  
  -- Insert or update the token
  INSERT INTO secure_tokens (site_id, token_type, encrypted_value, identifier, updated_at)
  VALUES (p_site_id, p_token_type, encrypted_token, p_identifier, NOW())
  ON CONFLICT (site_id, token_type, identifier)
  DO UPDATE SET 
    encrypted_value = encrypted_token,
    updated_at = NOW()
  RETURNING id INTO token_id;
  
  RETURN token_id;
END;
$$;


--
-- Name: original_16765(text, text, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16765(auth0_id_param text, email_param text, name_param text, picture_param text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Primero intentar encontrar un usuario existente en auth.users por email
  SELECT id INTO user_id FROM auth.users WHERE email = email_param;
  
  IF user_id IS NULL THEN
    -- Si no existe, crear nuevo usuario en auth.users
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      email_param,
      '',
      NOW(),
      '{"provider": "auth0", "providers": ["auth0"]}',
      jsonb_build_object(
        'name', name_param,
        'avatar_url', picture_param,
        'auth0_id', auth0_id_param
      ),
      NOW(),
      NOW(),
      '',
      '',
      '',
      ''
    )
    RETURNING id INTO user_id;
  END IF;

  -- Ahora intentar encontrar o crear el perfil
  INSERT INTO public.profiles (id, email, name, avatar_url, auth0_id)
  VALUES (
    user_id,
    email_param,
    name_param,
    picture_param,
    auth0_id_param
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = email_param,
    name = name_param,
    avatar_url = picture_param,
    auth0_id = auth0_id_param,
    updated_at = NOW();
  
  RETURN user_id;
END;
$$;


--
-- Name: original_16769(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16769(command_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    UPDATE public.commands 
    SET performance = performance ^ 4  -- Toggle flag bit
    WHERE id = command_id;
END;
$$;


--
-- Name: original_16784(uuid, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean, integer, text, timestamp without time zone); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16784(p_site_id uuid, p_plan text DEFAULT NULL::text, p_card_name text DEFAULT NULL::text, p_masked_card_number text DEFAULT NULL::text, p_card_expiry text DEFAULT NULL::text, p_stripe_customer_id text DEFAULT NULL::text, p_stripe_payment_method_id text DEFAULT NULL::text, p_stripe_subscription_id text DEFAULT NULL::text, p_card_address text DEFAULT NULL::text, p_card_city text DEFAULT NULL::text, p_card_postal_code text DEFAULT NULL::text, p_card_country text DEFAULT NULL::text, p_tax_id text DEFAULT NULL::text, p_billing_address text DEFAULT NULL::text, p_billing_city text DEFAULT NULL::text, p_billing_postal_code text DEFAULT NULL::text, p_billing_country text DEFAULT NULL::text, p_auto_renew boolean DEFAULT NULL::boolean, p_credits_available integer DEFAULT NULL::integer, p_subscription_status text DEFAULT NULL::text, p_subscription_current_period_end timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  billing_record billing%ROWTYPE;
BEGIN
  -- Verificar si existe registro de billing
  SELECT * INTO billing_record FROM billing WHERE site_id = p_site_id;
  
  IF FOUND THEN
    -- Actualizar registro existente
    UPDATE billing SET
      plan = COALESCE(p_plan, plan),
      card_name = COALESCE(p_card_name, card_name),
      masked_card_number = COALESCE(p_masked_card_number, masked_card_number),
      card_expiry = COALESCE(p_card_expiry, card_expiry),
      stripe_customer_id = COALESCE(p_stripe_customer_id, stripe_customer_id),
      stripe_payment_method_id = COALESCE(p_stripe_payment_method_id, stripe_payment_method_id),
      stripe_subscription_id = COALESCE(p_stripe_subscription_id, stripe_subscription_id),
      card_address = COALESCE(p_card_address, card_address),
      card_city = COALESCE(p_card_city, card_city),
      card_postal_code = COALESCE(p_card_postal_code, card_postal_code),
      card_country = COALESCE(p_card_country, card_country),
      tax_id = COALESCE(p_tax_id, tax_id),
      billing_address = COALESCE(p_billing_address, billing_address),
      billing_city = COALESCE(p_billing_city, billing_city),
      billing_postal_code = COALESCE(p_billing_postal_code, billing_postal_code),
      billing_country = COALESCE(p_billing_country, billing_country),
      auto_renew = COALESCE(p_auto_renew, auto_renew),
      credits_available = COALESCE(p_credits_available, credits_available),
      subscription_status = COALESCE(p_subscription_status, subscription_status),
      subscription_current_period_end = COALESCE(p_subscription_current_period_end, subscription_current_period_end),
      updated_at = NOW()
    WHERE site_id = p_site_id;
  ELSE
    -- Crear nuevo registro
    INSERT INTO billing (
      site_id,
      plan,
      card_name,
      masked_card_number,
      card_expiry,
      stripe_customer_id,
      stripe_payment_method_id,
      stripe_subscription_id,
      card_address,
      card_city,
      card_postal_code,
      card_country,
      tax_id,
      billing_address,
      billing_city,
      billing_postal_code,
      billing_country,
      auto_renew,
      credits_available,
      subscription_status,
      subscription_current_period_end,
      created_at,
      updated_at
    ) VALUES (
      p_site_id,
      COALESCE(p_plan, 'commission'),
      p_card_name,
      p_masked_card_number,
      p_card_expiry,
      p_stripe_customer_id,
      p_stripe_payment_method_id,
      p_stripe_subscription_id,
      p_card_address,
      p_card_city,
      p_card_postal_code,
      p_card_country,
      p_tax_id,
      p_billing_address,
      p_billing_city,
      p_billing_postal_code,
      p_billing_country,
      COALESCE(p_auto_renew, true),
      COALESCE(p_credits_available, 0),
      p_subscription_status,
      p_subscription_current_period_end,
      NOW(),
      NOW()
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Billing information updated successfully'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

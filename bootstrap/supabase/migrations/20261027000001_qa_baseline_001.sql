SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: original_16702(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16702() RETURNS TABLE(table_name text, trigger_name text, status text, performance_impact text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'information_schema, public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.event_object_table::TEXT,
        t.trigger_name::TEXT,
        CASE 
            WHEN t.trigger_name IS NOT NULL THEN 'PROTECTED'
            ELSE 'NOT PROTECTED'
        END::TEXT,
        CASE 
            WHEN t.trigger_name IS NOT NULL THEN 'MINIMAL (single function call)'
            ELSE 'N/A'
        END::TEXT
    FROM information_schema.tables tab
    LEFT JOIN information_schema.triggers t ON t.event_object_table = tab.table_name 
        AND t.trigger_name LIKE 'trigger_delete_protection_%'
        AND t.event_object_schema = 'public'
    WHERE tab.table_schema = 'public'
    AND tab.table_type = 'BASE TABLE'
    ORDER BY tab.table_name;
END;
$$;


--
-- Name: original_16704(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16704() RETURNS TABLE(table_name text, insert_trigger text, update_trigger text, delete_trigger text, status text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    table_names TEXT[] := ARRAY[
        'leads', 'campaigns', 'segments', 'experiments', 'sales',
        'agents', 'content', 'requirements', 'tasks', 'visitors',
        'visitor_sessions', 'messages', 'notifications'
    ];
    
    current_table TEXT;
    insert_trig TEXT;
    update_trig TEXT;
    delete_trig TEXT;
    status_msg TEXT;
    
BEGIN
    FOREACH current_table IN ARRAY table_names
    LOOP
        -- Check if triggers exist
        SELECT 
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_insert_permission_' || current_table
                AND event_object_table = current_table
            ) THEN '✅ Active' ELSE '❌ Missing' END,
            
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_update_permission_' || current_table
                AND event_object_table = current_table
            ) THEN '✅ Active' ELSE '❌ Missing' END,
            
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_delete_protection_' || current_table
                AND event_object_table = current_table
            ) THEN '✅ Active' ELSE '❌ Missing' END
        INTO insert_trig, update_trig, delete_trig;
        
        -- Determine overall status
        IF insert_trig = '✅ Active' AND update_trig = '✅ Active' AND delete_trig = '✅ Active' THEN
            status_msg := '✅ Fully Protected';
        ELSIF insert_trig = '✅ Active' AND update_trig = '✅ Active' THEN
            status_msg := '⚠️ CREATE/UPDATE Protected';
        ELSIF delete_trig = '✅ Active' THEN
            status_msg := '⚠️ DELETE Protected Only';
        ELSE
            status_msg := '❌ No Protection';
        END IF;
        
        RETURN QUERY SELECT current_table, insert_trig, update_trig, delete_trig, status_msg;
    END LOOP;
END;
$$;


--
-- Name: original_16707(uuid, bigint); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16707(p_visitor_id uuid, p_last_seen_timestamp bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    debug_info jsonb;
    current_role_setting text;
    current_user_id uuid;
    jwt_claims jsonb;
BEGIN
    -- Recopilar información de debug
    BEGIN
        current_role_setting := current_setting('role', true);
    EXCEPTION WHEN OTHERS THEN
        current_role_setting := 'ERROR_GETTING_ROLE';
    END;
    
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
    END;
    
    BEGIN
        jwt_claims := auth.jwt();
    EXCEPTION WHEN OTHERS THEN
        jwt_claims := NULL;
    END;
    
    debug_info := jsonb_build_object(
        'current_role_setting', current_role_setting,
        'current_user_id', current_user_id,
        'jwt_claims', jwt_claims,
        'session_user', session_user,
        'current_user', current_user,
        'is_service_role_function', public.is_service_role()
    );
    
    RETURN debug_info;
END;
$$;


--
-- Name: original_16708(text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16708(encrypted_value text, encryption_key text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  actual_key TEXT;
BEGIN
  -- Use provided key or fall back to an environment variable
  actual_key := COALESCE(encryption_key, current_setting('app.encryption_key', true));
  
  -- If no key is available, raise an exception
  IF actual_key IS NULL THEN
    RAISE EXCEPTION 'Encryption key is not available';
  END IF;
  
  -- Return decrypted value
  RETURN pgp_sym_decrypt(
    decode(encrypted_value, 'base64'),
    actual_key
  );
EXCEPTION
  WHEN others THEN
    RETURN NULL; -- Return NULL if decryption fails
END;
$$;


--
-- Name: original_16711(uuid, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16711(p_site_id uuid, p_token_type text, p_identifier text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  rows_affected INTEGER;
BEGIN
  DELETE FROM secure_tokens
  WHERE site_id = p_site_id
    AND token_type = p_token_type
    AND identifier = p_identifier
  RETURNING 1 INTO rows_affected;
  
  RETURN FOUND;
END;
$$;


--
-- Name: original_16713(text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16713(token_value text, encryption_key text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  actual_key TEXT;
BEGIN
  -- Use provided key or fall back to an environment variable
  actual_key := COALESCE(encryption_key, current_setting('app.encryption_key', true));
  
  -- If no key is available, raise an exception
  IF actual_key IS NULL THEN
    RAISE EXCEPTION 'Encryption key is not available';
  END IF;
  
  -- Return encrypted value using pgcrypto
  RETURN encode(
    pgp_sym_encrypt(
      token_value, 
      actual_key
    ),
    'base64'
  );
END;
$$;


--
-- Name: original_16716(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16716(site_uuid uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
    site_prefix text;
    max_serial_num integer;
    new_serial_id text;
    attempt_count integer := 0;
    max_attempts integer := 10;
BEGIN
    -- Get site name to create prefix (first 3 characters, uppercase)
    SELECT UPPER(LEFT(COALESCE(name, 'TSK'), 3))
    INTO site_prefix
    FROM public.sites
    WHERE id = site_uuid;
    
    -- If site not found, use default prefix
    IF site_prefix IS NULL THEN
        site_prefix := 'TSK';
    END IF;
    
    -- Loop to handle race conditions
    LOOP
        -- Get the maximum serial number for this site prefix
        SELECT COALESCE(MAX(
            CASE 
                WHEN t.serial_id ~ ('^' || site_prefix || '-[0-9]+$') 
                THEN CAST(SPLIT_PART(t.serial_id, '-', 2) AS INTEGER)
                ELSE 0
            END
        ), 0) + 1
        INTO max_serial_num
        FROM public.tasks t
        WHERE t.site_id = site_uuid
        AND t.serial_id LIKE (site_prefix || '-%');
        
        -- Generate serial_id with format: PREFIX-NNNN
        new_serial_id := site_prefix || '-' || LPAD(max_serial_num::text, 4, '0');
        
        -- Check if this serial_id already exists
        IF NOT EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.site_id = site_uuid 
            AND t.serial_id = new_serial_id
        ) THEN
            -- Serial ID is unique, we can use it
            RETURN new_serial_id;
        END IF;
        
        -- Increment attempt counter
        attempt_count := attempt_count + 1;
        
        -- If we've tried too many times, add a random suffix
        IF attempt_count >= max_attempts THEN
            new_serial_id := site_prefix || '-' || LPAD(max_serial_num::text, 4, '0') || '-' || EXTRACT(EPOCH FROM clock_timestamp())::bigint;
            RETURN new_serial_id;
        END IF;
        
        -- Small delay to reduce contention
        PERFORM pg_sleep(0.001 * attempt_count);
    END LOOP;
END;
$_$;


--
-- Name: original_16717(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16717() RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  auth0_sub TEXT;
  user_id UUID;
BEGIN
  -- Intentar obtener el sub claim del token JWT
  BEGIN
    auth0_sub := current_setting('request.jwt.claims', true)::json->>'sub';
  EXCEPTION
    WHEN others THEN
      auth0_sub := NULL;
  END;
  
  -- Si no hay token o no tiene sub, intentar usar auth.uid() por compatibilidad
  IF auth0_sub IS NULL THEN
    RETURN auth.uid();
  END IF;
  
  -- Buscar el perfil correspondiente al ID de Auth0
  SELECT id INTO user_id FROM public.profiles WHERE auth0_id = auth0_sub;
  RETURN user_id;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;


--
-- Name: original_16718(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16718(command_id uuid) RETURNS TABLE(has_like boolean, has_dislike boolean, has_flag boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (performance & 1) = 1 AS has_like,
        (performance & 2) = 2 AS has_dislike,
        (performance & 4) = 4 AS has_flag
    FROM public.commands
    WHERE id = command_id;
END;
$$;


--
-- Name: original_16719(uuid, text, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16719(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  token_record RECORD;
  decrypted_value TEXT;
BEGIN
  -- Get the encrypted token
  SELECT * INTO token_record
  FROM secure_tokens
  WHERE site_id = p_site_id
    AND token_type = p_token_type
    AND identifier = p_identifier;
    
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  
  -- Decrypt the token
  decrypted_value := decrypt_token(token_record.encrypted_value, p_encryption_key);
  
  -- Update last_used timestamp
  UPDATE secure_tokens
  SET last_used = NOW()
  WHERE id = token_record.id;
  
  RETURN decrypted_value;
END;
$$;


--
-- Name: original_16720(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16720(user_id_param uuid) RETURNS TABLE(id uuid, email text, name text, avatar_url text, bio text, role text, language text, timezone text, notifications jsonb, settings jsonb, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.email,
    p.name,
    p.avatar_url,
    p.bio,
    p.role,
    p.language,
    p.timezone,
    p.notifications,
    p.settings,
    p.created_at,
    p.updated_at
  FROM public.profiles p
  WHERE p.id = user_id_param;
END;
$$;


--
-- Name: original_16737(uuid, bigint); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16737(visitor_id uuid, last_seen_timestamp bigint) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    -- Deshabilitar el trigger específico temporalmente
    ALTER TABLE public.visitors DISABLE TRIGGER trigger_update_permission_visitors;
    
    -- Realizar la actualización
    UPDATE public.visitors 
    SET 
        total_sessions = COALESCE(total_sessions, 0) + 1,
        last_seen_at = last_seen_timestamp,
        updated_at = NOW()
    WHERE id = visitor_id;
    
    -- Reactivar el trigger
    ALTER TABLE public.visitors ENABLE TRIGGER trigger_update_permission_visitors;
    
    -- Verificar si se actualizó alguna fila
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Visitor with ID % not found', visitor_id;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    -- Asegurar que el trigger se reactive en caso de error
    ALTER TABLE public.visitors ENABLE TRIGGER trigger_update_permission_visitors;
    RAISE;
END;
$$;


--
-- Name: original_16738(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16738() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
  SELECT current_setting('role', true) = 'service_role' OR 
         (auth.jwt() ->> 'role') = 'service_role'
$$;


--
-- Name: original_16739(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16739() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    -- Check if the user has the superadmin role in auth.users
    RETURN EXISTS (
        SELECT 1 
        FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'superadmin'
    );
END;
$$;

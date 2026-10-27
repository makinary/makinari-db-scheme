SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: check_delete_permission(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_delete_permission() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
DECLARE
    target_site_id UUID;
    current_user_id UUID;
    user_role TEXT;
    is_owner BOOLEAN := FALSE;
    is_admin BOOLEAN := FALSE;
    deleting_site_id TEXT;
    deleting_user_id TEXT;
BEGIN
    -- Get current user
    current_user_id := auth.uid();
    
    -- Skip check for system operations (when no user context)
    IF current_user_id IS NULL THEN
        RETURN OLD;
    END IF;
    
    -- Check if we're in a legitimate site deletion context
    BEGIN
        deleting_site_id := current_setting('app.deleting_site_id', true);
        deleting_user_id := current_setting('app.deleting_user_id', true);
    EXCEPTION
        WHEN OTHERS THEN
            deleting_site_id := '';
            deleting_user_id := '';
    END;
    
    -- Get site_id from the record being deleted
    CASE TG_TABLE_NAME
        WHEN 'sites' THEN
            target_site_id := OLD.id;
            
        WHEN 'task_comments' THEN
            SELECT t.site_id INTO target_site_id
            FROM public.tasks t 
            WHERE t.id = OLD.task_id;
            
        WHEN 'task_categories' THEN
            SELECT t.site_id INTO target_site_id
            FROM public.tasks t 
            WHERE t.id = OLD.task_id;
            
        WHEN 'agent_assets' THEN
            SELECT a.site_id INTO target_site_id
            FROM public.agents a 
            WHERE a.id = OLD.agent_id;
            
        WHEN 'agent_memories' THEN
            SELECT a.site_id INTO target_site_id
            FROM public.agents a 
            WHERE a.id = OLD.agent_id;
            
        WHEN 'campaign_requirements' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.campaigns c 
            WHERE c.id = OLD.campaign_id;
            
        WHEN 'campaign_segments' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.campaigns c 
            WHERE c.id = OLD.campaign_id;
            
        WHEN 'campaign_subtasks' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.campaigns c 
            WHERE c.id = OLD.campaign_id;
            
        WHEN 'experiment_segments' THEN
            SELECT e.site_id INTO target_site_id
            FROM public.experiments e 
            WHERE e.id = OLD.experiment_id;
            
        WHEN 'requirement_segments' THEN
            SELECT r.site_id INTO target_site_id
            FROM public.requirements r 
            WHERE r.id = OLD.requirement_id;
            
        WHEN 'messages' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.conversations c 
            WHERE c.id = OLD.conversation_id;
            
        WHEN 'sale_orders' THEN
            target_site_id := OLD.site_id;
            
        ELSE
            -- Default: assume table has site_id column
            BEGIN
                EXECUTE format('SELECT ($1).site_id') USING OLD INTO target_site_id;
            EXCEPTION
                WHEN OTHERS THEN
                    target_site_id := NULL;
            END;
    END CASE;
    
    -- If we couldn't determine site_id, allow the operation (might be system table)
    IF target_site_id IS NULL THEN
        RETURN OLD;
    END IF;
    
    -- CRITICAL: Check if this deletion is part of a legitimate site deletion
    IF deleting_site_id IS NOT NULL 
       AND deleting_site_id != '' 
       AND deleting_site_id = target_site_id::text
       AND deleting_user_id = current_user_id::text THEN
        -- This is a legitimate site deletion by the site owner
        RETURN OLD;
    END IF;
    
    -- For individual record deletions, check normal permissions
    
    -- Check if user is site owner (fastest check)
    SELECT EXISTS (
        SELECT 1 FROM public.sites 
        WHERE id = target_site_id AND user_id = current_user_id
    ) INTO is_owner;
    
    -- If owner, allow immediately
    IF is_owner THEN
        RETURN OLD;
    END IF;
    
    -- Check if user is admin member
    BEGIN
        SELECT role INTO user_role
        FROM public.site_members 
        WHERE site_id = target_site_id 
        AND user_id = current_user_id 
        AND status = 'active';
        
        is_admin := (user_role = 'admin');
    EXCEPTION
        WHEN undefined_table THEN
            -- site_members table doesn't exist, treat as non-admin
            is_admin := FALSE;
            user_role := 'none';
    END;
    
    -- Allow if admin, block otherwise
    IF is_admin THEN
        RETURN OLD;
    ELSE
        RAISE EXCEPTION 'DELETE_PERMISSION_DENIED: Only site owners and admins can delete records. Your role: none';
    END IF;
END;
$_$;


--
-- Name: check_delete_protection_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_delete_protection_status() RETURNS TABLE(table_name text, trigger_name text, status text, performance_impact text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_16702(); END$$;


--
-- Name: check_referral_system_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_referral_system_status() RETURNS TABLE(component text, status text, details text)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  -- Verificar tablas
  RETURN QUERY
  SELECT 
    'Tabla referral_codes'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referral_codes') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    (SELECT COUNT(*)::TEXT || ' códigos' FROM public.referral_codes)::TEXT;
    
  RETURN QUERY
  SELECT 
    'Tabla referral_code_uses'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referral_code_uses') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    (SELECT COUNT(*)::TEXT || ' usos' FROM public.referral_code_uses)::TEXT;
  
  -- Verificar funciones
  RETURN QUERY
  SELECT 
    'Función validate_referral_code'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_referral_code') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Valida códigos de referido'::TEXT;
    
  RETURN QUERY
  SELECT 
    'Función register_referral_code_use'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'register_referral_code_use') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Registra uso de códigos'::TEXT;
    
  RETURN QUERY
  SELECT 
    'Función handle_new_user'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Trigger de nuevos usuarios'::TEXT;
  
  -- Verificar trigger
  RETURN QUERY
  SELECT 
    'Trigger on_auth_user_created'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Trigger en auth.users'::TEXT;
    
  -- Verificar códigos activos
  RETURN QUERY
  SELECT 
    'Códigos activos'::TEXT,
    (SELECT COUNT(*)::TEXT FROM public.referral_codes WHERE is_active = true),
    (SELECT string_agg(code, ', ') FROM public.referral_codes WHERE is_active = true)::TEXT;
END;
$$;


--
-- Name: check_role_restrictions_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_role_restrictions_status() RETURNS TABLE(table_name text, insert_trigger text, update_trigger text, delete_trigger text, status text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_16704(); END$$;


--
-- Name: checkpoint_icp_mining_execution(uuid, uuid, uuid, integer, integer, integer, integer, integer, integer, text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.checkpoint_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_version integer, p_processed integer, p_found integer, p_page integer, p_offset integer, p_total integer, p_status text, p_snapshot jsonb, p_errors jsonb DEFAULT '[]'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE r public.icp_mining; d public.icp_dispatch_runs;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(734210, 1);
  SELECT * INTO d FROM public.icp_dispatch_runs WHERE site_id = p_site_id AND state IN ('reserved', 'running', 'blocked');
  IF FOUND THEN
    IF d.icp_mining_id IS DISTINCT FROM p_id OR d.run_id IS DISTINCT FROM p_run_id OR d.state <> 'running' THEN
      RAISE EXCEPTION 'Dispatch execution ownership lost';
    END IF;
    IF p_processed < d.baseline_processed OR p_found < d.baseline_found
      OR p_processed::bigint - d.baseline_processed > d.reserved_candidates
      OR p_found::bigint - d.baseline_found > d.reserved_matches
      OR p_found::bigint - d.baseline_found > p_processed::bigint - d.baseline_processed THEN
      RAISE EXCEPTION 'Dispatch checkpoint exceeds reservation';
    END IF;
  END IF;
  SELECT * INTO r FROM public.icp_mining WHERE id = p_id AND site_id = p_site_id FOR UPDATE;
  IF NOT FOUND OR r.execution_run_id IS DISTINCT FROM p_run_id OR p_run_id IS NULL THEN
    RAISE EXCEPTION 'Mining execution no longer owns request';
  END IF;
  -- A completed activity response may be lost. Retrying its exact sequence is a no-op.
  IF p_version = r.checkpoint_version THEN RETURN jsonb_build_object('success', true, 'applied', false); END IF;
  IF NOT r.execution_active OR p_version IS NULL OR p_version <> r.checkpoint_version + 1 THEN RAISE EXCEPTION 'Stale mining checkpoint'; END IF;
  IF p_processed IS NULL OR p_found IS NULL OR p_page IS NULL OR p_offset IS NULL
    OR p_processed < COALESCE(r.processed_targets, 0) OR p_found < COALESCE(r.found_matches, 0)
    OR p_found > p_processed OR p_page < COALESCE(r.current_page, 0) OR p_offset NOT BETWEEN 0 AND 9
    OR (p_page = COALESCE(r.current_page, 0) AND p_offset < COALESCE(r.current_page_offset, 0))
    OR p_status NOT IN ('running', 'pending', 'completed') OR p_status IS NULL
    OR (p_total IS NOT NULL AND p_total < 0) OR jsonb_typeof(p_errors) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Invalid mining checkpoint';
  END IF;
  IF p_snapshot IS NOT NULL AND (jsonb_typeof(p_snapshot) IS DISTINCT FROM 'object'
    OR (p_snapshot->>'page')::integer IS DISTINCT FROM p_page
    OR jsonb_typeof(p_snapshot->'candidates') IS DISTINCT FROM 'array') THEN RAISE EXCEPTION 'Invalid page snapshot'; END IF;
  PERFORM pg_catalog.set_config('app.icp_execution_owner', p_run_id::text, true);
  UPDATE public.icp_mining SET processed_targets = p_processed, found_matches = p_found,
    current_page = p_page, current_page_offset = p_offset, current_page_snapshot = p_snapshot,
    checkpoint_version = p_version, total_targets = COALESCE(p_total, total_targets),
    status = p_status, execution_active = p_status = 'running', last_progress_at = now(),
    finished_at = CASE WHEN p_status = 'completed' THEN now() ELSE NULL END,
    last_error = CASE WHEN jsonb_array_length(p_errors) > 0 THEN p_errors::text ELSE NULL END,
    errors = COALESCE(errors, '[]'::jsonb) || p_errors
    WHERE id = p_id;
  RETURN jsonb_build_object('success', true, 'applied', true);
END $$;


--
-- Name: checkpoint_platform_quota_usage(uuid, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.checkpoint_platform_quota_usage(p_site_id uuid, p_capability text, p_period text, p_used integer) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  INSERT INTO public.platform_quotas (
    site_id,
    capability,
    period,
    used,
    created_at,
    updated_at
  )
  VALUES (
    p_site_id,
    p_capability,
    p_period,
    GREATEST(p_used, 0),
    timezone('utc', now()),
    timezone('utc', now())
  )
  ON CONFLICT (site_id, capability, period)
  DO UPDATE SET
    used = GREATEST(public.platform_quotas.used, EXCLUDED.used),
    updated_at = timezone('utc', now());
$$;


--
-- Name: claim_agent_requirement_run(uuid[], integer, integer, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_agent_requirement_run(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[] DEFAULT '{}'::uuid[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF p_max_concurrent IS NULL OR p_max_concurrent NOT BETWEEN 1 AND 100
    OR p_ttl_seconds IS NULL OR p_ttl_seconds NOT BETWEEN 60 AND 86400
    OR cardinality(p_excluded_ids)>10000 OR cardinality(p_scheduled_ids)>10000 THEN
    RAISE EXCEPTION 'Invalid agent cron claim' USING ERRCODE='22023';
  END IF;
  PERFORM public.recheck_requirement_economic_pauses(p_excluded_ids);
  PERFORM public.apply_pending_requirement_commands();
  RETURN public.claim_agent_requirement_run_before_commands(p_excluded_ids,p_max_concurrent,p_ttl_seconds,p_scheduled_ids);
END;
$$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: hold_migration_diagnostic(uuid, text, integer, integer, text, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hold_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text, p_plan_id uuid, p_step_id text, p_reason text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_row public.requirement_migration_lifecycle%ROWTYPE;
  v_diag public.requirement_migration_diagnostics%ROWTYPE;
  v_plan public.instance_plans%ROWTYPE;
  v_result jsonb;
BEGIN
  IF p_expected_version IS NULL OR p_expected_version < 1 OR p_plan_id IS NULL
    OR NULLIF(btrim(p_step_id), '') IS NULL OR NULLIF(btrim(p_reason), '') IS NULL
    OR char_length(p_reason) > 2048 THEN
    RAISE EXCEPTION 'Invalid diagnostic hold' USING ERRCODE = '22023';
  END IF;
  v_row := public.lock_requirement_migration_diagnostic_scope(
    p_requirement_id, p_file, p_execution_generation, p_run_id, true);
  IF v_row.version <> p_expected_version THEN
    RAISE EXCEPTION 'Migration lifecycle version conflict' USING ERRCODE = '40001';
  END IF;
  SELECT * INTO v_diag FROM public.requirement_migration_diagnostics
    WHERE requirement_id=p_requirement_id AND file=p_file FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No independent diagnosis' USING ERRCODE = '40001'; END IF;
  SELECT * INTO v_plan FROM public.instance_plans WHERE id=p_plan_id FOR UPDATE;
  IF NOT FOUND OR v_plan.metadata->>'requirement_id' IS DISTINCT FROM p_requirement_id::text
    OR v_plan.instance_id::text IS DISTINCT FROM
      (SELECT metadata->>'runner_instance_id' FROM public.requirements WHERE id=p_requirement_id)
    OR v_plan.status NOT IN ('pending','in_progress','active','completed','failed')
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(v_plan.steps) s WHERE s->>'id'=p_step_id)
  THEN RAISE EXCEPTION 'Diagnostic plan scope changed' USING ERRCODE = '40001'; END IF;
  v_result := public.transition_requirement_migration(p_requirement_id, p_file, p_expected_version,
    p_execution_generation, jsonb_build_object('state','platform_review','checksum',v_row.checksum,
      'specification_checksum',v_row.specification_checksum,'original_sql',v_row.original_sql,
      'reason',p_reason,'review',jsonb_build_object('diagnostic_id',v_diag.token,'diagnosis',v_diag.result),
      'attempts',v_row.attempts));
  UPDATE public.instance_plans SET status='blocked', updated_at=clock_timestamp(),
    steps=(SELECT jsonb_agg(CASE WHEN s->>'id'=p_step_id AND s->>'status' NOT IN ('completed','cancelled')
      THEN s || jsonb_build_object('status','blocked','error_message',p_reason) ELSE s END ORDER BY n)
      FROM jsonb_array_elements(v_plan.steps) WITH ORDINALITY e(s,n))
    WHERE id=p_plan_id;
  UPDATE public.remote_instances SET status='pending', updated_at=clock_timestamp()
    WHERE id=v_plan.instance_id AND status='running';
  INSERT INTO public.requirement_status(site_id,instance_id,requirement_id,stage,message)
    SELECT site_id,v_plan.instance_id,id,'blocked',p_reason FROM public.requirements WHERE id=p_requirement_id;
  RETURN v_result;
END;
$$;


--
-- Name: import_catalog_batch(uuid, jsonb, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.import_catalog_batch(p_site_id uuid, p_rows jsonb, p_mode text, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4379420($1,$2,$3,$4); END$_$;


--
-- Name: increment_agent_conversations(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_agent_conversations() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  UPDATE public.agents
  SET conversations = conversations + 1,
      last_active = NOW()
  WHERE id = NEW.agent_id;
  RETURN NEW;
END;
$$;


--
-- Name: increment_referral_code_usage(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_referral_code_usage() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  UPDATE public.referral_codes 
  SET current_uses = current_uses + 1
  WHERE id = NEW.referral_code_id;
  
  RETURN NEW;
END;
$$;


--
-- Name: increment_requirement_metadata_counter(uuid, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_requirement_metadata_counter(p_requirement_id uuid, p_key text, p_increment integer DEFAULT 1, p_initial_value integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_metadata jsonb;
  v_current integer;
  v_next integer;
BEGIN
  IF NULLIF(btrim(p_key), '') IS NULL OR p_key !~ '^[a-zA-Z0-9_]+$' THEN
    RAISE EXCEPTION 'Invalid metadata counter key: %', p_key;
  END IF;

  SELECT CASE
    WHEN jsonb_typeof(metadata) = 'object' THEN metadata
    ELSE '{}'::jsonb
  END
  INTO v_metadata
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Requirement % not found', p_requirement_id;
  END IF;

  v_current := CASE
    WHEN COALESCE(v_metadata->>p_key, '') ~ '^-?[0-9]{1,9}$'
      THEN (v_metadata->>p_key)::integer
    ELSE p_initial_value
  END;
  v_next := v_current + p_increment;

  UPDATE public.requirements
  SET
    metadata = jsonb_set(v_metadata, ARRAY[p_key], to_jsonb(v_next), true),
    updated_at = timezone('utc', now())
  WHERE id = p_requirement_id;

  RETURN v_next;
END;
$_$;


--
-- Name: increment_system_memory_access(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_system_memory_access(p_memory_id uuid, p_amount integer) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  UPDATE public.system_memories
  SET
    access_count = access_count + GREATEST(p_amount, 0),
    last_accessed = timezone('utc', now())
  WHERE id = p_memory_id;
$$;


--
-- Name: increment_template_usage(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_template_usage() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public, pg_temp'
    SET lock_timeout TO '10s'
    SET statement_timeout TO '30s'
    AS $$
BEGIN
    -- Actualizar basándose en trigger NEW record
    UPDATE public.whatsapp_templates 
    SET 
        usage_count = COALESCE(usage_count, 0) + 1,
        last_used = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id;  -- Usar NEW.id en lugar de NEW.template_id
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- No fallar el trigger
        RETURN NEW;
END;
$$;


--
-- Name: increment_template_usage(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_template_usage(template_sid_param text) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    UPDATE whatsapp_templates 
    SET 
        usage_count = COALESCE(usage_count, 0) + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE template_sid = template_sid_param;
END;
$$;


--
-- Name: increment_usage_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_usage_count() RETURNS integer
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    -- Implementation depends on the original function logic
    -- This is a placeholder that should be updated with the actual logic
    RETURN 1;
END;
$$;


--
-- Name: increment_visitor_sessions(uuid, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_visitor_sessions(visitor_id uuid, last_seen_timestamp bigint) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16737($1,$2); RETURN; END$_$;

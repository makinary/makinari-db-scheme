SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: set_site_agent_channel_enabled(uuid, text, boolean, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_site_agent_channel_enabled(p_site_id uuid, p_connection_id text, p_enabled boolean, p_actor_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  stored public.settings%ROWTYPE; target jsonb; marker jsonb; channels_result jsonb;
  before_projection jsonb; after_projection jsonb; entry jsonb; category text;
  connection_count integer; social_used integer := 0; agent_used integer := 0;
  social_limit integer; agent_limit integer; addons integer; plan_name text;
  previous_status text; previous_enabled jsonb; already_active boolean;
BEGIN
  IF p_site_id IS NULL OR p_connection_id IS NULL OR btrim(p_connection_id)='' OR
    p_enabled IS NULL OR p_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Channel activation inputs are required';
  END IF;
  PERFORM public.lock_site_license(p_site_id);
  IF NOT EXISTS (
    SELECT 1 FROM public.sites s WHERE s.id=p_site_id AND s.archived_at IS NULL AND (
      s.user_id=p_actor_id OR EXISTS (
        SELECT 1 FROM public.site_members m WHERE m.site_id=s.id AND m.user_id=p_actor_id
          AND m.status='active' AND public.site_member_has_effective_license(m.id)
          AND (m.role IN ('owner','admin') OR EXISTS (
            SELECT 1 FROM public.site_ownership o WHERE o.site_id=s.id AND o.user_id=p_actor_id))
      )
    )
  ) THEN RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Channel activation site access denied'; END IF;
  SELECT * INTO stored FROM public.settings WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR jsonb_typeof(stored.channels->'connections') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Channel does not belong to site';
  END IF;
  SELECT count(*) INTO connection_count FROM jsonb_array_elements(stored.channels->'connections')
    WHERE value->>'id'=p_connection_id;
  IF connection_count<>1 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Channel must uniquely belong to site';
  END IF;
  SELECT value INTO target FROM jsonb_array_elements(stored.channels->'connections') WHERE value->>'id'=p_connection_id;
  IF NOT coalesce(target->>'status' IN ('connected','disabled','license_suspended') OR
    (target->>'type'='voice' AND target->>'status' IN ('active','synced')),false) THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Only established channels can change activation';
  END IF;
  before_projection := public.get_site_licensed_resources(p_site_id);
  IF before_projection IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Channel license is unavailable';
  END IF;
  SELECT coalesce(bool_or(value->>'status' IN ('connected','active','synced')
    AND value->'enabled' IS DISTINCT FROM 'false'::jsonb AND value->'license_suspended'='false'::jsonb),false)
    INTO already_active FROM jsonb_array_elements(before_projection->'channels'->'connections') WHERE value->>'id'=p_connection_id;
  IF p_enabled AND NOT already_active THEN
    -- Admission counts ALL current effective slots, even resources added after
    -- this connection. Immutable chronological reconciliation cannot evict them.
    SELECT count(*) INTO social_used FROM jsonb_array_elements(before_projection->'social_media')
      WHERE value->'isActive' IN ('true'::jsonb,'1'::jsonb) AND value->'license_suspended'='false'::jsonb;
    SELECT count(*) INTO agent_used FROM jsonb_array_elements(before_projection->'channels'->'connections')
      WHERE (value->>'status'='connected' OR (value->>'type'='voice' AND value->>'status' IN ('active','synced')))
        AND value->'enabled' IS DISTINCT FROM 'false'::jsonb AND value->'license_suspended'='false'::jsonb;
    plan_name := public.effective_site_plan(p_site_id);
    social_limit := CASE plan_name WHEN 'engine' THEN 3 WHEN 'foundry' THEN 6 WHEN 'enterprise' THEN 10 ELSE 1 END;
    agent_limit := CASE plan_name WHEN 'engine' THEN 1 WHEN 'foundry' THEN 3 WHEN 'enterprise' THEN 10 ELSE 0 END;
    SELECT CASE WHEN stripe_subscription_id IS NULL OR (
      paid_subscription_invoice_id IS NOT NULL AND paid_subscription_period_start <= clock_timestamp()
      AND paid_subscription_period_end > clock_timestamp()
      AND lower(coalesce(subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired'))
      THEN greatest(coalesce(addons_count,0),0) ELSE 0 END INTO addons FROM public.billing WHERE site_id=p_site_id;
    IF greatest(social_used-social_limit,0)+greatest(agent_used+1-agent_limit,0)>coalesce(addons,0) THEN
      RETURN jsonb_build_object('success',false,'code','ACCOUNT_LIMIT');
    END IF;
  END IF;
  marker := coalesce(target->'_license','{}'::jsonb);
  previous_status := CASE WHEN coalesce(marker->'manually_disabled'='true'::jsonb,false)
    THEN marker->>'manualPreviousStatus' WHEN target->>'status'='license_suspended'
    THEN marker->>'previousStatus' ELSE target->>'status' END;
  IF NOT coalesce(previous_status='connected' OR (target->>'type'='voice' AND previous_status IN ('active','synced')),false) THEN
    previous_status := 'connected';
  END IF;
  previous_enabled := CASE WHEN coalesce(marker->'manually_disabled'='true'::jsonb,false)
    THEN coalesce(marker->'manualPreviousEnabled','true'::jsonb) ELSE coalesce(target->'enabled','true'::jsonb) END;
  marker := (marker - 'suspended' - 'previousStatus') || jsonb_build_object(
    'manually_disabled',NOT p_enabled,'manualPreviousStatus',previous_status,'manualPreviousEnabled',previous_enabled);
  -- Preserve the trusted historical enabled value in the marker, but explicit
  -- activation must enable legacy rows whose old enabled flag was already false.
  target := target || jsonb_build_object('_license',marker,'status',CASE WHEN p_enabled THEN previous_status ELSE 'disabled' END,
    'enabled',p_enabled,'license_suspended',false);
  BEGIN
    INSERT INTO public.agent_channel_activation_context VALUES(txid_current(),p_site_id,p_connection_id);
    UPDATE public.settings SET channels=jsonb_set(stored.channels,'{connections}',(
      SELECT jsonb_agg(CASE WHEN value->>'id'=p_connection_id THEN target ELSE value END ORDER BY ordinality)
      FROM jsonb_array_elements(stored.channels->'connections') WITH ORDINALITY
    )),updated_at=clock_timestamp() WHERE site_id=p_site_id RETURNING channels INTO channels_result;
    DELETE FROM public.agent_channel_activation_context WHERE transaction_id=txid_current() AND site_id=p_site_id AND connection_id=p_connection_id;
    IF p_enabled THEN
      after_projection := public.get_site_licensed_resources(p_site_id);
      IF NOT EXISTS (SELECT 1 FROM jsonb_array_elements(after_projection->'channels'->'connections')
        WHERE value->>'id'=p_connection_id AND (value->>'status'='connected' OR
          (value->>'type'='voice' AND value->>'status' IN ('active','synced')))
          AND value->'enabled' IS DISTINCT FROM 'false'::jsonb AND value->'license_suspended'='false'::jsonb) THEN
        RAISE EXCEPTION USING ERRCODE='PML01', MESSAGE='ACCOUNT_LIMIT';
      END IF;
      FOREACH category IN ARRAY ARRAY['social','agent'] LOOP
        FOR entry IN SELECT value FROM jsonb_array_elements(CASE WHEN category='social' THEN before_projection->'social_media'
          ELSE before_projection->'channels'->'connections' END) WHERE value->'license_suspended'='false'::jsonb AND (
            CASE WHEN category='social' THEN value->'isActive' IN ('true'::jsonb,'1'::jsonb)
              ELSE (value->>'status'='connected' OR (value->>'type'='voice' AND value->>'status' IN ('active','synced')))
                AND value->'enabled' IS DISTINCT FROM 'false'::jsonb END) LOOP
          IF NOT EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN category='social' THEN after_projection->'social_media'
            ELSE after_projection->'channels'->'connections' END) WHERE value->'_license'->'order'=entry->'_license'->'order'
              AND value->'license_suspended'='false'::jsonb AND (CASE WHEN category='social' THEN value->'isActive' IN ('true'::jsonb,'1'::jsonb)
                ELSE (value->>'status'='connected' OR (value->>'type'='voice' AND value->>'status' IN ('active','synced')))
                  AND value->'enabled' IS DISTINCT FROM 'false'::jsonb END)) THEN
            RAISE EXCEPTION USING ERRCODE='PML01', MESSAGE='ACCOUNT_LIMIT';
          END IF;
        END LOOP;
      END LOOP;
    END IF;
  EXCEPTION WHEN SQLSTATE 'PML01' THEN
    -- The settings write, trigger effects and capability all roll back together.
    RETURN jsonb_build_object('success',false,'code','ACCOUNT_LIMIT');
  END;
  RETURN jsonb_build_object('success',true,'channels',channels_result);
END;
$$;


--
-- Name: set_site_member_enabled(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_site_member_enabled(p_site_id uuid, p_member_id uuid, p_enabled boolean) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE target public.site_members%ROWTYPE; owner_id uuid;
BEGIN
  IF p_site_id IS NULL OR p_member_id IS NULL OR p_enabled IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Member enabled inputs are required';
  END IF;
  PERFORM public.lock_site_license(p_site_id);
  SELECT user_id INTO owner_id FROM public.sites WHERE id = p_site_id AND archived_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Site is unavailable'; END IF;
  SELECT * INTO target FROM public.site_members WHERE id = p_member_id AND site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Member does not belong to site'; END IF;
  IF target.role = 'owner' OR target.user_id = owner_id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Site owners cannot be disabled';
  END IF;
  IF target.status IS NULL OR target.status NOT IN ('active','pending') THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Only active or pending members can be enabled or disabled';
  END IF;
  -- The existing guard admits reactivation only when a seat is actually free.
  -- Do not rerank on enable: a request must never succeed only to be suspended again.
  UPDATE public.site_members SET manually_disabled = NOT p_enabled,license_suspended = NOT p_enabled
    WHERE id = target.id;
  IF NOT p_enabled THEN PERFORM public.reconcile_site_member_license(p_site_id); END IF;
  SELECT * INTO target FROM public.site_members WHERE id = p_member_id AND site_id = p_site_id;
  RETURN to_jsonb(target);
END;
$$;


--
-- Name: set_task_priority_from_serial(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_task_priority_from_serial() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $_$
BEGIN
    -- Extract numeric part from serial_id and set as priority
    IF NEW.serial_id IS NOT NULL THEN
        NEW.priority := CAST(SUBSTRING(NEW.serial_id FROM '-(\d+)$') AS INTEGER);
    END IF;
    RETURN NEW;
END;
$_$;


--
-- Name: set_task_serial_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_task_serial_id() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    attempt_count integer := 0;
    max_attempts integer := 5;
    generated_serial_id text;
BEGIN
    -- Only set serial_id if it's empty or NULL
    IF NEW.serial_id IS NULL OR NEW.serial_id = '' THEN
        LOOP
            -- Generate a new serial_id
            generated_serial_id := public.generate_task_serial_id(NEW.site_id);
            
            -- Check if this serial_id is unique
            IF NOT EXISTS (
                SELECT 1 FROM public.tasks t
                WHERE t.site_id = NEW.site_id 
                AND t.serial_id = generated_serial_id
                AND t.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
            ) THEN
                NEW.serial_id := generated_serial_id;
                EXIT;
            END IF;
            
            -- Increment attempt counter
            attempt_count := attempt_count + 1;
            
            -- If we've tried too many times, add timestamp suffix
            IF attempt_count >= max_attempts THEN
                NEW.serial_id := generated_serial_id || '-' || EXTRACT(EPOCH FROM clock_timestamp())::bigint;
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
    BEGIN
      NEW.updated_at := NOW();
      RETURN NEW;
    END;
    $$;


--
-- Name: settle_harness_model_reservation(uuid, uuid, numeric, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.settle_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text) RETURNS jsonb
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
  SELECT public.finish_harness_model_reservation($1,$2,$3,$4,$5,NULL);
$_$;


--
-- Name: settle_image_generation_reservation(uuid, text, uuid, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.settle_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_generation_id text, p_model text) RETURNS jsonb
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
  SELECT public.finish_image_generation_reservation($1,$2,$3,$4,NULL,$5,$6);
$_$;

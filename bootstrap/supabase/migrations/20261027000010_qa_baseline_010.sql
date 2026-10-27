SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: advance_credit_auto_top_up_settings_revision(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.advance_credit_auto_top_up_settings_revision() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF ROW(NEW.enabled,NEW.minimum_credits,NEW.target_credits,
      NEW.max_monthly_spend_cents,NEW.stripe_payment_method_id,NEW.state)
    IS DISTINCT FROM ROW(OLD.enabled,OLD.minimum_credits,OLD.target_credits,
      OLD.max_monthly_spend_cents,OLD.stripe_payment_method_id,OLD.state) THEN
    NEW.settings_revision := OLD.settings_revision+1;
  ELSE
    NEW.settings_revision := OLD.settings_revision;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: agent_requirement_runner_allowed(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.agent_requirement_runner_allowed(p_requirement_id uuid, p_instance_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.requirements%ROWTYPE; i public.remote_instances%ROWTYPE; a public.instance_logs%ROWTYPE;
BEGIN
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id;
  IF NOT FOUND OR r.metadata ? 'execution_hold'
    OR coalesce(r.metadata->>'customer_paused','false')='true'
    OR coalesce(r.metadata->>'user_paused','false')='true'
    OR coalesce(r.metadata->>'cron_paused','false')='true' THEN RETURN false; END IF;
  -- Existing assistant admission takes SHARE on this instance. UPDATE also
  -- fences legacy-discovered owners before runner_instance_id has been bound.
  SELECT * INTO i FROM public.remote_instances WHERE id=p_instance_id AND site_id=r.site_id FOR UPDATE;
  IF NOT FOUND OR i.is_archived IS TRUE OR i.status IN ('paused','stopped','stopping','cancelled') THEN RETURN false; END IF;
  IF EXISTS (SELECT 1 FROM public.instance_plans WHERE site_id=r.site_id AND status='paused'
    AND (instance_id=i.id OR metadata->>'requirement_id'=r.id::text)) THEN RETURN false; END IF;
  SELECT * INTO a FROM public.instance_logs WHERE instance_id=i.id AND site_id=r.site_id
    AND log_type='user_action' AND trusted_user_action IS TRUE ORDER BY created_at DESC,id DESC LIMIT 1;
  IF FOUND AND coalesce(a.details->>'status','') NOT IN ('completed','failed') THEN RETURN false; END IF;
  IF r.metadata->>'assistant_origin_instance_id' IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.remote_instances WHERE id::text=r.metadata->>'assistant_origin_instance_id'
      AND site_id=r.site_id) THEN RETURN false; END IF;
    SELECT * INTO a FROM public.instance_logs WHERE instance_id::text=r.metadata->>'assistant_origin_instance_id'
      AND site_id=r.site_id AND log_type='user_action' AND trusted_user_action IS TRUE
      ORDER BY created_at DESC,id DESC LIMIT 1;
    IF NOT FOUND OR coalesce(a.details->>'status','') NOT IN ('completed','failed') THEN RETURN false; END IF;
  END IF;
  RETURN true;
END;
$$;


--
-- Name: append_instance_plan_repair_step_atomic(uuid, text, integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.append_instance_plan_repair_step_atomic(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4230473($1,$2,$3,$4,$5); END$_$;


--
-- Name: append_session_recording_chunk(uuid, text, uuid, uuid, text, bigint, text, uuid, text, bigint, bigint, integer, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.append_session_recording_chunk(p_event_id uuid, p_site_id text, p_visitor_id uuid, p_session_id uuid, p_url text, p_timestamp bigint, p_storage_path text, p_chunk_id uuid, p_content_hash text, p_start_timestamp bigint, p_end_timestamp bigint, p_event_count integer, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT jsonb_build_object(
    'state', result->'state',
    'event_id', (result->'event_ids')->(p_session_id::text)
  )
  FROM (
    SELECT public.append_session_recording_chunks(
      jsonb_build_array(
        jsonb_build_object(
          'event_id', p_event_id,
          'site_id', p_site_id,
          'visitor_id', p_visitor_id,
          'session_id', p_session_id,
          'url', p_url,
          'timestamp', p_timestamp,
          'storage_path', p_storage_path,
          'chunk_id', p_chunk_id,
          'content_hash', p_content_hash,
          'start_timestamp', p_start_timestamp,
          'end_timestamp', p_end_timestamp,
          'event_count', p_event_count,
          'metadata', COALESCE(p_metadata, '{}'::jsonb)
        )
      )
    ) AS result
  ) AS batch;
$$;


--
-- Name: append_session_recording_chunks(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.append_session_recording_chunks(p_chunks jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_chunk jsonb;
  v_first_chunk jsonb;
  v_session_id uuid;
  v_recording_event_id uuid;
  v_site_id text;
  v_existing_site_id text;
  v_properties jsonb;
  v_chunk_id uuid;
  v_inserted_chunk_id uuid;
  v_existing_chunk_id uuid;
  v_existing_session_id uuid;
  v_storage_path text;
  v_content_hash text;
  v_existing_path text;
  v_existing_hash text;
  v_timestamp bigint;
  v_start_timestamp bigint;
  v_end_timestamp bigint;
  v_event_count integer;
  v_new_metadata jsonb;
  v_new_start bigint;
  v_new_end bigint;
  v_new_last_chunk bigint;
  v_new_event_count bigint;
  v_existing_start bigint;
  v_existing_end bigint;
  v_existing_event_count bigint;
  v_existing_last_chunk bigint;
  v_inserted_total integer := 0;
  v_duplicate_total integer := 0;
  v_inserted_for_session integer;
  v_event_ids jsonb := '{}'::jsonb;
BEGIN
  IF p_chunks IS NULL OR jsonb_typeof(p_chunks) <> 'array' THEN
    RAISE EXCEPTION 'Recording batch must be a JSON array';
  END IF;
  IF jsonb_array_length(p_chunks) < 1
    OR jsonb_array_length(p_chunks) > 10
  THEN
    RAISE EXCEPTION 'Recording batch must contain 1-10 chunks';
  END IF;

  FOR v_chunk IN
    SELECT value
    FROM jsonb_array_elements(p_chunks)
  LOOP
    IF jsonb_typeof(v_chunk) <> 'object'
      OR COALESCE(v_chunk->>'event_id', '')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR COALESCE(v_chunk->>'session_id', '')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR COALESCE(v_chunk->>'chunk_id', '')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR NULLIF(btrim(v_chunk->>'site_id'), '') IS NULL
      OR NULLIF(btrim(v_chunk->>'storage_path'), '') IS NULL
      OR NULLIF(btrim(v_chunk->>'content_hash'), '') IS NULL
      OR COALESCE(v_chunk->>'timestamp', '') !~ '^[0-9]{1,19}$'
      OR COALESCE(v_chunk->>'start_timestamp', '') !~ '^[0-9]{1,19}$'
      OR COALESCE(v_chunk->>'end_timestamp', '') !~ '^[0-9]{1,19}$'
      OR COALESCE(v_chunk->>'event_count', '') !~ '^[0-9]{1,9}$'
    THEN
      RAISE EXCEPTION 'Invalid recording chunk';
    END IF;

    IF NULLIF(v_chunk->>'visitor_id', '') IS NOT NULL
      AND (v_chunk->>'visitor_id')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    THEN
      RAISE EXCEPTION 'Invalid recording visitor';
    END IF;

    IF (v_chunk->>'end_timestamp')::bigint
      < (v_chunk->>'start_timestamp')::bigint
    THEN
      RAISE EXCEPTION 'Invalid recording timestamps';
    END IF;
  END LOOP;

  FOR v_session_id IN
    SELECT DISTINCT (value->>'session_id')::uuid
    FROM jsonb_array_elements(p_chunks)
    ORDER BY 1
  LOOP
    PERFORM pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(v_session_id::text, 0)
    );

    SELECT value
    INTO v_first_chunk
    FROM jsonb_array_elements(p_chunks)
    WHERE (value->>'session_id')::uuid = v_session_id
    ORDER BY
      (value->>'timestamp')::bigint,
      (value->>'chunk_id')::uuid
    LIMIT 1;

    v_site_id := v_first_chunk->>'site_id';

    PERFORM 1
    FROM public.visitor_sessions
    WHERE id = v_session_id
      AND site_id::text = v_site_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Recording session does not belong to site';
    END IF;

    SELECT
      id,
      site_id,
      CASE
        WHEN jsonb_typeof(properties) = 'object' THEN properties
        ELSE '{}'::jsonb
      END
    INTO v_recording_event_id, v_existing_site_id, v_properties
    FROM public.session_events
    WHERE session_id = v_session_id
      AND event_type = 'session_recording'
    ORDER BY created_at, id
    LIMIT 1
    FOR UPDATE;

    IF NOT FOUND THEN
      INSERT INTO public.session_events (
        id,
        site_id,
        visitor_id,
        session_id,
        event_type,
        url,
        timestamp,
        properties
      )
      VALUES (
        (v_first_chunk->>'event_id')::uuid,
        v_site_id,
        NULLIF(v_first_chunk->>'visitor_id', '')::uuid,
        v_session_id,
        'session_recording',
        NULLIF(v_first_chunk->>'url', ''),
        (v_first_chunk->>'timestamp')::bigint,
        '{}'::jsonb
      )
      RETURNING id, site_id, properties
      INTO v_recording_event_id, v_existing_site_id, v_properties;
    END IF;

    IF v_existing_site_id IS DISTINCT FROM v_site_id THEN
      RAISE EXCEPTION 'Recording session does not belong to site';
    END IF;

    v_new_metadata := '{}'::jsonb;
    v_new_start := NULL;
    v_new_end := NULL;
    v_new_last_chunk := NULL;
    v_new_event_count := 0;
    v_inserted_for_session := 0;

    FOR v_chunk IN
      SELECT value
      FROM jsonb_array_elements(p_chunks)
      WHERE (value->>'session_id')::uuid = v_session_id
      ORDER BY
        (value->>'timestamp')::bigint,
        (value->>'chunk_id')::uuid
    LOOP
      IF v_chunk->>'site_id' IS DISTINCT FROM v_site_id THEN
        RAISE EXCEPTION 'Recording batch mixes sites for one session';
      END IF;

      v_chunk_id := (v_chunk->>'chunk_id')::uuid;
      v_storage_path := v_chunk->>'storage_path';
      v_content_hash := v_chunk->>'content_hash';
      v_timestamp := (v_chunk->>'timestamp')::bigint;
      v_start_timestamp := (v_chunk->>'start_timestamp')::bigint;
      v_end_timestamp := (v_chunk->>'end_timestamp')::bigint;
      v_event_count := (v_chunk->>'event_count')::integer;
      v_inserted_chunk_id := NULL;

      INSERT INTO public.session_recording_chunks (
        chunk_id,
        recording_event_id,
        site_id,
        session_id,
        storage_path,
        content_hash,
        chunk_timestamp,
        start_timestamp,
        end_timestamp,
        event_count
      )
      VALUES (
        v_chunk_id,
        v_recording_event_id,
        v_site_id,
        v_session_id,
        v_storage_path,
        v_content_hash,
        v_timestamp,
        v_start_timestamp,
        v_end_timestamp,
        v_event_count
      )
      ON CONFLICT DO NOTHING
      RETURNING chunk_id INTO v_inserted_chunk_id;

      IF v_inserted_chunk_id IS NULL THEN
        SELECT chunk_id, session_id, storage_path, content_hash
        INTO
          v_existing_chunk_id,
          v_existing_session_id,
          v_existing_path,
          v_existing_hash
        FROM public.session_recording_chunks
        WHERE chunk_id = v_chunk_id
          OR storage_path = v_storage_path
          OR (
            session_id = v_session_id
            AND content_hash = v_content_hash
          )
        ORDER BY
          (chunk_id = v_chunk_id) DESC,
          (storage_path = v_storage_path) DESC
        LIMIT 1;

        IF v_existing_session_id IS DISTINCT FROM v_session_id
          OR v_existing_hash IS DISTINCT FROM v_content_hash
          OR (
            v_existing_chunk_id = v_chunk_id
            AND v_existing_path IS DISTINCT FROM v_storage_path
          )
          OR (
            v_existing_path = v_storage_path
            AND v_existing_chunk_id IS DISTINCT FROM v_chunk_id
          )
        THEN
          RAISE EXCEPTION
            'Recording chunk identity conflicts with existing content';
        END IF;

        v_duplicate_total := v_duplicate_total + 1;
        CONTINUE;
      END IF;

      v_inserted_total := v_inserted_total + 1;
      v_inserted_for_session := v_inserted_for_session + 1;
      v_new_metadata := CASE
        WHEN jsonb_typeof(v_chunk->'metadata') = 'object'
          THEN jsonb_strip_nulls(jsonb_build_object(
            'device_type',
              CASE
                WHEN v_chunk->'metadata'->>'device_type'
                  IN ('desktop', 'tablet', 'mobile')
                  THEN v_chunk->'metadata'->>'device_type'
                ELSE NULL
              END,
            'screen_size',
              CASE
                WHEN COALESCE(v_chunk->'metadata'->>'screen_size', '')
                  ~ '^[0-9]{1,5}x[0-9]{1,5}$'
                  THEN v_chunk->'metadata'->>'screen_size'
                ELSE NULL
              END
          ))
        ELSE '{}'::jsonb
      END;
      v_new_start := CASE
        WHEN v_new_start IS NULL THEN v_start_timestamp
        ELSE LEAST(v_new_start, v_start_timestamp)
      END;
      v_new_end := CASE
        WHEN v_new_end IS NULL THEN v_end_timestamp
        ELSE GREATEST(v_new_end, v_end_timestamp)
      END;
      v_new_last_chunk := CASE
        WHEN v_new_last_chunk IS NULL THEN v_timestamp
        ELSE GREATEST(v_new_last_chunk, v_timestamp)
      END;
      v_new_event_count := v_new_event_count + v_event_count;
    END LOOP;

    IF v_inserted_for_session > 0 THEN
      v_existing_start := CASE
        WHEN COALESCE(v_properties->>'start_time', '') ~ '^[0-9]{1,19}$'
          THEN (v_properties->>'start_time')::bigint
        ELSE v_new_start
      END;
      v_existing_end := CASE
        WHEN COALESCE(v_properties->>'end_time', '') ~ '^[0-9]{1,19}$'
          THEN (v_properties->>'end_time')::bigint
        ELSE v_new_end
      END;
      v_existing_event_count := CASE
        WHEN COALESCE(v_properties->>'total_events', '') ~ '^[0-9]{1,19}$'
          THEN (v_properties->>'total_events')::bigint
        ELSE 0
      END;
      v_existing_last_chunk := CASE
        WHEN COALESCE(v_properties->>'last_chunk_at', '') ~ '^[0-9]{1,19}$'
          THEN (v_properties->>'last_chunk_at')::bigint
        ELSE v_new_last_chunk
      END;

      UPDATE public.session_events
      SET
        timestamp = GREATEST(timestamp, v_new_last_chunk),
        properties = (
          v_properties - 'chunks' - 'chunk_manifest'
        ) || jsonb_build_object(
          'start_time', LEAST(v_existing_start, v_new_start),
          'end_time', GREATEST(v_existing_end, v_new_end),
          'duration', GREATEST(
            0,
            GREATEST(v_existing_end, v_new_end)
              - LEAST(v_existing_start, v_new_start)
          ),
          'total_events', v_existing_event_count + v_new_event_count,
          'last_chunk_at', GREATEST(v_existing_last_chunk, v_new_last_chunk),
          'metadata', v_new_metadata
        ),
        updated_at = timezone('utc', now())
      WHERE id = v_recording_event_id;
    END IF;

    v_event_ids := v_event_ids || jsonb_build_object(
      v_session_id::text,
      v_recording_event_id
    );
  END LOOP;

  RETURN jsonb_build_object(
    'state', CASE WHEN v_inserted_total > 0 THEN 'updated' ELSE 'duplicate' END,
    'inserted_chunks', v_inserted_total,
    'duplicate_chunks', v_duplicate_total,
    'event_ids', v_event_ids
  );
END;
$_$;


--
-- Name: apply_marketplace_provisioning(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_marketplace_provisioning(p_integration_id uuid, p_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations;
BEGIN
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF p_status NOT IN ('active','revoked','failed') OR p_status IS NULL THEN RAISE EXCEPTION 'Invalid provisioning status'; END IF;
  IF integration.provisioning_status<>'pending' THEN RETURN to_jsonb(integration); END IF;
  IF (p_status='active' AND integration.provisioning_operation<>'activate')
    OR (p_status='revoked' AND integration.provisioning_operation<>'deactivate') THEN
    RAISE EXCEPTION 'Provisioning operation mismatch';
  END IF;
  UPDATE public.marketplace_integrations SET
    provisioning_status=CASE WHEN p_status='failed' THEN 'not_ready' ELSE p_status END,
    provisioning_result=CASE WHEN p_status='failed' THEN 'failed' ELSE 'confirmed' END,
    enabled=p_status='active',updated_at=now()
    WHERE id=integration.id RETURNING * INTO integration;
  RETURN to_jsonb(integration);
END;
$$;

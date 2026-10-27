SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: original_4228213(uuid, integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4228213(p_reservation_id uuid, p_time_window_hours integer) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  UPDATE public.reservations
  SET metadata = coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
      '_reminder_' || p_time_window_hours::text || 'h_sent',
      true
    )
  WHERE id = p_reservation_id;
$$;


--
-- Name: original_4228220(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4228220(p_message_id uuid, p_conversation_id uuid) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  WITH claimed AS (
    UPDATE public.messages
    SET
      custom_data = jsonb_set(
        coalesce(custom_data, '{}'::jsonb),
        '{status}',
        to_jsonb('sending'::text),
        true
      ),
      updated_at = now()
    WHERE id = p_message_id
      AND conversation_id = p_conversation_id
      AND custom_data->>'status' = 'accepted'
    RETURNING id
  )
  SELECT EXISTS (SELECT 1 FROM claimed);
$$;


--
-- Name: original_4228221(jsonb); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4228221(p_messages jsonb) RETURNS TABLE(message_id uuid)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  WITH requested AS (
    SELECT DISTINCT item.message_id, item.conversation_id
    FROM jsonb_to_recordset(coalesce(p_messages, '[]'::jsonb))
      AS item(message_id uuid, conversation_id uuid)
  ),
  claimed AS (
    UPDATE public.messages AS messages
    SET
      custom_data = jsonb_set(
        coalesce(messages.custom_data, '{}'::jsonb),
        '{status}',
        to_jsonb('sending'::text),
        true
      ),
      updated_at = now()
    FROM requested
    WHERE messages.id = requested.message_id
      AND messages.conversation_id = requested.conversation_id
      AND messages.custom_data->>'status' = 'accepted'
    RETURNING messages.id
  )
  SELECT claimed.id AS message_id FROM claimed;
$$;


--
-- Name: original_4228222(timestamp with time zone, integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4228222(p_cutoff timestamp with time zone, p_limit integer DEFAULT 500) RETURNS integer
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  WITH candidates AS (
    SELECT id
    FROM public.messages
    WHERE custom_data->>'status' = 'sending'
      AND updated_at < p_cutoff
    ORDER BY updated_at
    LIMIT greatest(1, least(coalesce(p_limit, 500), 2000))
    FOR UPDATE SKIP LOCKED
  ),
  reset AS (
    UPDATE public.messages AS messages
    SET
      custom_data = jsonb_set(
        coalesce(messages.custom_data, '{}'::jsonb),
        '{status}',
        to_jsonb('accepted'::text),
        true
      ),
      updated_at = now()
    FROM candidates
    WHERE messages.id = candidates.id
      AND messages.custom_data->>'status' = 'sending'
    RETURNING messages.id
  )
  SELECT count(*)::integer FROM reset;
$$;


--
-- Name: original_4230473(uuid, text, integer, text, jsonb); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4230473(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
DECLARE
  v_plan public.instance_plans%ROWTYPE;
  v_steps jsonb;
  v_source_step jsonb;
  v_source_generation integer;
  v_step jsonb;
BEGIN
  SELECT * INTO v_plan
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'persisted', false);
  END IF;

  v_steps := COALESCE(v_plan.steps, '[]'::jsonb);
  SELECT step INTO v_source_step
  FROM jsonb_array_elements(v_steps) AS step
  WHERE step->>'id' = p_source_step_id
  LIMIT 1;

  IF v_source_step IS NULL THEN
    RETURN jsonb_build_object('state', 'missing', 'persisted', false);
  END IF;

  IF v_source_step->>'status' IS DISTINCT FROM 'completed' THEN
    RETURN jsonb_build_object('state', 'stale', 'persisted', false);
  END IF;

  SELECT step INTO v_step
  FROM jsonb_array_elements(v_steps) AS step
  WHERE step->'metadata'->>'repair_source_step_id' = p_source_step_id
    AND step->'metadata'->'repair_run'->>'repair_run_id' = p_repair_run_id
  LIMIT 1;
  IF v_step IS NOT NULL THEN
    RETURN jsonb_build_object(
      'state', 'duplicate',
      'persisted', true,
      'step_id', v_step->>'id',
      'generation', CASE
        WHEN COALESCE(v_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
          THEN (v_step->>'infrastructure_generation')::integer
        ELSE 0
      END
    );
  END IF;

  v_source_generation := CASE
    WHEN COALESCE(v_source_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_source_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  IF v_source_generation IS DISTINCT FROM p_expected_source_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'persisted', false,
      'generation', v_source_generation
    );
  END IF;

  IF v_plan.status NOT IN ('completed', 'in_progress') THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'persisted', false,
      'generation', v_source_generation
    );
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(v_steps) AS step
    WHERE step->>'id' = p_repair_step->>'id'
  ) THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'persisted', false,
      'generation', v_source_generation
    );
  END IF;

  IF p_repair_step->'metadata'->'repair_run'->>'repair_run_id'
    IS DISTINCT FROM p_repair_run_id
  THEN
    RAISE EXCEPTION 'repair step identity does not match repair run id';
  END IF;

  v_step := p_repair_step || jsonb_build_object(
    'status', 'pending',
    'infrastructure_generation', 0,
    'created_at', COALESCE(p_repair_step->>'created_at', timezone('utc', now())::text),
    'updated_at', timezone('utc', now())::text
  );
  v_steps := v_steps || jsonb_build_array(v_step);

  UPDATE public.instance_plans
  SET
    steps = v_steps,
    status = 'in_progress',
    completed_at = NULL,
    steps_total = jsonb_array_length(v_steps),
    progress_percentage = CASE
      WHEN jsonb_array_length(v_steps) = 0 THEN 0
      ELSE round(
        100.0 * (
          SELECT count(*) FROM jsonb_array_elements(v_steps) AS step
          WHERE step->>'status' = 'completed'
        ) / jsonb_array_length(v_steps)
      )
    END,
    updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  RETURN jsonb_build_object(
    'state', 'applied',
    'persisted', true,
    'step_id', v_step->>'id',
    'generation', 0
  );
END;
$_$;


--
-- Name: original_4247935(uuid[], integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4247935(p_site_ids uuid[], p_limit integer DEFAULT 1000) RETURNS TABLE(site_id uuid, post_id text, content_id text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
  WITH social_content AS (
    SELECT
      content.site_id,
      content.id,
      content.published_at,
      outstand_post.post_id
    FROM public.content AS content
    CROSS JOIN LATERAL (
      SELECT substring(tag.value FROM '^outstand_id_(.+)$') AS post_id
      FROM unnest(content.tags) WITH ORDINALITY AS tag(value, position)
      WHERE tag.value LIKE 'outstand_id_%'
      ORDER BY tag.position
      LIMIT 1
    ) AS outstand_post
    WHERE content.site_id = ANY(p_site_ids)
      AND (content.status = 'published' OR content.published_at IS NOT NULL)
  ),
  due AS (
    SELECT
      social_content.site_id,
      social_content.post_id,
      coalesce(performance.content_id::text, social_content.id::text) AS content_id,
      performance.fetched_at,
      social_content.published_at
    FROM social_content
    LEFT JOIN public.content_performance AS performance
      ON performance.site_id = social_content.site_id
      AND performance.outstand_post_id = social_content.post_id
    WHERE
      (social_content.published_at IS NULL
        AND (performance.fetched_at IS NULL
          OR performance.fetched_at <= now() - interval '6 hours'))
      OR (social_content.published_at >= now() - interval '1 day'
        AND (performance.fetched_at IS NULL
          OR performance.fetched_at <= now() - interval '6 hours'))
      OR (social_content.published_at < now() - interval '1 day'
        AND social_content.published_at >= now() - interval '7 days'
        AND (performance.fetched_at IS NULL
          OR performance.fetched_at <= now() - interval '12 hours'))
      OR (social_content.published_at < now() - interval '7 days'
        AND social_content.published_at >= now() - interval '30 days'
        AND (performance.fetched_at IS NULL
          OR performance.fetched_at <= now() - interval '24 hours'))
      OR (social_content.published_at < now() - interval '30 days'
        AND performance.fetched_at IS NULL)
  )
  SELECT DISTINCT ON (due.site_id, due.post_id)
    due.site_id, due.post_id, due.content_id
  FROM due
  ORDER BY due.site_id, due.post_id, due.fetched_at NULLS FIRST
  LIMIT greatest(1, least(coalesce(p_limit, 1000), 5000));
$_$;


--
-- Name: original_4248376(uuid, text, integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4248376(p_site_id uuid, p_account_id text, p_limit integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
DECLARE
  v_media jsonb;
  v_index integer;
  v_owners integer;
  v_existing public.outstand_initial_imports%ROWTYPE;
BEGIN
  IF p_site_id IS NULL OR p_account_id IS NULL OR p_limit IS NULL
    OR p_account_id !~ '^[A-Za-z0-9_-]{1,80}$' OR p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'Invalid initial import request';
  END IF;

  -- Serialize every claim (including an account changing sites) before the
  -- billable POST; the ledger is keyed by provider account ID globally.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_account_id, 0));
  -- Lock the whole settings row so competing workers/manual requests cannot
  -- simultaneously claim an account or overwrite each other's JSONB changes.
  SELECT social_media INTO v_media FROM public.settings
  WHERE site_id = p_site_id FOR UPDATE;
  IF jsonb_typeof(v_media) IS DISTINCT FROM 'array' THEN RETURN false; END IF;

  SELECT count(*) INTO v_owners
  FROM public.settings AS s
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE WHEN jsonb_typeof(s.social_media) = 'array' THEN s.social_media ELSE '[]'::jsonb END
  ) AS a(value)
  WHERE a.value->>'id' = p_account_id
    AND a.value->>'isActive' IN ('true', '1');
  IF v_owners <> 1 THEN RETURN false; END IF;

  SELECT (position - 1)::integer INTO v_index
  FROM jsonb_array_elements(v_media) WITH ORDINALITY AS a(value, position)
  WHERE a.value->>'id' = p_account_id
    AND a.value->>'isActive' IN ('true', '1')
  LIMIT 1;
  IF v_index IS NULL THEN RETURN false; END IF;

  -- An account may already have an import marker from the previous worker.
  -- Do not create another billable job if provider history was later cleared.
  IF EXISTS (SELECT 1 FROM public.cron_status WHERE site_id = p_site_id
    AND activity_name = 'outstand_historical_import_' || p_account_id)
  THEN RETURN false; END IF;

  INSERT INTO public.outstand_initial_imports (account_id, site_id, import_limit)
  VALUES (p_account_id, p_site_id, p_limit) ON CONFLICT (account_id) DO NOTHING;
  IF NOT FOUND THEN
    -- A stale settings form can replace the JSON flag. Reconstruct it from
    -- the durable ledger without issuing another billable provider request.
    SELECT * INTO v_existing FROM public.outstand_initial_imports
    WHERE account_id = p_account_id AND site_id = p_site_id;
    IF FOUND THEN
      UPDATE public.settings SET social_media = jsonb_set(v_media,
        ARRAY[v_index::text, 'initialImport'], jsonb_strip_nulls(jsonb_build_object(
          'status', v_existing.status, 'limit', v_existing.import_limit,
          'jobId', v_existing.job_id, 'imported', v_existing.imported,
          'failed', v_existing.failed, 'requestedAt', v_existing.created_at,
          'updatedAt', v_existing.updated_at)), true), updated_at = now()
      WHERE site_id = p_site_id AND NOT (v_media->v_index ? 'initialImport');
    END IF;
    RETURN false;
  END IF;

  UPDATE public.settings
  SET social_media = jsonb_set(v_media, ARRAY[v_index::text, 'initialImport'],
    jsonb_build_object('status', 'requested', 'limit', p_limit, 'requestedAt', now()), true),
      updated_at = now()
  WHERE site_id = p_site_id;
  RETURN true;
END;
$_$;


--
-- Name: original_4248377(uuid, text, text, text, integer, integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4248377(p_site_id uuid, p_account_id text, p_status text, p_job_id text DEFAULT NULL::text, p_imported integer DEFAULT NULL::integer, p_failed integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
DECLARE
  v_media jsonb;
  v_index integer;
  v_flag jsonb;
  v_status text;
  v_existing_job text;
  v_existing_site uuid;
BEGIN
  IF p_site_id IS NULL OR p_account_id IS NULL OR p_status IS NULL OR
    p_account_id !~ '^[A-Za-z0-9_-]{1,80}$' OR
    p_status NOT IN ('queued', 'running', 'completed', 'partial', 'failed', 'unknown') THEN
    RAISE EXCEPTION 'Invalid initial import status';
  END IF;
  IF (p_job_id IS NULL OR p_job_id = '') AND p_status <> 'unknown' THEN
    RAISE EXCEPTION 'Provider job ID required to record an import';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_account_id, 0));
  SELECT social_media INTO v_media FROM public.settings
  WHERE site_id = p_site_id FOR UPDATE;
  IF jsonb_typeof(v_media) IS DISTINCT FROM 'array' THEN RETURN false; END IF;

  SELECT (position - 1)::integer, a.value->'initialImport'
  INTO v_index, v_flag
  FROM jsonb_array_elements(v_media) WITH ORDINALITY AS a(value, position)
  WHERE a.value->>'id' = p_account_id
    AND a.value->>'isActive' IN ('true', '1')
  LIMIT 1;
  IF v_index IS NULL THEN RETURN false; END IF;
  IF jsonb_typeof(v_flag) IS DISTINCT FROM 'object' THEN v_flag := '{}'::jsonb; END IF;

  -- A provider job may appear after our POST timed out, or predate this
  -- migration. Adopt the first one; never replace its identity later.
  IF p_job_id IS NOT NULL AND p_status <> 'unknown' THEN
    INSERT INTO public.outstand_initial_imports
      (account_id, site_id, import_limit, status, job_id, imported, failed)
    VALUES (p_account_id, p_site_id, 100, p_status, p_job_id, p_imported, p_failed)
    ON CONFLICT (account_id) DO NOTHING;
  END IF;
  IF p_job_id IS NULL AND NOT EXISTS (SELECT 1 FROM public.outstand_initial_imports
    WHERE account_id = p_account_id AND site_id = p_site_id)
  THEN RETURN false; END IF;
  SELECT status, job_id, site_id INTO v_status, v_existing_job, v_existing_site
  FROM public.outstand_initial_imports WHERE account_id = p_account_id;
  IF v_existing_site IS DISTINCT FROM p_site_id OR
    (v_existing_job IS NOT NULL AND v_existing_job IS DISTINCT FROM p_job_id)
  THEN RETURN false; END IF;

  -- The ledger is authoritative; JSONB may be stale after settings saves.
  IF v_status IN ('queued', 'running', 'completed', 'partial', 'failed')
    AND p_status = 'unknown' THEN RETURN false; END IF;
  IF v_status IN ('completed', 'partial', 'failed') AND v_status <> p_status THEN RETURN false; END IF;

  UPDATE public.outstand_initial_imports
  SET status = p_status, job_id = coalesce(p_job_id, job_id),
      imported = coalesce(p_imported, imported), failed = coalesce(p_failed, failed),
      updated_at = now()
  WHERE account_id = p_account_id AND site_id = p_site_id
    AND (status NOT IN ('completed', 'partial', 'failed') OR status = p_status);

  v_flag := v_flag || jsonb_build_object('status', p_status, 'updatedAt', now());
  IF p_job_id IS NOT NULL THEN v_flag := v_flag || jsonb_build_object('jobId', p_job_id); END IF;
  IF p_imported IS NOT NULL THEN v_flag := v_flag || jsonb_build_object('imported', p_imported); END IF;
  IF p_failed IS NOT NULL THEN v_flag := v_flag || jsonb_build_object('failed', p_failed); END IF;
  UPDATE public.settings
  SET social_media = jsonb_set(v_media, ARRAY[v_index::text, 'initialImport'], v_flag),
      updated_at = now()
  WHERE site_id = p_site_id;
  RETURN true;
END;
$_$;


--
-- Name: original_4249998(uuid, jsonb, jsonb, uuid, text, boolean); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4249998(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid DEFAULT NULL::uuid, p_expected_hash text DEFAULT NULL::text, p_check_version boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  -- Even service callers must use the source-locked RPC for generated postings.
  IF coalesce(p_entry->>'source_type', '') NOT IN ('manual', 'opening') THEN
    RAISE EXCEPTION 'Standalone journals must be manual or opening entries' USING ERRCODE = '42501';
  END IF;
  RETURN public.accounting_save_journal_internal(p_site_id, p_entry, p_lines, p_entry_id,
    p_expected_hash, p_check_version, false);
END;
$$;

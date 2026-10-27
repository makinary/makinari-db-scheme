SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: consolidate_session_recording_duplicates(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consolidate_session_recording_duplicates(p_row_limit integer DEFAULT 100) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_session_id uuid;
  v_canonical_id uuid;
  v_row_ids uuid[];
  v_deleted integer := 0;
  v_has_more boolean := false;
BEGIN
  IF p_row_limit IS NULL OR p_row_limit < 1 OR p_row_limit > 500 THEN
    RAISE EXCEPTION 'Row limit must be between 1 and 500';
  END IF;

  SELECT event.session_id
  INTO v_session_id
  FROM public.session_events AS event
  WHERE event.event_type = 'session_recording'
    AND event.session_id IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.session_events AS duplicate
      WHERE duplicate.event_type = 'session_recording'
        AND duplicate.session_id = event.session_id
        AND duplicate.id <> event.id
    )
  ORDER BY event.session_id, event.created_at, event.id
  LIMIT 1;

  IF v_session_id IS NULL THEN
    RETURN jsonb_build_object('state', 'complete', 'merged_rows', 0);
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_session_id::text, 0)
  );

  SELECT array_agg(candidate.id ORDER BY candidate.created_at, candidate.id)
  INTO v_row_ids
  FROM (
    SELECT id, created_at
    FROM public.session_events
    WHERE event_type = 'session_recording'
      AND session_id = v_session_id
    ORDER BY created_at, id
    LIMIT p_row_limit + 1
    FOR UPDATE
  ) AS candidate;

  IF COALESCE(array_length(v_row_ids, 1), 0) < 2 THEN
    RETURN jsonb_build_object('state', 'retry', 'merged_rows', 0);
  END IF;
  v_canonical_id := v_row_ids[1];

  IF EXISTS (
    SELECT 1
    FROM (
      SELECT manifest.key AS chunk_id
      FROM public.session_events AS event
      CROSS JOIN LATERAL jsonb_each(
        CASE
          WHEN jsonb_typeof(event.properties->'chunk_manifest') = 'object'
            THEN event.properties->'chunk_manifest'
          ELSE '{}'::jsonb
        END
      ) AS manifest
      WHERE event.id = ANY(v_row_ids)
      GROUP BY manifest.key
      HAVING count(DISTINCT manifest.value) > 1
    ) AS conflicts
  ) THEN
    RAISE EXCEPTION
      'Cannot consolidate session % because chunk manifests conflict',
      v_session_id;
  END IF;

  WITH recording_rows AS (
    SELECT
      event.id,
      event.created_at,
      event.timestamp,
      CASE
        WHEN jsonb_typeof(event.properties) = 'object' THEN event.properties
        ELSE '{}'::jsonb
      END AS properties
    FROM public.session_events AS event
    WHERE event.id = ANY(v_row_ids)
  ),
  unique_recording_rows AS (
    SELECT DISTINCT ON (chunk_identity)
      id,
      created_at,
      timestamp,
      properties
    FROM (
      SELECT
        row.*,
        CASE
          WHEN row.properties->'chunk_manifest' <> '{}'::jsonb
            THEN COALESCE(
              (
                SELECT jsonb_agg(
                  manifest.value->>'content_hash'
                  ORDER BY manifest.value->>'content_hash'
                )
                FROM jsonb_each(
                  row.properties->'chunk_manifest'
                ) AS manifest
              ),
              row.properties->'chunk_manifest'
            )
          WHEN row.properties->'chunks' <> '[]'::jsonb
            THEN row.properties->'chunks'
          ELSE jsonb_build_object('row_id', row.id)
        END AS chunk_identity
      FROM recording_rows AS row
    ) AS identified
    ORDER BY chunk_identity, created_at, id
  ),
  latest_metadata AS (
    SELECT
      CASE
        WHEN jsonb_typeof(properties->'metadata') = 'object'
          THEN properties->'metadata'
        ELSE '{}'::jsonb
      END AS metadata
    FROM unique_recording_rows
    ORDER BY created_at DESC, id DESC
    LIMIT 1
  ),
  recording_stats AS (
    SELECT
      min(
        CASE
          WHEN COALESCE(properties->>'start_time', '') ~ '^[0-9]{1,19}$'
            THEN (properties->>'start_time')::bigint
          ELSE timestamp
        END
      ) AS start_time,
      max(
        CASE
          WHEN COALESCE(properties->>'end_time', '') ~ '^[0-9]{1,19}$'
            THEN (properties->>'end_time')::bigint
          ELSE timestamp
        END
      ) AS end_time,
      max(
        CASE
          WHEN COALESCE(properties->>'last_chunk_at', '') ~ '^[0-9]{1,19}$'
            THEN (properties->>'last_chunk_at')::bigint
          ELSE timestamp
        END
      ) AS last_chunk_at,
      max(timestamp) AS event_timestamp,
      sum(
        CASE
          WHEN COALESCE(properties->>'total_events', '') ~ '^[0-9]{1,19}$'
            THEN (properties->>'total_events')::bigint
          ELSE 0
        END
      ) AS total_events
    FROM unique_recording_rows
  ),
  ledger_stats AS (
    SELECT
      CASE
        WHEN count(*) > 0 AND count(chunk.event_count) = count(*)
          THEN sum(chunk.event_count)::bigint
      END AS total_events
    FROM public.session_recording_chunks AS chunk
    WHERE chunk.session_id = v_session_id
  ),
  path_values AS (
    SELECT
      source.path,
      min(source.created_at) AS first_seen
    FROM (
      SELECT row.created_at, chunk_path.value AS path
      FROM recording_rows AS row
      CROSS JOIN LATERAL jsonb_array_elements_text(
        CASE
          WHEN jsonb_typeof(row.properties->'chunks') = 'array'
            THEN row.properties->'chunks'
          ELSE '[]'::jsonb
        END
      ) AS chunk_path
      UNION ALL
      SELECT row.created_at, manifest.value->>'path' AS path
      FROM recording_rows AS row
      CROSS JOIN LATERAL jsonb_each(
        CASE
          WHEN jsonb_typeof(row.properties->'chunk_manifest') = 'object'
            THEN row.properties->'chunk_manifest'
          ELSE '{}'::jsonb
        END
      ) AS manifest
    ) AS source
    WHERE source.path IS NOT NULL
      AND source.path <> ''
    GROUP BY source.path
  ),
  merged_paths AS (
    SELECT jsonb_agg(path ORDER BY first_seen, path) AS chunks
    FROM path_values
  ),
  manifest_values AS (
    SELECT DISTINCT ON (manifest.key)
      manifest.key AS chunk_id,
      manifest.value AS chunk_value
    FROM recording_rows AS row
    CROSS JOIN LATERAL jsonb_each(
      CASE
        WHEN jsonb_typeof(row.properties->'chunk_manifest') = 'object'
          THEN row.properties->'chunk_manifest'
        ELSE '{}'::jsonb
      END
    ) AS manifest
    ORDER BY manifest.key, row.created_at ASC, row.id ASC
  ),
  merged_manifest AS (
    SELECT jsonb_object_agg(chunk_id, chunk_value ORDER BY chunk_id)
      AS chunk_manifest
    FROM manifest_values
  )
  UPDATE public.session_events AS target
  SET
    timestamp = stats.event_timestamp,
    properties = (
      CASE
        WHEN jsonb_typeof(target.properties) = 'object' THEN target.properties
        ELSE '{}'::jsonb
      END
    ) || jsonb_build_object(
      'chunks', COALESCE(paths.chunks, '[]'::jsonb),
      'chunk_manifest', COALESCE(manifest.chunk_manifest, '{}'::jsonb),
      'start_time', stats.start_time,
      'end_time', stats.end_time,
      'duration', GREATEST(0, stats.end_time - stats.start_time),
      'total_events', COALESCE(ledger.total_events, stats.total_events),
      'last_chunk_at', stats.last_chunk_at,
      'metadata', metadata.metadata
    ),
    updated_at = timezone('utc', now())
  FROM recording_stats AS stats
  CROSS JOIN ledger_stats AS ledger
  CROSS JOIN latest_metadata AS metadata
  CROSS JOIN merged_paths AS paths
  CROSS JOIN merged_manifest AS manifest
  WHERE target.id = v_canonical_id;

  UPDATE public.session_recording_chunks
  SET recording_event_id = v_canonical_id
  WHERE session_id = v_session_id
    AND recording_event_id = ANY(v_row_ids)
    AND recording_event_id <> v_canonical_id;

  DELETE FROM public.session_events
  WHERE id = ANY(v_row_ids)
    AND id <> v_canonical_id;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  SELECT EXISTS (
    SELECT 1
    FROM public.session_events
    WHERE event_type = 'session_recording'
      AND session_id = v_session_id
      AND id <> v_canonical_id
  )
  INTO v_has_more;

  RETURN jsonb_build_object(
    'state', CASE WHEN v_has_more THEN 'pending' ELSE 'session_complete' END,
    'session_id', v_session_id,
    'merged_rows', v_deleted,
    'has_more', v_has_more
  );
END;
$_$;


--
-- Name: control_harness_session(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.control_harness_session(p_id uuid, p_site_id uuid, p_action text, p_message text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_sessions%ROWTYPE; s jsonb; result jsonb;
BEGIN
  IF p_action IS NULL OR p_action NOT IN ('pause','cancel','resume') OR length(p_message)>20000 THEN
    RAISE EXCEPTION 'Invalid harness control' USING ERRCODE='22023';
  END IF;
  SELECT * INTO r FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF r.snapshot->>'status' IN ('completed','cancelled')
    OR (p_action='resume' AND r.lease_expires_at>clock_timestamp()) THEN RETURN NULL; END IF;
  s:=r.snapshot||jsonb_build_object('status',CASE p_action WHEN 'resume' THEN 'queued' WHEN 'pause' THEN 'paused' ELSE 'cancelled' END);
  IF p_action IN ('pause','cancel') THEN
    s:=s||jsonb_build_object('reason',CASE p_action WHEN 'pause' THEN 'user_pause' ELSE 'user_cancel' END);
  END IF;
  IF p_action='resume' AND p_message IS NOT NULL AND length(p_message)>0 THEN
    s:=jsonb_set(s,'{messages}',(s->'messages')||jsonb_build_array(jsonb_build_object('role','user','content',p_message)));
  END IF;
  UPDATE public.harness_sessions SET version=version+1,lease_owner=NULL,lease_expires_at=NULL,
    snapshot=s||jsonb_build_object('version',version+1,'updatedAt',clock_timestamp())
    WHERE id=p_id AND site_id=p_site_id RETURNING snapshot INTO result;
  RETURN result;
END;
$$;


--
-- Name: create_payout_request(uuid, numeric, jsonb, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_payout_request(p_site_id uuid, p_requested_credits numeric, p_bank_details jsonb, p_requested_by uuid, p_idempotency_key text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_request public.payout_requests;
BEGIN
  IF p_requested_credits IS NULL OR p_requested_credits <= 0 THEN
    RAISE EXCEPTION 'Requested credits must be greater than zero';
  END IF;
  IF p_bank_details IS NULL OR jsonb_typeof(p_bank_details) <> 'object' THEN
    RAISE EXCEPTION 'Bank details must be an object';
  END IF;
  IF p_idempotency_key IS NULL
    OR length(p_idempotency_key) < 16
    OR length(p_idempotency_key) > 128 THEN
    RAISE EXCEPTION 'Invalid idempotency key';
  END IF;

  IF NOT (
    EXISTS (
      SELECT 1
      FROM public.sites s
      WHERE s.id = p_site_id
        AND s.user_id = p_requested_by
    )
    OR EXISTS (
      SELECT 1
      FROM public.site_ownership so
      WHERE so.site_id = p_site_id
        AND so.user_id = p_requested_by
    )
    OR EXISTS (
      SELECT 1
      FROM public.site_members sm
      WHERE sm.site_id = p_site_id
        AND sm.user_id = p_requested_by
        AND sm.status = 'active'
        AND sm.role IN ('owner', 'admin')
    )
  ) THEN
    RAISE EXCEPTION 'Requester is not authorized';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_site_id::text || ':' || p_idempotency_key, 0)
  );

  SELECT *
  INTO v_request
  FROM public.payout_requests
  WHERE site_id = p_site_id
    AND idempotency_key = p_idempotency_key;

  IF FOUND THEN
    RETURN to_jsonb(v_request);
  END IF;

  PERFORM public.deduct_balance(p_site_id, p_requested_credits);

  INSERT INTO public.payout_requests (
    site_id,
    requested_credits,
    status,
    bank_details,
    requested_by,
    idempotency_key
  )
  VALUES (
    p_site_id,
    p_requested_credits,
    'pending',
    p_bank_details,
    p_requested_by,
    p_idempotency_key
  )
  RETURNING * INTO v_request;

  RETURN to_jsonb(v_request);
END;
$$;


--
-- Name: current_user_has_location_restrictions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_user_has_location_restrictions() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.site_members m
    JOIN public.site_member_location_restrictions r
      ON r.site_id = m.site_id AND r.site_member_id = m.id
    WHERE m.user_id = auth.uid()
      AND coalesce(public.current_user_site_role(m.site_id), '') NOT IN ('owner','admin')
  );
$$;


--
-- Name: current_user_has_site_location_restrictions(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_user_has_site_location_restrictions(p_site_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
  SELECT CASE
    WHEN auth.uid() IS NULL OR public.current_user_site_role(p_site_id) IS NULL THEN true
    WHEN public.current_user_site_role(p_site_id) IN ('owner','admin') THEN false
    ELSE EXISTS (
      SELECT 1 FROM public.site_members m
      JOIN public.site_member_location_restrictions r
        ON r.site_id=m.site_id AND r.site_member_id=m.id
      WHERE m.site_id=p_site_id AND m.user_id=auth.uid()
    )
  END;
$$;


--
-- Name: current_user_location_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_user_location_access(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  effective_role text; member_id uuid; member_count integer;
  restrictions uuid[]; current_revision integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Authentication required';
  END IF;
  effective_role := public.current_user_site_role(p_site_id);
  IF effective_role IS NULL OR effective_role NOT IN ('owner', 'admin', 'collaborator', 'marketing') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Site access denied';
  END IF;
  SELECT count(*), (array_agg(sm.id))[1] INTO member_count, member_id
    FROM public.site_members sm WHERE sm.site_id = p_site_id
      AND sm.user_id = auth.uid() AND sm.status = 'active';
  -- A primary owner need not have a membership row. All other valid roles do.
  IF member_count > 1 OR (member_count = 0 AND effective_role <> 'owner') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Site access denied';
  END IF;
  SELECT coalesce(array_agg(r.location_id ORDER BY r.location_id), '{}'::uuid[]) INTO restrictions
    FROM public.site_member_location_restrictions r
    WHERE r.site_id = p_site_id AND r.site_member_id = member_id;
  SELECT coalesce(max(a.revision), 0) INTO current_revision
    FROM public.site_member_location_restriction_audit a
    WHERE a.site_id = p_site_id AND a.site_member_id = member_id;
  RETURN jsonb_build_object('site_id', p_site_id, 'role', effective_role,
    'restricted_location_ids', restrictions, 'revision', current_revision);
END;
$$;

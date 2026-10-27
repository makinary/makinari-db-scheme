SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: transfer_requirement_migration_execution(uuid, text, integer, integer, uuid, uuid, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.transfer_requirement_migration_execution(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    SET "TimeZone" TO 'UTC'
    AS $_$
DECLARE
  r public.requirements%ROWTYPE;
  i public.remote_instances%ROWTYPE;
  old_row public.requirement_migration_lifecycle%ROWTYPE;
  new_row public.requirement_migration_lifecycle%ROWTYPE;
  saved public.requirement_migration_execution_handoffs%ROWTYPE;
  v_diagnostic jsonb;
  v_generation text;
  v_keys text[] := ARRAY['apps_project_ref','tenant_id','schema','sandbox_name','file','observed_at',
    'sql_checksum','specification_checksum','receipt_found','feedback_registered','feedback_checksum'];
  v_key text;
  v_observed timestamptz;
  v_now timestamptz;
BEGIN
  IF p_requirement_id IS NULL OR p_instance_id IS NULL OR p_request_id IS NULL
    OR p_file IS NULL OR octet_length(p_file) > 512
    OR p_file !~ '^(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*\.sql$'
    OR p_expected_version IS NULL OR p_expected_version NOT BETWEEN 1 AND 2147483646
    OR p_expected_execution_generation IS NULL OR p_expected_execution_generation NOT BETWEEN 0 AND 2147483646
    OR p_operator_id IS NULL OR p_operator_id !~ '[^[:space:]]' OR char_length(p_operator_id) > 200
    OR p_reason IS NULL OR p_reason !~ '[^[:space:]]' OR char_length(p_reason) > 2000
    OR jsonb_typeof(p_evidence) IS DISTINCT FROM 'object' OR octet_length(p_evidence::text) > 4096 THEN
    RAISE EXCEPTION 'Invalid migration execution handoff input' USING ERRCODE = '22023';
  END IF;
  -- Requirement first serializes absent-row checks with lifecycle/diagnostic RPCs.
  SELECT * INTO r FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Handoff requirement missing' USING ERRCODE = 'P0002'; END IF;
  SELECT * INTO saved FROM public.requirement_migration_execution_handoffs WHERE id = p_request_id;
  IF FOUND THEN
    IF saved.requirement_id IS DISTINCT FROM p_requirement_id OR saved.file IS DISTINCT FROM p_file
      OR saved.instance_id IS DISTINCT FROM p_instance_id OR saved.transferred_version <> p_expected_version + 1
      OR saved.execution_generation <> p_expected_execution_generation
      OR saved.operator_id IS DISTINCT FROM p_operator_id OR saved.reason IS DISTINCT FROM p_reason
      OR saved.evidence IS DISTINCT FROM p_evidence THEN
      RAISE EXCEPTION 'Handoff request identity conflict' USING ERRCODE = '23505';
    END IF;
    -- Historical read, even after pause/resume, spec changes or evidence expiry.
    RETURN jsonb_build_object('receipt_id', saved.id, 'state', 'transferred', 'resumed', false);
  END IF;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_execution_handoffs
    WHERE requirement_id = r.id AND file = p_file) THEN
    RAISE EXCEPTION 'Migration execution already transferred' USING ERRCODE = '23505';
  END IF;
  IF r.status IS DISTINCT FROM 'blocked' OR r.cron_lock_active IS DISTINCT FROM false
    OR r.cron_lock_expires_at > clock_timestamp() THEN
    RAISE EXCEPTION 'Handoff requires an idle blocked requirement' USING ERRCODE = '40001';
  END IF;
  IF jsonb_typeof(r.metadata) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid handoff metadata' USING ERRCODE = '22023';
  END IF;
  v_generation := CASE WHEN r.metadata ? 'requirement_execution_generation'
    THEN r.metadata->>'requirement_execution_generation' ELSE '0' END;
  IF v_generation IS NULL OR v_generation !~ '^(0|[1-9][0-9]{0,9})$' THEN
    RAISE EXCEPTION 'Invalid handoff execution generation' USING ERRCODE = '22023';
  END IF;
  IF v_generation::bigint <> p_expected_execution_generation::bigint
    OR r.metadata->>'runner_instance_id' IS DISTINCT FROM p_instance_id::text THEN
    RAISE EXCEPTION 'Stale handoff generation or runner' USING ERRCODE = '40001';
  END IF;
  PERFORM 1 FROM public.requirement_migration_lifecycle WHERE requirement_id = r.id ORDER BY file FOR UPDATE;
  SELECT * INTO old_row FROM public.requirement_migration_lifecycle WHERE requirement_id = r.id AND file = p_file;
  IF NOT FOUND OR old_row.version <> p_expected_version THEN
    RAISE EXCEPTION 'Stale handoff lifecycle version' USING ERRCODE = '40001';
  END IF;
  IF old_row.state NOT IN ('platform_review','correction_required')
    OR (old_row.review IS NOT NULL AND (jsonb_typeof(old_row.review) <> 'object'
      OR old_row.review->>'decision' = 'approved_for_validation')) THEN
    RAISE EXCEPTION 'Migration is not eligible for execution handoff' USING ERRCODE = '23514';
  END IF;
  PERFORM 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = r.id ORDER BY file FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = r.id
    AND state IN ('running','followup_reviewing')) THEN
    RAISE EXCEPTION 'Migration diagnosis is active or consumed by review' USING ERRCODE = '23514';
  END IF;
  SELECT to_jsonb(d) INTO v_diagnostic FROM public.requirement_migration_diagnostics d
    WHERE requirement_id = r.id AND file = p_file;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_reconciliations h WHERE h.requirement_id = r.id
    AND NOT EXISTS (SELECT 1 FROM public.requirement_migration_reconciliation_resumes s WHERE s.receipt_id = h.id)) THEN
    RAISE EXCEPTION 'Migration reconciliation still requires its own resume' USING ERRCODE = '23514';
  END IF;
  SELECT * INTO i FROM public.remote_instances WHERE id = p_instance_id FOR UPDATE;
  IF NOT FOUND OR i.site_id IS DISTINCT FROM r.site_id OR i.is_archived IS DISTINCT FROM false
    OR COALESCE(i.status, '') NOT IN ('pending','running') THEN
    RAISE EXCEPTION 'Handoff runner is not eligible' USING ERRCODE = '40001';
  END IF;
  PERFORM 1 FROM public.instance_plans WHERE instance_id = i.id OR metadata->>'requirement_id' = r.id::text
    ORDER BY id FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.instance_plans WHERE metadata->>'requirement_id' = r.id::text
    AND COALESCE(metadata->>'workflow_template','false') <> 'true' AND status = 'paused') THEN
    RAISE EXCEPTION 'Handoff cannot consume a manual plan pause' USING ERRCODE = '40001';
  END IF;
  -- The existing visibility trigger clears platform holds on transition. Never
  -- let it erase unrelated metadata. Other lifecycle rows remain untouched.
  IF (r.metadata ? 'execution_hold' AND NOT (
      r.metadata#>>'{execution_hold,kind}' IS NOT DISTINCT FROM 'migration_platform_review'
      AND r.metadata#>>'{execution_hold,file}' IS NOT DISTINCT FROM p_file))
    OR NULLIF(r.metadata->>'cron_blocker_provenance', '') IS NOT NULL THEN
    RAISE EXCEPTION 'Requirement has another execution hold' USING ERRCODE = '23514';
  END IF;
  IF r.instructions IS NULL OR r.instructions !~ '[^[:space:]]' OR octet_length(r.instructions) > 65536 THEN
    RAISE EXCEPTION 'Canonical specification missing' USING ERRCODE = '23514';
  END IF;
  IF NOT (p_evidence ?& v_keys) OR (p_evidence - v_keys) <> '{}'::jsonb THEN
    RAISE EXCEPTION 'Invalid handoff evidence keys' USING ERRCODE = '22023';
  END IF;
  FOREACH v_key IN ARRAY v_keys LOOP
    IF v_key NOT IN ('receipt_found','feedback_registered') AND jsonb_typeof(p_evidence->v_key) IS DISTINCT FROM 'string' THEN
      RAISE EXCEPTION 'Invalid handoff evidence type' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  IF p_evidence->>'apps_project_ref' !~ '^[a-z]{20}$'
    OR p_evidence->>'tenant_id' !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    OR p_evidence->>'schema' IS DISTINCT FROM 'app_' || left(replace(r.id::text, '-', ''), 24)
    OR p_evidence->>'sandbox_name' IS DISTINCT FROM 'req-' || left(r.id::text, 8) || '-' || left(i.id::text, 8)
    OR p_evidence->>'file' IS DISTINCT FROM p_file
    OR p_evidence->>'sql_checksum' !~ '^[a-f0-9]{64}$'
    OR p_evidence->>'feedback_checksum' IS DISTINCT FROM p_evidence->>'sql_checksum'
    OR p_evidence->>'specification_checksum' IS DISTINCT FROM encode(sha256(convert_to(r.instructions, 'UTF8')), 'hex')
    OR p_evidence->'receipt_found' IS DISTINCT FROM 'false'::jsonb
    OR p_evidence->'feedback_registered' IS DISTINCT FROM 'true'::jsonb
    OR p_evidence->>'observed_at' !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$' THEN
    RAISE EXCEPTION 'Handoff evidence scope mismatch' USING ERRCODE = '22023';
  END IF;
  BEGIN
    v_observed := (p_evidence->>'observed_at')::timestamptz;
  EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN
    RAISE EXCEPTION 'Invalid handoff observation time' USING ERRCODE = '22023';
  END;
  v_now := clock_timestamp();
  IF NOT isfinite(v_observed) OR v_observed < v_now - interval '5 minutes' OR v_observed > v_now THEN
    RAISE EXCEPTION 'Stale or future handoff evidence' USING ERRCODE = '40001';
  END IF;
  -- Insert BEFORE updating the row; every later failure rolls back both.
  INSERT INTO public.requirement_migration_execution_handoffs
    (id,requirement_id,file,site_id,instance_id,operator_id,reason,prior_lifecycle,prior_diagnostic,
      evidence,execution_generation,transferred_version,created_at)
    VALUES (p_request_id,r.id,p_file,r.site_id,i.id,p_operator_id,p_reason,to_jsonb(old_row),v_diagnostic,
      p_evidence,p_expected_execution_generation,old_row.version + 1,v_now);
  UPDATE public.requirement_migration_lifecycle SET state = 'transferred', version = old_row.version + 1,
    updated_at = v_now WHERE requirement_id = r.id AND file = p_file RETURNING * INTO new_row;
  IF NOT public.migration_execution_handoff_matches(new_row) THEN
    RAISE EXCEPTION 'Handoff lifecycle changed unexpectedly' USING ERRCODE = '40001';
  END IF;
  -- correction_required may still have a stale projection; remove only this
  -- file's projection. Never clear another hold published by the visibility RPC.
  UPDATE public.requirements SET metadata = metadata - 'execution_hold' WHERE id = r.id
    AND metadata#>>'{execution_hold,kind}' = 'migration_platform_review'
    AND metadata#>>'{execution_hold,file}' = p_file;
  INSERT INTO public.instance_logs(instance_id,site_id,log_type,level,message,details)
    VALUES (i.id,r.site_id,'system','info','Legacy migration execution authority transferred; execution remains blocked. No validation was granted.',
      jsonb_build_object('event','migration_execution_handoff','receipt_id',p_request_id,
        'requirement_id',r.id,'transferred_version',new_row.version,
        'execution_generation',p_expected_execution_generation,'state','transferred','resumed',false));
  RETURN jsonb_build_object('receipt_id',p_request_id,'state','transferred','resumed',false);
END;
$_$;


--
-- Name: transition_requirement_migration(uuid, text, integer, integer, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.transition_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_value jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_metadata jsonb;
  v_generation_text text;
  v_generation integer;
  v_previous public.requirement_migration_lifecycle%ROWTYPE;
  v_result public.requirement_migration_lifecycle%ROWTYPE;
  v_exists boolean;
  v_state text;
  v_checksum text;
  v_specification_checksum text;
  v_original_sql text;
  v_reason text;
  v_review jsonb;
  v_attempts integer;
BEGIN
  IF p_requirement_id IS NULL OR p_file IS NULL OR octet_length(p_file) > 512
    OR p_file !~ '^(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*\.sql$'
    OR p_expected_version IS NULL OR p_expected_version < 0 OR p_expected_version >= 2147483647
    OR p_expected_execution_generation IS NULL OR p_expected_execution_generation < 0
    OR jsonb_typeof(p_value) IS DISTINCT FROM 'object'
  THEN
    RAISE EXCEPTION 'Invalid migration lifecycle input' USING ERRCODE = '22023';
  END IF;

  IF jsonb_typeof(p_value->'state') IS DISTINCT FROM 'string'
    OR jsonb_typeof(p_value->'checksum') IS DISTINCT FROM 'string'
    OR jsonb_typeof(p_value->'specification_checksum') IS DISTINCT FROM 'string'
    OR jsonb_typeof(p_value->'reason') IS DISTINCT FROM 'string'
    OR jsonb_typeof(p_value->'attempts') IS DISTINCT FROM 'number'
    OR (p_value ? 'original_sql' AND jsonb_typeof(p_value->'original_sql') NOT IN ('string', 'null'))
    OR EXISTS (SELECT 1 FROM jsonb_object_keys(p_value) AS fields(key)
      WHERE key NOT IN ('state', 'checksum', 'specification_checksum', 'original_sql', 'reason', 'review', 'attempts'))
  THEN
    RAISE EXCEPTION 'Invalid migration lifecycle value' USING ERRCODE = '22023';
  END IF;

  v_state := p_value->>'state';
  v_checksum := p_value->>'checksum';
  v_specification_checksum := p_value->>'specification_checksum';
  v_original_sql := p_value->>'original_sql';
  v_reason := p_value->>'reason';
  IF v_state NOT IN ('correction_required', 'reviewing', 'validation_pending', 'validated', 'platform_review')
    OR v_checksum !~ '^[a-f0-9]{64}$' OR v_specification_checksum !~ '^[a-f0-9]{64}$'
    OR octet_length(v_original_sql) > 65536 OR char_length(v_reason) > 2048
    OR (p_value->>'attempts') !~ '^[0-5]$'
  THEN
    RAISE EXCEPTION 'Invalid migration lifecycle value' USING ERRCODE = '22023';
  END IF;
  v_attempts := (p_value->>'attempts')::integer;

  -- This lock also serializes absent-row inserts and requirements status changes.
  -- Always acquire it BEFORE the lifecycle lock. No advisory/GUC bypass exists.
  SELECT metadata INTO v_metadata FROM public.requirements
    WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Migration requirement does not exist' USING ERRCODE = 'P0002';
  END IF;
  IF v_metadata IS NOT NULL AND jsonb_typeof(v_metadata) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid requirement execution generation' USING ERRCODE = '22023';
  END IF;
  IF COALESCE(v_metadata ? 'requirement_execution_generation', false) THEN
    v_generation_text := v_metadata->>'requirement_execution_generation';
    IF v_generation_text IS NULL OR v_generation_text !~ '^(0|[1-9][0-9]{0,9})$' THEN
      RAISE EXCEPTION 'Invalid requirement execution generation' USING ERRCODE = '22023';
    END IF;
    IF v_generation_text::bigint > 2147483647 THEN
      RAISE EXCEPTION 'Invalid requirement execution generation' USING ERRCODE = '22023';
    END IF;
    v_generation := v_generation_text::integer;
  ELSE
    v_generation := 0;
  END IF;
  IF v_generation IS DISTINCT FROM p_expected_execution_generation THEN
    RAISE EXCEPTION 'Stale requirement execution generation' USING ERRCODE = '40001';
  END IF;

  SELECT * INTO v_previous FROM public.requirement_migration_lifecycle
    WHERE requirement_id = p_requirement_id AND file = p_file FOR UPDATE;
  v_exists := FOUND;
  IF (NOT v_exists AND p_expected_version <> 0)
    OR (v_exists AND v_previous.version <> p_expected_version)
  THEN
    RAISE EXCEPTION 'Migration lifecycle version conflict' USING ERRCODE = '40001';
  END IF;

  IF NOT v_exists THEN
    IF v_state NOT IN ('correction_required', 'reviewing', 'platform_review')
      OR (v_state = 'reviewing' AND v_attempts <> 1)
    THEN
      RAISE EXCEPTION 'Invalid initial migration lifecycle state' USING ERRCODE = '23514';
    END IF;
  ELSE
    -- A reviewing row is a durable lease, not an expiring retry hint. An
    -- interrupted reviewer must be reconciled, not silently reacquired/reset.
    IF NOT (
      (v_previous.state = 'correction_required' AND v_state IN ('correction_required', 'reviewing', 'platform_review'))
      OR (v_previous.state = 'reviewing' AND v_state IN ('correction_required', 'validation_pending', 'platform_review'))
      -- A known atomic SQL rollback may be sent back for correction.
      OR (v_previous.state = 'validation_pending' AND v_state IN ('correction_required', 'validated', 'platform_review'))
      OR (v_previous.state = 'validated' AND v_state = 'platform_review')
      -- Only this service-role RPC can explicitly release a platform hold.
      -- Release does not reopen the requirement or skip fresh validation.
      OR (v_previous.state = 'platform_review' AND v_state IN ('platform_review', 'correction_required', 'validation_pending'))
    ) THEN
      RAISE EXCEPTION 'Invalid migration lifecycle transition' USING ERRCODE = '23514';
    END IF;
    IF v_attempts < v_previous.attempts
      OR (v_state = 'reviewing' AND v_attempts <> v_previous.attempts + 1)
    THEN
      RAISE EXCEPTION 'Migration review attempts cannot reset or reuse a lease' USING ERRCODE = '23514';
    END IF;
    IF v_specification_checksum IS DISTINCT FROM v_previous.specification_checksum THEN
      RAISE EXCEPTION 'Migration specification checksum is immutable' USING ERRCODE = '23514';
    END IF;
    IF v_checksum IS DISTINCT FROM v_previous.checksum AND NOT (
      v_previous.state = 'correction_required' AND v_state IN ('correction_required', 'reviewing')
    ) THEN
      RAISE EXCEPTION 'Reviewed migration checksum is immutable' USING ERRCODE = '23514';
    END IF;
    IF NOT (p_value ? 'original_sql') THEN
      v_original_sql := v_previous.original_sql;
    ELSIF v_previous.original_sql IS NOT NULL AND v_original_sql IS DISTINCT FROM v_previous.original_sql THEN
      RAISE EXCEPTION 'Original migration SQL is immutable' USING ERRCODE = '23514';
    END IF;
  END IF;
  v_review := CASE WHEN p_value ? 'review' THEN NULLIF(p_value->'review', 'null'::jsonb)
    ELSE v_previous.review END;

  IF v_exists THEN
    UPDATE public.requirement_migration_lifecycle SET
      version = v_previous.version + 1, state = v_state, checksum = v_checksum,
      specification_checksum = v_specification_checksum, original_sql = v_original_sql,
      reason = v_reason, review = v_review, attempts = v_attempts, updated_at = clock_timestamp()
    WHERE requirement_id = p_requirement_id AND file = p_file RETURNING * INTO v_result;
  ELSE
    INSERT INTO public.requirement_migration_lifecycle (
      requirement_id, file, version, state, checksum, specification_checksum,
      original_sql, reason, review, attempts
    ) VALUES (
      p_requirement_id, p_file, 1, v_state, v_checksum, v_specification_checksum,
      v_original_sql, v_reason, v_review, v_attempts
    ) RETURNING * INTO v_result;
  END IF;

  IF v_state = 'platform_review' THEN
    UPDATE public.requirements SET status = 'blocked' WHERE id = p_requirement_id;
  END IF;
  RETURN to_jsonb(v_result);
END;
$_$;


--
-- Name: update_activity_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_activity_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_api_key_last_used(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_api_key_last_used() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  UPDATE public.api_keys
  SET last_used_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: update_content_performance_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_content_performance_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_conversation_last_message_time(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_conversation_last_message_time() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    -- Update the conversation's last_message_at timestamp
    -- Use explicit public schema reference since search_path is empty for security
    -- Only update if conversation_id is not null for performance
    IF NEW.conversation_id IS NOT NULL THEN
        UPDATE public.conversations 
        SET 
            last_message_at = NEW.created_at,  -- Use message timestamp instead of NOW() for consistency
            updated_at = NEW.created_at
        WHERE id = NEW.conversation_id;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: update_copywriting_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_copywriting_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_cron_status_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_cron_status_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

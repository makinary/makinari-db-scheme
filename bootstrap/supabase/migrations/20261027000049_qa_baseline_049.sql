SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: reconcile_instance_plan_status_atomic(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_instance_plan_status_atomic(p_plan_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_status text;
  v_steps jsonb;
  v_total integer;
  v_completed integer;
  v_has_runnable boolean;
  v_has_failed boolean;
  v_has_cancelled boolean;
  v_next_status text;
BEGIN
  SELECT
    status,
    CASE WHEN jsonb_typeof(steps) = 'array' THEN steps ELSE '[]'::jsonb END
  INTO v_status, v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'status', 'unknown');
  END IF;
  IF v_status IN ('paused', 'cancelled', 'completed', 'failed') THEN
    RETURN jsonb_build_object('state', 'guarded', 'status', v_status);
  END IF;

  SELECT
    count(*),
    count(*) FILTER (WHERE entry.value->>'status' = 'completed'),
    bool_or(
      entry.value->>'status' IN ('pending', 'in_progress')
      OR (
        entry.value->>'status' = 'failed'
        AND (CASE
          WHEN COALESCE(entry.value->>'retry_count', '') ~ '^[0-9]{1,9}$'
            THEN (entry.value->>'retry_count')::integer
          ELSE 0
        END) < 2
      )
    ),
    bool_or(entry.value->>'status' = 'failed'),
    bool_or(entry.value->>'status' IN ('cancelled', 'skipped'))
  INTO
    v_total, v_completed, v_has_runnable, v_has_failed, v_has_cancelled
  FROM jsonb_array_elements(v_steps) AS entry(value);

  v_next_status := 'in_progress';
  IF v_total > 0 AND v_completed = v_total THEN
    v_next_status := 'completed';
  ELSIF NOT COALESCE(v_has_runnable, false) AND COALESCE(v_has_failed, false) THEN
    v_next_status := 'failed';
  ELSIF NOT COALESCE(v_has_runnable, false) AND COALESCE(v_has_cancelled, false) THEN
    v_next_status := 'cancelled';
  END IF;

  UPDATE public.instance_plans
  SET
    status = v_next_status,
    steps_completed = v_completed,
    progress_percentage = CASE
      WHEN v_total = 0 THEN 0
      ELSE round((v_completed::numeric / v_total) * 100)::integer
    END,
    completed_at = CASE
      WHEN v_next_status = 'in_progress' THEN NULL
      ELSE COALESCE(completed_at, timezone('utc', now()))
    END,
    updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  RETURN jsonb_build_object(
    'state', 'applied',
    'status', v_next_status,
    'completed_count', v_completed,
    'total_count', v_total
  );
END;
$_$;


--
-- Name: reconcile_marketplace_provider_status(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_marketplace_provider_status(p_integration_id uuid, p_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations; connection public.marketplace_merchant_connections;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Provider status backend required' USING ERRCODE='42501'; END IF;
  IF p_status IS NULL OR p_status NOT IN ('active','inactive','pending','failed') THEN RAISE EXCEPTION 'Invalid provider status'; END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF NOT FOUND OR integration.merchant_connection_id IS NULL THEN RAISE EXCEPTION 'Merchant integration unavailable'; END IF;
  SELECT * INTO connection FROM public.marketplace_merchant_connections WHERE id=integration.merchant_connection_id FOR SHARE;
  IF NOT FOUND OR (connection.site_id,connection.provider,connection.environment,connection.country,connection.credential_mode)
    IS DISTINCT FROM (integration.site_id,integration.provider,integration.environment,integration.country,integration.credential_mode) THEN
    RAISE EXCEPTION 'Provider status authorization binding mismatch';
  END IF;
  IF p_status='active' THEN
    -- A provider still being active while disconnect is pending is not evidence
    -- that the local deactivation mutation failed. Never cancel its recovery.
    IF integration.provisioning_status='pending' AND integration.provisioning_operation='deactivate' THEN
      RETURN to_jsonb(integration);
    END IF;
    IF connection.status<>'authorized' OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(connection.authorized_stores) store
      WHERE store->>'id'=integration.external_store_id) THEN RAISE EXCEPTION 'Provider status authorization unavailable'; END IF;
    IF integration.provisioning_status='active' THEN RETURN to_jsonb(integration); END IF;
    IF integration.provisioning_status='pending' AND integration.provisioning_operation='activate' THEN
      RETURN public.apply_marketplace_provisioning(integration.id,'active');
    END IF;
    -- A previously completed/revoked receiver is not resurrected by a stale
    -- event. Explicit verified reauthorization starts a new activation claim.
    RETURN to_jsonb(integration);
  ELSIF p_status='inactive' THEN
    IF integration.provisioning_status='pending' AND integration.provisioning_operation='activate' THEN
      RETURN to_jsonb(integration);
    END IF;
    IF integration.provisioning_status='revoked' AND NOT integration.enabled THEN RETURN to_jsonb(integration); END IF;
    UPDATE public.marketplace_integrations SET enabled=false,provisioning_status='revoked',
      provisioning_operation='deactivate',provisioning_result='confirmed',updated_at=now()
      WHERE id=integration.id RETURNING * INTO integration;
  ELSIF p_status='pending' THEN
    IF integration.provisioning_status='pending' THEN RETURN to_jsonb(integration); END IF;
    IF connection.status<>'authorized' OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(connection.authorized_stores) store
      WHERE store->>'id'=integration.external_store_id) THEN RAISE EXCEPTION 'Provider status authorization unavailable'; END IF;
    UPDATE public.marketplace_integrations SET provisioning_status='pending',provisioning_operation='activate',
      provisioning_result='unknown',provisioning_claim_id=gen_random_uuid(),provider_batch_id=NULL,updated_at=now()
      WHERE id=integration.id RETURNING * INTO integration;
  ELSE
    IF integration.provisioning_status='pending' THEN RETURN public.apply_marketplace_provisioning(integration.id,'failed'); END IF;
  END IF;
  RETURN to_jsonb(integration);
END;
$$;


--
-- Name: reconcile_marketplace_provisioning(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_marketplace_provisioning(p_integration_id uuid, p_provider_batch_id text, p_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Provisioning backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF NOT FOUND OR integration.merchant_connection_id IS NULL OR (integration.provider_batch_id IS NOT NULL
    AND integration.provider_batch_id IS DISTINCT FROM p_provider_batch_id) THEN
    RAISE EXCEPTION 'Provider provisioning identity mismatch';
  END IF;
  -- Uber provisioned events have no asynchronous batch id. Rappi batch ids must
  -- match the one persisted from the provider response, never an unrelated store.
  IF integration.provider='rappi' AND (p_provider_batch_id IS NULL OR integration.provider_batch_id IS NULL) THEN
    RAISE EXCEPTION 'Provider batch receipt unavailable';
  END IF;
  RETURN public.apply_marketplace_provisioning(integration.id,p_status);
END;
$$;


--
-- Name: reconcile_marketplace_provisioning_status(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_marketplace_provisioning_status(p_integration_id uuid, p_actor_user_id uuid, p_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations; connection public.marketplace_merchant_connections;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Provisioning backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF NOT FOUND OR integration.merchant_connection_id IS NULL THEN RAISE EXCEPTION 'Merchant integration unavailable'; END IF;
  PERFORM public.marketplace_assert_actor(integration.site_id,p_actor_user_id,true);
  IF p_status IS NULL OR p_status NOT IN ('active','revoked','failed') THEN RAISE EXCEPTION 'Invalid provisioning status'; END IF;
  SELECT * INTO connection FROM public.marketplace_merchant_connections WHERE id=integration.merchant_connection_id FOR SHARE;
  IF NOT FOUND OR (connection.site_id,connection.provider,connection.environment,connection.country,connection.credential_mode)
    IS DISTINCT FROM (integration.site_id,integration.provider,integration.environment,integration.country,integration.credential_mode)
    THEN RAISE EXCEPTION 'Merchant status authorization mismatch'; END IF;
  IF p_status='active' AND (connection.status<>'authorized' OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(connection.authorized_stores) store WHERE store->>'id'=integration.external_store_id)) THEN
    RAISE EXCEPTION 'Merchant status authorization unavailable';
  END IF;
  IF integration.provisioning_status='pending' AND (
    integration.provisioning_operation IS NULL
    OR (p_status='active' AND integration.provisioning_operation<>'activate')
    OR (p_status='revoked' AND integration.provisioning_operation<>'deactivate')) THEN
    RAISE EXCEPTION 'Provisioning operation mismatch';
  END IF;
  -- The caller performs a fresh authoritative read through this exact app and
  -- store and completes required webhook registration before reporting active.
  -- Token expiry does not revoke already provisioned operational app access.
  -- This intentionally does not weaken signed-event batch matching.
  RETURN public.apply_marketplace_provisioning(integration.id,p_status);
END;
$$;


--
-- Name: reconcile_requirement_migration(uuid, text, integer, integer, timestamp with time zone, bigint, uuid, uuid, text, uuid, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_expected_updated_at timestamp with time zone, p_expected_backlog_revision bigint, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    SET "TimeZone" TO 'UTC'
    AS $_$
DECLARE
  r public.requirements%ROWTYPE;
  old_row public.requirement_migration_lifecycle%ROWTYPE;
  new_row public.requirement_migration_lifecycle%ROWTYPE;
  saved public.requirement_migration_reconciliations%ROWTYPE;
  v_request jsonb;
  v_keys text[] := ARRAY['apps_project_ref','tenant_id','schema','observed_at','sql_checksum',
    'receipt_found','sandbox_name','specification_checksum'];
  v_key text;
  v_hash text;
  v_observed timestamptz;
  v_now timestamptz;
BEGIN
  IF p_requirement_id IS NULL OR p_instance_id IS NULL OR p_plan_id IS NULL OR p_request_id IS NULL
    OR p_file IS NULL OR octet_length(p_file) > 512
    OR p_file !~ '^migrations/[A-Za-z0-9_-][A-Za-z0-9_.-]*\.sql$'
    OR p_expected_version IS NULL OR p_expected_version NOT BETWEEN 1 AND 2147483646
    OR p_expected_execution_generation IS NULL OR p_expected_execution_generation NOT BETWEEN 0 AND 2147483646
    OR p_expected_updated_at IS NULL OR NOT isfinite(p_expected_updated_at)
    OR p_expected_backlog_revision IS NULL OR p_expected_backlog_revision < 0
    OR p_step_id IS NULL OR p_step_id !~ '[^[:space:]]' OR char_length(p_step_id) > 200
    OR p_operator_id IS NULL OR p_operator_id !~ '[^[:space:]]' OR char_length(p_operator_id) > 200
    OR p_reason IS NULL OR p_reason !~ '[^[:space:]]' OR char_length(p_reason) > 2000
    OR jsonb_typeof(p_evidence) IS DISTINCT FROM 'object' OR octet_length(p_evidence::text) > 4096 THEN
    RAISE EXCEPTION 'Invalid migration reconciliation input' USING ERRCODE = '22023';
  END IF;
  v_request := jsonb_build_object('requirement_id', p_requirement_id, 'file', p_file,
    'expected_version', p_expected_version, 'expected_execution_generation', p_expected_execution_generation,
    'expected_updated_at', p_expected_updated_at, 'expected_backlog_revision', p_expected_backlog_revision,
    'instance_id', p_instance_id, 'plan_id', p_plan_id, 'step_id', p_step_id,
    'request_id', p_request_id, 'operator_id', p_operator_id, 'reason', p_reason, 'evidence', p_evidence);
  -- Serialize absence checks, CAS and transitions. Replays are historical reads,
  -- not renewed evidence or an instruction to mutate whatever is current now.
  PERFORM 1 FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  SELECT * INTO saved FROM public.requirement_migration_reconciliations WHERE id = p_request_id;
  IF FOUND THEN
    IF saved.request IS DISTINCT FROM v_request THEN
      RAISE EXCEPTION 'Reconciliation request conflict' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('receipt_id', saved.id, 'lifecycle', saved.lifecycle, 'resumed', false);
  END IF;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_reconciliations
    WHERE requirement_id = p_requirement_id AND file = p_file) THEN
    RAISE EXCEPTION 'Migration was already reconciled' USING ERRCODE = '23505';
  END IF;
  r := public.lock_migration_reconciliation_scope(p_requirement_id, p_file, p_instance_id,
    p_plan_id, p_step_id, p_expected_execution_generation, p_expected_backlog_revision);
  IF r.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION 'Stale reconciliation requirement' USING ERRCODE = '40001';
  END IF;
  SELECT * INTO old_row FROM public.requirement_migration_lifecycle
    WHERE requirement_id = r.id AND file = p_file;
  IF NOT FOUND OR old_row.version IS DISTINCT FROM p_expected_version THEN
    RAISE EXCEPTION 'Stale reconciliation lifecycle' USING ERRCODE = '40001';
  END IF;
  IF old_row.state <> 'platform_review' OR old_row.attempts <> 5
    OR old_row.reason <> 'A pending migration has no requirement-bound implementation plan; technical review is required.'
    OR (old_row.review IS NOT NULL AND (jsonb_typeof(old_row.review) IS DISTINCT FROM 'object'
      OR old_row.review->>'decision' IS DISTINCT FROM 'request_changes'
      OR (old_row.review ? 'reason' AND jsonb_typeof(old_row.review->'reason') IS DISTINCT FROM 'string')
      OR (old_row.review - ARRAY['decision','reason']) <> '{}'::jsonb)) THEN
    RAISE EXCEPTION 'Migration is not the legacy missing-plan hold' USING ERRCODE = '23514';
  END IF;
  IF r.instructions IS NULL OR r.instructions !~ '[^[:space:]]' OR octet_length(r.instructions) > 65536 THEN
    RAISE EXCEPTION 'Canonical specification missing' USING ERRCODE = '23514';
  END IF;
  v_hash := encode(sha256(convert_to(r.instructions, 'UTF8')), 'hex');
  IF v_hash = old_row.specification_checksum THEN
    RAISE EXCEPTION 'Reconciliation requires a changed specification' USING ERRCODE = '23514';
  END IF;
  -- Do not let the existing hold-visibility trigger erase a different hold.
  IF (r.metadata ? 'execution_hold' AND NOT (
      r.metadata#>>'{execution_hold,kind}' IS NOT DISTINCT FROM 'migration_platform_review'
      AND r.metadata#>>'{execution_hold,file}' IS NOT DISTINCT FROM p_file))
    OR NULLIF(r.metadata->>'cron_blocker_provenance', '') IS NOT NULL THEN
    RAISE EXCEPTION 'Requirement has another execution hold' USING ERRCODE = '23514';
  END IF;
  IF NOT (p_evidence ?& v_keys) OR (p_evidence - v_keys) <> '{}'::jsonb THEN
    RAISE EXCEPTION 'Invalid reconciliation evidence keys' USING ERRCODE = '22023';
  END IF;
  FOREACH v_key IN ARRAY v_keys LOOP
    IF v_key <> 'receipt_found' AND jsonb_typeof(p_evidence->v_key) IS DISTINCT FROM 'string' THEN
      RAISE EXCEPTION 'Invalid reconciliation evidence type' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  IF p_evidence->>'apps_project_ref' !~ '^[a-z]{20}$'
    OR p_evidence->>'tenant_id' !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    OR p_evidence->>'schema' !~ '^app_[a-f0-9]{24}$'
    OR p_evidence->>'schema' IS DISTINCT FROM 'app_' || left(replace(r.id::text, '-', ''), 24)
    OR p_evidence->'receipt_found' IS DISTINCT FROM 'false'::jsonb
    OR p_evidence->>'sql_checksum' IS DISTINCT FROM old_row.checksum
    OR p_evidence->>'specification_checksum' IS DISTINCT FROM v_hash
    OR p_evidence->>'sandbox_name' IS DISTINCT FROM 'req-' || left(r.id::text, 8) || '-' || left(p_instance_id::text, 8)
    OR p_evidence->>'observed_at' !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$' THEN
    RAISE EXCEPTION 'Reconciliation evidence scope mismatch' USING ERRCODE = '22023';
  END IF;
  BEGIN
    v_observed := (p_evidence->>'observed_at')::timestamptz;
  EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN
    RAISE EXCEPTION 'Invalid reconciliation observation time' USING ERRCODE = '22023';
  END;
  v_now := clock_timestamp();
  IF NOT isfinite(v_observed) OR v_observed < v_now - interval '5 minutes' OR v_observed > v_now + interval '30 seconds' THEN
    RAISE EXCEPTION 'Stale reconciliation evidence' USING ERRCODE = '40001';
  END IF;
  new_row := old_row;
  new_row.specification_checksum := v_hash;
  new_row.state := 'correction_required';
  new_row.review := NULL;
  new_row.version := old_row.version + 1;
  new_row.reason := 'Operator reconciled the legacy missing-plan specification binding. Fresh independent diagnosis, security review and validation remain mandatory; budgets are unchanged.';
  new_row.updated_at := v_now;
  -- Archive the complete original row BEFORE rebinding. Frozen response is also
  -- append-only; a retry never returns a later reviewer/validation transition.
  INSERT INTO public.requirement_migration_reconciliations
    (id,requirement_id,file,site_id,instance_id,plan_id,step_id,operator_id,reason,
      execution_generation,backlog_revision,prior_lifecycle,specification_checksum,specification,evidence,request,lifecycle)
    VALUES (p_request_id,r.id,p_file,r.site_id,p_instance_id,p_plan_id,p_step_id,p_operator_id,p_reason,
      p_expected_execution_generation,p_expected_backlog_revision,to_jsonb(old_row),v_hash,r.instructions,p_evidence,v_request,to_jsonb(new_row))
    RETURNING * INTO saved;
  UPDATE public.requirement_migration_lifecycle SET specification_checksum = new_row.specification_checksum,
    state = new_row.state, review = NULL, version = new_row.version, reason = new_row.reason, updated_at = new_row.updated_at
    WHERE requirement_id = r.id AND file = p_file RETURNING * INTO old_row;
  IF to_jsonb(old_row) IS DISTINCT FROM to_jsonb(new_row) THEN
    RAISE EXCEPTION 'Reconciliation transition changed unexpectedly' USING ERRCODE = '40001';
  END IF;
  INSERT INTO public.instance_logs(instance_id,site_id,log_type,level,message,details)
    VALUES (p_instance_id,r.site_id,'system','info','Migration specification reconciled; execution remains blocked.',
      jsonb_build_object('event','migration_operator_reconciliation','receipt_id',p_request_id,
        'requirement_id',r.id,'plan_id',p_plan_id,'step_id',p_step_id,'file',p_file,
        'receipt_found',false,'observed_at',v_observed,'sql_checksum',old_row.checksum,
        'specification_checksum',v_hash,'prior_specification_checksum',saved.prior_lifecycle->>'specification_checksum'));
  INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,message)
    VALUES (r.id,r.site_id,p_instance_id,'blocked',
      'Migration specification reconciled. Execution remains blocked until an explicit checked resume; fresh security review and validation are required.');
  RETURN jsonb_build_object('receipt_id',p_request_id,'lifecycle',to_jsonb(new_row),'resumed',false);
END;
$_$;


--
-- Name: reconcile_site_member_license(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reconcile_site_member_license(p_site_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE payload jsonb; owner_id uuid; capacity integer;
BEGIN
  PERFORM public.lock_site_license(p_site_id);
  SELECT user_id INTO owner_id FROM public.sites WHERE id = p_site_id;
  -- Ownership transfers clear both flags, including while the site is archived.
  UPDATE public.site_members SET manually_disabled = false,license_suspended = false
    WHERE site_id = p_site_id AND user_id = owner_id AND (manually_disabled OR license_suspended);
  payload := public.get_site_member_license(p_site_id);
  -- Other archived memberships retain their state until the site is restored.
  IF payload IS NULL THEN RETURN; END IF;
  capacity := coalesce((payload->>'limit')::integer - 1,2147483646);
  WITH ranked AS (
    SELECT id,row_number() OVER (ORDER BY created_at ASC NULLS LAST,id) AS position
    FROM public.site_members WHERE site_id = p_site_id AND user_id IS DISTINCT FROM owner_id
      AND status IN ('active','pending') AND NOT manually_disabled
  ) UPDATE public.site_members sm SET license_suspended = true FROM ranked r
    WHERE sm.id = r.id AND r.position > capacity AND NOT sm.license_suspended;
  WITH ranked AS (
    SELECT id,row_number() OVER (ORDER BY created_at ASC NULLS LAST,id) AS position
    FROM public.site_members WHERE site_id = p_site_id AND user_id IS DISTINCT FROM owner_id
      AND status IN ('active','pending') AND NOT manually_disabled
  ) UPDATE public.site_members sm SET license_suspended = false FROM ranked r
    WHERE sm.id = r.id AND r.position <= capacity AND sm.license_suspended;
  UPDATE public.site_members SET license_suspended = false WHERE site_id = p_site_id
    AND status NOT IN ('active','pending') AND NOT manually_disabled AND license_suspended;
END;
$$;

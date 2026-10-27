SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: publish_requirement_migration_hold(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.publish_requirement_migration_hold() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_requirement public.requirements%ROWTYPE;
  v_instance_id uuid;
  v_message text;
  v_hold jsonb;
  v_remaining public.requirement_migration_lifecycle%ROWTYPE;
  v_public_reason text;
BEGIN
  SELECT * INTO v_requirement FROM public.requirements
    WHERE id = NEW.requirement_id FOR UPDATE;
  IF NOT FOUND THEN RETURN NEW; END IF;

  IF NEW.state <> 'platform_review' THEN
    IF TG_OP = 'UPDATE' AND OLD.state = 'platform_review' THEN
      SELECT * INTO v_remaining FROM public.requirement_migration_lifecycle
        WHERE requirement_id = NEW.requirement_id AND state = 'platform_review'
        ORDER BY updated_at DESC, file LIMIT 1;
      IF FOUND THEN
        UPDATE public.requirements SET metadata = COALESCE(metadata, '{}'::jsonb) ||
          jsonb_build_object('execution_hold', jsonb_build_object('kind', 'migration_platform_review',
            'file', v_remaining.file, 'reason', 'Another database migration still requires technical reconciliation.', 'attempts', v_remaining.attempts,
            'updated_at', v_remaining.updated_at, 'resolution_actor', 'platform', 'user_action_required', false))
          WHERE id = NEW.requirement_id;
      ELSE
        UPDATE public.requirements SET metadata = COALESCE(metadata, '{}'::jsonb) - 'execution_hold'
          WHERE id = NEW.requirement_id;
      END IF;
    END IF;
    -- Clearing the projection does not reopen the requirement, instance or plan.
    RETURN NEW;
  END IF;

  -- Lifecycle reasons may contain SQL/provider diagnostics. Never copy those to
  -- browser-readable metadata or status messages; retain them in the private receipt.
  v_public_reason := CASE
    WHEN NEW.review ? 'diagnostic_id' THEN 'Independent migration diagnosis did not produce a validated correction. Technical reconciliation is required.'
    WHEN NEW.attempts >= 5 THEN 'The migration correction/review budget is exhausted. Technical reconciliation is required.'
    ELSE 'Database migration safety validation requires technical reconciliation.' END;
  v_hold := jsonb_build_object('kind', 'migration_platform_review', 'file', NEW.file,
    'reason', v_public_reason, 'attempts', NEW.attempts, 'updated_at', NEW.updated_at,
    'resolution_actor', 'platform', 'user_action_required', false);
  v_message := 'Execution blocked: ' || NEW.file || '. ' || v_public_reason ||
    ' Technical reconciliation is required; no customer approval is needed. ' ||
    'Updating a plan step does not resume execution. The attempt count records assignments/reviews, not proof of irreparability.';

  UPDATE public.requirements SET status = 'blocked', updated_at = clock_timestamp(),
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('execution_hold', v_hold)
    WHERE id = NEW.requirement_id;

  IF COALESCE(v_requirement.metadata->>'runner_instance_id', '')
    ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    SELECT id INTO v_instance_id FROM public.remote_instances
      WHERE id = (v_requirement.metadata->>'runner_instance_id')::uuid
        AND site_id = v_requirement.site_id FOR UPDATE;
  END IF;
  IF v_instance_id IS NOT NULL THEN
    UPDATE public.instance_plans AS plan SET status = 'blocked', updated_at = clock_timestamp(),
      steps = CASE WHEN jsonb_typeof(plan.steps) = 'array' THEN
        (SELECT COALESCE(jsonb_agg(CASE WHEN step->>'status' IN ('pending', 'in_progress')
          THEN step || jsonb_build_object('status', 'blocked', 'error_message', v_message)
          ELSE step END ORDER BY ordinal), '[]'::jsonb)
         FROM jsonb_array_elements(plan.steps) WITH ORDINALITY items(step, ordinal))
        ELSE plan.steps END
      WHERE plan.instance_id = v_instance_id
        AND plan.metadata->>'requirement_id' = NEW.requirement_id::text
        AND COALESCE(plan.metadata->>'workflow_template', 'false') <> 'true'
        AND plan.status IN ('pending', 'in_progress', 'active', 'blocked');
    -- Preserve manual pauses, terminal plans and unrelated work sharing a chat.
    UPDATE public.remote_instances SET status = 'pending', updated_at = clock_timestamp()
      WHERE id = v_instance_id AND status IN ('running', 'starting')
        AND NOT EXISTS (SELECT 1 FROM public.instance_plans p
          WHERE p.instance_id = v_instance_id AND p.status IN ('pending', 'in_progress', 'active')
            AND p.metadata->>'requirement_id' IS DISTINCT FROM NEW.requirement_id::text
            AND COALESCE(p.metadata->>'workflow_template', 'false') <> 'true')
        AND NOT EXISTS (SELECT 1 FROM public.requirements r
          WHERE r.id <> NEW.requirement_id AND r.status IN ('backlog', 'in-progress')
            AND r.metadata->>'runner_instance_id' = v_instance_id::text);
  END IF;

  IF TG_OP = 'INSERT' OR OLD.state IS DISTINCT FROM NEW.state OR OLD.reason IS DISTINCT FROM NEW.reason THEN
    INSERT INTO public.requirement_status(requirement_id, site_id, instance_id, stage, message)
      VALUES (NEW.requirement_id, v_requirement.site_id, v_instance_id, 'blocked', v_message);
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: put_harness_artifact(uuid, uuid, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.put_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_artifact_id text, p_text text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE used bigint; reserved bigint; own_reservation integer; expected_id text; char_count integer;
BEGIN
  PERFORM public.lock_harness_host_owner(p_id,p_site_id,p_owner);
  IF p_operation_id IS NULL OR length(p_operation_id) NOT BETWEEN 1 AND 1000 OR p_text IS NULL OR p_artifact_id IS NULL
  THEN RAISE EXCEPTION 'Invalid harness artifact' USING ERRCODE='22023'; END IF;
  IF octet_length(p_text)>1048576
  THEN RAISE EXCEPTION 'Harness artifact quota exceeded' USING ERRCODE='54000'; END IF;
  expected_id := encode(sha256(convert_to(p_id::text,'UTF8') || decode('00','hex') || convert_to(p_operation_id,'UTF8') || decode('00','hex') || convert_to(p_text,'UTF8')),'hex');
  IF p_artifact_id IS DISTINCT FROM expected_id
  THEN RAISE EXCEPTION 'Invalid harness artifact identity' USING ERRCODE='22023'; END IF;
  -- Count UTF-16 code units for the host contract, including astral Unicode pairs.
  char_count := length(p_text)+length(regexp_replace(p_text,U&'[^\+010000-\+10FFFF]','','g'));
  IF EXISTS (SELECT 1 FROM public.harness_artifacts WHERE session_id=p_id AND id=p_artifact_id) THEN
    UPDATE public.harness_artifact_reservations SET bytes=0 WHERE session_id=p_id AND operation_id=p_operation_id;
    RETURN jsonb_build_object('id',p_artifact_id,'bytes',octet_length(p_text),'chars',char_count);
  END IF;
  SELECT coalesce(sum(bytes),0) INTO used FROM public.harness_artifacts WHERE session_id=p_id;
  SELECT coalesce(sum(bytes),0) INTO reserved FROM public.harness_artifact_reservations WHERE session_id=p_id;
  SELECT bytes INTO own_reservation FROM public.harness_artifact_reservations WHERE session_id=p_id AND operation_id=p_operation_id;
  IF used+reserved-coalesce(own_reservation,0)+octet_length(p_text)>16777216
  THEN RAISE EXCEPTION 'Harness artifact quota exceeded' USING ERRCODE='54000'; END IF;
  INSERT INTO public.harness_artifacts(session_id,site_id,id,operation_id,content) VALUES(p_id,p_site_id,p_artifact_id,p_operation_id,p_text);
  INSERT INTO public.harness_artifact_reservations(session_id,site_id,operation_id,bytes) VALUES(p_id,p_site_id,p_operation_id,0)
    ON CONFLICT (session_id,operation_id) DO UPDATE SET bytes=0;
  RETURN jsonb_build_object('id',p_artifact_id,'bytes',octet_length(p_text),'chars',char_count);
END;
$$;


--
-- Name: queue_record_embedding_on_record_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.queue_record_embedding_on_record_change() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_node_ids uuid[] := '{}'::uuid[];
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF OLD.record_embedding_revision = NEW.record_embedding_revision THEN
      RETURN NEW;
    END IF;

    IF
      OLD.title IS DISTINCT FROM NEW.title
      OR OLD.category_id IS DISTINCT FROM NEW.category_id
    THEN
      SELECT COALESCE(array_agg(n.id), '{}'::uuid[])
      INTO v_node_ids
      FROM public.record_diagram_nodes n
      WHERE n.record_id = NEW.id;
    END IF;
  END IF;

  PERFORM public.enqueue_record_embedding_job(NEW.id, v_node_ids, false);
  RETURN NEW;
END;
$$;


--
-- Name: read_harness_artifact(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.read_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_artifact_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE result jsonb;
BEGIN
  PERFORM public.lock_harness_host_owner(p_id,p_site_id,p_owner);
  IF p_artifact_id IS NULL OR p_artifact_id !~ '^[a-f0-9]{64}$'
  THEN RAISE EXCEPTION 'Invalid harness artifact identity' USING ERRCODE='22023'; END IF;
  SELECT jsonb_build_object('text',content) INTO result FROM public.harness_artifacts
    WHERE session_id=p_id AND site_id=p_site_id AND id=p_artifact_id;
  RETURN result;
END;
$_$;


--
-- Name: read_site_location_restrictions(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.read_site_location_restrictions(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
DECLARE effective_role text; location_rows jsonb; member_rows jsonb; enabled boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Authentication required';
  END IF;
  effective_role := public.current_user_site_role(p_site_id);
  IF effective_role IS NULL OR effective_role NOT IN ('owner','admin') THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Team manager access required';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id',l.id,'name',l.name,'is_active',l.is_active
  ) ORDER BY l.name,l.id),'[]'::jsonb) INTO location_rows
    FROM public.locations l WHERE l.site_id=p_site_id;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id',sm.id,'role',sm.role,
    'is_location_exempt',sm.role IN ('owner','admin') OR EXISTS (
      SELECT 1 FROM public.sites s WHERE s.id=p_site_id AND s.user_id=sm.user_id
    ) OR EXISTS (
      SELECT 1 FROM public.site_ownership so WHERE so.site_id=p_site_id AND so.user_id=sm.user_id
    ),
    'restricted_location_ids',coalesce((
      SELECT jsonb_agg(r.location_id ORDER BY r.location_id)
      FROM public.site_member_location_restrictions r
      WHERE r.site_id=p_site_id AND r.site_member_id=sm.id
    ),'[]'::jsonb)
  ) ORDER BY sm.id),'[]'::jsonb) INTO member_rows
    FROM public.site_members sm WHERE sm.site_id=p_site_id;
  SELECT editing_enabled INTO enabled FROM public.location_access_rollout WHERE singleton;
  RETURN jsonb_build_object('site_id',p_site_id,'locations',location_rows,'members',member_rows,
    'editing_enabled',coalesce(enabled,false));
END;
$$;


--
-- Name: rebind_marketplace_merchant_connection(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rebind_marketplace_merchant_connection(p_integration_id uuid, p_connection_id uuid, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations; connection public.marketplace_merchant_connections;
  previous public.marketplace_merchant_connections; preserve_state boolean; permit_id uuid;
  prior_guard text := current_setting('marketplace.rebind',true);
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Merchant backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Merchant integration unavailable'; END IF;
  PERFORM public.marketplace_assert_actor(integration.site_id,p_actor_user_id,true);
  SELECT * INTO connection FROM public.marketplace_merchant_connections WHERE id=p_connection_id FOR SHARE;
  IF NOT FOUND OR (connection.site_id,connection.provider,connection.environment,connection.country)
    IS DISTINCT FROM (integration.site_id,integration.provider,integration.environment,integration.country)
    OR connection.status<>'authorized' OR (connection.token_expires_at IS NOT NULL AND connection.token_expires_at<=now())
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(connection.authorized_stores) store
      WHERE store->>'id'=integration.external_store_id) THEN
    RAISE EXCEPTION 'Merchant reauthorization binding mismatch' USING ERRCODE='42501';
  END IF;
  IF integration.merchant_connection_id=connection.id THEN RETURN to_jsonb(integration); END IF;
  SELECT * INTO previous FROM public.marketplace_merchant_connections WHERE id=integration.merchant_connection_id FOR SHARE;
  preserve_state := integration.provisioning_status IN ('active','pending') OR integration.provisioning_result='unknown';
  IF preserve_state THEN
    IF previous.id IS NULL THEN
      -- Legacy app identity cannot be proved from native ciphertext in SQL.
      -- Require the manager to disable its manual receiver before migration.
      IF integration.enabled OR integration.provisioning_status='pending' OR integration.provisioning_result='unknown' THEN
        RAISE EXCEPTION 'Disconnect the existing provider app before changing authorization';
      END IF;
      preserve_state := false;
    ELSIF previous.app_client_id_hash IS DISTINCT FROM connection.app_client_id_hash THEN
      RAISE EXCEPTION 'Disconnect the existing provider app before changing authorization';
    END IF;
  END IF;
  INSERT INTO public.marketplace_rebind_permits(backend_pid,transaction_id,integration_id,connection_id,actor_user_id)
  VALUES(pg_backend_pid(),txid_current(),integration.id,connection.id,p_actor_user_id) RETURNING id INTO permit_id;
  PERFORM set_config('marketplace.rebind',permit_id::text,true);
  UPDATE public.marketplace_integrations SET merchant_connection_id=connection.id,credential_mode=connection.credential_mode,
    secret_id=NULL,enabled=CASE WHEN preserve_state THEN enabled ELSE false END,
    provisioning_status=CASE WHEN preserve_state THEN provisioning_status ELSE 'not_ready' END,
    provisioning_operation=CASE WHEN preserve_state THEN provisioning_operation ELSE NULL END,
    provisioning_result=CASE WHEN preserve_state THEN provisioning_result ELSE NULL END,
    provisioning_claim_id=CASE WHEN preserve_state THEN provisioning_claim_id ELSE NULL END,
    provider_batch_id=CASE WHEN preserve_state THEN provider_batch_id ELSE NULL END,updated_at=now()
    WHERE id=integration.id RETURNING * INTO integration;
  DELETE FROM public.marketplace_rebind_permits WHERE id=permit_id;
  PERFORM set_config('marketplace.rebind',coalesce(prior_guard,''),true);
  RETURN to_jsonb(integration);
EXCEPTION WHEN OTHERS THEN
  PERFORM set_config('marketplace.rebind',coalesce(prior_guard,''),true);
  RAISE;
END;
$$;


--
-- Name: recheck_requirement_economic_pauses(uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.recheck_requirement_economic_pauses(p_excluded_ids uuid[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE candidate record; receipt public.requirement_economic_pauses%ROWTYPE;
  r public.requirements%ROWTYPE; h public.harness_requirement_runs%ROWTYPE;
  s public.harness_sessions%ROWTYPE; latest public.requirement_status%ROWTYPE;
  observation jsonb; renewal jsonb; available numeric; effective_budget numeric; credit_minimum numeric;
  command record; action public.instance_logs%ROWTYPE; owner public.remote_instances%ROWTYPE;
  patch jsonb; ready boolean; has_command boolean;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended('requirement-cron-global-capacity',0));
  FOR candidate IN SELECT requirement_id FROM public.requirement_economic_pauses
    WHERE checked_at<=clock_timestamp()-interval '60 seconds'
      AND NOT(requirement_id=ANY(coalesce(p_excluded_ids,'{}'::uuid[])))
    ORDER BY checked_at,requirement_id LIMIT 100
  LOOP
    SELECT * INTO r FROM public.requirements WHERE id=candidate.requirement_id FOR UPDATE SKIP LOCKED;
    IF NOT FOUND THEN CONTINUE; END IF;
    SELECT * INTO h FROM public.harness_requirement_runs WHERE requirement_id=r.id FOR UPDATE;
    SELECT * INTO s FROM public.harness_sessions WHERE id=h.session_id FOR UPDATE;
    SELECT * INTO receipt FROM public.requirement_economic_pauses WHERE requirement_id=r.id FOR UPDATE;
    IF NOT FOUND THEN CONTINUE; END IF;
    UPDATE public.requirement_economic_pauses SET checked_at=clock_timestamp(),last_error_code=NULL WHERE requirement_id=r.id;
    BEGIN
      IF public.requirement_pause_command_guard(r.id,receipt.requirement_guard) IS DISTINCT FROM true
        OR r.status<>'blocked' OR r.cron_lock_expires_at>clock_timestamp()
        OR h.session_id IS DISTINCT FROM receipt.session_id OR h.generation IS DISTINCT FROM receipt.generation
        OR h.site_id IS DISTINCT FROM r.site_id OR h.pause_reason IS DISTINCT FROM receipt.pause_reason
        OR h.next_run_at IS NOT NULL OR s.version IS DISTINCT FROM receipt.session_version
        OR s.lease_expires_at>clock_timestamp() THEN CONTINUE; END IF;
      SELECT * INTO latest FROM public.requirement_status WHERE requirement_id=r.id
        ORDER BY updated_at DESC NULLS LAST,id DESC LIMIT 1;
      IF latest.id IS DISTINCT FROM receipt.status_id OR to_jsonb(latest) IS DISTINCT FROM receipt.status_guard
        OR latest.cycle IS DISTINCT FROM 'agent:'||h.last_cycle_id THEN CONTINUE; END IF;
      IF EXISTS (SELECT 1 FROM public.harness_sessions cleanup WHERE cleanup.sandbox_cleanup_token IS NOT NULL AND (
        cleanup.id=h.session_id OR (cleanup.site_id=r.site_id AND cleanup.snapshot#>>'{request,requirementId}'=r.id::text)
        OR cleanup.sandbox_cleanup_resource=s.snapshot#>>'{workspace,id}')) THEN CONTINUE; END IF;
      IF s.id IS NOT NULL AND (s.site_id IS DISTINCT FROM r.site_id OR s.user_id IS DISTINCT FROM r.user_id
        OR (s.snapshot#>>'{request,requirementId}' IS NOT NULL AND s.snapshot#>>'{request,requirementId}'<>r.id::text)
        OR coalesce(s.snapshot->>'status','') NOT IN ('queued','running','paused')
        OR (s.snapshot->>'status'='paused' AND s.snapshot->>'reason' IS DISTINCT FROM h.pause_reason)
        OR s.snapshot ? 'pending' OR s.snapshot->'uncertainOperations' IS DISTINCT FROM '[]'::jsonb
        OR EXISTS (SELECT 1 FROM jsonb_array_elements(s.snapshot->'messages') msg,
          jsonb_array_elements(coalesce(msg->'toolCalls','[]'::jsonb)) call
          WHERE NOT EXISTS (SELECT 1 FROM jsonb_array_elements(s.snapshot->'messages') result
            WHERE result->>'role'='tool' AND result->>'toolCallId'=call->>'id'))) THEN CONTINUE; END IF;
      -- Match command draining's UUID-ordered owner locks before checking the
      -- runner. A distinct origin cannot be paused/archived during recovery.
      ready:=true;
      FOR owner IN SELECT i.* FROM public.remote_instances i WHERE i.site_id=r.site_id
        AND i.id::text IN (r.metadata->>'runner_instance_id',r.metadata->>'assistant_origin_instance_id')
        ORDER BY i.id FOR UPDATE
      LOOP
        IF owner.is_archived IS TRUE OR owner.status IN ('paused','stopped','stopping','cancelled') THEN ready:=false; END IF;
      END LOOP;
      IF NOT ready OR public.agent_requirement_runner_allowed(r.id,(r.metadata->>'runner_instance_id')::uuid) IS DISTINCT FROM true THEN CONTINUE; END IF;
      IF EXISTS (SELECT 1 FROM public.instance_plans p WHERE p.site_id=r.site_id AND p.status='paused'
        AND (p.metadata->>'requirement_id'=r.id::text OR p.instance_id::text IN
          (r.metadata->>'runner_instance_id',r.metadata->>'assistant_origin_instance_id'))) THEN CONTINUE; END IF;
      IF EXISTS (SELECT 1 FROM public.harness_model_credit_reservations
        WHERE (requirement_id=r.id OR session_id=h.session_id) AND state IN ('reserved','dispatched','pending')) THEN CONTINUE; END IF;
      IF EXISTS (SELECT 1 FROM public.requirements other WHERE other.id<>r.id AND other.cron_lock_expires_at>clock_timestamp()
        AND (other.metadata->>'runner_instance_id'=r.metadata->>'runner_instance_id'
          OR other.metadata->>'assistant_origin_instance_id'=r.metadata->>'runner_instance_id')) THEN CONTINUE; END IF;
      -- Wait for the entire admitted pending chain. Never let a new revision
      -- leapfrog a running action or use a cancelled/paused action as consent.
      patch:='{}'::jsonb; ready:=true; has_command:=false;
      FOR command IN SELECT c.* FROM public.requirement_commands c
        WHERE c.requirement_id=r.id AND c.applied_at IS NULL ORDER BY c.revision FOR UPDATE
      LOOP
        SELECT * INTO action FROM public.instance_logs WHERE id=command.action_id FOR SHARE;
        IF NOT FOUND OR coalesce(action.details->>'status','') NOT IN ('completed','failed')
          OR action.trusted_user_action IS DISTINCT FROM true OR action.log_type IS DISTINCT FROM 'user_action'
          OR action.site_id IS DISTINCT FROM r.site_id THEN ready:=false; EXIT; END IF;
        patch:=patch||command.patch;
        has_command:=has_command OR action.created_at>=latest.updated_at;
      END LOOP;
      IF NOT ready OR (receipt.pause_reason IN ('turn_budget_exhausted','active_time_budget_exhausted') AND NOT has_command) THEN CONTINUE; END IF;
      observation:=public.requirement_budget_observation(r.id);
      effective_budget:=CASE WHEN patch ? 'budget' THEN (patch->>'budget')::numeric ELSE r.budget END;
      IF effective_budget IS NOT NULL AND (effective_budget<0 OR effective_budget::text IN ('NaN','Infinity','-Infinity')
        OR (observation->>'spent_usd')::numeric>=effective_budget) THEN CONTINUE; END IF;
      IF (observation->>'pending_model_reservations')::integer<>0 THEN CONTINUE; END IF;
      renewal:=public.renew_site_plan_credits(r.site_id);
      IF renewal->>'success' IS DISTINCT FROM 'true' THEN CONTINUE; END IF;
      SELECT credits_available INTO available FROM public.billing WHERE site_id=r.site_id FOR UPDATE;
      IF NOT FOUND OR available IS NULL OR available<=0 OR available::text IN ('NaN','Infinity','-Infinity') THEN CONTINUE; END IF;
      -- A positive balance can still be smaller than the rejected model hold.
      -- Require the trusted snapshot's actual admission amount to avoid reopening
      -- the same workspace every cron without any new usable funding.
      IF receipt.pause_reason='account_credits_exhausted' THEN
        IF jsonb_typeof(s.snapshot->'creditRecoveryMinimum') IS DISTINCT FROM 'number' THEN CONTINUE; END IF;
        credit_minimum:=(s.snapshot->>'creditRecoveryMinimum')::numeric;
        IF credit_minimum<=0 OR credit_minimum::text IN ('NaN','Infinity','-Infinity') OR available<credit_minimum THEN CONTINUE; END IF;
      END IF;
      IF s.id IS NOT NULL AND public.control_harness_session(s.id,r.site_id,'resume',NULL) IS NULL THEN CONTINUE; END IF;
      UPDATE public.requirements SET status='in-progress',updated_at=clock_timestamp() WHERE id=r.id;
      UPDATE public.harness_requirement_runs SET pause_reason=NULL,next_run_at=clock_timestamp() WHERE requirement_id=r.id;
      -- Apply the already authorized command atomically with recovery, including
      -- its budget, before any cycle can observe the old exhausted budget.
      IF patch<>'{}'::jsonb THEN
        PERFORM public.apply_recovered_requirement_commands(r.id,patch);
      END IF;
      INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,cycle,message)
        VALUES(r.id,r.site_id,(r.metadata->>'runner_instance_id')::uuid,'in-progress','economic-recovery:'||h.last_cycle_id,
          format('Recoverable pause %s reevaluated: %s USD spent, %s USD budget, %s account credits available. Existing session retained.',
            receipt.pause_reason,observation->>'spent_usd',coalesce(effective_budget::text,'unlimited'),available));
    EXCEPTION WHEN OTHERS THEN
      UPDATE public.requirement_economic_pauses SET last_error_code=SQLSTATE WHERE requirement_id=r.id;
    END;
  END LOOP;
END;
$$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: replace_archived_requirement_runner(uuid, text, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.replace_archived_requirement_runner(p_requirement_id uuid, p_run_id text, p_expected_instance_id uuid, p_expected_execution_generation integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_requirement public.requirements%ROWTYPE;
  v_instance public.remote_instances%ROWTYPE;
  v_action public.instance_logs%ROWTYPE;
  v_receipt public.requirement_archived_runner_reassignments%ROWTYPE;
  v_metadata jsonb;
  v_generation integer;
  v_generation_text text;
  v_owner text;
  v_origin text;
  v_discovered_owner uuid;
  v_new_instance_id uuid;
  v_plan public.instance_plans%ROWTYPE;
  v_plan_ids uuid[] := '{}'::uuid[];
  v_item_ids text[];
  v_references_valid boolean;
  v_reference_count integer;
BEGIN
  IF p_requirement_id IS NULL OR p_expected_instance_id IS NULL
    OR NULLIF(btrim(p_run_id), '') IS NULL
    OR p_expected_execution_generation IS NULL
    OR p_expected_execution_generation < 0 OR p_expected_execution_generation >= 2147483647
  THEN RETURN jsonb_build_object('state', 'guarded', 'reason', 'missing_execution_identity'); END IF;

  -- Same order as claim/activation; prevents overlapping admission on old owner.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('requirement-cron-global-capacity', 0));
  SELECT * INTO v_requirement FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('state', 'guarded', 'reason', 'requirement_missing'); END IF;
  IF v_requirement.cron_lock_run_id IS DISTINCT FROM p_run_id THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'run_owner_changed');
  END IF;
  IF v_requirement.cron_lock_expires_at IS NULL
    OR v_requirement.cron_lock_expires_at <= clock_timestamp() THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'lease_expired');
  END IF;
  IF v_requirement.cron_lock_active IS DISTINCT FROM false THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'execution_active');
  END IF;
  IF COALESCE(v_requirement.status, '') NOT IN ('backlog', 'in-progress') THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'execution_not_runnable');
  END IF;
  IF v_requirement.site_id IS NULL OR v_requirement.user_id IS NULL THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'requirement_identity_missing');
  END IF;
  IF v_requirement.metadata IS NOT NULL AND jsonb_typeof(v_requirement.metadata) <> 'object' THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'invalid_requirement_metadata');
  END IF;
  v_metadata := COALESCE(v_requirement.metadata, '{}'::jsonb);
  v_generation_text := v_metadata->>'requirement_execution_generation';
  v_generation := 0;
  IF v_metadata ? 'requirement_execution_generation' THEN
    IF v_generation_text IS NULL OR v_generation_text !~ '^[0-9]{1,10}$'
      OR v_generation_text::bigint > 2147483647 THEN
      RETURN jsonb_build_object('state', 'guarded', 'reason', 'invalid_execution_generation');
    END IF;
    v_generation := v_generation_text::integer;
  END IF;
  v_owner := v_metadata->>'runner_instance_id';
  v_origin := v_metadata->>'assistant_origin_instance_id';
  IF v_origin IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.remote_instances WHERE id::text = v_origin AND site_id = v_requirement.site_id
  ) THEN RETURN jsonb_build_object('state', 'guarded', 'reason', 'assistant_origin_unavailable'); END IF;

  SELECT * INTO v_receipt FROM public.requirement_archived_runner_reassignments
    WHERE requirement_id = p_requirement_id AND run_id = p_run_id;
  IF FOUND THEN
    IF v_receipt.site_id = v_requirement.site_id
      AND v_receipt.previous_instance_id = p_expected_instance_id
      AND v_receipt.previous_execution_generation = p_expected_execution_generation
      AND v_receipt.execution_generation = v_generation
      AND v_receipt.instance_id::text = v_owner
      AND EXISTS (SELECT 1 FROM public.remote_instances WHERE id = v_receipt.instance_id
        AND site_id = v_requirement.site_id AND is_archived IS FALSE)
    THEN RETURN jsonb_build_object('state', 'duplicate', 'instance_id', v_receipt.instance_id,
      'execution_generation', v_generation, 'metadata', v_metadata); END IF;
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'replacement_receipt_changed');
  END IF;
  IF v_generation <> p_expected_execution_generation THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'execution_generation_changed');
  END IF;
  SELECT * INTO v_instance FROM public.remote_instances WHERE id = p_expected_instance_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('state', 'guarded', 'reason', 'original_instance_unavailable'); END IF;
  IF v_instance.site_id IS DISTINCT FROM v_requirement.site_id THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'instance_site_mismatch');
  END IF;
  IF v_owner IS NOT NULL THEN
    IF v_owner IS DISTINCT FROM p_expected_instance_id::text THEN
      RETURN jsonb_build_object('state', 'guarded', 'reason', 'runner_instance_owner_changed');
    END IF;
  ELSE
    -- Legacy discovery must be reproducible, never caller-provided authority.
    -- A known origin wins; otherwise use the earliest non-maintenance plan owner.
    IF v_origin IS NOT NULL THEN
      v_discovered_owner := CASE WHEN v_origin = p_expected_instance_id::text THEN p_expected_instance_id ELSE NULL END;
    ELSE
      IF EXISTS (SELECT 1 FROM public.instance_plans AS plan
        LEFT JOIN public.remote_instances AS instance ON instance.id = plan.instance_id
        WHERE plan.site_id = v_requirement.site_id AND plan.metadata->>'requirement_id' = p_requirement_id::text
          AND (instance.id IS NULL OR instance.site_id IS DISTINCT FROM v_requirement.site_id)) THEN
        RETURN jsonb_build_object('state', 'guarded', 'reason', 'original_instance_unavailable');
      END IF;
      SELECT plan.instance_id INTO v_discovered_owner FROM public.instance_plans AS plan
        JOIN public.remote_instances AS instance ON instance.id = plan.instance_id
        WHERE plan.site_id = v_requirement.site_id AND plan.metadata->>'requirement_id' = p_requirement_id::text
          AND instance.site_id = v_requirement.site_id AND instance.name NOT LIKE 'req-maint-%'
        ORDER BY plan.created_at ASC, plan.id ASC LIMIT 1;
      IF v_discovered_owner IS NULL AND v_instance.name = 'req-runner-' || p_requirement_id::text THEN
        v_discovered_owner := p_expected_instance_id;
      END IF;
    END IF;
    IF v_discovered_owner IS DISTINCT FROM p_expected_instance_id THEN
      RETURN jsonb_build_object('state', 'guarded', 'reason', 'runner_instance_owner_changed');
    END IF;
  END IF;
  IF v_instance.is_archived IS DISTINCT FROM true THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'original_instance_not_archived');
  END IF;
  -- Archive is explicit intent, not proof that an in-flight assistant tool has
  -- quiesced. Never infer completion from age/provider silence. Completed/failed
  -- are authoritative terminal outcomes: the failure writer intentionally keeps
  -- the last recovery snapshot, whose inFlight bit is not a live tool lease.
  -- A pause/cancellation with inFlight still set remains ambiguous and guarded.
  SELECT * INTO v_action FROM public.instance_logs
    WHERE instance_id = p_expected_instance_id AND site_id = v_requirement.site_id
      AND log_type = 'user_action' AND trusted_user_action IS TRUE
    ORDER BY created_at DESC, id DESC LIMIT 1 FOR UPDATE;
  IF FOUND AND (COALESCE(v_action.details->>'status', '') NOT IN (
    'completed', 'failed', 'paused', 'stopped', 'cancelled'
  ) OR (v_action.details->>'status' NOT IN ('completed', 'failed')
    AND v_action.details->'assistant_recovery'->>'inFlight' = 'true')) THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'original_assistant_action_not_finished');
  END IF;
  IF EXISTS (SELECT 1 FROM public.requirements AS other
    WHERE other.id <> p_requirement_id AND other.cron_lock_active IS TRUE
      AND other.cron_lock_run_id IS NOT NULL AND other.cron_lock_expires_at > clock_timestamp()
      AND (other.metadata->>'runner_instance_id' = p_expected_instance_id::text
        OR (other.metadata->>'runner_instance_id' IS NULL
          AND other.metadata->>'assistant_origin_instance_id' = p_expected_instance_id::text))) THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'original_instance_execution_active');
  END IF;
  IF EXISTS (SELECT 1 FROM public.remote_instances WHERE site_id = v_requirement.site_id
    AND name = 'req-runner-' || p_requirement_id::text AND is_archived IS NOT TRUE) THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'canonical_runner_exists');
  END IF;
  IF EXISTS (SELECT 1 FROM public.instance_plans AS plan
    JOIN public.remote_instances AS instance ON instance.id = plan.instance_id
    WHERE plan.site_id = v_requirement.site_id AND plan.metadata->>'requirement_id' = p_requirement_id::text
      AND plan.instance_id <> p_expected_instance_id
      AND plan.status IN ('pending', 'in_progress', 'active', 'paused')
      AND instance.is_archived IS NOT TRUE AND instance.name NOT LIKE 'req-maint-%') THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'competing_instance_active');
  END IF;

  SELECT COALESCE(array_agg(item->>'id'), '{}'::text[]) INTO v_item_ids
    FROM jsonb_array_elements(CASE WHEN jsonb_typeof(v_requirement.backlog->'items') = 'array'
      THEN v_requirement.backlog->'items' ELSE '[]'::jsonb END) AS item
    WHERE jsonb_typeof(item->'id') = 'string' AND btrim(item->>'id') <> '';
  -- Lock source candidates before classifying them. A supported legacy plan
  -- cannot be silently left behind while a new runner replans completed work.
  -- The captured IDs are the exact transfer set; no broad post-insert UPDATE.
  FOR v_plan IN SELECT * FROM public.instance_plans
    WHERE instance_id = p_expected_instance_id AND site_id = v_requirement.site_id
      AND status IN ('pending', 'in_progress', 'active', 'paused') ORDER BY id FOR UPDATE
  LOOP
    IF v_plan.metadata->'workflow_run' = 'true'::jsonb
      OR v_plan.metadata->'workflow_template' = 'true'::jsonb THEN CONTINUE; END IF;
    IF v_plan.metadata->>'requirement_id' IS NOT NULL THEN
      IF v_plan.metadata->>'requirement_id' = p_requirement_id::text THEN
        v_plan_ids := array_append(v_plan_ids, v_plan.id);
      END IF;
      CONTINUE; -- An explicit different requirement is never transferable.
    END IF;
    -- Legacy association must be unambiguous: no shared historical owner, no
    -- malformed shape, and every declared plan/step backlog link belongs here.
    IF (v_plan.metadata IS NOT NULL AND jsonb_typeof(v_plan.metadata) <> 'object')
      OR jsonb_typeof(v_plan.steps) IS DISTINCT FROM 'array'
      OR EXISTS (SELECT 1 FROM public.requirements AS other
        WHERE other.id <> p_requirement_id
          AND (other.metadata->>'runner_instance_id' = p_expected_instance_id::text
            OR other.metadata->>'assistant_origin_instance_id' = p_expected_instance_id::text))
      OR EXISTS (SELECT 1 FROM public.instance_plans AS other
        WHERE other.instance_id = p_expected_instance_id AND other.site_id = v_requirement.site_id
          AND other.metadata->>'requirement_id' IS NOT NULL
          AND other.metadata->>'requirement_id' <> p_requirement_id::text
          AND other.metadata->'workflow_run' IS DISTINCT FROM 'true'::jsonb
          AND other.metadata->'workflow_template' IS DISTINCT FROM 'true'::jsonb)
    THEN RETURN jsonb_build_object('state', 'guarded', 'reason', 'legacy_plan_scope_ambiguous'); END IF;
    IF EXISTS (SELECT 1 FROM jsonb_array_elements(v_plan.steps) AS step
      WHERE jsonb_typeof(step) IS DISTINCT FROM 'object'
        OR (step ? 'metadata' AND step->'metadata' <> 'null'::jsonb
          AND jsonb_typeof(step->'metadata') <> 'object')) THEN
      RETURN jsonb_build_object('state', 'guarded', 'reason', 'legacy_plan_scope_ambiguous');
    END IF;
    SELECT count(*)::integer, COALESCE(bool_and(
      jsonb_typeof(reference) = 'string' AND (reference #>> '{}') = ANY(v_item_ids)), false)
      INTO v_reference_count, v_references_valid
      FROM (
        SELECT v_plan.metadata->'backlog_item_id' AS reference
        UNION ALL SELECT step->'backlog_item_id' FROM jsonb_array_elements(v_plan.steps) AS step
        UNION ALL SELECT step->'metadata'->'backlog_item_id' FROM jsonb_array_elements(v_plan.steps) AS step
      ) AS references_to_check
      WHERE reference IS NOT NULL AND reference <> 'null'::jsonb;
    IF v_reference_count = 0 OR NOT v_references_valid THEN
      RETURN jsonb_build_object('state', 'guarded', 'reason', 'legacy_plan_scope_ambiguous');
    END IF;
    v_plan_ids := array_append(v_plan_ids, v_plan.id);
  END LOOP;
  IF v_requirement.cron_lock_expires_at <= clock_timestamp() THEN
    RETURN jsonb_build_object('state', 'guarded', 'reason', 'lease_expired');
  END IF;
  INSERT INTO public.remote_instances(name, instance_type, status, is_archived, site_id, user_id, created_by)
    VALUES ('req-runner-' || p_requirement_id::text, 'browser', 'pending', false,
      v_requirement.site_id, v_requirement.user_id, v_requirement.user_id)
    RETURNING id INTO v_new_instance_id;
  v_metadata := v_metadata || jsonb_build_object('runner_instance_id', v_new_instance_id,
    'requirement_execution_generation', v_generation + 1);
  UPDATE public.requirements SET metadata = v_metadata WHERE id = p_requirement_id;
  UPDATE public.instance_plans SET instance_id = v_new_instance_id
    WHERE id = ANY(v_plan_ids) AND instance_id = p_expected_instance_id AND site_id = v_requirement.site_id
      AND status IN ('pending', 'in_progress', 'active', 'paused');
  INSERT INTO public.requirement_archived_runner_reassignments(requirement_id, site_id,
    previous_instance_id, instance_id, run_id, previous_execution_generation, execution_generation)
    VALUES (p_requirement_id, v_requirement.site_id, p_expected_instance_id, v_new_instance_id,
      p_run_id, v_generation, v_generation + 1);
  RETURN jsonb_build_object('state', 'replaced', 'instance_id', v_new_instance_id,
    'execution_generation', v_generation + 1, 'metadata', v_metadata);
END;
$_$;


--
-- Name: replace_site_member_location_restrictions(uuid, uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.replace_site_member_location_restrictions(p_site_id uuid, p_member_id uuid, p_location_ids uuid[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  actor uuid := auth.uid(); effective_role text; target public.site_members%ROWTYPE;
  rollout_enabled boolean; old_ids uuid[]; new_ids uuid[]; current_revision integer;
BEGIN
  -- A serializable snapshot can still serialize before a concurrent revocation
  -- after waiting for its lock. This RPC needs fresh post-lock authorization.
  IF current_setting('transaction_isolation') <> 'read committed' THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'Location restriction writes require READ COMMITTED';
  END IF;
  IF actor IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Authentication required';
  END IF;
  effective_role := public.current_user_site_role(p_site_id);
  IF effective_role IS NULL OR effective_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Team manager access required';
  END IF;
  SELECT editing_enabled INTO rollout_enabled FROM public.location_access_rollout
    WHERE singleton FOR SHARE;
  IF rollout_enabled IS DISTINCT FROM true THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'Location restriction editing is not enabled';
  END IF;
  IF p_site_id IS NULL OR p_member_id IS NULL OR p_location_ids IS NULL
    OR (cardinality(p_location_ids) > 0 AND array_ndims(p_location_ids) <> 1)
    OR EXISTS (SELECT 1 FROM unnest(p_location_ids) location_id WHERE location_id IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'A member and a non-null location UUID array are required';
  END IF;
  -- Serialize with license/membership transitions; a stale isolation snapshot is
  -- not allowed. Existing membership triggers also use this site lock.
  PERFORM public.lock_site_license(p_site_id);
  effective_role := public.current_user_site_role(p_site_id);
  IF effective_role IS NULL OR effective_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Team manager access required';
  END IF;
  -- Ordinary membership UPDATE locks its row before the license trigger locks
  -- the site. Never wait for that row while holding the site lock: return 55P03
  -- so the whole request can be retried rather than deadlocking either writer.
  SELECT * INTO target FROM public.site_members
    WHERE id = p_member_id AND site_id = p_site_id FOR UPDATE NOWAIT;
  IF NOT FOUND OR target.status IS NULL OR target.status NOT IN ('active', 'pending')
    OR target.role IS NULL OR target.role NOT IN ('owner', 'admin', 'collaborator', 'marketing')
    OR (target.status = 'active' AND target.user_id IS NULL)
    OR (target.status = 'pending' AND nullif(btrim(target.email), '') IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'An active member or valid pending invitation in this site is required';
  END IF;
  SELECT coalesce(array_agg(DISTINCT location_id ORDER BY location_id), '{}'::uuid[]) INTO new_ids
    FROM unnest(p_location_ids) location_id;
  IF cardinality(new_ids) > 0 AND (
    target.role IN ('owner', 'admin') OR EXISTS (
      SELECT 1 FROM public.sites s WHERE s.id = p_site_id AND s.user_id = target.user_id
    ) OR EXISTS (SELECT 1 FROM public.site_ownership so
      WHERE so.site_id = p_site_id AND so.user_id = target.user_id)
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Owners and admins are exempt from location restrictions';
  END IF;
  -- Lock every resolved location to stabilize tenant identity against moves or
  -- deletion, then compare the full count. No partial filtering/silent clearing.
  PERFORM 1 FROM public.locations l WHERE l.site_id = p_site_id AND l.id = ANY(new_ids)
    ORDER BY l.id FOR KEY SHARE;
  IF (SELECT count(*) FROM public.locations l WHERE l.site_id = p_site_id AND l.id = ANY(new_ids))
    <> cardinality(new_ids) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Every location must belong to this site';
  END IF;
  SELECT coalesce(array_agg(r.location_id ORDER BY r.location_id), '{}'::uuid[]) INTO old_ids
    FROM public.site_member_location_restrictions r
    WHERE r.site_id = p_site_id AND r.site_member_id = p_member_id;
  SELECT coalesce(max(a.revision), 0) INTO current_revision
    FROM public.site_member_location_restriction_audit a
    WHERE a.site_id = p_site_id AND a.site_member_id = p_member_id;
  IF old_ids IS DISTINCT FROM new_ids THEN
    DELETE FROM public.site_member_location_restrictions
      WHERE site_id = p_site_id AND site_member_id = p_member_id;
    INSERT INTO public.site_member_location_restrictions(site_id, site_member_id, location_id)
      SELECT p_site_id, p_member_id, location_id FROM unnest(new_ids) location_id;
    current_revision := current_revision + 1;
    INSERT INTO public.site_member_location_restriction_audit(
      site_id, site_member_id, actor_user_id, old_location_ids, new_location_ids, revision
    ) VALUES (p_site_id, p_member_id, actor, old_ids, new_ids, current_revision);
  END IF;
  RETURN jsonb_build_object('site_id', p_site_id, 'site_member_id', p_member_id,
    'restricted_location_ids', new_ids, 'revision', current_revision);
END;
$$;


--
-- Name: replace_site_member_location_restrictions_checked(uuid, uuid, uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.replace_site_member_location_restrictions_checked(p_site_id uuid, p_member_id uuid, p_location_ids uuid[], p_expected_location_ids uuid[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
DECLARE expected_ids uuid[]; saved_ids uuid[];
BEGIN
  IF current_setting('transaction_isolation') <> 'read committed' THEN
    RAISE EXCEPTION 'Location restriction writes require READ COMMITTED' USING ERRCODE='40001';
  END IF;
  IF auth.uid() IS NULL OR coalesce(public.current_user_site_role(p_site_id),'') NOT IN ('owner','admin') THEN
    RAISE EXCEPTION 'Team manager access required' USING ERRCODE='42501';
  END IF;
  IF p_site_id IS NULL OR p_member_id IS NULL OR p_expected_location_ids IS NULL
    OR (cardinality(p_expected_location_ids)>0 AND array_ndims(p_expected_location_ids)<>1)
    OR EXISTS(SELECT 1 FROM unnest(p_expected_location_ids) location_id WHERE location_id IS NULL) THEN
    RAISE EXCEPTION 'The previously saved location UUID array is required' USING ERRCODE='22023';
  END IF;
  PERFORM public.lock_site_license(p_site_id);
  IF coalesce(public.current_user_site_role(p_site_id),'') NOT IN ('owner','admin') THEN
    RAISE EXCEPTION 'Team manager access required' USING ERRCODE='42501';
  END IF;
  -- The legacy writer takes this same transaction lock. Compare and replace are
  -- one operation, including across simultaneous saves from separate managers.
  SELECT coalesce(array_agg(DISTINCT location_id ORDER BY location_id),'{}'::uuid[])
    INTO expected_ids FROM unnest(p_expected_location_ids) location_id;
  SELECT coalesce(array_agg(location_id ORDER BY location_id),'{}'::uuid[])
    INTO saved_ids FROM public.site_member_location_restrictions
    WHERE site_id=p_site_id AND site_member_id=p_member_id;
  IF expected_ids IS DISTINCT FROM saved_ids THEN
    -- Not 40001/55P03: replaying a stale full replacement must never auto-retry.
    RAISE EXCEPTION 'Location restrictions changed; reload before saving' USING ERRCODE='55000';
  END IF;
  RETURN public.replace_site_member_location_restrictions(p_site_id,p_member_id,p_location_ids);
END;
$$;


--
-- Name: requirement_budget_observation(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.requirement_budget_observation(p_requirement_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.requirements%ROWTYPE; model_spent numeric; tool_spent numeric;
  sandbox_spent numeric; pending_models integer; total_spent numeric;
BEGIN
  SELECT * INTO STRICT r FROM public.requirements WHERE id=p_requirement_id;
  IF r.budget IS NOT NULL AND (r.budget<0 OR r.budget::text IN ('NaN','Infinity','-Infinity')) THEN
    RAISE EXCEPTION 'Invalid requirement monetary budget';
  END IF;
  SELECT coalesce(sum(charged) FILTER (WHERE state='settled'),0),
    count(*) FILTER (WHERE state IN ('reserved','dispatched','pending'))
    INTO model_spent,pending_models FROM public.harness_model_credit_reservations
    WHERE requirement_id=r.id AND site_id=r.site_id;
  SELECT greatest(0,coalesce(-sum(charges.amount),0)) INTO tool_spent FROM (
    SELECT t.amount FROM public.credit_transactions t
    WHERE t.site_id=r.site_id AND t.metadata->>'requirement_id'=r.id::text
      AND t.transaction_type NOT IN ('sandbox_usage','agent_model_reservation',
        'agent_model_refund','agent_model_refund_expired','agent_model_settlement','agent_model_actual_cost')
    UNION ALL
    SELECT t.amount FROM public.harness_sessions s
    JOIN public.credit_transactions t ON t.site_id=s.site_id AND t.metadata->>'session_id'=s.id::text
    WHERE s.site_id=r.site_id AND s.snapshot#>>'{request,requirementId}'=r.id::text
      -- Never charge two requirements for conflicting provenance.
      AND t.metadata->>'requirement_id' IS NULL
      AND t.transaction_type NOT IN ('sandbox_usage','agent_model_reservation',
        'agent_model_refund','agent_model_refund_expired','agent_model_settlement','agent_model_actual_cost')
  ) charges;
  SELECT coalesce(sum(s.credits_charged),0) INTO sandbox_spent
    FROM public.sandbox_billing_sessions s
    JOIN public.sandbox_billing_resources b ON b.sandbox_name=s.sandbox_name
    WHERE b.site_id=r.site_id AND b.owner_kind='requirement' AND b.owner_id=r.id;
  total_spent:=model_spent+tool_spent+sandbox_spent;
  RETURN jsonb_build_object('state',CASE WHEN r.budget IS NULL THEN 'unlimited'
    WHEN total_spent>=r.budget THEN 'exhausted' ELSE 'available' END,
    'budget_usd',r.budget,'spent_usd',total_spent,'model_usd',model_spent,
    'tools_usd',tool_spent,'sandbox_usd',sandbox_spent,'pending_model_reservations',pending_models);
END;
$$;


--
-- Name: requirement_pause_command_guard(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.requirement_pause_command_guard(p_id uuid, p_guard jsonb) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.requirements%ROWTYPE; baseline bigint; count_commands bigint;
BEGIN
  SELECT * INTO r FROM public.requirements WHERE id=p_id;
  IF NOT FOUND THEN RETURN false; END IF;
  IF to_jsonb(r)-ARRAY['budget','updated_at'] = p_guard THEN RETURN true; END IF;
  IF to_jsonb(r)-ARRAY['budget','updated_at','external_user_action_revision','last_external_user_action_id']
    IS DISTINCT FROM p_guard-ARRAY['external_user_action_revision','last_external_user_action_id'] THEN RETURN false; END IF;
  baseline:=(p_guard->>'external_user_action_revision')::bigint;
  IF baseline IS NULL OR r.external_user_action_revision<=baseline THEN RETURN false; END IF;
  SELECT count(*) INTO count_commands FROM public.requirement_commands c
    JOIN public.requirement_user_action_receipts receipt ON receipt.requirement_id=c.requirement_id
      AND receipt.action_id=c.action_id AND receipt.revision=c.revision
    JOIN public.instance_logs a ON a.id=c.action_id AND a.site_id=r.site_id
    WHERE c.requirement_id=r.id AND c.applied_at IS NULL AND c.revision>baseline
      AND c.revision<=r.external_user_action_revision AND a.log_type='user_action' AND a.trusted_user_action IS TRUE;
  RETURN count_commands=r.external_user_action_revision-baseline AND EXISTS (
    SELECT 1 FROM public.requirement_commands c WHERE c.requirement_id=r.id
      AND c.revision=r.external_user_action_revision AND c.action_id::text=r.last_external_user_action_id
      AND c.applied_at IS NULL);
END;
$$;


--
-- Name: requirement_quarantine_timestamp(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.requirement_quarantine_timestamp(p_item jsonb) RETURNS timestamp with time zone
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
DECLARE
  v_value text;
BEGIN
  v_value := COALESCE(
    NULLIF(p_item->'review_quarantine'->>'quarantined_at', ''),
    NULLIF(p_item->>'updated_at', '')
  );
  IF v_value IS NULL THEN
    RETURN 'infinity'::timestamptz;
  END IF;
  RETURN v_value::timestamptz;
EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN
  RETURN 'infinity'::timestamptz;
END;
$$;

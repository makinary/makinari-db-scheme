SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: apps_record_migration_feedback(text, uuid, text, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_record_migration_feedback(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_context_key text, p_error jsonb DEFAULT NULL::jsonb) RETURNS public.apps_migration_feedback
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  namespace_oid oid;
  existing_receipt jsonb;
  result public.apps_migration_feedback%ROWTYPE;
BEGIN
  IF p_target_schema IS NULL OR p_target_schema !~ '^app_[a-f0-9]{24}$'
    OR p_expected_tenant_id IS NULL
    OR p_migration_key IS NULL OR octet_length(p_migration_key) > 522
    OR p_migration_key !~ '^migration:(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*[.]sql$'
    OR p_migration_key ~ '(^|/)[.]{1,2}(/|$)' OR p_migration_key LIKE '%//%'
    OR p_migration_checksum IS NULL OR p_migration_checksum !~ '^[a-f0-9]{64}$'
    OR p_context_key IS NULL OR octet_length(p_context_key) NOT BETWEEN 1 AND 256
    OR (p_error IS NOT NULL AND (jsonb_typeof(p_error) <> 'object' OR octet_length(p_error::text) > 4096))
  THEN
    RAISE EXCEPTION 'Invalid migration feedback payload';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_target_schema, 0));
  IF NOT EXISTS (
    SELECT 1 FROM public.apps_tenants
    WHERE tenant_id = p_expected_tenant_id AND schema = p_target_schema AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Tenant and schema do not match an active tenant';
  END IF;
  SELECT n.oid INTO namespace_oid
  FROM pg_catalog.pg_namespace n JOIN pg_catalog.pg_roles r ON r.oid = n.nspowner
  WHERE n.nspname = p_target_schema
    AND r.rolname = 'app_owner_' || substring(p_target_schema FROM 5)
    AND NOT (r.rolcanlogin OR r.rolinherit OR r.rolsuper OR r.rolcreatedb
      OR r.rolcreaterole OR r.rolreplication OR r.rolbypassrls)
    AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_auth_members WHERE member = r.oid);
  IF namespace_oid IS NULL OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class
    WHERE relnamespace = namespace_oid AND relname = '_meta' AND relkind = 'r'
      AND relowner = to_regrole('apps_migration_coordinator')::oid AND relrowsecurity
  ) THEN
    RAISE EXCEPTION 'Migration feedback requires an isolated schema and protected receipts';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.apps_migration_feedback
    WHERE target_schema = p_target_schema AND tenant_id <> p_expected_tenant_id
  ) THEN
    RAISE EXCEPTION 'Migration feedback tenant binding changed';
  END IF;

  EXECUTE format('SELECT jsonb_build_object(''value'', value) FROM %I._meta WHERE key = $1', p_target_schema)
    INTO existing_receipt USING p_migration_key;
  IF existing_receipt IS NOT NULL THEN
    -- Fail closed on legacy receipts without a checksum. Never backfill, replace,
    -- clear a diagnostic, or otherwise mutate an already-applied file here.
    IF existing_receipt->'value'->>'checksum' IS DISTINCT FROM p_migration_checksum THEN
      RAISE EXCEPTION 'Migration % changed after application or has no verifiable checksum', p_migration_key;
    END IF;
    result := ROW(p_target_schema, p_migration_key, p_expected_tenant_id,
      p_migration_checksum, p_context_key, p_error, now())::public.apps_migration_feedback;
    RETURN result;
  END IF;

  INSERT INTO public.apps_migration_feedback AS f (
    target_schema, migration_key, tenant_id, checksum, context_key, error, updated_at
  ) VALUES (
    p_target_schema, p_migration_key, p_expected_tenant_id,
    p_migration_checksum, p_context_key, p_error, now()
  ) ON CONFLICT (target_schema, migration_key) DO UPDATE SET
    checksum = EXCLUDED.checksum, context_key = EXCLUDED.context_key,
    error = EXCLUDED.error, updated_at = EXCLUDED.updated_at
  WHERE f.tenant_id = EXCLUDED.tenant_id
  RETURNING f.* INTO result;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Migration feedback tenant binding changed';
  END IF;
  RETURN result;
END;
$_$;


--
-- Name: apps_reload_migration_schema(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_reload_migration_schema(p_target_schema text, p_expected_tenant_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  -- Reuse the exact active binding, isolated schema/ledger trust and stream
  -- lock checks rather than introducing a weaker cache-reload authorization.
  PERFORM public.apps_get_migration_workspace(p_target_schema, p_expected_tenant_id);
  PERFORM pg_catalog.pg_notify('pgrst', 'reload schema');
END;
$$;


--
-- Name: archive_catalog_category(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.archive_catalog_category(p_site_id uuid, p_category_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4320078($1,$2); END$_$;


--
-- Name: archive_site(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.archive_site(p_site_id uuid, p_actor_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  site_row public.sites%ROWTYPE;
  domain_snapshot jsonb;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' OR p_actor_id IS NULL THEN
    RAISE EXCEPTION 'Password-verified server access is required' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO site_row FROM public.sites WHERE id = p_site_id FOR UPDATE;
  IF NOT FOUND OR site_row.user_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'Only the site owner can archive this site' USING ERRCODE = '42501';
  END IF;
  IF site_row.archived_at IS NOT NULL THEN
    RETURN true;
  END IF;

  SELECT coalesce(jsonb_agg(to_jsonb(d)), '[]'::jsonb) INTO domain_snapshot
    FROM public.allowed_domains d WHERE d.site_id = p_site_id;

  UPDATE public.sites SET
    archived_at = now(),
    archived_by = p_actor_id,
    archive_snapshot = jsonb_build_object(
      'url', site_row.url,
      'tracking', site_row.tracking,
      'allowed_domains', domain_snapshot
    ),
    url = NULL,
    tracking = coalesce(site_row.tracking, '{}'::jsonb) || jsonb_build_object(
      'track_visitors', false, 'track_actions', false,
      'record_screen', false, 'enable_chat', false
    ),
    updated_at = now()
  WHERE id = p_site_id;

  -- Only routing associations are removed; original rows remain in the snapshot.
  -- Business data, ownership, settings, orders and billing history are retained.
  DELETE FROM public.allowed_domains WHERE site_id = p_site_id;
  UPDATE public.api_keys SET status = 'revoked', updated_at = now()
    WHERE site_id = p_site_id AND status = 'active';
  RETURN true;
END;
$$;


--
-- Name: assert_agent_requirement_run(uuid, text, integer, uuid, boolean, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_agent_requirement_run(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_allow_terminal boolean DEFAULT false, p_renew_seconds integer DEFAULT 300) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.requirements%ROWTYPE; m public.harness_requirement_runs%ROWTYPE; s public.harness_sessions%ROWTYPE; i uuid;
BEGIN
  IF p_run_id IS NULL OR p_generation IS NULL OR p_session_id IS NULL OR p_allow_terminal IS NULL
    OR p_renew_seconds IS NULL OR p_renew_seconds NOT BETWEEN 1 AND 300 THEN RETURN false; END IF;
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id FOR UPDATE;
  IF NOT FOUND OR r.cron_lock_run_id IS DISTINCT FROM p_run_id OR r.cron_lock_active IS NOT TRUE
    OR r.cron_lock_expires_at IS NULL OR r.cron_lock_expires_at<=clock_timestamp()
    OR r.metadata->>'requirement_execution_generation' IS DISTINCT FROM p_generation::text
    OR r.status IS NULL OR (r.status NOT IN ('backlog','in-progress') AND NOT (p_allow_terminal AND r.status IN ('blocked','on-review','done')))
  THEN RETURN false; END IF;
  SELECT * INTO m FROM public.harness_requirement_runs WHERE requirement_id=r.id FOR UPDATE;
  IF NOT FOUND OR m.site_id<>r.site_id OR m.session_id<>p_session_id OR m.generation<>p_generation THEN RETURN false; END IF;
  SELECT id INTO i FROM public.remote_instances WHERE id::text=r.metadata->>'runner_instance_id' AND site_id=r.site_id;
  IF i IS NULL OR NOT public.agent_requirement_runner_allowed(r.id,i) THEN RETURN false; END IF;
  SELECT * INTO s FROM public.harness_sessions WHERE id=p_session_id FOR UPDATE;
  IF FOUND THEN
    IF s.site_id<>r.site_id OR s.user_id<>r.user_id
      OR (s.snapshot#>>'{request,requirementId}' IS NOT NULL AND s.snapshot#>>'{request,requirementId}'<>r.id::text)
      OR (NOT p_allow_terminal AND s.snapshot->>'status' NOT IN ('queued','running')) THEN RETURN false; END IF;
    -- Session token is separate: never replace owner, reset counters, or revive an
    -- expired session lease. The engine independently asserts its exact token.
    IF s.lease_expires_at>clock_timestamp() AND s.snapshot->>'status'='running' THEN
      UPDATE public.harness_sessions SET lease_expires_at=clock_timestamp()+make_interval(secs=>p_renew_seconds) WHERE id=s.id;
    END IF;
  END IF;
  UPDATE public.requirements SET cron_lock_expires_at=clock_timestamp()+make_interval(secs=>p_renew_seconds) WHERE id=r.id;
  RETURN true;
END;
$$;


--
-- Name: assert_credit_auto_top_up_service_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_credit_auto_top_up_service_role() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF coalesce(current_setting('request.jwt.claim.role',true),'') IN ('anon','authenticated')
    OR (coalesce(current_setting('request.jwt.claim.role',true),'') <> 'service_role'
      AND coalesce(current_setting('role',true),'') <> 'service_role') THEN
    RAISE EXCEPTION 'Automatic credit top-up requires service role';
  END IF;
END;
$$;


--
-- Name: assert_harness_sandbox_cleanup(uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid, p_resource text) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT EXISTS (SELECT 1 FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id
    AND sandbox_cleanup_token=p_token AND sandbox_cleanup_resource=p_resource);
$$;


--
-- Name: assert_requirement_cron_execution_owner(uuid, text, integer, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_requirement_cron_execution_owner(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean DEFAULT false, p_allow_terminal boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_result jsonb;
  v_handoff jsonb;
  v_runner text;
BEGIN
  v_result := public.assert_requirement_cron_execution_owner_before_assistant_handoff(
    p_requirement_id, p_run_id, p_expected_execution_generation, p_allow_inactive, p_allow_terminal);
  IF v_result->>'current' <> 'true' THEN RETURN v_result; END IF;
  SELECT metadata->>'runner_instance_id' INTO v_runner FROM public.requirements
    WHERE id = p_requirement_id;
  -- Terminal cleanup may stop the owned sandbox after a user pause. The base
  -- assertion still fences run/generation/expiry; this does not authorize work.
  IF v_runner IS NOT NULL AND p_allow_terminal IS NOT TRUE THEN
    v_handoff := public.inspect_requirement_assistant_handoff(p_requirement_id, v_runner::uuid);
    IF NOT (v_handoff->>'allowed')::boolean THEN
      RETURN jsonb_build_object('current', false, 'reason', v_handoff->>'reason');
    END IF;
  END IF;
  RETURN v_result;
END;
$$;


--
-- Name: assert_requirement_cron_execution_owner_before_assistant_handof(uuid, text, integer, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_requirement_cron_execution_owner_before_assistant_handof(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean DEFAULT false, p_allow_terminal boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_requirement public.requirements%ROWTYPE;
  v_generation integer;
BEGIN
  IF NULLIF(btrim(p_run_id), '') IS NULL
    OR p_expected_execution_generation IS NULL
    OR p_expected_execution_generation < 0
  THEN
    RETURN jsonb_build_object('current', false, 'reason', 'missing_execution_identity');
  END IF;

  -- Serialize the observation with claim/revoke/resume/finalization mutations.
  SELECT * INTO v_requirement FROM public.requirements
  WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('current', false, 'reason', 'requirement_missing');
  END IF;
  v_generation := CASE
    WHEN COALESCE(v_requirement.metadata->>'requirement_execution_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_requirement.metadata->>'requirement_execution_generation')::integer
    ELSE 0 END;
  IF v_requirement.cron_lock_run_id IS DISTINCT FROM p_run_id THEN
    RETURN jsonb_build_object('current', false, 'reason', 'run_owner_changed');
  END IF;
  IF v_generation IS DISTINCT FROM p_expected_execution_generation THEN
    RETURN jsonb_build_object('current', false, 'reason', 'execution_generation_changed');
  END IF;
  IF v_requirement.cron_lock_expires_at IS NULL
    OR v_requirement.cron_lock_expires_at <= pg_catalog.clock_timestamp()
  THEN
    RETURN jsonb_build_object('current', false, 'reason', 'lease_expired');
  END IF;
  IF NOT COALESCE(p_allow_inactive, false)
    AND v_requirement.cron_lock_active IS DISTINCT FROM true
  THEN
    RETURN jsonb_build_object('current', false, 'reason', 'lease_inactive');
  END IF;
  IF NOT COALESCE(p_allow_terminal, false) AND (
    COALESCE(v_requirement.status, '') NOT IN ('backlog', 'in-progress')
    OR EXISTS (
      SELECT 1 FROM public.remote_instances AS instance
      WHERE instance.id::text = v_requirement.metadata->>'runner_instance_id'
        AND instance.status = 'paused'
    )
    OR COALESCE((
      SELECT plan.status FROM public.instance_plans AS plan
      WHERE plan.instance_id::text = v_requirement.metadata->>'runner_instance_id'
        AND plan.status IN ('pending', 'in_progress', 'active', 'paused')
      ORDER BY plan.created_at DESC, plan.id DESC LIMIT 1
    ), '') = 'paused'
  ) THEN
    RETURN jsonb_build_object('current', false, 'reason', 'execution_not_runnable');
  END IF;
  RETURN jsonb_build_object('current', true);
END;
$_$;


--
-- Name: assert_visitor_identity_service_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_visitor_identity_service_role() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception using errcode = '42501', message = 'service_role_required';
  end if;
end;
$$;


--
-- Name: assign_location_scope(text, uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assign_location_scope(p_table text, p_id uuid, p_site_id uuid, p_location_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $_$
DECLARE scope_column text; changed integer;
BEGIN
  IF current_setting('transaction_isolation') <> 'read committed' THEN
    RAISE EXCEPTION 'Scope assignment requires READ COMMITTED' USING ERRCODE='40001';
  END IF;
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  PERFORM public.lock_site_license(p_site_id);
  IF coalesce(public.current_user_site_role(p_site_id),'') NOT IN ('owner','admin')
    OR p_location_id IS NULL OR NOT public.user_can_access_location(p_site_id,p_location_id) THEN
    RAISE EXCEPTION 'Manager location access required' USING ERRCODE='42501';
  END IF;
  SELECT location_column INTO scope_column FROM location_acl_private.roots
    WHERE table_name=p_table AND table_name IN ('deals','quotations','subscriptions','tasks',
      'conversations','records','sale_orders','reservations');
  IF scope_column IS NULL THEN RAISE EXCEPTION 'Unsupported scope root' USING ERRCODE='22023'; END IF;
  INSERT INTO location_acl_private.scope_assignments VALUES
    (txid_current(),p_table,p_id,p_site_id,p_location_id,auth.uid());
  EXECUTE format('UPDATE public.%I SET %I=$1 WHERE id=$2 AND site_id=$3 AND %I IS NULL',
    p_table,scope_column,scope_column) USING p_location_id,p_id,p_site_id;
  GET DIAGNOSTICS changed=ROW_COUNT;
  DELETE FROM location_acl_private.scope_assignments
    WHERE transaction_id=txid_current() AND table_name=p_table AND row_id=p_id;
  IF changed<>1 THEN RAISE EXCEPTION 'Unresolved root not found' USING ERRCODE='22023'; END IF;
  RETURN jsonb_build_object('table',p_table,'id',p_id,'site_id',p_site_id,'location_id',p_location_id);
END;
$_$;


--
-- Name: assign_migration_diagnostic_followup(uuid, text, uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assign_migration_diagnostic_followup(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_lifecycle public.requirement_migration_lifecycle%ROWTYPE;
  v_diagnostic public.requirement_migration_diagnostics%ROWTYPE;
BEGIN
  IF p_token IS NULL THEN
    RAISE EXCEPTION 'Invalid migration diagnostic token' USING ERRCODE = '22023';
  END IF;
  v_lifecycle := public.lock_requirement_migration_diagnostic_scope(
    p_requirement_id, p_file, p_execution_generation, p_run_id, true);
  SELECT * INTO v_diagnostic FROM public.requirement_migration_diagnostics
    WHERE requirement_id = p_requirement_id AND file = p_file FOR UPDATE;
  IF NOT FOUND OR v_diagnostic.token IS DISTINCT FROM p_token
    OR v_diagnostic.execution_generation IS DISTINCT FROM p_execution_generation
    OR v_diagnostic.checksum IS DISTINCT FROM v_lifecycle.checksum
    OR v_diagnostic.specification_checksum IS DISTINCT FROM v_lifecycle.specification_checksum
    OR v_diagnostic.state NOT IN ('followup_ready', 'followup_assigned')
  THEN
    RAISE EXCEPTION 'Migration diagnostic followup scope conflict' USING ERRCODE = '40001';
  END IF;
  IF v_diagnostic.state = 'followup_assigned' THEN RETURN to_jsonb(v_diagnostic); END IF;
  UPDATE public.requirement_migration_diagnostics SET state = 'followup_assigned', updated_at = clock_timestamp()
    WHERE requirement_id = p_requirement_id AND file = p_file RETURNING * INTO v_diagnostic;
  RETURN to_jsonb(v_diagnostic);
END;
$$;


--
-- Name: attach_credit_auto_top_up_payment_method_internal(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attach_credit_auto_top_up_payment_method_internal(p_site_id uuid, p_stripe_payment_method_id text, p_stripe_customer_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_site_id IS NULL OR p_stripe_payment_method_id IS NULL
    OR p_stripe_payment_method_id !~ '^pm_[A-Za-z0-9]+$'
    OR p_stripe_customer_id IS NULL OR p_stripe_customer_id !~ '^cus_[A-Za-z0-9]+$'
  THEN RAISE EXCEPTION 'Invalid verified Stripe payment method'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR b.stripe_customer_id IS DISTINCT FROM p_stripe_customer_id THEN
    RAISE EXCEPTION 'Stripe customer does not match billing account';
  END IF;
  INSERT INTO public.credit_auto_top_up_settings(site_id,stripe_payment_method_id)
    VALUES (p_site_id,p_stripe_payment_method_id)
  ON CONFLICT (site_id) DO UPDATE SET
    stripe_payment_method_id=excluded.stripe_payment_method_id,updated_at=now();
  RETURN jsonb_build_object('success',true,'outcome','attached','site_id',p_site_id);
END;
$_$;


--
-- Name: auth_user_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_user_id() RETURNS uuid
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16697(); END$$;

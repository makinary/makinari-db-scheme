SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: authorize_credit_auto_top_up_dispatch(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.authorize_credit_auto_top_up_dispatch(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; s public.credit_auto_top_up_settings%ROWTYPE;
  a public.credit_auto_top_up_attempts%ROWTYPE; v_now timestamptz;
  v_reason text; v_spent bigint; v_month timestamptz;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  PERFORM public.renew_site_plan_credits(p_site_id);
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  SELECT * INTO a FROM public.credit_auto_top_up_attempts
    WHERE site_id=p_site_id AND id=p_attempt_id FOR UPDATE;
  SELECT * INTO s FROM public.credit_auto_top_up_settings WHERE site_id=p_site_id FOR UPDATE;
  v_now := clock_timestamp();
  IF a.id IS NULL OR a.status <> 'pending' OR a.claim_token IS DISTINCT FROM p_claim_token
    OR a.claim_expires_at <= v_now OR a.dispatch_started_at IS NOT NULL
    OR a.stripe_payment_intent_id IS NOT NULL THEN
    RETURN jsonb_build_object('success',true,'outcome','not_authorized','reason','stale_or_dispatched',
      'attempt_id',p_attempt_id,'dispatch_started_at',a.dispatch_started_at);
  END IF;
  IF s.site_id IS NULL OR NOT s.enabled OR s.state <> 'ready'
    OR a.settings_revision IS DISTINCT FROM s.settings_revision
    OR b.stripe_customer_id IS DISTINCT FROM a.stripe_customer_id
    OR s.stripe_payment_method_id IS DISTINCT FROM a.stripe_payment_method_id THEN
    v_reason := 'consent_changed';
  ELSIF b.site_id IS NULL OR b.status IS DISTINCT FROM 'active'
    OR NOT EXISTS (SELECT 1 FROM public.sites WHERE id=p_site_id AND archived_at IS NULL)
    OR b.stripe_customer_id IS NULL OR b.stripe_customer_id !~ '^cus_[A-Za-z0-9]+$'
    OR s.stripe_payment_method_id IS NULL OR s.stripe_payment_method_id !~ '^pm_[A-Za-z0-9]+$'
    OR b.credits_available >= s.minimum_credits
    OR a.credits IS DISTINCT FROM ceil(s.target_credits-b.credits_available)::integer
    OR a.amount_cents <> a.credits*100 THEN
    v_reason := 'not_eligible';
  ELSE
    v_month := date_trunc('month',v_now AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
    SELECT coalesce(sum(amount_cents),0) INTO v_spent
      FROM public.credit_auto_top_up_attempts WHERE site_id=p_site_id AND
      (status='pending' OR (status='succeeded'
        AND greatest(created_at,finished_at) >= v_month
        AND greatest(created_at,finished_at) < (v_month AT TIME ZONE 'UTC'+interval '1 month') AT TIME ZONE 'UTC'));
    IF v_spent > s.max_monthly_spend_cents THEN v_reason := 'monthly_cap'; END IF;
  END IF;
  IF v_reason IS NOT NULL THEN
    -- No external operation was authorized: release only this reservation,
    -- without pausing the user's settings or requiring a Stripe cancellation.
    UPDATE public.credit_auto_top_up_attempts SET status='failed',finished_at=v_now WHERE id=a.id;
    RETURN jsonb_build_object('success',true,'outcome','not_authorized','reason',v_reason,'attempt_id',a.id);
  END IF;
  UPDATE public.credit_auto_top_up_attempts SET dispatch_started_at=v_now WHERE id=a.id;
  RETURN jsonb_build_object('success',true,'outcome','authorized','attempt_id',a.id,
    'idempotency_key','credit-auto-top-up-'||a.id::text,
    'claim_token',a.claim_token,'claim_expires_at',a.claim_expires_at,'dispatch_started_at',v_now,
    'credits',a.credits,'amount_cents',a.amount_cents,
    'stripe_customer_id',a.stripe_customer_id,'stripe_payment_method_id',a.stripe_payment_method_id);
END;
$_$;


--
-- Name: authorize_order_item_unit_sync(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.authorize_order_item_unit_sync() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  command_name text := CASE
    WHEN TG_OP = 'INSERT' THEN 'insert'
    WHEN TG_OP = 'DELETE' THEN 'delete'
    ELSE 'update'
  END;
  target_site_id uuid;
  is_service_role boolean :=
    current_setting('role', true) = 'service_role'
    OR COALESCE((auth.jwt() ->> 'role') = 'service_role', false)
    OR session_user = 'postgres';
BEGIN
  target_site_id := CASE
    WHEN TG_OP = 'DELETE' THEN OLD.site_id
    ELSE NEW.site_id
  END;
  IF NOT is_service_role
    AND NOT public.user_can(target_site_id, command_name)
    AND NOT EXISTS (
      SELECT 1
      FROM public.site_ownership AS ownership
      WHERE ownership.site_id = target_site_id
        AND ownership.user_id = auth.uid()
    )
  THEN
    RAISE EXCEPTION 'Insufficient permissions' USING ERRCODE = '42501';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: backfill_catalog_search(uuid, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.backfill_catalog_search(p_after_id uuid, p_limit integer, p_site_id uuid) RETURNS TABLE(catalog_item_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE v_id uuid; v_locked uuid;
BEGIN
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'invalid backfill limit' USING ERRCODE = '22023';
  END IF;
  FOR v_id IN SELECT i.id FROM public.catalog_items i
    WHERE (p_after_id IS NULL OR i.id > p_after_id) AND (p_site_id IS NULL OR i.site_id = p_site_id)
    ORDER BY i.id LIMIT p_limit
  LOOP
    SELECT i.id INTO v_locked FROM public.catalog_items i WHERE i.id = v_id FOR NO KEY UPDATE SKIP LOCKED;
    IF FOUND THEN
      PERFORM public.refresh_catalog_search_document(v_id);
      UPDATE public.catalog_embedding_jobs SET status = 'pending', attempts = 0,
        next_attempt_at = now(), last_error = NULL, updated_at = now()
        WHERE public.catalog_embedding_jobs.catalog_item_id = v_id AND status = 'exhausted';
    ELSE
      -- Advancing the cursor remains safe; the deferred item is durable.
      INSERT INTO public.catalog_search_refresh_events(catalog_item_id, revive_exhausted) VALUES (v_id, true);
    END IF;
    catalog_item_id := v_id;
    RETURN NEXT;
  END LOOP;
END $$;


--
-- Name: begin_credit_auto_top_up_attempt(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_credit_auto_top_up_attempt(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; s public.credit_auto_top_up_settings%ROWTYPE;
  a public.credit_auto_top_up_attempts%ROWTYPE; v_credits integer; v_cents integer;
  v_spent bigint; v_month timestamptz; v_now timestamptz;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_site_id IS NULL THEN RAISE EXCEPTION 'Site required'; END IF;
  PERFORM public.renew_site_plan_credits(p_site_id);
  -- All charge/configuration/settlement writers serialize on billing first.
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',true,'outcome','not_eligible'); END IF;
  SELECT * INTO a FROM public.credit_auto_top_up_attempts
    WHERE site_id=p_site_id AND status='pending' FOR UPDATE;
  SELECT * INTO s FROM public.credit_auto_top_up_settings WHERE site_id=p_site_id FOR UPDATE;
  v_now := clock_timestamp();
  IF a.id IS NOT NULL THEN
    IF a.dispatch_started_at IS NOT NULL AND a.stripe_payment_intent_id IS NULL THEN
      RETURN jsonb_build_object('success',true,'outcome','needs_reconciliation',
        'attempt_id',a.id,'dispatch_started_at',a.dispatch_started_at);
    END IF;
    -- Saved Stripe identities remain recoverable after disabling consent.
    IF a.dispatch_started_at IS NULL AND a.stripe_payment_intent_id IS NULL AND
      (s.site_id IS NULL OR NOT s.enabled OR s.state <> 'ready'
        OR s.settings_revision IS DISTINCT FROM a.settings_revision
        OR b.stripe_customer_id IS DISTINCT FROM a.stripe_customer_id
        OR s.stripe_payment_method_id IS DISTINCT FROM a.stripe_payment_method_id) THEN
      UPDATE public.credit_auto_top_up_attempts SET status='failed',finished_at=v_now WHERE id=a.id;
      RETURN jsonb_build_object('success',true,'outcome','not_eligible','reason','consent_changed','attempt_id',a.id);
    END IF;
    IF a.claim_expires_at > v_now THEN
      RETURN jsonb_build_object('success',true,'outcome','in_progress','attempt_id',a.id);
    END IF;
    UPDATE public.credit_auto_top_up_attempts SET claim_token=gen_random_uuid(),
      claim_expires_at=v_now+interval '10 minutes' WHERE id=a.id RETURNING * INTO a;
  ELSE
    IF s.site_id IS NULL OR NOT s.enabled OR s.state <> 'ready'
      OR b.status IS DISTINCT FROM 'active'
      OR NOT EXISTS (SELECT 1 FROM public.sites WHERE id=p_site_id AND archived_at IS NULL)
      OR b.stripe_customer_id IS NULL OR b.stripe_customer_id !~ '^cus_[A-Za-z0-9]+$'
      OR s.stripe_payment_method_id IS NULL OR b.credits_available >= s.minimum_credits THEN
      RETURN jsonb_build_object('success',true,'outcome','not_eligible');
    END IF;
    v_credits := ceil(s.target_credits-b.credits_available)::integer;
    IF v_credits NOT BETWEEN 1 AND 1000000 THEN
      RETURN jsonb_build_object('success',true,'outcome','not_eligible');
    END IF;
    v_cents := v_credits*100;
    v_month := date_trunc('month',v_now AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
    SELECT coalesce(sum(amount_cents),0) INTO v_spent
      FROM public.credit_auto_top_up_attempts WHERE site_id=p_site_id AND
      (status='pending' OR (status='succeeded'
        AND greatest(created_at,finished_at) >= v_month
        AND greatest(created_at,finished_at) < (v_month AT TIME ZONE 'UTC'+interval '1 month') AT TIME ZONE 'UTC'));
    IF v_spent+v_cents > s.max_monthly_spend_cents THEN
      RETURN jsonb_build_object('success',true,'outcome','not_eligible','reason','monthly_cap');
    END IF;
    INSERT INTO public.credit_auto_top_up_attempts(site_id,credits,amount_cents,
      stripe_customer_id,stripe_payment_method_id,claim_expires_at,settings_revision)
    VALUES (p_site_id,v_credits,v_cents,b.stripe_customer_id,s.stripe_payment_method_id,
      v_now+interval '10 minutes',s.settings_revision) RETURNING * INTO a;
  END IF;
  RETURN jsonb_build_object('success',true,'outcome','claimed','attempt_id',a.id,
    'idempotency_key','credit-auto-top-up-'||a.id::text,
    'claim_token',a.claim_token,'claim_expires_at',a.claim_expires_at,
    'credits',a.credits,'amount_cents',a.amount_cents,
    'stripe_customer_id',a.stripe_customer_id,'stripe_payment_method_id',a.stripe_payment_method_id,
    'stripe_payment_intent_id',a.stripe_payment_intent_id,'dispatch_started_at',a.dispatch_started_at);
END;
$_$;


--
-- Name: begin_credit_auto_top_up_setup(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_credit_auto_top_up_setup(p_site_id uuid, p_actor_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; v_token uuid := gen_random_uuid();
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_actor_id IS NULL THEN RAISE EXCEPTION 'Authenticated actor required'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR b.stripe_customer_id IS NULL THEN RAISE EXCEPTION 'Billing customer required'; END IF;
  UPDATE public.credit_auto_top_up_settings SET enabled=false WHERE site_id=p_site_id;
  INSERT INTO public.credit_auto_top_up_card_setups(site_id,token,actor_id,stripe_customer_id,status)
    VALUES(p_site_id,v_token,p_actor_id,b.stripe_customer_id,'pending')
  ON CONFLICT(site_id) DO UPDATE SET token=excluded.token,actor_id=excluded.actor_id,
    stripe_customer_id=excluded.stripe_customer_id,status='pending',stripe_payment_method_id=NULL,
    created_at=now(),completed_at=NULL;
  RETURN jsonb_build_object('outcome','started','token',v_token,'stripe_customer_id',b.stripe_customer_id);
END;
$$;


--
-- Name: begin_harness_sandbox_cleanup(uuid, uuid, text, text, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_owner text, p_resource text, p_token uuid, p_bootstrap boolean DEFAULT false) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_sessions%ROWTYPE;
BEGIN
  SELECT * INTO r FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR p_token IS NULL OR r.sandbox_cleanup_token IS NOT NULL THEN RETURN false; END IF;
  -- Serializes against register_sandbox_billing (which locks this same row).
  PERFORM 1 FROM public.sandbox_billing_resources WHERE sandbox_name=p_resource FOR UPDATE;
  IF p_owner IS NULL THEN
    PERFORM 1 FROM public.requirements WHERE id::text=r.snapshot#>>'{request,requirementId}' FOR UPDATE;
    -- Housekeeping may discover canonical h-session resources, but only from
    -- trusted same-tenant requirement sessions with no resumable references.
    IF p_bootstrap OR p_resource IS DISTINCT FROM 'h-'||p_id::text
      OR r.snapshot->>'status' NOT IN ('completed','cancelled','failed')
      OR r.lease_expires_at > clock_timestamp()
      OR NOT EXISTS (SELECT 1 FROM public.sandbox_billing_resources b JOIN public.requirements q
        ON q.id=b.owner_id AND q.site_id=b.site_id WHERE b.sandbox_name=p_resource
        AND b.site_id=p_site_id AND b.owner_kind='requirement'
        AND q.id::text=r.snapshot#>>'{request,requirementId}' AND q.status IN ('done','cancelled','canceled'))
      OR EXISTS (SELECT 1 FROM public.harness_sessions s WHERE s.snapshot#>>'{workspace,id}'=p_resource
        AND (s.site_id<>p_site_id OR s.snapshot#>>'{request,requirementId}' IS DISTINCT FROM r.snapshot#>>'{request,requirementId}'
          OR s.snapshot->>'status' NOT IN ('completed','cancelled','failed') OR s.lease_expires_at>clock_timestamp()))
      OR EXISTS (SELECT 1 FROM public.harness_sessions s WHERE s.site_id=p_site_id
        AND s.snapshot#>>'{request,requirementId}'=r.snapshot#>>'{request,requirementId}'
        AND (s.snapshot->>'status' NOT IN ('completed','cancelled','failed') OR s.lease_expires_at>clock_timestamp()))
      OR EXISTS (SELECT 1 FROM public.requirement_status WHERE active_sandbox_id=p_resource)
      OR EXISTS (SELECT 1 FROM public.instance_plans WHERE metadata->>'active_sandbox_id'=p_resource) THEN RETURN false; END IF;
  ELSIF r.lease_owner IS DISTINCT FROM p_owner OR r.lease_expires_at <= clock_timestamp()
    OR r.lease_expires_at IS NULL THEN RETURN false;
  ELSIF p_bootstrap THEN
    IF p_resource IS DISTINCT FROM 'h-'||p_id::text OR r.snapshot ? 'workspace'
      OR r.snapshot->>'status' NOT IN ('running','waiting','paused','failed') THEN RETURN false; END IF;
  ELSE
    IF r.snapshot->>'status' NOT IN ('waiting','paused','completed','cancelled','failed')
      OR r.snapshot#>>'{workspace,id}' IS DISTINCT FROM p_resource THEN RETURN false; END IF;
  END IF;
  UPDATE public.harness_sessions SET sandbox_cleanup_token=p_token,
    sandbox_cleanup_resource=p_resource,sandbox_cleanup_started_at=clock_timestamp() WHERE id=p_id;
  RETURN true;
END;
$$;


--
-- Name: begin_icp_dispatch(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_icp_dispatch(p_id uuid, p_run_id uuid, p_workflow_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE d public.icp_dispatch_runs; r public.icp_mining; claim jsonb;
BEGIN
  IF p_run_id IS NULL OR NULLIF(btrim(p_workflow_id), '') IS NULL THEN RAISE EXCEPTION 'Execution identity required'; END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(734210, 1);
  SELECT * INTO d FROM public.icp_dispatch_runs WHERE id = p_id FOR UPDATE;
  IF NOT FOUND OR d.workflow_id IS DISTINCT FROM p_workflow_id THEN RAISE EXCEPTION 'Dispatch workflow mismatch'; END IF;
  IF d.run_id IS NOT NULL AND d.run_id IS DISTINCT FROM p_run_id THEN RAISE EXCEPTION 'Dispatch run mismatch'; END IF;
  IF d.state NOT IN ('reserved', 'running') THEN RETURN jsonb_build_object('acquired', false, 'reason', d.state); END IF;
  IF d.state = 'reserved' THEN
    UPDATE public.icp_dispatch_runs SET run_id = p_run_id, updated_at = clock_timestamp() WHERE id = d.id RETURNING * INTO d;
    claim := public.claim_icp_mining_execution(d.icp_mining_id, d.site_id, p_run_id, p_workflow_id);
    IF (claim->>'acquired')::boolean IS DISTINCT FROM true THEN
      -- Uncertain start never returns its quota/slot. Manual reconciliation only.
      UPDATE public.icp_dispatch_runs SET state = 'blocked', error = 'begin_claim_not_acquired',
        updated_at = clock_timestamp() WHERE id = d.id;
      RETURN jsonb_build_object('acquired', false, 'reason', 'busy');
    END IF;
    SELECT * INTO r FROM public.icp_mining WHERE id = d.icp_mining_id FOR UPDATE;
    UPDATE public.icp_dispatch_runs SET state = 'running', baseline_processed = COALESCE(r.processed_targets, 0),
      baseline_found = COALESCE(r.found_matches, 0), updated_at = clock_timestamp()
      WHERE id = d.id RETURNING * INTO d;
  ELSE
    SELECT * INTO r FROM public.icp_mining WHERE id = d.icp_mining_id FOR UPDATE;
    IF r.execution_run_id IS DISTINCT FROM p_run_id OR r.execution_workflow_id IS DISTINCT FROM p_workflow_id THEN
      RAISE EXCEPTION 'Dispatch execution ownership lost';
    END IF;
  END IF;
  -- Explicit allowlist: never return errors, last_error, criteria or future audit
  -- columns. Same-run retries retain the ORIGINAL baselines and current cursor.
  RETURN jsonb_build_object('acquired', true, 'reservation', to_jsonb(d), 'icp', jsonb_build_object(
    'id', r.id, 'site_id', r.site_id, 'role_query_id', r.role_query_id, 'name', r.name, 'status', r.status,
    'total_targets', r.total_targets, 'processed_targets', r.processed_targets, 'found_matches', r.found_matches,
    'current_page', r.current_page, 'current_page_offset', r.current_page_offset, 'created_at', r.created_at,
    'checkpoint_version', r.checkpoint_version, 'current_page_snapshot', r.current_page_snapshot));
END $$;


--
-- Name: begin_marketplace_oauth(jsonb, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_marketplace_oauth(p_context jsonb, p_state_hash text, p_encrypted_context text, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.marketplace_oauth_sessions;
BEGIN
  PERFORM public.marketplace_assert_actor((p_context->>'site_id')::uuid,p_actor_user_id,true);
  IF jsonb_typeof(p_context) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Invalid OAuth context'; END IF;
  INSERT INTO public.marketplace_oauth_sessions(id,state_hash,site_id,user_id,provider,environment,country,
    credential_mode,encrypted_context,expires_at)
  VALUES(coalesce((p_context->>'id')::uuid,gen_random_uuid()),p_state_hash,(p_context->>'site_id')::uuid,
    p_actor_user_id,p_context->>'provider',p_context->>'environment',p_context->>'country',
    coalesce(p_context->>'credential_mode','platform'),p_encrypted_context,
    coalesce((p_context->>'expires_at')::timestamptz,now()+interval '10 minutes')) RETURNING * INTO session;
  RETURN to_jsonb(session);
END;
$$;


--
-- Name: begin_migration_diagnostic_review(uuid, text, integer, integer, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.begin_migration_diagnostic_review(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_value jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_previous public.requirement_migration_lifecycle%ROWTYPE;
  v_result public.requirement_migration_lifecycle%ROWTYPE;
  v_diagnostic public.requirement_migration_diagnostics%ROWTYPE;
  v_original_sql text;
BEGIN
  -- Explicit bounded counterpart of the original lifecycle validation, not a
  -- relaxation of its +1 reviewing rule. Only assigned followup can retain 5.
  IF p_expected_version IS NULL OR p_expected_version < 1 OR p_expected_version >= 2147483647
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
  IF p_value->>'state' <> 'reviewing' OR p_value->>'attempts' <> '5'
    OR (p_value->>'checksum') !~ '^[a-f0-9]{64}$'
    OR (p_value->>'specification_checksum') !~ '^[a-f0-9]{64}$'
    OR octet_length(p_value->>'original_sql') > 65536 OR char_length(p_value->>'reason') > 2048
  THEN
    RAISE EXCEPTION 'Invalid migration lifecycle value' USING ERRCODE = '22023';
  END IF;
  v_previous := public.lock_requirement_migration_diagnostic_scope(
    p_requirement_id, p_file, p_execution_generation, NULL, false);
  IF v_previous.version <> p_expected_version THEN
    RAISE EXCEPTION 'Migration lifecycle version conflict' USING ERRCODE = '40001';
  END IF;
  SELECT * INTO v_diagnostic FROM public.requirement_migration_diagnostics
    WHERE requirement_id = p_requirement_id AND file = p_file FOR UPDATE;
  IF NOT FOUND OR v_diagnostic.state <> 'followup_assigned'
    OR v_diagnostic.execution_generation IS DISTINCT FROM p_execution_generation
    OR v_diagnostic.specification_checksum IS DISTINCT FROM v_previous.specification_checksum
  THEN
    RAISE EXCEPTION 'Migration diagnostic followup is not assigned in this scope' USING ERRCODE = '40001';
  END IF;
  IF p_value->>'specification_checksum' IS DISTINCT FROM v_previous.specification_checksum THEN
    RAISE EXCEPTION 'Migration specification checksum is immutable' USING ERRCODE = '23514';
  END IF;
  IF p_value->>'checksum' = v_diagnostic.checksum THEN
    RAISE EXCEPTION 'Migration diagnostic followup must materialize changed SQL' USING ERRCODE = '23514';
  END IF;
  v_original_sql := v_previous.original_sql;
  IF p_value ? 'original_sql' THEN
    IF p_value->>'original_sql' IS DISTINCT FROM v_previous.original_sql THEN
      RAISE EXCEPTION 'Original migration SQL is immutable' USING ERRCODE = '23514';
    END IF;
  END IF;
  UPDATE public.requirement_migration_lifecycle SET
    version = v_previous.version + 1, state = 'reviewing', checksum = p_value->>'checksum',
    original_sql = v_original_sql, reason = p_value->>'reason', review = NULL,
    attempts = 5, updated_at = clock_timestamp()
    WHERE requirement_id = p_requirement_id AND file = p_file RETURNING * INTO v_result;
  UPDATE public.requirement_migration_diagnostics SET state = 'followup_reviewing', updated_at = clock_timestamp()
    WHERE requirement_id = p_requirement_id AND file = p_file;
  RETURN to_jsonb(v_result);
END;
$_$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: resume_reconciled_requirement_migration(uuid, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resume_reconciled_requirement_migration(p_requirement_id uuid, p_receipt_id uuid, p_evidence jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    SET "TimeZone" TO 'UTC'
    AS $_$
DECLARE
  saved public.requirement_migration_reconciliations%ROWTYPE;
  resumed public.requirement_migration_reconciliation_resumes%ROWTYPE;
  r public.requirements%ROWTYPE;
  life public.requirement_migration_lifecycle%ROWTYPE;
  v_observed timestamptz;
  v_now timestamptz;
BEGIN
  IF p_requirement_id IS NULL OR p_receipt_id IS NULL THEN
    RAISE EXCEPTION 'Invalid reconciliation resume input' USING ERRCODE = '22023';
  END IF;
  PERFORM 1 FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  SELECT * INTO saved FROM public.requirement_migration_reconciliations
    WHERE id = p_receipt_id AND requirement_id = p_requirement_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reconciliation receipt missing' USING ERRCODE = 'P0002'; END IF;
  SELECT * INTO resumed FROM public.requirement_migration_reconciliation_resumes WHERE receipt_id = saved.id;
  IF FOUND THEN
    RETURN jsonb_build_object('receipt_id',saved.id,'resumed',true,'execution_generation',resumed.execution_generation);
  END IF;
  r := public.lock_migration_reconciliation_scope(saved.requirement_id,saved.file,saved.instance_id,
    saved.plan_id,saved.step_id,saved.execution_generation,saved.backlog_revision);
  SELECT * INTO life FROM public.requirement_migration_lifecycle WHERE requirement_id = r.id AND file = saved.file;
  IF NOT FOUND OR to_jsonb(life) IS DISTINCT FROM saved.lifecycle
    OR life.state <> 'correction_required' OR life.attempts <> 5 OR life.review IS NOT NULL
    OR r.site_id IS DISTINCT FROM saved.site_id OR r.instructions IS DISTINCT FROM saved.specification
    OR encode(sha256(convert_to(r.instructions, 'UTF8')), 'hex') IS DISTINCT FROM saved.specification_checksum THEN
    RAISE EXCEPTION 'Reconciliation scope changed before resume' USING ERRCODE = '40001';
  END IF;
  -- All identity/hash/absence fields must exactly match the validated original
  -- attestation. Only the fresh observation timestamp may differ. DB still
  -- trusts service_role for remote facts; no Apps call is made from this RPC.
  IF jsonb_typeof(p_evidence) IS DISTINCT FROM 'object'
    OR octet_length(p_evidence::text) > 4096
    OR (p_evidence - 'observed_at') IS DISTINCT FROM (saved.evidence - 'observed_at')
    OR jsonb_typeof(p_evidence->'observed_at') IS DISTINCT FROM 'string'
    OR p_evidence->>'observed_at' !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$' THEN
    RAISE EXCEPTION 'Resume evidence scope mismatch' USING ERRCODE = '22023';
  END IF;
  BEGIN
    v_observed := (p_evidence->>'observed_at')::timestamptz;
  EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN
    RAISE EXCEPTION 'Invalid resume observation time' USING ERRCODE = '22023';
  END;
  v_now := clock_timestamp();
  IF NOT isfinite(v_observed) OR v_observed < v_now - interval '5 minutes' OR v_observed > v_now + interval '30 seconds' THEN
    RAISE EXCEPTION 'Stale resume evidence' USING ERRCODE = '40001';
  END IF;
  IF r.metadata ? 'execution_hold' OR NULLIF(r.metadata->>'cron_blocker_provenance', '') IS NOT NULL
    OR EXISTS (SELECT 1 FROM public.requirement_migration_lifecycle
      WHERE requirement_id = r.id AND file <> saved.file AND state <> 'validated')
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(r.backlog->'items') AS item
      -- Ordinary downstream dependency waits are not a requirement-wide hold.
      -- Keep those unchanged; direct/user/platform blockers and quarantine deny.
      WHERE jsonb_typeof(COALESCE(item->'blocked_by','[]'::jsonb)) <> 'array'
        OR EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(item->'blocked_by') = 'array'
          THEN item->'blocked_by' ELSE '[]'::jsonb END) AS blocker
          WHERE blocker->>'category' IS DISTINCT FROM 'dependency'
            OR COALESCE(blocker->>'resolution_actor','') NOT IN ('executor','verifier')
            OR COALESCE(blocker->'user_action_required','false'::jsonb) <> 'false'::jsonb)
        OR COALESCE(item#>'{review_quarantine,active}','false'::jsonb) <> 'false'::jsonb
        OR COALESCE(item->'plan_cancellation_pending','null'::jsonb) <> 'null'::jsonb
        OR item->>'status' IN ('blocked','needs_review')) THEN
    RAISE EXCEPTION 'Requirement has another unresolved hold' USING ERRCODE = '23514';
  END IF;
  -- Insert before status UPDATE for the durable pending-reconciliation guard;
  -- any update/visibility/audit failure rolls this receipt back as well.
  INSERT INTO public.requirement_migration_reconciliation_resumes(receipt_id,requirement_id,execution_generation,evidence)
    VALUES (saved.id,r.id,saved.execution_generation + 1,p_evidence) RETURNING * INTO resumed;
  UPDATE public.requirements SET status = 'in-progress',
    metadata = jsonb_set(metadata, '{requirement_execution_generation}', to_jsonb(saved.execution_generation + 1)),
    updated_at = GREATEST(clock_timestamp(), updated_at + interval '1 microsecond') WHERE id = r.id;
  INSERT INTO public.instance_logs(instance_id,site_id,log_type,level,message,details)
    VALUES (saved.instance_id,r.site_id,'system','info','Reconciled migration execution resumed without resetting budgets.',
      jsonb_build_object('event','migration_operator_reconciliation_resume','receipt_id',saved.id,
        'requirement_id',r.id,'execution_generation',resumed.execution_generation,
        'receipt_found',false,'observed_at',v_observed));
  INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,message)
    VALUES (r.id,r.site_id,saved.instance_id,'in-progress',
      'Execution resumed after audited migration reconciliation. Fresh independent diagnosis, security review and validation remain required.');
  RETURN jsonb_build_object('receipt_id',saved.id,'resumed',true,'execution_generation',resumed.execution_generation);
END;
$_$;


--
-- Name: retire_requirement_migration_hold(uuid, text, integer, integer, uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.retire_requirement_migration_hold(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  r public.requirements%ROWTYPE;
  i public.remote_instances%ROWTYPE;
  l public.requirement_migration_lifecycle%ROWTYPE;
  saved public.requirement_migration_retirements%ROWTYPE;
  diagnostic jsonb;
  generation text;
  observed timestamptz;
BEGIN
  IF p_requirement_id IS NULL OR p_instance_id IS NULL OR p_request_id IS NULL
    OR p_file IS NULL OR octet_length(p_file) > 512
    OR p_file !~ '^(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*\.sql$'
    OR p_expected_version IS NULL OR p_expected_version NOT BETWEEN 1 AND 2147483646
    OR p_expected_execution_generation IS NULL OR p_expected_execution_generation NOT BETWEEN 0 AND 2147483646
    OR p_operator_id IS NULL OR char_length(btrim(p_operator_id)) NOT BETWEEN 1 AND 200
    OR p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 1 AND 2000 THEN
    RAISE EXCEPTION 'Invalid migration retirement input' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO r FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Retirement requirement missing' USING ERRCODE = 'P0002'; END IF;
  SELECT * INTO saved FROM public.requirement_migration_retirements WHERE id = p_request_id;
  IF FOUND THEN
    IF saved.requirement_id IS DISTINCT FROM p_requirement_id OR saved.file IS DISTINCT FROM p_file
      OR saved.instance_id IS DISTINCT FROM p_instance_id OR saved.operator_id IS DISTINCT FROM p_operator_id
      OR saved.reason IS DISTINCT FROM p_reason OR saved.transferred_version <> p_expected_version + 1
      OR saved.execution_generation <> p_expected_execution_generation THEN
      RAISE EXCEPTION 'Retirement request identity conflict' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('receipt_id',saved.id,'state','transferred','resumed',false,'already_recorded',true);
  END IF;
  IF r.cron_lock_active IS DISTINCT FROM false OR r.cron_lock_expires_at > clock_timestamp()
    OR COALESCE(r.status, '') NOT IN ('blocked','paused') THEN
    RAISE EXCEPTION 'Retirement requires an idle blocked or paused requirement' USING ERRCODE = '40001';
  END IF;
  generation := CASE WHEN r.metadata ? 'requirement_execution_generation'
    THEN r.metadata->>'requirement_execution_generation' ELSE '0' END;
  IF jsonb_typeof(r.metadata) IS DISTINCT FROM 'object' OR generation IS NULL
    OR generation !~ '^(0|[1-9][0-9]{0,9})$' THEN
    RAISE EXCEPTION 'Invalid retirement execution generation' USING ERRCODE = '22023';
  END IF;
  IF generation::bigint <> p_expected_execution_generation
    OR r.metadata->>'runner_instance_id' IS DISTINCT FROM p_instance_id::text THEN
    RAISE EXCEPTION 'Stale retirement generation or owner' USING ERRCODE = '40001';
  END IF;
  SELECT * INTO i FROM public.remote_instances WHERE id = p_instance_id FOR UPDATE;
  IF NOT FOUND OR i.site_id IS DISTINCT FROM r.site_id OR i.user_id IS DISTINCT FROM r.user_id THEN
    RAISE EXCEPTION 'Retirement owner scope mismatch' USING ERRCODE = '40001';
  END IF;
  -- Archived/error owners may have their obsolete authority retired, but this
  -- operation never unarchives, resumes, replaces or assigns an owner.
  SELECT * INTO l FROM public.requirement_migration_lifecycle
    WHERE requirement_id = r.id AND file = p_file FOR UPDATE;
  IF NOT FOUND OR l.version <> p_expected_version THEN
    RAISE EXCEPTION 'Stale retirement lifecycle version' USING ERRCODE = '40001';
  END IF;
  IF l.state NOT IN ('platform_review','correction_required') THEN
    RAISE EXCEPTION 'Active review, validation or transferred history cannot be retired' USING ERRCODE = '23514';
  END IF;
  IF r.metadata ? 'execution_hold' AND (
    r.metadata#>>'{execution_hold,kind}' IS DISTINCT FROM 'migration_platform_review'
    OR r.metadata#>>'{execution_hold,file}' IS DISTINCT FROM p_file
  ) THEN
    RAISE EXCEPTION 'Unrelated execution hold prevents retirement' USING ERRCODE = '23514';
  END IF;
  PERFORM 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = r.id ORDER BY file FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = r.id
    AND state IN ('running','followup_reviewing')) OR EXISTS (
    SELECT 1 FROM public.requirement_migration_reconciliations c WHERE c.requirement_id = r.id
      AND NOT EXISTS (SELECT 1 FROM public.requirement_migration_reconciliation_resumes s WHERE s.receipt_id = c.id)
  ) THEN
    RAISE EXCEPTION 'Active diagnosis or unfinished reconciliation prevents retirement' USING ERRCODE = '23514';
  END IF;
  SELECT to_jsonb(d) INTO diagnostic FROM public.requirement_migration_diagnostics d
    WHERE d.requirement_id = r.id AND d.file = p_file;
  observed := clock_timestamp();
  INSERT INTO public.requirement_migration_retirements
    (id,requirement_id,file,site_id,instance_id,operator_id,reason,execution_generation,
      transferred_version,prior_lifecycle,prior_diagnostic,prior_requirement_metadata,created_at)
    VALUES (p_request_id,r.id,p_file,r.site_id,i.id,p_operator_id,p_reason,p_expected_execution_generation,
      l.version + 1,to_jsonb(l),diagnostic,r.metadata,observed);
  UPDATE public.requirement_migration_lifecycle SET state = 'transferred', version = l.version + 1,
    updated_at = observed WHERE requirement_id = r.id AND file = p_file;
  UPDATE public.requirements SET metadata = metadata - 'execution_hold' WHERE id = r.id
    AND metadata#>>'{execution_hold,kind}' = 'migration_platform_review'
    AND metadata#>>'{execution_hold,file}' = p_file;
  INSERT INTO public.instance_logs(instance_id,site_id,log_type,level,message,details)
    VALUES (i.id,r.site_id,'system','info',
      'Legacy migration hold retired by operator. No SQL was applied or validated; execution has not resumed.',
      jsonb_build_object('event','migration_legacy_retirement','receipt_id',p_request_id,
        'requirement_id',r.id,'file',p_file,'state','transferred','resumed',false));
  RETURN jsonb_build_object('receipt_id',p_request_id,'state','transferred','resumed',false,'already_recorded',false);
END;
$_$;


--
-- Name: retire_sandbox_billing(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.retire_sandbox_billing(p_sandbox_name text, p_phase text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE r public.sandbox_billing_resources%ROWTYPE;
BEGIN
  IF p_phase NOT IN ('begin','finish') OR p_phase IS NULL THEN RAISE EXCEPTION 'Invalid sandbox retirement phase'; END IF;
  SELECT * INTO r FROM public.sandbox_billing_resources WHERE sandbox_name=p_sandbox_name FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',true,'outcome','untracked'); END IF;
  IF r.retired_at IS NOT NULL THEN RETURN jsonb_build_object('success',true,'outcome','retired'); END IF;
  IF p_phase='begin' THEN
    IF r.last_reconciled_at IS NULL OR r.last_reconciled_at < clock_timestamp()-interval '1 minute'
      OR EXISTS (SELECT 1 FROM public.sandbox_billing_sessions
      WHERE sandbox_name=p_sandbox_name AND (ended_at IS NULL OR billed_through < ended_at)) THEN
      RAISE EXCEPTION 'Sandbox usage settlement is pending';
    END IF;
    UPDATE public.sandbox_billing_resources SET deletion_requested_at=coalesce(deletion_requested_at,clock_timestamp())
      WHERE sandbox_name=p_sandbox_name;
    RETURN jsonb_build_object('success',true,'outcome','delete_pending');
  END IF;
  IF r.deletion_requested_at IS NULL THEN RETURN jsonb_build_object('success',false,'outcome','unproven_disappearance'); END IF;
  UPDATE public.sandbox_billing_resources SET retired_at=clock_timestamp() WHERE sandbox_name=p_sandbox_name;
  RETURN jsonb_build_object('success',true,'outcome','retired');
END;
$$;


--
-- Name: revoke_marketplace_merchant_connection(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.revoke_marketplace_merchant_connection(p_connection_id uuid, p_actor_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE connection public.marketplace_merchant_connections;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Merchant backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO connection FROM public.marketplace_merchant_connections WHERE id=p_connection_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Merchant connection unavailable'; END IF;
  PERFORM public.marketplace_assert_actor(connection.site_id,p_actor_user_id,true);
  -- No remote mutation occurs here. The authorized backend calls this only after
  -- actual provider revocation/deactivation confirmation, never on unknown results.
  UPDATE public.marketplace_integrations SET enabled=false,provisioning_status='revoked',
    provisioning_result='confirmed',updated_at=now()
    WHERE merchant_connection_id=connection.id;
  UPDATE public.marketplace_merchant_connections SET status='revoked',encrypted_authorization=NULL,
    token_expires_at=NULL,updated_at=now() WHERE id=connection.id;
END;
$$;


--
-- Name: revoke_visitor_identity_issuer_grants(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.revoke_visitor_identity_issuer_grants() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_invalidated boolean;
begin
  if tg_op = 'INSERT' then
    -- A caller cannot select or resurrect a credential's version.
    new.identity_token_version := gen_random_uuid();
    return new;
  end if;

  if tg_op = 'DELETE' then
    v_invalidated := true;
  else
    v_invalidated := new.status is distinct from old.status
      or new.site_id is distinct from old.site_id
      or new.user_id is distinct from old.user_id
      or new.lookup_hash is distinct from old.lookup_hash
      or new.key_hash is distinct from old.key_hash
      or new.scopes is distinct from old.scopes
      or new.expires_at is distinct from old.expires_at;
    -- Even restoring an earlier field value produces a fresh random version.
    -- Ordinary metadata/last_used_at updates do not revoke or rotate identity.
    new.identity_token_version := case when v_invalidated
      then gen_random_uuid() else old.identity_token_version end;
  end if;

  if v_invalidated then
    update public.visitor_session_identity_grants g
      set revoked_at = clock_timestamp(), trusted_token_hash = null, updated_at = clock_timestamp()
      where g.revoked_at is null and exists (
        select 1 from public.visitor_identity_token_redemptions r
          where r.issuer_key_id = old.id and r.session_id = g.session_id
            and r.token_hash = g.trusted_token_hash
      );
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;


--
-- Name: revoke_visitor_session_identity(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.revoke_visitor_session_identity(p_site_id uuid, p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare v_now timestamptz;
begin
  perform public.assert_visitor_identity_service_role();
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text, 0));
  perform 1 from public.visitor_sessions where id = p_session_id and site_id = p_site_id for update;
  if not found then return jsonb_build_object('status', 'invalid_session'); end if;
  v_now := clock_timestamp();
  insert into public.visitor_identity_session_state(session_id, epoch) values(p_session_id, 1)
    on conflict(session_id) do update set epoch = public.visitor_identity_session_state.epoch + 1;
  update public.visitor_session_identity_grants
    set revoked_at = v_now, trusted_token_hash = null, updated_at = v_now
    where site_id = p_site_id and session_id = p_session_id and revoked_at is null;
  update public.visitor_identity_challenges set cancelled_at = v_now, updated_at = v_now
    where site_id = p_site_id and session_id = p_session_id and consumed_at is null and cancelled_at is null;
  update public.visitor_sessions set lead_id = null, identified_at = null, updated_at = v_now
    where site_id = p_site_id and id = p_session_id;
  return jsonb_build_object('status', 'revoked');
end;
$$;


--
-- Name: robot_instance_requirement_candidates(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.robot_instance_requirement_candidates(p_instance_id uuid) RETURNS uuid[]
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE ids uuid[]; binding text;
BEGIN
  FOR binding IN
    SELECT metadata->>'requirement_id' FROM public.remote_instances WHERE id = p_instance_id
    UNION SELECT metadata->>'requirement_id' FROM public.instance_plans WHERE instance_id = p_instance_id
    UNION SELECT value FROM public.instance_logs l CROSS JOIN LATERAL unnest(ARRAY[
      l.details->>'requirement_id', l.details->>'requirementId',
      l.tool_args->>'requirement_id', l.tool_args->>'requirementId'
    ]) tags(value) WHERE l.instance_id = p_instance_id
  LOOP
    IF binding IS NOT NULL AND binding !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
      RAISE EXCEPTION 'Ambiguous requirement association' USING ERRCODE = 'PT409';
    END IF;
  END LOOP;
  SELECT COALESCE(array_agg(DISTINCT id ORDER BY id), '{}'::uuid[]) INTO ids FROM (
    SELECT id FROM public.requirements WHERE lower(metadata->>'runner_instance_id') = p_instance_id::text
      OR lower(metadata->>'assistant_origin_instance_id') = p_instance_id::text
    UNION SELECT (metadata->>'requirement_id')::uuid FROM public.remote_instances WHERE id = p_instance_id
    UNION SELECT (metadata->>'requirement_id')::uuid FROM public.instance_plans WHERE instance_id = p_instance_id
    UNION SELECT requirement_id FROM public.requirement_status WHERE instance_id = p_instance_id
    UNION SELECT requirement_id FROM public.requirement_harness_decisions WHERE instance_id = p_instance_id
    UNION SELECT requirement_id FROM public.requirement_migration_reconciliations WHERE instance_id = p_instance_id
    UNION SELECT requirement_id FROM public.requirement_migration_execution_handoffs WHERE instance_id = p_instance_id
    UNION SELECT requirement_id FROM public.catalog_item_requirements WHERE instance_id = p_instance_id
    UNION SELECT requirement_id FROM public.requirement_cron_cycle_outcomes WHERE runner_instance_id = p_instance_id
    UNION SELECT value::uuid FROM public.instance_logs l CROSS JOIN LATERAL unnest(ARRAY[
      l.details->>'requirement_id', l.details->>'requirementId',
      l.tool_args->>'requirement_id', l.tool_args->>'requirementId'
    ]) tags(value) WHERE l.instance_id = p_instance_id
    UNION SELECT r.requirement_id FROM public.requirement_user_action_receipts r
      JOIN public.instance_logs l ON l.id = r.action_id WHERE l.instance_id = p_instance_id
  ) candidates WHERE id IS NOT NULL;
  IF cardinality(ids) > 1000 THEN
    RAISE EXCEPTION 'Requirement deletion scope exceeds the safety limit' USING ERRCODE = 'PT409';
  END IF;
  RETURN ids;
END;
$_$;


--
-- Name: rollback_api_keys(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rollback_api_keys() RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    -- Implementation depends on the original function logic
    -- This is a placeholder that should be updated with the actual logic
    RAISE NOTICE 'rollback_api_keys function secured with search_path';
END;
$$;


--
-- Name: save_credit_auto_top_up_with_billing_card(uuid, uuid, text, text, uuid, numeric, numeric, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_credit_auto_top_up_with_billing_card(p_site_id uuid, p_actor_id uuid, p_stripe_customer_id text, p_stripe_payment_method_id text, p_expected_setup_token uuid, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; s public.credit_auto_top_up_card_setups%ROWTYPE;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_actor_id IS NULL OR p_stripe_payment_method_id IS NULL OR p_stripe_payment_method_id !~ '^pm_[A-Za-z0-9]+$' THEN
    RAISE EXCEPTION 'Verified actor and billing card required';
  END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR b.stripe_customer_id IS DISTINCT FROM p_stripe_customer_id THEN RAISE EXCEPTION 'Billing customer changed'; END IF;
  SELECT * INTO s FROM public.credit_auto_top_up_card_setups WHERE site_id=p_site_id FOR UPDATE;
  IF s.token IS DISTINCT FROM p_expected_setup_token OR s.status='pending' THEN RAISE EXCEPTION 'Card setup changed'; END IF;
  IF s.status='completed' AND s.source='top_up' THEN RAISE EXCEPTION 'Explicit top-up card must be retained'; END IF;
  IF EXISTS(SELECT 1 FROM public.credit_auto_top_up_attempts WHERE site_id=p_site_id AND status='pending') THEN
    RAISE EXCEPTION 'Pending top-up requires reconciliation';
  END IF;
  INSERT INTO public.credit_auto_top_up_card_setups(site_id,token,actor_id,stripe_customer_id,status,stripe_payment_method_id,completed_at,source)
    VALUES(p_site_id,gen_random_uuid(),p_actor_id,p_stripe_customer_id,'completed',p_stripe_payment_method_id,now(),'billing')
  ON CONFLICT(site_id) DO UPDATE SET token=excluded.token,actor_id=excluded.actor_id,stripe_customer_id=excluded.stripe_customer_id,
    status='completed',stripe_payment_method_id=excluded.stripe_payment_method_id,completed_at=now(),source='billing';
  -- Disable only inside this transaction before rebinding; an enabled setting
  -- still points at its former card until the private attach finishes.
  UPDATE public.credit_auto_top_up_settings SET enabled=false WHERE site_id=p_site_id;
  PERFORM public.attach_credit_auto_top_up_payment_method_internal(p_site_id,p_stripe_payment_method_id,p_stripe_customer_id);
  RETURN public.set_credit_auto_top_up_settings(p_site_id,true,p_minimum_credits,p_target_credits,p_max_monthly_spend_cents,p_actor_id);
END;
$_$;


--
-- Name: save_harness_host_state(uuid, uuid, text, bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_harness_host_state(p_id uuid, p_site_id uuid, p_owner text, p_expected_version bigint, p_ciphertext text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE previous bigint;
BEGIN
  PERFORM public.lock_harness_host_owner(p_id,p_site_id,p_owner);
  IF p_expected_version IS NULL OR p_expected_version NOT BETWEEN 0 AND 9007199254740989
    OR p_ciphertext IS NULL OR octet_length(p_ciphertext) > 262144
    OR p_ciphertext !~ '^v1\.[A-Za-z0-9+/]{16}\.[A-Za-z0-9+/]{22}==\.[A-Za-z0-9+/]+={0,2}$'
  THEN RAISE EXCEPTION 'Invalid harness encrypted state' USING ERRCODE='22023'; END IF;
  SELECT version INTO previous FROM public.harness_host_state WHERE session_id=p_id AND site_id=p_site_id;
  IF coalesce(previous,0) <> p_expected_version
  THEN RAISE EXCEPTION 'Harness host version conflict' USING ERRCODE='P0002'; END IF;
  INSERT INTO public.harness_host_state(session_id,site_id,version,ciphertext)
    VALUES(p_id,p_site_id,p_expected_version+1,p_ciphertext)
    ON CONFLICT (session_id) DO UPDATE SET version=EXCLUDED.version,ciphertext=EXCLUDED.ciphertext;
  RETURN p_expected_version+1;
END;
$_$;


--
-- Name: save_harness_session(uuid, uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_snapshot jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_sessions%ROWTYPE; result jsonb; t timestamptz;
BEGIN
  IF NOT public.valid_harness_snapshot(p_snapshot) OR p_snapshot->>'id' IS DISTINCT FROM p_id::text OR p_snapshot->>'status' = 'queued'
  THEN RAISE EXCEPTION 'Invalid harness snapshot' USING ERRCODE='22023'; END IF;
  SELECT * INTO r FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  t := clock_timestamp();
  IF r.lease_owner IS DISTINCT FROM p_owner OR p_owner IS NULL OR r.lease_expires_at IS NULL OR r.lease_expires_at <= t
    OR r.snapshot->>'status' <> 'running' OR r.version <> (p_snapshot->>'version')::bigint THEN RETURN NULL; END IF;
  UPDATE public.harness_sessions SET version=version+1,
    snapshot=p_snapshot || jsonb_build_object('version',version+1,'updatedAt',t)
    WHERE id=p_id AND site_id=p_site_id RETURNING snapshot INTO result;
  RETURN result;
END;
$$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: claim_agent_requirement_run_before_commands(uuid[], integer, integer, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_agent_requirement_run_before_commands(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[] DEFAULT '{}'::uuid[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE r public.requirements%ROWTYPE; m public.harness_requirement_runs%ROWTYPE;
  s public.harness_sessions%ROWTYPE; instance_id uuid; generation integer; run_id text;
  active integer; due boolean; has_mapping boolean; has_session boolean; recover_wait boolean; t timestamptz;
BEGIN
  IF p_max_concurrent IS NULL OR p_max_concurrent NOT BETWEEN 1 AND 100
    OR p_ttl_seconds IS NULL OR p_ttl_seconds NOT BETWEEN 60 AND 86400
    OR cardinality(p_excluded_ids)>10000 OR cardinality(p_scheduled_ids)>10000
  THEN RAISE EXCEPTION 'Invalid agent cron claim' USING ERRCODE='22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('requirement-cron-global-capacity',0));
  t:=clock_timestamp();
  SELECT count(*) INTO active FROM public.requirements WHERE cron_lock_active IS TRUE AND cron_lock_expires_at>t;
  IF active>=p_max_concurrent THEN RETURN jsonb_build_object('state','capacity_full'); END IF;
  FOR r IN SELECT q.* FROM public.requirements q
    WHERE q.created_at>='2026-09-01 00:00:00+00'::timestamptz
      AND q.updated_at>='2026-09-01 00:00:00+00'::timestamptz
      AND q.site_id IS NOT NULL AND q.user_id IS NOT NULL
      AND (q.metadata IS NULL OR jsonb_typeof(q.metadata)='object')
      AND NOT (q.id=ANY(coalesce(p_excluded_ids,'{}'::uuid[])))
      AND (q.cron_lock_expires_at IS NULL OR q.cron_lock_expires_at<=t)
      AND NOT coalesce(q.metadata ? 'execution_hold',false)
      AND (q.status IN ('backlog','in-progress') OR
        (q.status='blocked' AND q.metadata->>'cron_blocker_provenance' IN
          ('product_no_progress_circuit','cron_infrastructure','product_attempt_budget','product_replan_circuit')) OR
        (q.status='blocked' AND EXISTS (SELECT 1 FROM public.harness_requirement_runs h WHERE h.requirement_id=q.id
          AND q.metadata->>'requirement_execution_generation' ~ '^[0-9]{1,9}$'
          AND (q.metadata->>'requirement_execution_generation')::integer>h.generation)) OR
        -- Only provably recoverable historical waits may consume the bounded
        -- candidate window. Repeat the evidence check under locks below: this
        -- prefilter is not authorization and cannot replace revalidation.
        (q.status='blocked' AND EXISTS (
          SELECT 1 FROM public.harness_requirement_runs h
          JOIN public.harness_sessions hs ON hs.id=h.session_id
          CROSS JOIN LATERAL (SELECT st.*,st.xmin AS status_xmin FROM public.requirement_status st
            WHERE st.requirement_id=q.id ORDER BY st.updated_at DESC NULLS LAST,st.id DESC LIMIT 1) last_status
          WHERE h.requirement_id=q.id AND h.site_id=q.site_id
            AND h.generation=CASE
              WHEN NOT coalesce(q.metadata ? 'requirement_execution_generation',false) THEN 0
              WHEN q.metadata->>'requirement_execution_generation' ~ '^[0-9]{1,9}$'
                THEN (q.metadata->>'requirement_execution_generation')::integer
              ELSE NULL END
            AND hs.site_id=q.site_id AND hs.user_id=q.user_id
            AND (hs.lease_expires_at IS NULL OR hs.lease_expires_at<=t)
            AND (hs.snapshot#>>'{request,requirementId}' IS NULL OR hs.snapshot#>>'{request,requirementId}'=q.id::text)
            AND hs.snapshot->>'status'='waiting' AND h.next_run_at IS NULL
            AND h.pause_reason=coalesce(hs.snapshot->>'reason','waiting')
            AND q.xmin=h.xmin AND q.xmin=last_status.status_xmin
            AND last_status.site_id=q.site_id
            AND last_status.instance_id::text=q.metadata->>'runner_instance_id'
            AND last_status.stage='blocked' AND last_status.cycle='agent:'||h.last_cycle_id
            -- Read-only admission checks here; the authoritative helper takes
            -- owner locks later, after the requirement/mapping/session locks.
            AND coalesce(q.metadata->>'customer_paused','false')<>'true'
            AND coalesce(q.metadata->>'user_paused','false')<>'true'
            AND coalesce(q.metadata->>'cron_paused','false')<>'true'
            AND EXISTS (SELECT 1 FROM public.remote_instances i WHERE i.id=last_status.instance_id
              AND i.site_id=q.site_id AND i.is_archived IS NOT TRUE
              AND i.status NOT IN ('paused','stopped','stopping','cancelled'))
            AND NOT EXISTS (SELECT 1 FROM public.instance_plans p WHERE p.site_id=q.site_id AND p.status='paused'
              AND (p.instance_id=last_status.instance_id OR p.metadata->>'requirement_id'=q.id::text))
            AND coalesce((SELECT coalesce(a.details->>'status','') IN ('completed','failed')
              FROM public.instance_logs a WHERE a.instance_id=last_status.instance_id AND a.site_id=q.site_id
                AND a.log_type='user_action' AND a.trusted_user_action IS TRUE
              ORDER BY a.created_at DESC,a.id DESC LIMIT 1),true)
            AND (q.metadata->>'assistant_origin_instance_id' IS NULL OR (
              EXISTS (SELECT 1 FROM public.remote_instances i WHERE i.id::text=q.metadata->>'assistant_origin_instance_id'
                AND i.site_id=q.site_id)
              AND coalesce((SELECT coalesce(a.details->>'status','') IN ('completed','failed')
                FROM public.instance_logs a WHERE a.instance_id::text=q.metadata->>'assistant_origin_instance_id'
                  AND a.site_id=q.site_id AND a.log_type='user_action' AND a.trusted_user_action IS TRUE
                ORDER BY a.created_at DESC,a.id DESC LIMIT 1),false)))
            AND NOT EXISTS (SELECT 1 FROM public.requirements other WHERE other.id<>q.id AND other.cron_lock_expires_at>t
              AND (other.metadata->>'runner_instance_id'=last_status.instance_id::text
                OR other.metadata->>'assistant_origin_instance_id'=last_status.instance_id::text)))) OR
        (q.status IN ('done','on-review') AND q.cron IS NOT NULL AND q.id=ANY(coalesce(p_scheduled_ids,'{}'::uuid[]))))
    ORDER BY q.updated_at,q.id LIMIT 1000 FOR UPDATE OF q SKIP LOCKED
  LOOP
    generation:=0;
    IF r.metadata ? 'requirement_execution_generation' THEN
      IF coalesce(r.metadata->>'requirement_execution_generation','') !~ '^[0-9]{1,9}$' THEN CONTINUE; END IF;
      generation:=(r.metadata->>'requirement_execution_generation')::integer;
    END IF;
    SELECT * INTO m FROM public.harness_requirement_runs WHERE requirement_id=r.id FOR UPDATE;
    has_mapping:=FOUND;
    IF has_mapping AND (m.site_id<>r.site_id OR generation<m.generation) THEN CONTINUE; END IF;
    due:=r.status IN ('done','on-review') AND r.cron IS NOT NULL AND r.id=ANY(coalesce(p_scheduled_ids,'{}'::uuid[]));
    SELECT * INTO s FROM public.harness_sessions WHERE id=m.session_id FOR UPDATE;
    has_session:=FOUND;
    IF has_session AND (s.site_id<>r.site_id OR s.user_id<>r.user_id OR s.lease_expires_at>clock_timestamp()
      OR (s.snapshot#>>'{request,requirementId}' IS NOT NULL AND s.snapshot#>>'{request,requirementId}'<>r.id::text)) THEN CONTINUE; END IF;
    recover_wait:=false;
    IF r.status='blocked' AND has_mapping AND has_session AND generation=m.generation
      AND s.snapshot->>'status'='waiting' AND m.next_run_at IS NULL
      AND m.pause_reason=coalesce(s.snapshot->>'reason','waiting') THEN
      -- Old finish wrote requirement, mapping and status in one transaction.
      -- Exact cycle + latest status + xmin equality reject later manual edits,
      -- including a manual block with an unchanged status string. If history was
      -- pruned/rewritten, fail closed; do not infer authorization from wait text.
      SELECT EXISTS (
        SELECT 1 FROM public.requirements q
        JOIN public.harness_requirement_runs h ON h.requirement_id=q.id
        CROSS JOIN LATERAL (SELECT st.* , st.xmin AS status_xmin FROM public.requirement_status st
          WHERE st.requirement_id=q.id ORDER BY st.updated_at DESC NULLS LAST,st.id DESC LIMIT 1) last_status
        WHERE q.id=r.id AND q.xmin=h.xmin AND q.xmin=last_status.status_xmin
          AND last_status.site_id=r.site_id
          AND last_status.instance_id::text=r.metadata->>'runner_instance_id'
          AND last_status.stage='blocked' AND last_status.cycle='agent:'||m.last_cycle_id
      ) INTO recover_wait;
    END IF;
    -- The wider candidate scan above grants no new manual-block escape hatch.
    IF r.status='blocked' AND NOT recover_wait
      AND NOT coalesce(r.metadata->>'cron_blocker_provenance' IN
        ('product_no_progress_circuit','cron_infrastructure','product_attempt_budget','product_replan_circuit'),false)
      AND NOT (has_mapping AND generation>m.generation) THEN CONTINUE; END IF;
    IF has_mapping AND NOT due AND generation=m.generation THEN
      IF m.next_run_at>clock_timestamp() OR (m.pause_reason IS NOT NULL AND m.next_run_at IS NULL AND NOT recover_wait) THEN CONTINUE; END IF;
      IF has_session AND s.snapshot->>'status' IN ('paused','cancelled')
      THEN CONTINUE; END IF;
    END IF;
    -- Existing identity is authoritative, even if missing/archived. Never replace.
    instance_id:=NULL;
    IF r.metadata->>'runner_instance_id' IS NOT NULL THEN
      SELECT id INTO instance_id FROM public.remote_instances WHERE id::text=r.metadata->>'runner_instance_id' AND site_id=r.site_id;
      IF instance_id IS NULL THEN CONTINUE; END IF;
    ELSIF r.metadata->>'assistant_origin_instance_id' IS NOT NULL THEN
      SELECT id INTO instance_id FROM public.remote_instances WHERE id::text=r.metadata->>'assistant_origin_instance_id' AND site_id=r.site_id;
      IF instance_id IS NULL THEN CONTINUE; END IF;
    ELSE
      SELECT p.instance_id INTO instance_id FROM public.instance_plans p WHERE p.site_id=r.site_id
        AND p.metadata->>'requirement_id'=r.id::text ORDER BY p.created_at,p.id LIMIT 1;
      IF NOT FOUND THEN
        SELECT id INTO instance_id FROM public.remote_instances WHERE site_id=r.site_id AND name='req-runner-'||r.id::text ORDER BY created_at,id LIMIT 1;
      END IF;
      IF instance_id IS NULL THEN
        -- User guards must precede even first-run infrastructure creation.
        IF coalesce(r.metadata->>'customer_paused','false')='true' OR coalesce(r.metadata->>'user_paused','false')='true'
          OR coalesce(r.metadata->>'cron_paused','false')='true' OR EXISTS (SELECT 1 FROM public.instance_plans
            WHERE site_id=r.site_id AND metadata->>'requirement_id'=r.id::text) THEN CONTINUE; END IF;
        INSERT INTO public.remote_instances(name,instance_type,status,is_archived,site_id,user_id,created_by)
          VALUES('req-runner-'||r.id::text,'browser','pending',false,r.site_id,r.user_id,r.user_id) RETURNING id INTO instance_id;
      END IF;
    END IF;
    IF NOT public.agent_requirement_runner_allowed(r.id,instance_id) THEN CONTINUE; END IF;
    IF EXISTS (SELECT 1 FROM public.requirements other WHERE other.id<>r.id AND other.cron_lock_expires_at>clock_timestamp()
      AND (other.metadata->>'runner_instance_id'=instance_id::text OR other.metadata->>'assistant_origin_instance_id'=instance_id::text)) THEN CONTINUE; END IF;
    IF has_session AND NOT due AND generation=m.generation AND s.snapshot->>'status'='completed' THEN
      -- Crash recovery: the durable terminal save may precede the cycle-finally
      -- call. Project its result after both leases expire; never replay its work.
      UPDATE public.requirements SET status='on-review',updated_at=clock_timestamp(),cron_lock_run_id=NULL,
        cron_lock_expires_at=NULL,cron_lock_active=false WHERE id=r.id;
      UPDATE public.harness_requirement_runs SET last_cycle_id=coalesce(r.cron_lock_run_id,'recovered:'||s.id::text),
        pause_reason=NULL,next_run_at=NULL WHERE requirement_id=r.id;
      INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,cycle,message)
        VALUES(r.id,r.site_id,instance_id,'on-review','agent-recovered:'||s.id::text,
          'Agent session completed; recovered its review handoff after an interrupted cycle.');
      CONTINUE;
    END IF;
    IF due THEN
      generation:=generation+1;
      -- Only an explicitly due terminal occurrence receives a new session/budget.
      IF has_session AND s.snapshot->>'status' NOT IN ('completed','cancelled') THEN CONTINUE; END IF;
      m.previous_session_id:=m.session_id;
      m.session_id:=gen_random_uuid();
    ELSIF has_session AND generation>m.generation THEN
      IF s.snapshot->>'status'='cancelled' THEN CONTINUE; END IF;
      -- Explicit user generation may resume; budgets/pending/workspace stay intact.
      IF s.snapshot->>'status'='completed' THEN
        UPDATE public.harness_sessions SET version=version+1,lease_owner=NULL,lease_expires_at=NULL,
          snapshot=snapshot||jsonb_build_object('status','queued','version',version+1,'updatedAt',clock_timestamp()) WHERE id=s.id;
      ELSE
        PERFORM public.control_harness_session(s.id,r.site_id,'resume',NULL);
      END IF;
    ELSIF has_session AND s.snapshot->>'status' IN ('waiting','failed') THEN
      PERFORM public.control_harness_session(s.id,r.site_id,'resume',NULL);
    END IF;
    IF NOT has_mapping THEN m.session_id:=gen_random_uuid(); END IF;
    run_id:='agent-cron-'||gen_random_uuid()::text;
    INSERT INTO public.harness_requirement_runs(requirement_id,site_id,session_id,previous_session_id,generation,next_run_at,pause_reason,last_cycle_id)
      VALUES(r.id,r.site_id,m.session_id,m.previous_session_id,generation,NULL,NULL,m.last_cycle_id)
      ON CONFLICT(requirement_id) DO UPDATE SET session_id=EXCLUDED.session_id,
        previous_session_id=CASE WHEN due THEN EXCLUDED.previous_session_id ELSE public.harness_requirement_runs.previous_session_id END,
        generation=EXCLUDED.generation,next_run_at=NULL,pause_reason=NULL;
    UPDATE public.requirements SET status='in-progress',updated_at=clock_timestamp(),cron_lock_run_id=run_id,cron_lock_active=true,
      cron_lock_expires_at=clock_timestamp()+make_interval(secs=>p_ttl_seconds),
      metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('runner_instance_id',instance_id,'requirement_execution_generation',generation)
      WHERE id=r.id RETURNING * INTO r;
    RETURN jsonb_build_object('state','claimed','requirement',to_jsonb(r),'run',jsonb_build_object(
      'requirementId',r.id,'siteId',r.site_id,'userId',r.user_id,'instanceId',instance_id,
      'runId',run_id,'executionGeneration',generation,'sessionId',m.session_id));
  END LOOP;
  RETURN NULL;
END;
$_$;


--
-- Name: claim_approved_message(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_approved_message(p_message_id uuid, p_conversation_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4228220($1,$2); END$_$;


--
-- Name: claim_approved_messages_batch(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_approved_messages_batch(p_messages jsonb) RETURNS TABLE(message_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_4228221($1); END$_$;


--
-- Name: claim_catalog_embedding_jobs(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_catalog_embedding_jobs(p_limit integer, p_lease_seconds integer) RETURNS TABLE(id uuid, catalog_item_id uuid, site_id uuid, document_text text, source_hash text, source_revision bigint, claim_token uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
BEGIN
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 100 OR p_lease_seconds IS NULL
    OR p_lease_seconds NOT BETWEEN 30 AND 900 THEN
    RAISE EXCEPTION 'invalid claim bounds' USING ERRCODE = '22023';
  END IF;
  -- Independent of the provider claim size (API currently claims only eight).
  -- Non-semantic/sort-only fanout still makes bounded progress at 100 per poll.
  PERFORM public.catalog_search_drain_refresh_events(100);
  RETURN QUERY SELECT * FROM public.catalog_search_claim_embedding_jobs(p_limit, p_lease_seconds);
END $$;


--
-- Name: claim_harness_session(uuid, uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_sessions%ROWTYPE; result jsonb; t timestamptz;
BEGIN
  IF p_owner IS NULL OR length(btrim(p_owner)) = 0 OR length(p_owner) > 200 OR p_ttl_seconds IS NULL OR p_ttl_seconds NOT BETWEEN 1 AND 300
  THEN RAISE EXCEPTION 'Invalid harness lease' USING ERRCODE='22023'; END IF;
  SELECT * INTO r FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN NULL; END IF;
  t := clock_timestamp();
  IF r.snapshot->>'status' NOT IN ('queued','running')
    OR (r.lease_owner IS NOT NULL AND r.lease_owner <> p_owner AND r.lease_expires_at > t) THEN RETURN NULL; END IF;
  UPDATE public.harness_sessions SET
    lease_owner=p_owner, lease_expires_at=t+make_interval(secs=>p_ttl_seconds), version=version+1,
    snapshot=snapshot || jsonb_build_object('status','running','version',version+1,'updatedAt',t)
    WHERE id=p_id AND site_id=p_site_id RETURNING snapshot INTO result;
  RETURN result;
END;
$$;


--
-- Name: claim_icp_mining_execution(uuid, uuid, uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_workflow_id text, p_previous_run_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE r public.icp_mining; d public.icp_dispatch_runs;
BEGIN
  IF p_run_id IS NULL OR NULLIF(p_workflow_id, '') IS NULL THEN RAISE EXCEPTION 'Execution identity required'; END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(734210, 1);
  SELECT * INTO d FROM public.icp_dispatch_runs WHERE site_id = p_site_id AND state IN ('reserved', 'running', 'blocked');
  IF FOUND AND (d.workflow_id IS DISTINCT FROM p_workflow_id OR d.icp_mining_id IS DISTINCT FROM p_id
    OR d.run_id IS DISTINCT FROM p_run_id OR d.state = 'blocked') THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'busy',
      'owner_run_id', d.run_id, 'owner_workflow_id', d.workflow_id);
  END IF;
  SELECT * INTO r FROM public.icp_mining WHERE id = p_id AND site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Mining request not found in site'; END IF;
  IF r.execution_run_id = p_run_id THEN
    RETURN jsonb_build_object('acquired', r.execution_active, 'reason', 'same_run', 'icp', to_jsonb(r));
  END IF;
  IF r.execution_active AND r.execution_run_id IS DISTINCT FROM p_previous_run_id THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'busy',
      'owner_run_id', r.execution_run_id, 'owner_workflow_id', r.execution_workflow_id);
  END IF;
  IF r.status NOT IN ('pending', 'running') THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'not_pending');
  END IF;
  PERFORM pg_catalog.set_config('app.icp_execution_owner', p_run_id::text, true);
  UPDATE public.icp_mining SET execution_run_id = p_run_id, execution_workflow_id = p_workflow_id,
    execution_active = true, checkpoint_version = 0, status = 'running',
    started_at = COALESCE(started_at, now()), finished_at = NULL, last_progress_at = now()
    WHERE id = p_id RETURNING * INTO r;
  RETURN jsonb_build_object('acquired', true, 'icp', to_jsonb(r));
END $$;


--
-- Name: claim_insufficient_credit_email(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_insufficient_credit_email(p_site_id uuid, p_recipient_hash text, p_owner_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  v_now timestamptz;
  v_last_attempt_at timestamptz;
  v_attempted_at timestamptz[];
  v_idempotency_key text;
BEGIN
  IF p_site_id IS NULL OR p_recipient_hash IS NULL OR p_owner_id IS NULL
    OR length(p_recipient_hash) <> 64
    OR p_recipient_hash COLLATE "C" !~ '^[0-9a-f]{64}$' THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_input');
  END IF;

  -- Fixed, disjoint two-int advisory-lock namespaces avoid site/recipient lock
  -- inversion even if hashtext collides. Collisions only over-serialize callers.
  -- Every worker takes the site lock FIRST, then the recipient lock, including
  -- first attempts where no durable row exists yet. Locks last to xact commit.
  PERFORM pg_catalog.pg_advisory_xact_lock(1768121701, pg_catalog.hashtext(p_site_id::text));
  PERFORM pg_catalog.pg_advisory_xact_lock(1768121702, pg_catalog.hashtext(p_recipient_hash));

  -- Bind the owner captured by the caller before resolving its recipient email.
  -- A transfer between that read and claim must not notify the previous owner.
  -- Keep the active owned site stable through commit (including archival/deletion).
  PERFORM 1 FROM public.sites
    WHERE id = p_site_id AND archived_at IS NULL AND user_id = p_owner_id FOR SHARE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'site_unavailable');
  END IF;
  -- now()/transaction_timestamp() can predate time spent waiting on another
  -- worker. Evaluate rolling windows using wall-clock time AFTER all locks.
  v_now := pg_catalog.clock_timestamp();

  SELECT last_attempt_at INTO v_last_attempt_at
    FROM public.insufficient_credit_email_site_gates WHERE site_id = p_site_id;
  IF v_last_attempt_at > v_now - interval '24 hours' THEN
    -- Same-site duplicates do not reveal the prior key or consume any budget,
    -- even when the caller supplies a different valid recipient hash.
    RETURN jsonb_build_object('acquired', false, 'reason', 'site_rate_limited');
  END IF;

  SELECT attempted_at INTO v_attempted_at
    FROM public.insufficient_credit_email_recipient_gates WHERE recipient_hash = p_recipient_hash;
  SELECT coalesce(array_agg(attempt_at ORDER BY attempt_at), ARRAY[]::timestamptz[])
    INTO v_attempted_at FROM unnest(v_attempted_at) AS attempts(attempt_at)
    WHERE attempt_at > v_now - interval '10 minutes';
  IF cardinality(v_attempted_at) >= 3 THEN
    -- No inserts, updates or even pruning for a denied claim.
    RETURN jsonb_build_object('acquired', false, 'reason', 'recipient_rate_limited');
  END IF;

  v_idempotency_key := 'insufficient-credit-email:' || pg_catalog.gen_random_uuid()::text;
  INSERT INTO public.insufficient_credit_email_site_gates(site_id, last_attempt_at, idempotency_key)
    VALUES (p_site_id, v_now, v_idempotency_key)
    ON CONFLICT (site_id) DO UPDATE
      SET last_attempt_at = EXCLUDED.last_attempt_at, idempotency_key = EXCLUDED.idempotency_key;
  INSERT INTO public.insufficient_credit_email_recipient_gates(recipient_hash, attempted_at)
    VALUES (p_recipient_hash, array_append(v_attempted_at, v_now))
    ON CONFLICT (recipient_hash) DO UPDATE SET attempted_at = EXCLUDED.attempted_at;

  RETURN jsonb_build_object('acquired', true, 'idempotency_key', v_idempotency_key);
END;
$_$;


--
-- Name: claim_invoice_reminder(uuid, uuid, text, date, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_invoice_reminder(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_sale public.sales%rowtype;
  v_receipt public.invoice_reminders%rowtype;
begin
  if p_interval_days is null or p_interval_days < 1 or p_interval_days > 365
    or p_local_day is null or not isfinite(p_local_day) or p_local_day < date '0001-01-01' or p_local_day > date '9999-12-31'
    or p_reminder_key is null or length(p_reminder_key) not between 1 and 200 then
    raise exception 'Invalid invoice reminder claim';
  end if;
  select * into v_sale from public.sales where id = p_sale_id and site_id = p_site_id for update;
  if not found then return jsonb_build_object('reason', 'sale_not_found'); end if;
  if v_sale.status is distinct from 'pending' or v_sale.amount_due is null or v_sale.amount_due <= 0
    or v_sale.amount_due::text in ('NaN', 'Infinity', '-Infinity')
    or v_sale.due_date is null or not isfinite(v_sale.due_date) or v_sale.due_date < date '0001-01-01'
    or v_sale.due_date > p_local_day then
    return jsonb_build_object('reason', 'invoice_not_due');
  end if;
  select * into v_receipt from public.invoice_reminders
    where site_id = p_site_id and sale_id = p_sale_id and state in ('generating', 'ready', 'uncertain')
    order by created_at desc limit 1;
  if found then
    return jsonb_build_object('reason', case when v_receipt.state = 'ready' then 'ready' else 'reminder_uncertain' end,
      'reminder', to_jsonb(v_receipt));
  end if;
  if exists (select 1 from public.invoice_reminders where site_id = p_site_id and sale_id = p_sale_id
    and (reminder_key = p_reminder_key or sent_at > now() - make_interval(days => p_interval_days))) then
    return jsonb_build_object('reason', 'repeat_interval');
  end if;
  insert into public.invoice_reminders(site_id, sale_id, reminder_key)
    values (p_site_id, p_sale_id, p_reminder_key) returning * into v_receipt;
  return jsonb_build_object('claimed', true, 'reminder', to_jsonb(v_receipt));
end;
$$;


--
-- Name: claim_invoice_reminder_with_cooldown(uuid, uuid, text, date, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_invoice_reminder_with_cooldown(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer, p_mode text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_sale public.sales%rowtype;
  v_receipt public.invoice_reminders%rowtype;
  v_last_sent timestamptz;
  v_sent_count bigint;
  v_days integer;
begin
  if p_mode is null or p_mode not in ('progressive', 'fixed')
    or p_interval_days is null or p_interval_days < 1 or p_interval_days > 365
    or p_local_day is null or not isfinite(p_local_day) or p_local_day < date '0001-01-01' or p_local_day > date '9999-12-31'
    or p_reminder_key is null or length(p_reminder_key) not between 1 and 200 then
    raise exception 'Invalid invoice reminder claim';
  end if;
  -- Serialize competing keys and changing cadences for the same invoice.
  select * into v_sale from public.sales where id = p_sale_id and site_id = p_site_id for update;
  if not found then return jsonb_build_object('reason', 'sale_not_found'); end if;
  if v_sale.status is distinct from 'pending' or v_sale.amount_due is null or v_sale.amount_due <= 0
    or v_sale.amount_due::text in ('NaN', 'Infinity', '-Infinity')
    or v_sale.due_date is null or not isfinite(v_sale.due_date) or v_sale.due_date < date '0001-01-01'
    or v_sale.due_date > p_local_day then
    return jsonb_build_object('reason', 'invoice_not_due');
  end if;
  select * into v_receipt from public.invoice_reminders
    where site_id = p_site_id and sale_id = p_sale_id and state in ('generating', 'ready', 'uncertain')
    order by created_at desc limit 1;
  if found then
    return jsonb_build_object('reason', case when v_receipt.state = 'ready' then 'ready' else 'reminder_uncertain' end,
      'reminder', to_jsonb(v_receipt));
  end if;
  if exists (select 1 from public.invoice_reminders where site_id = p_site_id and sale_id = p_sale_id
    and reminder_key = p_reminder_key) then return jsonb_build_object('reason', 'repeat_interval'); end if;
  select count(*), max(sent_at) into v_sent_count, v_last_sent from public.invoice_reminders
    where site_id = p_site_id and sale_id = p_sale_id and state = 'sent';
  if v_sent_count > 0 then
    v_days := case when p_mode = 'fixed' then p_interval_days
      else case when v_sent_count <= 2 then 1 when v_sent_count = 3 then 3
        when v_sent_count = 4 then 7 else 14 end end;
    if v_last_sent is null or v_last_sent > now() - make_interval(days => v_days) then
      return jsonb_build_object('reason', 'repeat_interval');
    end if;
  end if;
  insert into public.invoice_reminders(site_id, sale_id, reminder_key)
    values (p_site_id, p_sale_id, p_reminder_key) returning * into v_receipt;
  return jsonb_build_object('claimed', true, 'reminder', to_jsonb(v_receipt));
end;
$$;

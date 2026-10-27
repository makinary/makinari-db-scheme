SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: fetch_sites_needing_billing_initialization(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fetch_sites_needing_billing_initialization() RETURNS TABLE(site_id uuid)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  SELECT s.id FROM public.sites s WHERE s.archived_at IS NULL AND NOT EXISTS
    (SELECT 1 FROM public.billing b WHERE b.site_id = s.id);
$$;


--
-- Name: fetch_social_posts_due_for_analytics(uuid[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fetch_social_posts_due_for_analytics(p_site_ids uuid[], p_limit integer DEFAULT 1000) RETURNS TABLE(site_id uuid, post_id text, content_id text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_4247935($1,$2); END$_$;


--
-- Name: finalize_requirement_execution_atomic(uuid, uuid, uuid, integer, text, uuid, text, text, text, text, text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finalize_requirement_execution_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_expected_execution_generation integer, p_event_id text, p_existing_status_id uuid, p_stage text, p_message text, p_repo_url text, p_preview_url text, p_source_code text, p_snapshot_id text, p_is_complete boolean, p_mark_on_review boolean) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_requirement_status text;
  v_requirement_site_id uuid;
  v_metadata jsonb;
  v_backlog jsonb;
  v_execution_generation integer;
  v_status_id uuid;
  v_cycle text := 'cron-finalize:' || p_event_id;
  v_has_outstanding_work boolean := false;
BEGIN
  IF NULLIF(btrim(p_event_id), '') IS NULL THEN
    RAISE EXCEPTION 'p_event_id is required';
  END IF;
  IF p_stage NOT IN ('done', 'in-progress', 'blocked', 'on-review') THEN
    RAISE EXCEPTION 'Unsupported final requirement status: %', p_stage;
  END IF;

  SELECT
    status,
    site_id,
    CASE WHEN jsonb_typeof(metadata) = 'object'
      THEN metadata ELSE '{}'::jsonb END,
    CASE WHEN jsonb_typeof(backlog) = 'object'
      THEN backlog ELSE '{}'::jsonb END
  INTO
    v_requirement_status,
    v_requirement_site_id,
    v_metadata,
    v_backlog
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'state', 'missing',
      'effective_status', 'in-progress'
    );
  END IF;
  IF v_requirement_site_id IS DISTINCT FROM p_site_id THEN
    RAISE EXCEPTION 'Requirement % does not belong to site %',
      p_requirement_id, p_site_id;
  END IF;

  v_execution_generation := CASE
    WHEN COALESCE(
      v_metadata->>'requirement_execution_generation',
      ''
    ) ~ '^[0-9]{1,9}$'
      THEN (v_metadata->>'requirement_execution_generation')::integer
    ELSE 0
  END;
  IF v_execution_generation IS DISTINCT FROM
    p_expected_execution_generation
  THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'effective_status', 'in-progress'
    );
  END IF;
  IF v_requirement_status IN ('cancelled', 'canceled')
    OR (v_requirement_status = 'done' AND NOT p_is_complete)
  THEN
    RETURN jsonb_build_object(
      'state', 'guarded',
      'effective_status',
      CASE WHEN v_requirement_status = 'done' THEN 'done' ELSE 'blocked' END
    );
  END IF;

  SELECT id
  INTO v_status_id
  FROM public.requirement_status
  WHERE requirement_id = p_requirement_id
    AND cycle = v_cycle
  ORDER BY created_at DESC, id DESC
  LIMIT 1
  FOR UPDATE;

  IF v_status_id IS NULL AND p_existing_status_id IS NOT NULL THEN
    SELECT id
    INTO v_status_id
    FROM public.requirement_status
    WHERE id = p_existing_status_id
      AND requirement_id = p_requirement_id
      AND site_id = p_site_id
      AND instance_id IS NOT DISTINCT FROM p_instance_id
    FOR UPDATE;
  END IF;

  IF v_status_id IS NULL THEN
    INSERT INTO public.requirement_status (
      site_id,
      instance_id,
      requirement_id,
      repo_url,
      preview_url,
      source_code,
      snapshot_id,
      stage,
      cycle,
      message
    ) VALUES (
      p_site_id,
      p_instance_id,
      p_requirement_id,
      p_repo_url,
      p_preview_url,
      p_source_code,
      p_snapshot_id,
      p_stage,
      v_cycle,
      p_message
    )
    RETURNING id INTO v_status_id;
  ELSE
    UPDATE public.requirement_status
    SET
      repo_url = p_repo_url,
      preview_url = p_preview_url,
      source_code = p_source_code,
      snapshot_id = COALESCE(p_snapshot_id, snapshot_id),
      stage = p_stage,
      cycle = v_cycle,
      message = p_message,
      updated_at = timezone('utc', now())
    WHERE id = v_status_id;
  END IF;

  IF p_is_complete THEN
    UPDATE public.requirements
    SET status = 'done', updated_at = timezone('utc', now())
    WHERE id = p_requirement_id;

    UPDATE public.remote_instances
    SET status = 'pending'
    WHERE id = p_instance_id
      AND site_id = p_site_id
      AND status IN ('running', 'starting');

    UPDATE public.instance_plans
    SET status = 'cancelled', updated_at = timezone('utc', now())
    WHERE instance_id = p_instance_id
      AND metadata->>'requirement_id' = p_requirement_id::text
      AND status IN ('pending', 'in_progress', 'active');
  ELSIF p_mark_on_review THEN
    SELECT EXISTS (
      SELECT 1
      FROM jsonb_array_elements(
        CASE
          WHEN jsonb_typeof(v_backlog->'items') = 'array'
            THEN v_backlog->'items'
          ELSE '[]'::jsonb
        END
      ) AS item
      WHERE COALESCE(item->>'status', '') NOT IN (
        'done',
        'needs_review',
        'rejected'
      )
    )
    INTO v_has_outstanding_work;
    IF NOT v_has_outstanding_work THEN
      UPDATE public.requirements
      SET status = 'on-review', updated_at = timezone('utc', now())
      WHERE id = p_requirement_id;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'state', 'applied',
    'effective_status', p_stage,
    'status_id', v_status_id
  );
END;
$_$;


--
-- Name: finalize_setup_email_delivery(text, uuid, jsonb, uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finalize_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid, p_state text, p_receipt jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  r public.setup_email_delivery_receipts%ROWTYPE;
BEGIN
  IF p_state IS NULL OR p_state NOT IN ('sent','skipped','uncertain')
    OR p_receipt IS NULL OR jsonb_typeof(p_receipt) <> 'object'
    OR p_receipt->>'status' IS DISTINCT FROM p_state THEN
    RAISE EXCEPTION 'Invalid setup email receipt' USING ERRCODE = '22023';
  END IF;
  IF p_state = 'sent' AND (p_receipt->>'success' IS DISTINCT FROM 'true'
    OR coalesce(btrim(p_receipt->>'messageId'),'') = ''
    OR p_receipt->>'recipient' IS DISTINCT FROM p_payload->>'email'
    OR coalesce(p_receipt->>'sent_at','') = '') THEN
    RAISE EXCEPTION 'Sent receipt requires actual delivery confirmation' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO r FROM public.setup_email_delivery_receipts WHERE operation_key = p_operation_key FOR UPDATE;
  IF NOT FOUND OR p_claim_token IS NULL OR r.claim_token <> p_claim_token
    OR p_site_id IS NULL OR r.site_id <> p_site_id OR p_payload IS NULL OR r.payload <> p_payload THEN
    RETURN jsonb_build_object('outcome','conflict');
  END IF;
  -- Same-token uncertain -> sent supports evidence-based operator reconciliation,
  -- never authorizes another send. Terminal success cannot be overwritten.
  IF r.state <> 'claimed' AND NOT (r.state = 'uncertain' AND p_state = 'sent') THEN
    IF r.state = p_state AND r.receipt = p_receipt THEN
      RETURN jsonb_build_object('outcome',r.state,'receipt',r.receipt);
    END IF;
    RETURN jsonb_build_object('outcome','conflict');
  END IF;
  UPDATE public.setup_email_delivery_receipts SET state = p_state, receipt = p_receipt, finalized_at = now()
    WHERE operation_key = p_operation_key;
  RETURN jsonb_build_object('outcome',p_state,'receipt',p_receipt);
END;
$$;


--
-- Name: finish_agent_requirement_cycle(uuid, text, integer, uuid, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_agent_requirement_cycle(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_session_status text, p_reason text, p_summary text, p_repo_url text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.requirements%ROWTYPE; s public.harness_sessions%ROWTYPE; target text; retry boolean; frozen boolean; t timestamptz:=clock_timestamp();
BEGIN
  IF p_session_status IS NULL OR p_session_status NOT IN ('queued','running','completed','waiting','paused','failed','cancelled')
    OR length(p_reason)>4000 OR length(p_summary)>20000 OR length(p_repo_url)>4000
  THEN RAISE EXCEPTION 'Invalid agent cycle result' USING ERRCODE='22023'; END IF;
  IF NOT public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id,true,300) THEN
    -- Finally-release only our still-current lease; never undo a user pause.
    UPDATE public.requirements SET cron_lock_run_id=NULL,cron_lock_expires_at=NULL,cron_lock_active=false
      WHERE id=p_requirement_id AND cron_lock_run_id=p_run_id
        AND metadata->>'requirement_execution_generation'=p_generation::text
        AND EXISTS (SELECT 1 FROM public.harness_requirement_runs WHERE requirement_id=p_requirement_id AND session_id=p_session_id AND generation=p_generation);
    RETURN false;
  END IF;
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id;
  SELECT * INTO s FROM public.harness_sessions WHERE id=p_session_id;
  -- An interactive control arriving after the worker snapshot must win over a
  -- stale worker's final projection. Never turn a newly paused session into done.
  IF FOUND AND s.snapshot->>'status' IN ('paused','cancelled') THEN
    p_session_status:=s.snapshot->>'status';
    p_reason:=coalesce(s.snapshot->>'reason',p_session_status);
  END IF;
  -- Waiting is agent continuation, not a product/user stop. The engine owns
  -- real budget, billing and authorization pauses; never weaken those statuses.
  retry:=p_session_status IN ('failed','waiting');
  frozen:=p_session_status IN ('paused','cancelled');
  target:=CASE WHEN p_session_status='completed' THEN 'on-review' WHEN frozen THEN 'blocked' ELSE 'in-progress' END;
  -- implemented is a review projection, never automatic product acceptance/done.
  UPDATE public.requirements SET status=target,updated_at=t,cron_lock_run_id=NULL,cron_lock_expires_at=NULL,cron_lock_active=false WHERE id=r.id;
  UPDATE public.harness_requirement_runs SET last_cycle_id=p_run_id,
    pause_reason=CASE WHEN frozen THEN coalesce(p_reason,p_session_status) ELSE NULL END,
    next_run_at=CASE WHEN retry THEN t+interval '60 seconds' WHEN p_session_status IN ('queued','running') THEN t ELSE NULL END
    WHERE requirement_id=r.id;
  INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,cycle,message,repo_url)
    VALUES(r.id,r.site_id,(r.metadata->>'runner_instance_id')::uuid,target,'agent:'||p_run_id,
      coalesce(nullif(p_summary,''),p_reason,p_session_status),p_repo_url);
  RETURN true;
END;
$$;


--
-- Name: finish_harness_model_reservation(uuid, uuid, numeric, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text, p_cancel_reason text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_model_credit_reservations%ROWTYPE; b public.billing%ROWTYPE;
  v_trial numeric; v_restore_trial numeric; v_charge numeric; v_refund numeric; v_plan numeric; v_legacy numeric; v_purchase numeric;
  v_restore_plan numeric; v_same_period boolean; v_extra jsonb; v_metadata jsonb;
  g public.openrouter_generation_charges%ROWTYPE; v_global_id text; v_already_charged boolean:=false;
BEGIN
  IF p_cost IS NOT NULL AND (p_cost<0 OR p_cost::text IN ('NaN','Infinity','-Infinity')) THEN
    RAISE EXCEPTION 'Invalid OpenRouter actual cost'; END IF;
  IF p_generation_id IS NOT NULL AND (length(p_generation_id)=0 OR length(p_generation_id)>256) THEN
    RAISE EXCEPTION 'Invalid generation identity'; END IF;
  IF p_model IS NOT NULL AND length(p_model)>500 THEN RAISE EXCEPTION 'Invalid provider model'; END IF;
  IF p_cancel_reason IS NOT NULL AND p_cancel_reason NOT IN ('predispatch','admission_rejected') THEN
    RAISE EXCEPTION 'Invalid cancellation proof'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('harness-model:'||p_session_id,0));
  SELECT * INTO r FROM public.harness_model_credit_reservations WHERE session_id=p_session_id AND event_id=p_event_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false); END IF;
  IF r.state IN ('settled','cancelled') THEN
    IF (r.state='cancelled') IS DISTINCT FROM (p_cancel_reason IS NOT NULL)
      OR (r.state='settled' AND r.provider_cost IS DISTINCT FROM p_cost)
      OR (p_generation_id IS NOT NULL AND r.generation_id IS DISTINCT FROM p_generation_id) THEN
      RAISE EXCEPTION 'Model settlement identity conflict'; END IF;
    RETURN jsonb_build_object('success',true,'state',r.state,'charged',r.charged);
  END IF;
  IF r.provider_cost IS NOT NULL AND p_cost IS NOT NULL AND r.provider_cost<>p_cost THEN
    RAISE EXCEPTION 'Provider cost conflict'; END IF;
  IF r.generation_id IS NOT NULL AND p_generation_id IS NOT NULL AND r.generation_id<>p_generation_id THEN
    RAISE EXCEPTION 'Provider generation conflict'; END IF;
  IF p_cancel_reason IS NOT NULL AND (r.provider_cost IS NOT NULL OR r.generation_id IS NOT NULL
    OR r.state='pending') THEN RAISE EXCEPTION 'Cannot refund uncertain accepted generation'; END IF;
  IF p_cancel_reason IS NULL AND r.state='reserved' THEN RAISE EXCEPTION 'Model was not dispatched'; END IF;
  UPDATE public.harness_model_credit_reservations SET provider_cost=coalesce(p_cost,provider_cost),
    generation_id=coalesce(p_generation_id,generation_id),model=coalesce(p_model,model)
    WHERE session_id=p_session_id AND event_id=p_event_id;
  IF p_cancel_reason IS NULL THEN
    v_global_id:=coalesce(p_generation_id,r.generation_id,'harness:'||p_event_id);
    -- A previously unknown transport can later disclose its generation ID.
    -- Move its uncharged fallback receipt rather than stranding a pending alias.
    IF v_global_id<>'harness:'||p_event_id THEN
      PERFORM pg_advisory_xact_lock(hashtextextended('openrouter_generation:harness:'||p_event_id,0));
      DELETE FROM public.openrouter_generation_charges WHERE event_id='harness:'||p_event_id
        AND state='pending' AND metadata->>'harness_reservation_event'=p_event_id::text;
    END IF;
    PERFORM pg_advisory_xact_lock(hashtextextended('openrouter_generation:'||v_global_id,0));
    SELECT * INTO g FROM public.openrouter_generation_charges WHERE event_id=v_global_id FOR UPDATE;
    IF FOUND THEN
      IF g.site_id<>r.site_id OR (g.provider_cost IS NOT NULL AND coalesce(p_cost,r.provider_cost) IS NOT NULL
        AND g.provider_cost<>coalesce(p_cost,r.provider_cost)) OR (g.metadata ? 'harness_reservation_event'
        AND g.metadata->>'harness_reservation_event'<>p_event_id::text) THEN
        RAISE EXCEPTION 'OpenRouter billing identity conflict'; END IF;
      v_already_charged:=g.state='charged';
      IF NOT v_already_charged THEN
        UPDATE public.openrouter_generation_charges SET provider_cost=coalesce(p_cost,r.provider_cost,provider_cost),
          amount=coalesce(p_cost,r.provider_cost,provider_cost)*1.25,
          metadata=metadata||jsonb_build_object('harness_reservation_event',p_event_id)
          WHERE event_id=v_global_id; END IF;
    ELSE
      INSERT INTO public.openrouter_generation_charges(event_id,site_id,provider_cost,amount,metadata)
        VALUES(v_global_id,r.site_id,coalesce(p_cost,r.provider_cost),coalesce(p_cost,r.provider_cost)*1.25,
          jsonb_build_object('harness_reservation_event',p_event_id));
    END IF;
  END IF;
  IF p_cancel_reason IS NULL AND coalesce(p_cost,r.provider_cost) IS NULL THEN
    UPDATE public.harness_model_credit_reservations SET state='pending' WHERE session_id=p_session_id AND event_id=p_event_id;
    RETURN jsonb_build_object('success',false,'state','pending','error','Actual cost unknown'); END IF;
  v_charge:=CASE WHEN p_cancel_reason IS NOT NULL THEN 0 ELSE coalesce(p_cost,r.provider_cost)*1.25 END;
  IF v_already_charged THEN v_charge:=0; END IF;
  PERFORM public.renew_site_plan_credits(r.site_id);
  SELECT * INTO b FROM public.billing WHERE site_id=r.site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing row missing for held model work'; END IF;
  v_metadata:=jsonb_build_object('session_id',p_session_id,'event_id',p_event_id,'requirement_id',r.requirement_id,
    'generation_id',coalesce(p_generation_id,r.generation_id),'model',coalesce(p_model,r.model),
    'provider_cost',coalesce(p_cost,r.provider_cost),'multiplier',1.25,'actual_charge',coalesce(p_cost,r.provider_cost)*1.25,
    'already_charged_globally',v_already_charged);
  IF v_charge>r.amount THEN
    v_extra:=public.deduct_credits(r.site_id,v_charge-r.amount,'agent_model_actual_cost',
      'OpenRouter actual cost above admission hold',v_metadata);
    IF v_extra->>'success' IS DISTINCT FROM 'true' THEN
      UPDATE public.harness_model_credit_reservations SET state='pending' WHERE session_id=p_session_id AND event_id=p_event_id;
      RETURN jsonb_build_object('success',false,'state','pending','error','Additional credits required'); END IF;
  END IF;
  v_refund:=greatest(r.amount-v_charge,0);
  -- Preserve spend order trial -> plan -> legacy -> purchased; refund in reverse.
  v_purchase:=least(r.purchased_spent,v_refund);
  v_legacy:=least(r.legacy_spent,v_refund-v_purchase);
  v_plan:=least(r.plan_spent,v_refund-v_purchase-v_legacy);
  v_trial:=v_refund-v_purchase-v_legacy-v_plan;
  v_restore_trial:=CASE WHEN b.trial_ends_at IS NOT DISTINCT FROM r.trial_ends_at
    AND r.trial_ends_at>clock_timestamp() AND b.status='active'
    AND NOT EXISTS(SELECT 1 FROM public.sites WHERE id=r.site_id AND archived_at IS NOT NULL)
    THEN least(v_trial,greatest(50-b.trial_credits_available,0)) ELSE 0 END;
  v_same_period:=b.plan_credit_period_start IS NOT DISTINCT FROM r.period_start
    AND b.plan_credit_period_end IS NOT DISTINCT FROM r.period_end;
  -- Old plan money expires; it never becomes bought/legacy money or a new
  -- month's allowance. Never replenish a revoked/downgraded entitlement either.
  v_restore_plan:=CASE WHEN v_same_period AND r.period_end>clock_timestamp() AND b.status='active'
    AND NOT EXISTS(SELECT 1 FROM public.sites WHERE id=r.site_id AND archived_at IS NOT NULL) THEN
    least(v_plan,greatest(b.plan_credit_allowance-greatest(b.plan_credits_used-v_plan,0)-b.plan_credits_available,0)) ELSE 0 END;
  IF v_refund>0 THEN
    UPDATE public.billing SET trial_credits_available=trial_credits_available+v_restore_trial,
      plan_credits_available=plan_credits_available+v_restore_plan,
      legacy_credits_available=legacy_credits_available+v_legacy,purchased_credits_available=purchased_credits_available+v_purchase,
      credits_available=credits_available+v_restore_trial+v_restore_plan+v_legacy+v_purchase,
      credits_used=greatest(coalesce(credits_used,0)-v_refund,0),
      monthly_credits_used=CASE WHEN v_same_period THEN greatest(monthly_credits_used-v_refund,0) ELSE monthly_credits_used END,
      plan_credits_used=CASE WHEN v_same_period THEN greatest(plan_credits_used-v_plan,0) ELSE plan_credits_used END WHERE id=b.id;
    IF v_restore_trial+v_restore_plan+v_legacy+v_purchase>0 THEN
      INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
        VALUES(r.site_id,v_restore_trial+v_restore_plan+v_legacy+v_purchase,'agent_model_refund','Unused OpenRouter admission hold',
          v_metadata||jsonb_build_object('trial_credits_restored',v_restore_trial,'plan_credits_restored',v_restore_plan,'legacy_credits_restored',v_legacy,
            'purchased_credits_restored',v_purchase,'cancellation_reason',p_cancel_reason)); END IF;
    IF v_plan>v_restore_plan OR v_trial>v_restore_trial THEN
      INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
        VALUES(r.site_id,0,'agent_model_refund_expired','Unused included hold expired with its entitlement',
          v_metadata||jsonb_build_object('expired_trial_refund',v_trial-v_restore_trial,'expired_plan_refund',v_plan-v_restore_plan)); END IF;
  END IF;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES(r.site_id,0,'agent_model_settlement','OpenRouter final usage.cost settlement',v_metadata);
  UPDATE public.harness_model_credit_reservations SET state=CASE WHEN p_cancel_reason IS NULL THEN 'settled' ELSE 'cancelled' END,
    charged=CASE WHEN p_cancel_reason IS NULL THEN coalesce(p_cost,r.provider_cost)*1.25 ELSE 0 END,
    settled_at=now() WHERE session_id=p_session_id AND event_id=p_event_id;
  IF p_cancel_reason IS NULL AND NOT v_already_charged THEN
    UPDATE public.openrouter_generation_charges SET state='charged',charged_at=now(),result=jsonb_build_object(
      'success',true,'charged',coalesce(p_cost,r.provider_cost)*1.25,'provider_cost',coalesce(p_cost,r.provider_cost),'multiplier',1.25)
      WHERE event_id=v_global_id;
  END IF;
  RETURN jsonb_build_object('success',true,'state',CASE WHEN p_cancel_reason IS NULL THEN 'settled' ELSE 'cancelled' END,
    'charged',CASE WHEN p_cancel_reason IS NULL THEN coalesce(p_cost,r.provider_cost)*1.25 ELSE 0 END);
END;
$$;


--
-- Name: finish_harness_sandbox_cleanup(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.finish_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  UPDATE public.harness_sessions SET sandbox_cleanup_token=NULL,sandbox_cleanup_resource=NULL,
    sandbox_cleanup_started_at=NULL WHERE id=p_id AND site_id=p_site_id AND sandbox_cleanup_token=p_token;
  RETURN FOUND;
END;
$$;

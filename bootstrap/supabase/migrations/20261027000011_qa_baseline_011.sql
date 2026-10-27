SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: apply_paid_subscription_credit_coverage(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_paid_subscription_credit_coverage(p_invoice jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  b public.billing%ROWTYPE; w record; r jsonb;
  v_site uuid := (p_invoice->>'site_id')::uuid;
  v_interval text := coalesce(p_invoice->>'billing_interval','month');
  v_start timestamptz := (p_invoice->>'period_start')::timestamptz;
  v_end timestamptz := (p_invoice->>'period_end')::timestamptz;
  v_allowance numeric := public.site_plan_credit_allowance(p_invoice->>'plan',(p_invoice->>'addons_count')::integer);
  v_source text := 'stripe_invoice:' || (p_invoice->>'invoice_id');
  v_anchor timestamptz;
  v_remaining numeric; v_delta numeric;
BEGIN
  IF v_interval NOT IN ('month','year') OR v_start IS NULL OR v_end IS NULL
    OR NOT isfinite(v_start) OR NOT isfinite(v_end) OR v_start > now() OR v_end <= now()
    OR (p_invoice->>'billing_reason' = 'subscription_update'
      AND coalesce((p_invoice->>'coverage_verified')::boolean,false) IS NOT TRUE)
  THEN RAISE EXCEPTION 'Invalid verified paid coverage'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id = v_site FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Invoice site has no billing record'; END IF;
  IF b.paid_subscription_period_start > v_start
    OR b.paid_subscription_paid_at > (p_invoice->>'paid_at')::timestamptz THEN
    RETURN jsonb_build_object('success',true,'outcome','stale_period','credits_granted',0);
  END IF;
  IF b.paid_subscription_period_start = v_start AND b.paid_subscription_period_end >= v_end
    AND p_invoice->>'billing_reason' <> 'subscription_update' THEN
    RETURN jsonb_build_object('success',true,'outcome','not_due','credits_granted',0);
  END IF;
  -- Bind identity first: the replacement guard intentionally clears prior coverage.
  UPDATE public.billing SET stripe_subscription_id = p_invoice->>'subscription_id' WHERE id = b.id;
  v_anchor := coalesce(b.plan_credit_anchor,CASE WHEN p_invoice->>'billing_reason' = 'subscription_update'
    THEN b.plan_credit_period_start END,CASE WHEN p_invoice->>'plan' = 'commission'
      AND b.plan_credit_period_end > now() THEN b.plan_credit_period_start END,v_start);
  IF v_interval = 'year' THEN
    SELECT * INTO w FROM public.subscription_monthly_credit_window(v_anchor,v_end,now());
  ELSE
    SELECT v_start AS period_start,v_end AS period_end INTO w;
  END IF;
  IF b.plan_credit_period_end > now() AND ((b.plan_credit_anchor IS NOT NULL
      AND (v_interval = 'year' OR p_invoice->>'billing_reason' = 'subscription_update'
        OR b.paid_subscription_invoice_id IS NULL))
    OR (p_invoice->>'plan' = 'commission' AND b.plan_credit_anchor IS NULL)
    OR (p_invoice->>'billing_reason' = 'subscription_update'
      AND b.plan_credit_source LIKE 'stripe%' AND b.plan_credit_source <> 'stripe_unverified')) THEN
    IF b.paid_subscription_invoice_id IS NOT NULL AND b.paid_subscription_plan IS NOT NULL
      AND b.stripe_subscription_id = p_invoice->>'subscription_id' THEN
      -- Carry only the stored excess, not the previous full quota or remaining
      -- balance. Repeated changes retain this same excess and never refill usage.
      v_allowance := v_allowance + greatest(b.plan_credit_allowance -
        public.site_plan_credit_allowance(b.paid_subscription_plan,b.paid_subscription_addons_count),0);
    END IF;
    v_remaining := greatest(v_allowance-b.plan_credits_used,0);
    v_delta := v_remaining-b.plan_credits_available;
    UPDATE public.billing SET plan_credits_available = v_remaining,
      credits_available = v_remaining+purchased_credits_available+legacy_credits_available,
      plan_credit_allowance = v_allowance,
      plan_credit_period_start = b.plan_credit_period_start,
      plan_credit_period_end = greatest(b.plan_credit_period_end,w.period_end),
      plan_credit_source = v_source WHERE id = b.id;
    INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
      VALUES(v_site,v_delta,'plan_credit_adjustment','Paid plan change retaining current usage',
        jsonb_build_object('credit_bucket','plan','source',v_source,'plan_credits_used',b.plan_credits_used));
    -- payments.credits records integer reset grants; the adjustment stays in the ledger.
    r := jsonb_build_object('success',true,'outcome','adjusted','credits_granted',0);
  ELSE
    r := public.reset_site_plan_credit_period(v_site,w.period_start,w.period_end,v_allowance,v_source);
  END IF;
  IF r->>'outcome' <> 'stale_period' THEN
    UPDATE public.billing SET plan = p_invoice->>'plan',addons_count = (p_invoice->>'addons_count')::integer,
      billing_interval = v_interval,paid_subscription_period_start = v_start,paid_subscription_period_end = v_end,
      paid_subscription_invoice_id = p_invoice->>'invoice_id',paid_subscription_plan = p_invoice->>'plan',
      paid_subscription_paid_at = (p_invoice->>'paid_at')::timestamptz,
      plan_credit_anchor = v_anchor,
      paid_subscription_addons_count = (p_invoice->>'addons_count')::integer WHERE id = b.id;
  END IF;
  RETURN r;
END;
$$;


--
-- Name: apply_pending_requirement_commands(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_pending_requirement_commands() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE r public.requirements%ROWTYPE; mapping public.harness_requirement_runs%ROWTYPE;
  session public.harness_sessions%ROWTYPE; owner public.remote_instances%ROWTYPE;
  command record; patch jsonb; action_status text; applied_ids uuid[]; assignments text; generation integer;
  t timestamptz:=clock_timestamp();
BEGIN
  FOR r IN SELECT q.* FROM public.requirements q
    WHERE EXISTS (SELECT 1 FROM public.requirement_commands c WHERE c.requirement_id=q.id AND c.applied_at IS NULL)
      AND (SELECT a.details->>'status' FROM public.requirement_commands c JOIN public.instance_logs a ON a.id=c.action_id
        WHERE c.requirement_id=q.id AND c.applied_at IS NULL ORDER BY c.revision LIMIT 1) IN ('completed','failed')
      AND (q.cron_lock_expires_at IS NULL OR q.cron_lock_expires_at<=t)
      AND q.status NOT IN ('cancelled','canceled')
      AND (q.metadata IS NULL OR jsonb_typeof(q.metadata)='object')
      AND NOT coalesce(q.metadata ? 'execution_hold',false)
      AND coalesce(q.metadata->>'user_paused','false')<>'true'
      AND coalesce(q.metadata->>'customer_paused','false')<>'true'
      AND coalesce(q.metadata->>'cron_paused','false')<>'true'
      AND NOT (q.status='blocked' AND EXISTS (SELECT 1 FROM public.harness_requirement_runs h
        WHERE h.requirement_id=q.id AND h.pause_reason IS NOT NULL
          AND (h.pause_reason IN ('token_budget_exhausted','account_credits_exhausted','turn_budget_exhausted','active_time_budget_exhausted')
            OR NOT EXISTS (SELECT 1 FROM public.harness_sessions resumed WHERE resumed.id=h.session_id
              AND resumed.site_id=q.site_id AND resumed.snapshot->>'status'='queued'))))
      AND NOT EXISTS (SELECT 1 FROM public.harness_requirement_runs h JOIN public.harness_sessions s ON s.id=h.session_id
        WHERE h.requirement_id=q.id AND (s.lease_expires_at>t OR s.snapshot->>'status' IN ('paused','cancelled')))
      AND NOT EXISTS (SELECT 1 FROM public.remote_instances i WHERE i.site_id=q.site_id
        AND i.id::text IN (q.metadata->>'runner_instance_id',q.metadata->>'assistant_origin_instance_id')
        AND i.status IN ('paused','stopped','stopping'))
      AND NOT EXISTS (SELECT 1 FROM public.instance_plans p WHERE p.site_id=q.site_id AND p.status='paused'
        AND (p.metadata->>'requirement_id'=q.id::text OR p.instance_id::text IN
          (q.metadata->>'runner_instance_id',q.metadata->>'assistant_origin_instance_id')))
    ORDER BY q.updated_at,q.id LIMIT 100 FOR UPDATE OF q SKIP LOCKED
  LOOP
    SELECT * INTO mapping FROM public.harness_requirement_runs WHERE requirement_id=r.id FOR UPDATE;
    IF FOUND THEN
      SELECT * INTO session FROM public.harness_sessions WHERE id=mapping.session_id FOR UPDATE;
      IF r.status='blocked' AND mapping.pause_reason IS NOT NULL AND (
        mapping.pause_reason IN ('token_budget_exhausted','account_credits_exhausted','turn_budget_exhausted','active_time_budget_exhausted')
        OR session.site_id IS DISTINCT FROM r.site_id OR session.snapshot->>'status' IS DISTINCT FROM 'queued') THEN CONTINUE; END IF;
      IF FOUND AND (session.lease_expires_at>clock_timestamp() OR session.snapshot->>'status' IN ('paused','cancelled')) THEN CONTINUE; END IF;
    END IF;
    owner:=NULL;
    FOR owner IN SELECT i.* FROM public.remote_instances i WHERE i.site_id=r.site_id
      AND i.id::text IN (r.metadata->>'runner_instance_id',r.metadata->>'assistant_origin_instance_id') ORDER BY i.id FOR UPDATE
    LOOP
      IF owner.status IN ('paused','stopped','stopping') THEN EXIT; END IF;
    END LOOP;
    IF owner.status IN ('paused','stopped','stopping') THEN CONTINUE; END IF;
    IF EXISTS (SELECT 1 FROM public.instance_plans p WHERE p.site_id=r.site_id AND p.status='paused'
      AND (p.metadata->>'requirement_id'=r.id::text OR p.instance_id::text IN
        (r.metadata->>'runner_instance_id',r.metadata->>'assistant_origin_instance_id'))) THEN CONTINUE; END IF;
    generation:=0;
    IF r.metadata ? 'requirement_execution_generation' THEN
      IF coalesce(r.metadata->>'requirement_execution_generation','') !~ '^[0-9]{1,9}$' THEN CONTINUE; END IF;
      generation:=(r.metadata->>'requirement_execution_generation')::integer;
      IF generation>=999999999 THEN CONTINUE; END IF;
    END IF;
    patch:='{}'::jsonb; applied_ids:='{}'::uuid[];
    FOR command IN SELECT c.* FROM public.requirement_commands c
      WHERE c.requirement_id=r.id AND c.applied_at IS NULL ORDER BY c.revision FOR UPDATE
    LOOP
      SELECT a.details->>'status' INTO action_status FROM public.instance_logs a WHERE a.id=command.action_id FOR SHARE;
      IF NOT FOUND OR coalesce(action_status,'') NOT IN ('completed','failed') THEN EXIT; END IF;
      patch:=patch||command.patch; applied_ids:=array_append(applied_ids,command.action_id);
    END LOOP;
    IF cardinality(applied_ids)=0 THEN CONTINUE; END IF;
    SELECT string_agg(format('%I = (jsonb_populate_record(q, $1)).%I',key,key),', ' ORDER BY key)
      INTO assignments FROM jsonb_object_keys(patch-ARRAY['status','completion_status']) key;
    IF assignments IS NOT NULL THEN assignments:=assignments||', '; ELSE assignments:=''; END IF;
    EXECUTE 'UPDATE public.requirements q SET '||assignments||
      'status = ''in-progress'', completion_status = ''pending'', updated_at = $2, '||
      'metadata = coalesce(q.metadata, ''{}''::jsonb) || jsonb_build_object(''requirement_execution_generation'', $3), '||
      'cron_lock_run_id = NULL, cron_lock_expires_at = NULL, cron_lock_active = false WHERE q.id = $4'
      USING patch,clock_timestamp(),generation+1,r.id;
    UPDATE public.requirement_commands SET applied_at=clock_timestamp() WHERE requirement_id=r.id AND action_id=ANY(applied_ids);
  END LOOP;
END;
$_$;


--
-- Name: apply_recovered_requirement_commands(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_recovered_requirement_commands(p_id uuid, p_patch jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE assignments text; generation integer;
BEGIN
  SELECT (metadata->>'requirement_execution_generation')::integer INTO generation
    FROM public.requirements WHERE id=p_id FOR UPDATE;
  IF generation IS NULL OR generation<0 OR generation>=999999999 THEN
    RAISE EXCEPTION 'Invalid recovery generation' USING ERRCODE='22023';
  END IF;
  SELECT string_agg(format('%I = (jsonb_populate_record(q, $1)).%I',key,key),', ' ORDER BY key)
    INTO assignments FROM jsonb_object_keys(p_patch-ARRAY['status','completion_status']) key;
  IF assignments IS NOT NULL THEN assignments:=assignments||', '; ELSE assignments:=''; END IF;
  EXECUTE 'UPDATE public.requirements q SET '||assignments||
    'status = ''in-progress'', completion_status = ''pending'', updated_at = clock_timestamp(), '||
    'metadata = coalesce(q.metadata, ''{}''::jsonb) || jsonb_build_object(''requirement_execution_generation'', $2), '||
    'cron_lock_run_id = NULL, cron_lock_expires_at = NULL, cron_lock_active = false WHERE q.id = $3'
    USING p_patch,generation+1,p_id;
  UPDATE public.requirement_commands SET applied_at=clock_timestamp() WHERE requirement_id=p_id AND applied_at IS NULL;
END;
$_$;


--
-- Name: apply_self_service_line_inventory(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_self_service_line_inventory() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE o public.sale_orders%ROWTYPE; prior public.self_service_inventory_releases%ROWTYPE;
  delta numeric; policy text; tracked boolean;
BEGIN
  SELECT * INTO o FROM public.sale_orders WHERE id=NEW.sale_order_id FOR UPDATE;
  IF NOT public.is_self_service_order_items(o.items) THEN RETURN NEW; END IF;
  SELECT * INTO prior FROM public.self_service_inventory_releases WHERE sale_order_item_id=NEW.id FOR UPDATE;
  IF FOUND AND ROW(prior.catalog_item_id,prior.location_id,prior.site_id,prior.sale_order_id)
    IS DISTINCT FROM ROW(NEW.catalog_item_id,o.origin_location_id,NEW.site_id,NEW.sale_order_id) THEN
    RAISE EXCEPTION 'Released self-service inventory identity is immutable' USING ERRCODE='42501';
  END IF;
  IF NEW.status IN ('draft','cancelled') THEN RETURN NEW; END IF;
  IF NEW.quantity IS NULL OR NEW.quantity < 0 OR NEW.quantity::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Invalid self-service quantity' USING ERRCODE='22023';
  END IF;
  IF o.origin_location_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.locations WHERE id=o.origin_location_id AND site_id=o.site_id
  ) THEN RAISE EXCEPTION 'Self-service inventory location mismatch' USING ERRCODE='42501'; END IF;
  delta := greatest(0,NEW.quantity-coalesce(prior.quantity,0));
  SELECT coalesce(commerce->>'decrement_stock_on','ship') INTO policy FROM public.settings WHERE site_id=o.site_id LIMIT 1;
  IF NEW.catalog_item_id IS NOT NULL THEN
    SELECT track_inventory INTO tracked FROM public.catalog_items WHERE id=NEW.catalog_item_id AND site_id=o.site_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Self-service inventory item mismatch' USING ERRCODE='42501'; END IF;
  END IF;
  IF delta > 0 AND tracked AND coalesce(policy,'ship') <> 'never' THEN
    INSERT INTO public.inventory_levels AS level (site_id,catalog_item_id,location_id,quantity,updated_at)
      VALUES (o.site_id,NEW.catalog_item_id,o.origin_location_id,0,now())
    ON CONFLICT (catalog_item_id,location_id) DO UPDATE SET
      quantity=greatest(0,level.quantity-delta),updated_at=now()
      WHERE level.site_id=o.site_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Self-service inventory tenant mismatch' USING ERRCODE='42501'; END IF;
  END IF;
  INSERT INTO public.self_service_inventory_releases
    (sale_order_item_id,sale_order_id,site_id,catalog_item_id,location_id,quantity)
    VALUES (NEW.id,o.id,o.site_id,NEW.catalog_item_id,o.origin_location_id,NEW.quantity)
    ON CONFLICT (sale_order_item_id) DO UPDATE SET
      quantity=greatest(self_service_inventory_releases.quantity,excluded.quantity),updated_at=now();
  RETURN NEW;
END;
$$;


--
-- Name: apply_site_partner_license(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_site_partner_license(p_license_key uuid, p_site_id uuid, p_actor_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  partner_record public.partner_licenses%ROWTYPE;
  billing_record public.billing%ROWTYPE;
  target_plan text;
BEGIN
  IF p_actor_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.sites s WHERE s.id = p_site_id AND s.archived_at IS NULL AND (
      s.user_id = p_actor_id OR EXISTS (SELECT 1 FROM public.site_members sm
        WHERE sm.site_id = s.id AND sm.user_id = p_actor_id AND sm.status = 'active'
          AND public.site_member_has_effective_license(sm.id) AND (sm.role IN ('owner','admin') OR EXISTS (
            SELECT 1 FROM public.site_ownership so WHERE so.site_id = s.id AND so.user_id = p_actor_id)))
    )
  ) THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Partner license site access denied'; END IF;
  PERFORM public.lock_site_license(p_site_id);
  -- Recheck after taking the site lock: a concurrent license expiry/ownership transfer
  -- must not authorize a stale manager decision.
  IF NOT EXISTS (
    SELECT 1 FROM public.sites s WHERE s.id = p_site_id AND s.archived_at IS NULL AND (
      s.user_id = p_actor_id OR EXISTS (SELECT 1 FROM public.site_members sm
        WHERE sm.site_id = s.id AND sm.user_id = p_actor_id AND sm.status = 'active'
          AND public.site_member_has_effective_license(sm.id) AND (sm.role IN ('owner','admin') OR EXISTS (
            SELECT 1 FROM public.site_ownership so WHERE so.site_id = s.id AND so.user_id = p_actor_id)))
    )
  ) THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Partner license site access denied'; END IF;
  SELECT * INTO partner_record FROM public.partner_licenses WHERE license_key = p_license_key FOR UPDATE;
  IF NOT FOUND OR partner_record.user_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Partner license ownership denied';
  END IF;
  IF partner_record.status IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Partner license is not active';
  END IF;
  IF partner_record.site_id IS NOT NULL AND partner_record.site_id <> p_site_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'PARTNER_LICENSE_LINKED';
  END IF;
  SELECT * INTO billing_record FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'PARTNER_BILLING_MISSING'; END IF;
  IF billing_record.stripe_subscription_id IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'PARTNER_STRIPE_CONFLICT';
  END IF;
  target_plan := CASE WHEN lower(coalesce(partner_record.plan_name,'')) LIKE '%foundry%'
    OR lower(coalesce(partner_record.plan_name,'')) LIKE '%tier 2%'
    OR lower(coalesce(partner_record.plan_name,'')) LIKE '%tier2%' THEN 'foundry' ELSE 'engine' END;
  UPDATE public.partner_licenses SET site_id = p_site_id WHERE id = partner_record.id AND user_id = p_actor_id;
  -- Existing financial triggers own credit bucket transitions. Never touch balances.
  UPDATE public.billing SET plan = target_plan,subscription_status = 'active',auto_renew = false,updated_at = now()
    WHERE id = billing_record.id;
  RETURN jsonb_build_object('success',true,'plan',target_plan);
END;
$$;

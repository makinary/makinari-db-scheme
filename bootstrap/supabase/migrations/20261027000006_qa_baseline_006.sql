SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: original_4296761(uuid, uuid, uuid, text, text, text, numeric, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4296761(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  actor uuid := auth.uid();
  snapshot jsonb;
  payload jsonb;
  prior public.lead_invoice_payment_requests%ROWTYPE;
  invoice public.sales%ROWTYPE;
  total numeric;
  remaining numeric;
  received numeric;
  applied numeric;
  next_status text;
  allocations jsonb := '[]'::jsonb;
  result jsonb;
  receipt_time timestamptz := clock_timestamp();
BEGIN
  -- Authentication and lead visibility are checked even on idempotent replay.
  snapshot := public.lead_open_invoice_snapshot(p_site_id, p_lead_id);
  IF p_request_id IS NULL OR p_version IS NULL OR p_version !~ '^[a-f0-9]{32}$'
    OR p_currency IS NULL OR p_currency !~ '^[A-Z]{3}$'
    OR p_mode IS NULL OR p_mode NOT IN ('full', 'partial')
    OR p_method IS NULL OR p_method NOT IN ('credit_card','debit_card','bank_transfer','cash',
      'check','paypal','stripe','venmo','zelle','crypto','wire_transfer')
    OR length(coalesce(p_notes, '')) > 2000
    OR (p_mode = 'partial' AND (p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity')
      OR p_amount <= 0 OR p_amount > 999999999999 OR p_amount <> trunc(p_amount, 2))) THEN
    RAISE EXCEPTION 'Invalid invoice payment' USING ERRCODE = '22023';
  END IF;
  payload := jsonb_build_object('siteId', p_site_id, 'leadId', p_lead_id,
    'version', p_version, 'currency', p_currency, 'mode', p_mode,
    'amount', CASE WHEN p_mode = 'partial' THEN p_amount ELSE NULL END,
    'method', p_method, 'notes', btrim(coalesce(p_notes, '')));

  -- Serialize payments for one lead, including retries and new invoice inserts
  -- referencing that lead. Other invoice writers serialize on their sale rows.
  PERFORM 1 FROM public.leads WHERE id = p_lead_id AND site_id = p_site_id FOR UPDATE;
  SELECT * INTO prior FROM public.lead_invoice_payment_requests WHERE request_id = p_request_id;
  IF FOUND THEN
    IF prior.actor_id <> actor OR prior.site_id <> p_site_id OR prior.lead_id <> p_lead_id
      OR prior.payload IS DISTINCT FROM payload THEN
      RAISE EXCEPTION 'Payment request already used with different details' USING ERRCODE = '22023';
    END IF;
    RETURN prior.result;
  END IF;

  snapshot := public.lead_open_invoice_snapshot(p_site_id, p_lead_id);
  PERFORM 1 FROM public.sales s WHERE s.id IN (
    SELECT (item->>'id')::uuid FROM jsonb_array_elements(snapshot->'invoices') item
  ) ORDER BY s.id FOR UPDATE;
  snapshot := public.lead_open_invoice_snapshot(p_site_id, p_lead_id);
  IF snapshot->>'version' IS DISTINCT FROM p_version THEN
    RAISE EXCEPTION 'Invoice balances changed' USING ERRCODE = '40001';
  END IF;
  IF EXISTS (SELECT 1 FROM jsonb_array_elements(snapshot->'invoices') item
    WHERE item->>'currency' IS NULL OR item->>'currency' !~ '^[A-Z]{3}$') THEN
    RAISE EXCEPTION 'Invoice currency requires review' USING ERRCODE = '23514';
  END IF;
  SELECT coalesce(sum((item->>'amountDue')::numeric), 0) INTO total
    FROM jsonb_array_elements(snapshot->'invoices') item WHERE item->>'currency' = p_currency;
  received := CASE WHEN p_mode = 'full' THEN total ELSE p_amount END;
  IF received <= 0 OR received > total OR received <> trunc(received, 2) THEN
    RAISE EXCEPTION 'Payment exceeds available invoice balances' USING ERRCODE = '23514';
  END IF;
  remaining := received;
  FOR invoice IN SELECT s.* FROM public.sales s WHERE s.id IN (
    SELECT (item->>'id')::uuid FROM jsonb_array_elements(snapshot->'invoices') item
    WHERE item->>'currency' = p_currency
  ) ORDER BY s.sale_date DESC, s.created_at DESC, s.id DESC LOOP
    EXIT WHEN remaining = 0;
    IF invoice.amount_due <> trunc(invoice.amount_due, 2)
      OR jsonb_typeof(coalesce(invoice.payments, '[]'::jsonb)) <> 'array' THEN
      RAISE EXCEPTION 'Invoice payment history requires review' USING ERRCODE = '23514';
    END IF;
    applied := least(invoice.amount_due, remaining);
    next_status := CASE WHEN invoice.amount_due = applied AND invoice.status = 'pending'
      THEN 'completed' ELSE invoice.status END;
    UPDATE public.sales SET amount_due = invoice.amount_due - applied, status = next_status,
      payment_method = p_method,
      payments = coalesce(invoice.payments, '[]'::jsonb) || jsonb_build_array(jsonb_build_object(
        'id', p_request_id::text || ':' || invoice.id::text, 'request_id', p_request_id,
        'amount', applied, 'currency', p_currency, 'date', receipt_time,
        'method', p_method, 'notes', btrim(coalesce(p_notes, '')), 'recorded_by', actor
      )),
      accounting_state = CASE WHEN invoice.accounting_state = 'unpublished' THEN 'unpublished' ELSE 'pending' END,
      updated_at = clock_timestamp()
    WHERE id = invoice.id AND site_id = p_site_id AND lead_id = p_lead_id;
    allocations := allocations || jsonb_build_array(jsonb_build_object('invoiceId', invoice.id,
      'amount', applied, 'amountDue', invoice.amount_due - applied,
      'previousStatus', invoice.status, 'status', next_status));
    remaining := remaining - applied;
  END LOOP;
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'Invoice allocation incomplete' USING ERRCODE = '40001';
  END IF;
  result := jsonb_build_object('requestId', p_request_id, 'amount', received,
    'currency', p_currency, 'allocations', allocations);
  INSERT INTO public.lead_invoice_payment_requests(request_id, site_id, lead_id, actor_id, payload, result)
    VALUES (p_request_id, p_site_id, p_lead_id, actor, payload, result);
  RETURN result;
END;
$_$;


--
-- Name: original_4320078(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4320078(p_site_id uuid, p_category_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF p_site_id IS NULL OR p_category_id IS NULL THEN
    RAISE EXCEPTION 'Site and category IDs are required' USING ERRCODE = '22023';
  END IF;
  IF auth.uid() IS NULL OR coalesce(public.current_user_site_role(p_site_id), '') NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Only site owners and admins can archive categories' USING ERRCODE = '42501';
  END IF;
  PERFORM public.catalog_archive_lock_site(p_site_id);
  PERFORM c.id FROM public.catalog_categories c
    WHERE c.id = p_category_id AND c.site_id = p_site_id FOR UPDATE NOWAIT;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Catalog category not found' USING ERRCODE = 'P0002';
  END IF;
  -- The trigger is the single cascade authority, including direct status writes
  -- and retries. No caller-controlled session flag or service-role bypass exists.
  UPDATE public.catalog_categories SET status = 'archived'
    WHERE id = p_category_id AND site_id = p_site_id;
  RETURN jsonb_build_object('item_ids', public.catalog_category_archive_item_ids(p_site_id, p_category_id));
END;
$$;


--
-- Name: original_4373681(uuid, uuid, text, numeric, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4373681(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE actor uuid; session public.pos_register_sessions%ROWTYPE; site_currency text;
BEGIN
  actor := public.pos_register_authorize(p_site_id);
  IF p_request_id IS NULL OR p_opening_amount IS NULL OR p_opening_amount < 0
    OR p_opening_amount > 999999999 OR p_opening_amount <> round(p_opening_amount,2)
    OR p_opening_amount::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'A request ID and finite nonnegative opening amount are required' USING ERRCODE = '22023';
  END IF;
  -- Shared location locks prevent tenant reassignment; the location-scoped
  -- advisory lock serializes opens without deadlocking session receipt writers.
  PERFORM 1 FROM public.locations WHERE id = p_location_id AND site_id = p_site_id AND is_active IS TRUE FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'An active same-site location is required' USING ERRCODE = '22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('pos_register_open:' || p_site_id::text || ':' || p_location_id::text,0));
  SELECT * INTO session FROM public.pos_register_sessions WHERE id = p_request_id FOR UPDATE;
  IF FOUND THEN
    IF ROW(session.site_id,session.location_id,session.currency,session.opening_amount,session.opened_by)
      IS DISTINCT FROM ROW(p_site_id,p_location_id,p_currency,p_opening_amount,actor) THEN
      RAISE EXCEPTION 'Register open request ID conflict' USING ERRCODE = '23505';
    END IF;
    RETURN to_jsonb(session);
  END IF;
  SELECT upper(coalesce(currency,'USD')) INTO site_currency FROM public.settings WHERE site_id = p_site_id;
  site_currency := coalesce(site_currency,'USD');
  IF p_currency IS NULL OR p_currency !~ '^[A-Z]{3}$' OR p_currency <> site_currency THEN
    RAISE EXCEPTION 'Register currency must match the site currency' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.pos_register_sessions(id,site_id,location_id,currency,opened_by,opening_amount)
    VALUES (p_request_id,p_site_id,p_location_id,site_currency,actor,p_opening_amount) RETURNING * INTO session;
  RETURN to_jsonb(session);
END;
$_$;


--
-- Name: original_4373682(uuid, text, numeric, text, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4373682(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.pos_register_sessions%ROWTYPE; movement public.pos_register_movements%ROWTYPE; actor uuid;
BEGIN
  SELECT * INTO session FROM public.pos_register_sessions WHERE id = p_session_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Register session not found' USING ERRCODE = '22023'; END IF;
  actor := public.pos_register_authorize(session.site_id,session.opened_by);
  IF p_request_id IS NULL OR p_kind IS NULL OR p_kind NOT IN ('cash_in','cash_out','cash_refund')
    OR p_amount IS NULL OR p_amount <= 0 OR p_amount > 999999999 OR p_amount <> round(p_amount,2)
    OR p_amount::text IN ('NaN','Infinity','-Infinity')
    OR p_reason IS NULL OR length(btrim(p_reason)) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'A valid kind, positive finite amount, reason and request ID are required' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO movement FROM public.pos_register_movements WHERE site_id = session.site_id AND request_id = p_request_id;
  IF FOUND THEN
    IF ROW(movement.session_id,movement.kind,movement.amount,movement.reason,movement.actor_id)
      IS DISTINCT FROM ROW(p_session_id,p_kind,p_amount,btrim(p_reason),actor) THEN
      RAISE EXCEPTION 'Register movement request ID conflict' USING ERRCODE = '23505';
    END IF;
    RETURN to_jsonb(movement);
  END IF;
  IF session.status <> 'open' THEN RAISE EXCEPTION 'Register session is closed' USING ERRCODE = '23514'; END IF;
  INSERT INTO public.pos_register_movements(session_id,site_id,kind,amount,reason,actor_id,request_id)
    VALUES (session.id,session.site_id,p_kind,p_amount,btrim(p_reason),actor,p_request_id) RETURNING * INTO movement;
  RETURN to_jsonb(movement);
END;
$$;


--
-- Name: original_4373683(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4373683(p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.pos_register_sessions%ROWTYPE; cash_received numeric; total_received numeric;
  cash_in numeric; cash_out numeric; cash_refunds numeric; receipt_count bigint;
  payment_totals jsonb; movements jsonb; receipts jsonb;
BEGIN
  -- All receipt/movement writers acquire FOR UPDATE on this row. A shared lock
  -- gives one coherent summary, independent of the sale's date or current totals.
  SELECT * INTO session FROM public.pos_register_sessions WHERE id = p_session_id FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Register session not found' USING ERRCODE = '22023'; END IF;
  PERFORM public.pos_register_authorize(session.site_id);
  IF session.status = 'closed' THEN RETURN session.snapshot; END IF;
  SELECT coalesce(sum(amount) FILTER (WHERE method = 'cash'),0), coalesce(sum(amount),0), count(*),
    coalesce(jsonb_agg(to_jsonb(r) ORDER BY received_at,id),'[]'::jsonb)
    INTO cash_received,total_received,receipt_count,receipts FROM public.pos_register_receipts r WHERE session_id = session.id;
  SELECT coalesce(jsonb_object_agg(method,total),'{}'::jsonb) INTO payment_totals FROM (
    SELECT method,sum(amount) total FROM public.pos_register_receipts WHERE session_id = session.id GROUP BY method
  ) totals;
  SELECT coalesce(sum(amount) FILTER (WHERE kind = 'cash_in'),0),
    coalesce(sum(amount) FILTER (WHERE kind = 'cash_out'),0),
    coalesce(sum(amount) FILTER (WHERE kind = 'cash_refund'),0),
    coalesce(jsonb_agg(to_jsonb(m) ORDER BY created_at,id),'[]'::jsonb)
    INTO cash_in,cash_out,cash_refunds,movements FROM public.pos_register_movements m WHERE session_id = session.id;
  RETURN jsonb_build_object('opening_amount',session.opening_amount,'cash_received',cash_received,
    'cash_in',cash_in,'cash_out',cash_out,'cash_refunds',cash_refunds,
    'expected_amount',session.opening_amount + cash_received + cash_in - cash_out - cash_refunds,
    'total_received',total_received,'payment_totals',payment_totals,'receipt_count',receipt_count,
    'movements',movements,'receipts',receipts);
END;
$$;


--
-- Name: original_4373684(uuid, numeric, text, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4373684(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.pos_register_sessions%ROWTYPE; actor uuid; summary jsonb;
BEGIN
  SELECT * INTO session FROM public.pos_register_sessions WHERE id = p_session_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Register session not found' USING ERRCODE = '22023'; END IF;
  actor := public.pos_register_authorize(session.site_id,session.opened_by);
  IF p_request_id IS NULL OR p_counted_amount IS NULL OR p_counted_amount < 0
    OR p_counted_amount > 999999999 OR p_counted_amount <> round(p_counted_amount,2)
    OR p_counted_amount::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'A request ID and finite nonnegative counted amount are required' USING ERRCODE = '22023';
  END IF;
  IF p_notes IS NULL OR length(p_notes) > 2000 THEN
    RAISE EXCEPTION 'Register close notes must be text with at most 2000 characters' USING ERRCODE = '22023';
  END IF;
  IF session.status = 'closed' THEN
    IF ROW(session.close_request_id,session.counted_amount,session.notes,session.closed_by)
      IS DISTINCT FROM ROW(p_request_id,p_counted_amount,p_notes,actor) THEN
      RAISE EXCEPTION 'Register close request ID conflict' USING ERRCODE = '23505';
    END IF;
    RETURN to_jsonb(session);
  END IF;
  summary := public.pos_register_summary(session.id);
  UPDATE public.pos_register_sessions SET status = 'closed', closed_by = actor, closed_at = clock_timestamp(),
    counted_amount = p_counted_amount, expected_amount = (summary->>'expected_amount')::numeric,
    difference = p_counted_amount - (summary->>'expected_amount')::numeric,
    notes = p_notes, close_request_id = p_request_id, snapshot = summary WHERE id = session.id RETURNING * INTO session;
  RETURN to_jsonb(session);
END;
$$;


--
-- Name: original_4379393(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4379393(p_plan_id uuid, p_instance_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    SET lock_timeout TO '5s'
    AS $$
DECLARE
  plan public.instance_plans%ROWTYPE;
  instance public.remote_instances%ROWTYPE;
  ids uuid[];
  next_steps jsonb;
  mutation_at timestamptz;
  changed integer;
BEGIN
  IF auth.uid() IS NULL OR auth.role() IS DISTINCT FROM 'authenticated' THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'PT401';
  END IF;
  SELECT * INTO plan FROM public.instance_plans WHERE id = p_plan_id AND instance_id = p_instance_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Plan not found' USING ERRCODE = 'PT404'; END IF;
  IF public.current_user_site_role(plan.site_id) IS NULL
    OR public.current_user_site_role(plan.site_id) NOT IN ('owner','admin')
    OR public.user_can(plan.site_id, 'update') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Site owner or administrator update permission required' USING ERRCODE = 'PT403';
  END IF;

  ids := public.robot_instance_requirement_candidates(p_instance_id);
  -- Match worker/deletion lock order: requirements before instance before plan.
  PERFORM 1 FROM public.requirements WHERE id = ANY(ids) ORDER BY id FOR UPDATE;
  SELECT * INTO instance FROM public.remote_instances WHERE id = p_instance_id FOR UPDATE;
  IF NOT FOUND OR instance.site_id IS DISTINCT FROM plan.site_id THEN
    RAISE EXCEPTION 'Plan instance scope changed' USING ERRCODE = 'PT409';
  END IF;
  -- Lock every existing sibling before inspecting sandbox evidence. Updates that
  -- preserve bindings do not acquire the instance lock in the binding trigger.
  -- New inserts/binding changes still fence on the locked real parent instance.
  PERFORM 1 FROM public.instance_plans WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  SELECT * INTO plan FROM public.instance_plans WHERE id = p_plan_id AND instance_id = p_instance_id FOR UPDATE;
  IF NOT FOUND OR plan.site_id IS DISTINCT FROM instance.site_id
    OR ids IS DISTINCT FROM public.robot_instance_requirement_candidates(p_instance_id) THEN
    RAISE EXCEPTION 'Plan requirement scope changed' USING ERRCODE = 'PT409';
  END IF;
  IF public.current_user_site_role(plan.site_id) IS NULL
    OR public.current_user_site_role(plan.site_id) NOT IN ('owner','admin')
    OR public.user_can(plan.site_id, 'update') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Site owner or administrator update permission required' USING ERRCODE = 'PT403';
  END IF;
  -- This is reconciliation, not remote cancellation or inferred lease expiry.
  -- Paused/stopped instances fence new harness/assistant admission under this lock.
  IF COALESCE(instance.status,'') NOT IN ('paused','stopped')
    OR instance.provider_instance_id IS NOT NULL
    OR NULLIF(instance.metadata->>'active_sandbox_id','') IS NOT NULL
    OR NULLIF(instance.metadata->>'sandbox_id','') IS NOT NULL
    OR NULLIF(instance.configuration->>'active_sandbox_id','') IS NOT NULL
    OR NULLIF(instance.configuration->>'sandbox_id','') IS NOT NULL
    OR NULLIF(plan.metadata->>'active_sandbox_id','') IS NOT NULL
    OR NULLIF(plan.metadata->>'sandbox_id','') IS NOT NULL
    OR EXISTS (SELECT 1 FROM public.instance_plans sibling WHERE sibling.instance_id = p_instance_id AND (
      NULLIF(sibling.metadata->>'active_sandbox_id','') IS NOT NULL
      OR NULLIF(sibling.metadata->>'sandbox_id','') IS NOT NULL
      OR EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(sibling.steps) = 'array'
        THEN sibling.steps ELSE '[]'::jsonb END) step WHERE
        NULLIF(step->>'active_sandbox_id','') IS NOT NULL OR NULLIF(step->>'sandbox_id','') IS NOT NULL
        OR NULLIF(step->'metadata'->>'active_sandbox_id','') IS NOT NULL
        OR NULLIF(step->'metadata'->>'sandbox_id','') IS NOT NULL)))
    OR EXISTS (SELECT 1 FROM public.requirements r WHERE r.id = ANY(ids) AND (
      r.site_id IS DISTINCT FROM instance.site_id OR r.cron_lock_active IS TRUE
      OR r.cron_lock_run_id IS NOT NULL OR r.cron_lock_expires_at IS NOT NULL
      OR NULLIF(r.metadata->>'active_sandbox_id','') IS NOT NULL
      OR NULLIF(r.metadata->>'sandbox_id','') IS NOT NULL))
    OR EXISTS (SELECT 1 FROM public.instance_logs WHERE instance_id = p_instance_id
      AND log_type = 'user_action' AND details->>'status' = 'running')
    OR EXISTS (SELECT 1 FROM public.instance_nodes WHERE instance_id = p_instance_id
      AND status IN ('running','in_progress','active'))
    OR EXISTS (SELECT 1 FROM public.workflow_runs WHERE instance_id = p_instance_id
      AND status IN ('pending','in_progress','running','active'))
    OR EXISTS (SELECT 1 FROM public.workflow_triggers WHERE instance_id = p_instance_id AND enabled IS TRUE)
    OR EXISTS (SELECT 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = ANY(ids)
      AND state IN ('running','followup_reviewing'))
    OR EXISTS (SELECT 1 FROM public.requirement_status s WHERE s.requirement_id = ANY(ids)
      AND s.stage IN ('in-progress','running','active') AND NULLIF(s.active_sandbox_id,'') IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.requirement_status newer WHERE newer.requirement_id = s.requirement_id
        AND (newer.updated_at, newer.id) > (s.updated_at, s.id)))
    OR EXISTS (SELECT 1 FROM public.harness_requirement_runs h JOIN public.harness_sessions s ON s.id = h.session_id
      WHERE h.requirement_id = ANY(ids) AND (s.snapshot->>'status' IN ('queued','running')
        OR s.lease_owner IS NOT NULL OR s.lease_expires_at IS NOT NULL)) THEN
    RAISE EXCEPTION 'Stop and reconcile execution before cancelling the plan' USING ERRCODE = 'PT409';
  END IF;
  IF plan.status NOT IN ('pending','in_progress','paused','blocked','cancelled')
    OR plan.metadata->>'workflow_template' = 'true'
    OR plan.metadata->>'workflow_run' = 'true'
    OR (plan.steps IS NOT NULL AND jsonb_typeof(plan.steps) IS DISTINCT FROM 'array') THEN
    RAISE EXCEPTION 'Plan cannot be cancelled through this operation' USING ERRCODE = 'PT409';
  END IF;
  IF EXISTS (SELECT 1 FROM jsonb_array_elements(COALESCE(plan.steps,'[]'::jsonb)) s WHERE
    jsonb_typeof(s) IS DISTINCT FROM 'object' OR s->>'status' IS NULL
    OR s->>'status' NOT IN ('pending','in_progress','in-progress','running','active','paused','blocked',
      'completed','failed','cancelled','canceled','skipped')
    OR NULLIF(s->>'active_sandbox_id','') IS NOT NULL OR NULLIF(s->>'sandbox_id','') IS NOT NULL
    OR NULLIF(s->'metadata'->>'active_sandbox_id','') IS NOT NULL
    OR NULLIF(s->'metadata'->>'sandbox_id','') IS NOT NULL) THEN
    RAISE EXCEPTION 'Plan steps require execution reconciliation' USING ERRCODE = 'PT409';
  END IF;
  mutation_at := clock_timestamp();
  SELECT COALESCE(jsonb_agg(CASE WHEN s.value->>'status' IN
    ('pending','in_progress','in-progress','running','active','paused','blocked') THEN
      s.value || jsonb_build_object('status','cancelled','cancelled_at',mutation_at,
        'cancellation_reason','Cancelled by project manager') ELSE s.value END ORDER BY s.ordinality),'[]'::jsonb),
    count(*) FILTER (WHERE s.value->>'status' IN
      ('pending','in_progress','in-progress','running','active','paused','blocked'))::integer
  INTO next_steps, changed FROM jsonb_array_elements(COALESCE(plan.steps,'[]'::jsonb))
    WITH ORDINALITY s(value,ordinality);
  IF plan.status <> 'cancelled' OR changed > 0
    OR plan.completion_reason IS DISTINCT FROM 'Cancelled by project manager' THEN
    UPDATE public.instance_plans SET status = 'cancelled', steps = next_steps,
      completed_at = COALESCE(completed_at,mutation_at),
      completion_reason = 'Cancelled by project manager', updated_at = mutation_at
    WHERE id = p_plan_id AND instance_id = p_instance_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Plan cancellation not confirmed' USING ERRCODE = 'PT409'; END IF;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.instance_plans WHERE id = p_plan_id
    AND instance_id = p_instance_id AND site_id = instance.site_id AND status = 'cancelled'
    AND completion_reason = 'Cancelled by project manager' AND steps IS NOT DISTINCT FROM next_steps) THEN
    RAISE EXCEPTION 'Plan cancellation receipt mismatch' USING ERRCODE = 'PT409';
  END IF;
  RETURN jsonb_build_object('plan_id',p_plan_id,'instance_id',p_instance_id,
    'status','cancelled','steps_cancelled',changed);
END;
$$;

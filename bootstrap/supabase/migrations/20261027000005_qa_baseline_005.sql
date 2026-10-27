SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: original_4249999(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4249999(p_site_id uuid, p_entry_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE entry_key text; source_kind text;
BEGIN
  IF p_site_id IS NULL OR p_entry_id IS NULL OR (auth.role() IS DISTINCT FROM 'service_role'
    AND (auth.uid() IS NULL OR NOT public.user_can(p_site_id, 'delete'))) THEN
    RAISE EXCEPTION 'Journal deletion is not authorized' USING ERRCODE = '42501';
  END IF;
  SELECT idempotency_key INTO entry_key FROM public.journal_entries WHERE id = p_entry_id AND site_id = p_site_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Journal not found' USING ERRCODE = 'P0002'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('accounting:journal:' || p_site_id::text || ':' || entry_key, 0));
  SELECT source_type INTO source_kind FROM public.journal_entries
    WHERE id = p_entry_id AND site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Journal not found' USING ERRCODE = 'P0002'; END IF;
  IF source_kind <> 'manual' THEN
    RAISE EXCEPTION 'Only manual journals can be deleted here' USING ERRCODE = '42501';
  END IF;
  DELETE FROM public.journal_lines WHERE entry_id = p_entry_id;
  DELETE FROM public.journal_entries WHERE id = p_entry_id AND site_id = p_site_id;
END;
$$;


--
-- Name: original_4250037(uuid, uuid, timestamp with time zone, jsonb, jsonb); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4250037(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  previous public.purchases%ROWTYPE; replacement public.purchases%ROWTYPE;
  item jsonb; payment jsonb; quantity numeric; unit_cost numeric; subtotal numeric;
  total numeric := 0; paid numeric := 0; payment_amount numeric; catalog_id uuid; matched uuid;
  recorded_paid numeric := 0; implicit_paid numeric;
BEGIN
  IF p_site_id IS NULL OR p_purchase_id IS NULL OR (auth.role() IS DISTINCT FROM 'service_role'
    AND (auth.uid() IS NULL OR NOT public.user_can(p_site_id, 'update'))) THEN
    RAISE EXCEPTION 'Purchase update is not authorized' USING ERRCODE = '42501';
  END IF;
  IF p_expected_updated_at IS NULL OR NOT isfinite(p_expected_updated_at)
    OR jsonb_typeof(p_items) IS DISTINCT FROM 'array' OR jsonb_typeof(p_update) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid purchase update' USING ERRCODE = '22023';
  END IF;
  IF jsonb_array_length(p_items) NOT BETWEEN 1 AND 5000 OR EXISTS (
    SELECT 1 FROM jsonb_object_keys(p_update) k
    WHERE k NOT IN ('title','vendor_company_id','status','currency','purchase_date','due_date','location_id','notes')
  ) THEN
    RAISE EXCEPTION 'Invalid item count or purchase update fields' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO previous FROM public.purchases WHERE id = p_purchase_id AND site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Purchase not found in this site' USING ERRCODE = 'P0002'; END IF;
  IF previous.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION 'Purchase changed; reload before saving' USING ERRCODE = '40001';
  END IF;
  SELECT * INTO replacement FROM jsonb_populate_record(previous, p_update);
  IF replacement.title IS NULL OR length(btrim(replacement.title)) NOT BETWEEN 1 AND 200
    OR replacement.status IS NULL OR replacement.status NOT IN ('draft','pending','completed','cancelled')
    OR replacement.currency IS NULL OR replacement.currency !~ '^[A-Z]{3}$'
    OR replacement.purchase_date IS NULL OR NOT isfinite(replacement.purchase_date)
    OR (replacement.due_date IS NOT NULL AND (NOT isfinite(replacement.due_date)
      OR replacement.due_date < DATE '0001-01-01' OR replacement.due_date > DATE '9999-12-31'))
    OR coalesce(length(replacement.notes), 0) > 10000 THEN
    RAISE EXCEPTION 'Invalid purchase header' USING ERRCODE = '22023';
  END IF;
  IF replacement.location_id IS NOT NULL THEN
    SELECT id INTO matched FROM public.locations WHERE id = replacement.location_id AND site_id = p_site_id FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Purchase location not found in this site' USING ERRCODE = '23514'; END IF;
  END IF;
  IF replacement.vendor_company_id IS NOT NULL THEN
    -- Vendors use the shared global company registry, not a nonexistent site_id.
    SELECT id INTO matched FROM public.companies WHERE id = replacement.vendor_company_id FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Purchase vendor not found' USING ERRCODE = '23514'; END IF;
  END IF;
  FOR item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    IF jsonb_typeof(item) IS DISTINCT FROM 'object' OR jsonb_typeof(item->'quantity') IS DISTINCT FROM 'number'
      OR jsonb_typeof(item->'unit_cost') IS DISTINCT FROM 'number'
      OR jsonb_typeof(item->'name') IS DISTINCT FROM 'string'
      OR length(btrim(item->>'name')) NOT BETWEEN 1 AND 500 THEN
      RAISE EXCEPTION 'Invalid purchase item' USING ERRCODE = '22023';
    END IF;
    quantity := (item->>'quantity')::numeric;
    unit_cost := (item->>'unit_cost')::numeric;
    IF NOT (quantity > 0 AND quantity <= 1000000000) OR quantity <> trunc(quantity, 6)
      OR unit_cost NOT BETWEEN 0 AND 1000000000000 OR unit_cost <> trunc(unit_cost, 2) THEN
      RAISE EXCEPTION 'Invalid purchase item quantity or unit cost' USING ERRCODE = '22023';
    END IF;
    subtotal := round(quantity * unit_cost, 2);
    IF item ? 'subtotal' AND (jsonb_typeof(item->'subtotal') IS DISTINCT FROM 'number'
      OR (item->>'subtotal')::numeric IS DISTINCT FROM subtotal) THEN
      RAISE EXCEPTION 'Purchase item subtotal does not match quantity and cost' USING ERRCODE = '22023';
    END IF;
    total := total + subtotal;
    IF total > 1000000000000 THEN RAISE EXCEPTION 'Purchase total exceeds the supported amount' USING ERRCODE = '22023'; END IF;
    catalog_id := (item->>'catalog_item_id')::uuid;
    IF catalog_id IS NOT NULL THEN
      SELECT id INTO matched FROM public.catalog_items WHERE id = catalog_id AND site_id = p_site_id FOR SHARE;
      IF NOT FOUND THEN RAISE EXCEPTION 'Purchase catalog item not found in this site' USING ERRCODE = '23514'; END IF;
    END IF;
  END LOOP;
  IF previous.amount IS NULL OR previous.amount NOT BETWEEN 0 AND 1000000000000
    OR previous.amount_due IS NULL OR previous.amount_due NOT BETWEEN 0 AND previous.amount
    OR previous.amount <> trunc(previous.amount, 2) OR previous.amount_due <> trunc(previous.amount_due, 2) THEN
    RAISE EXCEPTION 'Existing purchase balances require review' USING ERRCODE = '23514';
  END IF;
  IF previous.payments IS NOT NULL AND jsonb_typeof(previous.payments) <> 'null' THEN
    IF jsonb_typeof(previous.payments) <> 'array' THEN
      RAISE EXCEPTION 'Purchase payment receipts require review' USING ERRCODE = '23514';
    END IF;
    FOR payment IN SELECT value FROM jsonb_array_elements(previous.payments) LOOP
      IF coalesce(payment->>'amount', '') !~ '^[0-9]+([.][0-9]+)?$' THEN
        RAISE EXCEPTION 'Purchase payment amount requires review' USING ERRCODE = '23514';
      END IF;
      payment_amount := (payment->>'amount')::numeric;
      IF payment_amount > 1000000000000 OR payment_amount <> trunc(payment_amount, 2) THEN
        RAISE EXCEPTION 'Invalid purchase payment amount' USING ERRCODE = '23514';
      END IF;
      recorded_paid := recorded_paid + payment_amount;
    END LOOP;
  END IF;
  implicit_paid := previous.amount - previous.amount_due;
  IF implicit_paid > total AND recorded_paid < implicit_paid THEN
    RAISE EXCEPTION 'Legacy purchase payment receipts require review before reducing the total'
      USING ERRCODE = '23514';
  END IF;
  paid := greatest(recorded_paid, implicit_paid);
  DELETE FROM public.purchase_items WHERE purchase_id = p_purchase_id AND site_id = p_site_id;
  FOR item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    INSERT INTO public.purchase_items(purchase_id, site_id, catalog_item_id, name, quantity, unit_cost, subtotal)
      VALUES (p_purchase_id, p_site_id, (item->>'catalog_item_id')::uuid, item->>'name',
        (item->>'quantity')::numeric, (item->>'unit_cost')::numeric,
        round((item->>'quantity')::numeric * (item->>'unit_cost')::numeric, 2));
  END LOOP;
  UPDATE public.purchases SET title = replacement.title, vendor_company_id = replacement.vendor_company_id,
    status = replacement.status, currency = replacement.currency, purchase_date = replacement.purchase_date,
    due_date = replacement.due_date,
    location_id = replacement.location_id, notes = replacement.notes, amount = total, amount_due = greatest(0, total - paid),
    accounting_state = CASE WHEN previous.accounting_state = 'unpublished' THEN 'unpublished' ELSE 'pending' END,
    updated_at = clock_timestamp() WHERE id = p_purchase_id AND site_id = p_site_id;
END;
$_$;


--
-- Name: original_4250041(uuid, text, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4250041(p_site_id uuid, p_source_type text, p_source_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE source_table text; source_row jsonb;
BEGIN
  IF p_site_id IS NULL OR p_source_id IS NULL OR (auth.role() IS DISTINCT FROM 'service_role'
    AND (auth.uid() IS NULL OR NOT public.user_can(p_site_id, 'delete'))) THEN
    RAISE EXCEPTION 'Accounting source deletion is not authorized' USING ERRCODE = '42501';
  END IF;
  source_table := CASE p_source_type WHEN 'sale' THEN 'sales' WHEN 'expense' THEN 'transactions'
    WHEN 'purchase' THEN 'purchases' END;
  IF source_table IS NULL THEN RAISE EXCEPTION 'Invalid source type' USING ERRCODE = '22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('accounting:source:' || p_site_id::text || ':' || p_source_type || ':' || p_source_id::text, 0));
  EXECUTE format('SELECT to_jsonb(s) FROM public.%I s WHERE id=$1 AND site_id=$2 FOR UPDATE', source_table)
    INTO source_row USING p_source_id, p_site_id;
  IF source_row IS NULL THEN RAISE EXCEPTION 'Accounting source not found' USING ERRCODE = 'P0002'; END IF;
  IF p_source_type = 'sale' AND EXISTS (SELECT 1 FROM public.accounting_sale_refunds WHERE sale_id = p_source_id) THEN
    RAISE EXCEPTION 'Refunded sales must be retained for audit' USING ERRCODE = '23503';
  END IF;
  DELETE FROM public.journal_lines l USING public.journal_entries e
    WHERE l.entry_id=e.id AND e.site_id=p_site_id AND e.source_type=p_source_type AND e.source_id=p_source_id;
  DELETE FROM public.journal_entries WHERE site_id=p_site_id AND source_type=p_source_type AND source_id=p_source_id;
  -- Any FK, permission trigger or other delete failure rolls back the journal deletes too.
  EXECUTE format('DELETE FROM public.%I WHERE id=$1 AND site_id=$2', source_table) USING p_source_id, p_site_id;
END;
$_$;


--
-- Name: original_4272421(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4272421(p_instance_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE i public.remote_instances%ROWTYPE; ids uuid[]; provider text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'PT401';
  END IF;
  SELECT * INTO i FROM public.remote_instances WHERE id = p_instance_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Instance not found' USING ERRCODE = 'PT404'; END IF;
  IF public.current_user_site_role(i.site_id) IS NULL
    OR public.current_user_site_role(i.site_id) NOT IN ('owner','admin')
    OR public.user_can(i.site_id, 'delete') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Site owner or administrator deletion permission required' USING ERRCODE = 'PT403';
  END IF;
  ids := public.robot_instance_requirement_candidates(i.id);
  IF EXISTS (
    SELECT 1 FROM unnest(ids) candidate(id) LEFT JOIN public.requirements r USING (id)
    WHERE r.id IS NULL OR r.site_id IS DISTINCT FROM i.site_id OR NOT COALESCE((
      (lower(r.metadata->>'runner_instance_id') = i.id::text
        AND (r.metadata->>'assistant_origin_instance_id' IS NULL
          OR lower(r.metadata->>'assistant_origin_instance_id') = i.id::text))
      OR (r.metadata->>'runner_instance_id' IS NULL
        AND lower(r.metadata->>'assistant_origin_instance_id') = i.id::text)
    ), false)
  ) THEN RAISE EXCEPTION 'Requirements are missing, shared, cross-site or ambiguously owned' USING ERRCODE = 'PT409'; END IF;

  IF EXISTS (
    SELECT 1 FROM (
      SELECT requirement_id, instance_id, site_id FROM public.requirement_status
      UNION ALL SELECT requirement_id, instance_id, site_id FROM public.requirement_harness_decisions
      UNION ALL SELECT requirement_id, instance_id, site_id FROM public.requirement_migration_reconciliations
      UNION ALL SELECT requirement_id, instance_id, site_id FROM public.requirement_migration_execution_handoffs
      UNION ALL SELECT requirement_id, instance_id, site_id FROM public.catalog_item_requirements
    ) history WHERE requirement_id = ANY(ids)
      AND (site_id IS DISTINCT FROM i.site_id OR (instance_id IS NOT NULL AND instance_id <> i.id))
  ) OR EXISTS (
    SELECT 1 FROM public.requirement_cron_cycle_outcomes
    WHERE requirement_id = ANY(ids) AND runner_instance_id IS NOT NULL AND runner_instance_id <> i.id
  ) OR EXISTS (
    SELECT 1 FROM public.requirement_user_action_receipts r JOIN public.instance_logs l ON l.id = r.action_id
    WHERE r.requirement_id = ANY(ids) AND (l.instance_id <> i.id OR l.site_id IS DISTINCT FROM i.site_id)
  ) OR EXISTS (
    SELECT 1 FROM public.requirement_migration_reconciliation_resumes s
      JOIN public.requirement_migration_reconciliations r ON r.id = s.receipt_id
    WHERE (r.requirement_id = ANY(ids) OR s.requirement_id = ANY(ids))
      AND r.requirement_id IS DISTINCT FROM s.requirement_id
  ) OR EXISTS (
    SELECT 1 FROM public.remote_instances other WHERE other.id <> i.id
      AND lower(other.metadata->>'requirement_id') = ANY(ids::text[])
  ) OR EXISTS (
    SELECT 1 FROM public.instance_plans p
    WHERE (p.instance_id = i.id OR lower(p.metadata->>'requirement_id') = ANY(ids::text[]))
      AND (p.instance_id <> i.id OR p.site_id IS DISTINCT FROM i.site_id)
  ) OR EXISTS (
    SELECT 1 FROM public.instance_plans child JOIN public.instance_plans parent ON child.parent_plan_id = parent.id
    WHERE parent.instance_id = i.id AND (child.instance_id <> i.id OR child.site_id IS DISTINCT FROM i.site_id)
  ) OR EXISTS (
    SELECT 1 FROM public.instance_logs l WHERE l.instance_id = i.id AND l.site_id IS DISTINCT FROM i.site_id
  ) OR EXISTS (
    SELECT 1 FROM (
      SELECT l.instance_id FROM public.instance_logs l
      WHERE l.details->>'requirement_id' IS NOT NULL
        AND lower(l.details->>'requirement_id') = ANY(ids::text[])
      UNION ALL
      SELECT l.instance_id FROM public.instance_logs l
      WHERE l.details->>'requirementId' IS NOT NULL
        AND lower(l.details->>'requirementId') = ANY(ids::text[])
      UNION ALL
      SELECT l.instance_id FROM public.instance_logs l
      WHERE l.tool_args->>'requirement_id' IS NOT NULL
        AND lower(l.tool_args->>'requirement_id') = ANY(ids::text[])
      UNION ALL
      SELECT l.instance_id FROM public.instance_logs l
      WHERE l.tool_args->>'requirementId' IS NOT NULL
        AND lower(l.tool_args->>'requirementId') = ANY(ids::text[])
    ) tagged_logs
    WHERE cardinality(ids) > 0 AND tagged_logs.instance_id <> i.id
  ) OR EXISTS (
    SELECT 1 FROM public.instance_logs child JOIN public.instance_logs parent ON child.parent_log_id = parent.id
    WHERE parent.instance_id = i.id AND (child.instance_id <> i.id OR child.site_id IS DISTINCT FROM i.site_id)
  ) OR EXISTS (
    SELECT 1 FROM public.assets WHERE instance_id = i.id AND site_id IS DISTINCT FROM i.site_id
  ) OR EXISTS (
    SELECT 1 FROM public.assets a WHERE a.instance_id = i.id AND (
      EXISTS (SELECT 1 FROM public.agent_assets WHERE asset_id = a.id)
      OR EXISTS (SELECT 1 FROM public.content_assets WHERE asset_id = a.id)
      OR EXISTS (SELECT 1 FROM public.requirement_status s WHERE s.asset_id = a.id
        AND (NOT s.requirement_id = ANY(ids) OR s.site_id IS DISTINCT FROM i.site_id
          OR (s.instance_id IS NOT NULL AND s.instance_id <> i.id))))
  ) OR EXISTS (
    SELECT 1 FROM public.workflow_triggers t
    WHERE (t.instance_id = i.id OR t.template_plan_id IN (SELECT id FROM public.instance_plans WHERE instance_id = i.id))
      AND (t.instance_id <> i.id OR t.site_id IS DISTINCT FROM i.site_id)
  ) OR EXISTS (
    SELECT 1 FROM public.workflow_runs w
    WHERE (w.instance_id = i.id
      OR w.run_plan_id IN (SELECT id FROM public.instance_plans WHERE instance_id = i.id)
      OR w.template_plan_id IN (SELECT id FROM public.instance_plans WHERE instance_id = i.id)
      OR w.trigger_id IN (SELECT id FROM public.workflow_triggers WHERE instance_id = i.id))
      AND (w.instance_id <> i.id OR w.site_id IS DISTINCT FROM i.site_id)
  ) OR EXISTS (
    SELECT 1 FROM public.instance_nodes n WHERE n.instance_id = i.id AND n.site_id IS DISTINCT FROM i.site_id
  ) OR EXISTS (
    SELECT 1 FROM public.campaign_requirements cr JOIN public.campaigns c ON c.id = cr.campaign_id
    WHERE cr.requirement_id = ANY(ids) AND c.site_id IS DISTINCT FROM i.site_id
  ) THEN RAISE EXCEPTION 'Requirement history or plans are shared across instances or sites' USING ERRCODE = 'PT409'; END IF;

  -- Bounded v1: no revocation or inferred lease expiry. Quiesce/reconcile first.
  -- Legacy cosmetic running with no provider ID is admissible only when none of
  -- the persisted execution signals below are present. Never infer a provider.
  IF COALESCE(i.status, '') NOT IN ('pending','uninstantiated','paused','stopped','error','running')
    OR (i.status = 'running' AND i.provider_instance_id IS NOT NULL)
    OR EXISTS (SELECT 1 FROM public.requirements r WHERE r.id = ANY(ids)
      AND (r.cron_lock_active IS TRUE OR r.cron_lock_run_id IS NOT NULL OR r.cron_lock_expires_at IS NOT NULL
        OR NULLIF(r.metadata->>'active_sandbox_id','') IS NOT NULL
        OR NULLIF(r.metadata->>'sandbox_id','') IS NOT NULL))
    OR EXISTS (SELECT 1 FROM public.instance_plans p WHERE p.instance_id = i.id
      AND (p.status IN ('in_progress','in-progress','active','running')
        OR NULLIF(p.metadata->>'active_sandbox_id','') IS NOT NULL
        OR NULLIF(p.metadata->>'sandbox_id','') IS NOT NULL OR EXISTS (
        SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(p.steps) = 'array' THEN p.steps ELSE '[]'::jsonb END) s
        WHERE s->>'status' IN ('in_progress','in-progress','active','running'))))
    OR EXISTS (SELECT 1 FROM public.instance_logs l WHERE l.instance_id = i.id
      AND l.log_type = 'user_action' AND l.details->>'status' = 'running')
    OR EXISTS (SELECT 1 FROM public.instance_nodes WHERE instance_id = i.id AND status IN ('running','in_progress','active'))
    OR EXISTS (SELECT 1 FROM public.workflow_runs WHERE instance_id = i.id AND status IN ('pending','in_progress','running','active'))
    OR EXISTS (SELECT 1 FROM public.workflow_triggers WHERE instance_id = i.id AND enabled IS TRUE)
    OR EXISTS (SELECT 1 FROM (
      SELECT DISTINCT ON (requirement_id) stage, active_sandbox_id FROM public.requirement_status
      WHERE requirement_id = ANY(ids) ORDER BY requirement_id, updated_at DESC, id DESC
    ) latest WHERE latest.stage IN ('in-progress','running','active')
      AND NULLIF(latest.active_sandbox_id,'') IS NOT NULL)
    OR EXISTS (SELECT 1 FROM public.requirement_migration_diagnostics d WHERE d.requirement_id = ANY(ids)
      AND d.state IN ('running','followup_reviewing'))
    OR NULLIF(i.metadata->>'active_sandbox_id','') IS NOT NULL
    OR NULLIF(i.metadata->>'sandbox_id','') IS NOT NULL
    OR NULLIF(i.configuration->>'active_sandbox_id','') IS NOT NULL
    OR NULLIF(i.configuration->>'sandbox_id','') IS NOT NULL
  THEN RAISE EXCEPTION 'Execution must be stopped and reconciled before deletion' USING ERRCODE = 'PT409'; END IF;
  IF (SELECT count(DISTINCT value) FROM unnest(ARRAY[
    to_jsonb(i)->>'provider', i.metadata->>'provider', i.configuration->>'provider'
  ]) providers(value) WHERE value IS NOT NULL) > 1 THEN
    RAISE EXCEPTION 'Provider identity is ambiguous' USING ERRCODE = 'PT409';
  END IF;
  provider := COALESCE(to_jsonb(i)->>'provider', i.metadata->>'provider', i.configuration->>'provider');
  RETURN jsonb_build_object('instance_id', i.id, 'site_id', i.site_id, 'requirement_ids', ids,
    'provider', provider, 'provider_instance_id', i.provider_instance_id, 'status', i.status);
END;
$$;


--
-- Name: original_4272425(uuid, uuid[], text, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4272425(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    SET lock_timeout TO '5s'
    AS $$
DECLARE before_scope jsonb; current_scope jsonb; ids uuid[]; expected uuid[]; deleted_count bigint;
BEGIN
  before_scope := public.get_robot_instance_deletion_scope(p_instance_id);
  -- The scheduler takes this same mutex before requirement row locks.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('requirement-cron-global-capacity', 0));
  IF p_expected_requirement_ids IS NULL OR array_position(p_expected_requirement_ids, NULL) IS NOT NULL
    OR cardinality(p_expected_requirement_ids) > 1000 THEN
    RAISE EXCEPTION 'An exact expected requirement set is required' USING ERRCODE = 'PT409';
  END IF;
  SELECT COALESCE(array_agg(DISTINCT id ORDER BY id), '{}'::uuid[]) INTO expected FROM unnest(p_expected_requirement_ids) id;
  IF cardinality(expected) <> cardinality(p_expected_requirement_ids) THEN
    RAISE EXCEPTION 'Expected requirement IDs must be unique' USING ERRCODE = 'PT409';
  END IF;
  ids := public.robot_instance_requirement_candidates(p_instance_id);
  IF ids IS DISTINCT FROM expected THEN
    RAISE EXCEPTION 'Requirement deletion scope changed' USING ERRCODE = 'PT409';
  END IF;
  PERFORM 1 FROM public.requirements WHERE id = ANY(ids) ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.requirement_migration_lifecycle WHERE requirement_id = ANY(ids) ORDER BY requirement_id, file FOR UPDATE;
  PERFORM 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = ANY(ids) ORDER BY requirement_id, file FOR UPDATE;
  PERFORM 1 FROM public.remote_instances WHERE id = p_instance_id FOR UPDATE;
  PERFORM 1 FROM public.instance_plans WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.workflow_triggers WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.workflow_runs WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.instance_nodes WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.instance_logs WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.requirement_status WHERE requirement_id = ANY(ids) ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.assets WHERE instance_id = p_instance_id ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.catalog_item_requirements WHERE requirement_id = ANY(ids) ORDER BY id FOR UPDATE;
  PERFORM 1 FROM public.campaign_requirements WHERE requirement_id = ANY(ids) ORDER BY campaign_id, requirement_id FOR UPDATE;
  -- Binding triggers take KEY SHARE on their real parents. New bindings either
  -- commit before this lock and appear here, or fail after their parent is gone.
  current_scope := public.get_robot_instance_deletion_scope(p_instance_id);
  IF current_scope->'requirement_ids' IS DISTINCT FROM to_jsonb(expected)
    OR current_scope->>'provider' IS DISTINCT FROM p_expected_provider
    OR current_scope->>'provider_instance_id' IS DISTINCT FROM p_expected_provider_instance_id
    OR current_scope->>'status' IS DISTINCT FROM p_expected_status
    OR current_scope->>'site_id' IS DISTINCT FROM before_scope->>'site_id' THEN
    RAISE EXCEPTION 'Requirement or provider deletion scope changed' USING ERRCODE = 'PT409';
  END IF;
  UPDATE public.api_keys SET status = 'revoked'
    WHERE site_id = (current_scope->>'site_id')::uuid
      AND metadata->>'issued_by' = 'platform-api.ensure-platform-key'
      AND lower(metadata->>'requirement_id') = ANY(ids::text[]);
  DELETE FROM public.requirements WHERE id = ANY(ids);
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  IF deleted_count <> cardinality(ids) THEN
    RAISE EXCEPTION 'Not every expected requirement was deleted' USING ERRCODE = 'PT409';
  END IF;
  DELETE FROM public.instance_logs WHERE instance_id = p_instance_id;
  DELETE FROM public.remote_instances WHERE id = p_instance_id;
  IF NOT FOUND OR EXISTS (SELECT 1 FROM public.requirements WHERE id = ANY(ids))
    OR EXISTS (SELECT 1 FROM public.remote_instances WHERE id = p_instance_id) THEN
    RAISE EXCEPTION 'Instance deletion was not completed' USING ERRCODE = 'PT409';
  END IF;
  -- Unexpected FK/guard failures propagate and roll back this entire statement.
  RETURN jsonb_build_object('instance_id', p_instance_id, 'deleted_requirement_ids', ids);
END;
$$;


--
-- Name: original_4296760(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4296760(p_site_id uuid, p_lead_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  actor uuid := auth.uid();
  restricted boolean;
  invoices jsonb;
BEGIN
  IF actor IS NULL OR NOT coalesce(public.user_can(p_site_id, 'update'), false) THEN
    RAISE EXCEPTION 'Invoice payment access denied' USING ERRCODE = '42501';
  END IF;
  restricted := NOT EXISTS (SELECT 1 FROM public.sites s WHERE s.id = p_site_id AND s.user_id = actor)
    AND NOT EXISTS (SELECT 1 FROM public.site_ownership o WHERE o.site_id = p_site_id AND o.user_id = actor)
    AND EXISTS (SELECT 1 FROM public.site_members m WHERE m.site_id = p_site_id
      AND m.user_id = actor AND m.status = 'active' AND m.restrict_to_assigned_only);
  IF NOT EXISTS (SELECT 1 FROM public.leads l WHERE l.id = p_lead_id AND l.site_id = p_site_id
    AND (NOT restricted OR l.user_id = actor OR l.assignee_id = actor)) THEN
    RAISE EXCEPTION 'Lead payment access denied' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id', s.id, 'title', s.title, 'invoiceNumber', s.invoice_number,
    'amountDue', s.amount_due, 'currency', s.currency, 'saleDate', s.sale_date,
    'createdAt', s.created_at, 'updatedAt', s.updated_at, 'status', s.status
  ) ORDER BY s.sale_date DESC, s.created_at DESC, s.id DESC), '[]'::jsonb)
  INTO invoices FROM public.sales s
  WHERE s.site_id = p_site_id AND s.lead_id = p_lead_id
    AND s.status IN ('pending', 'completed') AND s.amount_due > 0
    AND (NOT restricted OR s.user_id = actor);
  RETURN jsonb_build_object('invoices', invoices, 'version', md5(invoices::text));
END;
$$;

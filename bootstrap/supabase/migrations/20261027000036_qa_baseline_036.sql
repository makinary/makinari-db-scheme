SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: guard_external_identity_grant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_external_identity_grant() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if new.revoked_at is null and exists (
    select 1 from public.visitor_external_identities where lead_id = new.lead_id
  ) and not exists (
    select 1 from public.visitor_identity_token_redemptions r
      join public.visitor_external_identities i on i.id = r.identity_id
      where r.session_id = new.session_id and r.site_id = new.site_id
        and r.visitor_id = new.visitor_id and i.lead_id = new.lead_id
        and r.token_hash = new.trusted_token_hash
        and r.epoch = coalesce((select epoch from public.visitor_identity_session_state
          where session_id = new.session_id), 0)
  ) then raise exception using errcode = '42501', message = 'external_identity_token_required'; end if;
  return new;
end;
$$;


--
-- Name: guard_harness_sandbox_cleanup(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_harness_sandbox_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF NEW.snapshot#>>'{request,requirementId}' IS NOT NULL THEN
    PERFORM 1 FROM public.requirements WHERE id::text=NEW.snapshot#>>'{request,requirementId}' FOR SHARE;
    IF NEW.snapshot->>'status' IN ('queued','running') AND EXISTS (
      SELECT 1 FROM public.harness_sessions s WHERE s.id<>NEW.id AND s.sandbox_cleanup_token IS NOT NULL
        AND s.site_id=NEW.site_id AND s.snapshot#>>'{request,requirementId}'=NEW.snapshot#>>'{request,requirementId}') THEN
      RAISE EXCEPTION 'Sandbox cleanup requires reconciliation';
    END IF;
  END IF;
  -- Another occurrence cannot attach/dispatch against a resource being deleted.
  IF NEW.snapshot#>>'{workspace,id}' IS NOT NULL THEN
    PERFORM 1 FROM public.sandbox_billing_resources
      WHERE sandbox_name=NEW.snapshot#>>'{workspace,id}' FOR UPDATE;
  END IF;
  IF NEW.snapshot#>>'{workspace,id}' IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.harness_sessions WHERE sandbox_cleanup_token IS NOT NULL
      AND sandbox_cleanup_resource=NEW.snapshot#>>'{workspace,id}' AND id<>NEW.id) THEN
    RAISE EXCEPTION 'Sandbox cleanup requires reconciliation';
  END IF;
  IF TG_OP='UPDATE' AND OLD.sandbox_cleanup_token IS NOT NULL AND NEW.sandbox_cleanup_token IS NOT NULL AND
    (NEW.snapshot->>'status' IN ('queued','running') AND NEW.snapshot IS DISTINCT FROM OLD.snapshot
     OR NEW.lease_owner IS NOT NULL AND NEW.lease_owner IS DISTINCT FROM OLD.lease_owner) THEN
    RAISE EXCEPTION 'Sandbox cleanup requires reconciliation';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_harness_session(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_harness_session() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE explicit_reopen boolean:=false;
BEGIN
  IF NOT public.valid_harness_snapshot(NEW.snapshot) THEN RAISE EXCEPTION 'Invalid harness snapshot' USING ERRCODE='22023'; END IF;
  IF TG_OP='INSERT' THEN
    IF NEW.snapshot->>'status'<>'queued' OR NEW.version<>0
      OR (NEW.snapshot->>'turns')::numeric<>0 OR (NEW.snapshot->>'allocatedTokens')::numeric<>0 OR (NEW.snapshot->>'activeMs')::numeric<>0
      OR NEW.lease_owner IS NOT NULL OR NEW.lease_expires_at IS NOT NULL THEN
      RAISE EXCEPTION 'Invalid initial harness session' USING ERRCODE='22023'; END IF;
  ELSE
    explicit_reopen:=OLD.snapshot->>'status'='completed' AND NEW.snapshot->>'status'='queued'
      AND (OLD.lease_expires_at IS NULL OR OLD.lease_expires_at<=clock_timestamp())
      AND NEW.lease_owner IS NULL AND NEW.lease_expires_at IS NULL
      AND NEW.snapshot-ARRAY['status','version','updatedAt']=OLD.snapshot-ARRAY['status','version','updatedAt']
      AND EXISTS (SELECT 1 FROM public.harness_requirement_runs h JOIN public.requirements r ON r.id=h.requirement_id
        WHERE h.session_id=OLD.id AND h.site_id=OLD.site_id AND r.site_id=OLD.site_id AND r.user_id=OLD.user_id
          AND r.status IN ('backlog','in-progress','blocked') AND NOT coalesce(r.metadata ? 'execution_hold',false)
          AND CASE WHEN r.metadata->>'requirement_execution_generation' ~ '^[0-9]{1,9}$'
            THEN (r.metadata->>'requirement_execution_generation')::integer>h.generation ELSE false END);
    IF NEW.id<>OLD.id OR NEW.site_id<>OLD.site_id OR NEW.user_id<>OLD.user_id
      OR NEW.snapshot->'request' IS DISTINCT FROM OLD.snapshot->'request'
      OR NEW.snapshot->'createdAt' IS DISTINCT FROM OLD.snapshot->'createdAt'
      OR (OLD.snapshot ? 'workspace' AND NEW.snapshot->'workspace' IS DISTINCT FROM OLD.snapshot->'workspace') THEN
      RAISE EXCEPTION 'Harness identity is immutable' USING ERRCODE='22023'; END IF;
    IF NEW.version<OLD.version OR NEW.version>OLD.version+1
      OR (NEW.snapshot IS DISTINCT FROM OLD.snapshot AND NEW.version<>OLD.version+1)
      OR (OLD.snapshot->>'status' IN ('completed','cancelled') AND NEW.snapshot IS DISTINCT FROM OLD.snapshot AND NOT explicit_reopen)
      OR (NEW.snapshot->>'turns')::numeric<(OLD.snapshot->>'turns')::numeric
      OR (NEW.snapshot->>'allocatedTokens')::numeric<(OLD.snapshot->>'allocatedTokens')::numeric
      OR (NEW.snapshot->>'activeMs')::numeric<(OLD.snapshot->>'activeMs')::numeric
      OR NOT ((NEW.snapshot->'uncertainOperations') @> (OLD.snapshot->'uncertainOperations')) THEN
      RAISE EXCEPTION 'Invalid harness snapshot update' USING ERRCODE='22023'; END IF;
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: guard_icp_mining_execution_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_icp_mining_execution_update() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF (OLD.execution_run_id IS NOT NULL OR NEW.execution_run_id IS NOT NULL)
    AND (NEW.processed_targets, NEW.found_matches, NEW.current_page, NEW.current_page_offset,
      NEW.status, NEW.execution_run_id, NEW.execution_active, NEW.execution_workflow_id, NEW.checkpoint_version,
      NEW.current_page_snapshot, NEW.total_targets, NEW.started_at, NEW.finished_at, NEW.last_progress_at, NEW.last_error, NEW.errors)
      IS DISTINCT FROM
      (OLD.processed_targets, OLD.found_matches, OLD.current_page, OLD.current_page_offset,
      OLD.status, OLD.execution_run_id, OLD.execution_active, OLD.execution_workflow_id, OLD.checkpoint_version,
      OLD.current_page_snapshot, OLD.total_targets, OLD.started_at, OLD.finished_at, OLD.last_progress_at, OLD.last_error, OLD.errors)
    AND (NEW.execution_run_id IS NULL OR COALESCE(pg_catalog.current_setting('app.icp_execution_owner', true), '') IS DISTINCT FROM NEW.execution_run_id::text) THEN
    RAISE EXCEPTION 'Mining progress must use the execution checkpoint protocol';
  END IF;
  RETURN NEW;
END $$;


--
-- Name: guard_icypeas_email_search(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_icypeas_email_search() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF ROW(NEW.id, NEW.site_id, NEW.input_hash, NEW.firstname, NEW.lastname, NEW.domain_or_company)
     IS DISTINCT FROM ROW(OLD.id, OLD.site_id, OLD.input_hash, OLD.firstname, OLD.lastname, OLD.domain_or_company) THEN
    RAISE EXCEPTION 'IcyPeas search identity is immutable';
  END IF;
  IF OLD.search_id IS NOT NULL AND NEW.search_id IS DISTINCT FROM OLD.search_id THEN
    RAISE EXCEPTION 'IcyPeas provider search ID is immutable';
  END IF;
  IF OLD.state IN ('matched', 'no_match', 'failed') AND NEW IS DISTINCT FROM OLD THEN
    RAISE EXCEPTION 'IcyPeas terminal result is immutable';
  END IF;
  IF OLD.state <> 'ready' AND NEW.state = 'ready' THEN
    RAISE EXCEPTION 'IcyPeas submitted jobs cannot be reset';
  END IF;
  IF OLD.state <> 'ready' AND NEW.state = 'submitting' AND OLD.state <> 'submitting' THEN
    RAISE EXCEPTION 'IcyPeas jobs cannot be resubmitted';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_instance_log_requirement_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_instance_log_requirement_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE binding text; bound_site uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
    AND ARRAY[NEW.details->>'requirement_id', NEW.details->>'requirementId',
      NEW.tool_args->>'requirement_id', NEW.tool_args->>'requirementId']
      IS NOT DISTINCT FROM ARRAY[OLD.details->>'requirement_id', OLD.details->>'requirementId',
        OLD.tool_args->>'requirement_id', OLD.tool_args->>'requirementId'] THEN RETURN NEW; END IF;
  FOR binding IN SELECT DISTINCT value FROM unnest(ARRAY[
    NEW.details->>'requirement_id', NEW.details->>'requirementId',
    NEW.tool_args->>'requirement_id', NEW.tool_args->>'requirementId'
  ]) tags(value) WHERE value IS NOT NULL ORDER BY value LOOP
    IF binding !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
      RAISE EXCEPTION 'Invalid log requirement binding' USING ERRCODE = '23514';
    END IF;
    SELECT site_id INTO bound_site FROM public.requirements WHERE id = binding::uuid FOR KEY SHARE;
    IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
      RAISE EXCEPTION 'Log requirement binding is missing or cross-site' USING ERRCODE = '23514';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$_$;


--
-- Name: guard_instance_plan_requirement_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_instance_plan_requirement_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE binding text := NEW.metadata->>'requirement_id'; bound_site uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
    AND NEW.instance_id IS NOT DISTINCT FROM OLD.instance_id
    AND NEW.metadata->'requirement_id' IS NOT DISTINCT FROM OLD.metadata->'requirement_id'
  THEN RETURN NEW; END IF;
  IF binding IS NOT NULL THEN
    IF binding !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
      RAISE EXCEPTION 'Invalid plan requirement binding' USING ERRCODE = '23514';
    END IF;
    SELECT site_id INTO bound_site FROM public.requirements WHERE id = binding::uuid FOR KEY SHARE;
    IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
      RAISE EXCEPTION 'Plan requirement binding is missing or cross-site' USING ERRCODE = '23514';
    END IF;
  END IF;
  SELECT site_id INTO bound_site FROM public.remote_instances WHERE id = NEW.instance_id FOR KEY SHARE;
  IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
    RAISE EXCEPTION 'Plan instance binding is missing or cross-site' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: guard_instance_requirement_metadata_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_instance_requirement_metadata_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE binding text := NEW.metadata->>'requirement_id'; bound_site uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
    AND NEW.metadata->'requirement_id' IS NOT DISTINCT FROM OLD.metadata->'requirement_id'
  THEN RETURN NEW; END IF;
  IF binding IS NULL THEN RETURN NEW; END IF;
  IF binding !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RAISE EXCEPTION 'Invalid instance requirement binding' USING ERRCODE = '23514';
  END IF;
  SELECT site_id INTO bound_site FROM public.requirements WHERE id = binding::uuid FOR KEY SHARE;
  IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
    RAISE EXCEPTION 'Instance requirement binding is missing or cross-site' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: guard_marketplace_native_write(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_marketplace_native_write() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE row_data jsonb; protected boolean := false;
BEGIN
  IF public.marketplace_is_backend() THEN
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;
  -- The printer owns only its local bounded acknowledgement. No provider state,
  -- quantities, prices, modifiers or other metadata may change in this exception.
  IF TG_TABLE_NAME = 'sale_order_items' AND TG_OP = 'UPDATE' THEN
    IF (to_jsonb(NEW)-'metadata') = (to_jsonb(OLD)-'metadata')
      AND (coalesce(to_jsonb(NEW)->'metadata','{}'::jsonb)-'printed_quantity')
        = (coalesce(to_jsonb(OLD)->'metadata','{}'::jsonb)-'printed_quantity')
      AND jsonb_typeof(to_jsonb(NEW)#>'{metadata,printed_quantity}') = 'number'
      AND (to_jsonb(NEW)#>>'{metadata,printed_quantity}')::numeric BETWEEN 0 AND (to_jsonb(NEW)->>'quantity')::numeric
      AND public.user_can((to_jsonb(NEW)->>'site_id')::uuid,'update')
      AND EXISTS (SELECT 1 FROM public.sale_orders WHERE id = (to_jsonb(NEW)->>'sale_order_id')::uuid
        AND marketplace_integration_id IS NOT NULL AND (metadata#>>'{marketplace,state}' IN ('accepted','ready','completed')
          OR (metadata#>>'{marketplace,state}' = 'cancelled' AND (to_jsonb(NEW)#>>'{metadata,printed_quantity}')::numeric = 0))
        AND metadata#>>'{marketplace,sync_status}' = 'confirmed'
        AND coalesce(metadata#>>'{marketplace,operation,status}','confirmed') NOT IN ('pending','unknown')) THEN
      RETURN NEW;
    END IF;
  END IF;
  -- Check both images: unlinking/reparenting must not bypass provider ownership.
  FOR row_data IN SELECT value FROM jsonb_array_elements(jsonb_build_array(
    CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) ELSE '{}'::jsonb END,
    CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) ELSE '{}'::jsonb END
  )) LOOP
    protected := protected OR row_data->>'marketplace_integration_id' IS NOT NULL
      OR row_data#>'{metadata,marketplace}' IS NOT NULL
      OR row_data#>'{payment_details,marketplace}' IS NOT NULL;
    IF TG_TABLE_NAME = 'site_secrets' THEN
      protected := protected OR coalesce(row_data->>'use_case','') LIKE 'marketplace:%'
        OR coalesce(row_data->>'provider','') IN ('uber_eats','rappi');
    END IF;
    IF row_data->>'sale_order_id' IS NOT NULL THEN
      protected := protected OR EXISTS (SELECT 1 FROM public.sale_orders
        WHERE id = (row_data->>'sale_order_id')::uuid AND marketplace_integration_id IS NOT NULL);
    END IF;
    IF row_data->>'sale_order_item_id' IS NOT NULL THEN
      protected := protected OR EXISTS (SELECT 1 FROM public.sale_order_items i
        JOIN public.sale_orders o ON o.id = i.sale_order_id
        WHERE i.id = (row_data->>'sale_order_item_id')::uuid AND o.marketplace_integration_id IS NOT NULL);
    END IF;
    IF TG_TABLE_NAME = 'sales' AND row_data->>'id' IS NOT NULL THEN
      protected := protected OR EXISTS (SELECT 1 FROM public.sale_orders
        WHERE sale_id = (row_data->>'id')::uuid AND marketplace_integration_id IS NOT NULL);
    END IF;
    IF row_data->>'shipment_id' IS NOT NULL THEN
      protected := protected OR EXISTS (SELECT 1 FROM public.shipments
        WHERE id = (row_data->>'shipment_id')::uuid AND marketplace_integration_id IS NOT NULL);
    END IF;
  END LOOP;
  IF protected THEN RAISE EXCEPTION 'Marketplace records are provider-owned' USING ERRCODE = '42501'; END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;


--
-- Name: guard_member_license(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_member_license() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE payload jsonb; primary_owner uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND (NEW.id IS DISTINCT FROM OLD.id OR NEW.site_id IS DISTINCT FROM OLD.site_id
    OR (NEW.user_id IS DISTINCT FROM OLD.user_id AND NOT
      (OLD.user_id IS NULL AND OLD.status = 'pending' AND NEW.status = 'active' AND NEW.user_id IS NOT NULL))) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Member identity and site are immutable';
  END IF;
  PERFORM public.lock_site_license(CASE WHEN TG_OP = 'DELETE' THEN OLD.site_id ELSE NEW.site_id END);
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  SELECT user_id INTO primary_owner FROM public.sites WHERE id = NEW.site_id;
  IF NEW.user_id = primary_owner THEN
    NEW.manually_disabled := false; NEW.license_suspended := false; RETURN NEW;
  END IF;
  IF NEW.manually_disabled THEN NEW.license_suspended := true; END IF;
  IF NEW.status IN ('active','pending') AND NOT NEW.license_suspended AND (
    TG_OP = 'INSERT' OR (OLD.status IS DISTINCT FROM 'active' AND OLD.status IS DISTINCT FROM 'pending') OR OLD.license_suspended
  ) THEN
    payload := public.get_site_member_license(NEW.site_id,CASE WHEN TG_OP = 'UPDATE' THEN OLD.id ELSE NULL END);
    IF (payload->>'limit') IS NOT NULL AND (payload->>'current')::integer >= (payload->>'limit')::integer THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'MEMBER_LIMIT', DETAIL = payload::text;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_migration_execution_handoff(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_migration_execution_handoff() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF TG_OP = 'DELETE' AND NOT EXISTS (
    SELECT 1 FROM public.requirements WHERE id = OLD.requirement_id
  ) THEN
    RETURN NULL;
  END IF;
  IF TG_OP <> 'INSERT' AND (OLD.state = 'transferred' OR EXISTS (
    SELECT 1 FROM public.requirement_migration_execution_handoffs h
    WHERE h.requirement_id = OLD.requirement_id AND h.file = OLD.file
  ) OR EXISTS (
    SELECT 1 FROM public.requirement_migration_retirements h
    WHERE h.requirement_id = OLD.requirement_id AND h.file = OLD.file
  )) THEN
    IF TG_OP <> 'UPDATE' OR OLD.state = 'transferred' OR NEW.state <> 'transferred' THEN
      RAISE EXCEPTION 'Transferred migration lifecycle is immutable' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF TG_OP <> 'DELETE' AND NEW.state = 'transferred' THEN
    IF TG_OP <> 'UPDATE' OR NOT public.migration_execution_handoff_matches(NEW)
      OR NOT (EXISTS (
        SELECT 1 FROM public.requirement_migration_execution_handoffs h
        WHERE h.requirement_id = NEW.requirement_id AND h.file = NEW.file
          AND h.prior_lifecycle = to_jsonb(OLD)
      ) OR EXISTS (
        SELECT 1 FROM public.requirement_migration_retirements h
        WHERE h.requirement_id = NEW.requirement_id AND h.file = NEW.file
          AND h.prior_lifecycle = to_jsonb(OLD)
      )) THEN
      RAISE EXCEPTION 'Transferred migration requires its matching immutable receipt' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: guard_pending_migration_reconciliation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_pending_migration_reconciliation() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status
    AND COALESCE(NEW.status, '') NOT IN ('blocked','paused','stopped','cancelled','canceled')
    AND EXISTS (SELECT 1 FROM public.requirement_migration_reconciliations AS receipt
      WHERE receipt.requirement_id = NEW.id AND NOT EXISTS (
        SELECT 1 FROM public.requirement_migration_reconciliation_resumes AS resumed
        WHERE resumed.receipt_id = receipt.id)) THEN
    RAISE EXCEPTION 'Reconciled migration requires explicit operator resume' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_platform_key_requirement_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_platform_key_requirement_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE binding text := NEW.metadata->>'requirement_id'; bound_site uuid;
BEGIN
  IF NEW.metadata->>'issued_by' IS DISTINCT FROM 'platform-api.ensure-platform-key'
    OR (TG_OP = 'UPDATE' AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
      AND NEW.metadata->'requirement_id' IS NOT DISTINCT FROM OLD.metadata->'requirement_id'
      AND NEW.metadata->'issued_by' IS NOT DISTINCT FROM OLD.metadata->'issued_by'
      AND NEW.status IS DISTINCT FROM 'active') THEN RETURN NEW; END IF;
  IF binding IS NULL OR binding !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RAISE EXCEPTION 'Invalid platform key requirement binding' USING ERRCODE = '23514';
  END IF;
  SELECT site_id INTO bound_site FROM public.requirements WHERE id = binding::uuid FOR KEY SHARE;
  IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
    RAISE EXCEPTION 'Platform key requirement binding is missing or cross-site' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: guard_requirement_assistant_admission(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_assistant_admission() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_requirement public.requirements%ROWTYPE;
  v_archived boolean;
BEGIN
  IF NEW.log_type <> 'user_action' OR NEW.trusted_user_action IS DISTINCT FROM true THEN RETURN NEW; END IF;
  FOR v_requirement IN
    SELECT * FROM public.requirements WHERE site_id = NEW.site_id
      AND metadata->>'runner_instance_id' = NEW.instance_id::text
      -- Admission belongs to the current owner, including cron-created and
      -- replacement runners that never had an assistant origin.
    ORDER BY id FOR UPDATE
  LOOP
    IF v_requirement.cron_lock_active IS TRUE AND v_requirement.cron_lock_run_id IS NOT NULL
      AND v_requirement.cron_lock_expires_at > clock_timestamp() THEN
      RAISE EXCEPTION USING ERRCODE = '55P03', MESSAGE = 'requirement_execution_busy';
    END IF;
  END LOOP;
  SELECT is_archived INTO v_archived FROM public.remote_instances
    WHERE id = NEW.instance_id AND site_id = NEW.site_id FOR SHARE;
  IF v_archived IS TRUE THEN
    RAISE EXCEPTION USING ERRCODE = '55P03', MESSAGE = 'original_instance_archived';
  END IF;
  RETURN NEW;
END;
$$;

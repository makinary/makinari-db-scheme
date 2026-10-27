SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: guard_requirement_deletion_authority(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_deletion_authority() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  -- Preserve pre-existing system deletion and a real site-root FK cascade. The
  -- built-in role setting is PostgreSQL-authorized SET ROLE, not a caller flag.
  -- Neither exception grants access to the authenticated-only deletion RPCs.
  IF NOT EXISTS (SELECT 1 FROM public.sites WHERE id = OLD.site_id)
    OR (auth.uid() IS NULL AND current_setting('role', true) = 'service_role') THEN
    RETURN OLD;
  END IF;
  IF auth.uid() IS NULL
    OR public.current_user_site_role(OLD.site_id) IS NULL
    OR public.current_user_site_role(OLD.site_id) NOT IN ('owner', 'admin')
    OR public.user_can(OLD.site_id, 'delete') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Requirement deletion requires site owner or administrator permission' USING ERRCODE = 'PT403';
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: guard_requirement_instance_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_instance_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE binding text; bound_site uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
    AND NEW.metadata->'runner_instance_id' IS NOT DISTINCT FROM OLD.metadata->'runner_instance_id'
    AND NEW.metadata->'assistant_origin_instance_id' IS NOT DISTINCT FROM OLD.metadata->'assistant_origin_instance_id'
  THEN RETURN NEW; END IF;
  FOR binding IN SELECT DISTINCT value FROM unnest(ARRAY[
    NEW.metadata->>'runner_instance_id', NEW.metadata->>'assistant_origin_instance_id'
  ]) AS bindings(value) WHERE value IS NOT NULL ORDER BY value LOOP
    IF binding !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
      RAISE EXCEPTION 'Invalid requirement instance binding' USING ERRCODE = '23514';
    END IF;
    SELECT site_id INTO bound_site FROM public.remote_instances
      WHERE id = binding::uuid FOR KEY SHARE;
    IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
      RAISE EXCEPTION 'Requirement instance binding is missing or cross-site' USING ERRCODE = '23514';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$_$;


--
-- Name: guard_requirement_migration_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_migration_status() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status OR NEW.status='blocked' THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_lifecycle l WHERE l.requirement_id=NEW.id
    AND (l.state='platform_review' OR (l.state='transferred' AND NOT public.migration_execution_handoff_matches(l)))) THEN
    RAISE EXCEPTION 'Requirement is blocked by migration platform review or invalid handoff' USING ERRCODE='23514';
  END IF;
  IF NEW.status='on-review' AND EXISTS (
    SELECT 1 FROM public.harness_requirement_runs h JOIN public.harness_sessions s ON s.id=h.session_id
    WHERE h.requirement_id=NEW.id AND h.site_id=NEW.site_id AND s.site_id=NEW.site_id AND s.user_id=NEW.user_id
      AND h.generation::text=NEW.metadata->>'requirement_execution_generation'
      AND s.snapshot->>'status'='completed'
      AND (s.snapshot#>>'{request,requirementId}' IS NULL OR s.snapshot#>>'{request,requirementId}'=NEW.id::text)
  ) THEN RETURN NEW; END IF;
  IF NEW.status IN ('done','on-review') AND EXISTS (SELECT 1 FROM public.requirement_migration_lifecycle l
    WHERE l.requirement_id=NEW.id AND l.state<>'validated' AND NOT public.migration_execution_handoff_matches(l)) THEN
    RAISE EXCEPTION 'Requirement has unvalidated migration lifecycle records' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_requirement_owned_receipt_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_owned_receipt_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  -- A real root deletion, not a role, session setting or trigger-depth bypass.
  IF EXISTS (SELECT 1 FROM public.requirements WHERE id = OLD.requirement_id) THEN
    RAISE EXCEPTION 'Requirement history is append-only while its requirement exists' USING ERRCODE = '23514';
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: guard_requirement_sandbox_cleanup(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_sandbox_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status NOT IN ('done','cancelled','canceled') AND EXISTS (
    SELECT 1 FROM public.harness_sessions WHERE sandbox_cleanup_token IS NOT NULL AND site_id=NEW.site_id
      AND snapshot#>>'{request,requirementId}'=NEW.id::text) THEN
    RAISE EXCEPTION 'Sandbox cleanup requires reconciliation';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_requirement_status_instance_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_requirement_status_instance_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE bound_site uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
    AND NEW.instance_id IS NOT DISTINCT FROM OLD.instance_id
    AND NEW.requirement_id IS NOT DISTINCT FROM OLD.requirement_id THEN RETURN NEW; END IF;
  SELECT site_id INTO bound_site FROM public.requirements WHERE id = NEW.requirement_id FOR KEY SHARE;
  IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
    RAISE EXCEPTION 'Requirement status binding is missing or cross-site' USING ERRCODE = '23514';
  END IF;
  IF NEW.instance_id IS NOT NULL THEN
    SELECT site_id INTO bound_site FROM public.remote_instances WHERE id = NEW.instance_id FOR KEY SHARE;
    IF NOT FOUND OR bound_site IS DISTINCT FROM NEW.site_id THEN
      RAISE EXCEPTION 'Requirement status instance is missing or cross-site' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_robot_deletion_child_authority(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_robot_deletion_child_authority() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE resource_site uuid;
BEGIN
  IF TG_TABLE_NAME = 'campaign_requirements' THEN
    IF NOT EXISTS (SELECT 1 FROM public.requirements WHERE id = OLD.requirement_id) THEN RETURN OLD; END IF;
    SELECT site_id INTO resource_site FROM public.campaigns WHERE id = OLD.campaign_id;
  ELSE
    IF OLD.instance_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.remote_instances WHERE id = OLD.instance_id
    ) THEN RETURN OLD; END IF;
    resource_site := OLD.site_id;
  END IF;
  IF resource_site IS NULL OR NOT EXISTS (SELECT 1 FROM public.sites WHERE id = resource_site)
    OR (auth.uid() IS NULL AND current_setting('role', true) = 'service_role') THEN RETURN OLD; END IF;
  IF auth.uid() IS NULL OR public.current_user_site_role(resource_site) IS NULL
    OR public.current_user_site_role(resource_site) NOT IN ('owner','admin')
    OR public.user_can(resource_site, 'delete') IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Site owner or administrator deletion permission required' USING ERRCODE = 'PT403';
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: guard_sandbox_cleanup_registration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_sandbox_cleanup_registration() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.harness_sessions WHERE sandbox_cleanup_token IS NOT NULL
    AND sandbox_cleanup_resource=NEW.sandbox_name)
    AND NEW.deletion_requested_at IS NOT DISTINCT FROM OLD.deletion_requested_at
    AND NEW.retired_at IS NOT DISTINCT FROM OLD.retired_at THEN
    RAISE EXCEPTION 'Sandbox cleanup requires reconciliation';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_self_service_line(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_self_service_line() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE parent_order public.sale_orders%ROWTYPE; paid boolean;
BEGIN
  IF TG_OP='UPDATE' AND ROW(NEW.sale_order_id,NEW.site_id) IS DISTINCT FROM ROW(OLD.sale_order_id,OLD.site_id) THEN
    IF coalesce(OLD.metadata->'self_service','false') = 'true'::jsonb OR EXISTS (
      SELECT 1 FROM public.sale_orders WHERE id=OLD.sale_order_id AND public.is_self_service_order_items(items)
    ) THEN RAISE EXCEPTION 'Self-service line scope is immutable' USING ERRCODE='42501'; END IF;
  END IF;
  SELECT * INTO parent_order FROM public.sale_orders WHERE id=NEW.sale_order_id FOR UPDATE;
  IF NOT public.is_self_service_order_items(parent_order.items) THEN RETURN NEW; END IF;
  IF NEW.status IS NULL THEN RAISE EXCEPTION 'Self-service line status is required' USING ERRCODE='22023'; END IF;
  IF NEW.site_id IS DISTINCT FROM parent_order.site_id THEN
    RAISE EXCEPTION 'Self-service line site mismatch' USING ERRCODE='42501';
  END IF;
  IF TG_OP='UPDATE' AND coalesce(OLD.metadata->'self_service','false')='true'::jsonb
    AND (NEW.metadata->'self_service' IS DISTINCT FROM 'true'::jsonb
      OR NEW.metadata->'self_service_location_id' IS DISTINCT FROM OLD.metadata->'self_service_location_id') THEN
    RAISE EXCEPTION 'Self-service line marker is immutable' USING ERRCODE='42501';
  END IF;
  NEW.metadata := coalesce(NEW.metadata,'{}') || jsonb_build_object(
    'self_service',true,'self_service_location_id',parent_order.origin_location_id);
  SELECT status='completed' AND amount_due >= 0 AND amount_due <= 0.009
    INTO paid FROM public.sales WHERE id=parent_order.sale_id AND site_id=parent_order.site_id FOR UPDATE;
  IF NEW.status NOT IN ('draft','cancelled') OR (NEW.sent_at IS NOT NULL AND NEW.status <> 'cancelled') THEN
    IF parent_order.status='cancelled' OR paid IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Self-service line requires full payment' USING ERRCODE='42501';
    END IF;
    NEW.sent_at := coalesce(NEW.sent_at,now());
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_self_service_order(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_self_service_order() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE marked boolean; paid boolean;
BEGIN
  marked := public.is_self_service_order_items(NEW.items);
  IF TG_OP='UPDATE' AND marked AND NOT public.is_self_service_order_items(OLD.items) THEN
    RAISE EXCEPTION 'Existing orders cannot acquire a self-service marker' USING ERRCODE='42501';
  END IF;
  IF TG_OP = 'UPDATE' AND public.is_self_service_order_items(OLD.items) THEN
    IF NOT marked OR ROW(NEW.site_id,NEW.sale_id,NEW.origin_location_id)
      IS DISTINCT FROM ROW(OLD.site_id,OLD.sale_id,OLD.origin_location_id) THEN
      RAISE EXCEPTION 'Self-service marker and scope are immutable' USING ERRCODE='42501';
    END IF;
  END IF;
  IF NOT marked THEN RETURN NEW; END IF;
  SELECT status = 'completed' AND amount_due >= 0 AND amount_due <= 0.009
    INTO paid FROM public.sales WHERE id=NEW.sale_id AND site_id=NEW.site_id FOR UPDATE;
  IF NEW.status NOT IN ('draft','pending','cancelled') AND paid IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Self-service order requires full payment' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_self_service_unit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_self_service_unit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE line public.sale_order_items%ROWTYPE; parent_order public.sale_orders%ROWTYPE; paid boolean;
BEGIN
  IF TG_OP='UPDATE' AND ROW(NEW.sale_order_item_id,NEW.site_id) IS DISTINCT FROM ROW(OLD.sale_order_item_id,OLD.site_id) THEN
    IF EXISTS(SELECT 1 FROM public.sale_order_items i JOIN public.sale_orders o ON o.id=i.sale_order_id
      WHERE i.id=OLD.sale_order_item_id AND public.is_self_service_order_items(o.items)) THEN
      RAISE EXCEPTION 'Self-service unit scope is immutable' USING ERRCODE='42501';
    END IF;
  END IF;
  SELECT * INTO line FROM public.sale_order_items WHERE id=NEW.sale_order_item_id;
  SELECT * INTO parent_order FROM public.sale_orders WHERE id=line.sale_order_id FOR UPDATE;
  IF NOT public.is_self_service_order_items(parent_order.items) THEN RETURN NEW; END IF;
  IF NEW.site_id IS DISTINCT FROM parent_order.site_id THEN
    RAISE EXCEPTION 'Self-service unit site mismatch' USING ERRCODE='42501';
  END IF;
  IF NEW.status NOT IN ('draft','cancelled') THEN
    SELECT status='completed' AND amount_due >= 0 AND amount_due <= 0.009
      INTO paid FROM public.sales WHERE id=parent_order.sale_id AND site_id=parent_order.site_id FOR UPDATE;
    IF paid IS DISTINCT FROM true OR parent_order.status='cancelled' THEN
      RAISE EXCEPTION 'Self-service unit requires full payment' USING ERRCODE='42501';
    END IF;
    IF line.status IN ('draft','cancelled') OR line.sent_at IS NULL THEN
      RAISE EXCEPTION 'Self-service line must be released before unit preparation' USING ERRCODE='42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_site_archive_state(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_site_archive_state() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.archived_at IS NOT NULL OR NEW.archived_by IS NOT NULL
         OR NEW.archive_snapshot IS NOT NULL THEN
        RAISE EXCEPTION 'Site archival requires password verification' USING ERRCODE = '42501';
      END IF;
    ELSIF OLD.archived_at IS NOT NULL
       OR NEW.archived_at IS DISTINCT FROM OLD.archived_at
       OR NEW.archived_by IS DISTINCT FROM OLD.archived_by
       OR NEW.archive_snapshot IS DISTINCT FROM OLD.archive_snapshot THEN
      RAISE EXCEPTION 'Site archival requires password verification' USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_startup_trial_billing(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_startup_trial_billing() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE t public.site_startup_trials%ROWTYPE; v_now timestamptz := clock_timestamp();
  v_browser boolean := coalesce(auth.role(),'') IN ('anon','authenticated')
    OR coalesce(current_setting('role',true),'') IN ('anon','authenticated');
  v_expired numeric := 0;
BEGIN
  IF v_browser AND (TG_OP = 'INSERT' OR ROW(NEW.trial_credits_available,NEW.trial_started_at,NEW.trial_ends_at,NEW.trial_converted_at)
    IS DISTINCT FROM ROW(OLD.trial_credits_available,OLD.trial_started_at,OLD.trial_ends_at,OLD.trial_converted_at)) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Trial fields are server managed'; END IF;
  SELECT * INTO t FROM public.site_startup_trials WHERE site_id = NEW.site_id;
  IF TG_OP='UPDATE' AND OLD.trial_ends_at <= v_now AND (
    (NEW.trial_credits_available < OLD.trial_credits_available AND NEW.credits_used > OLD.credits_used)
    OR NEW.trial_credits_available > OLD.trial_credits_available
  ) THEN
    RAISE EXCEPTION USING ERRCODE='40001', MESSAGE='Trial expired while debit was being admitted; retry';
  END IF;
  IF NEW.trial_converted_at IS NOT NULL AND NEW.trial_converted_at IS DISTINCT FROM t.converted_at THEN
    RAISE EXCEPTION 'Trial conversion projection must match its claim'; END IF;
  IF NEW.trial_started_at IS NOT NULL AND (t.site_id IS NULL OR NEW.trial_started_at <> t.started_at
    OR NEW.trial_ends_at IS DISTINCT FROM t.ends_at) THEN
    RAISE EXCEPTION 'Trial projection must match its immutable claim'; END IF;
  IF t.site_id IS NOT NULL AND t.converted_at IS NULL AND (
    (NEW.stripe_subscription_id IS NOT NULL AND NEW.paid_subscription_invoice_id IS NOT NULL
      AND NEW.paid_subscription_period_start <= v_now AND NEW.paid_subscription_period_end > v_now
      AND (NEW.plan IN ('engine','foundry','enterprise') OR NEW.addons_count > 0))
    OR (NEW.stripe_subscription_id IS NULL AND NEW.plan IN ('engine','foundry','enterprise'))
  ) THEN
    UPDATE public.site_startup_trials SET converted_at = v_now WHERE site_id = NEW.site_id;
    t.converted_at := v_now;
  END IF;
  IF t.converted_at IS NOT NULL THEN
    v_expired := NEW.trial_credits_available;
    NEW.trial_converted_at := t.converted_at;
    NEW.trial_started_at := NULL; NEW.trial_ends_at := NULL; NEW.trial_credits_available := 0;
  ELSIF NEW.trial_ends_at <= v_now OR NEW.status IS DISTINCT FROM 'active' OR NOT EXISTS (
    SELECT 1 FROM public.sites WHERE id = NEW.site_id AND archived_at IS NULL
  ) THEN v_expired := NEW.trial_credits_available; NEW.trial_credits_available := 0; END IF;
  IF v_expired > 0 THEN
    INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
      VALUES(NEW.site_id,-v_expired,'startup_trial_expiry','Unused Startup trial credits expired',
        jsonb_build_object('credit_bucket','trial','reason',CASE WHEN t.converted_at IS NOT NULL THEN 'converted' ELSE 'expired_or_archived' END));
  END IF;
  NEW.credits_available := NEW.plan_credits_available + NEW.purchased_credits_available
    + NEW.legacy_credits_available + NEW.trial_credits_available;
  RETURN NEW;
END;
$$;


--
-- Name: guard_visitor_identity_issuer_scope(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_visitor_identity_issuer_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if 'identity:issue' = any(new.scopes) and coalesce(auth.role(), '') <> 'service_role' then
    if new.site_id is null or new.user_id <> auth.uid() or not exists (
      select 1 from public.sites where id = new.site_id and user_id = auth.uid()
    ) then raise exception using errcode = '42501', message = 'identity_issuer_owner_required'; end if;
  end if;
  return new;
end;
$$;


--
-- Name: handle_campaign_deletion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_campaign_deletion() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    -- Log de la operación (opcional, para debugging)
    RAISE NOTICE 'Deleting campaign: % - %', OLD.id, OLD.title;
    
    -- Primero eliminamos las relaciones en campaign_requirements
    DELETE FROM public.campaign_requirements 
    WHERE campaign_id = OLD.id;
    
    -- Luego eliminamos los requirements que solo estaban asociados a esta campaña
    -- (requirements que no tienen otras relaciones de campaña)
    DELETE FROM public.requirements 
    WHERE id IN (
        SELECT r.id 
        FROM public.requirements r
        LEFT JOIN public.campaign_requirements cr ON r.id = cr.requirement_id
        WHERE cr.requirement_id IS NULL
        AND r.id IN (
            -- Solo eliminar requirements que estaban asociados a la campaña eliminada
            SELECT requirement_id 
            FROM public.campaign_requirements 
            WHERE campaign_id = OLD.id
        )
    );
    
    -- También eliminar subtasks relacionadas
    DELETE FROM public.campaign_subtasks 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar segments relacionados
    DELETE FROM public.campaign_segments 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar transacciones relacionadas
    DELETE FROM public.transactions 
    WHERE campaign_id = OLD.id;
    
    RAISE NOTICE 'Campaign deletion completed for: %', OLD.id;
    
    RETURN OLD;
END;
$$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: sync_sale_order_item_units_from_line(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_sale_order_item_units_from_line() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  unit_count integer;
  unit_quantity numeric;
  status_changed boolean := true;
  shipment_delivered_at timestamptz;
BEGIN
  IF NEW.parent_sale_order_item_id IS NOT NULL OR NEW.quantity <= 0 THEN
    DELETE FROM public.sale_order_item_units
    WHERE sale_order_item_id = NEW.id;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    status_changed := NEW.status IS DISTINCT FROM OLD.status;
  END IF;

  IF NEW.shipment_id IS NOT NULL THEN
    SELECT delivered_at
    INTO shipment_delivered_at
    FROM public.shipments
    WHERE id = NEW.shipment_id;
  END IF;

  unit_count := CASE
    WHEN NEW.quantity = trunc(NEW.quantity)
      THEN GREATEST(1, NEW.quantity::integer)
    ELSE 1
  END;
  unit_quantity := CASE WHEN unit_count = 1 THEN NEW.quantity ELSE 1 END;

  INSERT INTO public.sale_order_item_units (
    site_id,
    sale_order_item_id,
    unit_index,
    quantity,
    status,
    shipment_id,
    started_at,
    in_progress_at,
    ready_at,
    completed_at,
    delivered_at,
    created_at,
    updated_at
  )
  SELECT
    NEW.site_id,
    NEW.id,
    generated_index,
    unit_quantity,
    NEW.status,
    NEW.shipment_id,
    COALESCE(NEW.sent_at, NEW.created_at),
    CASE
      WHEN NEW.status IN (
        'preparing',
        'in_progress',
        'completed',
        'ready',
        'returned'
      ) THEN COALESCE(NEW.sent_at, NEW.created_at)
      ELSE NULL
    END,
    CASE
      WHEN NEW.status IN ('completed', 'ready', 'returned') THEN now()
      ELSE NULL
    END,
    CASE
      WHEN NEW.status IN ('completed', 'ready', 'returned') THEN now()
      ELSE NULL
    END,
    shipment_delivered_at,
    NEW.created_at,
    now()
  FROM generate_series(1, unit_count) AS generated_index
  ON CONFLICT (sale_order_item_id, unit_index) DO NOTHING;

  UPDATE public.sale_order_item_units
  SET
    site_id = NEW.site_id,
    quantity = unit_quantity,
    shipment_id = NEW.shipment_id,
    delivered_at = shipment_delivered_at,
    started_at = COALESCE(NEW.sent_at, started_at, NEW.created_at),
    status = CASE WHEN status_changed THEN NEW.status ELSE status END
  WHERE sale_order_item_id = NEW.id
    AND unit_index <= unit_count;

  DELETE FROM public.sale_order_item_units
  WHERE sale_order_item_id = NEW.id
    AND unit_index > unit_count;

  RETURN NEW;
END;
$$;


--
-- Name: sync_site_members_license_json(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_site_members_license_json(p_site_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  UPDATE public.settings SET team_members = (
    SELECT coalesce(jsonb_agg(jsonb_build_object('email',sm.email,'role',CASE sm.role
      WHEN 'admin' THEN 'admin' WHEN 'marketing' THEN 'create' ELSE 'view' END,
      'name',coalesce(sm.name,''),'position',coalesce(sm.position,'')) ORDER BY sm.created_at,sm.id),'[]')
    FROM public.site_members sm WHERE sm.site_id = p_site_id AND sm.status = 'active'
      AND sm.role <> 'owner' AND public.site_member_has_effective_license(sm.id)
  ) WHERE site_id = p_site_id;
$$;


--
-- Name: sync_site_members_to_settings(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_site_members_to_settings() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE affected_site_id uuid; team_members_json jsonb;
BEGIN
  affected_site_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.site_id ELSE NEW.site_id END;
  IF current_setting('app.deleting_site',true) = affected_site_id::text OR
    NOT EXISTS (SELECT 1 FROM public.sites WHERE id = affected_site_id) THEN
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF; RETURN NEW;
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object('email',sm.email,'role',CASE sm.role
    WHEN 'admin' THEN 'admin' WHEN 'marketing' THEN 'create' ELSE 'view' END,
    'name',coalesce(sm.name,''),'position',coalesce(sm.position,'')) ORDER BY sm.created_at,sm.id),'[]')
    INTO team_members_json FROM public.site_members sm
    WHERE sm.site_id = affected_site_id AND sm.status = 'active' AND sm.role <> 'owner' AND public.site_member_has_effective_license(sm.id);
  UPDATE public.settings SET team_members = team_members_json,updated_at = now() WHERE site_id = affected_site_id;
  IF NOT FOUND THEN
    INSERT INTO public.settings(site_id,team_members,created_at,updated_at) VALUES (affected_site_id,team_members_json,now(),now())
      ON CONFLICT(site_id) DO UPDATE SET team_members = excluded.team_members,updated_at = now();
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END;
$$;


--
-- Name: sync_site_members_to_team_members(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_site_members_to_team_members() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  -- Preserve the existing recursion sentinel (not an authorization bypass).
  IF current_setting('site_members.is_updating',true) = 'true' THEN RETURN NULL; END IF;
  PERFORM set_config('site_members.is_updating','true',true);
  PERFORM public.sync_site_members_license_json(CASE WHEN TG_OP = 'DELETE' THEN OLD.site_id ELSE NEW.site_id END);
  PERFORM set_config('site_members.is_updating','false',true);
  RETURN NULL;
END;
$$;


--
-- Name: sync_site_ownership(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_site_ownership() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    INSERT INTO public.site_ownership(site_id, user_id)
    VALUES (NEW.id, NEW.user_id)
    ON CONFLICT (site_id) DO UPDATE SET user_id = EXCLUDED.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.site_ownership WHERE site_id = OLD.id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: sync_stripe_subscription_state(uuid, text, text, text, text, timestamp with time zone, timestamp with time zone, timestamp with time zone, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_stripe_subscription_state(p_site_id uuid, p_customer_id text, p_subscription_id text, p_expected_subscription_id text, p_status text, p_current_period_end timestamp with time zone DEFAULT NULL::timestamp with time zone, p_start_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_end_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_auto_renew boolean DEFAULT true, p_invoice_id text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; v_status text := lower(p_status);
  s public.stripe_subscription_invoice_settlements%ROWTYPE;
BEGIN
  IF p_site_id IS NULL OR p_customer_id IS NULL OR p_customer_id !~ '^cus_[A-Za-z0-9]+$'
    OR p_subscription_id IS NULL OR p_subscription_id !~ '^sub_[A-Za-z0-9]+$'
    OR (p_expected_subscription_id IS NOT NULL AND p_expected_subscription_id !~ '^sub_[A-Za-z0-9]+$')
    OR v_status IS NULL OR v_status NOT IN
      ('active','trialing','past_due','unpaid','incomplete','paused','canceled','cancelled','incomplete_expired')
    OR (p_current_period_end IS NOT NULL AND NOT isfinite(p_current_period_end))
    OR (p_start_date IS NOT NULL AND NOT isfinite(p_start_date))
    OR (p_end_date IS NOT NULL AND NOT isfinite(p_end_date))
    OR (p_invoice_id IS NOT NULL AND p_invoice_id !~ '^in_[A-Za-z0-9]+$')
  THEN RAISE EXCEPTION 'Invalid verified Stripe subscription state'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Subscription site has no billing record'; END IF;
  IF b.stripe_customer_id IS DISTINCT FROM p_customer_id
  THEN RAISE EXCEPTION 'Stripe subscription billing identity mismatch'; END IF;
  IF p_invoice_id IS NOT NULL THEN
    SELECT * INTO s FROM public.stripe_subscription_invoice_settlements WHERE invoice_id = p_invoice_id;
    IF FOUND AND (s.site_id IS DISTINCT FROM p_site_id OR s.customer_id IS DISTINCT FROM p_customer_id
      OR s.subscription_id IS DISTINCT FROM p_subscription_id)
    THEN RAISE EXCEPTION 'Stripe invoice settlement identity mismatch'; END IF;
    -- Settlement and recovery hold this same billing lock when applying the
    -- marker. Reading it here closes the app pre-read -> status-sync race for
    -- both paid and failed retries without suppressing genuine lifecycle events.
    IF s.credit_coverage_applied AND b.stripe_subscription_id = p_subscription_id
      AND b.stripe_subscription_id IS NOT DISTINCT FROM p_expected_subscription_id THEN
      RETURN jsonb_build_object('outcome','synced','subscription_id',p_subscription_id,'invoice_sync_skipped',true);
    END IF;
  END IF;
  IF b.stripe_subscription_id IS DISTINCT FROM p_expected_subscription_id
    OR (b.stripe_subscription_id IS DISTINCT FROM p_subscription_id AND (
      v_status IN ('canceled','cancelled','incomplete_expired')
      OR (b.stripe_subscription_id IS NOT NULL AND lower(coalesce(b.subscription_status,''))
        NOT IN ('canceled','cancelled','incomplete_expired'))
      OR EXISTS (SELECT 1 FROM public.stripe_subscription_invoice_settlements
        WHERE site_id = p_site_id AND subscription_id = p_subscription_id)
      OR EXISTS (SELECT 1 FROM public.site_retired_stripe_subscriptions
        WHERE site_id = p_site_id AND subscription_id = p_subscription_id)))
    OR (b.stripe_subscription_id = p_subscription_id
      AND lower(coalesce(b.subscription_status,'')) IN ('canceled','cancelled','incomplete_expired')
      AND v_status NOT IN ('canceled','cancelled','incomplete_expired')) THEN
    RETURN jsonb_build_object('outcome','obsolete_subscription','subscription_id',b.stripe_subscription_id);
  END IF;
  UPDATE public.billing SET stripe_subscription_id = p_subscription_id,subscription_status = v_status,
    subscription_current_period_end = p_current_period_end,subscription_start_date = p_start_date,
    subscription_end_date = p_end_date,auto_renew = coalesce(p_auto_renew,true),updated_at = now()
    WHERE id = b.id;
  RETURN jsonb_build_object('outcome','synced','subscription_id',p_subscription_id);
END;
$_$;


--
-- Name: tenant_id_from_jwt(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tenant_id_from_jwt() RETURNS uuid
    LANGUAGE sql STABLE
    SET search_path TO 'pg_catalog'
    AS $$
  SELECT nullif(
    current_setting('request.jwt.claims', true)::jsonb->>'tenant_id',
    ''
  )::uuid;
$$;


--
-- Name: toggle_flag(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.toggle_flag(command_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16769($1); RETURN; END$_$;


--
-- Name: touch_sale_order_item_unit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_sale_order_item_unit() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NEW.status IN ('draft', 'new', 'pending') THEN
      NEW.in_progress_at := NULL;
      NEW.ready_at := NULL;
      NEW.completed_at := NULL;
      NEW.delivered_at := NULL;
    ELSIF NEW.status IN ('preparing', 'in_progress') THEN
      NEW.in_progress_at := COALESCE(NEW.in_progress_at, now());
      NEW.ready_at := NULL;
      NEW.completed_at := NULL;
      NEW.delivered_at := NULL;
    ELSIF NEW.status IN ('completed', 'ready') THEN
      NEW.in_progress_at := COALESCE(NEW.in_progress_at, NEW.started_at);
      NEW.ready_at := COALESCE(NEW.ready_at, NEW.completed_at, now());
      NEW.completed_at := NEW.ready_at;
    ELSIF NEW.status = 'returned' THEN
      NEW.in_progress_at := COALESCE(NEW.in_progress_at, NEW.started_at);
      NEW.ready_at := COALESCE(NEW.ready_at, NEW.completed_at, now());
      NEW.completed_at := NEW.ready_at;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: track_requirement_economic_pause(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.track_requirement_economic_pause() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF TG_TABLE_NAME='requirements' THEN
    -- Even SET status='blocked' on an already blocked row is a new manual stop.
    DELETE FROM public.requirement_economic_pauses WHERE requirement_id=NEW.id;
  ELSE
    PERFORM public.capture_requirement_economic_pause(NEW.id);
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: transfer_location_inventory(uuid, uuid, uuid, uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.transfer_location_inventory(p_site_id uuid, p_catalog_item_id uuid, p_from_location_id uuid, p_to_location_id uuid, p_quantity numeric) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
DECLARE source_quantity numeric; target_quantity numeric;
BEGIN
  IF current_setting('transaction_isolation') <> 'read committed' THEN
    RAISE EXCEPTION 'Inventory transfer requires READ COMMITTED' USING ERRCODE='40001';
  END IF;
  PERFORM public.lock_site_license(p_site_id);
  IF auth.uid() IS NULL OR current_setting('role',true) <> 'authenticated'
    OR NOT coalesce(public.user_can(p_site_id,'update'),false)
    OR NOT public.user_can_access_location(p_site_id,p_from_location_id)
    OR NOT public.user_can_access_location(p_site_id,p_to_location_id) THEN
    RAISE EXCEPTION 'Inventory transfer access denied' USING ERRCODE='42501';
  END IF;
  IF p_from_location_id IS NULL OR p_to_location_id IS NULL
    OR p_from_location_id=p_to_location_id OR p_quantity IS NULL
    OR p_quantity::text IN ('NaN','Infinity','-Infinity') OR p_quantity<=0 OR p_quantity>1000000000 THEN
    RAISE EXCEPTION 'Two distinct locations and a positive finite quantity are required' USING ERRCODE='22023';
  END IF;
  -- Serialize per catalog item, including creation of a missing destination row.
  -- The source and destination mutate in one transaction, never sequential HTTP.
  PERFORM 1 FROM public.catalog_items WHERE id=p_catalog_item_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Catalog item must belong to this site' USING ERRCODE='22023'; END IF;
  PERFORM 1 FROM public.inventory_levels WHERE site_id=p_site_id
    AND catalog_item_id=p_catalog_item_id AND location_id IN (p_from_location_id,p_to_location_id)
    ORDER BY location_id FOR UPDATE;
  SELECT quantity INTO source_quantity FROM public.inventory_levels
    WHERE site_id=p_site_id AND catalog_item_id=p_catalog_item_id AND location_id=p_from_location_id;
  IF source_quantity IS NULL OR source_quantity<p_quantity THEN
    RAISE EXCEPTION 'Insufficient inventory' USING ERRCODE='22023';
  END IF;
  INSERT INTO public.inventory_levels(site_id,catalog_item_id,location_id,quantity)
    VALUES(p_site_id,p_catalog_item_id,p_to_location_id,0)
    ON CONFLICT (catalog_item_id,location_id) DO NOTHING;
  IF NOT EXISTS(SELECT 1 FROM public.inventory_levels WHERE site_id=p_site_id
    AND catalog_item_id=p_catalog_item_id AND location_id=p_to_location_id) THEN
    RAISE EXCEPTION 'Inventory destination tenant is inconsistent' USING ERRCODE='23503';
  END IF;
  UPDATE public.inventory_levels SET quantity=quantity-p_quantity,updated_at=clock_timestamp()
    WHERE site_id=p_site_id AND catalog_item_id=p_catalog_item_id AND location_id=p_from_location_id
    RETURNING quantity INTO source_quantity;
  UPDATE public.inventory_levels SET quantity=quantity+p_quantity,updated_at=clock_timestamp()
    WHERE site_id=p_site_id AND catalog_item_id=p_catalog_item_id AND location_id=p_to_location_id
    RETURNING quantity INTO target_quantity;
  RETURN jsonb_build_object('from_quantity',source_quantity,'to_quantity',target_quantity);
END;
$$;

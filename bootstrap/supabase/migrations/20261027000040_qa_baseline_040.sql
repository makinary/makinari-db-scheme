SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: ingest_marketplace_event(uuid, text, jsonb, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ingest_marketplace_event(p_integration_id uuid, p_event_key text, p_order jsonb, p_event_at timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
<<import_vars>>
DECLARE integration public.marketplace_integrations; receipt public.marketplace_events;
  native_order public.sale_orders; order_id uuid; sale_id uuid; shipment_id uuid;
  external_id text := p_order->>'external_order_id'; kind text := coalesce(p_order->>'event_kind','order');
  state text := p_order->>'status'; prior_state text; native_status text; line_status text;
  marketplace jsonb; delivery jsonb := p_order->'delivery'; item jsonb; line_id uuid;
  old_event_at timestamptz; item_ids uuid[] := ARRAY[]::uuid[]; can_replace boolean := true;
  native_items jsonb; modifier jsonb; modifier_id uuid; modifier_key text; modifier_node record; parent_id uuid;
  shipment_state text; delivery_event_at timestamptz; resolution text; courier_replaced boolean := false;
BEGIN
  IF NOT public.marketplace_is_backend() THEN
    RAISE EXCEPTION 'Marketplace ingestion requires backend' USING ERRCODE = '42501';
  END IF;
  IF jsonb_typeof(p_order) IS DISTINCT FROM 'object' OR octet_length(p_order::text) > 262144
    OR kind NOT IN ('order','snapshot','cancel','delivery','ignore') THEN RAISE EXCEPTION 'Invalid normalized event'; END IF;
  IF kind = 'snapshot' THEN kind := 'order'; END IF;
  IF kind = 'order' AND (p_order->>'fulfillment_method' IS NULL
    OR p_order->>'fulfillment_method' NOT IN ('delivery','pickup')
    OR (p_order->>'delivery_mode' IS NOT NULL AND p_order->>'delivery_mode' NOT IN ('marketplace_managed','merchant_managed'))
    OR jsonb_typeof(p_order->'totals_provisional') IS DISTINCT FROM 'boolean') THEN
    RAISE EXCEPTION 'Invalid normalized fulfillment';
  END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id = p_integration_id FOR UPDATE;
  IF NOT FOUND OR NOT integration.enabled OR NOT EXISTS (
    SELECT 1 FROM public.sites WHERE id = integration.site_id AND archived_at IS NULL
  ) THEN RAISE EXCEPTION 'Marketplace integration unavailable'; END IF;
  IF p_order->>'external_store_id' IS NOT NULL AND
    p_order->>'external_store_id' IS DISTINCT FROM integration.external_store_id THEN
    RAISE EXCEPTION 'Marketplace store mismatch';
  END IF;
  SELECT * INTO receipt FROM public.marketplace_events
    WHERE integration_id = p_integration_id AND event_key = p_event_key;
  IF FOUND THEN RETURN jsonb_build_object('order_id',receipt.order_id,'shipment_id',receipt.shipment_id,'duplicate',true); END IF;
  IF kind <> 'ignore' AND (external_id IS NULL OR length(external_id) NOT BETWEEN 1 AND 200) THEN
    RAISE EXCEPTION 'External order identity required';
  END IF;
  SELECT * INTO native_order FROM public.sale_orders
    WHERE marketplace_integration_id = integration.id AND external_order_id = external_id FOR UPDATE;
  order_id := native_order.id; sale_id := native_order.sale_id;
  prior_state := native_order.metadata#>>'{marketplace,state}';
  old_event_at := (native_order.metadata#>>'{marketplace,event_at}')::timestamptz;
  IF p_event_at IS NOT NULL AND old_event_at IS NOT NULL AND p_event_at < old_event_at THEN can_replace := false; END IF;
  IF kind = 'order' AND coalesce((p_order->>'totals_provisional')::boolean,false)
    AND native_order.id IS NOT NULL AND native_order.metadata#>>'{marketplace,totals_provisional}' = 'false'
    THEN can_replace := false; END IF;
  IF kind = 'cancel' THEN state := 'cancelled'; END IF;
  IF kind = 'order' THEN
    IF state IS NULL OR state NOT IN ('pending','scheduled','accepted','ready','rejected','cancelled','completed')
      OR jsonb_typeof(p_order->'items') IS DISTINCT FROM 'array'
      OR jsonb_array_length(p_order->'items') > 200 OR p_order->>'currency' !~ '^[A-Z]{3}$'
      OR p_order->>'currency' IS NULL OR p_order->>'total' IS NULL
      OR (p_order->>'total')::numeric < 0 OR (p_order->>'subtotal')::numeric < 0
      OR (p_order->>'subtotal')::numeric IS NULL OR (p_order->>'discount_total')::numeric IS NULL
      OR (p_order->>'discount_total')::numeric < 0 THEN RAISE EXCEPTION 'Invalid normalized order'; END IF;
    SELECT coalesce(jsonb_agg(jsonb_build_object('id',value->>'external_id','name',value->>'name',
      'quantity',value->'quantity','unitPrice',value->'unit_price','subtotal',value->'total',
      'description',value->>'notes','metadata',jsonb_build_object('marketplace',value))),'[]'::jsonb) INTO native_items
      FROM jsonb_array_elements(p_order->'items');
    -- Cancel-before-order is a durable tombstone. Never reopen native cancelled
    -- orders, including definitive Rappi rejection. Later Uber deny may accept.
    IF EXISTS (SELECT 1 FROM public.marketplace_events WHERE integration_id = integration.id
      AND normalized_payload->>'external_order_id' = external_id
      AND normalized_payload->>'event_kind' = 'cancel') THEN state := 'cancelled'; END IF;
    IF native_order.status = 'cancelled' THEN state := coalesce(prior_state,'cancelled');
    ELSIF prior_state = 'completed' AND state <> 'cancelled' THEN state := 'completed';
    ELSIF prior_state = 'ready' AND state IN ('pending','scheduled','accepted') THEN state := prior_state;
    ELSIF prior_state IN ('accepted','rejected') AND state IN ('pending','scheduled') THEN state := prior_state; END IF;
    IF NOT can_replace THEN state := prior_state; END IF;
  END IF;
  IF kind IN ('order','cancel') AND (kind = 'order' OR order_id IS NOT NULL) AND can_replace THEN
    marketplace := coalesce(native_order.metadata->'marketplace','{}'::jsonb)
      || coalesce(p_order#>'{metadata,marketplace}','{}'::jsonb)
      || jsonb_build_object('provider',integration.provider,'external_order_id',external_id,
        'external_store_id',integration.external_store_id,'state',state,'delivery_mode',
        coalesce(p_order->>'delivery_mode',native_order.metadata#>>'{marketplace,delivery_mode}','marketplace_managed'),
        'sync_status','confirmed','capabilities',public.marketplace_capabilities(integration.provider,state,integration.manual_ready));
    IF kind = 'order' THEN marketplace := marketplace||jsonb_strip_nulls(jsonb_build_object(
      'display_id',p_order->>'display_id','totals_provisional',p_order->'totals_provisional',
      'customer',p_order->'customer','accept_by',p_order->>'accept_by','scheduled_at',p_order->>'scheduled_at',
      'marketplace_totals',p_order->'marketplace_totals')); END IF;
    IF p_event_at IS NOT NULL THEN marketplace := marketplace||jsonb_build_object('event_at',p_event_at); END IF;
    IF state IN ('accepted','ready','completed') AND native_order.metadata#>>'{marketplace,accepted_at}' IS NULL THEN
      marketplace := marketplace||jsonb_build_object('accepted_at',now());
    END IF;
    -- Do not lose an unresolved operation just because an unrelated delivery or
    -- duplicate state webhook arrives. Authoritative state can resolve it only
    -- when matching the claimed transition (or terminal cancellation).
    IF native_order.metadata#>>'{marketplace,operation,status}' IN ('pending','unknown') THEN
      resolution := CASE
        WHEN state = 'cancelled' THEN CASE
          WHEN native_order.metadata#>>'{marketplace,operation,action}' IN ('cancel','reject') THEN 'confirmed'
          ELSE 'failed' END
        WHEN native_order.metadata#>>'{marketplace,operation,action}' = 'accept' AND state IN ('accepted','ready','completed') THEN 'confirmed'
        WHEN native_order.metadata#>>'{marketplace,operation,action}' = 'ready' AND state IN ('ready','completed') THEN 'confirmed'
        WHEN native_order.metadata#>>'{marketplace,operation,action}' = 'reject' AND state = 'rejected' THEN 'confirmed'
        ELSE NULL END;
      IF resolution IS NOT NULL THEN
        UPDATE public.marketplace_actions SET status = resolution,finished_at = now()
          WHERE marketplace_actions.order_id = native_order.id AND status IN ('pending','unknown');
        marketplace := marketplace || jsonb_build_object('operation',
          (native_order.metadata#>'{marketplace,operation}')||jsonb_build_object('status',resolution));
      ELSE
        marketplace := marketplace || jsonb_build_object('sync_status',native_order.metadata#>>'{marketplace,sync_status}',
          'operation',native_order.metadata#>'{marketplace,operation}');
      END IF;
    END IF;
    native_status := public.marketplace_native_state(state,integration.provider);
    line_status := CASE WHEN native_status = 'draft' THEN 'draft' WHEN native_status = 'cancelled' THEN 'cancelled'
      WHEN state IN ('ready','completed') THEN 'completed' ELSE 'new' END;
    IF order_id IS NULL THEN
      sale_id := gen_random_uuid(); order_id := gen_random_uuid();
      INSERT INTO public.sales(id,site_id,user_id,title,product_name,amount,amount_due,currency,status,
        source,payment_method,payment_details,product_details,sale_date)
      VALUES(sale_id,integration.site_id,integration.created_by_user_id,
        'Marketplace order '||coalesce(p_order->>'display_id',external_id),'Marketplace order',
        (p_order->>'total')::numeric,0,p_order->>'currency','pending','online','external',
        jsonb_build_object('marketplace',jsonb_build_object('provider',integration.provider,
          'integration_id',integration.id,'external_order_id',external_id,'payment_managed_externally',true)),
        p_order->'items',now());
      INSERT INTO public.sale_orders(id,sale_id,site_id,user_id,order_number,items,subtotal,tax_total,
        discount_total,total,currency,status,notes,origin_location_id,fulfillment_method,shipping_address,metadata,
        marketplace_integration_id,external_order_id)
      VALUES(order_id,sale_id,integration.site_id,integration.created_by_user_id,
        integration.provider||'-'||external_id,native_items,(p_order->>'subtotal')::numeric,
        coalesce((p_order#>>'{marketplace_totals,tax}')::numeric,0),
        (p_order->>'discount_total')::numeric,(p_order->>'total')::numeric,p_order->>'currency',native_status,p_order->>'notes',
        integration.origin_location_id,CASE WHEN p_order->>'fulfillment_method' = 'delivery' THEN 'ship' ELSE 'pickup' END,
        CASE WHEN delivery->>'address' IS NOT NULL THEN jsonb_build_object('line1',delivery->>'address') END,
        jsonb_build_object('marketplace',marketplace),integration.id,external_id);
    ELSE
      UPDATE public.sale_orders SET status = native_status,
        metadata = coalesce(metadata,'{}'::jsonb)||jsonb_build_object('marketplace',marketplace),updated_at = now()
        WHERE id = order_id;
    END IF;
    IF kind = 'order' THEN
      UPDATE public.sales SET amount = (p_order->>'total')::numeric,amount_due = 0,currency = p_order->>'currency',
        product_details = p_order->'items',updated_at = now() WHERE id = sale_id;
      UPDATE public.sale_orders SET items = native_items,subtotal = (p_order->>'subtotal')::numeric,
        tax_total = coalesce((p_order#>>'{marketplace_totals,tax}')::numeric,0),
        discount_total = (p_order->>'discount_total')::numeric,total = (p_order->>'total')::numeric,
        currency = p_order->>'currency',notes = p_order->>'notes',shipping_address = CASE WHEN delivery->>'address' IS NOT NULL
          THEN jsonb_build_object('line1',delivery->>'address') ELSE shipping_address END
        WHERE id = order_id;
      FOR item IN SELECT value FROM jsonb_array_elements(p_order->'items') LOOP
        IF length(coalesce(item->>'external_id','')) NOT BETWEEN 1 AND 200 OR length(coalesce(item->>'name','')) < 1
          OR (item->>'quantity')::numeric IS NULL OR (item->>'quantity')::numeric <= 0
          OR (item->>'quantity')::numeric > 1000 OR (item->>'unit_price')::numeric IS NULL
          OR (item->>'unit_price')::numeric < 0 OR (item->>'total')::numeric IS NULL OR (item->>'total')::numeric < 0
          THEN RAISE EXCEPTION 'Invalid normalized item'; END IF;
        SELECT id INTO line_id FROM public.sale_order_items WHERE sale_order_id = order_id
          AND metadata#>>'{marketplace,external_id}' = item->>'external_id';
        IF line_id IS NULL THEN
          line_id := gen_random_uuid();
          -- Unmapped catalog IDs intentionally NULL: snapshot prices/modifiers
          -- remain provider-owned, with no inventory or internal promotions.
          INSERT INTO public.sale_order_items(id,sale_order_id,site_id,name,description,quantity,unit_price,subtotal,status,location_id,metadata)
          VALUES(line_id,order_id,integration.site_id,item->>'name',item->>'notes',(item->>'quantity')::numeric,
            (item->>'unit_price')::numeric,(item->>'total')::numeric,line_status,integration.origin_location_id,
            jsonb_build_object('marketplace',item));
        ELSE
          UPDATE public.sale_order_items SET name = item->>'name',description = item->>'notes',quantity = (item->>'quantity')::numeric,
            unit_price = (item->>'unit_price')::numeric,subtotal = (item->>'total')::numeric,status = line_status,
            metadata = coalesce(metadata,'{}'::jsonb)||jsonb_build_object('marketplace',item) WHERE id = line_id;
        END IF;
        IF line_id = ANY(item_ids) THEN RAISE EXCEPTION 'Duplicate normalized item identity'; END IF;
        item_ids := array_append(item_ids,line_id);
        FOR modifier_node IN SELECT * FROM public.marketplace_modifier_nodes(item) LOOP
          modifier := modifier_node.modifier; modifier_key := modifier_node.external_key;
          IF modifier->>'external_id' IS NULL OR length(modifier_key) > 450
            OR length(coalesce(modifier->>'name','')) < 1 OR (modifier->>'quantity')::numeric IS NULL
            OR (modifier->>'quantity')::numeric <= 0 OR (modifier->>'quantity')::numeric > 1000
            OR (modifier->>'unit_price')::numeric IS NULL OR (modifier->>'unit_price')::numeric < 0
            OR (modifier->>'total')::numeric IS NULL OR (modifier->>'total')::numeric < 0
            THEN RAISE EXCEPTION 'Invalid normalized modifier'; END IF;
          SELECT id INTO parent_id FROM public.sale_order_items WHERE sale_order_id = order_id
            AND metadata#>>'{marketplace,external_id}' = modifier_node.parent_key;
          SELECT id INTO modifier_id FROM public.sale_order_items WHERE sale_order_id = order_id
            AND metadata#>>'{marketplace,external_id}' = modifier_key;
          IF modifier_id IS NULL THEN
            modifier_id := gen_random_uuid();
            INSERT INTO public.sale_order_items(id,sale_order_id,site_id,name,quantity,unit_price,subtotal,status,
              location_id,parent_sale_order_item_id,metadata)
            VALUES(modifier_id,order_id,integration.site_id,modifier->>'name',(modifier->>'quantity')::numeric,
              (modifier->>'unit_price')::numeric,CASE WHEN modifier_node.included
                THEN 0 ELSE (modifier->>'total')::numeric END,line_status,integration.origin_location_id,parent_id,
              jsonb_build_object('is_modifier',true,'marketplace',modifier||jsonb_build_object('external_id',modifier_key)));
          ELSE
            UPDATE public.sale_order_items SET name = modifier->>'name',quantity = (modifier->>'quantity')::numeric,
              unit_price = (modifier->>'unit_price')::numeric,subtotal = CASE
                WHEN modifier_node.included THEN 0 ELSE (modifier->>'total')::numeric END,
              status = line_status,metadata = jsonb_build_object('is_modifier',true,'marketplace',
                modifier||jsonb_build_object('external_id',modifier_key)) WHERE id = modifier_id;
          END IF;
          IF modifier_id = ANY(item_ids) THEN RAISE EXCEPTION 'Duplicate normalized modifier identity'; END IF;
          item_ids := array_append(item_ids,modifier_id);
        END LOOP;
      END LOOP;
      DELETE FROM public.sale_order_items WHERE sale_order_id = order_id AND NOT(id = ANY(item_ids));
    ELSE UPDATE public.sale_order_items SET status = line_status WHERE sale_order_id = order_id; END IF;
  END IF;
  SELECT id INTO shipment_id FROM public.shipments WHERE sale_order_id = order_id AND marketplace_integration_id = integration.id;
  SELECT (metadata#>>'{marketplace,event_at}')::timestamptz INTO delivery_event_at FROM public.shipments WHERE id = shipment_id;
  IF delivery IS NULL AND kind = 'order' THEN
    SELECT normalized_payload->'delivery' INTO delivery FROM public.marketplace_events
      WHERE integration_id = integration.id AND normalized_payload->>'external_order_id' = external_id
        AND normalized_payload->'delivery' IS NOT NULL ORDER BY event_at DESC NULLS LAST,created_at DESC LIMIT 1;
  END IF;
  IF order_id IS NOT NULL AND can_replace AND (delivery IS NOT NULL OR
    (kind = 'order' AND p_order->>'fulfillment_method' = 'delivery'))
    AND (p_event_at IS NULL OR delivery_event_at IS NULL OR p_event_at >= delivery_event_at) THEN
    marketplace := jsonb_build_object('provider',integration.provider,'external_order_id',external_id,
      'external_store_id',integration.external_store_id,'state',coalesce(state,prior_state),'sync_status','confirmed',
      'delivery_mode',coalesce(p_order->>'delivery_mode',native_order.metadata#>>'{marketplace,delivery_mode}','marketplace_managed'),
      'capabilities',jsonb_build_object('request_delivery',false,'cancel_delivery',false))
      || jsonb_strip_nulls(jsonb_build_object('courier',delivery->'courier','delivery_status',delivery->>'status',
        'provider_event',delivery->>'provider_event',
        'estimated_arrival_at',delivery->>'estimated_arrival_at','eta_minutes',delivery->'eta_minutes'));
    IF p_event_at IS NOT NULL THEN marketplace := marketplace||jsonb_build_object('event_at',p_event_at); END IF;
    -- Only explicit provider delivery states map to native milestones; no
    -- acceptance, visibility, courier assignment or guessed ETA means delivered.
    shipment_state := CASE upper(delivery->>'status')
      WHEN 'DELIVERED' THEN 'delivered' WHEN 'COMPLETED' THEN 'delivered'
      WHEN 'DROPOFF_COMPLETED' THEN 'delivered' WHEN 'IN_TRANSIT' THEN 'in_transit'
      WHEN 'EN_ROUTE_TO_DROPOFF' THEN 'in_transit' WHEN 'PICKED_UP' THEN 'shipped'
      WHEN 'PREPARING' THEN 'preparing' WHEN 'CANCELLED' THEN 'cancelled' WHEN 'CANCELED' THEN 'cancelled'
      ELSE NULL END;
    IF integration.provider = 'rappi' AND delivery->>'provider_event' = 'hand_to_domiciliary' THEN
      shipment_state := 'shipped';
    END IF;
    IF shipment_id IS NULL THEN
      INSERT INTO public.shipments(site_id,sale_order_id,sale_id,origin_location_id,status,carrier,user_id,
        stock_decremented,metadata,marketplace_integration_id)
      VALUES(integration.site_id,order_id,sale_id,integration.origin_location_id,'pending',integration.provider,
        integration.created_by_user_id,false,jsonb_build_object('marketplace',marketplace),integration.id)
      RETURNING id INTO shipment_id;
    ELSE
      IF delivery->'courier' IS NOT NULL THEN
        courier_replaced := delivery#>>'{courier,id}' IS NOT NULL AND
          delivery#>>'{courier,id}' IS DISTINCT FROM
            (SELECT metadata#>>'{marketplace,courier,id}' FROM public.shipments WHERE id = shipment_id);
        marketplace := marketplace||jsonb_build_object('courier',
          CASE WHEN courier_replaced THEN '{}'::jsonb ELSE
            coalesce((SELECT metadata#>'{marketplace,courier}' FROM public.shipments WHERE id = shipment_id),'{}'::jsonb) END
          || jsonb_strip_nulls(delivery->'courier'));
      END IF;
      UPDATE public.shipments SET metadata = coalesce(metadata,'{}'::jsonb)||jsonb_build_object('marketplace',
        coalesce(metadata->'marketplace','{}'::jsonb)||marketplace),updated_at = now() WHERE id = shipment_id;
    END IF;
    UPDATE public.shipments SET status = CASE WHEN status IN ('delivered','cancelled') THEN status
        WHEN shipment_state IS NULL THEN status
        WHEN status = 'in_transit' AND shipment_state IN ('shipped','preparing') THEN status
        WHEN status = 'shipped' AND shipment_state = 'preparing' THEN status ELSE shipment_state END,
      last_lat = coalesce((delivery#>>'{courier,latitude}')::numeric,CASE WHEN courier_replaced THEN NULL ELSE last_lat END),
      last_lng = coalesce((delivery#>>'{courier,longitude}')::numeric,CASE WHEN courier_replaced THEN NULL ELSE last_lng END),
      last_located_at = CASE WHEN delivery#>>'{courier,latitude}' IS NOT NULL AND delivery#>>'{courier,longitude}' IS NOT NULL
        THEN coalesce(p_event_at,now()) WHEN courier_replaced THEN NULL ELSE last_located_at END,
      estimated_delivery_at = coalesce((delivery->>'estimated_arrival_at')::timestamptz,estimated_delivery_at),
      shipping_address = CASE WHEN delivery->>'address' IS NOT NULL THEN jsonb_build_object('line1',delivery->>'address') ELSE shipping_address END,
      delivered_at = CASE WHEN shipment_state = 'delivered' THEN coalesce(delivered_at,p_event_at,now()) ELSE delivered_at END
      WHERE id = shipment_id;
    UPDATE public.sale_order_items SET shipment_id = import_vars.shipment_id WHERE sale_order_id = order_id;
  END IF;
  IF state = 'cancelled' AND shipment_id IS NOT NULL AND can_replace THEN
    UPDATE public.shipments SET status = 'cancelled' WHERE id = shipment_id;
  END IF;
  IF kind IN ('order','cancel') AND shipment_id IS NOT NULL AND can_replace THEN
    SELECT metadata->'marketplace' INTO marketplace FROM public.sale_orders WHERE id = order_id;
    UPDATE public.shipments SET
      status = CASE WHEN status = 'pending' AND state IN ('accepted','ready') THEN 'preparing' ELSE status END,
      metadata = coalesce(metadata,'{}'::jsonb)||jsonb_build_object('marketplace',
        coalesce(metadata->'marketplace','{}'::jsonb)||jsonb_build_object(
          'state',state,'sync_status',marketplace->>'sync_status','operation',marketplace->'operation')),
      updated_at = now() WHERE id = shipment_id;
  END IF;
  INSERT INTO public.marketplace_events(integration_id,event_key,event_at,normalized_payload,order_id,shipment_id)
    VALUES(integration.id,p_event_key,p_event_at,p_order,order_id,shipment_id);
  RETURN jsonb_build_object('order_id',order_id,'shipment_id',shipment_id,'duplicate',false);
END;
$_$;


--
-- Name: initialize_site_billing(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.initialize_site_billing(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  b public.billing%ROWTYPE;
  v_inserted boolean := false;
  v_grant integer := public.site_plan_credit_allowance('commission', 0)::integer;
  v_month timestamptz := date_trunc('month', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
BEGIN
  -- Serialize all issuers without conflicting with ledger foreign-key locks.
  PERFORM 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NULL FOR NO KEY UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'error','Active site not found'); END IF;
  IF EXISTS (SELECT 1 FROM public.payments WHERE site_id = p_site_id AND payment_method = 'initial_credit') THEN
    v_grant := 0;
  END IF;
  INSERT INTO public.billing(site_id,plan,credits_available,credits_used,status,
    plan_credits_available,plan_credit_allowance,plan_credit_period_start,plan_credit_period_end,plan_credit_source)
    VALUES (p_site_id,'commission',v_grant,0,'active',v_grant,
      public.site_plan_credit_allowance('commission', 0),v_month,
      (v_month AT TIME ZONE 'UTC' + interval '1 month') AT TIME ZONE 'UTC','signup')
    ON CONFLICT (site_id) DO NOTHING RETURNING * INTO b;
  v_inserted := FOUND;
  IF NOT v_inserted THEN SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE; END IF;
  -- The source name stays compatible with same-period verified Stripe upgrades.
  -- A missing marker never authorizes refilling an existing, possibly spent row.
  IF NOT EXISTS (SELECT 1 FROM public.payments WHERE site_id = p_site_id AND payment_method = 'initial_credit') THEN
    INSERT INTO public.payments(site_id,transaction_id,transaction_type,amount,currency,status,payment_method,credits,details)
      VALUES (p_site_id,'initial_credit_' || p_site_id,'credit',0,'USD','completed','initial_credit',
        CASE WHEN v_inserted THEN v_grant ELSE 0 END,
        jsonb_build_object('note','Initial monthly Toolbox allowance','existing_billing',NOT v_inserted,
          'credit_bucket','plan','period_start',v_month,
          'period_end',(v_month AT TIME ZONE 'UTC' + interval '1 month') AT TIME ZONE 'UTC'));
  END IF;
  RETURN jsonb_build_object('success',true,'outcome',CASE WHEN v_inserted THEN 'initialized' ELSE 'already_initialized' END,
    'credits_granted',CASE WHEN v_inserted THEN v_grant ELSE 0 END,'billing_id',b.id,'credits_available',b.credits_available);
END;
$$;


--
-- Name: inspect_requirement_assistant_handoff(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inspect_requirement_assistant_handoff(p_requirement_id uuid, p_instance_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_requirement public.requirements%ROWTYPE;
  v_instance public.remote_instances%ROWTYPE;
  v_action public.instance_logs%ROWTYPE;
BEGIN
  SELECT * INTO v_requirement FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('allowed', false, 'reason', 'requirement_missing'); END IF;
  IF v_requirement.metadata->>'assistant_origin_instance_id' IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM public.remote_instances
      WHERE id::text = v_requirement.metadata->>'assistant_origin_instance_id'
        AND site_id = v_requirement.site_id) THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'assistant_origin_unavailable');
  END IF;
  IF v_requirement.metadata->>'runner_instance_id' IS NOT NULL
    AND v_requirement.metadata->>'runner_instance_id' IS DISTINCT FROM p_instance_id::text THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'runner_instance_owner_changed');
  END IF;
  SELECT * INTO v_instance FROM public.remote_instances
    WHERE id = p_instance_id AND site_id = v_requirement.site_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('allowed', false, 'reason', 'original_instance_unavailable'); END IF;
  IF v_instance.is_archived IS TRUE THEN
    -- This inspector runs before preparation, which may write backlog/resume
    -- state. Do not authorize that phase while an old assistant is still active.
    -- The replacement transaction repeats this check under row locks.
    SELECT * INTO v_action FROM public.instance_logs
      WHERE instance_id = p_instance_id AND site_id = v_requirement.site_id
        AND log_type = 'user_action' AND trusted_user_action IS TRUE
      ORDER BY created_at DESC, id DESC LIMIT 1;
    IF FOUND AND (COALESCE(v_action.details->>'status', '') NOT IN (
      'completed', 'failed', 'paused', 'stopped', 'cancelled'
    ) OR (v_action.details->>'status' NOT IN ('completed', 'failed')
      AND v_action.details->'assistant_recovery'->>'inFlight' = 'true')) THEN
      RETURN jsonb_build_object('allowed', false, 'reason', 'original_assistant_action_not_finished');
    END IF;
    RETURN jsonb_build_object('allowed', false, 'reason', 'original_instance_archived');
  END IF;
  IF v_instance.status IN ('paused', 'stopped', 'stopping') THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'original_instance_paused');
  END IF;
  -- Always honor the replacement runner's newest trusted action if one exists.
  SELECT * INTO v_action FROM public.instance_logs
    WHERE instance_id = p_instance_id AND site_id = v_requirement.site_id
      AND log_type = 'user_action' AND trusted_user_action IS TRUE
    ORDER BY created_at DESC, id DESC LIMIT 1;
  IF FOUND THEN
    IF COALESCE(v_action.details->>'status', '') NOT IN ('completed', 'failed') THEN
      RETURN jsonb_build_object('allowed', false, 'reason', 'assistant_action_not_finished');
    END IF;
    RETURN jsonb_build_object('allowed', true);
  END IF;
  IF v_requirement.metadata->>'assistant_origin_instance_id' IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.requirement_archived_runner_reassignments AS receipt
      WHERE receipt.requirement_id = p_requirement_id AND receipt.site_id = v_requirement.site_id
        AND receipt.instance_id = p_instance_id
        AND receipt.instance_id::text = v_requirement.metadata->>'runner_instance_id'
        AND CASE WHEN v_requirement.metadata->>'requirement_execution_generation' ~ '^[0-9]{1,10}$'
          THEN (v_requirement.metadata->>'requirement_execution_generation')::bigint
            BETWEEN receipt.execution_generation AND 2147483647
          ELSE false END) THEN
      RETURN jsonb_build_object('allowed', true);
    END IF;
    RETURN jsonb_build_object('allowed', false, 'reason', 'assistant_handoff_not_confirmed');
  END IF;
  RETURN jsonb_build_object('allowed', true);
END;
$_$;

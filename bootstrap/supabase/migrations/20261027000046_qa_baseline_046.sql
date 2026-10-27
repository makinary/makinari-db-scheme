SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: persist_tracking_event_batch(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.persist_tracking_event_batch(p_events jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_event jsonb;
  v_inserted integer := 0;
  v_total integer;
BEGIN
  IF p_events IS NULL OR pg_catalog.jsonb_typeof(p_events) <> 'array' THEN
    RAISE EXCEPTION 'Tracking batch must be a JSON array';
  END IF;

  v_total := pg_catalog.jsonb_array_length(p_events);
  IF v_total < 1 OR v_total > 100 THEN
    RAISE EXCEPTION 'Tracking batch must contain 1-100 events';
  END IF;

  FOR v_event IN
    SELECT value
    FROM pg_catalog.jsonb_array_elements(p_events)
  LOOP
    IF pg_catalog.jsonb_typeof(v_event) <> 'object'
      OR COALESCE(v_event->>'id', '')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR COALESCE(v_event->>'site_id', '')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR NULLIF(pg_catalog.btrim(v_event->>'event_type'), '') IS NULL
      OR COALESCE(v_event->>'timestamp', '') !~ '^[0-9]{1,19}$'
    THEN
      RAISE EXCEPTION 'Invalid tracking event';
    END IF;

    IF NULLIF(v_event->>'visitor_id', '') IS NOT NULL
      AND (v_event->>'visitor_id')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    THEN
      RAISE EXCEPTION 'Invalid tracking visitor';
    END IF;

    IF NULLIF(v_event->>'session_id', '') IS NOT NULL
      AND (v_event->>'session_id')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    THEN
      RAISE EXCEPTION 'Invalid tracking session';
    END IF;

    IF NULLIF(v_event->>'segment_id', '') IS NOT NULL
      AND (v_event->>'segment_id')
        !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    THEN
      RAISE EXCEPTION 'Invalid tracking segment';
    END IF;
  END LOOP;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_array_elements(p_events) AS item(value)
    WHERE NULLIF(item.value->>'session_id', '') IS NOT NULL
    GROUP BY item.value->>'session_id'
    HAVING pg_catalog.count(DISTINCT item.value->>'site_id') > 1
      OR pg_catalog.count(
        DISTINCT NULLIF(item.value->>'visitor_id', '')
      ) > 1
  ) THEN
    RAISE EXCEPTION 'Tracking batch has conflicting session ownership';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_array_elements(p_events) AS item(value)
    JOIN public.visitor_sessions AS session
      ON session.id = NULLIF(item.value->>'session_id', '')::uuid
    WHERE session.site_id <> (item.value->>'site_id')::uuid
      OR (
        NULLIF(item.value->>'visitor_id', '') IS NOT NULL
        AND session.visitor_id
          <> NULLIF(item.value->>'visitor_id', '')::uuid
      )
  ) THEN
    RAISE EXCEPTION 'Tracking session ownership conflict';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_to_recordset(p_events) AS item(
      id text,
      site_id text,
      event_type text,
      url text,
      visitor_id text,
      session_id text,
      "timestamp" bigint
    )
    JOIN public.session_events AS existing
      ON existing.id = item.id::uuid
    WHERE existing.site_id IS DISTINCT FROM item.site_id
      OR existing.event_type IS DISTINCT FROM item.event_type
      OR existing.url IS DISTINCT FROM item.url
      OR existing.visitor_id
        IS DISTINCT FROM NULLIF(item.visitor_id, '')::uuid
      OR existing.session_id
        IS DISTINCT FROM NULLIF(item.session_id, '')::uuid
      OR existing.timestamp IS DISTINCT FROM item."timestamp"
  ) THEN
    RAISE EXCEPTION 'Tracking event ID conflicts with existing event';
  END IF;

  INSERT INTO public.visitor_sessions (
    id,
    visitor_id,
    site_id,
    landing_url,
    current_url,
    referrer,
    started_at,
    last_activity_at,
    page_views,
    is_active
  )
  SELECT DISTINCT ON (session_id)
    session_id::uuid,
    visitor_id::uuid,
    site_id::uuid,
    url,
    url,
    referrer,
    item."timestamp",
    item."timestamp",
    1,
    true
  FROM pg_catalog.jsonb_to_recordset(p_events) AS item(
    session_id text,
    visitor_id text,
    site_id text,
    url text,
    referrer text,
    "timestamp" bigint
  )
  WHERE NULLIF(session_id, '') IS NOT NULL
    AND NULLIF(visitor_id, '') IS NOT NULL
  ORDER BY session_id, item."timestamp" ASC
  ON CONFLICT (id) DO NOTHING;

  WITH inserted AS (
    INSERT INTO public.session_events (
      id,
      site_id,
      event_type,
      event_name,
      url,
      referrer,
      visitor_id,
      session_id,
      segment_id,
      timestamp,
      properties,
      user_agent,
      ip,
      data
    )
    SELECT
      id::uuid,
      site_id,
      event_type,
      event_name,
      url,
      referrer,
      NULLIF(visitor_id, '')::uuid,
      NULLIF(session_id, '')::uuid,
      NULLIF(segment_id, '')::uuid,
      item."timestamp",
      COALESCE(properties, '{}'::jsonb),
      user_agent,
      ip,
      COALESCE(data, '{}'::jsonb)
    FROM pg_catalog.jsonb_to_recordset(p_events) AS item(
      id text,
      site_id text,
      event_type text,
      event_name text,
      url text,
      referrer text,
      visitor_id text,
      session_id text,
      segment_id text,
      "timestamp" bigint,
      properties jsonb,
      user_agent text,
      ip text,
      data jsonb
    )
    ON CONFLICT (id) DO NOTHING
    RETURNING 1
  )
  SELECT pg_catalog.count(*)::integer
  INTO v_inserted
  FROM inserted;

  RETURN pg_catalog.jsonb_build_object(
    'received', v_total,
    'inserted', v_inserted,
    'duplicates', v_total - v_inserted
  );
END;
$_$;


--
-- Name: pos_checkout_claim(uuid, text, uuid, uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_checkout_claim(p_site_id uuid, p_mutation_id text, p_actor_id uuid, p_order_id uuid, p_fingerprint text, p_owner_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE attempt public.pos_checkout_attempts%ROWTYPE;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Server checkout admission required' USING ERRCODE = '42501';
  END IF;
  -- Both identity and order admission are serialized. Unique indexes remain the
  -- final guard when another server attempts a different key for the same order.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_site_id::text || ':' || p_mutation_id,0));
  SELECT * INTO attempt FROM public.pos_checkout_attempts
    WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id FOR UPDATE;
  IF FOUND THEN
    IF attempt.actor_id IS DISTINCT FROM p_actor_id OR attempt.fingerprint IS DISTINCT FROM p_fingerprint
      OR attempt.requested_order_id IS DISTINCT FROM p_order_id THEN
      RETURN jsonb_build_object('state','identity_conflict');
    END IF;
    RETURN jsonb_build_object('state',attempt.state,'result',attempt.result,
      'orderId',attempt.order_id,'saleId',attempt.sale_id);
  END IF;
  IF p_order_id IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(hashtextextended(p_site_id::text || ':order:' || p_order_id::text,0));
    IF NOT EXISTS (SELECT 1 FROM public.sale_orders WHERE id=p_order_id AND site_id=p_site_id) THEN
      RETURN jsonb_build_object('state','identity_conflict');
    END IF;
    IF EXISTS (SELECT 1 FROM public.pos_checkout_attempts WHERE site_id=p_site_id AND order_id=p_order_id
      AND state IN ('processing','writes_started','review_required')) THEN
      RETURN jsonb_build_object('state','order_busy');
    END IF;
  END IF;
  INSERT INTO public.pos_checkout_attempts(site_id,client_mutation_id,actor_id,requested_order_id,order_id,fingerprint,owner_token,state)
    VALUES(p_site_id,p_mutation_id,p_actor_id,p_order_id,p_order_id,p_fingerprint,p_owner_token,'processing');
  RETURN jsonb_build_object('state','claimed');
END;
$$;


--
-- Name: pos_checkout_commit_order(uuid, text, uuid, uuid, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE attempt public.pos_checkout_attempts%ROWTYPE; saved_order public.sale_orders%ROWTYPE;
  saved_sale public.sales%ROWTYPE; next_sale public.sales%ROWTYPE; next_order public.sale_orders%ROWTYPE;
  previous_claims text; previous_role text;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Server checkout commit required' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO attempt FROM public.pos_checkout_attempts
    WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id AND owner_token=p_owner_token FOR UPDATE;
  IF NOT FOUND OR attempt.state <> 'writes_started' OR attempt.requested_order_id IS DISTINCT FROM p_order_id THEN
    RAISE EXCEPTION 'Checkout admission mismatch' USING ERRCODE = '42501';
  END IF;
  IF jsonb_typeof(p_sale_patch) IS DISTINCT FROM 'object' OR jsonb_typeof(p_order_patch) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid checkout patches' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO saved_order FROM public.sale_orders WHERE id=p_order_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Checkout order unavailable' USING ERRCODE = '22023'; END IF;
  SELECT * INTO saved_sale FROM public.sales WHERE id=saved_order.sale_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Checkout sale unavailable' USING ERRCODE = '22023'; END IF;
  next_sale := jsonb_populate_record(saved_sale,p_sale_patch);
  next_order := jsonb_populate_record(saved_order,p_order_patch);
  IF ROW(next_sale.id,next_sale.site_id,next_sale.location_id,next_sale.currency)
      IS DISTINCT FROM ROW(saved_sale.id,saved_sale.site_id,saved_sale.location_id,saved_sale.currency)
    OR ROW(next_order.id,next_order.site_id,next_order.sale_id)
      IS DISTINCT FROM ROW(saved_order.id,saved_order.site_id,saved_order.sale_id) THEN
    RAISE EXCEPTION 'Checkout scope is immutable' USING ERRCODE = '22023';
  END IF;
  -- Existing register/accounting/attribution triggers derive the actor from JWT.
  -- Bind that actor to server-owned admission and reauthorize inside this transaction.
  previous_claims := current_setting('request.jwt.claims',true);
  previous_role := current_setting('request.jwt.claim.role',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',attempt.actor_id,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.pos_register_authorize(p_site_id,attempt.actor_id);
  IF public.current_user_has_site_location_restrictions(p_site_id) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'Unrestricted checkout access required' USING ERRCODE = '42501';
  END IF;
  UPDATE public.sales SET lead_id=next_sale.lead_id,buyer_user_id=next_sale.buyer_user_id,
    owner_site_id=next_sale.owner_site_id,campaign_id=next_sale.campaign_id,segment_id=next_sale.segment_id,
    company_id=next_sale.company_id,title=next_sale.title,product_name=next_sale.product_name,
    amount=next_sale.amount,amount_due=next_sale.amount_due,user_id=next_sale.user_id,
    sale_date=next_sale.sale_date,source=next_sale.source,status=next_sale.status,
    payments=next_sale.payments,payment_method=next_sale.payment_method
    WHERE id=saved_sale.id RETURNING * INTO saved_sale;
  UPDATE public.sale_orders SET price_list_id=next_order.price_list_id,buyer_user_id=next_order.buyer_user_id,
    owner_site_id=next_order.owner_site_id,fulfillment_method=next_order.fulfillment_method,
    origin_location_id=next_order.origin_location_id,shipping_address=next_order.shipping_address,
    scheduled_for=next_order.scheduled_for,subtotal=next_order.subtotal,tax_total=next_order.tax_total,
    shipping_cost=next_order.shipping_cost,total=next_order.total,currency=next_order.currency,
    discount_total=next_order.discount_total,promotion_id=next_order.promotion_id,status=next_order.status,
    user_id=next_order.user_id,seller_user_id=next_order.seller_user_id,
    requested_by_lead_id=next_order.requested_by_lead_id,items=next_order.items,notes=next_order.notes
    WHERE id=saved_order.id RETURNING * INTO saved_order;
  UPDATE public.pos_checkout_attempts SET order_id=saved_order.id,sale_id=saved_sale.id,
    updated_at=clock_timestamp() WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id;
  PERFORM set_config('request.jwt.claims',coalesce(previous_claims,''),true);
  PERFORM set_config('request.jwt.claim.role',coalesce(previous_role,''),true);
  RETURN jsonb_build_object('sale',to_jsonb(saved_sale),'order',to_jsonb(saved_order));
END;
$$;


--
-- Name: pos_checkout_commit_order(uuid, text, uuid, uuid, jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb, p_expected_sale jsonb, p_expected_order jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE attempt public.pos_checkout_attempts%ROWTYPE; saved_order public.sale_orders%ROWTYPE;
  saved_sale public.sales%ROWTYPE; next_sale public.sales%ROWTYPE; next_order public.sale_orders%ROWTYPE;
  previous_claims text; previous_role text; previous_sub text;
  invalidate_mobile_checkout boolean := false;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Server checkout commit required' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO attempt FROM public.pos_checkout_attempts
    WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id AND owner_token=p_owner_token FOR UPDATE;
  IF NOT FOUND OR attempt.state <> 'writes_started' OR attempt.requested_order_id IS DISTINCT FROM p_order_id THEN
    RAISE EXCEPTION 'Checkout admission mismatch' USING ERRCODE = '42501';
  END IF;
  IF jsonb_typeof(p_sale_patch) IS DISTINCT FROM 'object' OR jsonb_typeof(p_order_patch) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid checkout patches' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO saved_order FROM public.sale_orders WHERE id=p_order_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Checkout order unavailable' USING ERRCODE = '22023'; END IF;
  SELECT * INTO saved_sale FROM public.sales WHERE id=saved_order.sale_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Checkout sale unavailable' USING ERRCODE = '22023'; END IF;
  IF jsonb_typeof(p_expected_sale) IS DISTINCT FROM 'object' OR jsonb_typeof(p_expected_order) IS DISTINCT FROM 'object'
    OR NOT p_expected_sale ?& ARRAY['amount','amount_due','payments']
    OR NOT p_expected_order ?& ARRAY['sale_id','status','total','currency','notes','updated_at']
    OR to_jsonb(saved_sale)->'payments' IS DISTINCT FROM p_expected_sale->'payments'
    OR NOT to_jsonb(saved_sale) @> p_expected_sale OR NOT to_jsonb(saved_order) @> p_expected_order THEN
    RAISE EXCEPTION 'Checkout balance or order changed before commit' USING ERRCODE = '40001';
  END IF;
  next_sale := jsonb_populate_record(saved_sale,p_sale_patch);
  next_order := jsonb_populate_record(saved_order,p_order_patch);
  IF ROW(next_sale.id,next_sale.site_id,next_sale.location_id,next_sale.currency)
      IS DISTINCT FROM ROW(saved_sale.id,saved_sale.site_id,saved_sale.location_id,saved_sale.currency)
    OR ROW(next_order.id,next_order.site_id,next_order.sale_id)
      IS DISTINCT FROM ROW(saved_order.id,saved_order.site_id,saved_order.sale_id) THEN
    RAISE EXCEPTION 'Checkout scope is immutable' USING ERRCODE = '22023';
  END IF;
  IF (next_sale.source IS DISTINCT FROM 'pos' AND NOT (
      saved_sale.source = 'shop' AND next_sale.source = 'shop'
      AND public.is_self_service_order_items(saved_order.items)
      AND public.is_self_service_order_items(next_order.items)))
    OR (public.is_self_service_order_items(saved_order.items) AND next_sale.source IS DISTINCT FROM saved_sale.source)
    OR next_sale.amount IS NULL OR next_sale.amount_due IS NULL
    OR next_sale.amount::text IN ('NaN','Infinity','-Infinity') OR next_sale.amount_due::text IN ('NaN','Infinity','-Infinity')
    OR next_sale.amount < 0 OR next_sale.amount_due < 0
    OR next_sale.amount_due > next_sale.amount OR next_order.currency IS DISTINCT FROM saved_order.currency THEN
    RAISE EXCEPTION 'Invalid checkout financial state' USING ERRCODE = '22023';
  END IF;
  -- Cash winning the sale lock invalidates both an already linked mobile session
  -- and a reserved session still being created. A later verified Stripe charge
  -- must enter the existing rejected-settlement compensation/refund path.
  IF public.is_self_service_order_items(saved_order.items)
    AND next_sale.amount_due < saved_sale.amount_due
    AND next_sale.payments IS DISTINCT FROM saved_sale.payments
    AND jsonb_typeof(next_sale.payments) = 'array' THEN
    invalidate_mobile_checkout := EXISTS (
      SELECT 1 FROM jsonb_array_elements(next_sale.payments) payment
      WHERE payment->>'status' = 'completed' AND payment->>'method' <> 'stripe'
        AND NOT EXISTS (
          SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(saved_sale.payments)='array'
            THEN saved_sale.payments ELSE '[]'::jsonb END) prior WHERE prior=payment
        )
    );
  END IF;
  -- Existing register/accounting/attribution triggers derive the actor from JWT.
  -- Bind that actor to server-owned admission and reauthorize inside this transaction.
  previous_claims := current_setting('request.jwt.claims',true);
  previous_role := current_setting('request.jwt.claim.role',true);
  previous_sub := current_setting('request.jwt.claim.sub',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',attempt.actor_id,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM set_config('request.jwt.claim.sub',attempt.actor_id::text,true);
  PERFORM public.pos_register_authorize(p_site_id,attempt.actor_id);
  IF public.current_user_has_site_location_restrictions(p_site_id) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'Unrestricted checkout access required' USING ERRCODE = '42501';
  END IF;
  UPDATE public.sales SET lead_id=next_sale.lead_id,buyer_user_id=next_sale.buyer_user_id,
    owner_site_id=next_sale.owner_site_id,campaign_id=next_sale.campaign_id,segment_id=next_sale.segment_id,
    company_id=next_sale.company_id,title=next_sale.title,product_name=next_sale.product_name,
    amount=next_sale.amount,amount_due=next_sale.amount_due,user_id=next_sale.user_id,
    sale_date=next_sale.sale_date,source=next_sale.source,status=next_sale.status,
    payments=next_sale.payments,payment_method=next_sale.payment_method,
    stripe_checkout_session_id=CASE WHEN invalidate_mobile_checkout THEN NULL ELSE saved_sale.stripe_checkout_session_id END,
    stripe_checkout_attempt=CASE WHEN invalidate_mobile_checkout THEN coalesce(saved_sale.stripe_checkout_attempt,0)+1
      ELSE saved_sale.stripe_checkout_attempt END
    WHERE id=saved_sale.id RETURNING * INTO saved_sale;
  UPDATE public.sale_orders SET price_list_id=next_order.price_list_id,buyer_user_id=next_order.buyer_user_id,
    owner_site_id=next_order.owner_site_id,fulfillment_method=next_order.fulfillment_method,
    origin_location_id=next_order.origin_location_id,shipping_address=next_order.shipping_address,
    scheduled_for=next_order.scheduled_for,subtotal=next_order.subtotal,tax_total=next_order.tax_total,
    shipping_cost=next_order.shipping_cost,total=next_order.total,currency=next_order.currency,
    discount_total=next_order.discount_total,promotion_id=next_order.promotion_id,status=next_order.status,
    user_id=next_order.user_id,seller_user_id=next_order.seller_user_id,
    requested_by_lead_id=next_order.requested_by_lead_id,items=next_order.items,notes=next_order.notes
    WHERE id=saved_order.id RETURNING * INTO saved_order;
  UPDATE public.pos_checkout_attempts SET order_id=saved_order.id,sale_id=saved_sale.id,
    updated_at=clock_timestamp() WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id;
  PERFORM set_config('request.jwt.claims',coalesce(previous_claims,''),true);
  PERFORM set_config('request.jwt.claim.role',coalesce(previous_role,''),true);
  PERFORM set_config('request.jwt.claim.sub',coalesce(previous_sub,''),true);
  RETURN jsonb_build_object('sale',to_jsonb(saved_sale),'order',to_jsonb(saved_order));
END;
$$;


--
-- Name: pos_checkout_transition(uuid, text, uuid, text, uuid, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_checkout_transition(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_state text, p_order_id uuid DEFAULT NULL::uuid, p_sale_id uuid DEFAULT NULL::uuid, p_result jsonb DEFAULT NULL::jsonb) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE attempt public.pos_checkout_attempts%ROWTYPE;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Server checkout transition required' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO attempt FROM public.pos_checkout_attempts
    WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id AND owner_token=p_owner_token FOR UPDATE;
  IF NOT FOUND THEN RETURN false; END IF;
  IF NOT ((attempt.state='processing' AND p_state IN ('writes_started','rejected'))
    OR (attempt.state='writes_started' AND p_state IN ('completed','review_required'))) THEN RETURN false; END IF;
  IF p_order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.sale_orders WHERE id=p_order_id AND site_id=p_site_id)
    OR p_sale_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.sales WHERE id=p_sale_id AND site_id=p_site_id) THEN
    RAISE EXCEPTION 'Checkout result scope mismatch' USING ERRCODE = '22023';
  END IF;
  UPDATE public.pos_checkout_attempts SET state=p_state,order_id=coalesce(p_order_id,order_id),
    sale_id=coalesce(p_sale_id,sale_id),result=p_result,updated_at=clock_timestamp()
    WHERE site_id=p_site_id AND client_mutation_id=p_mutation_id;
  RETURN true;
END;
$$;


--
-- Name: pos_register_authorize(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_authorize(p_site_id uuid, p_opened_by uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE actor uuid := auth.uid(); member_role text := public.current_user_site_role(p_site_id);
BEGIN
  IF actor IS NULL OR auth.role() IS DISTINCT FROM 'authenticated'
    OR member_role IS NULL OR member_role NOT IN ('owner','admin','collaborator')
    OR NOT EXISTS (SELECT 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NULL) THEN
    RAISE EXCEPTION 'Register access denied' USING ERRCODE = '42501';
  END IF;
  IF p_opened_by IS NOT NULL AND actor <> p_opened_by AND member_role NOT IN ('owner','admin') THEN
    RAISE EXCEPTION 'Only the register opener or a manager may mutate this session' USING ERRCODE = '42501';
  END IF;
  RETURN actor;
END;
$$;

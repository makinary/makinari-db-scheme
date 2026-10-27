SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: claim_marketplace_action(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_action(p_order_id uuid, p_action text, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Marketplace backend required' USING ERRCODE='42501'; END IF;
  SELECT i.* INTO integration FROM public.marketplace_integrations i JOIN public.sale_orders o
    ON o.marketplace_integration_id=i.id WHERE o.id=p_order_id FOR SHARE OF i;
  IF integration.merchant_connection_id IS NOT NULL AND (integration.provisioning_status<>'active'
    OR NOT EXISTS (SELECT 1 FROM public.marketplace_merchant_connections c WHERE c.id=integration.merchant_connection_id
      AND c.status='authorized'
      AND EXISTS (SELECT 1 FROM jsonb_array_elements(c.authorized_stores) store WHERE store->>'id'=integration.external_store_id))) THEN
    RAISE EXCEPTION 'Marketplace merchant connection is not active';
  END IF;
  RETURN public.claim_marketplace_action_active(p_order_id,p_action,p_actor_user_id);
END;
$$;


--
-- Name: claim_marketplace_action_active(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_action_active(p_order_id uuid, p_action text, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE native_order public.sale_orders; integration public.marketplace_integrations;
  operation public.marketplace_actions; marketplace jsonb; actor_role text;
BEGIN
  IF NOT public.marketplace_is_backend() THEN
    RAISE EXCEPTION 'Marketplace actions require backend' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO native_order FROM public.sale_orders WHERE id = p_order_id FOR UPDATE;
  IF NOT FOUND OR native_order.marketplace_integration_id IS NULL THEN RAISE EXCEPTION 'Marketplace order not found'; END IF;
  PERFORM public.marketplace_assert_actor(native_order.site_id,p_actor_user_id,false);
  IF EXISTS (SELECT 1 FROM public.site_members WHERE site_id = native_order.site_id AND user_id = p_actor_user_id
    AND restrict_to_assigned_only AND role NOT IN ('owner','admin'))
    AND NOT EXISTS (SELECT 1 FROM public.sites WHERE id = native_order.site_id AND user_id = p_actor_user_id)
    AND NOT EXISTS (SELECT 1 FROM public.site_ownership WHERE site_id = native_order.site_id AND user_id = p_actor_user_id) THEN
    RAISE EXCEPTION 'Marketplace operator must be assigned to this order' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO operation FROM public.marketplace_actions
    WHERE order_id = p_order_id AND status IN ('pending','unknown');
  IF FOUND THEN RETURN jsonb_build_object('action_id',operation.id,'duplicate',true,'order',to_jsonb(native_order),
    'operation',jsonb_build_object('action',operation.action,'status',operation.status)); END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id = native_order.marketplace_integration_id;
  marketplace := native_order.metadata->'marketplace';
  IF NOT integration.enabled OR p_action IS NULL OR p_action NOT IN ('accept','reject','ready','cancel')
    OR marketplace->>'sync_status' IS DISTINCT FROM 'confirmed'
    OR marketplace->>'state' IN ('scheduled','rejected','cancelled','completed')
    OR coalesce((marketplace->>'totals_provisional')::boolean,false)
    OR (marketplace#>>ARRAY['capabilities',p_action])::boolean IS DISTINCT FROM true
    OR (public.marketplace_capabilities(integration.provider,marketplace->>'state',integration.manual_ready)->>p_action)::boolean IS DISTINCT FROM true
    OR (p_action IN ('accept','reject') AND marketplace->>'accept_by' IS NOT NULL
      AND (marketplace->>'accept_by')::timestamptz <= now()) THEN
    RAISE EXCEPTION 'Marketplace action unavailable';
  END IF;
  INSERT INTO public.marketplace_actions(order_id,actor_user_id,action) VALUES(p_order_id,p_actor_user_id,p_action)
    RETURNING * INTO operation;
  marketplace := marketplace||jsonb_build_object('sync_status','pending','operation',
    jsonb_build_object('action',p_action,'status','pending'));
  UPDATE public.sale_orders SET metadata = metadata||jsonb_build_object('marketplace',marketplace),updated_at = now()
    WHERE id = p_order_id RETURNING * INTO native_order;
  RETURN jsonb_build_object('action_id',operation.id,'duplicate',false,'order',to_jsonb(native_order),
    'operation',jsonb_build_object('action',p_action,'status','pending'));
END;
$$;


--
-- Name: claim_marketplace_oauth(text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_oauth(p_state_hash text, p_provider text, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.marketplace_oauth_sessions;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'OAuth backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO session FROM public.marketplace_oauth_sessions WHERE state_hash = p_state_hash FOR UPDATE;
  IF NOT FOUND OR session.user_id IS DISTINCT FROM p_actor_user_id OR session.provider IS DISTINCT FROM p_provider
    OR session.status <> 'created' OR session.expires_at <= now() THEN
    RAISE EXCEPTION 'OAuth state unavailable' USING ERRCODE='42501';
  END IF;
  PERFORM public.marketplace_assert_actor(session.site_id,p_actor_user_id,true);
  UPDATE public.marketplace_oauth_sessions SET status='claimed',claimed_at=now() WHERE id=session.id RETURNING * INTO session;
  RETURN to_jsonb(session);
END;
$$;


--
-- Name: claim_marketplace_poll(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_poll(p_limit integer DEFAULT 3) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE claimed jsonb;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Marketplace polling requires backend' USING ERRCODE='42501'; END IF;
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 3 THEN RAISE EXCEPTION 'Invalid marketplace poll limit'; END IF;
  WITH eligible AS (
    SELECT i.id FROM public.marketplace_integrations i JOIN public.sites s ON s.id=i.site_id
    WHERE i.enabled AND s.archived_at IS NULL AND (i.last_polled_at IS NULL OR i.last_polled_at<=now()-interval '45 seconds')
      AND (i.merchant_connection_id IS NULL OR (i.provisioning_status='active' AND EXISTS (
        SELECT 1 FROM public.marketplace_merchant_connections c WHERE c.id=i.merchant_connection_id AND c.status='authorized'
          AND EXISTS (SELECT 1 FROM jsonb_array_elements(c.authorized_stores) store WHERE store->>'id'=i.external_store_id))))
    ORDER BY i.last_polled_at NULLS FIRST,i.id LIMIT p_limit FOR UPDATE OF i SKIP LOCKED
  ), changed AS (
    UPDATE public.marketplace_integrations i SET last_polled_at=now(),poll_sent_next=NOT i.poll_sent_next
    FROM eligible e WHERE i.id=e.id RETURNING i.id,i.provider,i.poll_sent_next
  ) SELECT coalesce(jsonb_agg(jsonb_build_object('integration_id',id,'provider',provider,
    'order_list',CASE WHEN poll_sent_next THEN 'new' ELSE 'sent' END)),'[]'::jsonb) INTO claimed FROM changed;
  RETURN claimed;
END;
$$;


--
-- Name: claim_marketplace_provisioning(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_provisioning(p_integration_id uuid, p_operation text, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations; connection public.marketplace_merchant_connections;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Provisioning backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO integration FROM public.marketplace_integrations WHERE id=p_integration_id FOR UPDATE;
  IF NOT FOUND OR integration.merchant_connection_id IS NULL THEN RAISE EXCEPTION 'Merchant integration unavailable'; END IF;
  PERFORM public.marketplace_assert_actor(integration.site_id,p_actor_user_id,true);
  IF p_operation IS NULL OR p_operation NOT IN ('activate','deactivate') THEN RAISE EXCEPTION 'Invalid provisioning operation'; END IF;
  IF integration.provisioning_status='pending' THEN
    RETURN jsonb_build_object('batch_id',integration.provisioning_claim_id,'duplicate',true,'integration',to_jsonb(integration));
  END IF;
  SELECT * INTO connection FROM public.marketplace_merchant_connections WHERE id=integration.merchant_connection_id FOR SHARE;
  IF connection.status<>'authorized' OR (connection.token_expires_at IS NOT NULL AND connection.token_expires_at<=now())
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(connection.authorized_stores) store WHERE store->>'id'=integration.external_store_id)
    THEN RAISE EXCEPTION 'Merchant authorization unavailable'; END IF;
  IF (p_operation='activate' AND integration.provisioning_status='active')
    OR (p_operation='deactivate' AND integration.provisioning_status='revoked') THEN
    RETURN jsonb_build_object('batch_id',integration.provisioning_claim_id,'duplicate',true,'integration',to_jsonb(integration));
  END IF;
  UPDATE public.marketplace_integrations SET provisioning_status='pending',provisioning_operation=p_operation,
    provisioning_claim_id=gen_random_uuid(),provider_batch_id=NULL,provisioning_result='pending',
    enabled=CASE WHEN p_operation='activate' THEN true ELSE enabled END,updated_at=now()
    WHERE id=integration.id RETURNING * INTO integration;
  RETURN jsonb_build_object('batch_id',integration.provisioning_claim_id,'duplicate',false,'integration',to_jsonb(integration));
END;
$$;


--
-- Name: claim_marketplace_webhook_registration(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_webhook_registration(p_scope jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE registration public.marketplace_webhook_registrations; duplicate boolean := false;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Webhook backend required' USING ERRCODE='42501'; END IF;
  IF jsonb_typeof(p_scope) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Invalid webhook app scope'; END IF;
  INSERT INTO public.marketplace_webhook_registrations(app_client_id_hash,provider,environment,country,integration_id,event)
  VALUES(p_scope->>'app_client_id_hash',p_scope->>'provider',p_scope->>'environment',p_scope->>'country',
    (p_scope->>'integration_id')::uuid,p_scope->>'event') ON CONFLICT DO NOTHING RETURNING * INTO registration;
  IF NOT FOUND THEN
    duplicate := true;
    SELECT * INTO registration FROM public.marketplace_webhook_registrations
      WHERE app_client_id_hash=p_scope->>'app_client_id_hash' AND provider=p_scope->>'provider'
        AND environment=p_scope->>'environment' AND country IS NOT DISTINCT FROM p_scope->>'country'
        AND integration_id IS NOT DISTINCT FROM (p_scope->>'integration_id')::uuid AND event=p_scope->>'event' FOR UPDATE;
  END IF;
  IF EXISTS (SELECT 1 FROM public.marketplace_provider_webhook_keys k WHERE k.app_client_id_hash=registration.app_client_id_hash
    AND k.provider=registration.provider AND k.environment=registration.environment
    AND k.country IS NOT DISTINCT FROM registration.country AND k.integration_id IS NOT DISTINCT FROM registration.integration_id
    AND k.event=registration.event) THEN
    duplicate := true;
    UPDATE public.marketplace_webhook_registrations SET status='ready',finished_at=coalesce(finished_at,now())
      WHERE claim_id=registration.claim_id RETURNING * INTO registration;
  END IF;
  RETURN jsonb_build_object('claim_id',registration.claim_id,'duplicate',duplicate,'status',registration.status);
END;
$$;


--
-- Name: claim_marketplace_webhook_registration(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE lease public.marketplace_webhook_registration_apps; acquired boolean := true;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Webhook backend required' USING ERRCODE='42501'; END IF;
  INSERT INTO public.marketplace_webhook_registration_apps(app_client_id_hash,provider,environment,country)
  VALUES(p_app_hash,p_provider,p_environment,p_country) ON CONFLICT DO NOTHING RETURNING * INTO lease;
  IF NOT FOUND THEN
    SELECT * INTO lease FROM public.marketplace_webhook_registration_apps WHERE app_client_id_hash=p_app_hash
      AND provider=p_provider AND environment=p_environment AND country IS NOT DISTINCT FROM p_country FOR UPDATE;
    IF lease.status='ready' THEN
      UPDATE public.marketplace_webhook_registration_apps SET status='running',claim_id=gen_random_uuid(),updated_at=now()
        WHERE claim_id=lease.claim_id RETURNING * INTO lease;
    ELSE acquired := false;
    END IF;
  END IF;
  RETURN jsonb_build_object('claim_id',lease.claim_id,'acquired',acquired,'status',lease.status);
END;
$$;


--
-- Name: claim_marketplace_webhook_registration(text, text, text, text, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text, p_actor_user_id uuid, p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  PERFORM public.marketplace_assert_actor(p_site_id,p_actor_user_id,true);
  RETURN public.claim_marketplace_webhook_registration(p_app_hash,p_provider,p_environment,p_country);
END;
$$;


--
-- Name: claim_migration_diagnostic(uuid, text, integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_lifecycle public.requirement_migration_lifecycle%ROWTYPE;
  v_result public.requirement_migration_diagnostics%ROWTYPE;
BEGIN
  IF p_expected_version IS NULL OR p_expected_version < 1 OR p_expected_version >= 2147483647 THEN
    RAISE EXCEPTION 'Invalid migration lifecycle version' USING ERRCODE = '22023';
  END IF;
  v_lifecycle := public.lock_requirement_migration_diagnostic_scope(
    p_requirement_id, p_file, p_execution_generation, p_run_id, true);
  IF v_lifecycle.version <> p_expected_version THEN
    RAISE EXCEPTION 'Migration lifecycle version conflict' USING ERRCODE = '40001';
  END IF;
  INSERT INTO public.requirement_migration_diagnostics (
    requirement_id, file, execution_generation, state, checksum, specification_checksum
  ) VALUES (
    p_requirement_id, p_file, p_execution_generation, 'running', v_lifecycle.checksum, v_lifecycle.specification_checksum
  ) ON CONFLICT (requirement_id, file) DO NOTHING RETURNING * INTO v_result;
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN to_jsonb(v_result);
END;
$$;


--
-- Name: claim_outstand_initial_import(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_outstand_initial_import(p_site_id uuid, p_account_id text, p_limit integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4248376($1,$2,$3); END$_$;


--
-- Name: claim_provider_webhook_event(text, text, text, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_provider_webhook_event(p_provider text, p_event_id text, p_event_type text, p_claim_token uuid, p_lease_seconds integer DEFAULT 300) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_new_expires_at timestamp with time zone;
  v_claim_expires_at timestamp with time zone;
  v_status text;
BEGIN
  IF p_provider IS NULL OR btrim(p_provider) = ''
    OR p_event_id IS NULL OR btrim(p_event_id) = ''
    OR p_event_type IS NULL OR btrim(p_event_type) = ''
    OR p_claim_token IS NULL
  THEN
    RAISE EXCEPTION 'Provider, event ID, event type, and claim token are required';
  END IF;
  IF p_lease_seconds IS NULL
    OR p_lease_seconds < 30
    OR p_lease_seconds > 3600
  THEN
    RAISE EXCEPTION 'Lease seconds must be between 30 and 3600';
  END IF;

  v_new_expires_at :=
    timezone('utc', now()) + make_interval(secs => p_lease_seconds);

  INSERT INTO private.provider_webhook_events (
    provider,
    event_id,
    event_type,
    status,
    claim_token,
    attempt_count,
    claimed_at,
    claim_expires_at
  )
  VALUES (
    p_provider,
    p_event_id,
    p_event_type,
    'processing',
    p_claim_token,
    1,
    timezone('utc', now()),
    v_new_expires_at
  )
  ON CONFLICT (provider, event_id) DO NOTHING
  RETURNING claim_expires_at INTO v_claim_expires_at;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'state', 'claimed',
      'claim_expires_at', v_claim_expires_at
    );
  END IF;

  UPDATE private.provider_webhook_events
  SET
    event_type = p_event_type,
    status = 'processing',
    claim_token = p_claim_token,
    attempt_count = attempt_count + 1,
    claimed_at = timezone('utc', now()),
    claim_expires_at = v_new_expires_at,
    completed_at = NULL,
    last_error = NULL,
    updated_at = timezone('utc', now())
  WHERE provider = p_provider
    AND event_id = p_event_id
    AND (
      status = 'failed'
      OR (
        status = 'processing'
        AND (
          claim_expires_at IS NULL
          OR claim_expires_at <= timezone('utc', now())
        )
      )
    )
  RETURNING claim_expires_at INTO v_claim_expires_at;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'state', 'claimed',
      'claim_expires_at', v_claim_expires_at
    );
  END IF;

  SELECT status
  INTO v_status
  FROM private.provider_webhook_events
  WHERE provider = p_provider
    AND event_id = p_event_id;

  IF v_status = 'completed' THEN
    RETURN jsonb_build_object('state', 'completed');
  END IF;
  RETURN jsonb_build_object('state', 'busy');
END;
$$;


--
-- Name: claim_quotation_checkout(uuid, uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_quotation_checkout(p_quotation_id uuid, p_site_id uuid, p_claim_id uuid, p_buyer_user_id uuid, p_public_access_token text) RETURNS TABLE(result text, sale_id uuid, order_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  quotation_row public.quotations%ROWTYPE;
  token_authorized boolean;
  buyer_authorized boolean;
BEGIN
  IF p_claim_id IS NULL THEN
    RETURN QUERY SELECT 'unauthorized'::text, NULL::uuid, NULL::uuid;
    RETURN;
  END IF;

  SELECT *
  INTO quotation_row
  FROM public.quotations
  WHERE id = p_quotation_id
  FOR UPDATE;

  IF NOT FOUND OR quotation_row.site_id <> p_site_id THEN
    RETURN QUERY SELECT 'not_found'::text, NULL::uuid, NULL::uuid;
    RETURN;
  END IF;

  token_authorized :=
    p_public_access_token IS NOT NULL
    AND p_public_access_token ~ '^[A-Za-z0-9_-]{20,64}$'
    AND quotation_row.public_access_token = p_public_access_token
    AND quotation_row.public_access_token_revoked_at IS NULL
    AND (
      quotation_row.public_access_token_expires_at IS NULL
      OR quotation_row.public_access_token_expires_at > now()
    );

  buyer_authorized :=
    p_public_access_token IS NULL
    AND p_buyer_user_id IS NOT NULL
    AND quotation_row.buyer_user_id IS NOT NULL
    AND quotation_row.buyer_user_id = p_buyer_user_id;

  IF NOT token_authorized AND NOT buyer_authorized THEN
    RETURN QUERY SELECT 'unauthorized'::text, NULL::uuid, NULL::uuid;
    RETURN;
  END IF;

  IF quotation_row.status = 'accepted'
     AND quotation_row.checkout_sale_id IS NOT NULL
     AND quotation_row.checkout_order_id IS NOT NULL THEN
    RETURN QUERY
      SELECT
        'completed'::text,
        quotation_row.checkout_sale_id,
        quotation_row.checkout_order_id;
    RETURN;
  END IF;

  IF quotation_row.status <> 'sent' THEN
    RETURN QUERY SELECT 'unavailable'::text, NULL::uuid, NULL::uuid;
    RETURN;
  END IF;

  IF quotation_row.valid_until IS NOT NULL
     AND quotation_row.valid_until < now() THEN
    RETURN QUERY SELECT 'expired'::text, NULL::uuid, NULL::uuid;
    RETURN;
  END IF;

  IF quotation_row.checkout_claim_id IS NULL
     OR quotation_row.checkout_claim_id = p_claim_id
     OR quotation_row.checkout_claimed_at IS NULL
     OR quotation_row.checkout_claimed_at < now() - interval '10 minutes' THEN
    UPDATE public.quotations
    SET
      checkout_claim_id = p_claim_id,
      checkout_claimed_at = now()
    WHERE id = p_quotation_id;

    RETURN QUERY
      SELECT
        'claimed'::text,
        quotation_row.checkout_sale_id,
        quotation_row.checkout_order_id;
    RETURN;
  END IF;

  RETURN QUERY
    SELECT
      'busy'::text,
      quotation_row.checkout_sale_id,
      quotation_row.checkout_order_id;
END;
$_$;

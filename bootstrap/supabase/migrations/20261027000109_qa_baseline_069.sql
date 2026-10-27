SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: validate_marketplace_consent(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_marketplace_consent() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Consent is backend-owned' USING ERRCODE='42501'; END IF;
  IF TG_TABLE_NAME='marketplace_oauth_sessions' AND TG_OP='UPDATE' THEN
    IF (to_jsonb(NEW)-ARRAY['status','claimed_at','finished_at','encrypted_context']) IS DISTINCT FROM
      (to_jsonb(OLD)-ARRAY['status','claimed_at','finished_at','encrypted_context'])
      OR (NEW.status IS DISTINCT FROM OLD.status AND NOT ((OLD.status='created' AND NEW.status IN ('claimed','failed'))
        OR (OLD.status='claimed' AND NEW.status IN ('completed','failed')))) THEN
      RAISE EXCEPTION 'OAuth state identity or lifecycle is immutable';
    END IF;
  ELSIF TG_TABLE_NAME='marketplace_merchant_connections' THEN
    IF TG_OP='UPDATE' AND ((to_jsonb(NEW)-ARRAY['status','encrypted_authorization','token_expires_at','authorized_stores','updated_at'])
      IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['status','encrypted_authorization','token_expires_at','authorized_stores','updated_at'])
      OR (OLD.status='revoked' AND NEW.status<>'revoked')) THEN RAISE EXCEPTION 'Merchant connection identity is immutable'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.marketplace_oauth_sessions s WHERE s.id=NEW.oauth_session_id
      AND (s.site_id,s.user_id,s.provider,s.environment,s.country,s.credential_mode) =
        (NEW.site_id,NEW.actor_user_id,NEW.provider,NEW.environment,NEW.country,NEW.credential_mode)
      AND s.status IN ('claimed','completed')) THEN RAISE EXCEPTION 'Merchant consent binding mismatch'; END IF;
    IF EXISTS (SELECT 1 FROM jsonb_array_elements(NEW.authorized_stores) store
      WHERE jsonb_typeof(store) IS DISTINCT FROM 'object' OR length(coalesce(store->>'id','')) NOT BETWEEN 1 AND 200) THEN
      RAISE EXCEPTION 'Invalid authorized store identity';
    END IF;
    IF NEW.status='revoked' AND EXISTS (SELECT 1 FROM public.marketplace_integrations i
      WHERE to_jsonb(i)->>'merchant_connection_id'=NEW.id::text AND i.enabled) THEN
      RAISE EXCEPTION 'Disable integrations before revoking consent';
    END IF;
  ELSIF TG_TABLE_NAME='marketplace_provider_webhook_keys' THEN
    IF TG_OP='UPDATE' THEN RAISE EXCEPTION 'Registered webhook key is immutable'; END IF;
    IF NEW.integration_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.marketplace_integrations i
      JOIN public.marketplace_merchant_connections c ON c.id=(to_jsonb(i)->>'merchant_connection_id')::uuid
      WHERE i.id=NEW.integration_id AND i.provider=NEW.provider AND i.environment=NEW.environment
        AND (NEW.country IS NULL OR i.country=NEW.country) AND c.app_client_id_hash=NEW.app_client_id_hash) THEN
      RAISE EXCEPTION 'Webhook key app scope mismatch';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_marketplace_integration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_marketplace_integration() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE connection public.marketplace_merchant_connections; binding_changed boolean := false;
BEGIN
  IF NOT public.marketplace_is_backend() THEN
    RAISE EXCEPTION 'Marketplace configuration is backend-owned' USING ERRCODE='42501';
  END IF;
  IF TG_OP='UPDATE' THEN
    IF (NEW.id,NEW.site_id,NEW.provider,NEW.environment,NEW.external_store_id,NEW.created_by_user_id)
      IS DISTINCT FROM (OLD.id,OLD.site_id,OLD.provider,OLD.environment,OLD.external_store_id,OLD.created_by_user_id) THEN
      RAISE EXCEPTION 'Marketplace integration identity is immutable';
    END IF;
    binding_changed := (NEW.secret_id,NEW.credential_mode,NEW.merchant_connection_id)
      IS DISTINCT FROM (OLD.secret_id,OLD.credential_mode,OLD.merchant_connection_id);
    IF binding_changed AND NOT EXISTS (SELECT 1 FROM public.marketplace_rebind_permits permit
      WHERE permit.id::text=current_setting('marketplace.rebind',true) AND permit.backend_pid=pg_backend_pid()
        AND permit.transaction_id=txid_current() AND permit.integration_id=NEW.id
        AND permit.connection_id=NEW.merchant_connection_id AND NEW.secret_id IS NULL) THEN
      RAISE EXCEPTION 'Marketplace integration identity is immutable';
    END IF;
    IF (binding_changed OR OLD.merchant_connection_id IS NOT NULL OR NEW.merchant_connection_id IS NOT NULL)
      AND NEW.country IS DISTINCT FROM OLD.country THEN RAISE EXCEPTION 'Merchant connection country is immutable'; END IF;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE id=NEW.origin_location_id AND site_id=NEW.site_id AND is_active)
    THEN RAISE EXCEPTION 'Marketplace location tenant mismatch'; END IF;
  IF NEW.credential_mode='custom' AND NEW.secret_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.site_secrets
    WHERE id=NEW.secret_id AND site_id=NEW.site_id AND provider=NEW.provider
      AND use_case='marketplace:'||NEW.id::text AND instance_id IS NULL) THEN
    RAISE EXCEPTION 'Marketplace native secret tenant mismatch';
  END IF;
  IF NEW.merchant_connection_id IS NOT NULL THEN
    SELECT * INTO connection FROM public.marketplace_merchant_connections WHERE id=NEW.merchant_connection_id FOR SHARE;
    IF NOT FOUND OR (connection.site_id,connection.provider,connection.environment,connection.country,connection.credential_mode)
      IS DISTINCT FROM (NEW.site_id,NEW.provider,NEW.environment,NEW.country,NEW.credential_mode)
      OR ((NEW.enabled OR TG_OP='INSERT' OR binding_changed) AND connection.status<>'authorized')
      OR ((TG_OP='INSERT' OR NEW.enabled OR binding_changed) AND NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(connection.authorized_stores) store WHERE store->>'id'=NEW.external_store_id)) THEN
      RAISE EXCEPTION 'Marketplace merchant authorization mismatch';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_marketplace_webhook_app_lease(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_marketplace_webhook_app_lease() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Webhook app lease is backend-owned' USING ERRCODE='42501'; END IF;
  IF TG_OP='UPDATE' AND ((to_jsonb(NEW)-ARRAY['claim_id','status','updated_at']) IS DISTINCT FROM
    (to_jsonb(OLD)-ARRAY['claim_id','status','updated_at']) OR (OLD.status='unknown' AND NEW.status<>'unknown')
    OR (NEW.claim_id IS DISTINCT FROM OLD.claim_id AND NOT (OLD.status='ready' AND NEW.status='running'))) THEN
    RAISE EXCEPTION 'Webhook app identity or lifecycle is immutable';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_marketplace_webhook_registration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_marketplace_webhook_registration() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'Webhook registration is backend-owned' USING ERRCODE='42501'; END IF;
  IF TG_OP='UPDATE' AND ((to_jsonb(NEW)-ARRAY['status','finished_at']) IS DISTINCT FROM
    (to_jsonb(OLD)-ARRAY['status','finished_at']) OR (OLD.status='ready' AND NEW.status<>'ready')
    OR (OLD.status='unknown' AND NEW.status='pending')) THEN
    RAISE EXCEPTION 'Webhook registration identity or lifecycle is immutable';
  END IF;
  IF NEW.integration_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.marketplace_integrations i
    JOIN public.marketplace_merchant_connections c ON c.id=i.merchant_connection_id WHERE i.id=NEW.integration_id
      AND c.app_client_id_hash=NEW.app_client_id_hash AND i.provider=NEW.provider AND i.environment=NEW.environment
      AND (NEW.country IS NULL OR i.country=NEW.country)) THEN RAISE EXCEPTION 'Webhook registration app scope mismatch'; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_notifications(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_notifications(notifications jsonb) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
BEGIN
  -- Check if notifications has the required structure
  RETURN (
    notifications ? 'email' AND
    notifications ? 'push' AND
    (notifications->>'email')::boolean IS NOT NULL AND
    (notifications->>'push')::boolean IS NOT NULL
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;


--
-- Name: validate_performance_bitmask(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_performance_bitmask() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  -- Verificar que like y dislike no estén activos simultáneamente
  IF (NEW.performance & 1) = 1 AND (NEW.performance & 2) = 2 THEN
    RAISE EXCEPTION 'Like y dislike no pueden estar activos simultáneamente';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_referral_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_referral_code(code_param text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16788($1); END$_$;


--
-- Name: validate_sale_order_attribution(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_sale_order_attribution() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.seller_user_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM public.sites
      WHERE id = NEW.site_id
        AND user_id = NEW.seller_user_id
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.site_members
      WHERE site_id = NEW.site_id
        AND user_id = NEW.seller_user_id
        AND status = 'active'
    )
  THEN
    RAISE EXCEPTION 'seller_user_id must be an active member of the order site';
  END IF;

  IF NEW.requested_by_lead_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM public.leads
      WHERE id = NEW.requested_by_lead_id
        AND site_id = NEW.site_id
    )
  THEN
    RAISE EXCEPTION 'requested_by_lead_id must belong to the order site';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: verify_consume_visitor_identity_challenge(uuid, uuid, uuid, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_consume_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_is_match boolean, p_trusted_token_hash text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_challenge public.visitor_identity_challenges%rowtype;
  v_session public.visitor_sessions%rowtype;
  v_now timestamptz := clock_timestamp();
  v_attempts integer;
begin
  perform public.assert_visitor_identity_service_role();
  perform pg_advisory_xact_lock(hashtextextended(
    p_session_id::text || ':' || p_challenge_id::text,
    0
  ));
  select * into v_session
  from public.visitor_sessions
  where id = p_session_id and site_id = p_site_id
  for update;
  if not found then
    return jsonb_build_object('status', 'invalid_session');
  end if;

  select * into v_challenge
  from public.visitor_identity_challenges
  where id = p_challenge_id and site_id = p_site_id and session_id = p_session_id
  for update;
  if not found
     or v_challenge.cancelled_at is not null
     or v_challenge.consumed_at is not null
     or v_challenge.expires_at <= v_now
     or v_challenge.attempts >= 5 then
    return jsonb_build_object('status', 'challenge_expired');
  end if;

  if not p_is_match then
    v_attempts := v_challenge.attempts + 1;
    update public.visitor_identity_challenges
    set attempts = v_attempts,
        cancelled_at = case when v_attempts >= 5 then v_now else cancelled_at end,
        updated_at = v_now
    where id = p_challenge_id;
    return jsonb_build_object(
      'status', case when v_attempts >= 5 then 'attempt_limit' else 'invalid_code' end,
      'attempts_remaining', greatest(0, 5 - v_attempts)
    );
  end if;

  update public.visitor_identity_challenges
  set consumed_at = v_now, updated_at = v_now
  where id = p_challenge_id;
  insert into public.visitor_session_identity_grants (
    site_id, session_id, visitor_id, lead_id, trusted_token_hash,
    granted_at, revoked_at, updated_at
  ) values (
    p_site_id, p_session_id, v_challenge.visitor_id, v_challenge.lead_id,
    p_trusted_token_hash, v_now, null, v_now
  )
  on conflict (session_id) do update set
    site_id = excluded.site_id,
    visitor_id = excluded.visitor_id,
    lead_id = excluded.lead_id,
    trusted_token_hash = excluded.trusted_token_hash,
    granted_at = excluded.granted_at,
    expires_at = null,
    revoked_at = null,
    updated_at = excluded.updated_at;
  update public.visitor_sessions
  set lead_id = v_challenge.lead_id,
      identified_at = (extract(epoch from v_now) * 1000)::bigint,
      updated_at = v_now
  where id = p_session_id and site_id = p_site_id;
  update public.visitors
  set lead_id = v_challenge.lead_id, is_identified = true
  where id = v_challenge.visitor_id;
  return jsonb_build_object('status', 'verified', 'lead_id', v_challenge.lead_id);
end;
$$;


--
-- Name: policy_originals; Type: TABLE; Schema: commerce_rls_private; Owner: -
--

CREATE TABLE commerce_rls_private.policy_originals (
    table_name text NOT NULL,
    relation_oid oid NOT NULL,
    policy_oid oid NOT NULL,
    original_using text NOT NULL,
    original_check text NOT NULL,
    original_roles oid[] NOT NULL,
    original_command "char" NOT NULL,
    original_permissive boolean NOT NULL,
    bounded_expression text NOT NULL,
    function_oid oid NOT NULL,
    function_body text NOT NULL,
    dependencies jsonb NOT NULL,
    installed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: links; Type: TABLE; Schema: location_acl_private; Owner: -
--

CREATE TABLE location_acl_private.links (
    child_table text NOT NULL,
    child_column text NOT NULL,
    parent_table text NOT NULL,
    required boolean DEFAULT false NOT NULL,
    same_location boolean DEFAULT false NOT NULL
);


--
-- Name: roots; Type: TABLE; Schema: location_acl_private; Owner: -
--

CREATE TABLE location_acl_private.roots (
    table_name text NOT NULL,
    location_column text NOT NULL
);


--
-- Name: scope_assignments; Type: TABLE; Schema: location_acl_private; Owner: -
--

CREATE TABLE location_acl_private.scope_assignments (
    transaction_id bigint NOT NULL,
    table_name text NOT NULL,
    row_id uuid NOT NULL,
    site_id uuid NOT NULL,
    location_id uuid NOT NULL,
    actor_id uuid NOT NULL
);


--
-- Name: provider_webhook_events; Type: TABLE; Schema: private; Owner: -
--

CREATE TABLE private.provider_webhook_events (
    provider text NOT NULL,
    event_id text NOT NULL,
    event_type text NOT NULL,
    status text NOT NULL,
    claim_token uuid,
    attempt_count integer DEFAULT 0 NOT NULL,
    claimed_at timestamp with time zone,
    claim_expires_at timestamp with time zone,
    completed_at timestamp with time zone,
    last_error text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT provider_webhook_events_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT provider_webhook_events_status_check CHECK ((status = ANY (ARRAY['processing'::text, 'completed'::text, 'failed'::text])))
);


--
-- Name: accounting_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    code text NOT NULL,
    key text,
    type text NOT NULL,
    label text NOT NULL,
    system boolean DEFAULT false,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT accounting_accounts_type_check CHECK ((type = ANY (ARRAY['asset'::text, 'liability'::text, 'equity'::text, 'income'::text, 'expense'::text])))
);


--
-- Name: accounting_sale_refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting_sale_refunds (
    id text NOT NULL,
    sale_id uuid NOT NULL,
    site_id uuid NOT NULL,
    amount numeric NOT NULL,
    currency text NOT NULL,
    refunded_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT accounting_sale_refunds_amount_check CHECK (((amount > (0)::numeric) AND (amount <= ('1000000000000'::bigint)::numeric) AND (amount = trunc(amount, 2)))),
    CONSTRAINT accounting_sale_refunds_currency_check CHECK ((currency ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT accounting_sale_refunds_id_check CHECK (((id ~ '^re_[A-Za-z0-9_]+$'::text) AND (length(id) <= 255))),
    CONSTRAINT accounting_sale_refunds_refunded_at_check CHECK (isfinite(refunded_at))
);


--
-- Name: activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    workflow_id character varying(255) NOT NULL,
    workflow_type character varying(100) NOT NULL,
    schedule_id character varying(255),
    status character varying(50) DEFAULT 'STARTED'::character varying NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    duration_ms integer,
    input_data jsonb,
    output_data jsonb,
    error_message text,
    error_details jsonb,
    retry_count integer DEFAULT 0,
    execution_context jsonb,
    metrics jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: agent_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_assets (
    agent_id uuid NOT NULL,
    asset_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid
);


--
-- Name: agent_channel_activation_context; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_channel_activation_context (
    transaction_id bigint NOT NULL,
    site_id uuid NOT NULL,
    connection_id text NOT NULL
);

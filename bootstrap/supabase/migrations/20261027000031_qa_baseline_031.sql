SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: enqueue_record_embedding_job(uuid, uuid[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[] DEFAULT '{}'::uuid[], p_replace boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_job_id uuid;
  v_site_id uuid;
  v_revision bigint;
  v_record_revision bigint;
BEGIN
  SELECT r.site_id, COALESCE(d.revision, 0), r.record_embedding_revision
  INTO v_site_id, v_revision, v_record_revision
  FROM public.records r
  LEFT JOIN public.record_diagrams d ON d.record_id = r.id
  WHERE r.id = p_record_id;

  IF v_site_id IS NULL THEN
    RAISE EXCEPTION 'Record not found';
  END IF;

  INSERT INTO public.record_embedding_jobs(
    record_id,
    site_id,
    diagram_revision,
    record_revision,
    node_ids,
    status,
    attempts,
    last_error,
    claimed_at,
    completed_at,
    updated_at
  )
  VALUES (
    p_record_id,
    v_site_id,
    v_revision,
    v_record_revision,
    COALESCE(p_node_ids, '{}'::uuid[]),
    'pending',
    0,
    NULL,
    NULL,
    NULL,
    now()
  )
  ON CONFLICT (record_id, diagram_revision, record_revision) DO UPDATE SET
    node_ids = CASE
      WHEN p_replace AND record_embedding_jobs.status = 'processing'
        THEN EXCLUDED.node_ids
      ELSE ARRAY(
        SELECT DISTINCT node_id
        FROM unnest(
          record_embedding_jobs.node_ids || EXCLUDED.node_ids
        ) AS ids(node_id)
      )
    END,
    status = 'pending',
    attempts = 0,
    last_error = NULL,
    claimed_at = NULL,
    completed_at = NULL,
    updated_at = now()
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$;


--
-- Name: ensure_api_key_not_expired(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_api_key_not_expired() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF NEW.expires_at IS NOT NULL AND NEW.expires_at < CURRENT_TIMESTAMP THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: evaluate_requirement_cycle_budget(uuid, text, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.evaluate_requirement_cycle_budget(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE observation jsonb;
BEGIN
  IF public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Requirement budget ownership changed' USING ERRCODE='42501';
  END IF;
  PERFORM 1 FROM public.requirements WHERE id=p_requirement_id FOR UPDATE;
  -- No monetary cap: avoid all historical aggregation in ordinary admission.
  -- Recovery still uses the full observation to inspect pending reservations.
  IF (SELECT budget IS NULL FROM public.requirements WHERE id=p_requirement_id) THEN
    RETURN jsonb_build_object('state','unlimited','budget_usd',NULL);
  END IF;
  observation:=public.requirement_budget_observation(p_requirement_id);
  IF observation->>'state'='exhausted' THEN
    IF public.finish_agent_requirement_cycle(p_requirement_id,p_run_id,p_generation,p_session_id,
      'paused','token_budget_exhausted',format(
        'Requirement monetary budget exhausted: %s USD charged / %s USD budget. Checked at cycle start.',
        observation->>'spent_usd',observation->>'budget_usd')) IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Requirement budget projection ownership changed' USING ERRCODE='42501';
    END IF;
  END IF;
  RETURN observation;
END;
$$;


--
-- Name: exchange_visitor_identity_token(uuid, uuid, uuid, text, text, bigint, uuid, bigint, bigint, text, text, text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exchange_visitor_identity_token(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_key_id uuid DEFAULT NULL::uuid, p_key_fingerprint text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  v_session public.visitor_sessions%rowtype;
  v_identity public.visitor_external_identities%rowtype;
  v_redemption public.visitor_identity_token_redemptions%rowtype;
  v_grant public.visitor_session_identity_grants%rowtype;
  v_epoch bigint;
  v_owner uuid;
  v_lead uuid;
  v_key_expiry timestamptz;
  v_now timestamptz;
begin
  perform public.assert_visitor_identity_service_role();
  -- Match logout lock order; serialize all grants against the canonical session.
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text, 0));
  select * into v_session from public.visitor_sessions
    where id = p_session_id and site_id = p_site_id and visitor_id = p_visitor_id for update;
  v_now := clock_timestamp();
  if not found or not coalesce(v_session.is_active, false) then
    return jsonb_build_object('status', 'invalid_session');
  end if;
  if p_issued_at is null or p_expires_at is null or p_expires_at - p_issued_at <> 90
    or to_timestamp(p_issued_at) > v_now or to_timestamp(p_expires_at) <= v_now
    or p_jti is null or p_token_hash is null or p_token_hash !~ '^[a-f0-9]{64}$'
    or p_subject is null or length(p_subject) not between 1 and 255
    or length(p_name) > 200 or length(p_email) > 320
    or p_issuer is null or not (
      p_issuer = 'integration:' || p_site_id::text
      or (p_issuer = 'supabase:rnjgeloamtszdjplmqxy'
        and p_site_id = '9be0a6a2-5567-41bf-ad06-cb4014f0faf2'::uuid)
    ) then return jsonb_build_object('status', 'invalid_token');
  end if;
  select epoch into v_epoch from public.visitor_identity_session_state where session_id = p_session_id;
  if p_epoch is null or p_epoch <> coalesce(v_epoch, 0) then
    return jsonb_build_object('status', 'revoked');
  end if;
  if p_issuer = 'integration:' || p_site_id::text then
    -- Credential revocation fences even unconsumed tokens. Namespace stays stable.
    select expires_at into v_key_expiry from public.api_keys
      where id = p_key_id and site_id = p_site_id and status = 'active'
        and encode(sha256(convert_to(key_hash, 'UTF8')), 'hex') = p_key_fingerprint
        and 'identity:issue' = any(scopes) and expires_at > v_now for share;
    if not found then return jsonb_build_object('status', 'revoked'); end if;
  elsif p_key_id is not null or p_key_fingerprint is not null then
    return jsonb_build_object('status', 'invalid_token');
  end if;

  select * into v_grant from public.visitor_session_identity_grants where session_id = p_session_id for update;
  v_now := clock_timestamp();
  if to_timestamp(p_expires_at) <= v_now or v_key_expiry <= v_now then
    return jsonb_build_object('status', 'revoked');
  end if;
  select * into v_redemption from public.visitor_identity_token_redemptions where jti = p_jti;
  if found then
    -- Retry is valid only while the exact grant remains active; never reinsert it.
    if v_redemption.site_id = p_site_id and v_redemption.session_id = p_session_id
      and v_redemption.visitor_id = p_visitor_id and v_redemption.epoch = p_epoch
      and v_redemption.token_hash = p_token_hash and v_redemption.expires_at > v_now
      and v_grant.revoked_at is null and v_grant.expires_at > v_now
      and v_grant.trusted_token_hash = p_token_hash and v_session.lead_id = v_grant.lead_id then
      return jsonb_build_object('status', 'verified', 'lead_id', v_grant.lead_id, 'expires_at', v_grant.expires_at);
    end if;
    return jsonb_build_object('status', 'revoked');
  end if;

  -- The namespace excludes the credential id so API-key rotation is transparent.
  perform pg_advisory_xact_lock(hashtextextended(
    p_site_id::text || ':' || p_issuer || ':' || p_subject, 1));
  v_now := clock_timestamp();
  if to_timestamp(p_expires_at) <= v_now or v_key_expiry <= v_now then
    return jsonb_build_object('status', 'revoked');
  end if;
  select * into v_identity from public.visitor_external_identities
    where site_id = p_site_id and issuer = p_issuer and external_user_id = p_subject;
  -- Even an expired grant retains the identity boundary until explicit logout.
  if v_session.lead_id is not null and
    (v_identity.id is null or v_identity.lead_id <> v_session.lead_id) then
    return jsonb_build_object('status', 'identity_conflict');
  end if;
  if v_identity.id is null then
    select user_id into v_owner from public.sites where id = p_site_id;
    if v_owner is null then return jsonb_build_object('status', 'invalid_site'); end if;
    v_lead := gen_random_uuid();
    -- Do not look up, merge, or claim an email-matching lead. Keeping asserted email
    -- private also prevents legacy email-only new-lead/OTP flows from claiming it.
    insert into public.leads(id, site_id, user_id, name, status, origin)
      values(v_lead, p_site_id, v_owner, coalesce(p_name, 'Verified visitor'), 'new', 'server_identity');
    insert into public.visitor_external_identities(site_id, issuer, external_user_id, lead_id, display_name, asserted_email)
      values(p_site_id, p_issuer, p_subject, v_lead, p_name, p_email) returning * into v_identity;
  end if;
  insert into public.visitor_identity_token_redemptions(
    jti, site_id, session_id, visitor_id, identity_id, issuer_key_id, epoch, token_hash, expires_at
  ) values(p_jti, p_site_id, p_session_id, p_visitor_id, v_identity.id, p_key_id, p_epoch, p_token_hash, to_timestamp(p_expires_at));
  insert into public.visitor_session_identity_grants(
    site_id, session_id, visitor_id, lead_id, trusted_token_hash, granted_at, expires_at, revoked_at, updated_at
  ) values(p_site_id, p_session_id, p_visitor_id, v_identity.lead_id, p_token_hash, v_now,
    least(v_now + interval '15 minutes', v_key_expiry), null, v_now)
  on conflict(session_id) do update set
    site_id = excluded.site_id, visitor_id = excluded.visitor_id, lead_id = excluded.lead_id,
    trusted_token_hash = excluded.trusted_token_hash, granted_at = excluded.granted_at,
    expires_at = excluded.expires_at, revoked_at = null, updated_at = excluded.updated_at;
  update public.visitor_sessions set lead_id = v_identity.lead_id,
    identified_at = (extract(epoch from v_now) * 1000)::bigint, updated_at = v_now
    where id = p_session_id;
  update public.visitor_identity_challenges set cancelled_at = v_now, updated_at = v_now
    where session_id = p_session_id and consumed_at is null and cancelled_at is null;
  return jsonb_build_object('status', 'verified', 'lead_id', v_identity.lead_id,
    'expires_at', least(v_now + interval '15 minutes', v_key_expiry));
end;
$_$;


--
-- Name: exchange_visitor_identity_token_v2(uuid, uuid, uuid, text, text, bigint, uuid, bigint, bigint, text, text, text, uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exchange_visitor_identity_token_v2(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_key_id uuid DEFAULT NULL::uuid, p_key_fingerprint text DEFAULT NULL::text, p_key_version uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform public.assert_visitor_identity_service_role();
  -- Preserve the session -> key -> grant lock order used by exchange and logout.
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text, 0));
  perform 1 from public.visitor_sessions
    where id = p_session_id and site_id = p_site_id and visitor_id = p_visitor_id
      and is_active is true for update;
  if not found then return jsonb_build_object('status', 'invalid_session'); end if;

  if p_issuer = 'integration:' || p_site_id::text then
    perform 1 from public.api_keys
      where id = p_key_id and site_id = p_site_id
        and identity_token_version = p_key_version
        and status = 'active' and 'identity:issue' = any(scopes)
        and expires_at > clock_timestamp()
      for share;
    if not found then return jsonb_build_object('status', 'revoked'); end if;
  elsif p_key_version is not null then
    return jsonb_build_object('status', 'invalid_token');
  end if;

  -- This call executes as the migration/function owner. That is the only role
  -- with access to the unversioned helper after the REVOKE above.
  return public.exchange_visitor_identity_token(
    p_site_id, p_session_id, p_visitor_id, p_issuer, p_subject, p_epoch, p_jti,
    p_issued_at, p_expires_at, p_token_hash, p_name, p_email, p_key_id, p_key_fingerprint
  );
end;
$$;


--
-- Name: expire_old_api_keys(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.expire_old_api_keys() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  UPDATE public.api_keys
  SET status = 'expired'
  WHERE status = 'active'
    AND expires_at < CURRENT_TIMESTAMP;
  RETURN NULL; -- AFTER trigger, return value ignored
END;
$$;


--
-- Name: fail_catalog_embedding_job(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_error text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.catalog_embedding_jobs j SET status = CASE WHEN j.attempts >= 8 THEN 'exhausted' ELSE 'retry' END,
    claim_token = NULL, lease_expires_at = NULL,
    next_attempt_at = clock_timestamp() + make_interval(secs => least(3600, 5 * power(2, least(j.attempts, 9)))::integer),
    -- Persist a controlled category only. Provider error bodies can contain secrets/documents.
    last_error = CASE WHEN p_error IN ('provider_error', 'rate_limited', 'invalid_embedding', 'timeout')
      THEN p_error ELSE 'embedding_failed' END, updated_at = now()
  WHERE j.id = p_job_id AND j.status = 'leased' AND j.claim_token = p_claim_token
    AND j.lease_expires_at > clock_timestamp();
  RETURN FOUND;
END $$;


--
-- Name: fail_credit_auto_top_up_attempt(uuid, uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE b public.billing%ROWTYPE; a public.credit_auto_top_up_attempts%ROWTYPE;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_stripe_payment_intent_id IS NULL OR p_stripe_payment_intent_id !~ '^pi_[A-Za-z0-9]+$'
    OR p_stripe_status IS NULL OR p_stripe_status <> 'canceled'
  THEN RAISE EXCEPTION 'Verified terminal nonpaying Stripe intent required'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing record not found'; END IF;
  SELECT * INTO a FROM public.credit_auto_top_up_attempts
    WHERE site_id=p_site_id AND id=p_attempt_id FOR UPDATE;
  IF NOT FOUND OR (a.stripe_payment_intent_id IS NOT NULL
    AND a.stripe_payment_intent_id <> p_stripe_payment_intent_id) THEN
    RAISE EXCEPTION 'Automatic top-up failure identity mismatch';
  END IF;
  IF a.status = 'failed' THEN
    RETURN jsonb_build_object('success',true,'outcome','duplicate','attempt_id',a.id);
  END IF;
  IF a.status <> 'pending' OR a.claim_token IS DISTINCT FROM p_claim_token THEN
    RAISE EXCEPTION 'Stale or terminal automatic top-up attempt';
  END IF;
  IF EXISTS (SELECT 1 FROM public.billing_credit_grant_keys
    WHERE idempotency_key=p_stripe_payment_intent_id)
    OR EXISTS (SELECT 1 FROM public.payments WHERE transaction_id=p_stripe_payment_intent_id
      AND status='completed') THEN
    RAISE EXCEPTION 'Cannot fail an already credited Stripe intent';
  END IF;
  UPDATE public.credit_auto_top_up_attempts
    SET status='failed',stripe_payment_intent_id=p_stripe_payment_intent_id,finished_at=now()
    WHERE id=a.id;
  UPDATE public.credit_auto_top_up_settings SET state='paused',updated_at=now()
    WHERE site_id=p_site_id;
  RETURN jsonb_build_object('success',true,'outcome','failed','attempt_id',a.id);
END;
$_$;


--
-- Name: fail_marketplace_oauth(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_marketplace_oauth(p_session_id uuid, p_actor_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE session public.marketplace_oauth_sessions;
BEGIN
  IF NOT public.marketplace_is_backend() THEN RAISE EXCEPTION 'OAuth backend required' USING ERRCODE='42501'; END IF;
  SELECT * INTO session FROM public.marketplace_oauth_sessions WHERE id=p_session_id FOR UPDATE;
  IF NOT FOUND OR session.user_id IS DISTINCT FROM p_actor_user_id THEN
    RAISE EXCEPTION 'OAuth state unavailable' USING ERRCODE='42501';
  END IF;
  PERFORM public.marketplace_assert_actor(session.site_id,p_actor_user_id,true);
  IF session.status IN ('created','claimed') THEN
    UPDATE public.marketplace_oauth_sessions SET status='failed',encrypted_context=NULL,finished_at=now() WHERE id=session.id;
  END IF;
END;
$$;


--
-- Name: fail_stripe_sale_compensation(text, uuid, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_error text, p_manual_review boolean DEFAULT false) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.stripe_sale_checkout_effects
  SET compensation_status = CASE
        WHEN p_manual_review THEN 'manual_review'
        ELSE 'failed'
      END,
      compensation_error = left(coalesce(p_error, 'Unknown error'), 4000),
      compensation_claim_token = NULL,
      updated_at = now()
  WHERE stripe_session_id = p_session_id
    AND compensation_status = 'processing'
    AND compensation_claim_token = p_claim_token;
  RETURN FOUND;
END;
$$;


--
-- Name: fail_stripe_sale_fulfillment(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.stripe_sale_checkout_effects
  SET fulfillment_status = 'failed',
      fulfillment_claim_token = NULL,
      updated_at = now()
  WHERE stripe_session_id = p_session_id
    AND fulfillment_status = 'processing'
    AND fulfillment_claim_token = p_claim_token;
  RETURN FOUND;
END;
$$;


--
-- Name: fail_stripe_webhook_event(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fail_stripe_webhook_event(p_event_id text, p_claim_token uuid, p_error_message text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.webhook_events
  SET status = 'failed',
      error_message = left(coalesce(p_error_message, 'Unknown error'), 4000),
      claim_token = NULL,
      updated_at = now()
  WHERE stripe_event_id = p_event_id
    AND status = 'processing'
    AND claim_token = p_claim_token;

  RETURN FOUND;
END;
$$;


--
-- Name: fence_retired_stripe_subscription_identity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fence_retired_stripe_subscription_identity() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.stripe_subscription_id IS DISTINCT FROM OLD.stripe_subscription_id THEN
    IF EXISTS (SELECT 1 FROM public.site_retired_stripe_subscriptions
      WHERE site_id = OLD.site_id AND subscription_id = NEW.stripe_subscription_id) THEN
      RETURN NULL; -- Discard the whole obsolete write before any bucket guard.
    END IF;
    IF OLD.stripe_subscription_id IS NOT NULL THEN
      INSERT INTO public.site_retired_stripe_subscriptions(site_id,subscription_id)
        VALUES(OLD.site_id,OLD.stripe_subscription_id) ON CONFLICT DO NOTHING;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

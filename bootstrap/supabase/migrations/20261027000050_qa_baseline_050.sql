SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: record_channel_health_event(uuid, text, text, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_channel_health_event(p_site_id uuid, p_channel text, p_direction text, p_source_id uuid, p_outcome text, p_error_class text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_successes integer;
  v_failures integer;
  v_auth_failures integer;
  v_successes_after_failure integer;
  v_last_success timestamptz;
  v_last_failure timestamptz;
  v_existing_status text;
  v_reset_at timestamptz;
  v_previous_error_class text;
  v_status text;
BEGIN
  IF p_site_id IS NULL OR p_channel IS NULL OR p_channel NOT IN ('email', 'whatsapp')
     OR p_direction NOT IN ('inbound', 'outbound')
     OR p_direction IS NULL
     OR p_outcome NOT IN ('success', 'failure')
     OR p_outcome IS NULL OR p_source_id IS NULL
     OR (p_error_class IS NOT NULL AND p_error_class NOT IN ('auth', 'provider', 'recipient', 'content', 'unknown')) THEN
    RAISE EXCEPTION 'Invalid channel health event';
  END IF;

  -- Lock the aggregate first; concurrent deliveries for a channel are reduced
  -- in order. Duplicate events do not reset the observation clock.
  INSERT INTO public.channel_health (site_id, channel, direction)
  VALUES (p_site_id, p_channel, p_direction)
  ON CONFLICT DO NOTHING;
  PERFORM 1 FROM public.channel_health
  WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction FOR UPDATE;

  SELECT status, reset_at INTO v_existing_status, v_reset_at FROM public.channel_health
  WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction;

  SELECT error_class INTO v_previous_error_class
  FROM public.channel_health_events
  WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction
    AND source_id = p_source_id AND outcome = 'failure';

  -- A retry of a pre-reset source cannot attest to the new credentials. Keep
  -- its original observation for audit; require a fresh message to recover.
  IF EXISTS (
    SELECT 1 FROM public.channel_health_events
    WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction
      AND source_id = p_source_id AND observed_at <= v_reset_at
  ) THEN RETURN false; END IF;

  INSERT INTO public.channel_health_events (site_id, channel, direction, source_id, outcome, error_class)
  VALUES (p_site_id, p_channel, p_direction, p_source_id, p_outcome,
          CASE WHEN p_outcome = 'success' THEN NULL ELSE p_error_class END)
  ON CONFLICT (site_id, channel, direction, source_id) DO UPDATE
    SET outcome = excluded.outcome, error_class = excluded.error_class,
        observed_at = CASE
          WHEN public.channel_health_events.outcome = 'failure' AND excluded.outcome = 'failure'
            THEN public.channel_health_events.observed_at
          ELSE clock_timestamp()
        END
    WHERE public.channel_health_events.outcome <> 'success'
      AND (public.channel_health_events.outcome IS DISTINCT FROM excluded.outcome
           OR public.channel_health_events.error_class IS DISTINCT FROM excluded.error_class);

  IF NOT FOUND THEN RETURN false; END IF;

  -- Non-channel failures are audit observations, not fresh verdicts. The one
  -- exception is reclassifying an earlier auth/provider failure as recipient
  -- or content, which must remove its previous effect on the aggregate.
  IF p_outcome = 'failure' AND coalesce(p_error_class, 'unknown') NOT IN ('auth', 'provider')
     AND v_previous_error_class IS DISTINCT FROM 'auth'
     AND v_previous_error_class IS DISTINCT FROM 'provider'
  THEN
    -- If there was no prior verdict, the default aggregate row suffices;
    -- otherwise do not extend the lifetime of an unrelated verdict.
    RETURN true;
  END IF;

  -- The caller validates freshness of this state before spending AI tokens.

  SELECT max(observed_at) FILTER (WHERE outcome = 'success'),
         max(observed_at) FILTER (WHERE outcome = 'failure' AND error_class IN ('auth', 'provider'))
  INTO v_last_success, v_last_failure
  FROM public.channel_health_events
  WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction
    AND observed_at > coalesce(v_reset_at, '-infinity'::timestamptz);

  SELECT count(*) FILTER (WHERE outcome = 'success')::integer,
         count(*) FILTER (WHERE outcome = 'failure' AND error_class IN ('auth', 'provider'))::integer,
         count(*) FILTER (WHERE outcome = 'failure' AND error_class = 'auth')::integer,
         count(*) FILTER (WHERE outcome = 'success' AND observed_at > coalesce(v_last_failure, '-infinity'::timestamptz))::integer
  INTO v_successes, v_failures, v_auth_failures, v_successes_after_failure
  FROM public.channel_health_events
  WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction
    AND observed_at >= now() - interval '15 minutes'
    AND observed_at > coalesce(v_reset_at, '-infinity'::timestamptz);

  v_status := CASE
    WHEN v_existing_status = 'unhealthy' AND v_successes_after_failure < 2 THEN 'unhealthy'
    WHEN v_failures >= 1 AND v_successes_after_failure >= 2 THEN 'healthy'
    WHEN v_auth_failures >= 2 OR (v_failures >= 5 AND v_failures * 2 >= v_successes + v_failures) THEN 'unhealthy'
    WHEN v_failures >= 1 THEN 'degraded'
    WHEN v_successes >= 1 THEN 'healthy'
    ELSE 'unknown'
  END;

  UPDATE public.channel_health
  SET status = v_status, successes_15m = v_successes,
      channel_failures_15m = v_failures, last_success_at = v_last_success,
       last_failure_at = v_last_failure, updated_at = clock_timestamp()
  WHERE site_id = p_site_id AND channel = p_channel AND direction = p_direction;
  RETURN true;
END;
$$;


--
-- Name: record_credit_auto_top_up_consent(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_credit_auto_top_up_consent(p_site_id uuid, p_actor_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; s public.credit_auto_top_up_settings%ROWTYPE; v_id uuid;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_actor_id IS NULL THEN RAISE EXCEPTION 'Verified consent actor required'; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Billing record not found'; END IF;
  SELECT * INTO s FROM public.credit_auto_top_up_settings WHERE site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Automatic top-up settings not found'; END IF;
  INSERT INTO public.credit_auto_top_up_consent_log(site_id,actor_id,settings_revision,settings_snapshot)
  VALUES (p_site_id,p_actor_id,s.settings_revision,
    to_jsonb(s)||jsonb_build_object('stripe_customer_id',b.stripe_customer_id,'currency','usd'))
  RETURNING id INTO v_id;
  RETURN jsonb_build_object('success',true,'outcome','recorded','consent_id',v_id,
    'settings_revision',s.settings_revision);
END;
$$;


--
-- Name: record_credit_auto_top_up_intent(uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_credit_auto_top_up_intent(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE a public.credit_auto_top_up_attempts%ROWTYPE;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_stripe_payment_intent_id IS NULL OR p_stripe_payment_intent_id !~ '^pi_[A-Za-z0-9]+$'
  THEN RAISE EXCEPTION 'Valid Stripe payment intent required'; END IF;
  PERFORM 1 FROM public.billing WHERE site_id=p_site_id FOR UPDATE;
  SELECT * INTO a FROM public.credit_auto_top_up_attempts
    WHERE site_id=p_site_id AND id=p_attempt_id FOR UPDATE;
  IF NOT FOUND OR a.status <> 'pending' OR a.claim_token IS DISTINCT FROM p_claim_token
    OR a.dispatch_started_at IS NULL
    OR (a.stripe_payment_intent_id IS NOT NULL
      AND a.stripe_payment_intent_id <> p_stripe_payment_intent_id) THEN
    RAISE EXCEPTION 'Stale, undispatched or conflicting automatic top-up intent';
  END IF;
  UPDATE public.credit_auto_top_up_attempts SET stripe_payment_intent_id=p_stripe_payment_intent_id
    WHERE id=a.id;
  RETURN jsonb_build_object('success',true,'outcome','recorded','attempt_id',a.id);
END;
$_$;

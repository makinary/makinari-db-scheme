SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: resend_visitor_identity_challenge(uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resend_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_otp_hash text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_challenge public.visitor_identity_challenges%rowtype;
  v_now timestamptz := clock_timestamp();
begin
  perform public.assert_visitor_identity_service_role();
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text || ':' || p_challenge_id::text, 0));
  select * into v_challenge
  from public.visitor_identity_challenges
  where id = p_challenge_id and site_id = p_site_id and session_id = p_session_id
  for update;

  if not found or v_challenge.cancelled_at is not null or v_challenge.consumed_at is not null
     or v_challenge.expires_at <= v_now then
    return jsonb_build_object('status', 'challenge_expired');
  end if;
  if v_challenge.resend_count >= 3 then
    return jsonb_build_object('status', 'resend_limit');
  end if;
  if v_challenge.resend_available_at > v_now then
    return jsonb_build_object(
      'status', 'cooldown',
      'retry_after', greatest(1, ceil(extract(epoch from v_challenge.resend_available_at - v_now)))
    );
  end if;

  update public.visitor_identity_challenges
  set otp_hash = p_otp_hash,
      attempts = 0,
      resend_count = resend_count + 1,
      expires_at = v_now + interval '10 minutes',
      resend_available_at = v_now + interval '60 seconds',
      updated_at = v_now
  where id = p_challenge_id;

  return jsonb_build_object(
    'status', 'resent',
    'challenge_id', p_challenge_id,
    'masked_email', v_challenge.masked_email,
    'email', v_challenge.normalized_email,
    'lead_id', v_challenge.lead_id,
    'expires_at', v_now + interval '10 minutes',
    'resend_available_at', v_now + interval '60 seconds'
  );
end;
$$;


--
-- Name: reserve_agent_requirement_credits(uuid, text, integer, uuid, uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserve_agent_requirement_credits(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_event_id uuid, p_amount numeric) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE site uuid;
BEGIN
  IF EXISTS(SELECT 1 FROM public.harness_model_credit_reservations WHERE session_id=p_session_id AND event_id=p_event_id
    AND requirement_id=p_requirement_id AND amount=p_amount) THEN
    RETURN (SELECT jsonb_build_object('success',true,'state',state) FROM public.harness_model_credit_reservations
      WHERE session_id=p_session_id AND event_id=p_event_id); END IF;
  IF NOT public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id) THEN
    RETURN jsonb_build_object('success',false); END IF;
  SELECT site_id INTO site FROM public.requirements WHERE id=p_requirement_id;
  IF NOT EXISTS(SELECT 1 FROM public.harness_sessions WHERE id=p_session_id AND site_id=site) THEN
    RETURN jsonb_build_object('success',false); END IF;
  RETURN public.hold_harness_model_credits(p_session_id,site,p_event_id,p_amount,p_requirement_id);
END;
$$;


--
-- Name: reserve_harness_artifact(uuid, uuid, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserve_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_bytes integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE used bigint; reserved bigint; previous integer;
BEGIN
  PERFORM public.lock_harness_host_owner(p_id,p_site_id,p_owner);
  IF p_operation_id IS NULL OR length(p_operation_id) NOT BETWEEN 1 AND 1000
    OR p_bytes IS NULL OR p_bytes NOT BETWEEN 1 AND 1048576
  THEN RAISE EXCEPTION 'Invalid harness artifact reservation' USING ERRCODE='22023'; END IF;
  SELECT bytes INTO previous FROM public.harness_artifact_reservations WHERE session_id=p_id AND operation_id=p_operation_id;
  -- Repeated preflights are idempotent. A consumed reservation must be reacquired
  -- before any new execution; never promise capacity already occupied by output.
  IF FOUND AND previous >= p_bytes THEN RETURN true; END IF;
  SELECT coalesce(sum(bytes),0) INTO used FROM public.harness_artifacts WHERE session_id=p_id;
  SELECT coalesce(sum(bytes),0) INTO reserved FROM public.harness_artifact_reservations WHERE session_id=p_id;
  IF used+reserved-coalesce(previous,0)+p_bytes > 16777216
  THEN RAISE EXCEPTION 'Harness artifact quota exceeded before execution' USING ERRCODE='54000'; END IF;
  INSERT INTO public.harness_artifact_reservations(session_id,site_id,operation_id,bytes) VALUES(p_id,p_site_id,p_operation_id,p_bytes)
    ON CONFLICT (session_id,operation_id) DO UPDATE SET bytes=EXCLUDED.bytes;
  RETURN true;
END;
$$;


--
-- Name: reserve_harness_model_credits(uuid, uuid, text, uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserve_harness_model_credits(p_session_id uuid, p_site_id uuid, p_owner text, p_event_id uuid, p_amount numeric) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF EXISTS(SELECT 1 FROM public.harness_model_credit_reservations WHERE session_id=p_session_id AND event_id=p_event_id
    AND site_id=p_site_id AND requirement_id IS NULL AND amount=p_amount) THEN
    RETURN (SELECT jsonb_build_object('success',true,'state',state) FROM public.harness_model_credit_reservations
      WHERE session_id=p_session_id AND event_id=p_event_id); END IF;
  PERFORM 1 FROM public.harness_sessions WHERE id=p_session_id AND site_id=p_site_id AND lease_owner=p_owner
    AND lease_expires_at>clock_timestamp() AND snapshot->>'status'='running' FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false); END IF;
  RETURN public.hold_harness_model_credits(p_session_id,p_site_id,p_event_id,p_amount,NULL);
END;
$$;


--
-- Name: reserve_icp_dispatch(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserve_icp_dispatch(p_site_id uuid, p_icp_id uuid, p_dispatch_key text, p_workflow_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  c public.icp_dispatch_config;
  d public.icp_dispatch_runs;
  r public.icp_mining;
  activity_settings jsonb;
  settings_json jsonb;
  list_ids jsonb;
  target integer := 150;
  research boolean := false;
  all_lists boolean := true;
  candidate_cap integer;
  candidates_used bigint;
  matches_used bigint;
  candidates integer;
  matches integer;
  stamp timestamptz;
  day_utc date;
BEGIN
  IF p_site_id IS NULL OR p_icp_id IS NULL OR NULLIF(btrim(p_dispatch_key), '') IS NULL
    OR NULLIF(btrim(p_workflow_id), '') IS NULL THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_identity');
  END IF;
  -- One transaction lock for ALL reservations, begin, finish and manual claims.
  -- Always acquire it BEFORE config/reservation/ICP row locks. Never use a TTL.
  PERFORM pg_catalog.pg_advisory_xact_lock(734210, 1);
  SELECT * INTO c FROM public.icp_dispatch_config WHERE id FOR SHARE;
  SELECT * INTO d FROM public.icp_dispatch_runs WHERE dispatch_key = p_dispatch_key;
  IF FOUND THEN
    IF (d.site_id, d.icp_mining_id, d.workflow_id) IS DISTINCT FROM (p_site_id, p_icp_id, p_workflow_id) THEN
      RETURN jsonb_build_object('acquired', false, 'reason', 'dispatch_key_conflict');
    END IF;
    RETURN jsonb_build_object('acquired', true, 'reservation', to_jsonb(d));
  END IF;
  IF EXISTS (SELECT 1 FROM public.icp_dispatch_runs WHERE workflow_id = p_workflow_id) THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'workflow_id_conflict');
  END IF;
  IF c.enabled IS DISTINCT FROM true THEN RETURN jsonb_build_object('acquired', false, 'reason', 'disabled'); END IF;
  stamp := clock_timestamp();
  day_utc := (stamp AT TIME ZONE 'UTC')::date;
  PERFORM 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NULL FOR SHARE;
  IF NOT FOUND THEN RETURN jsonb_build_object('acquired', false, 'reason', 'site_unavailable'); END IF;

  -- Read authoritative settings for EVERY new reservation. Missing legacy fields
  -- use defaults; malformed controls (including any malformed selected ID) deny.
  SELECT activities INTO activity_settings FROM public.settings WHERE site_id = p_site_id FOR SHARE;
  activity_settings := COALESCE(activity_settings, '{}'::jsonb);
  IF jsonb_typeof(activity_settings) IS DISTINCT FROM 'object' THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
  END IF;
  settings_json := COALESCE(activity_settings->'icp_lead_generation', '{}'::jsonb);
  IF jsonb_typeof(settings_json) IS DISTINCT FROM 'object' THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
  END IF;
  IF settings_json ? 'target_leads' THEN
    IF jsonb_typeof(settings_json->'target_leads') IS DISTINCT FROM 'number' THEN
      RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
    END IF;
    IF (settings_json->>'target_leads')::numeric NOT BETWEEN 1 AND 3000
      OR trunc((settings_json->>'target_leads')::numeric) <> (settings_json->>'target_leads')::numeric THEN
      RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
    END IF;
    target := (settings_json->>'target_leads')::numeric::integer;
  END IF;
  IF settings_json ? 'research_enabled' THEN
    IF jsonb_typeof(settings_json->'research_enabled') IS DISTINCT FROM 'boolean' THEN
      RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
    END IF;
    research := (settings_json->>'research_enabled')::boolean;
  END IF;
  IF settings_json ? 'all_lists' THEN
    IF jsonb_typeof(settings_json->'all_lists') IS DISTINCT FROM 'boolean' THEN
      RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
    END IF;
    all_lists := (settings_json->>'all_lists')::boolean;
  END IF;
  list_ids := COALESCE(settings_json->'list_ids', '[]'::jsonb);
  IF jsonb_typeof(list_ids) IS DISTINCT FROM 'array' THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings');
  END IF;
  IF jsonb_array_length(list_ids) > 1000 OR EXISTS (
    SELECT 1 FROM jsonb_array_elements(list_ids) AS item(value)
    WHERE jsonb_typeof(value) IS DISTINCT FROM 'string'
      OR (value #>> '{}') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  ) THEN RETURN jsonb_build_object('acquired', false, 'reason', 'invalid_settings'); END IF;
  IF NOT all_lists AND NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements_text(list_ids) AS item(value) WHERE value::uuid = p_icp_id
  ) THEN RETURN jsonb_build_object('acquired', false, 'reason', 'list_not_selected'); END IF;

  SELECT * INTO r FROM public.icp_mining WHERE id = p_icp_id AND site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('acquired', false, 'reason', 'list_unavailable'); END IF;
  IF r.status NOT IN ('pending', 'running') THEN RETURN jsonb_build_object('acquired', false, 'reason', 'not_pending'); END IF;
  IF EXISTS (SELECT 1 FROM public.icp_dispatch_runs WHERE site_id = p_site_id AND state IN ('reserved', 'running', 'blocked')) THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'site_busy');
  END IF;
  IF EXISTS (SELECT 1 FROM public.icp_mining WHERE site_id = p_site_id AND execution_active) THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'execution_busy');
  END IF;
  IF (SELECT count(*) FROM public.icp_dispatch_runs WHERE state IN ('reserved', 'running', 'blocked'))
    + (SELECT count(*) FROM public.icp_mining legacy WHERE legacy.execution_active AND NOT EXISTS (
        SELECT 1 FROM public.icp_dispatch_runs owned WHERE owned.icp_mining_id = legacy.id
          AND owned.run_id = legacy.execution_run_id AND owned.state IN ('reserved', 'running', 'blocked')
      )) >= c.max_concurrency THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'global_capacity');
  END IF;
  IF EXISTS (SELECT 1 FROM public.icp_dispatch_site_state WHERE site_id = p_site_id AND next_eligible_at > stamp) THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'site_cooldown');
  END IF;
  IF EXISTS (SELECT 1 FROM public.icp_dispatch_list_state WHERE icp_mining_id = p_icp_id AND next_eligible_at > stamp) THEN
    RETURN jsonb_build_object('acquired', false, 'reason', 'list_cooldown');
  END IF;
  candidate_cap := least(c.daily_candidate_limit, target * 10);
  SELECT COALESCE(sum(budget.reserved_candidates), 0),
    COALESCE(sum(CASE WHEN budget.state = 'settled' THEN budget.found ELSE budget.reserved_matches END), 0)
    INTO candidates_used, matches_used FROM public.icp_dispatch_runs budget
    WHERE budget.site_id = p_site_id AND budget.budget_day = day_utc;
  IF matches_used >= target THEN RETURN jsonb_build_object('acquired', false, 'reason', 'match_quota'); END IF;
  IF candidates_used >= candidate_cap THEN RETURN jsonb_build_object('acquired', false, 'reason', 'candidate_quota'); END IF;
  -- total_targets=0 is the pre-fetch/unknown sentinel in the existing schema.
  candidates := least(c.slice_candidates, candidate_cap - candidates_used,
    CASE WHEN r.total_targets > 0 THEN greatest(0, r.total_targets - COALESCE(r.processed_targets, 0)) ELSE 10 END);
  IF candidates < 1 THEN RETURN jsonb_build_object('acquired', false, 'reason', 'list_exhausted'); END IF;
  matches := least(candidates, target - matches_used);
  INSERT INTO public.icp_dispatch_runs (site_id, icp_mining_id, dispatch_key, workflow_id,
    budget_day, target_limit, candidate_limit, research_enabled, reserved_candidates, reserved_matches, created_at, updated_at)
    VALUES (p_site_id, p_icp_id, p_dispatch_key, p_workflow_id, day_utc, target, candidate_cap,
      research, candidates, matches, stamp, stamp) RETURNING * INTO d;
  -- Touch fairness at reservation, not completion; lost start responses keep their turn.
  INSERT INTO public.icp_dispatch_site_state (site_id, last_dispatched_at) VALUES (p_site_id, stamp)
    ON CONFLICT (site_id) DO UPDATE SET last_dispatched_at = EXCLUDED.last_dispatched_at;
  INSERT INTO public.icp_dispatch_list_state (icp_mining_id, site_id, last_dispatched_at) VALUES (p_icp_id, p_site_id, stamp)
    ON CONFLICT (icp_mining_id) DO UPDATE SET last_dispatched_at = EXCLUDED.last_dispatched_at;
  RETURN jsonb_build_object('acquired', true, 'reservation', to_jsonb(d));
END $_$;


--
-- Name: reserve_platform_quota(uuid, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserve_platform_quota(p_site_id uuid, p_capability text, p_period text, p_cost integer, p_default_limit integer) RETURNS TABLE(allowed boolean, used integer, quota_limit integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  affected integer;
BEGIN
  INSERT INTO public.platform_quotas (
    site_id,
    capability,
    period,
    used,
    created_at,
    updated_at
  )
  VALUES (
    p_site_id,
    p_capability,
    p_period,
    0,
    timezone('utc', now()),
    timezone('utc', now())
  )
  ON CONFLICT (site_id, capability, period) DO NOTHING;

  RETURN QUERY
  UPDATE public.platform_quotas AS quota
  SET
    used = quota.used + GREATEST(p_cost, 1),
    updated_at = timezone('utc', now())
  WHERE quota.site_id = p_site_id
    AND quota.capability = p_capability
    AND quota.period = p_period
    AND quota.used + GREATEST(p_cost, 1)
      <= COALESCE(quota.quota_override, p_default_limit)
  RETURNING
    true,
    quota.used,
    COALESCE(quota.quota_override, p_default_limit);

  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected = 0 THEN
    RETURN QUERY
    SELECT
      false,
      quota.used,
      COALESCE(quota.quota_override, p_default_limit)
    FROM public.platform_quotas AS quota
    WHERE quota.site_id = p_site_id
      AND quota.capability = p_capability
      AND quota.period = p_period;
  END IF;
END;
$$;


--
-- Name: reserve_stripe_checkout_attempt(uuid, bigint, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserve_stripe_checkout_attempt(p_sale_id uuid, p_amount_minor bigint, p_currency text, p_expected_session_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_sale public.sales%ROWTYPE;
  v_currency text;
  v_expected_minor bigint;
  v_attempt bigint;
BEGIN
  IF p_amount_minor IS NULL OR p_amount_minor < 0 THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'Invalid payment amount'
    );
  END IF;

  SELECT *
  INTO v_sale
  FROM public.sales
  WHERE id = p_sale_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'Payment record not found'
    );
  END IF;

  IF v_sale.status NOT IN ('pending', 'completed') THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'This payment is no longer available'
    );
  END IF;

  IF v_sale.amount_due IS NULL OR v_sale.amount_due <= 0 THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'This document has no outstanding balance'
    );
  END IF;

  v_currency := lower(trim(coalesce(v_sale.currency, 'USD')));
  IF v_currency <> lower(trim(coalesce(p_currency, ''))) THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'Payment currency changed'
    );
  END IF;

  v_expected_minor :=
    public.stripe_amount_to_minor(v_sale.amount_due, v_currency);
  IF v_expected_minor IS NULL OR v_expected_minor <> p_amount_minor THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'Payment amount changed'
    );
  END IF;

  IF v_sale.stripe_checkout_session_id
    IS DISTINCT FROM p_expected_session_id THEN
    RETURN jsonb_build_object(
      'status', 'checkout_changed',
      'session_id', v_sale.stripe_checkout_session_id
    );
  END IF;

  v_attempt := coalesce(v_sale.stripe_checkout_attempt, 0) + 1;
  UPDATE public.sales
  SET stripe_checkout_attempt = v_attempt,
      stripe_checkout_session_id = NULL,
      updated_at = now()
  WHERE id = v_sale.id;

  RETURN jsonb_build_object(
    'status', 'reserved',
    'attempt', v_attempt
  );
END;
$$;


--
-- Name: reset_channel_health_on_reconfiguration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_channel_health_on_reconfiguration() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF OLD.channels->'agent_email' IS DISTINCT FROM NEW.channels->'agent_email'
     OR OLD.channels->'agent_mail' IS DISTINCT FROM NEW.channels->'agent_mail'
     OR OLD.channels->'agent' IS DISTINCT FROM NEW.channels->'agent'
     OR ((OLD.channels->'email') - 'last_sync_attempt' - 'last_sync_error' - 'sync_error_count' - 'sync_status' - 'synced')
       IS DISTINCT FROM
        ((NEW.channels->'email') - 'last_sync_attempt' - 'last_sync_error' - 'sync_error_count' - 'sync_status' - 'synced')
  THEN
    UPDATE public.channel_health
    SET status = 'unknown', successes_15m = 0, channel_failures_15m = 0,
        last_success_at = NULL, last_failure_at = NULL,
        reset_at = clock_timestamp(), updated_at = clock_timestamp()
    WHERE site_id = NEW.site_id AND channel = 'email' AND direction = 'outbound';
  END IF;

  IF coalesce(OLD.channels->'whatsapp', OLD.channels->'agent_whatsapp')
     IS DISTINCT FROM coalesce(NEW.channels->'whatsapp', NEW.channels->'agent_whatsapp') THEN
    UPDATE public.channel_health
    SET status = 'unknown', successes_15m = 0, channel_failures_15m = 0,
        last_success_at = NULL, last_failure_at = NULL,
        reset_at = clock_timestamp(), updated_at = clock_timestamp()
    WHERE site_id = NEW.site_id AND channel = 'whatsapp' AND direction = 'outbound';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: reset_credit_auto_top_up_card_source(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_credit_auto_top_up_card_source() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.status='pending' THEN NEW.source := 'top_up'; END IF;
  RETURN NEW;
END;
$$;

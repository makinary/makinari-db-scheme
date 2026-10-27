SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: start_site_startup_trial(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.start_site_startup_trial(p_site_id uuid, p_actor_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE owner_id uuid; v_now timestamptz; dto jsonb;
BEGIN
  IF p_site_id IS NULL OR p_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Trial inputs are required'; END IF;
  SELECT user_id INTO owner_id FROM public.sites WHERE id = p_site_id AND archived_at IS NULL;
  IF NOT FOUND OR NOT (owner_id = p_actor_id OR EXISTS (
    SELECT 1 FROM public.site_members m WHERE m.site_id = p_site_id AND m.user_id = p_actor_id
      AND m.status = 'active' AND m.role IN ('owner','admin')
      AND public.site_member_has_effective_license(m.id)
  )) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'A licensed site manager must start the trial'; END IF;
  IF current_setting('transaction_isolation') = 'repeatable read' THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'Trial activation requires READ COMMITTED or SERIALIZABLE'; END IF;
  -- Owner lock prevents simultaneous claims across projects. Billing is locked
  -- before the site, matching the existing financial writer trigger order.
  PERFORM pg_advisory_xact_lock(hashtextextended('startup-trial-owner:' || owner_id,0));
  PERFORM 1 FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  PERFORM 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NULL AND user_id = owner_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Primary ownership changed'; END IF;
  IF owner_id IS DISTINCT FROM p_actor_id AND NOT EXISTS (
    SELECT 1 FROM public.site_members m WHERE m.site_id=p_site_id AND m.user_id=p_actor_id
      AND m.status='active' AND m.role IN ('owner','admin') AND public.site_member_has_effective_license(m.id)
  ) THEN RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Manager authorization changed'; END IF;
  dto := public.get_site_startup_trial(p_site_id);
  IF EXISTS (SELECT 1 FROM public.site_startup_trials WHERE site_id = p_site_id) THEN
    RETURN dto || jsonb_build_object('outcome','already_started'); END IF;
  IF EXISTS (SELECT 1 FROM public.site_startup_trials WHERE primary_owner_id = owner_id) THEN
    RETURN dto || jsonb_build_object('outcome','already_used'); END IF;
  IF dto->>'state' <> 'eligible' THEN RETURN dto || jsonb_build_object('outcome','not_eligible'); END IF;
  v_now := clock_timestamp();
  INSERT INTO public.site_startup_trials(primary_owner_id,site_id,started_at,ends_at)
    VALUES(owner_id,p_site_id,v_now,v_now + interval '360 hours');
  UPDATE public.billing SET trial_started_at = v_now,trial_ends_at = v_now + interval '360 hours',
    trial_credits_available = 50 WHERE site_id = p_site_id;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES(p_site_id,50,'startup_trial_grant','One-time 15-day Startup trial',
      jsonb_build_object('credit_bucket','trial','ends_at',v_now + interval '360 hours'));
  PERFORM public.reconcile_site_member_license(p_site_id);
  UPDATE public.settings SET social_media = social_media,channels = channels WHERE site_id = p_site_id;
  RETURN public.get_site_startup_trial(p_site_id) || jsonb_build_object('outcome','started');
END;
$$;


--
-- Name: status_observed_state(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.status_observed_state(status text, checks jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    SET search_path TO ''
    AS $$
DECLARE
  evidence jsonb := COALESCE(checks, '{}'::jsonb);
  http_value jsonb;
  route_array jsonb;
  route jsonb;
  providers jsonb;
  provider jsonb;
  configured_count integer := 0;
  all_configuration boolean := true;
BEGIN
  IF status = 'down' THEN RETURN 'down'; END IF;
  IF status IS NULL OR status NOT IN ('up', 'degraded', 'skipped') THEN RETURN 'skipped'; END IF;
  IF status = 'skipped' THEN RETURN 'skipped'; END IF;

  FOR http_value IN SELECT value FROM pg_catalog.jsonb_array_elements(
    pg_catalog.jsonb_build_array(evidence -> 'httpStatus', evidence -> 'continuationHttpStatus'))
  LOOP
    IF pg_catalog.jsonb_typeof(http_value) = 'number' AND
      ((http_value::text)::numeric = 0 OR (http_value::text)::numeric >= 500 OR
       (http_value::text)::numeric IN (401, 403, 404, 429)) THEN RETURN 'down'; END IF;
  END LOOP;
  FOR route_array IN SELECT value FROM pg_catalog.jsonb_array_elements(
    pg_catalog.jsonb_build_array(evidence -> 'routes', evidence -> 'sampleRoutes'))
  LOOP
    IF pg_catalog.jsonb_typeof(route_array) = 'array' THEN
      FOR route IN SELECT value FROM pg_catalog.jsonb_array_elements(route_array)
      LOOP
        http_value := route -> 'status';
        IF pg_catalog.jsonb_typeof(http_value) = 'number' AND
          ((http_value::text)::numeric = 0 OR (http_value::text)::numeric >= 500 OR
           (http_value::text)::numeric IN (401, 403, 404, 429)) THEN RETURN 'down'; END IF;
      END LOOP;
    END IF;
  END LOOP;

  IF evidence -> 'verification' IN ('"unverified"'::jsonb, '"configuration"'::jsonb)
    OR evidence -> 'telemetryFound' = 'false'::jsonb THEN RETURN 'skipped'; END IF;
  IF evidence -> 'verification' = '"partial"'::jsonb
    AND evidence -> 'observedFailure' = 'false'::jsonb THEN RETURN 'skipped'; END IF;
  IF evidence -> 'routesRegistered' = 'true'::jsonb
    AND evidence -> 'sideEffectSafe' = 'true'::jsonb THEN RETURN 'skipped'; END IF;

  providers := COALESCE(NULLIF(evidence -> 'providers', 'null'::jsonb), evidence -> 'inheritedProviders');
  IF pg_catalog.jsonb_typeof(providers) IN ('object', 'array') THEN
    FOR provider IN
      SELECT value FROM pg_catalog.jsonb_each(
        CASE WHEN pg_catalog.jsonb_typeof(providers) = 'object' THEN providers ELSE '{}'::jsonb END)
      UNION ALL
      SELECT value FROM pg_catalog.jsonb_array_elements(
        CASE WHEN pg_catalog.jsonb_typeof(providers) = 'array' THEN providers ELSE '[]'::jsonb END)
    LOOP
      IF pg_catalog.jsonb_typeof(provider) = 'object' AND provider -> 'configured' = 'true'::jsonb THEN
        configured_count := configured_count + 1;
        all_configuration := all_configuration AND COALESCE(
          provider -> 'verification' = '"configuration"'::jsonb AND provider -> 'liveProbe' = 'false'::jsonb, false);
      END IF;
    END LOOP;
    IF configured_count > 0 AND all_configuration THEN RETURN 'skipped'; END IF;
  END IF;
  RETURN status;
END;
$$;


--
-- Name: store_secure_token(uuid, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.store_secure_token(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16764($1,$2,$3,$4,$5); END$_$;


--
-- Name: stripe_amount_to_minor(numeric, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stripe_amount_to_minor(p_amount numeric, p_currency text) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_currency text := lower(trim(coalesce(p_currency, '')));
  v_minor numeric;
BEGIN
  IF p_amount IS NULL OR p_amount < 0 OR v_currency = '' THEN
    RETURN NULL;
  END IF;

  IF v_currency = 'ugx' THEN
    IF p_amount <> trunc(p_amount) THEN
      RETURN NULL;
    END IF;
    v_minor := p_amount * 100;
  ELSIF v_currency = ANY (ARRAY[
    'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga',
    'pyg', 'rwf', 'vnd', 'vuv', 'xaf', 'xof', 'xpf'
  ]) THEN
    v_minor := round(p_amount);
  ELSE
    v_minor := round(p_amount * 100);
  END IF;

  IF v_minor > 9223372036854775807 THEN
    RETURN NULL;
  END IF;
  RETURN v_minor::bigint;
END;
$$;


--
-- Name: submit_requirement_command(uuid, uuid, uuid, uuid, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_requirement_command(p_requirement_id uuid, p_site_id uuid, p_user_id uuid, p_instance_id uuid, p_action_id uuid, p_patch jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  r public.requirements%ROWTYPE;
  candidate public.requirements%ROWTYPE;
  source public.remote_instances%ROWTYPE;
  action public.instance_logs%ROWTYPE;
  command_revision bigint;
  entry record;
  column_required boolean;
  constraint_row record;
  constraint_valid boolean;
BEGIN
  IF p_requirement_id IS NULL OR p_site_id IS NULL OR p_user_id IS NULL
    OR p_instance_id IS NULL OR p_action_id IS NULL THEN
    RAISE EXCEPTION 'Invalid requirement command scope' USING ERRCODE = '22023';
  END IF;
  -- Keep the scheduler/recovery lock order: requirement, instance, action.
  SELECT * INTO r FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND OR r.site_id IS DISTINCT FROM p_site_id
    OR public.site_user_has_effective_access(p_site_id, p_user_id) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Requirement command authorization denied' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO source FROM public.remote_instances
    WHERE id = p_instance_id AND site_id = p_site_id FOR SHARE;
  IF NOT FOUND OR source.is_archived IS TRUE THEN
    RAISE EXCEPTION 'Requirement command authorization denied' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO action FROM public.instance_logs WHERE id = p_action_id FOR SHARE;
  IF NOT FOUND OR action.site_id IS DISTINCT FROM p_site_id
    OR action.user_id IS DISTINCT FROM p_user_id OR action.instance_id IS DISTINCT FROM p_instance_id
    OR action.log_type IS DISTINCT FROM 'user_action' OR action.trusted_user_action IS DISTINCT FROM true
    OR coalesce(action.details->>'status', '') NOT IN ('running', 'completed') THEN
    RAISE EXCEPTION 'Requirement command authorization denied' USING ERRCODE = '42501';
  END IF;
  -- An authenticated replay cannot replace the original patch, even after drain.
  IF EXISTS (SELECT 1 FROM public.requirement_commands
    WHERE requirement_id = r.id AND action_id = action.id) THEN
    RETURN jsonb_build_object('state', 'duplicate', 'requirement', to_jsonb(r),
      'authorization_action_id', action.id, 'runner_instance_id', r.metadata->>'runner_instance_id');
  END IF;
  IF jsonb_typeof(p_patch) IS DISTINCT FROM 'object' OR p_patch = '{}'::jsonb THEN
    RAISE EXCEPTION 'Invalid requirement command patch' USING ERRCODE = '22023';
  END IF;
  FOR entry IN SELECT key, value FROM jsonb_each(p_patch) LOOP
    IF entry.key NOT IN ('title', 'description', 'instructions', 'priority', 'status',
      'completion_status', 'type', 'budget', 'cron', 'cycle') THEN
      RAISE EXCEPTION 'Invalid requirement command patch field' USING ERRCODE = '22023';
    END IF;
    -- Optional fields/types are read from the installed schema, not a stale copy.
    SELECT attnotnull INTO column_required FROM pg_attribute
      WHERE attrelid = 'public.requirements'::regclass AND attname = entry.key
        AND attnum > 0 AND NOT attisdropped;
    IF NOT FOUND OR (entry.value = 'null'::jsonb AND column_required)
      OR (entry.value <> 'null'::jsonb AND jsonb_typeof(entry.value) <>
        CASE WHEN entry.key = 'budget' THEN 'number' ELSE 'string' END) THEN
      RAISE EXCEPTION 'Invalid requirement command patch type' USING ERRCODE = '22023';
    END IF;
    IF (entry.key = 'priority' AND coalesce(entry.value #>> '{}', '') NOT IN ('high', 'medium', 'low'))
      OR (entry.key = 'status' AND coalesce(entry.value #>> '{}', '') NOT IN ('backlog', 'in-progress'))
      OR (entry.key = 'completion_status' AND entry.value IS DISTINCT FROM '"pending"'::jsonb) THEN
      RAISE EXCEPTION 'Invalid requirement command patch status' USING ERRCODE = '22023';
    END IF;
    IF entry.key IN ('title', 'instructions', 'type') AND coalesce(length(entry.value #>> '{}'), 0) = 0 THEN
      RAISE EXCEPTION 'Invalid requirement command patch empty field' USING ERRCODE = '22023';
    END IF;
    IF (entry.key = 'budget' AND entry.value <> 'null'::jsonb AND (entry.value #>> '{}')::numeric < 0)
      OR (entry.value <> 'null'::jsonb AND entry.key <> 'budget' AND length(entry.value #>> '{}') >
        CASE entry.key WHEN 'title' THEN 300 WHEN 'description' THEN 24000
          WHEN 'instructions' THEN 48000 WHEN 'type' THEN 100 ELSE 200 END) THEN
      RAISE EXCEPTION 'Invalid requirement command patch size or budget' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  -- Use the actual composite type (including enums/numeric constraints) and
  -- CHECK constraints without temporarily updating the requirement or triggers.
  candidate := jsonb_populate_record(r, p_patch);
  FOR constraint_row IN SELECT pg_get_expr(conbin, conrelid) expression
    FROM pg_constraint WHERE conrelid = 'public.requirements'::regclass AND contype = 'c'
  LOOP
    EXECUTE 'SELECT (' || constraint_row.expression || ') FROM (SELECT ($1::public.requirements).*) checked'
      INTO constraint_valid USING candidate;
    IF constraint_valid IS FALSE THEN
      RAISE EXCEPTION 'Invalid requirement command patch constraint' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  SELECT receipt.revision INTO command_revision FROM public.requirement_user_action_receipts receipt
    WHERE receipt.requirement_id = r.id AND receipt.action_id = action.id;
  IF NOT FOUND THEN
    command_revision := r.external_user_action_revision + 1;
    INSERT INTO public.requirement_user_action_receipts(requirement_id, action_id, action_created_at, revision)
      VALUES (r.id, action.id, action.created_at, command_revision);
    UPDATE public.requirements SET external_user_action_revision = command_revision,
      last_external_user_action_id = action.id::text WHERE id = r.id RETURNING * INTO r;
  ELSIF EXISTS (SELECT 1 FROM public.requirement_commands command
    WHERE command.requirement_id = r.id AND command.revision > command_revision) THEN
    -- Recovery receipts are independent, but their first command admission must
    -- not slip behind any newer queued or applied command. The requirement lock
    -- serializes this frontier check with submissions and draining. Existing
    -- command duplicates already returned above and remain valid replays.
    RAISE EXCEPTION 'Stale requirement command receipt revision' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.requirement_commands(requirement_id, action_id, patch, revision)
    VALUES (r.id, action.id, p_patch, command_revision);
  RETURN jsonb_build_object('state', 'queued', 'requirement', to_jsonb(r),
    'authorization_action_id', action.id, 'runner_instance_id', r.metadata->>'runner_instance_id');
END;
$_$;


--
-- Name: subscription_monthly_credit_window(timestamp with time zone, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.subscription_monthly_credit_window(p_start timestamp with time zone, p_end timestamp with time zone, p_at timestamp with time zone) RETURNS TABLE(period_start timestamp with time zone, period_end timestamp with time zone)
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE v_index integer; v_start timestamp; v_at timestamp; v_candidate timestamptz;
BEGIN
  IF p_start IS NULL OR p_end IS NULL OR p_at IS NULL OR NOT isfinite(p_start)
    OR NOT isfinite(p_end) OR NOT isfinite(p_at) OR p_end <= p_start OR p_at < p_start OR p_at >= p_end
  THEN RAISE EXCEPTION 'Invalid covered monthly credit window'; END IF;
  v_start := p_start AT TIME ZONE 'UTC'; v_at := p_at AT TIME ZONE 'UTC';
  v_index := (extract(year FROM v_at)::integer-extract(year FROM v_start)::integer)*12
    + extract(month FROM v_at)::integer-extract(month FROM v_start)::integer;
  v_candidate := (v_start + make_interval(months => v_index)) AT TIME ZONE 'UTC';
  IF v_candidate > p_at THEN v_index := v_index - 1; END IF;
  -- Always calculate from the original anchor (Jan 31 -> Feb 28 -> Mar 31),
  -- never from the preceding clamped month or the worker execution timestamp.
  period_start := (v_start + make_interval(months => v_index)) AT TIME ZONE 'UTC';
  period_end := least((v_start + make_interval(months => v_index+1)) AT TIME ZONE 'UTC',p_end);
  RETURN NEXT;
END;
$$;


--
-- Name: sync_auth0_user(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_auth0_user(auth0_id_param text, email_param text, name_param text, picture_param text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16765($1,$2,$3,$4); END$_$;


--
-- Name: sync_order_line_unit_delivery(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_order_line_unit_delivery() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  UPDATE public.sale_order_item_units
  SET delivered_at = CASE
    WHEN NEW.status = 'delivered'
      THEN COALESCE(NEW.delivered_at, now())
    ELSE NEW.delivered_at
  END
  WHERE shipment_id = NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: sync_order_lines_from_order_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_order_lines_from_order_status() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE line_status text;
BEGIN
  IF public.is_self_service_order_items(NEW.items) AND NEW.status IN ('pending','in_progress') THEN
    RETURN NEW;
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status IN ('pending','in_progress','completed','cancelled') THEN
    line_status := CASE NEW.status WHEN 'pending' THEN 'new' WHEN 'in_progress' THEN 'preparing' ELSE NEW.status END;
    UPDATE public.sale_order_items SET status=line_status
      WHERE site_id=NEW.site_id AND sale_order_id=NEW.id AND status IS DISTINCT FROM line_status;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: sync_sale_order_item_status_from_units(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_sale_order_item_status_from_units() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  shared_status text;
  status_count integer;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  PERFORM 1
  FROM public.sale_order_items
  WHERE id = NEW.sale_order_item_id
  FOR UPDATE;

  SELECT min(status), count(DISTINCT status)
  INTO shared_status, status_count
  FROM public.sale_order_item_units
  WHERE sale_order_item_id = NEW.sale_order_item_id;

  IF status_count = 1 THEN
    UPDATE public.sale_order_items
    SET status = shared_status
    WHERE id = NEW.sale_order_item_id
      AND status IS DISTINCT FROM shared_status;
  END IF;

  RETURN NEW;
END;
$$;

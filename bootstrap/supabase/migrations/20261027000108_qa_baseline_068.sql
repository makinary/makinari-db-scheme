SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: update_instance_plan_step_status_atomic(uuid, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_instance_plan_step_status_atomic(p_plan_id uuid, p_step_id text, p_status text, p_error_message text DEFAULT NULL::text, p_expected_generation integer DEFAULT 0) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_steps jsonb;
  v_step jsonb;
  v_step_index integer;
  v_current_status text;
  v_generation integer;
BEGIN
  IF p_status NOT IN (
    'pending',
    'in_progress',
    'completed',
    'failed',
    'cancelled'
  ) THEN
    RAISE EXCEPTION 'Unsupported plan step status: %', p_status;
  END IF;

  SELECT CASE
    WHEN jsonb_typeof(steps) = 'array' THEN steps
    ELSE '[]'::jsonb
  END
  INTO v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'persisted', false);
  END IF;

  SELECT entry.value, (entry.ordinality - 1)::integer
  INTO v_step, v_step_index
  FROM jsonb_array_elements(v_steps)
    WITH ORDINALITY AS entry(value, ordinality)
  WHERE entry.value->>'id' = p_step_id
  LIMIT 1;
  IF v_step IS NULL THEN
    RETURN jsonb_build_object('state', 'missing', 'persisted', false);
  END IF;

  v_generation := CASE
    WHEN COALESCE(v_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  v_current_status := v_step->>'status';
  IF v_current_status = p_status
    AND p_status IN ('completed', 'failed', 'cancelled')
    AND (
      v_generation IS NOT DISTINCT FROM p_expected_generation
      OR v_generation::bigint IS NOT DISTINCT FROM
        p_expected_generation::bigint + 1
    )
  THEN
    RETURN jsonb_build_object(
      'state', 'duplicate',
      'persisted', true,
      'generation', v_generation
    );
  END IF;
  IF v_generation IS DISTINCT FROM p_expected_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'persisted', false,
      'generation', v_generation
    );
  END IF;
  IF v_current_status IN ('completed', 'cancelled')
    AND v_current_status <> p_status
  THEN
    RETURN jsonb_build_object(
      'state', 'terminal',
      'persisted', false,
      'generation', v_generation
    );
  END IF;

  v_step := v_step || jsonb_build_object(
    'status', p_status,
    'infrastructure_generation', v_generation + 1
  );
  IF p_status = 'in_progress' THEN
    v_step := v_step || jsonb_build_object(
      'started_at',
      COALESCE(v_step->'started_at', to_jsonb(timezone('utc', now())))
    );
  ELSIF p_status IN ('completed', 'failed', 'cancelled') THEN
    v_step := v_step || jsonb_build_object(
      'completed_at', timezone('utc', now())
    );
    IF p_status IN ('completed', 'failed') THEN
      v_step := v_step || jsonb_build_object(
        'infra_retry_count', 0,
        'infra_retry_after', NULL,
        'infrastructure_error', NULL,
        'infrastructure_waiting', false,
        'infrastructure_kind', NULL,
        'infrastructure_failure_provenance', NULL,
        'infrastructure_correlation', NULL,
        'infrastructure_state', NULL,
        'infrastructure_circuit_open', false,
        'infrastructure_intervention_required', false,
        'infrastructure_product_retry_count', NULL
      );
    END IF;
    IF p_status = 'failed' THEN
      v_step := v_step || jsonb_build_object(
        'retry_count', CASE
          WHEN COALESCE(v_step->>'retry_count', '') ~ '^[0-9]{1,9}$'
            THEN (v_step->>'retry_count')::integer + 1
          ELSE 1
        END,
        'error_message', COALESCE(p_error_message, v_step->>'error_message')
      );
    ELSIF p_status = 'completed' THEN
      v_step := v_step || jsonb_build_object('error_message', NULL);
    END IF;
  END IF;

  v_steps := jsonb_set(
    v_steps,
    ARRAY[v_step_index::text],
    v_step,
    false
  );
  UPDATE public.instance_plans
  SET steps = v_steps, updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  RETURN jsonb_build_object(
    'state', 'applied',
    'persisted', true,
    'generation', v_generation + 1
  );
END;
$_$;


--
-- Name: update_lead_analysis_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_lead_analysis_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: update_lead_research_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_lead_research_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_modified_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_sale_orders_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_sale_orders_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: update_site_secrets_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_site_secrets_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;


--
-- Name: update_synced_objects_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_synced_objects_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_webhook_events_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_webhook_events_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_whatsapp_template_tracking_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_whatsapp_template_tracking_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_whatsapp_templates_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_whatsapp_templates_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: upsert_billing(uuid, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean, integer, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_billing(p_site_id uuid, p_plan text DEFAULT NULL::text, p_card_name text DEFAULT NULL::text, p_masked_card_number text DEFAULT NULL::text, p_card_expiry text DEFAULT NULL::text, p_stripe_customer_id text DEFAULT NULL::text, p_stripe_payment_method_id text DEFAULT NULL::text, p_stripe_subscription_id text DEFAULT NULL::text, p_card_address text DEFAULT NULL::text, p_card_city text DEFAULT NULL::text, p_card_postal_code text DEFAULT NULL::text, p_card_country text DEFAULT NULL::text, p_tax_id text DEFAULT NULL::text, p_billing_address text DEFAULT NULL::text, p_billing_city text DEFAULT NULL::text, p_billing_postal_code text DEFAULT NULL::text, p_billing_country text DEFAULT NULL::text, p_auto_renew boolean DEFAULT NULL::boolean, p_credits_available integer DEFAULT NULL::integer, p_subscription_status text DEFAULT NULL::text, p_subscription_current_period_end timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16784($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21); END$_$;


--
-- Name: user_can(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.user_can(p_site_id uuid, p_command text) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    SET row_security TO 'off'
    AS $$
DECLARE
  r text;
  cmd text;
BEGIN
  cmd := lower(coalesce(p_command, ''));
  r := public.current_user_site_role(p_site_id);

  IF r IS NULL THEN
    RETURN false;
  END IF;

  IF cmd = 'select' THEN
    RETURN true;
  END IF;

  IF r IN ('owner', 'admin') THEN
    RETURN cmd IN ('insert', 'update', 'delete');
  END IF;

  IF r = 'collaborator' THEN
    RETURN cmd IN ('insert', 'update');
  END IF;

  RETURN false;
END;
$$;


--
-- Name: user_can_access_location(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.user_can_access_location(p_site_id uuid, p_location_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE effective_role text; member_id uuid; member_count integer;
BEGIN
  IF auth.uid() IS NULL OR p_site_id IS NULL THEN RETURN false; END IF;
  effective_role := public.current_user_site_role(p_site_id);
  IF effective_role IS NULL OR effective_role NOT IN ('owner', 'admin', 'collaborator', 'marketing') THEN
    RETURN false;
  END IF;
  -- Even an exempt manager cannot authorize unknown or cross-site locations.
  IF p_location_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.locations l WHERE l.id = p_location_id AND l.site_id = p_site_id
  ) THEN RETURN false; END IF;
  SELECT count(*), (array_agg(sm.id))[1] INTO member_count, member_id
    FROM public.site_members sm WHERE sm.site_id = p_site_id
      AND sm.user_id = auth.uid() AND sm.status = 'active';
  IF member_count > 1 OR (member_count = 0 AND effective_role <> 'owner') THEN RETURN false; END IF;
  IF effective_role IN ('owner', 'admin') THEN RETURN true; END IF;
  IF p_location_id IS NULL THEN
    RETURN NOT EXISTS (SELECT 1 FROM public.site_member_location_restrictions r
      WHERE r.site_id = p_site_id AND r.site_member_id = member_id);
  END IF;
  RETURN NOT EXISTS (SELECT 1 FROM public.site_member_location_restrictions r
    WHERE r.site_id = p_site_id AND r.site_member_id = member_id AND r.location_id = p_location_id);
END;
$$;


--
-- Name: user_has_access_to_site(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.user_has_access_to_site(user_id_param uuid, site_id_param uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16785($1,$2); END$_$;


--
-- Name: valid_harness_snapshot(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valid_harness_snapshot(s jsonb) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE k text; n numeric; item jsonb;
BEGIN
  IF jsonb_typeof(s) IS DISTINCT FROM 'object' OR octet_length(s::text) > 4000000 THEN RETURN false; END IF;
  IF jsonb_typeof(s->'id') IS DISTINCT FROM 'string'
    OR NOT (s->>'status' = ANY(ARRAY['queued','running','completed','waiting','paused','failed','cancelled']))
    OR jsonb_typeof(s->'status') IS DISTINCT FROM 'string'
    OR jsonb_typeof(s->'request') IS DISTINCT FROM 'object'
    OR jsonb_typeof(s#>'{request,limits}') IS DISTINCT FROM 'object'
    OR jsonb_typeof(s#>'{request,objective}') IS DISTINCT FROM 'string'
    OR length(s#>>'{request,objective}') NOT BETWEEN 1 AND 24000
    OR jsonb_typeof(s#>'{request,repository,url}') IS DISTINCT FROM 'string'
    OR length(s#>>'{request,repository,url}') NOT BETWEEN 1 AND 4000
    OR jsonb_typeof(s->'createdAt') IS DISTINCT FROM 'string'
    OR jsonb_typeof(s->'updatedAt') IS DISTINCT FROM 'string'
    OR jsonb_typeof(s->'messages') IS DISTINCT FROM 'array'
    OR jsonb_typeof(s->'uncertainOperations') IS DISTINCT FROM 'array'
  THEN RETURN false; END IF;
  FOREACH k IN ARRAY ARRAY['version','turns','allocatedTokens','activeMs'] LOOP
    IF jsonb_typeof(s->k) IS DISTINCT FROM 'number' THEN RETURN false; END IF;
    n := (s->>k)::numeric;
    IF n < 0 OR n > 9007199254740991 OR trunc(n) <> n THEN RETURN false; END IF;
  END LOOP;
  FOREACH k IN ARRAY ARRAY['maxTurns','maxOutputTokens','maxTotalTokens','maxActiveMs'] LOOP
    IF jsonb_typeof(s#>ARRAY['request','limits',k]) IS DISTINCT FROM 'number' THEN RETURN false; END IF;
    n := (s#>>ARRAY['request','limits',k])::numeric;
    IF n < 1 OR trunc(n) <> n OR n > (CASE k WHEN 'maxTurns' THEN 1000 WHEN 'maxOutputTokens' THEN 131072 WHEN 'maxTotalTokens' THEN 100000000 ELSE 86400000 END)
    THEN RETURN false; END IF;
  END LOOP;
  IF jsonb_array_length(s->'messages') > 10000 OR jsonb_array_length(s->'uncertainOperations') > 10000 THEN RETURN false; END IF;
  FOR item IN SELECT value FROM jsonb_array_elements(s->'messages') LOOP
    IF jsonb_typeof(item) IS DISTINCT FROM 'object' OR jsonb_typeof(item->'role') IS DISTINCT FROM 'string'
      OR NOT (item->>'role' = ANY(ARRAY['user','assistant','tool']))
      OR jsonb_typeof(item->'content') IS DISTINCT FROM 'string' THEN RETURN false; END IF;
  END LOOP;
  FOR item IN SELECT value FROM jsonb_array_elements(s->'uncertainOperations') LOOP
    IF jsonb_typeof(item) IS DISTINCT FROM 'string' OR length(item#>>'{}') > 1000 THEN RETURN false; END IF;
  END LOOP;
  IF s ? 'workspace' AND (jsonb_typeof(s->'workspace') IS DISTINCT FROM 'object'
    OR s#>>'{workspace,provider}' IS DISTINCT FROM 'vercel'
    OR jsonb_typeof(s#>'{workspace,id}') IS DISTINCT FROM 'string' OR length(s#>>'{workspace,id}') NOT BETWEEN 1 AND 1000
    OR jsonb_typeof(s#>'{workspace,root}') IS DISTINCT FROM 'string' OR left(s#>>'{workspace,root}',1) <> '/') THEN RETURN false; END IF;
  IF s ? 'pending' AND (jsonb_typeof(s->'pending') IS DISTINCT FROM 'object'
    OR jsonb_typeof(s#>'{pending,call}') IS DISTINCT FROM 'object'
    OR jsonb_typeof(s#>'{pending,call,id}') IS DISTINCT FROM 'string'
    OR jsonb_typeof(s#>'{pending,call,name}') IS DISTINCT FROM 'string'
    OR jsonb_typeof(s#>'{pending,call,arguments}') IS DISTINCT FROM 'string'
    OR jsonb_typeof(s#>'{pending,fingerprint}') IS DISTINCT FROM 'string'
    OR NOT (s#>>'{pending,effect}' = ANY(ARRAY['read','write']))
    OR jsonb_typeof(s#>'{pending,effect}') IS DISTINCT FROM 'string') THEN RETURN false; END IF;
  RETURN true;
EXCEPTION WHEN OTHERS THEN RETURN false;
END;
$$;

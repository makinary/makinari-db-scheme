SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: bill_openrouter_generation(uuid, text, numeric, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bill_openrouter_generation(p_site_id uuid, p_event_id text, p_provider_cost numeric, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  charge public.openrouter_generation_charges%ROWTYPE;
  v_result jsonb;
BEGIN
  IF p_site_id IS NULL OR p_event_id IS NULL OR length(p_event_id) NOT BETWEEN 1 AND 256
    OR p_provider_cost < 0
    OR p_provider_cost::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Invalid OpenRouter usage charge';
  END IF;
  -- Serialize first registration as well as retries, before any billing bucket lock.
  PERFORM pg_advisory_xact_lock(hashtextextended('openrouter_generation:' || p_event_id, 0));
  SELECT * INTO charge FROM public.openrouter_generation_charges WHERE event_id = p_event_id FOR UPDATE;
  IF FOUND THEN
    IF charge.site_id <> p_site_id OR (charge.provider_cost IS NOT NULL AND p_provider_cost IS NOT NULL
      AND charge.provider_cost <> p_provider_cost) THEN
      RAISE EXCEPTION 'OpenRouter billing identity conflict';
    END IF;
    IF charge.state = 'charged' THEN RETURN charge.result; END IF;
    IF charge.metadata ? 'harness_reservation_event' THEN
      RETURN jsonb_build_object('success',false,'error','Reserved generation requires reservation reconciliation');
    END IF;
    IF charge.provider_cost IS NULL AND p_provider_cost IS NOT NULL THEN
      UPDATE public.openrouter_generation_charges SET provider_cost=p_provider_cost,amount=p_provider_cost*1.25
        WHERE event_id=p_event_id RETURNING * INTO charge;
    END IF;
  ELSE
    INSERT INTO public.openrouter_generation_charges(event_id,site_id,provider_cost,amount,metadata)
      VALUES(p_event_id,p_site_id,p_provider_cost,p_provider_cost * 1.25,coalesce(p_metadata,'{}'::jsonb))
      RETURNING * INTO charge;
  END IF;
  IF charge.provider_cost IS NULL THEN
    v_result := jsonb_build_object('success',false,'error','Provider cost requires reconciliation');
    UPDATE public.openrouter_generation_charges SET result=v_result WHERE event_id=p_event_id;
    RETURN v_result;
  END IF;
  IF charge.amount = 0 THEN
    v_result := jsonb_build_object('success',true,'charged',0,'provider_cost',charge.provider_cost,'multiplier',1.25);
  ELSE
    v_result := public.deduct_credits(p_site_id,charge.amount,'assistant_tokens','OpenRouter actual usage + 25% markup',
      charge.metadata || jsonb_build_object('provider','openrouter','generation_id',p_event_id,
        'provider_cost',charge.provider_cost,'cost_multiplier',1.25));
  END IF;
  IF v_result->>'success' = 'true' THEN
    v_result := v_result || jsonb_build_object('charged',charge.amount,'provider_cost',charge.provider_cost,'multiplier',1.25);
    UPDATE public.openrouter_generation_charges SET state='charged',result=v_result,charged_at=now() WHERE event_id=p_event_id;
  ELSE
    -- Keep known, unpaid usage for operator reconciliation; never re-run the generation.
    UPDATE public.openrouter_generation_charges SET result=v_result WHERE event_id=p_event_id;
  END IF;
  RETURN v_result;
END;
$$;


--
-- Name: bill_sandbox_sessions(text, jsonb, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bill_sandbox_sessions(p_sandbox_name text, p_sessions jsonb, p_observed_at timestamp with time zone) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE r public.sandbox_billing_resources%ROWTYPE; s public.sandbox_billing_sessions%ROWTYPE;
  item jsonb; v_id text; v_start timestamptz; v_end timestamptz; v_until timestamptz;
  v_from timestamptz; v_amount numeric; v_total numeric := 0; result jsonb;
BEGIN
  IF p_observed_at IS NULL OR NOT isfinite(p_observed_at)
    OR p_observed_at > clock_timestamp() + interval '5 seconds'
    OR jsonb_typeof(p_sessions) IS DISTINCT FROM 'array' OR jsonb_array_length(p_sessions) > 1000 THEN
    RAISE EXCEPTION 'Invalid sandbox session observation';
  END IF;
  SELECT * INTO r FROM public.sandbox_billing_resources WHERE sandbox_name = p_sandbox_name FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',true,'outcome','untracked','credits_charged',0); END IF;
  -- One resource row serializes cron/stop/recovery requests. The global session
  -- primary key prevents one actual VM being assigned to two billing resources.
  FOR item IN SELECT value FROM jsonb_array_elements(p_sessions) LOOP
    v_id := item->>'id';
    v_start := (item->>'started_at')::timestamptz;
    v_end := (item->>'ended_at')::timestamptz;
    IF v_id IS NULL OR length(v_id) NOT BETWEEN 1 AND 200 OR v_start IS NULL OR NOT isfinite(v_start)
      OR (v_end IS NOT NULL AND (NOT isfinite(v_end) OR v_end < v_start)) THEN
      RAISE EXCEPTION 'Invalid VM session interval';
    END IF;
    v_until := least(coalesce(v_end,p_observed_at),p_observed_at,clock_timestamp());
    -- Entire old sessions are not even adopted; stopped time is never included.
    IF v_until <= greatest(v_start,r.registered_at) THEN CONTINUE; END IF;
    INSERT INTO public.sandbox_billing_sessions(session_id,sandbox_name,started_at,billed_through)
      VALUES(v_id,p_sandbox_name,v_start,greatest(v_start,r.registered_at)) ON CONFLICT DO NOTHING;
    SELECT * INTO s FROM public.sandbox_billing_sessions WHERE session_id = v_id FOR UPDATE;
    IF s.sandbox_name <> p_sandbox_name OR s.started_at <> v_start THEN
      RAISE EXCEPTION 'VM session billing identity conflict';
    END IF;
    IF (s.ended_at IS NOT NULL AND v_end IS NOT NULL AND s.ended_at <> v_end)
      OR (v_end IS NOT NULL AND v_end < s.billed_through) THEN
      RAISE EXCEPTION 'VM session terminal interval conflict';
    END IF;
    IF s.ended_at IS NOT NULL THEN v_until := least(v_until,s.ended_at); END IF;
    v_from := s.billed_through;
    IF v_until > v_from THEN
      -- Unbounded numeric: no per-tick rounding, margin, or whole-hour rounding.
      v_amount := extract(epoch FROM (v_until-greatest(v_start,r.registered_at))) * 0.5 / 3600 - s.credits_charged;
      result := public.deduct_credits(r.site_id,v_amount,'sandbox_usage','Active sandbox VM time',
        jsonb_build_object('sandbox_name',p_sandbox_name,'session_id',v_id,
          'from',v_from,'through',v_until,'credits_per_hour',0.5));
      IF NOT coalesce((result->>'success')::boolean,false) THEN
        -- Roll back ALL deductions/watermarks in this batch, preserving payable
        -- intervals for retry after replenishment. No partial/phantom settlement.
        RAISE EXCEPTION 'Sandbox billing requires available credits' USING ERRCODE = 'P0001';
      END IF;
      UPDATE public.sandbox_billing_sessions SET billed_through=v_until,
        credits_charged=credits_charged+v_amount WHERE session_id=v_id;
      v_total := v_total+v_amount;
    END IF;
    IF v_end IS NOT NULL THEN
      UPDATE public.sandbox_billing_sessions SET ended_at=least(coalesce(ended_at,v_end),v_end) WHERE session_id=v_id;
    END IF;
  END LOOP;
  RETURN jsonb_build_object('success',true,'credits_charged',v_total);
END;
$$;


--
-- Name: billing_license_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.billing_license_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE target_site_id uuid;
BEGIN
  target_site_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.site_id ELSE NEW.site_id END;
  PERFORM public.lock_site_license(target_site_id);
  IF TG_WHEN = 'AFTER' THEN
    -- Usage-only writes and identical provider retries must not rewrite settings.
    -- Include every billing input used by effective_site_plan and the add-on pool.
    IF TG_OP = 'UPDATE' AND ROW(
      NEW.plan,NEW.addons_count,NEW.status,NEW.stripe_subscription_id,NEW.subscription_status,
      NEW.paid_subscription_invoice_id,NEW.paid_subscription_period_start,NEW.paid_subscription_period_end,
      NEW.trial_started_at,NEW.trial_ends_at,NEW.trial_converted_at
    ) IS NOT DISTINCT FROM ROW(
      OLD.plan,OLD.addons_count,OLD.status,OLD.stripe_subscription_id,OLD.subscription_status,
      OLD.paid_subscription_invoice_id,OLD.paid_subscription_period_start,OLD.paid_subscription_period_end,
      OLD.trial_started_at,OLD.trial_ends_at,OLD.trial_converted_at
    ) THEN RETURN NULL; END IF;
    PERFORM public.reconcile_site_member_license(target_site_id);
    UPDATE public.settings SET social_media = social_media,channels = channels WHERE settings.site_id = target_site_id;
    RETURN NULL;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  IF TG_OP = 'UPDATE' AND NEW.site_id IS DISTINCT FROM OLD.site_id THEN RAISE EXCEPTION 'Billing site is immutable'; END IF;
  RETURN NEW;
END;
$$;

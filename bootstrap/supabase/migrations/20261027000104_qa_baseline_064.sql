SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: settle_stripe_subscription_invoice(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.settle_stripe_subscription_invoice(p_invoice jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  v_site uuid := (p_invoice->>'site_id')::uuid;
  v_invoice text := p_invoice->>'invoice_id';
  v_customer text := p_invoice->>'customer_id';
  v_subscription text := p_invoice->>'subscription_id';
  v_status text := p_invoice->>'status';
  v_amount numeric := (p_invoice->>'amount')::numeric;
  v_currency text := p_invoice->>'currency';
  v_plan text := p_invoice->>'plan';
  v_addons integer := (p_invoice->>'addons_count')::integer;
  v_reason text := p_invoice->>'billing_reason';
  v_interval text := coalesce(p_invoice->>'billing_interval','month');
  v_current_status text := lower(nullif(p_invoice->>'current_subscription_status', ''));
  v_period_start timestamptz := nullif(p_invoice->>'period_start', '')::timestamptz;
  v_period_end timestamptz := nullif(p_invoice->>'period_end', '')::timestamptz;
  v_paid_at timestamptz := nullif(p_invoice->>'paid_at', '')::timestamptz;
  v_credits integer := 0;
  v_reset jsonb;
  v_credit_outcome text := 'not_eligible';
  v_billing public.billing%ROWTYPE;
  v_payment public.payments%ROWTYPE;
  v_settlement public.stripe_subscription_invoice_settlements%ROWTYPE;
  v_details jsonb;
  v_coverage jsonb;
  v_duplicate boolean := false;
  v_applied boolean := false;
BEGIN
  IF jsonb_typeof(p_invoice) IS DISTINCT FROM 'object'
    OR v_site IS NULL OR v_invoice IS NULL OR v_invoice !~ '^in_[A-Za-z0-9]+$'
    OR v_customer IS NULL OR v_customer !~ '^cus_[A-Za-z0-9]+$'
    OR v_subscription IS NULL OR v_subscription !~ '^sub_[A-Za-z0-9]+$'
    OR v_status IS NULL OR v_status NOT IN ('paid', 'failed')
    OR v_amount IS NULL OR v_amount < 0 OR v_amount::text IN ('NaN', 'Infinity', '-Infinity')
    OR v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$'
    OR v_plan IS NULL OR v_plan NOT IN ('commission', 'engine', 'foundry', 'enterprise')
    OR (v_plan = 'commission' AND (v_addons < 1 OR p_invoice->'coverage_verified' IS DISTINCT FROM 'true'::jsonb))
    OR v_addons IS NULL OR v_addons < 0 OR v_addons > 100
    OR v_interval NOT IN ('month','year')
    OR v_reason IS NULL
    OR (v_current_status IS NOT NULL AND v_current_status NOT IN
      ('active', 'trialing', 'past_due', 'unpaid', 'incomplete', 'paused', 'canceled', 'cancelled', 'incomplete_expired'))
    OR (v_status = 'paid' AND (v_paid_at IS NULL OR NOT isfinite(v_paid_at)))
    OR ((v_period_start IS NULL) <> (v_period_end IS NULL))
    OR (v_period_start IS NOT NULL AND (NOT isfinite(v_period_start)
      OR NOT isfinite(v_period_end) OR v_period_end <= v_period_start))
    OR (v_reason IN ('subscription_create', 'subscription_cycle') AND v_period_start IS NULL)
    OR (v_status = 'paid' AND v_reason IN ('subscription_create', 'subscription_cycle')
      AND v_period_start > now())
  THEN RAISE EXCEPTION 'Invalid verified Stripe invoice'; END IF;

  -- Same invoice on different sites must serialize before tenant validation.
  PERFORM pg_advisory_xact_lock(hashtextextended('stripe-invoice:' || v_invoice, 0));
  SELECT * INTO v_billing FROM public.billing WHERE site_id = v_site FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Invoice site has no billing record'; END IF;
  IF v_billing.stripe_customer_id IS DISTINCT FROM v_customer
    OR (v_billing.stripe_subscription_id IS NOT NULL
      AND v_billing.stripe_subscription_id <> v_subscription)
    OR EXISTS (SELECT 1 FROM public.site_retired_stripe_subscriptions
      WHERE site_id = v_site AND subscription_id = v_subscription)
  THEN RAISE EXCEPTION 'Stripe invoice billing identity mismatch'; END IF;

  SELECT * INTO v_payment FROM public.payments
    WHERE transaction_id = 'stripe_invoice_' || v_invoice FOR UPDATE;
  IF FOUND AND (v_payment.site_id <> v_site OR v_payment.transaction_type <> 'subscription')
  THEN RAISE EXCEPTION 'Stripe invoice payment identity mismatch'; END IF;

  SELECT * INTO v_settlement FROM public.stripe_subscription_invoice_settlements
    WHERE invoice_id = v_invoice;
  IF FOUND THEN
    IF v_settlement.site_id <> v_site OR v_settlement.customer_id <> v_customer
      OR v_settlement.subscription_id <> v_subscription
      OR (v_status = 'paid' AND (v_settlement.amount <> v_amount OR v_settlement.currency <> v_currency))
    THEN RAISE EXCEPTION 'Stripe invoice settlement identity mismatch'; END IF;
  END IF;

  -- Invoice snapshots are not status updates. In particular a delayed duplicate
  -- paused snapshot cannot poison an active row, or revive a newly paused row.
  -- Status synchronization is a separate expected-subscription-ID fenced RPC.
  IF v_settlement.invoice_id IS NOT NULL THEN
    IF v_status <> 'paid' OR v_settlement.credit_coverage_applied
      OR v_settlement.verified_credit_coverage IS NULL THEN
      RETURN jsonb_build_object('outcome', CASE WHEN v_status = 'paid' THEN 'duplicate' ELSE 'ignored_failure' END,
        'payment_id', v_settlement.payment_id, 'credits_granted', 0);
    END IF;
    v_duplicate := true;
    -- Financial identity was checked above. Never replace settled coverage with
    -- retry-supplied tier, period, reason, interval or paid_at.
    v_coverage := v_settlement.verified_credit_coverage;
    v_period_end := (v_coverage->>'period_end')::timestamptz;
  ELSE
    IF v_status = 'paid' AND (v_reason IN ('subscription_create','subscription_cycle')
      OR (v_reason = 'subscription_update' AND coalesce((p_invoice->>'coverage_verified')::boolean,false))) THEN
      v_coverage := jsonb_build_object('site_id',v_site,'subscription_id',v_subscription,
        'invoice_id',v_invoice,'plan',v_plan,'addons_count',v_addons,'billing_interval',v_interval,
        'billing_reason',v_reason,'period_start',v_period_start,'period_end',v_period_end,
        'paid_at',v_paid_at,'coverage_verified',true);
    END IF;
  END IF;

  IF v_status = 'failed' AND v_payment.status IS NOT NULL AND v_payment.status <> 'failed' THEN
    RETURN jsonb_build_object('outcome', 'ignored_failure', 'payment_id', v_payment.id, 'credits_granted', 0);
  END IF;
  IF NOT v_duplicate AND v_status = 'paid' AND v_payment.status IS NOT NULL AND v_payment.status <> 'failed' THEN
    RAISE EXCEPTION 'Legacy completed invoice requires credit reconciliation';
  END IF;
  IF NOT v_duplicate AND v_status = 'paid' AND EXISTS (
    SELECT 1 FROM public.credit_transactions
    WHERE site_id = v_site AND metadata->>'stripe_invoice_id' = v_invoice AND amount > 0
  ) THEN RAISE EXCEPTION 'Invoice already has historical credits; reconciliation required'; END IF;
  IF NOT v_duplicate AND v_status = 'paid' AND v_reason = 'subscription_create' AND EXISTS (
    SELECT 1 FROM public.payments WHERE site_id = v_site AND status = 'completed'
      AND transaction_type = 'subscription' AND details->>'stripe_subscription_id' = v_subscription
      AND details ? 'stripe_session_id'
  ) THEN RAISE EXCEPTION 'Legacy subscription checkout requires credit reconciliation'; END IF;

  IF v_status = 'paid' AND v_coverage IS NOT NULL THEN
    IF lower(coalesce(v_billing.subscription_status, '')) IN ('canceled', 'cancelled', 'incomplete_expired')
      OR v_current_status IN ('canceled','cancelled','incomplete_expired') THEN
      -- Historical payment is still auditable, but must never resurrect paid
      -- entitlement after the current subscription has terminated.
      v_credit_outcome := 'terminal_subscription';
    ELSIF lower(coalesce(v_billing.subscription_status,'')) <> 'active'
      OR (v_current_status IS NOT NULL AND v_current_status <> 'active') THEN
      v_credit_outcome := 'inactive_subscription';
    ELSIF coalesce(v_billing.status, '') <> 'active' OR EXISTS (
      SELECT 1 FROM public.sites WHERE id = v_site AND archived_at IS NOT NULL
    ) THEN
      v_credit_outcome := 'inactive';
    ELSIF v_period_end <= now() THEN
      -- Do not retry an already expired historical invoice forever. Record it
      -- without a grant rather than asking the current-period helper to reject it.
      v_credit_outcome := 'stale_period';
    ELSIF (v_coverage->>'billing_reason' = 'subscription_update' OR v_coverage->>'plan' = 'commission') AND (
      p_invoice->'coverage_verified' IS DISTINCT FROM 'true'::jsonb
      OR jsonb_typeof(p_invoice->'current_service') IS DISTINCT FROM 'object'
      OR p_invoice->'current_service'->'plan' IS DISTINCT FROM v_coverage->'plan'
      OR p_invoice->'current_service'->'addons_count' IS DISTINCT FROM v_coverage->'addons_count'
      OR p_invoice->'current_service'->'billing_interval' IS DISTINCT FROM v_coverage->'billing_interval') THEN
      -- Immutable invoice proof does not prove the currently configured service.
      -- Gate by a separate fresh server-verified tuple, never retry-supplied
      -- invoice entitlement, and never overwrite/poison the settled payload.
      v_credit_outcome := 'current_service_mismatch';
    ELSE
      v_reset := public.apply_paid_subscription_credit_coverage(v_coverage);
      IF (v_reset->>'success')::boolean IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Stripe plan credit reset failed';
      END IF;
      v_credits := (v_reset->>'credits_granted')::integer;
      v_credit_outcome := v_reset->>'outcome';
      v_applied := v_credit_outcome IN ('reset','adjusted','not_due');
    END IF;
  END IF;

  IF v_duplicate THEN
    IF v_applied THEN
      UPDATE public.stripe_subscription_invoice_settlements SET credit_coverage_applied = true,
        credits_granted = credits_granted + v_credits WHERE invoice_id = v_invoice;
      UPDATE public.payments SET credits = coalesce(credits,0) + v_credits,
        details = coalesce(details,'{}'::jsonb) || jsonb_build_object('credit_outcome',v_credit_outcome,
          'credit_coverage_recovered',true),updated_at = now() WHERE id = v_settlement.payment_id;
    END IF;
    RETURN jsonb_build_object('outcome','duplicate','payment_id',v_settlement.payment_id,
      'credits_granted',v_credits,'credit_outcome',v_credit_outcome,'coverage_recovered',v_applied);
  END IF;

  v_details := jsonb_strip_nulls(jsonb_build_object(
    'stripe_invoice_id', v_invoice, 'stripe_subscription_id', v_subscription,
    'stripe_customer_id', v_customer, 'stripe_payment_intent_id', p_invoice->>'payment_intent_id',
    'billing_reason', v_reason, 'plan', v_plan, 'addons_count', v_addons, 'billing_interval', v_interval,
    'stripe_event_id', p_invoice->>'event_id', 'paid_at', p_invoice->>'paid_at',
    'period_start', v_period_start, 'period_end', v_period_end,
    'credit_bucket', 'plan', 'credit_outcome', v_credit_outcome
  ));
  IF v_payment.id IS NULL THEN
    INSERT INTO public.payments(site_id, transaction_id, transaction_type, amount, currency,
      status, payment_method, details, credits, invoice_url)
    VALUES (v_site, 'stripe_invoice_' || v_invoice, 'subscription', v_amount, v_currency,
      CASE WHEN v_status = 'paid' THEN 'completed' ELSE 'failed' END, 'stripe', v_details,
      v_credits, p_invoice->>'invoice_url') RETURNING * INTO v_payment;
  ELSE
    UPDATE public.payments SET amount = v_amount, currency = v_currency,
      status = CASE WHEN v_status = 'paid' THEN 'completed' ELSE 'failed' END,
      details = coalesce(details, '{}'::jsonb) || v_details,
      credits = v_credits, invoice_url = coalesce(p_invoice->>'invoice_url', invoice_url), updated_at = now()
    WHERE id = v_payment.id;
  END IF;
  IF v_status = 'failed' THEN
    RETURN jsonb_build_object('outcome', 'failed_recorded', 'payment_id', v_payment.id, 'credits_granted', 0);
  END IF;

  INSERT INTO public.stripe_subscription_invoice_settlements(invoice_id, site_id, payment_id,
    customer_id, subscription_id, amount, currency, credits_granted, event_id,
    verified_credit_coverage,credit_coverage_applied)
  VALUES (v_invoice, v_site, v_payment.id, v_customer, v_subscription, v_amount, v_currency,
    v_credits, p_invoice->>'event_id',v_coverage,v_applied);
  -- The helper wrote the plan reset ledger atomically. Never also append an
  -- additive subscription grant or change purchased/legacy/account_balance.
  RETURN jsonb_build_object('outcome', 'settled', 'payment_id', v_payment.id, 'credits_granted', v_credits);
END;
$_$;


--
-- Name: shop_category_offsets(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.shop_category_offsets(p_site_id uuid) RETURNS TABLE(name text, "offset" integer, count integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_3976648($1); END$_$;


--
-- Name: simulate_user_creation(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.simulate_user_creation(test_email text, test_name text, test_referral_code text) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
  test_user_id UUID;
  test_user_record RECORD;
  trigger_result RECORD;
BEGIN
  -- Generar ID único para el test
  test_user_id := gen_random_uuid();
  
  PERFORM log_debug('=== SIMULACIÓN DE CREACIÓN DE USUARIO ===');
  PERFORM log_debug('Email: ' || test_email);
  PERFORM log_debug('Nombre: ' || test_name);
  PERFORM log_debug('Código: ' || test_referral_code);
  PERFORM log_debug('ID generado: ' || test_user_id::TEXT);
  
  -- Crear registro simulado
  SELECT 
    test_user_id as id,
    test_email as email,
    jsonb_build_object(
      'name', test_name,
      'referral_code', test_referral_code
    ) as raw_user_meta_data,
    NOW() as created_at,
    NOW() as updated_at
  INTO test_user_record;
  
  -- Ejecutar la función de trigger manualmente
  PERFORM handle_new_user_debug() FROM (
    SELECT 
      test_user_record.id as id,
      test_user_record.email as email,
      test_user_record.raw_user_meta_data as raw_user_meta_data,
      test_user_record.created_at as created_at,
      test_user_record.updated_at as updated_at
  ) AS NEW;
  
  RETURN 'Simulación completada - revisa los logs NOTICE arriba';
  
EXCEPTION WHEN OTHERS THEN
  RETURN 'Error en simulación: ' || SQLERRM;
END;
$$;


--
-- Name: site_member_has_effective_license(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.site_member_has_effective_license(p_member_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
  SELECT coalesce((
    SELECT NOT m.manually_disabled AND (m.user_id = s.user_id OR (
      SELECT count(*) FROM public.site_members earlier
      WHERE earlier.site_id=m.site_id AND earlier.user_id IS DISTINCT FROM s.user_id
        AND earlier.status IN ('active','pending') AND NOT earlier.manually_disabled
        AND (coalesce(earlier.created_at,'infinity'::timestamptz),earlier.id)
          <= (coalesce(m.created_at,'infinity'::timestamptz),m.id)
    ) < CASE public.effective_site_plan(m.site_id)
      WHEN 'engine' THEN 5 WHEN 'foundry' THEN 10 WHEN 'enterprise' THEN 2147483647 ELSE 1 END)
    FROM public.site_members m JOIN public.sites s ON s.id=m.site_id
    WHERE m.id=p_member_id AND s.archived_at IS NULL AND m.status IN ('active','pending')
  ),false);
$$;


--
-- Name: site_owner_has_platform_payment(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.site_owner_has_platform_payment(p_site_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
DECLARE owner_id uuid;
BEGIN
  SELECT user_id INTO owner_id FROM public.sites WHERE id=p_site_id;
  IF NOT FOUND OR owner_id IS NULL THEN RETURN true; END IF;
  RETURN EXISTS (
    SELECT 1 FROM public.payments p JOIN public.sites s ON s.id=p.site_id
    WHERE (s.user_id=owner_id OR s.id=p_site_id)
      AND p.transaction_type IN ('subscription','credits_purchase')
      AND p.status IN ('completed','refunded','partially_refunded')
      AND p.amount>0 AND p.amount::text NOT IN ('NaN','Infinity','-Infinity')
  ) OR EXISTS (
    SELECT 1 FROM public.stripe_subscription_invoice_settlements settlement
      JOIN public.sites s ON s.id=settlement.site_id
    WHERE (s.user_id=owner_id OR s.id=p_site_id)
      AND settlement.amount>0 AND settlement.amount::text NOT IN ('NaN','Infinity','-Infinity')
  );
END;
$$;


--
-- Name: site_owner_license_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.site_owner_license_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id OR (OLD.archived_at IS NOT NULL AND NEW.archived_at IS NULL) THEN
    PERFORM public.reconcile_site_member_license(NEW.id);
    UPDATE public.settings SET social_media = social_media,channels = channels WHERE site_id = NEW.id;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: site_plan_credit_allowance(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.site_plan_credit_allowance(p_plan text, p_addons integer DEFAULT 0) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  RETURN CASE lower(trim(p_plan))
    WHEN 'engine' THEN 20 WHEN 'starter' THEN 20
    WHEN 'foundry' THEN 100 WHEN 'startup' THEN 100
    WHEN 'enterprise' THEN 500
    WHEN 'commission' THEN 1 WHEN 'free' THEN 1 WHEN 'toolbox' THEN 1
    ELSE 0 END
    + CASE WHEN lower(trim(p_plan)) IN ('commission','engine','starter','foundry','startup','enterprise')
      THEN greatest(coalesce(p_addons, 0), 0) ELSE 0 END;
END;
$$;


--
-- Name: site_user_has_effective_access(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.site_user_has_effective_access(p_site_id uuid, p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
  SELECT p_user_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.sites s WHERE s.id=p_site_id AND s.archived_at IS NULL
      AND (s.user_id=p_user_id OR EXISTS (
        SELECT 1 FROM public.site_members m WHERE m.site_id=s.id AND m.user_id=p_user_id
          AND m.status='active' AND public.site_member_has_effective_license(m.id)
      ))
  );
$$;


--
-- Name: stamp_requirement_review_quarantine(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stamp_requirement_review_quarantine() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
  v_item jsonb;
  v_items jsonb := '[]'::jsonb;
  v_changed boolean := false;
  v_now timestamptz := timezone('utc', now());
BEGIN
  IF jsonb_typeof(NEW.backlog->'items') <> 'array' THEN
    RETURN NEW;
  END IF;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(NEW.backlog->'items')
      WITH ORDINALITY
    ORDER BY ordinality
  LOOP
    IF v_item->>'status' = 'needs_review'
      AND COALESCE(
        v_item->'review_quarantine'->>'active',
        'false'
      ) <> 'true'
    THEN
      v_item := v_item || jsonb_build_object(
        'review_quarantine',
        jsonb_build_object(
          'active', true,
          'kind', 'manual',
          'reason', 'Review quarantine created by database guard',
          'quarantined_at', v_now,
          'external_action_revision',
            NEW.external_user_action_revision
        ),
        'plan_cancellation_pending',
        COALESCE(
          v_item->'plan_cancellation_pending',
          jsonb_build_object(
            'reason', 'Backlog item entered needs_review',
            'requested_at', v_now
          )
        )
      );
      v_changed := true;
    END IF;
    v_items := v_items || jsonb_build_array(v_item);
  END LOOP;

  IF v_changed THEN
    NEW.backlog := jsonb_set(NEW.backlog, '{items}', v_items, false);
    NEW.backlog_revision := GREATEST(
      COALESCE(NEW.backlog_revision, 0),
      COALESCE(OLD.backlog_revision, 0) + 1
    );
    NEW.updated_at := v_now;
  END IF;
  RETURN NEW;
END;
$$;

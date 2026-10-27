SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: apply_stripe_sale_financial_effects(uuid, text, numeric, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_stripe_sale_financial_effects(p_sale_id uuid, p_session_id text, p_settlement_amount numeric, p_settlement_currency text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_effect public.stripe_sale_checkout_effects%ROWTYPE;
  v_sale public.sales%ROWTYPE;
  v_billing_id uuid;
  v_plan text;
  v_site_user_id uuid;
  v_commission_rate numeric;
  v_commission_amount numeric;
  v_balance_credit numeric;
  v_suffix text;
  v_sale_transaction_id text;
  v_commission_transaction_id text;
BEGIN
  -- account_balance is denominated in USD, regardless of checkout currency.
  IF upper(trim(coalesce(p_settlement_currency, ''))) <> 'USD' THEN
    RAISE EXCEPTION 'Stripe wallet settlement must be USD';
  END IF;
  IF p_settlement_amount IS NULL OR p_settlement_amount <= 0
    OR p_settlement_amount::text IN ('NaN', 'Infinity', '-Infinity')
    OR p_settlement_amount <> round(p_settlement_amount, 2) THEN
    RAISE EXCEPTION 'Invalid Stripe USD settlement amount';
  END IF;

  SELECT * INTO v_effect
  FROM public.stripe_sale_checkout_effects
  WHERE stripe_session_id = p_session_id
  FOR UPDATE;

  IF NOT FOUND OR v_effect.settlement_status <> 'settled'
    OR v_effect.sale_id IS DISTINCT FROM p_sale_id THEN
    RAISE EXCEPTION 'Stripe settlement effect is not eligible';
  END IF;
  IF v_effect.financial_status = 'completed' THEN
    RETURN jsonb_build_object('status', 'already_completed');
  END IF;

  SELECT * INTO v_sale
  FROM public.sales
  WHERE id = p_sale_id
  FOR UPDATE;

  IF NOT FOUND
    OR v_sale.stripe_checkout_session_id IS DISTINCT FROM p_session_id
    OR coalesce(v_sale.amount_due, 0) <> 0
    OR v_sale.status IN ('cancelled', 'refunded') THEN
    RAISE EXCEPTION 'Stripe sale is not eligible for financial effects';
  END IF;

  v_suffix := coalesce(v_effect.order_id::text, p_session_id);
  v_sale_transaction_id := 'sale_' || p_sale_id::text || '_' || v_suffix;
  v_commission_transaction_id :=
    'commission_' || p_sale_id::text || '_' || v_suffix;

  IF EXISTS (
    SELECT 1 FROM public.payments
    WHERE transaction_id = v_sale_transaction_id
  ) THEN
    IF EXISTS (
      SELECT 1 FROM public.payments
      WHERE transaction_id = v_sale_transaction_id
        AND (upper(currency) IS DISTINCT FROM 'USD' OR amount <> p_settlement_amount)
    ) THEN
      RAISE EXCEPTION 'Existing Stripe revenue requires currency reconciliation';
    END IF;
    UPDATE public.stripe_sale_checkout_effects
    SET financial_status = 'completed',
        financial_completed_at = now(),
        updated_at = now()
    WHERE stripe_session_id = p_session_id;
    RETURN jsonb_build_object('status', 'recovered_existing');
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('stripe-billing:' || v_sale.site_id::text, 0)
  );
  SELECT id, plan
  INTO v_billing_id, v_plan
  FROM public.billing
  WHERE site_id = v_sale.site_id
  ORDER BY created_at
  LIMIT 1
  FOR UPDATE;

  v_commission_rate := CASE
    WHEN v_plan = 'enterprise' THEN 0.045
    WHEN v_plan = 'foundry' THEN 0.055
    WHEN v_plan = 'engine' THEN 0.06
    WHEN v_plan = 'commission' THEN 0.07
    ELSE 0.07
  END;
  v_commission_amount :=
    round(p_settlement_amount * v_commission_rate, 2);
  v_balance_credit :=
    round(p_settlement_amount - v_commission_amount, 2);

  IF v_balance_credit <= 0 THEN
    RAISE EXCEPTION 'Stripe settlement balance credit is not positive';
  END IF;

  IF v_billing_id IS NULL THEN
    INSERT INTO public.billing AS current_billing (site_id, plan, account_balance)
    VALUES (v_sale.site_id, 'commission', v_balance_credit)
    ON CONFLICT (site_id) DO UPDATE
    SET account_balance =
          coalesce(current_billing.account_balance, 0)
          + excluded.account_balance,
        updated_at = now();
  ELSE
    UPDATE public.billing
    SET account_balance = coalesce(account_balance, 0) + v_balance_credit,
        updated_at = now()
    WHERE id = v_billing_id;
  END IF;

  INSERT INTO public.payments (
    site_id, transaction_id, transaction_type, amount, currency,
    status, payment_method, details
  )
  VALUES
  (
    v_sale.site_id,
    v_sale_transaction_id,
    'sale',
    p_settlement_amount,
    'USD',
    'completed',
    'stripe',
    jsonb_build_object(
      'stripe_payment_intent_id', v_effect.payment_intent_id,
      'stripe_session_id', p_session_id,
      'order_id', v_effect.order_id,
      'sale_id', p_sale_id,
      'gross_amount', p_settlement_amount,
      'original_currency', v_effect.currency,
      'original_amount', v_effect.amount_minor,
      'commission_basis', 'processing_included',
      'commission_rate', v_commission_rate
    )
  ),
  (
    v_sale.site_id,
    v_commission_transaction_id,
    'commission',
    v_commission_amount,
    'USD',
    'completed',
    'system',
    jsonb_build_object(
      'order_id', v_effect.order_id,
      'sale_id', p_sale_id,
      'commission_basis', 'processing_included',
      'commission_rate', v_commission_rate,
      'related_transaction_id', v_sale_transaction_id
    )
  );

  SELECT user_id INTO v_site_user_id
  FROM public.sites
  WHERE id = v_sale.site_id;

  IF v_site_user_id IS NOT NULL THEN
    INSERT INTO public.transactions (
      site_id, user_id, type, amount, description, category,
      date, currency, accounting_state
    )
    VALUES (
      v_sale.site_id,
      v_site_user_id,
      'variable',
      v_commission_amount,
      CASE
        WHEN v_effect.order_id IS NULL
          THEN 'Platform commission for sale ' || p_sale_id::text
        ELSE 'Platform commission for order ' || v_effect.order_id::text
      END,
      'operating',
      current_date,
      'USD',
      'pending'
    );
  END IF;

  UPDATE public.stripe_sale_checkout_effects
  SET financial_status = 'completed',
      financial_completed_at = now(),
      updated_at = now()
  WHERE stripe_session_id = p_session_id;

  RETURN jsonb_build_object(
    'status', 'completed',
    'balance_credit', v_balance_credit,
    'commission_amount', v_commission_amount
  );
END;
$$;


--
-- Name: apply_stripe_sale_inventory_effect(uuid, uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_stripe_sale_inventory_effect(p_sale_id uuid, p_order_id uuid, p_session_id text, p_claim_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_effect public.stripe_sale_checkout_effects%ROWTYPE;
  v_sale public.sales%ROWTYPE;
  v_order public.sale_orders%ROWTYPE;
  v_commerce jsonb;
  v_policy text;
  v_item record;
BEGIN
  SELECT * INTO v_effect
  FROM public.stripe_sale_checkout_effects
  WHERE stripe_session_id = p_session_id
  FOR UPDATE;
  IF NOT FOUND
    OR v_effect.sale_id IS DISTINCT FROM p_sale_id
    OR v_effect.order_id IS DISTINCT FROM p_order_id
    OR v_effect.fulfillment_status <> 'processing'
    OR v_effect.fulfillment_claim_token IS DISTINCT FROM p_claim_token THEN
    RAISE EXCEPTION 'Stripe inventory effect is not owned by this claim';
  END IF;

  SELECT * INTO v_order
  FROM public.sale_orders
  WHERE id = p_order_id
    AND sale_id = p_sale_id
  FOR UPDATE;
  SELECT * INTO v_sale
  FROM public.sales
  WHERE id = p_sale_id
    AND stripe_checkout_session_id = p_session_id
  FOR UPDATE;
  IF v_sale.id IS NULL OR v_order.id IS NULL THEN
    RAISE EXCEPTION 'Stripe inventory sale or order was not found';
  END IF;

  IF public.is_self_service_order_items(v_order.items) THEN
    -- The same durable per-line effect owns cash, free and Stripe releases.
    -- Even a completed Stripe inventory retry must validate current payment.
    PERFORM public.release_self_service_order(v_order.site_id,p_order_id);
    UPDATE public.stripe_sale_checkout_effects
      SET inventory_completed_at=coalesce(inventory_completed_at,now()),updated_at=now()
      WHERE stripe_session_id=p_session_id;
    RETURN jsonb_build_object('status',CASE WHEN v_effect.inventory_completed_at IS NULL
      THEN 'completed' ELSE 'already_completed' END);
  END IF;
  IF v_effect.inventory_completed_at IS NOT NULL THEN
    RETURN jsonb_build_object('status','already_completed');
  END IF;

  SELECT commerce INTO v_commerce
  FROM public.settings
  WHERE site_id = v_sale.site_id
  LIMIT 1;
  v_policy := coalesce(v_commerce->>'decrement_stock_on', 'ship');

  IF v_policy <> 'never' AND v_order.origin_location_id IS NOT NULL THEN
    FOR v_item IN
      SELECT soi.catalog_item_id, soi.quantity
      FROM public.sale_order_items soi
      JOIN public.catalog_items ci ON ci.id = soi.catalog_item_id
      WHERE soi.sale_order_id = p_order_id
        AND soi.catalog_item_id IS NOT NULL
        AND ci.track_inventory = true
    LOOP
      INSERT INTO public.inventory_levels AS current_level (
        site_id, catalog_item_id, location_id, quantity, updated_at
      )
      VALUES (
        v_sale.site_id,
        v_item.catalog_item_id,
        v_order.origin_location_id,
        0,
        now()
      )
      ON CONFLICT (catalog_item_id, location_id)
      DO UPDATE SET
        quantity = greatest(
          0,
          current_level.quantity - v_item.quantity
        ),
        updated_at = now();
    END LOOP;
  END IF;

  UPDATE public.stripe_sale_checkout_effects
  SET inventory_completed_at = now(),
      updated_at = now()
  WHERE stripe_session_id = p_session_id;
  RETURN jsonb_build_object('status', 'completed');
END;
$$;


--
-- Name: apps_apply_migration(text, uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_apply_migration(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_migration_sql text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  existing_value jsonb;
  existing_checksum_key text;
BEGIN
  IF p_target_schema !~ '^app_[a-f0-9]{24}$' THEN
    RAISE EXCEPTION 'Invalid tenant schema';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.apps_tenants
    WHERE tenant_id = p_expected_tenant_id
      AND schema = p_target_schema
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Tenant and schema do not match an active tenant';
  END IF;

  IF p_migration_key !~ '^migration:[A-Za-z0-9_./-]+\.sql$'
    OR p_migration_sql IS NULL
    OR length(trim(p_migration_sql)) = 0
    OR p_migration_checksum !~ '^[a-f0-9]{64}$'
  THEN
    RAISE EXCEPTION 'Invalid migration payload';
  END IF;

  -- Serialize the whole tenant migration stream. Locking only by filename
  -- would allow the same SQL to run concurrently under two renamed files.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_target_schema, 0));

  EXECUTE format(
    'SELECT value FROM %I._meta WHERE key = $1 FOR UPDATE',
    p_target_schema
  )
  INTO existing_value
  USING p_migration_key;

  IF existing_value IS NOT NULL THEN
    IF (existing_value ? 'checksum')
      AND existing_value->>'checksum' <> p_migration_checksum
    THEN
      RAISE EXCEPTION
        'Migration % changed after application',
        p_migration_key;
    END IF;

    IF NOT (existing_value ? 'checksum') THEN
      EXECUTE format(
        'UPDATE %I._meta
         SET value = value || jsonb_build_object(
           ''checksum'', $1,
           ''checksum_backfilled_at'', now()::text
         ),
         updated_at = now()
         WHERE key = $2',
        p_target_schema
      )
      USING p_migration_checksum, p_migration_key;
    END IF;
    RETURN false;
  END IF;

  EXECUTE format(
    'SELECT key
       FROM %I._meta
      WHERE key LIKE ''migration:%%''
        AND value->>''checksum'' = $1
      LIMIT 1',
    p_target_schema
  )
  INTO existing_checksum_key
  USING p_migration_checksum;

  -- A rename must not turn already-applied SQL into a pending migration.
  IF existing_checksum_key IS NOT NULL THEN
    RETURN false;
  END IF;

  -- The outer SECURITY DEFINER function only coordinates trusted metadata.
  -- User SQL runs inside the tenant-local executor owned by that tenant's
  -- constrained role, never as this function's privileged owner.
  EXECUTE format(
    'SELECT %I._execute_tenant_migration($1)',
    p_target_schema
  )
  USING p_migration_sql;

  EXECUTE format(
    'INSERT INTO %I._meta (key, value)
     VALUES ($1, jsonb_build_object(
       ''applied_at'', now()::text,
       ''checksum'', $2
     ))',
    p_target_schema
  )
  USING p_migration_key, p_migration_checksum;

  RETURN true;
END;
$_$;

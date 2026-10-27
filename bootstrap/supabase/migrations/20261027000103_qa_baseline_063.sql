SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: settle_stripe_sale_checkout(uuid, uuid, text, bigint, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.settle_stripe_sale_checkout(p_sale_id uuid, p_order_id uuid, p_session_id text, p_amount_minor bigint, p_currency text, p_payment_intent_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_sale public.sales%ROWTYPE;
  v_order public.sale_orders%ROWTYPE;
  v_effect public.stripe_sale_checkout_effects%ROWTYPE;
  v_currency text;
  v_expected_minor bigint;
  v_paid_amount numeric;
  v_payment jsonb;
  v_payments jsonb;
  v_payment_details jsonb;
  v_order_status text;
BEGIN
  IF nullif(trim(p_session_id), '') IS NULL
    OR p_amount_minor IS NULL
    OR p_amount_minor <= 0 THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'invalid_session_payment'
    );
  END IF;

  SELECT *
  INTO v_effect
  FROM public.stripe_sale_checkout_effects
  WHERE stripe_session_id = p_session_id
  FOR UPDATE;

  IF FOUND AND v_effect.settlement_status = 'rejected' THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', coalesce(v_effect.rejection_reason, 'previously_rejected')
    );
  END IF;
  IF v_effect.stripe_session_id IS NOT NULL
    AND (
      v_effect.sale_reference <> p_sale_id::text
      OR v_effect.order_id IS DISTINCT FROM p_order_id
      OR v_effect.payment_intent_id IS DISTINCT FROM p_payment_intent_id
      OR v_effect.amount_minor <> p_amount_minor
      OR v_effect.currency <> lower(trim(coalesce(p_currency, '')))
    ) THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'settlement_identity_mismatch'
    );
  END IF;

  -- Match admitted POS checkout/release lock order before locking its sale.
  -- The existing validation below still owns all settlement authorization.
  IF p_order_id IS NOT NULL THEN
    PERFORM id FROM public.sale_orders
      WHERE id=p_order_id AND sale_id=p_sale_id FOR UPDATE;
  END IF;

  SELECT *
  INTO v_sale
  FROM public.sales
  WHERE id = p_sale_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'rejected', 'reason', 'sale_not_found');
  END IF;
  IF v_sale.stripe_checkout_session_id IS DISTINCT FROM p_session_id THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'checkout_session_replaced'
    );
  END IF;

  v_currency := lower(trim(coalesce(v_sale.currency, 'USD')));
  IF v_currency <> lower(trim(coalesce(p_currency, ''))) THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'currency_mismatch'
    );
  END IF;

  IF v_sale.amount_due IS NULL OR v_sale.amount_due <= 0 THEN
    IF v_sale.stripe_payment_intent_id IS NOT NULL
      AND v_sale.stripe_payment_intent_id IS DISTINCT FROM p_payment_intent_id THEN
      RETURN jsonb_build_object(
        'status', 'rejected',
        'reason', 'payment_intent_mismatch'
      );
    END IF;

    IF p_order_id IS NOT NULL THEN
      SELECT *
      INTO v_order
      FROM public.sale_orders
      WHERE id = p_order_id
        AND sale_id = v_sale.id;
      IF NOT FOUND THEN
        RETURN jsonb_build_object(
          'status', 'rejected',
          'reason', 'sale_order_not_found'
        );
      END IF;
    END IF;

    INSERT INTO public.stripe_sale_checkout_effects (
      stripe_session_id,
      sale_reference,
      sale_id,
      order_id,
      payment_intent_id,
      amount_minor,
      currency,
      settlement_status,
      financial_status,
      fulfillment_status,
      compensation_status
    )
    VALUES (
      p_session_id,
      p_sale_id::text,
      v_sale.id,
      p_order_id,
      coalesce(p_payment_intent_id, v_sale.stripe_payment_intent_id),
      p_amount_minor,
      v_currency,
      'settled',
      'pending',
      CASE WHEN p_order_id IS NULL THEN 'not_required' ELSE 'pending' END,
      'not_required'
    )
    ON CONFLICT (stripe_session_id) DO NOTHING;

    RETURN jsonb_build_object(
      'status', 'already_settled',
      'resume_effects', v_sale.status NOT IN ('cancelled', 'refunded'),
      'sale_id', v_sale.id,
      'site_id', v_sale.site_id,
      'lead_id', v_sale.lead_id,
      'order_id', p_order_id,
      'order_user_id',
        CASE WHEN p_order_id IS NULL THEN NULL ELSE v_order.user_id END,
      'order_buyer_user_id',
        CASE WHEN p_order_id IS NULL THEN NULL ELSE v_order.buyer_user_id END
    );
  END IF;

  IF v_sale.status IN ('cancelled', 'refunded')
    OR v_sale.status NOT IN ('pending', 'completed') THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'sale_not_payable'
    );
  END IF;

  v_expected_minor :=
    public.stripe_amount_to_minor(v_sale.amount_due, v_currency);
  IF v_expected_minor IS NULL OR v_expected_minor <> p_amount_minor THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'amount_mismatch'
    );
  END IF;

  IF p_order_id IS NULL AND EXISTS (
    SELECT 1 FROM public.sale_orders WHERE sale_id = v_sale.id
  ) THEN
    RETURN jsonb_build_object(
      'status', 'rejected',
      'reason', 'sale_order_required'
    );
  END IF;

  IF p_order_id IS NOT NULL THEN
    SELECT *
    INTO v_order
    FROM public.sale_orders
    WHERE id = p_order_id
      AND sale_id = v_sale.id
    FOR UPDATE;

    IF NOT FOUND THEN
      RETURN jsonb_build_object(
        'status', 'rejected',
        'reason', 'sale_order_not_found'
      );
    END IF;
    IF v_order.status IN ('cancelled', 'refunded')
      OR v_order.status NOT IN ('pending', 'completed') THEN
      RETURN jsonb_build_object(
        'status', 'rejected',
        'reason', 'sale_order_not_payable'
      );
    END IF;
  END IF;

  v_paid_amount := v_sale.amount_due;
  v_payment := jsonb_build_object(
    'method', 'stripe',
    'amount', v_paid_amount,
    'tendered', v_paid_amount,
    'change', 0,
    'date', now(),
    'status', 'completed',
    'stripe_session_id', p_session_id
  );
  IF p_payment_intent_id IS NOT NULL THEN
    v_payment := v_payment || jsonb_build_object(
      'stripe_payment_intent_id', p_payment_intent_id
    );
  END IF;
  v_payments := CASE
    WHEN jsonb_typeof(v_sale.payments) = 'array' THEN v_sale.payments
    ELSE '[]'::jsonb
  END;
  v_payment_details := CASE
    WHEN jsonb_typeof(v_sale.payment_details) = 'object'
      THEN v_sale.payment_details
    ELSE '{}'::jsonb
  END;
  v_payment_details := v_payment_details || jsonb_build_object(
    'processor', 'stripe',
    'stripe_checkout_session_id', p_session_id,
    'amount_total', p_amount_minor,
    'currency', v_currency,
    'stripe_payment_intent_id', p_payment_intent_id
  );

  UPDATE public.sales
  SET status = 'completed',
      amount_due = 0,
      payment_method = 'stripe',
      stripe_payment_intent_id = p_payment_intent_id,
      payment_details = v_payment_details,
      payments = v_payments || jsonb_build_array(v_payment),
      updated_at = now()
  WHERE id = v_sale.id;

  IF p_order_id IS NOT NULL THEN
    v_order_status := CASE
      WHEN v_order.status = 'completed'
        OR v_order.fulfillment_method = 'none' THEN 'completed'
      ELSE 'in_progress'
    END;
    UPDATE public.sale_orders
    SET status = v_order_status,
        updated_at = now()
    WHERE id = v_order.id;
  END IF;

  INSERT INTO public.stripe_sale_checkout_effects (
    stripe_session_id,
    sale_reference,
    sale_id,
    order_id,
    payment_intent_id,
    amount_minor,
    currency,
    settlement_status,
    fulfillment_status
  )
  VALUES (
    p_session_id,
    p_sale_id::text,
    v_sale.id,
    p_order_id,
    p_payment_intent_id,
    p_amount_minor,
    v_currency,
    'settled',
    CASE WHEN p_order_id IS NULL THEN 'not_required' ELSE 'pending' END
  )
  ON CONFLICT (stripe_session_id) DO NOTHING;

  RETURN jsonb_build_object(
    'status', 'settled',
    'resume_effects', true,
    'sale_id', v_sale.id,
    'site_id', v_sale.site_id,
    'lead_id', v_sale.lead_id,
    'order_id', p_order_id,
    'order_user_id',
      CASE WHEN p_order_id IS NULL THEN NULL ELSE v_order.user_id END,
    'order_buyer_user_id',
      CASE WHEN p_order_id IS NULL THEN NULL ELSE v_order.buyer_user_id END
  );
END;
$$;

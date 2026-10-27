SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: refresh_catalog_search_document(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_catalog_search_document(p_item_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
  v_item public.catalog_items%ROWTYPE;
  v_doc text; v_name text; v_sku text; v_hash text; v_revision bigint;
BEGIN
  -- Backfill must not wait on a source row after already locking another item.
  SELECT * INTO v_item FROM public.catalog_items WHERE id = p_item_id FOR NO KEY UPDATE SKIP LOCKED;
  IF NOT FOUND THEN
    IF EXISTS (SELECT 1 FROM public.catalog_items WHERE id = p_item_id) THEN
      INSERT INTO public.catalog_search_refresh_events(catalog_item_id) VALUES (p_item_id);
    END IF;
    RETURN false;
  END IF;
  v_doc := public.catalog_search_document_text(p_item_id);
  -- Full lexical fields: hash indexes are byte-bounded even for multibyte names.
  v_name := btrim(regexp_replace(v_item.name, '[[:space:]]+', ' ', 'g'));
  v_sku := btrim(regexp_replace(coalesce(v_item.sku, ''), '[[:space:]]+', ' ', 'g'));
  -- Structured retrieval identity prevents ambiguous labeled semantic documents
  -- from hiding a lexical edit. Lexical-only edits may harmlessly re-embed.
  v_hash := encode(sha256(convert_to(jsonb_build_array('source-v2-byte7000', v_name, v_sku, v_doc)::text, 'UTF8')), 'hex');
  INSERT INTO public.catalog_search_documents AS d
    (catalog_item_id, site_id, document_text, name_text, sku_text, source_hash, source_revision)
  VALUES (v_item.id, v_item.site_id, v_doc, v_name, v_sku, v_hash, 1)
  ON CONFLICT (catalog_item_id) DO UPDATE SET
    site_id = EXCLUDED.site_id, document_text = EXCLUDED.document_text,
    name_text = EXCLUDED.name_text, sku_text = EXCLUDED.sku_text,
    source_hash = EXCLUDED.source_hash, source_revision = d.source_revision + 1,
    embedding = NULL, embedding_model = NULL, embedding_source_hash = NULL, indexed_at = NULL
  WHERE d.source_hash IS DISTINCT FROM EXCLUDED.source_hash OR d.site_id IS DISTINCT FROM EXCLUDED.site_id
  RETURNING source_revision INTO v_revision;
  IF NOT FOUND THEN RETURN false; END IF;
  INSERT INTO public.catalog_embedding_jobs AS j(catalog_item_id, site_id, source_hash, source_revision)
    VALUES (v_item.id, v_item.site_id, v_hash, v_revision)
  ON CONFLICT (catalog_item_id) DO UPDATE SET site_id = EXCLUDED.site_id,
    source_hash = EXCLUDED.source_hash, source_revision = EXCLUDED.source_revision,
    status = 'pending', claim_token = NULL, lease_expires_at = NULL,
    attempts = 0, next_attempt_at = now(), last_error = NULL, updated_at = now();
  PERFORM public.catalog_search_bump_revision(v_item.site_id);
  RETURN true;
END $$;


--
-- Name: refresh_conversation_message_summary(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_conversation_message_summary() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  target_conversation_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_conversation_id := OLD.conversation_id;
  ELSE
    target_conversation_id := NEW.conversation_id;
  END IF;

  IF TG_OP = 'UPDATE'
    AND OLD.conversation_id IS DISTINCT FROM NEW.conversation_id
  THEN
    PERFORM pg_advisory_xact_lock(
      hashtextextended(
        LEAST(OLD.conversation_id::text, NEW.conversation_id::text),
        0
      )
    );
    PERFORM pg_advisory_xact_lock(
      hashtextextended(
        GREATEST(OLD.conversation_id::text, NEW.conversation_id::text),
        0
      )
    );
  ELSE
    PERFORM pg_advisory_xact_lock(
      hashtextextended(target_conversation_id::text, 0)
    );
  END IF;

  UPDATE public.conversations AS conversation
  SET
    message_count = summary.total,
    last_message_preview = summary.latest,
    last_message_at = (summary.latest->>'created_at')::timestamptz
  FROM (
    SELECT
      COUNT(*)::bigint AS total,
      (
        SELECT jsonb_build_object(
          'id', latest.id,
          'content', latest.content,
          'role', latest.role,
          'created_at', latest.created_at
        )
        FROM public.messages AS latest
        WHERE latest.conversation_id = target_conversation_id
        ORDER BY latest.created_at DESC, latest.id DESC
        LIMIT 1
      ) AS latest
    FROM public.messages
    WHERE conversation_id = target_conversation_id
  ) AS summary
  WHERE conversation.id = target_conversation_id;

  IF TG_OP = 'UPDATE' AND OLD.conversation_id IS DISTINCT FROM NEW.conversation_id THEN
    UPDATE public.conversations AS conversation
    SET
      message_count = summary.total,
      last_message_preview = summary.latest,
      last_message_at = (summary.latest->>'created_at')::timestamptz
    FROM (
      SELECT
        COUNT(*)::bigint AS total,
        (
          SELECT jsonb_build_object(
            'id', latest.id,
            'content', latest.content,
            'role', latest.role,
            'created_at', latest.created_at
          )
          FROM public.messages AS latest
          WHERE latest.conversation_id = OLD.conversation_id
          ORDER BY latest.created_at DESC, latest.id DESC
          LIMIT 1
        ) AS latest
      FROM public.messages
      WHERE conversation_id = OLD.conversation_id
    ) AS summary
    WHERE conversation.id = OLD.conversation_id;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: register_referral_code_use(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.register_referral_code_use(code_param text, user_id_param uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16752($1,$2); END$_$;


--
-- Name: register_sandbox_billing(text, text, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.register_sandbox_billing(p_sandbox_name text, p_owner_kind text, p_owner_id uuid, p_site_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE v_site uuid; v_requirement uuid; v_available numeric; r public.sandbox_billing_resources%ROWTYPE;
BEGIN
  IF p_sandbox_name IS NULL OR length(p_sandbox_name) NOT BETWEEN 1 AND 200 OR p_owner_id IS NULL THEN
    RAISE EXCEPTION 'Invalid sandbox billing owner';
  END IF;
  -- Never trust provider tags, model-selected site IDs, or audit log metadata.
  IF p_owner_kind = 'harness' THEN
    SELECT site_id, (snapshot#>>'{request,requirementId}')::uuid INTO v_site,v_requirement
      FROM public.harness_sessions WHERE id = p_owner_id FOR SHARE;
    -- Repeated occurrences of one requirement share the same durable owner.
    IF v_requirement IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM public.requirements WHERE id=v_requirement AND site_id=v_site) THEN
        RAISE EXCEPTION 'Sandbox billing requirement ownership mismatch';
      END IF;
      p_owner_kind := 'requirement'; p_owner_id := v_requirement;
    END IF;
  ELSIF p_owner_kind = 'requirement' THEN
    SELECT site_id INTO v_site FROM public.requirements WHERE id = p_owner_id FOR SHARE;
  ELSIF p_owner_kind = 'workflow' THEN
    SELECT site_id INTO v_site FROM public.instance_plans WHERE id = p_owner_id FOR SHARE;
  ELSE RAISE EXCEPTION 'Invalid sandbox billing owner'; END IF;
  IF v_site IS NULL OR (p_site_id IS NOT NULL AND p_site_id <> v_site) THEN
    RAISE EXCEPTION 'Sandbox billing site ownership mismatch';
  END IF;
  INSERT INTO public.sandbox_billing_resources(sandbox_name,site_id,owner_kind,owner_id)
    VALUES(p_sandbox_name,v_site,p_owner_kind,p_owner_id) ON CONFLICT DO NOTHING;
  SELECT * INTO r FROM public.sandbox_billing_resources WHERE sandbox_name = p_sandbox_name FOR UPDATE;
  -- A requirement may adopt an earlier harness occurrence on its own site.
  -- Identity is site-immutable; repeated registration never moves the floor.
  IF r.site_id <> v_site THEN RAISE EXCEPTION 'Sandbox billing identity conflict'; END IF;
  IF r.owner_kind <> p_owner_kind OR r.owner_id <> p_owner_id THEN
    RAISE EXCEPTION 'Sandbox billing owner identity conflict';
  END IF;
  IF r.deletion_requested_at IS NOT NULL AND r.retired_at IS NULL THEN
    RAISE EXCEPTION 'Sandbox deletion is pending';
  END IF;
  PERFORM public.renew_site_plan_credits(v_site);
  SELECT credits_available INTO v_available FROM public.billing WHERE site_id=v_site FOR UPDATE;
  IF v_available IS NULL OR v_available <= 0 THEN
    RETURN jsonb_build_object('success',false,'error','Sandbox requires available credits');
  END IF;
  UPDATE public.sandbox_billing_resources SET deletion_requested_at=NULL,retired_at=NULL WHERE sandbox_name=p_sandbox_name;
  RETURN jsonb_build_object('success',true,'site_id',r.site_id,'registered_at',r.registered_at);
END;
$$;


--
-- Name: reject_migration_execution_handoff_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reject_migration_execution_handoff_mutation() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  RAISE EXCEPTION 'Migration execution handoffs are append-only' USING ERRCODE = '23514';
END;
$$;


--
-- Name: reject_migration_reconciliation_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reject_migration_reconciliation_mutation() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  RAISE EXCEPTION 'Migration reconciliation receipts are append-only' USING ERRCODE = '23514';
END;
$$;


--
-- Name: reject_migration_retirement_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reject_migration_retirement_mutation() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  RAISE EXCEPTION 'Migration retirement receipts are append-only' USING ERRCODE = '23514';
END;
$$;


--
-- Name: release_deployment_recovery_scan_lease(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.release_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_released boolean := false;
BEGIN
  DELETE FROM public.deployment_recovery_scan_leases
  WHERE lease_key = p_lease_key
    AND owner_id = p_owner_id
  RETURNING true INTO v_released;
  RETURN COALESCE(v_released, false);
END;
$$;


--
-- Name: release_harness_session(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.release_harness_session(p_id uuid, p_site_id uuid, p_owner text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  -- Release works after a terminal save, without replacing status or snapshot.
  UPDATE public.harness_sessions SET lease_owner=NULL, lease_expires_at=NULL
    WHERE id=p_id AND site_id=p_site_id AND lease_owner=p_owner;
  RETURN FOUND;
END;
$$;


--
-- Name: release_image_generation_reservation(uuid, text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.release_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_reason text) RETURNS jsonb
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
  SELECT public.finish_image_generation_reservation($1,$2,$3,NULL,$4,NULL,NULL);
$_$;


--
-- Name: release_quotation_checkout_claim(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.release_quotation_checkout_claim(p_quotation_id uuid, p_claim_id uuid) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  WITH released AS (
    UPDATE public.quotations
    SET
      checkout_claim_id = NULL,
      checkout_claimed_at = NULL
    WHERE id = p_quotation_id
      AND status = 'sent'
      AND checkout_claim_id = p_claim_id
    RETURNING 1
  )
  SELECT EXISTS (SELECT 1 FROM released);
$$;


--
-- Name: release_self_service_order(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.release_self_service_order(p_site_id uuid, p_order_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE o public.sale_orders%ROWTYPE; paid boolean; result jsonb;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Server self-service release required' USING ERRCODE='42501';
  END IF;
  SELECT * INTO o FROM public.sale_orders WHERE id=p_order_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR NOT public.is_self_service_order_items(o.items) OR o.status='cancelled' THEN
    RAISE EXCEPTION 'Active self-service order required' USING ERRCODE='42501';
  END IF;
  SELECT status='completed' AND amount_due >= 0 AND amount_due <= 0.009
    INTO paid FROM public.sales WHERE id=o.sale_id AND site_id=p_site_id FOR UPDATE;
  IF paid IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Self-service release requires full payment' USING ERRCODE='42501';
  END IF;
  PERFORM id FROM public.sale_order_items WHERE sale_order_id=o.id ORDER BY catalog_item_id,id FOR UPDATE;
  -- Consistent SKU locks serialize different orders even when their line IDs and
  -- modifiers appear in opposite order. Inventory updates still use row upserts.
  PERFORM id FROM public.catalog_items WHERE site_id=o.site_id AND id IN (
    SELECT catalog_item_id FROM public.sale_order_items WHERE sale_order_id=o.id
  ) ORDER BY id FOR UPDATE;
  -- One statement and transaction release parents and modifiers with stock effects.
  UPDATE public.sale_order_items SET status='new',sent_at=coalesce(sent_at,now())
    WHERE sale_order_id=o.id AND status='draft';
  SELECT coalesce(jsonb_agg(to_jsonb(i) ORDER BY i.id),'[]') INTO result
    FROM public.sale_order_items i WHERE sale_order_id=o.id;
  RETURN jsonb_build_object('status','completed','items',result);
END;
$$;


--
-- Name: remove_all_delete_protection_triggers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_all_delete_protection_triggers() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16753(); RETURN; END$$;


--
-- Name: remove_delete_protection_trigger(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_delete_protection_trigger(p_table_name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16754($1); RETURN; END$_$;


--
-- Name: renew_harness_session(uuid, uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.renew_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_sessions%ROWTYPE; t timestamptz;
BEGIN
  IF p_owner IS NULL OR length(btrim(p_owner)) = 0 OR length(p_owner) > 200 OR p_ttl_seconds IS NULL OR p_ttl_seconds NOT BETWEEN 1 AND 300
  THEN RAISE EXCEPTION 'Invalid harness lease' USING ERRCODE='22023'; END IF;
  SELECT * INTO r FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN false; END IF;
  t := clock_timestamp();
  IF r.lease_owner IS DISTINCT FROM p_owner OR r.lease_expires_at IS NULL OR r.lease_expires_at <= t OR r.snapshot->>'status' <> 'running' THEN RETURN false; END IF;
  UPDATE public.harness_sessions SET lease_expires_at=t+make_interval(secs=>p_ttl_seconds) WHERE id=p_id AND site_id=p_site_id;
  RETURN true;
END;
$$;


--
-- Name: renew_site_plan_credits(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.renew_site_plan_credits(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; v_month timestamptz; v_start timestamptz; w record;
  v_expired numeric;
BEGIN
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'error','Billing record not found'); END IF;
  IF b.trial_ends_at <= clock_timestamp() AND b.trial_credits_available > 0 THEN
    UPDATE public.billing SET trial_credits_available=trial_credits_available
      WHERE id=b.id RETURNING * INTO b;
  END IF;
  IF EXISTS (SELECT 1 FROM public.sites WHERE id = p_site_id AND archived_at IS NOT NULL)
    OR (coalesce(b.status,'') <> 'active' AND lower(coalesce(b.subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired')) THEN
    IF b.plan_credits_available > 0 THEN
      v_expired := b.plan_credits_available;
      UPDATE public.billing SET plan_credits_available = 0,
        credits_available = purchased_credits_available + legacy_credits_available WHERE id = b.id RETURNING * INTO b;
      INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
        VALUES (p_site_id,-v_expired,'plan_credit_expiry','Inactive included plan allowance',
          jsonb_build_object('credit_bucket','plan','reason','inactive'));
    END IF;
    RETURN jsonb_build_object('success',true,'outcome','inactive','credits_granted',0,'credits_available',b.credits_available);
  END IF;
  IF b.stripe_subscription_id IS NOT NULL AND lower(coalesce(b.subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired') THEN
    IF b.billing_interval = 'year' AND b.subscription_status = 'active'
      AND b.paid_subscription_period_start <= now() AND b.paid_subscription_period_end > now() THEN
      IF b.plan_credit_period_end > now() THEN
        RETURN jsonb_build_object('success',true,'outcome','not_due','credits_granted',0,'credits_available',b.credits_available);
      END IF;
      SELECT * INTO w FROM public.subscription_monthly_credit_window(
        coalesce(b.plan_credit_anchor,b.paid_subscription_period_start),b.paid_subscription_period_end,now());
      RETURN public.reset_site_plan_credit_period(p_site_id,w.period_start,w.period_end,
        public.site_plan_credit_allowance(b.paid_subscription_plan,b.paid_subscription_addons_count),
        'stripe_invoice:' || b.paid_subscription_invoice_id);
    END IF;
    IF (b.plan_credit_period_end <= now() OR b.paid_subscription_period_end <= now()) AND b.plan_credits_available > 0 THEN
      INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
        VALUES (p_site_id,-b.plan_credits_available,'plan_credit_expiry','Expired Stripe plan allowance',
          jsonb_build_object('credit_bucket','plan','period_end',b.plan_credit_period_end));
      UPDATE public.billing SET plan_credits_available = 0,
        credits_available = purchased_credits_available + legacy_credits_available WHERE id = b.id RETURNING * INTO b;
    END IF;
    IF b.paid_subscription_period_end <= now() THEN
      UPDATE public.billing SET plan='commission',addons_count=0 WHERE id=b.id RETURNING * INTO b;
    END IF;
    RETURN jsonb_build_object('success',true,'outcome','stripe_managed','credits_granted',0,'credits_available',b.credits_available);
  END IF;
  IF b.plan_credit_anchor IS NOT NULL AND b.plan_credit_period_end > now() THEN
    RETURN jsonb_build_object('success',true,'outcome','not_due','credits_granted',0,'credits_available',b.credits_available);
  END IF;
  v_month := date_trunc('month', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
  v_start := CASE WHEN b.plan_credit_anchor IS NOT NULL AND b.plan_credit_period_end IS NOT NULL
    THEN greatest(v_month,b.plan_credit_period_end) ELSE v_month END;
  RETURN public.reset_site_plan_credit_period(p_site_id,v_start,(v_month AT TIME ZONE 'UTC' + interval '1 month') AT TIME ZONE 'UTC',
    public.site_plan_credit_allowance(b.plan,b.addons_count),'workflow');
END;
$$;

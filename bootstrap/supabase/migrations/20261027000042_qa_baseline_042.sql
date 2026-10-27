SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: link_stripe_checkout_session(uuid, bigint, text, bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.link_stripe_checkout_session(p_sale_id uuid, p_attempt bigint, p_session_id text, p_amount_minor bigint, p_currency text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_sale public.sales%ROWTYPE;
  v_currency text;
  v_expected_minor bigint;
BEGIN
  IF p_attempt IS NULL
    OR nullif(trim(p_session_id), '') IS NULL
    OR p_amount_minor IS NULL
    OR p_amount_minor < 0 THEN
    RETURN jsonb_build_object('status', 'rejected', 'reason', 'invalid_input');
  END IF;

  SELECT *
  INTO v_sale
  FROM public.sales
  WHERE id = p_sale_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'rejected', 'reason', 'sale_not_found');
  END IF;
  IF v_sale.stripe_checkout_attempt <> p_attempt THEN
    RETURN jsonb_build_object('status', 'rejected', 'reason', 'stale_attempt');
  END IF;
  IF v_sale.status NOT IN ('pending', 'completed')
    OR v_sale.amount_due IS NULL
    OR v_sale.amount_due <= 0 THEN
    RETURN jsonb_build_object('status', 'rejected', 'reason', 'not_payable');
  END IF;

  v_currency := lower(trim(coalesce(v_sale.currency, 'USD')));
  v_expected_minor :=
    public.stripe_amount_to_minor(v_sale.amount_due, v_currency);
  IF v_currency <> lower(trim(coalesce(p_currency, '')))
    OR v_expected_minor IS NULL
    OR v_expected_minor <> p_amount_minor THEN
    RETURN jsonb_build_object('status', 'rejected', 'reason', 'payment_changed');
  END IF;

  UPDATE public.sales
  SET stripe_checkout_session_id = p_session_id,
      updated_at = now()
  WHERE id = v_sale.id;

  RETURN jsonb_build_object('status', 'linked');
END;
$$;


--
-- Name: list_credit_auto_top_up_candidates(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_credit_auto_top_up_candidates(p_limit integer DEFAULT 20) RETURNS TABLE(site_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE v_now timestamptz := clock_timestamp(); v_month timestamptz; v_next_month timestamptz;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'Invalid automatic top-up candidate limit';
  END IF;
  v_month := date_trunc('month',v_now AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
  v_next_month := (v_month AT TIME ZONE 'UTC'+interval '1 month') AT TIME ZONE 'UTC';
  RETURN QUERY
  WITH eligible AS (
    SELECT s.site_id AS candidate_site_id,recent.created_at AS ordering_time
      FROM public.credit_auto_top_up_settings s
      JOIN public.billing b ON b.site_id=s.site_id
      JOIN public.sites t ON t.id=s.site_id
      CROSS JOIN LATERAL (
        SELECT b.credits_available-CASE WHEN b.plan_credit_period_end <= v_now
          OR (b.stripe_subscription_id IS NOT NULL AND b.paid_subscription_period_end <= v_now)
          THEN b.plan_credits_available ELSE 0 END AS balance
      ) effective
      LEFT JOIN LATERAL (
        SELECT a.created_at FROM public.credit_auto_top_up_attempts a
          WHERE a.site_id=s.site_id ORDER BY a.created_at DESC LIMIT 1
      ) recent ON true
      WHERE s.enabled AND s.state='ready' AND s.stripe_payment_method_id IS NOT NULL
        AND b.status='active' AND b.stripe_customer_id ~ '^cus_[A-Za-z0-9]+$'
        AND t.archived_at IS NULL AND effective.balance < s.minimum_credits
        AND ceil(s.target_credits-effective.balance) BETWEEN 1 AND 1000000
        AND NOT EXISTS (SELECT 1 FROM public.credit_auto_top_up_attempts pending
          WHERE pending.site_id=s.site_id AND pending.status='pending')
        AND (SELECT coalesce(sum(spent.amount_cents),0)
          FROM public.credit_auto_top_up_attempts spent WHERE spent.site_id=s.site_id AND
          (spent.status='pending' OR (spent.status='succeeded'
            AND greatest(spent.created_at,spent.finished_at) >= v_month
            AND greatest(spent.created_at,spent.finished_at) < v_next_month)))
          + ceil(s.target_credits-effective.balance)*100 <= s.max_monthly_spend_cents
      ORDER BY recent.created_at ASC NULLS FIRST,s.site_id LIMIT p_limit
  ), due AS (
    SELECT a.site_id AS candidate_site_id,a.claim_expires_at AS ordering_time
      FROM public.credit_auto_top_up_attempts a JOIN public.billing b ON b.site_id=a.site_id
      WHERE a.status='pending' AND a.claim_expires_at <= v_now
        AND (a.stripe_payment_intent_id IS NOT NULL OR a.dispatch_started_at IS NULL)
      ORDER BY a.claim_expires_at,a.created_at,a.site_id
      LIMIT CASE WHEN EXISTS (SELECT 1 FROM eligible)
        THEN greatest(1,(p_limit+1)/2) ELSE p_limit END
  )
  SELECT candidates.candidate_site_id FROM (
    SELECT 0 AS priority,due.candidate_site_id,due.ordering_time FROM due
    UNION ALL SELECT 1 AS priority,eligible.candidate_site_id,eligible.ordering_time FROM eligible
  ) candidates ORDER BY candidates.priority,candidates.ordering_time ASC NULLS FIRST,
    candidates.candidate_site_id LIMIT p_limit;
END;
$_$;


--
-- Name: load_harness_host_state(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.load_harness_host_state(p_id uuid, p_site_id uuid, p_owner text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE result jsonb;
BEGIN
  PERFORM public.lock_harness_host_owner(p_id,p_site_id,p_owner);
  SELECT jsonb_build_object('version',version,'ciphertext',ciphertext) INTO result
    FROM public.harness_host_state WHERE session_id=p_id AND site_id=p_site_id;
  RETURN result;
END;
$$;


--
-- Name: instance_pending_work; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_pending_work (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid,
    message text NOT NULL,
    activity text DEFAULT 'ask'::text NOT NULL,
    context jsonb DEFAULT '{}'::jsonb NOT NULL,
    system_prompt text,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    claimed_at timestamp with time zone,
    sent_at timestamp with time zone,
    CONSTRAINT instance_pending_work_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'claimed'::text, 'sent'::text, 'cancelled'::text])))
);


--
-- Name: load_ready_pending_work(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.load_ready_pending_work(p_limit integer DEFAULT 200) RETURNS SETOF public.instance_pending_work
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  WITH candidate_ids AS (
    SELECT DISTINCT ON (pending.instance_id)
      pending.id,
      pending.instance_id,
      pending.created_at
    FROM public.instance_pending_work AS pending
    WHERE pending.status = 'pending'
      AND NOT EXISTS (
        SELECT 1
        FROM public.instance_logs AS log
        WHERE log.instance_id = pending.instance_id
          AND log.log_type = 'user_action'
          AND log.details->>'status' = 'running'
      )
    ORDER BY
      pending.instance_id,
      CASE WHEN pending.status = 'claimed' THEN 0 ELSE 1 END,
      pending.created_at ASC
  ),
  locked AS (
    SELECT pending.id
    FROM public.instance_pending_work AS pending
    JOIN candidate_ids AS candidate ON candidate.id = pending.id
    ORDER BY candidate.created_at ASC
    LIMIT LEAST(GREATEST(p_limit, 1), 500)
    FOR UPDATE OF pending SKIP LOCKED
  ),
  claimed AS (
    UPDATE public.instance_pending_work AS pending
    SET
      status = 'claimed',
      claimed_at = timezone('utc', now())
    FROM locked
    WHERE pending.id = locked.id
    RETURNING pending.*
  )
  SELECT * FROM claimed;
$$;


--
-- Name: location_acl_assert_unscoped_rpc(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_assert_unscoped_rpc() RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
BEGIN
  IF current_setting('role',true) = 'anon' OR (
    current_setting('role',true) = 'authenticated'
    AND public.current_user_has_location_restrictions()
  ) THEN
    RAISE EXCEPTION 'This operation has no authorized location projection' USING ERRCODE='42501';
  END IF;
END;
$$;


--
-- Name: location_acl_can_manage_ownership(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_can_manage_ownership(p_site_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.sites s WHERE s.id = p_site_id
      AND s.user_id = auth.uid() AND s.archived_at IS NULL
  );
$$;


--
-- Name: location_acl_guard_root_scope(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_guard_root_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $_$
DECLARE scope_column text; old_data jsonb := to_jsonb(OLD); data jsonb := to_jsonb(NEW);
  approved boolean := false; link record; child_scope text; inconsistent boolean;
BEGIN
  SELECT location_column INTO STRICT scope_column FROM location_acl_private.roots WHERE table_name=TG_TABLE_NAME;
  IF old_data->'site_id' IS DISTINCT FROM data->'site_id'
    OR old_data->'id' IS DISTINCT FROM data->'id' THEN
    RAISE EXCEPTION 'Operational root identity is immutable' USING ERRCODE='23514';
  END IF;
  IF old_data->scope_column IS NOT DISTINCT FROM data->scope_column THEN RETURN NEW; END IF;
  IF old_data->>scope_column IS NOT NULL OR data->>scope_column IS NULL THEN
    RAISE EXCEPTION 'Known location scope is immutable' USING ERRCODE='23514';
  END IF;
  DELETE FROM location_acl_private.scope_assignments
    WHERE transaction_id=txid_current() AND table_name=TG_TABLE_NAME
      AND row_id=NEW.id AND site_id=NEW.site_id
      AND location_id=(data->>scope_column)::uuid AND actor_id=auth.uid()
    RETURNING true INTO approved;
  IF approved IS DISTINCT FROM true
    OR coalesce(public.current_user_site_role(NEW.site_id),'') NOT IN ('owner','admin') THEN
    RAISE EXCEPTION 'Manager scope assignment required' USING ERRCODE='42501';
  END IF;
  -- Child validation locks the parent FOR SHARE. Initial assignment must not
  -- invalidate an existing child's scope, including unresolved NULL children.
  FOR link IN SELECT * FROM location_acl_private.links WHERE parent_table=TG_TABLE_NAME AND same_location LOOP
    SELECT location_column INTO STRICT child_scope FROM location_acl_private.roots WHERE table_name=link.child_table;
    EXECUTE format('SELECT EXISTS(SELECT 1 FROM public.%I WHERE %I=$1
      AND (%I IS DISTINCT FROM $2 OR site_id IS DISTINCT FROM $3))',
      link.child_table,link.child_column,child_scope)
      INTO inconsistent USING NEW.id,(data->>scope_column)::uuid,NEW.site_id;
    IF inconsistent THEN
      RAISE EXCEPTION 'Operational parent scope is inconsistent' USING ERRCODE='23514';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$_$;


--
-- Name: location_acl_inherit_scope(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_inherit_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $_$
DECLARE link record; data jsonb := to_jsonb(NEW); old_data jsonb;
  scope_column text; scope_id uuid; parent_site uuid; parent_scope uuid; parent_column text;
  inherited_scope uuid; has_parent boolean := false; links_changed boolean;
BEGIN
  SELECT location_column INTO scope_column FROM location_acl_private.roots WHERE table_name=TG_TABLE_NAME;
  IF TG_OP='UPDATE' THEN
    old_data := to_jsonb(OLD);
    SELECT EXISTS(SELECT 1 FROM location_acl_private.links l WHERE l.child_table=TG_TABLE_NAME
      AND old_data->l.child_column IS DISTINCT FROM data->l.child_column) INTO links_changed;
    IF old_data->scope_column IS NOT DISTINCT FROM data->scope_column
      AND old_data->'site_id' IS NOT DISTINCT FROM data->'site_id' AND NOT links_changed THEN RETURN NEW; END IF;
  END IF;
  scope_id := (data->>scope_column)::uuid;
  FOR link IN SELECT * FROM location_acl_private.links WHERE child_table=TG_TABLE_NAME ORDER BY parent_table,child_column LOOP
    IF data->>link.child_column IS NULL THEN
      IF link.required THEN RAISE EXCEPTION 'Operational parent required' USING ERRCODE='23503'; END IF;
      CONTINUE;
    END IF;
    SELECT location_column INTO parent_column FROM location_acl_private.roots WHERE table_name=link.parent_table;
    -- SHARE conflicts with non-key scope updates after redundant triple FKs go.
    EXECUTE format('SELECT site_id,%s FROM public.%I WHERE id=$1 FOR SHARE',
      CASE WHEN parent_column IS NULL THEN 'NULL::uuid' ELSE quote_ident(parent_column) END,link.parent_table)
      INTO parent_site,parent_scope USING (data->>link.child_column)::uuid;
    IF parent_site IS NULL OR (data ? 'site_id' AND parent_site IS DISTINCT FROM (data->>'site_id')::uuid) THEN
      RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='23503';
    END IF;
    IF NOT link.same_location THEN CONTINUE; END IF;
    IF has_parent AND parent_scope IS DISTINCT FROM inherited_scope THEN
      RAISE EXCEPTION 'All operational parent locations must agree' USING ERRCODE='23514';
    END IF;
    inherited_scope := parent_scope; has_parent := true;
    IF scope_id IS NULL AND TG_OP='INSERT' THEN scope_id := parent_scope; END IF;
    IF scope_id IS DISTINCT FROM parent_scope THEN
      RAISE EXCEPTION 'All operational parent locations must agree' USING ERRCODE='23514';
    END IF;
  END LOOP;
  IF scope_column IS NOT NULL THEN NEW := jsonb_populate_record(NEW,jsonb_build_object(scope_column,scope_id)); END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: location_acl_visible_accounting_sale_refunds(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_accounting_sale_refunds() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.sale_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sales WHERE id=NEW.sale_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_deal_owners(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_deal_owners() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'deal_id' IS DISTINCT FROM to_jsonb(NEW)->'deal_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.deal_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.deals WHERE id=NEW.deal_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_invoice_reminders(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_invoice_reminders() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.sale_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sales WHERE id=NEW.sale_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_messages(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_messages() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'conversation_id' IS DISTINCT FROM to_jsonb(NEW)->'conversation_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.conversation_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.conversations WHERE id=NEW.conversation_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_pos_register_movements(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_pos_register_movements() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'session_id' IS DISTINCT FROM to_jsonb(NEW)->'session_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.session_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.pos_register_sessions WHERE id=NEW.session_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_pos_register_receipts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_pos_register_receipts() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.sale_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sales WHERE id=NEW.sale_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'session_id' IS DISTINCT FROM to_jsonb(NEW)->'session_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.session_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.pos_register_sessions WHERE id=NEW.session_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_purchase_items(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_purchase_items() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'purchase_id' IS DISTINCT FROM to_jsonb(NEW)->'purchase_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.purchase_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.purchases WHERE id=NEW.purchase_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_quotation_items(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_quotation_items() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'quotation_id' IS DISTINCT FROM to_jsonb(NEW)->'quotation_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.quotation_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.quotations WHERE id=NEW.quotation_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_quotations(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_quotations() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'deal_id' IS DISTINCT FROM to_jsonb(NEW)->'deal_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.deal_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.deals WHERE id=NEW.deal_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_reservations(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_reservations() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_order_item_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_order_item_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'operating_location_id' IS DISTINCT FROM to_jsonb(NEW)->'operating_location_id') AND NEW.sale_order_item_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sale_order_items WHERE id=NEW.sale_order_item_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_sale_order_item_units(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_sale_order_item_units() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_order_item_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_order_item_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.sale_order_item_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sale_order_items WHERE id=NEW.sale_order_item_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'shipment_id' IS DISTINCT FROM to_jsonb(NEW)->'shipment_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.shipment_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.shipments WHERE id=NEW.shipment_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;

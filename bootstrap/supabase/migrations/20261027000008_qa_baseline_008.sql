SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: accounting_record_sale_refund(uuid, text, numeric, text, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_record_sale_refund(p_sale_id uuid, p_refund_id text, p_amount numeric, p_currency text, p_refunded_at timestamp with time zone) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  sale_row public.sales%ROWTYPE; previous public.accounting_sale_refunds%ROWTYPE;
  payment jsonb; payment_total numeric := 0; payment_amount numeric; received_amount numeric;
  refunded_amount numeric;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Refund receipts require a trusted service caller' USING ERRCODE = '42501';
  END IF;
  IF p_sale_id IS NULL OR p_refund_id IS NULL OR p_refund_id !~ '^re_[A-Za-z0-9_]+$'
    OR length(p_refund_id) > 255 OR p_amount IS NULL OR NOT (p_amount > 0 AND p_amount <= 1000000000000)
    OR p_amount <> trunc(p_amount, 2) OR p_currency IS NULL OR p_currency !~ '^[A-Z]{3}$'
    OR p_refunded_at IS NULL OR NOT isfinite(p_refunded_at) THEN
    RAISE EXCEPTION 'Invalid refund receipt' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO sale_row FROM public.sales WHERE id = p_sale_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Refund sale not found' USING ERRCODE = 'P0002'; END IF;
  IF upper(sale_row.currency) IS DISTINCT FROM p_currency THEN
    RAISE EXCEPTION 'Refund currency does not match the sale' USING ERRCODE = '23514';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('accounting:refund:' || p_refund_id, 0));
  SELECT * INTO previous FROM public.accounting_sale_refunds WHERE id = p_refund_id;
  IF FOUND THEN
    IF previous.sale_id = p_sale_id AND previous.site_id = sale_row.site_id AND previous.amount = p_amount
      AND previous.currency = p_currency AND previous.refunded_at = p_refunded_at THEN RETURN; END IF;
    RAISE EXCEPTION 'Refund identity conflicts with an existing receipt' USING ERRCODE = '23505';
  END IF;
  -- sales.payments is a JSONB receipt array, not public.payments (platform payouts).
  IF sale_row.payments IS NOT NULL AND jsonb_typeof(sale_row.payments) <> 'null' THEN
    IF jsonb_typeof(sale_row.payments) <> 'array' THEN
      RAISE EXCEPTION 'Sale payment receipts require review' USING ERRCODE = '23514';
    END IF;
    FOR payment IN SELECT value FROM jsonb_array_elements(sale_row.payments) LOOP
      IF coalesce(payment->>'amount', '') !~ '^[0-9]+([.][0-9]+)?$' THEN
        RAISE EXCEPTION 'Sale payment amount requires review' USING ERRCODE = '23514';
      END IF;
      payment_amount := (payment->>'amount')::numeric;
      IF payment_amount > 1000000000000 OR payment_amount <> trunc(payment_amount, 2) THEN
        RAISE EXCEPTION 'Invalid recorded payment amount' USING ERRCODE = '23514';
      END IF;
      payment_total := payment_total + payment_amount;
    END LOOP;
  END IF;
  IF sale_row.amount IS NULL OR sale_row.amount NOT BETWEEN 0 AND 1000000000000
    OR (sale_row.amount_due IS NOT NULL AND sale_row.amount_due NOT BETWEEN 0 AND 1000000000000) THEN
    RAISE EXCEPTION 'Sale amounts require review' USING ERRCODE = '23514';
  END IF;
  received_amount := greatest(payment_total, greatest(0, sale_row.amount - coalesce(sale_row.amount_due, sale_row.amount)));
  SELECT coalesce(sum(amount), 0) INTO refunded_amount FROM public.accounting_sale_refunds WHERE sale_id = p_sale_id;
  IF refunded_amount + p_amount > received_amount THEN
    RAISE EXCEPTION 'Cumulative refunds exceed recorded receipts' USING ERRCODE = '23514';
  END IF;
  INSERT INTO public.accounting_sale_refunds(id, sale_id, site_id, amount, currency, refunded_at)
    VALUES (p_refund_id, p_sale_id, sale_row.site_id, p_amount, p_currency, p_refunded_at);
  UPDATE public.sales SET accounting_state = CASE WHEN accounting_state = 'unpublished'
    THEN 'unpublished' ELSE 'pending' END, updated_at = clock_timestamp() WHERE id = p_sale_id;
END;
$_$;


--
-- Name: accounting_replace_source_journals(uuid, text, uuid, jsonb, timestamp with time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_replace_source_journals(p_site_id uuid, p_source_type text, p_source_id uuid, p_entries jsonb, p_source_updated_at timestamp with time zone, p_state text DEFAULT 'posted'::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  source_table text; source_row jsonb; source_version timestamptz; source_company uuid;
  draft jsonb; line jsonb; entry_key text; key_prefix text; kept_ids uuid[] := ARRAY[]::uuid[];
  seen_keys text[] := ARRAY[]::text[]; saved_id uuid;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Source journals require a trusted service caller' USING ERRCODE = '42501';
  END IF;
  source_table := CASE p_source_type WHEN 'sale' THEN 'sales' WHEN 'expense' THEN 'transactions'
    WHEN 'purchase' THEN 'purchases' END;
  IF source_table IS NULL OR p_site_id IS NULL OR p_source_id IS NULL OR p_source_updated_at IS NULL
    OR NOT isfinite(p_source_updated_at) OR p_state IS NULL OR p_state NOT IN ('posted','unpublished')
    OR jsonb_typeof(p_entries) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Invalid source journal request' USING ERRCODE = '22023';
  END IF;
  IF jsonb_array_length(p_entries) > 5000
    OR (p_state = 'unpublished' AND jsonb_array_length(p_entries) <> 0) THEN
    RAISE EXCEPTION 'Invalid source journal count or unpublished payload' USING ERRCODE = '22023';
  END IF;
  key_prefix := p_source_type || ':' || p_source_id::text;
  PERFORM pg_advisory_xact_lock(hashtextextended('accounting:source:' || p_site_id::text || ':' || key_prefix, 0));
  EXECUTE format('SELECT to_jsonb(s) FROM public.%I s WHERE id = $1 AND site_id = $2 FOR UPDATE', source_table)
    INTO source_row USING p_source_id, p_site_id;
  IF source_row IS NULL THEN
    RAISE EXCEPTION 'Accounting source not found in this site' USING ERRCODE = 'P0002';
  END IF;
  source_version := (source_row->>'updated_at')::timestamptz;
  IF source_version IS DISTINCT FROM p_source_updated_at THEN
    RAISE EXCEPTION 'Accounting source changed; reload before posting' USING ERRCODE = '40001';
  END IF;
  source_company := (source_row->>CASE WHEN p_source_type = 'purchase'
    THEN 'vendor_company_id' ELSE 'company_id' END)::uuid;
  FOR draft IN SELECT value FROM jsonb_array_elements(p_entries) LOOP
    IF jsonb_typeof(draft) IS DISTINCT FROM 'object' OR jsonb_typeof(draft->'entry') IS DISTINCT FROM 'object'
      OR jsonb_typeof(draft->'lines') IS DISTINCT FROM 'array'
      OR (draft->'entry'->>'source_type') IS DISTINCT FROM p_source_type
      OR (draft->'entry'->>'source_id')::uuid IS DISTINCT FROM p_source_id THEN
      RAISE EXCEPTION 'Journal does not belong to this source' USING ERRCODE = '22023';
    END IF;
    entry_key := draft->'entry'->>'idempotency_key';
    IF entry_key IS NULL OR NOT (entry_key = key_prefix OR starts_with(entry_key, key_prefix || ':'))
      OR entry_key = ANY(seen_keys) THEN
      RAISE EXCEPTION 'Invalid or duplicate source idempotency key' USING ERRCODE = '22023';
    END IF;
    seen_keys := array_append(seen_keys, entry_key);
    FOR line IN SELECT value FROM jsonb_array_elements(draft->'lines') LOOP
      IF line->>'company_id' IS NOT NULL AND (line->>'company_id')::uuid IS DISTINCT FROM source_company THEN
        RAISE EXCEPTION 'Company dimension must match the accounting source' USING ERRCODE = '23514';
      END IF;
    END LOOP;
    saved_id := public.accounting_save_journal_internal(p_site_id, draft->'entry', draft->'lines',
      NULL, NULL, false, true);
    kept_ids := array_append(kept_ids, saved_id);
  END LOOP;
  -- Reconciliation and state change share this transaction; never delete headers
  -- that matched a draft, and never touch a different site's or source's journals.
  DELETE FROM public.journal_lines l USING public.journal_entries e
    WHERE l.entry_id = e.id AND e.site_id = p_site_id AND e.source_type = p_source_type
      AND e.source_id = p_source_id AND NOT (e.id = ANY(kept_ids));
  DELETE FROM public.journal_entries WHERE site_id = p_site_id AND source_type = p_source_type
    AND source_id = p_source_id AND NOT (id = ANY(kept_ids));
  EXECUTE format('UPDATE public.%I SET accounting_state = $1 WHERE id = $2 AND site_id = $3 AND accounting_state IS DISTINCT FROM $1', source_table)
    USING p_state, p_source_id, p_site_id;
END;
$_$;


--
-- Name: accounting_report_snapshot(uuid, timestamp with time zone, timestamp with time zone, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_report_snapshot(p_site_id uuid, p_from timestamp with time zone, p_to_exclusive timestamp with time zone, p_currency text, p_include_opening boolean) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE result jsonb;
BEGIN
  IF p_site_id IS NULL OR (auth.role() IS DISTINCT FROM 'service_role'
    AND (auth.uid() IS NULL OR NOT public.user_can(p_site_id,'select'))) THEN
    RAISE EXCEPTION 'Accounting report access denied' USING ERRCODE = '42501';
  END IF;
  IF p_to_exclusive IS NULL OR NOT isfinite(p_to_exclusive) OR p_currency IS NULL
    OR p_currency !~ '^[A-Z]{3}$' OR p_include_opening IS NULL
    OR (p_from IS NOT NULL AND (NOT isfinite(p_from) OR p_from >= p_to_exclusive)) THEN
    RAISE EXCEPTION 'Invalid accounting report parameters' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.journal_entries e WHERE e.site_id=p_site_id
    AND (p_from IS NULL OR e.entry_date >= p_from) AND e.entry_date < p_to_exclusive
    AND (p_include_opening OR e.source_type <> 'opening')
    AND (e.currency IS NULL OR e.currency !~ '^[A-Z]{3}$')) THEN
    RAISE EXCEPTION 'ACCOUNTING_UNKNOWN_CURRENCY' USING ERRCODE = 'P0001';
  END IF;
  IF EXISTS (SELECT 1 FROM public.journal_entries e LEFT JOIN public.journal_lines l ON l.entry_id=e.id
    WHERE e.site_id=p_site_id AND e.currency=p_currency
      AND (p_from IS NULL OR e.entry_date >= p_from) AND e.entry_date < p_to_exclusive
      AND (p_include_opening OR e.source_type <> 'opening')
    GROUP BY e.id HAVING count(l.id)<2 OR sum(l.debit) IS DISTINCT FROM sum(l.credit)
      OR coalesce(sum(l.debit),0)<=0 OR bool_or(l.debit IS NULL OR l.credit IS NULL
        OR l.debit NOT BETWEEN 0 AND 1000000000000 OR l.credit NOT BETWEEN 0 AND 1000000000000
        OR l.debit<>trunc(l.debit,2) OR l.credit<>trunc(l.credit,2)
        OR NOT ((l.debit>0 AND l.credit=0) OR (l.credit>0 AND l.debit=0)))) THEN
    RAISE EXCEPTION 'ACCOUNTING_INVALID_JOURNAL' USING ERRCODE = 'P0001';
  END IF;
  SELECT coalesce(jsonb_object_agg(account_code, jsonb_build_object('debit', debit, 'credit', credit)), '{}'::jsonb)
    INTO result FROM (
      SELECT l.account_code, sum(l.debit) AS debit, sum(l.credit) AS credit
      FROM public.journal_lines l JOIN public.journal_entries e ON e.id=l.entry_id
      WHERE e.site_id=p_site_id AND e.currency=p_currency
        AND (p_from IS NULL OR e.entry_date>=p_from) AND e.entry_date<p_to_exclusive
        AND (p_include_opening OR e.source_type<>'opening') GROUP BY l.account_code
    ) totals;
  RETURN result;
END;
$_$;


--
-- Name: accounting_save_journal(uuid, jsonb, jsonb, uuid, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_save_journal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid DEFAULT NULL::uuid, p_expected_hash text DEFAULT NULL::text, p_check_version boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4249998($1,$2,$3,$4,$5,$6); END$_$;


--
-- Name: accounting_save_journal_internal(uuid, jsonb, jsonb, uuid, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_save_journal_internal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean, p_allow_source boolean) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  existing public.journal_entries%ROWTYPE; entry_id uuid; source_kind text;
  source_id uuid; entry_key text; entry_currency text; entry_hash text; entry_day timestamptz;
  is_service boolean := coalesce(auth.role() = 'service_role', false); line jsonb;
BEGIN
  IF p_site_id IS NULL OR (NOT is_service AND (auth.uid() IS NULL OR NOT (
    public.user_can(p_site_id, 'insert') OR public.user_can(p_site_id, 'update')))) THEN
    RAISE EXCEPTION 'Accounting write is not authorized' USING ERRCODE = '42501';
  END IF;
  IF jsonb_typeof(p_entry) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid journal header' USING ERRCODE = '22023';
  END IF;
  source_kind := p_entry->>'source_type';
  source_id := (p_entry->>'source_id')::uuid;
  entry_key := p_entry->>'idempotency_key';
  entry_currency := p_entry->>'currency';
  entry_hash := p_entry->>'source_hash';
  IF source_kind IS NULL OR source_kind NOT IN ('manual','opening','sale','expense','purchase')
    OR (source_kind IN ('sale','expense','purchase') AND NOT (p_allow_source AND is_service))
    OR (source_kind IN ('manual','opening') AND source_id IS NOT NULL)
    OR (source_kind IN ('sale','expense','purchase') AND source_id IS NULL) THEN
    RAISE EXCEPTION 'Invalid or unauthorized journal source' USING ERRCODE = '42501';
  END IF;
  IF entry_key IS NULL OR length(entry_key) NOT BETWEEN 1 AND 300
    OR (source_kind = 'manual' AND entry_key !~ '^manual:[0-9a-fA-F-]{36}$')
    OR (source_kind = 'opening' AND entry_key <> 'opening:' || p_site_id::text)
    OR entry_currency IS NULL OR entry_currency !~ '^[A-Z]{3}$'
    OR entry_hash IS NULL OR entry_hash !~ '^[0-9a-f]{64}$'
    OR coalesce(length(p_entry->>'memo'), 0) > 2000
    OR (p_entry ? 'site_id' AND p_entry->>'site_id' IS DISTINCT FROM p_site_id::text)
    OR (p_entry->>'entry_date') IS NULL
    OR (p_entry->>'entry_date') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T00:00:00([.]0{1,6})?Z$' THEN
    RAISE EXCEPTION 'Invalid journal header fields' USING ERRCODE = '22023';
  END IF;
  entry_day := (p_entry->>'entry_date')::timestamptz;
  IF NOT isfinite(entry_day) THEN
    RAISE EXCEPTION 'Invalid journal date' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('accounting:journal:' || p_site_id::text || ':' || entry_key, 0));
  IF p_entry_id IS NULL THEN
    SELECT * INTO existing FROM public.journal_entries
      WHERE site_id = p_site_id AND idempotency_key = entry_key FOR UPDATE;
  ELSE
    SELECT * INTO existing FROM public.journal_entries WHERE site_id = p_site_id AND id = p_entry_id FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Journal not found in this site' USING ERRCODE = 'P0002';
    END IF;
  END IF;
  IF NOT is_service AND NOT public.user_can(p_site_id, CASE WHEN existing.id IS NULL THEN 'insert' ELSE 'update' END) THEN
    RAISE EXCEPTION 'Accounting operation is not authorized' USING ERRCODE = '42501';
  END IF;
  IF existing.id IS NOT NULL AND (existing.source_type IS DISTINCT FROM source_kind
    OR existing.source_id IS DISTINCT FROM source_id OR existing.idempotency_key IS DISTINCT FROM entry_key) THEN
    RAISE EXCEPTION 'Journal identity is immutable' USING ERRCODE = '23514';
  END IF;
  IF existing.id IS NOT NULL AND source_kind IN ('manual','opening')
    AND existing.currency IS NOT NULL AND existing.currency <> entry_currency THEN
    RAISE EXCEPTION 'Existing journal currency cannot change; use a correcting entry' USING ERRCODE = '23514';
  END IF;
  IF (p_check_version AND existing.source_hash IS DISTINCT FROM p_expected_hash)
    OR (NOT is_service AND existing.id IS NOT NULL AND NOT coalesce(p_check_version, false)) THEN
    RAISE EXCEPTION 'Journal changed; reload before saving' USING ERRCODE = '40001';
  END IF;
  PERFORM public.accounting_validate_journal_lines(p_site_id, p_lines, existing.id, p_allow_source AND is_service);
  -- A hash alone is not proof of equal content. Check all persisted fields and the
  -- complete line multiset before skipping an idempotent replay.
  IF existing.id IS NOT NULL AND existing.source_hash = entry_hash AND existing.entry_date = entry_day
    AND existing.memo IS NOT DISTINCT FROM (p_entry->>'memo') AND existing.currency = entry_currency
    AND existing.status = 'posted' AND NOT EXISTS (
      (SELECT to_jsonb(l) - ARRAY['id','entry_id','created_at','updated_at'] FROM public.journal_lines l
        WHERE l.entry_id = existing.id EXCEPT ALL
       SELECT jsonb_build_object('account_code', j->>'account_code', 'debit', (j->>'debit')::numeric,
         'credit', (j->>'credit')::numeric, 'location_id', j->'location_id', 'lead_id', j->'lead_id',
         'campaign_id', j->'campaign_id', 'segment_id', j->'segment_id', 'catalog_item_id', j->'catalog_item_id',
         'catalog_category_id', j->'catalog_category_id', 'company_id', j->'company_id') FROM jsonb_array_elements(p_lines) j)
      UNION ALL
      (SELECT jsonb_build_object('account_code', j->>'account_code', 'debit', (j->>'debit')::numeric,
         'credit', (j->>'credit')::numeric, 'location_id', j->'location_id', 'lead_id', j->'lead_id',
         'campaign_id', j->'campaign_id', 'segment_id', j->'segment_id', 'catalog_item_id', j->'catalog_item_id',
         'catalog_category_id', j->'catalog_category_id', 'company_id', j->'company_id') FROM jsonb_array_elements(p_lines) j
       EXCEPT ALL SELECT to_jsonb(l) - ARRAY['id','entry_id','created_at','updated_at'] FROM public.journal_lines l
        WHERE l.entry_id = existing.id)
    ) THEN RETURN existing.id;
  END IF;
  IF existing.id IS NULL THEN
    INSERT INTO public.journal_entries(site_id, entry_date, memo, source_type, source_id,
      idempotency_key, source_hash, currency, status)
    VALUES (p_site_id, entry_day, p_entry->>'memo', source_kind, source_id, entry_key, entry_hash, entry_currency, 'posted')
    RETURNING id INTO entry_id;
  ELSE
    entry_id := existing.id;
    UPDATE public.journal_entries SET entry_date = entry_day, memo = p_entry->>'memo',
      source_hash = entry_hash, currency = entry_currency, status = 'posted', updated_at = clock_timestamp()
      WHERE id = entry_id AND site_id = p_site_id;
    DELETE FROM public.journal_lines WHERE journal_lines.entry_id = existing.id;
  END IF;
  FOR line IN SELECT value FROM jsonb_array_elements(p_lines) LOOP
    INSERT INTO public.journal_lines(entry_id, account_code, debit, credit, location_id, lead_id,
      campaign_id, segment_id, catalog_item_id, catalog_category_id, company_id)
    VALUES (entry_id, line->>'account_code', (line->>'debit')::numeric, (line->>'credit')::numeric,
      (line->>'location_id')::uuid, (line->>'lead_id')::uuid, (line->>'campaign_id')::uuid,
      (line->>'segment_id')::uuid, (line->>'catalog_item_id')::uuid, (line->>'catalog_category_id')::uuid,
      (line->>'company_id')::uuid);
  END LOOP;
  RETURN entry_id;
END;
$_$;


--
-- Name: accounting_touch_source(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_touch_source() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE old_data jsonb := to_jsonb(OLD); new_data jsonb := to_jsonb(NEW); field text; changed boolean := false;
BEGIN
  FOREACH field IN ARRAY ARRAY['site_id','amount','amount_due','currency','payments','status','sale_date','purchase_date','date',
    'category','location_id','lead_id','campaign_id','segment_id','catalog_item_id','catalog_category_id',
    'company_id','vendor_company_id','sale_order_id','title','product_name','invoice_number','reference_code','description','notes'] LOOP
    changed := changed OR new_data->field IS DISTINCT FROM old_data->field;
  END LOOP;
  IF changed THEN
    NEW.accounting_state := CASE WHEN OLD.accounting_state='unpublished' OR NEW.accounting_state='unpublished'
      THEN 'unpublished' ELSE 'pending' END;
  END IF;
  NEW.updated_at := greatest(clock_timestamp(), OLD.updated_at + interval '1 microsecond');
  RETURN NEW;
END;
$$;


--
-- Name: accounting_touch_source_from_child(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_touch_source_from_child() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE child_row jsonb; versions jsonb[]; source_id uuid; source_site uuid; field text;
  relevant text[]; changed boolean := false;
BEGIN
  relevant := CASE TG_TABLE_NAME WHEN 'sale_orders' THEN ARRAY['sale_id','site_id','tax_total']
    WHEN 'sale_order_items' THEN ARRAY['sale_order_id','site_id','catalog_item_id']
    ELSE ARRAY['purchase_id','site_id','catalog_item_id','quantity','unit_cost','subtotal'] END;
  IF TG_OP='UPDATE' THEN
    FOREACH field IN ARRAY relevant LOOP
      changed := changed OR (to_jsonb(NEW)->field IS DISTINCT FROM to_jsonb(OLD)->field);
    END LOOP;
    IF NOT changed THEN RETURN NEW; END IF;
  END IF;
  versions := CASE TG_OP WHEN 'INSERT' THEN ARRAY[to_jsonb(NEW)] WHEN 'DELETE' THEN ARRAY[to_jsonb(OLD)]
    ELSE ARRAY[to_jsonb(OLD),to_jsonb(NEW)] END;
  FOREACH child_row IN ARRAY versions LOOP
    source_site := (child_row->>'site_id')::uuid;
    IF TG_TABLE_NAME='purchase_items' THEN
      UPDATE public.purchases SET updated_at=clock_timestamp(),
        accounting_state=CASE WHEN accounting_state='unpublished' THEN 'unpublished' ELSE 'pending' END
        WHERE id=(child_row->>'purchase_id')::uuid AND site_id=source_site;
    ELSE
      IF TG_TABLE_NAME='sale_orders' THEN source_id := (child_row->>'sale_id')::uuid;
      ELSE SELECT sale_id INTO source_id FROM public.sale_orders WHERE id=(child_row->>'sale_order_id')::uuid AND site_id=source_site;
      END IF;
      UPDATE public.sales SET updated_at=clock_timestamp(),
        accounting_state=CASE WHEN accounting_state='unpublished' THEN 'unpublished' ELSE 'pending' END
        WHERE id=source_id AND site_id=source_site;
    END IF;
  END LOOP;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: accounting_update_purchase_items(uuid, uuid, timestamp with time zone, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_update_purchase_items(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_4250037($1,$2,$3,$4,$5); RETURN; END$_$;

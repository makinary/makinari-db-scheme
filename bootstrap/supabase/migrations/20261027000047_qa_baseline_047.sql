SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: pos_register_capture_sale_payments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_capture_sale_payments() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE old_payments jsonb := '[]'::jsonb; new_payments jsonb; payment jsonb;
  payment_id uuid; session_id uuid; recorded_by uuid; actor uuid;
  session public.pos_register_sessions%ROWTYPE; amount numeric; tendered numeric; change_amount numeric;
  method text; tagged boolean := false;
BEGIN
  IF TG_OP <> 'INSERT' AND jsonb_typeof(OLD.payments) = 'array' THEN old_payments := OLD.payments; END IF;
  tagged := EXISTS (SELECT 1 FROM jsonb_array_elements(old_payments) p WHERE p ? 'register_session_id')
    OR EXISTS (SELECT 1 FROM public.pos_register_receipts WHERE sale_id = CASE WHEN TG_OP = 'INSERT' THEN NEW.id ELSE OLD.id END);
  IF TG_OP = 'DELETE' THEN
    IF tagged THEN RAISE EXCEPTION 'Sales with register receipts cannot be deleted' USING ERRCODE = '23514'; END IF;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND tagged AND ROW(NEW.id,NEW.site_id,NEW.currency,NEW.location_id)
    IS DISTINCT FROM ROW(OLD.id,OLD.site_id,OLD.currency,OLD.location_id) THEN
    RAISE EXCEPTION 'Register sale identity, site, currency and location are immutable' USING ERRCODE = '23514';
  END IF;
  new_payments := coalesce(NEW.payments,'[]'::jsonb);
  IF jsonb_typeof(new_payments) <> 'array' THEN
    IF tagged THEN RAISE EXCEPTION 'Tagged register payments cannot be removed' USING ERRCODE = '23514'; END IF;
    RETURN NEW; -- Preserve unrelated legacy/non-POS payment formats.
  END IF;
  FOR payment IN SELECT value FROM jsonb_array_elements(old_payments) WHERE value ? 'register_session_id' LOOP
    IF (SELECT count(*) FROM jsonb_array_elements(new_payments) p WHERE p = payment) <> 1 THEN
      RAISE EXCEPTION 'Tagged register payments are immutable' USING ERRCODE = '23514';
    END IF;
  END LOOP;
  -- Validate UUIDs before ordered session locking; never silently drop malformed
  -- tags. Untagged historical and legacy-client payments stay unassigned.
  FOR payment IN SELECT value FROM jsonb_array_elements(new_payments) WHERE value ? 'register_session_id' LOOP
    BEGIN
      session_id := (payment->>'register_session_id')::uuid;
      payment_id := (payment->>'payment_id')::uuid;
      recorded_by := (payment->>'recorded_by')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'Register payment tags require valid UUIDs' USING ERRCODE = '22023';
    END;
    IF session_id IS NULL OR payment_id IS NULL OR recorded_by IS NULL THEN
      RAISE EXCEPTION 'Register payment tags require session, payment and actor UUIDs' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM jsonb_array_elements(new_payments) p WHERE p ? 'register_session_id'
    GROUP BY (p->>'payment_id')::uuid HAVING count(*) > 1) THEN
    RAISE EXCEPTION 'Duplicate register payment ID' USING ERRCODE = '23505';
  END IF;
  -- Lock every newly referenced session in UUID order. Close and movements take
  -- this same row lock, so receipt insertion and the sale save commit atomically.
  FOR session_id IN SELECT DISTINCT (p->>'register_session_id')::uuid
    FROM jsonb_array_elements(new_payments) p WHERE p ? 'register_session_id'
      AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(old_payments) o WHERE o = p)
    ORDER BY 1 LOOP
    SELECT * INTO session FROM public.pos_register_sessions WHERE id = session_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Register session not found' USING ERRCODE = '22023'; END IF;
    actor := public.pos_register_authorize(session.site_id,session.opened_by);
    IF session.status <> 'open' THEN RAISE EXCEPTION 'Register session is closed' USING ERRCODE = '23514'; END IF;
    IF NEW.site_id IS DISTINCT FROM session.site_id OR NEW.location_id IS DISTINCT FROM session.location_id
      OR NEW.currency IS DISTINCT FROM session.currency THEN
      RAISE EXCEPTION 'Register payment site, location and currency must match the sale' USING ERRCODE = '22023';
    END IF;
    PERFORM 1 FROM public.locations WHERE id = session.location_id AND site_id = session.site_id AND is_active IS TRUE FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'An active same-site register location is required' USING ERRCODE = '22023'; END IF;
    FOR payment IN SELECT value FROM jsonb_array_elements(new_payments) p
      WHERE p ? 'register_session_id' AND (p->>'register_session_id')::uuid = session.id
        AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(old_payments) o WHERE o = p) LOOP
      payment_id := (payment->>'payment_id')::uuid;
      recorded_by := (payment->>'recorded_by')::uuid;
      IF recorded_by <> actor THEN RAISE EXCEPTION 'Register payment actor must match authenticated user' USING ERRCODE = '42501'; END IF;
      IF payment->>'status' IS DISTINCT FROM 'completed' THEN
        RAISE EXCEPTION 'Tagged register payments must be completed' USING ERRCODE = '22023';
      END IF;
      method := payment->>'method';
      IF method IS NULL OR method NOT IN ('cash','credit_card','debit_card','transfer','on_account','other') THEN
        RAISE EXCEPTION 'Invalid register payment method' USING ERRCODE = '22023';
      END IF;
      IF payment ? 'currency' AND payment->>'currency' IS DISTINCT FROM session.currency THEN
        RAISE EXCEPTION 'Register payment currency mismatch' USING ERRCODE = '22023';
      END IF;
      BEGIN
        amount := (payment->>'amount')::numeric;
        tendered := (payment->>'tendered')::numeric;
        change_amount := (payment->>'change')::numeric;
      EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RAISE EXCEPTION 'Register payment amounts must be finite numbers' USING ERRCODE = '22023';
      END;
      IF amount IS NULL OR amount <= 0 OR amount::text IN ('NaN','Infinity','-Infinity')
        OR tendered IS NULL OR tendered < 0 OR tendered::text IN ('NaN','Infinity','-Infinity')
        OR change_amount IS NULL OR change_amount < 0 OR change_amount::text IN ('NaN','Infinity','-Infinity')
        OR (method = 'cash' AND tendered - change_amount <> amount) THEN
        RAISE EXCEPTION 'Register payment amounts must be finite, nonnegative and balanced for cash' USING ERRCODE = '22023';
      END IF;
      -- Global payment-ID uniqueness rejects cross-sale/session reuse rather than
      -- silently accepting a mismatched receipt. Unchanged sale replays skip here.
      INSERT INTO public.pos_register_receipts(id,session_id,site_id,sale_id,method,amount,tendered,change,actor_id)
        VALUES (payment_id,session.id,session.site_id,NEW.id,method,amount,tendered,change_amount,actor);
    END LOOP;
  END LOOP;
  RETURN NEW;
END;
$$;


--
-- Name: pos_register_close(uuid, numeric, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_close(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4373684($1,$2,$3,$4); END$_$;


--
-- Name: pos_register_immutable_ledger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_immutable_ledger() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  RAISE EXCEPTION 'Register ledger rows are immutable' USING ERRCODE = '23514';
END;
$$;


--
-- Name: pos_register_move(uuid, text, numeric, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_move(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4373682($1,$2,$3,$4,$5); END$_$;


--
-- Name: pos_register_open(uuid, uuid, text, numeric, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_open(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4373681($1,$2,$3,$4,$5); END$_$;


--
-- Name: pos_register_preserve_session(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_preserve_session() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'Register sessions cannot be deleted' USING ERRCODE = '23514';
  END IF;
  IF OLD.status = 'closed' AND NEW IS DISTINCT FROM OLD THEN
    RAISE EXCEPTION 'Closed register snapshots are immutable' USING ERRCODE = '23514';
  END IF;
  IF ROW(NEW.id,NEW.site_id,NEW.location_id,NEW.currency,NEW.opened_by,NEW.opened_at,NEW.opening_amount)
    IS DISTINCT FROM ROW(OLD.id,OLD.site_id,OLD.location_id,OLD.currency,OLD.opened_by,OLD.opened_at,OLD.opening_amount) THEN
    RAISE EXCEPTION 'Register opening fields are immutable' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: pos_register_summary(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pos_register_summary(p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4373683($1); END$_$;


--
-- Name: prepare_requirement_source_checkpoint(uuid, text, integer, uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prepare_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_intent jsonb) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE r public.requirements%ROWTYPE; s public.harness_sessions%ROWTYPE;
BEGIN
  IF jsonb_typeof(p_intent) IS DISTINCT FROM 'object' OR octet_length(p_intent::text)>4000000
    OR coalesce(p_intent->>'parentSha','') !~ '^[0-9a-f]{40}$'
    OR coalesce(p_intent->>'expectedSha','') !~ '^[0-9a-f]{40}$'
    OR jsonb_typeof(p_intent->'createRef') IS DISTINCT FROM 'boolean'
    OR jsonb_typeof(p_intent->'baseline') IS DISTINCT FROM 'object'
    OR p_intent#>>'{baseline,commitSha}' IS DISTINCT FROM p_intent->>'expectedSha'
  THEN RAISE EXCEPTION 'Invalid checkpoint publication intent' USING ERRCODE='22023'; END IF;
  IF NOT public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id,false,300) THEN RETURN false; END IF;
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id FOR UPDATE;
  SELECT * INTO s FROM public.harness_sessions WHERE id=p_session_id AND site_id=r.site_id FOR UPDATE;
  IF NOT FOUND OR p_owner IS NULL OR s.lease_owner IS DISTINCT FROM p_owner
    OR s.lease_expires_at IS NULL OR s.lease_expires_at<=clock_timestamp()
    OR s.snapshot->>'status' IS DISTINCT FROM 'running' THEN RETURN false; END IF;
  INSERT INTO public.requirement_source_checkpoints(requirement_id,site_id,session_id,pending_publication,last_result)
    VALUES(r.id,r.site_id,p_session_id,p_intent,'{"state":"unknown","reason":"publication_prepared"}'::jsonb)
    ON CONFLICT(requirement_id) DO UPDATE SET session_id=EXCLUDED.session_id,
      pending_publication=EXCLUDED.pending_publication,updated_at=clock_timestamp();
  RETURN true;
END;
$_$;


--
-- Name: preserve_marketplace_secret_identity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.preserve_marketplace_secret_identity() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.marketplace_integrations WHERE secret_id = OLD.id) THEN
    IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Reserved marketplace secret is linked'; END IF;
    IF (NEW.id,NEW.site_id,NEW.provider,NEW.use_case,NEW.instance_id) IS DISTINCT FROM
      (OLD.id,OLD.site_id,OLD.provider,OLD.use_case,OLD.instance_id) THEN
      RAISE EXCEPTION 'Reserved marketplace secret identity is immutable';
    END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;


--
-- Name: preserve_sale_order_creator(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.preserve_sale_order_creator() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF OLD.created_by_user_id IS DISTINCT FROM NEW.created_by_user_id THEN
    RAISE EXCEPTION 'created_by_user_id is immutable';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: prevent_cancelled_order_reopen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_cancelled_order_reopen() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF OLD.status = 'cancelled' AND NEW.status IS DISTINCT FROM 'cancelled' THEN
    RAISE EXCEPTION 'Cancelled orders cannot be reopened'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: prevent_last_admin_deletion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_last_admin_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    admin_owner_count INT;
BEGIN
    IF OLD.role IN ('admin', 'owner') THEN
        -- 1. Check if there are other admins/owners in site_members
        SELECT count(*)
        INTO admin_owner_count
        FROM site_members
        WHERE site_id = OLD.site_id
          AND role IN ('admin', 'owner')
          AND id != OLD.id;

        -- 2. If none found in site_members, check if there's an owner in site_ownership
        -- that is different from the user being deleted
        IF admin_owner_count = 0 THEN
            SELECT count(*)
            INTO admin_owner_count
            FROM site_ownership
            WHERE site_id = OLD.site_id
              AND (OLD.user_id IS NULL OR user_id != OLD.user_id);
        END IF;

        -- 3. If no other admins/owners exist in either table, block the deletion
        IF admin_owner_count = 0 THEN
            RAISE EXCEPTION 'Cannot delete the last admin or owner of the site. At least one admin or owner must remain.';
        END IF;
    END IF;

    RETURN OLD;
END;
$$;


--
-- Name: prevent_last_admin_role_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_last_admin_role_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    admin_owner_count INT;
BEGIN
    IF OLD.role IN ('admin', 'owner') AND NEW.role NOT IN ('admin', 'owner') THEN
        -- 1. Check if there are other admins/owners in site_members
        SELECT count(*)
        INTO admin_owner_count
        FROM site_members
        WHERE site_id = OLD.site_id
          AND role IN ('admin', 'owner')
          AND id != OLD.id;

        -- 2. If none found in site_members, check if there's an owner in site_ownership
        -- that is different from the user whose role is being changed
        IF admin_owner_count = 0 THEN
            SELECT count(*)
            INTO admin_owner_count
            FROM site_ownership
            WHERE site_id = OLD.site_id
              AND (OLD.user_id IS NULL OR user_id != OLD.user_id);
        END IF;

        -- 3. If no other admins/owners exist in either table, block the role change
        IF admin_owner_count = 0 THEN
            RAISE EXCEPTION 'Cannot change the role of the last admin or owner of the site. At least one admin or owner must remain.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: preview_catalog_import_categories(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.preview_catalog_import_categories(p_site_id uuid, p_names jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4387865($1,$2); END$_$;


--
-- Name: process_referral_code_use(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.process_referral_code_use(p_referral_code_id uuid, p_user_id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16750($1,$2); END$_$;


--
-- Name: protect_member_license(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_member_license() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF current_user IN ('anon','authenticated') AND TG_OP = 'INSERT' THEN NEW.created_at := clock_timestamp(); END IF;
  IF TG_OP = 'UPDATE' AND NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Member addition time is immutable';
  END IF;
  IF current_user IN ('anon','authenticated') AND TG_OP = 'UPDATE' AND OLD.user_id IS NULL
    AND NEW.user_id IS NOT NULL AND NEW.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Invitation identity must match authenticated user';
  END IF;
  IF current_user IN ('anon','authenticated') AND (
    (TG_OP = 'INSERT' AND NEW.license_suspended) OR
    (TG_OP = 'UPDATE' AND NEW.license_suspended IS DISTINCT FROM OLD.license_suspended)
  ) THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'License suspension is server managed'; END IF;
  IF current_user IN ('anon','authenticated') AND (
    (TG_OP = 'INSERT' AND NEW.manually_disabled) OR
    (TG_OP = 'UPDATE' AND NEW.manually_disabled IS DISTINCT FROM OLD.manually_disabled)
  ) THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Member enabled state is server managed'; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: protect_settings_license(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_settings_license() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE old_items jsonb; new_items jsonb; result jsonb; item jsonb; previous jsonb; category text;
  identity text; old_count integer; new_count integer; item_position bigint; unchanged boolean;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS DISTINCT FROM OLD.site_id THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Settings site is immutable';
  END IF;
  IF current_user NOT IN ('anon','authenticated') THEN RETURN NEW; END IF;
  FOREACH category IN ARRAY ARRAY['social','agent'] LOOP
    old_items := CASE WHEN TG_OP = 'INSERT' THEN '[]'::jsonb WHEN category = 'social' THEN OLD.social_media
      ELSE OLD.channels->'connections' END;
    new_items := CASE WHEN category = 'social' THEN NEW.social_media ELSE NEW.channels->'connections' END;
    IF new_items IS NULL OR new_items = 'null'::jsonb THEN CONTINUE; END IF;
    IF jsonb_typeof(new_items) <> 'array' THEN RAISE EXCEPTION 'Resource connections must be arrays'; END IF;
    old_items := coalesce(nullif(old_items,'null'::jsonb),'[]');
    SELECT (SELECT coalesce(jsonb_agg(value - '_license' - 'license_suspended' ORDER BY ordinality),'[]')
      FROM jsonb_array_elements(new_items) WITH ORDINALITY) =
      (SELECT coalesce(jsonb_agg(value - '_license' - 'license_suspended' ORDER BY ordinality),'[]')
      FROM jsonb_array_elements(old_items) WITH ORDINALITY) INTO unchanged;
    result := '[]'::jsonb;
    FOR item,item_position IN SELECT value,ordinality FROM jsonb_array_elements(new_items) WITH ORDINALITY LOOP
      identity := coalesce(nullif(item->>'id',''),nullif(item->>'zavu_sender_id',''),nullif(item->>'zavu_invitation_id',''),
        md5((item - '_license' - 'license_suspended' - 'isActive' - 'status' - 'updated_at')::text));
      SELECT count(*) INTO old_count FROM jsonb_array_elements(old_items)
        WHERE coalesce(nullif(value->>'id',''),nullif(value->>'zavu_sender_id',''),nullif(value->>'zavu_invitation_id',''),
          md5((value - '_license' - 'license_suspended' - 'isActive' - 'status' - 'updated_at')::text)) = identity;
      SELECT count(*) INTO new_count FROM jsonb_array_elements(new_items)
        WHERE coalesce(nullif(value->>'id',''),nullif(value->>'zavu_sender_id',''),nullif(value->>'zavu_invitation_id',''),
          md5((value - '_license' - 'license_suspended' - 'isActive' - 'status' - 'updated_at')::text)) = identity;
      IF new_count > greatest(1,old_count) THEN RAISE EXCEPTION 'Duplicate resource identity'; END IF;
      IF old_count > 1 AND NOT coalesce(item->'_license' ? 'order',false) AND NOT unchanged THEN
        RAISE EXCEPTION 'Legacy duplicate resources require stored license metadata';
      END IF;
      SELECT value INTO previous FROM jsonb_array_elements(old_items) WITH ORDINALITY
        WHERE coalesce(nullif(value->>'id',''),nullif(value->>'zavu_sender_id',''),nullif(value->>'zavu_invitation_id',''),
          md5((value - '_license' - 'license_suspended' - 'isActive' - 'status' - 'updated_at')::text)) = identity
          AND (old_count <= 1 OR CASE WHEN item->'_license' ? 'order'
            THEN value->'_license'->'order' = item->'_license'->'order' ELSE ordinality = item_position END)
        ORDER BY ordinality LIMIT 1;
      IF (item ? '_license' AND item->'_license' IS DISTINCT FROM previous->'_license') OR
        (item ? 'license_suspended' AND item->'license_suspended' IS DISTINCT FROM coalesce(previous->'license_suspended','false')) THEN
        RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Resource license metadata is server managed';
      END IF;
      item := item - '_license' - 'license_suspended';
      IF previous ? '_license' THEN item := item || jsonb_build_object('_license',previous->'_license',
        'license_suspended',coalesce(previous->'license_suspended','false')); END IF;
      result := result || jsonb_build_array(item);
    END LOOP;
    IF category = 'social' THEN NEW.social_media := result;
    ELSE NEW.channels := jsonb_set(NEW.channels,'{connections}',result); END IF;
  END LOOP;
  RETURN NEW;
END;
$$;

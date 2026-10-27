SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: grant_purchased_site_credits(uuid, numeric, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.grant_purchased_site_credits(p_site_id uuid, p_amount numeric, p_idempotency_key text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; k public.billing_credit_grant_keys%ROWTYPE;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount::text IN ('NaN','Infinity','-Infinity')
    OR p_idempotency_key IS NULL OR length(p_idempotency_key) < 8 OR length(p_idempotency_key) > 200
    OR jsonb_typeof(p_metadata) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Invalid purchased credit grant'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('purchased_credit:' || p_idempotency_key,0));
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'error','Billing record not found'); END IF;
  SELECT * INTO k FROM public.billing_credit_grant_keys WHERE idempotency_key = p_idempotency_key;
  IF FOUND THEN
    IF k.site_id <> p_site_id OR k.amount <> p_amount THEN RAISE EXCEPTION 'Purchased credit idempotency conflict'; END IF;
    RETURN jsonb_build_object('success',true,'outcome','duplicate','credits_granted',0,'new_balance',b.credits_available);
  END IF;
  -- Older completed checkout payments already delivered their credits. Adopt
  -- their identity without granting a second time when a webhook is replayed.
  IF EXISTS (SELECT 1 FROM public.payments WHERE transaction_id = p_idempotency_key
    AND (site_id <> p_site_id OR coalesce(credits,0) <> p_amount)) THEN
    RAISE EXCEPTION 'Historical purchase identity conflict';
  END IF;
  INSERT INTO public.billing_credit_grant_keys(idempotency_key,site_id,amount)
    VALUES (p_idempotency_key,p_site_id,p_amount);
  IF EXISTS (SELECT 1 FROM public.payments WHERE transaction_id = p_idempotency_key
    AND site_id = p_site_id AND status = 'completed' AND transaction_type = 'credits_purchase') THEN
    RETURN jsonb_build_object('success',true,'outcome','duplicate','credits_granted',0,'new_balance',b.credits_available);
  END IF;
  UPDATE public.billing SET purchased_credits_available = purchased_credits_available + p_amount,
    credits_available = credits_available + p_amount WHERE id = b.id;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES (p_site_id,p_amount,'credits_purchase','Purchased non-expiring credits',
      p_metadata || jsonb_build_object('credit_bucket','purchased','idempotency_key',p_idempotency_key));
  RETURN jsonb_build_object('success',true,'outcome','granted','credits_granted',p_amount,'new_balance',b.credits_available + p_amount);
END;
$$;


--
-- Name: guard_allowed_domain_provenance(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_allowed_domain_provenance() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  claim_role text := auth.role();
  database_role text := current_setting('role', true);
  service_writer boolean;
  deleted_requirement_cleanup boolean := false;
BEGIN
  -- Follow the existing JWT/SQL-role checks. SECURITY DEFINER's current_user
  -- is the function owner, not evidence that the caller is a trusted writer.
  service_writer := (coalesce(claim_role = 'service_role', false)
      OR coalesce(database_role = 'service_role', false))
    AND coalesce(claim_role, '') NOT IN ('anon', 'authenticated')
    AND coalesce(database_role, '') NOT IN ('anon', 'authenticated');

  IF NOT service_writer THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.source = 'harness' OR NEW.requirement_id IS NOT NULL THEN
        RAISE EXCEPTION 'Automatic domain provenance is server managed' USING ERRCODE = '42501';
      END IF;
    ELSE
      -- The browser may edit manual domains, but cannot rewrite their origin.
      -- ON DELETE SET NULL must not block an authorized requirement deletion.
      -- Only permit clearing a reference whose requirement really disappeared,
      -- without changing the domain identity or the recorded source.
      IF OLD.requirement_id IS NOT NULL AND NEW.requirement_id IS NULL
        AND NEW.site_id IS NOT DISTINCT FROM OLD.site_id
        AND NEW.domain IS NOT DISTINCT FROM OLD.domain
        AND NEW.source IS NOT DISTINCT FROM OLD.source THEN
        deleted_requirement_cleanup := NOT EXISTS (
          SELECT 1 FROM public.requirements WHERE id = OLD.requirement_id
        );
      END IF;
      IF NEW.source IS DISTINCT FROM OLD.source
        OR (NEW.requirement_id IS DISTINCT FROM OLD.requirement_id AND NOT deleted_requirement_cleanup)
        OR ((OLD.source = 'harness' OR OLD.requirement_id IS NOT NULL)
          AND (NEW.site_id IS DISTINCT FROM OLD.site_id OR NEW.domain IS DISTINCT FROM OLD.domain)) THEN
        RAISE EXCEPTION 'Automatic domain provenance is server managed' USING ERRCODE = '42501';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_archived_runner_reassignment_history(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_archived_runner_reassignment_history() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF TG_OP = 'DELETE' AND NOT EXISTS (
    SELECT 1 FROM public.requirements WHERE id = OLD.requirement_id
  ) THEN RETURN OLD; END IF;
  RAISE EXCEPTION 'Archived runner reassignment history is append-only'
    USING ERRCODE = '23514';
END;
$$;


--
-- Name: guard_archived_site_domain(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_archived_site_domain() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  PERFORM 1 FROM public.sites
    WHERE id = NEW.site_id AND archived_at IS NULL FOR KEY SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'An active site is required' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_billing_credit_buckets(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_billing_credit_buckets() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_browser boolean := coalesce(auth.role(), '') IN ('anon','authenticated')
    OR coalesce(current_setting('role',true),'') IN ('anon','authenticated');
  v_terminal boolean := lower(coalesce(NEW.subscription_status, '')) IN ('canceled','cancelled','incomplete_expired');
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.site_id IS DISTINCT FROM OLD.site_id THEN
    RAISE EXCEPTION 'Billing tenant identity is immutable';
  END IF;
  IF TG_OP = 'UPDATE' AND lower(coalesce(OLD.subscription_status,'')) IN ('canceled','cancelled','incomplete_expired')
    AND NOT v_terminal AND NEW.stripe_subscription_id IS NOT DISTINCT FROM OLD.stripe_subscription_id
    AND OLD.stripe_subscription_id IS NOT NULL THEN
    RAISE EXCEPTION 'A terminated Stripe subscription cannot be reactivated by a stale event';
  END IF;
  IF v_browser AND NOT (
    EXISTS (SELECT 1 FROM public.sites WHERE id = NEW.site_id AND user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.site_ownership WHERE site_id = NEW.site_id AND user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.site_members WHERE site_id = NEW.site_id AND user_id = auth.uid()
      AND status = 'active' AND role IN ('owner','admin'))
  ) THEN RAISE EXCEPTION 'Billing manager authorization required'; END IF;
  IF TG_OP = 'INSERT' THEN
    IF v_browser THEN RAISE EXCEPTION 'Billing initialization requires the authorized server'; END IF;
    IF coalesce(NEW.credits_available, 0) <> NEW.plan_credits_available + NEW.purchased_credits_available + NEW.legacy_credits_available + NEW.trial_credits_available THEN
      RAISE EXCEPTION 'Use initialize_site_billing or a classified credit RPC';
    END IF;
  ELSE
    IF v_browser AND ROW(NEW.plan,NEW.credits_available,NEW.credits_used,NEW.account_balance,
      NEW.plan_credits_available,NEW.purchased_credits_available,NEW.legacy_credits_available,NEW.trial_credits_available,
      NEW.monthly_credits_used,NEW.plan_credits_used,NEW.plan_credit_allowance,NEW.plan_credit_period_start,NEW.plan_credit_period_end,
      NEW.subscription_status,NEW.stripe_customer_id,NEW.stripe_subscription_id,NEW.addons_count,NEW.auto_renew,
      NEW.created_at,NEW.subscription_start_date,NEW.subscription_end_date,NEW.subscription_current_period_end,NEW.status,NEW.plan_credit_source)
      IS DISTINCT FROM ROW(OLD.plan,OLD.credits_available,OLD.credits_used,OLD.account_balance,
      OLD.plan_credits_available,OLD.purchased_credits_available,OLD.legacy_credits_available,OLD.trial_credits_available,
      OLD.monthly_credits_used,OLD.plan_credits_used,OLD.plan_credit_allowance,OLD.plan_credit_period_start,OLD.plan_credit_period_end,
      OLD.subscription_status,OLD.stripe_customer_id,OLD.stripe_subscription_id,OLD.addons_count,OLD.auto_renew,
      OLD.created_at,OLD.subscription_start_date,OLD.subscription_end_date,OLD.subscription_current_period_end,OLD.status,OLD.plan_credit_source)
      THEN RAISE EXCEPTION 'Financial billing fields are server managed'; END IF;
    IF NEW.credits_available IS DISTINCT FROM OLD.credits_available
      AND ROW(NEW.plan_credits_available,NEW.purchased_credits_available,NEW.legacy_credits_available,NEW.trial_credits_available)
        IS NOT DISTINCT FROM ROW(OLD.plan_credits_available,OLD.purchased_credits_available,OLD.legacy_credits_available,OLD.trial_credits_available)
      AND NOT (NEW.trial_credits_available > 0 AND NEW.credits_available =
        NEW.plan_credits_available + NEW.purchased_credits_available + NEW.legacy_credits_available)
      THEN RAISE EXCEPTION 'Aggregate-only credit writes are disabled; use a classified credit RPC'; END IF;
  END IF;
  IF TG_OP = 'UPDATE' AND NOT v_terminal AND NEW.stripe_subscription_id IS NOT NULL
    AND NEW.stripe_subscription_id IS DISTINCT FROM OLD.stripe_subscription_id THEN
    -- A different verified subscription needs its own paid invoice. Metadata
    -- synchronization does not grant credits or inherit the previous paid period.
    NEW.plan_credit_source := 'stripe_unverified';
    NEW.plan_credits_available := 0;
  END IF;
  IF v_terminal THEN
    NEW.plan := 'commission'; NEW.addons_count := 0; NEW.plan_credit_allowance := 1;
    IF TG_OP = 'INSERT' OR lower(coalesce(OLD.subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired') THEN
      NEW.plan_credits_available := 1; NEW.monthly_credits_used := 0; NEW.plan_credits_used := 0;
      NEW.plan_credit_source := 'toolbox';
      NEW.plan_credit_period_start := date_trunc('month', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
      NEW.plan_credit_period_end := (NEW.plan_credit_period_start AT TIME ZONE 'UTC' + interval '1 month') AT TIME ZONE 'UTC';
    END IF;
  ELSIF TG_OP = 'UPDATE' AND (NEW.plan IS DISTINCT FROM OLD.plan OR NEW.addons_count IS DISTINCT FROM OLD.addons_count)
    AND NEW.stripe_subscription_id IS NULL THEN
    -- Server-authorized partner licenses change entitlement without touching
    -- bought money. Repeating the same plan does not refill spent credits.
    NEW.plan_credit_allowance := public.site_plan_credit_allowance(NEW.plan,NEW.addons_count);
    NEW.plan_credits_available := greatest(NEW.plan_credit_allowance - OLD.plan_credits_used,0);
  END IF;
  NEW.credits_available := NEW.plan_credits_available + NEW.purchased_credits_available + NEW.legacy_credits_available + NEW.trial_credits_available;
  RETURN NEW;
END;
$$;


--
-- Name: guard_billing_paid_subscription_coverage(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_billing_paid_subscription_coverage() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE v_browser boolean := coalesce(auth.role(),'') IN ('anon','authenticated')
  OR coalesce(current_setting('role',true),'') IN ('anon','authenticated');
BEGIN
  IF TG_OP = 'UPDATE' AND v_browser AND
    ROW(NEW.billing_interval,NEW.paid_subscription_period_start,NEW.paid_subscription_period_end,
      NEW.paid_subscription_invoice_id,NEW.paid_subscription_plan,NEW.paid_subscription_addons_count,NEW.paid_subscription_paid_at,NEW.plan_credit_anchor)
    IS DISTINCT FROM
    ROW(OLD.billing_interval,OLD.paid_subscription_period_start,OLD.paid_subscription_period_end,
      OLD.paid_subscription_invoice_id,OLD.paid_subscription_plan,OLD.paid_subscription_addons_count,OLD.paid_subscription_paid_at,OLD.plan_credit_anchor)
  THEN RAISE EXCEPTION 'Paid subscription coverage is server managed'; END IF;
  IF lower(coalesce(NEW.subscription_status,'')) IN ('canceled','cancelled','incomplete_expired')
    OR (TG_OP = 'UPDATE' AND NEW.stripe_subscription_id IS DISTINCT FROM OLD.stripe_subscription_id) THEN
    NEW.paid_subscription_period_start := NULL; NEW.paid_subscription_period_end := NULL;
    NEW.paid_subscription_invoice_id := NULL; NEW.paid_subscription_plan := NULL;
    NEW.paid_subscription_addons_count := NULL;
    NEW.paid_subscription_paid_at := NULL;
    -- Subscription IDs and cancellation are not monthly allowance boundaries.
    -- The earlier bucket guard resets usage on cancellation; retain the paid
    -- window/consumption so cancel -> replacement cannot refill a spent month.
    IF TG_OP = 'UPDATE' AND OLD.plan_credit_anchor IS NOT NULL AND (
      NEW.stripe_subscription_id IS DISTINCT FROM OLD.stripe_subscription_id
      OR lower(coalesce(OLD.subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired')) THEN
      NEW.plan_credit_anchor := OLD.plan_credit_anchor;
      NEW.plan_credit_period_start := OLD.plan_credit_period_start;
      NEW.plan_credit_period_end := OLD.plan_credit_period_end;
      NEW.plan_credits_used := OLD.plan_credits_used;
      NEW.monthly_credits_used := OLD.monthly_credits_used;
    END IF;
    NEW.billing_interval := 'month';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_cancelled_instance_plan(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_cancelled_instance_plan() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF OLD.status = 'cancelled' AND OLD.completion_reason = 'Cancelled by project manager'
    AND (NEW.status IS DISTINCT FROM 'cancelled'
      OR NEW.completion_reason IS DISTINCT FROM OLD.completion_reason) THEN
    RAISE EXCEPTION 'Cancelled plans cannot be resumed' USING ERRCODE = '23514';
  END IF;
  IF OLD.status = 'cancelled' AND OLD.completion_reason = 'Cancelled by project manager'
    AND NEW.steps IS DISTINCT FROM OLD.steps THEN
    RAISE EXCEPTION 'Cancelled plan step evidence is immutable' USING ERRCODE = '23514';
  END IF;
  IF NEW.status = 'cancelled' AND NEW.completion_reason = 'Cancelled by project manager' AND (
    (NEW.steps IS NOT NULL AND jsonb_typeof(NEW.steps) IS DISTINCT FROM 'array')
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(NEW.steps) = 'array'
      THEN NEW.steps ELSE '[]'::jsonb END) s WHERE jsonb_typeof(s) IS DISTINCT FROM 'object'
      OR s->>'status' IS NULL OR s->>'status' NOT IN ('completed','failed','cancelled','canceled','skipped'))
  ) THEN RAISE EXCEPTION 'Cancelled plans must have terminal steps' USING ERRCODE = '23514'; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_catalog_archive_redeemable_link(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_catalog_archive_redeemable_link() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (NEW.site_id, NEW.reservable_catalog_item_id, NEW.pass_catalog_item_id)
    IS NOT DISTINCT FROM (OLD.site_id, OLD.reservable_catalog_item_id, OLD.pass_catalog_item_id) THEN
    RETURN NEW;
  END IF;
  PERFORM public.catalog_archive_lock_site(NEW.site_id);
  PERFORM i.id FROM public.catalog_items i
    WHERE i.id = NEW.reservable_catalog_item_id AND i.site_id = NEW.site_id
      AND i.status IS DISTINCT FROM 'archived' FOR SHARE NOWAIT;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Redeemable item must be unarchived and belong to the link site' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_catalog_category_archive(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_catalog_category_archive() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.site_id IS DISTINCT FROM OLD.site_id THEN
      RAISE EXCEPTION 'Catalog category identity and site are immutable' USING ERRCODE = '23514';
    END IF;
    IF NEW.status IS NOT DISTINCT FROM OLD.status AND NEW.status = 'active' THEN
      RETURN NEW;
    END IF;
  ELSIF NEW.status = 'active' THEN
    RETURN NEW;
  END IF;

  IF auth.uid() IS NULL OR coalesce(public.current_user_site_role(NEW.site_id), '') NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Only site owners and admins can change category archive state' USING ERRCODE = '42501';
  END IF;
  PERFORM public.catalog_archive_lock_site(NEW.site_id);
  IF TG_OP = 'INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.updated_at := statement_timestamp();
  END IF;
  -- Restoring a category is manager-only and never restores its items.
  RETURN NEW;
END;
$$;


--
-- Name: guard_catalog_import_category_name(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_catalog_import_category_name() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.catalog_archive_lock_site(OLD.site_id);
    RETURN OLD;
  END IF;
  PERFORM public.catalog_archive_lock_site(NEW.site_id);
  RETURN NEW;
END;
$$;


--
-- Name: guard_catalog_item_archive_membership(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_catalog_item_archive_membership() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  site_key uuid;
  ancestor_ids uuid[];
  category_ids uuid[];
BEGIN
  IF TG_OP = 'UPDATE' THEN
    -- Grandfather unrelated edits, including edits of archived or legacy items.
    IF (NEW.id, NEW.site_id, NEW.category_id, NEW.parent_id, NEW.status)
      IS NOT DISTINCT FROM (OLD.id, OLD.site_id, OLD.category_id, OLD.parent_id, OLD.status) THEN
      RETURN NEW;
    END IF;
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'Catalog item identity is immutable' USING ERRCODE = '23514';
    END IF;
  END IF;

  FOR site_key IN SELECT DISTINCT s FROM unnest(ARRAY[
    CASE WHEN TG_OP <> 'INSERT' THEN OLD.site_id END,
    CASE WHEN TG_OP <> 'DELETE' THEN NEW.site_id END
  ]) s WHERE s IS NOT NULL ORDER BY s LOOP
    PERFORM public.catalog_archive_lock_site(site_key);
  END LOOP;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;

  -- Archived inserts/moves also take the gate so the recursive result is complete.
  IF NEW.status IS DISTINCT FROM 'active' THEN RETURN NEW; END IF;

  IF NEW.parent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.catalog_items WHERE id = NEW.parent_id AND site_id = NEW.site_id
  ) THEN
    RAISE EXCEPTION 'Catalog parent must belong to the item site' USING ERRCODE = '23514';
  END IF;
  WITH RECURSIVE ancestors(id, parent_id, category_id) AS (
    SELECT i.id, i.parent_id, i.category_id FROM public.catalog_items i
      WHERE i.site_id = NEW.site_id AND i.id = NEW.parent_id
    UNION
    SELECT i.id, i.parent_id, i.category_id FROM public.catalog_items i
      JOIN ancestors a ON i.id = a.parent_id WHERE i.site_id = NEW.site_id
  ) SELECT coalesce(array_agg(id), ARRAY[]::uuid[]),
      array_append(coalesce(array_agg(category_id), ARRAY[]::uuid[]), NEW.category_id)
    INTO ancestor_ids, category_ids FROM ancestors;

  -- Same gate excludes concurrent status/relationship changes. NOWAIT row locks
  -- also avoid inversions with unrelated edits that deliberately skip the gate.
  PERFORM c.id FROM public.catalog_categories c
    WHERE c.site_id = NEW.site_id AND c.id = ANY(category_ids)
    ORDER BY c.id FOR SHARE NOWAIT;
  IF NEW.category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.catalog_categories WHERE id = NEW.category_id AND site_id = NEW.site_id
  ) THEN
    RAISE EXCEPTION 'Catalog category must belong to the item site' USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM public.catalog_categories
    WHERE site_id = NEW.site_id AND id = ANY(category_ids) AND status = 'archived') THEN
    RAISE EXCEPTION 'Active items cannot belong to an archived category' USING ERRCODE = '23514';
  END IF;
  PERFORM i.id FROM public.catalog_items i
    WHERE i.site_id = NEW.site_id AND i.id = ANY(ancestor_ids)
    ORDER BY i.id FOR SHARE NOWAIT;
  IF EXISTS (SELECT 1 FROM public.catalog_items
    WHERE site_id = NEW.site_id AND id = ANY(ancestor_ids) AND status = 'archived') THEN
    RAISE EXCEPTION 'Active variants cannot belong to an archived parent' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_credit_auto_top_up_card_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_credit_auto_top_up_card_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF NEW.enabled AND NOT EXISTS (
    SELECT 1 FROM public.credit_auto_top_up_card_setups s JOIN public.billing b ON b.site_id=s.site_id
    WHERE s.site_id=NEW.site_id AND s.status='completed'
      AND s.stripe_customer_id=b.stripe_customer_id AND s.stripe_payment_method_id=NEW.stripe_payment_method_id
  ) THEN RAISE EXCEPTION 'Complete the latest card setup before enabling automatic top-up'; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: guard_cron_outcome_instance_binding(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_cron_outcome_instance_binding() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE requirement_site uuid; instance_site uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.requirement_id IS NOT DISTINCT FROM OLD.requirement_id
    AND NEW.runner_instance_id IS NOT DISTINCT FROM OLD.runner_instance_id THEN RETURN NEW; END IF;
  IF NEW.runner_instance_id IS NULL THEN RETURN NEW; END IF;
  SELECT site_id INTO requirement_site FROM public.requirements WHERE id = NEW.requirement_id FOR KEY SHARE;
  SELECT site_id INTO instance_site FROM public.remote_instances WHERE id = NEW.runner_instance_id FOR KEY SHARE;
  IF NOT FOUND OR requirement_site IS NULL OR requirement_site IS DISTINCT FROM instance_site THEN
    RAISE EXCEPTION 'Cron outcome instance is missing or cross-site' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: accounting_validate_journal_lines(uuid, jsonb, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounting_validate_journal_lines(p_site_id uuid, p_lines jsonb, p_existing_id uuid, p_allow_dimensions boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  line jsonb; debit_amount numeric; credit_amount numeric; debit_total numeric := 0;
  credit_total numeric := 0; account_row public.accounting_accounts%ROWTYPE;
  dimension text; dimension_table text; dimension_id uuid; matched uuid;
BEGIN
  IF jsonb_typeof(p_lines) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Journal lines must be an array' USING ERRCODE = '22023';
  END IF;
  IF jsonb_array_length(p_lines) NOT BETWEEN 2 AND 500 THEN
    RAISE EXCEPTION 'A journal requires 2 to 500 lines' USING ERRCODE = '22023';
  END IF;
  FOR line IN SELECT value FROM jsonb_array_elements(p_lines) LOOP
    IF jsonb_typeof(line) IS DISTINCT FROM 'object'
      OR jsonb_typeof(line->'debit') IS DISTINCT FROM 'number'
      OR jsonb_typeof(line->'credit') IS DISTINCT FROM 'number'
      OR jsonb_typeof(line->'account_code') IS DISTINCT FROM 'string'
      OR (line->>'account_code') !~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$' THEN
      RAISE EXCEPTION 'Invalid journal line' USING ERRCODE = '22023';
    END IF;
    debit_amount := (line->>'debit')::numeric;
    credit_amount := (line->>'credit')::numeric;
    IF debit_amount NOT BETWEEN 0 AND 1000000000000 OR credit_amount NOT BETWEEN 0 AND 1000000000000
      OR debit_amount <> trunc(debit_amount, 2) OR credit_amount <> trunc(credit_amount, 2)
      OR NOT ((debit_amount > 0 AND credit_amount = 0) OR (credit_amount > 0 AND debit_amount = 0)) THEN
      RAISE EXCEPTION 'Each line requires exactly one positive two-decimal amount' USING ERRCODE = '22023';
    END IF;
    debit_total := debit_total + debit_amount;
    credit_total := credit_total + credit_amount;
    SELECT * INTO account_row FROM public.accounting_accounts
      WHERE site_id = p_site_id AND code = line->>'account_code' FOR SHARE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Journal account not found in this site' USING ERRCODE = '23514';
    END IF;
    IF account_row.active IS DISTINCT FROM true AND (
      p_existing_id IS NULL OR EXISTS (
        (SELECT l.debit, l.credit FROM public.journal_lines l
          WHERE l.entry_id = p_existing_id AND l.account_code = account_row.code
         EXCEPT ALL
         SELECT (j->>'debit')::numeric, (j->>'credit')::numeric
          FROM jsonb_array_elements(p_lines) j WHERE j->>'account_code' = account_row.code)
        UNION ALL
        (SELECT (j->>'debit')::numeric, (j->>'credit')::numeric
          FROM jsonb_array_elements(p_lines) j WHERE j->>'account_code' = account_row.code
         EXCEPT ALL
         SELECT l.debit, l.credit FROM public.journal_lines l
          WHERE l.entry_id = p_existing_id AND l.account_code = account_row.code)
      )
    ) THEN
      RAISE EXCEPTION 'Inactive account amounts cannot be added or changed' USING ERRCODE = '23514';
    END IF;
    FOREACH dimension IN ARRAY ARRAY['location_id','lead_id','campaign_id','segment_id',
      'catalog_item_id','catalog_category_id','company_id'] LOOP
      IF line->>dimension IS NULL THEN CONTINUE; END IF;
      IF NOT p_allow_dimensions THEN
        RAISE EXCEPTION 'Manual and opening journals do not accept dimensions' USING ERRCODE = '22023';
      END IF;
      dimension_id := (line->>dimension)::uuid;
      dimension_table := CASE dimension WHEN 'location_id' THEN 'locations' WHEN 'lead_id' THEN 'leads'
        WHEN 'campaign_id' THEN 'campaigns' WHEN 'segment_id' THEN 'segments'
        WHEN 'catalog_item_id' THEN 'catalog_items' WHEN 'catalog_category_id' THEN 'catalog_categories'
        WHEN 'company_id' THEN 'companies' END;
      matched := NULL;
      -- Companies are a global registry, not tenant-owned. The source RPC checks
      -- their identity against the locked source; standalone journals forbid dimensions.
      IF dimension = 'company_id' THEN
        SELECT id INTO matched FROM public.companies WHERE id = dimension_id FOR SHARE;
      ELSE
        EXECUTE format('SELECT id FROM public.%I WHERE id = $1 AND site_id = $2 FOR SHARE', dimension_table)
          INTO matched USING dimension_id, p_site_id;
      END IF;
      IF matched IS NULL THEN
        RAISE EXCEPTION 'Invalid journal dimension for this site' USING ERRCODE = '23514';
      END IF;
    END LOOP;
  END LOOP;
  IF p_existing_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.journal_lines l JOIN public.accounting_accounts a
      ON a.site_id = p_site_id AND a.code = l.account_code
    WHERE l.entry_id = p_existing_id AND a.active IS DISTINCT FROM true
      AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(p_lines) j WHERE j->>'account_code' = a.code)
  ) THEN
    RAISE EXCEPTION 'Inactive account amounts cannot be removed' USING ERRCODE = '23514';
  END IF;
  IF debit_total <= 0 OR debit_total <> credit_total THEN
    RAISE EXCEPTION 'Journal debits and credits must balance exactly' USING ERRCODE = '23514';
  END IF;
END;
$_$;


--
-- Name: acquire_deployment_recovery_scan_lease(text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acquire_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text, p_ttl_seconds integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_acquired boolean := false;
BEGIN
  IF NULLIF(btrim(p_lease_key), '') IS NULL
    OR NULLIF(btrim(p_owner_id), '') IS NULL
  THEN
    RAISE EXCEPTION 'Lease key and owner are required';
  END IF;
  IF p_ttl_seconds IS NULL OR p_ttl_seconds < 1 OR p_ttl_seconds > 3600 THEN
    RAISE EXCEPTION 'Lease TTL must be between 1 and 3600 seconds';
  END IF;

  INSERT INTO public.deployment_recovery_scan_leases (
    lease_key,
    owner_id,
    expires_at,
    updated_at
  )
  VALUES (
    p_lease_key,
    p_owner_id,
    timezone('utc', now()) + make_interval(secs => p_ttl_seconds),
    timezone('utc', now())
  )
  ON CONFLICT (lease_key) DO UPDATE
  SET
    owner_id = EXCLUDED.owner_id,
    expires_at = EXCLUDED.expires_at,
    updated_at = EXCLUDED.updated_at
  WHERE deployment_recovery_scan_leases.expires_at <= timezone('utc', now())
    OR deployment_recovery_scan_leases.owner_id = EXCLUDED.owner_id
  RETURNING true INTO v_acquired;

  RETURN COALESCE(v_acquired, false);
END;
$$;


--
-- Name: activate_pending_site_memberships(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.activate_pending_site_memberships() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  updated_count INTEGER := 0;
  site_record RECORD;
BEGIN
  -- Solo procesar en INSERT (nuevo perfil creado)
  IF TG_OP = 'INSERT' AND NEW.email IS NOT NULL THEN
    BEGIN
      -- Verificar que la tabla site_members existe antes de usarla
      IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'site_members' 
          AND table_schema = 'public'
      ) THEN
        
        -- Procesar cada invitación pendiente por separado
        FOR site_record IN 
          SELECT id, site_id, email 
          FROM public.site_members 
          WHERE email = NEW.email 
            AND status = 'pending' 
            AND user_id IS NULL
        LOOP
          BEGIN
            -- Verificar si ya existe un registro activo para este user_id y site_id
            IF NOT EXISTS (
              SELECT 1 FROM public.site_members 
              WHERE site_id = site_record.site_id 
                AND user_id = NEW.id 
                AND status = 'active'
            ) THEN
              -- Actualizar el registro pendiente
              UPDATE public.site_members
              SET 
                user_id = NEW.id,
                status = 'active',
                updated_at = NOW()
              WHERE id = site_record.id;
              
              updated_count := updated_count + 1;
              
              RAISE NOTICE 'Activated site membership for user % on site % (email: %)', 
                           NEW.id, site_record.site_id, NEW.email;
            ELSE
              -- Ya existe un registro activo, eliminar el pendiente
              DELETE FROM public.site_members WHERE id = site_record.id;
              
              RAISE NOTICE 'Removed duplicate pending membership for user % on site %', 
                           NEW.id, site_record.site_id;
            END IF;
            
          EXCEPTION
            WHEN unique_violation THEN
              -- Si hay violación de constraint único, eliminar el pendiente
              DELETE FROM public.site_members WHERE id = site_record.id;
              RAISE WARNING 'Removed conflicting site member record for % on site %', 
                            NEW.email, site_record.site_id;
              
            WHEN OTHERS THEN
              RAISE WARNING 'Error processing site member % for %: %', 
                            site_record.id, NEW.email, SQLERRM;
          END;
        END LOOP;
        
        IF updated_count > 0 THEN
          RAISE NOTICE 'Total activated memberships: % for user %', updated_count, NEW.email;
        END IF;
        
      ELSE
        RAISE NOTICE 'Table site_members does not exist, skipping membership activation';
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but don't fail profile creation
        RAISE WARNING 'General error activating site memberships for %: %', 
                      NEW.email, SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: activate_requirement_cron_run(uuid, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.activate_requirement_cron_run(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer DEFAULT 7200) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_result jsonb;
  v_requirement public.requirements%ROWTYPE;
  v_runner text;
BEGIN
  v_result := public.activate_requirement_cron_run_before_assistant_handoff(
    p_requirement_id, p_run_id, p_max_concurrent, p_ttl_seconds);
  IF v_result->>'state' <> 'active' THEN RETURN v_result; END IF;
  SELECT * INTO v_requirement FROM public.requirements WHERE id = p_requirement_id;
  v_runner := v_requirement.metadata->>'runner_instance_id';
  IF COALESCE(v_requirement.status, '') NOT IN ('backlog', 'in-progress')
    OR v_requirement.cron_lock_expires_at <= clock_timestamp()
    OR COALESCE((SELECT plan.status FROM public.instance_plans AS plan
      WHERE plan.instance_id::text = v_runner
        AND plan.status IN ('pending', 'in_progress', 'active', 'paused')
      ORDER BY plan.created_at DESC, plan.id DESC LIMIT 1), '') = 'paused'
    OR (v_runner IS NOT NULL AND EXISTS (SELECT 1 FROM public.requirements AS other
      WHERE other.id <> p_requirement_id AND other.metadata->>'runner_instance_id' = v_runner
        AND other.cron_lock_active IS TRUE AND other.cron_lock_run_id IS NOT NULL
        AND other.cron_lock_expires_at > clock_timestamp()))
    OR (v_runner IS NOT NULL AND NOT (public.inspect_requirement_assistant_handoff(
      p_requirement_id, v_runner::uuid)->>'allowed')::boolean)
  THEN
    UPDATE public.requirements SET cron_lock_active = false
      WHERE id = p_requirement_id AND cron_lock_run_id = p_run_id;
    RETURN jsonb_build_object('state', 'stale');
  END IF;
  RETURN v_result;
END;
$$;


--
-- Name: activate_requirement_cron_run_before_assistant_handoff(uuid, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.activate_requirement_cron_run_before_assistant_handoff(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer DEFAULT 7200) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_now timestamptz := now();
  v_lock_run_id text;
  v_lock_expires_at timestamptz;
  v_lock_active boolean;
  v_active integer;
BEGIN
  IF p_max_concurrent IS NULL
    OR p_max_concurrent < 1
    OR p_max_concurrent > 100
  THEN
    RAISE EXCEPTION 'Maximum concurrent requirement runs must be between 1 and 100';
  END IF;
  IF p_ttl_seconds IS NULL
    OR p_ttl_seconds < 60
    OR p_ttl_seconds > 86400
  THEN
    RAISE EXCEPTION 'Requirement lock TTL must be between 60 and 86400 seconds';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('requirement-cron-global-capacity', 0)
  );

  SELECT
    cron_lock_run_id,
    cron_lock_expires_at,
    cron_lock_active
  INTO
    v_lock_run_id,
    v_lock_expires_at,
    v_lock_active
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;

  IF NOT FOUND
    OR v_lock_run_id IS DISTINCT FROM p_run_id
    OR v_lock_expires_at IS NULL
    OR v_lock_expires_at <= v_now
  THEN
    RETURN jsonb_build_object('state', 'stale');
  END IF;

  SELECT count(*)::integer
  INTO v_active
  FROM public.requirements
  WHERE cron_lock_expires_at > v_now
    AND cron_lock_active = true;

  IF v_lock_active THEN
    RETURN jsonb_build_object(
      'state', 'active',
      'active_runs', v_active
    );
  END IF;

  IF v_active >= p_max_concurrent THEN
    RETURN jsonb_build_object(
      'state', 'capacity_full',
      'active_runs', v_active
    );
  END IF;

  UPDATE public.requirements
  SET
    cron_lock_active = true,
    cron_lock_expires_at =
      v_now + pg_catalog.make_interval(secs => p_ttl_seconds)
  WHERE id = p_requirement_id
    AND cron_lock_run_id = p_run_id;

  RETURN jsonb_build_object(
    'state', 'active',
    'active_runs', v_active + 1
  );
END;
$$;


--
-- Name: add_balance(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_balance(p_site_id uuid, p_amount numeric) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_balance numeric;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be greater than zero';
  END IF;

  INSERT INTO public.billing (site_id, account_balance)
  VALUES (p_site_id, p_amount)
  ON CONFLICT (site_id)
  DO UPDATE SET
    account_balance = coalesce(public.billing.account_balance, 0) + EXCLUDED.account_balance,
    updated_at = now()
  RETURNING account_balance INTO v_balance;

  RETURN v_balance;
END;
$$;


--
-- Name: add_command_id_to_all_tables(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_command_id_to_all_tables() RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    rec RECORD;
    sql_text TEXT;
BEGIN
    -- Implementation depends on the original function logic
    -- This is a placeholder that should be updated with the actual logic
    RAISE NOTICE 'add_command_id_to_all_tables function secured with search_path';
END;
$$;


--
-- Name: add_credits(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_credits(p_site_id uuid, p_credits integer) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  RAISE EXCEPTION 'Unclassified additive credits are disabled; use a classified idempotent grant RPC';
END;
$$;


--
-- Name: add_credits(uuid, numeric, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount::text IN ('NaN','Infinity','-Infinity')
    OR jsonb_typeof(p_metadata) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Invalid credit amount'; END IF;
  IF p_type IN ('initial_credit','credit_renewal','stripe_subscription_invoice','subscription_renewal_recovery','plan_credit_reset') THEN
    RAISE EXCEPTION 'Plan credits require an idempotent plan-period RPC';
  END IF;
  IF p_type = 'credits_purchase' THEN
    RETURN public.grant_purchased_site_credits(p_site_id,p_amount,p_metadata->>'idempotency_key',p_metadata);
  END IF;
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('success',false,'error','Billing record not found'); END IF;
  UPDATE public.billing SET legacy_credits_available = legacy_credits_available + p_amount,
    credits_available = credits_available + p_amount WHERE id = b.id;
  INSERT INTO public.credit_transactions(site_id,amount,transaction_type,description,metadata)
    VALUES (p_site_id,p_amount,p_type,p_description,p_metadata || jsonb_build_object('credit_bucket','legacy'));
  RETURN jsonb_build_object('success',true,'new_balance',b.credits_available + p_amount);
END;
$$;


--
-- Name: add_delete_protection_trigger(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_delete_protection_trigger(p_table_name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16695($1); RETURN; END$_$;


--
-- Name: add_to_waitlist(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_to_waitlist(email_param text, name_param text DEFAULT NULL::text, referral_code_param text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16696($1,$2,$3); END$_$;

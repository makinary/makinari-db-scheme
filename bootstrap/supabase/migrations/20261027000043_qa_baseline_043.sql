SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: location_acl_visible_sale_order_items(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_sale_order_items() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_order_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_order_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.sale_order_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sale_orders WHERE id=NEW.sale_order_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'shipment_id' IS DISTINCT FROM to_jsonb(NEW)->'shipment_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.shipment_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.shipments WHERE id=NEW.shipment_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_sale_orders(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_sale_orders() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'quotation_id' IS DISTINCT FROM to_jsonb(NEW)->'quotation_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.quotation_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.quotations WHERE id=NEW.quotation_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.sale_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sales WHERE id=NEW.sale_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_sales(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_sales() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'quotation_id' IS DISTINCT FROM to_jsonb(NEW)->'quotation_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.quotation_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.quotations WHERE id=NEW.quotation_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'subscription_id' IS DISTINCT FROM to_jsonb(NEW)->'subscription_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.subscription_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.subscriptions WHERE id=NEW.subscription_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_shipment_location_pings(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_shipment_location_pings() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'shipment_id' IS DISTINCT FROM to_jsonb(NEW)->'shipment_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.shipment_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.shipments WHERE id=NEW.shipment_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_shipments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_shipments() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'origin_location_id' IS DISTINCT FROM to_jsonb(NEW)->'origin_location_id') AND NEW.sale_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sales WHERE id=NEW.sale_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_order_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_order_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'origin_location_id' IS DISTINCT FROM to_jsonb(NEW)->'origin_location_id') AND NEW.sale_order_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sale_orders WHERE id=NEW.sale_order_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_task_categories(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_task_categories() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'task_id' IS DISTINCT FROM to_jsonb(NEW)->'task_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.task_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.tasks WHERE id=NEW.task_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_task_comments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_task_comments() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'task_id' IS DISTINCT FROM to_jsonb(NEW)->'task_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id') AND NEW.task_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.tasks WHERE id=NEW.task_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_tasks(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_tasks() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'conversation_id' IS DISTINCT FROM to_jsonb(NEW)->'conversation_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.conversation_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.conversations WHERE id=NEW.conversation_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'deal_id' IS DISTINCT FROM to_jsonb(NEW)->'deal_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.deal_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.deals WHERE id=NEW.deal_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'lead_id' IS DISTINCT FROM to_jsonb(NEW)->'lead_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.lead_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.leads WHERE id=NEW.lead_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: location_acl_visible_transactions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_acl_visible_transactions() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN IF current_setting('role',true) <> 'authenticated' THEN RETURN NEW; END IF; IF (TG_OP='INSERT' OR to_jsonb(OLD)->'sale_order_id' IS DISTINCT FROM to_jsonb(NEW)->'sale_order_id'
        OR to_jsonb(OLD)->'site_id' IS DISTINCT FROM to_jsonb(NEW)->'site_id' OR to_jsonb(OLD)->'location_id' IS DISTINCT FROM to_jsonb(NEW)->'location_id') AND NEW.sale_order_id IS NOT NULL AND NOT EXISTS
        (SELECT 1 FROM public.sale_orders WHERE id=NEW.sale_order_id) THEN
        RAISE EXCEPTION 'Operational parent unavailable' USING ERRCODE='42501'; END IF; RETURN NEW; END$$;


--
-- Name: lock_harness_host_owner(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lock_harness_host_owner(p_id uuid, p_site_id uuid, p_owner text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE r public.harness_sessions%ROWTYPE;
BEGIN
  IF p_id IS NULL OR p_site_id IS NULL OR p_owner IS NULL OR length(btrim(p_owner)) = 0 OR length(p_owner) > 200
  THEN RAISE EXCEPTION 'Invalid harness host scope' USING ERRCODE='22023'; END IF;
  SELECT * INTO r FROM public.harness_sessions WHERE id=p_id AND site_id=p_site_id FOR UPDATE;
  IF NOT FOUND OR r.lease_owner IS DISTINCT FROM p_owner OR r.lease_expires_at IS NULL
    OR r.lease_expires_at <= clock_timestamp() OR r.snapshot->>'status' IS DISTINCT FROM 'running'
  THEN RAISE EXCEPTION 'Harness host ownership conflict' USING ERRCODE='P0002'; END IF;
END;
$$;


--
-- Name: requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    priority text NOT NULL,
    status text NOT NULL,
    completion_status text NOT NULL,
    source text,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    budget numeric,
    instructions text,
    command_id uuid,
    type public.requirement_type DEFAULT 'task'::public.requirement_type,
    metadata jsonb DEFAULT '{}'::jsonb,
    cron text,
    cycle text,
    cron_lock_expires_at timestamp with time zone,
    cron_lock_run_id text,
    backlog jsonb DEFAULT '{}'::jsonb NOT NULL,
    progress jsonb DEFAULT '[]'::jsonb NOT NULL,
    backlog_revision bigint DEFAULT 0 NOT NULL,
    cron_lock_active boolean DEFAULT false NOT NULL,
    external_user_action_revision bigint DEFAULT 0 NOT NULL,
    last_external_user_action_id text,
    CONSTRAINT requirements_completion_status_check CHECK ((completion_status = ANY (ARRAY['pending'::text, 'completed'::text, 'rejected'::text]))),
    CONSTRAINT requirements_priority_check CHECK ((priority = ANY (ARRAY['high'::text, 'medium'::text, 'low'::text]))),
    CONSTRAINT requirements_status_check CHECK ((status = ANY (ARRAY['validated'::text, 'in-progress'::text, 'on-review'::text, 'done'::text, 'backlog'::text, 'canceled'::text, 'cancelled'::text, 'blocked'::text])))
);


--
-- Name: lock_migration_reconciliation_scope(uuid, text, uuid, uuid, text, integer, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lock_migration_reconciliation_scope(p_requirement_id uuid, p_file text, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_generation integer, p_backlog_revision bigint) RETURNS public.requirements
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  r public.requirements%ROWTYPE;
  i public.remote_instances%ROWTYPE;
  p public.instance_plans%ROWTYPE;
  s jsonb;
  b jsonb;
  v_item_id text;
  v_generation text;
BEGIN
  SELECT * INTO r FROM public.requirements WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reconciliation requirement missing' USING ERRCODE = 'P0002'; END IF;
  IF r.status IS DISTINCT FROM 'blocked' OR r.cron_lock_active IS DISTINCT FROM false
    OR r.cron_lock_expires_at > clock_timestamp() THEN
    RAISE EXCEPTION 'Reconciliation requires an idle blocked requirement' USING ERRCODE = '40001';
  END IF;
  IF jsonb_typeof(r.metadata) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid reconciliation metadata' USING ERRCODE = '22023';
  END IF;
  v_generation := COALESCE(r.metadata->>'requirement_execution_generation', '0');
  IF (r.metadata ? 'requirement_execution_generation' AND r.metadata->'requirement_execution_generation' = 'null'::jsonb)
    OR v_generation !~ '^(0|[1-9][0-9]{0,9})$' THEN
    RAISE EXCEPTION 'Invalid reconciliation generation' USING ERRCODE = '22023';
  END IF;
  IF v_generation::bigint IS DISTINCT FROM p_generation::bigint
    OR r.backlog_revision IS DISTINCT FROM p_backlog_revision THEN
    RAISE EXCEPTION 'Stale reconciliation generation or backlog' USING ERRCODE = '40001';
  END IF;
  IF r.metadata->>'runner_instance_id' IS DISTINCT FROM p_instance_id::text THEN
    RAISE EXCEPTION 'Reconciliation owner changed' USING ERRCODE = '40001';
  END IF;
  PERFORM 1 FROM public.requirement_migration_lifecycle WHERE requirement_id = r.id ORDER BY file FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_diagnostics WHERE requirement_id = r.id AND file = p_file) THEN
    RAISE EXCEPTION 'Migration diagnosis already exists' USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM public.requirement_migration_lifecycle
    WHERE requirement_id = r.id AND file <> p_file AND state <> 'validated') THEN
    RAISE EXCEPTION 'Requirement has another unresolved migration' USING ERRCODE = '23514';
  END IF;
  SELECT * INTO i FROM public.remote_instances WHERE id = p_instance_id FOR UPDATE;
  IF NOT FOUND OR i.site_id IS DISTINCT FROM r.site_id OR i.is_archived IS TRUE
    OR COALESCE(i.status, '') NOT IN ('pending', 'running') THEN
    RAISE EXCEPTION 'Reconciliation instance is not eligible' USING ERRCODE = '40001';
  END IF;
  PERFORM 1 FROM public.instance_plans
    WHERE instance_id = i.id OR metadata->>'requirement_id' = r.id::text ORDER BY id FOR UPDATE;
  SELECT * INTO p FROM public.instance_plans WHERE id = p_plan_id;
  IF NOT FOUND OR p.instance_id IS DISTINCT FROM i.id OR p.site_id IS DISTINCT FROM r.site_id
    OR p.metadata->>'requirement_id' IS DISTINCT FROM r.id::text
    OR COALESCE(p.metadata->>'workflow_template', 'false') <> 'false'
    OR COALESCE(p.status, '') NOT IN ('pending', 'in_progress', 'active')
    OR jsonb_typeof(p.steps) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Reconciliation plan is not eligible' USING ERRCODE = '40001';
  END IF;
  IF EXISTS (SELECT 1 FROM public.instance_plans AS other
    WHERE other.id <> p.id AND (other.instance_id = i.id OR other.metadata->>'requirement_id' = r.id::text)
      AND COALESCE(other.metadata->>'workflow_template', 'false') <> 'true'
      AND (COALESCE(other.status, '') NOT IN ('completed', 'cancelled', 'failed')
        OR EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(other.steps) = 'array'
          THEN other.steps ELSE '[{}]'::jsonb END) AS step
          WHERE COALESCE(step->>'status', '') NOT IN ('completed', 'cancelled', 'failed')))) THEN
    RAISE EXCEPTION 'Competing reconciliation plan' USING ERRCODE = '40001';
  END IF;
  IF (SELECT count(*) FROM jsonb_array_elements(p.steps) AS step WHERE step->>'id' = p_step_id) <> 1 THEN
    RAISE EXCEPTION 'Reconciliation step missing or ambiguous' USING ERRCODE = '23514';
  END IF;
  SELECT step INTO s FROM jsonb_array_elements(p.steps) AS step WHERE step->>'id' = p_step_id;
  IF s->>'status' IS DISTINCT FROM 'pending' OR s->'requires_sandbox' IS DISTINCT FROM 'true'::jsonb
    OR p.steps->-1->>'id' IS DISTINCT FROM p_step_id
    OR (s ? 'metadata' AND jsonb_typeof(s->'metadata') IS DISTINCT FROM 'object')
    OR COALESCE(s->'metadata', '{}'::jsonb) ?| ARRAY['migration_correction_key','migration_diagnostic_token',
      'migration_diagnostic_file','migration_correction_run_id','migration_correction_files','repair_run','repair_source_step_id']
    OR COALESCE(s->'infrastructure_circuit_open', 'false'::jsonb) <> 'false'::jsonb
    OR COALESCE(s->'infrastructure_waiting', 'false'::jsonb) <> 'false'::jsonb
    OR COALESCE(s->'infrastructure_intervention_required', 'false'::jsonb) <> 'false'::jsonb
    OR COALESCE(s->>'infrastructure_state', 'ready') NOT IN ('ready', 'healthy')
    OR NULLIF(s->>'infra_retry_after', '') IS NOT NULL
    OR COALESCE(s->>'infra_retry_count', '0') !~ '^[0-3]$'
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(p.steps) AS step
      WHERE step->>'id' IS DISTINCT FROM p_step_id AND COALESCE(step->>'status', '') NOT IN ('completed', 'cancelled')) THEN
    RAISE EXCEPTION 'Reconciliation step is not pending and runnable' USING ERRCODE = '23514';
  END IF;
  v_item_id := COALESCE(s#>>'{metadata,backlog_item_id}', s->>'backlog_item_id');
  IF NULLIF(v_item_id, '') IS NULL OR (s ? 'backlog_item_id' AND s#>>'{metadata,backlog_item_id}' IS NOT NULL
      AND s->>'backlog_item_id' IS DISTINCT FROM s#>>'{metadata,backlog_item_id}')
    OR jsonb_typeof(r.backlog->'items') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Reconciliation backlog binding invalid' USING ERRCODE = '23514';
  END IF;
  IF (SELECT count(*) FROM jsonb_array_elements(r.backlog->'items') AS item WHERE item->>'id' = v_item_id) <> 1 THEN
    RAISE EXCEPTION 'Reconciliation backlog item missing or ambiguous' USING ERRCODE = '23514';
  END IF;
  SELECT item INTO b FROM jsonb_array_elements(r.backlog->'items') AS item WHERE item->>'id' = v_item_id;
  IF COALESCE(b->>'status', '') NOT IN ('pending', 'in_progress')
    OR COALESCE(b->'blocked_by', '[]'::jsonb) <> '[]'::jsonb
    OR COALESCE(b#>'{review_quarantine,active}', 'false'::jsonb) <> 'false'::jsonb
    OR COALESCE(b->'plan_cancellation_pending', 'null'::jsonb) <> 'null'::jsonb
    OR COALESCE(b->>'attempts', '') !~ '^[0-9]{1,9}$'
    OR jsonb_typeof(COALESCE(b->'depends_on', '[]'::jsonb)) <> 'array' THEN
    RAISE EXCEPTION 'Reconciliation backlog item is not runnable' USING ERRCODE = '23514';
  END IF;
  -- Conservative defaults from requirement-flows (core 4, ornamental 2);
  -- operators must also honor stricter deployment limits. No budget is reset.
  IF (b->>'attempts')::integer >= (CASE WHEN b->>'tier' = 'ornamental' THEN 2 ELSE 4 END)
    OR EXISTS (SELECT 1 FROM jsonb_array_elements_text(COALESCE(b->'depends_on', '[]'::jsonb)) AS dep(id)
      WHERE (SELECT count(*) FROM jsonb_array_elements(r.backlog->'items') AS item
        WHERE item->>'id' = dep.id AND item->>'status' = 'done') <> 1) THEN
    RAISE EXCEPTION 'Reconciliation backlog budget or dependencies blocked' USING ERRCODE = '23514';
  END IF;
  RETURN r;
END;
$_$;


--
-- Name: requirement_migration_lifecycle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_migration_lifecycle (
    requirement_id uuid NOT NULL,
    file text NOT NULL,
    version integer NOT NULL,
    state text NOT NULL,
    checksum text NOT NULL,
    specification_checksum text NOT NULL,
    original_sql text,
    reason text NOT NULL,
    review jsonb,
    attempts integer NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT requirement_migration_lifecycle_attempts_check CHECK (((attempts >= 0) AND (attempts <= 5))),
    CONSTRAINT requirement_migration_lifecycle_checksum_check CHECK ((checksum ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT requirement_migration_lifecycle_file_check CHECK (((octet_length(file) <= 512) AND (file ~ '^(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*\.sql$'::text))),
    CONSTRAINT requirement_migration_lifecycle_original_sql_check CHECK ((octet_length(original_sql) <= 65536)),
    CONSTRAINT requirement_migration_lifecycle_reason_check CHECK ((char_length(reason) <= 2048)),
    CONSTRAINT requirement_migration_lifecycle_specification_checksum_check CHECK ((specification_checksum ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT requirement_migration_lifecycle_state_check CHECK ((state = ANY (ARRAY['correction_required'::text, 'reviewing'::text, 'validation_pending'::text, 'validated'::text, 'platform_review'::text, 'transferred'::text]))),
    CONSTRAINT requirement_migration_lifecycle_version_check CHECK ((version > 0))
);


--
-- Name: lock_requirement_migration_diagnostic_scope(uuid, text, integer, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lock_requirement_migration_diagnostic_scope(p_requirement_id uuid, p_file text, p_execution_generation integer, p_run_id text, p_require_cron_owner boolean) RETURNS public.requirement_migration_lifecycle
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_requirement public.requirements%ROWTYPE;
  v_lifecycle public.requirement_migration_lifecycle%ROWTYPE;
  v_generation_text text;
  v_generation integer;
BEGIN
  IF p_requirement_id IS NULL OR p_file IS NULL OR octet_length(p_file) > 512
    OR p_file !~ '^(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*\.sql$'
    OR p_execution_generation IS NULL OR p_execution_generation < 0
    OR p_require_cron_owner IS NULL
    OR (p_require_cron_owner AND NULLIF(btrim(p_run_id), '') IS NULL)
  THEN
    RAISE EXCEPTION 'Invalid migration diagnostic scope' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_requirement FROM public.requirements
    WHERE id = p_requirement_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Migration requirement does not exist' USING ERRCODE = 'P0002';
  END IF;
  -- Same strict generation decoding as the ordinary lifecycle transition.
  IF v_requirement.metadata IS NOT NULL AND jsonb_typeof(v_requirement.metadata) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Invalid requirement execution generation' USING ERRCODE = '22023';
  END IF;
  IF COALESCE(v_requirement.metadata ? 'requirement_execution_generation', false) THEN
    v_generation_text := v_requirement.metadata->>'requirement_execution_generation';
    IF v_generation_text IS NULL OR v_generation_text !~ '^(0|[1-9][0-9]{0,9})$' THEN
      RAISE EXCEPTION 'Invalid requirement execution generation' USING ERRCODE = '22023';
    END IF;
    IF v_generation_text::bigint > 2147483647 THEN
      RAISE EXCEPTION 'Invalid requirement execution generation' USING ERRCODE = '22023';
    END IF;
    v_generation := v_generation_text::integer;
  ELSE
    v_generation := 0;
  END IF;
  IF v_generation IS DISTINCT FROM p_execution_generation THEN
    RAISE EXCEPTION 'Stale requirement execution generation' USING ERRCODE = '40001';
  END IF;
  IF COALESCE(v_requirement.status, '') NOT IN ('backlog', 'in-progress')
    OR EXISTS (SELECT 1 FROM public.remote_instances AS instance
      WHERE instance.id::text = v_requirement.metadata->>'runner_instance_id'
        AND (instance.status IN ('paused', 'stopped', 'stopping') OR instance.is_archived IS TRUE))
    OR COALESCE((SELECT plan.status FROM public.instance_plans AS plan
      WHERE plan.instance_id::text = v_requirement.metadata->>'runner_instance_id'
        AND plan.status IN ('pending', 'in_progress', 'active', 'paused')
      ORDER BY plan.created_at DESC, plan.id DESC LIMIT 1), '') = 'paused'
  THEN
    RAISE EXCEPTION 'Migration diagnostic requirement is not runnable' USING ERRCODE = '40001';
  END IF;
  IF p_require_cron_owner AND (
    public.assert_requirement_cron_execution_owner(
      p_requirement_id, p_run_id, p_execution_generation, false, false
    )->'current' IS DISTINCT FROM 'true'::jsonb
  ) THEN
    RAISE EXCEPTION 'Stale migration diagnostic execution owner' USING ERRCODE = '40001';
  END IF;
  SELECT * INTO v_lifecycle FROM public.requirement_migration_lifecycle
    WHERE requirement_id = p_requirement_id AND file = p_file FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Migration lifecycle does not exist' USING ERRCODE = 'P0002';
  END IF;
  IF v_lifecycle.state <> 'correction_required' OR v_lifecycle.attempts <> 5 THEN
    RAISE EXCEPTION 'Migration diagnostic requires exhausted historical budget in correction_required' USING ERRCODE = '23514';
  END IF;
  RETURN v_lifecycle;
END;
$_$;


--
-- Name: lock_site_license(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lock_site_license(p_site_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  -- REPEATABLE READ could reuse a pre-lock membership snapshot. Fail closed.
  IF current_setting('transaction_isolation') = 'repeatable read' THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'License writes require READ COMMITTED or SERIALIZABLE';
  END IF;
  PERFORM 1 FROM public.sites WHERE id = p_site_id FOR UPDATE;
END;
$$;


--
-- Name: log_asset_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_asset_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  -- Crear una tabla de logs si no existe
  CREATE TABLE IF NOT EXISTS public.debug_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation TEXT,
    user_id UUID,
    site_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  
  -- Registrar el intento de inserción
  INSERT INTO public.debug_logs (operation, user_id, site_id, details)
  VALUES (
    'asset_insert',
    NEW.user_id,
    NEW.site_id,
    jsonb_build_object(
      'auth_uid', auth.uid(),
      'has_site_access', public.user_has_access_to_site(NEW.user_id, NEW.site_id),
      'asset_name', NEW.name
    )
  );
  
  RETURN NEW;
END;
$$;


--
-- Name: log_debug(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_debug(message text) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  RAISE NOTICE '[DEBUG] %', message;
  -- También podríamos insertar en una tabla de logs si fuera necesario
END;
$$;

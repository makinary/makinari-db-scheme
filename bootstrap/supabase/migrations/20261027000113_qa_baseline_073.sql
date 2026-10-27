SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: harness_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_sessions (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    snapshot jsonb NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    lease_owner text,
    lease_expires_at timestamp with time zone,
    sandbox_cleanup_token uuid,
    sandbox_cleanup_resource text,
    sandbox_cleanup_started_at timestamp with time zone,
    CONSTRAINT harness_cleanup_pair CHECK ((((sandbox_cleanup_token IS NULL) = (sandbox_cleanup_resource IS NULL)) AND ((sandbox_cleanup_token IS NULL) = (sandbox_cleanup_started_at IS NULL)))),
    CONSTRAINT harness_lease_pair CHECK (((lease_owner IS NULL) = (lease_expires_at IS NULL))),
    CONSTRAINT harness_owner_bound CHECK (((lease_owner IS NULL) OR ((length(btrim(lease_owner)) > 0) AND (length(lease_owner) <= 200)))),
    CONSTRAINT harness_sessions_version_check CHECK (((version >= 0) AND (version <= '9007199254740991'::bigint))),
    CONSTRAINT harness_snapshot_identity CHECK ((((snapshot ->> 'id'::text) = (id)::text) AND (((snapshot ->> 'version'::text))::numeric = (version)::numeric))),
    CONSTRAINT harness_snapshot_valid CHECK (public.valid_harness_snapshot(snapshot))
);


--
-- Name: icp_dispatch_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icp_dispatch_config (
    id boolean DEFAULT true NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    max_concurrency integer DEFAULT 3 NOT NULL,
    slice_candidates integer DEFAULT 10 NOT NULL,
    daily_candidate_limit integer DEFAULT 3000 NOT NULL,
    CONSTRAINT icp_dispatch_config_daily_candidate_limit_check CHECK (((daily_candidate_limit >= 1) AND (daily_candidate_limit <= 3000))),
    CONSTRAINT icp_dispatch_config_id_check CHECK (id),
    CONSTRAINT icp_dispatch_config_max_concurrency_check CHECK (((max_concurrency >= 1) AND (max_concurrency <= 10))),
    CONSTRAINT icp_dispatch_config_slice_candidates_check CHECK (((slice_candidates >= 1) AND (slice_candidates <= 10)))
);


--
-- Name: icp_dispatch_list_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icp_dispatch_list_state (
    icp_mining_id uuid NOT NULL,
    site_id uuid NOT NULL,
    last_dispatched_at timestamp with time zone,
    next_eligible_at timestamp with time zone,
    failure_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT icp_dispatch_list_state_failure_count_check CHECK ((failure_count >= 0))
);


--
-- Name: icp_dispatch_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icp_dispatch_runs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    icp_mining_id uuid NOT NULL,
    dispatch_key text NOT NULL,
    workflow_id text NOT NULL,
    run_id uuid,
    budget_day date NOT NULL,
    state text DEFAULT 'reserved'::text NOT NULL,
    target_limit integer NOT NULL,
    candidate_limit integer NOT NULL,
    research_enabled boolean NOT NULL,
    baseline_processed integer,
    baseline_found integer,
    reserved_candidates integer NOT NULL,
    reserved_matches integer NOT NULL,
    processed integer DEFAULT 0 NOT NULL,
    found integer DEFAULT 0 NOT NULL,
    error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT icp_dispatch_runs_baseline_found_check CHECK ((baseline_found >= 0)),
    CONSTRAINT icp_dispatch_runs_baseline_processed_check CHECK ((baseline_processed >= 0)),
    CONSTRAINT icp_dispatch_runs_check CHECK ((((candidate_limit >= 1) AND (candidate_limit <= 3000)) AND (candidate_limit <= (target_limit * 10)))),
    CONSTRAINT icp_dispatch_runs_check1 CHECK ((((reserved_candidates >= 1) AND (reserved_candidates <= 10)) AND (reserved_candidates <= candidate_limit))),
    CONSTRAINT icp_dispatch_runs_check2 CHECK ((((reserved_matches >= 1) AND (reserved_matches <= 10)) AND (reserved_matches <= reserved_candidates) AND (reserved_matches <= target_limit))),
    CONSTRAINT icp_dispatch_runs_check3 CHECK (((processed >= 0) AND (processed <= reserved_candidates))),
    CONSTRAINT icp_dispatch_runs_check4 CHECK ((((found >= 0) AND (found <= reserved_matches)) AND (found <= processed))),
    CONSTRAINT icp_dispatch_runs_check5 CHECK (((baseline_processed IS NULL) = (baseline_found IS NULL))),
    CONSTRAINT icp_dispatch_runs_check6 CHECK (((state <> ALL (ARRAY['running'::text, 'settled'::text])) OR ((run_id IS NOT NULL) AND (baseline_processed IS NOT NULL)))),
    CONSTRAINT icp_dispatch_runs_check7 CHECK (((state = 'settled'::text) OR ((processed = 0) AND (found = 0)))),
    CONSTRAINT icp_dispatch_runs_dispatch_key_check CHECK ((length(btrim(dispatch_key)) > 0)),
    CONSTRAINT icp_dispatch_runs_state_check CHECK ((state = ANY (ARRAY['reserved'::text, 'running'::text, 'settled'::text, 'blocked'::text]))),
    CONSTRAINT icp_dispatch_runs_target_limit_check CHECK (((target_limit >= 1) AND (target_limit <= 3000))),
    CONSTRAINT icp_dispatch_runs_workflow_id_check CHECK ((length(btrim(workflow_id)) > 0))
);


--
-- Name: icp_dispatch_site_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icp_dispatch_site_state (
    site_id uuid NOT NULL,
    last_dispatched_at timestamp with time zone,
    next_eligible_at timestamp with time zone,
    consecutive_failures integer DEFAULT 0 NOT NULL,
    CONSTRAINT icp_dispatch_site_state_consecutive_failures_check CHECK ((consecutive_failures >= 0))
);


--
-- Name: icp_mining; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icp_mining (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_query_id uuid NOT NULL,
    icp_criteria jsonb NOT NULL,
    icp_hash text GENERATED ALWAYS AS (encode(extensions.digest((icp_criteria)::text, 'sha256'::text), 'hex'::text)) STORED,
    status text DEFAULT 'pending'::text NOT NULL,
    total_targets integer DEFAULT 0,
    processed_targets integer DEFAULT 0,
    found_matches integer DEFAULT 0,
    progress_percent numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN (total_targets > 0) THEN round(((100.0 * (processed_targets)::numeric) / (total_targets)::numeric), 2)
    WHEN (status = 'completed'::text) THEN 100.00
    ELSE 0.00
END) STORED,
    started_at timestamp with time zone,
    last_progress_at timestamp with time zone,
    finished_at timestamp with time zone,
    last_error text,
    errors jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    site_id uuid,
    name text,
    current_page smallint DEFAULT '0'::smallint,
    current_page_offset integer,
    execution_run_id uuid,
    execution_workflow_id text,
    execution_active boolean DEFAULT false NOT NULL,
    checkpoint_version integer DEFAULT 0 NOT NULL,
    current_page_snapshot jsonb,
    CONSTRAINT icp_mining_found_matches_check CHECK ((found_matches >= 0)),
    CONSTRAINT icp_mining_page_offset_range CHECK (((current_page_offset IS NULL) OR ((current_page_offset >= 0) AND (current_page_offset <= 9)))),
    CONSTRAINT icp_mining_processed_targets_check CHECK ((processed_targets >= 0)),
    CONSTRAINT icp_mining_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'running'::text, 'completed'::text, 'failed'::text]))),
    CONSTRAINT icp_mining_total_targets_check CHECK ((total_targets >= 0))
);


--
-- Name: icypeas_email_searches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.icypeas_email_searches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    input_hash text NOT NULL,
    firstname text DEFAULT ''::text NOT NULL,
    lastname text DEFAULT ''::text NOT NULL,
    domain_or_company text NOT NULL,
    state text DEFAULT 'ready'::text NOT NULL,
    search_id text,
    status text DEFAULT 'READY'::text NOT NULL,
    emails jsonb DEFAULT '[]'::jsonb NOT NULL,
    error text,
    next_poll_at timestamp with time zone DEFAULT now() NOT NULL,
    poll_token uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT icypeas_email_searches_check CHECK (((firstname <> ''::text) OR (lastname <> ''::text))),
    CONSTRAINT icypeas_email_searches_check1 CHECK (((state <> ALL (ARRAY['ready'::text, 'submitting'::text, 'unknown'::text])) OR (search_id IS NULL))),
    CONSTRAINT icypeas_email_searches_check2 CHECK (((state <> ALL (ARRAY['pending'::text, 'matched'::text, 'no_match'::text])) OR (search_id IS NOT NULL))),
    CONSTRAINT icypeas_email_searches_check3 CHECK ((((state = 'matched'::text) AND (jsonb_array_length(emails) > 0)) OR ((state <> 'matched'::text) AND (emails = '[]'::jsonb)))),
    CONSTRAINT icypeas_email_searches_domain_or_company_check CHECK (((length(domain_or_company) >= 1) AND (length(domain_or_company) <= 500))),
    CONSTRAINT icypeas_email_searches_emails_check CHECK (((jsonb_typeof(emails) = 'array'::text) AND (jsonb_array_length(emails) <= 20))),
    CONSTRAINT icypeas_email_searches_firstname_check CHECK ((length(firstname) <= 200)),
    CONSTRAINT icypeas_email_searches_input_hash_check CHECK ((input_hash ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT icypeas_email_searches_lastname_check CHECK ((length(lastname) <= 200)),
    CONSTRAINT icypeas_email_searches_search_id_check CHECK ((search_id ~ '^[A-Za-z0-9_-]{1,200}$'::text)),
    CONSTRAINT icypeas_email_searches_state_check CHECK ((state = ANY (ARRAY['ready'::text, 'submitting'::text, 'unknown'::text, 'pending'::text, 'matched'::text, 'no_match'::text, 'failed'::text])))
);


--
-- Name: image_generation_credit_reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.image_generation_credit_reservations (
    site_id uuid NOT NULL,
    operation_id text NOT NULL,
    request_hash text NOT NULL,
    dispatch_token uuid NOT NULL,
    requested_count integer NOT NULL,
    amount numeric NOT NULL,
    trial_spent numeric NOT NULL,
    plan_spent numeric NOT NULL,
    legacy_spent numeric NOT NULL,
    purchased_spent numeric NOT NULL,
    trial_started_at timestamp with time zone,
    trial_ends_at timestamp with time zone,
    period_start timestamp with time zone,
    period_end timestamp with time zone,
    state text DEFAULT 'reserved'::text NOT NULL,
    actual_count integer,
    charged numeric,
    generation_id text,
    model text,
    reason text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    dispatched_at timestamp with time zone,
    finished_at timestamp with time zone,
    CONSTRAINT image_generation_credit_reservations_actual_count_check CHECK (((actual_count >= 1) AND (actual_count <= 4))),
    CONSTRAINT image_generation_credit_reservations_check CHECK (((amount = ((requested_count)::numeric * 0.1)) AND (amount = (((trial_spent + plan_spent) + legacy_spent) + purchased_spent)) AND (trial_spent >= (0)::numeric) AND (plan_spent >= (0)::numeric) AND (legacy_spent >= (0)::numeric) AND (purchased_spent >= (0)::numeric))),
    CONSTRAINT image_generation_credit_reservations_check1 CHECK (((charged IS NULL) OR ((charged >= (0)::numeric) AND (charged <= amount) AND ((charged)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text]))))),
    CONSTRAINT image_generation_credit_reservations_operation_id_check CHECK ((operation_id ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT image_generation_credit_reservations_request_hash_check CHECK ((request_hash ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT image_generation_credit_reservations_requested_count_check CHECK (((requested_count >= 1) AND (requested_count <= 4))),
    CONSTRAINT image_generation_credit_reservations_state_check CHECK ((state = ANY (ARRAY['reserved'::text, 'dispatched'::text, 'pending'::text, 'settled'::text, 'released'::text])))
);


--
-- Name: instance_artifacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_artifacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid,
    screen text NOT NULL,
    url text NOT NULL,
    title text,
    description text,
    should_reload boolean DEFAULT false NOT NULL,
    context jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.instance_artifacts FORCE ROW LEVEL SECURITY;


--
-- Name: instance_context_memories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_context_memories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone NOT NULL,
    end_log_id uuid NOT NULL,
    summary text NOT NULL,
    embedding public.vector(1536) NOT NULL,
    embedding_model text DEFAULT 'text-embedding-3-small'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT instance_context_memories_range CHECK ((end_at >= start_at))
);


--
-- Name: instance_context_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_context_state (
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    cursor_at timestamp with time zone,
    cursor_log_id uuid,
    revision bigint DEFAULT 0 NOT NULL,
    model text,
    provider text,
    used_tokens integer,
    available_tokens integer,
    measured_at timestamp with time zone,
    source text DEFAULT 'estimate'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    reserved_output_tokens integer DEFAULT 0 NOT NULL,
    output_tokens integer,
    input_breakdown jsonb
);


--
-- Name: instance_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    log_type text NOT NULL,
    level text DEFAULT 'info'::text NOT NULL,
    message text NOT NULL,
    details jsonb DEFAULT '{}'::jsonb,
    step_id text,
    tool_name text,
    tool_call_id text,
    tool_args jsonb DEFAULT '{}'::jsonb,
    tool_result jsonb DEFAULT '{}'::jsonb,
    is_error boolean DEFAULT false,
    duration_ms integer,
    tokens_used jsonb DEFAULT '{}'::jsonb,
    screenshot_base64 text,
    artifacts jsonb DEFAULT '[]'::jsonb,
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid,
    agent_id uuid,
    command_id uuid,
    parent_log_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    trusted_user_action boolean DEFAULT false NOT NULL,
    CONSTRAINT instance_logs_level_check CHECK ((level = ANY (ARRAY['debug'::text, 'info'::text, 'warn'::text, 'error'::text, 'critical'::text]))),
    CONSTRAINT instance_logs_log_type_check CHECK ((log_type = ANY (ARRAY['system'::text, 'user_action'::text, 'agent_action'::text, 'tool_call'::text, 'tool_result'::text, 'error'::text, 'performance'::text, 'thinking'::text, 'infrastructure'::text, 'system_action'::text, 'workflow_execution'::text, 'step_execution'::text, 'execution_summary'::text, 'session_acquired'::text, 'user_attention_required'::text, 'session_request'::text, 'user_message'::text])))
);


--
-- Name: instance_node_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_node_contexts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    target_node_id uuid NOT NULL,
    context_node_id uuid NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    type text
);


--
-- Name: instance_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_nodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instance_id uuid NOT NULL,
    parent_node_id uuid,
    original_node_id uuid,
    parent_instance_log_id uuid,
    type text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    result jsonb DEFAULT '{}'::jsonb,
    settings jsonb DEFAULT '{}'::jsonb,
    prompt jsonb DEFAULT '{}'::jsonb,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT instance_nodes_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'running'::text, 'completed'::text, 'failed'::text, 'cancelled'::text])))
);


--
-- Name: instance_plan_step_infrastructure_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_plan_step_infrastructure_events (
    plan_id uuid NOT NULL,
    step_id text NOT NULL,
    event_id text NOT NULL,
    event_type text NOT NULL,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT instance_plan_step_infrastructure_events_event_id_check CHECK (((char_length(event_id) >= 1) AND (char_length(event_id) <= 300))),
    CONSTRAINT instance_plan_step_infrastructure_events_event_type_check CHECK ((event_type = ANY (ARRAY['failure'::text, 'success_clear'::text, 'deployment_recovery'::text, 'step_patch'::text]))),
    CONSTRAINT instance_plan_step_infrastructure_events_step_id_check CHECK (((char_length(step_id) >= 1) AND (char_length(step_id) <= 200)))
);


--
-- Name: instance_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    plan_type text NOT NULL,
    priority integer DEFAULT 5,
    status text DEFAULT 'pending'::text NOT NULL,
    instructions text,
    expected_output text,
    success_criteria jsonb DEFAULT '[]'::jsonb,
    validation_rules jsonb DEFAULT '[]'::jsonb,
    tools_required jsonb DEFAULT '[]'::jsonb,
    estimated_duration_minutes integer,
    actual_duration_minutes integer,
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    results jsonb DEFAULT '{}'::jsonb,
    artifacts jsonb DEFAULT '[]'::jsonb,
    error_message text,
    progress_percentage integer DEFAULT 0,
    steps_completed integer DEFAULT 0,
    steps_total integer DEFAULT 1,
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    agent_id uuid,
    command_id uuid,
    parent_plan_id uuid,
    depends_on jsonb DEFAULT '[]'::jsonb,
    blocks jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    due_at timestamp with time zone,
    steps jsonb DEFAULT '{}'::jsonb,
    completion_reason text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT instance_plans_plan_type_check CHECK ((plan_type = ANY (ARRAY['objective'::text, 'task'::text, 'verification'::text, 'milestone'::text]))),
    CONSTRAINT instance_plans_priority_check CHECK (((priority >= 1) AND (priority <= 10))),
    CONSTRAINT instance_plans_progress_percentage_check CHECK (((progress_percentage >= 0) AND (progress_percentage <= 100))),
    CONSTRAINT instance_plans_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'paused'::text, 'completed'::text, 'failed'::text, 'cancelled'::text, 'blocked'::text])))
);


--
-- Name: insufficient_credit_email_recipient_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.insufficient_credit_email_recipient_gates (
    recipient_hash text NOT NULL,
    attempted_at timestamp with time zone[] NOT NULL,
    CONSTRAINT insufficient_credit_email_recipient_gates_attempted_at_check CHECK ((((cardinality(attempted_at) >= 1) AND (cardinality(attempted_at) <= 3)) AND (array_ndims(attempted_at) = 1) AND (array_lower(attempted_at, 1) = 1) AND (array_position(attempted_at, NULL::timestamp with time zone) IS NULL))),
    CONSTRAINT insufficient_credit_email_recipient_gates_recipient_hash_check CHECK (((length(recipient_hash) = 64) AND ((recipient_hash COLLATE "C") ~ '^[0-9a-f]{64}$'::text)))
);

ALTER TABLE ONLY public.insufficient_credit_email_recipient_gates FORCE ROW LEVEL SECURITY;


--
-- Name: insufficient_credit_email_site_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.insufficient_credit_email_site_gates (
    site_id uuid NOT NULL,
    last_attempt_at timestamp with time zone NOT NULL,
    idempotency_key text NOT NULL
);

ALTER TABLE ONLY public.insufficient_credit_email_site_gates FORCE ROW LEVEL SECURITY;


--
-- Name: inventory_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_levels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    location_id uuid NOT NULL,
    quantity numeric DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: invoice_reminders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_reminders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    sale_id uuid NOT NULL,
    reminder_key text NOT NULL,
    state text DEFAULT 'generating'::text NOT NULL,
    message_id uuid,
    command_id text,
    provider_message_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    CONSTRAINT invoice_reminders_reminder_key_check CHECK (((length(reminder_key) >= 1) AND (length(reminder_key) <= 200))),
    CONSTRAINT invoice_reminders_state_check CHECK ((state = ANY (ARRAY['generating'::text, 'ready'::text, 'sent'::text, 'uncertain'::text, 'cancelled'::text])))
);

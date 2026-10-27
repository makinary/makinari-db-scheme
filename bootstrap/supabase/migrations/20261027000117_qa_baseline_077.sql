SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: requirement_cron_cycle_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_cron_cycle_outcomes (
    requirement_id uuid NOT NULL,
    cycle_id text NOT NULL,
    cycle_started_at timestamp with time zone NOT NULL,
    outcome text NOT NULL,
    runner_instance_id uuid,
    accepted_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    execution_generation integer DEFAULT 0 NOT NULL,
    plan_id uuid,
    step_id text,
    CONSTRAINT requirement_cron_cycle_outcomes_cycle_id_check CHECK (((char_length(cycle_id) >= 1) AND (char_length(cycle_id) <= 200))),
    CONSTRAINT requirement_cron_cycle_outcomes_execution_generation_check CHECK ((execution_generation >= 0)),
    CONSTRAINT requirement_cron_cycle_outcomes_outcome_check CHECK ((outcome = ANY (ARRAY['progress'::text, 'product_no_progress'::text, 'product_failure'::text, 'infrastructure_wait'::text, 'infrastructure_retry'::text, 'infrastructure_exhausted'::text, 'scheduler_cooldown'::text, 'remediation_handoff'::text, 'paused'::text, 'idle'::text])))
);


--
-- Name: requirement_economic_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_economic_pauses (
    requirement_id uuid NOT NULL,
    status_id uuid NOT NULL,
    session_id uuid NOT NULL,
    generation integer NOT NULL,
    requirement_guard jsonb NOT NULL,
    status_guard jsonb NOT NULL,
    session_version bigint,
    last_error_code text,
    checked_at timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    pause_reason text DEFAULT 'token_budget_exhausted'::text NOT NULL
);


--
-- Name: requirement_harness_decisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_harness_decisions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    requirement_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    site_id uuid NOT NULL,
    request_id uuid NOT NULL,
    decision text NOT NULL,
    item_id text,
    reason text NOT NULL,
    payload jsonb NOT NULL,
    contract_snapshot jsonb NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    email_state text DEFAULT 'unconfigured'::text NOT NULL,
    email_attempted_at timestamp with time zone,
    email_error text,
    CONSTRAINT requirement_harness_decisions_contract_snapshot_check CHECK ((jsonb_typeof(contract_snapshot) = 'object'::text)),
    CONSTRAINT requirement_harness_decisions_decision_check CHECK ((decision = ANY (ARRAY['approve_backlog'::text, 'adapt_backlog'::text, 'escalate_support'::text]))),
    CONSTRAINT requirement_harness_decisions_email_error_check CHECK ((char_length(email_error) <= 2000)),
    CONSTRAINT requirement_harness_decisions_email_state_check CHECK ((email_state = ANY (ARRAY['pending'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'unconfigured'::text]))),
    CONSTRAINT requirement_harness_decisions_item_id_check CHECK (((item_id IS NULL) OR ((char_length(item_id) >= 1) AND (char_length(item_id) <= 200)))),
    CONSTRAINT requirement_harness_decisions_payload_check CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT requirement_harness_decisions_reason_check CHECK (((char_length(reason) >= 1) AND (char_length(reason) <= 4000))),
    CONSTRAINT requirement_harness_decisions_status_check CHECK ((status = ANY (ARRAY['applied'::text, 'recorded'::text])))
);


--
-- Name: requirement_migration_diagnostics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_migration_diagnostics (
    requirement_id uuid NOT NULL,
    file text NOT NULL,
    token uuid DEFAULT gen_random_uuid() NOT NULL,
    execution_generation integer NOT NULL,
    state text NOT NULL,
    checksum text NOT NULL,
    specification_checksum text NOT NULL,
    result jsonb,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT requirement_migration_diagnostics_checksum_check CHECK ((checksum ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT requirement_migration_diagnostics_execution_generation_check CHECK ((execution_generation >= 0)),
    CONSTRAINT requirement_migration_diagnostics_result_check CHECK (((result IS NULL) OR ((jsonb_typeof(result) = 'object'::text) AND (octet_length((result)::text) <= 65536)))),
    CONSTRAINT requirement_migration_diagnostics_specification_checksum_check CHECK ((specification_checksum ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT requirement_migration_diagnostics_state_check CHECK ((state = ANY (ARRAY['running'::text, 'followup_ready'::text, 'followup_assigned'::text, 'followup_reviewing'::text, 'exhausted'::text])))
);


--
-- Name: requirement_migration_execution_handoffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_migration_execution_handoffs (
    id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    file text NOT NULL,
    site_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    operator_id text NOT NULL,
    reason text NOT NULL,
    prior_lifecycle jsonb NOT NULL,
    prior_diagnostic jsonb,
    evidence jsonb NOT NULL,
    execution_generation integer NOT NULL,
    transferred_version integer NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT requirement_migration_execution_hand_execution_generation_check CHECK (((execution_generation >= 0) AND (execution_generation <= 2147483646))),
    CONSTRAINT requirement_migration_execution_hando_transferred_version_check CHECK ((transferred_version > 1)),
    CONSTRAINT requirement_migration_execution_handoffs_evidence_check CHECK (((jsonb_typeof(evidence) = 'object'::text) AND (octet_length((evidence)::text) <= 4096))),
    CONSTRAINT requirement_migration_execution_handoffs_operator_id_check CHECK (((operator_id ~ '[^[:space:]]'::text) AND (char_length(operator_id) <= 200))),
    CONSTRAINT requirement_migration_execution_handoffs_prior_diagnostic_check CHECK ((jsonb_typeof(prior_diagnostic) = 'object'::text)),
    CONSTRAINT requirement_migration_execution_handoffs_prior_lifecycle_check CHECK ((jsonb_typeof(prior_lifecycle) = 'object'::text)),
    CONSTRAINT requirement_migration_execution_handoffs_reason_check CHECK (((reason ~ '[^[:space:]]'::text) AND (char_length(reason) <= 2000)))
);


--
-- Name: requirement_migration_reconciliation_resumes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_migration_reconciliation_resumes (
    receipt_id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    execution_generation integer NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    evidence jsonb NOT NULL,
    CONSTRAINT requirement_migration_reconciliatio_execution_generation_check1 CHECK ((execution_generation > 0)),
    CONSTRAINT requirement_migration_reconciliation_resumes_evidence_check CHECK ((jsonb_typeof(evidence) = 'object'::text))
);


--
-- Name: requirement_migration_reconciliations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_migration_reconciliations (
    id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    file text NOT NULL,
    site_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    step_id text NOT NULL,
    operator_id text NOT NULL,
    reason text NOT NULL,
    execution_generation integer NOT NULL,
    backlog_revision bigint NOT NULL,
    prior_lifecycle jsonb NOT NULL,
    specification_checksum text NOT NULL,
    specification text NOT NULL,
    evidence jsonb NOT NULL,
    request jsonb NOT NULL,
    lifecycle jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT requirement_migration_reconciliati_specification_checksum_check CHECK ((specification_checksum ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT requirement_migration_reconciliation_execution_generation_check CHECK (((execution_generation >= 0) AND (execution_generation <= 2147483646))),
    CONSTRAINT requirement_migration_reconciliations_backlog_revision_check CHECK ((backlog_revision >= 0)),
    CONSTRAINT requirement_migration_reconciliations_evidence_check CHECK ((jsonb_typeof(evidence) = 'object'::text)),
    CONSTRAINT requirement_migration_reconciliations_lifecycle_check CHECK ((jsonb_typeof(lifecycle) = 'object'::text)),
    CONSTRAINT requirement_migration_reconciliations_operator_id_check CHECK (((operator_id ~ '[^[:space:]]'::text) AND (char_length(operator_id) <= 200))),
    CONSTRAINT requirement_migration_reconciliations_prior_lifecycle_check CHECK ((jsonb_typeof(prior_lifecycle) = 'object'::text)),
    CONSTRAINT requirement_migration_reconciliations_reason_check CHECK (((reason ~ '[^[:space:]]'::text) AND (char_length(reason) <= 2000))),
    CONSTRAINT requirement_migration_reconciliations_request_check CHECK ((jsonb_typeof(request) = 'object'::text)),
    CONSTRAINT requirement_migration_reconciliations_step_id_check CHECK (((char_length(step_id) >= 1) AND (char_length(step_id) <= 200)))
);


--
-- Name: requirement_migration_retirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_migration_retirements (
    id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    file text NOT NULL,
    site_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    operator_id text NOT NULL,
    reason text NOT NULL,
    execution_generation integer NOT NULL,
    transferred_version integer NOT NULL,
    prior_lifecycle jsonb NOT NULL,
    prior_diagnostic jsonb,
    prior_requirement_metadata jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT requirement_migration_retireme_prior_requirement_metadata_check CHECK ((jsonb_typeof(prior_requirement_metadata) = 'object'::text)),
    CONSTRAINT requirement_migration_retirements_execution_generation_check CHECK (((execution_generation >= 0) AND (execution_generation <= 2147483646))),
    CONSTRAINT requirement_migration_retirements_operator_id_check CHECK (((char_length(btrim(operator_id)) >= 1) AND (char_length(btrim(operator_id)) <= 200))),
    CONSTRAINT requirement_migration_retirements_prior_diagnostic_check CHECK ((jsonb_typeof(prior_diagnostic) = 'object'::text)),
    CONSTRAINT requirement_migration_retirements_prior_lifecycle_check CHECK ((jsonb_typeof(prior_lifecycle) = 'object'::text)),
    CONSTRAINT requirement_migration_retirements_reason_check CHECK (((char_length(btrim(reason)) >= 1) AND (char_length(btrim(reason)) <= 2000))),
    CONSTRAINT requirement_migration_retirements_transferred_version_check CHECK ((transferred_version > 1))
);


--
-- Name: requirement_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_segments (
    requirement_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    command_id uuid
);


--
-- Name: requirement_source_checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_source_checkpoints (
    requirement_id uuid NOT NULL,
    site_id uuid NOT NULL,
    session_id uuid NOT NULL,
    baseline jsonb,
    pending_publication jsonb,
    last_result jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: requirement_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_status (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid NOT NULL,
    instance_id uuid,
    asset_id uuid,
    requirement_id uuid NOT NULL,
    repo_url text,
    stage text NOT NULL,
    message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    preview_url text,
    source_code text,
    cycle text,
    endpoint_url text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    snapshot_id text,
    active_sandbox_id text,
    CONSTRAINT requirement_status_stage_check CHECK ((stage = ANY (ARRAY['pending'::text, 'in-progress'::text, 'on-review'::text, 'completed'::text, 'done'::text, 'failed'::text, 'blocked'::text, 'paused'::text, 'cancelled'::text, 'backlog'::text, 'validated'::text, 'needs_review'::text])))
);


--
-- Name: requirement_user_action_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_user_action_receipts (
    requirement_id uuid NOT NULL,
    action_id uuid NOT NULL,
    action_created_at timestamp with time zone NOT NULL,
    revision bigint NOT NULL,
    consumed_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT requirement_user_action_receipts_revision_check CHECK ((revision > 0))
);


--
-- Name: reservation_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    duration_minutes integer DEFAULT 60 NOT NULL,
    capacity integer DEFAULT 1 NOT NULL,
    timezone text NOT NULL,
    days jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text
);


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    catalog_item_id uuid,
    status text DEFAULT 'confirmed'::text NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    buyer_user_id uuid,
    owner_site_id uuid,
    quantity integer DEFAULT 1 NOT NULL,
    sale_order_item_id uuid,
    entitlement_id uuid,
    resource_type text DEFAULT 'catalog_item'::text NOT NULL,
    location_id uuid,
    assignee_user_id uuid,
    channel text DEFAULT 'physical'::text NOT NULL,
    terms_text text,
    terms_accepted_at timestamp with time zone,
    signature_url text,
    photo_url text,
    signed_at timestamp with time zone,
    id_url text,
    metadata jsonb DEFAULT '{}'::jsonb,
    operating_location_id uuid,
    CONSTRAINT reservations_channel_check CHECK ((channel = ANY (ARRAY['physical'::text, 'online'::text]))),
    CONSTRAINT reservations_resource_target_check CHECK ((((resource_type = 'catalog_item'::text) AND (catalog_item_id IS NOT NULL) AND (location_id IS NULL) AND (assignee_user_id IS NULL)) OR ((resource_type = 'location'::text) AND (location_id IS NOT NULL) AND (catalog_item_id IS NULL) AND (assignee_user_id IS NULL)) OR ((resource_type = 'employee'::text) AND (assignee_user_id IS NOT NULL) AND (catalog_item_id IS NULL) AND (location_id IS NULL)))),
    CONSTRAINT reservations_resource_type_check CHECK ((resource_type = ANY (ARRAY['catalog_item'::text, 'location'::text, 'employee'::text]))),
    CONSTRAINT reservations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text, 'completed'::text])))
);


--
-- Name: role_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_queries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    query jsonb NOT NULL,
    query_hash text GENERATED ALWAYS AS (encode(extensions.digest((query)::text, 'sha256'::text), 'hex'::text)) STORED,
    synced_pages integer DEFAULT 0 NOT NULL,
    total_persons integer,
    total_organizations integer,
    total_search_results integer,
    status text DEFAULT 'pending'::text,
    last_run_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: role_query_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_query_segments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_query_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sale_order_item_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_order_item_units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    sale_order_item_id uuid NOT NULL,
    unit_index integer NOT NULL,
    quantity numeric DEFAULT 1 NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    assigned_to uuid,
    shipment_id uuid,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    in_progress_at timestamp with time zone,
    ready_at timestamp with time zone,
    delivered_at timestamp with time zone,
    CONSTRAINT sale_order_item_units_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT sale_order_item_units_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'new'::text, 'pending'::text, 'preparing'::text, 'in_progress'::text, 'completed'::text, 'ready'::text, 'returned'::text, 'cancelled'::text]))),
    CONSTRAINT sale_order_item_units_unit_index_check CHECK ((unit_index > 0))
);


--
-- Name: sale_order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sale_order_id uuid NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid,
    location_id uuid,
    name text NOT NULL,
    description text,
    quantity numeric DEFAULT 1 NOT NULL,
    unit_price numeric DEFAULT 0 NOT NULL,
    subtotal numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    sent_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    shipment_id uuid,
    parent_sale_order_item_id uuid,
    assigned_to uuid,
    CONSTRAINT sale_order_items_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'new'::text, 'pending'::text, 'preparing'::text, 'in_progress'::text, 'completed'::text, 'ready'::text, 'returned'::text, 'cancelled'::text])))
);


--
-- Name: sale_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_orders (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    sale_id uuid NOT NULL,
    order_number text NOT NULL,
    items jsonb DEFAULT '[]'::jsonb NOT NULL,
    subtotal numeric DEFAULT 0 NOT NULL,
    tax_total numeric DEFAULT 0 NOT NULL,
    discount_total numeric DEFAULT 0 NOT NULL,
    total numeric DEFAULT 0 NOT NULL,
    notes text,
    status text DEFAULT 'completed'::text NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    promotion_id uuid,
    price_list_id uuid,
    buyer_user_id uuid,
    owner_site_id uuid,
    fulfillment_method text,
    origin_location_id uuid,
    shipping_address jsonb,
    currency text DEFAULT 'USD'::text NOT NULL,
    shipping_cost numeric DEFAULT 0 NOT NULL,
    scheduled_for timestamp with time zone,
    public_access_token text,
    last_emailed_at timestamp with time zone,
    public_access_token_expires_at timestamp with time zone,
    public_access_token_revoked_at timestamp with time zone,
    created_by_user_id uuid,
    seller_user_id uuid,
    requested_by_lead_id uuid,
    quotation_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    marketplace_integration_id uuid,
    external_order_id text,
    marketplace_polled_at timestamp with time zone,
    location_id uuid,
    CONSTRAINT sale_orders_fulfillment_method_check CHECK ((fulfillment_method = ANY (ARRAY['pickup'::text, 'ship'::text, 'dine_in'::text, 'none'::text]))),
    CONSTRAINT sale_orders_marketplace_identity CHECK ((((marketplace_integration_id IS NULL) = (external_order_id IS NULL)) AND ((external_order_id IS NULL) OR ((length(external_order_id) >= 1) AND (length(external_order_id) <= 200)))))
);

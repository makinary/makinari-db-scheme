SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: marketplace_webhook_registration_apps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_webhook_registration_apps (
    claim_id uuid DEFAULT gen_random_uuid() NOT NULL,
    app_client_id_hash text NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text,
    status text DEFAULT 'running'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT marketplace_webhook_registration_apps_app_client_id_hash_check CHECK ((app_client_id_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT marketplace_webhook_registration_apps_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_webhook_registration_apps_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_webhook_registration_apps_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text]))),
    CONSTRAINT marketplace_webhook_registration_apps_status_check CHECK ((status = ANY (ARRAY['running'::text, 'ready'::text, 'unknown'::text])))
);


--
-- Name: marketplace_webhook_registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_webhook_registrations (
    claim_id uuid DEFAULT gen_random_uuid() NOT NULL,
    app_client_id_hash text NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text,
    integration_id uuid,
    event text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    CONSTRAINT marketplace_webhook_registrations_app_client_id_hash_check CHECK ((app_client_id_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT marketplace_webhook_registrations_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_webhook_registrations_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_webhook_registrations_event_check CHECK (((length(event) >= 1) AND (length(event) <= 100))),
    CONSTRAINT marketplace_webhook_registrations_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text]))),
    CONSTRAINT marketplace_webhook_registrations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'ready'::text, 'unknown'::text])))
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    visitor_id uuid,
    agent_id uuid,
    user_id uuid,
    lead_id uuid,
    content text NOT NULL,
    role text NOT NULL,
    read_at timestamp with time zone,
    custom_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    command_id uuid,
    interaction text,
    CONSTRAINT valid_role CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text, 'function'::text, 'tool'::text, 'data'::text, 'team_member'::text])))
);


--
-- Name: modifier_group_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modifier_group_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    modifier_group_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: modifier_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modifier_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    min_select integer DEFAULT 0 NOT NULL,
    max_select integer,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT modifier_groups_max_select_check CHECK (((max_select IS NULL) OR (max_select >= min_select))),
    CONSTRAINT modifier_groups_min_select_check CHECK ((min_select >= 0))
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL,
    is_read boolean DEFAULT false,
    action_url text,
    related_entity_type text,
    related_entity_id uuid,
    site_id uuid,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    event_type text,
    severity integer,
    command_id uuid,
    CONSTRAINT notifications_event_type_check CHECK ((event_type = ANY (ARRAY['lead_created'::text, 'kpi_alert'::text, 'experiment_result'::text]))),
    CONSTRAINT notifications_type_check CHECK ((type = ANY (ARRAY['info'::text, 'success'::text, 'warning'::text, 'error'::text])))
);


--
-- Name: openrouter_generation_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.openrouter_generation_charges (
    event_id text NOT NULL,
    site_id uuid NOT NULL,
    provider_cost numeric,
    amount numeric,
    state text DEFAULT 'pending'::text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    result jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    charged_at timestamp with time zone,
    CONSTRAINT openrouter_generation_charges_amount_check CHECK (((amount >= (0)::numeric) AND ((amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT openrouter_generation_charges_event_id_check CHECK (((length(event_id) >= 1) AND (length(event_id) <= 256))),
    CONSTRAINT openrouter_generation_charges_provider_cost_check CHECK (((provider_cost >= (0)::numeric) AND ((provider_cost)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT openrouter_generation_charges_state_check CHECK ((state = ANY (ARRAY['pending'::text, 'charged'::text])))
);


--
-- Name: outstand_initial_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outstand_initial_imports (
    account_id text NOT NULL,
    site_id uuid NOT NULL,
    status text DEFAULT 'requested'::text NOT NULL,
    import_limit integer NOT NULL,
    job_id text,
    imported integer,
    failed integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT outstand_initial_imports_import_limit_check CHECK (((import_limit >= 1) AND (import_limit <= 100))),
    CONSTRAINT outstand_initial_imports_status_check CHECK ((status = ANY (ARRAY['requested'::text, 'queued'::text, 'running'::text, 'completed'::text, 'partial'::text, 'failed'::text, 'unknown'::text])))
);


--
-- Name: partner_licenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partner_licenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    license_key uuid NOT NULL,
    parent_license_key uuid,
    partner character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    plan_name character varying(255) NOT NULL,
    user_id uuid,
    site_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pass_redeemable_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pass_redeemable_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    pass_catalog_item_id uuid NOT NULL,
    reservable_catalog_item_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: pass_round_robin_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pass_round_robin_state (
    pass_catalog_item_id uuid NOT NULL,
    site_id uuid NOT NULL,
    next_index integer DEFAULT 0 NOT NULL,
    last_member_id uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid NOT NULL,
    transaction_id character varying(255) DEFAULT ('tx_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)),
    transaction_type character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying,
    status character varying(50) NOT NULL,
    payment_method character varying(50),
    details jsonb DEFAULT '{}'::jsonb,
    credits integer DEFAULT 0,
    invoice_url character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    command_id uuid
);


--
-- Name: payout_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payout_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    requested_credits numeric NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    bank_details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    requested_by uuid,
    resolved_at timestamp with time zone,
    resolved_by uuid,
    idempotency_key text,
    CONSTRAINT payout_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'rejected'::text])))
);


--
-- Name: persons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_query_id uuid,
    external_person_id bigint,
    external_role_id bigint,
    external_organization_id bigint,
    full_name text,
    role_title text,
    company_name text,
    start_date date,
    end_date date,
    is_current boolean,
    location text,
    emails jsonb,
    phones jsonb,
    raw_result jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    personal_emails jsonb[] DEFAULT '{}'::jsonb[],
    linkedin_profile text
);


--
-- Name: platform_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    requirement_id uuid,
    api_key_id uuid,
    endpoint text NOT NULL,
    method text NOT NULL,
    status integer NOT NULL,
    scope text,
    capability text,
    cost_units integer DEFAULT 1 NOT NULL,
    latency_ms integer DEFAULT 0 NOT NULL,
    test_only boolean DEFAULT false NOT NULL,
    error text,
    request_summary jsonb,
    response_summary jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.platform_audit_log FORCE ROW LEVEL SECURITY;


--
-- Name: platform_quotas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_quotas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    capability text NOT NULL,
    period text NOT NULL,
    used integer DEFAULT 0 NOT NULL,
    quota_override integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.platform_quotas FORCE ROW LEVEL SECURITY;


--
-- Name: platform_tracking_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_tracking_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    requirement_id uuid,
    event_name text NOT NULL,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    source text DEFAULT 'platform-api'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.platform_tracking_events FORCE ROW LEVEL SECURITY;


--
-- Name: platform_user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_user_roles (
    user_id uuid NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT platform_user_roles_role_check CHECK ((role = ANY (ARRAY['super_admin'::text, 'finance_admin'::text])))
);


--
-- Name: pos_checkout_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_checkout_attempts (
    site_id uuid NOT NULL,
    client_mutation_id text NOT NULL,
    actor_id uuid NOT NULL,
    requested_order_id uuid,
    order_id uuid,
    sale_id uuid,
    fingerprint text NOT NULL,
    owner_token uuid NOT NULL,
    state text NOT NULL,
    result jsonb,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pos_checkout_attempts_client_mutation_id_check CHECK (((length(client_mutation_id) >= 1) AND (length(client_mutation_id) <= 128))),
    CONSTRAINT pos_checkout_attempts_state_check CHECK ((state = ANY (ARRAY['processing'::text, 'writes_started'::text, 'completed'::text, 'rejected'::text, 'review_required'::text])))
);


--
-- Name: pos_client_mutations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_client_mutations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    client_mutation_id text NOT NULL,
    kind text NOT NULL,
    sale_id uuid,
    order_id uuid,
    lead_id uuid,
    result jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pos_client_mutations_kind_check CHECK ((kind = ANY (ARRAY['checkout'::text, 'check_in'::text, 'create_lead'::text])))
);


--
-- Name: pos_register_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_register_movements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    site_id uuid NOT NULL,
    kind text NOT NULL,
    amount numeric NOT NULL,
    reason text NOT NULL,
    actor_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    request_id uuid NOT NULL,
    CONSTRAINT pos_register_movements_amount_check CHECK (((amount > (0)::numeric) AND (amount <= (999999999)::numeric) AND (amount = round(amount, 2)) AND ((amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT pos_register_movements_kind_check CHECK ((kind = ANY (ARRAY['cash_in'::text, 'cash_out'::text, 'cash_refund'::text]))),
    CONSTRAINT pos_register_movements_reason_check CHECK (((length(btrim(reason)) >= 1) AND (length(btrim(reason)) <= 500)))
);


--
-- Name: pos_register_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_register_receipts (
    id uuid NOT NULL,
    session_id uuid NOT NULL,
    site_id uuid NOT NULL,
    sale_id uuid NOT NULL,
    method text NOT NULL,
    amount numeric NOT NULL,
    tendered numeric NOT NULL,
    change numeric NOT NULL,
    received_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    actor_id uuid NOT NULL,
    CONSTRAINT pos_register_receipts_amount_check CHECK (((amount > (0)::numeric) AND ((amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT pos_register_receipts_change_check CHECK (((change >= (0)::numeric) AND ((change)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT pos_register_receipts_check CHECK (((method <> 'cash'::text) OR ((tendered - change) = amount))),
    CONSTRAINT pos_register_receipts_method_check CHECK (((length(btrim(method)) > 0) AND (method = lower(btrim(method))))),
    CONSTRAINT pos_register_receipts_tendered_check CHECK (((tendered >= (0)::numeric) AND ((tendered)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text]))))
);


--
-- Name: pos_register_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_register_sessions (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    location_id uuid NOT NULL,
    currency text NOT NULL,
    opened_by uuid NOT NULL,
    closed_by uuid,
    opened_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    closed_at timestamp with time zone,
    opening_amount numeric NOT NULL,
    counted_amount numeric,
    expected_amount numeric,
    difference numeric,
    notes text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    close_request_id uuid,
    snapshot jsonb,
    CONSTRAINT pos_register_sessions_check CHECK ((((status = 'open'::text) AND (closed_by IS NULL) AND (closed_at IS NULL) AND (counted_amount IS NULL) AND (expected_amount IS NULL) AND (difference IS NULL) AND (close_request_id IS NULL) AND (snapshot IS NULL)) OR ((status = 'closed'::text) AND (closed_by IS NOT NULL) AND (closed_at IS NOT NULL) AND (counted_amount IS NOT NULL) AND (expected_amount IS NOT NULL) AND (difference IS NOT NULL) AND (close_request_id IS NOT NULL) AND (snapshot IS NOT NULL) AND (jsonb_typeof(snapshot) = 'object'::text)))),
    CONSTRAINT pos_register_sessions_counted_amount_check CHECK ((((counted_amount >= (0)::numeric) AND (counted_amount <= (999999999)::numeric)) AND (counted_amount = round(counted_amount, 2)) AND ((counted_amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT pos_register_sessions_currency_check CHECK ((currency ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT pos_register_sessions_difference_check CHECK (((difference)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text]))),
    CONSTRAINT pos_register_sessions_expected_amount_check CHECK (((expected_amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text]))),
    CONSTRAINT pos_register_sessions_notes_check CHECK ((length(notes) <= 2000)),
    CONSTRAINT pos_register_sessions_opening_amount_check CHECK ((((opening_amount >= (0)::numeric) AND (opening_amount <= (999999999)::numeric)) AND (opening_amount = round(opening_amount, 2)) AND ((opening_amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT pos_register_sessions_status_check CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text])))
);


--
-- Name: price_list_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.price_list_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    price_list_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    unit_price numeric NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

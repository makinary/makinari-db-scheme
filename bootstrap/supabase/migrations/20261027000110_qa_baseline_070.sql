SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: agent_memories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_memories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    user_id uuid NOT NULL,
    type text NOT NULL,
    key text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    raw_data text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    access_count integer DEFAULT 0,
    last_accessed timestamp with time zone DEFAULT now(),
    command_id uuid,
    chain_of_thoughts text
);


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    type text NOT NULL,
    status text NOT NULL,
    prompt text NOT NULL,
    conversations integer DEFAULT 0,
    success_rate integer DEFAULT 0,
    configuration jsonb DEFAULT '{}'::jsonb,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_active timestamp with time zone DEFAULT now(),
    role text,
    tools jsonb DEFAULT '{}'::jsonb,
    activities jsonb DEFAULT '{}'::jsonb,
    integrations jsonb DEFAULT '{}'::jsonb,
    supervisor uuid,
    backstory text,
    command_id uuid,
    CONSTRAINT agents_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'training'::text]))),
    CONSTRAINT agents_type_check CHECK ((type = ANY (ARRAY['sales'::text, 'support'::text, 'marketing'::text])))
);


--
-- Name: allowed_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allowed_domains (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    source text DEFAULT 'unknown'::text NOT NULL,
    requirement_id uuid,
    CONSTRAINT allowed_domains_source_check CHECK ((source = ANY (ARRAY['unknown'::text, 'user'::text, 'harness'::text]))),
    CONSTRAINT valid_domain CHECK (((domain = 'localhost'::text) OR (domain ~* '^([a-zA-Z0-9-]+\.)*[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$'::text) OR (domain ~* '^(\d{1,3}\.){3}\d{1,3}$'::text) OR (domain ~* '^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'::text)))
);


--
-- Name: analysis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analysis (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    url_path text NOT NULL,
    structure jsonb NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'completed'::text,
    request_time integer,
    provider text,
    model_id text,
    command_id uuid
);


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    key_hash text NOT NULL,
    prefix character varying(50) NOT NULL,
    user_id uuid NOT NULL,
    site_id uuid,
    status public.key_status DEFAULT 'active'::public.key_status,
    scopes text[] NOT NULL,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb DEFAULT '{}'::jsonb,
    lookup_hash text,
    identity_token_version uuid DEFAULT gen_random_uuid() NOT NULL,
    CONSTRAINT valid_expires_at CHECK ((expires_at > created_at)),
    CONSTRAINT valid_prefix CHECK (((prefix)::text ~* '^[a-zA-Z0-9_-]+$'::text)),
    CONSTRAINT valid_scopes CHECK ((array_length(scopes, 1) > 0))
);


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    context_id uuid NOT NULL,
    title text NOT NULL,
    start_datetime timestamp with time zone NOT NULL,
    end_datetime timestamp with time zone NOT NULL,
    duration integer NOT NULL,
    timezone text NOT NULL,
    participants text[] DEFAULT '{}'::text[] NOT NULL,
    location text,
    description text,
    reminder jsonb,
    status text DEFAULT 'confirmed'::text NOT NULL,
    calendar_link text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT appointments_duration_check CHECK ((duration >= 5)),
    CONSTRAINT appointments_valid_interval CHECK ((end_datetime > start_datetime))
);


--
-- Name: apps_tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apps_tenants (
    tenant_id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    user_id uuid NOT NULL,
    site_id uuid NOT NULL,
    schema text NOT NULL,
    bucket text NOT NULL,
    auth_provider text DEFAULT 'supabase'::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    requires_isolation boolean DEFAULT false NOT NULL,
    limits jsonb DEFAULT jsonb_build_object('max_rows_per_table', 100000, 'max_storage_mb', 500, 'max_auth_users', 10000, 'max_rpc_calls_per_day', 50000) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT apps_tenants_auth_provider_check CHECK ((auth_provider = ANY (ARRAY['supabase'::text, 'auth0'::text]))),
    CONSTRAINT apps_tenants_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'destroyed'::text])))
);


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    file_path text NOT NULL,
    file_type text NOT NULL,
    file_size integer,
    metadata jsonb DEFAULT '{}'::jsonb,
    is_public boolean DEFAULT false,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    instance_id uuid
);


--
-- Name: audience_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audience_leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    audience_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    page_number integer DEFAULT 1 NOT NULL,
    send_status text DEFAULT 'pending'::text NOT NULL,
    sent_at timestamp with time zone,
    error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audience_leads_send_status_check CHECK ((send_status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text, 'skipped'::text])))
);


--
-- Name: audiences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audiences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    instance_id uuid,
    filters jsonb DEFAULT '{}'::jsonb,
    total_count integer DEFAULT 0 NOT NULL,
    page_size integer DEFAULT 50 NOT NULL,
    status text DEFAULT 'building'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audiences_status_check CHECK ((status = ANY (ARRAY['building'::text, 'ready'::text, 'error'::text])))
);


--
-- Name: automation_auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.automation_auth_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    provider_auth_state_id text,
    domain text NOT NULL,
    auth_type text NOT NULL,
    auth_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    browser_type text DEFAULT 'chrome'::text,
    user_agent text,
    viewport jsonb DEFAULT '{"width": 1920, "height": 1080}'::jsonb,
    last_used_at timestamp with time zone,
    usage_count integer DEFAULT 0,
    is_valid boolean DEFAULT true,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    instance_id uuid,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    CONSTRAINT automation_auth_sessions_auth_type_check CHECK ((auth_type = ANY (ARRAY['cookies'::text, 'localStorage'::text, 'sessionStorage'::text, 'credentials'::text, 'oauth'::text])))
);


--
-- Name: billing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid NOT NULL,
    plan character varying(50) DEFAULT 'free'::character varying NOT NULL,
    card_name character varying(255),
    masked_card_number character varying(19),
    card_expiry character varying(7),
    stripe_customer_id character varying(255),
    stripe_payment_method_id character varying(255),
    card_address character varying(255),
    card_city character varying(100),
    card_postal_code character varying(20),
    card_country character varying(100),
    tax_id character varying(100),
    billing_address character varying(255),
    billing_city character varying(100),
    billing_postal_code character varying(20),
    billing_country character varying(100),
    auto_renew boolean DEFAULT true,
    credits_available numeric DEFAULT 0,
    credits_used numeric DEFAULT 0,
    subscription_start_date timestamp with time zone,
    subscription_end_date timestamp with time zone,
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    command_id uuid,
    stripe_subscription_id text,
    subscription_status text,
    subscription_current_period_end timestamp with time zone,
    account_balance numeric DEFAULT 0,
    addons_count integer DEFAULT 0 NOT NULL,
    plan_credits_available numeric DEFAULT 0 NOT NULL,
    purchased_credits_available numeric DEFAULT 0 NOT NULL,
    legacy_credits_available numeric DEFAULT 0 NOT NULL,
    monthly_credits_used numeric DEFAULT 0 NOT NULL,
    plan_credits_used numeric DEFAULT 0 NOT NULL,
    plan_credit_allowance numeric DEFAULT 0 NOT NULL,
    plan_credit_source text DEFAULT 'migration'::text NOT NULL,
    plan_credit_period_start timestamp with time zone,
    plan_credit_period_end timestamp with time zone,
    billing_interval text DEFAULT 'month'::text NOT NULL,
    paid_subscription_period_start timestamp with time zone,
    paid_subscription_period_end timestamp with time zone,
    paid_subscription_invoice_id text,
    paid_subscription_paid_at timestamp with time zone,
    plan_credit_anchor timestamp with time zone,
    paid_subscription_plan text,
    paid_subscription_addons_count integer,
    trial_credits_available numeric DEFAULT 0 NOT NULL,
    trial_started_at timestamp with time zone,
    trial_ends_at timestamp with time zone,
    trial_converted_at timestamp with time zone,
    CONSTRAINT billing_billing_interval_check CHECK ((billing_interval = ANY (ARRAY['month'::text, 'year'::text]))),
    CONSTRAINT billing_credit_buckets_valid CHECK (((plan_credits_available >= (0)::numeric) AND (purchased_credits_available >= (0)::numeric) AND (legacy_credits_available >= (0)::numeric) AND (trial_credits_available >= (0)::numeric) AND (trial_credits_available <= (50)::numeric) AND (monthly_credits_used >= (0)::numeric) AND (plan_credits_used >= (0)::numeric) AND (plan_credit_allowance >= (0)::numeric) AND (credits_available = (((plan_credits_available + purchased_credits_available) + legacy_credits_available) + trial_credits_available)) AND ((credits_available)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])) AND ((monthly_credits_used)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])) AND ((plan_credits_used)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])) AND ((plan_credit_allowance)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])) AND (((plan_credit_period_start IS NULL) AND (plan_credit_period_end IS NULL)) OR ((plan_credit_period_start IS NOT NULL) AND (plan_credit_period_end IS NOT NULL) AND isfinite(plan_credit_period_start) AND isfinite(plan_credit_period_end) AND (plan_credit_period_end > plan_credit_period_start))) AND (((trial_started_at IS NULL) AND (trial_ends_at IS NULL) AND (trial_credits_available = (0)::numeric)) OR ((trial_started_at IS NOT NULL) AND (trial_ends_at IS NOT NULL) AND (trial_ends_at = (trial_started_at + '360:00:00'::interval)) AND isfinite(trial_started_at) AND isfinite(trial_ends_at))) AND ((trial_converted_at IS NULL) OR (isfinite(trial_converted_at) AND (trial_credits_available = (0)::numeric))))),
    CONSTRAINT billing_paid_subscription_coverage_valid CHECK ((((paid_subscription_period_start IS NULL) AND (paid_subscription_period_end IS NULL) AND (paid_subscription_invoice_id IS NULL) AND (paid_subscription_plan IS NULL) AND (paid_subscription_addons_count IS NULL) AND (paid_subscription_paid_at IS NULL)) OR ((paid_subscription_period_start IS NOT NULL) AND (paid_subscription_period_end IS NOT NULL) AND isfinite(paid_subscription_period_start) AND isfinite(paid_subscription_period_end) AND (paid_subscription_period_end > paid_subscription_period_start) AND (paid_subscription_invoice_id IS NOT NULL) AND (paid_subscription_invoice_id ~ '^in_[A-Za-z0-9]+$'::text) AND (paid_subscription_paid_at IS NOT NULL) AND isfinite(paid_subscription_paid_at) AND (paid_subscription_plan IS NOT NULL) AND (paid_subscription_plan = ANY (ARRAY['commission'::text, 'engine'::text, 'foundry'::text, 'enterprise'::text])) AND (paid_subscription_addons_count IS NOT NULL) AND ((paid_subscription_addons_count >= 0) AND (paid_subscription_addons_count <= 100)) AND ((paid_subscription_plan <> 'commission'::text) OR (paid_subscription_addons_count > 0)) AND (stripe_subscription_id IS NOT NULL)))),
    CONSTRAINT billing_plan_credit_anchor_check CHECK (((plan_credit_anchor IS NULL) OR isfinite(plan_credit_anchor)))
);


--
-- Name: billing_credit_grant_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_credit_grant_keys (
    idempotency_key text NOT NULL,
    site_id uuid NOT NULL,
    amount numeric NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT billing_credit_grant_keys_amount_check CHECK (((amount > (0)::numeric) AND ((amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text]))))
);


--
-- Name: billing_credit_migration_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_credit_migration_audit (
    site_id uuid NOT NULL,
    previous_plan text,
    previous_subscription_status text,
    previous_credits_available numeric NOT NULL,
    previous_credits_used numeric NOT NULL,
    previous_account_balance numeric NOT NULL,
    protected_purchase_upper_bound numeric NOT NULL,
    protected_unclassified_credits numeric NOT NULL,
    expired_plan_credits numeric NOT NULL,
    migrated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: calendar_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_blocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaign_requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_requirements (
    campaign_id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    command_id uuid
);


--
-- Name: campaign_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_segments (
    campaign_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    command_id uuid
);


--
-- Name: campaign_subtasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_subtasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    title text NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    CONSTRAINT campaign_subtasks_status_check CHECK ((status = ANY (ARRAY['completed'::text, 'in-progress'::text, 'pending'::text])))
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    priority public.campaign_priority DEFAULT 'medium'::public.campaign_priority NOT NULL,
    status public.campaign_status DEFAULT 'pending'::public.campaign_status NOT NULL,
    due_date date,
    assignees integer DEFAULT 0,
    issues integer DEFAULT 0,
    revenue jsonb DEFAULT '{"actual": 0, "currency": "USD", "estimated": 0, "projected": 0}'::jsonb,
    budget jsonb DEFAULT '{"currency": "USD", "allocated": 0, "remaining": 0}'::jsonb,
    type text NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- Name: catalog_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    income_account_key text,
    cogs_account_key text,
    status text DEFAULT 'active'::text NOT NULL,
    CONSTRAINT catalog_categories_status_check CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text])))
);


--
-- Name: catalog_embedding_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_embedding_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    catalog_item_id uuid NOT NULL,
    site_id uuid NOT NULL,
    source_hash text NOT NULL,
    source_revision bigint NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    claim_token uuid,
    lease_expires_at timestamp with time zone,
    attempts integer DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    last_error text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT catalog_embedding_jobs_attempts_check CHECK ((attempts >= 0)),
    CONSTRAINT catalog_embedding_jobs_check CHECK (((status = 'leased'::text) = ((claim_token IS NOT NULL) AND (lease_expires_at IS NOT NULL)))),
    CONSTRAINT catalog_embedding_jobs_source_revision_check CHECK ((source_revision > 0)),
    CONSTRAINT catalog_embedding_jobs_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'leased'::text, 'retry'::text, 'done'::text, 'exhausted'::text])))
);


--
-- Name: catalog_import_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_import_batches (
    site_id uuid NOT NULL,
    request_id uuid NOT NULL,
    actor_id uuid NOT NULL,
    payload jsonb NOT NULL,
    result jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT statement_timestamp() NOT NULL,
    CONSTRAINT catalog_import_batches_payload_check CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT catalog_import_batches_result_check CHECK ((jsonb_typeof(result) = 'object'::text))
);

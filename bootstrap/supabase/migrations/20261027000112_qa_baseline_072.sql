SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visitor_id uuid,
    agent_id uuid,
    user_id uuid,
    lead_id uuid,
    site_id uuid,
    status text DEFAULT 'active'::text,
    title text,
    custom_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_message_at timestamp with time zone,
    is_archived boolean DEFAULT false,
    command_id uuid,
    flag integer DEFAULT 0,
    delegate_id uuid,
    channel text,
    last_message_preview jsonb,
    message_count bigint DEFAULT 0 NOT NULL,
    location_id uuid
);


--
-- Name: copywriting; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.copywriting (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    copy_type text NOT NULL,
    target_audience text,
    use_case text,
    notes text,
    tags text[] DEFAULT '{}'::text[],
    status text DEFAULT 'draft'::text NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT copywriting_copy_type_check CHECK ((copy_type = ANY (ARRAY['tweet'::text, 'pitch'::text, 'blurb'::text, 'cold_email'::text, 'cold_call'::text, 'social_post'::text, 'ad_copy'::text, 'landing_page'::text, 'email_subject'::text, 'product_description'::text, 'tagline'::text, 'call_to_action'::text, 'other'::text]))),
    CONSTRAINT copywriting_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'review'::text, 'approved'::text, 'published'::text, 'archived'::text])))
);


--
-- Name: credit_auto_top_up_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_auto_top_up_attempts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    credits integer NOT NULL,
    amount_cents integer NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    stripe_customer_id text NOT NULL,
    stripe_payment_method_id text NOT NULL,
    stripe_payment_intent_id text,
    claim_token uuid DEFAULT gen_random_uuid() NOT NULL,
    claim_expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    settings_revision bigint DEFAULT 0 NOT NULL,
    dispatch_started_at timestamp with time zone,
    CONSTRAINT credit_auto_top_up_attempt_finished CHECK ((((status = 'pending'::text) AND (finished_at IS NULL)) OR ((status <> 'pending'::text) AND (finished_at IS NOT NULL)))),
    CONSTRAINT credit_auto_top_up_attempts_check CHECK ((amount_cents = (credits * 100))),
    CONSTRAINT credit_auto_top_up_attempts_credits_check CHECK (((credits >= 1) AND (credits <= 1000000))),
    CONSTRAINT credit_auto_top_up_attempts_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'succeeded'::text, 'failed'::text]))),
    CONSTRAINT credit_auto_top_up_attempts_stripe_customer_id_check CHECK ((stripe_customer_id ~ '^cus_[A-Za-z0-9]+$'::text)),
    CONSTRAINT credit_auto_top_up_attempts_stripe_payment_intent_id_check CHECK (((stripe_payment_intent_id IS NULL) OR (stripe_payment_intent_id ~ '^pi_[A-Za-z0-9]+$'::text))),
    CONSTRAINT credit_auto_top_up_attempts_stripe_payment_method_id_check CHECK ((stripe_payment_method_id ~ '^pm_[A-Za-z0-9]+$'::text))
);


--
-- Name: credit_auto_top_up_card_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_auto_top_up_card_setups (
    site_id uuid NOT NULL,
    token uuid NOT NULL,
    actor_id uuid NOT NULL,
    stripe_customer_id text NOT NULL,
    status text NOT NULL,
    stripe_payment_method_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    source text DEFAULT 'top_up'::text NOT NULL,
    CONSTRAINT credit_auto_top_up_card_setups_source_check CHECK ((source = ANY (ARRAY['billing'::text, 'top_up'::text]))),
    CONSTRAINT credit_auto_top_up_card_setups_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text])))
);


--
-- Name: credit_auto_top_up_consent_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_auto_top_up_consent_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    actor_id uuid NOT NULL,
    recorded_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    settings_revision bigint NOT NULL,
    settings_snapshot jsonb NOT NULL,
    unit_price_cents integer DEFAULT 100 NOT NULL,
    CONSTRAINT credit_auto_top_up_consent_log_unit_price_cents_check CHECK ((unit_price_cents = 100))
);


--
-- Name: credit_auto_top_up_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_auto_top_up_settings (
    site_id uuid NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    minimum_credits numeric DEFAULT 5 NOT NULL,
    target_credits numeric DEFAULT 20 NOT NULL,
    max_monthly_spend_cents integer DEFAULT 10000 NOT NULL,
    stripe_payment_method_id text,
    state text DEFAULT 'ready'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    settings_revision bigint DEFAULT 1 NOT NULL,
    CONSTRAINT credit_auto_top_up_settings_bounds CHECK (((minimum_credits >= (0)::numeric) AND (minimum_credits <= (1000000)::numeric) AND (target_credits > minimum_credits) AND (target_credits <= (1000000)::numeric) AND ((minimum_credits)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])) AND ((target_credits)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])) AND ((max_monthly_spend_cents >= 100) AND (max_monthly_spend_cents <= 100000000)) AND ((stripe_payment_method_id IS NULL) OR (stripe_payment_method_id ~ '^pm_[A-Za-z0-9]+$'::text)))),
    CONSTRAINT credit_auto_top_up_settings_settings_revision_check CHECK ((settings_revision > 0)),
    CONSTRAINT credit_auto_top_up_settings_state_check CHECK ((state = ANY (ARRAY['ready'::text, 'paused'::text])))
);


--
-- Name: credit_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_transactions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid NOT NULL,
    amount numeric NOT NULL,
    transaction_type character varying NOT NULL,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: cron_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cron_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id text,
    schedule_id text,
    activity_name text,
    status text DEFAULT 'pending'::text NOT NULL,
    last_run timestamp with time zone,
    next_run timestamp with time zone,
    error_message text,
    retry_count integer DEFAULT 0,
    site_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    progress smallint DEFAULT '0'::smallint
);


--
-- Name: customizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    element_id uuid NOT NULL,
    key text NOT NULL,
    value jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: deal_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deal_leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deal_id uuid,
    lead_id uuid,
    role text,
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: deal_owners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deal_owners (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deal_id uuid,
    user_id uuid,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: deals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    amount numeric,
    currency text DEFAULT 'USD'::text,
    stage text DEFAULT 'prospecting'::text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    company_id uuid,
    site_id uuid,
    expected_close_date date,
    notes text,
    qualification_score numeric DEFAULT 0,
    qualification_criteria jsonb DEFAULT '{}'::jsonb,
    sales_order_id uuid,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    accepted_quotation_id uuid,
    user_id uuid DEFAULT auth.uid(),
    location_id uuid
);


--
-- Name: debug_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.debug_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    operation text,
    user_id uuid,
    site_id uuid,
    details jsonb,
    created_at timestamp with time zone DEFAULT now(),
    command_id uuid
);


--
-- Name: deployment_recovery_scan_leases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_recovery_scan_leases (
    lease_key text NOT NULL,
    owner_id text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT deployment_recovery_scan_leases_lease_key_check CHECK (((char_length(lease_key) >= 1) AND (char_length(lease_key) <= 100))),
    CONSTRAINT deployment_recovery_scan_leases_owner_id_check CHECK (((char_length(owner_id) >= 1) AND (char_length(owner_id) <= 200)))
);


--
-- Name: editor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.editor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    site jsonb DEFAULT '{}'::jsonb,
    campaigns jsonb DEFAULT '[]'::jsonb,
    customizations jsonb DEFAULT '{}'::jsonb,
    variants jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.elements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    layer_id uuid NOT NULL,
    text text,
    type text NOT NULL,
    props jsonb DEFAULT '{}'::jsonb,
    value text,
    code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: entitlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entitlements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    buyer_user_id uuid NOT NULL,
    owner_site_id uuid,
    catalog_item_id uuid NOT NULL,
    source_type text NOT NULL,
    source_id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    uses_total integer,
    uses_remaining integer,
    CONSTRAINT entitlements_source_type_check CHECK ((source_type = ANY (ARRAY['purchase'::text, 'subscription'::text]))),
    CONSTRAINT entitlements_status_check CHECK ((status = ANY (ARRAY['active'::text, 'revoked'::text, 'expired'::text, 'used'::text])))
);


--
-- Name: experiment_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_segments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    experiment_id uuid,
    segment_id uuid,
    participants integer DEFAULT 0,
    command_id uuid
);


--
-- Name: experiments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    status text NOT NULL,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    conversion numeric,
    roi numeric,
    preview_url text,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    hypothesis text,
    campaign_id uuid,
    command_id uuid,
    instructions text,
    validations text,
    CONSTRAINT experiments_status_check CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'draft'::text])))
);


--
-- Name: external_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_resources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key text NOT NULL,
    url text NOT NULL,
    description text,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid
);


--
-- Name: harness_artifact_reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_artifact_reservations (
    session_id uuid NOT NULL,
    site_id uuid NOT NULL,
    operation_id text NOT NULL,
    bytes integer NOT NULL,
    CONSTRAINT harness_artifact_reservations_bytes_check CHECK (((bytes >= 0) AND (bytes <= 1048576))),
    CONSTRAINT harness_artifact_reservations_operation_id_check CHECK (((length(operation_id) >= 1) AND (length(operation_id) <= 1000)))
);


--
-- Name: harness_artifacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_artifacts (
    session_id uuid NOT NULL,
    site_id uuid NOT NULL,
    id text NOT NULL,
    operation_id text NOT NULL,
    content text NOT NULL,
    bytes integer GENERATED ALWAYS AS (octet_length(content)) STORED,
    CONSTRAINT harness_artifacts_content_check CHECK ((octet_length(content) <= 1048576)),
    CONSTRAINT harness_artifacts_id_check CHECK ((id ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT harness_artifacts_operation_id_check CHECK (((length(operation_id) >= 1) AND (length(operation_id) <= 1000)))
);


--
-- Name: harness_host_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_host_state (
    session_id uuid NOT NULL,
    site_id uuid NOT NULL,
    version bigint NOT NULL,
    ciphertext text NOT NULL,
    CONSTRAINT harness_host_state_ciphertext_check CHECK (((octet_length(ciphertext) <= 262144) AND (ciphertext ~ '^v1\.[A-Za-z0-9+/]{16}\.[A-Za-z0-9+/]{22}==\.[A-Za-z0-9+/]+={0,2}$'::text))),
    CONSTRAINT harness_host_state_version_check CHECK (((version >= 1) AND (version <= '9007199254740990'::bigint)))
);


--
-- Name: harness_model_credit_reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_model_credit_reservations (
    session_id uuid NOT NULL,
    event_id uuid NOT NULL,
    site_id uuid NOT NULL,
    requirement_id uuid,
    amount numeric NOT NULL,
    plan_spent numeric NOT NULL,
    legacy_spent numeric NOT NULL,
    purchased_spent numeric NOT NULL,
    period_start timestamp with time zone,
    period_end timestamp with time zone,
    state text DEFAULT 'reserved'::text NOT NULL,
    provider_cost numeric,
    generation_id text,
    model text,
    charged numeric,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    settled_at timestamp with time zone,
    trial_spent numeric DEFAULT 0 NOT NULL,
    trial_ends_at timestamp with time zone,
    CONSTRAINT harness_model_credit_reservations_amount_check CHECK (((amount > (0)::numeric) AND (amount <= (1000)::numeric) AND ((amount)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT harness_model_credit_reservations_check CHECK (((plan_spent >= (0)::numeric) AND (legacy_spent >= (0)::numeric) AND (purchased_spent >= (0)::numeric) AND (trial_spent >= (0)::numeric) AND (amount = (((plan_spent + legacy_spent) + purchased_spent) + trial_spent)) AND ((trial_spent = (0)::numeric) OR ((trial_ends_at IS NOT NULL) AND isfinite(trial_ends_at))))),
    CONSTRAINT harness_model_credit_reservations_provider_cost_check CHECK (((provider_cost >= (0)::numeric) AND ((provider_cost)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text])))),
    CONSTRAINT harness_model_credit_reservations_state_check CHECK ((state = ANY (ARRAY['reserved'::text, 'dispatched'::text, 'pending'::text, 'settled'::text, 'cancelled'::text])))
);


--
-- Name: harness_requirement_credit_reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_requirement_credit_reservations (
    session_id uuid NOT NULL,
    event_id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    amount numeric NOT NULL,
    result jsonb NOT NULL,
    CONSTRAINT harness_requirement_credit_reservations_amount_check CHECK (((amount > (0)::numeric) AND (amount <= (1000)::numeric)))
);


--
-- Name: harness_requirement_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harness_requirement_runs (
    requirement_id uuid NOT NULL,
    site_id uuid NOT NULL,
    session_id uuid NOT NULL,
    previous_session_id uuid,
    generation integer NOT NULL,
    next_run_at timestamp with time zone,
    pause_reason text,
    last_cycle_id text,
    workspace_id text,
    CONSTRAINT harness_requirement_runs_generation_check CHECK ((generation >= 0))
);

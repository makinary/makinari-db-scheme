SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.states (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    section_id uuid NOT NULL,
    name text NOT NULL,
    "order" integer NOT NULL,
    frame jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: stripe_sale_checkout_effects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stripe_sale_checkout_effects (
    stripe_session_id text NOT NULL,
    sale_reference text NOT NULL,
    sale_id uuid,
    order_id uuid,
    payment_intent_id text,
    amount_minor bigint NOT NULL,
    currency text NOT NULL,
    settlement_status text NOT NULL,
    rejection_reason text,
    financial_status text DEFAULT 'pending'::text NOT NULL,
    financial_completed_at timestamp with time zone,
    fulfillment_status text DEFAULT 'pending'::text NOT NULL,
    fulfillment_claim_token uuid,
    fulfillment_claimed_at timestamp with time zone,
    fulfillment_completed_at timestamp with time zone,
    inventory_completed_at timestamp with time zone,
    compensation_status text DEFAULT 'not_required'::text NOT NULL,
    compensation_claim_token uuid,
    compensation_claimed_at timestamp with time zone,
    compensation_completed_at timestamp with time zone,
    stripe_refund_id text,
    compensation_error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT stripe_sale_checkout_effects_compensation_status_check CHECK ((compensation_status = ANY (ARRAY['not_required'::text, 'processing'::text, 'failed'::text, 'refunded'::text, 'manual_review'::text]))),
    CONSTRAINT stripe_sale_checkout_effects_financial_status_check CHECK ((financial_status = ANY (ARRAY['pending'::text, 'completed'::text, 'not_required'::text]))),
    CONSTRAINT stripe_sale_checkout_effects_fulfillment_status_check CHECK ((fulfillment_status = ANY (ARRAY['pending'::text, 'processing'::text, 'failed'::text, 'completed'::text, 'not_required'::text]))),
    CONSTRAINT stripe_sale_checkout_effects_settlement_status_check CHECK ((settlement_status = ANY (ARRAY['settled'::text, 'rejected'::text])))
);


--
-- Name: stripe_subscription_invoice_settlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stripe_subscription_invoice_settlements (
    invoice_id text NOT NULL,
    site_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    customer_id text NOT NULL,
    subscription_id text NOT NULL,
    amount numeric NOT NULL,
    currency text NOT NULL,
    credits_granted integer NOT NULL,
    event_id text,
    settled_at timestamp with time zone DEFAULT now() NOT NULL,
    verified_credit_coverage jsonb,
    credit_coverage_applied boolean DEFAULT false NOT NULL,
    CONSTRAINT stripe_subscription_invoice_settlements_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT stripe_subscription_invoice_settlements_credits_granted_check CHECK ((credits_granted >= 0)),
    CONSTRAINT stripe_subscription_invoice_settlements_invoice_id_check CHECK ((invoice_id ~~ 'in\_%'::text))
);


--
-- Name: subscription_plan_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_plan_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    plan_catalog_item_id uuid NOT NULL,
    digital_catalog_item_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    start_date timestamp with time zone DEFAULT now() NOT NULL,
    next_billing_date timestamp with time zone,
    amount numeric NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    buyer_user_id uuid,
    owner_site_id uuid,
    end_date timestamp with time zone,
    due_date date,
    location_id uuid,
    CONSTRAINT subscriptions_due_date_calendar_check CHECK (((due_date IS NULL) OR (isfinite(due_date) AND ((due_date >= '0001-01-01'::date) AND (due_date <= '9999-12-31'::date))))),
    CONSTRAINT subscriptions_status_check CHECK ((status = ANY (ARRAY['active'::text, 'paused'::text, 'cancelled'::text, 'expired'::text])))
);


--
-- Name: synced_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.synced_objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    external_id text NOT NULL,
    site_id uuid NOT NULL,
    object_type text DEFAULT 'email'::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    provider text,
    first_seen_at timestamp with time zone DEFAULT now(),
    last_processed_at timestamp with time zone,
    process_count integer DEFAULT 0,
    metadata jsonb DEFAULT '{}'::jsonb,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    hash numeric(20,0),
    claim_token uuid,
    claim_expires_at timestamp with time zone,
    CONSTRAINT synced_objects_hash_uint64_check CHECK (((hash IS NULL) OR ((hash >= (0)::numeric) AND (hash <= '18446744073709551615'::numeric))))
);


--
-- Name: system_memories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_memories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid,
    system_type text NOT NULL,
    key text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    raw_data text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    access_count integer DEFAULT 0,
    last_accessed timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone,
    command_id uuid
);


--
-- Name: system_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid NOT NULL,
    trigger text NOT NULL,
    system_key text NOT NULL,
    status text NOT NULL,
    summary text,
    probe_path text,
    http_status integer,
    latency_ms integer DEFAULT 0 NOT NULL,
    error_message text,
    health_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT system_status_status_check CHECK ((status = ANY (ARRAY['up'::text, 'degraded'::text, 'down'::text, 'skipped'::text])))
);

ALTER TABLE ONLY public.system_status FORCE ROW LEVEL SECURITY;


--
-- Name: system_status_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_status_runs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trigger text NOT NULL,
    environment text,
    overall_status text NOT NULL,
    sla_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    checks_passed integer DEFAULT 0 NOT NULL,
    checks_failed integer DEFAULT 0 NOT NULL,
    checks_degraded integer DEFAULT 0 NOT NULL,
    duration_ms integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT system_status_runs_overall_status_check CHECK ((overall_status = ANY (ARRAY['healthy'::text, 'degraded'::text, 'down'::text]))),
    CONSTRAINT system_status_runs_trigger_check CHECK ((trigger = ANY (ARRAY['github_push'::text, 'cron_hourly'::text, 'manual'::text])))
);

ALTER TABLE ONLY public.system_status_runs FORCE ROW LEVEL SECURITY;


--
-- Name: system_telemetry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_telemetry (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    system_key text NOT NULL,
    status text NOT NULL,
    message text,
    latency_ms integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT system_telemetry_status_check CHECK ((status = ANY (ARRAY['up'::text, 'degraded'::text, 'down'::text])))
);

ALTER TABLE ONLY public.system_telemetry FORCE ROW LEVEL SECURITY;


--
-- Name: task_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_categories (
    task_id uuid NOT NULL,
    category_id uuid NOT NULL
);


--
-- Name: task_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid NOT NULL,
    user_id uuid NOT NULL,
    content text NOT NULL,
    attachments jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_private boolean DEFAULT false NOT NULL,
    files jsonb DEFAULT '[]'::jsonb NOT NULL,
    cta jsonb DEFAULT '{}'::jsonb
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lead_id uuid,
    title text NOT NULL,
    description text,
    type text NOT NULL,
    stage text NOT NULL,
    status text NOT NULL,
    scheduled_date timestamp with time zone NOT NULL,
    completed_date timestamp with time zone,
    amount numeric(10,2),
    assignee uuid,
    notes text,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    serial_id text NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    address jsonb,
    conversation_id uuid,
    deal_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    location_id uuid,
    CONSTRAINT tasks_stage_check CHECK ((stage = ANY (ARRAY['awareness'::text, 'consideration'::text, 'decision'::text, 'purchase'::text, 'retention'::text, 'referral'::text]))),
    CONSTRAINT tasks_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text, 'failed'::text, 'canceled'::text])))
);


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taxes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    name text NOT NULL,
    rate numeric DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT taxes_rate_check CHECK (((rate >= (0)::numeric) AND (rate <= (100)::numeric)))
);


--
-- Name: tenant_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_users (
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid,
    type text NOT NULL,
    amount numeric NOT NULL,
    description text,
    date date NOT NULL,
    currency text DEFAULT 'USD'::text,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    category text,
    location_id uuid,
    lead_id uuid,
    segment_id uuid,
    catalog_item_id uuid,
    catalog_category_id uuid,
    company_id uuid,
    accounting_state text DEFAULT 'pending'::text NOT NULL,
    sale_order_id uuid,
    CONSTRAINT transactions_accounting_state_check CHECK ((accounting_state = ANY (ARRAY['pending'::text, 'posted'::text, 'unpublished'::text]))),
    CONSTRAINT transactions_type_check CHECK ((type = ANY (ARRAY['fixed'::text, 'variable'::text])))
);


--
-- Name: transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_state_id uuid NOT NULL,
    to_state_id uuid NOT NULL,
    duration numeric NOT NULL,
    effects jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transitions_no_self_reference CHECK ((from_state_id <> to_state_id))
);


--
-- Name: user_shortcuts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_shortcuts (
    user_id uuid NOT NULL,
    shortcuts jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    site_id uuid NOT NULL
);


--
-- Name: user_site_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_site_notifications (
    user_id uuid NOT NULL,
    site_id uuid NOT NULL,
    email_enabled boolean DEFAULT true NOT NULL,
    push_enabled boolean DEFAULT true NOT NULL,
    categories jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    state_id uuid NOT NULL,
    name text NOT NULL,
    overrides jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: visitor_external_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_external_identities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    issuer text NOT NULL,
    external_user_id text NOT NULL,
    lead_id uuid NOT NULL,
    display_name text,
    asserted_email text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT visitor_external_identities_asserted_email_check CHECK ((length(asserted_email) <= 320)),
    CONSTRAINT visitor_external_identities_display_name_check CHECK ((length(display_name) <= 200)),
    CONSTRAINT visitor_external_identities_external_user_id_check CHECK (((length(external_user_id) >= 1) AND (length(external_user_id) <= 255))),
    CONSTRAINT visitor_external_identities_issuer_check CHECK (((length(issuer) >= 1) AND (length(issuer) <= 100)))
);

ALTER TABLE ONLY public.visitor_external_identities FORCE ROW LEVEL SECURITY;


--
-- Name: visitor_identity_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_identity_attributes (
    session_id uuid NOT NULL,
    attributes jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.visitor_identity_attributes FORCE ROW LEVEL SECURITY;


--
-- Name: visitor_identity_challenges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_identity_challenges (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    session_id uuid NOT NULL,
    visitor_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    normalized_email text NOT NULL,
    masked_email text NOT NULL,
    otp_hash text NOT NULL,
    request_ip_hash text,
    attempts integer DEFAULT 0 NOT NULL,
    resend_count integer DEFAULT 0 NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    resend_available_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT visitor_identity_challenges_attempts_check CHECK (((attempts >= 0) AND (attempts <= 5))),
    CONSTRAINT visitor_identity_challenges_resend_count_check CHECK (((resend_count >= 0) AND (resend_count <= 3)))
);

ALTER TABLE ONLY public.visitor_identity_challenges FORCE ROW LEVEL SECURITY;


--
-- Name: visitor_identity_session_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_identity_session_state (
    session_id uuid NOT NULL,
    epoch bigint DEFAULT 0 NOT NULL,
    CONSTRAINT visitor_identity_session_state_epoch_check CHECK ((epoch >= 0))
);

ALTER TABLE ONLY public.visitor_identity_session_state FORCE ROW LEVEL SECURITY;

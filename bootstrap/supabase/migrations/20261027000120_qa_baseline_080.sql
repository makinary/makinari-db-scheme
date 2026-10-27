SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: visitor_identity_token_redemptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_identity_token_redemptions (
    jti uuid NOT NULL,
    site_id uuid NOT NULL,
    session_id uuid NOT NULL,
    visitor_id uuid NOT NULL,
    identity_id uuid NOT NULL,
    issuer_key_id uuid,
    epoch bigint NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT visitor_identity_token_redemptions_token_hash_check CHECK ((token_hash ~ '^[a-f0-9]{64}$'::text))
);

ALTER TABLE ONLY public.visitor_identity_token_redemptions FORCE ROW LEVEL SECURITY;


--
-- Name: visitor_session_identity_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_session_identity_grants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    session_id uuid NOT NULL,
    visitor_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    trusted_token_hash text,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.visitor_session_identity_grants FORCE ROW LEVEL SECURITY;


--
-- Name: visitor_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitor_sessions (
    id uuid NOT NULL,
    visitor_id uuid NOT NULL,
    site_id uuid NOT NULL,
    landing_url text,
    current_url text,
    referrer text,
    utm_source text,
    utm_medium text,
    utm_campaign text,
    utm_term text,
    utm_content text,
    started_at bigint NOT NULL,
    last_activity_at bigint NOT NULL,
    page_views integer DEFAULT 1,
    device jsonb,
    browser jsonb,
    location jsonb,
    previous_session_id uuid,
    performance jsonb,
    consent jsonb,
    is_active boolean DEFAULT true,
    duration bigint,
    active_time bigint,
    idle_time bigint,
    lead_id uuid,
    exit_url text,
    exit_type text,
    custom_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    command_id uuid,
    identified_at bigint,
    lead_data jsonb
);


--
-- Name: visitors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visitors (
    id uuid NOT NULL,
    first_seen_at bigint NOT NULL,
    last_seen_at bigint NOT NULL,
    total_sessions integer DEFAULT 1,
    total_page_views integer DEFAULT 0,
    total_time_spent bigint DEFAULT 0,
    first_url text,
    first_referrer text,
    first_utm_source text,
    first_utm_medium text,
    first_utm_campaign text,
    first_utm_term text,
    first_utm_content text,
    custom_data jsonb,
    lead_id uuid,
    is_identified boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    fingerprint text,
    command_id uuid,
    segment_id uuid,
    campaign_id uuid,
    experiment_id uuid
);


--
-- Name: voice_call_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voice_call_deliveries (
    id uuid NOT NULL,
    site_id uuid NOT NULL,
    message_id uuid NOT NULL,
    conversation_id uuid,
    lead_id uuid,
    audience_id uuid,
    zavu_sender_id text NOT NULL,
    zavu_call_id text,
    recipient_phone text NOT NULL,
    status text DEFAULT 'placing'::text NOT NULL,
    placement_attempt_token uuid NOT NULL,
    error_message text,
    duration_seconds integer,
    end_reason text,
    turn_count integer,
    cost numeric(14,6),
    currency text,
    transcript jsonb,
    provider_created_at timestamp with time zone,
    answered_at timestamp with time zone,
    ended_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT voice_call_deliveries_cost_nonnegative CHECK (((cost IS NULL) OR (cost >= (0)::numeric))),
    CONSTRAINT voice_call_deliveries_duration_nonnegative CHECK (((duration_seconds IS NULL) OR (duration_seconds >= 0))),
    CONSTRAINT voice_call_deliveries_phone_e164 CHECK ((recipient_phone ~ '^\+[1-9][0-9]{6,14}$'::text)),
    CONSTRAINT voice_call_deliveries_status_valid CHECK ((status = ANY (ARRAY['placing'::text, 'placement_unknown'::text, 'queued'::text, 'ringing'::text, 'in_progress'::text, 'completed'::text, 'failed'::text, 'busy'::text, 'no_answer'::text, 'canceled'::text]))),
    CONSTRAINT voice_call_deliveries_turn_count_nonnegative CHECK (((turn_count IS NULL) OR (turn_count >= 0)))
);


--
-- Name: waitlist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.waitlist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    name text,
    referral_code_attempted text,
    source text DEFAULT 'signup'::text,
    status text DEFAULT 'pending'::text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT waitlist_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'converted'::text])))
);


--
-- Name: webhook_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    stripe_event_id character varying(255) NOT NULL,
    event_type character varying(100) NOT NULL,
    processed_at timestamp with time zone DEFAULT now(),
    status character varying(50) DEFAULT 'processed'::character varying NOT NULL,
    event_data jsonb DEFAULT '{}'::jsonb,
    error_message text,
    site_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    claim_token uuid,
    claimed_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT webhook_events_status_check CHECK (((status)::text = ANY ((ARRAY['processing'::character varying, 'processed'::character varying, 'failed'::character varying, 'skipped'::character varying])::text[])))
);


--
-- Name: webhooks_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhooks_deliveries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    endpoint_id uuid NOT NULL,
    subscription_id uuid,
    event_type text NOT NULL,
    payload jsonb NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp with time zone,
    response_status integer,
    response_body text,
    last_error text,
    delivered_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: webhooks_endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhooks_endpoints (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    created_by uuid NOT NULL,
    name text NOT NULL,
    description text,
    target_url text NOT NULL,
    secret text,
    is_active boolean DEFAULT true NOT NULL,
    handshake_status text DEFAULT 'pending'::text,
    handshake_token text,
    handshake_verified_at timestamp with time zone,
    last_handshake_error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: webhooks_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhooks_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    endpoint_id uuid NOT NULL,
    event_type text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    filters jsonb DEFAULT '{}'::jsonb
);


--
-- Name: whatsapp_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.whatsapp_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_sid text NOT NULL,
    template_name text NOT NULL,
    content text NOT NULL,
    original_message text,
    site_id uuid NOT NULL,
    account_sid text NOT NULL,
    status text DEFAULT 'active'::text,
    language text DEFAULT 'es'::text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp with time zone,
    usage_count integer DEFAULT 0,
    templated_body text,
    placeholder_map jsonb,
    CONSTRAINT whatsapp_templates_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'pending'::text, 'failed'::text, 'rejected'::text, 'paused'::text, 'disabled'::text, 'approved'::text, 'received'::text])))
);


--
-- Name: workflow_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_runs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instance_id uuid NOT NULL,
    template_plan_id uuid,
    run_plan_id uuid NOT NULL,
    trigger_id uuid,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    dry_run boolean DEFAULT false NOT NULL,
    idempotency_key text,
    site_id uuid NOT NULL,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    claim_token uuid,
    claimed_at timestamp with time zone,
    claim_expires_at timestamp with time zone,
    completed_at timestamp with time zone,
    error_message text,
    CONSTRAINT workflow_runs_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text, 'failed'::text, 'cancelled'::text])))
);


--
-- Name: workflow_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_triggers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instance_id uuid NOT NULL,
    template_plan_id uuid,
    node_id uuid,
    kind text NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT workflow_triggers_kind_check CHECK ((kind = ANY (ARRAY['cron'::text, 'db_event'::text, 'webhook'::text, 'manual'::text, 'channel_message'::text])))
);


--
-- Name: policy_originals policy_originals_pkey; Type: CONSTRAINT; Schema: commerce_rls_private; Owner: -
--

ALTER TABLE ONLY commerce_rls_private.policy_originals
    ADD CONSTRAINT policy_originals_pkey PRIMARY KEY (table_name);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: location_acl_private; Owner: -
--

ALTER TABLE ONLY location_acl_private.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (child_table, child_column);


--
-- Name: roots roots_pkey; Type: CONSTRAINT; Schema: location_acl_private; Owner: -
--

ALTER TABLE ONLY location_acl_private.roots
    ADD CONSTRAINT roots_pkey PRIMARY KEY (table_name);


--
-- Name: scope_assignments scope_assignments_pkey; Type: CONSTRAINT; Schema: location_acl_private; Owner: -
--

ALTER TABLE ONLY location_acl_private.scope_assignments
    ADD CONSTRAINT scope_assignments_pkey PRIMARY KEY (transaction_id, table_name, row_id);


--
-- Name: provider_webhook_events provider_webhook_events_pkey; Type: CONSTRAINT; Schema: private; Owner: -
--

ALTER TABLE ONLY private.provider_webhook_events
    ADD CONSTRAINT provider_webhook_events_pkey PRIMARY KEY (provider, event_id);


--
-- Name: accounting_accounts accounting_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_accounts
    ADD CONSTRAINT accounting_accounts_pkey PRIMARY KEY (id);


--
-- Name: accounting_accounts accounting_accounts_site_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_accounts
    ADD CONSTRAINT accounting_accounts_site_id_code_key UNIQUE (site_id, code);


--
-- Name: journal_entries accounting_entry_currency_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.journal_entries
    ADD CONSTRAINT accounting_entry_currency_valid CHECK (((currency IS NOT NULL) AND (currency ~ '^[A-Z]{3}$'::text))) NOT VALID;


--
-- Name: journal_entries accounting_entry_date_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.journal_entries
    ADD CONSTRAINT accounting_entry_date_valid CHECK (((entry_date IS NOT NULL) AND isfinite(entry_date))) NOT VALID;


--
-- Name: journal_lines accounting_line_amounts_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.journal_lines
    ADD CONSTRAINT accounting_line_amounts_valid CHECK (((debit IS NOT NULL) AND (credit IS NOT NULL) AND ((debit >= (0)::numeric) AND (debit <= ('1000000000000'::bigint)::numeric)) AND ((credit >= (0)::numeric) AND (credit <= ('1000000000000'::bigint)::numeric)) AND (debit = trunc(debit, 2)) AND (credit = trunc(credit, 2)) AND (((debit > (0)::numeric) AND (credit = (0)::numeric)) OR ((credit > (0)::numeric) AND (debit = (0)::numeric))))) NOT VALID;


--
-- Name: accounting_sale_refunds accounting_sale_refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_sale_refunds
    ADD CONSTRAINT accounting_sale_refunds_pkey PRIMARY KEY (id);


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- Name: agent_assets agent_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_assets
    ADD CONSTRAINT agent_assets_pkey PRIMARY KEY (agent_id, asset_id);


--
-- Name: agent_channel_activation_context agent_channel_activation_context_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_channel_activation_context
    ADD CONSTRAINT agent_channel_activation_context_pkey PRIMARY KEY (transaction_id, site_id, connection_id);


--
-- Name: agent_memories agent_memories_agent_id_user_id_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memories
    ADD CONSTRAINT agent_memories_agent_id_user_id_key_key UNIQUE (agent_id, user_id, key);


--
-- Name: agent_memories agent_memories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memories
    ADD CONSTRAINT agent_memories_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: allowed_domains allowed_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowed_domains
    ADD CONSTRAINT allowed_domains_pkey PRIMARY KEY (id);


--
-- Name: analysis analysis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis
    ADD CONSTRAINT analysis_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);

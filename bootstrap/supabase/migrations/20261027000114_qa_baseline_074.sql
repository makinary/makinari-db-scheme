SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: item_spec_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_spec_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: item_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_specs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    category_id uuid NOT NULL,
    name text NOT NULL,
    image_url text,
    video_url text,
    address text,
    city text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: journal_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    entry_date timestamp with time zone NOT NULL,
    memo text,
    status text DEFAULT 'posted'::text NOT NULL,
    source_type text NOT NULL,
    source_id uuid,
    idempotency_key text NOT NULL,
    source_hash text,
    currency text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT journal_entries_source_type_check CHECK ((source_type = ANY (ARRAY['sale'::text, 'expense'::text, 'purchase'::text, 'opening'::text, 'manual'::text])))
);


--
-- Name: journal_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entry_id uuid NOT NULL,
    account_code text NOT NULL,
    debit numeric DEFAULT 0 NOT NULL,
    credit numeric DEFAULT 0 NOT NULL,
    location_id uuid,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    lead_id uuid,
    campaign_id uuid,
    segment_id uuid,
    catalog_item_id uuid,
    catalog_category_id uuid,
    company_id uuid
);


--
-- Name: kpis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kpis (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    value numeric NOT NULL,
    previous_value numeric,
    unit text NOT NULL,
    type text NOT NULL,
    period_start timestamp with time zone NOT NULL,
    period_end timestamp with time zone NOT NULL,
    segment_id uuid,
    is_highlighted boolean DEFAULT false,
    target_value numeric,
    metadata jsonb DEFAULT '{}'::jsonb,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    trend numeric DEFAULT 0,
    benchmark numeric,
    command_id uuid,
    CONSTRAINT kpis_type_check CHECK ((type IS NOT NULL))
);


--
-- Name: layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    state_id uuid NOT NULL,
    name text NOT NULL,
    "order" integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: lead_analysis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lead_analysis (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_name text NOT NULL,
    industry text,
    company_size text,
    annual_revenue text,
    current_kpis jsonb DEFAULT '{"churnRate": 0, "monthlyLeads": 0, "conversionRate": 0, "monthlyRevenue": 0, "salesCycleLength": 0, "averageOrderValue": 0, "convertedCustomers": 0, "salesQualifiedLeads": 0, "customerLifetimeSpan": 0, "customerLifetimeValue": 0, "customerAcquisitionCost": 0, "marketingQualifiedLeads": 0}'::jsonb,
    current_costs jsonb DEFAULT '{"cogs": 0, "otherCosts": 0, "salesTeamCost": 0, "marketingBudget": 0, "salesCommission": 0, "technologyCosts": 0, "operationalCosts": 0, "totalMonthlyCosts": 0}'::jsonb,
    sales_process jsonb DEFAULT '{"winRate": 0, "painPoints": [], "leadSources": [], "salesTeamSize": 0, "averageDealSize": 0, "salesActivities": {"paidAds": false, "coldCalls": false, "directMail": false, "seoContent": false, "tradeShows": false, "videoCalls": false, "activations": false, "retargeting": false, "partnerships": false, "personalBrand": false, "socialSelling": false, "physicalVisits": false, "webinarsEvents": false, "referralProgram": false, "contentMarketing": false, "influencerMarketing": false, "transactionalEmails": false, "personalizedFollowUp": false}, "closingTechniques": [], "followUpFrequency": "", "qualificationProcess": {"interviews": false, "companySize": false, "leadScoring": false, "deepResearch": false, "icpTargeting": false, "manualResearch": false, "decisionMakerID": false, "behaviorAnalysis": false, "competitorAnalysis": false, "budgetQualification": false, "painPointAssessment": false, "demographicFiltering": false}}'::jsonb,
    goals jsonb DEFAULT '{"timeframe": "", "salesGoals": [], "revenueTarget": 0, "marketingGoals": [], "growthChallenges": [], "primaryObjectives": []}'::jsonb,
    analysis_results jsonb DEFAULT '{"currentROI": 0, "riskFactors": [], "projectedROI": 0, "projectedCosts": 0, "recommendations": [], "expectedTimeline": "", "opportunityCosts": 0, "projectedRevenue": 0, "potentialIncrease": 0, "implementationPlan": {}}'::jsonb,
    roi_projections jsonb DEFAULT '{"sixMonth": {"roi": 0, "costs": 0, "revenue": 0}, "threeMonth": {"roi": 0, "costs": 0, "revenue": 0}, "twelveMonth": {"roi": 0, "costs": 0, "revenue": 0}, "twentyFourMonth": {"roi": 0, "costs": 0, "revenue": 0}}'::jsonb,
    strategies jsonb DEFAULT '{"costReduction": [], "revenueGrowth": [], "leadOptimization": [], "processAutomation": [], "technologyUpgrades": [], "conversionImprovement": []}'::jsonb,
    contact_info jsonb DEFAULT '{"name": "", "email": "", "phone": "", "title": "", "bestTimeToCall": "", "preferredContactMethod": ""}'::jsonb,
    status text DEFAULT 'draft'::text,
    completion_percentage integer DEFAULT 0,
    source text DEFAULT 'roi-calculator'::text,
    utm_source text,
    utm_medium text,
    utm_campaign text,
    referrer text,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    user_id uuid,
    site_id uuid,
    CONSTRAINT lead_analysis_completion_percentage_check CHECK (((completion_percentage >= 0) AND (completion_percentage <= 100)))
);


--
-- Name: lead_analysis_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.lead_analysis_summary WITH (security_invoker='true') AS
 SELECT id,
    company_name,
    industry,
    company_size,
    annual_revenue,
    status,
    completion_percentage,
    ((current_kpis ->> 'monthlyRevenue'::text))::numeric AS monthly_revenue,
    ((current_kpis ->> 'customerAcquisitionCost'::text))::numeric AS cac,
    ((current_kpis ->> 'customerLifetimeValue'::text))::numeric AS ltv,
    ((current_kpis ->> 'conversionRate'::text))::numeric AS conversion_rate,
    ((analysis_results ->> 'currentROI'::text))::numeric AS current_roi,
    ((analysis_results ->> 'projectedROI'::text))::numeric AS projected_roi,
    ((analysis_results ->> 'potentialIncrease'::text))::numeric AS potential_increase,
    (contact_info ->> 'email'::text) AS contact_email,
    (contact_info ->> 'name'::text) AS contact_name,
    source,
    utm_source,
    utm_campaign,
    created_at,
    updated_at,
    completed_at
   FROM public.lead_analysis;


--
-- Name: lead_invoice_payment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lead_invoice_payment_requests (
    request_id uuid NOT NULL,
    site_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    actor_id uuid NOT NULL,
    payload jsonb NOT NULL,
    result jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text,
    email text,
    "position" text,
    segment_id uuid,
    status text NOT NULL,
    notes text,
    last_contact timestamp with time zone,
    site_id uuid,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    phone text,
    origin text,
    social_networks jsonb DEFAULT '{}'::jsonb,
    address jsonb DEFAULT '{}'::jsonb,
    company jsonb DEFAULT '{}'::jsonb,
    subscription jsonb DEFAULT '{}'::jsonb,
    birthday text,
    campaign_id uuid,
    command_id uuid,
    language text,
    company_id uuid,
    attribution jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    assignee_id uuid,
    referral_lead_id uuid,
    person_id uuid,
    personal_email text,
    default_price_list_id uuid,
    buyer_user_id uuid,
    do_not_call boolean DEFAULT false NOT NULL,
    voice_call_consent_status text DEFAULT 'unknown'::text NOT NULL,
    voice_call_consent_at timestamp with time zone,
    CONSTRAINT leads_status_check CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'qualified'::text, 'cold'::text, 'converted'::text, 'lost'::text, 'not_qualified'::text]))),
    CONSTRAINT leads_voice_call_consent_status_valid CHECK ((voice_call_consent_status = ANY (ARRAY['unknown'::text, 'granted'::text, 'revoked'::text]))),
    CONSTRAINT leads_voice_call_consent_timestamp_valid CHECK (((voice_call_consent_status <> 'granted'::text) OR (voice_call_consent_at IS NOT NULL)))
);


--
-- Name: location_access_rollout; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_access_rollout (
    singleton boolean DEFAULT true NOT NULL,
    editing_enabled boolean DEFAULT false NOT NULL,
    CONSTRAINT location_access_rollout_singleton_check CHECK (singleton)
);


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    name text NOT NULL,
    code text,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    address text,
    city text,
    state text,
    zip text,
    country text
);


--
-- Name: marketplace_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    actor_user_id uuid NOT NULL,
    action text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    CONSTRAINT marketplace_actions_action_check CHECK ((action = ANY (ARRAY['accept'::text, 'reject'::text, 'ready'::text, 'cancel'::text]))),
    CONSTRAINT marketplace_actions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'failed'::text, 'unknown'::text])))
);


--
-- Name: marketplace_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    integration_id uuid NOT NULL,
    event_key text NOT NULL,
    event_at timestamp with time zone,
    normalized_payload jsonb NOT NULL,
    status text DEFAULT 'completed'::text NOT NULL,
    order_id uuid,
    shipment_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT marketplace_events_event_key_check CHECK (((length(event_key) >= 1) AND (length(event_key) <= 300))),
    CONSTRAINT marketplace_events_normalized_payload_check CHECK ((octet_length((normalized_payload)::text) <= 262144)),
    CONSTRAINT marketplace_events_status_check CHECK ((status = 'completed'::text))
);


--
-- Name: marketplace_integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_integrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text NOT NULL,
    external_store_id text NOT NULL,
    origin_location_id uuid NOT NULL,
    secret_id uuid,
    enabled boolean DEFAULT false NOT NULL,
    manual_ready boolean DEFAULT false NOT NULL,
    created_by_user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_polled_at timestamp with time zone,
    poll_sent_next boolean DEFAULT false NOT NULL,
    credential_mode text DEFAULT 'custom'::text NOT NULL,
    merchant_connection_id uuid,
    provisioning_status text DEFAULT 'active'::text NOT NULL,
    provisioning_operation text,
    provisioning_result text,
    provisioning_claim_id uuid,
    provider_batch_id text,
    CONSTRAINT marketplace_integration_credential_binding CHECK ((((credential_mode = 'custom'::text) AND ((secret_id IS NOT NULL) OR (merchant_connection_id IS NOT NULL))) OR ((credential_mode = 'platform'::text) AND (secret_id IS NULL) AND (merchant_connection_id IS NOT NULL)))),
    CONSTRAINT marketplace_integration_provisioning_enabled CHECK (((merchant_connection_id IS NULL) OR (NOT enabled) OR (provisioning_status = ANY (ARRAY['active'::text, 'pending'::text])))),
    CONSTRAINT marketplace_integrations_check CHECK (((provider <> 'rappi'::text) OR (country <> ALL (ARRAY['CA'::text, 'US'::text])))),
    CONSTRAINT marketplace_integrations_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_integrations_credential_mode_check CHECK ((credential_mode = ANY (ARRAY['custom'::text, 'platform'::text]))),
    CONSTRAINT marketplace_integrations_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_integrations_external_store_id_check CHECK (((length(external_store_id) >= 1) AND (length(external_store_id) <= 200))),
    CONSTRAINT marketplace_integrations_provider_batch_id_check CHECK (((length(provider_batch_id) >= 1) AND (length(provider_batch_id) <= 200))),
    CONSTRAINT marketplace_integrations_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text]))),
    CONSTRAINT marketplace_integrations_provisioning_operation_check CHECK ((provisioning_operation = ANY (ARRAY['activate'::text, 'deactivate'::text]))),
    CONSTRAINT marketplace_integrations_provisioning_result_check CHECK ((provisioning_result = ANY (ARRAY['pending'::text, 'unknown'::text, 'confirmed'::text, 'failed'::text]))),
    CONSTRAINT marketplace_integrations_provisioning_status_check CHECK ((provisioning_status = ANY (ARRAY['not_ready'::text, 'pending'::text, 'active'::text, 'revoked'::text])))
);


--
-- Name: marketplace_merchant_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_merchant_connections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    oauth_session_id uuid NOT NULL,
    site_id uuid NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text NOT NULL,
    credential_mode text NOT NULL,
    app_client_id_hash text NOT NULL,
    encrypted_authorization text,
    token_expires_at timestamp with time zone,
    authorized_stores jsonb DEFAULT '[]'::jsonb NOT NULL,
    actor_user_id uuid NOT NULL,
    status text DEFAULT 'authorized'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT marketplace_merchant_connections_app_client_id_hash_check CHECK ((app_client_id_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT marketplace_merchant_connections_authorized_stores_check CHECK (((jsonb_typeof(authorized_stores) = 'array'::text) AND (octet_length((authorized_stores)::text) <= 131072))),
    CONSTRAINT marketplace_merchant_connections_check CHECK (((status <> 'authorized'::text) OR (encrypted_authorization IS NOT NULL))),
    CONSTRAINT marketplace_merchant_connections_check1 CHECK (((status <> 'revoked'::text) OR (encrypted_authorization IS NULL))),
    CONSTRAINT marketplace_merchant_connections_check2 CHECK (((provider <> 'rappi'::text) OR (country <> ALL (ARRAY['CA'::text, 'US'::text])))),
    CONSTRAINT marketplace_merchant_connections_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_merchant_connections_credential_mode_check CHECK ((credential_mode = ANY (ARRAY['custom'::text, 'platform'::text]))),
    CONSTRAINT marketplace_merchant_connections_encrypted_authorization_check CHECK (((length(encrypted_authorization) >= 16) AND (length(encrypted_authorization) <= 32768))),
    CONSTRAINT marketplace_merchant_connections_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_merchant_connections_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text]))),
    CONSTRAINT marketplace_merchant_connections_status_check CHECK ((status = ANY (ARRAY['authorized'::text, 'revoked'::text])))
);


--
-- Name: marketplace_oauth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_oauth_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    state_hash text NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text NOT NULL,
    credential_mode text NOT NULL,
    encrypted_context text,
    expires_at timestamp with time zone NOT NULL,
    status text DEFAULT 'created'::text NOT NULL,
    claimed_at timestamp with time zone,
    finished_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT marketplace_oauth_sessions_check CHECK (((expires_at > created_at) AND (expires_at <= (created_at + '00:30:00'::interval)))),
    CONSTRAINT marketplace_oauth_sessions_check1 CHECK (((status <> ALL (ARRAY['created'::text, 'claimed'::text])) OR (encrypted_context IS NOT NULL))),
    CONSTRAINT marketplace_oauth_sessions_check2 CHECK (((status <> ALL (ARRAY['completed'::text, 'failed'::text])) OR (encrypted_context IS NULL))),
    CONSTRAINT marketplace_oauth_sessions_check3 CHECK (((provider <> 'rappi'::text) OR (country <> ALL (ARRAY['CA'::text, 'US'::text])))),
    CONSTRAINT marketplace_oauth_sessions_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_oauth_sessions_credential_mode_check CHECK ((credential_mode = ANY (ARRAY['custom'::text, 'platform'::text]))),
    CONSTRAINT marketplace_oauth_sessions_encrypted_context_check CHECK (((length(encrypted_context) >= 16) AND (length(encrypted_context) <= 32768))),
    CONSTRAINT marketplace_oauth_sessions_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_oauth_sessions_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text]))),
    CONSTRAINT marketplace_oauth_sessions_state_hash_check CHECK ((state_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT marketplace_oauth_sessions_status_check CHECK ((status = ANY (ARRAY['created'::text, 'claimed'::text, 'completed'::text, 'failed'::text])))
);


--
-- Name: marketplace_platform_apps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_platform_apps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text NOT NULL,
    app_client_id_hash text NOT NULL,
    encrypted_credentials text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT marketplace_platform_apps_app_client_id_hash_check CHECK ((app_client_id_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT marketplace_platform_apps_check CHECK (((provider <> 'rappi'::text) OR (country <> ALL (ARRAY['CA'::text, 'US'::text])))),
    CONSTRAINT marketplace_platform_apps_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_platform_apps_encrypted_credentials_check CHECK (((length(encrypted_credentials) >= 16) AND (length(encrypted_credentials) <= 32768))),
    CONSTRAINT marketplace_platform_apps_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_platform_apps_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text])))
);


--
-- Name: marketplace_provider_webhook_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_provider_webhook_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    app_client_id_hash text NOT NULL,
    provider text NOT NULL,
    environment text NOT NULL,
    country text,
    integration_id uuid,
    event text NOT NULL,
    secret_ciphertext text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT marketplace_provider_webhook_keys_app_client_id_hash_check CHECK ((app_client_id_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT marketplace_provider_webhook_keys_country_check CHECK ((country = ANY (ARRAY['AR'::text, 'BR'::text, 'CA'::text, 'CL'::text, 'CO'::text, 'CR'::text, 'EC'::text, 'MX'::text, 'PE'::text, 'US'::text, 'UY'::text]))),
    CONSTRAINT marketplace_provider_webhook_keys_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT marketplace_provider_webhook_keys_event_check CHECK (((length(event) >= 1) AND (length(event) <= 100))),
    CONSTRAINT marketplace_provider_webhook_keys_provider_check CHECK ((provider = ANY (ARRAY['uber_eats'::text, 'rappi'::text]))),
    CONSTRAINT marketplace_provider_webhook_keys_secret_ciphertext_check CHECK (((length(secret_ciphertext) >= 16) AND (length(secret_ciphertext) <= 32768)))
);


--
-- Name: marketplace_rebind_permits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_rebind_permits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    backend_pid integer NOT NULL,
    transaction_id bigint NOT NULL,
    integration_id uuid NOT NULL,
    connection_id uuid NOT NULL,
    actor_user_id uuid NOT NULL
);

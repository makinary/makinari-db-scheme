SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lead_id uuid,
    campaign_id uuid,
    segment_id uuid,
    amount numeric NOT NULL,
    currency text DEFAULT 'USD'::text,
    status text NOT NULL,
    title text NOT NULL,
    description text,
    sale_date date NOT NULL,
    payment_method text,
    payment_details jsonb DEFAULT '{}'::jsonb,
    invoice_number text,
    product_name text,
    product_type text,
    product_details jsonb DEFAULT '{}'::jsonb,
    reference_code text,
    external_id text,
    notes text,
    tags text[],
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    channel text DEFAULT 'online'::text,
    source text DEFAULT 'online'::text,
    amount_due numeric DEFAULT '0'::numeric,
    payments jsonb DEFAULT '[]'::jsonb,
    buyer_user_id uuid,
    owner_site_id uuid,
    location_id uuid,
    company_id uuid,
    accounting_state text DEFAULT 'pending'::text NOT NULL,
    public_access_token text,
    last_emailed_at timestamp with time zone,
    stripe_checkout_session_id text,
    stripe_payment_intent_id text,
    public_access_token_expires_at timestamp with time zone,
    public_access_token_revoked_at timestamp with time zone,
    stripe_checkout_attempt bigint DEFAULT 0 NOT NULL,
    subscription_id uuid,
    quotation_id uuid,
    due_date date,
    CONSTRAINT sales_accounting_state_check CHECK ((accounting_state = ANY (ARRAY['pending'::text, 'posted'::text, 'unpublished'::text]))),
    CONSTRAINT sales_due_date_calendar_check CHECK (((due_date IS NULL) OR (isfinite(due_date) AND ((due_date >= '0001-01-01'::date) AND (due_date <= '9999-12-31'::date))))),
    CONSTRAINT sales_source_check CHECK ((source = ANY (ARRAY['retail'::text, 'online'::text, 'marketplace'::text, 'quote'::text, 'shop'::text, 'pos'::text, 'sales'::text]))),
    CONSTRAINT sales_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'cancelled'::text, 'refunded'::text])))
);


--
-- Name: sandbox_billing_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sandbox_billing_resources (
    sandbox_name text NOT NULL,
    site_id uuid NOT NULL,
    registered_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    last_reconciled_at timestamp with time zone,
    deletion_requested_at timestamp with time zone,
    retired_at timestamp with time zone,
    owner_kind text NOT NULL,
    owner_id uuid NOT NULL,
    CONSTRAINT sandbox_billing_resources_owner_kind_check CHECK ((owner_kind = ANY (ARRAY['harness'::text, 'requirement'::text, 'workflow'::text]))),
    CONSTRAINT sandbox_billing_resources_sandbox_name_check CHECK (((length(sandbox_name) >= 1) AND (length(sandbox_name) <= 200)))
);


--
-- Name: sandbox_billing_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sandbox_billing_sessions (
    session_id text NOT NULL,
    sandbox_name text NOT NULL,
    started_at timestamp with time zone NOT NULL,
    billed_through timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    credits_charged numeric DEFAULT 0 NOT NULL,
    CONSTRAINT sandbox_billing_sessions_check CHECK ((billed_through >= started_at)),
    CONSTRAINT sandbox_billing_sessions_credits_charged_check CHECK ((credits_charged >= (0)::numeric)),
    CONSTRAINT sandbox_billing_sessions_session_id_check CHECK (((length(session_id) >= 1) AND (length(session_id) <= 200)))
);


--
-- Name: sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    name text NOT NULL,
    "order" integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: secure_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.secure_tokens (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid,
    token_type text NOT NULL,
    encrypted_value text NOT NULL,
    identifier text NOT NULL,
    last_used timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.segments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    audience public.segment_audience,
    size numeric,
    engagement integer,
    is_active boolean DEFAULT true,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    language public.segment_language DEFAULT 'en'::public.segment_language NOT NULL,
    url text,
    analysis jsonb,
    topics jsonb,
    icp jsonb,
    estimated_value numeric,
    command_id uuid,
    rules jsonb DEFAULT '[]'::jsonb,
    CONSTRAINT segments_audience_check CHECK ((audience = ANY (ARRAY['enterprise'::public.segment_audience, 'smb'::public.segment_audience, 'startup'::public.segment_audience, 'b2b_saas'::public.segment_audience, 'e_commerce'::public.segment_audience, 'tech'::public.segment_audience, 'finance'::public.segment_audience, 'healthcare'::public.segment_audience, 'education'::public.segment_audience, 'manufacturing'::public.segment_audience, 'retail'::public.segment_audience, 'real_estate'::public.segment_audience, 'hospitality'::public.segment_audience, 'automotive'::public.segment_audience, 'media'::public.segment_audience, 'telecom'::public.segment_audience, 'energy'::public.segment_audience, 'agriculture'::public.segment_audience, 'construction'::public.segment_audience, 'logistics'::public.segment_audience, 'professional'::public.segment_audience, 'government'::public.segment_audience, 'nonprofit'::public.segment_audience, 'legal'::public.segment_audience, 'pharma'::public.segment_audience, 'insurance'::public.segment_audience, 'consulting'::public.segment_audience, 'research'::public.segment_audience, 'aerospace'::public.segment_audience, 'gaming'::public.segment_audience]))),
    CONSTRAINT segments_language_check CHECK ((language = ANY (ARRAY['en'::public.segment_language, 'zh'::public.segment_language, 'hi'::public.segment_language, 'es'::public.segment_language, 'ar'::public.segment_language, 'bn'::public.segment_language, 'pt'::public.segment_language, 'ru'::public.segment_language, 'ja'::public.segment_language, 'de'::public.segment_language, 'fr'::public.segment_language, 'ur'::public.segment_language, 'id'::public.segment_language, 'tr'::public.segment_language, 'it'::public.segment_language, 'th'::public.segment_language, 'vi'::public.segment_language, 'ko'::public.segment_language, 'fa'::public.segment_language, 'pl'::public.segment_language, 'uk'::public.segment_language, 'ro'::public.segment_language, 'nl'::public.segment_language, 'el'::public.segment_language, 'cs'::public.segment_language, 'sv'::public.segment_language, 'hu'::public.segment_language, 'da'::public.segment_language, 'fi'::public.segment_language, 'no'::public.segment_language])))
);


--
-- Name: self_service_inventory_releases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.self_service_inventory_releases (
    sale_order_item_id uuid NOT NULL,
    sale_order_id uuid NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid,
    location_id uuid NOT NULL,
    quantity numeric NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT self_service_inventory_releases_quantity_check CHECK (((quantity >= (0)::numeric) AND ((quantity)::text <> ALL (ARRAY['NaN'::text, 'Infinity'::text, '-Infinity'::text]))))
);


--
-- Name: session_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type text NOT NULL,
    url text,
    "timestamp" bigint NOT NULL,
    data jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    site_id text NOT NULL,
    visitor_id uuid,
    referrer text,
    user_agent text,
    ip text,
    event_name text,
    properties jsonb DEFAULT '{}'::jsonb,
    session_id uuid,
    activity jsonb,
    command_id uuid,
    segment_id uuid
);


--
-- Name: session_recording_chunks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_recording_chunks (
    chunk_id uuid NOT NULL,
    recording_event_id uuid NOT NULL,
    site_id text NOT NULL,
    session_id uuid NOT NULL,
    storage_path text NOT NULL,
    content_hash text NOT NULL,
    chunk_timestamp bigint,
    start_timestamp bigint,
    end_timestamp bigint,
    event_count integer,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT session_recording_chunks_event_count_check CHECK (((event_count IS NULL) OR (event_count >= 0))),
    CONSTRAINT session_recording_chunks_timestamp_check CHECK (((start_timestamp IS NULL) OR (end_timestamp IS NULL) OR (end_timestamp >= start_timestamp)))
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    about text,
    company_size text,
    industry text,
    products jsonb DEFAULT '[]'::jsonb,
    services jsonb DEFAULT '[]'::jsonb,
    swot jsonb DEFAULT '{"threats": "", "strengths": "", "weaknesses": "", "opportunities": ""}'::jsonb,
    locations jsonb DEFAULT '[]'::jsonb,
    marketing_budget jsonb DEFAULT '{"total": 0, "available": 0}'::jsonb,
    marketing_channels jsonb DEFAULT '[]'::jsonb,
    social_media jsonb DEFAULT '[]'::jsonb,
    analytics_provider text,
    analytics_id text,
    team_members jsonb DEFAULT '[]'::jsonb,
    team_roles jsonb DEFAULT '[]'::jsonb,
    org_structure jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    competitors jsonb DEFAULT '[]'::jsonb,
    focus_mode integer DEFAULT 50,
    goals jsonb DEFAULT '[]'::jsonb,
    channels jsonb DEFAULT '[]'::jsonb,
    business_hours jsonb DEFAULT '[]'::jsonb,
    branding jsonb DEFAULT '{}'::jsonb,
    customer_journey jsonb DEFAULT '{}'::jsonb,
    onboarding jsonb DEFAULT '{}'::jsonb,
    business_model jsonb DEFAULT '{}'::jsonb,
    activities jsonb DEFAULT '{}'::jsonb,
    calendars jsonb DEFAULT '[]'::jsonb,
    commerce jsonb DEFAULT '{"decrement_stock_on": "ship", "stock_shortage_policy": "allow", "default_availability_mode": "manual"}'::jsonb,
    currency text DEFAULT 'USD'::text NOT NULL,
    shop jsonb,
    visits jsonb DEFAULT '{"require_id": false, "terms_text": "", "require_photo": true, "enabled_online": true, "enabled_physical": true, "require_signature": true, "default_duration_minutes": 60}'::jsonb,
    default_locale text DEFAULT 'en'::text NOT NULL,
    printers jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT settings_default_locale_check CHECK ((default_locale = ANY (ARRAY['en'::text, 'es'::text, 'fr'::text, 'de'::text, 'ja'::text])))
);


--
-- Name: setup_email_delivery_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setup_email_delivery_receipts (
    operation_key text NOT NULL,
    site_id uuid NOT NULL,
    payload jsonb NOT NULL,
    claim_token uuid NOT NULL,
    state text DEFAULT 'claimed'::text NOT NULL,
    receipt jsonb,
    claimed_at timestamp with time zone DEFAULT now() NOT NULL,
    finalized_at timestamp with time zone,
    CONSTRAINT setup_email_delivery_receipts_check CHECK ((((state = 'claimed'::text) AND (receipt IS NULL) AND (finalized_at IS NULL)) OR ((state <> 'claimed'::text) AND (receipt IS NOT NULL) AND (finalized_at IS NOT NULL)))),
    CONSTRAINT setup_email_delivery_receipts_operation_key_check CHECK (((length(operation_key) >= 1) AND (length(operation_key) <= 200))),
    CONSTRAINT setup_email_delivery_receipts_payload_check CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT setup_email_delivery_receipts_state_check CHECK ((state = ANY (ARRAY['claimed'::text, 'sent'::text, 'skipped'::text, 'uncertain'::text])))
);

ALTER TABLE ONLY public.setup_email_delivery_receipts FORCE ROW LEVEL SECURITY;


--
-- Name: shipment_location_pings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shipment_location_pings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    shipment_id uuid NOT NULL,
    user_id uuid NOT NULL,
    lat numeric NOT NULL,
    lng numeric NOT NULL,
    accuracy numeric,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: shipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shipments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    sale_order_id uuid NOT NULL,
    sale_id uuid,
    lead_id uuid,
    origin_location_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    carrier text,
    tracking_number text,
    shipping_address jsonb,
    stock_decremented boolean DEFAULT false,
    estimated_delivery_at timestamp with time zone,
    shipped_at timestamp with time zone,
    delivered_at timestamp with time zone,
    notes text,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    assigned_to uuid,
    last_lat numeric,
    last_lng numeric,
    last_located_at timestamp with time zone,
    stripe_checkout_session_id text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    marketplace_integration_id uuid,
    external_delivery_id text,
    CONSTRAINT shipments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'preparing'::text, 'shipped'::text, 'in_transit'::text, 'delivered'::text, 'cancelled'::text, 'failed'::text])))
);


--
-- Name: site_member_location_restriction_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_member_location_restriction_audit (
    id bigint NOT NULL,
    site_id uuid NOT NULL,
    site_member_id uuid NOT NULL,
    actor_user_id uuid NOT NULL,
    old_location_ids uuid[] NOT NULL,
    new_location_ids uuid[] NOT NULL,
    revision integer NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT site_member_location_restriction_audit_revision_check CHECK ((revision > 0))
);


--
-- Name: site_member_location_restriction_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.site_member_location_restriction_audit ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.site_member_location_restriction_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: site_member_location_restrictions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_member_location_restrictions (
    site_id uuid NOT NULL,
    site_member_id uuid NOT NULL,
    location_id uuid NOT NULL
);


--
-- Name: site_ownership; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_ownership (
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: site_retired_stripe_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_retired_stripe_subscriptions (
    site_id uuid NOT NULL,
    subscription_id text NOT NULL,
    retired_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT site_retired_stripe_subscriptions_subscription_id_check CHECK ((subscription_id ~ '^sub_[A-Za-z0-9]+$'::text))
);


--
-- Name: site_secrets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_secrets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    instance_id uuid,
    name text NOT NULL,
    provider text NOT NULL,
    use_case text NOT NULL,
    encrypted_value text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: site_skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_skills (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    types text[] DEFAULT '{}'::text[] NOT NULL,
    content text NOT NULL,
    source text DEFAULT 'custom'::text NOT NULL,
    source_url text,
    enabled boolean DEFAULT true NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT site_skills_check CHECK (((source <> 'github'::text) OR (source_url IS NOT NULL))),
    CONSTRAINT site_skills_content_check CHECK (((octet_length(content) >= 1) AND (octet_length(content) <= 131072))),
    CONSTRAINT site_skills_description_check CHECK ((length(description) <= 2000)),
    CONSTRAINT site_skills_name_check CHECK (((length(name) >= 1) AND (length(name) <= 200))),
    CONSTRAINT site_skills_slug_check CHECK (((slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text) AND (length(slug) <= 100))),
    CONSTRAINT site_skills_source_check CHECK ((source = ANY (ARRAY['custom'::text, 'github'::text])))
);


--
-- Name: site_startup_trials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_startup_trials (
    primary_owner_id uuid NOT NULL,
    site_id uuid NOT NULL,
    started_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    converted_at timestamp with time zone,
    CONSTRAINT site_startup_trials_check CHECK ((isfinite(started_at) AND isfinite(ends_at) AND (ends_at = (started_at + '360:00:00'::interval)))),
    CONSTRAINT site_startup_trials_check1 CHECK (((converted_at IS NULL) OR (isfinite(converted_at) AND (converted_at >= started_at))))
);


--
-- Name: site_subscription_checkout_leases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_subscription_checkout_leases (
    site_id uuid NOT NULL,
    token uuid NOT NULL,
    lease_until timestamp with time zone NOT NULL
);


--
-- Name: social_comment_sync_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_comment_sync_state (
    site_id uuid NOT NULL,
    outstand_post_id text NOT NULL,
    network text NOT NULL,
    last_success_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT social_comment_sync_state_network_check CHECK (((network <> ''::text) AND (network = lower(btrim(network))) AND (network <> 'twitter'::text))),
    CONSTRAINT social_comment_sync_state_outstand_post_id_check CHECK ((btrim(outstand_post_id) <> ''::text))
);

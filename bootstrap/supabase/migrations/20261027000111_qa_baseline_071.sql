SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: catalog_item_modifier_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_item_modifier_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    modifier_group_id uuid NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_item_requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_item_requirements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    requirement_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_item_specs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_item_specs (
    catalog_item_id uuid NOT NULL,
    item_spec_id uuid NOT NULL,
    sort_order integer DEFAULT 0
);


--
-- Name: catalog_item_taxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_item_taxes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    tax_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_search_documents (
    catalog_item_id uuid NOT NULL,
    site_id uuid NOT NULL,
    document_text text NOT NULL,
    name_text text NOT NULL,
    sku_text text NOT NULL,
    source_hash text NOT NULL,
    source_revision bigint NOT NULL,
    embedding public.vector(1536),
    embedding_model text,
    embedding_source_hash text,
    indexed_at timestamp with time zone,
    search_tsv tsvector GENERATED ALWAYS AS (((setweight(to_tsvector('simple'::regconfig, name_text), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, sku_text), 'A'::"char")) || setweight(to_tsvector('simple'::regconfig, document_text), 'B'::"char"))) STORED,
    CONSTRAINT catalog_search_documents_source_revision_check CHECK ((source_revision > 0))
);


--
-- Name: catalog_search_refresh_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_search_refresh_events (
    id bigint NOT NULL,
    catalog_item_id uuid NOT NULL,
    revive_exhausted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_search_refresh_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.catalog_search_refresh_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.catalog_search_refresh_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: catalog_search_revision_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_search_revision_events (
    id bigint NOT NULL,
    site_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_search_revision_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.catalog_search_revision_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.catalog_search_revision_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: catalog_search_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_search_revisions (
    scope text NOT NULL,
    revision bigint DEFAULT 0 NOT NULL,
    CONSTRAINT catalog_search_revisions_revision_check CHECK ((revision >= 0))
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    icon text,
    color text,
    is_active boolean DEFAULT true,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: channel_health; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channel_health (
    site_id uuid NOT NULL,
    channel text NOT NULL,
    direction text NOT NULL,
    status text DEFAULT 'unknown'::text NOT NULL,
    successes_15m integer DEFAULT 0 NOT NULL,
    channel_failures_15m integer DEFAULT 0 NOT NULL,
    last_success_at timestamp with time zone,
    last_failure_at timestamp with time zone,
    reset_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT channel_health_channel_check CHECK ((channel = ANY (ARRAY['email'::text, 'whatsapp'::text]))),
    CONSTRAINT channel_health_direction_check CHECK ((direction = ANY (ARRAY['inbound'::text, 'outbound'::text]))),
    CONSTRAINT channel_health_status_check CHECK ((status = ANY (ARRAY['unknown'::text, 'healthy'::text, 'degraded'::text, 'unhealthy'::text])))
);


--
-- Name: channel_health_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channel_health_events (
    id bigint NOT NULL,
    site_id uuid NOT NULL,
    channel text NOT NULL,
    direction text NOT NULL,
    source_id uuid NOT NULL,
    outcome text NOT NULL,
    error_class text,
    observed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT channel_health_events_channel_check CHECK ((channel = ANY (ARRAY['email'::text, 'whatsapp'::text]))),
    CONSTRAINT channel_health_events_direction_check CHECK ((direction = ANY (ARRAY['inbound'::text, 'outbound'::text]))),
    CONSTRAINT channel_health_events_error_class_check CHECK ((error_class = ANY (ARRAY['auth'::text, 'provider'::text, 'recipient'::text, 'content'::text, 'unknown'::text]))),
    CONSTRAINT channel_health_events_outcome_check CHECK ((outcome = ANY (ARRAY['success'::text, 'failure'::text])))
);


--
-- Name: channel_health_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.channel_health_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.channel_health_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: commands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task text NOT NULL,
    status public.command_status DEFAULT 'pending'::public.command_status NOT NULL,
    description text,
    results jsonb DEFAULT '[]'::jsonb,
    targets jsonb DEFAULT '[]'::jsonb,
    tools jsonb DEFAULT '[]'::jsonb,
    context text,
    supervisor jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    completion_date timestamp with time zone,
    duration integer,
    model text,
    agent_id uuid,
    user_id uuid NOT NULL,
    output_tokens numeric DEFAULT '0'::numeric,
    input_tokens numeric DEFAULT '0'::numeric,
    site_id uuid,
    agent_background text,
    functions jsonb DEFAULT '[]'::jsonb,
    performance integer DEFAULT 0
);


--
-- Name: commands_dislikes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.commands_dislikes WITH (security_invoker='true') AS
 SELECT id,
    task,
    status,
    description,
    results,
    targets,
    tools,
    context,
    supervisor,
    created_at,
    updated_at,
    completion_date,
    duration,
    model,
    agent_id,
    user_id,
    output_tokens,
    input_tokens,
    site_id,
    agent_background,
    functions,
    performance
   FROM public.commands
  WHERE ((performance & 2) = 2);


--
-- Name: commands_flags; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.commands_flags WITH (security_invoker='true') AS
 SELECT id,
    task,
    status,
    description,
    results,
    targets,
    tools,
    context,
    supervisor,
    created_at,
    updated_at,
    completion_date,
    duration,
    model,
    agent_id,
    user_id,
    output_tokens,
    input_tokens,
    site_id,
    agent_background,
    functions,
    performance
   FROM public.commands
  WHERE ((performance & 4) = 4);


--
-- Name: commands_likes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.commands_likes WITH (security_invoker='true') AS
 SELECT id,
    task,
    status,
    description,
    results,
    targets,
    tools,
    context,
    supervisor,
    created_at,
    updated_at,
    completion_date,
    duration,
    model,
    agent_id,
    user_id,
    output_tokens,
    input_tokens,
    site_id,
    agent_background,
    functions,
    performance
   FROM public.commands
  WHERE ((performance & 1) = 1);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    website text,
    industry text,
    size text,
    annual_revenue text,
    founded text,
    description text,
    address jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    legal_name text,
    tax_id text,
    tax_country text,
    registration_number text,
    vat_number text,
    legal_structure text,
    phone text,
    email text,
    linkedin_url text,
    employees_count integer,
    is_public boolean DEFAULT false,
    stock_symbol text,
    parent_company_id uuid,
    logo_url text,
    cover_image_url text,
    social_media jsonb DEFAULT '{}'::jsonb,
    key_people jsonb DEFAULT '[]'::jsonb,
    funding_info jsonb DEFAULT '{}'::jsonb,
    certifications text[] DEFAULT ARRAY[]::text[],
    awards text[] DEFAULT ARRAY[]::text[],
    business_model text,
    products_services jsonb DEFAULT '[]'::jsonb,
    tech_stack text[] DEFAULT ARRAY[]::text[],
    languages text[] DEFAULT ARRAY['en'::text],
    business_hours jsonb DEFAULT '{}'::jsonb,
    video_url text,
    press_releases jsonb DEFAULT '[]'::jsonb,
    partnerships jsonb DEFAULT '[]'::jsonb,
    competitor_info jsonb DEFAULT '{}'::jsonb,
    sustainability_score integer,
    diversity_info jsonb DEFAULT '{}'::jsonb,
    remote_policy text,
    office_locations jsonb DEFAULT '[]'::jsonb,
    market_cap bigint,
    last_funding_date date,
    ipo_date date,
    acquisition_date date,
    acquired_by_id uuid,
    CONSTRAINT companies_annual_revenue_check CHECK ((annual_revenue = ANY (ARRAY['<1M'::text, '1M-10M'::text, '10M-50M'::text, '50M-100M'::text, '100M-500M'::text, '500M-1B'::text, '>1B'::text]))),
    CONSTRAINT companies_business_model_check CHECK ((business_model = ANY (ARRAY['b2b'::text, 'b2c'::text, 'b2b2c'::text, 'marketplace'::text, 'saas'::text, 'ecommerce'::text, 'other'::text]))),
    CONSTRAINT companies_industry_check CHECK ((industry = ANY (ARRAY['technology'::text, 'finance'::text, 'healthcare'::text, 'education'::text, 'retail'::text, 'manufacturing'::text, 'services'::text, 'hospitality'::text, 'media'::text, 'real_estate'::text, 'logistics'::text, 'nonprofit'::text, 'other'::text]))),
    CONSTRAINT companies_legal_structure_check CHECK ((legal_structure = ANY (ARRAY['sole_proprietorship'::text, 'partnership'::text, 'llc'::text, 'corporation'::text, 'nonprofit'::text, 'cooperative'::text, 's_corp'::text, 'c_corp'::text, 'lp'::text, 'llp'::text, 'sa'::text, 'srl'::text, 'gmbh'::text, 'ltd'::text, 'plc'::text, 'bv'::text, 'nv'::text, 'other'::text]))),
    CONSTRAINT companies_remote_policy_check CHECK ((remote_policy = ANY (ARRAY['remote_first'::text, 'hybrid'::text, 'office_only'::text, 'flexible'::text]))),
    CONSTRAINT companies_size_check CHECK ((size = ANY (ARRAY['1-10'::text, '11-50'::text, '51-200'::text, '201-500'::text, '501-1000'::text, '1001-5000'::text, '5001-10000'::text, '10001+'::text]))),
    CONSTRAINT companies_sustainability_score_check CHECK (((sustainability_score >= 0) AND (sustainability_score <= 100)))
);


--
-- Name: content; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    title text NOT NULL,
    description text,
    type text NOT NULL,
    status text NOT NULL,
    segment_id uuid,
    site_id uuid NOT NULL,
    author_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    published_at timestamp with time zone,
    tags text[],
    estimated_reading_time integer,
    word_count integer,
    seo_score integer,
    user_id uuid,
    text text,
    campaign_id uuid,
    performance_rating smallint,
    metadata jsonb DEFAULT '{}'::jsonb,
    command_id uuid,
    instructions text,
    public_search tsvector GENERATED ALWAYS AS (to_tsvector('simple'::regconfig, ((((COALESCE(title, ''::text) || ' '::text) || COALESCE(description, ''::text)) || ' '::text) || COALESCE(text, ''::text)))) STORED,
    CONSTRAINT content_content_type_check CHECK ((type = ANY (ARRAY['blog_post'::text, 'video'::text, 'podcast'::text, 'social_post'::text, 'newsletter'::text, 'case_study'::text, 'whitepaper'::text, 'infographic'::text, 'webinar'::text, 'ebook'::text, 'ad'::text, 'landing_page'::text]))),
    CONSTRAINT content_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'review'::text, 'approved'::text, 'published'::text, 'archived'::text]))),
    CONSTRAINT performance_rating_range CHECK (((performance_rating IS NULL) OR ((performance_rating >= 1) AND (performance_rating <= 5))))
);


--
-- Name: content_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_assets (
    content_id uuid NOT NULL,
    asset_id uuid NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: content_performance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_performance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    content_id uuid,
    outstand_post_id text NOT NULL,
    likes integer DEFAULT 0,
    comments integer DEFAULT 0,
    shares integer DEFAULT 0,
    views integer DEFAULT 0,
    impressions integer DEFAULT 0,
    reach integer DEFAULT 0,
    engagement_rate numeric(10,4) DEFAULT 0,
    metrics_by_account jsonb DEFAULT '[]'::jsonb,
    fetched_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

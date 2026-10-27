SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: price_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.price_lists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    name text NOT NULL,
    code text,
    currency text DEFAULT 'USD'::text,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    channels text[] DEFAULT ARRAY['pos'::text] NOT NULL,
    CONSTRAINT price_lists_channels_check CHECK (((channels <@ ARRAY['marketplace'::text, 'shop'::text, 'pos'::text]) AND (cardinality(channels) >= 1)))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    email text NOT NULL,
    name text,
    avatar_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    command_id uuid,
    bio text,
    role text,
    language text DEFAULT 'es'::text,
    timezone text DEFAULT 'America/Mexico_City'::text,
    notifications jsonb DEFAULT '{"push": true, "email": true}'::jsonb,
    settings jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    account_kind text DEFAULT 'standard'::text,
    CONSTRAINT profiles_account_kind_check CHECK ((account_kind = ANY (ARRAY['standard'::text, 'client'::text]))),
    CONSTRAINT profiles_language_check CHECK ((language = ANY (ARRAY['es'::text, 'en'::text, 'fr'::text, 'de'::text, 'ja'::text]))),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['Product Manager'::text, 'Designer'::text, 'Developer'::text, 'Marketing'::text, 'Sales'::text, 'CEO'::text, 'Other'::text]))),
    CONSTRAINT valid_notifications CHECK (public.validate_notifications(notifications))
);


--
-- Name: promotion_catalog_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotion_catalog_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    promotion_id uuid NOT NULL,
    catalog_category_id uuid NOT NULL,
    site_id uuid NOT NULL
);


--
-- Name: promotion_catalog_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotion_catalog_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    promotion_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    site_id uuid NOT NULL
);


--
-- Name: promotion_required_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotion_required_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    promotion_id uuid NOT NULL,
    catalog_category_id uuid NOT NULL,
    site_id uuid NOT NULL,
    min_quantity integer DEFAULT 1 NOT NULL,
    CONSTRAINT promotion_required_categories_min_quantity_check CHECK ((min_quantity >= 1))
);


--
-- Name: promotion_required_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotion_required_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    promotion_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    site_id uuid NOT NULL,
    min_quantity integer DEFAULT 1 NOT NULL,
    CONSTRAINT promotion_required_items_min_quantity_check CHECK ((min_quantity >= 1))
);


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    campaign_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    code text,
    discount_type text NOT NULL,
    discount_value numeric NOT NULL,
    applies_to text DEFAULT 'all'::text NOT NULL,
    min_order_amount numeric,
    usage_limit integer,
    usage_count integer DEFAULT 0,
    status text DEFAULT 'draft'::text NOT NULL,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    channels text[] DEFAULT ARRAY['marketplace'::text, 'shop'::text, 'pos'::text] NOT NULL,
    location_ids uuid[] DEFAULT ARRAY[]::uuid[] NOT NULL,
    active_weekdays smallint[] DEFAULT '{}'::smallint[] NOT NULL,
    required_items_mode text DEFAULT 'all'::text NOT NULL,
    usage_limit_per_user integer,
    bogo_buy_qty integer DEFAULT 1 NOT NULL,
    bogo_get_qty integer DEFAULT 1 NOT NULL,
    image_url text,
    show_on_shop boolean DEFAULT false NOT NULL,
    show_on_marketplace boolean DEFAULT false NOT NULL,
    currency text,
    CONSTRAINT promotions_active_weekdays_check CHECK ((active_weekdays <@ ARRAY[(0)::smallint, (1)::smallint, (2)::smallint, (3)::smallint, (4)::smallint, (5)::smallint, (6)::smallint])),
    CONSTRAINT promotions_applies_to_check CHECK ((applies_to = ANY (ARRAY['all'::text, 'selected_items'::text]))),
    CONSTRAINT promotions_bogo_buy_qty_check CHECK ((bogo_buy_qty >= 1)),
    CONSTRAINT promotions_bogo_get_qty_check CHECK ((bogo_get_qty >= 1)),
    CONSTRAINT promotions_channels_check CHECK (((channels <@ ARRAY['marketplace'::text, 'shop'::text, 'pos'::text]) AND (cardinality(channels) >= 1))),
    CONSTRAINT promotions_discount_type_check CHECK ((discount_type = ANY (ARRAY['percent'::text, 'fixed'::text, 'bogo'::text]))),
    CONSTRAINT promotions_required_items_mode_check CHECK ((required_items_mode = ANY (ARRAY['all'::text, 'any'::text]))),
    CONSTRAINT promotions_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'paused'::text, 'expired'::text])))
);


--
-- Name: purchase_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_id uuid NOT NULL,
    site_id uuid NOT NULL,
    catalog_item_id uuid,
    name text DEFAULT ''::text NOT NULL,
    quantity numeric DEFAULT 1 NOT NULL,
    unit_cost numeric DEFAULT 0 NOT NULL,
    subtotal numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    vendor_company_id uuid,
    user_id uuid,
    title text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    amount_due numeric DEFAULT 0 NOT NULL,
    currency text DEFAULT 'USD'::text NOT NULL,
    payments jsonb DEFAULT '[]'::jsonb NOT NULL,
    purchase_date date DEFAULT CURRENT_DATE NOT NULL,
    location_id uuid,
    accounting_state text DEFAULT 'pending'::text NOT NULL,
    stock_received boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    public_access_token text,
    last_emailed_at timestamp with time zone,
    public_access_token_expires_at timestamp with time zone,
    public_access_token_revoked_at timestamp with time zone,
    due_date date,
    CONSTRAINT purchases_accounting_state_check CHECK ((accounting_state = ANY (ARRAY['pending'::text, 'posted'::text, 'unpublished'::text]))),
    CONSTRAINT purchases_due_date_calendar_check CHECK (((due_date IS NULL) OR (isfinite(due_date) AND ((due_date >= '0001-01-01'::date) AND (due_date <= '9999-12-31'::date))))),
    CONSTRAINT purchases_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'pending'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: quotation_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotation_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    quotation_id uuid NOT NULL,
    catalog_item_id uuid NOT NULL,
    name text NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price numeric DEFAULT 0 NOT NULL,
    subtotal numeric DEFAULT 0 NOT NULL,
    metadata jsonb
);


--
-- Name: quotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    deal_id uuid,
    lead_id uuid NOT NULL,
    buyer_user_id uuid,
    price_list_id uuid,
    status text DEFAULT 'draft'::text NOT NULL,
    valid_until timestamp with time zone,
    currency text DEFAULT 'USD'::text NOT NULL,
    notes text,
    subtotal numeric DEFAULT 0 NOT NULL,
    discount_total numeric DEFAULT 0 NOT NULL,
    total numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tax_total numeric DEFAULT 0 NOT NULL,
    public_access_token text,
    public_access_token_expires_at timestamp with time zone,
    public_access_token_revoked_at timestamp with time zone,
    checkout_claim_id uuid,
    checkout_claimed_at timestamp with time zone,
    checkout_sale_id uuid,
    checkout_order_id uuid,
    location_id uuid,
    CONSTRAINT quotations_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sent'::text, 'accepted'::text, 'rejected'::text, 'expired'::text])))
);


--
-- Name: record_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid,
    name text NOT NULL,
    description text,
    icon text,
    template_fields jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    parent_category_id uuid,
    system_key text
);


--
-- Name: record_diagram_edges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_diagram_edges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    site_id uuid NOT NULL,
    source_node_id uuid NOT NULL,
    target_node_id uuid NOT NULL,
    relation_type text DEFAULT 'relates_to'::text NOT NULL,
    label text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT record_diagram_edges_distinct_nodes_check CHECK ((source_node_id <> target_node_id)),
    CONSTRAINT record_diagram_edges_metadata_object_check CHECK ((jsonb_typeof(metadata) = 'object'::text))
);


--
-- Name: record_diagram_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_diagram_nodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    site_id uuid NOT NULL,
    kind text DEFAULT 'note'::text NOT NULL,
    title text DEFAULT 'Untitled'::text NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    position_x double precision DEFAULT 80 NOT NULL,
    position_y double precision DEFAULT 80 NOT NULL,
    embedding public.vector(1536),
    embedding_source_hash text,
    embedding_model text,
    embedding_updated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT record_diagram_nodes_kind_check CHECK ((kind = ANY (ARRAY['title'::text, 'description'::text, 'note'::text, 'concept'::text, 'question'::text, 'decision'::text, 'source'::text, 'process'::text, 'data'::text, 'database'::text, 'terminator'::text]))),
    CONSTRAINT record_diagram_nodes_metadata_object_check CHECK ((jsonb_typeof(metadata) = 'object'::text))
);


--
-- Name: record_diagrams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_diagrams (
    record_id uuid NOT NULL,
    site_id uuid NOT NULL,
    revision bigint DEFAULT 0 NOT NULL,
    viewport jsonb DEFAULT '{"x": 0, "y": 0, "zoom": 1}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT record_diagrams_viewport_object_check CHECK ((jsonb_typeof(viewport) = 'object'::text))
);


--
-- Name: records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.records (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    site_id uuid,
    category_id uuid,
    title text NOT NULL,
    description text,
    data jsonb DEFAULT '{}'::jsonb,
    relations jsonb DEFAULT '{}'::jsonb,
    status text DEFAULT 'draft'::text,
    embedding public.vector(1536),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    summary text,
    record_embedding_revision bigint DEFAULT 0 NOT NULL,
    source_type text,
    source_id text,
    location_id uuid
);


--
-- Name: referral_code_uses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_code_uses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    referral_code_id uuid NOT NULL,
    user_id uuid NOT NULL,
    used_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: referral_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    max_uses integer,
    current_uses integer DEFAULT 0,
    expires_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT referral_codes_current_uses_check CHECK ((current_uses >= 0)),
    CONSTRAINT referral_codes_max_uses_check CHECK (((max_uses IS NULL) OR (max_uses > 0)))
);


--
-- Name: remote_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remote_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    instance_type text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    provider_instance_id text,
    cdp_url text,
    timeout_hours integer DEFAULT 1,
    configuration jsonb DEFAULT '{}'::jsonb,
    environment_variables jsonb DEFAULT '{}'::jsonb,
    tools_enabled jsonb DEFAULT '["bash", "computer", "edit"]'::jsonb,
    last_screenshot_at timestamp with time zone,
    last_activity_at timestamp with time zone,
    total_commands_executed integer DEFAULT 0,
    estimated_cost numeric(10,4) DEFAULT 0.0000,
    actual_cost numeric(10,4) DEFAULT 0.0000,
    site_id uuid NOT NULL,
    user_id uuid NOT NULL,
    agent_id uuid,
    command_id uuid,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    stopped_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    is_archived boolean DEFAULT false NOT NULL,
    CONSTRAINT remote_instances_instance_type_check CHECK ((instance_type = ANY (ARRAY['ubuntu'::text, 'browser'::text, 'windows'::text]))),
    CONSTRAINT remote_instances_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'starting'::text, 'running'::text, 'paused'::text, 'stopping'::text, 'stopped'::text, 'error'::text, 'uninstantiated'::text])))
);


--
-- Name: remote_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remote_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone_number text NOT NULL,
    user_id uuid,
    site_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    instance_id uuid
);


--
-- Name: requirement_archived_runner_reassignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_archived_runner_reassignments (
    requirement_id uuid NOT NULL,
    site_id uuid NOT NULL,
    previous_instance_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    run_id text NOT NULL,
    previous_execution_generation integer NOT NULL,
    execution_generation integer NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT requirement_archived_runner__previous_execution_generatio_check CHECK ((previous_execution_generation >= 0)),
    CONSTRAINT requirement_archived_runner_reassign_execution_generation_check CHECK ((execution_generation > 0)),
    CONSTRAINT requirement_archived_runner_reassignments_check CHECK ((instance_id <> previous_instance_id)),
    CONSTRAINT requirement_archived_runner_reassignments_check1 CHECK (((execution_generation)::bigint = ((previous_execution_generation)::bigint + 1))),
    CONSTRAINT requirement_archived_runner_reassignments_run_id_check CHECK ((btrim(run_id) <> ''::text))
);


--
-- Name: requirement_campaigns; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.requirement_campaigns WITH (security_invoker='true') AS
 SELECT requirement_id,
    campaign_id
   FROM public.campaign_requirements;


--
-- Name: requirement_commands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requirement_commands (
    requirement_id uuid NOT NULL,
    action_id uuid NOT NULL,
    patch jsonb NOT NULL,
    revision bigint NOT NULL,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    applied_at timestamp with time zone,
    CONSTRAINT requirement_commands_patch_check CHECK ((jsonb_typeof(patch) = 'object'::text)),
    CONSTRAINT requirement_commands_revision_check CHECK ((revision > 0))
);

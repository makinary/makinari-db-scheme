SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: catalog_search_commerce_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_commerce_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE v_old uuid; v_new uuid; v_site uuid;
BEGIN
  IF TG_TABLE_NAME = 'sites' THEN
    IF TG_OP <> 'INSERT' THEN v_old := OLD.id; END IF;
    IF TG_OP <> 'DELETE' THEN v_new := NEW.id; END IF;
  ELSE
    IF TG_OP <> 'INSERT' THEN v_old := OLD.site_id; END IF;
    IF TG_OP <> 'DELETE' THEN v_new := NEW.site_id; END IF;
  END IF;
  FOR v_site IN SELECT DISTINCT x FROM unnest(ARRAY[v_old, v_new]) x WHERE x IS NOT NULL ORDER BY x
  LOOP
    PERFORM public.catalog_search_bump_revision(v_site);
  END LOOP;
  RETURN coalesce(NEW, OLD);
END $$;


--
-- Name: catalog_search_document_text(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_document_text(p_item_id uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
  SELECT left(btrim(regexp_replace(concat_ws(' ',
    'Name: ' || left(i.name, 1000), 'SKU: ' || left(i.sku, 250), 'Category: ' || left(c.name, 500),
    (SELECT string_agg(names.name, ' ' ORDER BY names.name COLLATE "C") FROM (
      SELECT DISTINCT left(s.name, 150) COLLATE "C" AS name
      FROM public.catalog_item_specs j JOIN public.item_specs s ON s.id = j.item_spec_id
      WHERE j.catalog_item_id = i.id AND s.site_id = i.site_id
      ORDER BY name LIMIT 20
    ) names),
    (SELECT string_agg(a.key || ' ' || left(i.metadata->'attributes'->>a.key, 200), ' ' ORDER BY a.key)
      FROM unnest(ARRAY['brand','material','dimensions','weight','warranty','duration',
        'level','language','format','license_type','color','size']) a(key)
      WHERE jsonb_typeof(i.metadata->'attributes'->a.key) = 'string'),
    'Description: ' || left(i.description, 6000)
  ), '[[:space:]]+', ' ', 'g')), 6000)
  FROM public.catalog_items i
  LEFT JOIN public.catalog_categories c ON c.id = i.category_id AND c.site_id = i.site_id
  WHERE i.id = p_item_id
$$;


--
-- Name: catalog_search_drain_refresh_events(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_drain_refresh_events(p_limit integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE v_event record; v_locked uuid; v_count integer := 0;
BEGIN
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'invalid refresh limit' USING ERRCODE = '22023';
  END IF;
  FOR v_event IN SELECT e.id, e.catalog_item_id, e.revive_exhausted FROM public.catalog_search_refresh_events e
    ORDER BY e.id LIMIT p_limit FOR UPDATE SKIP LOCKED
  LOOP
    SELECT i.id INTO v_locked FROM public.catalog_items i WHERE i.id = v_event.catalog_item_id
      FOR NO KEY UPDATE SKIP LOCKED;
    IF NOT FOUND AND EXISTS (SELECT 1 FROM public.catalog_items WHERE id = v_event.catalog_item_id) THEN
      CONTINUE; -- Busy source: retain request, never wait while holding queue/item locks.
    END IF;
    IF v_locked IS NOT NULL THEN
      PERFORM public.refresh_catalog_search_document(v_event.catalog_item_id);
      IF v_event.revive_exhausted THEN
        UPDATE public.catalog_embedding_jobs SET status = 'pending', attempts = 0,
          next_attempt_at = now(), last_error = NULL, updated_at = now()
          WHERE catalog_item_id = v_event.catalog_item_id AND status = 'exhausted';
      END IF;
    END IF;
    DELETE FROM public.catalog_search_refresh_events WHERE id = v_event.id;
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END $$;


--
-- Name: catalog_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    kind text NOT NULL,
    name text NOT NULL,
    description text,
    sku text,
    cost numeric,
    lowest_sale_price numeric,
    target_sale_price numeric,
    track_inventory boolean DEFAULT false,
    availability_mode text DEFAULT 'manual'::text,
    availability_status text DEFAULT 'available'::text,
    status text DEFAULT 'active'::text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    category_id uuid,
    is_pos_available boolean DEFAULT true,
    is_recurring boolean DEFAULT false,
    is_reservation boolean DEFAULT false,
    image_url text,
    digital_subtype text,
    is_marketplace_listed boolean DEFAULT true,
    currency text DEFAULT 'USD'::text NOT NULL,
    parent_id uuid,
    is_purchasable boolean DEFAULT true,
    pass_uses integer,
    pass_validity_days integer,
    is_dynamic_price boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    redeem_assignment_mode text DEFAULT 'user_choice'::text NOT NULL,
    CONSTRAINT catalog_items_availability_mode_check CHECK ((availability_mode = ANY (ARRAY['manual'::text, 'inventory'::text, 'always'::text]))),
    CONSTRAINT catalog_items_availability_status_check CHECK ((availability_status = ANY (ARRAY['available'::text, 'unavailable'::text, 'sold_out'::text]))),
    CONSTRAINT catalog_items_digital_subtype_check CHECK ((digital_subtype = ANY (ARRAY['ticket'::text, 'course'::text, 'file'::text, 'pass'::text, 'license'::text]))),
    CONSTRAINT catalog_items_kind_check CHECK ((kind = ANY (ARRAY['product'::text, 'service'::text, 'digital_asset'::text]))),
    CONSTRAINT catalog_items_redeem_assignment_mode_check CHECK ((redeem_assignment_mode = ANY (ARRAY['user_choice'::text, 'round_robin'::text]))),
    CONSTRAINT catalog_items_status_check CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text])))
);


--
-- Name: catalog_search_eligible(public.catalog_items, uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_eligible(i public.catalog_items, p_site_id uuid, p_channel text, p_filters jsonb) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
  SELECT (p_site_id IS NULL OR i.site_id = p_site_id)
    AND EXISTS (SELECT 1 FROM public.sites s WHERE s.id = i.site_id AND s.archived_at IS NULL)
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_each(p_filters) f
      WHERE CASE WHEN f.key = 'kind' THEN NOT (
        (f.value = '"variant"'::jsonb AND i.parent_id IS NOT NULL) OR
        (f.value <> '"variant"'::jsonb AND to_jsonb(i)->'kind' = f.value
          AND (p_channel <> 'catalog' OR i.parent_id IS NULL)))
        WHEN f.key IN ('category_id','parent_id') AND f.value <> 'null'::jsonb
        THEN (to_jsonb(i)->>f.key)::uuid IS DISTINCT FROM (f.value #>> '{}')::uuid
        ELSE coalesce(to_jsonb(i)->f.key, 'null'::jsonb) IS DISTINCT FROM f.value END
    )
    AND CASE
      WHEN p_channel = 'catalog' THEN true
      WHEN p_channel = 'tools' THEN
        (p_filters ? 'status' OR p_filters ? 'availability_status') OR
        (i.status = 'active' AND i.availability_status = 'available' AND
          (i.parent_id IS NULL OR EXISTS (SELECT 1 FROM public.catalog_items p
            WHERE p.id = i.parent_id AND p.site_id = i.site_id
              AND p.status = 'active' AND p.availability_status = 'available')))
      WHEN p_channel IN ('shop','marketplace') THEN
        i.status = 'active' AND i.is_marketplace_listed IS TRUE AND i.parent_id IS NULL
        AND (i.availability_mode IS DISTINCT FROM 'manual' OR i.availability_status = 'available')
      WHEN p_channel = 'pos' THEN
        i.status = 'active' AND i.is_pos_available IS DISTINCT FROM false
        AND (i.availability_mode IS DISTINCT FROM 'manual' OR i.availability_status = 'available')
        AND (i.parent_id IS NULL OR EXISTS (SELECT 1 FROM public.catalog_items p
          WHERE p.id = i.parent_id AND p.site_id = i.site_id AND p.status = 'active'
            AND p.is_pos_available IS DISTINCT FROM false
            AND (p.availability_mode IS DISTINCT FROM 'manual' OR p.availability_status = 'available')))
      ELSE false
    END
$$;


--
-- Name: catalog_search_index_pending(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_index_pending() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
  SELECT EXISTS (SELECT 1 FROM public.catalog_search_refresh_events)
    OR EXISTS (SELECT 1 FROM public.catalog_embedding_jobs j WHERE j.attempts < 8
      AND ((j.status IN ('pending','retry') AND j.next_attempt_at <= statement_timestamp())
        OR (j.status = 'leased' AND j.lease_expires_at <= statement_timestamp())))
$$;


--
-- Name: catalog_search_item_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_item_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE v_changed boolean;
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.catalog_search_bump_revision(OLD.site_id);
    RETURN OLD;
  END IF;
  v_changed := public.refresh_catalog_search_document(NEW.id);
  IF NOT v_changed THEN PERFORM public.catalog_search_bump_revision(NEW.site_id); END IF;
  IF TG_OP = 'UPDATE' AND OLD.site_id IS DISTINCT FROM NEW.site_id THEN
    PERFORM public.catalog_search_bump_revision(OLD.site_id);
  END IF;
  RETURN NEW;
END $$;


--
-- Name: catalog_search_refresh_batch(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_refresh_batch(p_limit integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
BEGIN
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'invalid refresh batch limit' USING ERRCODE = '22023';
  END IF;
  RETURN public.catalog_search_drain_refresh_events(p_limit);
END $$;


--
-- Name: catalog_search_relationship_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_relationship_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE v_old jsonb; v_new jsonb; v_site uuid;
BEGIN
  IF TG_OP <> 'INSERT' THEN v_old := to_jsonb(OLD); END IF;
  IF TG_OP <> 'DELETE' THEN v_new := to_jsonb(NEW); END IF;
  IF TG_TABLE_NAME = 'catalog_item_specs' THEN
    INSERT INTO public.catalog_search_refresh_events(catalog_item_id)
      SELECT DISTINCT x FROM unnest(ARRAY[(v_old->>'catalog_item_id')::uuid,
        (v_new->>'catalog_item_id')::uuid]) x WHERE x IS NOT NULL;
    -- Links have no site_id. Invalidate the actual old/new item sites immediately.
    FOR v_site IN SELECT DISTINCT i.site_id FROM public.catalog_items i
      WHERE i.id IN ((v_old->>'catalog_item_id')::uuid, (v_new->>'catalog_item_id')::uuid)
    LOOP PERFORM public.catalog_search_bump_revision(v_site); END LOOP;
  ELSIF TG_TABLE_NAME = 'catalog_categories' THEN
    INSERT INTO public.catalog_search_refresh_events(catalog_item_id)
      SELECT i.id FROM public.catalog_items i
      WHERE i.category_id IN ((v_old->>'id')::uuid, (v_new->>'id')::uuid);
  ELSIF TG_TABLE_NAME = 'item_specs' THEN
    INSERT INTO public.catalog_search_refresh_events(catalog_item_id)
      SELECT DISTINCT j.catalog_item_id FROM public.catalog_item_specs j
      WHERE j.item_spec_id IN ((v_old->>'id')::uuid, (v_new->>'id')::uuid);
  END IF;
  FOR v_site IN SELECT DISTINCT x FROM unnest(ARRAY[(v_old->>'site_id')::uuid,
    (v_new->>'site_id')::uuid]) x WHERE x IS NOT NULL
  LOOP PERFORM public.catalog_search_bump_revision(v_site); END LOOP;
  RETURN coalesce(NEW, OLD);
END $$;


--
-- Name: catalog_search_revision(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_revision(p_site_id uuid DEFAULT NULL::uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
  SELECT 'events-v1:' || count(*)::text || ':' || coalesce(max(e.id), 0)::text
  FROM public.catalog_search_revision_events e
  WHERE p_site_id IS NULL OR e.site_id = p_site_id
$$;


--
-- Name: catalog_search_validate(uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_validate(p_site_id uuid, p_channel text, p_filters jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $_$
DECLARE v_key text; v_value jsonb; v_text text;
BEGIN
  IF p_channel IS NULL OR p_channel NOT IN ('tools', 'shop', 'marketplace', 'catalog', 'pos')
    OR (p_site_id IS NULL AND p_channel <> 'marketplace') THEN
    RAISE EXCEPTION 'invalid search scope/channel' USING ERRCODE = '22023';
  END IF;
  IF p_filters IS NULL OR jsonb_typeof(p_filters) <> 'object' THEN
    RAISE EXCEPTION 'filters must be an object' USING ERRCODE = '22023';
  END IF;
  FOR v_key, v_value IN SELECT * FROM jsonb_each(p_filters) LOOP
    v_text := v_value #>> '{}';
    IF v_key NOT IN ('kind','digital_subtype','category_id','parent_id','status','availability_status',
      'currency','is_reservation','is_purchasable','is_recurring','is_pos_available','is_marketplace_listed') THEN
      RAISE EXCEPTION 'unsupported catalog filter' USING ERRCODE = '22023';
    END IF;
    IF v_key LIKE 'is\_%' ESCAPE '\' THEN
      IF jsonb_typeof(v_value) <> 'boolean' THEN
        RAISE EXCEPTION 'boolean filter required' USING ERRCODE = '22023';
      END IF;
    ELSIF v_key IN ('category_id', 'parent_id') THEN
      IF v_value <> 'null'::jsonb AND (jsonb_typeof(v_value) <> 'string' OR
        v_text !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') THEN
        RAISE EXCEPTION 'UUID or null filter required' USING ERRCODE = '22023';
      END IF;
    ELSIF jsonb_typeof(v_value) <> 'string' OR length(v_text) NOT BETWEEN 1 AND 80 THEN
      RAISE EXCEPTION 'string filter required' USING ERRCODE = '22023';
    END IF;
    IF (v_key = 'kind' AND v_text NOT IN ('product', 'service', 'digital_asset', 'variant'))
      OR (v_key = 'status' AND v_text NOT IN ('active','archived'))
      OR (v_key = 'availability_status' AND v_text NOT IN ('available','unavailable','sold_out'))
      OR (v_key = 'currency' AND v_text !~ '^[A-Z]{3}$') THEN
      RAISE EXCEPTION 'invalid catalog filter value' USING ERRCODE = '22023';
    END IF;
  END LOOP;
END $_$;


--
-- Name: catalog_search_visible_ids(uuid[], uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_visible_ids(p_ids uuid[], p_site_id uuid, p_channel text, p_filters jsonb) RETURNS TABLE(id uuid, site_id uuid)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
BEGIN
  PERFORM public.catalog_search_validate(p_site_id, p_channel, p_filters);
  IF p_ids IS NULL OR cardinality(p_ids) > 400 OR array_position(p_ids, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'invalid visible ID bounds' USING ERRCODE = '22023';
  END IF;
  RETURN QUERY SELECT i.id, i.site_id FROM public.catalog_items i
    WHERE i.id = ANY(p_ids) AND public.catalog_search_eligible(i, p_site_id, p_channel, p_filters)
    ORDER BY i.id;
END $$;


--
-- Name: check_billing_system(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_billing_system() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16699(); END$$;


--
-- Name: check_create_update_permission(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_create_update_permission() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
DECLARE
    target_site_id UUID;
    current_user_id UUID;
    user_role TEXT;
    is_owner BOOLEAN := FALSE;
    is_admin BOOLEAN := FALSE;
    is_collaborator BOOLEAN := FALSE;
    is_service_role BOOLEAN := FALSE;
    is_superuser BOOLEAN := FALSE;
BEGIN

    -- sql_editor_direct_postgres_session_v1
    IF session_user = 'postgres'
       AND current_setting('role', true) IN ('none', 'postgres')
       AND auth.uid() IS NULL
       AND coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb) = '{}'::jsonb
    THEN
        RETURN NEW;
    END IF;
    -- NEW: Check if current user is superuser (postgres)
    SELECT rolsuper INTO is_superuser 
    FROM pg_roles 
    WHERE rolname = current_user;
    
    -- Allow superuser to bypass all restrictions
    IF is_superuser THEN
        RETURN NEW;
    END IF;
    
    -- Check if this is service_role (bypass restrictions)
    -- Fix: The previous check `current_setting('role') = 'service_role'` only checks the PostgreSQL role,
    -- which is usually 'authenticator' for API requests. We need to check the JWT claims.
    BEGIN
        is_service_role := (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');
    EXCEPTION WHEN OTHERS THEN
        is_service_role := FALSE;
    END;
    
    -- Allow service_role to bypass restrictions
    IF is_service_role THEN
        RETURN NEW;
    END IF;
    
    -- Get current user
    current_user_id := auth.uid();
    
    -- If no user, block the operation
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'CREATE_UPDATE_PERMISSION_DENIED: Authentication required';
    END IF;
    
    -- Get the site_id from the record being inserted/updated
    CASE TG_TABLE_NAME
        WHEN 'visitors' THEN
            -- visitors doesn't have direct site_id, get from related tables
            IF NEW.segment_id IS NOT NULL THEN
                SELECT s.site_id INTO target_site_id
                FROM public.segments s
                WHERE s.id = NEW.segment_id;
            ELSIF NEW.lead_id IS NOT NULL THEN
                SELECT l.site_id INTO target_site_id
                FROM public.leads l
                WHERE l.id = NEW.lead_id;
            ELSE
                -- Allow if can't determine site_id (system operation)
                RETURN NEW;
            END IF;
            
        WHEN 'visitor_sessions' THEN
            target_site_id := NEW.site_id;
            
        WHEN 'messages' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.conversations c 
            WHERE c.id = NEW.conversation_id;
            
        ELSE
            -- Default: assume table has site_id column
            BEGIN
                EXECUTE format('SELECT ($1).site_id') USING NEW INTO target_site_id;
            EXCEPTION WHEN OTHERS THEN
                -- If no site_id column, allow operation (might be system table)
                RETURN NEW;
            END;
    END CASE;
    
    -- If we couldn't determine site_id, allow the operation (might be system table)
    IF target_site_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check if user is site owner (fastest check)
    SELECT EXISTS (
        SELECT 1 FROM public.site_ownership 
        WHERE site_id = target_site_id AND user_id = current_user_id
    ) INTO is_owner;
    
    -- If owner, allow immediately
    IF is_owner THEN
        RETURN NEW;
    END IF;
    
    -- Check user role in site_members
    SELECT role INTO user_role
    FROM public.site_members 
    WHERE site_id = target_site_id 
    AND user_id = current_user_id 
    AND status = 'active';
    
    -- Set role flags
    is_admin := (user_role = 'admin');
    is_collaborator := (user_role = 'collaborator');
    
    -- Allow admin and collaborator to create/update
    IF is_admin OR is_collaborator THEN
        RETURN NEW;
    END IF;
    
    -- Block marketing (viewer) and any other roles
    RAISE EXCEPTION 'CREATE_UPDATE_PERMISSION_DENIED: Only site owners, admins, and collaborators can create/update records. Your role: % on site: %', 
        COALESCE(user_role, 'none'), target_site_id;
END;
$_$;

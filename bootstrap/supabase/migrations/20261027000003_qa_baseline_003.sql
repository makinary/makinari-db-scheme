SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: original_16785(uuid, uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16785(user_id_param uuid, site_id_param uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  site_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.sites 
    WHERE id = site_id_param 
    AND user_id = user_id_param
  ) INTO site_exists;
  
  RETURN site_exists;
END;
$$;


--
-- Name: original_16788(text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16788(code_param text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  referral_record RECORD;
BEGIN
  -- Validar parámetro de entrada
  IF code_param IS NULL OR code_param = '' THEN
    RETURN FALSE;
  END IF;

  -- Buscar el código de referido
  SELECT *
  INTO referral_record
  FROM public.referral_codes
  WHERE code = code_param
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > NOW());
  
  -- Si no existe el código, retornar falso
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Si tiene límite de usos, verificar que no se haya excedido
  IF referral_record.max_uses IS NOT NULL THEN
    IF referral_record.current_uses >= referral_record.max_uses THEN
      RETURN FALSE;
    END IF;
  END IF;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    -- En caso de cualquier error, retornar FALSE
    RETURN FALSE;
END;
$$;


--
-- Name: original_2912363(text[]); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_2912363(phone_variants text[]) RETURNS TABLE(id uuid, phone text, raw_user_meta_data jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT au.id, au.phone::text, au.raw_user_meta_data
  FROM auth.users au
  WHERE au.phone = ANY(phone_variants)
     OR au.raw_user_meta_data->>'phone' = ANY(phone_variants);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: site_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_id uuid NOT NULL,
    user_id uuid,
    role text NOT NULL,
    added_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    email text NOT NULL,
    name text,
    "position" text,
    status text DEFAULT 'pending'::text,
    blocked_screens text[] DEFAULT '{}'::text[] NOT NULL,
    restrict_to_assigned_only boolean DEFAULT false,
    license_suspended boolean DEFAULT false NOT NULL,
    manually_disabled boolean DEFAULT false NOT NULL,
    CONSTRAINT site_members_manual_disable_suspends CHECK (((NOT manually_disabled) OR license_suspended)),
    CONSTRAINT site_members_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'marketing'::text, 'collaborator'::text]))),
    CONSTRAINT site_members_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'rejected'::text])))
);


--
-- Name: original_3880809(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_3880809(p_site_id uuid) RETURNS SETOF public.site_members
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  uid uuid := auth.uid();
  allowed boolean := false;
BEGIN
  IF uid IS NULL OR p_site_id IS NULL THEN
    RETURN;
  END IF;

  allowed := EXISTS (
    SELECT 1
    FROM public.sites s
    WHERE s.id = p_site_id
      AND s.user_id = uid
  );

  IF NOT allowed THEN
    allowed := EXISTS (
      SELECT 1
      FROM public.site_members sm
      WHERE sm.site_id = p_site_id
        AND sm.user_id = uid
    );
  END IF;

  IF NOT allowed THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT sm.*
  FROM public.site_members sm
  WHERE sm.site_id = p_site_id
  ORDER BY sm.role DESC;
END;
$$;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    url text,
    description text,
    logo_url text,
    resource_urls jsonb DEFAULT '[]'::jsonb,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tracking jsonb DEFAULT '{"record_screen": false, "track_actions": false, "track_visitors": false}'::jsonb,
    command_id uuid,
    archived_at timestamp with time zone,
    archived_by uuid,
    archive_snapshot jsonb
);


--
-- Name: original_3927106(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_3927106() RETURNS SETOF public.sites
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
  SELECT s.* FROM public.sites s WHERE s.archived_at IS NULL AND public.current_user_site_role(s.id) IS NOT NULL;
$$;


--
-- Name: original_3976648(uuid); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_3976648(p_site_id uuid) RETURNS TABLE(name text, "offset" integer, count integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    SET row_security TO 'off'
    AS $$
  WITH listed AS (
    SELECT
      COALESCE(NULLIF(BTRIM(cc.name), ''), 'Other') AS category_name,
      (ROW_NUMBER() OVER (
        ORDER BY ci.sort_order ASC NULLS LAST, ci.name ASC NULLS LAST, ci.id ASC
      ) - 1)::integer AS row_offset
    FROM public.catalog_items ci
    LEFT JOIN public.catalog_categories cc ON cc.id = ci.category_id
    WHERE ci.site_id = p_site_id
      AND ci.status = 'active'
      AND ci.is_marketplace_listed = true
      AND ci.parent_id IS NULL
      AND (
        ci.availability_mode IS NULL
        OR ci.availability_mode <> 'manual'
        OR ci.availability_status = 'available'
      )
  )
  SELECT
    category_name AS name,
    MIN(row_offset) AS "offset",
    COUNT(*)::integer AS count
  FROM listed
  GROUP BY category_name
  ORDER BY MIN(row_offset);
$$;


--
-- Name: original_4106481(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4106481() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  SELECT pur.role
  FROM public.platform_user_roles pur
  WHERE pur.user_id = auth.uid()
  LIMIT 1;
$$;


--
-- Name: original_4185985(uuid, uuid[], text, uuid, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4185985(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid DEFAULT NULL::uuid, p_status text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  actor_id uuid := auth.uid();
  requested_count integer;
  matched_count integer;
  updated_count integer := 0;
  is_service_role boolean :=
    current_setting('role', true) = 'service_role'
    OR COALESCE((auth.jwt() ->> 'role') = 'service_role', false)
    OR session_user = 'postgres';
  is_owner boolean := false;
  member_role text;
  restrict_to_assigned boolean := false;
  transitions jsonb;
BEGIN
  SELECT count(*)
  INTO requested_count
  FROM (
    SELECT DISTINCT requested.unit_id
    FROM unnest(p_unit_ids) AS requested(unit_id)
    WHERE requested.unit_id IS NOT NULL
  ) AS requested_units;

  IF requested_count = 0 OR requested_count > 100 THEN
    RAISE EXCEPTION 'Select between 1 and 100 order-line units';
  END IF;

  IF NOT is_service_role THEN
    IF actor_id IS NULL THEN
      RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    SELECT (
      EXISTS (
        SELECT 1 FROM public.sites AS site
        WHERE site.id = p_site_id
          AND site.user_id = actor_id
      )
      OR EXISTS (
        SELECT 1 FROM public.site_ownership AS ownership
        WHERE ownership.site_id = p_site_id
          AND ownership.user_id = actor_id
      )
    )
    INTO is_owner;

    SELECT member.role::text, COALESCE(member.restrict_to_assigned_only, false)
    INTO member_role, restrict_to_assigned
    FROM public.site_members AS member
    WHERE member.site_id = p_site_id
      AND member.user_id = actor_id
      AND member.status = 'active'
    LIMIT 1;

    IF NOT is_owner
      AND COALESCE(member_role, '') NOT IN (
        'owner',
        'admin',
        'collaborator'
      )
    THEN
      RAISE EXCEPTION 'Insufficient permissions' USING ERRCODE = '42501';
    END IF;
  END IF;

  PERFORM item.id
  FROM public.sale_order_items AS item
  WHERE item.id IN (
    SELECT unit.sale_order_item_id
    FROM public.sale_order_item_units AS unit
    WHERE unit.site_id = p_site_id
      AND unit.id = ANY(p_unit_ids)
  )
  ORDER BY item.id
  FOR UPDATE;

  PERFORM 1
  FROM public.sale_order_item_units AS unit
  WHERE unit.site_id = p_site_id
    AND unit.id = ANY(p_unit_ids)
  ORDER BY unit.id
  FOR UPDATE;

  SELECT count(*)
  INTO matched_count
  FROM public.sale_order_item_units AS unit
  WHERE unit.site_id = p_site_id
    AND unit.id = ANY(p_unit_ids);

  IF matched_count <> requested_count THEN
    RAISE EXCEPTION 'One or more order-line units were not found';
  END IF;

  IF NOT is_service_role AND NOT is_owner AND restrict_to_assigned THEN
    IF EXISTS (
      SELECT 1
      FROM public.sale_order_item_units AS unit
      WHERE unit.site_id = p_site_id
        AND unit.id = ANY(p_unit_ids)
        AND unit.assigned_to IS DISTINCT FROM actor_id
    ) THEN
      RAISE EXCEPTION 'Restricted members can only update assigned units'
        USING ERRCODE = '42501';
    END IF;
    IF p_operation = 'assign'
      AND p_assignee_id IS DISTINCT FROM actor_id
    THEN
      RAISE EXCEPTION 'Restricted members cannot reassign units'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  IF p_operation = 'assign' THEN
    IF p_assignee_id IS NOT NULL AND NOT (
      EXISTS (
        SELECT 1 FROM public.sites AS site
        WHERE site.id = p_site_id
          AND site.user_id = p_assignee_id
      )
      OR EXISTS (
        SELECT 1 FROM public.site_ownership AS ownership
        WHERE ownership.site_id = p_site_id
          AND ownership.user_id = p_assignee_id
      )
      OR EXISTS (
        SELECT 1 FROM public.site_members AS member
        WHERE member.site_id = p_site_id
          AND member.user_id = p_assignee_id
          AND member.status = 'active'
      )
    ) THEN
      RAISE EXCEPTION 'Assignee must be an active site member';
    END IF;

    UPDATE public.sale_order_item_units
    SET assigned_to = p_assignee_id
    WHERE site_id = p_site_id
      AND id = ANY(p_unit_ids);
  ELSIF p_operation = 'advance' THEN
    transitions := p_status::jsonb;
    IF transitions IS NULL
      OR jsonb_object_length(transitions) <> requested_count
    THEN
      RAISE EXCEPTION 'Expected transitions are required';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.sale_order_item_units AS unit
      WHERE unit.site_id = p_site_id
        AND unit.id = ANY(p_unit_ids)
        AND transitions ->> unit.id::text IS DISTINCT FROM CASE unit.status
          WHEN 'draft' THEN 'preparing'
          WHEN 'new' THEN 'preparing'
          WHEN 'pending' THEN 'preparing'
          WHEN 'preparing' THEN 'completed'
          WHEN 'in_progress' THEN 'completed'
          WHEN 'completed' THEN 'returned'
          WHEN 'ready' THEN 'returned'
          ELSE NULL
        END
    ) THEN
      RAISE EXCEPTION 'Order-line units changed before this update';
    END IF;

    UPDATE public.sale_order_item_units
    SET status = transitions ->> id::text
    WHERE site_id = p_site_id
      AND id = ANY(p_unit_ids);
  ELSIF p_operation = 'set_status' THEN
    IF p_status NOT IN ('preparing', 'completed', 'returned') THEN
      RAISE EXCEPTION 'Invalid target status';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.sale_order_item_units AS unit
      WHERE unit.site_id = p_site_id
        AND unit.id = ANY(p_unit_ids)
        AND p_status IS DISTINCT FROM CASE unit.status
          WHEN 'draft' THEN 'preparing'
          WHEN 'new' THEN 'preparing'
          WHEN 'pending' THEN 'preparing'
          WHEN 'preparing' THEN 'completed'
          WHEN 'in_progress' THEN 'completed'
          WHEN 'completed' THEN 'returned'
          WHEN 'ready' THEN 'returned'
          ELSE NULL
        END
    ) THEN
      RAISE EXCEPTION 'Order-line units can only move to their next status';
    END IF;

    UPDATE public.sale_order_item_units
    SET status = p_status
    WHERE site_id = p_site_id
      AND id = ANY(p_unit_ids);
  ELSIF p_operation = 'cancel' THEN
    UPDATE public.sale_order_item_units
    SET status = 'cancelled'
    WHERE site_id = p_site_id
      AND id = ANY(p_unit_ids)
      AND status NOT IN ('cancelled', 'returned');
  ELSE
    RAISE EXCEPTION 'Invalid order-line unit operation';
  END IF;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$;


--
-- Name: original_4228212(uuid, integer); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_4228212(p_task_id uuid, p_time_window_hours integer) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  UPDATE public.tasks
  SET metadata = coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
      '_reminder_' || p_time_window_hours::text || 'h_sent',
      true
    )
  WHERE id = p_task_id;
$$;

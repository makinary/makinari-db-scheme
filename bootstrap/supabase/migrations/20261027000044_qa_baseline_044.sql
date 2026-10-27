SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: manually_activate_user_memberships(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.manually_activate_user_memberships(user_email text) RETURNS integer
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    member_record RECORD;
    user_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    -- First, find the user by email
    SELECT id, email INTO user_record
    FROM profiles 
    WHERE email = user_email
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User with email % not found', user_email;
    END IF;
    
    -- Find all pending site_members with this email
    FOR member_record IN 
        SELECT id, site_id, role, email
        FROM site_members 
        WHERE email = user_email 
        AND user_id IS NULL
        AND status = 'pending'
    LOOP
        -- Update the site_member with the user_id and set status to active
        UPDATE site_members 
        SET 
            user_id = user_record.id,
            status = 'active',
            updated_at = NOW()
        WHERE id = member_record.id;
        
        updated_count := updated_count + 1;
        
        -- If this member is an owner, create the site_ownership record
        IF member_record.role = 'owner' THEN
            INSERT INTO site_ownership (site_id, user_id, created_at)
            VALUES (member_record.site_id, user_record.id, NOW())
            ON CONFLICT (site_id, user_id) DO NOTHING; -- Prevent duplicates
        END IF;
    END LOOP;
    
    RETURN updated_count;
END;
$$;


--
-- Name: mark_image_generation_reservation_pending(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_image_generation_reservation_pending(p_site_id uuid, p_operation_id text, p_token uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  UPDATE public.image_generation_credit_reservations SET state='pending',reason='outcome_uncertain'
    WHERE site_id=p_site_id AND operation_id=p_operation_id AND dispatch_token=p_token AND state IN ('dispatched','pending');
  RETURN jsonb_build_object('success',FOUND);
END $$;


--
-- Name: mark_reservation_reminder_sent(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_reservation_reminder_sent(p_reservation_id uuid, p_time_window_hours integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_4228213($1,$2); RETURN; END$_$;


--
-- Name: mark_task_reminder_sent(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_task_reminder_sent(p_task_id uuid, p_time_window_hours integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_4228212($1,$2); RETURN; END$_$;


--
-- Name: marketplace_assert_actor(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.marketplace_assert_actor(p_site_id uuid, p_actor_user_id uuid, p_manager boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE claims text := current_setting('request.jwt.claims',true);
  subject text := current_setting('request.jwt.claim.sub',true); allowed boolean; actor_role text;
BEGIN
  IF NOT public.marketplace_is_backend() OR p_actor_user_id IS NULL THEN
    RAISE EXCEPTION 'Marketplace backend actor required' USING ERRCODE = '42501';
  END IF;
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',p_actor_user_id,'role','service_role')::text,true);
  PERFORM set_config('request.jwt.claim.sub',p_actor_user_id::text,true);
  actor_role := public.current_user_site_role(p_site_id);
  allowed := public.user_can(p_site_id,'update') AND (NOT p_manager OR actor_role IN ('owner','admin'));
  PERFORM set_config('request.jwt.claims',coalesce(claims,''),true);
  PERFORM set_config('request.jwt.claim.sub',coalesce(subject,''),true);
  IF allowed IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Marketplace actor has insufficient site permission' USING ERRCODE = '42501';
  END IF;
END;
$$;


--
-- Name: marketplace_capabilities(text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.marketplace_capabilities(p_provider text, p_state text, p_manual_ready boolean) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  SELECT jsonb_build_object('accept',p_state = 'pending','reject',p_state = 'pending',
    'ready',p_provider = 'rappi' AND p_manual_ready AND p_state = 'accepted',
    'cancel',p_provider = 'uber_eats' AND p_state IN ('accepted','ready'),
    'request_delivery',false,'cancel_delivery',false)
$$;


--
-- Name: marketplace_is_backend(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.marketplace_is_backend() RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  SELECT current_setting('role', true) = 'service_role'
    OR (current_setting('role', true) = 'none' AND session_user = 'postgres')
$$;


--
-- Name: marketplace_modifier_nodes(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.marketplace_modifier_nodes(p_item jsonb) RETURNS TABLE(modifier jsonb, external_key text, parent_key text, included boolean)
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  WITH RECURSIVE tree(node,key,parent,depth,price_included) AS (
    SELECT value,(p_item->>'external_id')||':modifier:'||(value->>'external_id'),p_item->>'external_id',1,
      coalesce((p_item->>'modifiers_included_in_price')::boolean,false)
    FROM jsonb_array_elements(coalesce(p_item->'modifiers','[]'::jsonb))
    UNION ALL
    SELECT child.value,tree.key||':modifier:'||(child.value->>'external_id'),tree.key,tree.depth+1,
      tree.price_included OR coalesce((tree.node->>'modifiers_included_in_price')::boolean,false)
    FROM tree CROSS JOIN LATERAL jsonb_array_elements(coalesce(tree.node->'modifiers','[]'::jsonb)) child
    WHERE tree.depth < 10
  ) SELECT node,key,parent,price_included FROM tree ORDER BY depth,key
$$;


--
-- Name: marketplace_native_state(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.marketplace_native_state(p_state text, p_provider text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  SELECT CASE WHEN p_state = 'accepted' THEN 'pending' WHEN p_state = 'ready' THEN 'in_progress'
    WHEN p_state = 'completed' THEN 'completed' WHEN p_state = 'cancelled' THEN 'cancelled'
    WHEN p_state = 'rejected' AND p_provider = 'rappi' THEN 'cancelled' ELSE 'draft' END
$$;


--
-- Name: match_instance_context_memories(uuid, uuid, public.vector, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.match_instance_context_memories(p_instance_id uuid, p_site_id uuid, p_embedding public.vector, p_limit integer DEFAULT 3) RETURNS TABLE(id uuid, summary text, similarity double precision)
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'extensions', 'pg_temp'
    AS $$
  SELECT m.id, m.summary, (1 - (m.embedding <=> p_embedding))::float
  FROM public.instance_context_memories m
  WHERE m.instance_id = p_instance_id AND m.site_id = p_site_id
  ORDER BY m.embedding <=> p_embedding LIMIT LEAST(GREATEST(p_limit, 1), 5);
$$;


--
-- Name: match_record_diagram_nodes(public.vector, uuid, uuid, double precision, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.match_record_diagram_nodes(query_embedding public.vector, p_site_id uuid, p_record_id uuid DEFAULT NULL::uuid, match_threshold double precision DEFAULT 0.5, match_count integer DEFAULT 10) RETURNS TABLE(id uuid, record_id uuid, kind text, title text, content text, similarity double precision)
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  SELECT
    n.id,
    n.record_id,
    n.kind,
    n.title,
    n.content,
    1 - (n.embedding <=> query_embedding) AS similarity
  FROM public.record_diagram_nodes n
  WHERE n.site_id = p_site_id
    AND (p_record_id IS NULL OR n.record_id = p_record_id)
    AND n.embedding IS NOT NULL
    AND 1 - (n.embedding <=> query_embedding) > match_threshold
  ORDER BY n.embedding <=> query_embedding
  LIMIT GREATEST(1, LEAST(COALESCE(match_count, 10), 200));
$$;


--
-- Name: match_records(public.vector, double precision, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.match_records(query_embedding public.vector, match_threshold double precision, match_count integer, p_site_id uuid) RETURNS TABLE(id uuid, category_id uuid, title text, description text, summary text, data jsonb, relations jsonb, status text, created_at timestamp with time zone, similarity double precision)
    LANGUAGE sql STABLE
    AS $$
  SELECT
    id,
    category_id,
    title,
    description,
    summary,
    data,
    relations,
    status,
    created_at,
    1 - (records.embedding <=> query_embedding) as similarity
  FROM
    public.records
  WHERE
    site_id = p_site_id
    AND 1 - (records.embedding <=> query_embedding) > match_threshold
  ORDER BY
    records.embedding <=> query_embedding
  LIMIT
    match_count;
$$;


--
-- Name: match_records_vector(uuid, double precision, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.match_records_vector(query_record_id uuid, match_threshold double precision, match_count integer) RETURNS TABLE(id uuid, title text, description text, similarity double precision, category_name text)
    LANGUAGE plpgsql
    SET search_path TO 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
  q_embedding vector(1536);
  q_site_id uuid;
BEGIN
  -- Get the embedding and site_id of the target record
  SELECT embedding, site_id INTO q_embedding, q_site_id
  FROM records
  WHERE records.id = query_record_id;

  IF q_embedding IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.title,
    r.description,
    1 - (r.embedding <=> q_embedding) AS similarity,
    c.name as category_name
  FROM records r
  LEFT JOIN record_categories c ON r.category_id = c.id
  WHERE r.embedding IS NOT NULL
    AND r.site_id = q_site_id
    AND r.id != query_record_id
    AND 1 - (r.embedding <=> q_embedding) > match_threshold
  ORDER BY r.embedding <=> q_embedding
  LIMIT match_count;
END;
$$;


--
-- Name: member_license_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.member_license_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  PERFORM public.reconcile_site_member_license(CASE WHEN TG_OP = 'DELETE' THEN OLD.site_id ELSE NEW.site_id END);
  RETURN NULL;
END;
$$;


--
-- Name: migrate_team_members_to_site_members(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.migrate_team_members_to_site_members() RETURNS void
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  -- For each site with team members in settings
  INSERT INTO public.site_members (site_id, user_id, role, email, name, position, added_by, status)
  SELECT 
    s.id AS site_id,
    (SELECT id FROM auth.users WHERE email = tm.email LIMIT 1) AS user_id,
    CASE 
      WHEN tm.role = 'admin' THEN 'admin'
      WHEN tm.role = 'delete' THEN 'marketing'
      WHEN tm.role = 'create' THEN 'marketing'
      WHEN tm.role = 'view' THEN 'collaborator'
      ELSE 'collaborator' 
    END AS role,
    tm.email,
    tm.name,
    tm.position,
    s.user_id AS added_by,
    CASE
      WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = tm.email) THEN 'active'
      ELSE 'pending'
    END AS status
  FROM public.sites s
  CROSS JOIN LATERAL jsonb_to_recordset(
    COALESCE(
      (SELECT team_members FROM public.settings WHERE site_id = s.id),
      '[]'::jsonb
    )
  ) AS tm(email text, role text, name text, position text)
  WHERE tm.email IS NOT NULL AND tm.email != ''
  -- Don't duplicate entries
  ON CONFLICT (site_id, email) DO NOTHING;
  
  -- Set the creator of each site as the owner in site_members if not already
  INSERT INTO public.site_members (site_id, user_id, role, email, name, position, status)
  SELECT 
    s.id AS site_id,
    s.user_id AS user_id,
    'owner' AS role,
    u.email,
    p.name,
    '' AS position,
    'active' AS status
  FROM public.sites s
  JOIN auth.users u ON s.user_id = u.id
  LEFT JOIN public.profiles p ON s.user_id = p.id
  WHERE NOT EXISTS (
    SELECT 1 FROM public.site_members 
    WHERE site_id = s.id AND user_id = s.user_id
  );
END;
$$;


--
-- Name: migration_execution_handoff_matches(public.requirement_migration_lifecycle); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.migration_execution_handoff_matches(p_row public.requirement_migration_lifecycle) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT p_row.state = 'transferred' AND (
    EXISTS (
      SELECT 1 FROM public.requirement_migration_execution_handoffs h
      JOIN public.requirements r ON r.id = h.requirement_id AND r.site_id = h.site_id
      WHERE h.requirement_id = p_row.requirement_id AND h.file = p_row.file
        AND h.transferred_version = p_row.version
        AND h.prior_lifecycle->'version' = to_jsonb(p_row.version - 1)
        AND h.created_at = p_row.updated_at
        AND h.prior_lifecycle->>'state' IN ('platform_review', 'correction_required')
        AND h.prior_lifecycle - ARRAY['state','version','updated_at']
          = to_jsonb(p_row) - ARRAY['state','version','updated_at']
    ) OR EXISTS (
      SELECT 1 FROM public.requirement_migration_retirements h
      JOIN public.requirements r ON r.id = h.requirement_id AND r.site_id = h.site_id
      WHERE h.requirement_id = p_row.requirement_id AND h.file = p_row.file
        AND h.transferred_version = p_row.version
        AND h.prior_lifecycle->'version' = to_jsonb(p_row.version - 1)
        AND h.created_at = p_row.updated_at
        AND h.prior_lifecycle->>'state' IN ('platform_review', 'correction_required')
        AND h.prior_lifecycle - ARRAY['state','version','updated_at']
          = to_jsonb(p_row) - ARRAY['state','version','updated_at']
    )
  );
$$;


--
-- Name: mutate_sale_order_item_units(uuid, uuid[], text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mutate_sale_order_item_units(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid DEFAULT NULL::uuid, p_status text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4185985($1,$2,$3,$4,$5); END$_$;


--
-- Name: normalize_billing_plan_names(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.normalize_billing_plan_names() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  NEW.plan := CASE NEW.plan WHEN 'starter' THEN 'engine'
    WHEN 'startup' THEN 'foundry' ELSE NEW.plan END;
  RETURN NEW;
END;
$$;


--
-- Name: observe_email_sync_channel_health(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.observe_email_sync_channel_health() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_email jsonb := NEW.channels->'email';
  v_attempt text := v_email->>'last_sync_attempt';
  v_outcome text;
  v_error text;
  v_class text;
  v_source_id uuid;
BEGIN
  IF session_user NOT IN ('postgres', 'service_role')
     AND current_setting('role', true) IS DISTINCT FROM 'service_role'
  THEN RETURN NEW; END IF;
  IF NEW.site_id IS NULL OR v_email->>'enabled' IS DISTINCT FROM 'true'
     OR coalesce(v_email->>'status' IN ('active', 'synced'), false) = false
     OR v_attempt IS NULL OR v_attempt = '' THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' THEN
    IF v_attempt IS NOT DISTINCT FROM OLD.channels->'email'->>'last_sync_attempt'
    THEN RETURN NEW; END IF;
  END IF;

  IF v_email->>'sync_status' = 'error' THEN
    v_outcome := 'failure';
    v_error := lower(left(coalesce(v_email->>'last_sync_error', ''), 300));
    v_class := CASE
      WHEN v_error ~ '(unauthoriz|forbidden|authentication|credential|invalid api key|expired token|imap auth|(^|[^0-9])(401|403)([^0-9]|$))' THEN 'auth'
      WHEN v_error ~ '(rate.limit|timeout|timed out|econnreset|econnrefused|etimedout|service unavailable|(^|[^0-9])(429|5[0-9][0-9])([^0-9]|$))' THEN 'provider'
      ELSE 'unknown'
    END;
  ELSIF v_email->>'sync_status' = 'active'
        AND nullif(v_email->>'last_sync_error', '') IS NULL THEN
    v_outcome := 'success';
  ELSE RETURN NEW; END IF;

  v_source_id := extensions.uuid_generate_v5(
    '8fb3f7a7-d174-4643-9ad7-cc0d73dba845'::uuid,
    NEW.site_id::text || ':email:sync:' || v_attempt
  );
  PERFORM public.record_channel_health_event(NEW.site_id, 'email', 'inbound',
    v_source_id, v_outcome, v_class);
  RETURN NEW;
END;
$_$;

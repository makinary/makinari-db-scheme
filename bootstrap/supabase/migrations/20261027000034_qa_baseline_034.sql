SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: get_record_diagram_context(uuid, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_record_diagram_context(p_record_id uuid, p_node_limit integer DEFAULT 100, p_content_limit integer DEFAULT 4000, p_edge_limit integer DEFAULT 200) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  WITH target_record AS (
    SELECT r.id, r.title, r.category_id
    FROM public.records r
    WHERE r.id = p_record_id
  ),
  bounded_nodes AS (
    SELECT n.*
    FROM public.record_diagram_nodes n
    WHERE n.record_id = p_record_id
    ORDER BY n.id
    LIMIT GREATEST(1, LEAST(COALESCE(p_node_limit, 100), 100))
  ),
  bounded_edges AS (
    SELECT e.*
    FROM public.record_diagram_edges e
    WHERE e.record_id = p_record_id
      AND e.source_node_id IN (SELECT id FROM bounded_nodes)
      AND e.target_node_id IN (SELECT id FROM bounded_nodes)
    ORDER BY e.id
    LIMIT GREATEST(0, LEAST(COALESCE(p_edge_limit, 200), 200))
  )
  SELECT jsonb_build_object(
    'schema', 'record-diagram.v1',
    'record', jsonb_build_object(
      'id', r.id,
      'title', r.title,
      'category', c.name
    ),
    'nodes', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', n.id,
        'kind', n.kind,
        'title', n.title,
        'content', left(
          n.content,
          GREATEST(100, LEAST(COALESCE(p_content_limit, 4000), 4000))
        ),
        'metadata', n.metadata
      ) ORDER BY n.id)
      FROM bounded_nodes n
    ), '[]'::jsonb),
    'edges', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', e.id,
        'source', e.source_node_id,
        'target', e.target_node_id,
        'type', e.relation_type,
        'label', e.label,
        'metadata', e.metadata
      ) ORDER BY e.id)
      FROM bounded_edges e
    ), '[]'::jsonb)
  )
  FROM target_record r
  LEFT JOIN public.record_categories c ON c.id = r.category_id
  ;
$$;


--
-- Name: get_record_diagram_neighborhood(uuid[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_record_diagram_neighborhood(p_node_ids uuid[], p_neighbor_limit integer DEFAULT 100) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  WITH requested AS (
    SELECT unnest(p_node_ids[1:50]) AS id
  ),
  neighborhood_edges AS (
    SELECT e.*
    FROM public.record_diagram_edges e
    WHERE e.source_node_id IN (SELECT id FROM requested)
       OR e.target_node_id IN (SELECT id FROM requested)
    ORDER BY e.id
    LIMIT GREATEST(1, LEAST(COALESCE(p_neighbor_limit, 100) * 2, 200))
  ),
  neighborhood_node_ids AS (
    SELECT id FROM requested
    UNION
    SELECT source_node_id FROM neighborhood_edges
    UNION
    SELECT target_node_id FROM neighborhood_edges
  ),
  neighborhood_nodes AS (
    SELECT n.*
    FROM public.record_diagram_nodes n
    WHERE n.id IN (SELECT id FROM neighborhood_node_ids)
    ORDER BY n.id
    LIMIT GREATEST(1, LEAST(COALESCE(p_neighbor_limit, 100), 100))
  )
  SELECT jsonb_build_object(
    'schema', 'record-diagram-neighborhood.v1',
    'nodes', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', n.id,
        'recordId', n.record_id,
        'kind', n.kind,
        'title', n.title,
        'content', n.content,
        'metadata', n.metadata,
        'matched', n.id IN (SELECT id FROM requested)
      ) ORDER BY n.id)
      FROM neighborhood_nodes n
    ), '[]'::jsonb),
    'edges', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', e.id,
        'recordId', e.record_id,
        'source', e.source_node_id,
        'target', e.target_node_id,
        'type', e.relation_type,
        'label', e.label,
        'metadata', e.metadata
      ) ORDER BY e.id)
      FROM neighborhood_edges e
      WHERE e.source_node_id IN (SELECT id FROM neighborhood_nodes)
        AND e.target_node_id IN (SELECT id FROM neighborhood_nodes)
    ), '[]'::jsonb)
  );
$$;


--
-- Name: get_records_similarity_edges(uuid, double precision, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_records_similarity_edges(p_site_id uuid, match_threshold double precision, match_per_record integer) RETURNS TABLE(source_id uuid, target_id uuid, similarity double precision)
    LANGUAGE plpgsql
    SET search_path TO 'public', 'extensions', 'pg_temp'
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    r1.id as source_id,
    r2.id as target_id,
    1 - (r1.embedding <=> r2.embedding) as similarity
  FROM records r1
  CROSS JOIN LATERAL (
    SELECT id, embedding
    FROM records
    WHERE site_id = p_site_id
      AND embedding IS NOT NULL
      AND id > r1.id -- To avoid A->B and B->A, only get pairs once
      AND 1 - (r1.embedding <=> embedding) > match_threshold
    ORDER BY r1.embedding <=> embedding
    LIMIT match_per_record
  ) r2
  WHERE r1.site_id = p_site_id
    AND r1.embedding IS NOT NULL;
END;
$$;


--
-- Name: get_robot_instance_deletion_scope(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_robot_instance_deletion_scope(p_instance_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4272421($1); END$_$;


--
-- Name: get_secure_token(uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_secure_token(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16719($1,$2,$3,$4); END$_$;


--
-- Name: get_site_licensed_resources(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_site_licensed_resources(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE s public.settings%ROWTYPE; b public.billing%ROWTYPE;
  plan_name text; social_limit integer; agent_limit integer; addons integer;
  social_used integer := 0; agent_used integer := 0; entry jsonb; item jsonb;
  active boolean; keep boolean; category text; all_items jsonb := '[]';
  social_result jsonb := '[]'; agent_result jsonb := '[]'; result_channels jsonb;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.sites WHERE id=p_site_id AND archived_at IS NULL) THEN RETURN NULL; END IF;
  SELECT * INTO s FROM public.settings WHERE site_id=p_site_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT * INTO b FROM public.billing WHERE site_id=p_site_id;
  IF NOT FOUND OR b.status IS DISTINCT FROM 'active' THEN RETURN NULL; END IF;
  plan_name := public.effective_site_plan(p_site_id);
  social_limit := CASE plan_name WHEN 'engine' THEN 3 WHEN 'foundry' THEN 6 WHEN 'enterprise' THEN 10 ELSE 1 END;
  agent_limit := CASE plan_name WHEN 'engine' THEN 1 WHEN 'foundry' THEN 3 WHEN 'enterprise' THEN 10 ELSE 0 END;
  addons := CASE WHEN b.stripe_subscription_id IS NULL OR (
    b.paid_subscription_invoice_id IS NOT NULL AND b.paid_subscription_period_start <= clock_timestamp()
    AND b.paid_subscription_period_end > clock_timestamp()
    AND lower(coalesce(b.subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired'))
    THEN greatest(coalesce(b.addons_count,0),0) ELSE 0 END;
  FOREACH category IN ARRAY ARRAY['social','agent'] LOOP
    FOR item IN SELECT value FROM jsonb_array_elements(CASE WHEN category='social'
      THEN coalesce(nullif(s.social_media,'null'::jsonb),'[]')
      ELSE coalesce(nullif(s.channels->'connections','null'::jsonb),'[]') END) LOOP
      IF category='agent' AND coalesce(item->'_license'->'manually_disabled'='true'::jsonb,false) THEN
        item := item || '{"status":"disabled","enabled":false,"license_suspended":false}'::jsonb;
      END IF;
      active := CASE WHEN category='social' THEN item->'isActive' IN ('true'::jsonb,'1'::jsonb)
        OR coalesce((item->'_license'->>'suspended')::boolean,false)
        ELSE NOT coalesce(item->'_license'->'manually_disabled'='true'::jsonb,false)
          AND item->'enabled' IS DISTINCT FROM 'false'::jsonb AND (
            item->>'status'='connected' OR (item->>'type'='voice' AND item->>'status' IN ('active','synced'))
            OR coalesce((item->'_license'->>'suspended')::boolean,false)) END;
      all_items := all_items || jsonb_build_array(jsonb_build_object('category',category,'item',item,'active',coalesce(active,false)));
    END LOOP;
  END LOOP;
  FOR entry IN SELECT value FROM jsonb_array_elements(all_items)
    ORDER BY (value->'item'->'_license'->>'order')::bigint NULLS LAST LOOP
    item := entry->'item'; category := entry->>'category'; active := (entry->>'active')::boolean; keep := false;
    IF active THEN
      IF category='social' AND social_used < social_limit THEN social_used := social_used + 1; keep := true;
      ELSIF category='agent' AND agent_used < agent_limit THEN agent_used := agent_used + 1; keep := true;
      ELSIF addons > 0 THEN addons := addons - 1; keep := true; END IF;
    END IF;
    IF active THEN
      item := item || CASE WHEN category='social' THEN jsonb_build_object('isActive',keep)
        ELSE jsonb_build_object('status',CASE WHEN NOT keep THEN 'license_suspended'
      WHEN item->>'type'='voice' AND item->>'status' IN ('active','synced') THEN item->>'status'
      WHEN item->>'type'='voice' AND item->'_license'->>'previousStatus' IN ('active','synced')
        THEN item->'_license'->>'previousStatus'
      ELSE 'connected' END) END;
    END IF;
    item := item || jsonb_build_object('license_suspended',active AND NOT keep);
    IF category='social' THEN social_result := social_result || jsonb_build_array(item);
    ELSE agent_result := agent_result || jsonb_build_array(item); END IF;
  END LOOP;
  result_channels := CASE WHEN jsonb_typeof(s.channels)='object' THEN s.channels ELSE '{}'::jsonb END;
  RETURN jsonb_build_object('social_media',social_result,'channels',
    jsonb_set(result_channels,'{connections}',agent_result),'effective_plan',plan_name);
END;
$$;


--
-- Name: get_site_member_license(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_site_member_license(p_site_id uuid, p_member_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  owner_id uuid; plan_name text; seat_limit integer; used integer; demand integer;
BEGIN
  SELECT user_id INTO owner_id FROM public.sites WHERE id = p_site_id AND archived_at IS NULL;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF p_member_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.site_members WHERE id = p_member_id AND site_id = p_site_id
  ) THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'Member does not belong to site'; END IF;
  plan_name := public.effective_site_plan(p_site_id);
  plan_name := CASE WHEN plan_name IN ('engine','foundry','enterprise') THEN plan_name ELSE 'commission' END;
  seat_limit := CASE plan_name WHEN 'engine' THEN 5 WHEN 'foundry' THEN 10 WHEN 'enterprise' THEN NULL ELSE 1 END;
  SELECT 1 + count(*) FILTER (WHERE public.site_member_has_effective_license(id) AND id IS DISTINCT FROM p_member_id),
    1 + count(*) INTO used, demand
  FROM public.site_members WHERE site_id = p_site_id AND user_id IS DISTINCT FROM owner_id
    AND status IN ('active','pending') AND NOT manually_disabled;
  RETURN jsonb_build_object('plan',plan_name,'current',used,'total',demand,'limit',seat_limit,
    'requiredPlan',CASE WHEN used + 1 <= 1 THEN 'commission' WHEN used + 1 <= 5 THEN 'engine'
      WHEN used + 1 <= 10 THEN 'foundry' ELSE 'enterprise' END,'siteId',p_site_id);
END;
$$;


--
-- Name: get_site_startup_trial(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_site_startup_trial(p_site_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE b public.billing%ROWTYPE; t public.site_startup_trials%ROWTYPE;
  owner_id uuid; v_now timestamptz := clock_timestamp(); v_state text;
BEGIN
  IF EXISTS (SELECT 1 FROM public.billing WHERE site_id=p_site_id
    AND trial_ends_at <= v_now AND trial_converted_at IS NULL) THEN
    PERFORM public.renew_site_plan_credits(p_site_id);
    PERFORM public.reconcile_site_member_license(p_site_id);
    UPDATE public.settings SET social_media=social_media,channels=channels WHERE site_id=p_site_id;
  END IF;
  v_now := clock_timestamp();
  SELECT user_id INTO owner_id FROM public.sites WHERE id = p_site_id AND archived_at IS NULL;
  IF NOT FOUND THEN v_state := 'unavailable';
  ELSE
    SELECT * INTO b FROM public.billing WHERE site_id = p_site_id;
    SELECT * INTO t FROM public.site_startup_trials WHERE site_id = p_site_id;
    IF t.site_id IS NOT NULL THEN
      v_state := CASE WHEN t.converted_at IS NOT NULL THEN 'converted'
        WHEN v_now >= t.ends_at THEN 'expired' WHEN v_now >= t.started_at THEN 'active' ELSE 'unavailable' END;
    ELSIF b.id IS NULL OR owner_id IS NULL OR b.status IS DISTINCT FROM 'active'
      OR coalesce(b.plan,'commission') NOT IN ('commission','free','toolbox')
      OR coalesce(b.addons_count,0) <> 0
      OR (b.stripe_subscription_id IS NOT NULL AND lower(coalesce(b.subscription_status,''))
        NOT IN ('canceled','cancelled','incomplete_expired'))
      OR b.paid_subscription_period_end > v_now
      OR EXISTS (SELECT 1 FROM public.site_startup_trials WHERE primary_owner_id = owner_id)
      OR public.site_owner_has_platform_payment(p_site_id)
    THEN v_state := 'unavailable'; ELSE v_state := 'eligible'; END IF;
  END IF;
  RETURN jsonb_build_object('success',true,'state',v_state,'started_at',t.started_at,'ends_at',t.ends_at,
    'credits_remaining',CASE WHEN v_state = 'active' THEN coalesce(b.trial_credits_available,0) ELSE 0 END,
    'server_now',v_now,'effective_plan',public.effective_site_plan(p_site_id),'offer_eligible',v_state='eligible');
END;
$$;


--
-- Name: get_system_status_daily(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_system_status_daily(p_since timestamp with time zone, p_until timestamp with time zone) RETURNS TABLE(system_key text, day date, check_count bigint, observed_check_count bigint, up_check_count bigint, degraded_check_count bigint, down_check_count bigint, skipped_check_count bigint)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  WITH observations AS MATERIALIZED (
    SELECT s.system_key, (s.created_at AT TIME ZONE 'UTC')::date AS day,
      public.status_observed_state(s.status, s.health_payload -> 'checks') AS state
    FROM public.system_status AS s
    WHERE s.created_at >= GREATEST(p_since, p_until - INTERVAL '2160 hours') AND s.created_at <= p_until
  )
  SELECT o.system_key, o.day, COUNT(*), COUNT(*) FILTER (WHERE o.state <> 'skipped'),
    COUNT(*) FILTER (WHERE o.state = 'up'), COUNT(*) FILTER (WHERE o.state = 'degraded'),
    COUNT(*) FILTER (WHERE o.state = 'down'), COUNT(*) FILTER (WHERE o.state = 'skipped')
  FROM observations AS o
  GROUP BY o.day, o.system_key
  ORDER BY o.day, o.system_key;
$$;


--
-- Name: get_system_status_observed_sla(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_system_status_observed_sla(p_since timestamp with time zone, p_until timestamp with time zone) RETURNS TABLE(system_key text, total_24h bigint, up_24h bigint, total_7d bigint, up_7d bigint, total_30d bigint, up_30d bigint)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  WITH observations AS MATERIALIZED (
    SELECT s.system_key, s.created_at,
      public.status_observed_state(s.status, s.health_payload -> 'checks') AS state
    FROM public.system_status AS s
    WHERE s.created_at >= GREATEST(p_since, p_until - INTERVAL '720 hours') AND s.created_at <= p_until
  )
  SELECT o.system_key,
    COUNT(*) FILTER (WHERE o.created_at >= p_until - INTERVAL '24 hours' AND o.state <> 'skipped'),
    COUNT(*) FILTER (WHERE o.created_at >= p_until - INTERVAL '24 hours' AND o.state = 'up'),
    COUNT(*) FILTER (WHERE o.created_at >= p_until - INTERVAL '168 hours' AND o.state <> 'skipped'),
    COUNT(*) FILTER (WHERE o.created_at >= p_until - INTERVAL '168 hours' AND o.state = 'up'),
    COUNT(*) FILTER (WHERE o.state <> 'skipped'), COUNT(*) FILTER (WHERE o.state = 'up')
  FROM observations AS o
  GROUP BY o.system_key
  ORDER BY o.system_key;
$$;


--
-- Name: get_system_status_sla(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_system_status_sla(p_since timestamp with time zone) RETURNS TABLE(system_key text, total_24h bigint, up_24h bigint, total_7d bigint, up_7d bigint, total_30d bigint, up_30d bigint)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  SELECT
    status_rows.system_key::text,
    COUNT(*) FILTER (
      WHERE status_rows.created_at >= NOW() - INTERVAL '24 hours'
        AND status_rows.status IN ('up', 'down', 'degraded')
    ) AS total_24h,
    COUNT(*) FILTER (
      WHERE status_rows.created_at >= NOW() - INTERVAL '24 hours'
        AND status_rows.status = 'up'
    ) AS up_24h,
    COUNT(*) FILTER (
      WHERE status_rows.created_at >= NOW() - INTERVAL '7 days'
        AND status_rows.status IN ('up', 'down', 'degraded')
    ) AS total_7d,
    COUNT(*) FILTER (
      WHERE status_rows.created_at >= NOW() - INTERVAL '7 days'
        AND status_rows.status = 'up'
    ) AS up_7d,
    COUNT(*) FILTER (
      WHERE status_rows.status IN ('up', 'down', 'degraded')
    ) AS total_30d,
    COUNT(*) FILTER (
      WHERE status_rows.status = 'up'
    ) AS up_30d
  FROM public.system_status AS status_rows
  WHERE status_rows.created_at >= GREATEST(
    COALESCE(p_since, NOW() - INTERVAL '30 days'),
    NOW() - INTERVAL '30 days'
  )
  GROUP BY status_rows.system_key;
$$;


--
-- Name: get_user_by_phone(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_by_phone(phone_variants text[]) RETURNS TABLE(id uuid, phone text, raw_user_meta_data jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_2912363($1); END$_$;


--
-- Name: get_user_profile_complete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_profile_complete(user_id_param uuid) RETURNS TABLE(id uuid, email text, name text, avatar_url text, bio text, role text, language text, timezone text, notifications jsonb, settings jsonb, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN QUERY SELECT * FROM location_acl_private.original_16720($1); END$_$;


--
-- Name: grant_new_visitor_identity(uuid, uuid, uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.grant_new_visitor_identity(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_trusted_token_hash text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_canonical_lead uuid;
  v_now timestamptz := clock_timestamp();
begin
  perform public.assert_visitor_identity_service_role();
  perform pg_advisory_xact_lock(hashtextextended(p_site_id::text || ':' || lower(trim(p_normalized_email)), 0));
  perform 1 from public.visitor_sessions
  where id = p_session_id and site_id = p_site_id and visitor_id = p_visitor_id for update;
  if not found then return jsonb_build_object('status', 'invalid_session'); end if;

  select id into v_canonical_lead from public.leads
  where site_id = p_site_id and lower(trim(email)) = lower(trim(p_normalized_email))
  order by created_at asc nulls last, id asc limit 1 for update;
  if v_canonical_lead is null then return jsonb_build_object('status', 'lead_not_found'); end if;
  if v_canonical_lead <> p_lead_id then
    return jsonb_build_object('status', 'existing', 'lead_id', v_canonical_lead);
  end if;

  insert into public.visitor_session_identity_grants (
    site_id, session_id, visitor_id, lead_id, trusted_token_hash, granted_at, revoked_at, updated_at
  ) values (p_site_id, p_session_id, p_visitor_id, p_lead_id, p_trusted_token_hash, v_now, null, v_now)
  on conflict (session_id) do update set
    site_id = excluded.site_id, visitor_id = excluded.visitor_id, lead_id = excluded.lead_id,
    trusted_token_hash = excluded.trusted_token_hash, granted_at = excluded.granted_at,
    expires_at = null, revoked_at = null, updated_at = excluded.updated_at;
  update public.visitor_sessions
  set lead_id = p_lead_id, identified_at = (extract(epoch from v_now) * 1000)::bigint, updated_at = v_now
  where id = p_session_id;
  update public.visitors set lead_id = p_lead_id, is_identified = true where id = p_visitor_id;
  return jsonb_build_object('status', 'granted', 'lead_id', p_lead_id);
end;
$$;

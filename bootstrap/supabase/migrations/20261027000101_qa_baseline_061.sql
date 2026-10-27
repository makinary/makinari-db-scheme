SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: save_marketplace_integration(jsonb, uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_marketplace_integration(p_config jsonb, p_secret_id uuid, p_encrypted_credentials text, p_actor_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE integration public.marketplace_integrations; existing public.marketplace_integrations;
  integration_id uuid := (p_config->>'id')::uuid; site uuid := (p_config->>'site_id')::uuid;
  location uuid := (p_config->>'origin_location_id')::uuid;
  mode text := coalesce(p_config->>'credential_mode','custom');
  connection_id uuid := (p_config->>'merchant_connection_id')::uuid; target_enabled boolean;
BEGIN
  PERFORM public.marketplace_assert_actor(site,p_actor_user_id,true);
  IF integration_id IS NULL OR mode NOT IN ('custom','platform') OR NOT EXISTS (
    SELECT 1 FROM public.locations WHERE id=location AND site_id=site AND is_active
  ) THEN RAISE EXCEPTION 'Invalid marketplace configuration'; END IF;
  SELECT * INTO existing FROM public.marketplace_integrations WHERE id=integration_id FOR UPDATE;
  IF FOUND AND (existing.site_id IS DISTINCT FROM site OR existing.secret_id IS DISTINCT FROM p_secret_id
    OR existing.provider IS DISTINCT FROM p_config->>'provider'
    OR existing.environment IS DISTINCT FROM p_config->>'environment'
    OR existing.external_store_id IS DISTINCT FROM p_config->>'external_store_id'
    OR existing.credential_mode IS DISTINCT FROM mode OR existing.merchant_connection_id IS DISTINCT FROM connection_id) THEN
    RAISE EXCEPTION 'Marketplace integration identity is immutable';
  END IF;
  IF mode='platform' THEN
    IF p_secret_id IS NOT NULL OR p_encrypted_credentials IS NOT NULL OR connection_id IS NULL THEN
      RAISE EXCEPTION 'Platform credentials must not be copied into site secrets';
    END IF;
  ELSE
    IF connection_id IS NOT NULL AND p_secret_id IS NULL THEN
      IF p_encrypted_credentials IS NOT NULL THEN RAISE EXCEPTION 'Merchant credentials are stored in the consent connection'; END IF;
    ELSIF p_secret_id IS NULL OR (existing.id IS NULL AND p_encrypted_credentials IS NULL) THEN
      RAISE EXCEPTION 'Encrypted marketplace credentials required';
    END IF;
    IF p_encrypted_credentials IS NOT NULL THEN
      IF length(p_encrypted_credentials) NOT BETWEEN 16 AND 32768 THEN RAISE EXCEPTION 'Invalid encrypted marketplace credentials'; END IF;
      IF EXISTS (SELECT 1 FROM public.site_secrets WHERE id=p_secret_id AND (
        site_id IS DISTINCT FROM site OR use_case IS DISTINCT FROM 'marketplace:'||integration_id::text
        OR provider IS DISTINCT FROM p_config->>'provider' OR instance_id IS NOT NULL
      )) THEN RAISE EXCEPTION 'Reserved secret identity mismatch'; END IF;
      INSERT INTO public.site_secrets(id,site_id,instance_id,name,provider,use_case,encrypted_value)
      VALUES(p_secret_id,site,NULL,'Marketplace credentials',p_config->>'provider',
        'marketplace:'||integration_id::text,p_encrypted_credentials)
      ON CONFLICT(id) DO UPDATE SET encrypted_value=excluded.encrypted_value,updated_at=now();
    END IF;
  END IF;
  -- Caller configuration cannot spoof provider confirmation or enable a store
  -- before provisioning. Legacy manually configured custom integrations remain compatible.
  target_enabled := coalesce((p_config->>'enabled')::boolean,false);
  IF connection_id IS NOT NULL THEN
    IF existing.id IS NULL THEN target_enabled := false;
    ELSIF target_enabled AND existing.provisioning_status<>'active' THEN target_enabled := existing.enabled;
    END IF;
  END IF;
  INSERT INTO public.marketplace_integrations(id,site_id,provider,environment,country,external_store_id,
    origin_location_id,secret_id,enabled,manual_ready,created_by_user_id,credential_mode,merchant_connection_id,provisioning_status)
  VALUES(integration_id,site,p_config->>'provider',p_config->>'environment',p_config->>'country',
    p_config->>'external_store_id',location,p_secret_id,target_enabled,
    coalesce((p_config->>'manual_ready')::boolean,false),p_actor_user_id,mode,connection_id,
    CASE WHEN existing.id IS NOT NULL THEN existing.provisioning_status
      WHEN connection_id IS NULL THEN 'active' ELSE 'not_ready' END)
  ON CONFLICT(id) DO UPDATE SET country=excluded.country,origin_location_id=excluded.origin_location_id,
    enabled=excluded.enabled,manual_ready=excluded.manual_ready,updated_at=now()
  RETURNING * INTO integration;
  RETURN to_jsonb(integration);
END;
$$;


--
-- Name: save_record_aggregate_embedding(uuid, bigint, text, public.vector); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_summary text, p_embedding public.vector) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.records r
  SET summary = p_summary, embedding = p_embedding, updated_at = now()
  WHERE r.id = p_record_id
    AND (
      EXISTS (
        SELECT 1
        FROM public.record_diagrams d
        WHERE d.record_id = p_record_id
          AND d.revision = p_diagram_revision
      )
      OR (
        p_diagram_revision = 0
        AND NOT EXISTS (
          SELECT 1 FROM public.record_diagrams d WHERE d.record_id = p_record_id
        )
      )
    );

  RETURN FOUND;
END;
$$;


--
-- Name: save_record_aggregate_embedding(uuid, bigint, bigint, text, public.vector); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_summary text, p_embedding public.vector) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.records r
  SET summary = p_summary, embedding = p_embedding, updated_at = now()
  WHERE r.id = p_record_id
    AND r.record_embedding_revision = p_record_revision
    AND (
      EXISTS (
        SELECT 1
        FROM public.record_diagrams d
        WHERE d.record_id = p_record_id
          AND d.revision = p_diagram_revision
      )
      OR (
        p_diagram_revision = 0
        AND NOT EXISTS (
          SELECT 1 FROM public.record_diagrams d WHERE d.record_id = p_record_id
        )
      )
    );

  RETURN FOUND;
END;
$$;


--
-- Name: save_record_diagram(uuid, bigint, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_record_diagram(p_record_id uuid, p_expected_revision bigint, p_viewport jsonb, p_nodes jsonb, p_edges jsonb) RETURNS TABLE(revision bigint, changed_node_ids uuid[])
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_site_id uuid;
  v_record_revision bigint;
  v_current_revision bigint;
  v_next_revision bigint;
  v_changed_node_ids uuid[] := '{}'::uuid[];
  v_old_edge_signature text;
  v_new_edge_signature text;
  v_old_node_ids uuid[];
  v_new_node_ids uuid[];
  v_semantic_changed boolean := false;
BEGIN
  IF jsonb_typeof(COALESCE(p_nodes, '[]'::jsonb)) <> 'array'
    OR jsonb_array_length(COALESCE(p_nodes, '[]'::jsonb)) > 200
    OR jsonb_typeof(COALESCE(p_edges, '[]'::jsonb)) <> 'array'
    OR jsonb_array_length(COALESCE(p_edges, '[]'::jsonb)) > 500
    OR jsonb_typeof(COALESCE(p_viewport, '{}'::jsonb)) <> 'object'
  THEN
    RAISE EXCEPTION 'Diagram payload exceeds its allowed shape or size';
  END IF;

  SELECT r.site_id, r.record_embedding_revision
  INTO v_site_id, v_record_revision
  FROM public.records r
  WHERE r.id = p_record_id;

  IF v_site_id IS NULL THEN
    RAISE EXCEPTION 'Record not found';
  END IF;

  INSERT INTO public.record_diagrams(record_id, site_id)
  VALUES (p_record_id, v_site_id)
  ON CONFLICT (record_id) DO NOTHING;

  SELECT d.revision
  INTO v_current_revision
  FROM public.record_diagrams d
  WHERE d.record_id = p_record_id
  FOR UPDATE;

  IF v_current_revision <> p_expected_revision THEN
    RAISE EXCEPTION 'Diagram revision conflict: expected %, current %',
      p_expected_revision, v_current_revision
      USING ERRCODE = '40001';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(COALESCE(p_nodes, '[]'::jsonb)) AS input(id uuid)
    JOIN public.record_diagram_nodes existing ON existing.id = input.id
    WHERE existing.record_id <> p_record_id
  ) OR EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(COALESCE(p_edges, '[]'::jsonb)) AS input(id uuid)
    JOIN public.record_diagram_edges existing ON existing.id = input.id
    WHERE existing.record_id <> p_record_id
  ) THEN
    RAISE EXCEPTION 'Diagram IDs must be scoped to their original record';
  END IF;

  SELECT COALESCE(array_agg(n.id ORDER BY n.id), '{}'::uuid[])
  INTO v_old_node_ids
  FROM public.record_diagram_nodes n
  WHERE n.record_id = p_record_id;

  SELECT COALESCE(array_agg(input.id ORDER BY input.id), '{}'::uuid[])
  INTO v_new_node_ids
  FROM jsonb_to_recordset(COALESCE(p_nodes, '[]'::jsonb)) AS input(id uuid);

  SELECT COALESCE(array_agg(input.id ORDER BY input.id), '{}'::uuid[])
  INTO v_changed_node_ids
  FROM jsonb_to_recordset(COALESCE(p_nodes, '[]'::jsonb)) AS input(
    id uuid,
    embedding_source_hash text
  )
  LEFT JOIN public.record_diagram_nodes existing
    ON existing.record_id = p_record_id AND existing.id = input.id
  WHERE existing.id IS NULL
    OR existing.embedding_source_hash IS DISTINCT FROM input.embedding_source_hash;

  SELECT md5(COALESCE(jsonb_agg(jsonb_build_object(
    'id', e.id,
    'source', e.source_node_id,
    'target', e.target_node_id,
    'type', e.relation_type,
    'label', e.label,
    'metadata', e.metadata
  ) ORDER BY e.id)::text, '[]'))
  INTO v_old_edge_signature
  FROM public.record_diagram_edges e
  WHERE e.record_id = p_record_id;

  SELECT md5(COALESCE(jsonb_agg(jsonb_build_object(
    'id', input.id,
    'source', input.source_node_id,
    'target', input.target_node_id,
    'type', input.relation_type,
    'label', input.label,
    'metadata', input.metadata
  ) ORDER BY input.id)::text, '[]'))
  INTO v_new_edge_signature
  FROM jsonb_to_recordset(COALESCE(p_edges, '[]'::jsonb)) AS input(
    id uuid,
    source_node_id uuid,
    target_node_id uuid,
    relation_type text,
    label text,
    metadata jsonb
  );

  INSERT INTO public.record_diagram_nodes(
    id, record_id, site_id, kind, title, content, metadata,
    position_x, position_y, embedding_source_hash
  )
  SELECT
    input.id, p_record_id, v_site_id, input.kind, input.title, input.content,
    COALESCE(input.metadata, '{}'::jsonb), input.position_x, input.position_y,
    input.embedding_source_hash
  FROM jsonb_to_recordset(COALESCE(p_nodes, '[]'::jsonb)) AS input(
    id uuid,
    kind text,
    title text,
    content text,
    metadata jsonb,
    position_x double precision,
    position_y double precision,
    embedding_source_hash text
  )
  ON CONFLICT (id) DO UPDATE SET
    kind = EXCLUDED.kind,
    title = EXCLUDED.title,
    content = EXCLUDED.content,
    metadata = EXCLUDED.metadata,
    position_x = EXCLUDED.position_x,
    position_y = EXCLUDED.position_y,
    embedding = CASE
      WHEN record_diagram_nodes.embedding_source_hash = EXCLUDED.embedding_source_hash
        THEN record_diagram_nodes.embedding
      ELSE NULL
    END,
    embedding_model = CASE
      WHEN record_diagram_nodes.embedding_source_hash = EXCLUDED.embedding_source_hash
        THEN record_diagram_nodes.embedding_model
      ELSE NULL
    END,
    embedding_updated_at = CASE
      WHEN record_diagram_nodes.embedding_source_hash = EXCLUDED.embedding_source_hash
        THEN record_diagram_nodes.embedding_updated_at
      ELSE NULL
    END,
    embedding_source_hash = EXCLUDED.embedding_source_hash,
    updated_at = now();

  DELETE FROM public.record_diagram_nodes existing
  WHERE existing.record_id = p_record_id
    AND NOT (existing.id = ANY(v_new_node_ids));

  INSERT INTO public.record_diagram_edges(
    id, record_id, site_id, source_node_id, target_node_id,
    relation_type, label, metadata
  )
  SELECT
    input.id, p_record_id, v_site_id, input.source_node_id,
    input.target_node_id, input.relation_type, input.label,
    COALESCE(input.metadata, '{}'::jsonb)
  FROM jsonb_to_recordset(COALESCE(p_edges, '[]'::jsonb)) AS input(
    id uuid,
    source_node_id uuid,
    target_node_id uuid,
    relation_type text,
    label text,
    metadata jsonb
  )
  ON CONFLICT (id) DO UPDATE SET
    source_node_id = EXCLUDED.source_node_id,
    target_node_id = EXCLUDED.target_node_id,
    relation_type = EXCLUDED.relation_type,
    label = EXCLUDED.label,
    metadata = EXCLUDED.metadata,
    updated_at = now();

  DELETE FROM public.record_diagram_edges existing
  WHERE existing.record_id = p_record_id
    AND NOT EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(COALESCE(p_edges, '[]'::jsonb)) AS input(id uuid)
      WHERE input.id = existing.id
    );

  v_semantic_changed :=
    cardinality(v_changed_node_ids) > 0
    OR v_old_node_ids IS DISTINCT FROM v_new_node_ids
    OR v_old_edge_signature IS DISTINCT FROM v_new_edge_signature;
  v_next_revision := v_current_revision + 1;

  UPDATE public.record_diagrams
  SET
    revision = v_next_revision,
    viewport = COALESCE(p_viewport, viewport),
    updated_at = now()
  WHERE record_id = p_record_id;

  IF v_semantic_changed THEN
    INSERT INTO public.record_embedding_jobs(
      record_id, site_id, diagram_revision, record_revision, node_ids
    )
    VALUES (
      p_record_id, v_site_id, v_next_revision, v_record_revision, v_changed_node_ids
    )
    ON CONFLICT (record_id, diagram_revision, record_revision) DO NOTHING;
  END IF;

  RETURN QUERY SELECT v_next_revision, v_changed_node_ids;
END;
$$;


--
-- Name: save_record_diagram_node_embedding(uuid, uuid, bigint, text, public.vector, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_embedding_source_hash text, p_embedding public.vector, p_embedding_model text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.record_diagram_nodes n
  SET
    embedding = p_embedding,
    embedding_model = p_embedding_model,
    embedding_updated_at = now()
  WHERE n.id = p_node_id
    AND n.record_id = p_record_id
    AND n.embedding_source_hash = p_embedding_source_hash
    AND EXISTS (
      SELECT 1
      FROM public.record_diagrams d
      WHERE d.record_id = p_record_id
        AND d.revision = p_diagram_revision
    );

  RETURN FOUND;
END;
$$;


--
-- Name: save_record_diagram_node_embedding(uuid, uuid, bigint, bigint, text, text, public.vector, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_embedding_source_hash text, p_new_embedding_source_hash text, p_embedding public.vector, p_embedding_model text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.record_diagram_nodes n
  SET
    embedding = p_embedding,
    embedding_source_hash = p_new_embedding_source_hash,
    embedding_model = p_embedding_model,
    embedding_updated_at = now()
  WHERE n.id = p_node_id
    AND n.record_id = p_record_id
    AND n.embedding_source_hash IS NOT DISTINCT FROM p_embedding_source_hash
    AND EXISTS (
      SELECT 1
      FROM public.records r
      WHERE r.id = p_record_id
        AND r.record_embedding_revision = p_record_revision
    )
    AND EXISTS (
      SELECT 1
      FROM public.record_diagrams d
      WHERE d.record_id = p_record_id
        AND d.revision = p_diagram_revision
    );

  RETURN FOUND;
END;
$$;


--
-- Name: set_credit_auto_top_up_settings(uuid, boolean, numeric, numeric, integer, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_credit_auto_top_up_settings(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_actor_id uuid, p_stripe_payment_method_id text DEFAULT NULL::text, p_state text DEFAULT 'ready'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE v_saved jsonb; v_consent jsonb;
BEGIN
  PERFORM public.assert_credit_auto_top_up_service_role();
  IF p_actor_id IS NULL THEN RAISE EXCEPTION 'Verified consent actor required'; END IF;
  v_saved := public.configure_credit_auto_top_up_settings_internal(p_site_id,p_enabled,
    p_minimum_credits,p_target_credits,p_max_monthly_spend_cents,p_stripe_payment_method_id,p_state);
  v_consent := public.record_credit_auto_top_up_consent(p_site_id,p_actor_id);
  RETURN v_saved||jsonb_build_object('consent_id',v_consent->'consent_id',
    'settings_revision',v_consent->'settings_revision');
END;
$$;


--
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: set_dislike(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_dislike(command_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16758($1); RETURN; END$_$;


--
-- Name: set_like(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_like(command_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); PERFORM location_acl_private.original_16759($1); RETURN; END$_$;

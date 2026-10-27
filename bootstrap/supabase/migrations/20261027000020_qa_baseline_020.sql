SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: cancel_harness_model_reservation(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_reason text) RETURNS jsonb
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
  SELECT public.finish_harness_model_reservation($1,$2,NULL,NULL,NULL,$3);
$_$;


--
-- Name: cancel_quiescent_instance_plan(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_quiescent_instance_plan(p_plan_id uuid, p_instance_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4379393($1,$2); END$_$;


--
-- Name: cancel_requirement_plan_steps_for_backlog_items(uuid, text[], text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_requirement_plan_steps_for_backlog_items(p_requirement_id uuid, p_item_ids text[], p_reason text, p_instance_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_item_ids text[];
  v_plan record;
  v_next_steps jsonb;
  v_steps_cancelled integer;
  v_total_steps_cancelled integer := 0;
  v_plans_touched integer := 0;
  v_plans_cancelled integer := 0;
  v_plan_ids uuid[] := ARRAY[]::uuid[];
  v_still_runnable boolean;
  v_now timestamptz := timezone('utc', now());
  v_mutation_at timestamptz;
BEGIN
  IF p_requirement_id IS NULL THEN
    RAISE EXCEPTION 'p_requirement_id is required';
  END IF;
  IF NULLIF(btrim(COALESCE(p_reason, '')), '') IS NULL THEN
    RAISE EXCEPTION 'p_reason is required';
  END IF;

  SELECT array_agg(DISTINCT btrim(item_id))
  INTO v_item_ids
  FROM unnest(COALESCE(p_item_ids, ARRAY[]::text[])) AS item(item_id)
  WHERE NULLIF(btrim(item_id), '') IS NOT NULL;

  IF COALESCE(cardinality(v_item_ids), 0) = 0 THEN
    RETURN jsonb_build_object(
      'plans_touched', 0,
      'plans_cancelled', 0,
      'steps_cancelled', 0,
      'plan_ids', '[]'::jsonb,
      'errors', '[]'::jsonb
    );
  END IF;

  FOR v_plan IN
    SELECT id, status, steps, updated_at, completion_reason, completed_at
    FROM public.instance_plans
    WHERE metadata->>'requirement_id' = p_requirement_id::text
      AND status IN ('pending', 'in_progress', 'active', 'paused')
      AND (p_instance_id IS NULL OR instance_id = p_instance_id)
    ORDER BY id
    FOR UPDATE
  LOOP
    v_mutation_at := GREATEST(
      v_now,
      COALESCE(v_plan.updated_at + interval '1 millisecond', v_now)
    );

    SELECT
      COALESCE(jsonb_agg(
        CASE
          WHEN COALESCE(
            step.value->'metadata'->>'backlog_item_id',
            step.value->>'backlog_item_id'
          ) = ANY(v_item_ids)
            AND step.value->>'status' IN (
              'pending', 'in_progress', 'failed'
            )
          THEN step.value || jsonb_build_object(
            'status', 'cancelled',
            'cancellation_reason', left(p_reason, 240),
            'cancelled_at', v_mutation_at
          )
          ELSE step.value
        END
        ORDER BY step.ordinality
      ), '[]'::jsonb),
      count(*) FILTER (
        WHERE COALESCE(
          step.value->'metadata'->>'backlog_item_id',
          step.value->>'backlog_item_id'
        ) = ANY(v_item_ids)
          AND step.value->>'status' IN (
            'pending', 'in_progress', 'failed'
          )
      )::integer
    INTO v_next_steps, v_steps_cancelled
    FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(v_plan.steps) = 'array'
        THEN v_plan.steps ELSE '[]'::jsonb END
    ) WITH ORDINALITY AS step(value, ordinality);

    IF v_steps_cancelled = 0 THEN
      CONTINUE;
    END IF;

    SELECT EXISTS (
      SELECT 1
      FROM jsonb_array_elements(v_next_steps) AS step(value)
      WHERE step.value->>'status' NOT IN (
        'completed', 'cancelled', 'skipped', 'paused'
      )
        AND (
          step.value->>'status' <> 'failed'
          OR CASE
            WHEN COALESCE(step.value->>'retry_count', '') ~ '^[0-9]{1,9}$'
              THEN (step.value->>'retry_count')::integer
            ELSE 0
          END < 2
        )
      )
    INTO v_still_runnable;

    UPDATE public.instance_plans
    SET
      steps = v_next_steps,
      status = CASE
        WHEN v_still_runnable THEN v_plan.status
        ELSE 'cancelled'
      END,
      completion_reason = CASE
        WHEN v_still_runnable THEN v_plan.completion_reason
        ELSE left(
          'Backlog item cancellation reached terminal state — ' || p_reason,
          500
        )
      END,
      completed_at = CASE
        WHEN v_still_runnable THEN v_plan.completed_at
        ELSE COALESCE(v_plan.completed_at, v_mutation_at)
      END,
      updated_at = v_mutation_at
    WHERE id = v_plan.id;

    v_plans_touched := v_plans_touched + 1;
    v_total_steps_cancelled :=
      v_total_steps_cancelled + v_steps_cancelled;
    v_plan_ids := array_append(v_plan_ids, v_plan.id);
    IF NOT v_still_runnable THEN
      v_plans_cancelled := v_plans_cancelled + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'plans_touched', v_plans_touched,
    'plans_cancelled', v_plans_cancelled,
    'steps_cancelled', v_total_steps_cancelled,
    'plan_ids', to_jsonb(v_plan_ids),
    'errors', '[]'::jsonb
  );
END;
$_$;


--
-- Name: cancel_stale_invoice_reminder(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_stale_invoice_reminder(p_site_id uuid, p_sale_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_sale public.sales%rowtype;
  v_receipt public.invoice_reminders%rowtype;
  v_message public.messages%rowtype;
begin
  select * into v_sale from public.sales where id = p_sale_id and site_id = p_site_id for update;
  if not found then return false; end if;
  select * into v_receipt from public.invoice_reminders where site_id = p_site_id and sale_id = p_sale_id
    and state = 'ready' order by created_at desc limit 1 for update;
  if not found or v_receipt.sent_at is not null or v_receipt.provider_message_id is not null then return false; end if;
  select * into v_message from public.messages where id = v_receipt.message_id for update;
  if not found or (v_message.custom_data ? 'outreach_delivery'
      and v_message.custom_data->'outreach_delivery'->>'state' is distinct from 'blocked')
    or coalesce(v_message.custom_data->>'status', '') = 'sent'
    or v_message.custom_data->'delivery'->>'success' = 'true'
    or (v_message.custom_data->'outreach_delivery') ?| array['sent_at', 'provider_message_id', 'provider_call_id']
    or v_message.custom_data ?| array['sent_at', 'provider_message_id', 'provider_call_id', 'external_message_id'] then return false; end if;
  if v_sale.status = 'pending' and v_sale.amount_due > 0
    and v_sale.due_date::text is not distinct from v_message.custom_data->>'invoice_due_date'
    and v_sale.amount_due::numeric is not distinct from (v_message.custom_data->>'invoice_amount_due')::numeric
    and v_sale.currency is not distinct from v_message.custom_data->>'invoice_currency' then return false; end if;
  update public.messages set custom_data = coalesce(custom_data, '{}'::jsonb) || '{"status":"cancelled","invoice_cancelled":true}'::jsonb
    where id = v_message.id;
  update public.invoice_reminders set state = 'cancelled' where id = v_receipt.id;
  return true;
end;
$$;


--
-- Name: cancel_visitor_identity_challenge(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  perform public.assert_visitor_identity_service_role();
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text || ':' || p_challenge_id::text, 0));
  update public.visitor_identity_challenges set cancelled_at = clock_timestamp(), updated_at = clock_timestamp()
  where id = p_challenge_id and site_id = p_site_id and session_id = p_session_id
    and consumed_at is null and cancelled_at is null;
  return jsonb_build_object('status', 'cancelled');
end;
$$;


--
-- Name: capture_requirement_economic_pause(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.capture_requirement_economic_pause(p_status_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE st public.requirement_status%ROWTYPE; r public.requirements%ROWTYPE;
  h public.harness_requirement_runs%ROWTYPE; s public.harness_sessions%ROWTYPE;
BEGIN
  SELECT * INTO st FROM public.requirement_status WHERE id=p_status_id;
  IF NOT FOUND OR st.stage<>'blocked' THEN RETURN; END IF;
  SELECT * INTO r FROM public.requirements WHERE id=st.requirement_id;
  SELECT * INTO h FROM public.harness_requirement_runs WHERE requirement_id=r.id;
  IF NOT FOUND OR r.status<>'blocked' OR st.site_id IS DISTINCT FROM r.site_id
    OR h.site_id IS DISTINCT FROM r.site_id OR st.cycle IS DISTINCT FROM 'agent:'||h.last_cycle_id
    OR st.instance_id::text IS DISTINCT FROM r.metadata->>'runner_instance_id'
    OR coalesce(h.pause_reason,'') NOT IN ('token_budget_exhausted','account_credits_exhausted',
      'turn_budget_exhausted','active_time_budget_exhausted') OR h.next_run_at IS NOT NULL
    OR h.generation::text IS DISTINCT FROM r.metadata->>'requirement_execution_generation' THEN RETURN; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.requirements q
    JOIN public.harness_requirement_runs m ON m.requirement_id=q.id
    JOIN public.requirement_status status ON status.id=st.id
    WHERE q.id=r.id AND q.xmin=m.xmin AND q.xmin=status.xmin) THEN RETURN; END IF;
  SELECT * INTO s FROM public.harness_sessions WHERE id=h.session_id;
  IF FOUND AND (s.site_id IS DISTINCT FROM r.site_id OR s.user_id IS DISTINCT FROM r.user_id
    OR coalesce(s.snapshot->>'status','') NOT IN ('queued','running','paused')
    OR (s.snapshot->>'status'='paused' AND s.snapshot->>'reason' IS DISTINCT FROM h.pause_reason)) THEN RETURN; END IF;
  INSERT INTO public.requirement_economic_pauses(requirement_id,status_id,session_id,generation,
    requirement_guard,status_guard,session_version,pause_reason)
    VALUES(r.id,st.id,h.session_id,h.generation,to_jsonb(r)-ARRAY['budget','updated_at'],to_jsonb(st),s.version,h.pause_reason)
    ON CONFLICT(requirement_id) DO UPDATE SET status_id=EXCLUDED.status_id,session_id=EXCLUDED.session_id,
      generation=EXCLUDED.generation,requirement_guard=EXCLUDED.requirement_guard,status_guard=EXCLUDED.status_guard,
      session_version=EXCLUDED.session_version,pause_reason=EXCLUDED.pause_reason,last_error_code=NULL,checked_at='-infinity';
END;
$$;


--
-- Name: cascade_catalog_category_archive(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cascade_catalog_category_archive() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  affected_ids uuid[];
BEGIN
  IF NEW.status <> 'archived' THEN RETURN NEW; END IF;
  affected_ids := public.catalog_category_archive_item_ids(NEW.site_id, NEW.id);
  PERFORM i.id FROM public.catalog_items i
    WHERE i.site_id = NEW.site_id AND i.id = ANY(affected_ids)
    ORDER BY i.id FOR UPDATE NOWAIT;
  UPDATE public.catalog_items SET status = 'archived', updated_at = statement_timestamp()
    WHERE site_id = NEW.site_id AND id = ANY(affected_ids) AND status IS DISTINCT FROM 'archived';
  -- Only eligibility links are removed, not pass history or accounting/promotions.
  PERFORM r.id FROM public.pass_redeemable_items r
    WHERE r.site_id = NEW.site_id AND r.reservable_catalog_item_id = ANY(affected_ids)
    ORDER BY r.id FOR UPDATE NOWAIT;
  DELETE FROM public.pass_redeemable_items
    WHERE site_id = NEW.site_id AND reservable_catalog_item_id = ANY(affected_ids);
  RETURN NEW;
END;
$$;


--
-- Name: catalog_archive_lock_site(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_archive_lock_site(p_site_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF current_setting('transaction_isolation') <> 'read committed' THEN
    RAISE EXCEPTION 'Catalog archival writes require READ COMMITTED'
      USING ERRCODE = '25001';
  END IF;
  IF NOT pg_try_advisory_xact_lock(hashtextextended('catalog-category-archive:' || p_site_id::text, 0)) THEN
    RAISE EXCEPTION 'Concurrent catalog change; retry the transaction'
      USING ERRCODE = '55P03';
  END IF;
END;
$$;


--
-- Name: catalog_category_archive_item_ids(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_category_archive_item_ids(p_site_id uuid, p_category_id uuid) RETURNS uuid[]
    LANGUAGE sql
    SET search_path TO 'public', 'pg_temp'
    AS $$
  WITH RECURSIVE affected(id) AS (
    SELECT i.id FROM public.catalog_items i
      WHERE i.site_id = p_site_id AND i.category_id = p_category_id
    UNION
    SELECT i.id FROM public.catalog_items i JOIN affected a ON i.parent_id = a.id
      WHERE i.site_id = p_site_id
  )
  SELECT coalesce(array_agg(id ORDER BY id), ARRAY[]::uuid[]) FROM affected;
$$;


--
-- Name: catalog_import_category_key(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_import_category_key(p_name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
  SELECT lower(regexp_replace(btrim(p_name, E' \t\n\r\v\f'), E'[ \t\n\r\v\f]+', ' ', 'g'));
$$;


--
-- Name: catalog_search_bump_revision(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_bump_revision(p_site_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
  INSERT INTO public.catalog_search_revision_events(site_id) VALUES (p_site_id)
$$;


--
-- Name: catalog_search_candidates(uuid, text, text, jsonb, text, public.vector, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_candidates(p_site_id uuid, p_channel text, p_query text, p_filters jsonb, p_mode text, p_embedding public.vector, p_limit integer, p_min_similarity double precision DEFAULT 0.35) RETURNS TABLE(id uuid, site_id uuid, score double precision, exact_match boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE v_query text; v_pattern text; v_tsquery tsquery;
BEGIN
  PERFORM public.catalog_search_validate(p_site_id, p_channel, p_filters);
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 201 OR p_mode IS NULL OR p_mode NOT IN ('text','semantic')
    OR p_query IS NULL OR length(p_query) > 1000 OR p_min_similarity IS NULL
    OR p_min_similarity NOT BETWEEN 0 AND 1 THEN
    RAISE EXCEPTION 'invalid candidate bounds' USING ERRCODE = '22023';
  END IF;
  v_query := btrim(regexp_replace(p_query, '[[:space:]]+', ' ', 'g'));
  IF v_query = '' THEN RETURN; END IF;
  IF p_mode = 'semantic' THEN
    IF p_embedding IS NULL OR vector_dims(p_embedding) <> 1536 OR (p_embedding <#> p_embedding) >= 0 THEN
      RAISE EXCEPTION 'expected nonzero 1536-dimensional query embedding' USING ERRCODE = '22023';
    END IF;
    RETURN QUERY WITH eligible AS MATERIALIZED (
      SELECT d.catalog_item_id, d.site_id, d.embedding,
        ((md5(lower(d.name_text)) = md5(lower(v_query)) AND lower(d.name_text) = lower(v_query)) OR
         (md5(lower(d.sku_text)) = md5(lower(v_query)) AND lower(d.sku_text) = lower(v_query))) AS exact
      FROM public.catalog_search_documents d JOIN public.catalog_items i ON i.id = d.catalog_item_id AND i.site_id = d.site_id
      WHERE (p_site_id IS NULL OR d.site_id = p_site_id)
        AND d.embedding IS NOT NULL AND d.embedding_model = 'openai/text-embedding-3-small'
        AND d.embedding_source_hash = d.source_hash
        AND public.catalog_search_eligible(i, p_site_id, p_channel, p_filters)
    ), ranked AS (
      -- The materialization fence prevents an ANN scan before live eligibility.
      -- Exact for scoped and global marketplace searches; no extension GUCs.
      SELECT e.catalog_item_id, e.site_id, e.embedding <=> p_embedding AS distance, e.exact
      FROM eligible e
      ORDER BY distance, e.catalog_item_id LIMIT p_limit
    )
    SELECT ranked.catalog_item_id, ranked.site_id, (1 - ranked.distance)::double precision, ranked.exact
    FROM ranked WHERE 1 - ranked.distance >= p_min_similarity
    ORDER BY ranked.distance, ranked.catalog_item_id;
  ELSE
    v_pattern := '%' || replace(replace(replace(v_query, '\', '\\'), '%', '\%'), '_', '\_') || '%';
    v_tsquery := websearch_to_tsquery('simple', v_query);
    RETURN QUERY WITH searchable AS (
      SELECT d.catalog_item_id, d.site_id, d.name_text, d.sku_text, d.document_text, d.search_tsv
      FROM public.catalog_search_documents d
      UNION ALL
      SELECT i.id, i.site_id, i.name, coalesce(i.sku, ''),
        concat_ws(' ', i.name, i.sku, left(i.description, 6000)),
        setweight(to_tsvector('simple', coalesce(i.name, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(i.sku, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(left(i.description, 6000), '')), 'B')
      FROM public.catalog_items i
      WHERE NOT EXISTS (SELECT 1 FROM public.catalog_search_documents d WHERE d.catalog_item_id = i.id)
    ) SELECT d.catalog_item_id, d.site_id,
      (CASE WHEN md5(lower(d.sku_text)) = md5(lower(v_query)) AND lower(d.sku_text) = lower(v_query) THEN 1000
        WHEN md5(lower(d.name_text)) = md5(lower(v_query)) AND lower(d.name_text) = lower(v_query) THEN 900 ELSE 0 END
        + 10 * ts_rank_cd(d.search_tsv, v_tsquery)
        + CASE WHEN d.document_text ILIKE v_pattern ESCAPE '\' THEN 2 ELSE 0 END
        + word_similarity(v_query, d.document_text))::double precision,
      ((md5(lower(d.name_text)) = md5(lower(v_query)) AND lower(d.name_text) = lower(v_query)) OR
       (md5(lower(d.sku_text)) = md5(lower(v_query)) AND lower(d.sku_text) = lower(v_query)))
    FROM searchable d JOIN public.catalog_items i ON i.id = d.catalog_item_id AND i.site_id = d.site_id
    WHERE (p_site_id IS NULL OR d.site_id = p_site_id)
      AND public.catalog_search_eligible(i, p_site_id, p_channel, p_filters)
      AND ((md5(lower(d.sku_text)) = md5(lower(v_query)) AND lower(d.sku_text) = lower(v_query)) OR
        (md5(lower(d.name_text)) = md5(lower(v_query)) AND lower(d.name_text) = lower(v_query))
        OR d.search_tsv @@ v_tsquery OR d.document_text ILIKE v_pattern ESCAPE '\'
        OR (length(v_query) >= 3 AND word_similarity(v_query, d.document_text) >= 0.5))
    ORDER BY 4 DESC, 3 DESC, d.catalog_item_id LIMIT p_limit;
  END IF;
END $$;


--
-- Name: catalog_search_claim_embedding_jobs(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.catalog_search_claim_embedding_jobs(p_limit integer, p_lease_seconds integer) RETURNS TABLE(id uuid, catalog_item_id uuid, site_id uuid, document_text text, source_hash text, source_revision bigint, claim_token uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
BEGIN
  IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 100 OR p_lease_seconds IS NULL
    OR p_lease_seconds NOT BETWEEN 30 AND 900 THEN
    RAISE EXCEPTION 'invalid claim bounds' USING ERRCODE = '22023';
  END IF;
  -- Crashed workers count toward the same finite retry budget as explicit failures.
  WITH exhausted AS (
    SELECT j.id FROM public.catalog_embedding_jobs j WHERE j.attempts >= 8
      AND ((j.status = 'leased' AND j.lease_expires_at <= clock_timestamp())
        OR j.status IN ('pending', 'retry'))
    ORDER BY j.id LIMIT p_limit FOR UPDATE SKIP LOCKED
  ) UPDATE public.catalog_embedding_jobs j SET status = 'exhausted', claim_token = NULL,
    lease_expires_at = NULL, last_error = 'attempts_exhausted', updated_at = now()
    FROM exhausted e WHERE j.id = e.id;
  RETURN QUERY WITH ready AS (
    SELECT j.id FROM public.catalog_embedding_jobs j
    WHERE j.attempts < 8 AND ((j.status IN ('pending', 'retry') AND j.next_attempt_at <= clock_timestamp())
      OR (j.status = 'leased' AND j.lease_expires_at <= clock_timestamp()))
    ORDER BY j.next_attempt_at, j.id LIMIT p_limit FOR UPDATE SKIP LOCKED
  ), claimed AS (
    UPDATE public.catalog_embedding_jobs j SET status = 'leased', claim_token = gen_random_uuid(),
      lease_expires_at = clock_timestamp() + make_interval(secs => p_lease_seconds),
      attempts = j.attempts + 1, updated_at = now()
    FROM ready r WHERE j.id = r.id RETURNING j.*
  )
  SELECT j.id, j.catalog_item_id, j.site_id, d.document_text, j.source_hash, j.source_revision, j.claim_token
  FROM claimed j JOIN public.catalog_search_documents d ON d.catalog_item_id = j.catalog_item_id
    AND d.source_hash = j.source_hash AND d.source_revision = j.source_revision;
END $$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: block_requirement_for_product_no_progress(uuid, uuid, uuid, text, integer, text, integer, uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer, p_plan_id uuid, p_step_id text, p_expected_step_generation integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_status text;
  v_site_id uuid;
  v_metadata jsonb;
  v_latest_cycle_id text;
  v_latest_outcome text;
  v_failure_cycles integer := 0;
  v_steps jsonb;
  v_step jsonb;
  v_step_generation integer;
  v_last_progress_at timestamptz;
  v_last_progress_cycle_id text;
  v_audit_cycle text := 'product-no-progress-circuit:' || p_cycle_id;
BEGIN
  IF p_minimum_failures IS NULL OR p_minimum_failures < 1 THEN
    RAISE EXCEPTION 'p_minimum_failures must be positive';
  END IF;

  SELECT
    status,
    site_id,
    CASE WHEN jsonb_typeof(metadata) = 'object'
      THEN metadata ELSE '{}'::jsonb END
  INTO v_status, v_site_id, v_metadata
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'blocked', false);
  END IF;
  IF v_site_id IS DISTINCT FROM p_site_id THEN
    RAISE EXCEPTION 'Requirement % does not belong to site %',
      p_requirement_id, p_site_id;
  END IF;
  IF v_status IN ('done', 'cancelled', 'canceled', 'on-review') THEN
    RETURN jsonb_build_object('state', 'guarded', 'blocked', false);
  END IF;
  IF (
    CASE
      WHEN COALESCE(
        v_metadata->>'requirement_execution_generation',
        ''
      ) ~ '^[0-9]{1,9}$'
        THEN (v_metadata->>'requirement_execution_generation')::integer
      ELSE 0
    END
  ) IS DISTINCT FROM p_expected_execution_generation THEN
    RETURN jsonb_build_object('state', 'stale', 'blocked', false);
  END IF;

  SELECT CASE
    WHEN jsonb_typeof(steps) = 'array' THEN steps
    ELSE '[]'::jsonb
  END
  INTO v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
    AND instance_id = p_instance_id
    AND metadata->>'requirement_id' = p_requirement_id::text
    AND status IN ('pending', 'in_progress', 'active')
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'stale', 'blocked', false);
  END IF;

  SELECT entry.value
  INTO v_step
  FROM jsonb_array_elements(v_steps) AS entry(value)
  WHERE entry.value->>'id' = p_step_id
  LIMIT 1;
  IF v_step IS NULL
    OR v_step->>'status' NOT IN ('pending', 'in_progress', 'failed')
    OR COALESCE(
      v_step->'metadata'->'no_progress_adjudication'->>'state',
      ''
    ) <> 'consumed'
    OR COALESCE(
      v_step->'metadata'->'no_progress_adjudication'
        ->>'execution_generation',
      ''
    ) <> p_expected_execution_generation::text
  THEN
    RETURN jsonb_build_object('state', 'stale', 'blocked', false);
  END IF;

  v_step_generation := CASE
    WHEN COALESCE(
      v_step->>'infrastructure_generation',
      ''
    ) ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  IF v_step_generation IS DISTINCT FROM p_expected_step_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale', 'blocked', false,
      'generation', v_step_generation
    );
  END IF;

  SELECT cycle_id, outcome
  INTO v_latest_cycle_id, v_latest_outcome
  FROM public.requirement_cron_cycle_outcomes
  WHERE requirement_id = p_requirement_id
    AND execution_generation = p_expected_execution_generation
    AND plan_id = p_plan_id
    AND step_id = p_step_id
  ORDER BY cycle_started_at DESC, cycle_id DESC
  LIMIT 1;

  SELECT cycle_started_at, cycle_id
  INTO v_last_progress_at, v_last_progress_cycle_id
  FROM public.requirement_cron_cycle_outcomes
  WHERE requirement_id = p_requirement_id
    AND execution_generation = p_expected_execution_generation
    AND plan_id = p_plan_id
    AND step_id = p_step_id
    AND outcome = 'progress'
  ORDER BY cycle_started_at DESC, cycle_id DESC
  LIMIT 1;

  SELECT count(*)::integer
  INTO v_failure_cycles
  FROM public.requirement_cron_cycle_outcomes
  WHERE requirement_id = p_requirement_id
    AND execution_generation = p_expected_execution_generation
    AND plan_id = p_plan_id
    AND step_id = p_step_id
    AND outcome = 'product_no_progress'
    AND (
      v_last_progress_at IS NULL
      OR (cycle_started_at, cycle_id) >
        (v_last_progress_at, v_last_progress_cycle_id)
    );

  IF v_latest_cycle_id IS DISTINCT FROM p_cycle_id
    OR v_latest_outcome <> 'product_no_progress'
    OR v_failure_cycles < p_minimum_failures
  THEN
    RETURN jsonb_build_object('state', 'stale', 'blocked', false);
  END IF;

  UPDATE public.requirements
  SET
    status = 'blocked',
    metadata = v_metadata || jsonb_build_object(
      'cron_blocker_provenance', 'product_no_progress_circuit',
      'cron_blocker_version', 2,
      'cron_blocker_event_id', p_cycle_id,
      'cron_blocker_plan_id', p_plan_id::text,
      'cron_blocker_step_id', p_step_id,
      'cron_blocker_generation', p_expected_step_generation
    ),
    updated_at = timezone('utc', now())
  WHERE id = p_requirement_id;

  IF NOT EXISTS (
    SELECT 1
    FROM public.requirement_status
    WHERE requirement_id = p_requirement_id
      AND cycle = v_audit_cycle
  ) THEN
    INSERT INTO public.requirement_status (
      requirement_id,
      site_id,
      instance_id,
      stage,
      cycle,
      message
    )
    VALUES (
      p_requirement_id,
      p_site_id,
      p_instance_id,
      'blocked',
      v_audit_cycle,
      p_message
    );
  END IF;

  RETURN jsonb_build_object(
    'state', 'applied',
    'blocked', true,
    'generation', v_step_generation
  );
END;
$_$;


--
-- Name: block_requirement_with_provenance(uuid, uuid, uuid, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.block_requirement_with_provenance(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_status text;
  v_site_id uuid;
  v_metadata jsonb;
  v_execution_generation integer;
  v_cycle text := 'requirement-block:' || p_event_id;
BEGIN
  IF NULLIF(btrim(p_event_id), '') IS NULL THEN
    RAISE EXCEPTION 'Block event id is required';
  END IF;
  IF p_provenance NOT IN (
    'product_failure',
    'product_no_progress_circuit',
    'product_replan_circuit',
    'product_workflow_circuit'
  ) THEN
    RAISE EXCEPTION 'Unsupported product blocker provenance: %', p_provenance;
  END IF;

  SELECT
    status,
    site_id,
    CASE WHEN jsonb_typeof(metadata) = 'object'
      THEN metadata ELSE '{}'::jsonb END
  INTO v_status, v_site_id, v_metadata
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'blocked', false);
  END IF;
  IF v_site_id IS DISTINCT FROM p_site_id THEN
    RAISE EXCEPTION 'Requirement % does not belong to site %',
      p_requirement_id, p_site_id;
  END IF;
  IF v_status IN ('done', 'cancelled', 'canceled', 'on-review') THEN
    RETURN jsonb_build_object('state', 'guarded', 'blocked', false);
  END IF;
  v_execution_generation := CASE
    WHEN COALESCE(
      v_metadata->>'requirement_execution_generation',
      ''
    ) ~ '^[0-9]{1,9}$'
      THEN (v_metadata->>'requirement_execution_generation')::integer
    ELSE 0
  END;
  IF v_execution_generation IS DISTINCT FROM
    p_expected_execution_generation
  THEN
    RETURN jsonb_build_object('state', 'stale', 'blocked', false);
  END IF;

  UPDATE public.requirements
  SET
    status = 'blocked',
    metadata = v_metadata || jsonb_build_object(
      'cron_blocker_provenance', p_provenance,
      'cron_blocker_version', 1,
      'cron_blocker_event_id', p_event_id
    ),
    updated_at = timezone('utc', now())
  WHERE id = p_requirement_id;

  IF NOT EXISTS (
    SELECT 1 FROM public.requirement_status
    WHERE requirement_id = p_requirement_id AND cycle = v_cycle
  ) THEN
    INSERT INTO public.requirement_status (
      requirement_id, site_id, instance_id, stage, cycle, message
    ) VALUES (
      p_requirement_id, p_site_id, p_instance_id,
      'blocked', v_cycle, p_message
    );
  END IF;
  RETURN jsonb_build_object('state', 'applied', 'blocked', true);
END;
$_$;


--
-- Name: bump_record_embedding_revision(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bump_record_embedding_revision() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  IF OLD.title IS DISTINCT FROM NEW.title
    OR OLD.description IS DISTINCT FROM NEW.description
    OR OLD.category_id IS DISTINCT FROM NEW.category_id
    OR OLD.data IS DISTINCT FROM NEW.data
    OR OLD.relations IS DISTINCT FROM NEW.relations
    OR OLD.status IS DISTINCT FROM NEW.status
  THEN
    NEW.record_embedding_revision := OLD.record_embedding_revision + 1;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: calculate_kpis_from_events(uuid, text, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_kpis_from_events(site_id_param uuid, kpi_type_param text, period_start_param timestamp with time zone, period_end_param timestamp with time zone) RETURNS TABLE(kpi_name text, kpi_value numeric, kpi_previous_value numeric, segment_id uuid)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
  previous_period_start TIMESTAMPTZ;
  previous_period_end TIMESTAMPTZ;
  period_length_days INTEGER;
BEGIN
  -- Calcular período anterior basado en la duración del período actual
  period_length_days := EXTRACT(EPOCH FROM (period_end_param - period_start_param)) / 86400;
  previous_period_start := period_start_param - (period_end_param - period_start_param);
  previous_period_end := period_start_param;
  
  -- Devolver diferentes métricas según el tipo de KPI solicitado
  IF kpi_type_param = 'traffic' THEN
    -- KPI de tráfico: número de page_views
    RETURN QUERY
    WITH current_data AS (
      SELECT 
        s.id AS segment_id,
        COUNT(*) AS current_count
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.event_type = 'page_view'
        AND ve.created_at BETWEEN period_start_param AND period_end_param
      GROUP BY s.id
    ),
    previous_data AS (
      SELECT 
        s.id AS segment_id,
        COUNT(*) AS previous_count
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.event_type = 'page_view'
        AND ve.created_at BETWEEN previous_period_start AND previous_period_end
      GROUP BY s.id
    )
    SELECT 
      'Visitas de página' AS kpi_name,
      COALESCE(cd.current_count, 0)::DECIMAL AS kpi_value,
      COALESCE(pd.previous_count, 0)::DECIMAL AS kpi_previous_value,
      cd.segment_id
    FROM current_data cd
    LEFT JOIN previous_data pd ON cd.segment_id = pd.segment_id
    UNION ALL
    SELECT 
      'Visitas de página (sin segmento)' AS kpi_name,
      COUNT(*)::DECIMAL AS kpi_value,
      (SELECT COUNT(*)::DECIMAL FROM public.visitor_events 
       WHERE site_id = site_id_param
         AND event_type = 'page_view'
         AND segment_id IS NULL
         AND created_at BETWEEN previous_period_start AND previous_period_end) AS kpi_previous_value,
      NULL::UUID AS segment_id
    FROM public.visitor_events
    WHERE site_id = site_id_param
      AND event_type = 'page_view'
      AND segment_id IS NULL
      AND created_at BETWEEN period_start_param AND period_end_param;
    
  ELSIF kpi_type_param = 'conversion' THEN
    -- KPI de conversión
    RETURN QUERY
    WITH conversions AS (
      SELECT 
        s.id AS segment_id,
        COUNT(*) FILTER (WHERE ve.event_type = 'conversion') AS conv_count,
        COUNT(*) FILTER (WHERE ve.event_type = 'page_view') AS view_count,
        COUNT(*) FILTER (WHERE ve.event_type = 'conversion' AND ve.created_at BETWEEN previous_period_start AND previous_period_end) AS prev_conv_count,
        COUNT(*) FILTER (WHERE ve.event_type = 'page_view' AND ve.created_at BETWEEN previous_period_start AND previous_period_end) AS prev_view_count
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.created_at BETWEEN previous_period_start AND period_end_param
        AND (ve.event_type = 'conversion' OR ve.event_type = 'page_view')
      GROUP BY s.id
    )
    SELECT 
      'Tasa de conversión' AS kpi_name,
      CASE 
        WHEN view_count > 0 THEN (conv_count * 100.0 / view_count)::DECIMAL 
        ELSE 0::DECIMAL 
      END AS kpi_value,
      CASE 
        WHEN prev_view_count > 0 THEN (prev_conv_count * 100.0 / prev_view_count)::DECIMAL 
        ELSE 0::DECIMAL 
      END AS kpi_previous_value,
      segment_id
    FROM conversions;
    
  ELSIF kpi_type_param = 'engagement' THEN
    -- KPI de engagement (promedio de duración de sesión)
    RETURN QUERY
    WITH engagement AS (
      SELECT 
        s.id AS segment_id,
        AVG(ve.duration_seconds) FILTER (WHERE ve.created_at BETWEEN period_start_param AND period_end_param) AS avg_duration,
        AVG(ve.duration_seconds) FILTER (WHERE ve.created_at BETWEEN previous_period_start AND previous_period_end) AS prev_avg_duration
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.created_at BETWEEN previous_period_start AND period_end_param
        AND ve.duration_seconds IS NOT NULL
      GROUP BY s.id
    )
    SELECT 
      'Tiempo promedio en página' AS kpi_name,
      COALESCE(avg_duration, 0)::DECIMAL AS kpi_value,
      COALESCE(prev_avg_duration, 0)::DECIMAL AS kpi_previous_value,
      segment_id
    FROM engagement;
  END IF;
END;
$$;


--
-- Name: can_access_record_diagram(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.can_access_record_diagram(p_record_id uuid, p_site_id uuid, p_command text DEFAULT 'select'::text) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  SELECT
    public.user_can(p_site_id, p_command)
    AND EXISTS (
      SELECT 1
      FROM public.records r
      WHERE r.id = p_record_id
        AND r.site_id = p_site_id
    );
$$;


--
-- Name: can_access_record_values(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.can_access_record_values(p_site_id uuid, p_relations jsonb) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    SET row_security TO 'off'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.sites s
    WHERE s.id = p_site_id
      AND (
        s.user_id = auth.uid()
        OR EXISTS (
          SELECT 1
          FROM public.site_ownership so
          WHERE so.site_id = s.id
            AND so.user_id = auth.uid()
        )
        OR EXISTS (
          SELECT 1
          FROM public.site_members sm
          WHERE sm.site_id = s.id
            AND sm.user_id = auth.uid()
            AND sm.status = 'active'
            AND (
              NOT COALESCE(sm.restrict_to_assigned_only, false)
              OR COALESCE(p_relations, '{}'::jsonb)::text LIKE
                '%' || auth.uid()::text || '%'
            )
        )
      )
  );
$$;

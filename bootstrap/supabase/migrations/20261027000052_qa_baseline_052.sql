SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: record_instance_context_usage(uuid, uuid, text, text, integer, integer, integer, integer, text, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_reserved_output_tokens integer, p_source text, p_measured_at timestamp with time zone) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  INSERT INTO public.instance_context_state
    (instance_id, site_id, model, provider, used_tokens, output_tokens,
     available_tokens, reserved_output_tokens, source, measured_at)
  SELECT p_instance_id, p_site_id, p_model, p_provider, p_used_tokens, p_output_tokens,
    p_available_tokens, p_reserved_output_tokens, p_source, p_measured_at
  WHERE EXISTS (SELECT 1 FROM public.remote_instances WHERE id = p_instance_id AND site_id = p_site_id)
  ON CONFLICT (instance_id) DO UPDATE SET
    model = EXCLUDED.model, provider = EXCLUDED.provider, used_tokens = EXCLUDED.used_tokens,
    output_tokens = EXCLUDED.output_tokens, available_tokens = EXCLUDED.available_tokens,
    reserved_output_tokens = EXCLUDED.reserved_output_tokens, source = EXCLUDED.source,
    measured_at = EXCLUDED.measured_at, updated_at = now()
  WHERE instance_context_state.site_id = EXCLUDED.site_id
    AND (instance_context_state.measured_at IS NULL OR instance_context_state.measured_at <= EXCLUDED.measured_at);
END $$;


--
-- Name: record_instance_plan_step_infrastructure_failure(uuid, text, text, text, jsonb, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_instance_plan_step_infrastructure_failure(p_plan_id uuid, p_step_id text, p_event_id text, p_error_message text, p_wait jsonb DEFAULT '{}'::jsonb, p_max_retries integer DEFAULT 4, p_expected_generation integer DEFAULT 0, p_allow_retryable_failed boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_steps jsonb; v_step jsonb; v_step_index integer;
  v_status text; v_generation integer;
  v_current_count integer; v_next_count integer;
  v_circuit_open boolean; v_retry_at timestamptz;
BEGIN
  IF NULLIF(btrim(p_step_id), '') IS NULL
    OR NULLIF(btrim(p_event_id), '') IS NULL
  THEN
    RAISE EXCEPTION 'Step id and event id are required';
  END IF;
  IF p_max_retries < 1 OR p_max_retries > 100 THEN
    RAISE EXCEPTION 'p_max_retries must be between 1 and 100';
  END IF;
  SELECT CASE
    WHEN jsonb_typeof(steps) = 'array' THEN steps
    ELSE '[]'::jsonb
  END
  INTO v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'state', 'missing', 'infra_count', 0, 'circuit_open', false
    );
  END IF;
  SELECT entry.value, (entry.ordinality - 1)::integer
  INTO v_step, v_step_index
  FROM jsonb_array_elements(v_steps)
    WITH ORDINALITY AS entry(value, ordinality)
  WHERE entry.value->>'id' = p_step_id
  LIMIT 1;
  IF v_step IS NULL THEN
    RETURN jsonb_build_object(
      'state', 'missing', 'infra_count', 0, 'circuit_open', false
    );
  END IF;
  v_generation := CASE
    WHEN COALESCE(v_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  IF EXISTS (
    SELECT 1
    FROM public.instance_plan_step_infrastructure_events
    WHERE plan_id = p_plan_id
      AND step_id = p_step_id
      AND event_id = p_event_id
  ) THEN
    IF v_generation::bigint IS DISTINCT FROM
      p_expected_generation::bigint + 1
    THEN
      RETURN jsonb_build_object(
        'state', 'stale', 'infra_count', 0,
        'circuit_open', false, 'generation', v_generation
      );
    END IF;
    RETURN jsonb_build_object(
      'state', 'duplicate',
      'infra_count', LEAST(
        CASE
          WHEN COALESCE(v_step->>'infra_retry_count', '') ~ '^[0-9]{1,9}$'
            THEN (v_step->>'infra_retry_count')::integer
          ELSE 0
        END,
        p_max_retries
      ),
      'circuit_open',
        COALESCE(v_step->>'infrastructure_circuit_open', '') = 'true',
      'retry_at', v_step->>'infra_retry_after',
      'generation', v_generation
    );
  END IF;
  IF v_generation IS DISTINCT FROM p_expected_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale',
      'infra_count',
        CASE WHEN COALESCE(v_step->>'infra_retry_count', '') ~ '^[0-9]{1,9}$'
          THEN (v_step->>'infra_retry_count')::integer ELSE 0 END,
      'circuit_open',
        COALESCE(v_step->>'infrastructure_circuit_open', '') = 'true',
      'generation', v_generation
    );
  END IF;
  v_status := v_step->>'status';
  IF v_status IN ('completed', 'cancelled')
    OR (v_status = 'failed' AND NOT p_allow_retryable_failed)
  THEN
    RETURN jsonb_build_object(
      'state', 'terminal',
      'infra_count',
        CASE WHEN COALESCE(v_step->>'infra_retry_count', '') ~ '^[0-9]{1,9}$'
          THEN (v_step->>'infra_retry_count')::integer ELSE 0 END,
      'circuit_open', false,
      'generation', v_generation
    );
  END IF;
  v_current_count := CASE
    WHEN COALESCE(v_step->>'infra_retry_count', '') ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infra_retry_count')::integer
    ELSE 0
  END;
  v_next_count := LEAST(v_current_count + 1, p_max_retries);
  v_circuit_open := v_next_count >= p_max_retries;
  v_retry_at := CASE
    WHEN v_circuit_open THEN NULL
    ELSE timezone('utc', now()) +
      LEAST(
        interval '1 minute' * power(2, GREATEST(0, v_next_count - 1)),
        interval '15 minutes'
      )
  END;
  v_step := v_step || jsonb_build_object(
    'infra_retry_count', v_next_count,
    'infra_retry_after', CASE
      WHEN v_retry_at IS NULL THEN NULL
      ELSE to_jsonb(v_retry_at)
    END,
    'infrastructure_error',
      COALESCE(NULLIF(p_error_message, ''), 'Infrastructure unavailable'),
    'infrastructure_waiting', true,
    'infrastructure_kind', COALESCE(p_wait->>'kind', 'gate'),
    'infrastructure_failure_provenance',
      COALESCE(p_wait->>'provenance', 'cron_infrastructure'),
    'infrastructure_correlation', COALESCE(p_wait->'correlation', 'null'::jsonb),
    'infrastructure_state', CASE
      WHEN v_circuit_open THEN 'intervention_required'
      ELSE 'backoff'
    END,
    'infrastructure_circuit_open', v_circuit_open,
    'infrastructure_intervention_required', v_circuit_open,
    'infrastructure_product_retry_count',
      CASE
        WHEN jsonb_typeof(
          v_step->'infrastructure_product_retry_count'
        ) = 'number'
        THEN v_step->'infrastructure_product_retry_count'
        ELSE to_jsonb(CASE
          WHEN COALESCE(v_step->>'retry_count', '') ~ '^[0-9]{1,9}$'
            THEN (v_step->>'retry_count')::integer
          ELSE 0
        END)
      END,
    'infrastructure_generation', v_generation + 1,
    'infrastructure_last_event_id', p_event_id
  );
  v_steps := jsonb_set(
    v_steps,
    ARRAY[v_step_index::text],
    v_step,
    false
  );

  UPDATE public.instance_plans
  SET steps = v_steps, updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  INSERT INTO public.instance_plan_step_infrastructure_events (
    plan_id,
    step_id,
    event_id,
    event_type,
    details
  )
  VALUES (
    p_plan_id,
    p_step_id,
    p_event_id,
    'failure',
    jsonb_build_object(
      'infra_count', v_next_count,
      'circuit_open', v_circuit_open,
      'generation', v_generation + 1,
      'wait', COALESCE(p_wait, '{}'::jsonb)
    )
  );

  RETURN jsonb_build_object(
    'state', 'applied',
    'infra_count', v_next_count,
    'circuit_open', v_circuit_open,
    'retry_at', v_retry_at,
    'generation', v_generation + 1
  );
END;
$_$;


--
-- Name: record_lead_invoice_payment(uuid, uuid, uuid, text, text, text, numeric, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_lead_invoice_payment(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4296761($1,$2,$3,$4,$5,$6,$7,$8,$9); END$_$;


--
-- Name: record_outstand_initial_import(uuid, text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_outstand_initial_import(p_site_id uuid, p_account_id text, p_status text, p_job_id text DEFAULT NULL::text, p_imported integer DEFAULT NULL::integer, p_failed integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_4248377($1,$2,$3,$4,$5,$6); END$_$;


--
-- Name: record_payment(uuid, character varying, numeric, character varying, character varying, jsonb, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_payment(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying DEFAULT 'success'::character varying, p_payment_method character varying DEFAULT 'credit_card'::character varying, p_details jsonb DEFAULT '{}'::jsonb, p_credits integer DEFAULT 0) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16751($1,$2,$3,$4,$5,$6,$7); END$_$;


--
-- Name: record_requirement_cron_cycle_outcome(uuid, text, timestamp with time zone, text, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_plan_id uuid;
  v_step_id text;
  v_metadata jsonb;
BEGIN
  IF p_outcome IN ('progress', 'product_no_progress') THEN
    WITH candidates AS (
      SELECT
        plan.id AS plan_id,
        entry.value->>'id' AS step_id
      FROM public.instance_plans AS plan
      CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(plan.steps) = 'array'
          THEN plan.steps ELSE '[]'::jsonb END
      ) AS entry(value)
      WHERE (
          p_runner_instance_id IS NULL
          OR plan.instance_id = p_runner_instance_id
        )
        AND plan.metadata->>'requirement_id' = p_requirement_id::text
        AND entry.value->'metadata'->>'cron_cycle_id' = p_cycle_id
        AND COALESCE(
          entry.value->'metadata'->>'cron_execution_generation',
          ''
        ) ~ '^[0-9]{1,9}$'
        AND (
          entry.value->'metadata'->>'cron_execution_generation'
        )::integer = p_expected_execution_generation
        AND (
          entry.value->>'status' IN ('pending', 'in_progress', 'failed')
          OR (
            p_outcome = 'progress'
            AND entry.value->>'status' = 'completed'
          )
        )
    ),
    counted_candidates AS (
      SELECT
        plan_id,
        step_id,
        count(*) OVER () AS candidate_count
      FROM candidates
    )
    SELECT
      plan_id,
      step_id
    INTO v_plan_id, v_step_id
    FROM counted_candidates
    WHERE candidate_count = 1;

    IF p_outcome = 'product_no_progress'
      AND (v_plan_id IS NULL OR v_step_id IS NULL)
    THEN
      SELECT CASE
        WHEN jsonb_typeof(metadata) = 'object' THEN metadata
        ELSE '{}'::jsonb
      END
      INTO v_metadata
      FROM public.requirements
      WHERE id = p_requirement_id;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Requirement % not found', p_requirement_id;
      END IF;
      RETURN jsonb_build_object(
        'accepted', false,
        'is_latest', false,
        'recorded_outcome', p_outcome,
        'metadata', v_metadata,
        'cron_attempts', CASE
          WHEN COALESCE(v_metadata->>'cron_attempts', '') ~ '^[0-9]{1,9}$'
            THEN (v_metadata->>'cron_attempts')::integer ELSE 0 END,
        'no_progress_cycles', CASE
          WHEN COALESCE(v_metadata->>'no_progress_cycles', '') ~
            '^[0-9]{1,9}$'
            THEN (v_metadata->>'no_progress_cycles')::integer ELSE 0 END,
        'infrastructure_failure_cycles', CASE
          WHEN COALESCE(
            v_metadata->>'cron_infrastructure_failure_cycles', ''
          ) ~ '^[0-9]{1,9}$'
            THEN (
              v_metadata->>'cron_infrastructure_failure_cycles'
            )::integer
          ELSE 0
        END,
        'plan_id', NULL,
        'step_id', NULL
      );
    END IF;
  END IF;

  RETURN public.record_requirement_cron_cycle_outcome(
    p_requirement_id,
    p_cycle_id,
    p_cycle_started_at,
    p_outcome,
    p_expected_execution_generation,
    p_runner_instance_id,
    v_plan_id,
    v_step_id
  );
END;
$_$;

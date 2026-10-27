SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: record_requirement_cron_cycle_outcome(uuid, text, timestamp with time zone, text, integer, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid, p_plan_id uuid, p_step_id text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_metadata jsonb;
  v_inserted boolean := false;
  v_recorded_outcome text;
  v_latest_cycle_id text;
  v_latest_outcome text;
  v_latest_started_at timestamptz;
  v_latest_runner_instance_id uuid;
  v_latest_plan_id uuid;
  v_latest_step_id text;
  v_last_progress_at timestamptz;
  v_last_progress_cycle_id text;
  v_last_scoped_progress_at timestamptz;
  v_last_scoped_progress_cycle_id text;
  v_last_recovery_at timestamptz;
  v_last_recovery_cycle_id text;
  v_cron_attempts integer := 0;
  v_no_progress_cycles integer := 0;
  v_infrastructure_failure_cycles integer := 0;
  v_allowed_outcomes constant text[] := ARRAY[
    'progress', 'product_no_progress', 'product_failure',
    'infrastructure_wait', 'infrastructure_retry',
    'infrastructure_exhausted', 'scheduler_cooldown',
    'remediation_handoff', 'paused', 'idle'
  ];
BEGIN
  IF NULLIF(btrim(p_cycle_id), '') IS NULL
    OR char_length(p_cycle_id) > 200
  THEN
    RAISE EXCEPTION 'p_cycle_id must contain 1 to 200 characters';
  END IF;
  IF p_cycle_started_at IS NULL
    OR p_cycle_started_at > timezone('utc', now()) + interval '5 minutes'
  THEN
    RAISE EXCEPTION 'p_cycle_started_at is invalid';
  END IF;
  IF NOT (p_outcome = ANY(v_allowed_outcomes)) THEN
    RAISE EXCEPTION 'Unsupported cron cycle outcome: %', p_outcome;
  END IF;
  IF (p_plan_id IS NULL) IS DISTINCT FROM
    (NULLIF(btrim(p_step_id), '') IS NULL)
  THEN
    RAISE EXCEPTION 'p_plan_id and p_step_id must be provided together';
  END IF;
  IF p_outcome = 'product_no_progress' AND p_plan_id IS NULL THEN
    RAISE EXCEPTION 'product_no_progress requires plan and step scope';
  END IF;

  SELECT CASE
    WHEN jsonb_typeof(metadata) = 'object' THEN metadata
    ELSE '{}'::jsonb
  END
  INTO v_metadata
  FROM public.requirements
  WHERE id = p_requirement_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Requirement % not found', p_requirement_id;
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
    RETURN jsonb_build_object(
      'accepted', false,
      'is_latest', false,
      'recorded_outcome', p_outcome,
      'metadata', v_metadata,
      'cron_attempts', 0,
      'no_progress_cycles', 0,
      'infrastructure_failure_cycles', 0
    );
  END IF;
  v_cron_attempts := CASE
    WHEN COALESCE(v_metadata->>'cron_attempts', '') ~ '^[0-9]{1,9}$'
      THEN (v_metadata->>'cron_attempts')::integer
    ELSE 0
  END;
  v_no_progress_cycles := CASE
    WHEN COALESCE(v_metadata->>'no_progress_cycles', '') ~ '^[0-9]{1,9}$'
      THEN (v_metadata->>'no_progress_cycles')::integer
    ELSE 0
  END;
  v_infrastructure_failure_cycles := CASE
    WHEN COALESCE(
      v_metadata->>'cron_infrastructure_failure_cycles',
      ''
    ) ~ '^[0-9]{1,9}$'
      THEN (v_metadata->>'cron_infrastructure_failure_cycles')::integer
    ELSE 0
  END;

  INSERT INTO public.requirement_cron_cycle_outcomes (
    requirement_id,
    cycle_id,
    cycle_started_at,
    execution_generation,
    outcome,
    runner_instance_id,
    plan_id,
    step_id
  )
  VALUES (
    p_requirement_id,
    p_cycle_id,
    p_cycle_started_at,
    p_expected_execution_generation,
    p_outcome,
    p_runner_instance_id,
    p_plan_id,
    NULLIF(btrim(p_step_id), '')
  )
  ON CONFLICT (requirement_id, cycle_id) DO NOTHING
  RETURNING true INTO v_inserted;

  SELECT outcome
  INTO v_recorded_outcome
  FROM public.requirement_cron_cycle_outcomes
  WHERE requirement_id = p_requirement_id
    AND cycle_id = p_cycle_id;

  SELECT
    cycle_id,
    outcome,
    cycle_started_at,
    runner_instance_id,
    plan_id,
    step_id
  INTO
    v_latest_cycle_id,
    v_latest_outcome,
    v_latest_started_at,
    v_latest_runner_instance_id,
    v_latest_plan_id,
    v_latest_step_id
  FROM public.requirement_cron_cycle_outcomes
  WHERE requirement_id = p_requirement_id
    AND execution_generation = p_expected_execution_generation
  ORDER BY cycle_started_at DESC, cycle_id DESC
  LIMIT 1;

  SELECT cycle_started_at, cycle_id
  INTO v_last_progress_at, v_last_progress_cycle_id
  FROM public.requirement_cron_cycle_outcomes
  WHERE requirement_id = p_requirement_id
    AND execution_generation = p_expected_execution_generation
    AND outcome = 'progress'
  ORDER BY cycle_started_at DESC, cycle_id DESC
  LIMIT 1;

  IF v_latest_outcome IN (
    'progress',
    'product_no_progress',
    'product_failure'
  ) THEN
    SELECT count(*) FILTER (
      WHERE outcome IN ('product_no_progress', 'product_failure')
    )::integer
    INTO v_cron_attempts
    FROM public.requirement_cron_cycle_outcomes
    WHERE requirement_id = p_requirement_id
      AND execution_generation = p_expected_execution_generation
      AND (
        v_last_progress_at IS NULL
        OR (cycle_started_at, cycle_id) >
          (v_last_progress_at, v_last_progress_cycle_id)
      );

    SELECT cycle_started_at, cycle_id
    INTO v_last_scoped_progress_at, v_last_scoped_progress_cycle_id
    FROM public.requirement_cron_cycle_outcomes
    WHERE requirement_id = p_requirement_id
      AND execution_generation = p_expected_execution_generation
      AND plan_id IS NOT DISTINCT FROM v_latest_plan_id
      AND step_id IS NOT DISTINCT FROM v_latest_step_id
      AND outcome = 'progress'
    ORDER BY cycle_started_at DESC, cycle_id DESC
    LIMIT 1;

    SELECT count(*)::integer
    INTO v_no_progress_cycles
    FROM public.requirement_cron_cycle_outcomes
    WHERE requirement_id = p_requirement_id
      AND execution_generation = p_expected_execution_generation
      AND plan_id IS NOT DISTINCT FROM v_latest_plan_id
      AND step_id IS NOT DISTINCT FROM v_latest_step_id
      AND outcome = 'product_no_progress'
      AND (
        v_last_scoped_progress_at IS NULL
        OR (cycle_started_at, cycle_id) >
          (
            v_last_scoped_progress_at,
            v_last_scoped_progress_cycle_id
          )
      );

    v_metadata := v_metadata || jsonb_build_object(
      'cron_attempts', COALESCE(v_cron_attempts, 0),
      'no_progress_cycles', COALESCE(v_no_progress_cycles, 0),
      'cron_no_progress_plan_id', v_latest_plan_id,
      'cron_no_progress_step_id', v_latest_step_id
    );
  END IF;

  IF v_latest_outcome IN (
    'progress',
    'product_no_progress',
    'product_failure',
    'remediation_handoff',
    'infrastructure_retry'
  ) THEN
    SELECT cycle_started_at, cycle_id
    INTO v_last_recovery_at, v_last_recovery_cycle_id
    FROM public.requirement_cron_cycle_outcomes
    WHERE requirement_id = p_requirement_id
      AND execution_generation = p_expected_execution_generation
      AND outcome IN (
        'progress',
        'product_no_progress',
        'product_failure',
        'remediation_handoff'
      )
    ORDER BY cycle_started_at DESC, cycle_id DESC
    LIMIT 1;

    SELECT count(*)::integer
    INTO v_infrastructure_failure_cycles
    FROM public.requirement_cron_cycle_outcomes
    WHERE requirement_id = p_requirement_id
      AND execution_generation = p_expected_execution_generation
      AND outcome = 'infrastructure_retry'
      AND (
        v_last_recovery_at IS NULL
        OR (cycle_started_at, cycle_id) >
          (v_last_recovery_at, v_last_recovery_cycle_id)
      );

    v_metadata := v_metadata || jsonb_build_object(
      'cron_infrastructure_failure_cycles',
      COALESCE(v_infrastructure_failure_cycles, 0)
    );
  END IF;

  v_metadata := v_metadata || jsonb_build_object(
    'cron_last_cycle_id', v_latest_cycle_id,
    'cron_last_cycle_outcome', v_latest_outcome,
    'cron_last_cycle_at', v_latest_started_at
  );
  IF v_last_progress_cycle_id IS NOT NULL THEN
    v_metadata := v_metadata || jsonb_build_object(
      'cron_last_progress_cycle_id', v_last_progress_cycle_id
    );
  END IF;
  IF v_latest_runner_instance_id IS NOT NULL THEN
    v_metadata := v_metadata || jsonb_build_object(
      'runner_instance_id', v_latest_runner_instance_id
    );
  END IF;

  UPDATE public.requirements
  SET
    metadata = v_metadata,
    updated_at = timezone('utc', now())
  WHERE id = p_requirement_id;

  RETURN jsonb_build_object(
    'accepted', v_inserted IS TRUE,
    'is_latest', p_cycle_id = v_latest_cycle_id,
    'recorded_outcome', v_recorded_outcome,
    'metadata', v_metadata,
    'cron_attempts', COALESCE(v_cron_attempts, 0),
    'no_progress_cycles', COALESCE(v_no_progress_cycles, 0),
    'infrastructure_failure_cycles',
      COALESCE(v_infrastructure_failure_cycles, 0),
    'plan_id', v_latest_plan_id,
    'step_id', v_latest_step_id
  );
END;
$_$;


--
-- Name: record_requirement_source_checkpoint(uuid, text, integer, uuid, text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_result jsonb, p_baseline jsonb DEFAULT NULL::jsonb) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE r public.requirements%ROWTYPE; s public.harness_sessions%ROWTYPE; state text; message text;
BEGIN
  state:=p_result->>'state';
  IF jsonb_typeof(p_result) IS DISTINCT FROM 'object' OR state IS NULL
    OR state NOT IN ('saved','unchanged','skipped','failed','unknown')
    OR octet_length(p_result::text)>8000
    OR (p_baseline IS NOT NULL AND (jsonb_typeof(p_baseline) IS DISTINCT FROM 'object'
      OR octet_length(p_baseline::text)>4000000 OR state NOT IN ('saved','unchanged')))
    OR (state IN ('saved','unchanged') AND (p_baseline IS NULL
      OR coalesce(p_result->>'sha','') !~ '^[0-9a-f]{40}$'
      OR p_baseline->>'commitSha' IS DISTINCT FROM p_result->>'sha'))
  THEN RAISE EXCEPTION 'Invalid source checkpoint receipt' USING ERRCODE='22023'; END IF;
  IF NOT public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id,false,300) THEN RETURN false; END IF;
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id FOR UPDATE;
  SELECT * INTO s FROM public.harness_sessions WHERE id=p_session_id AND site_id=r.site_id FOR UPDATE;
  IF NOT FOUND OR p_owner IS NULL OR s.lease_owner IS DISTINCT FROM p_owner
    OR s.lease_expires_at IS NULL OR s.lease_expires_at<=clock_timestamp()
    OR s.snapshot->>'status' IS DISTINCT FROM 'running' THEN RETURN false; END IF;
  INSERT INTO public.requirement_source_checkpoints(requirement_id,site_id,session_id,baseline,last_result)
    VALUES(r.id,r.site_id,p_session_id,p_baseline,p_result)
    ON CONFLICT(requirement_id) DO UPDATE SET session_id=EXCLUDED.session_id,
      baseline=coalesce(EXCLUDED.baseline,public.requirement_source_checkpoints.baseline),
      pending_publication=CASE WHEN state IN ('saved','unchanged') THEN NULL
        ELSE public.requirement_source_checkpoints.pending_publication END,
      last_result=EXCLUDED.last_result,updated_at=clock_timestamp();
  message:=CASE WHEN state IN ('saved','unchanged') THEN
    'Source checkpoint confirmed on GitHub: '||(p_result->>'sha')||'. Excluded files: '||coalesce(p_result->>'excludedCount','0')||'. This is a bounded source backup, not a complete sandbox backup, deployment or task acceptance.'
    ELSE 'Source checkpoint not confirmed ('||state||'). Sandbox work was not reset; retry on a later owned cycle.' END;
  INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,cycle,message,repo_url)
    VALUES(r.id,r.site_id,(r.metadata->>'runner_instance_id')::uuid,r.status,
      'source-checkpoint:'||p_run_id,message,
      CASE WHEN state IN ('saved','unchanged') THEN p_result->>'repoUrl' ELSE NULL END);
  RETURN true;
END;
$_$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: observe_message_channel_health(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.observe_message_channel_health() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_site uuid;
  v_channel text;
  v_config jsonb;
  v_channel_config jsonb;
  v_direction text;
  v_outcome text;
  v_error text;
  v_class text;
  v_source_id uuid;
BEGIN
  -- messages/settings permit client writes. A client must not manufacture
  -- provider observations in custom_data. SET ROLE is privilege-checked;
  -- the JWT claim GUC is not. SECURITY DEFINER also changes current_user.
  IF session_user NOT IN ('postgres', 'service_role')
     AND current_setting('role', true) IS DISTINCT FROM 'service_role'
  THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' THEN
    IF NEW.custom_data IS NOT DISTINCT FROM OLD.custom_data THEN RETURN NEW; END IF;
  END IF;
  SELECT site_id, channel INTO v_site, v_channel FROM public.conversations WHERE id = NEW.conversation_id;
  IF v_site IS NULL THEN RETURN NEW; END IF;

  IF NEW.role = 'user' THEN
    v_direction := 'inbound';
    v_outcome := 'success'; -- Ingestion into messages succeeded, not AI processing.
    v_channel := coalesce(NEW.custom_data->>'channel', v_channel);
    IF TG_OP = 'UPDATE' OR v_channel IS NULL OR v_channel NOT IN ('email', 'whatsapp') THEN RETURN NEW; END IF;
    -- A successful API ingestion is not evidence the provider's webhook
    -- works unless it carries a stable provider-origin message identifier.
    IF coalesce(NEW.custom_data->>'origin_message_id', '') = ''
       OR NEW.custom_data->>'status' = 'failed' THEN RETURN NEW; END IF;
  ELSIF NEW.role IN ('assistant', 'agent') THEN
    v_direction := 'outbound';
    v_channel := coalesce(NEW.custom_data#>>'{delivery,channel}', NEW.custom_data->>'channel', v_channel);
    IF NEW.custom_data#>>'{delivery,success}' = 'true'
       AND NEW.custom_data->>'status' IN ('sent', 'delivered') THEN
      v_outcome := 'success';
    ELSIF NEW.custom_data#>>'{delivery,success}' = 'false'
          AND NEW.custom_data->>'status' = 'failed' THEN
      v_outcome := 'failure';
      v_error := lower(left(coalesce(NEW.custom_data#>>'{delivery,details,error}',
                                    NEW.custom_data->>'error_message', ''), 300));
      v_class := CASE
        WHEN v_error ~ '(invalid (phone|email|address|recipient)|no (phone|email)|unsubscrib|bounce|unknown recipient)' THEN 'recipient'
        WHEN v_error ~ '(template|content|placeholder|approval|no valid channels)' THEN 'content'
        WHEN v_error ~ '(unauthoriz|forbidden|authentication|credential|invalid api key|expired token|smtp auth|(^|[^0-9])(401|403)([^0-9]|$))' THEN 'auth'
        WHEN v_error ~ '(rate.limit|timeout|timed out|econnreset|econnrefused|etimedout|service unavailable|(^|[^0-9])(429|5[0-9][0-9])([^0-9]|$))' THEN 'provider'
        ELSE 'unknown'
      END;
    ELSE RETURN NEW; END IF;
  ELSE RETURN NEW; END IF;

  -- A provider-origin id is not the same thing as an AI/customer-support run.
  -- Only the initial persisted inbound message can establish inbound traffic.
  -- This is a health observation for a configured channel, not an arbitrary
  -- conversation label. Reconfiguration requires fresh evidence.
  IF v_channel IN ('email', 'whatsapp') THEN
    -- Serialize with settings reconfiguration (same lock order: settings,
    -- then channel_health), so an in-flight send cannot bless old credentials.
    SELECT channels INTO v_config
    FROM public.settings WHERE site_id = v_site FOR SHARE;
    IF v_config IS NULL OR jsonb_typeof(v_config) <> 'object' THEN RETURN NEW; END IF;
    IF v_channel = 'email' THEN
      v_channel_config := v_config->'email';
      IF NOT coalesce((
        (v_channel_config->>'enabled' = 'true' AND v_channel_config->>'status' IN ('active', 'synced')
         AND (nullif(v_channel_config->>'email', '') IS NOT NULL
              OR nullif(v_channel_config->'aliases', 'null'::jsonb) IS NOT NULL))
        OR (v_config->'agent'->>'enabled' = 'true' AND v_config->'agent'->>'status' = 'active')
        OR (coalesce(v_config->'agent_mail'->>'enabled', v_config->'agent_email'->>'enabled', 'true') <> 'false'
            AND coalesce(v_config->'agent_mail'->>'status', v_config->'agent_email'->>'status') IN ('active', 'synced'))
      ), false) THEN RETURN NEW; END IF;
    ELSE
      v_channel_config := coalesce(v_config->'whatsapp', v_config->'agent_whatsapp');
      IF NOT coalesce(
        v_channel_config->>'enabled' IS DISTINCT FROM 'false'
        AND v_channel_config->>'status' = 'active'
        AND coalesce(v_channel_config->>'phone_number', v_channel_config->>'existingNumber',
                     v_channel_config->>'number', v_channel_config->>'phone') IS NOT NULL,
        false
      ) THEN RETURN NEW; END IF;
    END IF;

    -- Stable provider messages can be ingested more than once under different
    -- local message IDs. UUIDv5 deduplicates those deliveries without storing
    -- the raw provider identifier in a public health table.
    v_source_id := NEW.id;
    IF v_direction = 'inbound' AND NEW.custom_data->>'origin_message_id' IS NOT NULL THEN
      v_source_id := extensions.uuid_generate_v5(
        '8fb3f7a7-d174-4643-9ad7-cc0d73dba845'::uuid,
        v_site::text || ':' || v_channel || ':' || (NEW.custom_data->>'origin_message_id')
      );
    END IF;
    PERFORM public.record_channel_health_event(v_site, v_channel, v_direction,
      v_source_id, v_outcome, v_class);
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: patch_agent_requirement_plan(uuid, text, integer, uuid, uuid, text, jsonb, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.patch_agent_requirement_plan(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_title text, p_steps jsonb, p_expected_backlog_revision bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  r public.requirements%ROWTYPE; p public.instance_plans%ROWTYPE; i uuid;
  entry jsonb; current_step jsonb; updated_steps jsonb; sid text; item_id text;
  n integer; revision bigint; created boolean:=false;
BEGIN
  IF p_title IS NULL OR length(btrim(p_title)) NOT BETWEEN 1 AND 300
    OR jsonb_typeof(p_steps) IS DISTINCT FROM 'array' OR jsonb_array_length(p_steps)>40
    OR octet_length(p_steps::text)>200000 OR p_expected_backlog_revision IS NULL OR p_expected_backlog_revision<0
  THEN RAISE EXCEPTION 'Invalid requirement plan patch' USING ERRCODE='22023'; END IF;
  IF NOT public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id) THEN
    RETURN jsonb_build_object('state','stale'); END IF;
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id FOR UPDATE;
  revision:=coalesce(r.backlog_revision,0);
  IF revision<>p_expected_backlog_revision THEN
    RETURN jsonb_build_object('state','revision_conflict','backlog_revision',revision); END IF;
  SELECT id INTO i FROM public.remote_instances
    WHERE id::text=r.metadata->>'runner_instance_id' AND site_id=r.site_id FOR UPDATE;
  IF i IS NULL THEN RETURN jsonb_build_object('state','stale'); END IF;
  -- Serialize per runner and respect the existing single-active-plan index. A
  -- seed request never replaces, cancels, or resumes another active/paused plan.
  IF p_plan_id IS NULL THEN
    SELECT * INTO p FROM public.instance_plans WHERE instance_id=i
      AND status IN ('pending','in_progress','active','paused') ORDER BY id LIMIT 1 FOR UPDATE;
    IF FOUND THEN
      IF p.site_id<>r.site_id OR p.status='paused' OR p.metadata->>'requirement_id' IS DISTINCT FROM r.id::text
        OR coalesce(p.metadata->>'workflow_template','false')='true'
      THEN RETURN jsonb_build_object('state','stale'); END IF;
    ELSE
      p.id:=gen_random_uuid(); p.steps:='[]'::jsonb; created:=true;
    END IF;
  ELSE
    SELECT * INTO p FROM public.instance_plans WHERE id=p_plan_id AND site_id=r.site_id AND instance_id=i FOR UPDATE;
    IF NOT FOUND OR p.status='paused' OR coalesce(p.metadata->>'workflow_template','false')='true'
      OR (p.metadata->>'requirement_id' IS NOT NULL AND p.metadata->>'requirement_id'<>r.id::text)
    THEN RETURN jsonb_build_object('state','stale'); END IF;
    -- Instance-only legacy plans are accepted only when every existing step
    -- links unambiguously to this backlog; never rewrite another task's plan.
    IF p.metadata->>'requirement_id' IS NULL AND (
      jsonb_typeof(p.steps) IS DISTINCT FROM 'array' OR jsonb_array_length(p.steps)=0
      OR EXISTS (SELECT 1 FROM jsonb_array_elements(p.steps) s WHERE
        NOT EXISTS (SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(r.backlog->'items')='array' THEN r.backlog->'items' ELSE '[]' END) b
          WHERE b->>'id'=coalesce(s#>>'{metadata,backlog_item_id}',s->>'backlog_item_id')))
    ) THEN RETURN jsonb_build_object('state','stale'); END IF;
  END IF;
  IF jsonb_typeof(p.steps) IS DISTINCT FROM 'array' THEN RETURN jsonb_build_object('state','stale'); END IF;
  IF EXISTS (SELECT 1 FROM jsonb_array_elements(p_steps) s WHERE s->>'id' IS NOT NULL GROUP BY s->>'id' HAVING count(*)>1) THEN
    RAISE EXCEPTION 'Duplicate plan step IDs' USING ERRCODE='22023'; END IF;
  updated_steps:=p.steps;
  FOR entry IN SELECT value FROM jsonb_array_elements(p_steps) LOOP
    IF jsonb_typeof(entry) IS DISTINCT FROM 'object' OR jsonb_typeof(entry->'title') IS DISTINCT FROM 'string'
      OR length(btrim(entry->>'title')) NOT BETWEEN 1 AND 300
      OR (entry ? 'description' AND (jsonb_typeof(entry->'description') IS DISTINCT FROM 'string' OR length(entry->>'description')>4000))
      OR EXISTS (SELECT 1 FROM jsonb_object_keys(entry) k WHERE k NOT IN ('id','title','description','metadata'))
      OR (entry ? 'metadata' AND (jsonb_typeof(entry->'metadata') IS DISTINCT FROM 'object'
        OR EXISTS (SELECT 1 FROM jsonb_object_keys(entry->'metadata') k WHERE k<>'backlog_item_id')))
    THEN RAISE EXCEPTION 'Invalid plan step' USING ERRCODE='22023'; END IF;
    sid:=entry->>'id'; item_id:=entry#>>'{metadata,backlog_item_id}';
    IF (entry ? 'id' AND (jsonb_typeof(entry->'id') IS DISTINCT FROM 'string' OR sid !~ '^[A-Za-z0-9][A-Za-z0-9_.:-]{0,199}$'))
      OR (entry->'metadata' ? 'backlog_item_id' AND (jsonb_typeof(entry#>'{metadata,backlog_item_id}') IS DISTINCT FROM 'string'
        OR item_id !~ '^[A-Za-z0-9][A-Za-z0-9_.:-]{0,199}$'))
    THEN RAISE EXCEPTION 'Invalid plan step identifier' USING ERRCODE='22023'; END IF;
    IF item_id IS NOT NULL THEN
      SELECT count(*) INTO n FROM jsonb_array_elements(CASE WHEN jsonb_typeof(r.backlog->'items')='array' THEN r.backlog->'items' ELSE '[]' END) b WHERE b->>'id'=item_id;
      IF n<>1 THEN RETURN jsonb_build_object('state','not_found'); END IF;
    END IF;
    sid:=coalesce(sid,gen_random_uuid()::text);
    SELECT count(*) INTO n FROM jsonb_array_elements(updated_steps) s WHERE s->>'id'=sid;
    IF n>1 THEN RETURN jsonb_build_object('state','stale'); END IF;
    IF n=1 THEN
      SELECT value INTO current_step FROM jsonb_array_elements(updated_steps) WHERE value->>'id'=sid;
      IF coalesce(current_step#>>'{metadata,backlog_item_id}',current_step->>'backlog_item_id') IS NOT NULL THEN
        SELECT count(*) INTO n FROM jsonb_array_elements(CASE WHEN jsonb_typeof(r.backlog->'items')='array' THEN r.backlog->'items' ELSE '[]' END) b
          WHERE b->>'id'=coalesce(current_step#>>'{metadata,backlog_item_id}',current_step->>'backlog_item_id');
        IF n<>1 THEN RETURN jsonb_build_object('state','not_found'); END IF;
      END IF;
      -- Description updates cannot resume a manually paused step or silently
      -- relink it to another task. Preserve status, acceptance and legacy keys.
      IF current_step->>'status'='paused' OR (item_id IS NOT NULL AND
        coalesce(current_step#>>'{metadata,backlog_item_id}',current_step->>'backlog_item_id',item_id)<>item_id)
      THEN RETURN jsonb_build_object('state','stale'); END IF;
      current_step:=current_step||jsonb_build_object('title',entry->>'title');
      IF entry ? 'description' THEN current_step:=current_step||jsonb_build_object('description',entry->>'description'); END IF;
      IF item_id IS NOT NULL THEN current_step:=jsonb_set(current_step,'{metadata}',coalesce(current_step->'metadata','{}')||jsonb_build_object('backlog_item_id',item_id)); END IF;
      SELECT jsonb_agg(CASE WHEN value->>'id'=sid THEN current_step ELSE value END ORDER BY ord)
        INTO updated_steps FROM jsonb_array_elements(updated_steps) WITH ORDINALITY a(value,ord);
    ELSE
      updated_steps:=updated_steps||jsonb_build_array((entry-'metadata')||jsonb_build_object('id',sid,'status','pending')||
        CASE WHEN item_id IS NULL THEN '{}'::jsonb ELSE jsonb_build_object('metadata',jsonb_build_object('backlog_item_id',item_id)) END);
    END IF;
  END LOOP;
  IF created THEN
    INSERT INTO public.instance_plans(id,instance_id,site_id,user_id,title,plan_type,status,steps,metadata,steps_total,steps_completed)
      VALUES(p.id,i,r.site_id,r.user_id,btrim(p_title),'task','pending',updated_steps,
        jsonb_build_object('requirement_id',r.id,'agent_run_id',p_run_id,'harness_session_id',p_session_id),jsonb_array_length(updated_steps),0);
  ELSE
    UPDATE public.instance_plans SET title=btrim(p_title),steps=updated_steps,steps_total=jsonb_array_length(updated_steps),updated_at=clock_timestamp()
      WHERE id=p.id;
  END IF;
  UPDATE public.requirements SET backlog_revision=revision+1 WHERE id=r.id RETURNING backlog_revision INTO revision;
  RETURN jsonb_build_object('state',CASE WHEN created THEN 'created' ELSE 'updated' END,'plan_id',p.id,'backlog_revision',revision);
EXCEPTION WHEN unique_violation THEN
  -- Whole function block rolls back; another writer may have seeded a plan.
  RETURN jsonb_build_object('state','revision_conflict');
END;
$_$;


--
-- Name: patch_agent_requirement_progress(uuid, text, integer, uuid, uuid, text, text, text, text, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.patch_agent_requirement_progress(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_step_id text, p_item_id text, p_status text, p_message text, p_expected_backlog_revision bigint DEFAULT NULL::bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  r public.requirements%ROWTYPE; p public.instance_plans%ROWTYPE; entries jsonb; n integer; revision bigint;
  step_status text; item_status text; current_step jsonb; current_item jsonb;
  status_changed boolean:=false; message_recorded boolean:=false;
  plan_steps_total bigint; plan_steps_completed bigint; backlog_items_total bigint; backlog_items_completed bigint;
BEGIN
  step_status:=CASE WHEN p_status='done' THEN 'completed' ELSE p_status END;
  item_status:=CASE WHEN p_status='completed' THEN 'done' ELSE p_status END;
  IF length(p_message)>20000 OR length(p_step_id)>200 OR length(p_item_id)>200
    OR (p_step_id IS NOT NULL AND p_plan_id IS NULL)
    OR (p_status IS NOT NULL AND p_status NOT IN ('pending','in_progress','completed','done','failed'))
    OR (p_status IS NOT NULL AND p_plan_id IS NULL AND p_item_id IS NULL)
    OR (p_status IS NULL AND nullif(p_message,'') IS NULL)
  THEN RAISE EXCEPTION 'Invalid agent progress patch' USING ERRCODE='22023'; END IF;
  -- Preserve the existing ownership/pause assertion and its lease renewal.
  IF NOT public.assert_agent_requirement_run(p_requirement_id,p_run_id,p_generation,p_session_id) THEN
    RETURN jsonb_build_object('state','stale'); END IF;
  SELECT * INTO r FROM public.requirements WHERE id=p_requirement_id FOR UPDATE;
  revision:=coalesce(r.backlog_revision,0);
  IF p_expected_backlog_revision IS NOT NULL AND p_expected_backlog_revision<>revision THEN
    RETURN jsonb_build_object('state','revision_conflict','backlog_revision',revision); END IF;
  IF p_plan_id IS NOT NULL THEN
    SELECT * INTO p FROM public.instance_plans WHERE id=p_plan_id AND site_id=r.site_id
      AND instance_id::text=r.metadata->>'runner_instance_id' FOR UPDATE;
    IF NOT FOUND OR p.status='paused' OR (p.metadata->>'requirement_id' IS NOT NULL AND p.metadata->>'requirement_id'<>r.id::text) THEN
      RETURN jsonb_build_object('state','stale'); END IF;
  END IF;
  -- Validate both status targets before writing either. Message-only calls keep
  -- the original permissive target semantics, with absent receipt targets null.
  IF p_step_id IS NOT NULL THEN
    SELECT count(*) INTO n FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.steps)='array' THEN p.steps ELSE '[]'::jsonb END) e WHERE e->>'id'=p_step_id;
    IF n<>1 AND p_status IS NOT NULL THEN RETURN jsonb_build_object('state','not_found'); END IF;
    IF n=1 THEN SELECT e INTO current_step FROM jsonb_array_elements(p.steps) e WHERE e->>'id'=p_step_id; END IF;
  END IF;
  IF p_item_id IS NOT NULL THEN
    SELECT count(*) INTO n FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(r.backlog->'items')='array' THEN r.backlog->'items' ELSE '[]'::jsonb END) e WHERE e->>'id'=p_item_id;
    IF n<>1 AND p_status IS NOT NULL THEN RETURN jsonb_build_object('state','not_found'); END IF;
    IF n=1 THEN SELECT e INTO current_item FROM jsonb_array_elements(r.backlog->'items') e WHERE e->>'id'=p_item_id; END IF;
  END IF;
  -- Compare the canonical requested status under the row locks. No progress
  -- rewrite, timestamp change, or revision bump for an already-current status.
  IF p_plan_id IS NOT NULL AND p_step_id IS NULL AND p_status IS NOT NULL AND p.status IS DISTINCT FROM step_status THEN
    UPDATE public.instance_plans SET status=step_status,updated_at=clock_timestamp() WHERE id=p.id RETURNING * INTO p;
    status_changed:=true;
  END IF;
  IF p_step_id IS NOT NULL AND p_status IS NOT NULL AND current_step->>'status' IS DISTINCT FROM step_status THEN
    SELECT jsonb_agg(CASE WHEN e->>'id'=p_step_id THEN e||jsonb_build_object('status',step_status) ELSE e END ORDER BY ord)
      INTO entries FROM jsonb_array_elements(p.steps) WITH ORDINALITY a(e,ord);
    UPDATE public.instance_plans SET steps=entries,updated_at=clock_timestamp() WHERE id=p.id RETURNING * INTO p;
    current_step:=current_step||jsonb_build_object('status',step_status);
    status_changed:=true;
  END IF;
  IF p_item_id IS NOT NULL AND p_status IS NOT NULL AND current_item->>'status' IS DISTINCT FROM item_status THEN
    SELECT jsonb_agg(CASE WHEN e->>'id'=p_item_id THEN e||jsonb_build_object('status',item_status) ELSE e END ORDER BY ord)
      INTO entries FROM jsonb_array_elements(r.backlog->'items') WITH ORDINALITY a(e,ord);
    UPDATE public.requirements SET backlog=jsonb_set(backlog,'{items}',entries),backlog_revision=revision+1
      WHERE id=r.id RETURNING * INTO r;
    revision:=r.backlog_revision;
    current_item:=current_item||jsonb_build_object('status',item_status);
    status_changed:=true;
  END IF;
  IF nullif(p_message,'') IS NOT NULL THEN
    INSERT INTO public.requirement_status(requirement_id,site_id,instance_id,stage,message)
      VALUES(r.id,r.site_id,(r.metadata->>'runner_instance_id')::uuid,'in-progress',p_message);
    message_recorded:=true;
  END IF;
  -- Full-array counts, not cached columns or a bounded context preview. Neither
  -- these counts nor completing the last step changes the plan status.
  SELECT count(*),count(*) FILTER (WHERE e->>'status' IN ('done','completed')) INTO plan_steps_total,plan_steps_completed
    FROM jsonb_array_elements(CASE WHEN jsonb_typeof(p.steps)='array' THEN p.steps ELSE '[]'::jsonb END) e;
  SELECT count(*),count(*) FILTER (WHERE e->>'status' IN ('done','completed')) INTO backlog_items_total,backlog_items_completed
    FROM jsonb_array_elements(CASE WHEN jsonb_typeof(r.backlog->'items')='array' THEN r.backlog->'items' ELSE '[]'::jsonb END) e;
  RETURN jsonb_build_object(
    'state',CASE WHEN status_changed THEN 'updated' ELSE 'unchanged' END,
    'status_changed',status_changed,'message_recorded',message_recorded,'backlog_revision',revision,
    'plan_id',p.id,'plan_status',p.status,'step_id',current_step->>'id','step_status',current_step->>'status',
    'item_id',current_item->>'id','item_status',current_item->>'status',
    'plan_steps_total',plan_steps_total,'plan_steps_completed',plan_steps_completed,
    'backlog_items_total',backlog_items_total,'backlog_items_completed',backlog_items_completed);
END;
$$;


--
-- Name: patch_instance_plan_step_atomic(uuid, text, integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.patch_instance_plan_step_atomic(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_event_id text, p_patch jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
DECLARE
  v_steps jsonb;
  v_step jsonb;
  v_step_index integer;
  v_generation integer;
  v_event_generation integer;
  v_next_status text;
  v_safe_patch jsonb;
BEGIN
  IF NULLIF(btrim(p_event_id), '') IS NULL
    OR jsonb_typeof(p_patch) <> 'object'
  THEN
    RAISE EXCEPTION 'Event id and object patch are required';
  END IF;

  SELECT CASE WHEN jsonb_typeof(steps) = 'array'
    THEN steps ELSE '[]'::jsonb END
  INTO v_steps
  FROM public.instance_plans
  WHERE id = p_plan_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'missing', 'persisted', false);
  END IF;

  SELECT entry.value, (entry.ordinality - 1)::integer
  INTO v_step, v_step_index
  FROM jsonb_array_elements(v_steps)
    WITH ORDINALITY AS entry(value, ordinality)
  WHERE entry.value->>'id' = p_step_id
  LIMIT 1;
  IF v_step IS NULL THEN
    RETURN jsonb_build_object('state', 'missing', 'persisted', false);
  END IF;

  v_generation := CASE
    WHEN COALESCE(v_step->>'infrastructure_generation', '') ~ '^[0-9]{1,9}$'
      THEN (v_step->>'infrastructure_generation')::integer
    ELSE 0
  END;
  SELECT CASE
    WHEN COALESCE(details->>'generation', '') ~ '^[0-9]{1,9}$'
      THEN (details->>'generation')::integer
    ELSE 0
  END
  INTO v_event_generation
  FROM public.instance_plan_step_infrastructure_events
  WHERE plan_id = p_plan_id
    AND step_id = p_step_id
    AND event_id = p_event_id;
  IF FOUND THEN
    IF v_event_generation IS NOT DISTINCT FROM v_generation
      AND v_event_generation::bigint IS NOT DISTINCT FROM
        p_expected_generation::bigint + 1
    THEN
      RETURN jsonb_build_object(
        'state', 'duplicate', 'persisted', true,
        'generation', v_event_generation
      );
    END IF;
    RETURN jsonb_build_object(
      'state', 'stale', 'persisted', false, 'generation', v_generation
    );
  END IF;
  IF v_generation IS DISTINCT FROM p_expected_generation THEN
    RETURN jsonb_build_object(
      'state', 'stale', 'persisted', false, 'generation', v_generation
    );
  END IF;

  v_next_status := p_patch->>'status';
  IF v_step->>'status' IN ('completed', 'cancelled')
    AND COALESCE(v_next_status, v_step->>'status') <> v_step->>'status'
  THEN
    RETURN jsonb_build_object(
      'state', 'terminal', 'persisted', false, 'generation', v_generation
    );
  END IF;

  v_safe_patch := p_patch
    - ARRAY['id', 'order', 'infrastructure_generation'];
  v_step := v_step || v_safe_patch || jsonb_build_object(
    'infrastructure_generation', v_generation + 1,
    'infrastructure_last_event_id', p_event_id
  );
  v_steps := jsonb_set(
    v_steps, ARRAY[v_step_index::text], v_step, false
  );
  UPDATE public.instance_plans
  SET steps = v_steps, updated_at = timezone('utc', now())
  WHERE id = p_plan_id;

  INSERT INTO public.instance_plan_step_infrastructure_events (
    plan_id, step_id, event_id, event_type, details
  ) VALUES (
    p_plan_id, p_step_id, p_event_id, 'step_patch',
    jsonb_build_object('generation', v_generation + 1)
  );
  RETURN jsonb_build_object(
    'state', 'applied', 'persisted', true,
    'generation', v_generation + 1
  );
END;
$_$;


--
-- Name: patch_requirement_metadata_keys(uuid, jsonb, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.patch_requirement_metadata_keys(p_requirement_id uuid, p_patch jsonb DEFAULT '{}'::jsonb, p_remove_keys text[] DEFAULT '{}'::text[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_metadata jsonb;
BEGIN
  UPDATE public.requirements
  SET
    metadata =
      (
        CASE
          WHEN jsonb_typeof(metadata) = 'object' THEN metadata
          ELSE '{}'::jsonb
        END
        - COALESCE(p_remove_keys, '{}'::text[])
      )
      || CASE
        WHEN jsonb_typeof(p_patch) = 'object' THEN p_patch
        ELSE '{}'::jsonb
      END,
    updated_at = timezone('utc', now())
  WHERE id = p_requirement_id
  RETURNING metadata INTO v_metadata;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Requirement % not found', p_requirement_id;
  END IF;

  RETURN v_metadata;
END;
$$;

SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: dispatch_workflow_database_webhook(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dispatch_workflow_database_webhook() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  webhook_url text;
  webhook_api_key text;
  webhook_headers jsonb;
  webhook_payload jsonb;
BEGIN
  SELECT secret.decrypted_secret
  INTO webhook_url
  FROM vault.decrypted_secrets AS secret
  WHERE secret.name = 'workflow_webhook_url'
  LIMIT 1;

  SELECT secret.decrypted_secret
  INTO webhook_api_key
  FROM vault.decrypted_secrets AS secret
  WHERE secret.name = 'workflow_webhook_api_key'
  LIMIT 1;

  IF webhook_url IS NULL OR btrim(webhook_url) = '' THEN
    RAISE WARNING
      'Skipping workflow webhook for %.% because workflow_webhook_url is not configured in Vault',
      TG_TABLE_SCHEMA,
      TG_TABLE_NAME;
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    RETURN NEW;
  END IF;

  -- QA bootstrap must never dispatch to external or production destinations.
  IF webhook_url !~ '^http://(127[.]0[.]0[.]1|localhost|host[.]docker[.]internal):[0-9]+/' THEN
    RAISE WARNING 'QA workflow webhook rejected: non-local destination';
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
  END IF;

  webhook_headers := jsonb_build_object('Content-Type', 'application/json');
  IF webhook_api_key IS NOT NULL AND btrim(webhook_api_key) <> '' THEN
    webhook_headers := webhook_headers
      || jsonb_build_object('x-api-key', webhook_api_key);
  END IF;

  webhook_payload := jsonb_build_object(
    'type', TG_OP,
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'record', CASE
      WHEN TG_OP = 'DELETE' THEN 'null'::jsonb
      ELSE to_jsonb(NEW)
    END,
    'old_record', CASE
      WHEN TG_OP = 'INSERT' THEN 'null'::jsonb
      ELSE to_jsonb(OLD)
    END
  );

  PERFORM net.http_post(
    url := webhook_url,
    body := webhook_payload,
    params := '{}'::jsonb,
    headers := webhook_headers,
    timeout_milliseconds := 5000
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING
      'Could not enqueue workflow webhook for %.%: %',
      TG_TABLE_SCHEMA,
      TG_TABLE_NAME,
      SQLERRM;
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: effective_site_plan(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.effective_site_plan(p_site_id uuid) RETURNS text
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    SET row_security TO 'off'
    AS $$
DECLARE b public.billing%ROWTYPE; v_now timestamptz := clock_timestamp();
BEGIN
  SELECT * INTO b FROM public.billing WHERE site_id = p_site_id;
  IF NOT FOUND THEN RETURN 'commission'; END IF;
  IF b.status IS DISTINCT FROM 'active' OR NOT EXISTS (
    SELECT 1 FROM public.sites WHERE id=p_site_id AND archived_at IS NULL
  ) THEN RETURN 'commission'; END IF;
  IF b.plan IN ('engine','foundry','enterprise') AND (
    b.stripe_subscription_id IS NULL OR (
      b.paid_subscription_invoice_id IS NOT NULL AND b.paid_subscription_period_start <= v_now
      AND b.paid_subscription_period_end > v_now
      AND lower(coalesce(b.subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired'))
  ) THEN RETURN b.plan; END IF;
  IF b.trial_started_at <= v_now AND b.trial_ends_at > v_now AND EXISTS (
    SELECT 1 FROM public.site_startup_trials t WHERE t.site_id = p_site_id
      AND t.started_at = b.trial_started_at AND t.ends_at = b.trial_ends_at AND t.converted_at IS NULL
  ) THEN RETURN 'foundry'; END IF;
  RETURN 'commission';
END;
$$;


--
-- Name: encrypt_token(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.encrypt_token(token_value text, encryption_key text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$BEGIN PERFORM public.location_acl_assert_unscoped_rpc(); RETURN location_acl_private.original_16713($1,$2); END$_$;


--
-- Name: enforce_requirement_review_quarantine(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_requirement_review_quarantine() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE old_item jsonb; new_item jsonb; action_created_at timestamptz; agent_owned boolean;
BEGIN
  IF NEW.backlog IS NOT DISTINCT FROM OLD.backlog THEN RETURN NEW; END IF;
  agent_owned:=false;
  IF NEW.cron_lock_active IS TRUE AND NEW.cron_lock_run_id=OLD.cron_lock_run_id
    AND NEW.cron_lock_expires_at>clock_timestamp() AND NEW.status='in-progress'
    AND NEW.metadata IS NOT DISTINCT FROM OLD.metadata
    AND EXISTS (SELECT 1 FROM public.harness_requirement_runs h JOIN public.harness_sessions s ON s.id=h.session_id
      WHERE h.requirement_id=NEW.id AND h.site_id=NEW.site_id AND s.site_id=NEW.site_id AND s.user_id=NEW.user_id
        AND h.generation::text=NEW.metadata->>'requirement_execution_generation'
        AND s.snapshot->>'status' IN ('queued','running')) THEN
    agent_owned:=public.agent_requirement_runner_allowed(NEW.id,(NEW.metadata->>'runner_instance_id')::uuid);
  END IF;
  FOR old_item IN SELECT value FROM jsonb_array_elements(CASE WHEN jsonb_typeof(OLD.backlog->'items')='array'
    THEN OLD.backlog->'items' ELSE '[]'::jsonb END)
    WHERE value->>'status'='needs_review' OR coalesce(value#>>'{review_quarantine,active}','false')='true'
  LOOP
    SELECT value INTO new_item FROM jsonb_array_elements(CASE WHEN jsonb_typeof(NEW.backlog->'items')='array'
      THEN NEW.backlog->'items' ELSE '[]'::jsonb END) WHERE value->>'id'=old_item->>'id' LIMIT 1;
    IF agent_owned AND new_item-'status'=old_item-'status'
      AND new_item->>'status' IN ('pending','in_progress','done','failed') THEN CONTINUE; END IF;
    IF new_item IS NULL OR new_item->>'status'<>'needs_review' OR coalesce(new_item#>>'{review_quarantine,active}','false')<>'true' THEN
      IF NEW.external_user_action_revision<>OLD.external_user_action_revision+1 OR nullif(NEW.last_external_user_action_id,'') IS NULL
        OR new_item IS NULL OR new_item#>>'{review_quarantine,released_by_action_id}' IS DISTINCT FROM NEW.last_external_user_action_id THEN
        RAISE EXCEPTION 'Backlog item % is quarantined; a trusted newer user action must release it',old_item->>'id';
      END IF;
      SELECT log.created_at INTO action_created_at FROM public.instance_logs log
        WHERE log.id::text=NEW.last_external_user_action_id AND log.log_type='user_action' AND log.trusted_user_action=true
          AND log.details->>'requirement_id'=NEW.id::text LIMIT 1;
      IF action_created_at IS NULL OR action_created_at<=public.requirement_quarantine_timestamp(old_item) THEN
        RAISE EXCEPTION 'Backlog item % quarantine predates no trusted user action',old_item->>'id';
      END IF;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$$;


--
-- Name: enforce_settings_license(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_settings_license() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  plan_name text; addons integer; social_limit integer; agent_limit integer; max_order bigint := 0;
  all_items jsonb := '[]'; social_result jsonb := '[]'; agent_result jsonb := '[]';
  old_items jsonb; new_items jsonb; item jsonb; previous jsonb; marker jsonb; identity text;
  category text; entry jsonb; active boolean; social_used integer := 0; agent_used integer := 0;
  keep boolean; seen text[] := '{}'; seen_orders bigint[] := '{}'; old_count integer; occurrence integer;
  item_position bigint; unchanged boolean;
BEGIN
  PERFORM public.lock_site_license(NEW.site_id);
  SELECT public.effective_site_plan(NEW.site_id),CASE WHEN stripe_subscription_id IS NULL OR (
    paid_subscription_invoice_id IS NOT NULL AND paid_subscription_period_start <= clock_timestamp()
    AND paid_subscription_period_end > clock_timestamp()
    AND lower(coalesce(subscription_status,'')) NOT IN ('canceled','cancelled','incomplete_expired'))
    THEN greatest(coalesce(addons_count,0),0) ELSE 0 END INTO plan_name,addons FROM public.billing WHERE site_id = NEW.site_id;
  addons := coalesce(addons,0);
  social_limit := CASE plan_name WHEN 'engine' THEN 3 WHEN 'foundry' THEN 6 WHEN 'enterprise' THEN 10 ELSE 1 END;
  agent_limit := CASE plan_name WHEN 'engine' THEN 1 WHEN 'foundry' THEN 3 WHEN 'enterprise' THEN 10 ELSE 0 END;
  IF TG_OP = 'UPDATE' THEN
    SELECT coalesce(max((value->'_license'->>'order')::bigint),0) INTO max_order FROM jsonb_array_elements(
      coalesce(nullif(OLD.social_media,'null'::jsonb),'[]') || coalesce(nullif(OLD.channels->'connections','null'::jsonb),'[]'));
  END IF;
  FOREACH category IN ARRAY ARRAY['social','agent'] LOOP
    new_items := CASE WHEN category = 'social' THEN NEW.social_media ELSE NEW.channels->'connections' END;
    old_items := CASE WHEN TG_OP = 'INSERT' THEN '[]'::jsonb WHEN category = 'social' THEN OLD.social_media ELSE OLD.channels->'connections' END;
    IF new_items IS NULL OR new_items = 'null'::jsonb THEN CONTINUE; END IF;
    IF jsonb_typeof(new_items) <> 'array' THEN RAISE EXCEPTION 'Resource connections must be arrays'; END IF;
    old_items := coalesce(nullif(old_items,'null'::jsonb),'[]');
    SELECT (SELECT coalesce(jsonb_agg(value - '_license' - 'license_suspended' ORDER BY ordinality),'[]')
      FROM jsonb_array_elements(new_items) WITH ORDINALITY) =
      (SELECT coalesce(jsonb_agg(value - '_license' - 'license_suspended' ORDER BY ordinality),'[]')
      FROM jsonb_array_elements(old_items) WITH ORDINALITY) INTO unchanged;
    FOR item,item_position IN SELECT value,ordinality FROM jsonb_array_elements(new_items) WITH ORDINALITY LOOP
      IF jsonb_typeof(item) <> 'object' THEN RAISE EXCEPTION 'Resource connections must be objects'; END IF;
      identity := category || ':' || public.license_resource_identity(item);
      SELECT count(*) INTO old_count FROM jsonb_array_elements(old_items)
        WHERE public.license_resource_identity(value) = public.license_resource_identity(item);
      SELECT 1 + count(*) INTO occurrence FROM unnest(seen) AS existing(key) WHERE key = identity;
      -- Grandfather only stored duplicates; each occurrence still consumes capacity.
      IF occurrence > greatest(1,old_count) THEN RAISE EXCEPTION 'Duplicate resource identity'; END IF;
      seen := array_append(seen,identity);
      IF old_count > 1 AND NOT coalesce(item->'_license' ? 'order',false) AND NOT unchanged THEN
        RAISE EXCEPTION 'Legacy duplicate resources require stored license metadata';
      END IF;
      -- Match duplicate rows by their trusted stored order. Only unchanged arrays
      -- may omit metadata, including the first backfill before orders exist.
      SELECT value INTO previous FROM jsonb_array_elements(old_items) WITH ORDINALITY
        WHERE public.license_resource_identity(value) = public.license_resource_identity(item)
          AND (old_count <= 1 OR CASE WHEN item->'_license' ? 'order'
            THEN value->'_license'->'order' = item->'_license'->'order' ELSE ordinality = item_position END)
        ORDER BY ordinality LIMIT 1;
      IF old_count > 1 AND previous IS NULL THEN
        RAISE EXCEPTION 'Legacy duplicate resources require stored license metadata';
      END IF;
      -- Order is always inherited from stored state; even provider writes cannot reorder age.
      marker := coalesce(item->'_license',previous->'_license','{}');
      IF category='agent' AND NOT EXISTS (
        SELECT 1 FROM public.agent_channel_activation_context c
        WHERE c.transaction_id=txid_current() AND c.site_id=NEW.site_id AND c.connection_id=item->>'id'
      ) THEN
        marker := marker - 'manually_disabled' - 'manualPreviousStatus' - 'manualPreviousEnabled';
        IF previous->'_license' ? 'manually_disabled' THEN
          marker := marker || jsonb_build_object('manually_disabled',previous->'_license'->'manually_disabled');
        END IF;
        IF previous->'_license' ? 'manualPreviousStatus' THEN
          marker := marker || jsonb_build_object('manualPreviousStatus',previous->'_license'->'manualPreviousStatus');
        END IF;
        IF previous->'_license' ? 'manualPreviousEnabled' THEN
          marker := marker || jsonb_build_object('manualPreviousEnabled',previous->'_license'->'manualPreviousEnabled');
        END IF;
      END IF;
      IF previous->'_license' ? 'order' THEN marker := marker || jsonb_build_object('order',previous->'_license'->'order');
      ELSE max_order := max_order + 1; marker := marker || jsonb_build_object('order',max_order); END IF;
      IF (marker->>'order')::bigint = ANY(seen_orders) THEN RAISE EXCEPTION 'Duplicate resource license order'; END IF;
      seen_orders := array_append(seen_orders,(marker->>'order')::bigint);
      IF category = 'social' THEN
        active := item->'isActive' IN ('true'::jsonb,'1'::jsonb) OR coalesce((marker->>'suspended')::boolean,false);
      ELSE
        -- A manual non-license disconnect cancels restoration; never reconnect it later.
        IF coalesce(marker->'manually_disabled'='true'::jsonb,false) THEN
          item := item || '{"status":"disabled","enabled":false}'::jsonb;
          marker := marker - 'suspended' - 'previousStatus';
          active := false;
        ELSE
          IF NOT (item->>'status' IN ('connected','license_suspended') OR
            (item->>'type'='voice' AND item->>'status' IN ('active','synced'))) THEN
            marker := marker - 'suspended' - 'previousStatus';
          END IF;
          active := item->'enabled' IS DISTINCT FROM 'false'::jsonb AND (
            item->>'status'='connected' OR (item->>'type'='voice' AND item->>'status' IN ('active','synced'))
            OR coalesce((marker->>'suspended')::boolean,false));
        END IF;
      END IF;
      all_items := all_items || jsonb_build_array(jsonb_build_object('category',category,'item',item,'marker',marker,'active',coalesce(active,false)));
    END LOOP;
  END LOOP;
  -- Base quotas are independent; excesses compete for ONE pool by immutable addition order.
  FOR entry IN SELECT value FROM jsonb_array_elements(all_items) ORDER BY (value->'marker'->>'order')::bigint LOOP
    item := entry->'item'; marker := entry->'marker'; category := entry->>'category'; active := (entry->>'active')::boolean;
    keep := false;
    IF active THEN
      IF category = 'social' AND social_used < social_limit THEN social_used := social_used + 1; keep := true;
      ELSIF category = 'agent' AND agent_used < agent_limit THEN agent_used := agent_used + 1; keep := true;
      ELSIF addons > 0 THEN addons := addons - 1; keep := true; END IF;
    END IF;
    IF active AND NOT keep THEN
      IF NOT coalesce((marker->>'suspended')::boolean,false) THEN
        marker := marker || CASE WHEN category = 'social' THEN jsonb_build_object('previousIsActive',item->'isActive')
          ELSE jsonb_build_object('previousStatus',item->'status') END;
      END IF;
      marker := marker || '{"suspended":true}'::jsonb;
      item := item || CASE WHEN category = 'social' THEN '{"isActive":false}'::jsonb ELSE '{"status":"license_suspended"}'::jsonb END;
    ELSE
      IF keep AND coalesce((marker->>'suspended')::boolean,false) THEN
        item := item || CASE WHEN category = 'social' THEN jsonb_build_object('isActive',coalesce(marker->'previousIsActive','true'))
          ELSE jsonb_build_object('status',coalesce(marker->'previousStatus','"connected"')) END;
      END IF;
      marker := marker - 'suspended' - 'previousIsActive' - 'previousStatus';
    END IF;
    item := item || jsonb_build_object('_license',marker,'license_suspended',active AND NOT keep);
    IF category = 'social' THEN social_result := social_result || jsonb_build_array(item);
    ELSE agent_result := agent_result || jsonb_build_array(item); END IF;
  END LOOP;
  IF NEW.social_media IS NOT NULL AND NEW.social_media <> 'null'::jsonb THEN NEW.social_media := social_result; END IF;
  IF NEW.channels ? 'connections' THEN NEW.channels := jsonb_set(NEW.channels,'{connections}',agent_result); END IF;
  -- Legacy/browser writers may send team_members themselves. Always derive the
  -- automation mirror from licensed active membership, never from that payload.
  SELECT coalesce(jsonb_agg(jsonb_build_object('email',sm.email,'role',CASE sm.role
    WHEN 'admin' THEN 'admin' WHEN 'marketing' THEN 'create' ELSE 'view' END,
    'name',coalesce(sm.name,''),'position',coalesce(sm.position,'')) ORDER BY sm.created_at,sm.id),'[]')
    INTO NEW.team_members FROM public.site_members sm WHERE sm.site_id = NEW.site_id
    AND sm.status = 'active' AND sm.role <> 'owner' AND public.site_member_has_effective_license(sm.id);
  RETURN NEW;
END;
$$;


--
-- Name: enforce_voice_call_concurrency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_voice_call_concurrency() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  active_count integer;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(NEW.zavu_sender_id, 0)
  );

  SELECT count(*)
  INTO active_count
  FROM public.voice_call_deliveries
  WHERE zavu_sender_id = NEW.zavu_sender_id
    AND status IN (
      'placing',
      'queued',
      'initiated',
      'ringing',
      'answered',
      'in_progress'
    );

  IF active_count >= 5 THEN
    RAISE EXCEPTION 'VOICE_CALL_CONCURRENCY_LIMIT'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: enqueue_record_embedding_job(uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_job_id uuid;
  v_site_id uuid;
  v_revision bigint;
BEGIN
  SELECT r.site_id, COALESCE(d.revision, 0)
  INTO v_site_id, v_revision
  FROM public.records r
  LEFT JOIN public.record_diagrams d ON d.record_id = r.id
  WHERE r.id = p_record_id;

  IF v_site_id IS NULL THEN
    RAISE EXCEPTION 'Record not found';
  END IF;

  INSERT INTO public.record_embedding_jobs(
    record_id,
    site_id,
    diagram_revision,
    node_ids,
    status,
    attempts,
    last_error,
    claimed_at,
    completed_at,
    updated_at
  )
  VALUES (
    p_record_id,
    v_site_id,
    v_revision,
    COALESCE(p_node_ids, '{}'::uuid[]),
    'pending',
    0,
    NULL,
    NULL,
    NULL,
    now()
  )
  ON CONFLICT (record_id, diagram_revision) DO UPDATE SET
    node_ids = ARRAY(
      SELECT DISTINCT node_id
      FROM unnest(
        record_embedding_jobs.node_ids || EXCLUDED.node_ids
      ) AS node_id
    ),
    status = 'pending',
    attempts = 0,
    last_error = NULL,
    claimed_at = NULL,
    completed_at = NULL,
    updated_at = now()
  RETURNING id INTO v_job_id;

  RETURN v_job_id;
END;
$$;

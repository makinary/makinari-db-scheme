SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: apps_ensure_tenant(uuid, uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_ensure_tenant(p_requirement_id uuid, p_candidate_tenant_id uuid, p_user_id uuid, p_site_id uuid, p_auth_provider text DEFAULT 'supabase'::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  tenant_row public.apps_tenants%ROWTYPE;
  target_schema text;
  target_bucket text;
  owner_role text;
  was_created boolean := false;
BEGIN
  IF p_requirement_id IS NULL
    OR p_candidate_tenant_id IS NULL
    OR p_user_id IS NULL
    OR p_site_id IS NULL
    OR p_auth_provider NOT IN ('supabase', 'auth0')
  THEN
    RAISE EXCEPTION 'Invalid tenant provisioning payload';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('tenant:' || p_requirement_id::text, 0)
  );

  SELECT *
  INTO tenant_row
  FROM public.apps_tenants
  WHERE requirement_id = p_requirement_id
  FOR UPDATE;

  IF NOT FOUND THEN
    target_schema :=
      'app_' || left(replace(p_requirement_id::text, '-', ''), 24);
    target_bucket :=
      'tenant-' || left(replace(p_requirement_id::text, '-', ''), 24);

    INSERT INTO public.apps_tenants (
      tenant_id,
      requirement_id,
      user_id,
      site_id,
      schema,
      bucket,
      auth_provider,
      status
    )
    VALUES (
      p_candidate_tenant_id,
      p_requirement_id,
      p_user_id,
      p_site_id,
      target_schema,
      target_bucket,
      p_auth_provider,
      'active'
    )
    RETURNING * INTO tenant_row;
    was_created := true;
  END IF;

  IF tenant_row.status <> 'active'
    OR tenant_row.schema !~ '^app_[a-f0-9]{24}$'
    OR tenant_row.bucket IS NULL
  THEN
    RAISE EXCEPTION 'Tenant registry row is not active and valid';
  END IF;

  target_schema := tenant_row.schema;
  target_bucket := tenant_row.bucket;
  owner_role := 'app_owner_' || substring(target_schema FROM 5);

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = owner_role
  ) THEN
    EXECUTE format(
      'CREATE ROLE %I NOLOGIN NOINHERIT NOCREATEDB NOCREATEROLE',
      owner_role
    );
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_roles
    WHERE rolname = owner_role
      AND (rolsuper OR rolreplication OR rolbypassrls)
  ) THEN
    RAISE EXCEPTION
      'Tenant owner role % has unsafe managed role attributes',
      owner_role;
  END IF;
  EXECUTE format(
    'ALTER ROLE %I NOLOGIN NOINHERIT NOCREATEDB NOCREATEROLE',
    owner_role
  );
  -- Ownership changes require the SECURITY DEFINER owner to be able to
  -- assume the constrained tenant role. Do not inherit its privileges.
  EXECUTE format(
    'GRANT %I TO %I WITH INHERIT FALSE, SET TRUE',
    owner_role,
    current_user
  );

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_namespace
    WHERE nspname = target_schema
  ) THEN
    EXECUTE format('CREATE SCHEMA %I', target_schema);
  END IF;

  EXECUTE format(
    'GRANT USAGE ON SCHEMA %I TO anon, authenticated',
    target_schema
  );
  EXECUTE format(
    'GRANT USAGE, CREATE ON SCHEMA %I TO %I',
    target_schema,
    owner_role
  );
  EXECUTE format(
    'GRANT USAGE, CREATE ON SCHEMA %I
     TO apps_migration_coordinator',
    target_schema
  );
  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
     GRANT ALL PRIVILEGES ON TABLES TO anon, authenticated',
    owner_role,
    target_schema
  );
  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
     GRANT ALL PRIVILEGES ON ROUTINES TO anon, authenticated',
    owner_role,
    target_schema
  );
  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
     GRANT ALL PRIVILEGES ON SEQUENCES TO anon, authenticated',
    owner_role,
    target_schema
  );

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS %I._meta (
       key text PRIMARY KEY,
       value jsonb NOT NULL,
       updated_at timestamptz NOT NULL DEFAULT now()
     )',
    target_schema
  );
  EXECUTE format(
    'ALTER TABLE %I._meta ENABLE ROW LEVEL SECURITY',
    target_schema
  );
  EXECUTE format(
    'DROP POLICY IF EXISTS tenant_isolation ON %I._meta',
    target_schema
  );
  EXECUTE format(
    'CREATE POLICY tenant_isolation ON %I._meta USING (false)',
    target_schema
  );
  EXECUTE format(
    'INSERT INTO %I._meta (key, value)
     VALUES (
       ''provisioned'',
       jsonb_build_object(
         ''at'', now()::text,
         ''tenant_id'', $1
       )
     )
     ON CONFLICT (key) DO UPDATE
       SET value = excluded.value, updated_at = now()',
    target_schema
  )
  USING tenant_row.tenant_id;

  EXECUTE format(
    'ALTER TABLE %I._meta OWNER TO apps_migration_coordinator',
    target_schema
  );
  EXECUTE format(
    $executor$
    CREATE OR REPLACE FUNCTION %I._execute_tenant_migration(p_sql text)
    RETURNS void
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = %I, pg_catalog
    AS $body$
    BEGIN
      IF p_sql IS NULL OR length(trim(p_sql)) = 0 THEN
        RAISE EXCEPTION 'Empty tenant migration SQL';
      END IF;
      EXECUTE p_sql;
    END;
    $body$
    $executor$,
    target_schema,
    target_schema
  );
  EXECUTE format(
    'GRANT EXECUTE ON FUNCTION %I._execute_tenant_migration(text)
     TO apps_migration_coordinator',
    target_schema
  );
  EXECUTE format(
    'REVOKE ALL ON FUNCTION %I._execute_tenant_migration(text)
     FROM PUBLIC, anon, authenticated, service_role',
    target_schema
  );
  EXECUTE format(
    'ALTER FUNCTION %I._execute_tenant_migration(text) OWNER TO %I',
    target_schema,
    owner_role
  );
  EXECUTE format(
    'REVOKE CREATE ON SCHEMA %I FROM apps_migration_coordinator',
    target_schema
  );
  EXECUTE format(
    'ALTER SCHEMA %I OWNER TO %I',
    target_schema,
    owner_role
  );

  RETURN jsonb_build_object(
    'tenant_id', tenant_row.tenant_id,
    'schema', target_schema,
    'bucket', target_bucket,
    'auth_provider', tenant_row.auth_provider,
    'created', was_created
  );
END;
$_$;


--
-- Name: apps_exec_sql(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_exec_sql(sql text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN
  IF sql IS NULL OR length(trim(sql)) = 0 THEN
    RAISE EXCEPTION 'apps_exec_sql: empty SQL';
  END IF;
  EXECUTE sql;
END;
$$;


--
-- Name: apps_get_migration_receipt(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_get_migration_receipt(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
DECLARE
  receipt jsonb;
BEGIN
  IF p_target_schema !~ '^app_[a-f0-9]{24}$'
    OR p_migration_key !~ '^migration:[A-Za-z0-9_./-]+\.sql$'
  THEN
    RAISE EXCEPTION 'Invalid migration lookup';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.apps_tenants
    WHERE tenant_id = p_expected_tenant_id
      AND schema = p_target_schema
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Tenant and schema do not match an active tenant';
  END IF;

  EXECUTE format(
    'SELECT jsonb_build_object(''found'', true, ''value'', value)
       FROM %I._meta
      WHERE key = $1',
    p_target_schema
  )
  INTO receipt
  USING p_migration_key;

  RETURN COALESCE(receipt, jsonb_build_object('found', false));
END;
$_$;


--
-- Name: apps_get_migration_workspace(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apps_get_migration_workspace(p_target_schema text, p_expected_tenant_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $_$
DECLARE
  namespace_oid oid;
  owner_oid oid;
  coordinator_oid oid := to_regrole('apps_migration_coordinator')::oid;
  fingerprint text;
  files jsonb;
  receipts jsonb;
BEGIN
  IF p_target_schema IS NULL OR p_target_schema !~ '^app_[a-f0-9]{24}$'
    OR p_expected_tenant_id IS NULL
  THEN
    RAISE EXCEPTION 'Invalid migration workspace binding';
  END IF;

  -- Same seed and whole-schema stream as apps_apply_migration, including reads
  -- so structural feedback and receipts cannot straddle a coordinated apply.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_target_schema, 0));
  IF NOT EXISTS (
    SELECT 1 FROM public.apps_tenants
    WHERE tenant_id = p_expected_tenant_id AND schema = p_target_schema AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Tenant and schema do not match an active tenant';
  END IF;

  SELECT n.oid, r.oid INTO namespace_oid, owner_oid
  FROM pg_catalog.pg_namespace AS n
  JOIN pg_catalog.pg_roles AS r ON r.oid = n.nspowner
  WHERE n.nspname = p_target_schema
    AND r.rolname = 'app_owner_' || substring(p_target_schema FROM 5)
    AND NOT (r.rolcanlogin OR r.rolinherit OR r.rolsuper OR r.rolcreatedb
      OR r.rolcreaterole OR r.rolreplication OR r.rolbypassrls)
    AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_auth_members WHERE member = r.oid);
  IF namespace_oid IS NULL OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class
    WHERE relnamespace = namespace_oid AND relname = '_meta' AND relkind = 'r'
      AND relowner = coordinator_oid AND relrowsecurity
  ) THEN
    RAISE EXCEPTION 'Migration workspace requires an isolated schema and protected receipts';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.apps_migration_feedback
    WHERE target_schema = p_target_schema AND tenant_id <> p_expected_tenant_id
  ) THEN
    RAISE EXCEPTION 'Migration feedback tenant binding changed';
  END IF;

  -- MD5 is a deterministic 32-hex cache-context identifier, NOT a migration
  -- checksum or integrity proof. No extensions required. Only catalog structure
  -- is read: no tenant rows, sequence counters, statistics or receipt contents.
  -- Ordered JSON definitions avoid catalog OIDs and ambiguous concatenation.
  WITH definitions(kind, name, definition) AS (
    SELECT 'schema', n.nspname::text, jsonb_build_array(
      pg_get_userbyid(n.nspowner), ARRAY(SELECT x::text FROM unnest(n.nspacl) x ORDER BY x::text)
    ) FROM pg_catalog.pg_namespace n WHERE n.oid = namespace_oid
    UNION ALL
    SELECT 'relation', c.relname::text, jsonb_build_array(
      c.relkind, c.relpersistence, pg_get_userbyid(c.relowner), c.relrowsecurity,
      c.relforcerowsecurity, c.relreplident,
      ARRAY(SELECT x FROM unnest(c.reloptions) x ORDER BY x),
      ARRAY(SELECT x::text FROM unnest(c.relacl) x ORDER BY x::text),
      CASE WHEN c.relkind IN ('v', 'm') THEN pg_get_viewdef(c.oid, false) END,
      CASE WHEN c.relkind = 'p' THEN pg_get_partkeydef(c.oid) END,
      pg_get_expr(c.relpartbound, c.oid, false)
    ) FROM pg_catalog.pg_class c WHERE c.relnamespace = namespace_oid
    UNION ALL
    SELECT 'column', c.relname || '.' || a.attnum::text, jsonb_build_array(
      a.attname, format_type(a.atttypid, a.atttypmod), a.attnotnull,
      a.attidentity, a.attgenerated, a.attstorage, a.attcompression,
      a.attcollation::regcollation::text, pg_get_expr(d.adbin, d.adrelid, false),
      ARRAY(SELECT x::text FROM unnest(a.attacl) x ORDER BY x::text)
    ) FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
    WHERE c.relnamespace = namespace_oid AND a.attnum > 0 AND NOT a.attisdropped
    UNION ALL
    SELECT 'constraint', c.conrelid::regclass::text || ':' || c.conname,
      jsonb_build_array(c.contype, c.convalidated, pg_get_constraintdef(c.oid, false))
    FROM pg_catalog.pg_constraint c WHERE c.connamespace = namespace_oid
    UNION ALL
    SELECT 'index', c.relname::text, to_jsonb(pg_get_indexdef(i.indexrelid))
    FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class c ON c.oid = i.indexrelid
    WHERE c.relnamespace = namespace_oid
    UNION ALL
    SELECT 'policy', c.relname || ':' || p.polname, jsonb_build_array(
      p.polcmd, p.polpermissive,
      ARRAY(SELECT CASE WHEN r = 0 THEN 'PUBLIC' ELSE pg_get_userbyid(r) END
        FROM unnest(p.polroles) r ORDER BY 1),
      pg_get_expr(p.polqual, p.polrelid, false), pg_get_expr(p.polwithcheck, p.polrelid, false)
    ) FROM pg_catalog.pg_policy p JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = namespace_oid
    UNION ALL
    SELECT 'routine', p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')',
      jsonb_build_array(pg_get_functiondef(p.oid), pg_get_userbyid(p.proowner),
        ARRAY(SELECT x::text FROM unnest(p.proacl) x ORDER BY x::text))
    FROM pg_catalog.pg_proc p WHERE p.pronamespace = namespace_oid AND p.prokind <> 'a'
    UNION ALL
    SELECT 'type', t.typname::text, jsonb_build_array(
      t.typtype, pg_get_userbyid(t.typowner), t.typnotnull,
      format_type(t.typbasetype, t.typtypmod), t.typdefault,
      ARRAY(SELECT x::text FROM unnest(t.typacl) x ORDER BY x::text),
      ARRAY(SELECT e.enumlabel FROM pg_catalog.pg_enum e WHERE e.enumtypid = t.oid ORDER BY e.enumsortorder),
      (SELECT jsonb_build_array(format_type(r.rngsubtype, NULL), r.rngcollation::regcollation::text,
        r.rngcanonical::regprocedure::text, r.rngsubdiff::regprocedure::text)
        FROM pg_catalog.pg_range r WHERE r.rngtypid = t.oid)
    ) FROM pg_catalog.pg_type t WHERE t.typnamespace = namespace_oid
    UNION ALL
    SELECT 'trigger', c.relname || ':' || t.tgname,
      jsonb_build_array(t.tgenabled, pg_get_triggerdef(t.oid, false))
    FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
    WHERE c.relnamespace = namespace_oid AND NOT t.tgisinternal
    UNION ALL
    SELECT 'rule', c.relname || ':' || r.rulename,
      jsonb_build_array(r.ev_enabled, pg_get_ruledef(r.oid, false))
    FROM pg_catalog.pg_rewrite r JOIN pg_catalog.pg_class c ON c.oid = r.ev_class
    WHERE c.relnamespace = namespace_oid
    UNION ALL
    SELECT 'sequence', c.relname::text, jsonb_build_array(
      format_type(s.seqtypid, NULL), s.seqstart, s.seqincrement, s.seqmax, s.seqmin, s.seqcache, s.seqcycle
    ) FROM pg_catalog.pg_sequence s JOIN pg_catalog.pg_class c ON c.oid = s.seqrelid
    WHERE c.relnamespace = namespace_oid
    UNION ALL
    SELECT 'default_acl', pg_get_userbyid(d.defaclrole) || ':' || d.defaclobjtype::text,
      to_jsonb(ARRAY(SELECT x::text FROM unnest(d.defaclacl) x ORDER BY x::text))
    FROM pg_catalog.pg_default_acl d
    WHERE d.defaclnamespace = namespace_oid OR (d.defaclnamespace = 0 AND d.defaclrole = owner_oid)
    UNION ALL
    SELECT 'role', r.rolname::text, jsonb_build_array(
      r.rolsuper, r.rolinherit, r.rolcreaterole, r.rolcreatedb, r.rolcanlogin,
      r.rolreplication, r.rolbypassrls, r.rolconnlimit,
      ARRAY(SELECT x FROM unnest(r.rolconfig) x ORDER BY x)
    ) FROM pg_catalog.pg_roles r
    WHERE r.oid IN (owner_oid, coordinator_oid) OR r.rolname IN ('anon', 'authenticated', 'service_role')
    UNION ALL
    SELECT 'membership', pg_get_userbyid(m.roleid) || ':' || pg_get_userbyid(m.member),
      jsonb_build_array(m.admin_option, m.inherit_option, m.set_option)
    FROM pg_catalog.pg_auth_members m
    WHERE m.member IN (SELECT oid FROM pg_catalog.pg_roles
      WHERE oid IN (owner_oid, coordinator_oid) OR rolname IN ('anon', 'authenticated', 'service_role'))
  )
  SELECT md5(COALESCE(jsonb_agg(jsonb_build_array(kind, name, definition)
    ORDER BY kind COLLATE "C", name COLLATE "C", definition::text COLLATE "C"), '[]'::jsonb)::text)
  INTO fingerprint FROM definitions;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'migration_key', f.migration_key, 'checksum', f.checksum,
    'context_key', f.context_key, 'error', f.error
  ) ORDER BY f.migration_key COLLATE "C"), '[]'::jsonb)
  INTO files FROM public.apps_migration_feedback f
  WHERE f.target_schema = p_target_schema AND f.tenant_id = p_expected_tenant_id;

  -- Include every applied key, even historical paths the new journal rejects.
  EXECUTE format(
    'SELECT COALESCE(jsonb_agg(jsonb_build_object(''migration_key'', key, ''value'', value)
       ORDER BY key COLLATE "C"), ''[]''::jsonb) FROM %I._meta WHERE key LIKE ''migration:%%''',
    p_target_schema
  ) INTO receipts;
  RETURN jsonb_build_object('schema_fingerprint', fingerprint, 'files', files, 'receipts', receipts);
END;
$_$;


--
-- Name: apps_migration_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apps_migration_feedback (
    target_schema text NOT NULL,
    migration_key text NOT NULL,
    tenant_id uuid NOT NULL,
    checksum text NOT NULL,
    context_key text NOT NULL,
    error jsonb,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT apps_migration_feedback_checksum_check CHECK ((checksum ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT apps_migration_feedback_context_key_check CHECK (((octet_length(context_key) >= 1) AND (octet_length(context_key) <= 256))),
    CONSTRAINT apps_migration_feedback_error_check CHECK (((error IS NULL) OR ((jsonb_typeof(error) = 'object'::text) AND (octet_length((error)::text) <= 4096)))),
    CONSTRAINT apps_migration_feedback_migration_key_check CHECK (((octet_length(migration_key) <= 522) AND (migration_key ~ '^migration:(migrations|supabase/migrations|src/db/migrations|platform)/([A-Za-z0-9_-][A-Za-z0-9_.-]*/)*[A-Za-z0-9_-][A-Za-z0-9_.-]*[.]sql$'::text) AND (migration_key !~ '(^|/)[.]{1,2}(/|$)'::text) AND (migration_key !~~ '%//%'::text))),
    CONSTRAINT apps_migration_feedback_target_schema_check CHECK ((target_schema ~ '^app_[a-f0-9]{24}$'::text))
);

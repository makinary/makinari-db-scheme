-- Catalog-only checks: no customer rows read or written.
DO $verify$
DECLARE t oid := 'public.customer_support_inbound_commands'::regclass;
BEGIN
  IF (SELECT array_agg(attname::text || ':' || format_type(atttypid,atttypmod) || ':' || attnotnull::text ORDER BY attnum) FROM pg_attribute WHERE attrelid=t AND attnum>0 AND NOT attisdropped)
    IS DISTINCT FROM ARRAY['site_id:uuid:true','connection_id:text:true','origin_message_id:text:true','owner_token:uuid:true','command_id:uuid:false','created_at:timestamp with time zone:true'] THEN RAISE EXCEPTION 'Column mismatch'; END IF;
  IF (SELECT pg_get_expr(adbin,adrelid) FROM pg_attrdef WHERE adrelid=t AND adnum=6) IS DISTINCT FROM 'now()' OR (SELECT count(*) FROM pg_attrdef WHERE adrelid=t)<>1 THEN RAISE EXCEPTION 'Default mismatch'; END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid=t) OR EXISTS(SELECT FROM pg_policy WHERE polrelid=t) THEN RAISE EXCEPTION 'RLS mismatch'; END IF;
  IF (SELECT count(*) FROM pg_constraint WHERE conrelid=t AND contype IN ('p','f','c'))<>4
    OR NOT EXISTS(SELECT FROM pg_constraint WHERE conrelid=t AND contype='p' AND conkey=ARRAY[1,2,3]::smallint[])
    OR NOT EXISTS(SELECT FROM pg_constraint WHERE conrelid=t AND contype='f' AND conkey=ARRAY[5]::smallint[] AND confrelid='public.commands'::regclass AND confkey=ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid='public.commands'::regclass AND attname='id')]::smallint[] AND confdeltype='a' AND confupdtype='a' AND convalidated)
    OR (SELECT count(*) FROM pg_constraint WHERE conrelid=t AND contype='c' AND convalidated AND pg_get_constraintdef(oid) IN ('CHECK ((length(connection_id) > 0))','CHECK ((length(origin_message_id) > 0))'))<>2 THEN RAISE EXCEPTION 'Constraint mismatch'; END IF;
  IF (SELECT count(*) FROM pg_index WHERE indrelid=t)<>1 OR NOT EXISTS(SELECT FROM pg_index WHERE indrelid=t AND indisprimary AND indisunique AND indisvalid AND indisready AND indkey::text='1 2 3') THEN RAISE EXCEPTION 'Index mismatch'; END IF;
  IF EXISTS(SELECT FROM unnest(ARRAY['anon','authenticated','service_role']) r CROSS JOIN unnest(ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) p WHERE has_table_privilege(r,t,p) IS DISTINCT FROM (r='service_role' AND p IN ('SELECT','INSERT','UPDATE'))) THEN RAISE EXCEPTION 'Role privilege mismatch'; END IF;
  IF EXISTS(SELECT FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a WHERE c.oid=t AND a.grantee=0) THEN RAISE EXCEPTION 'PUBLIC grant'; END IF;
  IF NOT (SELECT rolbypassrls FROM pg_roles WHERE rolname='service_role') OR NOT has_schema_privilege('service_role','public','USAGE') THEN RAISE EXCEPTION 'Service access mismatch'; END IF;
END $verify$;
SELECT json_build_object('verified_at',clock_timestamp(),'columns_defaults_constraints_indexes_acl_rls','passed','scope','public','customer_rows_accessed',false);

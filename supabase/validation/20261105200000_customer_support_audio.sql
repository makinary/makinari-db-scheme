-- Catalog-only live verification; no customer reads or writes.
DO $verify$
DECLARE r text; p text; actual boolean;
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.customer_support_audio'::regclass) THEN
    RAISE EXCEPTION 'Audio RLS disabled';
  END IF;
  IF EXISTS (SELECT FROM pg_policy WHERE polrelid='public.customer_support_audio'::regclass) THEN
    RAISE EXCEPTION 'Unexpected audio policy';
  END IF;
  FOREACH r IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
    FOREACH p IN ARRAY ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] LOOP
      actual := has_table_privilege(r,'public.customer_support_audio',p);
      IF actual IS DISTINCT FROM (r='service_role' AND p IN ('SELECT','INSERT','UPDATE')) THEN
        RAISE EXCEPTION 'Unexpected audio privilege: % %',r,p;
      END IF;
    END LOOP;
  END LOOP;
  IF EXISTS (SELECT FROM pg_class c, LATERAL aclexplode(c.relacl) a
      WHERE c.oid='public.customer_support_audio'::regclass AND a.grantee=0) THEN
    RAISE EXCEPTION 'PUBLIC audio privileges';
  END IF;
  IF (SELECT count(*) FROM pg_constraint WHERE conrelid='public.customer_support_audio'::regclass AND contype='c' AND convalidated) <> 4
     OR NOT EXISTS (SELECT FROM pg_constraint WHERE conrelid='public.customer_support_audio'::regclass AND contype='p' AND pg_get_constraintdef(oid)='PRIMARY KEY (site_id, source_hash)')
     OR NOT EXISTS (SELECT FROM pg_constraint WHERE conrelid='public.customer_support_audio'::regclass AND contype='f' AND confrelid='public.sites'::regclass AND confdeltype='c' AND convalidated) THEN
    RAISE EXCEPTION 'Unexpected audio constraints';
  END IF;
  IF (SELECT count(*) FROM pg_attribute WHERE attrelid='public.customer_support_audio'::regclass AND attnum>0 AND NOT attisdropped AND attnotnull) <> 4 THEN
    RAISE EXCEPTION 'Unexpected audio nullability';
  END IF;
END $verify$;
SELECT json_build_object('rls_enabled',true,'policies',0,'service_role_select_insert_update_only',true,'public_anon_authenticated_denied',true,'validated_checks',4,'composite_pk',true,'site_fk_cascade',true);
SELECT json_build_object('constraint',conname,'definition',pg_get_constraintdef(oid)) FROM pg_constraint WHERE conrelid='public.customer_support_audio'::regclass ORDER BY conname;

BEGIN;
SET LOCAL lock_timeout = '5s';

-- Fresh-QA prerequisite only. A schema capture retains the private callee's
-- historical name but not the public function's OID. Do not apply to production.
DO $compatibility$
DECLARE
  entry_oid oid := 'public.accounting_update_purchase_items(uuid,uuid,timestamptz,jsonb,jsonb)'::regprocedure;
  entry pg_proc%ROWTYPE;
  original pg_proc%ROWTYPE;
  callee text;
  expected_name text := 'original_' || entry_oid;
  body text;
  definition text;
  implementation_oid oid;
BEGIN
  SELECT * INTO STRICT entry FROM pg_proc WHERE oid = entry_oid;
  -- Match the entire known wrapper, not a guard substring in arbitrary SQL.
  body := regexp_replace(entry.prosrc, '[[:space:]]', '', 'g');
  callee := substring(body FROM '^BEGINPERFORMpublic[.]location_acl_assert_unscoped_rpc\(\);PERFORMlocation_acl_private[.](original_[0-9]+)\(\$1,\$2,\$3,\$4,\$5\);RETURN;END$');
  IF callee IS NULL OR NOT entry.prosecdef
    OR entry.prorettype <> 'void'::regtype
    OR entry.prolang <> (SELECT oid FROM pg_language WHERE lanname = 'plpgsql')
    OR entry.proconfig IS DISTINCT FROM ARRAY['search_path=public, pg_temp']::text[] THEN
    RAISE EXCEPTION 'Unexpected captured accounting wrapper';
  END IF;
  implementation_oid := to_regprocedure(format('location_acl_private.%I(uuid,uuid,timestamptz,jsonb,jsonb)', callee));
  IF implementation_oid IS NULL THEN
    RAISE EXCEPTION 'Captured accounting implementation is missing';
  END IF;
  SELECT * INTO STRICT original FROM pg_proc WHERE oid = implementation_oid;
  IF original.proowner <> entry.proowner OR NOT original.prosecdef
    OR original.prorettype <> entry.prorettype OR original.proargtypes <> entry.proargtypes
    OR original.prolang <> entry.prolang OR original.proconfig IS DISTINCT FROM entry.proconfig
    OR position('DELETE FROM public.purchase_items WHERE purchase_id = p_purchase_id AND site_id = p_site_id;' IN original.prosrc) = 0
    OR position('UPDATE public.purchases SET title = replacement.title' IN original.prosrc) = 0
    OR position('Purchase update is not authorized' IN original.prosrc) = 0
    OR position('Received bill items must remain unchanged' IN original.prosrc) > 0 THEN
    RAISE EXCEPTION 'Unexpected captured accounting implementation';
  END IF;
  IF EXISTS (SELECT 1 FROM aclexplode(coalesce(original.proacl, acldefault('f', original.proowner)))
    WHERE grantee <> original.proowner AND privilege_type = 'EXECUTE')
    OR EXISTS (SELECT 1 FROM aclexplode(coalesce(entry.proacl, acldefault('f', entry.proowner)))
      WHERE grantee = 0 AND privilege_type = 'EXECUTE') THEN
    RAISE EXCEPTION 'Unexpected accounting execution grants';
  END IF;
  IF callee = expected_name THEN RETURN; END IF;
  IF to_regprocedure(format('location_acl_private.%I(uuid,uuid,timestamptz,jsonb,jsonb)', expected_name)) IS NOT NULL THEN
    RAISE EXCEPTION 'Accounting compatibility destination already exists';
  END IF;
  definition := pg_get_functiondef(entry_oid);
  -- Rename preserves private identity/owner/ACL; replacing the public function
  -- preserves its OID/owner/ACL and the exact unscoped authorization guard.
  EXECUTE format('ALTER FUNCTION location_acl_private.%I(uuid,uuid,timestamptz,jsonb,jsonb) RENAME TO %I', callee, expected_name);
  EXECUTE replace(definition, 'location_acl_private.' || callee || '(',
    'location_acl_private.' || expected_name || '(');
END;
$compatibility$;
COMMIT;
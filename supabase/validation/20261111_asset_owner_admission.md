# Asset ownership and inline text admission

## Applied target and evidence

- Only `20261111210000_asset_owner_admission.sql` applied to linked Makinari,
  project `rnjgeloamtszdjplmqxy`, using this repository's `.env.local` credentials.
- Transaction committed and receipt observed at **2026-11-11 20:34:10 UTC**.
- Independent catalog verification at **20:34:31 UTC**; local-credential exact-source
  history verification and temporary-table owner probe at **20:35:16 UTC**.
- SHA-256 of API/canonical/bootstrap SQL:
  `9f0be62574396bc59ab9e9bbbe92172693d874e7ed2b8bd9097e92e6dff4a5eb`.
- DDL and the exact source history entry committed atomically, with advisory lock,
  exclusive history lock, 5-second lock timeout and 60-second statement/idle limits.
- Asset table ACL, RLS and FORCE RLS flags verified unchanged in the transaction.
  Existing `user_id NOT NULL`, foreign keys and policies remain intact.
- Trigger is BEFORE INSERT, SECURITY INVOKER with an empty search path, and direct
  EXECUTE is revoked from PUBLIC, anon and authenticated. PostgREST was notified
  to reload its schema.
- Actual installed trigger tested on a temporary table against an existing
  instance; the complete probe was rolled back. No production asset rows,
  Storage objects, remote instances or customer records were created or changed.
- Private command receipts are in ignored `.exports/asset-owner-admission/`.
  No credentials were printed or committed. TLS follows the repository's local
  PGSSLMODE setting; certificate identity verification is not claimed.

## Database contract

- Adds nullable `public.assets.content text`, with no backfill or default rewrite.
- Explicit non-null `user_id` remains unchanged.
- For a missing owner under postgres, supabase_admin or service_role, derives the
  instance owner, rejecting a missing/cross-site instance. Without an instance,
  derives the site's owner.
- For other roles, uses `auth.uid()`; existing RLS still governs the insert. A
  missing resolved owner is rejected. This is not a new authorization bypass.
- No new RPC, SECURITY DEFINER, table grants or policy changes.
- Scope is public/Makinari only; Apps project and app_* schemas were not changed.
- Historical migration files and unrelated pending migrations were not replayed.

## API changes and rollout

The sibling API now selects `remote_instances.user_id`, uses it as asset ownership,
ignores user_id/file_path supplied in request bodies, and creates an inline path
for text content. HTTP creation authenticates the principal and checks site access.
The assistant wrapper checks site access when an actor is supplied; absent actors
remain the existing trusted internal tool-context contract, not a public credential.
The instance asset reader consumes stored inline text instead of downloading its
identifier. Inline images/documents are rejected; existing media upload tools are
unchanged. This also repairs the prior nonexistent `content` column and missing
required `file_path` in the text-creation path.

**API deployment is still pending.** Database fallback is active, but the complete
text-creation fix, route authorization and inline reading require the new runtime.
No deployment, Git commit/push, Spend Cap change, resource resize or event retention
cleanup was performed. This operation fixes audit point 3, not point 4 retention.

## Validation

- 26 focused Jest tests passed: asset creation ownership, forged body inputs,
  tenant mismatch, missing owner/content, inline media rejection, HTTP auth/site
  admission, inline reading and existing vision/inventory regressions.
- One in-memory PGlite SQL suite passed, exercising repeatability, service owner
  resolution, explicit owner preservation, tenant mismatch, missing instance,
  authenticated identity, RLS denial and invoker/NOT NULL preservation.
- TypeScript `tsc --noEmit` passed with exit 0.
- Six bootstrap validator regressions passed; manifest static validation confirms
  198 files / 53 upgrades, byte-identical sources and unchanged baseline.
- Full bootstrap replay, production HTTP creation and browser E2E were not run.
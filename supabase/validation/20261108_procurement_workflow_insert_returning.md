# Procurement INSERT RETURNING — applied and verified

## Result (2026-11-08 UTC)

Only `20261106110000_procurement_workflow_insert_returning.sql` was applied to
confirmed target `rnjgeloamtszdjplmqxy`, using schema repository `.env.local`.
Commit observed at **01:32:29.649495 UTC**; independent read-only verification
passed at **01:32:37.174 UTC**. Production business rows were neither tested nor
mutated. No robot inserts, webhook dispatch tests, broader migrations, commits,
pushes, deployments or builds were performed.

API and schema repository canonical copies are byte-identical, SHA-256:

```text
6e3b8f260accbb3cfaabe18dbb13f4fba5bc7eb37e00721e778b7905346a8f9a
```

History contains exactly one corrective version with the complete unchanged
canonical source as its single statement and the expected migration name.

## Previous blocker and corrected authorization

The earlier attempt rolled back before executing migration SQL: authenticated
lacked EXECUTE on `site_user_has_effective_access(uuid,uuid)`. Independent checks
at 01:29:21 UTC established absent history/helper and the original policy. The
previous unapplied source hash was
`9ed482bfdf242979e759425b7e0d8c74209dfbbc5609b3c0da5e249d2db34171`.
Only that unapplied correction was revised; no applied migration was edited.

The new `procurement_workflow_candidate_can_read(uuid,uuid)` is STABLE SECURITY
DEFINER with empty search_path, qualified references and an internally bound
`auth.uid()`, not an arbitrary actor argument. Null callers/site/instance fail
closed. It calls the existing privileged membership helper internally before
classification. Ordinary candidate rows need no remote_instances relookup;
private candidates retain the existence-checking `procurement_workflow_rls_read`.
The candidate predicate is deliberately not an existence RPC. It may distinguish
classification for known IDs but returns no payload. Never use it as a substitute
for read authorization on a supplied instance ID.

Authenticated EXECUTE on the existing membership helper remains **false**, with
its ACL/body unchanged. The classifier is denied to PUBLIC, anon, authenticated
and service_role. The new candidate helper is granted only to authenticated among
those roles. The existing internal arbitrary-actor read RPC retains its ACL:
authenticated denied, service_role allowed. Its replacement body explicitly
requires tenant membership and an existing same-site row, even for ordinary IDs.

## Transaction and independent evidence

Fresh preflight checked linked ref, configured direct endpoint and matching session
pooler identity without printing credentials. Read-only catalog/history checks
confirmed the prerequisite's exact canonical source, original helper bodies/ACLs,
eight restrictive SELECT guards, table ownership/RLS and absent correction.

Application acquired an advisory transaction lock and EXCLUSIVE migration-history
table lock; lock timeout 5 seconds, statement and idle transaction timeouts 60
seconds. Preconditions and postconditions surrounded only the corrected SQL and
exact-source history insertion in one transaction. API/schema equality was asserted.

A separate connection used BEGIN READ ONLY with a 30-second statement timeout to
repeat postconditions and capture catalogs. Verified:

- Exact history source/name/version and both new helper bodies, postgres ownership,
  SECURITY DEFINER, empty search_path and STABLE candidate/classifier.
- Narrow new helper ACLs, no PUBLIC execute, and unchanged membership/read RPC ACLs.
- Base guard remains RESTRICTIVE SELECT TO authenticated and invokes only
  `procurement_workflow_candidate_can_read(site_id, id)`.
- Seven derived guards and existing base tenant policies remain unchanged.
- Required table RLS, ownership and grants remain unchanged.

Private receipts and scripts remain under ignored `.exports/insert-returning-*`
with private permissions, including application and independent JSON receipts.
No production business-flow success or full schema replay is claimed.

## Tests completed before application

- API real PostgreSQL: **6 passed**. Socket-only disposable cluster with actual
  authenticated NOBYPASSRLS and revoked membership-helper EXECUTE. Reproduces both
  original RLS 42501 and rejected direct-call permission 42501; corrected ordinary
  member/manager INSERT RETURNING succeeds without a grant. Covers tenant/owner
  denial, single/array private triggers, all eight guards, sticky classification,
  private classifier denial, caller/null boundaries, and missing-ID/wrong-site/
  foreign-membership existence RPC denial.
- API PGlite confidentiality regression: **1 passed**.
- `python3 scripts/validate-bootstrap.py`: **190 files / 45 upgrades**, passed.
- `python3 scripts/test_validate_bootstrap.py`: **6 passed**.
- Canonical byte comparison and SHA-256 comparison passed.

Commands (API; PostgreSQL binaries required at /opt/homebrew/bin):

```sh
PATH=/opt/homebrew/bin:$PATH npm run test:procurement -- --runTestsByPath src/lib/procurement/__tests__/workflow-insert-returning-postgres.test.ts
PATH=/opt/homebrew/bin:$PATH NODE_OPTIONS=--experimental-vm-modules node node_modules/jest/bin/jest.js --config jest.config.js --runInBand --runTestsByPath src/lib/services/__tests__/procurement-workflow-confidentiality-migration.test.ts
```

The procurement Jest config excludes the services test; it was run separately.
The first separate invocation lacked the VM modules flag and failed; rerunning
with the required flag passed before application.

## Limits and preserved bootstrap exclusion

TLS encryption was confirmed. `verify-full` could not run because the local root
certificate was absent; the established `.env.local` `require` mode was used.
Server certificate verification is not claimed.

The correction remains **excluded from bootstrap**: its confidentiality prerequisite
is not packaged, and production workflow migrations require reviewed QA-local
outbound safeguards and classification-backfill review. Bootstrap files/manifests
and unrelated working-tree changes were preserved. The fixture is focused, not a
full Supabase replay; production verification was catalog/history only.

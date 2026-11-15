# Fresh-QA accounting wrapper compatibility — 2026-11-15

## Failure and correction

QA `qa-1794710471894-d269fe11` failed at the unchanged canonical
`20261113210500_accounting_preserve_received_bill_lines.sql` with `Unexpected
accounting location wrapper`. The captured public wrapper calls private
`original_4250037`, whereas the accounting patch resolves `original_<public OID>`.
Restoring CREATE FUNCTION statements assigns a new public OID.

Added **QA-only** bootstrap prerequisite
`20261113210450_qa_accounting_wrapper_oid_compatibility.sql`, ordered immediately
before that patch. It matches the entire known guarded wrapper body, verifies
signature, language, security configuration, owner, private implementation markers
and execution ACLs, and rejects an occupied destination. It renames the private
function and changes only the public wrapper's callee in one transaction.
Function OIDs, owners, ACLs and authorization guard remain intact. The canonical
accounting patch then executes in full; compatibility alone is not the receipt fix.

No applied migration, captured baseline file, canonical upgrade or production
database was modified. The prerequisite is intentionally absent from canonical
`supabase/migrations/`. `bootstrap/manifest.json` lists its hash separately under
`qaCompatibilityFiles`; the canonical upgrade manifest is unchanged.

## Verification

- Five new socket-only PostgreSQL cases load the actual captured public/private
  function definitions, assert OID mismatch, reproduce the old failure, and run
  compatibility followed by the unchanged accounting patch.
- Tests verify repeatable normalization before patching, preserved OIDs/owners/
  ACLs, partial receipt line identity, rejected changed/forged lines, restricted/
  anonymous/cross-site denial and denied real private calls for all browser/API roles.
- Unknown wrappers, missing implementations, unexpected private grants and target
  name collisions fail atomically.
- Combined new and existing receipt-review suites: **20 tests passed**. The new
  five cases were rerun after switching to the actual captured private definition;
  all passed. Existing receipt-review assertions were not edited.
- Bootstrap validator: **226 files / 80 canonical upgrades / 1 QA prerequisite**;
  all **nine validator regressions passed**. Canonical and captured file hashes
  remain unchanged. New-file ESLint and diff checks passed.
- Installer QA/mail regression suites: **25 tests passed**. The deleted QA ID
  remains rejected by create preflight; it was not reused or provisioned.

## Limits and next retry

No Azure environment, remote migration or production build was run for this
repair. Local PostgreSQL proves this specific restoration boundary; complete
Supabase bootstrap replay and live E2E remain unverified. Publish the schema
repository's prerequisite and manifest/validator changes, then use the installer
with a new exact QA ID and explicit infrastructure approval. Never replay this
bootstrap onto an existing/production database or mark the accounting patch
applied merely because compatibility succeeded.
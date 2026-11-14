# Task creation idempotency — applied and verified

## Reverification after API repairs — 2026-11-11

At **2026-11-11 00:30:39.957653 UTC**, a new read-only connection using this
repository's local credentials confirmed the nullable text column, valid/ready
unique index and exact-source migration history on `rnjgeloamtszdjplmqxy`.
Only `public` remains eligible and task RLS is enabled. The migration was already
applied, so no DDL, history insert or business-row operation was repeated.

API, canonical and bootstrap SQL still have the SHA-256 below; both manifests
contain exactly one matching entry. Bootstrap static validation and all six
validator tests passed again (192 files / 47 upgrades).

The API repairs remove implicit command filters from task lookups, bypass stale
list caches, fix local-worker response mapping and preserve reused task details.
They do not alter the SQL or stored key format and require no further migration.
Application deployment remains unverified. Different keys for the same business
issue can still create different tasks: the index guarantees shared-key
idempotency, not semantic matching. Existing dirty work and the separate snooze
migration were left untouched during this reverification. No commit/push performed.

## Execution

- Project: `rnjgeloamtszdjplmqxy`, checked against this repository's local PostgreSQL host and linked session pooler. Credentials were never printed.
- Applied only `20261111010000_task_creation_idempotency.sql`.
- Commit observed: **2026-11-10 23:56:37.552994 UTC**.
- Independent read-only verification: **2026-11-10 23:56:45.903527 UTC**.
- Only `public` was eligible; no existing `app_*` schema contained `tasks`.
- Advisory transaction lock, exclusive migration-history lock, 5-second lock timeout and 60-second statement/idle transaction timeouts.
- DDL and exact-source migration history committed atomically; PostgREST schema reload notified.
- No business-row reads/writes, task merging/deletion, notifications, API deployment, Git commits/pushes or other pending migrations were performed. Existing dirty changes were preserved.

## Verified contract

- Nullable `public.tasks.creation_key` of type `text`.
- Valid, ready, unique index `tasks_creation_identity_unique` on `(site_id, lead_id, creation_key)` with predicate `creation_key IS NOT NULL`.
- Migration version/name and complete source match the canonical file exactly.
- Existing RLS, FORCE RLS and table ACLs are unchanged; RLS remains enabled.
- API/canonical/fresh-QA bootstrap copies are byte-identical, SHA-256:

```text
0bd1ff2aee0896ad7784c5ff0c9fd7bea51443cae6c7bdda5034a86f46742d78
```

## Local validation

- API task suite: **56 tests passed**, including execution of this migration and uniqueness checks in PGlite.
- Bootstrap validator: **192 files / 47 canonical upgrades**, hashes and coverage valid.
- Bootstrap validator unit tests: **6 passed**.
- Full expanded Supabase bootstrap replay and live API task creation were not performed.

## Rollout and limitations

Deploy the API task changes next. Old callers that omit `creation_key` remain outside the index predicate; the database migration alone does not stop the old endpoint from creating duplicates. The updated endpoint always supplies a key and only notifies on the winning insert. Existing tasks remain unkeyed and must be discovered and updated by the agent.

The create endpoint requires a lead. PostgreSQL allows multiple NULL lead IDs in this index; direct leadless database writers are not protected by this identity. Distinct issues must use distinct keys; similar titles are not automatically merged. Closed tasks retain their key so retries cannot recreate completed work.

The bootstrap is for fresh local QA, not a command to replay a baseline on this existing database. New tenant provisioning must include the migration. No generated `supabase/types.ts` exists here; no unrelated schema-wide type export was introduced.

TLS encryption was verified with `require` mode; server certificate identity verification (`verify-full`) is not claimed. Private execution scripts/receipts remain under ignored `.exports/task-idempotency/`.

Security advisors were checked after application and report broader findings outside this migration's scope. No policies, grants or privileged functions were added here. Review [project security advisors](https://supabase.com/dashboard/project/rnjgeloamtszdjplmqxy/advisors/security); relevant existing categories include [RLS without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
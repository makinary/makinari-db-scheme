# First-contact WhatsApp snooze — application evidence

Applied only `20261111220000_first_contact_whatsapp_snooze.sql` to Makinari
project **rnjgeloamtszdjplmqxy**, schema **public**, using this repository's
ignored `.env.local` credentials and its matching cached Session pooler.
The Apps project was not modified.

## Execution and verification

- Read-only credential-based preflight: **2026-11-11 23:16:32.520107 UTC**.
  Both conversation/lead-site predecessors were recorded, required authorization
  and human-message triggers were enabled, and the new ledger tables were absent.
  No eligible `app_*` chat schemas existed on this target.
- Commit observed: **2026-11-11 23:16:52.338188 UTC**.
- Independent management-API read-only history verification:
  **2026-11-11 23:17:01.927552 UTC**.
- DDL and exact-source migration history committed in one transaction, using the
  shared migration advisory lock, exclusive history lock, 5s lock timeout and
  60s statement/idle-in-transaction timeouts. PostgREST schema reload notified.
- Existing conversations/messages/leads/settings ACL, RLS and FORCE RLS flags
  were compared inside the transaction and remained unchanged.
- Both new ledger tables have RLS enabled; anonymous/authenticated SELECT denied.
  `service_role` has SELECT/INSERT/UPDATE, not DELETE.
- All four new helper/RPC functions are SECURITY INVOKER with
  `search_path=pg_catalog`; client EXECUTE denied, server EXECUTE allowed.
  The replaced human-message trigger function remains SECURITY INVOKER.
- Pending-event and exact inbound-identity indexes are valid and ready.
- Exact SHA-256 of API, canonical, bootstrap and recorded migration source:
  `7e64eda5d2fda34c1b1e102f5ec70311be7f1a49cee4bdb3d7bb4b70810823cc`.
- Private application/preflight receipts are under ignored
  `.exports/first-contact-snooze/`, with restrictive permissions. TLS was enabled
  using `sslmode=require`; certificate-identity verification was not established.

## Regression checks

- API in-memory SQL and isolated PostgreSQL multiconnection suites:
  **27 passed, zero skipped** (includes the parent concurrency test).
- Canonical repository SQL suite: **21 passed, zero skipped**.
- Static bootstrap validator: **200 migrations / 55 canonical upgrades**;
  manifest coverage and source hashes match. The existing manifest already
  included this migration and did not require changes for this application.
- Full bootstrap replay, API deployment and live delivery E2E were not performed.

## Security advisor

The advisor reports informational `rls_enabled_no_policy` findings for both new
tables. This is intentional server-only storage: browser access is revoked and
no permissive client policy should be added to silence the finding.
See [Supabase explanation](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
Other project-wide findings were observed but were not remediated by this scoped
migration; this check is not a clean bill of health for the whole database.

## Rollout boundaries

No historical event recovery, customer-message send, production fixture insertion
or business-row backfill was performed. Applied predecessors remain immutable.
Deploy API echo registration and first-inbound reconciliation together, then
verify a controlled human-first contact, duplicates, expiry and manual resume.
The migration alone does not deploy those API handlers or recover old failed echoes.
Repository updates are local; no Git commit or push was performed.
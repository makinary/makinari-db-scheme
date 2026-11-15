# Makinari DB Schema

Source of truth for the Supabase database schema. Migrations and generated types live here.

## API timeout contention — applied (2026-11-15 UTC)

Applied only `20261114210000_requirement_economic_recovery_contention.sql` and
`20261114210100_catalog_backfill_contention.sql` to linked Makinari
(`rnjgeloamtszdjplmqxy`) at **02:34:00 UTC**, using ignored local credentials over
TLS. Both changes and exact-source history committed atomically. Independent
verification at **02:34:02 UTC** confirmed exact installed bodies, preserved
owners/authorization, function-local 50ms lock limits, unchanged synchronous
catalog refresh, and unchanged queue security. No business operation was invoked.

API/canonical/bootstrap copies match. Static validation covers **225 files / 80
upgrades**; all seven validator tests pass. The immutable baseline is unchanged.
These mitigate reproduced contention, not all possible timeout causes. The web
inventory fix and API error-message changes still require deployment. No historical
migration replay, commit, push or application deployment was performed.
See [application evidence](supabase/validation/20261115_timeout_contention.md).

## POS inventory debit receipts — applied (2026-11-14 UTC)

Applied only `20261114000000_order_line_inventory_receipts.sql` to linked
Makinari (`rnjgeloamtszdjplmqxy`) at **03:51:06 UTC**, using this repository's
ignored credentials over TLS. Independent verification at **03:51:17 UTC**
confirmed exact-source migration history, receipt RLS, client-denied direct
writes, the insert trigger, validated constraints, and the server-only historical
reconciliation RPC. Existing counts remained **2 stock levels / 1,194 order
lines / 609 orders**; no historical receipt backfill or stock movement occurred.

Canonical/frontend/bootstrap sources are byte-identical. Static bootstrap
validation covers **223 files / 78 upgrades**, all seven validator tests pass,
and 48 focused tests pass, including disposable local PostgreSQL regressions.
Matching application deployment and operator review of ambiguous historical
inventory remain separate. No commit, push or deployment was performed.
See [application evidence](supabase/validation/20261114_pos_inventory_receipts.md).

## Inventory workflow — applied (2026-11-13 UTC)

Applied only the ten inventory migrations from `20261113170000` through
`20261113210500` to linked Makinari at **23:30:57 UTC**, using this repository's
local credentials over TLS. Independent verification confirmed exact-source
history, RLS, client-denied direct writes, authenticated-only workflow RPCs and
unchanged existing counts: **2 stock levels / 71 bills / 157 bill lines**.
No real transfers or receipts were executed. Canonical/frontend/bootstrap copies
match; static validation covers **222 files / 77 upgrades**, all seven validator
tests pass, and 137 focused local PostgreSQL regressions passed. The captured
baseline remains unchanged. Matching web/API deployment and assistant tool
registration remain separate. See [application evidence](supabase/validation/20261113_inventory.md).

## Instance ownership and atomic quotation context — applied (2026-11-13 UTC)

Applied only `20261113160000_instance_ownership_rls.sql` and
`20261113180000_atomic_catalog_item_requirement.sql` to linked Makinari at
**21:26:40 UTC**, using this repository's local credentials. Independent checks
confirmed exact-source history, 100 restrictive guards across twenty RLS tables,
and authenticated-only invoker quotation creation. Read-only authenticated SQL
checks confirmed the restricted employee sees no foreign instances or sampled
foreign logs. Canonical/frontend/bootstrap copies match; static validation:
**212 files / 67 upgrades**, seven validator tests passed. No unrelated migration,
business-row rewrite, commit, push or deployment was performed. The matching web
code still requires deployment; reload older tabs. See [application evidence](supabase/validation/20261113_instance_ownership.md).

## Optional OpenRouter BYOK schema — applied (2026-11-12 UTC)

Applied the ten approved OpenRouter migrations (`20261112010000` through
`20261112072000`, including the API-owned `71000`) to linked Makinari at
**20:28:41 UTC**, using this repository's local credentials. Independent checks
at **20:29:07–08 UTC** confirmed exact-source history, validated constraints/indexes,
private client-denied tables/RPCs, and unchanged existing table security flags.
Created 375,468 command and 2,384 plan platform-attribution rows without updating
the original records. Customer connections and rollout approvals remain empty:
**BYOK is not activated and no provider request was made**.

The initial attempt rolled back on a bounded FK-validation timeout; the still
unapplied command migration was optimized to validate that FK set-wise before
commit. Canonical/source/bootstrap hashes now match. Bootstrap static validation:
**210 files / 65 upgrades**, seven validator regressions passed. No commit, push,
application deployment, environment change or unrelated migration was performed.
See [application and rollout evidence](supabase/validation/20261112_openrouter_byok.md).

## First-contact WhatsApp snooze — applied (2026-11-11 UTC)

Applied only `20261111220000_first_contact_whatsapp_snooze.sql` to linked Makinari
at **23:16:52 UTC**, using this repository's local credentials. Independent checks
confirmed exact-source history, server-only RLS-protected contact/event tables,
invoker RPCs and valid pending/inbound indexes. Existing table ACL/RLS flags were
preserved. No historical replay or customer sends were performed. API deployment
and controlled end-to-end verification remain required. Canonical/API/bootstrap
copies match; static bootstrap validation: **200 files / 55 upgrades**.
See [application evidence](supabase/validation/20261111_first_contact_whatsapp_snooze.md).

## Instance asset summaries — applied (2026-11-11 UTC)

Applied only `20261111223000_instance_asset_summaries.sql` at **22:24:40 UTC**:
valid instance/date and partial image indexes plus a bounded, RLS-preserving
invoker summary RPC. Independent plan verification uses the image index instead
of a sequential scan. Frontend batching/cache/abort fixes are local and still
require deployment. See [application evidence](supabase/validation/20261111_instance_asset_summaries.md).

## Database outage diagnosis — 2026-11-11

Read-only investigation confirms backend reachability loss around **19:46 UTC**,
unclean PostgreSQL recovery at **20:04 UTC**, and a preceding burst of unindexed
latest-image asset reads. The workload concern is confirmed; the termination's
root cause is not. Historical host metrics and platform lifecycle/termination
events are still required. No remediation, restart or billing change was made.
See [evidence, competing hypotheses and support handoff](supabase/validation/20261111_database_outage_rca.md).

## Asset owner admission — applied (2026-11-11 UTC)

Applied only `20261111210000_asset_owner_admission.sql` to linked Makinari at
**20:34:10 UTC**, using this repository's local credentials. Independent checks
confirmed exact-source migration history, the invoker-security ownership trigger,
the nullable inline `content` column and unchanged asset ACL/RLS/NOT NULL flags.
No business rows were rewritten. A live temporary-table trigger probe was rolled
back. API deployment is still required for authorized inline-text creation and
reading; existing backend inserts that omit ownership already receive the database
fallback. API/canonical/bootstrap copies match; **198 files / 53 upgrades**.
See [application evidence and rollout limits](supabase/validation/20261111_asset_owner_admission.md).

## Lead/site automation snooze — applied (2026-11-11 UTC)

Applied only `20261111040000_lead_site_automation_snooze.sql` to linked Makinari
at **04:00:03 UTC**, independently verified at **04:00:04 UTC**. Human-message
ingestion now resolves **lead override → AI Activities setting → ON, 4 hours**.
No assignments, active expiry or business rows changed. The earlier migration
remains immutable. Canonical/API/bootstrap hashes match; frontend deployment is
still required for the general card and new lead-menu controls.
See [application evidence](supabase/validation/20261111_lead_site_automation_snooze.md).

## Records relation validation and recoverable Trash — applied (2026-11-11 UTC)

Applied only `20261111032000` through `20261111032300` to linked project
`rnjgeloamtszdjplmqxy` at **03:15:48 UTC**, independently verified at **03:16:13 UTC**.
The four migrations add relation admission, recoverable subtree Trash, selective
batch restore and background safeguards. Existing policies are preserved with
additive active-only SELECT restrictions; no records were moved to Trash.
Unapplied drafts were renumbered to avoid the applied snooze timestamp collision.
Frontend/canonical/bootstrap sources and hashes match; **196 files / 51 upgrades**,
52 local migration tests and six bootstrap validator tests passed. Browser E2E and
full bootstrap replay remain unverified. See [execution evidence](supabase/validation/20261111_records_trash.md).

## Conversation automation snooze — applied (2026-11-11 UTC)

Applied only `20261110230000_conversation_automation_snooze.sql` to linked project
`rnjgeloamtszdjplmqxy` at **00:26:19 UTC**, independently verified at **00:26:29 UTC**.
Default ON is four hours after a new human reply; zero is explicit opt-out.
The final source includes database authorization for snooze changes and protection
against direct client edits to the human-reply timestamp. Only `public` was eligible.
No existing messages/conversations were updated and assignments are unchanged.
API/canonical/bootstrap copies and manifests match; nine SQL regressions and six
bootstrap-validator tests pass (**192 files / 47 upgrades**).
Application deployment and the remaining code-review fixes are still pending.
See [application evidence and remaining issues](supabase/validation/20261110_conversation_automation_snooze.md).

## Task creation idempotency — applied (2026-11-10 UTC)

Reverified using local credentials on **2026-11-11 at 00:30:39 UTC**: exact-source
history, nullable key and valid unique index still match. No DDL was replayed.
The subsequent API executor/cache/response-mapping repairs require no new migration.

Applied only `20261111010000_task_creation_idempotency.sql` to linked project
`rnjgeloamtszdjplmqxy` at **23:56:37 UTC**, using this repository's local credentials.
Independent read-only verification at **23:56:45 UTC** confirmed exact-source history,
nullable `public.tasks.creation_key` and the valid unique site/lead/key index.
RLS and table privileges are unchanged; no existing task rows were modified.
API, canonical and bootstrap copies are byte-identical. Bootstrap validation covers
**192 files / 47 upgrades**; six validator tests and 56 API task tests pass.
API deployment is still required to send the keys and suppress duplicate notifications.
See [application evidence and rollout limits](supabase/validation/20261110_task_creation_idempotency.md).

## Shipment carrier documents — applied (2026-11-10 UTC)

Applied only `20261109223000_shipment_carrier_documents.sql` to linked project
`rnjgeloamtszdjplmqxy` at **00:22:24 UTC**, using this repository's local credentials.
Independent read-only verification at **00:22:57 UTC** confirmed exact-source
migration history, table RLS, nine policies and the private 10 MiB PDF bucket.
The preexisting Storage denial for location-restricted users remains unchanged.
Canonical frontend/schema copies are byte-identical. No business rows were changed.
Bootstrap remains unchanged pending a reviewed Storage-aware packaging update.
See [application evidence and limitations](supabase/validation/20261110_shipment_carrier_documents.md).

## Procurement INSERT RETURNING — applied (2026-11-08 UTC)

Applied only corrected `20261106110000_procurement_workflow_insert_returning.sql`
at **01:32:29 UTC**, independently verified read-only at **01:32:37 UTC**.
The caller-bound SECURITY DEFINER candidate policy helper fixes INSERT RETURNING
without granting authenticated access to the privileged membership helper or private
classifier. Exact-source history, helper definitions/ACLs and restrictive policies
passed verification; API/schema copies are byte-identical. Six real PostgreSQL
regressions (including revoked membership privileges), one confidentiality test,
and bootstrap validation passed before application. No production business DML.
Excluded from bootstrap because its confidentiality prerequisite is not packaged.
See [application evidence and TLS limitation](supabase/validation/20261108_procurement_workflow_insert_returning.md).

## Customer support inbound command receipts — applied (2026-11-05 UTC)

Applied only `20261105193000_customer_support_inbound_commands.sql` to the linked
DB, with transaction locks and exact-source history; independently verified at
**22:26:28 UTC**. Only `public` was eligible. Columns, constraints, primary index,
RLS and SELECT/INSERT/UPDATE-only service-role privileges passed catalog checks.
API, canonical and bootstrap copies are byte-identical; package validation covers
**190 files / 45 upgrades**. No customer reads/writes, sends, replays or deployment
were performed. Existing dirty work is retained. PostgREST reload was notified;
HTTP availability and end-to-end customer responses remain unverified.
See [application evidence and scope](supabase/validation/20261105_customer_support_inbound_commands.md).

## Customer support audio receipts (2026-11-05 UTC)

Applied `20261105200000_customer_support_audio.sql` to linked Makinari at
19:59:49 UTC, transactionally with exact-source migration history. Independent
post-commit verification confirmed RLS, receipt constraints and service-role
SELECT/INSERT/UPDATE only (**no DELETE or TRUNCATE**). PUBLIC, anon and authenticated
have no table privileges. Only `public` was eligible; no customer rows were read.

API, canonical and bootstrap SQL are byte-identical. The fresh-QA package now
contains **189 files / 44 upgrades**; full expanded replay remains unverified.
See [application evidence and test scope](supabase/validation/20261105_customer_support_audio.md).

## Sandbox funding outcome (2026-11-05 UTC)

Applied `20261106104500_sandbox_insufficient_funding_outcome.sql` to linked Makinari
at 19:55:22 UTC using this repository's local PostgreSQL credentials. Insufficient
funding now returns a failed business outcome after full rollback of the failing
RPC batch; technical errors still propagate. No customer balances or history were
rewritten. Canonical API/schema/bootstrap SQL is byte-identical; the fresh-QA
package now contains **188 files / 43 upgrades**. Full package replay is not claimed.

The deployed API at application time was `08fbd29a`: it fails closed on the new
outcome but labels it generic reconciliation pending. Deploy the API's structured
outcome reader to restore the specific funding category. See
[verification and deployment limitation](supabase/validation/20261105_sandbox_funding_outcome.md).

## Requirement admission and workspace recovery (2026-11-04 UTC)

Applied `20261104110000_requirement_site_credit_admission.sql` and
`20261104111000_missing_requirement_workspace_recovery.sql` to linked Makinari
using this repository's local PostgreSQL credentials. Both migrations and their
exact-source history entries committed atomically. Admission excludes archived
sites and nonpositive/missing credit balances; the service-only recovery RPC
permits lease/version-fenced retirement of a confirmed-missing workspace reference.

Canonical API, schema repository and fresh-QA copies are byte-identical. The
bootstrap now contains **187 files / 42 upgrades**, without changing the immutable
baseline or the QA-local webhook guard. See [application verification](supabase/validation/20261104_requirement_admission_recovery.md).
No runtime deployment or manual requirement resume was performed. The new RPC
does not create sandboxes by itself: automatic reprovisioning requires the API
runtime changes. Full replay of the expanded fresh-QA package remains unverified.

## API procurement workflow update (2026-11-03)

Independently rechecked against the linked database on 2026-11-04 03:20 UTC:
all three versions are recorded exactly once with byte-identical canonical SQL;
13 webhook triggers, eight restrictive policies, cloud protection and event
identities are installed. They were not replayed. See the verification below.

The three forward migrations `20261104100000`, `20261104101000` and
`20261104102000` were applied atomically to linked Makinari using this repository's
local PostgreSQL configuration. Canonical SQL is synchronized from the sibling API,
including the previously installed `20261031010000_procurement_mcp_bridge.sql`.
See [application verification](supabase/validation/20261103_api_procurement_workflows.md).

Historical API files absent from migration history were **not** blindly replayed:
the installed schema includes later replacements and history is incomplete.
The fresh-QA bootstrap remains at **185 files / 40 upgrades**. These new canonical
migrations are not yet packaged there: the event dispatcher replacement needs a
reviewed QA-local destination guard, and confidentiality has classification backfills.
No API deployment or live outbound business-flow test was performed.

## Requirement date scope update (2026-11-03)

Migration `20261103210000_requirement_created_or_updated_scope.sql` is applied
to linked Makinari and included as a byte-identical canonical/bootstrap upgrade.
The active scheduler uses created **OR** updated since 2026-09-01 UTC, while
preserving ownership, leases, holds, pauses, budgets and permissions. The current
bootstrap now has **185 files / 40 upgrades**; its immutable baseline is unchanged.
See [application verification](supabase/validation/20261103210000_requirement_date_scope.md).
Full replay of this updated bootstrap and end-to-end execution remain unverified.

## Historical fresh-QA bootstrap checkpoint (2026-10-31)

`bootstrap/` contains a schema-only capture of the current Makinari application's
five schemas, split into bounded SQL migrations with a hash/provenance manifest.
It includes current commerce tables, permission RPCs, grants, RLS, custom Auth
profile trigger and Storage policies. No customer rows, Auth identities, Vault
values, buckets or Storage objects were copied.

The immutable 2026-10-27 capture is followed by 39 canonical forward migrations
through `20261030230000_procurement_storage_admission.sql`, including procurement,
POS checkout cancellation and cloud document/session persistence. See
[the QA update handoff](supabase/validation/20261030_qa_update.md) for validation
scope and remaining installation/test gates. `bootstrap/upgrades-20261030.json`
records upgrade hashes separately from the original capture provenance.

The Storage admission correction was applied separately to the explicitly
authorized linked Makinari project. See
[remote application verification](supabase/validation/20261030230000_storage_admission.md)
for exact SQL/hash/history checks and verification limits. This does not authorize
replaying the bootstrap or other pending migrations on that project.

Use `bootstrap/` **only for a fresh isolated QA Supabase**. It replaces replay of
the historical migration directory for fresh QA; never apply it on top of an
existing database. The historical migrations remain unchanged.

The direct legacy messages webhook with embedded external configuration is omitted.
The configurable workflow dispatcher retains its real behavior but accepts only
local HTTP destinations. Configure the local receiver and secret separately; do
not copy production Vault values. This intentionally differs from production
outbound delivery while retaining business/RLS behavior.

```bash
python3 scripts/validate-bootstrap.py
PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_validate_bootstrap.py
```

Validation covers file hashes, bounded chunks, timestamps, required objects and
outbound safeguards. On 2026-10-27, fresh Supabase replay completed all 145 chunks
after local portability corrections for `public`, the non-login coordinator role
and Supabase-owned default ACLs. That evidence covers the baseline only, not the
39 added upgrades. The 183-file baseline-plus-upgrades replay succeeded on the
isolated Azure QA on 2026-10-31; the subsequent Storage admission correction was
applied separately and its credential sharing browser scenario passed. **Full
fresh 184-file replay, complete module E2E
and users/fixtures remain pending**; replay is not a business-flow certificate. Compatible local Supabase
must provide Auth, Storage, pg_net/Vault and listed extensions. Existing platform
schemas are not replaced. Roles referenced by captured grants require the platform's
normal role setup. Storage bucket metadata and test objects must be provisioned
separately with synthetic data.

The baseline exported no rows. Forward migrations additionally create the private
`procurement-credentials` bucket and backfill replenishment queues and historical
tender policy bindings from the target database itself; they contain no exported
customer data. The installer packages the manifest-verified files in `bootstrap/`,
not the historical migration directory. Publishing Git changes does not update an
existing QA database. Never replay the captured baseline onto an existing target.

The installer discovers `makinari-db-scheme/bootstrap` from its source repositories
and verifies the manifest. Its QA command still requires schema acknowledgement
and a fresh unused QA ID; production and previously applied migrations are untouched.

## Private schema export

`scripts/export-schema.cjs` reads local PostgreSQL variables from `.env.local` and
exports schema-only DDL under ignored `.exports/` with private permissions. It can
use the cached matching Session pooler when the direct project endpoint is IPv6-only.
It never exports rows or platform-owned schemas. Raw function/trigger DDL may contain
embedded secrets: review it privately, never commit the raw export. The exporter
currently reuses the sibling frontend's installed dotenv and a PostgreSQL 17 binary
directory (`PG_BIN` overrides the default); it is not a portable standalone CLI yet.

`scripts/build-bootstrap.py` performs the reviewed transformations and preserves
historical files. It refuses overwriting an existing bootstrap. Subsequent captures
need explicit versioning/review, not editing an applied migration.

## Prerequisites

- Node.js (for Supabase CLI)
- A Supabase project ([dashboard](https://supabase.com/dashboard))

## Initial setup (one-time)

This repo already has `supabase init` applied. Use **npx** so you don't need a global install.

### 1. Login to Supabase CLI (opens browser)

```bash
npx supabase login
```

### 2. Link to your remote project

Get your **Project ref** from Supabase Dashboard → Project Settings → General.

```bash
npx supabase link --project-ref <PROJECT_REF>
```

### 3. Pull remote schema into migrations

This generates a migration SQL file with tables, FKs, indexes, constraints, enums, functions, and RLS policies. `jsonb` columns stay as `jsonb` in SQL.

```bash
npx supabase db pull
```

### 4. (Optional) Generate TypeScript types for your app

```bash
npx supabase gen types typescript --linked > supabase/types.ts
```

> **Alternative:** Install globally with `npm i -g supabase` and run the same commands without `npx`.

Commit `supabase/types.ts` or regenerate in CI when the schema changes.

## Repo layout after setup

- `supabase/migrations/` – SQL migrations (source of truth; use `supabase db pull` to sync from remote).
- `supabase/config.toml` – Local Supabase config (optional overrides).
- `supabase/types.ts` – Generated TS types (optional, from step 5).

## Refreshing the schema from Supabase

When the remote DB changes (e.g. via Dashboard or another tool), pull again:

```bash
npx supabase db pull
```

Then commit the new migration. To refresh types:

```bash
npx supabase gen types typescript --linked > supabase/types.ts
```

## RLS, triggers, extensions, grants

If you use RLS policies, triggers, Postgres extensions, or custom grants, `supabase db pull` should capture them. If something is missing, you can:

- Inspect the generated migration under `supabase/migrations/`.
- Add manual migrations for anything not reflected (e.g. `CREATE POLICY`, `CREATE TRIGGER`, `GRANT`).

If you have an existing `schema.sql` or a list of extensions/policies, we can align the pull output with it.

# OpenRouter optional customer BYOK — applied

Target: linked Makinari project `rnjgeloamtszdjplmqxy`. Connection uses this
repository's ignored `.env.local` PostgreSQL credentials and matching cached
session pooler. Credentials were not printed, copied to tracked files or changed.

## Authorized scope

Only these ten migrations, in timestamp order:

1. `20261112010000_openrouter_customer_connections.sql`
2. `20261112020000_openrouter_runtime_dispatch.sql`
3. `20261112021000_openrouter_command_routing.sql`
4. `20261112022000_openrouter_plan_routing.sql`
5. `20261112030000_openrouter_setup.sql`
6. `20261112040000_openrouter_pilot_approval.sql`
7. `20261112050000_openrouter_dispatch_attribution.sql`
8. `20261112060000_openrouter_customer_video_jobs.sql`
9. `20261112071000_requirement_plan_private_routing.sql`
10. `20261112072000_openrouter_customer_video_durability.sql`

The original source of `71000` is the sibling API repository; the other nine
originate in the web repository. Canonical and bootstrap copies are byte-identical
and manifest-hashed. No unrelated pending migration is included in this operation.

## Preflight and safe application

- The linked project, direct host and cached pooler user identify the same project.
- PostgreSQL 17.6, authenticated as the database owner, using TLS. This records
  encrypted transport, not a claim of certificate identity verification beyond
  the repository's configured `PGSSLMODE`.
- No named migration history entries or colliding BYOK tables existed.
- Required core columns, effective-license helper and exact eight-argument
  `patch_agent_requirement_plan` signature exist. The function's original body
  is preserved by the `71000` rename/wrappers.
- Preflight found 375,468 site-scoped commands and 2,384 site-scoped plans, with
  no missing referenced sites. Backfills create private **platform** attribution;
  they do not update the original commands/plans or infer customer funding.
- The first attempt exceeded the 120-second statement deadline during per-row
  foreign-key verification on the large command table. The whole transaction
  rolled back. An independent history/catalog read confirmed zero applied rows
  and no BYOK tables afterward.
- Only while still unapplied, `21000` was optimized to copy the snapshot first,
  then add and validate the same command foreign key set-wise inside its
  transaction. The FK is not left unvalidated; normal future writes remain checked.
  Updated source/canonical/bootstrap hashes match. Focused PostgreSQL regression
  passed after this adjustment.
- The approved batch uses one transaction, a deployment advisory lock, an
  exclusive migration-history lock, a 5-second lock wait limit and bounded
  statements. Exact-source history entries are written in that transaction.
  The final checks require matching snapshot backfill counts, unchanged existing
  table ACL/RLS flags, and no customer connections or rollout approvals.

## Rollout restrictions

Applying schema does not enable BYOK. No environment flags, customer credentials,
site approvals, API deployment or paid provider calls are part of this operation.
The customer/approval tables must remain empty after installation. Before later
activation, deploy the matching API/web code, review the gap between migration-time
legacy backfills and code rollout, and perform separately authorized low-budget
provider and billing acceptance checks. Keep durable routing reads enabled during
any future admission rollback; never reassign existing customer work to platform.

## Repository validation

- Static bootstrap: 210 files / 65 canonical upgrades, with unchanged captured
  baseline and local-only webhook protections.
- Seven bootstrap regression tests cover manifest hashes, coverage, source drift,
  and the two reviewed private-attribution backfills.
- Source API connection/authorization suite: 17 suites / 118 tests passed before
  application; optimized command FK suite: three PostgreSQL tests passed.
- Fresh complete Supabase bootstrap replay and live provider E2E are not claimed.
- Private SQL, logs, snapshots and receipts are under ignored
  `.exports/openrouter-20261112/`. No customer rows or credentials are in this report.

## Confirmed outcome

The revised transaction committed at **2026-11-12 20:28:41.078798 UTC**. Independent
connections verified the result at **20:29:07.847057** and **20:29:08.052863 UTC**:
The [sanitized machine-readable receipt](20261112_openrouter_byok_receipt.json)
contains all ten source hashes and the verification flags.

- All ten version/name/history records exist and their stored SQL matches the
  canonical source exactly, including the optimized command backfill.
- All ten newly created tables have RLS enabled. No `PUBLIC`, `anon` or
  `authenticated` table grants or function EXECUTE privileges were found on the
  new BYOK objects or requirement-plan wrappers.
- All foreign keys are validated; all indexes are valid and ready.
- 375,468 command pins and 2,384 plan pins exist, all attributed to platform.
- Connections, approvals, dispatches, receipts, video jobs and setup attempts
  remain empty. There was no inference charge or provider execution.
- Both public requirement-plan signatures remain executable by `service_role`.
  The renamed internal implementation is not; its body checksum was preserved.
- `service_role` cannot insert rollout approvals. Schema reload was notified
  transactionally. Existing core/billing table ACL/RLS flags were checked before
  commit and were not changed by this batch.

Supabase security advisors were queried after application. The informational
[RLS enabled without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)
notice is expected for these server-only client-denied tables; it is not an
instruction to add browser access. Existing unrelated advisor findings were not
remediated or claimed clean by this operation.
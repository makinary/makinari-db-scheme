# Sandbox insufficient funding outcome — application verification

Applied to Makinari `rnjgeloamtszdjplmqxy` on 2026-11-05 at 19:55:22 UTC using
this repository's ignored `.env.local` PostgreSQL credentials and identity-matched
session pooler. Secrets were not printed or passed in command arguments.
TLS was required and `pg_stat_ssl` confirmed SSL; certificate verification is
not claimed.

Migration: `20261106104500_sandbox_insufficient_funding_outcome.sql`

SHA-256: `6741acdda6568f022967f3480f6f95849fea8fbcc04fe57690c9e0b3d59e3a36`

## Application

- Only this migration was applied, not unrelated pending migrations.
- Exact live function precondition, advisory lock, exclusive migration-history
  lock, five-second lock timeout and 60-second statement timeout were used.
- The function replacement and exact canonical SQL history entry committed in
  one transaction. Existing function identity, owner and ACL were preserved.
- Initial guarded attempts rolled back before DDL due to whitespace mismatch
  in the client-built comparison. Comparing the exact JSON-decoded function
  definition corrected the guard; no schema drift was found.
- No billing RPC was invoked as a production test; no balances, budgets, sessions,
  or historical meters were manually modified. Debt remains unpaid and visible.
- Rollback is per failing RPC batch/page. Prior successful pagination calls are
  already committed; their watermarks prevent duplicate charging on retries.
- Canonical schema and bootstrap copies match the API source; manifest hashes
  and regression counts are updated to 188 files / 43 upgrades.

## Deployment limitation

Production API `08fbd29a` was verified READY before application. Its reader rejects
`success:false` safely, but classifies structured insufficient funding as generic
reconciliation pending until the new API is deployed. It does not assert success,
advance full-history completion, or permit additional compute on this failure.
This operation did not deploy API code, fix provider suppression, or close the
65 historical missing resources.

## Post-commit verification

A separate read-only connection verified exactly one history row containing the
byte-identical canonical SQL, owner `postgres`, SECURITY DEFINER and fixed
`search_path=public, pg_temp`. The funding sentinel guard and structured outcome
are present. Execute privileges are false for anon/authenticated and true for
service_role. Static manifest validation and all six validator tests passed;
`git diff --check` passed. Full fresh-Supabase replay and the next scheduled
production settlement execution have not been verified by this operation.

Private preflight, failed guards and committed application receipts are retained
under ignored `.exports/sandbox-funding-20261105/` with private permissions.
# POS inventory debit receipts — applied

## Target and authorized scope

Target: linked Makinari project `rnjgeloamtszdjplmqxy`. Only
`20261114000000_order_line_inventory_receipts.sql` was applied, using this
repository's ignored PostgreSQL credentials and validated session pooler over
TLS. No credentials were printed or copied to tracked files.

Commit observed **2026-11-14 03:51:06.407837 UTC**; independent verification
completed **03:51:17.126257 UTC**. The migration history contains exactly one
entry with the canonical SQL source. Application used a transaction, advisory
deployment lock, exclusive migration-history lock, five-second lock timeout and
ninety-second statement timeout. No other pending migration was applied.

## Verified results

- `order_line_inventory_receipts` has RLS and its scoped read policy enabled.
- Anonymous SELECT and direct authenticated/service-role writes are denied.
- The insert seed trigger is enabled; all four receipt constraints are validated.
- `reconcile_order_line_inventory` admits authenticated and service-role callers,
  validates site/order/line/location scope, and records inventory changes and
  cumulative processed/debited/refunded budgets atomically.
- `resolve_order_line_inventory_review` is executable only by `service_role`.
  The trigger function is not directly executable by client or service roles.
- Row counts stayed **2 stock levels / 1,194 order lines / 609 orders**.
- The receipt table contains **zero rows** immediately after application. No
  old movement history was guessed, no legacy reconciliation was performed,
  and no business stock/payment/shipment mutation was tested remotely.

Preflight confirmed TLS, absent target history/objects, required columns and
functions, and finite inventory. PostgREST schema reload was notified.
Sanitized evidence: [receipt](20261114_pos_inventory_receipts_receipt.json).
Private SQL/logs remain under ignored `.exports/pos-inventory-20261114/`.

## Repository validation

Frontend, canonical migration and fresh-QA bootstrap copies are byte-identical:
SHA-256 `6629124a4d1e42ed831ee275b2bf52b0ca2643e3446fdaba199c764def61e622`.
Both manifest entries and migration counts were updated without changing the
captured baseline or unrelated working-tree edits. Static validation:
**223 migration files / 78 canonical upgrades**, all seven validator tests pass.
The two focused application suites pass **48 tests**, including executable
disposable local PostgreSQL cases for replay, concurrency, tenant/RLS denial,
rollback, zero stock, bounded refunds and historical reconciliation.

## Rollout and advisory boundaries

Matching application code still needs deployment. Old application writers do not
update these receipts: coordinate their retirement during rollout. Historical
orders stay ambiguous until an authorized operator verifies actual movements
and records an audited attestation; do not infer a prior debit from completion
or payment status. The migrated schema does not itself change POS UI behavior.

Supabase security advisors were queried after application. Project-wide findings
were not remediated by this narrowly scoped migration. The authenticated
SECURITY DEFINER inventory RPC is intentional and performs explicit scope checks.
References: [database advisor guide](https://supabase.com/docs/guides/database/database-linter)
and [SECURITY DEFINER review](https://supabase.com/docs/guides/database/database-linter?lint=0024_authenticated_security_definer_function).

No commit, push, frontend/API deployment, historical backfill or production
transaction test was performed.
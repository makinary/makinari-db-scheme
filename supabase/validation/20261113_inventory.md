# Inventory movements, transfer orders and partial bill receipts — applied

Target: linked Makinari project `rnjgeloamtszdjplmqxy`, using this repository's
ignored PostgreSQL credentials and validated session pooler over TLS. Credentials
were not printed, changed or copied into tracked files.

## Authorized scope

Only these ten inventory migrations were applied, in order, in one transaction:

1. `20261113170000_inventory_movements.sql`
2. `20261113190000_inventory_writer_coordination.sql`
3. `20261113200000_inventory_receiving_responsibility.sql`
4. `20261113210000_inventory_transfer_orders.sql`
5. `20261113210100_inventory_transfer_legacy_projection.sql`
6. `20261113210150_inventory_transfer_partial_dispatch.sql`
7. `20261113210200_partial_bill_inventory_receipts.sql`
8. `20261113210300_inventory_transfer_stock_events.sql`
9. `20261113210400_inventory_receipt_write_boundary.sql`
10. `20261113210500_accounting_preserve_received_bill_lines.sql`

Commit observed **2026-11-13 23:30:57.997618 UTC**. Independent connection
verification completed **23:31:31.122946 UTC**. Every recorded migration name and
SQL statement matches the canonical/frontend source exactly. No other pending
migration was applied.

The application used a deployment advisory lock, exclusive migration-history
lock, five-second lock timeout and ninety-second statement timeout. The preflight
confirmed the project reference, TLS, prerequisites, absent target history/objects,
finite stock quantities and valid historical receipt budgets.

## Confirmed results

- All eight new public inventory/history/request tables have RLS enabled.
- Anonymous roles cannot SELECT them. Authenticated clients cannot directly
  INSERT, UPDATE or DELETE them; authorized operations go through scoped RPCs.
- Batch, transfer creation/transition and partial bill receipt RPCs are executable
  by authenticated users, not anonymous or service-role clients.
- The atomic location delta RPC also admits explicitly authorized server commerce
  paths through their server-only service client.
- The internal batch implementation cannot be executed by client roles.
- Transfer constraints are validated; temporary receipt capability storage is empty.
- Existing row counts remain **2 inventory levels / 71 purchases / 157 purchase
  items**. No receipt, transfer or movement rows were created by migration backfill:
  the target had no completed stock receipts and no previous movement history.

The migrations add immutable history, actor/payload idempotency, post-lock
authorization, requested/dispatched/received/returned/writeoff budgets, receiver
attribution, and protection against edits that would invalidate received bill
lines. They do not automatically perform business transfers or credit inventory.

## Repository validation

Canonical `supabase/migrations`, frontend sources and fresh-QA bootstrap copies
are byte-identical and manifest-hashed. Static package validation passed:
**222 migration files / 77 canonical upgrades**, with all seven validator
regressions passing. The immutable captured baseline was not regenerated.

Before application, **137 focused tests across five suites** passed using actual
disposable, socket-only local PostgreSQL. That is not a production mutation smoke
test or a complete fresh-Supabase replay. Evidence without secrets or customer
identities is in [the sanitized receipt](20261113_inventory_receipt.json).
Private SQL/logs remain in ignored `.exports/inventory-20261113/`.

## Advisory and rollout boundaries

Supabase security advisors were queried after application. Client-denied internal
request tables are intentionally RLS-protected without client policies. The new
authenticated SECURITY DEFINER RPCs intentionally validate users, resources and
locations; private implementations remain revoked. Project-wide preexisting
advisories were not changed in this inventory rollout. References:

- [RLS enabled without policy](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy)
- [Database advisor reference](https://supabase.com/docs/guides/database/database-linter)

PostgREST schema reload was notified. Matching frontend/API code still requires
deployment, and external assistant tool registration is separate. No deployment,
commit, push, real receipt/transfer mutation test or browser E2E against production
was performed. Reload older application tabs after the code rollout.
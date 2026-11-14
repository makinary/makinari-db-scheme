# Inbound command receipts — applied 2026-11-05 UTC

## Reverification — 2026-11-06 UTC

- Used this repository's ignored connection helper and credentials, with linked
  target checks and SSL. Database and owner checks passed.
- At **22:12:08.413192 UTC**, a read-only transaction confirmed exactly one history
  entry for `20261105193000` and byte-exact SQL/name equality with the canonical
  migration. Catalog assertions passed for columns, defaults, constraints, indexes,
  role grants and RLS in `public`. No customer rows were accessed.
- No DDL was replayed: the migration is already applied. API, canonical and
  bootstrap SQL copies remain byte-identical.
- Offline validation passed: **190 migrations / 45 upgrades**, **9 Python tests**,
  and **2 Node/PGlite tests**.
- The separate Customer Support `read_document` routing repair is API TypeScript
  only; it requires an API deployment, not a new database migration. This database
  verification does not deploy that repair or establish document-reading E2E success.

The confirmed missing live `public.customer_support_inbound_commands` blocker is
repaired. Only migration `20261105193000` was applied using the existing ignored
connection helper and db-scheme credentials, with linked-target checks and SSL.
No customer records were read or written; no sends, replays, other migrations or
deployments were performed. Existing dirty edits were preserved.

## Live evidence

- **22:25:30.751738 UTC:** read-only preflight confirmed expected database/owner,
  SSL, absent table and absent history version. Audio `20261105200000` was already
  recorded. Only `public` had an eligible commands relation; its id is UUID.
- API claim/bind source uses the six-column contract and only INSERT/SELECT/UPDATE;
  no API runtime changes were needed.
- One transaction used a 5s lock timeout, 60s statement timeout, the existing
  `makinari-reviewed-forward-migrations` advisory lock and EXCLUSIVE history-table
  lock. Preconditions were rechecked under locks. Canonical SQL and catalog
  assertions ran before the exact source was inserted as one history statement.
  The backdated version was inserted explicitly, without replaying audio or any
  intervening migration. `NOTIFY pgrst, 'reload schema'` was committed with it.
- **22:26:26.435102 UTC:** post-commit history count **1**, exact source **true**.
- **22:26:27.910696–22:26:28.042821 UTC:** independent read-only verification passed
  columns/types/nullability/default, primary-key index validity/order, identity
  checks, local commands FK with no cascade, RLS enabled without policies, no
  PUBLIC/anon/authenticated grants, and effective service-role SELECT/INSERT/UPDATE
  only (no DELETE/TRUNCATE/REFERENCES/TRIGGER). Service-role BYPASSRLS and public
  schema USAGE also passed. No customer-table SELECT was issued.
- Reusable catalog assertions: `20261105193000_customer_support_inbound_commands.sql`
  in this validation directory. Ignored application helper and sanitized evidence:
  `.exports/apply-customer-support-inbound.cjs` and
  `.exports/customer-support-inbound-verification.log`.

PostgREST HTTP availability remains unverified: the authorized db-scheme environment
has database connection credentials but no Supabase HTTP URL/service key. No other
credential source was used. Reload notification is not proof of cache convergence.
Actual customer response delivery, full Supabase bootstrap replay and end-to-end
behavior remain unverified; no replay was attempted. Future tenant provisioning
must include this migration. Do not replay the captured bootstrap on an existing DB.

## Changes

- Source: API `supabase/migrations/20261105193000_customer_support_inbound_commands.sql`.
- API, canonical and bootstrap copies are now byte-identical.
- API source was aligned only for privilege hardening: revoke ALL from `service_role` as well as PUBLIC,
  anon and authenticated before granting SELECT/INSERT/UPDATE, matching audio's
  protection against additive default DELETE/TRUNCATE grants. Added explanatory comment.
- Both manifests register SHA-256
  `4ed8cc9a534bb3711653bb0747dcd68e13f3b47847181803967ebe9b8154b0c5`
  in timestamp order. Baseline, previous entries and validation claims are unchanged.
- Eligible schemas are public and literal `app_` prefixes with a commands relation.
  Future tenant provisioning must include this DDL. The migration intentionally
  fails on an existing receipt table rather than concealing drift.
- Identity remains `(site_id, connection_id, origin_message_id)`. Nullable command
  binding and mandatory owner token preserve ambiguous/unbound receipts. No expiry,
  delete, cascading deletion or automatic reclaim was introduced. This does not
  make service-role UPDATE immutable or implement application-level owner fencing.

## Offline validation

Run from the db-scheme root:

```sh
python3 scripts/validate-bootstrap.py
python3 -m unittest discover -s scripts -p 'test_*.py' -v
/opt/homebrew/bin/node --test scripts/test_customer_support_inbound_commands.mjs
```

Post-application results: static validation **190 migrations / 45 upgrades**;
**9 Python tests** and **2 Node/PGlite tests** passed. API offline Jest regressions
also passed **2 suites / 8 tests** (`inbound-command-idempotency.test.ts` and
`command-identity.test.ts`, via `jest.support-response.config.js --runInBand
--runTestsByPath`). PGlite uses the already-installed sibling
API dependency and an in-memory database only; no package installation, credentials
or environment-file reads are needed.

Execution regression covers column types/nullability/default, eligible/quoted and
ineligible schemas, schema-local command foreign keys, identity collisions and
site/connection/origin separation, empty identity rejection, mandatory owner,
old unbound duplicate rejection, command binding, non-cascading command deletion,
RLS without policies, and exact role ACLs under deliberately broad default grants.
It executes service-role SELECT/INSERT/UPDATE and rejects DELETE/TRUNCATE. Static
checks enforce bootstrap equality, hashes/order and absence of reclaim machinery.
This is focused PostgreSQL execution, not a full Supabase replay or concurrency test.

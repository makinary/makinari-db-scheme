# Instance ownership and atomic quotation context — applied

Target: linked Makinari project `rnjgeloamtszdjplmqxy`. This repository's ignored
PostgreSQL credentials and matching cached session pooler were used over TLS.
No credentials were printed, changed or copied into tracked files.

## Authorized application

Only these two migrations were applied, in order, in one transaction:

1. `20261113160000_instance_ownership_rls.sql`
2. `20261113180000_atomic_catalog_item_requirement.sql`

Commit observed **2026-11-13 21:26:40.148628 UTC**. Independent catalog/history
verification completed at **21:26:47.541490 UTC**. Both stored migration names
and SQL match the canonical source exactly. No unrelated pending migration,
including inventory movements, was applied.

The batch used a deployment advisory lock, exclusive migration-history lock,
five-second lock timeout and sixty-second statement timeout. Preflight confirmed
the project identity, missing named history entries, all twenty expected tables,
existing global catalog-item uniqueness, and existing instance security triggers.

## Confirmed controls

- 100 new policies: four authenticated operation guards and one anonymous denial
  on each of twenty protected tables. All are restrictive; existing permissive,
  location and procurement policies remain in place.
- All twenty tables retain RLS. Existing FORCE RLS settings are not changed.
- Restricted active members require matching instance `user_id` or `created_by`.
  Linked resources require visible same-site parents; node-context edges require
  both visible endpoints, and infrastructure diagnostics require a visible plan.
- Browser inserts must attribute instances to the authenticated actor; browser
  updates cannot change site/attribution. The new attribution trigger coexists
  with the three previously installed instance triggers.
- Browser roles have no TRUNCATE privilege on the protected tables.
- `ensure_catalog_item_requirement(uuid)` is SECURITY INVOKER. Authenticated
  callers may execute it; anonymous and service-role callers cannot. Its item
  lock serializes creation, and caught admission/uniqueness failures roll back
  every insert without depending on DELETE permission.
- Instance row count remained **1,064** before and immediately after application.
  These migrations do not insert/update/delete business rows or backfill ownership.

## Live read-only smoke checks

One existing restricted member was checked by setting authenticated SQL role and
JWT claims within read-only transactions. No login token or customer identity is
included in this report.

- Visible instances: **2**; visible instances attributed only to others: **0**.
- A sampled foreign instance queried directly by ID returned **0** rows.
- A sampled log from a foreign instance queried directly by ID returned **0** rows.

An initial full-site log count exceeded the twenty-second diagnostic deadline
inside the existing site-role helper. It was read-only and made no changes. The
subsequent indexed/ID-bounded checks passed. This is not a performance benchmark
or proof of all privileged API/RPC boundaries.

## Repository validation and remaining rollout

Canonical/frontend/bootstrap copies of both migrations are byte-identical and
manifest-hashed. Static bootstrap inventory: **212 files / 67 upgrades**; all
seven validator tests passed. The captured baseline remains unchanged. Full
fresh Supabase replay is not claimed.

Frontend repair validation: **113 focused tests** passed, including real isolated
PostgreSQL ownership, hidden-link rollback and concurrent-creation checks plus
React permission-cache behavior. TypeScript and changed-file lint passed.
The broader quotation suite had one unrelated email-language assertion failure.

Deploy the matching frontend/Server Action changes to activate atomic quotation
creation and permission-generation caching. Reload older browser tabs. No commit,
push, frontend/API deployment, production build, customer mutation smoke test or
full browser E2E was performed. Private SQL, logs and receipts are retained under
ignored `.exports/instance-ownership-20261113/`.
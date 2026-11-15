# API timeout contention — applied

## Target and scope

Target: linked Makinari project `rnjgeloamtszdjplmqxy`. The user authorized applying
only these two forward migrations using this repository's ignored credentials:

- `20261114210000_requirement_economic_recovery_contention.sql`
- `20261114210100_catalog_backfill_contention.sql`

Commit observed **2026-11-15 02:34:00.362404 UTC**. Independent verification
completed **02:34:02.124152 UTC**. Connection used the validated session pooler
over TLS. Credentials and raw definitions were not copied into tracked evidence.

Preflight compared installed function bodies against reviewed API baselines and
confirmed both new history entries were absent. Application rechecked complete
definitions, including owners/grants/configuration, under a deployment advisory
lock and exclusive migration-history lock. Both complete migrations and history
entries committed in one transaction with five-second lock and ninety-second
statement limits. No unrelated historical migration was replayed or marked applied.

## Verified results

- Each new version has one history entry with exact canonical SQL source.
- Both installed function bodies exactly match the new migrations.
- Owners and client/service execution authorization are preserved.
- Both functions use local `lock_timeout=50ms`; no global timeout was increased.
- Requirement recovery rolls back a busy candidate and leaves it due for later
  recovery rather than waiting on mapping/session/receipt dependencies.
- Backfill durably queues a contended item before advancing its cursor; failed
  enqueue fails the transaction instead of silently discarding work.
- Synchronous `refresh_catalog_search_document` is unchanged.
- Refresh queue RLS and anonymous/authenticated write privileges are unchanged.
- No test requirement claim, billing renewal, catalog backfill or stock operation
  was executed remotely. Normal background activity was not stopped.
- PostgREST schema reload was notified at commit.

Sanitized evidence: [receipt](20261115_timeout_contention_receipt.json).
Private preflight/application/verification SQL and logs remain in ignored
`.exports/timeout-contention-20261115/`.

## Repository validation and limits

API, canonical and bootstrap SQL copies are byte-identical. Both bootstrap
manifests include matching SHA-256 hashes; captured baseline files are unchanged.
Static validation: **225 migrations / 80 canonical upgrades**, **seven validator
tests passed**. Prior focused API tests passed 12 requirement tests and nine
catalog tests, including disposable multi-session PostgreSQL contention cases.
Full fresh Supabase replay and real pgvector performance are not claimed.

The exact blocker from the original production timeout remains unidentified;
these are mitigations for reproduced contention, not proof that CPU/I/O or other
dependencies cannot time out. Observe normal scheduler progress, deferred queue
drain and query duration during rollout. Application deployment remains separate:
the inventory `created_at` query fix is web code, not part of these SQL changes.

Security advisors were queried after application; project-wide findings were not
remediated by this scope. The target functions remain denied to browser roles.
See the [database advisor remediation guide](https://supabase.com/docs/guides/database/database-linter).

No commit, push, web/API deployment or customer-data export was performed.
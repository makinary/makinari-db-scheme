# Conversation automation snooze — applied and independently verified

`20261110230000_conversation_automation_snooze.sql` is mirrored byte-for-byte
from API into canonical migrations and the manifest-verified fresh-QA bootstrap.
Applied using this repository's private `.env.local` PostgreSQL credentials and
linked session pooler to **rnjgeloamtszdjplmqxy**, only `public` eligible.

- Commit observed: **2026-11-11 00:26:19.813451 UTC**.
- Independent read-only verification: **2026-11-11 00:26:29.954781 UTC**.
- Transaction advisory lock, exclusive migration-history lock, 5-second lock
  timeout and 60-second statement/idle transaction timeouts.
- DDL and exact-source migration history committed atomically. PostgREST reload notified.
- No customer rows read or written for validation; no historical backfill, sends,
  application deployment, commits or pushes. Existing unrelated changes preserved.
- Verified columns/types/nullability, validated hours constraint, both enabled
  triggers, invoker functions, pinned search paths and revoked client EXECUTE.
- Table ACLs, RLS and FORCE RLS flags were checked unchanged in the transaction.
- TLS encryption verified (`require`); certificate identity (`verify-full`) not claimed.

Final source SHA-256 (API, canonical and bootstrap):
`3d1090a292077ad75be3ce66f408c41a2509f570b95fafe0105560c8db5a6df5`.
Private execution SQL/receipts are under ignored `.exports/conversation-snooze/`.

## Contract and security

- Nullable `automation_paused_until`, `last_human_reply_at` timestamps and
  `automation_snooze_hours` numeric (null = 4 hours, 0 = disabled, maximum 168).
- Insert-only human (`team_member`) trigger pauses even pending sends; a failed
  send stays paused until expiry or explicit resume. Delivery UPDATE retries do
  not extend the pause. Internal note markers are excluded.
- Event time is clamped to database statement time. Old history retains its
  original expiry; equal/older events cannot undo a manual resume. A later human
  message extends, but never shortens, the current pause.
- Zero hours still records the human timestamp for in-flight response detection.
  Setting zero on an already-paused conversation should also clear its pause;
  the frontend action performs both updates atomically.
- SECURITY INVOKER, pinned to `pg_catalog`, schema-qualified tables, no client
  EXECUTE grant. Existing RLS remains authoritative. Failure to update an eligible
  conversation rejects the human insert atomically rather than silently allowing
  automation to continue. Assignments/status are untouched.
- Each schema's message FK resolves to its own conversation. No message site ID
  is assumed; tenant/site authorization comes from existing conversation RLS.
- The previously unapplied draft was hardened before execution: a BEFORE
  INSERT/UPDATE trigger requires schema-local `user_can(site_id,'update')` for
  authenticated snooze changes, even when legacy RLS broadly permits the row.
  Direct client edits to `last_human_reply_at` are rejected; nested human-message
  ingestion updates retain caller authorization. Actual superuser/BYPASSRLS roles
  remain trusted. These functions are invoker-only and not client-callable RPCs.
- This is not a general repair of legacy RLS, client message authorship, or other
  privileged database functions. Nested trigger trust is a database-internal boundary.

## Rollout boundary

The operator migration targets `public` and existing `app_*` schemas that have
both chat tables. Canonical/frontend share public on Makinari. Apps public lacking
chat tables is not evidence that any tenant schema has been upgraded. Verify
each target explicitly before enabling snooze readers/writers.

The schema repository's bootstrap is **fresh-local-QA**, a schema-only public
baseline plus upgrades. It is not an existing-database upgrade command or proof
of Apps tenant provisioning. Never replay its baseline on an existing database.
An app-scoped migration system needs reviewed equivalent schema-local DDL; this
operator migration enumerates schemas and must not be submitted to a restricted
tenant capability runner as if it were tenant-scoped SQL.

This migration is now immutable in the linked project; use a new forward migration
for any subsequent database correction. Verify columns/constraint/function ACL/search path, trigger presence,
actual conversation SELECT/UPDATE and message INSERT policies, and a disposable
authorized pending-send transaction in staging. Unauthorized membership/location
cases must fail. This change does not replace or broaden existing RLS policies.
No disposable production business-row test was executed because existing triggers
may enqueue webhooks. Behavioral validation was offline.

Remaining review findings are not fixed by applying DDL: webchat treats snoozed
workflow completion as 502, Resume now compares expiry rather than a revision,
early Zavu persistence loses generated titles, and contact-human can report skipped
acknowledgments as sent. Fix/retest these before claiming end-to-end readiness.

## Offline evidence

From API: `node --test __tests__/conversation-snooze-sql.test.mjs`.
Nine real PGlite SQL tests cover no backfill, default-on for existing/new chats, default/zero/fractional/bounded
hours, immediate pending pause/rollback, failed delivery UPDATE, duplicates,
monotonic extension, history/future clocks, notes/roles, assignment preservation,
both serial human/resume orderings, schema isolation and representative RLS
authorization including a missing UPDATE policy, broad legacy RLS with a viewer,
editor updates and direct human-timestamp forgery rejection. These are not full live-policy
replay or multi-connection contention tests.

From schema repository: `python3 scripts/validate-bootstrap.py` and
`python3 -m unittest discover -s scripts -p 'test_validate_bootstrap.py'`.
Package now contains 192 files / 47 upgrades. Full Supabase bootstrap replay and
live end-to-end delivery remain unverified. There is no assistant role mutation
or database delivery fence; an external provider send already in flight cannot
be recalled by this trigger.

Security advisors were checked after application and report broader preexisting
findings, including [RLS enabled without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
See [project security advisors](https://supabase.com/dashboard/project/rnjgeloamtszdjplmqxy/advisors/security).

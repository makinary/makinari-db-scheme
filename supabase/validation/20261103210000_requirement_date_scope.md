# Requirement date scope — remote application verification

Applied with explicit user authorization on 2026-11-03 to linked Makinari
`rnjgeloamtszdjplmqxy`, using this repository's `.env.local` PostgreSQL variables
and identity-matched session pooler. TLS was verified. No credentials were printed
or passed as command arguments.

- Migration: `20261103210000_requirement_created_or_updated_scope.sql`.
- SHA-256: `f971ec91d47c4c093e4a88764636d65ebc1e5c49d703f8805a6de817df1f8a9d`.
- Canonical API, schema repository and bootstrap copies are byte-identical.
- Only the installed private agent claim date predicate changed from AND to OR.
- The complete canonical SQL and one migration-history entry committed together.
- Function identities, owners, ACLs, SECURITY DEFINER and search_path were compared
  in-transaction and remained unchanged. The public command/economic-recovery
  wrapper definition remained byte-identical.

The preflight confirmed the linked project, TLS, absent history entry and exactly
one expected predicate. Application used an advisory lock, migration-history lock,
five-second lock timeout and 30-second statement timeout. Post-commit receipt
confirmed one history entry and the installed OR predicate.
Independent read-only verification through the same local PostgreSQL configuration
confirmed that the single stored history statement equals the canonical SQL byte
for byte, the old AND predicate is absent and HabitUall passes the new date scope.

No customer timestamps were rewritten, no commands resubmitted, and no manual
robot dispatch, other migrations, bootstrap replay or API deployment occurred.
The already-enabled cron can admit newly eligible historical projects after this
change. Eligibility does not prove provider execution or successful delivery.
The API recurrence-query correction still requires ordinary application deployment.

The fresh-QA package adds the canonical migration to both hash manifests without
changing captured baseline files. It now contains 185 files / 40 upgrades.
The manifest file retains its historical name `upgrades-20261030.json`.
Private application SQL and receipt are retained in ignored `.exports/`.

API offline validation before application: 49 harness-agent suites / 538 tests
passed, including the real SQL date boundary, historical updated project,
pause/hold/cancellation and metadata preservation checks; TypeScript passed.
These tests do not establish full fresh Supabase replay, production contention
or live customer end-to-end success.
After synchronization, bootstrap static validation passed for all 185 files / 40
upgrades, all six offline validator regressions passed and `git diff --check` passed.
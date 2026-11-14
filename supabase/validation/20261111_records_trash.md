# Records relation admission and recoverable Trash — applied

## Execution and verification

- Target: linked Makinari project `rnjgeloamtszdjplmqxy`, schema `public`, using
  this repository's private `.env.local` PostgreSQL credentials and matching
  session pooler. No credentials were printed or committed.
- Four migrations committed atomically at **2026-11-11 03:15:48.262938 UTC**.
- A new read-only connection verified the result at **03:16:13.835672 UTC**.
- Transaction advisory lock and exclusive migration-history lock; 5-second lock
  timeout, 60-second statement/idle-transaction limits. Exact source SQL stored
  atomically with each migration version; PostgREST reload notified.
- TLS encryption verified; `verify-full` certificate identity is not claimed.
- No customer content queried for validation, no explicit business-row DML, no
  trash/restore operation, no backfill, application deployment, commit or push.
  Adding nullable metadata columns leaves existing records active.

## Versions and synchronization

| Version | Migration |
| --- | --- |
| 20261111032000 | records_relation_admission |
| 20261111032100 | records_trash_storage |
| 20261111032200 | records_trash_rpc |
| 20261111032300 | records_trash_embeddings |

The original unapplied draft `20261110230000_records_relation_admission` collided
with the already applied conversation snooze version. All four Records drafts
were renumbered after the latest applied migration **before** application; no
applied migration or prior history was edited.

Exact source SHA-256 values:

```text
20261111032000 784bbaa4711fdbf0910b4f8a9be8e2c61b61b6435a79361467163f3ec0621626
20261111032100 2db0fb4b5647a38cd0da0652343ff8c634ce392655be990fe28792fb2ff65575
20261111032200 de6cf9804c3aed45cf5d67526d9e2291b04c67082e90c8e0d5bf532cd033c263
20261111032300 6f87aff14c8717b2bf7cf438861970ed3d08dac29e4283e0995bdc83d85ed57f
```

Frontend, canonical and bootstrap copies are byte-identical. Both bootstrap
manifests include their SHA-256 hashes. Fresh-QA package now contains **196 files /
51 canonical upgrades**. Its baseline remains unchanged; no full expanded
Supabase bootstrap replay is claimed.

## Verified database contracts

- Exact version/name/full SQL source in migration history: four matches.
- Six nullable metadata columns (`deleted_at`, `deletion_batch_id`,
  `deletion_root_category_id` on Records and categories).
- Ten expected enabled triggers across records/categories/diagrams/embedding jobs.
- Five authenticated RPCs installed; anonymous EXECUTE denied; internal helper
  EXECUTE denied to anonymous/authenticated roles; explicit search paths.
- Existing 16 Records/category policies preserved exactly; two additive
  restrictive active-only SELECT policies installed.
- Authenticated category physical DELETE denied; client trash metadata UPDATE
  denied. Permitted record DELETE uses the soft-delete trigger, preserving the
  prior record DELETE authorization predicates.
- Canonical vector retrieval functions confirmed SECURITY INVOKER before rollout.

## Behavior and boundaries

Collections move active subtree categories/records into one recoverable batch.
Restore only restores that batch; previously separately trashed items stay deleted.
Collection/list/restore authorization requires owner/admin, user_can and unscoped
location access. Individual record deletion preserves DELETE RLS.

System AI-feedback records remain managed by their source UI; only the existing
trusted backend feedback-removal lifecycle retains narrowly matched physical
deletion. Ordinary record purge is not exposed. Diagrams remain stored; trash
freezes their content and marks queued embedding work completed with a trash reason.
Already in-flight external requests cannot be recalled; external worker rollout
and rechecks remain operational requirements.

These migrations are now immutable. Future corrections require later versions.
This is not complete JSON foreign-key enforcement or compliance certification.
Real authenticated browser trash/restore and the 12 E2E cases remain pending on an
approved disposable QA. No production fixture writes were used to simulate them.

## Validation

- Frontend: 52 migration tests passed, including real socket-only PostgreSQL cases.
- Schema repository: `python3 scripts/validate-bootstrap.py` passed.
- Schema repository: six `test_validate_bootstrap.py` tests passed.
- Independent metadata/history/ACL/trigger/policy verification passed remotely.
- Security advisors queried after application; broader project findings remain.
  See [security advisors](https://supabase.com/dashboard/project/rnjgeloamtszdjplmqxy/advisors/security)
  and [RLS-without-policy guidance](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
  Authenticated SECURITY DEFINER RPCs are intentional here and enforce explicit
  authorization; their presence alone is not proof of a bypass.

Private preflight/application/verification SQL and receipts are stored in ignored
`.exports/records-rollout/`, not in the public bootstrap or user-facing assets.
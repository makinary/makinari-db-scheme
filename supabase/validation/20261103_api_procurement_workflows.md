# API procurement workflows — remote application verification

## Independent recheck — 2026-11-04 03:20 UTC

At the user's request, the linked project was checked again using the repository's
ignored local PostgreSQL configuration. The transaction was read-only; no
migrations were replayed and no credentials or Vault values were displayed.

The three versions listed below each have exactly one migration-history entry
whose statements include the complete byte-identical canonical SQL. API and
schema-repository copies also match the recorded SHA-256 hashes.

The live catalog confirmed 13 enabled procurement webhook triggers, eight
restrictive read policies, RLS on the private-instance table without direct
authenticated SELECT, the cloud confidentiality guard and UUID generation in
the shared webhook dispatcher. The connection used TLS. This recheck does not
establish certificate verification or live external webhook delivery.

The migrations were already applied, so applying them again would be incorrect.
The sanitized recheck receipt is retained privately in
`.exports/procurement-workflow-recheck.json`. No deployment, commit, push or
fresh-QA bootstrap changes were performed by this recheck.

## Original application

Applied with user authorization on 2026-11-03 to linked Makinari
`rnjgeloamtszdjplmqxy`, using this repository's ignored `.env.local` and its
identity-matched session pooler. Credentials were neither printed nor passed as
command arguments. The configured `PGSSLMODE=require` provided TLS encryption;
`verify-full` failed with the available local trust roots, so server certificate
verification is not claimed.

## Applied canonical migrations

| Migration | SHA-256 |
| --- | --- |
| `20261104100000_procurement_workflow_database_webhooks.sql` | `f84147a200ad3101de8d04a066fc9324b8d1e60701e30354d1392e42598433b9` |
| `20261104101000_procurement_workflow_confidentiality.sql` | `d221d5355d9b45337a0fbb8c8a41e7c9c68a4cd3ff031209f47e641f3704b297` |
| `20261104102000_workflow_database_webhook_event_identity.sql` | `2ff5965f21920faf73ea86d375704ab2d94b55150612c2484801037cc9e4a2dd` |

The API and schema repository copies are byte-identical. The already-recorded
`20261031010000_procurement_mcp_bridge.sql` was also synchronized into the schema
repository without reapplying it.

Preflight confirmed TLS, all required confidentiality RPCs, the compatible cloud
scope guard, absence of the new private-instance table, and RLS/site columns on
all eight policy targets. The shared dispatcher was already installed.

All three SQL bodies and their complete canonical migration-history statements
committed in one transaction. Only the outer per-file transaction boundaries were
removed for execution; the recorded statements retain the exact source files.
Application used an advisory transaction lock, an exclusive migration-history lock,
a five-second lock timeout and a 60-second statement timeout.

In-transaction assertions confirmed 13 enabled procurement webhook triggers,
eight restrictive read policies, private-instance table RLS, the cloud confidentiality
guard and UUID generation in the shared dispatcher. The confidentiality migration
also classifies existing purchasing workflow runs/plans; it does not rewrite the
source payloads. Vault configuration was not read, copied or changed by the operator.

## Verification and limits

- Independent post-commit read-only verification confirmed exactly one history
  entry per new version, each containing the byte-identical canonical SQL, all 13
  enabled triggers, eight restrictive policies, private-table RLS with no direct
  authenticated SELECT grant, and both cloud/event-identity function changes.
- Four focused API workflow suites passed: 62 tests for procurement triggers,
  actor access, history protection and dispatch idempotency.
- The executable PGlite confidentiality regression passed: one test exercising
  restrictive policies, derived-plan protection, cloud access and sticky classification.
- Bootstrap static validation passed for 185 files / 40 upgrades, all six offline
  validator regressions passed, and `git diff --check` passed.
- No test mutations, manual robot dispatch or outbound HTTP delivery were performed
  on the linked database. Future qualifying procurement mutations can now enqueue
  webhooks using its existing Vault-backed configuration.
- No API deployment was performed. Application deployment and live end-to-end
  compatibility remain separate operational gates.
- Many older API versions are absent from migration history despite later installed
  schema replacements. They were not replayed or marked applied without semantic
  reconciliation. This is not a certificate that all historical API migrations ran.
- The immutable fresh-QA bootstrap and its manifests remain unchanged by this update.
  Packaging these migrations requires a reviewed local-only dispatcher adaptation
  and explicit review of classification backfills; canonical production SQL must not
  silently replace the QA outbound safeguard.

Private preflight, application SQL, logs and receipts are retained under ignored
`.exports/` with private permissions; they are not publication artifacts.
# Storage admission correction — remote application verification

Applied with explicit user authorization on 2026-10-31 to the linked project
`rnjgeloamtszdjplmqxy`, using this repository's private PostgreSQL configuration
and its identity-matched cached session pooler. TLS was confirmed. Credentials
were passed through the process environment, not command arguments or Git.

## Exact scope

- Migration: `20261030230000_procurement_storage_admission.sql`.
- Canonical SHA-256:
  `997bc76693b46baa33897fe21f6739f788516eda9670dcd34f210861691bcd52`.
- Frontend, historical-directory and bootstrap SQL copies are byte-identical.
- Only `credential_bucket_insert_guard` was replaced. No business rows, Auth
  users, Storage objects, other policies, function bodies or grants were changed.
- The complete SQL and one migration-history row committed in the same transaction.
  No bulk migration, schema bootstrap, application build or deployment was run.

## Preflight and transaction safeguards

Read-only inspection confirmed the configured project identity, actual TLS,
the missing migration version, the existing restrictive authenticated INSERT
policy, prerequisite columns, Storage RLS and the installed access/completion
functions. The access function includes the newer authorized shared-read branch;
that existing behavior was preserved, not replaced with the older baseline.

Application used advisory serialization, a migration-history lock, a five-second
lock timeout and a 30-second statement timeout. In-transaction checks compared
the policy and prerequisite function definitions with the inspected fingerprints
and refused changed migration history or an already-recorded version. Policy
metadata was verified before commit.

## Post-application read-only verification

- Exactly one history row exists for version `20261030230000`.
- Its single stored SQL statement hashes to the canonical migration SHA-256.
- All unrelated migration-history entries retain their previous fingerprint.
- The replacement policy remains RESTRICTIVE, INSERT-only and authenticated-only.
- The other six credential-bucket policies are unchanged.
- Access/completion function bodies, owners and execution ACLs are unchanged.
- Storage RLS remains enabled; an anonymous unregistered path is denied.

The correction admits only an exact, unexpired, caller-owned pending reservation
when preliminary Storage metadata lacks final size/MIME. Supplied values must
match. Strict final size/MIME completion, pending-read denial, caller UPDATE/DELETE
denial and existing shared-read authorization remain intact.

## Test evidence and limits

Before application, the frontend's isolated PostgreSQL credential-storage,
evidence and storage suites passed **3 suites / 50 tests**, with no skips.
Bootstrap static validation and all six offline validator tests passed.

Earlier disposable Azure verification exercised actual Storage upload, private
read/share denial and the full nine-scenario procurement suite successfully.
This remote application performed read-only postchecks, not live allowed-path
uploads: no production test credentials, documents or synthetic customer rows
were created. Full current production browser health is not claimed.

Private preflight, guarded application SQL, receipts and postchecks remain in
ignored `.exports/`. This evidence contains no credentials or customer data.
Repository follow-up changes remain uncommitted/unpushed until requested.
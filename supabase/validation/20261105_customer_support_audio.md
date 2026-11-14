# Customer support audio — application evidence

## Applied

- Version: `20261105200000`; history name: `customer_support_audio`.
- Committed on linked Makinari; first post-commit history check:
  **2026-11-05 19:59:49.131424 UTC**.
- Independent read-only session verification: **19:59:50.299919 UTC**.
- History contains exactly one entry, with `statements` equal to a one-element
  array containing the exact canonical API SQL and the expected history name.
- SHA-256 (API, schema canonical and bootstrap):
  `28e62a4e03f622af725376446dc66da01a7c9584b3776b7a6467bbad048b4c45`.

Used repository `.env.local` through the ignored connection helper, requiring TLS
and checking the linked project against the direct host and cached session-pooler
identity. No credentials or endpoint identifiers are included here.

One explicit transaction acquired the reviewed-forward-migrations advisory lock
and an exclusive history-table lock, rechecked absent history/table and the exact
eligible schema set (`public`), executed the corrected SQL, asserted live catalog
invariants, inserted exact-source history, and committed. Lock timeout was 5s;
statement timeout 60s. No unrelated migration was executed. `app_auth` has no
`sites` table and was not eligible.

## Live verification

The catalog-only assertions in `20261105200000_customer_support_audio.sql` in this
validation directory passed both before commit and in a separate session after it:

- RLS enabled; zero policies (ordinary clients have no access).
- PUBLIC has no ACL entry; anon and authenticated have none of the seven table
  privileges checked. Effective service_role privileges are SELECT, INSERT,
  UPDATE only; DELETE, TRUNCATE, REFERENCES and TRIGGER are false.
- Composite primary key `(site_id, source_hash)`.
- Validated foreign key to `public.sites(id)` with ON DELETE CASCADE.
- Four validated CHECK constraints: lowercase 64-character hexadecimal hash;
  status pending/complete; transcript length at most 12000; complete receipts
  require a non-null, nonempty transcript.
- Four NOT NULL columns. No customer tables or receipt rows were queried.

Service-role RLS bypass does not grant DELETE/TRUNCATE. The FK cascade remains
intentional: deleting a parent site may remove its receipts; this change does not
prevent owner/admin DDL or parent-site deletion. Receipts must not be automatically
reclaimed without billing reconciliation.

## Repository and tests

- Canonical and fresh-QA migration copies are byte-identical to the API source.
- Both manifests include the new hash in version order: **189 files / 44 upgrades**.
- Immutable baseline, QA webhook guard and pre-existing dirty work preserved.
- `python3 scripts/validate-bootstrap.py`: passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_validate_bootstrap.py`: **6 passed**.
- `PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_customer_support_audio.py`: **3 passed**.
- `git diff --check`: passed.

Scope limits: live validation was catalog/ACL based, not customer-data DML or
role-based application traffic. No synthetic fixtures were inserted in the linked
database. Full expanded bootstrap replay and audio/billing E2E were not run.
No commit, push, runtime deployment or feature enablement was performed.

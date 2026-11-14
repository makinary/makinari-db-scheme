# Shipment carrier documents — applied and verified

## Target and execution

- Project: `rnjgeloamtszdjplmqxy`, matching the local PostgreSQL endpoint and linked
  project/session pooler in this repository. Credentials were not printed.
- Applied only `20261109223000_shipment_carrier_documents.sql`.
- Commit observed: **2026-11-10 00:22:24.632211 UTC**.
- Independent read-only verification: **2026-11-10 00:22:57.586771 UTC**.
- Advisory transaction lock and exclusive migration-history lock; 5-second lock
  timeout, 60-second statement and idle transaction timeouts.
- SQL and exact-source migration history inserted atomically, followed by a
  PostgREST schema-reload notification. No business-row DML, uploads, deployments,
  commits, pushes, or other pending migrations were performed.

Canonical schema/frontend copies have SHA-256:

```text
7ab819e75e708183638ab47e7c140459eaaad871993f1603dc8479ece6d6831c
```

## Verification

- Migration version occurs once; name and complete single-statement source match.
- `public.shipment_documents` exists with RLS enabled and SELECT/INSERT policies.
- Private `shipment-carrier-documents` bucket permits PDF only, at most 10 MiB.
- All seven Storage policies exist, including restrictive read/insert/update/delete
  guards protecting this bucket from unrelated permissive legacy policies.
- Both access helpers are SECURITY INVOKER with fixed `public, pg_temp` search path;
  authenticated execution is granted, anon/PUBLIC execution is not. Existing
  database defaults additionally grant service_role execution.
- Authenticated table access is SELECT/INSERT only; UPDATE/DELETE denied. Anon
  SELECT denied.
- Actual `SET LOCAL ROLE authenticated` without a JWT identity returned zero
  visible documents and false for shipment access and invalid-path access.
- API regression tests: **20 passed**. Bootstrap static validation: **190 files /
  45 upgrades**, unchanged. These are not full live upload or RLS identity tests.
- Security advisors were queried after application; broader existing findings
  remain outside this migration's scope. Review project findings in the dashboard:
  https://supabase.com/dashboard/project/rnjgeloamtszdjplmqxy/advisors/security

## Limits and follow-up

The existing restrictive `location_acl_private_storage` policy denies all Storage
access when `current_user_has_location_restrictions()` is true. It was deliberately
not relaxed: location-restricted users may read permitted metadata but cannot
upload/download the underlying PDF through Storage. A separately reviewed policy
change is needed for that capability; the application permission check alone
does not override Storage RLS.

TLS encryption was verified with the configured `require` mode. Server certificate
identity verification (`verify-full`) is not claimed. Scripts and raw receipts are
private under ignored `.exports/shipment-*`.

No real customer identities or files were used. Live allowed/cross-site/assigned-only
upload-download checks and application deployment remain pending. PDF validation
is format checking, not antivirus scanning or proof of carrier authenticity.

The migration is stored in canonical `supabase/migrations`, not the fresh-QA
bootstrap: it adds Storage objects/policies and a bucket insert, which need explicit
review against the bootstrap's no-unreviewed-insert rules and Storage prerequisites.
No generated `supabase/types.ts` exists in this checkout; a full remote type export
was not introduced as an unrelated schema-wide change.
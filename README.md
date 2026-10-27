# Makinari DB Schema

Source of truth for the Supabase database schema. Migrations and generated types live here.

## Current fresh-QA bootstrap (2026-10-27)

`bootstrap/` contains a schema-only capture of the current Makinari application's
five schemas, split into bounded SQL migrations with a hash/provenance manifest.
It includes current commerce tables, permission RPCs, grants, RLS, custom Auth
profile trigger and Storage policies. No customer rows, Auth identities, Vault
values, buckets or Storage objects were copied.

Use this project **only for a fresh isolated QA Supabase**. It replaces replay of
the historical migration directory for fresh QA; never apply it on top of an
existing database. The historical migrations remain unchanged.

The direct legacy messages webhook with embedded external configuration is omitted.
The configurable workflow dispatcher retains its real behavior but accepts only
local HTTP destinations. Configure the local receiver and secret separately; do
not copy production Vault values. This intentionally differs from production
outbound delivery while retaining business/RLS behavior.

```bash
python3 scripts/validate-bootstrap.py
```

Validation covers file hashes, bounded chunks, timestamps, required objects and
outbound safeguards. On 2026-10-27, fresh Supabase replay completed all 145 chunks
after local portability corrections for `public`, the non-login coordinator role
and Supabase-owned default ACLs. These corrections are not yet published. **E2E
and users/fixtures remain pending**; replay is not a business-flow certificate. Compatible local Supabase
must provide Auth, Storage, pg_net/Vault and listed extensions. Existing platform
schemas are not replaced. Roles referenced by captured grants require the platform's
normal role setup. Storage bucket metadata and test objects must be provisioned
separately with synthetic data.

The installer discovers `makinari-db-scheme/bootstrap` from its source repositories
and verifies the manifest. Its QA command still requires schema acknowledgement
and a fresh unused QA ID; production and previously applied migrations are untouched.

## Private schema export

`scripts/export-schema.cjs` reads local PostgreSQL variables from `.env.local` and
exports schema-only DDL under ignored `.exports/` with private permissions. It can
use the cached matching Session pooler when the direct project endpoint is IPv6-only.
It never exports rows or platform-owned schemas. Raw function/trigger DDL may contain
embedded secrets: review it privately, never commit the raw export. The exporter
currently reuses the sibling frontend's installed dotenv and a PostgreSQL 17 binary
directory (`PG_BIN` overrides the default); it is not a portable standalone CLI yet.

`scripts/build-bootstrap.py` performs the reviewed transformations and preserves
historical files. It refuses overwriting an existing bootstrap. Subsequent captures
need explicit versioning/review, not editing an applied migration.

## Prerequisites

- Node.js (for Supabase CLI)
- A Supabase project ([dashboard](https://supabase.com/dashboard))

## Initial setup (one-time)

This repo already has `supabase init` applied. Use **npx** so you don't need a global install.

### 1. Login to Supabase CLI (opens browser)

```bash
npx supabase login
```

### 2. Link to your remote project

Get your **Project ref** from Supabase Dashboard → Project Settings → General.

```bash
npx supabase link --project-ref <PROJECT_REF>
```

### 3. Pull remote schema into migrations

This generates a migration SQL file with tables, FKs, indexes, constraints, enums, functions, and RLS policies. `jsonb` columns stay as `jsonb` in SQL.

```bash
npx supabase db pull
```

### 4. (Optional) Generate TypeScript types for your app

```bash
npx supabase gen types typescript --linked > supabase/types.ts
```

> **Alternative:** Install globally with `npm i -g supabase` and run the same commands without `npx`.

Commit `supabase/types.ts` or regenerate in CI when the schema changes.

## Repo layout after setup

- `supabase/migrations/` – SQL migrations (source of truth; use `supabase db pull` to sync from remote).
- `supabase/config.toml` – Local Supabase config (optional overrides).
- `supabase/types.ts` – Generated TS types (optional, from step 5).

## Refreshing the schema from Supabase

When the remote DB changes (e.g. via Dashboard or another tool), pull again:

```bash
npx supabase db pull
```

Then commit the new migration. To refresh types:

```bash
npx supabase gen types typescript --linked > supabase/types.ts
```

## RLS, triggers, extensions, grants

If you use RLS policies, triggers, Postgres extensions, or custom grants, `supabase db pull` should capture them. If something is missing, you can:

- Inspect the generated migration under `supabase/migrations/`.
- Add manual migrations for anything not reflected (e.g. `CREATE POLICY`, `CREATE TRIGGER`, `GRANT`).

If you have an existing `schema.sql` or a list of extensions/policies, we can align the pull output with it.

# Makinari DB Schema

Source of truth for the Supabase database schema. Migrations and generated types live here.

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

# Bounded instance asset loading — applied

Only `20261111223000_instance_asset_summaries.sql` applied to Makinari
`rnjgeloamtszdjplmqxy` with this repository's local credentials.
Commit observed **2026-11-11 22:24:40 UTC**; independent catalog check
**22:24:56 UTC** confirmed both indexes valid/ready and one migration entry.
Exact source/history and read-only real-instance smoke checks passed: one summary,
matching asset count and at most three previews. No business rows changed.

## Database

- General `(instance_id, created_at DESC, id DESC)` index supports counts/previews.
- Partial image index supports last-image lookup with no large payload INCLUDE.
- Read-only EXPLAIN now uses `assets_instance_image_created_id_idx` and no Sort,
  replacing the prior Seq Scan plus Sort. Planner costs are not latency benchmarks.
- `get_instance_asset_summaries(uuid,uuid[])` accepts at most 100 instance IDs,
  reads same-site instances/assets, returns counts, three previews and one image
  path. SECURITY INVOKER, empty search path, anon/PUBLIC execution revoked;
  authenticated/service_role may execute subject to their table privileges/RLS.
- Asset table ACL/RLS/FORCE RLS flags unchanged; no default grants changed.
- DDL and exact-source history committed together with advisory/history locks,
  5s lock timeout, 60s statement timeout and PostgREST schema reload. Small live
  asset table allowed transactional index construction; no large-table rebuild.
- API/frontend/canonical/bootstrap migration copies are identical. Unrelated
  concurrent migrations remain untouched; only the named migration applied here.
- MCP read-only diagnostic role cannot execute the RPC (expected revoked grant);
  the live aggregate smoke check used local PostgreSQL credentials, read-only.

## Frontend process

The `/robots` avatar loader and browser stats use bounded grouped RPCs instead of
per-instance asset GETs. 394 IDs require four sequential calls per consumer. IDs
are deduplicated/sorted; changes to names/statuses alone do not restart effects.
Completed batches are cached, missing/forbidden rows are not invented as successful
empty assets, errors invalidate cached rows, and obsolete requests are aborted.
Authentication transitions and disabled/site-empty boundaries clear cache/state.
Requests have a 10s client timeout, 60s freshness refresh while visible, and no
overlapping refresh per consumer. Consumers have independent RLS-scoped caches;
multiple consumers/tabs may each make their own bounded calls. This is not global
cross-user caching or cross-tab deduplication.

Successful empty image results are cached. New assets refresh within the next
visible refresh cycle. Browser supplemental requirement/log reads are reduced to
blocks of four instances and abort on close/site/ID changes. Full inventory is
still supported; visible-window pagination can be a separate future optimization.

Failures expose unavailable/retry state instead of silently claiming no avatars.
The browser Files filter falls back to all instances on summary failure. Demo
mode summarizes existing demo fixtures locally; it does not replace production.

## Verification and release gates

- 24 focused React/Jest tests pass: 394-ID batching, stable IDs, cache persistence,
  obsolete requests, site/auth switches, absence/error semantics, explicit retry,
  demo summary projection and existing creation lifecycle regressions.
- Actual PGlite SQL suite passes: repeatability, counts/order, empty result, tenant
  denial, anon denial, bounded input, invoker execution and index presence.
- Six bootstrap validator tests pass; inventory 200 files / 55 upgrades, including
  one unrelated concurrent addition, with immutable baseline unchanged.
- Targeted lint passed for the new hook, browser data loader, creation hook,
  new hook tests and demo summary helper.
- Full frontend typecheck has an unrelated existing PostCSS type error at
  `__tests__/components/ui/mobile-primary-buttons.test.tsx:72`; changed-file error
  in the mocked setter was corrected and rechecked separately.
- No production build, HTTP browser E2E, frontend deployment, commit or push.
  Database improvements are active; grouped frontend requests require deployment.
- Private receipts under ignored `.exports/instance-asset-summaries/`.
  No credentials, user IDs, customer payloads or signed URLs were committed.
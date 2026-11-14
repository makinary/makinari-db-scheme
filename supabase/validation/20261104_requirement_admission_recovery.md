# Requirement admission and missing-workspace recovery — application verification

Applied with user authorization to linked Makinari `rnjgeloamtszdjplmqxy` at
2026-11-04 00:05:52 UTC. Connection used this repository's ignored `.env.local`
PostgreSQL variables and identity-matched session pooler. Credentials were not
printed or passed in command arguments. `PGSSLMODE=require` and `pg_stat_ssl`
confirmed encrypted TLS; server-certificate verification is not claimed.

| Migration | SHA-256 |
| --- | --- |
| `20261104110000_requirement_site_credit_admission.sql` | `c00a1624b729b00426eb0d63a6dcffc780bb1a04bcc634cfe387a86fe36ef308` |
| `20261104111000_missing_requirement_workspace_recovery.sql` | `b02e55293d3f67bf1b7660198146301511b12d7d28f49feee2ecbd27c500fe60` |

## Applied and verified

- Preflight confirmed absent migration history, absent recovery RPC/permit table,
  the expected scheduler definition and the reviewed session identity guard.
- Both migration bodies and their complete canonical history statements committed
  in one transaction. Only outer per-file BEGIN/COMMIT boundaries were removed
  during execution. Application used an advisory lock, exclusive migration-history
  lock, five-second lock timeout and 60-second statement timeout.
- In-transaction checks preserved existing function identities/owners/ACLs,
  SECURITY DEFINER/search_path, and the exact public command-recovery wrapper.
- Independent post-commit read-only verification confirmed one history row per
  version with byte-identical canonical SQL, archived-site and positive-credit
  predicates, private permit-table RLS, no permits left over, and RPC execution
  granted to service_role but not anon/authenticated. The service role cannot
  directly read or modify the private permit table.
- Source files are identical across the API, canonical schema repo and bootstrap.
  Both manifests now cover 187 files / 42 upgrades. Immutable baseline files and
  QA-local outbound protections remain unchanged.

## Validation and limits

API validation included disposable PostgreSQL admission/recharge/renewal and
multi-connection recheck tests; PGlite tests exercised recovery CAS, session
identity protection and actual bootstrap cleanup fencing. Git bootstrap tests
recovered a remote requirement branch without running repository hooks.

Schema-repository static hash/coverage validation and six validator regressions
pass. These are not proof of full fresh Supabase replay or production end-to-end
execution. The package's historical baseline validation metadata is unchanged.

No customer state was manually rewritten, no workspace retirement RPC was invoked,
no sandbox was provisioned, no requirement was resumed and no API deployment was
performed during application. Existing cron calls can use the new admission filters;
the recovery RPC remains inert until the updated runtime invokes it after a verified
provider GET 404. Recharging/plan renewal must update persisted available credits
before a skipped zero-balance site becomes eligible again.

Private preflight, application SQL, logs and receipts are retained in ignored
`.exports/` with private permissions. Unrelated existing repository changes and
the separate assistant execution-boundary work were not applied by this operation.
# Cloud document migrations — applied verification

Applied 2026-10-30 to project `rnjgeloamtszdjplmqxy` through the matching TLS
session pooler using this repository's local PostgreSQL credentials. Credentials
were passed through process environment, never command arguments or committed files.

Only these migrations were applied, atomically with their Supabase history rows:

| Version | Name | SHA-256 of exact SQL |
| --- | --- | --- |
| 20261030010000 | cloud_document_persistence | b65ad2f15756c437616aa75d4e9e53fda86551fccce7793ec6a88380e62a9c5f |
| 20261030020000 | cloud_requirement_sessions | db2b696474de7883c861e8852c9e684e0f0d1a3326c61d1bff97e34fc6d5cb70 |

Checks after commit:

- History statements have the same hashes as this repository and sibling API copies.
- Four cloud tables exist with RLS and no direct anon/authenticated/service-role access.
- `cloud_file_store` and `claim_cloud_git_publications` are executable by
  service_role only; internal helpers have no public execution grants.
- Revision/operation immutability, requirement/plan binding and environment triggers enabled.
- Cloud snapshots accepted without a repository; cloud+repository and negative
  counters rejected; legacy workspace snapshots accepted.
- Zero existing harness snapshots rejected by the new validator.
- Cloud tables remain empty; no test/customer documents or Git intents were created.

The security advisor's informational RLS-without-policy notices on these tables
are intentional: access is through authorized SECURITY DEFINER RPCs, not direct
table grants. See https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy.
Other project-wide advisory notices were not remediated by this scoped migration.

The prior snapshot-validator definition and verification output are retained
privately in ignored `.exports/`. No procurement/bootstrap migration, application
deployment, Git configuration or production E2E run was performed. Do not edit
these applied SQL files; use forward migrations for subsequent fixes.
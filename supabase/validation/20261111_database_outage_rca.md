# Makinari PostgreSQL outage investigation — 2026-11-11

## Scope and conclusion

Project `rnjgeloamtszdjplmqxy`, primary database, region `us-east-1`.
Investigation observations collected approximately **20:41–20:54 UTC** on
2026-11-11. Local display timezone in the incident screenshots was UTC−6.

**Confirmed incident:** loss of backend reachability, followed by an unclean
PostgreSQL restart and recovery at 20:04 UTC. **Exact root cause: unconfirmed.**
Host/control-plane history is required to distinguish resource exhaustion,
infrastructure failure, and an operator/platform-forced restart.

**Confirmed contributing workload concern:** a sudden burst of latest-image
asset reads whose query shape lacks an instance index and plans a sequential scan.
This is a real optimization target, not proof that those reads caused the outage.

Production operations in this investigation were read-only: scoped SQL, logs,
two authenticated Metrics API GETs, and EXPLAIN **without ANALYZE**. No restart,
DDL, cancellation, settings/billing changes, full-table payload scan, remediation,
external ticket submission or monitoring schedule was performed. Earlier asset
migration at 20:34 UTC is a separate operation, after the 20:04 recovery.

## Method and canonical checks

Followed Supabase [Detection checks](https://supabase.com/docs/guides/observability/detecting.md),
[Health monitor](https://supabase.com/docs/guides/observability/automate-with-agents/health),
and [Performance monitor](https://supabase.com/docs/guides/observability/automate-with-agents/performance).
Queries use ClickHouse `logs` and dotted `log_attributes` keys, explicit bounded
windows, and read-only Postgres catalog/statistics queries. Evidence is aggregate
or sanitized; no credentials, IPs, user IDs, raw query strings or customer payloads
are retained here. Unknown statuses are not counted as successful responses.
No operator-specific thresholds or prior alert state were supplied; canonical
defaults are used, and no claim of a newly deduplicated alert is made.

| Check | Outcome | Evidence / threshold / limitation |
|---|---|---|
| API hourly server-error comparison | Finding | 19:00–20:00 UTC: 176/9,344 = 1.884%; 18:00–19:00 UTC: 0/6,729. Both >=100 responses; >=20 errors and >=1% satisfied. No unknown gateway statuses. |
| Auth hourly comparison | Unable to assess | Previous hour has only 16 valid responses (1 unknown); incident hour 543 valid, 0 server errors, 5 unknown. Do not equate this source to gateway Auth outcomes. |
| Current connection pressure | Clear at snapshot | 20:45:35 UTC: 29 client connections, 1 active, max 60; 48.3%, below canonical 80%. Reserved/pool/role limits and incident peak not measured. |
| Current blockers/session review | Reviewed, no blocker found | One long-lived walsender waiting `WalSenderWaitForWal`, no blocking PIDs; no active long client transaction. Age alone does not justify cancellation. |
| Query regression comparison | Unable to assess | `pg_stat_statements` reset at 20:04:09.439559 UTC; no three reset-compatible hourly snapshots. Current cumulative slow statements include investigation SQL, not proof of a workload regression. |
| Current health advisors | Clear for returned checks | `get_advisors(type=health)` returned no lints around 20:45 UTC. This does not establish complete system health. |
| Host exhaustion at incident time | Unable to assess | Available metrics are post-incident scrapes; historical host series and boot/reset provenance absent. |
| Disk growth/exhaustion forecast | Unable to assess | No seven comparable daily disk-use snapshots. Database size is not total filesystem use. |
| Daily request growth policy | Not evaluated | Only incident-specific minute/hour workload context used; no canonical two-complete-day growth claim. |

## Timeline

| UTC | UTC−6 | Evidence |
|---|---|---|
| 19:00–19:30 | 13:00–13:30 | Gateway 264–662 requests per five-minute bucket; zero asset GETs in these buckets. PostgREST Warp timeout-manager messages already occur before the outage. |
| 19:30–19:45 | 13:30–13:45 | Gateway buckets rise to 1,949 / 2,606 / 1,327 requests. 1,293 asset GETs, compared with zero in preceding 30 minutes. Responses in these buckets have no recorded 5xx. |
| 19:42:43.163 | 13:42:43 | Last recorded completed Postgres checkpoint before log gap. This is a checkpoint timestamp, not exact time of process death. |
| 19:46:28.438 | 13:46:28 | First sampled gateway failure: 522 on a pending-work RPC. Auth gateway 524 follows at 19:46:33.600 and 19:46:38.087. |
| 19:46:54.030 | 13:46:54 | Realtime `DatabaseConnectionDown`, recovery window opens. |
| 19:47–20:03 | 13:47–14:03 | No `system_telemetry` rows in these minute buckets, between receipts at 19:46 and 20:04. DB-backed telemetry cannot reliably observe its own outage. |
| 19:56:54.030 | 13:56:54 | Realtime recovery window exceeds 600,000 ms; tenant process shuts down. |
| 20:04:07.940 | 14:04:07 | Metrics `process_start_time_seconds` for service labeled `postgresql`; runtime labeling does not establish an OS boot. |
| 20:04:09.472 | 14:04:09 | PostgreSQL starts; says database was interrupted and not properly shut down; automatic recovery. |
| 20:04:09.771 | 14:04:09 | Redo completes in 0.15 s; subsequent logical decoding resumes. End-of-WAL `invalid record length ... got 0` is not standalone proof of corruption. |
| 20:04:10–11 | 14:04:10–11 | PostgREST schema-cache recovery emits 503/PGRST002 failures and queued/retried reads. |
| 20:05–20:15 | 14:05–14:15 | Gateway five-minute buckets show 0 recorded 5xx, average origin time 118–132 ms. |
| 20:34:10 | 14:34:10 | Separate asset-owner migration applied; cannot have caused the earlier outage. |

Observed severe reachability interval is approximately **19:46–20:04 UTC**,
not a precisely measured universal downtime SLA. Gateway timestamps are recorded
response events; long timeouts mean request start time can precede the event.

## Severity and error families

| Gateway UTC bucket | Events | 5xx | Rate | Average origin time |
|---|---:|---:|---:|---:|
| 19:45–19:50 | 554 | 8 | 1.4% | 3,261 ms |
| 19:50–19:55 | 47 | 34 | 72.3% | 67,056 ms |
| 19:55–20:00 | 145 | 134 | 92.4% | 87,909 ms |
| 20:00–20:05 | 763 | 258 | 33.8% | 25,700 ms |
| 20:05–20:10 | 1,107 | 0 | 0% | 118 ms |

Between 19:46 and 20:05 UTC: 342 responses 522, 52 responses 525, 25 responses
521, 8 responses 544, 4 responses 503, 2 responses 524, 1 response 520.
These are gateway/server-side failures, not SQLSTATE errors proving one SQL cause.
Realtime connection-pool `queue_timeout` errors are downstream symptoms; its
shutdown concerns the tenant's Realtime process, not deletion of project/data.

Sample gateway correlation IDs, for support only (no customer identifiers):

| UTC | Status | Request ID |
|---|---:|---|
| 19:46:28.438 | 522 | `01a1cc25-bfd6-7182-9c39-d57f74acada3` |
| 19:46:33.600 | 524 | `01a1cc25-d400-75eb-a80a-c92cc7fde55c` |
| 19:46:38.087 | 524 | `01a1cc25-e587-7b59-9ef5-d18cb44ed132` |
| 19:47:08.496 | 522 | `01a1cc26-5c50-7a9f-b989-67fd498131ba` |
| 19:47:33.709 | 522 | `01a1cc26-becd-7237-8480-1204a10cc843` |

## Workload and query-plan finding

19:30–19:45 UTC asset GETs: **1,293**, all instance-filtered, no site filter in the
URL. **1,281** select `file_path`, filter images and use exactly `limit=1` with
descending creation time. The other 12 use another projection. None select `*`.
Therefore this particular burst is not evidence of downloading large inline
asset payloads. 779 asset OPTIONS requests in the same window are CORS context,
not an additional 779 database SELECTs.

Current frontend query-shape match:

- `/Users/prado/Desktop/Proyectos/Uncodie/Code/market-fit/app/components/robots/use-instance-browser-data.ts:100`:
  latest-image path query, `instance_id`, `file_type LIKE 'image/%'`, descending
  `created_at`, limit 1.
- Same file, lines 66–71 and 169–172: effect keyed by the `instances` array;
  cleanup stops future blocks/state writes but does not abort in-flight requests.
- Same file, lines 92–101: blocks of 15 instances with nested parallel requests.
- `/Users/prado/Desktop/Proyectos/Uncodie/Code/market-fit/app/context/RobotsContext.tsx:298–325`:
  remote-instance Realtime updates replace the array.
- `/Users/prado/Desktop/Proyectos/Uncodie/Code/market-fit/app/robots/use-robots-controller.tsx:177–181,233–234`:
  derived arrays drive the stats hook in workflow/imprenta views.

**Attribution strength:** query shape matches a concrete producer, but deployed
commit/client tracing are unverified. No limit-3 reads were observed despite a
limit-3 query in the current hook; do not claim the complete current hook generated
every request. Other versions/producers/cache behavior remain possible.

Live catalog lists asset indexes only on ID, command_id, site_id and user_id.
There is no index starting with instance_id. Read-only EXPLAIN for the image
query using a synthetic UUID gives **Limit → Sort(created_at DESC) → Seq Scan**.
This explains why `limit=1` does not make the lookup inherently cheap.
This plan is a privileged diagnostic, not the exact authenticated RLS execution
plan and not an elapsed-time measurement. No EXPLAIN ANALYZE/load test was run.

Next: verify the deployed producer, deduplicate stats by stable IDs, abort obsolete
requests, bound concurrency/cache appropriately, and evaluate an instance/creation
index (possibly a partial image index) with production RLS plans. These changes
require a separate reviewed implementation; none were made by this diagnosis.

## Host/capacity observations and limitations

Two Metrics API responses retrieved around 20:44–20:45 UTC were **byte-identical**.
Treat them as one possibly cached snapshot, not independent time-series evidence.
Private raw responses and a numeric summary are under ignored
`.exports/incident-20261111/`, private file permissions. Auth credentials were
loaded at runtime, sent only to the project's HTTPS Metrics endpoint, not printed.

| Metric | Returned value |
|---|---:|
| Host MemTotal | 948,191,232 bytes ≈ 0.883 GiB |
| MemAvailable | 433,651,712 bytes ≈ 0.404 GiB |
| Swap total / free | 1,073,737,728 / 212,201,472 bytes |
| Swap occupied | 861,536,256 bytes ≈ 0.802 GiB |
| Data filesystem capacity / available | 34,760,179,712 / 8,022,126,592 bytes |
| Data filesystem available | ≈7.47 GiB |
| Filesystem readonly | 0 for root and data |
| node_vmstat_oom_kill / postgresql_restarts_total | 0 / 0 |
| Load 1 / 5 / 15 | 0.47 / 0.30 / 0.21 |
| PostgREST pool max / available / waiting | 20 / 12 / 0 |

Zero restart/OOM counters **do not override confirmed Postgres restart logs**:
counter scope, boot/reset history and freshness are unknown. Swap occupancy does
not prove active swapping, an OOM kill or incident-time memory exhaustion.
Current free space does not reconstruct pre-restart disk fullness.

The ~1 GB memory observation and earlier Micro billing screenshot are consistent
with Micro compute. Supabase recommends up to 10 GB database size for Micro;
the current database is ~25.4 GB. This is a **sizing recommendation, not a hard
limit or a proven cause**. Host metrics history is needed for right-sizing.

Other post-restart snapshots: read-only off; no archiver failures since reset;
two active replication slots retaining ~359 KB each at 20:45 UTC; 99.84% heap
cache hit ratio since restart. Buffer hits do not establish physical disk latency.
`track_io_timing` and `track_wal_io_timing` are off; zero recorded I/O times are
not zero I/O latency. Checkpoints are intentionally paced with completion_target
0.9 and timeout 300 s; 88–143 s checkpoint write durations alone are not proof
of slow disk, particularly with millisecond sync phases.

## Competing hypotheses

| Hypothesis | Evidence supporting consideration | Missing / contrary evidence | Classification |
|---|---|---|---|
| Memory/CPU/I/O pressure with instance too small | Traffic burst, repeated unindexed image scans, ~1 GB host, substantial returned swap occupancy, 25.4 GB DB | No incident host series, CPU-credit/I/O deltas, OOM event or termination signal | Plausible; unconfirmed |
| Platform/host/container interruption or forced restart | Unclean recovery; multiple local service start markers at 20:04; prolonged backend reachability failures | No lifecycle audit, host health, operator identity or restart reason | Plausible; unconfirmed |
| Pure external client network fault | Gateway timeout/connectivity codes | Realtime also loses DB, SQL diagnostics previously timed out, Postgres later recovers uncleanly | Does not fully explain incident |
| Disk full / WAL accumulation | Provisioned size exceeds included quota; large DB | No recorded no-space error; post-incident free space and small slot retention; pre-incident full disk unknown | Not demonstrated |
| Connections exhausted | Realtime pool queues timed out | No too-many-clients/remaining-slots event; post-incident counts below 80%; incident peak unknown | Not demonstrated |
| Spend Cap restriction | UI quota exceeded and cap enabled earlier | No restriction transition/event tying it to 19:46; volume served until burst; unclean shutdown not explained by quota badge alone | Not demonstrated |
| Data corruption | End-of-WAL record-length message during recovery | Redo completed and decoding resumed; no corruption/PANIC signature found | Not demonstrated; no full integrity audit |
| Asset missing-user_id bug or 20:34 migration | Separate application failures existed | Constraint errors do not normally stop PostgreSQL; migration applied after recovery | Separate issue, not supported as restart cause |

Search of available 18:00–20:15 UTC logs found no explicit OOM, signal-9, no-space,
remaining-slots, too-many-clients, segmentation fault, PANIC or read-only-transaction
signature. **Absence of captured messages is not exclusion.** Postgres has a gap
between 19:42:43 and 20:04:09. Public Supabase status on this date lists a lifecycle
incident in ap-northeast-1, not this project's us-east-1; public status absence does
not rule out a project-local infrastructure fault.

## Required next evidence / support handoff

Send only after operator authorization, or paste into Supabase support:

> Project rnjgeloamtszdjplmqxy, primary DB us-east-1, 2026-11-11.
> Investigate 19:30–20:10 UTC, focusing on reachability loss at 19:46 and unclean
> PostgreSQL start at 20:04:09 UTC. Please provide host/container termination
> reason and lifecycle action/initiator, kernel OOM/cgroup events, host reboot or
> replacement markers, CPU/credits, memory/swap, disk capacity/inodes, IOPS/latency
> and connection high-water marks. Confirm whether Spend Cap enforcement occurred
> in this window. Gateway 522/524 samples and IDs are listed above. Postgres logs
> stop after checkpoint 19:42:43 and resume with unclean recovery; SQL/Realtime
> could not connect. No incident-time query/session history survived the reset.

Use [Studio Reports](https://supabase.com/dashboard/project/rnjgeloamtszdjplmqxy/reports)
and export the same time window before retention expires (Pro currently offers
up to seven days of report history). A new Metrics API scrape cannot retrieve
previous unsaved samples. If external Grafana/Prometheus history already exists,
use that instead of creating a collector retroactively. No monitoring configured.

Verification after any separately authorized fix: comparable gateway/Auth windows
with valid-status denominators; host time-series CPU/memory/swap/I/O and reset
markers; stable client counts; no repeated restart; lower latest-image query counts
and a reviewed plan. Do not claim a fix from a single health badge or zero events.

## References

- [API error interpretation](https://supabase.com/kb/troubleshooting/discovering-and-interpreting-api-errors-in-the-logs-7xREI9)
- [Metrics API](https://supabase.com/docs/guides/observability/metrics)
- [Metrics authentication/setup](https://supabase.com/docs/guides/observability/metrics/vendor-agnostic)
- [Reports/time windows](https://supabase.com/docs/guides/observability/reports)
- [Compute and disk sizing](https://supabase.com/docs/guides/platform/compute-and-disk)
- [PostgreSQL checkpoint behavior](https://www.postgresql.org/docs/17/runtime-config-wal.html)
- [Supabase public status](https://status.supabase.com/)
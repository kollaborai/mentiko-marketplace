---
id: incident-report
name: Incident Post-Mortem
format: markdown
category: analysis
tags: [incident, post-mortem, ops, reliability]
description: >
  Blameless post-mortem with timeline, impact analysis, root cause, five whys, and
  action items. Produced by an incident-response agent after a service disruption
  is resolved and data is gathered from logs and monitoring.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    incident_id:
      type: string
      description: Unique incident identifier
      pattern: "^INC-\\d+$"
    severity:
      type: string
      enum: [P0, P1, P2, P3]
      description: Incident severity level
    status:
      type: string
      enum: [open, mitigated, resolved, closed]
    timeline:
      type: array
      items:
        type: object
        properties:
          time:
            type: string
            description: ISO 8601 timestamp
          event:
            type: string
            description: What happened
          who:
            type: string
            description: Who took action or was involved
    root_cause:
      type: string
      description: Primary technical cause of the incident (minimum 2 sentences)
    action_items:
      type: array
      items:
        type: object
        properties:
          action:
            type: string
          owner:
            type: string
          due:
            type: string
          status:
            type: string
            enum: [open, in-progress, done]
    impact:
      type: object
      properties:
        users_affected:
          type: number
        duration_minutes:
          type: number
        services:
          type: array
          items:
            type: string
  required: [incident_id, severity, timeline, root_cause, action_items]
validation_rules:
  - severity must be P0, P1, P2, or P3
  - timeline entries must be in chronological order (ascending timestamps)
  - every action_item must have an owner and due date
  - root_cause must be at least 2 sentences
related_artifacts:
  - security-scan-report
  - diff-analysis
---

# Incident Post-Mortem: INC-2847

## Metadata

- Incident ID: INC-2847
- Date: 2026-03-08
- Duration: 23 minutes (14:37 UTC - 15:00 UTC)
- Severity: P1
- Status: resolved
- Author: Sarah Chen (SRE)
- Contributors: Marco Almazan (backend), Yuki Tanaka (DBA), Priya Sharma (on-call)

## Executive Summary

On March 8, 2026, a database connection pool exhaustion caused the Mentiko API to
return 503 errors for 23 minutes, affecting 847 active users. The root cause was a
misconfigured connection pool limit (10) that was not updated when we migrated from
SQLite to PostgreSQL in the production environment. A long-running analytics query
from a new reporting agent held 8 of the 10 connections for 4+ minutes, causing
all remaining request handlers to queue and time out. The issue was mitigated by
killing the runaway query and restarting the API with a corrected pool size of 50.

## Impact Assessment

| Metric | Value |
|--------|-------|
| Users affected | 847 |
| Downtime | 23 minutes |
| Revenue impact | ~$340 (estimated from MRR/uptime calculation) |
| Customer tickets | 14 (12 resolved, 2 pending follow-up) |
| Data loss | None |
| Chains interrupted | 31 (28 auto-retried successfully, 3 required manual restart) |

## Timeline

| Time (UTC) | Event | Who |
|------------|-------|-----|
| 14:31 | New analytics reporting agent (chain: daily-metrics-v2) launched in production | Automated scheduler |
| 14:33 | Reporting agent begins full-table scan of runs table (47M rows, no index on created_at) | reporting-agent session |
| 14:37 | API p99 latency spikes from 180ms to 8.2s; connection pool at 10/10 | Datadog alert fires |
| 14:38 | PagerDuty alert: "API error rate > 5%" fires, Priya Sharma paged | PagerDuty |
| 14:41 | Priya identifies connection pool saturation via `pg_stat_activity` | Priya Sharma |
| 14:43 | Marco identifies analytics query as the culprit (query running 10+ minutes) | Marco Almazan |
| 14:46 | Yuki executes `SELECT pg_cancel_backend(pid)` to kill runaway query | Yuki Tanaka |
| 14:47 | Connection pool begins draining; API error rate drops from 94% to 12% | Datadog |
| 14:52 | API restarted with `DB_POOL_SIZE=50` env override | Marco Almazan |
| 15:00 | API fully recovered; all metrics green; incident declared resolved | Priya Sharma |

### Timeline Narrative

The incident began silently at 14:31 when the automated scheduler launched the
`daily-metrics-v2` chain for the first time in production. The reporting agent within
this chain issued a full-table scan against the `runs` table, which contains 47 million
rows and lacks an index on the `created_at` column. PostgreSQL allocated 8 of the 10
available connections to execute and sort this query.

At 14:37, with only 2 connections remaining for all other API traffic, incoming requests
began queueing. Within 90 seconds, the queue depth exceeded the 30-second timeout, and
the API began returning 503s to end users. The Datadog alert fired at 14:38, and
on-call engineer Priya Sharma acknowledged within 3 minutes.

Diagnosis was fast because `pg_stat_activity` clearly showed the long-running query.
Killing it via `pg_cancel_backend` immediately freed the connections. Restarting the
API with a corrected pool size eliminated the underlying misconfiguration. Total
time to resolution: 23 minutes from first user impact.

## Root Cause Analysis

### Root Cause

The production PostgreSQL connection pool was configured with a limit of 10 connections,
a value carried over from the SQLite era where connection pooling was irrelevant.
This limit was never updated when the database was migrated to PostgreSQL in January 2026.
Under normal load this limit was sufficient, but the analytics reporting agent's
full-table scan consumed 80% of the pool and held those connections for 10+ minutes,
leaving insufficient capacity for regular API traffic.

### Contributing Factors

1. No index on `runs.created_at`, causing the analytics query to perform a full sequential scan instead of an index scan
2. `DB_POOL_SIZE` was not part of the deployment checklist or infrastructure-as-code configuration
3. The reporting chain was not load-tested in staging before being enabled in production

### Five Whys

1. Why did the API return 503s?
   The connection pool was exhausted and no connections were available for API handlers.

2. Why was the connection pool exhausted?
   A long-running analytics query held 8 of 10 connections for 10+ minutes.

3. Why was the connection pool only 10?
   The `DB_POOL_SIZE` configuration was never updated after the SQLite-to-PostgreSQL migration.

4. Why was the migration not audited for connection pool configuration?
   The migration focused on data integrity and schema; runtime configuration was not in scope.

5. Why did the analytics query hold connections so long?
   It performed a full table scan on 47M rows due to a missing index on the query's filter column.

## Resolution

The incident was resolved in two steps: (1) Yuki killed the runaway query using
`pg_cancel_backend`, which immediately freed 8 connections and allowed the API to
recover partially. (2) Marco restarted the API process with `DB_POOL_SIZE=50`
overriding the misconfigured default. The API was fully healthy by 15:00 UTC.

## Action Items

### Preventive (Fix Root Cause)

| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| Add `DB_POOL_SIZE=50` to production .env and infrastructure-as-code | Marco Almazan | 2026-03-10 | done |
| Create index on `runs.created_at` | Yuki Tanaka | 2026-03-11 | done |
| Add DB config section to post-migration checklist | Sarah Chen | 2026-03-15 | in-progress |

### Detective (Improve Monitoring)

| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| Add Datadog alert: connection pool utilization > 70% | Priya Sharma | 2026-03-12 | done |
| Add alert: any single query running > 60 seconds | Yuki Tanaka | 2026-03-15 | open |

### Reactive (Improve Response)

| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| Add runbook: DB connection pool exhaustion recovery steps | Sarah Chen | 2026-03-17 | open |
| Load-test new chains in staging before enabling in prod scheduler | Marco Almazan | 2026-03-20 | open |

## Lessons Learned

### What went well

- Alert fired within 1 minute of user impact (p99 latency threshold was well-tuned)
- `pg_stat_activity` made diagnosis fast and unambiguous
- Team communication in #incidents was calm and focused; no blame
- Auto-retry recovered 28 of 31 interrupted chains without user intervention

### What could be improved

- Connection pool configuration should be infrastructure-as-code, not an env var
- New chains with analytics queries should require a staging load test sign-off
- The migration checklist did not cover runtime configuration parameters

### Knowledge gaps identified

- Not all engineers knew the default `DB_POOL_SIZE` was still the SQLite-era value
- No documented process for identifying and killing runaway PostgreSQL queries

## Appendix

- Datadog incident dashboard: https://app.datadoghq.com/incidents/INC-2847
- PostgreSQL slow query log export: s3://mentiko-logs/incidents/INC-2847/pg-slow-queries.log
- Metrics graphs (14:30-15:15 UTC): https://app.datadoghq.com/dashboard/abc-123

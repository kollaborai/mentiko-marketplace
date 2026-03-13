---
id: log-output
name: Log Output
format: json
category: cli
tags: [logs, observability, errors, warnings, debugging]
description: >
  Parsed log output from an agent, service, or system process. Structured
  as an array of log entries with level, timestamp, message, and optional
  context. Produced by agents that analyze or summarize application logs.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    source:
      type: string
      description: where the logs came from (service name, file path, or session name)
    entries:
      type: array
      description: individual log lines parsed into structured form
      items:
        type: object
        properties:
          timestamp:
            type: string
            description: ISO 8601 timestamp string
          level:
            type: string
            enum: [debug, info, warn, error, fatal]
            description: log level
          message:
            type: string
            description: log message text (without timestamp or level prefix)
          context:
            type: [object, "null"]
            description: structured key-value context attached to this entry (null if none)
            additionalProperties: true
          source_line:
            type: string
            description: original raw log line before parsing
        required: [timestamp, level, message, context]
    errors_found:
      type: integer
      minimum: 0
      description: count of entries with level error or fatal
    warnings_found:
      type: integer
      minimum: 0
      description: count of entries with level warn
    total_lines:
      type: integer
      minimum: 0
      description: total log lines examined (including debug/info that may be summarized)
    summary:
      type: string
      description: one-paragraph analysis of what the logs show
    time_range:
      type: object
      description: start and end of the log window
      properties:
        from:
          type: string
          description: ISO 8601 timestamp of first entry
        to:
          type: string
          description: ISO 8601 timestamp of last entry
      required: [from, to]
  required: [source, entries, errors_found, warnings_found, total_lines, summary]
validation_rules:
  - level must be one of debug, info, warn, error, fatal
  - errors_found must equal count of entries where level is error or fatal
  - warnings_found must equal count of entries where level is warn
  - total_lines must be >= length of entries (entries may be a filtered subset)
  - timestamp must be a valid ISO 8601 string
  - summary must be non-empty
related_artifacts:
  - command-output
  - build-output
  - incident-report
---

```json
{
  "source": "docker logs mentiko-app-1 --since 1h",
  "total_lines": 847,
  "errors_found": 3,
  "warnings_found": 7,
  "summary": "847 log lines examined over 58 minutes. 3 errors occurred: one auth token decode failure at 14:23 (expired JWT from a webhook retry), one unhandled promise rejection in the chain-runner webhook handler at 14:31 (null agent emits field), and one database connection timeout at 14:44 that self-recovered after 2 retries. 7 warnings were rate-limit notices from the Stripe mock. No data loss detected.",
  "time_range": {
    "from": "2026-03-13T14:00:12.441Z",
    "to": "2026-03-13T14:58:03.109Z"
  },
  "entries": [
    {
      "timestamp": "2026-03-13T14:23:07.882Z",
      "level": "error",
      "message": "JWT verification failed: jwt expired",
      "context": {
        "path": "/api/webhooks/inbound",
        "method": "POST",
        "webhook_id": "wh_01j9k2m4n7p8q3r5s6t",
        "token_iat": 1741824000,
        "token_exp": 1741827600
      },
      "source_line": "2026-03-13T14:23:07.882Z [error] JWT verification failed: jwt expired {\"path\":\"/api/webhooks/inbound\",\"webhook_id\":\"wh_01j9k2m4n7p8q3r5s6t\"}"
    },
    {
      "timestamp": "2026-03-13T14:31:44.203Z",
      "level": "error",
      "message": "Unhandled promise rejection in webhook chain trigger",
      "context": {
        "chain_id": "analyze-pr-b29x",
        "error": "Cannot read properties of null (reading 'emits')",
        "agent_index": 2,
        "stack": "TypeError: Cannot read properties of null (reading 'emits')\n    at runAgent (lib/chain-runner.sh:247)\n    at chainWebhookHandler (/app/api/webhooks/chain/route.ts:88)"
      },
      "source_line": "2026-03-13T14:31:44.203Z [error] Unhandled promise rejection in webhook chain trigger {\"chain_id\":\"analyze-pr-b29x\",\"agent_index\":2}"
    },
    {
      "timestamp": "2026-03-13T14:44:19.556Z",
      "level": "error",
      "message": "Database connection timeout — retrying (attempt 1/3)",
      "context": {
        "host": "postgres",
        "port": 5432,
        "timeout_ms": 5000,
        "operation": "SELECT"
      },
      "source_line": "2026-03-13T14:44:19.556Z [error] Database connection timeout — retrying (attempt 1/3)"
    },
    {
      "timestamp": "2026-03-13T14:44:24.712Z",
      "level": "info",
      "message": "Database connection restored after 2 retries",
      "context": {
        "host": "postgres",
        "duration_ms": 5156
      },
      "source_line": "2026-03-13T14:44:24.712Z [info] Database connection restored after 2 retries"
    },
    {
      "timestamp": "2026-03-13T14:17:03.001Z",
      "level": "warn",
      "message": "Stripe mock rate limit approached (80/100 req/min)",
      "context": {
        "service": "stripe-mock",
        "current": 80,
        "limit": 100
      },
      "source_line": "2026-03-13T14:17:03.001Z [warn] Stripe mock rate limit approached (80/100 req/min)"
    }
  ]
}
```

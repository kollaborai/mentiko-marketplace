---
id: data-analysis-report
name: Data Analysis Report
format: json
category: data
tags: [data, statistics, analysis, dataset, anomalies, correlation]
description: Statistical analysis of a dataset with per-column metrics, anomaly detection, and correlation findings. Output of data profiling or exploratory data analysis (EDA) agents.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    dataset:
      type: string
      description: Dataset name, file path, or table identifier
    source:
      type: string
      description: Data source (e.g. "postgres://prod/events", "s3://bucket/events.csv")
    analyzed_at:
      type: string
      format: date-time
    rows_analyzed:
      type: integer
      description: Total rows in the dataset
    rows_sampled:
      type: integer
      description: Rows used for analysis (may differ if sampling was applied)
    columns:
      type: integer
      description: Total column count
    findings:
      type: array
      description: Per-field analysis
      items:
        type: object
        properties:
          field:
            type: string
            description: Column or field name
          type:
            type: string
            enum: [string, integer, float, boolean, datetime, json, unknown]
          nullable:
            type: boolean
          stats:
            type: object
            properties:
              min:
                description: Minimum value (type-appropriate)
              max:
                description: Maximum value
              mean:
                type: [number, "null"]
              median:
                type: [number, "null"]
              std_dev:
                type: [number, "null"]
              null_count:
                type: integer
              null_pct:
                type: number
              unique_count:
                type: integer
              top_values:
                type: array
                description: Most frequent values with counts
                items:
                  type: object
                  properties:
                    value: {}
                    count:
                      type: integer
                    pct:
                      type: number
          anomalies:
            type: array
            items:
              type: string
            description: Detected data quality issues or outliers
          recommendation:
            type: string
            description: Suggested action (validation rule, imputation strategy, etc.)
        required: [field, type, stats, anomalies]
    correlations:
      type: array
      description: Notable statistical correlations between numeric fields
      items:
        type: object
        properties:
          field_a:
            type: string
          field_b:
            type: string
          coefficient:
            type: number
            minimum: -1
            maximum: 1
            description: Pearson correlation coefficient
          strength:
            type: string
            enum: [strong, moderate, weak, negligible]
          direction:
            type: string
            enum: [positive, negative]
          notable:
            type: boolean
            description: True if coefficient magnitude > 0.7
        required: [field_a, field_b, coefficient, strength]
    data_quality_score:
      type: number
      minimum: 0
      maximum: 100
      description: Overall data quality score (completeness + validity + consistency)
    summary:
      type: string
      description: Key findings and actionable recommendations
  required: [dataset, analyzed_at, rows_analyzed, columns, findings, correlations, summary]
validation_rules:
  - correlations.coefficient must be between -1.0 and 1.0
  - stats.null_pct must equal (null_count / rows_analyzed) * 100
  - data_quality_score must be between 0 and 100
  - each finding.field must be unique within the findings array
  - strength must be "strong" if |coefficient| >= 0.7, "moderate" if >= 0.4, "weak" if >= 0.2, "negligible" otherwise
  - rows_sampled must be <= rows_analyzed
  - top_values pct values must sum to <= 100
related_artifacts: [metrics-report, research-summary]
---

{
  "dataset": "user_events",
  "source": "postgres://prod/analytics.user_events",
  "analyzed_at": "2026-03-13T05:00:00Z",
  "rows_analyzed": 2847391,
  "rows_sampled": 250000,
  "columns": 9,
  "data_quality_score": 74.2,
  "findings": [
    {
      "field": "user_id",
      "type": "string",
      "nullable": false,
      "stats": {
        "min": null,
        "max": null,
        "mean": null,
        "median": null,
        "std_dev": null,
        "null_count": 0,
        "null_pct": 0,
        "unique_count": 48213,
        "top_values": [
          { "value": "usr_anon", "count": 14209, "pct": 5.68 }
        ]
      },
      "anomalies": [
        "5.68% of events use the literal string 'usr_anon' rather than null for unauthenticated users — inconsistent sentinel value"
      ],
      "recommendation": "Standardize unauthenticated sessions to NULL user_id and add a separate boolean is_anonymous column."
    },
    {
      "field": "event_type",
      "type": "string",
      "nullable": false,
      "stats": {
        "min": null,
        "max": null,
        "mean": null,
        "median": null,
        "std_dev": null,
        "null_count": 0,
        "null_pct": 0,
        "unique_count": 147,
        "top_values": [
          { "value": "page_view", "count": 142381, "pct": 56.95 },
          { "value": "click", "count": 58204, "pct": 23.28 },
          { "value": "form_submit", "count": 21003, "pct": 8.40 }
        ]
      },
      "anomalies": [
        "147 distinct event types detected — expected ~30 based on schema docs. 117 undocumented types suggest client-side event naming is not validated.",
        "12 event types contain raw stack traces (e.g. 'Error: Cannot read...'): likely client-side error logging leaking into event stream."
      ],
      "recommendation": "Introduce an event type allowlist at ingestion. Route unrecognized types to a dead-letter table for review."
    },
    {
      "field": "duration_ms",
      "type": "float",
      "nullable": true,
      "stats": {
        "min": 0,
        "max": 86400000,
        "mean": 2847.3,
        "median": 412,
        "std_dev": 18423.1,
        "null_count": 31204,
        "null_pct": 12.5,
        "unique_count": 48901,
        "top_values": [
          { "value": 0, "count": 8412, "pct": 3.36 }
        ]
      },
      "anomalies": [
        "Max value of 86400000ms (24 hours) is physically impossible for a UI event — session timer not being reset on tab close.",
        "3.36% of events have duration_ms = 0 exactly — likely a client-side measurement failure.",
        "High std_dev (18423ms) relative to median (412ms) indicates extreme outliers skewing mean."
      ],
      "recommendation": "Cap duration_ms at 3600000 (1 hour) at ingestion. Treat 0-value as null. Investigate tab visibility API integration on client."
    },
    {
      "field": "created_at",
      "type": "datetime",
      "nullable": false,
      "stats": {
        "min": "2024-01-01T00:00:00Z",
        "max": "2026-03-13T04:59:59Z",
        "mean": null,
        "median": null,
        "std_dev": null,
        "null_count": 0,
        "null_pct": 0,
        "unique_count": 2847391,
        "top_values": []
      },
      "anomalies": [
        "0.03% of events have created_at in 2024 despite table only existing since 2025-06 — backdated events from data import."
      ],
      "recommendation": "Flag pre-2025-06 records for audit. Add a CHECK constraint: created_at >= '2025-06-01'."
    }
  ],
  "correlations": [
    {
      "field_a": "session_depth",
      "field_b": "conversion",
      "coefficient": 0.81,
      "strength": "strong",
      "direction": "positive",
      "notable": true
    },
    {
      "field_a": "duration_ms",
      "field_b": "error_count",
      "coefficient": 0.63,
      "strength": "moderate",
      "direction": "positive",
      "notable": false
    },
    {
      "field_a": "user_age_days",
      "field_b": "churn_flag",
      "coefficient": -0.71,
      "strength": "strong",
      "direction": "negative",
      "notable": true
    }
  ],
  "summary": "Data quality score is 74.2/100. Critical issues: (1) 147 undocumented event types including raw client error stack traces leaking into the event stream, (2) duration_ms values up to 86.4M ms (24h) are physically impossible and will corrupt aggregations, (3) the 'usr_anon' sentinel string creates an unindexable hotspot row for anonymous users. The strong positive correlation between session_depth and conversion (0.81) is the most actionable signal — users who reach depth 5+ convert at 4x the baseline rate."
}

---
id: metrics-report
name: Metrics & KPI Report
format: csv
category: business
tags: [metrics, kpi, reporting, data]
description: >
  Structured metrics report with KPI tracking, trend analysis, and variance from target.
  CSV-compatible for spreadsheet import. Produced by a reporting agent at the end of
  each reporting period (weekly, monthly, quarterly).
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    period:
      type: string
      description: Reporting period e.g. 2025-Q1 or 2026-03
    metrics:
      type: array
      items:
        type: object
        properties:
          metric:
            type: string
            description: Metric name in snake_case
          value:
            type: number
            description: Actual measured value (numeric, not string)
          target:
            type: number
            description: Target value for this period
          variance:
            type: number
            description: Absolute difference (value - target)
          variance_pct:
            type: string
            description: Percentage variance formatted as +/-X.X%
          trend:
            type: string
            enum: [up, down, flat]
            description: Direction relative to prior period
          period:
            type: string
            description: Period this measurement covers
          category:
            type: string
            enum: [product, revenue, ops, engineering, support]
    summary:
      type: string
      description: Plain-text summary of performance vs targets
  required: [period, metrics]
validation_rules:
  - trend must be one of up, down, flat (not "improving" or "declining")
  - variance_pct must be formatted as +/-X.X% (e.g. +3.3% or -8.6%)
  - all numeric values (value, target, variance) must be numbers not strings
  - category must be one of product, revenue, ops, engineering, support
related_artifacts:
  - data-analysis-report
  - benchmark-results
---

```csv
metric,value,target,variance,variance_pct,trend,period,category
mau,14820,14000,820,+5.9%,up,2026-02,product
dau,4140,3800,340,+8.9%,up,2026-02,product
dau_mau_ratio,0.279,0.271,0.008,+3.0%,up,2026-02,product
new_signups,1240,1100,140,+12.7%,up,2026-02,product
activation_rate,0.38,0.40,-0.02,-5.0%,down,2026-02,product
chain_runs_total,98450,90000,8450,+9.4%,up,2026-02,ops
chain_success_rate,0.947,0.95,-0.003,-0.3%,flat,2026-02,ops
avg_chain_duration_sec,142,120,22,+18.3%,down,2026-02,ops
agent_sessions_started,312840,280000,32840,+11.7%,up,2026-02,ops
mrr,87400,82000,5400,+6.6%,up,2026-02,revenue
arpu,48.20,50.00,-1.80,-3.6%,down,2026-02,revenue
churn_rate,0.019,0.025,-0.006,-24.0%,down,2026-02,revenue
ltv,770,800,-30,-3.8%,flat,2026-02,revenue
cac,108,100,8,+8.0%,up,2026-02,revenue
ltv_cac_ratio,7.13,8.0,-0.87,-10.9%,down,2026-02,revenue
nps_score,51,50,1,+2.0%,up,2026-02,support
support_ticket_volume,287,300,-13,-4.3%,down,2026-02,support
ticket_first_response_hrs,1.8,2.0,-0.2,-10.0%,down,2026-02,support
p99_api_latency_ms,210,200,10,+5.0%,flat,2026-02,engineering
error_rate,0.0071,0.010,-0.003,-29.0%,down,2026-02,engineering
uptime,0.9994,0.9990,0.0004,+0.0%,flat,2026-02,engineering
deploy_frequency_per_week,4.2,4.0,0.2,+5.0%,up,2026-02,engineering
mean_time_to_recovery_min,18,30,-12,-40.0%,down,2026-02,engineering
```

## Summary

period: 2026-02

Performance vs target: 14/23 metrics at or above target (61%).

Top performing:
- churn_rate down to 1.9% vs 2.5% target (-24%) — retention holding strong
- new_signups +12.7% over target — top-of-funnel healthy
- mean_time_to_recovery -40% vs target — incident response improving significantly

Needs attention:
- activation_rate 38% vs 40% target — users signing up but not completing first chain run
- avg_chain_duration_sec 18.3% over target — performance regression in chain runner (see INC-2847)
- ltv_cac_ratio 7.13 vs 8.0 target — CAC creeping up as paid acquisition scales

Recommended actions:
1. Investigate activation funnel drop-off — add onboarding analytics to identify where new users get stuck
2. Profile chain-runner.sh performance — avg chain duration regression started 2026-02-12 (after v0.8 deploy)
3. Review paid acquisition channels — CAC up 8%, evaluate channel efficiency before increasing spend

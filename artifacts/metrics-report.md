---
id: metrics-report
name: Metrics & KPI Report
format: csv
category: business
tags: [metrics, kpi, reporting, data]
description: Structured metrics report with KPI tracking, trend analysis, and variance explanations. CSV-compatible for spreadsheet import.
author: mentiko
version: 1.0
---

```csv
metric,value,target,variance,variance_pct,trend,period,category
MAU,12400,12000,+400,+3.3%,up,2025-03,product
DAU,3200,3000,+200,+6.7%,up,2025-03,product
conversion_rate,3.2%,3.5%,-0.3%,-8.6%,down,2025-03,growth
churn_rate,2.1%,2.5%,-0.4%,-16%,improving,2025-03,retention
arpu,45.00,50.00,-5.00,-10%,down,2025-03,revenue
cac,120.00,100.00,+20.00,+20%,up,2025-03,marketing
ltv,540.00,600.00,-60.00,-10%,down,2025-03,revenue
ltv_cac_ratio,4.5,6.0,-1.5,-25%,down,2025-03,finance
nps_score,42,50,-8,-16%,down,2025-03,satisfaction
response_time,2.5,3.0,-0.5,-16.7%,improving,2025-03,support
uptime_percentage,99.95%,99.9%,+0.05%,stable,2025-03,infra
error_rate,0.08%,0.1%,-0.02%,-20%,improving,2025-03,infra
```

## Summary
- Performance vs target: {METRICS_MEETING}/{TOTAL_METRICS} ({PERCENTAGE}%)
- Top improving metrics: {IMPROVING_LIST}
- Top declining metrics: {DECLINING_LIST}
- Key insights: {INSIGHTS}
- Recommended actions: {ACTIONS}

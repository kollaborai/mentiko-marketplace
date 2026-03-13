---
id: performance-analysis
name: Performance Analysis Report
format: json
category: analysis
tags: [performance, profiling, latency, throughput, bottleneck]
description: Performance profiling results with latency percentiles, throughput metrics, memory peaks, and bottleneck locations. Supports baseline comparisons for regression detection.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    profiler:
      type: string
      description: Profiling tool used (e.g. "artillery 2.0", "py-spy 0.3.14", "async-profiler 3.0")
    target:
      type: string
      description: Endpoint, function, or service profiled
    environment:
      type: object
      properties:
        cpu:
          type: string
          description: CPU model and core count
        memory_gb:
          type: number
        os:
          type: string
        runtime:
          type: string
          description: Runtime version (e.g. "node 22.3.0", "python 3.11.8")
    profiled_at:
      type: string
      format: date-time
    duration_s:
      type: number
      description: Test duration in seconds
    metrics:
      type: object
      properties:
        p50_ms:
          type: number
          description: Median response time in ms
        p75_ms:
          type: number
        p95_ms:
          type: number
          description: 95th percentile response time in ms
        p99_ms:
          type: number
        p999_ms:
          type: number
          description: 99.9th percentile response time in ms
        mean_ms:
          type: number
        min_ms:
          type: number
        max_ms:
          type: number
        rps:
          type: number
          description: Requests per second (throughput)
        error_rate_pct:
          type: number
          description: Percentage of requests that errored
        concurrent_users:
          type: integer
          description: Virtual users during test
      required: [p50_ms, p95_ms, p99_ms, mean_ms, rps, error_rate_pct]
    memory_peak_mb:
      type: number
      description: Peak heap memory usage in MB
    cpu_peak_pct:
      type: number
      description: Peak CPU utilization percentage
    bottlenecks:
      type: array
      items:
        type: object
        properties:
          location:
            type: string
            description: Function name, file path, or query
          type:
            type: string
            enum: [cpu, io, memory, network, lock, query]
          duration_ms:
            type: number
            description: Average time spent per request
          percentage:
            type: number
            description: Percentage of total request time
          call_count:
            type: integer
            description: Number of times called per request
          recommendation:
            type: string
        required: [location, type, duration_ms, percentage, recommendation]
    comparison_baseline:
      type: [object, "null"]
      description: Baseline metrics for regression comparison, null if first run
      properties:
        label:
          type: string
          description: Baseline identifier (e.g. "v2.1.0", "main@abc1234")
        p95_ms:
          type: number
        p99_ms:
          type: number
        rps:
          type: number
        delta_p95_pct:
          type: number
          description: Percentage change in p95 vs baseline (positive = slower)
        delta_rps_pct:
          type: number
          description: Percentage change in RPS vs baseline (positive = faster)
        regression_detected:
          type: boolean
    conclusion:
      type: string
      description: Summary of findings and top recommendations
  required: [profiler, target, profiled_at, metrics, bottlenecks, comparison_baseline, conclusion]
validation_rules:
  - p50_ms <= p75_ms <= p95_ms <= p99_ms (latency percentiles must be monotonically increasing)
  - error_rate_pct must be between 0 and 100
  - bottleneck percentage values must sum to <= 100
  - memory_peak_mb must be a positive number when present
  - cpu_peak_pct must be between 0 and 100 when present
  - comparison_baseline.delta_p95_pct must be computed as ((current - baseline) / baseline) * 100
related_artifacts: [benchmark-results, metrics-report]
---

{
  "profiler": "artillery 2.0.22",
  "target": "POST /api/chains/run",
  "environment": {
    "cpu": "AMD EPYC 7B13 x4 cores",
    "memory_gb": 8,
    "os": "debian 12 (bookworm)",
    "runtime": "node 22.3.0"
  },
  "profiled_at": "2026-03-13T06:00:00Z",
  "duration_s": 300,
  "metrics": {
    "p50_ms": 142,
    "p75_ms": 218,
    "p95_ms": 687,
    "p99_ms": 1240,
    "p999_ms": 2891,
    "mean_ms": 189,
    "min_ms": 38,
    "max_ms": 4102,
    "rps": 23.7,
    "error_rate_pct": 0.4,
    "concurrent_users": 50
  },
  "memory_peak_mb": 412,
  "cpu_peak_pct": 78,
  "bottlenecks": [
    {
      "location": "chain-runner.sh:execute_agent()",
      "type": "io",
      "duration_ms": 381,
      "percentage": 55.4,
      "call_count": 1,
      "recommendation": "Agent process spawning is synchronous and blocks the event loop. Move to child_process.spawn with async await and add a process pool for hot chains."
    },
    {
      "location": "db.query('SELECT * FROM runs WHERE org_id = ?')",
      "type": "query",
      "duration_ms": 112,
      "percentage": 16.3,
      "call_count": 3,
      "recommendation": "Missing index on (org_id, created_at). Add: CREATE INDEX idx_runs_org_created ON runs(org_id, created_at DESC). Also deduplicate the 3 identical queries into one."
    },
    {
      "location": "sanitizeOutput() in sanitize-output.ts",
      "type": "cpu",
      "duration_ms": 58,
      "percentage": 8.4,
      "call_count": 12,
      "recommendation": "Regex patterns are recompiled on every call. Move ANSI_REGEX and CREDENTIAL_PATTERNS to module scope as compiled constants."
    }
  ],
  "comparison_baseline": {
    "label": "v2.3.1",
    "p95_ms": 521,
    "p99_ms": 890,
    "rps": 28.4,
    "delta_p95_pct": 31.9,
    "delta_rps_pct": -16.5,
    "regression_detected": true
  },
  "conclusion": "P95 latency has regressed 31.9% vs v2.3.1 (521ms -> 687ms) and throughput dropped 16.5% (28.4 -> 23.7 rps). The dominant bottleneck is synchronous agent process spawning (55% of request time). Adding a database index on (org_id, created_at) and fixing regex recompilation in sanitizeOutput are quick wins worth ~24% latency improvement without architectural changes."
}

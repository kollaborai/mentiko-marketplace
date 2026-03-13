---
id: benchmark-results
name: Benchmark Results
format: json
category: analysis
tags: [benchmark, performance, comparison, optimization, ci]
description: Performance benchmark comparison between implementation variants or versions. Tracks named metrics with before/after values, delta percentages, and a pass/fail conclusion for CI gates.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    suite:
      type: string
      description: Benchmark suite name
    tool:
      type: string
      description: Benchmark framework (e.g. "hyperfine 1.18", "criterion 0.5", "bench.js 2.1.7")
    ran_at:
      type: string
      format: date-time
    iterations:
      type: integer
      description: Runs per benchmark metric
    warmup_iterations:
      type: integer
      description: Warmup runs excluded from results
    environment:
      type: object
      properties:
        cpu:
          type: string
        memory_gb:
          type: number
        os:
          type: string
        runtime:
          type: string
        load_avg:
          type: number
          description: System load average during benchmark (lower is more isolated)
      required: [cpu, os]
    metrics:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
            description: Benchmark metric name
          unit:
            type: string
            description: Measurement unit (e.g. "ms", "ops/sec", "MB/s", "ns")
          baseline:
            type: number
            description: Reference value (previous version, alternative implementation)
          baseline_label:
            type: string
            description: What the baseline represents (e.g. "v2.3.1", "naive-impl")
          current:
            type: number
            description: New implementation value
          current_label:
            type: string
            description: What current represents (e.g. "v2.4.0", "optimized-impl")
          delta_pct:
            type: number
            description: Percentage change (positive = higher value, interpretation depends on metric)
          improved:
            type: boolean
            description: True if the change is an improvement (context-aware: lower latency = improvement)
          std_dev_baseline:
            type: number
            description: Standard deviation of baseline measurements
          std_dev_current:
            type: number
            description: Standard deviation of current measurements
          statistically_significant:
            type: boolean
            description: True if delta exceeds noise threshold (typically > 2x std_dev)
        required: [name, unit, baseline, current, delta_pct, improved, statistically_significant]
    regressions_detected:
      type: integer
      description: Count of metrics where improved=false and statistically_significant=true
    improvements_detected:
      type: integer
      description: Count of metrics where improved=true and statistically_significant=true
    ci_gate_passed:
      type: boolean
      description: True if regressions_detected == 0
    conclusion:
      type: string
      description: Summary of benchmark results and recommendations
  required: [suite, tool, ran_at, metrics, regressions_detected, improvements_detected, ci_gate_passed, conclusion]
validation_rules:
  - delta_pct must be computed as ((current - baseline) / baseline) * 100 rounded to 2 decimal places
  - ci_gate_passed must be true iff regressions_detected == 0
  - regressions_detected must equal count of metrics where improved=false and statistically_significant=true
  - improvements_detected must equal count of metrics where improved=true and statistically_significant=true
  - iterations must be >= 10 for statistically valid results
  - std_dev values must be positive numbers when present
related_artifacts: [performance-analysis, metrics-report]
---

{
  "suite": "chain-runner execution benchmarks",
  "tool": "hyperfine 1.18.0",
  "ran_at": "2026-03-13T04:30:00Z",
  "iterations": 100,
  "warmup_iterations": 10,
  "environment": {
    "cpu": "Apple M3 Pro (12-core)",
    "memory_gb": 36,
    "os": "macOS 15.3.1",
    "runtime": "node 22.3.0",
    "load_avg": 0.41
  },
  "metrics": [
    {
      "name": "chain cold start",
      "unit": "ms",
      "baseline": 312.4,
      "baseline_label": "v2.3.1 — single pty session per agent",
      "current": 198.7,
      "current_label": "v2.4.0 — pty session pool (pre-warmed)",
      "delta_pct": -36.41,
      "improved": true,
      "std_dev_baseline": 18.2,
      "std_dev_current": 9.4,
      "statistically_significant": true
    },
    {
      "name": "agent handoff latency",
      "unit": "ms",
      "baseline": 84.1,
      "baseline_label": "v2.3.1",
      "current": 61.3,
      "current_label": "v2.4.0",
      "delta_pct": -27.11,
      "improved": true,
      "std_dev_baseline": 6.8,
      "std_dev_current": 4.1,
      "statistically_significant": true
    },
    {
      "name": "event file parse throughput",
      "unit": "ops/sec",
      "baseline": 4820,
      "baseline_label": "v2.3.1 — JSON.parse on each poll",
      "current": 12340,
      "current_label": "v2.4.0 — compiled schema validator",
      "delta_pct": 156.02,
      "improved": true,
      "std_dev_baseline": 241,
      "std_dev_current": 189,
      "statistically_significant": true
    },
    {
      "name": "sanitizeOutput() call",
      "unit": "ms",
      "baseline": 0.41,
      "baseline_label": "v2.3.1",
      "current": 0.44,
      "current_label": "v2.4.0",
      "delta_pct": 7.32,
      "improved": false,
      "std_dev_baseline": 0.08,
      "std_dev_current": 0.09,
      "statistically_significant": false
    },
    {
      "name": "peak memory per chain run",
      "unit": "MB",
      "baseline": 187,
      "baseline_label": "v2.3.1",
      "current": 204,
      "current_label": "v2.4.0 — session pool pre-allocates 5 slots",
      "delta_pct": 9.09,
      "improved": false,
      "std_dev_baseline": 12,
      "std_dev_current": 14,
      "statistically_significant": true
    }
  ],
  "regressions_detected": 1,
  "improvements_detected": 3,
  "ci_gate_passed": false,
  "conclusion": "v2.4.0 delivers strong wins: chain cold start improved 36.4% and event parsing throughput tripled (156% improvement) due to the compiled schema validator. The memory regression (+9.1MB per run) is real and statistically significant — the pre-warmed pty session pool allocates 5 idle sessions at startup. Acceptable if chain throughput is the priority, but should be made configurable (pool_size: 0 to disable). The sanitizeOutput delta (7.3%) is within noise and not statistically significant."
}

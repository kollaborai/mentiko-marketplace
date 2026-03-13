---
id: test-coverage-report
name: Test Coverage Report
format: json
category: analysis
tags: [testing, coverage, quality, jest, pytest, ci]
description: Test coverage analysis with per-file breakdown, uncovered line tracking, and threshold pass/fail. Works with any coverage tool (Jest, pytest-cov, Istanbul, etc.).
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    tool:
      type: string
      description: Coverage tool and version (e.g. "jest 29.7 + istanbul")
    generated_at:
      type: string
      format: date-time
    total_coverage_pct:
      type: number
      minimum: 0
      maximum: 100
      description: Overall statement coverage percentage
    line_coverage_pct:
      type: number
      minimum: 0
      maximum: 100
    branch_coverage_pct:
      type: number
      minimum: 0
      maximum: 100
    function_coverage_pct:
      type: number
      minimum: 0
      maximum: 100
    statement_coverage_pct:
      type: number
      minimum: 0
      maximum: 100
    threshold_pct:
      type: number
      description: Required minimum coverage percentage (from config)
    threshold_passed:
      type: boolean
      description: Whether total_coverage_pct >= threshold_pct
    files_analyzed:
      type: integer
    total_lines:
      type: integer
    covered_lines:
      type: integer
    uncovered_files:
      type: array
      description: Files below threshold or with notable gaps
      items:
        type: object
        properties:
          path:
            type: string
          coverage_pct:
            type: number
          uncovered_lines:
            type: array
            items:
              type: integer
            description: Line numbers with no coverage
          uncovered_branches:
            type: integer
          reason:
            type: string
            description: Why this file matters (e.g. "core auth logic")
        required: [path, coverage_pct, uncovered_lines]
    top_covered_files:
      type: array
      description: Files with 100% or near-100% coverage (positive signal)
      items:
        type: object
        properties:
          path:
            type: string
          coverage_pct:
            type: number
    summary:
      type: string
      description: Human-readable summary with key gaps and recommendations
  required: [tool, generated_at, total_coverage_pct, line_coverage_pct, branch_coverage_pct, function_coverage_pct, threshold_pct, threshold_passed, uncovered_files]
validation_rules:
  - threshold_passed must be true iff total_coverage_pct >= threshold_pct
  - all coverage percentages must be between 0 and 100 inclusive
  - covered_lines must be <= total_lines when both are present
  - uncovered_lines arrays must contain only positive integers
  - each path in uncovered_files must be unique
  - coverage_pct in uncovered_files should be < threshold_pct (otherwise not worth listing)
related_artifacts: [code-quality-report, regression-report]
---

{
  "tool": "jest 29.7.0 + @jest/coverage-provider v29.7.0 (istanbul)",
  "generated_at": "2026-03-13T07:45:00Z",
  "total_coverage_pct": 71.4,
  "line_coverage_pct": 73.1,
  "branch_coverage_pct": 62.8,
  "function_coverage_pct": 78.3,
  "statement_coverage_pct": 71.4,
  "threshold_pct": 80,
  "threshold_passed": false,
  "files_analyzed": 84,
  "total_lines": 6240,
  "covered_lines": 4562,
  "uncovered_files": [
    {
      "path": "src/auth/mfa.ts",
      "coverage_pct": 28.1,
      "uncovered_lines": [34, 35, 36, 51, 52, 71, 72, 73, 74, 88, 89, 103, 104, 105, 119],
      "uncovered_branches": 12,
      "reason": "Core MFA logic — TOTP validation and backup codes are untested"
    },
    {
      "path": "src/api/billing/webhooks.ts",
      "coverage_pct": 41.7,
      "uncovered_lines": [67, 68, 69, 70, 88, 89, 102, 103, 104, 115, 116],
      "uncovered_branches": 8,
      "reason": "Stripe webhook handler — failure paths and idempotency logic not tested"
    },
    {
      "path": "src/lib/queue/processor.ts",
      "coverage_pct": 55.2,
      "uncovered_lines": [144, 145, 146, 147, 161, 162, 180, 181, 182],
      "uncovered_branches": 5,
      "reason": "Job retry and dead-letter queue paths have no test coverage"
    },
    {
      "path": "src/db/migrations/runner.ts",
      "coverage_pct": 0,
      "uncovered_lines": [],
      "uncovered_branches": 0,
      "reason": "Migration runner has zero test coverage — untested in CI"
    },
    {
      "path": "src/utils/crypto.ts",
      "coverage_pct": 66.7,
      "uncovered_lines": [22, 23, 38, 39, 40],
      "uncovered_branches": 3,
      "reason": "Key derivation error branches untested"
    }
  ],
  "top_covered_files": [
    { "path": "src/utils/validators.ts", "coverage_pct": 100 },
    { "path": "src/api/health/route.ts", "coverage_pct": 100 },
    { "path": "src/models/user.ts", "coverage_pct": 97.4 },
    { "path": "src/lib/pagination.ts", "coverage_pct": 96.2 }
  ],
  "summary": "Coverage is at 71.4%, below the 80% threshold. The three most critical gaps are: MFA logic (28.1%), Stripe webhook handlers (41.7%), and the job queue retry paths (55.2%). The migration runner has 0% coverage and should be treated as a P1 gap given deployment risk. Branch coverage at 62.8% is the weakest metric — error paths and conditional branches are systematically undertested."
}

---
id: code-quality-report
name: Code Quality Report
format: json
category: analysis
tags: [code-quality, complexity, duplication, maintainability, technical-debt, metrics]
description: Code quality metrics covering cyclomatic complexity, code duplication, maintainability index, and a hotspot map of files most in need of attention.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    tool:
      type: string
      description: Quality analysis tool(s) used (e.g. "sonarqube 10.4", "codeclimate", "radon + pylint")
    analyzed_at:
      type: string
      format: date-time
    codebase_root:
      type: string
      description: Analyzed directory path
    overall_score:
      type: number
      minimum: 0
      maximum: 100
      description: Composite quality score (100 = perfect, 0 = critical)
    grade:
      type: string
      enum: [A, B, C, D, F]
      description: Letter grade derived from overall_score
    files_analyzed:
      type: integer
    total_lines:
      type: integer
      description: Total lines of code (excluding blanks and comments)
    issues:
      type: object
      properties:
        complexity:
          type: object
          properties:
            count:
              type: integer
              description: Functions/methods exceeding complexity threshold
            threshold:
              type: integer
              description: Cyclomatic complexity threshold (typically 10)
            max_found:
              type: integer
              description: Highest complexity value found
            avg_complexity:
              type: number
        duplication:
          type: object
          properties:
            count:
              type: integer
              description: Number of duplicate code blocks found
            duplicated_lines:
              type: integer
            duplication_pct:
              type: number
              description: Percentage of codebase that is duplicated
        maintainability:
          type: object
          properties:
            low_index_files:
              type: integer
              description: Files with maintainability index below threshold
            threshold:
              type: number
              description: Minimum acceptable maintainability index (typically 65)
            avg_index:
              type: number
              description: Average maintainability index across all files
        total_issues:
          type: integer
        debt_hours:
          type: number
          description: Estimated remediation time in hours
    hotspots:
      type: array
      description: Files most in need of refactoring
      items:
        type: object
        properties:
          file:
            type: string
          metric:
            type: string
            enum: [complexity, duplication, maintainability, length, all]
            description: Primary quality issue in this file
          value:
            type: number
            description: Measured value of the primary metric
          threshold:
            type: number
            description: Acceptable threshold for comparison
          lines:
            type: integer
            description: Lines of code in this file
          change_frequency:
            type: integer
            description: Number of commits touching this file in last 90 days
          risk_score:
            type: number
            description: Combined risk score (high complexity + high churn = dangerous)
          recommendation:
            type: string
        required: [file, metric, value, threshold, recommendation]
    trend:
      type: [string, "null"]
      description: Quality trend vs previous scan (e.g. "+2.1 pts vs 2026-02-13", "first scan")
    top_wins:
      type: array
      items:
        type: string
      description: Positive signals — well-maintained files or modules
  required: [tool, analyzed_at, overall_score, grade, files_analyzed, issues, hotspots]
validation_rules:
  - overall_score must be between 0 and 100
  - grade must align with score (A >= 90, B >= 80, C >= 70, D >= 60, F < 60)
  - issues.total_issues must equal sum of complexity.count + duplication.count + maintainability.low_index_files
  - hotspot risk_score should be highest for files with both high complexity and high change_frequency
  - duplication_pct must be between 0 and 100
  - complexity.max_found must be >= complexity.threshold when count > 0
related_artifacts: [test-coverage-report, code-review-feedback, diff-analysis]
---

{
  "tool": "sonarqube 10.4.1 + lizard 1.17.10",
  "analyzed_at": "2026-03-13T03:00:00Z",
  "codebase_root": "src/",
  "overall_score": 62.3,
  "grade": "D",
  "files_analyzed": 127,
  "total_lines": 18430,
  "issues": {
    "complexity": {
      "count": 14,
      "threshold": 10,
      "max_found": 47,
      "avg_complexity": 4.2
    },
    "duplication": {
      "count": 23,
      "duplicated_lines": 841,
      "duplication_pct": 4.6
    },
    "maintainability": {
      "low_index_files": 8,
      "threshold": 65,
      "avg_index": 71.4
    },
    "total_issues": 45,
    "debt_hours": 28.5
  },
  "hotspots": [
    {
      "file": "src/lib/chain-executor.ts",
      "metric": "complexity",
      "value": 47,
      "threshold": 10,
      "lines": 842,
      "change_frequency": 31,
      "risk_score": 94.1,
      "recommendation": "Cyclomatic complexity of 47 with 31 commits in 90 days = highest risk file in codebase. Break executeChain() into: validateChain(), resolveAgents(), runAgentPipeline(), handleErrors(). Each should have CC <= 8."
    },
    {
      "file": "src/api/routes/chains.ts",
      "metric": "all",
      "value": 38,
      "threshold": 10,
      "lines": 1241,
      "change_frequency": 28,
      "risk_score": 88.7,
      "recommendation": "1241-line route file with complexity 38 and heavy duplication. Split into: list.ts, create.ts, run.ts, import-export.ts. Extract shared middleware into chains-middleware.ts."
    },
    {
      "file": "src/db/repositories/run-repository.ts",
      "metric": "duplication",
      "value": 28.3,
      "threshold": 5,
      "lines": 398,
      "change_frequency": 12,
      "risk_score": 61.2,
      "recommendation": "28.3% of this file is duplicated across similar methods (findByOrg, findByWorkspace, findByChain). Extract a buildQuery(filters) helper and compose the three methods from it."
    },
    {
      "file": "src/auth/session.ts",
      "metric": "maintainability",
      "value": 41,
      "threshold": 65,
      "lines": 287,
      "change_frequency": 8,
      "risk_score": 52.4,
      "recommendation": "Maintainability index of 41 indicates poor readability. Main issues: deep nesting (avg 4.8 levels), no inline documentation, and 6 functions over 60 lines each. Break up the validate() function first (currently 94 lines with CC=19)."
    }
  ],
  "trend": "+1.4 pts vs 2026-02-13 scan (was 60.9 / grade D)",
  "top_wins": [
    "src/utils/validators.ts — CC avg 1.8, no duplication, MI 94",
    "src/lib/pagination.ts — 48 lines, CC 3, fully documented",
    "src/models/ — all 8 model files below CC 6 and MI above 82"
  ]
}

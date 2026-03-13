---
id: test-results
name: Test Results
format: json
category: cli
tags: [testing, jest, pytest, coverage, ci]
description: >
  Output from running a test suite. Captures pass/fail counts, coverage,
  individual failure details, and duration. Produced after agents that run
  unit, integration, or e2e tests.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    framework:
      type: string
      description: test runner used (jest, pytest, vitest, go test, rspec, etc.)
    total:
      type: integer
      minimum: 0
      description: total number of tests collected
    passed:
      type: integer
      minimum: 0
      description: tests that passed
    failed:
      type: integer
      minimum: 0
      description: tests that failed or errored
    skipped:
      type: integer
      minimum: 0
      description: tests that were skipped or pending
    coverage_percent:
      type: [number, "null"]
      minimum: 0
      maximum: 100
      description: overall line coverage percentage, null if coverage not collected
    failures:
      type: array
      description: individual test failure details (empty array if all passed)
      items:
        type: object
        properties:
          test_name:
            type: string
            description: full test name including suite path
          file:
            type: string
            description: source file path relative to repo root
          line:
            type: integer
            description: line number of the failing assertion
          message:
            type: string
            description: failure message or assertion error text
          duration_ms:
            type: integer
            description: how long this specific test took
        required: [test_name, file, line, message]
    duration_ms:
      type: integer
      minimum: 0
      description: total time for the full test run
    suite_name:
      type: string
      description: name of the test suite or file pattern that was run
  required: [framework, total, passed, failed, skipped, coverage_percent, failures, duration_ms]
validation_rules:
  - passed + failed + skipped must equal total
  - coverage_percent must be 0-100 or null
  - failures array must be empty when failed is 0
  - failures array length must equal failed count
  - duration_ms must be >= 0
  - framework must be non-empty string
related_artifacts:
  - code-changes
  - build-output
  - command-output
---

```json
{
  "framework": "jest",
  "suite_name": "tests/middleware/**/*.test.ts",
  "total": 47,
  "passed": 44,
  "failed": 2,
  "skipped": 1,
  "coverage_percent": 81.4,
  "duration_ms": 6243,
  "failures": [
    {
      "test_name": "authMiddleware > should reject expired tokens",
      "file": "tests/middleware/auth.test.ts",
      "line": 88,
      "message": "expect(received).toBe(expected)\n\nExpected: 401\nReceived: 500\n\nat Object.<anonymous> (tests/middleware/auth.test.ts:88:34)",
      "duration_ms": 12
    },
    {
      "test_name": "authMiddleware > should handle missing Authorization header",
      "file": "tests/middleware/auth.test.ts",
      "line": 112,
      "message": "TypeError: Cannot read properties of undefined (reading 'split')\n    at verifyJwt (lib/jwt.ts:9:45)\n    at authMiddleware (lib/middleware/auth.ts:6:18)\n    at Object.<anonymous> (tests/middleware/auth.test.ts:112:5)",
      "duration_ms": 3
    }
  ]
}
```

## all-passing example

```json
{
  "framework": "pytest",
  "suite_name": "tests/",
  "total": 132,
  "passed": 132,
  "failed": 0,
  "skipped": 4,
  "coverage_percent": 94.7,
  "duration_ms": 11820,
  "failures": []
}
```

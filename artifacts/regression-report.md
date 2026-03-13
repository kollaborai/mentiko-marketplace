---
id: regression-report
name: Regression Test Report
format: json
category: analysis
tags: [regression, testing, ci, quality, diff, versions]
description: Regression test results comparing two versions. Identifies tests that newly fail, tests that were fixed, and unchanged results. Used in CI/CD pipelines for merge gates.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    base_version:
      type: string
      description: Git ref, tag, or version of the baseline (e.g. "main@abc1234", "v2.3.1")
    new_version:
      type: string
      description: Git ref, tag, or version being compared (e.g. "feature/auth-refactor@def5678")
    test_runner:
      type: string
      description: Test framework used (e.g. "jest 29.7", "pytest 8.1", "playwright 1.42")
    ran_at:
      type: string
      format: date-time
    tests_run:
      type: integer
      description: Total number of tests executed in new_version run
    regressions:
      type: array
      description: Tests that passed in base but fail in new
      items:
        type: object
        properties:
          test_name:
            type: string
            description: Full test title/path
          file:
            type: string
            description: Test file relative path
          suite:
            type: string
            description: Describe block or test suite name
          base_status:
            type: string
            enum: [passed, skipped]
          new_status:
            type: string
            enum: [failed, errored, timed_out]
          error_message:
            type: string
            description: Failure message or error thrown
          stack_trace:
            type: string
            description: Abbreviated stack trace (first 5 lines)
          likely_cause:
            type: string
            description: Agent-inferred likely cause of the regression
        required: [test_name, file, base_status, new_status, error_message]
    fixed:
      type: array
      description: Tests that failed in base but pass in new
      items:
        type: object
        properties:
          test_name:
            type: string
          file:
            type: string
          base_status:
            type: string
            enum: [failed, errored, skipped]
          new_status:
            type: string
            enum: [passed]
        required: [test_name, file, base_status, new_status]
    new_failures:
      type: integer
      description: Count of regressions (tests that newly fail)
    fixed_failures:
      type: integer
      description: Count of tests newly passing
    skipped:
      type: integer
      description: Tests skipped in new run
    unchanged_pass:
      type: integer
      description: Tests passing in both versions
    unchanged_fail:
      type: integer
      description: Tests failing in both versions (pre-existing failures)
    ci_gate_passed:
      type: boolean
      description: Whether the regression gate is satisfied (new_failures == 0)
    notes:
      type: string
  required: [base_version, new_version, ran_at, tests_run, regressions, fixed, new_failures, fixed_failures, unchanged_pass, ci_gate_passed]
validation_rules:
  - new_failures must equal regressions array length
  - fixed_failures must equal fixed array length
  - ci_gate_passed must be true iff new_failures == 0
  - tests_run must equal new_failures + fixed_failures + unchanged_pass + unchanged_fail + skipped
  - each test_name must be unique within the regressions array
  - base_status in regressions must be "passed" or "skipped" (it was working, now broken)
  - new_status in fixed must be "passed" (it was failing, now works)
related_artifacts: [test-coverage-report, code-review-feedback, benchmark-results]
---

{
  "base_version": "main@a8f3c91",
  "new_version": "feature/auth-refactor@2d1e447",
  "test_runner": "jest 29.7.0",
  "ran_at": "2026-03-13T11:02:00Z",
  "tests_run": 412,
  "new_failures": 3,
  "fixed_failures": 1,
  "skipped": 7,
  "unchanged_pass": 398,
  "unchanged_fail": 3,
  "ci_gate_passed": false,
  "regressions": [
    {
      "test_name": "POST /api/auth/login > returns 200 with valid credentials",
      "file": "tests/api/auth.test.ts",
      "suite": "POST /api/auth/login",
      "base_status": "passed",
      "new_status": "failed",
      "error_message": "Expected status 200, received 500. Response: {\"error\":\"JWT_SECRET is required\"}",
      "stack_trace": "at Object.<anonymous> (tests/api/auth.test.ts:34:5)\nat runTest (/node_modules/jest-circus/build/run.js:121:9)",
      "likely_cause": "src/auth/token.ts now throws if JWT_SECRET is unset. The test environment does not define JWT_SECRET. Add JWT_SECRET=test-secret to jest.config.js testEnvironment."
    },
    {
      "test_name": "POST /api/auth/login > returns 200 with remember-me flag",
      "file": "tests/api/auth.test.ts",
      "suite": "POST /api/auth/login",
      "base_status": "passed",
      "new_status": "failed",
      "error_message": "Expected status 200, received 500. Response: {\"error\":\"JWT_SECRET is required\"}",
      "stack_trace": "at Object.<anonymous> (tests/api/auth.test.ts:52:5)\nat runTest (/node_modules/jest-circus/build/run.js:121:9)",
      "likely_cause": "Same root cause as previous regression — missing JWT_SECRET in test environment."
    },
    {
      "test_name": "User.findById > returns null for unknown ID",
      "file": "tests/models/user.test.ts",
      "suite": "User.findById",
      "base_status": "passed",
      "new_status": "errored",
      "error_message": "TypeError: Cannot read properties of undefined (reading 'findById'). User model default export was changed from class to named export in the refactor.",
      "stack_trace": "at Object.<anonymous> (tests/models/user.test.ts:18:3)\nat runTest (/node_modules/jest-circus/build/run.js:121:9)",
      "likely_cause": "src/models/user.ts export changed from default to named export. Test file still imports as default: import User from '../models/user'. Fix: import { User } from '../models/user'."
    }
  ],
  "fixed": [
    {
      "test_name": "GET /api/users/:id > returns 403 for cross-user access",
      "file": "tests/api/users.test.ts",
      "base_status": "failed",
      "new_status": "passed"
    }
  ],
  "notes": "All 3 regressions are caused by the auth refactor in src/auth/token.ts and src/models/user.ts. Two tests fail due to a missing JWT_SECRET in the jest test environment — easy fix. One test fails due to an export change. The previously failing authorization test is now fixed as a side effect of the refactor."
}

---
id: diff-analysis
name: Diff Impact Analysis
format: json
category: analysis
tags: [diff, code-change, impact, breaking-changes, api, risk]
description: Impact analysis of a code diff — what changed, which APIs are affected, breaking change detection, and risk assessment. Goes beyond line counts to semantic understanding.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    diff_ref:
      type: string
      description: Git ref, PR number, or commit range being analyzed (e.g. "PR-412", "main...feature/auth")
    base_ref:
      type: string
      description: Base branch or commit
    head_ref:
      type: string
      description: Head branch or commit
    analyzed_at:
      type: string
      format: date-time
    diff_summary:
      type: string
      description: High-level description of what changed and why
    files_changed:
      type: integer
    lines_added:
      type: integer
    lines_removed:
      type: integer
    breaking_changes:
      type: array
      description: Changes that break backward compatibility
      items:
        type: object
        properties:
          description:
            type: string
            description: What broke and how
          affected_file:
            type: string
          change_type:
            type: string
            enum: [export-removed, signature-changed, type-incompatible, behavior-changed, config-required, database-migration-required]
          risk_level:
            type: string
            enum: [critical, high, medium, low]
          migration_path:
            type: string
            description: How consumers should adapt
        required: [description, affected_file, change_type, risk_level]
    api_changes:
      type: array
      description: HTTP API endpoint changes
      items:
        type: object
        properties:
          endpoint:
            type: string
            description: HTTP method + path (e.g. "POST /api/auth/login")
          change_type:
            type: string
            enum: [added, removed, modified, deprecated]
          impact:
            type: string
            description: What this means for callers
          breaking:
            type: boolean
        required: [endpoint, change_type, impact, breaking]
    test_impact:
      type: array
      description: Test files likely affected by these changes
      items:
        type: object
        properties:
          test_file:
            type: string
          likely_affected:
            type: boolean
          reason:
            type: string
        required: [test_file, likely_affected]
    affected_systems:
      type: array
      items:
        type: string
      description: System areas affected (e.g. "authentication", "billing", "notifications")
    risk_level:
      type: string
      enum: [critical, high, medium, low]
      description: Overall change risk level
    risk_rationale:
      type: string
      description: Explanation for the assigned risk level
    deployment_notes:
      type: array
      items:
        type: string
      description: Steps required for safe deployment (migrations, env vars, cache invalidations)
  required: [diff_ref, analyzed_at, diff_summary, files_changed, breaking_changes, api_changes, test_impact, risk_level]
validation_rules:
  - risk_level must be the maximum risk of any individual breaking_change.risk_level when breaking_changes is non-empty
  - each endpoint in api_changes must include HTTP method prefix (GET, POST, PUT, PATCH, DELETE)
  - change_type must be one of the defined enum values
  - lines_added and lines_removed must be non-negative integers
  - breaking_changes with risk_level=critical require a migration_path
  - test_impact entries with likely_affected=true should have a non-empty reason
related_artifacts: [code-review-feedback, security-scan-report, regression-report]
---

{
  "diff_ref": "PR-412",
  "base_ref": "main@a8f3c91",
  "head_ref": "feature/auth-refactor@2d1e447",
  "analyzed_at": "2026-03-13T11:00:00Z",
  "files_changed": 14,
  "lines_added": 312,
  "lines_removed": 187,
  "diff_summary": "Authentication layer refactored to enforce JWT_SECRET at startup and remove the empty-string fallback. User model export changed from default to named export. Authorization middleware extracted from inline route handlers into a shared assertOwnership() guard. New strict mode breaks two auth test cases due to missing env setup.",
  "breaking_changes": [
    {
      "description": "src/models/user.ts changed from default export to named export. All importers using `import User from '../models/user'` will receive undefined at runtime.",
      "affected_file": "src/models/user.ts",
      "change_type": "export-removed",
      "risk_level": "high",
      "migration_path": "Update all import sites from `import User from` to `import { User } from`. Run: grep -r \"from.*models/user\" src/ tests/ to find all affected files."
    },
    {
      "description": "src/auth/token.ts now throws Error('JWT_SECRET is required') at module load time if the env var is unset. Previously, an empty string was silently used. Any environment (test, CI, staging) without JWT_SECRET will now fail to start.",
      "affected_file": "src/auth/token.ts",
      "change_type": "behavior-changed",
      "risk_level": "critical",
      "migration_path": "Add JWT_SECRET to all environments: .env.test, .env.staging, CI secrets, jest.config.js testEnvironment. Minimum: JWT_SECRET=test-secret-for-tests in jest env."
    }
  ],
  "api_changes": [
    {
      "endpoint": "POST /api/auth/login",
      "change_type": "modified",
      "impact": "Now returns HTTP 500 in environments missing JWT_SECRET rather than issuing an unsigned token. Behavior is correct but callers in non-production environments may need JWT_SECRET added to see any response.",
      "breaking": false
    },
    {
      "endpoint": "PUT /api/users/:id",
      "change_type": "modified",
      "impact": "Role field is now stripped from request body unless caller is admin. Clients passing role in update payloads will silently have it ignored rather than erroring. Newly enforced authorization check returns 403 for cross-user access.",
      "breaking": false
    },
    {
      "endpoint": "GET /api/users/:id/permissions",
      "change_type": "added",
      "impact": "New endpoint returning the caller's resolved permissions object. No breaking impact for existing consumers.",
      "breaking": false
    }
  ],
  "test_impact": [
    { "test_file": "tests/api/auth.test.ts", "likely_affected": true, "reason": "Imports token module which now throws without JWT_SECRET. All auth tests will 500." },
    { "test_file": "tests/models/user.test.ts", "likely_affected": true, "reason": "Uses default import of User model. Will receive undefined after named export change." },
    { "test_file": "tests/api/users.test.ts", "likely_affected": true, "reason": "User update endpoint now strips role field and enforces ownership. Existing test that sets role should still pass; cross-user tests will now correctly receive 403." },
    { "test_file": "tests/middleware/auth.test.ts", "likely_affected": false, "reason": "Tests middleware signature only, not affected by JWT startup change." }
  ],
  "affected_systems": ["authentication", "user-management", "authorization"],
  "risk_level": "critical",
  "risk_rationale": "JWT_SECRET enforcement is a startup-time breaking change that will cause the application to crash on launch in any environment missing the secret. This includes test runners, CI pipelines, staging envs, and local dev setups without the secret defined. Must be resolved before merge.",
  "deployment_notes": [
    "Add JWT_SECRET to all deployment environments before deploying. Check: staging .env, production .env, CI secrets (GitHub Actions), and jest testEnvironment.",
    "Run full test suite after adding JWT_SECRET to confirm the 2 regression tests are fixed.",
    "No database migrations required.",
    "No cache invalidation required."
  ]
}

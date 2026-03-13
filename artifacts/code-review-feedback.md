---
id: code-review-feedback
name: Code Review Feedback
format: json
category: analysis
tags: [code-review, pull-request, quality, feedback]
description: Structured code review output with file-level issues, before/after suggestions, severity ratings, and an approval decision. Machine-readable PR feedback.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    pr_id:
      type: [string, "null"]
      description: PR or MR identifier, null for ad-hoc reviews
    pr_url:
      type: [string, "null"]
      description: Link to the pull request
    reviewer_focus:
      type: string
      description: Review scope or emphasis (e.g. "security + correctness", "performance")
    reviewed_at:
      type: string
      format: date-time
    issues:
      type: array
      items:
        type: object
        properties:
          id:
            type: string
            description: Issue identifier (e.g. "CR-001")
          file:
            type: string
            description: Relative file path
          line:
            type: integer
            description: Starting line number
          line_end:
            type: integer
            description: Ending line number for multi-line issues
          severity:
            type: string
            enum: [blocking, major, minor, nit]
          category:
            type: string
            enum: [correctness, security, performance, maintainability, style, test-coverage]
          message:
            type: string
            description: Description of the issue
          suggestion:
            type: string
            description: Recommended fix or improvement
          code_before:
            type: string
            description: Current problematic code
          code_after:
            type: string
            description: Suggested replacement code
        required: [id, file, line, severity, category, message, suggestion]
    summary:
      type: string
      description: Overall review summary (2-4 sentences)
    approved:
      type: boolean
      description: Whether the PR is approved to merge
    blocking_issues:
      type: integer
      description: Count of severity=blocking issues
    major_issues:
      type: integer
    minor_issues:
      type: integer
    files_reviewed:
      type: integer
    lines_changed:
      type: integer
  required: [pr_id, reviewer_focus, reviewed_at, issues, summary, approved, blocking_issues]
validation_rules:
  - blocking_issues must equal count of issues where severity == "blocking"
  - approved must be false when blocking_issues > 0
  - each issue.id must be unique within the report
  - severity must be one of blocking, major, minor, nit
  - category must be one of correctness, security, performance, maintainability, style, test-coverage
  - code_before and code_after should both be present or both absent
  - summary must be at least 20 characters
related_artifacts: [git-diff, test-coverage-report, code-quality-report]
---

{
  "pr_id": "PR-412",
  "pr_url": "https://github.com/acme/api/pull/412",
  "reviewer_focus": "correctness + security",
  "reviewed_at": "2026-03-13T10:31:00Z",
  "files_reviewed": 6,
  "lines_changed": 184,
  "issues": [
    {
      "id": "CR-001",
      "file": "src/auth/token.ts",
      "line": 47,
      "line_end": 47,
      "severity": "blocking",
      "category": "security",
      "message": "JWT secret is sourced from process.env without a defined fallback, but the fallback is an empty string which would silently allow tokens signed with no secret in local envs.",
      "suggestion": "Throw at startup if JWT_SECRET is not set. Never use an empty fallback for signing secrets.",
      "code_before": "const secret = process.env.JWT_SECRET || '';",
      "code_after": "const secret = process.env.JWT_SECRET;\nif (!secret) throw new Error('JWT_SECRET is required');"
    },
    {
      "id": "CR-002",
      "file": "src/api/users/update.ts",
      "line": 23,
      "line_end": 29,
      "severity": "blocking",
      "category": "correctness",
      "message": "The role field is updated directly from req.body without authorization check. Any authenticated user can promote themselves to admin by passing role: 'admin'.",
      "suggestion": "Strip role from the update payload unless the caller is an admin. Apply a field allowlist based on the caller's role.",
      "code_before": "await User.update(req.params.id, req.body);",
      "code_after": "const allowedFields = isAdmin(req.user) ? ADMIN_FIELDS : USER_FIELDS;\nconst sanitized = pick(req.body, allowedFields);\nawait User.update(req.params.id, sanitized);"
    },
    {
      "id": "CR-003",
      "file": "src/api/users/update.ts",
      "line": 15,
      "severity": "major",
      "category": "correctness",
      "message": "No validation that req.params.id belongs to the authenticated user or that the caller has edit rights. Horizontal privilege escalation is possible.",
      "suggestion": "Assert req.params.id === req.user.id || isAdmin(req.user) before proceeding.",
      "code_before": "const user = await User.findById(req.params.id);",
      "code_after": "if (req.params.id !== req.user.id && !isAdmin(req.user)) {\n  return res.status(403).json({ error: 'Forbidden' });\n}\nconst user = await User.findById(req.params.id);"
    },
    {
      "id": "CR-004",
      "file": "src/api/users/list.ts",
      "line": 8,
      "severity": "minor",
      "category": "performance",
      "message": "User list is fetched without pagination. For large datasets this will OOM the process and timeout the client.",
      "suggestion": "Add limit/offset or cursor-based pagination. Default to limit=50.",
      "code_before": "const users = await User.findAll();",
      "code_after": "const limit = Math.min(Number(req.query.limit) || 50, 200);\nconst offset = Number(req.query.offset) || 0;\nconst users = await User.findAll({ limit, offset });"
    },
    {
      "id": "CR-005",
      "file": "src/utils/hash.ts",
      "line": 3,
      "severity": "nit",
      "category": "style",
      "message": "Unused import `crypto` from Node built-ins. The bcrypt package handles hashing directly.",
      "suggestion": "Remove the unused import.",
      "code_before": "import crypto from 'crypto';\nimport bcrypt from 'bcrypt';",
      "code_after": "import bcrypt from 'bcrypt';"
    }
  ],
  "summary": "Two blocking issues prevent merge: an auth token signing fallback that silently accepts empty secrets in local environments, and an unguarded mass-assignment endpoint that allows role escalation. The horizontal privilege escalation in user update is a critical fix as well. Pagination and the unused import are cleanup items for this PR or a followup.",
  "approved": false,
  "blocking_issues": 2,
  "major_issues": 1,
  "minor_issues": 1
}

---
id: git-diff
name: Git Diff
format: json
category: cli
tags: [git, diff, patch, code-review, pr]
description: >
  Git diff output with per-file metadata. Captures ref info, per-file
  additions/deletions, and the raw unified patch for each file. Produced
  by agents that summarize or review changes between two git refs.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    base_ref:
      type: string
      description: base git ref (branch name, commit SHA, or tag)
    head_ref:
      type: string
      description: head git ref being compared against base
    files:
      type: array
      description: per-file diff records
      items:
        type: object
        properties:
          path:
            type: string
            description: current file path relative to repo root
          old_path:
            type: string
            description: original path if file was renamed (omit otherwise)
          status:
            type: string
            enum: [added, modified, deleted, renamed, copied]
            description: change type
          additions:
            type: integer
            minimum: 0
            description: lines added in this file
          deletions:
            type: integer
            minimum: 0
            description: lines removed in this file
          binary:
            type: boolean
            description: true if this is a binary file (patch will be empty)
          patch:
            type: string
            description: unified diff patch for this file (empty string for binary files)
        required: [path, status, additions, deletions, binary, patch]
    total_additions:
      type: integer
      minimum: 0
      description: sum of additions across all files
    total_deletions:
      type: integer
      minimum: 0
      description: sum of deletions across all files
    commit_count:
      type: integer
      minimum: 0
      description: number of commits between base_ref and head_ref
  required: [base_ref, head_ref, files, total_additions, total_deletions]
validation_rules:
  - total_additions must equal sum of all files[*].additions
  - total_deletions must equal sum of all files[*].deletions
  - if binary is true, patch must be empty string
  - if status is renamed, old_path must be present
  - status must be one of added, modified, deleted, renamed, copied
  - base_ref and head_ref must be non-empty strings
related_artifacts:
  - code-changes
  - build-output
  - test-results
---

```json
{
  "base_ref": "main",
  "head_ref": "fix/auth-middleware-refactor",
  "commit_count": 3,
  "total_additions": 93,
  "total_deletions": 58,
  "files": [
    {
      "path": "lib/middleware/auth.ts",
      "status": "modified",
      "additions": 14,
      "deletions": 49,
      "binary": false,
      "patch": "@@ -1,52 +1,17 @@\n-import jwt from 'jsonwebtoken';\n-\n-export function authMiddleware(req, res, next) {\n-  const token = req.headers.authorization?.split(' ')[1];\n-  if (!token) return res.status(401).json({ error: 'No token' });\n-  try {\n-    const decoded = jwt.verify(token, process.env.JWT_SECRET);\n-    req.user = decoded;\n-    next();\n-  } catch (err) {\n-    return res.status(401).json({ error: 'Invalid token' });\n-  }\n-}\n+import { verifyJwt } from '../jwt';\n+\n+export function authMiddleware(req, res, next) {\n+  const result = verifyJwt(req.headers.authorization);\n+  if (!result.ok) return res.status(401).json({ error: result.error });\n+  req.user = result.payload;\n+  next();\n+}"
    },
    {
      "path": "lib/jwt.ts",
      "status": "added",
      "additions": 42,
      "deletions": 0,
      "binary": false,
      "patch": "@@ -0,0 +1,42 @@\n+import jwt from 'jsonwebtoken';\n+\n+export interface JwtResult {\n+  ok: boolean;\n+  payload?: Record<string, unknown>;\n+  error?: string;\n+}\n+\n+export function verifyJwt(authHeader: string | undefined): JwtResult {\n+  if (!authHeader?.startsWith('Bearer ')) {\n+    return { ok: false, error: 'Missing or malformed Authorization header' };\n+  }\n+  const token = authHeader.slice(7);\n+  try {\n+    const payload = jwt.verify(token, process.env.JWT_SECRET!) as Record<string, unknown>;\n+    return { ok: true, payload };\n+  } catch (err) {\n+    return { ok: false, error: (err as Error).message };\n+  }\n+}"
    },
    {
      "path": "tests/middleware/auth.test.ts",
      "status": "modified",
      "additions": 31,
      "deletions": 9,
      "binary": false,
      "patch": "@@ -45,15 +45,37 @@\n describe('authMiddleware', () => {\n-  it('should reject missing token', () => {\n-    const req = { headers: {} };\n-    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };\n+  it('should reject missing Authorization header', () => {\n+    const req = mockReq(undefined);\n+    const res = mockRes();\n     authMiddleware(req, res, jest.fn());\n-    expect(res.status).toHaveBeenCalledWith(401);\n+    expect(res.status).toHaveBeenCalledWith(401);\n+    expect(res.json).toHaveBeenCalledWith({ error: 'Missing or malformed Authorization header' });\n   });\n+\n+  it('should reject expired tokens', () => {\n+    const expiredToken = generateExpiredJwt();\n+    const req = mockReq(`Bearer ${expiredToken}`);\n+    const res = mockRes();\n+    authMiddleware(req, res, jest.fn());\n+    expect(res.status).toHaveBeenCalledWith(401);\n+    expect(res.json).toHaveBeenCalledWith({ error: 'jwt expired' });\n+  });\n });"
    },
    {
      "path": "docs/logos/logo-v2.png",
      "status": "added",
      "additions": 0,
      "deletions": 0,
      "binary": true,
      "patch": ""
    }
  ]
}
```

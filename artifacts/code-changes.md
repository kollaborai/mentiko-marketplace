---
id: code-changes
name: Code Changes
format: json
category: cli
tags: [git, diff, files, code, agent-output]
description: >
  Files changed by a coding agent during a task. Includes per-file action,
  line counts, and a unified diff preview. Produced after any agent that
  modifies files on disk.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    summary:
      type: string
      description: one-sentence description of what changed and why
    total_files:
      type: integer
      minimum: 0
      description: total number of files touched
    files_changed:
      type: array
      description: per-file change records
      items:
        type: object
        properties:
          path:
            type: string
            description: file path relative to repo root (no leading slash)
          action:
            type: string
            enum: [added, modified, deleted, renamed]
            description: type of change applied to this file
          lines_added:
            type: integer
            minimum: 0
            description: lines inserted
          lines_removed:
            type: integer
            minimum: 0
            description: lines deleted
          old_path:
            type: string
            description: original path for renamed files (omit otherwise)
        required: [path, action, lines_added, lines_removed]
    diff_preview:
      type: string
      description: unified diff of the first 100 changed lines (truncated with ... if longer)
  required: [summary, total_files, files_changed, diff_preview]
validation_rules:
  - total_files must equal the length of files_changed array
  - lines_added and lines_removed must be >= 0
  - action must be one of added, modified, deleted, renamed
  - path must be relative — no leading slash
  - old_path is required when action is renamed, omitted otherwise
  - diff_preview must start with "diff --git" if files_changed is non-empty
related_artifacts:
  - test-results
  - build-output
  - git-diff
---

```json
{
  "summary": "Refactored auth middleware to use shared JWT helper, removing 40 lines of duplicated decode logic across 3 files",
  "total_files": 4,
  "files_changed": [
    {
      "path": "lib/middleware/auth.ts",
      "action": "modified",
      "lines_added": 14,
      "lines_removed": 49
    },
    {
      "path": "lib/jwt.ts",
      "action": "added",
      "lines_added": 42,
      "lines_removed": 0
    },
    {
      "path": "lib/middleware/admin.ts",
      "action": "modified",
      "lines_added": 6,
      "lines_removed": 28
    },
    {
      "path": "tests/middleware/auth.test.ts",
      "action": "modified",
      "lines_added": 31,
      "lines_removed": 9
    }
  ],
  "diff_preview": "diff --git a/lib/middleware/auth.ts b/lib/middleware/auth.ts\nindex 8f3a2c1..4d7e9b2 100644\n--- a/lib/middleware/auth.ts\n+++ b/lib/middleware/auth.ts\n@@ -1,52 +1,17 @@\n-import jwt from 'jsonwebtoken';\n-\n-export function authMiddleware(req, res, next) {\n-  const token = req.headers.authorization?.split(' ')[1];\n-  if (!token) return res.status(401).json({ error: 'No token' });\n-  try {\n-    const decoded = jwt.verify(token, process.env.JWT_SECRET);\n-    req.user = decoded;\n-    next();\n-  } catch (err) {\n-    return res.status(401).json({ error: 'Invalid token' });\n-  }\n-}\n+import { verifyJwt } from '../jwt';\n+\n+export function authMiddleware(req, res, next) {\n+  const result = verifyJwt(req.headers.authorization);\n+  if (!result.ok) return res.status(401).json({ error: result.error });\n+  req.user = result.payload;\n+  next();\n+}\ndiff --git a/lib/jwt.ts b/lib/jwt.ts\nnew file mode 100644\nindex 0000000..9c14a88\n--- /dev/null\n+++ b/lib/jwt.ts\n@@ -0,0 +1,42 @@\n+import jwt from 'jsonwebtoken';\n+\n+export interface JwtResult {\n+  ok: boolean;\n+  payload?: Record<string, unknown>;\n+  error?: string;\n+}\n+\n+export function verifyJwt(authHeader: string | undefined): JwtResult {\n+  if (!authHeader?.startsWith('Bearer ')) {\n+    return { ok: false, error: 'Missing or malformed Authorization header' };\n+  }\n+  const token = authHeader.slice(7);\n+  try {\n+    const payload = jwt.verify(token, process.env.JWT_SECRET!) as Record<string, unknown>;\n+    return { ok: true, payload };\n+  } catch (err) {\n+    return { ok: false, error: (err as Error).message };\n+  }\n+}"
}
```

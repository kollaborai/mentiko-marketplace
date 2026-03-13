---
id: file-inventory
name: File Inventory
format: json
category: cli
tags: [files, filesystem, inventory, analysis, codebase]
description: >
  A directory listing with per-file metadata including size, extension,
  and modification time. Produced by agents that scan codebases, audit
  project structure, or enumerate workspace contents.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    root:
      type: string
      description: absolute path of the root directory scanned
    total_files:
      type: integer
      minimum: 0
      description: total number of files found (excluding directories)
    total_size_bytes:
      type: integer
      minimum: 0
      description: sum of all file sizes in bytes
    scanned_at:
      type: string
      description: ISO 8601 timestamp of when the scan was performed
    files:
      type: array
      description: per-file records
      items:
        type: object
        properties:
          path:
            type: string
            description: file path relative to root
          size_bytes:
            type: integer
            minimum: 0
            description: file size in bytes
          extension:
            type: string
            description: file extension including dot (e.g. .ts, .json) or empty string for no extension
          last_modified:
            type: string
            description: ISO 8601 timestamp of last modification
          is_binary:
            type: boolean
            description: true if the file is detected as binary
        required: [path, size_bytes, extension, last_modified, is_binary]
    by_extension:
      type: object
      description: rollup counts and total bytes per extension
      additionalProperties:
        type: object
        properties:
          count:
            type: integer
          total_bytes:
            type: integer
        required: [count, total_bytes]
    excluded_patterns:
      type: array
      description: glob patterns that were excluded from the scan
      items:
        type: string
  required: [root, total_files, total_size_bytes, files, by_extension]
validation_rules:
  - total_files must equal length of files array
  - total_size_bytes must equal sum of all files[*].size_bytes
  - sum of by_extension[*].count must equal total_files
  - sum of by_extension[*].total_bytes must equal total_size_bytes
  - all paths must be relative (no leading slash)
  - extension must start with dot or be empty string
related_artifacts:
  - code-changes
  - git-diff
  - command-output
---

```json
{
  "root": "/Users/malmazan/dev/agent-chain/web/lib",
  "scanned_at": "2026-03-13T15:02:44.331Z",
  "total_files": 28,
  "total_size_bytes": 184320,
  "excluded_patterns": ["node_modules/**", "**/*.d.ts", ".next/**"],
  "by_extension": {
    ".ts": {
      "count": 22,
      "total_bytes": 168902
    },
    ".tsx": {
      "count": 3,
      "total_bytes": 12841
    },
    ".json": {
      "count": 2,
      "total_bytes": 1944
    },
    ".sh": {
      "count": 1,
      "total_bytes": 633
    }
  },
  "files": [
    {
      "path": "agent-loader.ts",
      "size_bytes": 6148,
      "extension": ".ts",
      "last_modified": "2026-03-12T11:43:07Z",
      "is_binary": false
    },
    {
      "path": "bd-client.ts",
      "size_bytes": 4312,
      "extension": ".ts",
      "last_modified": "2026-03-10T09:22:51Z",
      "is_binary": false
    },
    {
      "path": "bd-shell.ts",
      "size_bytes": 2891,
      "extension": ".ts",
      "last_modified": "2026-03-10T09:18:33Z",
      "is_binary": false
    },
    {
      "path": "cli-pipe.ts",
      "size_bytes": 8744,
      "extension": ".ts",
      "last_modified": "2026-03-08T16:55:12Z",
      "is_binary": false
    },
    {
      "path": "config.ts",
      "size_bytes": 11203,
      "extension": ".ts",
      "last_modified": "2026-03-12T14:11:09Z",
      "is_binary": false
    },
    {
      "path": "sanitize-output.ts",
      "size_bytes": 3107,
      "extension": ".ts",
      "last_modified": "2026-03-07T21:34:48Z",
      "is_binary": false
    },
    {
      "path": "types.ts",
      "size_bytes": 9823,
      "extension": ".ts",
      "last_modified": "2026-03-11T10:04:22Z",
      "is_binary": false
    },
    {
      "path": "user-context.tsx",
      "size_bytes": 4219,
      "extension": ".tsx",
      "last_modified": "2026-03-09T18:22:01Z",
      "is_binary": false
    },
    {
      "path": "infra/provider-registry.ts",
      "size_bytes": 2341,
      "extension": ".ts",
      "last_modified": "2026-03-01T13:44:22Z",
      "is_binary": false
    },
    {
      "path": "infra/provider-types.ts",
      "size_bytes": 1887,
      "extension": ".ts",
      "last_modified": "2026-03-01T13:38:55Z",
      "is_binary": false
    },
    {
      "path": "infra/provisioner.ts",
      "size_bytes": 7432,
      "extension": ".ts",
      "last_modified": "2026-03-02T09:17:44Z",
      "is_binary": false
    },
    {
      "path": "infra/stripe-client.ts",
      "size_bytes": 5614,
      "extension": ".ts",
      "last_modified": "2026-03-04T11:02:37Z",
      "is_binary": false
    }
  ]
}
```

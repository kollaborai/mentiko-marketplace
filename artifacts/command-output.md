---
id: command-output
name: Command Output
format: json
category: cli
tags: [shell, command, stdout, stderr, exit-code]
description: >
  Result of running a shell command. Captures stdout, stderr, exit code,
  duration, and whether the command succeeded. Produced by agents that
  execute shell commands as part of a task.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    command:
      type: string
      description: the exact command string that was executed (with arguments)
    exit_code:
      type: integer
      minimum: 0
      maximum: 255
      description: process exit code — 0 means success
    stdout:
      type: string
      description: standard output captured from the process
    stderr:
      type: string
      description: standard error captured from the process (may be empty on success)
    duration_ms:
      type: integer
      minimum: 0
      description: wall-clock time in milliseconds from start to exit
    success:
      type: boolean
      description: true if exit_code is 0, false otherwise
    working_dir:
      type: string
      description: absolute path where the command was run
    truncated:
      type: boolean
      description: true if stdout or stderr was cut off due to size limits
  required: [command, exit_code, stdout, stderr, duration_ms, success]
validation_rules:
  - exit_code must be 0-255
  - if success is true, exit_code must be 0
  - if success is false, exit_code must be 1-255
  - duration_ms must be >= 0
  - stderr is allowed to be non-empty even when success is true (warnings)
  - command must be non-empty string
related_artifacts:
  - build-output
  - test-results
  - log-output
---

```json
{
  "command": "npm run build -- --no-cache",
  "exit_code": 0,
  "stdout": "\n> mentiko-web@0.4.1 build\n> next build\n\n   ▲ Next.js 15.2.0\n\n   Creating an optimized production build ...\n ✓ Compiled successfully\n ✓ Linting and checking validity of types\n ✓ Collecting page data\n ✓ Generating static pages (34/34)\n ✓ Collecting build traces\n ✓ Finalizing page optimization\n\nRoute (app)                              Size     First Load JS\n┌ ○ /                                   5.23 kB         112 kB\n├ ○ /chains                             14.1 kB         148 kB\n├ ○ /agents                             11.8 kB         145 kB\n├ ○ /runs/[id]                          18.2 kB         152 kB\n├ ○ /settings/account                   8.9 kB          132 kB\n└ ○ /marketplace                        9.4 kB          136 kB\n+ First Load JS shared by all           87.2 kB\n\n○  (Static)   prerendered as static content\n",
  "stderr": "",
  "duration_ms": 38420,
  "success": true,
  "working_dir": "/Users/malmazan/dev/agent-chain/web",
  "truncated": false
}
```

## failure example

```json
{
  "command": "npx tsc --noEmit",
  "exit_code": 1,
  "stdout": "",
  "stderr": "web/app/api/chains/route.ts(42,18): error TS2345: Argument of type 'string | undefined' is not assignable to parameter of type 'string'.\nweb/lib/config.ts(87,12): error TS2304: Cannot find name 'orgPath'.\n\nFound 2 errors in 2 files.\n",
  "duration_ms": 4812,
  "success": false,
  "working_dir": "/Users/malmazan/dev/agent-chain/web",
  "truncated": false
}
```

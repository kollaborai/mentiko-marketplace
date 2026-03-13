---
id: technical-analysis
name: Technical Analysis Report
format: markdown
category: analysis
tags: [analysis, architecture, code-review]
description: >
  Structured technical assessment with findings categorized by severity and dimension
  (architecture, performance, security, maintainability, scalability). Produced by a
  code review agent after analyzing a codebase, PR, or system component.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    subject:
      type: string
      description: The system, file, or PR being analyzed
    scope:
      type: array
      items:
        type: string
      description: Files or components included in the analysis
    findings:
      type: array
      items:
        type: object
        properties:
          category:
            type: string
            enum: [architecture, performance, security, maintainability, scalability]
          severity:
            type: string
            enum: [critical, high, medium, low, info]
          title:
            type: string
          detail:
            type: string
            description: Specific description of the finding with code references
          recommendation:
            type: string
            description: Actionable fix recommendation
    risk_summary:
      type: object
      properties:
        critical:
          type: number
        high:
          type: number
        medium:
          type: number
        low:
          type: number
      description: Count of findings by severity level
    recommendation_priority:
      type: array
      items:
        type: string
      description: Ordered list of highest-priority actions
  required: [subject, findings, risk_summary]
validation_rules:
  - category must be one of architecture, performance, security, maintainability, scalability
  - severity must be one of critical, high, medium, low, info
  - every critical or high finding must include a non-empty recommendation
  - risk_summary counts must match actual findings count by severity
related_artifacts:
  - code-quality-report
  - security-audit
  - diff-analysis
---

# Technical Analysis: chain-runner.sh Refactoring

## Executive Summary

Analysis of the proposed refactoring of `lib/chain-runner.sh` from a 847-line monolithic
bash script into a modular library structure. The current implementation works but
has become a maintenance liability: functions are 80-150 lines each, global state is
mutated across 12 functions, and there is no mechanism for testing individual components
without executing a full chain run. The proposed refactoring splits the file into 6
focused modules. This analysis identifies 5 findings, all addressable within the scope
of the refactoring.

## Context

- System/component: `lib/chain-runner.sh` (847 lines, 23 functions)
- Review date: 2026-03-12
- Reviewer: Mentiko Technical Analysis Agent v2.1
- Scope: chain-runner.sh, chain-runner-complete.sh, launch-agent.sh, event-trigger.sh

## Findings

---

### Finding 1: Global State Mutation Across 23 Functions

**Category:** architecture
**Severity:** high

**Detail:**
`chain-runner.sh` uses 14 global variables (`CHAIN_FILE`, `WORKSPACE`, `RUN_ID`,
`CURRENT_AGENT`, `AGENT_COUNT`, `EVENTS_DIR`, etc.) that are written by multiple
functions without ownership boundaries. `setup_run_directory()` writes `RUN_DIR` and
`EVENTS_DIR`, but `trigger_agent_event()` also mutates `EVENTS_DIR` on retry. This
creates temporal coupling: functions must be called in a specific order or state
becomes inconsistent. Line 342 shows `AGENT_COUNT` being incremented inside
`launch_agent_session()` and also reset inside `handle_branch_complete()` — these
interact unpredictably when branches run in parallel.

**Recommendation:**
Extract all run-scoped state into a single associative array `declare -A RUN_STATE`
passed explicitly to each function, or into a temp state file read/written atomically.
Functions should return values through stdout, not global mutation. This is the highest
priority change because it makes everything else easier to reason about.

---

### Finding 2: No Timeout Enforcement on Agent Sessions

**Category:** performance
**Severity:** high

**Detail:**
Agent sessions are launched via `pty-manager` but no timeout is enforced at the
chain-runner level. If an agent hangs (infinite loop, waiting for input that never
comes), the chain run waits indefinitely. The `watchdog.sh` script detects stalled
runs but only marks them as "stalled" after 30 minutes — it does not terminate the
session. In production, 3 of the last 47 chain runs had to be manually killed.
The agent config schema supports `timeout` (integer, seconds) but chain-runner.sh
at line 512 reads it and logs a warning but never acts on it:
```bash
local timeout="${agent_config[timeout]:-}"
if [ -n "$timeout" ]; then
  log_warn "agent timeout configured ($timeout s) but enforcement not yet implemented"
fi
```

**Recommendation:**
Implement timeout enforcement in `launch_agent_session()` using a background
`sleep $timeout && bin/p destroy $session_name` co-process that is killed if the
agent completes normally. Pattern:
```bash
( sleep "$timeout" && bin/p destroy "$session_name" \
    && emit_event "agent.timeout" "$session_name" ) &
TIMEOUT_PID=$!
wait_for_agent_completion "$session_name"
kill "$TIMEOUT_PID" 2>/dev/null
```

---

### Finding 3: Branch Termination Values Create Phantom Agent Sessions

**Category:** architecture
**Severity:** medium

**Detail:**
When a branch condition evaluates to a value like `"stop"`, `"skip"`, or `"done"`,
the current code treats it as an agent ID and attempts to launch an agent session
for it (line 634: `launch_agent "$branch_value"`). This creates a phantom session
that immediately fails, emits a `session.error` event, and — in some cases — triggers
the watchdog's retry logic, creating a retry loop. This was the root cause of the
phantom agents bug fixed in commit 7e2595f, but the underlying issue (branch values
not being validated before use as agent IDs) was only patched, not fixed architecturally.

**Recommendation:**
Define a reserved words set `TERMINAL_BRANCH_VALUES=("stop" "skip" "done" "end" "halt")`
and check against it before attempting to launch. In the refactored module structure,
this check belongs in `lib/chain-runner/branch.sh::resolve_branch_target()`.

---

### Finding 4: mktemp Suffix Pattern Breaks on macOS

**Category:** maintainability
**Severity:** medium

**Detail:**
`lib/agent-profile.sh` line 89 uses `mktemp /tmp/agent-env-XXXXXX.sh` with a `.sh`
suffix. On macOS, `mktemp` does not support suffixes after the template — this creates
a literal file named `/tmp/agent-env-XXXXXX.sh`. The second invocation fails with
"File exists", silently leaving the agent without sourced env vars. The correct pattern
is `mktemp /tmp/agent-env-XXXXXX` (no suffix). This was documented in CLAUDE.md but
the fix was not applied consistently across all call sites. Three additional mktemp
calls in `lib/chain-runner.sh` (lines 201, 445, 677) use the incorrect suffix pattern.

**Recommendation:**
Audit all mktemp calls in the codebase: `grep -rn 'mktemp.*\.sh' lib/`. Replace all
instances of `mktemp /tmp/XXXXXX.sh` with `mktemp /tmp/XXXXXX`. Add a CI lint check
via a custom bash lint rule (shellcheck does not catch this).

---

### Finding 5: Event Files Are Not Cleaned Up on Chain Cancellation

**Category:** scalability
**Severity:** low

**Detail:**
When a chain run is cancelled mid-execution (SIGTERM to the chain-runner process),
the trap handler at line 18 calls `cleanup_run()` which removes the run directory but
does not clean up event files in `${EVENTS_DIR}/`. These `.event` files accumulate:
a 3-hour chain run with 15 agents generates approximately 180 event files. Over time,
directories with thousands of event files cause `ls` and `inotifywait` to slow
noticeably (observed: 2.1s for `ls` on a directory with 4,200 event files vs 12ms
normally). A project with 500+ runs has accumulating event debris going back months.

**Recommendation:**
Add `rm -f "${EVENTS_DIR}"/*.event 2>/dev/null` to `cleanup_run()`. Additionally,
add a weekly cron job (`lib/maintenance.sh`) to prune event files older than 7 days
from all project run directories.

---

## Risk Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 2 |
| Medium | 2 |
| Low | 1 |

risk_summary:
  critical: 0
  high: 2
  medium: 2
  low: 1

## Recommendation Priority

1. Eliminate global state mutation — extract to `RUN_STATE` associative array (Finding 1)
2. Implement agent session timeout enforcement (Finding 2)
3. Validate branch termination values before use as agent IDs (Finding 3)
4. Fix all mktemp calls to remove .sh suffix (Finding 4)
5. Clean up event files in cleanup_run() trap handler (Finding 5)

## Conclusion

Overall assessment: REQUEST CHANGES

The refactoring is architecturally sound and the proposed module split is the right
direction. Two high-severity issues (global state mutation, missing timeout enforcement)
should be addressed as part of this refactoring rather than deferred. The medium and
low findings are straightforward fixes. Recommend approving the refactoring plan with
these 5 items included in scope.

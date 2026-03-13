---
id: threat-model
name: Threat Model
format: markdown
category: security
tags: [security, threat-model, stride, architecture]
description: >
  STRIDE-based threat model documenting assets, trust boundaries, threats, mitigations,
  and residual risk. Produced by a security agent during architecture review or before
  major system changes affecting security boundaries.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    system:
      type: string
      description: Name of the system or component being modeled
    scope:
      type: string
      description: What is and is not in scope for this threat model
    assets:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
          classification:
            type: string
            enum: [critical, sensitive, internal, public]
          description:
            type: string
    threats:
      type: array
      items:
        type: object
        properties:
          id:
            type: string
            description: Threat identifier e.g. T-001
          stride_category:
            type: string
            enum: [Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege]
          threat:
            type: string
            description: Description of the threat scenario
          mitigation:
            type: string
            description: Controls in place or recommended to address this threat
          residual_risk:
            type: string
            enum: [high, medium, low, accepted]
    trust_boundaries:
      type: array
      items:
        type: string
      description: List of trust boundary descriptions
  required: [system, assets, threats]
validation_rules:
  - stride_category must be one of the 6 STRIDE categories exactly as spelled
  - assets.classification must be critical, sensitive, internal, or public
  - every threat must have a non-empty mitigation field
  - residual_risk must be high, medium, low, or accepted
related_artifacts:
  - security-audit
  - security-scan-report
---

# Threat Model: Mentiko Chain Execution System

## Metadata

- System: Mentiko Chain Execution Engine
- Date: 2026-03-12
- Modeler: Mentiko Security Agent v1.4 (reviewed by: Priya Sharma)
- Methodology: STRIDE per-element
- Version: 1.2

## System Overview

The Mentiko chain execution system accepts a chain definition (JSON), spawns AI agent
sessions in isolated PTY terminals via `pty-manager`, coordinates handoffs through
file-based event triggers, and stores run artifacts in the filesystem. The system runs
on a Linux host (local or VPS), exposes a Next.js API layer for the web UI, and may
execute arbitrary CLI tools (claude, codex, aider, custom scripts) with user-configured
authorities (read_files, write_files, execute_commands, network_access).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│ Browser (Next.js Web UI)                                             │
│   user → /api/chains/run → chain-runner.sh → pty-manager sessions   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTPS (Caddy TLS)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│ VPS (74.207.252.96)                                                  │
│  ┌──────────────┐   ┌───────────────┐   ┌────────────────────────┐  │
│  │  Next.js API │──▶│ chain-runner  │──▶│  pty-manager sessions  │  │
│  │  :3000       │   │ (bash)        │   │  (agent 1, agent 2...) │  │
│  └──────────────┘   └───────────────┘   └────────────────────────┘  │
│         │                   │                        │               │
│         ▼                   ▼                        ▼               │
│  ┌──────────────┐   ┌───────────────┐   ┌────────────────────────┐  │
│  │  auth.db     │   │  events/      │   │  workspace files       │  │
│  │  (SQLite)    │   │  runs/        │   │  (read/write by agents)│  │
│  └──────────────┘   └───────────────┘   └────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Trust Boundaries

1. Public internet → Caddy reverse proxy (HTTPS termination, auth cookie required)
2. Next.js API process → chain-runner bash process (same host, user-level trust)
3. chain-runner process → pty-manager agent sessions (same host, agent config controls scope)

## Assets

| Asset | Classification | Description |
|-------|----------------|-------------|
| User API keys and credentials | critical | ANTHROPIC_API_KEY and other secrets stored in agent profiles, sourced via temp files |
| auth.db session tokens | critical | SQLite database containing all active session tokens; compromise = full account takeover |
| Workspace files | sensitive | Source code and project files that agents can read/write; may contain proprietary code |
| Chain execution history (runs/) | internal | Run logs, agent outputs, artifacts; sensitive but not credential-bearing |

## Threat Analysis (STRIDE)

---

### T-001: Spoofing — Agent Session Impersonation

**STRIDE Category:** Spoofing
**Threat:** A compromised or malicious agent process could read the PTY session name
of another agent's session from the runs directory and send crafted input to that
session via `bin/p send`, impersonating legitimate chain-runner coordination messages.

**Mitigation:**
PTY session names include a random run ID component (`session-{run_id}-{agent_id}`)
generated at chain start. Access to `bin/p send` requires filesystem access to the
runs directory. The runs directory is owned by the platform user and not world-readable.
All `bin/p` operations are logged with caller PID.

**Residual Risk:** low

---

### T-002: Tampering — Chain Definition File Modification

**STRIDE Category:** Tampering
**Threat:** An attacker with write access to the org's chains directory could modify
a chain definition JSON to inject malicious agent configurations (e.g., adding
`execute_commands` authority to an agent that shouldn't have it, or changing the
agent's model to one that exfiltrates data). The modified chain would be executed
the next time it is triggered.

**Mitigation:**
Chain definitions are stored in `~/.mentiko/namespaces/{ns}/orgs/{org}/chains/`.
Access requires authentication as an org member with write permissions. The web UI
shows diffs before saving chain edits. Chain definitions do not directly control
system-level permissions — agent `authorities` are validated against an allowlist
at launch time in `launch-agent.sh`. Chain file integrity hashing (SHA-256 of chain
file stored at launch, verified before each run) is recommended but not yet implemented.

**Residual Risk:** medium

---

### T-003: Repudiation — Agent Action Deniability

**STRIDE Category:** Repudiation
**Threat:** An agent executes a destructive action (deletes files, pushes code, makes
an API call) and there is insufficient audit trail to prove which chain run, which
agent, and which user triggered the action. A user claims they did not authorize
the action.

**Mitigation:**
Every chain run creates a run directory with a `run.json` manifest recording chain ID,
initiating user, start time, and agent sequence. Agent activity capture (`lib/agent-activity-capture.sh`)
records PTY output including tool calls. The audit log (`./bin/agent-chain audit`)
provides a queryable record of all runs. Gaps: tool-level audit (exactly what files
were written) requires the agent to produce a `code-changes` artifact; this is
optional, not enforced.

**Residual Risk:** medium

---

### T-004: Information Disclosure — Credential Leakage via PTY Output

**STRIDE Category:** Information Disclosure
**Threat:** An agent profile contains `ANTHROPIC_API_KEY` or other secrets. The key
is echoed to PTY output (e.g., the agent prints its environment for debugging), which
is captured to the runs log and visible in the web UI's output tab. Any user with
run read access can extract the credential.

**Mitigation:**
Agent profile env vars are written to a temp file, sourced, and deleted before the
agent CLI is invoked — they are never in the command string. `web/lib/sanitize-output.ts`
applies regex-based credential redaction to all PTY output before serving it via API.
The redaction patterns cover `ANTHROPIC_API_KEY`, `sk-*`, `Bearer *`, and common
secret patterns. Defense-in-depth: the temp file is created with `chmod 600`.

**Residual Risk:** low

---

### T-005: Denial of Service — Chain Run Flooding

**STRIDE Category:** Denial of Service
**Threat:** An authenticated user (or compromised account) submits hundreds of chain
run requests in rapid succession. Each spawns PTY agent sessions that consume CPU,
memory, and file descriptors. The system becomes unresponsive for all users.
(This maps to SEC-001 in the current security audit.)

**Mitigation:**
Currently: no rate limiting is implemented at the API layer. This is an open finding
(SEC-001). Planned: per-user rate limit (10 runs/minute, 50/hour), per-org concurrent
chain cap (5), implemented via Redis token bucket.

**Residual Risk:** high

---

### T-006: Elevation of Privilege — Agent Escaping Authority Sandbox

**STRIDE Category:** Elevation of Privilege
**Threat:** An agent configured with only `read_files` authority executes a shell
command via a tool call (e.g., Claude's bash tool) that the authority model was
intended to prevent. The agent writes files, spawns processes, or makes network
requests that exceed its configured authorities.

**Mitigation:**
Agent authorities are enforced by passing `--allowedTools` flags to the claude CLI.
An agent with `read_files` only receives `--allowedTools Read,Glob,Grep`. Write and
execute tools are not available. However, this enforcement is only as strong as the
CLI's tool restriction implementation — if the model finds a way to write through
an allowed tool (e.g., writing to stdout and redirecting), the restriction is bypassed.
Full sandbox enforcement would require OS-level controls (seccomp, chroot, or container
isolation per agent).

**Residual Risk:** medium

---

## Security Controls

| Control | Type | Threats Addressed | Status |
|---------|------|-------------------|--------|
| HTTPS TLS termination via Caddy | Preventive | T-004 (transit) | Implemented |
| Session cookie auth on all API routes | Preventive | T-001, T-006 | Implemented |
| Credential redaction in sanitize-output.ts | Detective/Preventive | T-004 | Implemented |
| Temp file env sourcing (chmod 600) | Preventive | T-004 | Implemented |
| Agent authority --allowedTools enforcement | Preventive | T-006 | Implemented |
| Run audit log (runs/ directory) | Detective | T-003 | Implemented |
| Rate limiting on /api/chains/run | Preventive | T-005 | Planned (SEC-001) |
| Chain file integrity hashing | Detective | T-002 | Not implemented |

## Recommended Actions

| Priority | Action | Owner | Due Date |
|----------|--------|-------|----------|
| High | Implement rate limiting on /api/chains/run (SEC-001) | Marco Almazan | 2026-03-19 |
| Medium | Add chain definition integrity hashing (SHA-256 at save, verify at run) | Sarah Chen | 2026-04-01 |
| Medium | Enforce `code-changes` artifact production for agents with write_files authority | Marco Almazan | 2026-04-15 |
| Low | Evaluate OS-level sandboxing (seccomp profile) for agent sessions | Priya Sharma | 2026-05-01 |

## Assumptions and Limitations

- This model assumes the host OS and kernel are not compromised (out of scope)
- Assumes Caddy TLS configuration is correct and certificates are valid
- Does not cover supply chain threats (compromised npm packages, bash libraries)
- Agent model behavior (what Claude or Codex will actually do with a given prompt) is
  treated as probabilistic, not deterministic — the threat model cannot enumerate all
  possible agent actions

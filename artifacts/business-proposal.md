---
id: business-proposal
name: Business Proposal
format: markdown
category: business
tags: [business, proposal, executive]
description: >
  Executive-ready business proposal with problem statement, solution, market analysis,
  financials, and implementation roadmap. Produced by a strategy or research agent after
  analyzing market data and product requirements.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    executive_summary:
      type: string
      description: Problem + solution in 2-3 sentences
    problem_statement:
      type: string
      description: Description of the problem being solved
    solution:
      type: string
      description: Proposed solution and key benefits
    market_size:
      type: string
      description: TAM/SAM/SOM figures with sources
    financials:
      type: object
      properties:
        investment_required:
          type: string
          description: Total capital required with currency and amount
        roi_timeline:
          type: string
          description: Expected time to positive ROI
        projected_revenue:
          type: string
          description: Revenue projections by year
    implementation_phases:
      type: array
      items:
        type: object
        properties:
          phase:
            type: string
          duration:
            type: string
          milestones:
            type: array
            items:
              type: string
  required: [executive_summary, problem_statement, solution]
validation_rules:
  - executive_summary must be 2-5 sentences
  - financials.investment_required must include currency and amount
  - implementation_phases must have at least 2 phases
  - each phase must have a duration estimate
related_artifacts:
  - metrics-report
  - research-summary
---

# Business Proposal: Mentiko — AI Agent Orchestration Platform

## Executive Summary

Engineering teams waste 60-80% of their time on repetitive multi-step workflows that
require orchestrating multiple AI tools, switching context between systems, and manually
chaining outputs. Mentiko is an AI agent orchestration platform that lets teams define
these workflows as JSON chains, execute them in isolated PTY sessions, and monitor
results through a unified web interface. We are seeking $2.4M in seed funding to accelerate
product development and reach $1.2M ARR within 18 months of launch.

## Problem Statement

Modern engineering teams rely on 4-6 AI tools (Claude, Codex, GitHub Copilot, Cursor,
Aider) that each operate in isolation. Connecting them requires custom scripts, brittle
shell pipelines, and constant manual intervention.

**Impact:** Teams lose 12-15 hours per engineer per week to workflow glue code that
adds no business value.

**Current state:** Ad-hoc bash scripts, tmux sessions managed by hand, outputs
copy-pasted between tools. No audit trail, no retry logic, no visibility into what
ran or why.

**Desired state:** Declarative JSON chain definitions that orchestrate any AI tool,
with automatic retry, event-driven triggers, PTY isolation, and a real-time web UI
showing exactly what each agent is doing.

## Proposed Solution

Mentiko is a 4-layer orchestration system: a web UI for building and monitoring chains,
a bash orchestration engine that sequences agents via event triggers, a PTY execution
layer that isolates each agent in its own terminal session, and a file-based + SQLite
data layer for audit and replay.

**Key benefits:**

- Any AI CLI tool works out of the box: claude, codex, aider, kollabor, custom scripts
- JSON chain definitions are portable and version-controlled alongside code
- PTY isolation prevents agent sessions from interfering with each other
- Event-driven triggers enable complex branching without custom code
- Full audit trail: every input, output, and decision is captured and replayable

## Market Analysis

**Target market:** Engineering teams at companies with 10-500 engineers who have adopted
AI coding tools and hit the coordination ceiling.

**Market size:**
- TAM: $28B (global DevOps tools market, Gartner 2025)
- SAM: $4.2B (AI-augmented development tools segment)
- SOM: $185M (teams actively using 3+ AI tools, early adopter segment)

**Competitive landscape:**

| Competitor | Strengths | Weaknesses |
|------------|-----------|------------|
| LangChain/LangGraph | Large ecosystem, Python-native | No PTY execution, no real team workflow tooling |
| Prefect | Strong data pipeline UX | Not designed for AI agents or PTY sessions |
| GitHub Actions | Deep GitHub integration | Sequential by default, no AI tool awareness |
| Zapier | No-code ease of use | No code execution, no CLI tools, no audit depth |

## Solution Details

### Technical Approach

Mentiko's core is a bash orchestration engine (`chain-runner.sh`) that reads a chain
JSON definition, spawns agents via `pty-manager` into isolated PTY sessions, and
coordinates handoffs through file-based event triggers. Each agent runs in its own
session, can emit events that trigger downstream agents, and produces artifacts
(diffs, reports, metrics) that are captured and stored.

The web layer is Next.js 16 with a React Flow visual editor, real-time WebSocket
updates from PTY sessions, and a list-detail split UI for monitoring chains as they
execute. Data lives in the filesystem (namespaces/{id}/...) with SQLite for auth,
enabling zero-infrastructure local deployment and straightforward SaaS hosting.

### Implementation Timeline

| Phase | Duration | Deliverables | Dependencies |
|-------|----------|--------------|--------------|
| Phase 1: Core GA | 3 months | Stable chain runner, PTY isolation, web UI v1, basic auth | Engineering team onboarded |
| Phase 2: SaaS Launch | 3 months | Multi-tenant, Stripe billing, onboarding flow, marketplace v1 | Phase 1 complete, legal setup |
| Phase 3: Scale | 6 months | Team features, webhook triggers, email routing, enterprise SSO | Phase 2 + 50 paying customers |

### Resource Requirements

- Team: 3 engineers (1 backend/infra, 1 fullstack, 1 AI/tooling), 1 designer (part-time)
- Budget: $180K/year engineering salaries + $24K/year infrastructure + $36K/year tooling/ops
- Tools/Infrastructure: Linode VPS cluster, GitHub Actions CI/CD, Stripe, Cloudflare DNS

## Financial Projections

| Year | Revenue | Costs | Profit | ROI |
|------|---------|-------|--------|-----|
| Year 1 | $320K | $980K | -$660K | -67% |
| Year 2 | $1.4M | $1.1M | +$300K | +27% |
| Year 3 | $3.8M | $1.6M | +$2.2M | +138% |

Pricing: $49/seat/month (individual), $299/month (team up to 10), $999/month (org up
to 50). Enterprise custom pricing above 50 seats.

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Large vendor (Anthropic/OpenAI) ships native orchestration | Medium | High | Focus on multi-tool, multi-CLI support they won't own |
| PTY isolation breaks on cloud execution environments | Low | High | Abstract via workspace adapters (local, SSH, Docker) |
| Enterprise procurement cycles slow growth | Medium | Medium | Self-serve PLG motion first, sales-assist second |
| Key engineer departure | Low | High | Document architecture, no single points of knowledge |

## Next Steps

1. Approval to proceed: Board sign-off on $2.4M seed round by April 15, 2026
2. Phase 1 start date: May 1, 2026 (team already partially assembled)
3. Success metrics: 500 active orgs by month 6, $50K MRR by month 9, $100K MRR by month 12

## Appendix

Mentiko is currently open source with 847 GitHub stars and 23 active community contributors.
The marketplace (mentiko-marketplace) contains 40+ pre-built chains and 60+ agent
definitions covering common engineering workflows. A working demo is available at
mentiko.com. The founding team has 18 combined years in developer tooling, distributed
systems, and AI/ML infrastructure.

---
id: research-summary
name: Research Summary
format: markdown
category: business
tags: [research, literature, synthesis]
description: >
  Academic-style research synthesis with background, methodology, key findings, and
  citations. Produced by a research agent after analyzing literature, technical blogs,
  and empirical data on a specific topic.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    topic:
      type: string
      description: The research question or subject area
    methodology:
      type: string
      description: Research approach and source types analyzed
    sources_count:
      type: number
      description: Total number of sources reviewed
    key_findings:
      type: array
      items:
        type: string
      minItems: 3
      description: Top findings from the research, at least 3
    confidence_level:
      type: string
      enum: [high, medium, low]
      description: Overall confidence in findings based on source quality and consensus
    citations:
      type: array
      items:
        type: object
        properties:
          title:
            type: string
          author:
            type: string
          year:
            type: number
          url:
            type: string
  required: [topic, key_findings, confidence_level]
validation_rules:
  - key_findings must have at least 3 findings
  - confidence_level must be high, medium, or low with justification in body
  - citations must include author and year
  - abstract must be 100-300 words
related_artifacts:
  - technical-analysis
  - data-analysis-report
---

# Research Summary: AI Agent Orchestration Patterns in Production

## Abstract

This research synthesizes findings from 23 sources — academic papers, engineering
blog posts, conference talks (NeurIPS 2024, SREcon 2025), and production case studies —
on the practical challenges and emerging patterns in deploying multi-agent AI systems
at scale. The research covers the period 2023-2026 and focuses on teams with more
than 5 engineers actively using AI coding tools in production workflows. Key questions
examined: What coordination patterns emerge when multiple AI agents operate on shared
codebases? What failure modes are most common? What infrastructure choices correlate
with successful production deployments? Findings indicate that event-driven handoff
patterns significantly outperform polling-based approaches, that PTY session isolation
is underused but highly effective, and that most teams underestimate the importance
of audit trails until they hit their first production incident involving agent output.
Confidence level is medium due to the rapid pace of change in the field and limited
longitudinal data.

## Background

The deployment of AI coding agents in production engineering workflows has accelerated
dramatically since 2023. Teams that adopted early — primarily at companies with
10-200 engineers — developed ad-hoc orchestration approaches that varied widely
in reliability and observability. By 2025, a cluster of patterns began to emerge
from these early adopters, but most knowledge remained locked in internal documentation
and conference hallway conversations. This research attempts to synthesize the
publicly available evidence into actionable findings for teams building or evaluating
agent orchestration infrastructure.

## Methodology

- Research approach: Systematic literature review + practitioner interview synthesis
- Sources analyzed: 23 (8 academic papers, 9 engineering blogs, 4 conference talks, 2 case studies)
- Time period: 2023-01 through 2026-02
- Inclusion criteria: Production deployments with at least 3 months of runtime data;
  teams of 5+ engineers; explicit discussion of coordination or failure patterns

## Key Findings

### Finding 1: Event-Driven Handoffs Outperform Polling by 3-8x on Latency

**Source:** Rashid et al. (2025), "Coordination Overhead in Multi-Agent Code Generation Systems"

**Summary:**
Teams using file-based or message-queue event triggers between agents achieved
median handoff latency of 180-420ms vs 2.1-8.4s for polling-based approaches.
The improvement held across all workload sizes (2-agent chains up to 12-agent chains).
Additionally, event-driven systems showed 67% fewer "stuck pipeline" incidents
compared to polling systems over a 6-month observation window.

**Implications:**
Agent orchestration frameworks should prioritize event emission/subscription over
periodic polling. File-based events (inotify/kqueue) are sufficient for local
deployments; message queues (Redis Streams, NATS) are necessary at scale.

### Finding 2: PTY Session Isolation Reduces Cross-Agent Contamination by 94%

**Source:** Internal case study, Vercel Platform Team (2025); corroborated by
Gonzalez & Park (2024)

**Summary:**
Teams that ran agents in shared terminal sessions reported frequent issues with
environment variable leakage, working directory conflicts, and partial output
parsing errors. Teams using PTY isolation (one session per agent) reported a 94%
reduction in these contamination errors. The overhead of PTY session creation was
negligible (12-35ms per session) compared to agent startup time (2-8 seconds).

**Implications:**
Default agent execution should use isolated PTY sessions. Shared sessions are only
appropriate for agents explicitly designed to collaborate in real-time (peer patterns).

### Finding 3: Audit Trails Become Critical Within 60 Days of Production Use

**Source:** Survey of 47 teams, Dang & Okafor (2025), "Observability in LLM-Powered
Development Pipelines"

**Summary:**
87% of teams that deployed agents without audit trails reported at least one incident
within 60 days where they needed to replay or understand what an agent had done.
Of those, 61% said the lack of audit trail extended their incident resolution time
by more than 30 minutes. Teams with structured audit logs (input + output + decision
capture per agent step) resolved these incidents in median 8 minutes vs 47 minutes
for teams without.

**Implications:**
Audit trail infrastructure should be built before, not after, the first production
incident. At minimum: capture agent prompts, tool calls, and outputs. Better: capture
the full decision sequence including intermediate reasoning steps.

### Finding 4: Model Selection Matters Less Than Prompt Quality for Pipeline Reliability

**Source:** Chen et al. (2024), "Empirical Analysis of Agent Reliability Across LLM Providers"

**Summary:**
Across 12,000 chain runs logged from 6 teams, switching from GPT-4 to Claude 3
(or vice versa) changed pipeline success rate by 3-7%. Improving the system prompt
clarity and adding explicit output format constraints changed success rate by 18-34%.
The single highest-impact intervention was adding explicit "emit this JSON when done"
instructions to agent prompts.

**Implications:**
Teams optimizing for reliability should invest in prompt engineering before model
selection. Structured output instructions (JSON schema in prompt) are the highest-ROI
reliability intervention available.

### Finding 5: Connection Pool Exhaustion Is the Leading Infrastructure Failure Mode

**Source:** SREcon 2025, "Database Failures in AI-Augmented Engineering Workflows,"
Priya Sharma & Yuki Tanaka

**Summary:**
In a survey of 89 production incidents across 31 teams, 34% were caused by database
connection pool exhaustion triggered by long-running analytics queries from reporting
agents. The pattern: analytics agent does a full-table scan, holds connections, starves
the API. Teams that set explicit query timeouts and pool size limits at 3x their baseline
saw this failure mode drop to near-zero.

**Implications:**
Any agent that queries a production database should have explicit timeouts (< 60s) and
run in a read-only connection pool separate from the API's primary pool.

## Synthesis

The evidence converges on a clear pattern: agent orchestration reliability is primarily
an infrastructure and instrumentation problem, not a model capability problem. Teams
that treat agents as first-class infrastructure components — with isolated execution
environments, event-driven coordination, structured audit trails, and database access
controls — achieve significantly better outcomes than teams that treat agents as
enhanced shell scripts.

The gap between "it works in staging" and "it works in production" for agent pipelines
is larger than for traditional services, because agents can produce subtly wrong outputs
that only become visible at scale or under load. This makes audit trails and replay
capability disproportionately valuable.

## Gaps and Limitations

- Most data comes from software engineering teams; findings may not generalize to
  data science, ML ops, or non-technical agent deployments
- Longitudinal data beyond 12 months is sparse; the field is moving faster than
  publication cycles
- "Production use" definitions vary significantly across studies (some count any
  external-facing deployment, others require > 1000 agent runs/day)
- No controlled studies exist yet — all findings are observational

## Recommendations

1. Adopt event-driven handoff patterns from day one — the latency and reliability
   improvements are immediate and the implementation cost is low
2. Run every agent in an isolated PTY session — do not share terminal state between agents
3. Build audit trail infrastructure before you need it — structured capture of input,
   output, and tool calls per agent step
4. Set database query timeouts for all analytics agents — 60 seconds maximum,
   separate read-only connection pool
5. Invest in prompt quality before model selection — output format constraints
   are the highest-ROI reliability intervention

## References

1. Rashid, A., Kim, J., & Osei, B. (2025). Coordination Overhead in Multi-Agent Code
   Generation Systems. Proceedings of ICSE 2025.
   https://dl.acm.org/doi/10.1145/example-2025-rashid

2. Gonzalez, M. & Park, S. (2024). Terminal Session Isolation in Automated Software
   Engineering Agents. arXiv:2401.09847.
   https://arxiv.org/abs/2401.09847

3. Dang, L. & Okafor, C. (2025). Observability in LLM-Powered Development Pipelines.
   SREcon Americas 2025.
   https://www.usenix.org/conference/srecon25americas/presentation/dang

4. Chen, R., Hoffman, T., & Vasquez, E. (2024). Empirical Analysis of Agent Reliability
   Across LLM Providers. NeurIPS 2024 Workshop on Responsible AI in Engineering.
   https://neurips.cc/virtual/2024/workshop/example

5. Sharma, P. & Tanaka, Y. (2025). Database Failures in AI-Augmented Engineering
   Workflows. SREcon Americas 2025.
   https://www.usenix.org/conference/srecon25americas/presentation/sharma-tanaka

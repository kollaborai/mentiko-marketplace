# Incident Response Pipeline

Automated incident handling with detect, triage, resolve, and review agents.

## Agents

1. Detect - Analyzes alerts and confirms incidents
2. Triage - Assesses severity and coordinates response
3. Resolve - Implements fix and restores service
4. Review - Creates postmortem and improvement plan

## Features Demonstrated

- **Severity-based Escalation**: P1-P4 classification with appropriate response
- **Blameless Postmortems**: Focus on process improvement
- **Action Tracking**: Follow-up items with owners
- **MTTR Tracking**: Time to detect, triage, resolve metrics

## Running

```bash
# Set incident details
export INCIDENT_ID=INC-2024-001
export SEVERITY=P1
export SERVICE=api-gateway
export REGION=us-east-1
export SOURCE=alert
export ON_CALL="on-call@example.com"

# Run the incident response
chain-runner examples/incident-response/chain.json
```

## Workspace Structure

```
workspace/
  detect/
    incident-summary.md     - what's happening
    scope.md                - what's affected
    impact-assessment.md    - user and business impact
    initial-evidence.md     - logs, metrics, screenshots
    detection-timestamp.md  - when it started
  triage/
    triage-report.md        - severity and assessment
    severity.md             - assigned severity with rationale
    responders.md           - who's involved
    communication-plan.md    - notification plan
    estimated-resolution.md - time estimate
    war-room-commands.md    - commands to set up war room
  resolve/
    root-cause.md           - what caused it
    fix-options.md          - considered solutions
    actions-taken.md        - chronological action log
    fix-applied.md          - what was fixed
    verification.md         - how we verified
    rollback-plan.md        - how to undo if needed
    resolution-timestamp.md - when fixed
  review/
    postmortem.md           - full incident report
    timeline.md             - event timeline
    root-cause-analysis.md  - 5 whys, causal factors
    response-assessment.md  - what went well/didn't
    action-items.md         - prevention steps
    metrics.md              - MTTD, MTTR, availability
    communication-summary.md - notifications sent
```

## Severity Levels

- **P1 Critical**: Service down, all users affected, immediate response
- **P2 High**: Major degradation, many users affected
- **P3 Medium**: Partial degradation, some users affected
- **P4 Low**: Minor issue, few users affected

## Configuration

Before running, ensure:

- `alerts/{incident_id}.json` exists with alert details
- Monitoring dashboards are accessible
- On-call rotation is configured

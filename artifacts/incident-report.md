---
id: incident-report
name: Incident Post-Mortem
format: markdown
category: technical
tags: [incident, post-mortem, ops, reliability]
description: Blameless post-mortem template with timeline, impact analysis, root cause, contributing factors, and action items.
author: mentiko
version: 1.0
---

# Incident Post-Mortem

## Metadata
- Incident ID: {INCIDENT_ID}
- Date: {INCIDENT_DATE}
- Duration: {DURATION}
- Severity: {SEVERITY_LEVEL}
- Author: {AUTHOR}
- Contributors: {CONTRIBUTORS}

## Executive Summary
{ONE_PARAGRAPH_SUMMARY}

## Impact Assessment
| Metric | Value |
|--------|-------|
| Users affected | {AFFECTED_USERS} |
| Downtime | {DOWNTIME_DURATION} |
| Revenue impact | {REVENUE_IMPACT} |
| Customer tickets | {TICKET_COUNT} |
| Data loss | {DATA_LOSS} |

## Timeline
| Time (UTC) | Event | Duration |
|------------|-------|----------|
| {TIMESTAMP} | {EVENT_DESCRIPTION} | {ELAPSED_TIME} |
| ... | ... | ... |

### Timeline Narrative
{DETAILED_TIMELINE_NARRATIVE}

## Root Cause Analysis

### Root Cause
{PRIMARY_ROOT_CAUSE}

### Contributing Factors
1. {FACTOR_1}
2. {FACTOR_2}
3. {FACTOR_3}

### Five Whys
1. Why did the incident occur?
   {WHY_1}
2. Why did {WHY_1} happen?
   {WHY_2}
3. Why did {WHY_2} happen?
   {WHY_3}
4. Why did {WHY_3} happen?
   {WHY_4}
5. Why did {WHY_4} happen?
   {WHY_5}

## Resolution
{HOW_ISSUE_WAS_RESOLVED}

## Action Items

### Preventive (Fix Root Cause)
| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| {ACTION} | {OWNER} | {DATE} | {STATUS} |
| ... | ... | ... | ... |

### Detective (Improve Monitoring)
| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| ... | ... | ... | ... |

### Reactive (Improve Response)
| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| ... | ... | ... | ... |

## Lessons Learned
### What went well
- ...
- ...

### What could be improved
- ...
- ...

### Knowledge gaps identified
- ...
- ...

## Appendix
- Incident timeline screenshots: {LINK}
- Logs: {LINK}
- Metrics graphs: {LINK}

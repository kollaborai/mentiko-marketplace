---
id: threat-model
name: Threat Model
format: markdown
category: security
tags: [security, threat-model, stride, architecture]
description: STRIDE-based threat model documenting assets, trust boundaries, threats, mitigations, and residual risk for system security review.
author: mentiko
version: 1.0
---

# Threat Model: {SYSTEM_NAME}

## Metadata
- System: {SYSTEM}
- Date: {DATE}
- Modeler: {MODELER}
- Methodology: STRIDE per-element
- Version: {VERSION}

## System Overview
{SYSTEM_DESCRIPTION}

## Architecture Overview
```
[DIGRAM or ASCII art of system architecture]
```

## Trust Boundaries
| Boundary | Description | Trust Level |
|----------|-------------|-------------|
| {BOUNDARY_1} | {DESCRIPTION} | {TRUST_LEVEL} |
| ... | ... | ... |

## Data Flow Diagrams
### DFD Level 0 (Context)
{CONTEXT_DFD}

### DFD Level 1 (Process Decomposition)
{LEVEL_1_DFD}

## Assets
| Asset | Type | Sensitivity | Security Requirements |
|-------|------|-------------|----------------------|
| {ASSET_1} | {TYPE} | {SENSITIVITY} | {REQUIREMENTS} |
| ... | ... | ... | ... |

## Threat Analysis (STRIDE)

### External Entity: {ENTITY_NAME}
| STRIDE | Threat | Likelihood | Impact | Mitigation | Residual Risk |
|--------|--------|------------|--------|------------|--------------|
| Spoofing | ... | ... | ... | ... | ... |
| Tampering | ... | ... | ... | ... | ... |
| Repudiation | ... | ... | ... | ... | ... |
| Information Disclosure | ... | ... | ... | ... | ... |
| Denial of Service | ... | ... | ... | ... | ... |
| Elevation of Privilege | ... | ... | ... | ... | ... |

### Process: {PROCESS_NAME}
| STRIDE | Threat | Likelihood | Impact | Mitigation | Residual Risk |
|--------|--------|------------|--------|------------|--------------|
| ... | ... | ... | ... | ... | ... |

### Data Store: {STORE_NAME}
| STRIDE | Threat | Likelihood | Impact | Mitigation | Residual Risk |
|--------|--------|------------|--------|------------|--------------|
| ... | ... | ... | ... | ... | ... |

### Data Flow: {FLOW_NAME}
| STRIDE | Threat | Likelihood | Impact | Mitigation | Residual Risk |
|--------|--------|------------|--------|------------|--------------|
| ... | ... | ... | ... | ... | ... |

## Security Controls
| Control | Type | Threats Addressed | Implementation Status |
|---------|------|-------------------|----------------------|
| {CONTROL_1} | {TYPE} | {THREATS} | {STATUS} |
| ... | ... | ... | ... |

## Recommended Actions
| Priority | Action | Owner | Due Date |
|----------|--------|-------|----------|
| High | ... | ... | ... |
| Medium | ... | ... | ... |
| Low | ... | ... | ... |

## Assumptions and Limitations
- {ASSUMPTION_1}
- {ASSUMPTION_2}
...

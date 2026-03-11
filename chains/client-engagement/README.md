# Client Engagement Pipeline

Four-agent workflow for client deliverables with webhook notifications.

## Agents

1. Solutions Architect - Analyzes needs and designs technical solution
2. Account Executive - Creates proposal, pricing, and SOW
3. Project Manager - Reviews consistency and creates project plan
4. Quality Assurance - Final review for client readiness

## Features Demonstrated

- **Webhooks**: Notifies external endpoints on chain events
- **Branching**: Routes `needs-revision` event back to Solutions Architect
- **Multi-agent coordination**: Sequential workflow with handoffs

## Webhook Configuration

```json
"webhooks": {
  "enabled": true,
  "urls": ["https://webhook.site/your-unique-id"],
  "events": ["chain_started", "agent_complete", "chain_complete", "agent_error", "chain_error"],
  "retry": {
    "max_attempts": 3,
    "backoff_base": 2,
    "initial_delay": 1,
    "max_delay": 60
  }
}
```

## Running

```bash
# Set your task
export TASK="Create a proposal for a roofing company website"

# Run the chain
chain-runner examples/client-engagement/chain.json
```

## Workspace Structure

```
workspace/
  solution/     - Architecture, tech stack, timeline, risks
  proposal/     - Proposal, pricing, SOW
  planning/     - Project plan, milestones, resources
  qa/           - Final review and verdict
```

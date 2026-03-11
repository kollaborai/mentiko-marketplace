# Research Write Review Loop

Three-agent chain with conditional branching based on review verdict.

## Agents

1. Researcher - Gathers information on the topic
2. Writer - Creates content based on research
3. Reviewer - Reviews for quality, accuracy, completeness

## Features Demonstrated

- **Conditional Branching**: Routes to different agents based on review verdict
  - `needs-revision-research` -> Researcher
  - `needs-revision-draft` -> Writer
  - `review-approved` -> Chain complete

## Branching Configuration

```json
"branches": {
  "needs-revision-research": "researcher",
  "needs-revision-draft": "writer"
}
```

## Running

```bash
# Set your task
export TASK="Write a guide to container orchestration"

# Run the chain
chain-runner examples/research-write-review/chain.json
```

## How Branching Works

The Reviewer ends with a verdict:

```
VERDICT: approved              -> Chain completes
VERDICT: needs-revision-research -> Goes back to Researcher
VERDICT: needs-revision-draft   -> Goes back to Writer
```

The corresponding event is emitted, and the branches config routes it to the correct agent.

## Workspace Structure

```
workspace/
  research/   - Research findings
  draft/      - Content draft
  review/     - Review feedback with verdict
```

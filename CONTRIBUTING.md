# Contributing to the Mentiko Marketplace

## Process

1. Fork this repo
2. Add your agent or template following the structure below
3. Open a PR - it goes through peer review
4. Once approved and merged, it ships to all Mentiko workspaces within 24h

## Agent submissions (agents/)

Each agent lives in its own directory named after its id:

```
agents/
  my-agent/
    agent.json   required
    README.md    recommended (describe what it does, example inputs/outputs)
```

Required fields in agent.json:

```json
{
  "id": "my-agent",
  "name": "My Agent",
  "description": "One sentence. What does it do and when should you use it.",
  "role": "short role label",
  "version": "1.0",
  "prompt": "Full agent instructions. Include {TASK} placeholder.",
  "triggers": ["event_name"],
  "emits": "completion_event",
  "model": "claude-sonnet-4-6",
  "tools": [],
  "category": "general",
  "tags": [],
  "author": "your-github-username"
}
```

## Template submissions (templates/ or examples/)

Templates are reusable chain configurations. Examples are simpler
single-use demos. Both use the same format:

```
templates/
  my-template/
    chain.json   required
    README.md    recommended
```

## Review criteria

Reviewers check:

- agent.json has all required fields and validates against the schema
- prompt is clear, has {TASK} placeholder, produces predictable output
- no hardcoded secrets, API keys, or personal data
- no network calls to external services outside of the declared tools
- description and README accurately describe behavior
- id is kebab-case, unique, does not conflict with built-in agents

## What gets rejected

- agents that just wrap a single tool with no added value
- vague prompts that produce unpredictable output
- anything that exfiltrates data or has side effects outside the workspace
- duplicate submissions (check existing agents first)

# Mentiko Marketplace

Community-contributed agents and chain templates for [Mentiko](https://mentiko.com).

All submissions go through peer review before merging. Once merged, your
agent or template becomes available to all Mentiko users automatically
(VPSes pull updates daily).

## Structure

```
agents/
  <agent-id>/
    agent.json     required
    README.md      recommended

templates/
  <template-slug>/
    chain.json     required
    README.md      recommended

examples/
  <example-slug>/
    chain.json     required
    README.md      recommended
```

## Submitting

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Using

Agents and templates appear in your Mentiko workspace under the Marketplace
tab with a `community` badge. Install an agent to add it to your namespace.

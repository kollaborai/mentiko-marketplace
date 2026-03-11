# Code Review Chain

a two-agent pair programming workflow where the coder implements and the reviewer critiques.

## features

  webhook notifications
    - sends updates to configured webhook url
    - events: chain_started, agent_complete, chain_complete, agent_error, chain_error
    - retry with exponential backoff

  conditional branching
    - reviewer can send work back to coder via "needs-changes" verdict
    - iterates up to max_rounds (default: 3)

  agent roles
    - coder: implements features, writes code
    - reviewer: checks correctness, style, security, performance

## usage

  1. update the webhook url to your own endpoint
  2. create docs/client-brief.md or adjust read_first paths
  3. run: glm-chain run examples/code-review/chain.json

## chain structure

  coder (implement) → reviewer (critique)
                       ↓
                    needs-changes? → loop back to coder

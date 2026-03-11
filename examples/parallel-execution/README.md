# Parallel Execution Pipeline

demonstrates running multiple agents concurrently for faster delivery.

## features

  parallel execution
    - frontend, backend, docs, qa all start simultaneously
    - execution_mode: "all" runs all matching-trigger agents in parallel
    - max_concurrent limits how many agents run at once

  webhook notifications
    - agent_complete fires for each agent as they finish
    - track progress of parallel workstreams

  integration verification
    - integrator agent waits for all parallel work to complete
    - verifies all pieces work together
    - can loop back if critical issues found

## when to use

  good for:
    - agents don't depend on each other's work
    - speed is critical
    - you have resources for multiple concurrent agents

  not ideal for:
    - strict ordering requirements
    - shared state conflicts
    - limited compute resources

## usage

  1. create docs/requirements.md
  2. update webhook url
  3. run: glm-chain run examples/parallel-execution/chain.json

## chain structure

  → frontend ─┐
  → backend ─┤
  → docs   ─┼──→ integrator (waits for ALL)
  → qa     ─┘

## output

  workspace/frontend/     - components, pages, styles, tests
  workspace/backend/      - routes, models, middleware, tests
  workspace/docs/         - user guide, api reference, setup
  workspace/qa/           - test plan, test cases, acceptance criteria
  workspace/integration/  - integration report, api contract, gaps

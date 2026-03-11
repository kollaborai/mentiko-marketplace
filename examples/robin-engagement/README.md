# Robin Contractor Engagement

full client engagement workflow for a specific client with webhooks and revision loops.

## features

  webhook notifications
    - real-time engagement status updates
    - hmac signature support
    - retry with exponential backoff

  revision loops
    - quality reviewer can send back to solutions architect
    - tracks specific issues requiring revision
    - max_rounds prevents infinite loops

  client-specific customization
    - workspace/robin/ for all deliverables
    - robin-specific naming in documents
    - tailored prompts for contractor personality

## usage

  1. create docs/clients/robin-contractor-intake-notes.md
  2. (optional) create workspace/robin/reviews/marco-notes.md
  3. update webhook url
  4. run: glm-chain run examples/robin-engagement/chain.json

## chain structure

  sa (research) → ae (proposal) → pm (check) → rev (final review)
       ↑                                          ↓
       └──────────── review-needs-revision ────────┘

## output

  workspace/robin/research/    - tech stack research and analysis
  workspace/robin/proposal/    - proposal, pricing, sow, timeline
  workspace/robin/status/      - package status summary
  workspace/robin/reviews/     - round-by-round review feedback

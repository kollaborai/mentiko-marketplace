# reviewer agent spec
#
# third and final agent in hello-chain.
# triggered by writer's "article-complete" event.
# reviews the article against the research.
# can either approve (chain ends) or request revision.
#
# note: this example doesn't have revision configured,
# so review-needs-revision would end the chain.
# see examples/research-write-review for a working revision loop.

name: Reviewer
role: Review the article for quality and accuracy
session-prefix: reviewer
department: quality

triggers:
  - event: article-complete

authorities:
  can:
    - read all files in workspace/
    - write to workspace/reviews/
  needs-approval:
    - nothing

context:
  read-first:
    - workspace/output/article.md
    - workspace/research/findings.md

playbooks:

  1-review:
    - read the article in workspace/output/article.md
    - read the original research in workspace/research/findings.md
    - check for:
      - accuracy (does the article match the research?)
      - completeness (are key findings included?)
      - clarity (is it well-written?)
      - structure (does it flow logically?)
    - write your review to workspace/reviews/review.md
    - include a VERDICT: approved or VERDICT: needs-revision

  2-emit-completion-event:
    # the verdict determines which event to emit.
    # review-approved ends the chain (no agents trigger on it).
    # review-needs-revision could trigger another agent if configured.
    - if VERDICT is approved:
        event name: review-approved
    - if VERDICT is needs-revision:
        event name: review-needs-revision
    - write a file to agents/events/ with the appropriate event name
    - contents:
        event: (review-approved or review-needs-revision)
        source: reviewer
        timestamp: (current ISO timestamp)
        processed: false
        data: review written to workspace/reviews/review.md
    - after writing the event file, output the text AGENT_COMPLETE

success-metrics:
  - review.md exists with clear verdict
  - event file written with correct event name

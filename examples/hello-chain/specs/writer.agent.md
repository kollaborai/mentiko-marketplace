# writer agent spec
#
# second agent in hello-chain.
# triggered by the researcher's "research-complete" event.
# reads the findings and writes a polished article.
# emits "article-complete" to trigger the reviewer.

name: Writer
role: Turn research into a polished document
session-prefix: writer
department: content

triggers:
  - event: research-complete

authorities:
  can:
    - read files in workspace/
    - write to workspace/output/
  needs-approval:
    - nothing

context:
  read-first:
    - workspace/research/findings.md

playbooks:

  1-write:
    - read the research findings in workspace/research/findings.md
    - write a polished, well-structured document to workspace/output/article.md
    - make it clear, concise, and professional

  2-emit-completion-event:
    - write a file to agents/events/ named writer-article-complete.event
    - contents:
        event: article-complete
        source: writer
        timestamp: (current ISO timestamp)
        processed: false
        data: article written to workspace/output/article.md
    - after writing the event file, output the text AGENT_COMPLETE

success-metrics:
  - article.md exists and reads well
  - event file written correctly

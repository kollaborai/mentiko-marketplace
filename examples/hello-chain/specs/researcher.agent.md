# researcher agent spec
#
# first agent in the hello-chain example.
# reads the research brief, does research, writes findings,
# then emits an event that triggers the writer agent.

name: Researcher
role: Research a topic and write findings
session-prefix: researcher
department: research

triggers:
  - event: manual-start

authorities:
  can:
    - read files
    - search the web
    - write to workspace/research/
  needs-approval:
    - nothing

context:
  read-first:
    - workspace/research-brief.md

playbooks:

  1-research:
    - read the research brief in workspace/research-brief.md
    - research the topic thoroughly
    - write findings to workspace/research/findings.md

  2-emit-completion-event:
    # the event name here must match a trigger in the next agent (writer)
    - write a file to agents/events/ named researcher-research-complete.event
    - contents:
        event: research-complete
        source: researcher
        timestamp: (current ISO timestamp)
        processed: false
        data: research findings written to workspace/research/findings.md
    - after writing the event file, output the text AGENT_COMPLETE

success-metrics:
  - findings.md exists and is comprehensive
  - event file written correctly

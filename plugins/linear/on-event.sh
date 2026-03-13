#!/bin/bash
# Linear sync plugin — on-event handler
# Creates Linear issues when chain events fire.
# Env vars: PLUGIN_API_KEY, PLUGIN_TEAM_ID, PLUGIN_EVENT_TYPE,
#           PLUGIN_CHAIN_ID, PLUGIN_RUN_ID, PLUGIN_AGENT_ID

set -euo pipefail

API_KEY="${PLUGIN_API_KEY:-}"
TEAM_ID="${PLUGIN_TEAM_ID:-}"
EVENT_TYPE="${PLUGIN_EVENT_TYPE:-unknown}"
CHAIN_ID="${PLUGIN_CHAIN_ID:-unknown}"
RUN_ID="${PLUGIN_RUN_ID:-}"
AGENT_ID="${PLUGIN_AGENT_ID:-}"

if [[ -z "$API_KEY" ]]; then
    echo "  [linear] error: PLUGIN_API_KEY not set"
    exit 1
fi

LINEAR_API="https://api.linear.app/graphql"

# build title + body based on event type
case "$EVENT_TYPE" in
    chain-completed)
        TITLE="[mentiko] Chain '${CHAIN_ID}' completed"
        BODY="Chain \`${CHAIN_ID}\` completed successfully.${RUN_ID:+

Run ID: \`${RUN_ID}\`}"
        STATE_NAME="Done"
        ;;
    chain-stopped)
        TITLE="[mentiko] Chain '${CHAIN_ID}' failed"
        BODY="Chain \`${CHAIN_ID}\` stopped unexpectedly.${RUN_ID:+

Run ID: \`${RUN_ID}\`}${AGENT_ID:+
Last agent: \`${AGENT_ID}\`}"
        STATE_NAME="Cancelled"
        ;;
    agent-completed)
        TITLE="[mentiko] Agent '${AGENT_ID}' completed in '${CHAIN_ID}'"
        BODY="Agent \`${AGENT_ID}\` completed in chain \`${CHAIN_ID}\`.${RUN_ID:+

Run ID: \`${RUN_ID}\`}"
        STATE_NAME="Done"
        ;;
    *)
        echo "  [linear] skipping unknown event: $EVENT_TYPE"
        exit 0
        ;;
esac

# resolve team ID if not configured
if [[ -z "$TEAM_ID" ]]; then
    TEAM_RESP=$(curl -s -X POST "$LINEAR_API" \
        -H "Authorization: $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"query":"{ teams { nodes { id name } } }"}' 2>/dev/null)
    TEAM_ID=$(echo "$TEAM_RESP" | jq -r '.data.teams.nodes[0].id // ""' 2>/dev/null)
    if [[ -z "$TEAM_ID" ]]; then
        echo "  [linear] error: could not resolve team ID — set PLUGIN_TEAM_ID"
        exit 1
    fi
fi

# resolve workflow state ID
STATE_RESP=$(curl -s -X POST "$LINEAR_API" \
    -H "Authorization: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg tid "$TEAM_ID" --arg sname "$STATE_NAME" \
        '{query: "query($teamId:String!,$name:String!){workflowStates(filter:{team:{id:{eq:$teamId}},name:{eq:$name}}){nodes{id}}}",
          variables: {teamId: $tid, name: $sname}}')" 2>/dev/null)
STATE_ID=$(echo "$STATE_RESP" | jq -r '.data.workflowStates.nodes[0].id // ""' 2>/dev/null)

# create issue via GraphQL
MUTATION='mutation($input:IssueCreateInput!){issueCreate(input:$input){success issue{id identifier url}}}'
INPUT=$(jq -nc \
    --arg title "$TITLE" \
    --arg teamId "$TEAM_ID" \
    --arg description "$BODY" \
    --arg stateId "${STATE_ID:-}" \
    'if $stateId != "" then
       {title:$title,teamId:$teamId,description:$description,stateId:$stateId}
     else
       {title:$title,teamId:$teamId,description:$description}
     end')

RESPONSE=$(curl -s -X POST "$LINEAR_API" \
    -H "Authorization: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg q "$MUTATION" --argjson v "{\"input\":$INPUT}" '{query:$q,variables:$v}')" 2>/dev/null)

SUCCESS=$(echo "$RESPONSE" | jq -r '.data.issueCreate.success // false' 2>/dev/null)
ISSUE_URL=$(echo "$RESPONSE" | jq -r '.data.issueCreate.issue.url // ""' 2>/dev/null)
ISSUE_ID=$(echo "$RESPONSE" | jq -r '.data.issueCreate.issue.identifier // ""' 2>/dev/null)

if [[ "$SUCCESS" == "true" ]]; then
    echo "  [linear] created issue ${ISSUE_ID}: $ISSUE_URL"
else
    ERROR=$(echo "$RESPONSE" | jq -r '.errors[0].message // "unknown error"' 2>/dev/null)
    echo "  [linear] error creating issue: $ERROR"
    exit 1
fi

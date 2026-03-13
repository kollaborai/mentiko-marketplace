#!/bin/bash
# Slack notification plugin — on-event handler
# Called by plugin-runner.sh when a matching event fires.
# Env vars provided: PLUGIN_EVENT_TYPE, PLUGIN_CHAIN_ID, PLUGIN_RUN_ID,
#                   PLUGIN_WEBHOOK_URL, PLUGIN_CHANNEL, PLUGIN_NOTIFY_ON

set -euo pipefail

WEBHOOK_URL="${PLUGIN_WEBHOOK_URL:-}"
CHANNEL="${PLUGIN_CHANNEL:-}"
EVENT_TYPE="${PLUGIN_EVENT_TYPE:-unknown}"
CHAIN_ID="${PLUGIN_CHAIN_ID:-unknown}"
RUN_ID="${PLUGIN_RUN_ID:-}"
NOTIFY_ON="${PLUGIN_NOTIFY_ON:-all}"

# check filter
if [[ "$NOTIFY_ON" != "all" && "$NOTIFY_ON" != "$EVENT_TYPE" ]]; then
    exit 0
fi

if [[ -z "$WEBHOOK_URL" ]]; then
    echo "  [notify-slack] error: PLUGIN_WEBHOOK_URL not set"
    exit 1
fi

# build message
case "$EVENT_TYPE" in
    chain-completed)
        icon=":white_check_mark:"
        text="Chain *${CHAIN_ID}* completed successfully${RUN_ID:+ (run: ${RUN_ID})}"
        ;;
    chain-stopped)
        icon=":warning:"
        text="Chain *${CHAIN_ID}* stopped${RUN_ID:+ (run: ${RUN_ID})}"
        ;;
    agent-completed)
        AGENT_ID="${PLUGIN_AGENT_ID:-unknown}"
        icon=":robot_face:"
        text="Agent *${AGENT_ID}* in chain *${CHAIN_ID}* completed"
        ;;
    *)
        icon=":information_source:"
        text="Event *${EVENT_TYPE}* in chain *${CHAIN_ID}*"
        ;;
esac

# build payload
payload=$(jq -nc \
    --arg text "$icon $text" \
    --arg channel "${CHANNEL:-}" \
    'if $channel != "" then {text: $text, channel: $channel} else {text: $text} end')

curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    > /dev/null

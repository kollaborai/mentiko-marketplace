#!/bin/bash
# Custom webhook plugin — on-event handler
# Sends events to any HTTP endpoint

set -euo pipefail

URL="${PLUGIN_URL:-}"
SECRET="${PLUGIN_SECRET:-}"
EVENTS="${PLUGIN_EVENTS:-all}"
EVENT_TYPE="${PLUGIN_EVENT_TYPE:-unknown}"
CHAIN_ID="${PLUGIN_CHAIN_ID:-unknown}"
RUN_ID="${PLUGIN_RUN_ID:-}"

# check filter
if [[ "$EVENTS" != "all" && "$EVENTS" != "$EVENT_TYPE" ]]; then
    exit 0
fi

if [[ -z "$URL" ]]; then
    echo "  [custom-webhook] error: PLUGIN_URL not set"
    exit 1
fi

# build payload
payload=$(jq -nc \
    --arg event_type "$EVENT_TYPE" \
    --arg chain_id "$CHAIN_ID" \
    --arg run_id "${RUN_ID:-}" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
        event_type: $event_type,
        chain_id: $chain_id,
        run_id: $run_id,
        timestamp: $timestamp
    }')

# Send webhook
curl -s -X POST "$URL" \
    -H "Content-Type: application/json" \
    ${SECRET:+-H "X-Webhook-Signature: $SECRET"} \
    -d "$payload" \
    > /dev/null

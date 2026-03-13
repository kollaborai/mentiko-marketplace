#!/bin/bash
# PagerDuty alerts plugin — on-event handler
# Triggers incidents when chains fail (chain-stopped event).
# Env vars: PLUGIN_ROUTING_KEY, PLUGIN_SEVERITY, PLUGIN_EVENT_TYPE,
#           PLUGIN_CHAIN_ID, PLUGIN_RUN_ID

set -euo pipefail

ROUTING_KEY="${PLUGIN_ROUTING_KEY:-}"
SEVERITY="${PLUGIN_SEVERITY:-error}"
EVENT_TYPE="${PLUGIN_EVENT_TYPE:-unknown}"
CHAIN_ID="${PLUGIN_CHAIN_ID:-unknown}"
RUN_ID="${PLUGIN_RUN_ID:-}"

if [[ -z "$ROUTING_KEY" ]]; then
    echo "  [pagerduty] error: PLUGIN_ROUTING_KEY not set"
    exit 1
fi

# Only trigger on chain-stopped (failure)
if [[ "$EVENT_TYPE" != "chain-stopped" ]]; then
    exit 0
fi

SUMMARY="Chain '${CHAIN_ID}' failed${RUN_ID:+ (run: ${RUN_ID})}"

payload=$(jq -nc \
    --arg routing_key "$ROUTING_KEY" \
    --arg severity "$SEVERITY" \
    --arg summary "$SUMMARY" \
    --arg dedup_key "mentiko-${CHAIN_ID}" \
    '{
        routing_key: $routing_key,
        event_action: "trigger",
        dedup_key: $dedup_key,
        payload: {
            summary: $summary,
            severity: $severity,
            source: "mentiko"
        }
    }')

RESPONSE=$(curl -s -o /tmp/pd-response.json -w "%{http_code}" \
    -X POST "https://events.pagerduty.com/v2/enqueue" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null)

if [[ "$RESPONSE" == "202" ]]; then
    DEDUP_KEY=$(jq -r '.dedup_key // ""' /tmp/pd-response.json 2>/dev/null)
    echo "  [pagerduty] incident triggered: $DEDUP_KEY"
else
    MSG=$(jq -r '.message // "unknown error"' /tmp/pd-response.json 2>/dev/null)
    echo "  [pagerduty] error (HTTP $RESPONSE): $MSG"
    rm -f /tmp/pd-response.json
    exit 1
fi
rm -f /tmp/pd-response.json

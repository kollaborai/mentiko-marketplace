#!/bin/bash
# Email notification plugin — on-event handler
# Uses the mentiko web API to send a transactional email.
# Env vars: PLUGIN_TO, PLUGIN_EVENT_TYPE, PLUGIN_CHAIN_ID, PLUGIN_RUN_ID,
#           PLUGIN_NOTIFY_ON, BETTER_AUTH_URL (base URL for API)

set -euo pipefail

TO="${PLUGIN_TO:-}"
EVENT_TYPE="${PLUGIN_EVENT_TYPE:-unknown}"
CHAIN_ID="${PLUGIN_CHAIN_ID:-unknown}"
RUN_ID="${PLUGIN_RUN_ID:-}"
NOTIFY_ON="${PLUGIN_NOTIFY_ON:-all}"
BASE_URL="${BETTER_AUTH_URL:-http://localhost:3000}"

# check filter
if [[ "$NOTIFY_ON" != "all" && "$NOTIFY_ON" != "$EVENT_TYPE" ]]; then
    exit 0
fi

if [[ -z "$TO" ]]; then
    echo "  [notify-email] error: PLUGIN_TO not set"
    exit 1
fi

case "$EVENT_TYPE" in
    chain-completed)
        subject="[mentiko] Chain '${CHAIN_ID}' completed"
        body="Your Mentiko chain '${CHAIN_ID}' completed successfully.${RUN_ID:+\n\nRun ID: ${RUN_ID}}"
        ;;
    chain-stopped)
        subject="[mentiko] Chain '${CHAIN_ID}' stopped"
        body="Your Mentiko chain '${CHAIN_ID}' has stopped.${RUN_ID:+\n\nRun ID: ${RUN_ID}}"
        ;;
    *)
        subject="[mentiko] Event: ${EVENT_TYPE}"
        body="Chain '${CHAIN_ID}' triggered event: ${EVENT_TYPE}"
        ;;
esac

# call the web API (internal, no auth needed from same host)
curl -s -X POST "${BASE_URL}/api/email/send" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg to "$TO" --arg subject "$subject" --arg body "$body" \
        '{to:$to, subject:$subject, text:$body}')" \
    > /dev/null 2>&1 || true

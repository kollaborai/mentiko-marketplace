---
id: shell-script
name: Shell Script
format: text
category: cli
tags: [bash, shell, script, automation, devops]
description: >
  A generated shell script with metadata about its variables, purpose, and
  permissions. Produced by agents that write automation scripts, deploy helpers,
  or setup/teardown scripts.
author: mentiko
version: 1.0
schema:
  type: object
  properties:
    shebang:
      type: string
      description: interpreter directive (first line of script)
    description:
      type: string
      description: what the script does, written as a one-paragraph comment
    variables:
      type: array
      description: configurable variables at the top of the script
      items:
        type: object
        properties:
          name:
            type: string
            description: variable name (UPPER_CASE by convention)
          default:
            type: string
            description: default value, or empty string if no default
          required:
            type: boolean
            description: if true, script exits with error when unset
          description:
            type: string
            description: what this variable controls
        required: [name, default, required, description]
    permissions:
      type: string
      description: chmod permissions string (e.g. 755, 644, 700)
    content:
      type: string
      description: full script content as a string (including shebang)
  required: [shebang, description, variables, permissions, content]
validation_rules:
  - shebang must start with #!
  - permissions must be a valid chmod octal string (3 digits, 0-7 each)
  - content must start with the same shebang string
  - variables with required=true must have an unset check in content (${VAR:?} or explicit guard)
  - description must be non-empty
related_artifacts:
  - command-output
  - deployment-manifest
  - config-file
---

## metadata

```json
{
  "shebang": "#!/usr/bin/env bash",
  "description": "Deploys the mentiko platform build to a remote server over SSH. Pulls the latest artifact from CI, copies it to /opt/mentiko/platform-build/, restarts the app container, and verifies it comes up healthy.",
  "permissions": "755",
  "variables": [
    {
      "name": "SERVER_IP",
      "default": "74.207.252.96",
      "required": false,
      "description": "IP address or hostname of the target server"
    },
    {
      "name": "DEPLOY_USER",
      "default": "root",
      "required": false,
      "description": "SSH user for the deployment connection"
    },
    {
      "name": "ARTIFACT_URL",
      "default": "",
      "required": true,
      "description": "URL to the platform build artifact (tar.gz from CI)"
    },
    {
      "name": "DEPLOY_DIR",
      "default": "/opt/mentiko/platform-build",
      "required": false,
      "description": "Remote directory where the build artifact is unpacked"
    }
  ],
  "content": "#!/usr/bin/env bash\nset -euo pipefail\n\n# Deploys the mentiko platform build to a remote server over SSH.\n# Pulls the latest artifact from CI, copies it to /opt/mentiko/platform-build/,\n# restarts the app container, and verifies it comes up healthy.\n\nSERVER_IP=\"${SERVER_IP:-74.207.252.96}\"\nDEPLOY_USER=\"${DEPLOY_USER:-root}\"\nARTIFACT_URL=\"${ARTIFACT_URL:?ARTIFACT_URL is required}\"\nDEPLOY_DIR=\"${DEPLOY_DIR:-/opt/mentiko/platform-build}\"\n\nSSH_TARGET=\"${DEPLOY_USER}@${SERVER_IP}\"\nTMP_ARTIFACT=\"/tmp/platform-build-$(date +%s).tar.gz\"\n\necho \"[deploy] downloading artifact...\"\ncurl -fsSL \"$ARTIFACT_URL\" -o \"$TMP_ARTIFACT\"\n\necho \"[deploy] copying to ${SSH_TARGET}:${DEPLOY_DIR}\"\nssh \"$SSH_TARGET\" \"mkdir -p ${DEPLOY_DIR}\"\nscp \"$TMP_ARTIFACT\" \"${SSH_TARGET}:/tmp/platform-build.tar.gz\"\nrm -f \"$TMP_ARTIFACT\"\n\necho \"[deploy] extracting and restarting...\"\nssh \"$SSH_TARGET\" bash -s <<'REMOTE'\n  set -euo pipefail\n  cd /opt/mentiko\n  tar -xzf /tmp/platform-build.tar.gz -C platform-build/ --strip-components=1\n  rm -f /tmp/platform-build.tar.gz\n  docker compose -f docker-compose.production.yml restart app\n  sleep 5\n  STATUS=$(docker compose -f docker-compose.production.yml ps --format json | jq -r '.[] | select(.Service==\"app\") | .State')\n  if [ \"$STATUS\" != \"running\" ]; then\n    echo \"ERROR: app container is $STATUS after restart\" >&2\n    exit 1\n  fi\n  echo \"[deploy] app is running\"\nREMOTE\n\necho \"[deploy] done. verifying health endpoint...\"\nHTTP_STATUS=$(curl -s -o /dev/null -w \"%{http_code}\" \"https://mentiko.com/api/health\")\nif [ \"$HTTP_STATUS\" != \"200\" ]; then\n  echo \"ERROR: health check returned HTTP $HTTP_STATUS\" >&2\n  exit 1\nfi\necho \"[deploy] health check passed (HTTP 200). deployment complete.\"\n"
}
```

## script content (formatted for readability)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Deploys the mentiko platform build to a remote server over SSH.
# Pulls the latest artifact from CI, copies it to /opt/mentiko/platform-build/,
# restarts the app container, and verifies it comes up healthy.

SERVER_IP="${SERVER_IP:-74.207.252.96}"
DEPLOY_USER="${DEPLOY_USER:-root}"
ARTIFACT_URL="${ARTIFACT_URL:?ARTIFACT_URL is required}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/mentiko/platform-build}"

SSH_TARGET="${DEPLOY_USER}@${SERVER_IP}"
TMP_ARTIFACT="/tmp/platform-build-$(date +%s).tar.gz"

echo "[deploy] downloading artifact..."
curl -fsSL "$ARTIFACT_URL" -o "$TMP_ARTIFACT"

echo "[deploy] copying to ${SSH_TARGET}:${DEPLOY_DIR}"
ssh "$SSH_TARGET" "mkdir -p ${DEPLOY_DIR}"
scp "$TMP_ARTIFACT" "${SSH_TARGET}:/tmp/platform-build.tar.gz"
rm -f "$TMP_ARTIFACT"

echo "[deploy] extracting and restarting..."
ssh "$SSH_TARGET" bash -s <<'REMOTE'
  set -euo pipefail
  cd /opt/mentiko
  tar -xzf /tmp/platform-build.tar.gz -C platform-build/ --strip-components=1
  rm -f /tmp/platform-build.tar.gz
  docker compose -f docker-compose.production.yml restart app
  sleep 5
  STATUS=$(docker compose -f docker-compose.production.yml ps --format json | jq -r '.[] | select(.Service=="app") | .State')
  if [ "$STATUS" != "running" ]; then
    echo "ERROR: app container is $STATUS after restart" >&2
    exit 1
  fi
  echo "[deploy] app is running"
REMOTE

echo "[deploy] done. verifying health endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://mentiko.com/api/health")
if [ "$HTTP_STATUS" != "200" ]; then
  echo "ERROR: health check returned HTTP $HTTP_STATUS" >&2
  exit 1
fi
echo "[deploy] health check passed (HTTP 200). deployment complete."
```

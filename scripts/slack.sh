#!/usr/bin/env bash
# Notification wrapper. Posts to a Slack incoming webhook channel.
# Usage: bash scripts/slack.sh "<message>"  (or pipe via stdin)
# Falls back to appending to DAILY-SUMMARY.md if SLACK_WEBHOOK_URL unset.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
FALLBACK="$ROOT/DAILY-SUMMARY.md"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

if [[ $# -gt 0 ]]; then
    msg="$*"
else
    msg="$(cat)"
fi

if [[ -z "${msg// /}" ]]; then
    echo "usage: bash scripts/slack.sh \"<message>\"" >&2
    exit 1
fi

stamp="$(date '+%Y-%m-%d %H:%M %Z')"

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
    {
        printf '\n---\n## %s (fallback — Slack not configured)\n%s\n' \
            "$stamp" "$msg"
    } >> "$FALLBACK"
    echo "[slack fallback] appended to DAILY-SUMMARY.md"
    exit 0
fi

payload="$(python3 -c "
import json, sys
print(json.dumps({'text': sys.argv[1]}))
" "$msg")"

curl -fsS -X POST \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "$SLACK_WEBHOOK_URL"
echo

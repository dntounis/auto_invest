#!/usr/bin/env bash
# Notification wrapper. Posts to a Telegram bot's chat via Bot API.
# Usage: bash scripts/telegram.sh "<message>"  (or pipe via stdin)
# Falls back to appending to DAILY-SUMMARY.md if TELEGRAM_BOT_TOKEN or
# TELEGRAM_CHAT_ID is unset.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
FALLBACK="$ROOT/DAILY-SUMMARY.md"

update_heartbeat() {
    local hb="$ROOT/memory/HEARTBEAT.md"
    if [[ -f "$hb" ]]; then
        local now
        now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        # Replace any existing "last_telegram:" line; append if absent.
        if grep -q "^last_telegram: " "$hb"; then
            python3 - "$hb" "$now" <<'PY'
import sys, re
path, now = sys.argv[1], sys.argv[2]
with open(path) as f:
    txt = f.read()
new = re.sub(r"^last_telegram: .*$", f"last_telegram: {now}", txt, flags=re.MULTILINE)
with open(path, "w") as f:
    f.write(new)
PY
        else
            echo "last_telegram: $now" >> "$hb"
        fi
    fi
}

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
    echo "usage: bash scripts/telegram.sh \"<message>\"" >&2
    exit 1
fi

stamp="$(date '+%Y-%m-%d %H:%M %Z')"

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    {
        printf '\n---\n## %s (fallback — Telegram not configured)\n%s\n' \
            "$stamp" "$msg"
    } >> "$FALLBACK"
    echo "[telegram fallback] appended to DAILY-SUMMARY.md"
    update_heartbeat
    exit 0
fi

payload="$(python3 -c "
import json, sys
print(json.dumps({
    'chat_id': sys.argv[1],
    'text': sys.argv[2],
    'disable_web_page_preview': True,
}))
" "$TELEGRAM_CHAT_ID" "$msg")"

curl -fsS -X POST \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
echo
update_heartbeat

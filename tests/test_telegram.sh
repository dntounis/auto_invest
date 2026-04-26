#!/usr/bin/env bash
# Tests for scripts/telegram.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp
TMPHOME="$(mktemp -d tests/.tmp/tg.XXXXXX)"

echo "test_telegram.sh"

# Test 1: fallback path writes to DAILY-SUMMARY.md when bot creds unset
start_test "fallback writes to DAILY-SUMMARY.md when TELEGRAM_BOT_TOKEN/CHAT_ID unset"
(
    cd "$TMPHOME"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
    bash scripts/telegram.sh "hello world" >/dev/null 2>&1
)
rc=$?
assert_exit_code 0 "$rc"
assert_file_exists "$TMPHOME/DAILY-SUMMARY.md"
body="$(cat "$TMPHOME/DAILY-SUMMARY.md")"
assert_contains "$body" "hello world"
assert_contains "$body" "fallback — Telegram not configured"

# Test 2: fallback also triggered when only one of the two is set
start_test "fallback triggers when only TELEGRAM_BOT_TOKEN is set (CHAT_ID missing)"
TMP_PARTIAL="$(mktemp -d tests/.tmp/tg.XXXXXX)"
(
    cd "$TMP_PARTIAL"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export TELEGRAM_BOT_TOKEN="dummy:token"
    unset TELEGRAM_CHAT_ID
    bash scripts/telegram.sh "partial config" >/dev/null 2>&1
)
rc=$?
assert_exit_code 0 "$rc"
assert_file_exists "$TMP_PARTIAL/DAILY-SUMMARY.md"
body_partial="$(cat "$TMP_PARTIAL/DAILY-SUMMARY.md")"
assert_contains "$body_partial" "partial config"
assert_contains "$body_partial" "fallback — Telegram not configured"

# Test 3: payload escaping handles awkward characters via fallback path
start_test "fallback preserves multi-line markdown content verbatim"
TMP2="$(mktemp -d tests/.tmp/tg.XXXXXX)"
(
    cd "$TMP2"
    cp -r "$ROOT/scripts" .
    unset TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
    msg=$'*EOD Apr 27* (paper)\nEquity: $10,012.40 (+0.12% day)\nNotes: "test" `code`'
    bash scripts/telegram.sh "$msg" >/dev/null 2>&1
)
body2="$(cat "$TMP2/DAILY-SUMMARY.md")"
assert_contains "$body2" "EOD Apr 27"
assert_contains "$body2" "Equity: \$10,012.40"
assert_contains "$body2" '"test"'
assert_contains "$body2" '`code`'
rm -rf tests/.tmp/tg.*

print_summary

#!/usr/bin/env bash
# Tests for scripts/slack.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp
TMPHOME="$(mktemp -d tests/.tmp/slack.XXXXXX)"

echo "test_slack.sh"

# Test 1: fallback path writes to DAILY-SUMMARY.md when webhook unset
start_test "fallback writes to DAILY-SUMMARY.md when SLACK_WEBHOOK_URL unset"
(
    cd "$TMPHOME"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset SLACK_WEBHOOK_URL
    bash scripts/slack.sh "hello world" >/dev/null 2>&1
)
rc=$?
assert_exit_code 0 "$rc"
assert_file_exists "$TMPHOME/DAILY-SUMMARY.md"
body="$(cat "$TMPHOME/DAILY-SUMMARY.md")"
assert_contains "$body" "hello world"
assert_contains "$body" "fallback — Slack not configured"

# Test 2: payload escaping handles awkward characters via fallback path
start_test "fallback preserves multi-line markdown content verbatim"
TMP2="$(mktemp -d tests/.tmp/slack.XXXXXX)"
(
    cd "$TMP2"
    cp -r "$ROOT/scripts" .
    unset SLACK_WEBHOOK_URL
    msg=$'*EOD Apr 27* (paper)\nEquity: $10,012.40 (+0.12% day)\nNotes: "test" `code`'
    bash scripts/slack.sh "$msg" >/dev/null 2>&1
)
body2="$(cat "$TMP2/DAILY-SUMMARY.md")"
assert_contains "$body2" "EOD Apr 27"
assert_contains "$body2" "Equity: \$10,012.40"
assert_contains "$body2" '"test"'
assert_contains "$body2" '`code`'
rm -rf tests/.tmp/slack.*

print_summary

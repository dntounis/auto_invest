#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp

echo "test_perplexity.sh"

# Test 1: exits 3 with stderr warning if PERPLEXITY_API_KEY unset
start_test "exits 3 when PERPLEXITY_API_KEY is unset"
TMP1="$(mktemp -d tests/.tmp/ppx.XXXXXX)"
out=$(
    cd "$TMP1"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset PERPLEXITY_API_KEY
    bash scripts/perplexity.sh "anything" 2>&1
)
rc=$?
assert_exit_code 3 "$rc"
assert_contains "$out" "PERPLEXITY_API_KEY not set"

# Test 2: exits 1 with usage hint if no query passed
start_test "exits 1 with usage when called with no args"
TMP2="$(mktemp -d tests/.tmp/ppx.XXXXXX)"
out=$(
    cd "$TMP2"
    cp -r "$ROOT/scripts" .
    rm -f .env
    bash scripts/perplexity.sh 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage"

rm -rf tests/.tmp/ppx.*
print_summary

#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp

echo "test_alpaca.sh"

# Test 1: refuses to run if ALPACA_API_KEY unset
start_test "exits 1 when ALPACA_API_KEY unset"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset ALPACA_API_KEY ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT TRADING_ENABLED
    bash scripts/alpaca.sh account 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "ALPACA_API_KEY"

# Test 2: refuses to run if ALPACA_SECRET_KEY unset
start_test "exits 1 when ALPACA_SECRET_KEY unset"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy"
    unset ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT TRADING_ENABLED
    bash scripts/alpaca.sh account 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "ALPACA_SECRET_KEY"

# Test 3: refuses to run if ALPACA_ENDPOINT unset (no defaulting to live URL)
start_test "exits 1 when ALPACA_ENDPOINT unset (no implicit live default)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    unset ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT TRADING_ENABLED
    bash scripts/alpaca.sh account 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "ALPACA_ENDPOINT"

# Test 4: refuses to run if ALPACA_DATA_ENDPOINT unset
start_test "exits 1 when ALPACA_DATA_ENDPOINT unset"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    unset ALPACA_DATA_ENDPOINT TRADING_ENABLED
    bash scripts/alpaca.sh account 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "ALPACA_DATA_ENDPOINT"

# Test 5: kill-switch refuses 'order' when TRADING_ENABLED != true
start_test "exits 4 on 'order' subcommand when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="false"
    bash scripts/alpaca.sh order '{"symbol":"X","qty":"1","side":"buy","type":"market","time_in_force":"day"}' 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"

# Test 6: kill-switch also refuses cancel-all
start_test "exits 4 on cancel-all when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED=""
    bash scripts/alpaca.sh cancel-all 2>&1
)
rc=$?
assert_exit_code 4 "$rc"

# Test 7: prints usage on bad subcommand
start_test "exits 1 with usage on bad subcommand"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    bash scripts/alpaca.sh nonsense 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "Usage"

rm -rf tests/.tmp/alp.*
print_summary

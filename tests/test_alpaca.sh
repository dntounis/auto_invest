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

# Test 8: trailing-stop subcommand gated by TRADING_ENABLED
start_test "exits 4 on trailing-stop when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh trailing-stop XLE 5 10 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"

# Test 9: trailing-stop with missing args
start_test "exits 1 on trailing-stop with missing args"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="true"
    bash scripts/alpaca.sh trailing-stop 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: trailing-stop"

# Test: replace-stop subcommand gated by TRADING_ENABLED
start_test "exits 4 on replace-stop when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh replace-stop dummy-id XLE 5 7 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"

# Test: replace-stop with missing args
start_test "exits 1 on replace-stop with missing args"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="true"
    bash scripts/alpaca.sh replace-stop 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: replace-stop"

# Test: activities does NOT require TRADING_ENABLED (read-only)
start_test "activities works without TRADING_ENABLED (read-only subcommand)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    # Use bogus keys so the curl call fails with auth error, not exits 4
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh activities 2>&1
)
rc=$?
# Must NOT be exit 4 (kill-switch) and must NOT show "Usage:" (subcommand should be recognized)
if [[ "$rc" == "4" ]]; then
    fail "activities was kill-switch-gated but should be read-only"
else
    pass
fi
assert_not_contains "$out" "Usage: bash scripts/alpaca.sh"

# Test: bars does NOT require TRADING_ENABLED (read-only)
start_test "bars works without TRADING_ENABLED (read-only subcommand)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh bars SPY 2>&1
)
rc=$?
if [[ "$rc" == "4" ]]; then
    fail "bars was kill-switch-gated but should be read-only"
else
    pass
fi
assert_not_contains "$out" "Usage: bash scripts/alpaca.sh"

# Test: bars with missing symbol exits 1
start_test "exits 1 on bars with missing symbol"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    bash scripts/alpaca.sh bars 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: bars"

# Test: scale-out subcommand gated by TRADING_ENABLED
start_test "exits 4 on scale-out when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh scale-out XLE 5 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"

# Test: scale-out with missing args exits 1
start_test "exits 1 on scale-out with missing args"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="true"
    bash scripts/alpaca.sh scale-out 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: scale-out"

# Test: dtc is a read-only subcommand — allowed even with the kill switch off
start_test "dtc is read-only (not blocked by TRADING_ENABLED=false)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="false"
    bash scripts/alpaca.sh dtc 2>&1
)
# Not refused by the kill switch, AND not fallen through to the unknown-subcommand
# usage branch (which is how this test fails before the case arm exists).
assert_not_contains "$out" "REFUSED"
assert_not_contains "$out" "Usage: bash scripts/alpaca.sh"

# Test: dtc appears in the usage line
start_test "dtc listed in usage"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    bash scripts/alpaca.sh bogus-subcommand 2>&1
)
assert_contains "$out" "dtc"

# The next several tests mirror the parser embedded in `alpaca.sh dtc` rather than
# invoking it, because the real subcommand curls Alpaca first and these must run
# offline with no credentials. The mirrored block is the parser's CONTRACT under
# test — if you change the parser in alpaca.sh, change it here too. Keep the two
# byte-identical; that coupling is the point, not an accident. (Only the pipe
# prefix differs: alpaca.sh feeds it `printf '%s' "$resp" | CURL_RC="$curl_rc"`,
# the tests feed it `echo ... | CURL_RC=0` to simulate a successful HTTP call.)
#
# `CURL_RC` is how the parser learns whether the transport succeeded: a non-"0"
# value means the curl itself failed and NOTHING is known, which must surface as
# source=error — never as source=unavailable, which Rule 14 reads as "field
# legitimately absent, derive locally" and would be a fail-open on a live account.

# Test: the dtc parser reports source=unavailable when the field is absent from an
# otherwise successful response (the benign paper-endpoint case)
start_test "dtc parser: successful call, absent field → source unavailable"
out=$(echo '{"equity":"10000","cash":"2000"}' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "unavailable"'
assert_contains "$out" '"daytrade_count": null'

# Test: the dtc parser reports source=api when the field is present
start_test "dtc parser: present field → source api"
out=$(echo '{"equity":"10000","daytrade_count":3}' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "api"'
assert_contains "$out" '"daytrade_count": 3'

# Test: the dtc parser falls back to unavailable (no traceback) on a
# non-integer-parseable string value, e.g. "3.0"
start_test "dtc parser: non-integer-parseable string (3.0) → source unavailable, no traceback"
out=$(echo '{"daytrade_count":"3.0"}' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "unavailable"'
assert_contains "$out" '"daytrade_count": null'
assert_not_contains "$out" "Traceback"

# Test: the dtc parser falls back to unavailable (no traceback) on a
# non-integer-parseable string value, e.g. "N/A"
start_test "dtc parser: non-integer-parseable string (N/A) → source unavailable, no traceback"
out=$(echo '{"daytrade_count":"N/A"}' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "unavailable"'
assert_contains "$out" '"daytrade_count": null'
assert_not_contains "$out" "Traceback"

# Test: the dtc parser accepts an integer-string value (Alpaca sometimes
# stringifies numerics), pinning the coercion behaviour
start_test "dtc parser: integer-string field (\"3\") → source api"
out=$(echo '{"daytrade_count":"3"}' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "api"'
assert_contains "$out" '"daytrade_count": 3'

# Test: a successful HTTP call whose body is not JSON at all (an HTML error page,
# a truncated proxy response) is a transport-level failure, NOT an absent field.
start_test "dtc parser: non-JSON body → source error"
out=$(echo '<html>502 Bad Gateway</html>' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "error"'
assert_contains "$out" '"daytrade_count": null'
assert_not_contains "$out" "Traceback"

# Test: an empty body from a 200 (or a JSON scalar rather than an object) is also
# an error, not an absent field.
start_test "dtc parser: empty body → source error"
out=$(printf '' | CURL_RC=0 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "error"'
assert_not_contains "$out" "Traceback"

# Test: a non-zero curl status wins over anything in the body. Even a perfectly
# well-formed cached/partial payload must not be reported as `api` or
# `unavailable` when the HTTP call itself failed.
start_test "dtc parser: non-zero curl status → source error even with a valid body"
out=$(echo '{"equity":"10000","daytrade_count":0}' | CURL_RC=22 python3 -c '
import json,os,sys
raw = sys.stdin.read()
if os.environ.get("CURL_RC") != "0":
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
try:
    d = json.loads(raw)
except Exception:
    d = None
if not isinstance(d, dict):
    print(json.dumps({"daytrade_count": None, "source": "error"}))
    raise SystemExit(0)
v = d.get("daytrade_count")
try:
    n = int(v)
except (TypeError, ValueError):
    n = None
if n is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": n, "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "error"'
assert_not_contains "$out" '"source": "api"'
assert_not_contains "$out" '"source": "unavailable"'

# Test: dtc's contract is total — a curl failure (bad creds, no network, 5xx)
# must still exit 0 with a well-formed payload, never let `set -euo pipefail`
# propagate curl's nonzero status. This is what lets a caller running under its
# own `set -e` (Task 4's routines) branch on `source` instead of dying at the
# call site. The payload MUST be source=error, not source=unavailable: the call
# failed, so nothing is known, and Rule 14 must block sells rather than derive a
# structurally-zero local count.
start_test "dtc: transport failure exits 0 with source=error (not unavailable)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    # Bogus creds so the real Alpaca endpoint (or any reachable stand-in)
    # rejects the request — we need an actual curl failure, not a mock.
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh dtc 2>&1
)
rc=$?
assert_exit_code 0 "$rc"
assert_contains "$out" '"source": "error"'
assert_not_contains "$out" '"source": "unavailable"'

rm -rf tests/.tmp/alp.*
print_summary

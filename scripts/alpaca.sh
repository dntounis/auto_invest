#!/usr/bin/env bash
# Alpaca API wrapper. All trading API calls go through here.
# Usage: bash scripts/alpaca.sh <subcommand> [args...]
#
# Read-only subcommands (always allowed):
#   account, positions, position SYM, quote SYM, orders [status]
#
# State-changing subcommands (gated by TRADING_ENABLED="true"):
#   order '<json>', cancel ORDER_ID, cancel-all, close SYM, close-all

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        [[ -z "${!key+x}" ]] && export "$key"="$value"
    done < "$ENV_FILE"
fi

# Required env vars — fail loudly, never silently default to live URLs.
: "${ALPACA_API_KEY:?ALPACA_API_KEY not set in environment}"
: "${ALPACA_SECRET_KEY:?ALPACA_SECRET_KEY not set in environment}"
: "${ALPACA_ENDPOINT:?ALPACA_ENDPOINT not set in environment (set to https://paper-api.alpaca.markets/v2 for paper, https://api.alpaca.markets/v2 for live)}"
: "${ALPACA_DATA_ENDPOINT:?ALPACA_DATA_ENDPOINT not set in environment (typically https://data.alpaca.markets/v2)}"

API="$ALPACA_ENDPOINT"
DATA="$ALPACA_DATA_ENDPOINT"

H_KEY="APCA-API-KEY-ID: $ALPACA_API_KEY"
H_SEC="APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY"

cmd="${1:-}"
shift || true

# Kill-switch helper for state-changing subcommands.
require_trading_enabled() {
    if [[ "${TRADING_ENABLED:-false}" != "true" ]]; then
        echo "REFUSED: TRADING_ENABLED is not 'true' (current: '${TRADING_ENABLED:-unset}'). Set TRADING_ENABLED=true to allow this subcommand." >&2
        exit 4
    fi
}

case "$cmd" in
    account)
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/account"
        ;;
    positions)
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/positions"
        ;;
    position)
        sym="${1:?usage: position SYM}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/positions/$sym"
        ;;
    quote)
        sym="${1:?usage: quote SYM}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$DATA/stocks/$sym/quotes/latest"
        ;;
    orders)
        status="${1:-open}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/orders?status=$status"
        ;;
    order)
        require_trading_enabled
        body="${1:?usage: order '<json>'}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
    cancel)
        require_trading_enabled
        oid="${1:?usage: cancel ORDER_ID}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/orders/$oid"
        ;;
    cancel-all)
        require_trading_enabled
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/orders"
        ;;
    close)
        require_trading_enabled
        sym="${1:?usage: close SYM}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/positions/$sym"
        ;;
    close-all)
        require_trading_enabled
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/positions"
        ;;
    scale-out)
        require_trading_enabled
        sym="${1:?usage: scale-out SYM QTY}"
        qty="${2:?usage: scale-out SYM QTY}"
        body=$(python3 -c "
import json, sys
print(json.dumps({
    'symbol': sys.argv[1],
    'qty': sys.argv[2],
    'side': 'sell',
    'type': 'market',
    'time_in_force': 'day',
}))" "$sym" "$qty")
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
    trailing-stop)
        require_trading_enabled
        sym="${1:?usage: trailing-stop SYM QTY TRAIL_PCT}"
        qty="${2:?usage: trailing-stop SYM QTY TRAIL_PCT}"
        trail="${3:?usage: trailing-stop SYM QTY TRAIL_PCT}"
        body=$(python3 -c "
import json, sys
print(json.dumps({
    'symbol': sys.argv[1],
    'qty': sys.argv[2],
    'side': 'sell',
    'type': 'trailing_stop',
    'trail_percent': sys.argv[3],
    'time_in_force': 'gtc',
    'extended_hours': False,
}))" "$sym" "$qty" "$trail")
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
    replace-stop)
        require_trading_enabled
        oid="${1:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        sym="${2:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        qty="${3:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        trail="${4:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        # Cancel existing stop. If it already fired or doesn't exist, Alpaca returns 422 — accept.
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/orders/$oid" || true
        body=$(python3 -c "
import json, sys
print(json.dumps({
    'symbol': sys.argv[1],
    'qty': sys.argv[2],
    'side': 'sell',
    'type': 'trailing_stop',
    'trail_percent': sys.argv[3],
    'time_in_force': 'gtc',
    'extended_hours': False,
}))" "$sym" "$qty" "$trail")
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
    activities)
        # Read-only — no kill-switch gate.
        # Optional first arg: date (YYYY-MM-DD). Defaults to today in America/Chicago.
        date_filter="${1:-$(TZ=America/Chicago date +%Y-%m-%d)}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" \
            "$API/account/activities?date=$date_filter"
        ;;
    bars)
        # Read-only — no kill-switch gate. Returns the most recent COUNT daily
        # bars (default 60) for moving-average / relative-strength math.
        # Note: Alpaca's bars endpoint returns null with limit-only and yields
        # bars ascending-from-`start`, so we set a `start` window wide enough to
        # cover COUNT trading days (~7 calendar per 5 trading) and trim to the
        # last COUNT bars here, keeping the COUNT arg meaning "last N bars".
        sym="${1:?usage: bars SYM [timeframe] [count]}"
        timeframe="${2:-1Day}"
        count="${3:-60}"
        start=$(python3 -c "import sys,datetime; n=int(sys.argv[1]); print((datetime.date.today()-datetime.timedelta(days=n*2+15)).isoformat())" "$count")
        curl -fsS -H "$H_KEY" -H "$H_SEC" \
            "$DATA/stocks/$sym/bars?timeframe=$timeframe&start=$start&limit=10000&adjustment=all" \
        | python3 -c "
import sys, json
d = json.load(sys.stdin)
bars = d.get('bars') or []
n = int(sys.argv[1])
d['bars'] = bars[-n:]
print(json.dumps(d))" "$count"
        ;;
    *)
        echo "Usage: bash scripts/alpaca.sh <account|positions|position|quote|orders|order|cancel|cancel-all|close|close-all|trailing-stop|replace-stop|activities|bars|scale-out> [args]" >&2
        exit 1
        ;;
esac
echo

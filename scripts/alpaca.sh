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
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
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
    *)
        echo "Usage: bash scripts/alpaca.sh <account|positions|position|quote|orders|order|cancel|cancel-all|close|close-all> [args]" >&2
        exit 1
        ;;
esac
echo

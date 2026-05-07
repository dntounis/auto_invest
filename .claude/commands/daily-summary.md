---
description: End-of-day summary (local mirror of cloud routine; no commit/push)
---

You are running the **daily-summary workflow** locally for v2. Resolve today's
date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

This is a v2 paper run. EOD snapshot + stop placement (Rule 13) + heartbeat check (DECIDED J).

## Step 1 — Read memory for continuity
- Tail of `memory/TRADE-LOG.md` — yesterday's equity (latest EOD snapshot) + today's BUY/EXIT/STOP rows
- Today's `memory/RESEARCH-LOG.md` entry (for pre-market summary in EOD body)

## Step 2 — Pull final state of the day
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
bash scripts/alpaca.sh activities    # for realized P&L from today's closes
```

## Step 3 — Compute metrics
- Day P&L (realized + unrealized vs yesterday's equity)
- Phase P&L (vs $10K Day 0 baseline)
- Trades today: count today's BUY rows + EXIT rows from TRADE-LOG.md → format as `<N opened, K closed>`
- Trades this week: count BUY rows since Monday (cap 3 per Rule 4)

## Step 4 — Place trailing stops for today's new positions (Rule 13, visa-aware)
For each position opened today (entry_date == today, identified from BUY rows
in TRADE-LOG.md committed earlier today by `market-open`) with no existing
trailing stop in `orders open`:
```
TRAIL_PCT=10  # default per Rule 6
bash scripts/alpaca.sh trailing-stop TICKER QTY $TRAIL_PCT
```
Visa-aware: this fires at 15:00 CT = 16:00 ET = NYSE close, so the stop queues in Alpaca's GTC book without firing same-day (`extended_hours=false`).

Append a STOP PLACED row to TRADE-LOG.md per stop placed:
```
### YYYY-MM-DD — STOP PLACED: TICKER trail %N
- Order ID: <from response>
- Trigger reason: routine placement at market close (Rule 13)
- Links to BUY: pm-YYYY-MM-DD-TICKER
```

## Step 5 — Heartbeat check (DECIDED J)
```
LAST_TG=$(grep "^last_telegram: " memory/HEARTBEAT.md | sed 's/last_telegram: //')
NOW=$(date -u +%s)
LAST_S=$(date -u -d "$LAST_TG" +%s 2>/dev/null || python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$LAST_TG'.replace('Z','+00:00')).timestamp()))")
HOURS_SINCE=$(( (NOW - LAST_S) / 3600 ))
```
If `HOURS_SINCE >= 48`, set `HEARTBEAT_PREFIX="Heartbeat: ${HOURS_SINCE}h silence — system alive\n"`. Otherwise empty.

## Step 6 — Append EOD snapshot to `memory/TRADE-LOG.md`
Use the schema at the top of TRADE-LOG.md. v2 positions table is no longer empty; include open positions with current prices, day chg, unrealized P&L, and active stop levels.

## Step 7 — Send ONE Telegram via `telegram.sh`
```
bash scripts/telegram.sh "${HEARTBEAT_PREFIX}*EOD <MMM DD>* (paper)
Equity: \$<X> (<±X%> day, <±X%> phase)
Cash: \$<X>
Trades today: <N opened, K closed>
Open positions: <N tickers> (<sector breakdown>)
Stops placed at close: <K positions>
Pre-market plan today: <decision from today's research log>
Tomorrow: pre-market checks at 6:00 CT"
```

## Step 8 — Skip commit
Local mode does not auto-commit. Review TRADE-LOG.md and HEARTBEAT.md changes, commit by hand if worth keeping.

---
description: Market-open execution (local mirror of cloud routine; no commit/push, kill-switch-gated)
---

You are running the **market-open execution workflow** locally. Resolve today's
date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` — match the cloud routine's
TZ so local entries align with cron-fired entries.

This is a v2 paper run. **Orders may execute** if `TRADING_ENABLED=true` in your
local `.env`. Otherwise the wrapper refuses with exit 4 — that's the kill-switch
working correctly. The cloud routine ALWAYS has TRADING_ENABLED=true in v2.

## Step 1 — Read memory
- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md`
- Today's `memory/RESEARCH-LOG.md` entry (must have pm-YYYY-MM-DD-TICKER IDs; v1-format = stop)
- Tail of `memory/TRADE-LOG.md`

If today's RESEARCH-LOG entry does not exist (e.g., pre-market was not run locally),
STOP with message "market-open $DATE: no RESEARCH-LOG entry found — run /pre-market first".
Do NOT make up trade ideas.

If today's RESEARCH-LOG entry lacks `pm-YYYY-MM-DD-TICKER` IDs, treat it as
v1-format and STOP — do not synthesize IDs.

## Step 2 — Pull state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
```

Idempotency: skip any ticker with an existing today BUY (DECIDED H).

## Step 3 — Apply buy-side gate
Per `TRADING-STRATEGY.md`. Reject ideas where `account.daytrade_count > 1` to
preserve Rule 14 buffer (a buy today + a stop-triggered sell tomorrow could
bump DTC; buffer of 1 keeps us well below the FINRA PDT threshold of 4 day
trades in 5 rolling business days even if a same-day stop fires unexpectedly).

Additional gate checks per idea:
- Total positions after fill ≤ 6
- Trades placed this week (incl. this one) ≤ 3
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- Instrument is a stock (not option/crypto/forex/futures)

## Step 4 — Rank, take top N
Ideas already ranked R:R-desc by pre-market. Take `min(passing, 3 - trades_this_week)`
(trades_this_week from TRADE-LOG.md tally read in Step 1). If the result is zero,
skip to Step 8 with no orders placed.

## Step 5 — Per-idea loop: quote, size, limit
For each selected idea, execute the following sub-steps **in order**:

**5a. Fetch live ask price**

```
bash scripts/alpaca.sh quote TICKER
```

Alpaca's `/stocks/{sym}/quotes/latest` returns:
```json
{"quote": {"ap": <ask_price>, "as": <ask_size>, ...}}
```

Extract `live_ask = response.quote.ap`. The `.ap` field is the correct ask price
field name. Do NOT use `.ask` or `.askPrice` — those are not Alpaca fields.

If `live_ask` is zero or null, skip this idea and log "no ask price available".

**5b. Extract trail percent**

Parse the RESEARCH-LOG entry for this idea for a line matching:
```
planned trail percent: N
```
(where N is a number). Set `trail_pct = N`.

If that line is absent, or N is 0 or blank, set `trail_pct = 10` (default).
This default prevents division-by-zero in the sizing formula below.

**5c. Compute position size**

```
RISK_PCT=${RISK_PER_TRADE_PCT:-2.0}        # default 2% of equity
MAX_POS_PCT=${MAX_POSITION_PCT:-20}        # default 20% cap
SLIPPAGE_PCT=${MAX_ENTRY_SLIPPAGE_PCT:-0.10}

dollar_risk       = (RISK_PCT / 100) * account.equity          # e.g., 200 on 10k
stop_distance_pct = trail_pct / 100                            # e.g., 0.10
shares_by_risk    = floor(dollar_risk / (live_ask * stop_distance_pct))
shares_by_cap     = floor((MAX_POS_PCT / 100) * account.equity / live_ask)
shares            = min(shares_by_risk, shares_by_cap)
```

If shares < 1, skip this idea (cap or risk budget too small).

**5d. Compute limit price**

```
limit_price = round(live_ask * (1 + SLIPPAGE_PCT / 100), 2)
```

After all ideas are processed, proceed to Step 6 with each idea's
`(shares, limit_price)` pair already computed.

## Step 6 — Place limit orders
For each idea with a valid `(shares, limit_price)` from Step 5:

1. Place the order:
```
ORDER_JSON=$(python3 -c "
import json
print(json.dumps({
    'symbol': 'TICKER',
    'qty': SHARES,
    'side': 'buy',
    'type': 'limit',
    'limit_price': str(LIMIT_PRICE),
    'time_in_force': 'day',
}))")
bash scripts/alpaca.sh order "$ORDER_JSON"
```

2. Poll for fill: every 5s, up to 12 times (60s ceiling).
   `bash scripts/alpaca.sh orders open` and look for the order ID.
   - If the order is no longer in the open list, it filled — record as filled.
   - If still open after 12 checks (60s), leave it; note as PENDING.

DO NOT place a trailing stop here — Rule 13 says daily-summary places it at market close.

DO NOT cancel positions or close anything — Rule 15 (no same-day exits, no closes, no cancels) applies even though this routine never sells.

## Step 7 — Append to `memory/TRADE-LOG.md` (locally)
**Filled orders** — append a full TRADE row using the schema at the top of TRADE-LOG.md:

```
### YYYY-MM-DD — TRADE: TICKER side=buy qty=N
- Entry: $X
- Stop level: pending (placed at daily-summary T 15:00 CT per Rule 13)
- Sector: <GICS sector or ETF sector classification>
- Thesis: <copied from RESEARCH-LOG entry>
- Catalyst: pm-YYYY-MM-DD-TICKER (link to RESEARCH-LOG entry)
- Target: $X (R:R X:1)
- Realized P&L: n/a (open position)
```

**Pending (not-yet-filled) orders** — one-line note only (NO full TRADE row).
Daily-summary upgrades to a full TRADE row after fill confirmation at EOD:

```
- PENDING YYYY-MM-DD TICKER: limit order placed @ $LIMIT_PRICE, not yet filled as of market-open run
```

## Step 8 — Telegram
1 msg per fill or reject. Silent if no orders attempted.

## Step 9 — Skip commit
Local mode does not auto-commit. Review changes; commit by hand if worth keeping.

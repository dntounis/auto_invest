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
- Trades placed this week (incl. this one) ≤ 5
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- **(v3, satellite only)** ETF-core market value stays ≥ 45% of deployed equity after the fill (skip + log if breached)
- **(v3, satellite only)** ≤ 2 satellite names in this idea's GICS sector after the fill
- Instrument is a stock (not option/crypto/forex/futures)

## Step 4 — Rank, take top N
Ideas already ranked R:R-desc by pre-market. Take `min(passing, 5 - trades_this_week)` *(v3 — cap 5)*
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

If `live_ask` is zero or null (stale quote), apply the **v3 fallback** before skipping:
read prior close via `bash scripts/alpaca.sh bars TICKER 1Day 2`. If a `bid` exists
within `MAX_ENTRY_SLIPPAGE_PCT` of prior close, set `limit_price = round(prior_close
* (1 + MAX_ENTRY_SLIPPAGE_PCT/100), 2)`, use `prior_close` as the sizing `price`, and
place a day-TIF limit (Telegram-note non-URGENT). Else skip and log "no ask price available".

**5b. Extract trail percent**

Parse the RESEARCH-LOG entry for this idea for a line matching:
```
planned trail percent: N
```
(where N is a number). Set `trail_pct = N`.

If that line is absent, or N is 0 or blank, set `trail_pct = 10` (default).
This default prevents division-by-zero in the sizing formula below.

**5c. Compute position size (deterministic helper — v3)**

Use the idea's **stop width** as `stop-frac` (parse `stop width N%` from the pm idea
line; fall back to `trail_pct / 100`). Then:

```
SIZE_JSON=$(python3 scripts/sizing.py size \
    --equity "$EQUITY" --price "$LIVE_ASK" --stop-frac "$STOP_FRAC")
```

Parse `shares`/`clamped`. If `clamped == "floor_skip"` or `shares < 1`, skip the idea
and log the reason. Same risk-parity logic (2% equity risk, clamped to the 20% cap),
now deterministic and unit-tested.

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
- Tier: core|satellite *(v3 — copied from the pm idea line)*
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

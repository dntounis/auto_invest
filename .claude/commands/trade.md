---
description: Manual one-off trade entry (subject to all v2 buy-side gates and risk rules)
---

You are running a **manual trade entry**. Args from the user: `TICKER`, optional `THESIS`, optional `STOP_PCT` (default 10).

**Mode guard (v3.4).** `TRADING_MODE` (default `paper`) and `ALPACA_ENDPOINT` must
agree — `paper` ↔ `paper-api.alpaca.markets`, `live` ↔ `api.alpaca.markets` without
`paper-api`. Never infer one from the other. If they disagree or `TRADING_MODE` is
neither `paper` nor `live`, stop and tell the user rather than guessing — this
command places a real order at Step 5, so a half-done switch here is the
highest-stakes place it could happen: there is no cron log to cross-check a
manual run against. If `TRADING_MODE=live`, prefix any Telegram message you send
with `🔴 LIVE `. Also compute `MODE_LABEL` — `(paper)` when `TRADING_MODE` is
`paper`, `(live)` when `live` — and use it for the account-label suffix in any
message body; never hardcode `(paper)`.

ALL routine gates apply: Buy-Side Gate from `TRADING-STRATEGY.md`, Rule 14 daytrade_count pre-flight, Rule 15 same-day skip (not relevant here since this IS a same-day buy — but no sell will happen until T+1 since stop placement is deferred to daily-summary per Rule 13).

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md` (Buy-Side Gate)
- `memory/TRADE-LOG.md` tail (week's trade count, current positions)
- Today's `memory/RESEARCH-LOG.md` if it exists (for sector context — optional)

## Step 2 — Pull state
```
bash scripts/alpaca.sh account     # equity, cash, long_market_value
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
```
Bind `EQUITY = account.equity` and `LONG_MARKET_VALUE = account.long_market_value`
(or the sum of position `market_value`s) — Step 4c needs both for the deployment
headroom.

## Step 3 — Apply Buy-Side Gate
Per `TRADING-STRATEGY.md`. ALL must pass:
- Total positions after this fill ≤ 6
- Trades this week (incl. this one) ≤ 5 *(Rule 4 — raised from 3 in v3)*
- Position cost ≤ 20% equity
- Position cost ≤ available cash
- **Rule 14 pre-flight — `DTC <= 1`** *(v3.3 — resolve via `bash scripts/alpaca.sh dtc`; **never** read `account.daytrade_count` raw. The paper endpoint omits the field, so the raw read silently evaluated to nothing and this gate never ran.)* Use midday Step 2's resolution:
  - `source=api` → `DTC = daytrade_count`, `DTC_SOURCE=api`.
  - `source=unavailable` (the call succeeded, the field is simply absent) → derive locally over the last 5 business days, `DTC_SOURCE=local`: `bash scripts/alpaca.sh activities` per business day is the primary evidence (symbols with a buy fill AND a sell fill on the same activity date), the TRADE-LOG same-day buy/sell scan is corroboration, take the `max`. Rules 13/15 make this structurally 0 — a non-zero result is itself URGENT-worthy: send the alert and treat it as a genuine DTC.
  - `source=error` (the `dtc` HTTP call itself failed — nothing is known) or `DTC_SOURCE=none` → **block any sell** (this command issues none) and send a Telegram URGENT. The BUY may still proceed, logged as a degraded state, on the same reasoning as market-open's buy-side gate: a buy cannot itself create a day trade, because Rule 13 defers the stop to market close. Never fall back to the local derivation on `error`.
  Buffer rationale: buy today + a possible stop-triggered sell tomorrow could bump DTC; a buffer of 1 keeps us 2 below the PDT threshold of 4. Log `Rule 14 DTC: <N> (source=api|local|none|error)` in the TRADE-LOG row at Step 6.
- TICKER is a stock (not option/crypto/forex/futures)

If any check fails, STOP and report which gate tripped.

## Step 4 — Quote, sizing, limit
a. Fetch live quote: `bash scripts/alpaca.sh quote TICKER`. Parse `.quote.ap` (Alpaca's ask field, NOT `.ask` or `.askPrice`). Call this `live_ask`.

b. `trail_pct = STOP_PCT or 10`. Must be > 0 (else division-by-zero in sizing).

c. Risk-parity sizing — **call the unit-tested sizer; never size inline** *(v3.3)*.
The old inline formula defaulted `MAX_POSITION_PCT` to **20**, so a manual entry
reintroduced the very oversizing defect v3.3 fixed (`sizing.py` targets 16% so five
clips fit under the 85% deployment ceiling), and it ignored the deployment ceiling
entirely. Use the same call market-open Step 5c uses:
```
STOP_FRAC=$(python3 -c "print($trail_pct/100)")   # or the user's STOP_PCT/100
HEADROOM=$(python3 -c "print(0.85*$EQUITY - $LONG_MARKET_VALUE)")   # from Step 2
SIZE_JSON=$(python3 scripts/sizing.py size \
    --equity "$EQUITY" --price "$live_ask" --stop-frac "$STOP_FRAC" \
    --headroom "$HEADROOM")
```
Parse `shares`, `cost`, `clamped`.
- `clamped == "floor_skip"` or `shares < 1` → skip and report why (the risk budget,
  the 16% cap, or the remaining headroom left too little to clear the 5%-of-equity
  minimum — a dust position is worse than none).
- `clamped == "headroom"` → the clip was deliberately shrunk to fit the remaining
  deployment room. Normal; proceed and say so in the report.
- `clamped == "cap"` or `"none"` → full risk-parity or 16%-capped clip; proceed.

If `HEADROOM <= 0` the book is already at or past the Rule 5 ceiling — no buy of any
size is permitted; stop and report it.

d. `limit = round(live_ask * (1 + MAX_ENTRY_SLIPPAGE_PCT/100), 2)` (default 0.10 = 0.10%).

## Step 5 — Place limit order
```
bash scripts/alpaca.sh order '{"symbol":"TICKER","qty":SHARES,"side":"buy","type":"limit","limit_price":"X","time_in_force":"day"}'
```
Poll fill: every 5s, up to 12 times (60s).

DO NOT place a trailing stop — Rule 13: stops go to daily-summary at market close.

## Step 6 — Append BUY trade row to TRADE-LOG.md
```
### YYYY-MM-DD — TRADE: TICKER side=buy qty=N
- Entry: $X
- Stop level: pending (placed at daily-summary T 15:00 CT per Rule 13)
- Sector: <GICS sector or ETF classification>
- Thesis: <user-supplied or "manual entry, no thesis given">
- Catalyst: manual-YYYY-MM-DD-TICKER
- Target: <user-supplied or "n/a (manual)">
- Realized P&L: n/a (open position)
- Rule 14 DTC: <N> (source=api|local|none|error) — buy-side buffer check only, no sells in this command
```
The `manual-` prefix distinguishes hand-entered trades from `pm-` routine ideas.
The `Rule 14 DTC:` line is the literal token the weekly review greps for to confirm
the gate genuinely ran *(v3.3)* — write it on every manual entry.

## Step 7 — Telegram one fill confirmation
```
bash scripts/telegram.sh "*MANUAL FILL MMM DD* ${MODE_LABEL} — TICKER N shares @ \$X (manual entry)"
```

## Step 8 — Stop placement deferred
This command does NOT place a trailing stop. Next daily-summary run at 15:00 CT will place it (Rule 13).

## Step 9 — Skip commit
Local mode does not auto-commit.

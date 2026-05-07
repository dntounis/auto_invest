---
description: Midday position management (local mirror of cloud routine; no commit/push)
---

You are running the **midday position-management workflow** locally. Resolve
today's date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

This is a v2 paper run. Sells may execute if `TRADING_ENABLED=true`.

## Visa-aware gates (READ FIRST)
- **Rule 14 (pre-flight):** Read `account.daytrade_count` (DTC) BEFORE any sell. If `DTC >= 2`, abort all sells; print which sells you would have done; exit. Re-check DTC between sells in a sector-kill loop.
- **Rule 15 (same-day skip):** Positions with `entry_date == today` are read-only. Do not act on them.
- **Rule 13 (no new stops):** This routine only TIGHTENS existing stops via `replace-stop`. Daily-summary places new stops at market close.

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md` (sell-side rules + Rules 13–15)
- Tail of `memory/TRADE-LOG.md` (positions with their `entry_date`, `Sector:` field, and initial stop info; recent EXIT rows for Rule 10 sector tally)

## Step 2 — Pull state
```
bash scripts/alpaca.sh account     # capture daytrade_count as DTC
bash scripts/alpaca.sh positions   # avg_entry_price + market_value + current_price per position
bash scripts/alpaca.sh orders open # open trailing-stop orders (for replace-stop trail_percent parse)
```

If `DTC >= 2`, abort all sells; print intended actions; exit.

On DTC >= 2 abort, also write a one-block note to memory/TRADE-LOG.md (locally; not committed):

```
### YYYY-MM-DD — MIDDAY ABORT: daytrade_count=N
- Reason: Rule 14 pre-flight tripped (DTC >= 2)
- Pending actions skipped: <list>
- Resolution: manual human review required
```

## Step 3 — Filter actionable
For each position:
- Determine `entry_date` from TRADE-LOG.md latest BUY row for this ticker
- Compute `unrealized_pl_pct = (current_price - avg_entry_price) / avg_entry_price * 100`. **Use `current_price` from the `positions` response, NOT `quote.ap`** (live ask would systematically skew P&L).

Drop positions where `entry_date == today` (Rule 15). Drop positions held in Alpaca but missing from TRADE-LOG.md (memory desync). Send Telegram URGENT: 'midday $DATE: position TICKER held in Alpaca but missing from TRADE-LOG.md, manual review required'. Then skip the position (treat as non-actionable). The remaining list is "actionable".

## Step 4 — Decide actions (in priority order, first match wins)
1. ≤ -7% → hard-close (Rule 7)
2. ≥ +20% → replace-stop trail=5 (Rule 8)
3. ≥ +15% AND current trail > 7 (parse `trail_percent` from `orders open` response for this ticker) → replace-stop trail=7 (Rule 8)
4. Sector-kill (Rule 10): scan most recent 20 EXIT rows OR last 30 calendar days (whichever is shorter); if this position's sector has 2 consecutive losses (negative `Realized P&L`, same `Sector:` tag, no winner between them) → close all actionable positions in that sector in a batch. Evaluate sector-kill ONCE per unique sector.
5. Else: no action.

## Step 5 — Execute
```
bash scripts/alpaca.sh close TICKER                                  # hard-close / sector-kill
bash scripts/alpaca.sh replace-stop ORDER_ID TICKER QTY NEW_TRAIL    # tighten
```
After each individual sell, refresh DTC:
```
DTC=$(bash scripts/alpaca.sh account | python3 -c "import json,sys; print(json.load(sys.stdin)['daytrade_count'])")
```
Abort if DTC reaches 2.

## Step 6 — Append action rows to `memory/TRADE-LOG.md` (locally)

For each completed sell, append an EXIT trade row:
```
### YYYY-MM-DD — TRADE: TICKER side=sell qty=N
- Exit: $X
- Stop level: <was: trail N% / fixed $X — fired: yes/no/manual>
- Sector: <copied from original BUY row>
- Thesis: <closed via Rule 7 / 8 / 10 — one phrase>
- Catalyst: <links back to original BUY's pm-YYYY-MM-DD-TICKER>
- Target: <was $X, R:R X:1>
- Realized P&L: $X (X.X%)
```

For each stop tightening, append a STOP UPDATE row:
```
### YYYY-MM-DD — STOP UPDATE: TICKER trail %X -> %Y
- Trigger: +15% gain / +20% gain (Rule 8)
- New stop order ID: <id from replace-stop response>
```

## Step 7 — Telegram
Silent if no actions and DTC < 2. Otherwise one summary message with prefix conventions:
- `*MIDDAY HARD-CLOSE MMM DD* (paper)` — URGENT, hard-close
- `*MIDDAY SECTOR-KILL MMM DD* (paper)` — URGENT, sector kill
- `*MIDDAY STOP UPDATE MMM DD* (paper)` — informational, stop tightening
- `*MIDDAY ABORT MMM DD* (paper)` — URGENT, DTC abort

## Step 8 — Skip commit
Local mode does not auto-commit.

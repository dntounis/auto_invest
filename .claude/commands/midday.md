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

## Step 3 — Filter actionable
For each position:
- Determine `entry_date` from TRADE-LOG.md latest BUY row for this ticker
- Compute `unrealized_pl_pct = (current_price - avg_entry_price) / avg_entry_price * 100`. **Use `current_price` from the `positions` response, NOT `quote.ap`** (live ask would systematically skew P&L).

Drop positions where `entry_date == today` (Rule 15). Drop positions held in Alpaca but missing from TRADE-LOG.md (memory desync — flag as needing manual review). The remaining list is "actionable".

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
Refresh DTC between sells. Abort if DTC reaches 2.

## Step 6 — Append action rows to `memory/TRADE-LOG.md` (locally)
- EXIT row schema: same as BUY but `side=sell`, with `Exit:` (not `Entry:`), `Realized P&L: $X (X.X%)`. **Include the `Sector:` field copied from the original BUY row** so the sector-kill lookback works on EXIT rows.
- STOP UPDATE row schema: `### YYYY-MM-DD — STOP UPDATE: TICKER trail %X -> %Y` with `Trigger:` and `New stop order ID:` lines.

## Step 7 — Telegram
Silent if no actions and DTC < 2. Otherwise one summary message with prefix conventions:
- `*MIDDAY HARD-CLOSE MMM DD* (paper)` — URGENT, hard-close
- `*MIDDAY SECTOR-KILL MMM DD* (paper)` — URGENT, sector kill
- `*MIDDAY STOP UPDATE MMM DD* (paper)` — informational, stop tightening
- `*MIDDAY ABORT MMM DD* (paper)` — URGENT, DTC abort

## Step 8 — Skip commit
Local mode does not auto-commit.

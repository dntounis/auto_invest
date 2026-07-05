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

## Step 4 — Decide actions
Determine each position's `tier` (`core`|`satellite`) from its BUY row `Tier:` field (default `core`). Hard-close (1) is exclusive; ladder (2) may scale-out AND tighten; decay (3) only fires on losers below entry.

1. ≤ -7% → hard-close (Rule 7). Exclusive.
2. **Profit ladder (Rule 8, v3):**
   ```
   # HWM-gain from the position's open trailing-stop order (the same order you read for
   # OID/QTY/trail_percent). hwm is the peak price Alpaca tracked since the stop was placed.
   # HWM_GAIN = (hwm - avg_entry_price) / avg_entry_price * 100
   # If the position has no open trailing stop yet (no hwm), omit --hwm-pct entirely.
   LADDER_JSON=$(python3 scripts/sizing.py ladder --tier "$TIER" --unrealized-pct "$UPCT" --hwm-pct "$HWM_GAIN")
   ```
   `--hwm-pct` makes `target_trail_pct` reflect the highest tier the position reached
   intraday (catching a post-midday spike that reversed), while `scaleouts_due` stays on
   the current-price `$UPCT` (v3.2). When no open stop exists, drop `--hwm-pct` — the call
   is backward-compatible and behaves exactly as before.
   - **Scale-out (deterministic — v3.1):** count existing `SCALE-OUT` rows for this
     position in TRADE-LOG.md → `SO_DONE`. Then ask the sizer for the qty (never
     compute it inline):
     ```
     Parse `scaleouts_due` from the `LADDER_JSON` computed above → `SCALEOUTS_DUE`.
     SO_JSON=$(python3 scripts/sizing.py scaleout --cur-qty "$CUR_QTY" \
         --scaleouts-due "$SCALEOUTS_DUE" --scaleouts-done "$SO_DONE")
     ```
     - `reason == "ok"` (sell_qty ≥ 1): this is a SELL — re-check Rule 14 `DTC` (< 2),
       then `bash scripts/alpaca.sh scale-out TICKER $SELL_QTY`. Log a `SCALE-OUT` row.
     - `reason == "sub_unit"`: a scale-out is owed but the lot is too small to trim and
       still leave a runner (e.g. a 2-share $900 satellite where 1/3 < 1 share, but the
       min-1-share rule already applies at qty ≥ 2, so `sub_unit` only hits qty 1).
       **Do NOT sell.** Log `SCALE-OUT-DEFERRED TICKER reason=sub_unit` (STEP 6) and rely
       on the same-tier trail-tighten below to capture the gain. No `DTC` impact.
     - `reason == "none_due"`: scale-out already logged for this tier — no action.
   - Tighten: if `target_trail_pct` non-null AND < current open stop trail (never raise, never < 3%) → `replace-stop OID TICKER QTY $target_trail_pct`.
3. **Momentum-decay rotation (Rule 16, v3):** `POS_RET` from `bash scripts/alpaca.sh bars TICKER 1Day 11`, `SPY_RET` from `bash scripts/alpaca.sh bars SPY 1Day 11`, `PRIOR_FLAG` from the latest DECAY-FLAG row for TICKER. `DECAY_JSON=$(python3 scripts/sizing.py decay --unrealized-pct "$UPCT" --pos-ret-10d "$POS_RET" --spy-ret-10d "$SPY_RET" --prior-flag "$PRIOR_FLAG")`. Always log a DECAY-FLAG row. If `rotate==1` and DTC < 2 → `close TICKER` (ROTATE-EXIT). Core ETF also rotates if its sector left the leading quadrant.
4. Sector-kill (Rule 10): scan most recent 20 EXIT rows OR last 30 calendar days (whichever is shorter); if this position's sector has 2 consecutive losses (negative `Realized P&L`, same `Sector:` tag, no winner between them) → close all actionable positions in that sector in a batch. Evaluate sector-kill ONCE per unique sector.
5. Else: no action.

## Step 5 — Execute
```
bash scripts/alpaca.sh close TICKER                                  # hard-close / sector-kill / rotation
bash scripts/alpaca.sh scale-out TICKER $SELL_QTY   # qty from sizing.py scaleout (min-1-share) (reason==ok only)
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
- Trigger: Rule 8 profit ladder, tier=<core|satellite>, unrealized +X%
- New stop order ID: <id from replace-stop response>
```

For each scale-out (v3):
```
### YYYY-MM-DD — SCALE-OUT: TICKER qty=N (scale-out slice, M before)
- Tier: <core|satellite> | Trigger: Rule 8 ladder, +X% (scale-out #K of 2) | Realized P&L on slice: $X
```

For each deferred (sub-unit) scale-out, append instead (no sell occurred):

### YYYY-MM-DD — SCALE-OUT-DEFERRED: TICKER reason=sub_unit
- Tier ladder owed a scale-out but qty too small to leave a runner; trail tightened instead.

For each momentum-decay evaluation (v3 — state for next midday):
```
### YYYY-MM-DD — DECAY-FLAG: TICKER flag=0|1
- unrealized %X | 10-session pos %A vs SPY %B | prior_flag=0|1 | rotate=0|1
```
(A ROTATE-EXIT is logged as a normal sell EXIT row with Thesis "Rule 16 momentum-decay rotation".)

## Step 7 — Telegram
Silent if no actions and DTC < 2. Otherwise one summary message with prefix conventions:
- `*MIDDAY HARD-CLOSE MMM DD* (paper)` — URGENT, hard-close
- `*MIDDAY SECTOR-KILL MMM DD* (paper)` — URGENT, sector kill
- `*MIDDAY ROTATE MMM DD* (paper)` — informational, momentum-decay rotation
- `*MIDDAY SCALE-OUT MMM DD* (paper)` — informational, Rule 8 partial
- `*MIDDAY STOP UPDATE MMM DD* (paper)` — informational, stop tightening
- `*MIDDAY ABORT MMM DD* (paper)` — URGENT, DTC abort

## Step 8 — Skip commit
Local mode does not auto-commit.

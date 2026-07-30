---
description: Midday position management (local mirror of cloud routine; no commit/push)
---

You are running the **midday position-management workflow** locally. Resolve
today's date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

This is a v2 paper run. Sells may execute if `TRADING_ENABLED=true`.

## Visa-aware gates (READ FIRST)
- **Rule 14 (pre-flight):** Resolve `DTC`/`DTC_SOURCE` via `bash scripts/alpaca.sh dtc` (v3.3, see Step 2) BEFORE any sell — never treat an absent field as 0. If `DTC >= 2`, or `DTC_SOURCE` is `none` or `error`, abort all sells and print which sells you would have done. **The abort blocks sells only — it does not end the run** (v3.3): still run Step 3/4's evaluation, still tighten stops via `replace-stop` (a GTC order, not a sell), still write `DECAY-FLAG` rows, and still write Step 6's `- midday $DATE:` cadence line and `Rule 14 DTC:` audit line. Re-check DTC between sells in a sector-kill loop.
- **Rule 15 (same-day skip):** Positions with `entry_date == today` are read-only. Do not act on them.
- **Rule 13 (no new stops):** This routine only TIGHTENS existing stops via `replace-stop`. Daily-summary places new stops at market close.

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md` (sell-side rules + Rules 13–15)
- Tail of `memory/TRADE-LOG.md` (positions with their `entry_date`, `Sector:` field, and initial stop info; recent EXIT rows for Rule 10 sector tally)

## Step 2 — Pull state
```
bash scripts/alpaca.sh dtc         # day-trade count + source (CRITICAL for Rule 14)
bash scripts/alpaca.sh account     # equity
bash scripts/alpaca.sh positions   # avg_entry_price + market_value + current_price per position
bash scripts/alpaca.sh orders open # open trailing-stop orders (for replace-stop trail_percent parse)
```

Resolve Rule 14 via `bash scripts/alpaca.sh dtc` *(v3.3, four sources)*:
- `source=api` → use the value.
- `source=unavailable` (call **succeeded**, field simply absent) → derive locally,
  `source=local`. Broker-first: `bash scripts/alpaca.sh activities` per business day
  over the last 5 business days is the **primary** evidence (count symbols with a buy
  fill AND a sell fill on the same activity date — this is the only thing that sees a
  GTC stop fill, a partial-fill re-entry, or a manual Alpaca-UI action); the
  TRADE-LOG same-day buy+sell / `SCALE-OUT` / `ROTATE-EXIT` scan is corroboration.
  Take `max` of the two; a disagreement is itself URGENT. Structurally 0 under Rules
  13/15 — non-zero from either source is URGENT.
- `source=error` (the `dtc` HTTP call itself failed — nothing is known) → block all
  sells + URGENT. **Never** substitute the local derivation here: it is structurally
  0 and would fail the gate open on a live account.
- TRADE-LOG unreadable for the local fallback → `source=none`, block sells + URGENT.

Never treat an absent field as 0. Log `Rule 14 DTC: <N> (source=...)`.
If `DTC >= 2`, `source=none` or `source=error`, abort sells — but still write Step 6's mandatory
`- midday $DATE:` cadence line first (v3.3 — an abort must not look like a cron
skip to Rule 18's sweep).

On DTC abort, also write a one-block note to memory/TRADE-LOG.md (locally; not
committed) — Step 6's `- midday $DATE:` and `Rule 14 DTC:` lines first, then:

```
### YYYY-MM-DD — MIDDAY ABORT: daytrade_count=N (source=api|local|none|error)
- Reason: Rule 14 pre-flight tripped (DTC >= 2, or source=none|error)
- Pending actions skipped: <list>
- Resolution: manual human review required
```

## Step 3 — Filter actionable
For each position:
- Determine `entry_date` from TRADE-LOG.md latest BUY row for this ticker
- Compute `unrealized_pl_pct = (current_price - avg_entry_price) / avg_entry_price * 100`. **Use `current_price` from the `positions` response, NOT `quote.ap`** (live ask would systematically skew P&L).

Drop positions where `entry_date == today` (Rule 15). Drop positions held in Alpaca but missing from TRADE-LOG.md (memory desync). Send Telegram URGENT: 'midday $DATE: position TICKER held in Alpaca but missing from TRADE-LOG.md, manual review required'. Then skip the position (treat as non-actionable). The remaining list is "actionable".

## Step 4 — Decide actions
Bind **two distinct attributes** per position *(v3.3 — do not conflate them)*:
- `TIER` — portfolio **role**, `core`|`satellite`, from the BUY row's `Tier:` field
  (default `core`). Drives the core floor and satellite caps; recorded in audit rows.
- `LADDER_TIER` — **instrument type**, `etf`|`stock`. The only valid value for
  `sizing.py ladder --tier`; `LADDERS` is keyed on instrument type because a broad
  fund and a single name move differently (etf +4/+7/+10/+15, stock +6/+10/+15/+25).

Derive `LADDER_TIER` from what the instrument **is** (a sector/broad-market fund →
`etf`; one company's shares → `stock`), not from the role. They coincide today only
because every core holding is an ETF; the first core single-stock or satellite ETF
would silently get the wrong ladder and the call would still succeed. Fallback only
if the instrument type is genuinely undeterminable: `core`→`etf`, `satellite`→`stock`
(and mark it as a fallback in the row). Never pass `$TIER` to `--tier`.

Hard-close (1) is exclusive; ladder (2) may scale-out AND tighten; decay (3) only fires on losers below entry.

1. ≤ -7% → hard-close (Rule 7). Exclusive.
2. **Profit ladder (Rule 8, v3):**
   ```
   # HWM-gain from the position's open trailing-stop order (the same order you read for
   # OID/QTY/trail_percent). hwm is the peak price Alpaca tracked since the stop was placed.
   # HWM_GAIN = (hwm - avg_entry_price) / avg_entry_price * 100
   # If the position has no open trailing stop yet (no hwm), omit --hwm-pct entirely.
   #
   # --tier takes LADDER_TIER (instrument type, etf|stock) — never $TIER, the
   # portfolio role, which is not a valid value for this flag.
   LADDER_JSON=$(python3 scripts/sizing.py ladder --tier "$LADDER_TIER" --unrealized-pct "$UPCT" --hwm-pct "$HWM_GAIN")
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
After each individual sell, re-resolve DTC via `bash scripts/alpaca.sh dtc`
(same four-source procedure as Step 2) — never re-read `account.daytrade_count`
directly; the field is absent on paper and a raw subscript raises, silently
leaving DTC empty and fail-open. `source=api` → use the value. `source=unavailable`
→ re-derive locally (Step 2 method: activities-primary, TRADE-LOG corroborating)
and ADD sells already done earlier in this loop (not yet in activities/TRADE-LOG).
`source=error` (the call failed) → abort, never re-derive. Anything else —
unparseable, missing, TRADE-LOG unreadable — is `source=none`: ABORT all remaining
sells in the batch now, URGENT Telegram, **then proceed to Step 6 — do NOT exit**.
Never continue the loop on an empty/unparseable value.

Abort if DTC reaches 2 (any source), or source=none, or source=error.

**A mid-loop abort blocks sells, not the run** *(v3.3 — this path used to say
"commit progress, exit", contradicting the preamble, Step 2 and Rule 14)*. Still
write Step 6's `- midday $DATE:` cadence line and `Rule 14 DTC:` audit line, the
rows already earned (EXIT/`SCALE-OUT` for sells completed before the abort, plus
every stop tightening and `DECAY-FLAG` row), then the Telegram. Exiting instead
would leave no cadence token, so daily-summary's Rule 18 sweep would read a cron
skip, re-run the evaluation and duplicate today's DECAY-FLAG rows (corrupting the
Rule 16 chain), and the weekly audit sweep would report a spurious Rule 14 gap.

## Step 6 — Append action rows to `memory/TRADE-LOG.md` (locally)

**MANDATORY first, on every path, without exception — NO-ACTION days and BOTH
DTC-abort paths (Step 2 pre-flight and Step 5 mid-loop) included (v3.3). No abort
reaches `exit` without passing through this step:**
```
- midday $DATE: <N> sells, <K> scale-outs, <M> stop-tightenings, <P> decay-flags (or "DTC ABORT (Step 2 pre-flight)" / "DTC ABORT (Step 5 mid-loop, K sells before abort)").
```
This is the token daily-summary's Rule 18 sweep looks for; omitting it on a
no-action or abort day makes midday indistinguishable from a cron skip and can
trigger a spurious catch-up re-run that duplicates today's DECAY-FLAG rows.

**Then — the Rule 14 audit line**, even with zero actionable positions
or zero scheduled actions:
```
- Rule 14 DTC: <N> (source=api|local|none|error) (sell attempted: yes|no)
```
Use the last resolved `DTC`/`DTC_SOURCE` (Step 5 mid-loop value if a sell was
attempted, else Step 2's). This is the literal token weekly review greps for to
confirm Rule 14 actually ran — never skip it.

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
- Trigger: Rule 8 profit ladder, tier=<core|satellite>, ladder=<etf|stock>, unrealized +X%
- New stop order ID: <id from replace-stop response>
```

For each scale-out (v3):
```
### YYYY-MM-DD — SCALE-OUT: TICKER qty=N (scale-out slice, M before)
- Tier: <core|satellite> (role) | Ladder: <etf|stock> (passed to --tier) | Trigger: Rule 8 ladder, +X% (scale-out #K of 2) | Realized P&L on slice: $X
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

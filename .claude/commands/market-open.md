---
description: Market-open execution (local mirror of cloud routine; no commit/push, kill-switch-gated)
---

You are running the **market-open execution workflow** locally. Resolve today's
date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` — match the cloud routine's
TZ so local entries align with cron-fired entries.

This is a v2 paper run. **Orders may execute** if `TRADING_ENABLED=true` in your
local `.env`. Otherwise the wrapper refuses with exit 4 — that's the kill-switch
working correctly. The cloud routine ALWAYS has TRADING_ENABLED=true in v2.

**Mode guard (v3.4).** `TRADING_MODE` (default `paper`) and `ALPACA_ENDPOINT` must
agree — `paper` ↔ `paper-api.alpaca.markets`, `live` ↔ `api.alpaca.markets` without
`paper-api`. Never infer one from the other. If they disagree or `TRADING_MODE` is
neither `paper` nor `live`, stop and tell the user rather than guessing. If
`TRADING_MODE=live`, prefix any Telegram message you send with `🔴 LIVE `. Also use
`MODE_LABEL` — `(paper)` when `TRADING_MODE` is `paper`, `(live)` when `live` — for
the account-label suffix in any message body; never hardcode `(paper)`.

## Step 0 — Rule 18: clear pending catch-ups (v3.3)
Scan the last 10 trading days (or last 200 rows) of TRADE-LOG for unresolved
`CATCH-UP PENDING: TICKER` rows — unresolved means no later `CATCH-UP CLEARED` row
for that ticker whose "Resolves..." line names the same pending date (ticker match
alone isn't enough; a ticker can cycle through multiple incidents). Rows older than
the lookback window are flagged via URGENT Telegram, not silently dropped. For each
unresolved row: if no longer held → clear `reason=already-exited`; if the trigger no
longer holds → clear `reason=trigger-no-longer-met` (for `action=scale-out`, re-check
the ladder tier via `sizing.py ladder` against live state — bind `LADDER_TIER`, the
**instrument** type `etf`|`stock` derived from what the symbol is, and pass that to
`--tier`; never the `core`|`satellite` role, which `sizing.py` rejects); else resolve DTC using
midday's Step 5 batch-accumulation procedure (NOT Step 3's buy-side gate — that's
permissive on `source=none`/`source=error`, wrong for a sell) — on `source=unavailable`,
add **only sells already executed earlier in this Step 0 batch whose symbol also has
a buy fill today**, not the raw batch count *(v3.4)*, tracking the raw count
separately as `DTC_CONSERVATIVE`; every Step 0 catch-up sell is aged by construction
(Rule 15), so this addition is normally 0 regardless of batch size — non-zero is
itself URGENT-worthy — abort on `DTC>=2`,
`source=none` or `source=error` (a failed `dtc` call knows nothing — never fall back
to the structurally-zero local derivation),
apply the Rule 15 check, then execute: `close TICKER` for hard-close/rotate-exit/
sector-kill, or `scale-out TICKER $SELL_QTY` with a freshly re-derived qty (never the
stale PENDING qty) for `action=scale-out`. Write the EXIT/SCALE-OUT row, then clear
`reason=executed`. Telegram once per cleared row. Silent if none.

## Step 1 — Read memory
- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md`
- Today's `memory/RESEARCH-LOG.md` entry (must have pm-YYYY-MM-DD-TICKER IDs; v1-format = stop)
- Tail of `memory/TRADE-LOG.md`

If today's RESEARCH-LOG entry does not exist (e.g., pre-market was not run locally),
STOP with message "market-open $DATE: no RESEARCH-LOG entry found — run /pre-market first".
**Before exiting** *(v3.3)*, append the mandatory Market-Open Run row (Step 7 format)
to `memory/TRADE-LOG.md`: `- market-open $DATE: 0 orders placed, 0 filled. HALTED at
Step 1 — no RESEARCH-LOG entry for today. Upstream pre-market failure; no ideas
evaluated.` plus a second line `- Rule 14 DTC: n/a (halted before gate evaluation)`.
Then exit. Do NOT make up trade ideas.

If today's RESEARCH-LOG entry lacks `pm-YYYY-MM-DD-TICKER` IDs, treat it as
v1-format and STOP — do not synthesize IDs. **Before exiting** *(v3.3)*, append the
same two rows, adapted: `- market-open $DATE: 0 orders placed, 0 filled. HALTED at Step 1
— RESEARCH-LOG entry is v1-format, no pm- IDs. Upstream pre-market failure; no ideas
evaluated.` plus `- Rule 14 DTC: n/a (halted before gate evaluation)`. Then exit.

## Step 2 — Pull state
```
bash scripts/alpaca.sh account     # equity, cash, buying_power
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
```

Then compute once for the run *(v3.3)*: `HEADROOM = (EQUITY * 0.85) - LONG_MARKET_VALUE`.
If `HEADROOM <= 0`, no buy of any size is permitted — skip all ideas.

Snapshot, read once from `positions` (+ `Tier:`/`Sector:` on each open BUY row):
`CORE_MV`, `SECTOR_MV[s]`, `POS_COUNT`, `SAT_COUNT[s]`. Running totals for this run,
all starting at 0: `COMMITTED_COST`, `COMMITTED_CORE_MV`, `COMMITTED_SECTOR_MV[s]`,
`COMMITTED_POS`, `COMMITTED_SAT[s]`. Every portfolio-shape gate below evaluates
against **snapshot + committed**, never the bare snapshot — before v3.3 only the
deployment ceiling accumulated, so two satellite ideas could each pass the core
floor individually and breach it jointly (equity $10k, LMV $4k = $3k core + $1k
satellite, two $1.6k satellites: 53.6% each, 41.7% after both).

**Rule 5 re-deployment trigger** *(v3.4)*. Count consecutive prior sessions
closed below the 75% floor by reading `memory/METRICS.jsonl` backwards from the
most recent line, counting `"in_band": false` entries until the first `true`.
`SESSIONS_BELOW_BAND = 0` if the last line is in band, if the file is absent, OR
if the file exists but has zero lines (truncated/first-run — treat like absent,
don't infer a count):
```
REDEPLOY_JSON=$(python3 scripts/sizing.py redeploy \
    --equity "$EQUITY" --lmv "$LONG_MARKET_VALUE" \
    --sessions-below-band "$SESSIONS_BELOW_BAND")
```
When `triggered` is true: the R:R floor for **`tier: core` ideas only** drops to
`rr_floor` (1.5) — satellites stay at 2:1 in every regime — and core ballast adds
size to restore the band (target `restore_dollars`, never overshoot it to fill
headroom). Log `Rule 5 REDEPLOY: armed (deployment X%, N sessions below band,
restore $Y, R:R floor 1.5)` in the Step 7 run row; log `Rule 5 REDEPLOY: not
armed` otherwise. This line must appear on every run — Task 2's metrics record
reads it for `rule5.triggered`.

Idempotency: skip any ticker with an existing today BUY (DECIDED H).

## Step 3 — Apply buy-side gate
Per `TRADING-STRATEGY.md`. Resolve `DTC`/`DTC_SOURCE` via `bash scripts/alpaca.sh dtc`
*(v3.3, same four-source procedure as midday: `api` | `local` | `none` | `error`)*.
Reject ideas where `DTC > 1` to preserve the Rule 14 buffer (a buy today + a
stop-triggered sell tomorrow could bump DTC; buffer of 1 keeps us well below the
FINRA PDT threshold of 4 day trades in 5 rolling business days even if a same-day
stop fires unexpectedly). `source=none` and `source=error` both allow buys but must
be logged as a degraded state — a buy cannot itself create a day trade because Rule
13 defers the stop to market close. This permissiveness is buy-side only; Step 0's
catch-up sells treat both as hard aborts.

Additional gate checks per idea. The four portfolio-shape gates **accumulate**
*(v3.3)* — each uses snapshot + committed. The idea isn't sized yet here, so use a
provisional `position_cost` (the pm idea's planned clip, else
`min(0.16*EQUITY, HEADROOM)`); this is a screen and Step 5c re-asserts all four on
the actual sized cost. Clip-shrink is safe: a headroom-clamped clip only makes these
ratios easier to satisfy, so this is accumulation, not a sizing change.
- Total positions after fill: `POS_COUNT + COMMITTED_POS + 1 ≤ 6` (skip the +1 if already held)
- Trades placed this week (incl. this one) ≤ 5
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- **(v3, satellite only)** ETF-core floor: `deployed_after = LONG_MARKET_VALUE + COMMITTED_COST + position_cost`, `core_after = CORE_MV + COMMITTED_CORE_MV` (a satellite adds nothing to core). Require `core_after / deployed_after ≥ 0.45`; skip + log if breached
- **(v3, satellite only)** `SAT_COUNT[sector] + COMMITTED_SAT[sector] + 1 ≤ 2` satellite names in this idea's GICS sector after the fill ("pending" = committed earlier this run)
- **(v3.1, all ideas)** Sector concentration cap: `sector_after = SECTOR_MV[sector] + COMMITTED_SECTOR_MV[sector] + position_cost`. If `sector_after / deployed_after > 0.50`, skip + log "sector cap: TICKER sector would be X% of deployed (> 50%)".
- **(v3.1, restated v3.3)** Deployment ceiling: no longer a pre-sizing refusal. `HEADROOM` is passed to the sizer in Step 5, which shrinks the clip to fit. Skip outright only if `HEADROOM <= 0`.
- **(v3.2, satellite only)** Macro-binary proximity: read the idea's `macro-window:` tag. If `tier` is `satellite` AND the tag names a Tier-1 binary on T+1/T+2 (anything other than `clear`), skip + log "macro-binary gate: TICKER blocked by <BINARY> at T+N". `tier: core` ideas (tag `n/a (core)`) bypass this check.
- **(v3.4, `rr-relaxed` ideas only)** Stale-trigger re-check: pre-market's trigger
  (~07:00) and this run's Step 2 recompute (live equity/LMV) can disagree — an
  overnight move or fill can put the book back in band. If the idea's line carries
  `rr-relaxed: yes (Rule 5 redeploy)` AND this run's `REDEPLOY_JSON.triggered` is
  `false`, skip + log "Rule 5 REDEPLOY: idea TICKER admitted at 1.5:1 but trigger no
  longer armed at market-open (deployment X%) — skipped". Untagged ideas qualified
  at 2:1 and are unaffected.
- Instrument is a stock (not option/crypto/forex/futures)

## Step 4 — Rank, take top N
Ideas already ranked R:R-desc by pre-market. Take `min(passing, 5 - trades_this_week)` *(v3 — cap 5)*
(trades_this_week from TRADE-LOG.md tally read in Step 1). If the result is zero,
skip to Step 7 (still writes the mandatory Market-Open Run row) with no orders placed.

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

**5c. Compute position size**

Use the idea's **stop width** as `stop-frac` (parse `stop width N%` from the pm idea
line; fall back to `trail_pct / 100`). Then:

```
SIZE_JSON=$(python3 scripts/sizing.py size --equity "$EQUITY" --price "$LIVE_ASK" \
    --stop-frac "$STOP_FRAC" --headroom "$HEADROOM")
```

`clamped == "floor_skip"` or `shares < 1` → skip + log. `clamped == "headroom"` →
clip deliberately shrunk to fit; proceed and log it.

**Re-assert the accumulating gates on the ACTUAL cost, then reserve** *(v3.3)*.
With `cost` now known, redo Step 3's four gates against snapshot + committed:
```
deployed_after = LONG_MARKET_VALUE + COMMITTED_COST + cost
core_after     = CORE_MV + COMMITTED_CORE_MV + (cost if tier == core else 0)
sector_after   = SECTOR_MV[sector] + COMMITTED_SECTOR_MV[sector] + cost

positions:  POS_COUNT + COMMITTED_POS + (0 if already held else 1) <= 6
core floor: core_after / deployed_after >= 0.45            (satellite only)
sat/sector: SAT_COUNT[sector] + COMMITTED_SAT[sector] + 1 <= 2   (satellite only)
sector cap: sector_after / deployed_after <= 0.50
ceiling:    deployed_after / EQUITY <= 0.85                (Rule 5 belt-and-braces)
```
Any failure → skip the idea, log which gate and by how much, reserve nothing. This
is the binding evaluation; Step 3's is a screen. Then reserve, before sizing the
next idea:
```
COMMITTED_COST += cost;  HEADROOM -= cost
COMMITTED_CORE_MV += cost if tier == core else 0
COMMITTED_SECTOR_MV[sector] += cost
COMMITTED_POS += 1  unless already held
COMMITTED_SAT[sector] += 1  if tier == satellite and not already held
```
Must happen here — Step 5 sizes every idea before Step 6 places any order, so a
decrement deferred to order-placement time would never fire and two ideas could
both consume the same headroom *and* both be gated against the same unchanged
core/sector/position snapshot. If a later order is rejected/unfilled in Step 6, the
reservation is simply released for the next session — don't re-size mid-run.

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

DO NOT cancel positions or close anything **in this step**. The ordinary path of
this command places BUY orders only; the single exception is Step 0's Rule 18
catch-up, which sells what a *previous* day's missed midday already owed *(v3.3 —
do not skip Step 0 because "market-open only buys", or the whole recovery path
never fires)*. That exception is visa-safe on both counts: the position was open
at the prior session's close, so it is aged and Rule 15 cannot be breached, and
every catch-up sell carries the full Rule 14 pre-flight (abort on `DTC>=2`,
`source=none` or `source=error`). The pre-flight is enforced at midday,
market-open Step 0, weekly-review and `/trade`.

## Step 7 — Append to `memory/TRADE-LOG.md` (locally)
**MANDATORY on every path — including HOLD and zero-fill.** Always write the run row
first (Rule 18 looks for the literal `- market-open $DATE:` token):

```
## $DATE — Market-Open Run (Day N, <Weekday>, Week W Day D)

- market-open $DATE: <N> orders placed, <K> filled. Pre-market Decision=<TRADE|HOLD>.
  <gate outcomes per idea, HEADROOM, deployment %, core %, sector spread, week budget>
- Rule 14 DTC: <N> (source=api|local|none|error) [conservative: <M>] — <buy-side buffer only, no sells this run | buy-side buffer + Step 0 catch-up: <K> sell(s) executed, each pre-flighted>.
```
Literal `Rule 14 DTC:` token — weekly review greps for it to confirm the gate ran.
`[conservative: <M>]` *(v3.4)* is `DTC_CONSERVATIVE`, the raw sell count from
Step 0's batch, tracked whenever Step 0 ran a local derivation this run; omit when
`source=api` or no local derivation occurred. Always write the line, including the
Step 1 halt copies of this row (use `n/a (halted before gate evaluation)` there
since Step 3's `dtc` call never ran, and omit the bracket too).

**Filled orders** — additionally append a full TRADE row using the schema at the top of TRADE-LOG.md:

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

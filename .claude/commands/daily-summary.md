---
description: End-of-day summary (local mirror of cloud routine; no commit/push)
---

You are running the **daily-summary workflow** locally for v2. Resolve today's
date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

This run executes against whichever account `TRADING_MODE` selects (see the mode
guard below). EOD snapshot + stop placement (Rule 13) + heartbeat check (DECIDED J).

**Mode guard (v3.4).** `TRADING_MODE` (default `paper`) and `ALPACA_ENDPOINT` must
agree — `paper` ↔ `paper-api.alpaca.markets`, `live` ↔ `api.alpaca.markets` without
`paper-api`. Never infer one from the other. If they disagree or `TRADING_MODE` is
neither `paper` nor `live`, stop and tell the user rather than guessing. If
`TRADING_MODE=live`, prefix any Telegram message you send with `🔴 LIVE `. Also use
`MODE_LABEL` — `(paper)` when `TRADING_MODE` is `paper`, `(live)` when `live` — for
the account-label suffix in any message body; never hardcode `(paper)`.

## STEP 0 — Rule 18: cadence sweep (FIRST action, v3.2)

Before pulling state, resolve `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` and verify today's
prior routines logged. On a US market holiday (no session) skip this sweep — the routines
correctly no-op. **A row that is itself, or wraps, a `MISSING ROUTINE` placeholder for
that routine does NOT count as evidence it ran** — for all three checks below.
- **pre-market** → `memory/RESEARCH-LOG.md` MUST have a `$DATE` entry (not a placeholder).
- **market-open** → `memory/TRADE-LOG.md` MUST have a `market-open $DATE` row (not a placeholder).
- **midday** → `memory/TRADE-LOG.md` MUST have a `- midday $DATE:` row (not a placeholder)
  *(v3.3 fix — the old `$DATE — Midday Run` token's real defect wasn't staleness: it's
  also written as a wrapper around daily-summary's own `MISSING ROUTINE: midday`
  placeholder, so it self-satisfied on 2026-07-22, the one genuine skip day.
  `- midday $DATE:` is midday's real per-run line, mandatory on every path per
  `routines/midday.md` STEP 6, and never written by the placeholder path)*.
For each missing routine:
```
bash scripts/telegram.sh "🚨 URGENT $DATE ${MODE_LABEL} — MISSING ROUTINE: <name> did not log today. Investigate cron. (Rule 18)"
```
and append a placeholder to that routine's log:
```
### $DATE — MISSING ROUTINE: <name> (Rule 18 cadence guardrail)
- No <name> entry found for $DATE at daily-summary sweep; cron skip suspected. Investigate.
```

**v3.3 catch-up:** if the missing routine is `midday`, also RUN midday's Step 3+4
evaluation now, applying the same Rule 14 pre-flight (`source=error` counts as
`none`). Execute stop tightenings immediately (`replace-stop` — GTC, no fill
risk, no DTC impact) and always write `DECAY-FLAG` rows (the Rule 16 consecutiveness
state). Do NOT market-sell OR scale-out at the bell — a scale-out is a partial market
sell with the same closing-bell fill risk as a full exit — instead write, per ticker:

```
### $DATE — CATCH-UP PENDING: TICKER action=<hard-close|rotate-exit|sector-kill|scale-out>
- Missed midday $DATE (Rule 18). Sell owed; deferred to next market-open STEP 0.
- Trigger: <condition>
- Qty (scale-out only): <N from sizing.py scaleout — informational, market-open re-derives live>
```

and send an URGENT Telegram. A missing `market-open` gets a placeholder only — the
entry window has closed.

**A Rule 14 abort in this catch-up blocks sells only — never the routine** (v3.3).
It must never skip Step 4 (Rule 13 stop placement) or Step 6 (the EOD snapshot):
placing a stop is not a sell, and daily-summary is the only placer of Rule 13
stops, so exiting early would leave today's new positions permanently unprotected.

Then continue to Step 1. If all three logged, proceed silently.

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
- Trades this week: count BUY rows since Monday (cap 5 per Rule 4 — v3.3 correction; it has been 5 since v3)

## Step 4 — Place trailing stops for today's new positions (Rule 13, visa-aware)
For each position opened today (entry_date == today, identified from BUY rows
in TRADE-LOG.md committed earlier today by `market-open`) with no existing
trailing stop in `orders open`:
```
TRAIL_PCT=10  # v2 always uses 10% (TRADING-STRATEGY.md Rule 6).
              # Pre-market may emit "planned trail percent: N" for sizing purposes,
              # but daily-summary places the canonical 10% trail. Per-position trail
              # customization deferred to v3.
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

**Rule 17 failure handling (v3.1).** If a `trailing-stop` / `replace-stop` call returns
non-2xx after 3 retries (retry with a short backoff; 504/5xx are the observed failure):
- Send URGENT: `bash scripts/telegram.sh "🚨 URGENT $DATE ${MODE_LABEL} — STOP PLACEMENT FAILED for TICKER QTYsh trail N% after 3 retries. Position is UNPROTECTED. Will retry first thing next routine (Rule 17)."`
- Append a marker row to TRADE-LOG.md:
  ```
  ### YYYY-MM-DD — STOP-PLACEMENT-FAILED: TICKER QTY TRAIL
  - N consecutive Alpaca write-path failures (HTTP <code>); position unprotected; Rule 17 retry pending.
  ```
- Continue the routine (do not abort the snapshot/commit). The marker is cleared when a later `STOP PLACED` row for TICKER lands.

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

## Step 6b — Append the metrics record (v3.4, MANDATORY — every session, incl. no-action days)
A missing line == a missing session for the cadence criterion, so this always runs, even on a
pure HOLD day with zero fills/rotations/stops.
```
bash scripts/alpaca.sh bars SPY 1Day 3   # spy_prior_close = 2nd-to-last close
BASE=$(python3 scripts/metrics.py daily --date "$DATE" --mode "${TRADING_MODE:-paper}" \
    --equity "$EQUITY" --prior-equity "$PRIOR_EQUITY" --lmv "$LONG_MARKET_VALUE" \
    --spy-close "$SPY_CLOSE" --spy-prior-close "$SPY_PRIOR_CLOSE" --positions "$POS_COUNT")
```
Merge in and append **one compact single-line** JSON object to `memory/METRICS.jsonl`
(append-only — never rewrite or reorder prior lines; a re-run replaces only today's line):
- A normal session logs 2 `Rule 14 DTC:` tokens (market-open + midday) and they can disagree
  (Aug 7 2026: `0` at market-open, `2` at midday); Task 6 adds a `[conservative: M]` bracket.
  Take max/weakest across *all* of the session's tokens, not last-writer-wins, because the
  higher count is the real risk position and a session is only as trustworthy as its
  worst-sourced token:
  `rule14.dtc` = max `N` across the session's *numeric* tokens (`N` = count before any
  `[conservative: M]` bracket — the figure that gates the ≤1 buffer / `>= 2` abort);
  `.dtc_conservative` = max `M` where present on a numeric token, else `null` (always `null`
  pre-Task 6, included from the first record so the schema doesn't change shape mid-window);
  `.source` = weakest source across the session's tokens (`api` > `local` > `none`/`error`);
  `.tokens_expected` (2 normal, 1 if a routine legitimately skipped);
  `.tokens_found` (count of today's tokens);
  `.accurate` = `false` when *any* numeric recorded `N` this session != true same-day round-trip
  count, `true` otherwise
  **`n/a` tokens** (v3.4 — market-open emits `Rule 14 DTC: n/a (halted before gate evaluation)`,
  no numeric `N`, on its **pre-Step-0 environment halts** *and* on a **Step 1 halt where Step 0
  executed nothing**; a Step 1 halt whose Step 0 ran a catch-up sell or aborted on one writes the
  real numeric token instead, so treat that session as an ordinary numeric one): still **count**
  toward `tokens_expected`/
  `tokens_found` (the mandated line was still emitted); **excluded** from the `dtc`/
  `dtc_conservative` maxima (nothing numeric to compare); contribute `none` to the `source`
  ranking (a halted routine evaluated no source). If **every** token this session is `n/a`:
  `dtc`=`null`, `dtc_conservative`=`null`, `source`=`none`, and `accurate`=**`true`** — nothing
  numeric was recorded, so nothing was recorded wrongly.
- `rule16.rotations` (ROTATE-EXIT rows today), `.suppressed` (`DECAY-SUPPRESSED` rows — Task 4),
  `.shallow_rotations` (rotations today shallower than -2.0% vs entry AND SPY 10-session > +3.0%
  — the Task 3 guard condition; should be 0 once shipped). **Exclude ROTATE-EXIT rows tagged
  `trigger: sector-quadrant`** *(v3.4)* — midday rotates those regardless of `suppressed`
  because a sector leaving the leading quadrant is an *absolute* signal the melt-up guard
  deliberately does not govern; counting them would FAIL `rule16_meltup` on correct behaviour.
  Only `trigger: decay-chain` rows can be shallow melt-up rotations
- `rule5.triggered` (re-deployment trigger **armed** today — Task 5; market-open computes it in
  Step 2, before the HOLD short-circuit, so it is true even on a zero-idea HOLD day)
- `rule5.acted` (v3.4) — `true` only when a core ballast add actually **filled** today under the
  relaxed 1.5:1 floor (armed *and* a filled `Tier: core` BUY tagged `rr-relaxed`); `false`
  otherwise, including armed-but-nothing-passed days. Diagnostic, not a gate: `metrics.py` no
  longer resets the deployment run on `triggered`, so a blocked window now FAILs `deployment`,
  and `rule5_acted` is what says whether the arming ever deployed capital
- `rule8.scaleouts`/`.tightenings` (SCALE-OUT / STOP UPDATE rows today)
- `ops.routines_expected` (4 normal), `.routines_logged` (per Step 0's sweep), `.missing`
  (`[]` when clean), `.unprotected_positions` (held, no open GTC trail after Step 4), `.stops_placed`
- `trades.buys`/`.sells` (fills today)
- `breaches` (`[]` when clean; else one-liners — day trade, stop moved down, -7% left open, sell
  with `DTC >= 2`)

## Step 7 — Send ONE Telegram via `telegram.sh`
```
bash scripts/telegram.sh "${HEARTBEAT_PREFIX}*EOD <MMM DD>* ${MODE_LABEL}
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

---
description: End-of-day summary (local mirror of cloud routine; no commit/push)
---

You are running the **daily-summary workflow** locally for v2. Resolve today's
date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

This is a v2 paper run. EOD snapshot + stop placement (Rule 13) + heartbeat check (DECIDED J).

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
bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — MISSING ROUTINE: <name> did not log today. Investigate cron. (Rule 18)"
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
- Send URGENT: `bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — STOP PLACEMENT FAILED for TICKER QTYsh trail N% after 3 retries. Position is UNPROTECTED. Will retry first thing next routine (Rule 17)."`
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

---
description: End-of-day summary (local mirror of cloud routine; no commit/push)
---

You are running the **daily-summary workflow** locally. Resolve today's date with `DATE=$(date +%Y-%m-%d)`.

This is a v1 paper-only run. No trades fired today (v1 = research only). EOD snapshot is the only output.

## Step 1 — Read memory for continuity
- Tail of `memory/TRADE-LOG.md` — find the most recent EOD snapshot to get yesterday's equity (needed for Day P&L)
- Today's `memory/RESEARCH-LOG.md` entry (if present)

## Step 2 — Pull final state of the day
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders
```

## Step 3 — Compute metrics
- Day P&L ($ and %) = today's equity − yesterday's equity (from prior EOD snapshot or Day 0 baseline)
- Phase cumulative P&L ($ and %) = today's equity − $10,000 starting baseline
- Trades today: always "none" in v1
- Trades this week (running total): always 0 in v1

## Step 4 — Append EOD snapshot to `memory/TRADE-LOG.md`
Use the schema at the top of `TRADE-LOG.md`:
```
### MMM DD — EOD Snapshot (Day N, Weekday)
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** ±$X (±X%) | **Phase P&L:** ±$X (±X%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |

**Notes:** one-paragraph plain-english summary (e.g. "Quiet session, no trades fired, equity unchanged from market drift").
```

## Step 5 — Send ONE Slack message via `slack.sh`
≤ 15 lines. Always include the `(paper)` suffix. Sample:
```
bash scripts/slack.sh "*EOD MMM DD* (paper)
Equity: \$X (±X% day, ±X% phase)
Cash: \$X
Trades today: none (v1 research only)
Open positions: none
Pre-market plan today: <decision from research log>
Tomorrow: pre-market checks at 6:00 CT"
```

(Locally, if `SLACK_WEBHOOK_URL` is unset in `.env`, the wrapper appends to `DAILY-SUMMARY.md` and exits 0 — that's expected behavior for local testing.)

## Step 6 — Skip commit
Local mode does not auto-commit. Review the appended snapshot and commit by hand if it's worth keeping.

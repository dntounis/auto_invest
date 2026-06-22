---
description: Pre-market research run (local mirror of cloud routine; no commit/push)
---

You are running the **pre-market research workflow** locally. Resolve today's date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` — match the cloud routine's TZ so local entries align with cron-fired entries.

This is a v1 paper-only research run. **No orders execute.** The Alpaca wrapper refuses state-changing subcommands.

## STEP 0 — Rule 17: clear any pending stop-placement failure (FIRST action)

Before any research or env checks, tail `memory/TRADE-LOG.md` for a
`STOP-PLACEMENT-FAILED TICKER QTY TRAIL` row that has **no later `STOP PLACED`** row
for the same ticker. If one exists, retry the placement as the very first action:
```
bash scripts/alpaca.sh trailing-stop TICKER QTY TRAIL
```
- On success: append a `STOP PLACED` row (clears the marker) and send a non-URGENT
  Telegram note "Rule 17 retry succeeded — TICKER now protected".
- On failure after 3 retries: send URGENT Telegram instructing manual placement via the
  Alpaca UI, leave the marker open, and continue the routine.
If no unresolved marker exists, proceed to STEP 1.

## Step 1 — Read memory for context
- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md`
- Tail of `memory/TRADE-LOG.md`
- Tail of `memory/RESEARCH-LOG.md`

## Step 2 — Pull live paper-account state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders
```

## Step 3 — Research market context via Perplexity
Run `bash scripts/perplexity.sh "<query>"` for each:
- "WTI and Brent oil price right now"
- "S&P 500 futures premarket today"
- "VIX level today"
- "Top stock market catalysts today $DATE"
- "Earnings reports today before market open"
- "Economic calendar today (CPI/PPI/FOMC/jobs data)"
- "S&P 500 sector momentum YTD"
- "Top momentum stocks today with bullish catalysts (earnings beat, guidance raise, analyst upgrade)"
- News on each currently-held ticker

**Single-stock satellite screen (v3).** For each single-stock candidate:
- `bash scripts/alpaca.sh bars TICKER 1Day 200` → confirm last close > 50-DMA and > 200-DMA.
- `bash scripts/alpaca.sh bars SPY 1Day 60` → candidate 10-/50-session returns vs SPY (relative strength positive). (60 bars covers the 50-session lookback, which needs 51 closes.)
- Reject candidates failing the liquidity filter (thin volume / wide spread).

If `perplexity.sh` exits 3, fall back to native `WebSearch` and **flag the fallback in the research-log entry** ("Sources: WebSearch fallback used for queries: ..."). If `alpaca.sh bars` is unavailable, degrade the satellite screen to catalyst + liquidity only and flag it.

## Step 4 — Write a dated entry to `memory/RESEARCH-LOG.md`

Use the schema documented at the top of `RESEARCH-LOG.md`. Include:

- **Account snapshot:** equity, cash, buying power, daytrade count
- **Market context:** oil, indices, VIX, today's releases, sector momentum
- **2–4 actionable trade ideas, ranked by R:R descending** (tie-break: ticker ascending), each tagged `tier: core` (sector ETF) or `tier: satellite` (single stock). One numbered line per idea using this exact format:
  ```
  1. **ID:** `pm-YYYY-MM-DD-TICKER` — **tier:** core|satellite, TICKER, catalyst, entry $X, stop $X (stop width N% → risk-parity sizing), target $X, R:R X:1, planned trail percent: N
  ```
  Each idea must satisfy the buy-side gate in `TRADING-STRATEGY.md` (≤6 positions, ≤5 trades/week, ≤20% equity, ETF core ≥45% of deployed, ≤2 satellites/sector, momentum aligned). Skip ideas that fail. Rank core + satellite together by R:R. On a TRADE day, include ≥1 satellite idea unless none pass the checklist (then note why). Default trail 10 for core ETFs; satellites set their own stop width (typically 12–15%).
- **Risk factors:** macro, sector, idiosyncratic
- **Decision:** TRADE or HOLD (default HOLD — patience > activity)
- **Sources:** Perplexity citations + any WebSearch fallback flags

> v2 reminder: `market-open` reads this entry and places limit orders for the top
> `min(passing_ideas, weekly_cap_remaining)` ideas in R:R order. Stops are placed
> by `daily-summary` at market close (Rule 13 — visa-aware).

## Step 5 — No notification by default
Local mode is interactive — you'll see the result in the chat. No Telegram call needed unless you want to test the path.

## Step 6 — Skip commit
Local mode does not auto-commit. Review the appended entry in `memory/RESEARCH-LOG.md` and commit by hand if it's worth keeping.

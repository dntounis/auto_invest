---
description: Pre-market research run (local mirror of cloud routine; no commit/push)
---

You are running the **pre-market research workflow** locally. Resolve today's date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` — match the cloud routine's TZ so local entries align with cron-fired entries.

This is a paper research run. **No buys and no sells, ever.** The only
state-changing call this command may make is `trailing-stop`, from Step 0 only
(Rule 17 retry + the v3.3 Rule 18 recovery of a missed daily-summary) — protective
GTC orders on aged positions. It is kill-switch-gated; exit 4 means positions are
unprotected, so alert and log the Rule 17 marker rather than shrugging it off.

## STEP 0 — Rules 17 + 18: pending-stop retry + cadence check (FIRST action)

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

**Rule 18 (v3.2) — verify the prior session's daily-summary logged.** Also as a first
action, resolve the prior trading day in `MMM DD` format:
`PRIOR_MMMDD=$(TZ=America/Chicago date -v-1d +'%b %d')` (fall back to plain
prior-calendar-day; this check is best-effort — skip weekends/holidays where the
prior session's snapshot is simply the most recent one). Confirm
`memory/TRADE-LOG.md` contains a `## <MMM DD> — EOD Snapshot` header whose date is
the prior trading day (headers use `MMM DD`, e.g. `Jul 02` — NOT ISO). Equivalent
robust check: confirm the most-recent `— EOD Snapshot` header in TRADE-LOG is dated
the prior trading session; if the newest EOD snapshot predates it, the prior
daily-summary is missing. If it is missing, send
`bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — MISSING ROUTINE: daily-summary did not log for <prior_date>. Investigate cron. (Rule 18)"` and append a
`### <prior_date> — MISSING ROUTINE: daily-summary (Rule 18)` placeholder to TRADE-LOG.md.

**Then — only on the "snapshot missing" branch — RUN THE MISSED RULE 13 STOP
PLACEMENT (v3.3).** If the prior session's snapshot is present, daily-summary ran
and placed its stops; skip this. (Idempotent, so a stray run is harmless, but it is
not unconditional.) daily-summary is the *only*
placer of Rule 13 stops — market-open never places one, midday only tightens one
that already exists — so a single skipped daily-summary leaves that day's positions
permanently stop-less. Pull `bash scripts/alpaca.sh positions` and
`bash scripts/alpaca.sh orders open`; for each held position with no open
`type=trailing_stop` order, place `bash scripts/alpaca.sh trailing-stop TICKER QTY 10`
(canonical Rule 6 trail; use a tighter trail if a prior `STOP UPDATE` row recorded
one — Rule 9 forbids moving a stop down; use the live `qty`, not a possibly-stale
TRADE-LOG one). Skip symbols that already have a stop (idempotent). Append a
`STOP PLACED` row citing "Rule 18 recovery of missed daily-summary <prior_date>"
and Telegram-note each placement (non-URGENT).

Visa-safe: every position reachable here was opened on or before the prior session
— it survived to this morning's `positions` pull — so it is aged by construction
and a stop placed now cannot produce a same-day round trip. Placing a stop is not a
sell, so Rule 15 is not engaged. Never stop a position whose entry date is today
(there are none at this hour — market-open has not run).

On placement failure, fall through to the Rule 17 escalation above (3 retries →
URGENT Telegram → `STOP-PLACEMENT-FAILED` marker → continue). Do not invent a new path.

Then continue.
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
- "US economic calendar next 5 trading days: NFP jobs report, CPI, PPI, Core PCE, FOMC decision, FOMC minutes, Powell press conference — with dates"
- "S&P 500 sector momentum YTD"
- "Top momentum stocks today with bullish catalysts (earnings beat, guidance raise, analyst upgrade)"
- News on each currently-held ticker

**Single-stock satellite screen (v3).** For each single-stock candidate:
- `bash scripts/alpaca.sh bars TICKER 1Day 200` → set `LAST_CLOSE` = the last bar's
  close (bound here by name — the `rscreen` call below passes it), and confirm
  `LAST_CLOSE` > 50-DMA and > 200-DMA.
- `bash scripts/alpaca.sh bars SPY 1Day 60` → `RS10`/`RS50` (ticker minus SPY, pp).
  Compute `DMA50` and `DMA50_PRIOR` (50-DMA now vs 10 sessions ago) from the 200-bar pull.
  Then *(v3.3, never by eye)*:
  ```
  python3 scripts/sizing.py rscreen --rs10 "$RS10" --rs50 "$RS50" \
      --close "$LAST_CLOSE" --dma50 "$DMA50" --dma50-prior "$DMA50_PRIOR"
  ```
  Reject on `pass == 0`, quoting `reason`. `RS50 > 0` is mandatory; `RS10 <= 0` can
  still pass as a `constructive_pullback` (within 3% of a rising 50-DMA).
  Tag the idea: `rs: RS10 <X>pp / RS50 <Y>pp / screen=<reason>`.
- Reject candidates failing the liquidity filter (thin volume / wide spread).
- **Macro-window (v3.2):** from the economic-calendar result, determine whether any Tier-1
  binary (NFP, CPI, PPI, Core PCE, FOMC decision/minutes, Powell presser) falls on T+1 or
  T+2 (the next two trading sessions after today's entry). Tag the idea line
  `macro-window: clear` if the nearest such binary is ≥ T+3, else
  `macro-window: <BINARY> T+N`. Do NOT propose a satellite whose macro-window is not clear
  (screen it out like a failed DMA/RS check, and note why). Core ETF ideas are exempt —
  always tag them `macro-window: n/a (core)`.

If `perplexity.sh` exits 3, fall back to native `WebSearch` and **flag the fallback in the research-log entry** ("Sources: WebSearch fallback used for queries: ..."). If `alpaca.sh bars` is unavailable, degrade the satellite screen to catalyst + liquidity only and flag it.

## Step 4 — Write a dated entry to `memory/RESEARCH-LOG.md`

Use the schema documented at the top of `RESEARCH-LOG.md`. Include:

- **Account snapshot:** equity, cash, buying power, daytrade count
- **Market context:** oil, indices, VIX, today's releases, sector momentum
- **2–4 actionable trade ideas, ranked by R:R descending** (tie-break: ticker ascending), each tagged `tier: core` (sector ETF) or `tier: satellite` (single stock). One numbered line per idea using this exact format:
  ```
  1. **ID:** `pm-YYYY-MM-DD-TICKER` — **tier:** core|satellite, TICKER, catalyst, entry $X, stop $X (stop width N% → risk-parity sizing), target $X, R:R X:1, planned trail percent: N, macro-window: clear|<BINARY> T+N|n/a (core)
  ```
  Each idea must satisfy the buy-side gate in `TRADING-STRATEGY.md` (≤6 positions, ≤5 trades/week, ≤20% equity, ETF core ≥45% of deployed, ≤2 satellites/sector, momentum aligned, macro-window clear for satellites). Skip ideas that fail. Rank core + satellite together by R:R. On a TRADE day, include ≥1 satellite idea unless none pass the checklist (then note why). Default trail 10 for core ETFs; satellites set their own stop width (typically 12–15%).
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

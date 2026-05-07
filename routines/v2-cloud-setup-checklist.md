# auto_invest v2 — Cloud Setup Checklist

Run through this checklist after merging v2 to `main`. Each routine is set up
the same way as v1: copy the file's contents into the Anthropic Routines UI's
Prompt field, set env vars in the env-vars textbox, set the cron schedule and
TZ, save, smoke-test with Run now.

**Pre-flight (one-time):**

- [ ] All v2 commits on `main`. Verify: `git log --oneline -25 origin/main` shows
      all task commits from the v2 implementation plan.
- [ ] v1 criterion #1 closed (5/5 clean cron weekdays).
- [ ] Local tests pass: `bash tests/run_all.sh`.

## Stage 1 — Re-paste pre-market with v2 idea-ID + R:R ranking

- [ ] Open `auto_invest pre-market` routine in Anthropic Routines UI.
- [ ] Copy entire contents of `routines/pre-market.md`. Paste into Prompt field. Save.
- [ ] Click "Run now". Watch the live log:
      - Env-var loop should print 7 vars `set` (Perplexity should be set; if you removed it during the v1 fallback test, restore it).
      - RESEARCH-LOG entry appears with `**ID:** pm-YYYY-MM-DD-TICKER` lines per idea.
      - Ideas listed in R:R-descending order.
- [ ] Pull main locally: `git pull --rebase origin main`. Verify the new entry shape.

## Stage 2 — Re-paste daily-summary with stop placement + heartbeat

- [ ] Add new env vars to the routine's textbox (in addition to v1 set):
      - `TRADING_ENABLED=true` (replace the v1 `false`)
      - `MAX_ENTRY_SLIPPAGE_PCT=0.10`
      - `RISK_PER_TRADE_PCT=2.0`
      - `MAX_POSITION_PCT=20`
- [ ] Copy entire contents of `routines/daily-summary.md`. Paste into Prompt field. Save.
- [ ] Click "Run now". Watch the live log:
      - `TRADING_ENABLED=true` printed in env-var loop.
      - If positions are open from earlier today (none expected at this stage): trailing stops placed.
      - Heartbeat check runs (almost certainly NOT prepended — last_telegram is recent).
      - EOD message sent.
- [ ] Pull main locally. Verify HEARTBEAT.md timestamp updated to ~just now.

## Stage 3 — Set up `auto_invest market-open` (NEW)

- [ ] In Anthropic Routines UI: New Routine.
- [ ] Name: `auto_invest market-open`
- [ ] Repository: `dntounis/auto_invest`
- [ ] Branch: `main`
- [ ] Cron schedule: `30 8 * * 1-5`, TZ: `America/Chicago`
- [ ] Env vars (copy entire set from daily-summary including the new v2 ones).
- [ ] Setup script: same trivial passthrough as v1 (`#!/bin/bash; echo ...; exit 0`).
- [ ] "Allow unrestricted branch pushes": ON.
- [ ] Prompt: paste entire contents of `routines/market-open.md` verbatim.
- [ ] Save.
- [ ] Click "Run now" smoke test (the routine will likely no-op if no fresh
      RESEARCH-LOG entry exists yet — verify the no-op path runs cleanly).

## Stage 4 — Set up `auto_invest midday` (NEW)

- [ ] New Routine. Name: `auto_invest midday`. Branch: main. Cron: `0 12 * * 1-5` America/Chicago.
- [ ] Env vars: same as market-open.
- [ ] Setup script: same trivial passthrough.
- [ ] Allow unrestricted branch pushes: ON.
- [ ] Prompt: paste entire contents of `routines/midday.md` verbatim.
- [ ] Save.
- [ ] Click "Run now" smoke test (will no-op if no actionable positions — verify clean run).

## Stage 5 — Set up `auto_invest weekly-review` (NEW)

- [ ] New Routine. Name: `auto_invest weekly-review`. Branch: main. Cron: `0 16 * * 5` America/Chicago.
- [ ] Env vars: same as midday.
- [ ] Setup script: same trivial passthrough.
- [ ] Allow unrestricted branch pushes: ON.
- [ ] Prompt: paste entire contents of `routines/weekly-review.md` verbatim.
- [ ] Save. (Don't smoke-test yet — wait for first natural Friday firing OR
      manually invoke after Stage 4 runs are done.)

## Stage 6 — First-day observation

- [ ] Wait for Monday's natural firings:
      - 06:00 CT pre-market: silent unless macro-urgent
      - 08:30 CT market-open: 0–N orders depending on RESEARCH-LOG ideas
      - 12:00 CT midday: silent unless action; placeholder run with no
        actionable positions on Day 1
      - 15:00 CT daily-summary: EOD with stop placements for any new positions
- [ ] Verify each fired by checking `git log --oneline origin/main` for the
      four expected commits.
- [ ] Inspect `bash scripts/alpaca.sh orders` — every position opened should
      have a corresponding trailing-stop GTC by 15:30 CT.
- [ ] Inspect `bash scripts/alpaca.sh account` — `daytrade_count` should be 0
      (no day trades possible by Day 1 design).

## v2 exit criteria observation

After the first clean day, observe for 2 weeks (10 weekdays). All v2 exit
criteria from the spec § 10 must hold. If `daytrade_count` ever exceeds 2,
investigate immediately — the visa-safety design has a leak.

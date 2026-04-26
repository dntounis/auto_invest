---
description: Pre-market research run (local mirror of cloud routine; no commit/push)
---

You are running the **pre-market research workflow** locally. Resolve today's date with `DATE=$(date +%Y-%m-%d)`.

This is a v1 paper-only research run. **No orders execute.** The Alpaca wrapper refuses state-changing subcommands.

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
- News on each currently-held ticker (in v1 there are no held positions — skip this)

If `perplexity.sh` exits 3, fall back to native `WebSearch` and **flag the fallback in the research-log entry** ("Sources: WebSearch fallback used for queries: ...").

## Step 4 — Append a dated entry to `memory/RESEARCH-LOG.md`
Use the entry schema documented at the top of `RESEARCH-LOG.md`. Include:
- Account snapshot (equity, cash, buying power, daytrade count)
- Market context (oil, indices, VIX, today's releases)
- 2–3 actionable trade ideas with catalyst + entry + stop + target + R:R
- Risk factors for the day
- Decision: TRADE or HOLD (default HOLD — patience > activity)
- Sources section with Perplexity citations and any WebSearch fallback flags

## Step 5 — No notification by default
Local mode is interactive — you'll see the result in the chat. No Telegram call needed unless you want to test the path.

## Step 6 — Skip commit
Local mode does not auto-commit. Review the appended entry in `memory/RESEARCH-LOG.md` and commit by hand if it's worth keeping.

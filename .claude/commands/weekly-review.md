---
description: Weekly review (local mirror of cloud routine; no commit/push)
---

You are running the **weekly-review workflow** locally for week ending today.
Resolve dates with:
```
DATE=$(TZ=America/Chicago date +%Y-%m-%d)
WEEK_START=$(TZ=America/Chicago date -d 'last Monday' +%Y-%m-%d 2>/dev/null || python3 -c "from datetime import date,timedelta; t=date.today(); print((t - timedelta(days=t.weekday())).isoformat())")
```

## Strategy mutation policy
`memory/TRADING-STRATEGY.md` is read-only here. Proposed changes go to
`memory/WEEKLY-REVIEW.md` under `## Proposed strategy changes (NOT auto-applied — human review required)`. Human applies them by hand.

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md`
- This week's `memory/RESEARCH-LOG.md` and `memory/TRADE-LOG.md` entries (since `$WEEK_START`)
- Last week's `memory/WEEKLY-REVIEW.md` entry (for prior-week comparison + prior `daytrade_count`)

## Step 2 — Pull state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
# Note: activities is a single-day filter (?date=). For week trade data,
# rely on TRADE-LOG.md (read in Step 1).
bash scripts/alpaca.sh activities    # today only sanity check
```

## Step 3 — Compute grade card

| Metric | Source |
|--------|--------|
| Starting portfolio | EOD snapshot from prior Friday (or Day 0 baseline if week 1) |
| Ending portfolio | `account.equity` |
| Week return | (ending - starting) / starting * 100, $ and % |
| S&P 500 week | from Perplexity if available, else "n/a" |
| Bot vs S&P | week_return - S&P 500 week (positive = beat the market) |
| Trades placed | count of BUY rows in TRADE-LOG.md this week |
| Win rate | (closed winners) / (closed total) |
| Best trade | highest realized P&L % |
| Worst trade | lowest realized P&L % |
| Profit factor | sum(gains) / abs(sum(losses)) |
| daytrade_count delta | `account.daytrade_count` now vs last week's `WEEKLY-REVIEW.md` entry (or 0 / "n/a (week 1)") |
| Rule violations | scan TRADE-LOG.md for: positions > 20%, missing trailing stops, -7% closes that exceeded -10%, Rule 13 violations, Rule 14 abort events |

## Step 4 — Append week-summary to `memory/TRADE-LOG.md` (locally)
```
### YYYY-MM-DD — WEEK SUMMARY (Week ending DATE)
- Trades placed: N (W:X / L:Y / open:Z)
- Week P&L: $X (X.X%)
- Phase P&L: $X (X.X%)
- Best: TICKER +X%
- Worst: TICKER -X%
- daytrade_count delta: <prior> -> <current>
- Rule violations: <list, or "none">
```

## Step 5 — Append entry to `memory/WEEKLY-REVIEW.md` (locally)
Use the template at the top of WEEKLY-REVIEW.md. Include `daytrade_count: <N>` in the stats table for next week's delta computation. If proposed strategy changes exist, append `## Proposed strategy changes (NOT auto-applied — human review required)` block.

## Step 6 — Telegram (1 message)
```
bash scripts/telegram.sh "*WEEK $WEEK_START → $DATE* (paper)
Week return: \$<X> (<±X%>)
Trades: <N> (W:<X> / L:<Y> / open:<Z>)
Best: <TICKER +X%> | Worst: <TICKER -X%>
DTC delta: <prior> -> <current>
Rule violations: <count>
<if proposed changes:> Strategy changes proposed — review WEEKLY-REVIEW.md before Mon"
```

## Step 7 — Skip commit
Local mode does not auto-commit.

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
bash scripts/alpaca.sh bars SPY 1Day 10  # benchmark (v3.3)
```

## Step 3 — Compute grade card

| Metric | Source |
|--------|--------|
| Starting portfolio | EOD snapshot from prior Friday (or Day 0 baseline if week 1) |
| Ending portfolio | `account.equity` |
| Week return | (ending - starting) / starting * 100, $ and % |
| S&P 500 week | **`bash scripts/alpaca.sh bars SPY 1Day 10` (v3.3) — never web search. Chain from prior WEEKLY-REVIEW.md entry, never re-query.** `prior_review_close` from prior entry's recorded `last_close` (protects against Alpaca's retroactive adjustments). Only `last_close` from fresh bars pull. Bootstrap: if prior entry has no recorded SPY close, take `prior_close` from bars query and note "bootstrapped" in provenance. If target date is holiday or absent in 10 bars, use most recent trading day's close (note date used) or retry with 20 bars. Mark "n/a" only if no trading day found — never substitute a web figure. Report: `X.XX% (SPY $A <prior-date> → $B <last-date>, Alpaca bars)`. |
| Bot vs S&P | `week_return - spy_week_return`; both legs from Alpaca prices |
| Alpha vs SPX (v3) | same as Bot vs S&P. **Never revise a prior week's benchmark figure** — append footnote to CURRENT entry naming the prior week, never edit historical entry |
| Core/satellite attribution (v3) | P&L of `Tier: core` vs `Tier: satellite` positions (no Tier field = core) |
| Trades placed | count of BUY rows in TRADE-LOG.md this week |
| Win rate | (closed winners) / (closed total) |
| Best trade | highest realized P&L % |
| Worst trade | lowest realized P&L % |
| Profit factor | sum(gains) / abs(sum(losses)) |
| daytrade_count delta | **`bash scripts/alpaca.sh dtc`, never raw `account.daytrade_count`** *(v3.3 — absent on paper)*. Resolve per midday Step 2 (`api` → use it; `unavailable` → derive locally, activities-primary; `none`/`error` → unresolvable). Compare vs last week's `WEEKLY-REVIEW.md` entry (or 0 / "n/a (week 1)"). Report the source alongside: `0 -> 1 (source=api)`, `unresolvable (source=error)` |
| Rule violations | scan TRADE-LOG.md for: positions > 20%, missing trailing stops, -7% closes that exceeded -10%, Rule 13 violations, Rule 14 abort events, **Rule 14 audit gaps (below)** |

**Rule 14 audit-token sweep (v3.3).** `grep -c 'Rule 14 DTC:'` over this week's
TRADE-LOG rows (`WEEK_START`..`DATE`). market-open and midday each must write the
token once per trading session on every path (HOLD, zero-fill, NO-ACTION, DTC
abort), so expect `2 × sessions` plus one per manual `/trade`. Check session by
session and **name every session missing either token as a `Rule 14 audit gap`** —
a gap is a finding even with no sell attempted, because the gate cannot be shown to
have run. Prompts are re-pasted by hand, so a stale paste drops the token silently;
this sweep is the only detector, and its previous absence is the missing-detector
shape that let the original Rule 14 fail-open survive fourteen weeks.

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
Use the template at the top of WEEKLY-REVIEW.md. Include `daytrade_count: <N>` in the stats table for next week's delta computation. **(v3)** If the satellite sleeve has underperformed the ETF core per-capital for 3+ consecutive weeks (compare the Core/satellite attribution across the last three entries), propose shrinking the satellite allocation. If proposed strategy changes exist, append `## Proposed strategy changes (NOT auto-applied — human review required)` block.

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

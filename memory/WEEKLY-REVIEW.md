# Weekly Review

Friday weekly reviews are appended below by the `weekly-review` routine *(v2)*. **No entries in v1.**

## Entry Template

```
## Week ending YYYY-MM-DD

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $X |
| Ending portfolio | $X |
| Week return | ±$X (±X%) |
| S&P 500 week | ±X% |
| Bot vs S&P | ±X% |
| Trades | N (W:X / L:Y / open:Z) |
| Win rate | X% |
| Best trade | SYM +X% |
| Worst trade | SYM -X% |
| Profit factor | X.XX |
| daytrade_count | N (delta vs prior week: ±M) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop |

### What Worked
- ...

### What Didn't Work
- ...

### Key Lessons
- ...

### Adjustments for Next Week
- ...

### Overall Grade: X
```

---

<!-- Weekly entries appended below -->

## Week ending 2026-05-15

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,000.00 |
| Ending portfolio | $10,055.34 |
| Week return | +$55.34 (+0.55%) |
| S&P 500 week | ~+0.09% (May 11 7,385.31 → May 15 7,391.88; data noisy across sources) |
| Bot vs S&P | +0.46% (beat) |
| Trades | 3 (W:0 / L:0 / open:3) |
| Win rate | n/a (no closes) |
| Best trade | XLE +3.70% (unrealized) |
| Worst trade | XLI -1.34% (unrealized) |
| Profit factor | n/a (no closes) |
| daytrade_count | 0 (delta vs prior week: n/a — week 1 of weekly-review) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| —      | —     | —    | —   | None — no positions closed this week |

### Open Positions at Week End
| Ticker | Entry      | Close   | Unrealized       | Stop                |
| ------ | ---------- | ------- | ---------------- | ------------------- |
| XLE    | $57.290588 | $59.41  | +$72.03 (+3.70%) | $53.45 (trail 10%)  |
| XLI    | $173.713636| $171.39 | -$25.56 (-1.34%) | $157.25 (trail 10%) |
| XLP    | $84.274348 | $84.66  | +$8.87 (+0.46%)  | $77.02 (trail 10%)  |

### What Worked
- **Patience > activity paid off.** Held flat at $10K for the entirety of v1 (Apr 27 → May 11) and the first two days of v2 (May 12 stale-quote XLI limit expired unfilled). Re-entered May 13 post-PPI with live quotes and clean fills inside ~40s — no slippage drag from chasing.
- **Buy-Side Gate held cleanly at submit.** All three May 13 BUYs passed every gate (positions ≤6, weekly trades ≤3, position cost ≤20% equity, cost ≤cash, daytrade_count buffer, catalyst documented). Cost-basis sizing landed 19.11–19.48% of equity per leg — tight under the 20% Rule 3 cap.
- **Sector-rotation conviction.** XLE/XLI/XLP were all in the leading quadrant per the Investing.com sector-rotation read; XLE +3.70% on the week validates the post-Hormuz-closure energy thesis.
- **Rule 13 worked as designed.** All three trailing stops placed at daily-summary T 15:00 CT — none could fire same-day, zero day-trade exposure. daytrade_count stayed 0/5 all week.
- **Beat the S&P benchmark.** Bot +0.55% vs SPX ~+0.09% (≈+0.46% alpha) — small base, only 2 sessions held, but directionally correct.

### What Didn't Work
- **Cap deployment 58% vs 75–85% v2 target.** Hit Rule 4 weekly cap (3/3) before reaching target deployment. Two unheld leading-quadrant sectors (XLB, XLU) carried to next Monday with no exposure this week.
- **May 12 XLE/XLP skipped on stale quotes (ap=0).** Lost a one-day head start on the energy/staples thesis. Re-entered May 13 at slightly higher prices (XLE $57.29 vs ~$56 May 12 bid; XLP $84.27 vs ~$82 May 12 bid). Cost: ~1–2% of position size in entry slippage relative to the missed May 12 fill.
- **XLI weakest leg.** Flat-to-down all week (close $171.39 vs entry $173.71, -1.34%). Industrials thesis (capex/AI-infra/grid/reshoring + Hormuz defense kicker) hasn't been confirmed by tape; watching for sector-rotation degrade next week.
- **Documentation gap May 8 / May 11 (no EOD snapshots).** Three-day cadence break before v2 deployment resumed. Doesn't affect P&L (no fills) but breaks the audit trail for prior-week starting-portfolio reconciliation; relied on carry-forward $10K for week-start.

### Key Lessons
- **Stale quotes (ap=0) on illiquid pre-market windows kill execution.** STEP 5a abort is correct (don't size off bid-only) but cost a day of exposure. Consider a STEP 5a fallback: if ap=0 but bid exists and spread is reasonable on the prior session's close, defer to next session's market-open rather than skip entirely. Open question for v3.
- **Weekly cap (Rule 4) binds before deployment-target (Rule 5).** With 5 candidate sectors and a 3-trade/week cap, full 75–85% deployment requires at least 2 weeks. Acceptable in v2 (slow, conservative ramp); flag for v3 as a structural constraint, not a bug.
- **Rule 13 close-time stop placement is operationally robust.** Zero same-day exit risk, daytrade_count untouched, trailing stops ratcheted up overnight on positive drift (XLE stop +$1.62 from May 13 placement to May 15 EOD on rising hwm). Visa-aware design held.
- **First-deployment week should weight entries toward leading-quadrant momentum, not defensive alternates.** Did this correctly (Energy/Industrials/Staples > Materials/Utilities).

### Adjustments for Next Week
- **Monday pre-market priority list:** XLB (only unheld leading-quadrant sector) → XLU (improving). Both in pre-market plan; re-validate live prices before market-open. Targets 5–6 position cap (Rule 2) and 75–85% deployment (Rule 5).
- **Watch XLI more carefully.** -1.34% after 2 sessions; if it crosses -7% (Rule 7) or sector rolls over (Rule 11), flag for midday hard-close. Industrials thesis is the weakest of the three and most exposed to tape rotation.
- **No strategy mutations proposed this week** (only 2 sessions of P&L data — too early). Continue rule book unchanged into Week 4.
- **Cadence guardrail:** EOD snapshot must be written every weekday (no May 8 / May 11 gaps). Daily-summary routine should not silently no-op on flat-equity days.

### Overall Grade: B+

Solid first deployment week. Beat the S&P, no rule violations, all stops placed per Rule 13, daytrade_count clean. Lost a half-grade for the May 12 stale-quote miss (cost ~one day of XLE/XLP exposure) and for sub-target deployment (58% vs 75–85%). Held book is green-or-flat with no Rule 7/8/10 triggers — clean baseline going into Week 4.

## Week ending 2026-05-22

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,055.34 |
| Ending portfolio | $10,076.44 |
| Week return | +$21.10 (+0.21%) |
| S&P 500 week | ~+1.28% (May 15 7,408.50 → May 22 ~7,503.26; data noisy across sources) |
| Bot vs S&P | -1.07% (lagged) |
| Trades | 1 (W:0 / L:0 / open:1) |
| Win rate | n/a (no closes) |
| Best trade | XLE +3.84% (unrealized) |
| Worst trade | XLI -1.02% (unrealized) |
| Profit factor | n/a (no closes) |
| daytrade_count | 0 (delta vs prior week: 0) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| —      | —     | —    | —   | None — no positions closed this week |

### Open Positions at Week End
| Ticker | Entry       | Close   | Unrealized       | Stop                |
| ------ | ----------- | ------- | ---------------- | ------------------- |
| XLB    | $50.08      | $50.31  | +$9.20 (+0.46%)  | $45.45 (trail 10%)  |
| XLE    | $57.290588  | $59.49  | +$74.78 (+3.84%) | $55.53 (trail 10%)  |
| XLI    | $173.713636 | $171.95 | -$19.40 (-1.02%) | $157.25 (trail 10%) |
| XLP    | $84.274348  | $84.79  | +$11.86 (+0.61%) | $78.03 (trail 10%)  |

### What Worked
- **Patience > activity held the line.** Only 1 trade placed (XLB, Mon May 18); the 2-trade weekly buffer went unused Tue–Fri because no idea passed the sector-momentum gate, not because of a forced pass. XLF (lagging quadrant) and XLU (improving-not-leading + 30Y rate headwind) were correctly rejected all four days.
- **Deployment fixed.** Capital deployment held 78% all week (within the v2 75–85% target band) — first full week inside the band, vs 58% sub-target last week. The Mon XLB add closed the Week 3 gap.
- **Clean execution, zero rule violations.** XLB filled at $50.08 (cost basis $2,003.20 = 19.97% equity — tight under the Rule 3 20% cap). All 4 trailing stops active per Rule 6, XLB's stop placed at close per Rule 13. daytrade_count 0/5, no Rule 14 aborts, no Rule 15 conflicts.
- **XLE remains the book anchor.** +3.84% / +$74.78 unrealized — energy thesis intact through Iran/Hormuz oil-premium chop.

### What Didn't Work
- **Lagged the S&P by ~1.07%.** This is the dominant fact of the week. The all-defensive/cyclical sector-ETF book (Staples/Industrials/Materials/Energy) underperformed a +1.28% risk-on broad-market rally to new highs. The bot has zero tech/growth exposure — the sectors that led the index higher.
- **Cash drag.** ~22% idle cash through a +1.28% week cost ~0.28% of relative performance. The remaining ~0.79% of the lag is sector selection — defensives underperforming a risk-on tape.
- **XLI still the weakest leg.** -1.02% unrealized, 9 trading days in; industrials thesis remains unconfirmed by tape (well above the -7% hard-close, but flat-to-red the entire holding period).
- **Buy-side universe exhausted.** All four leading-quadrant sectors are already held; the only screened candidates (XLF, XLU) fail the momentum gate. The 2-trade budget went unused for lack of a qualifying instrument, not by choice — a recurring structural constraint first flagged in Week 3.

### Key Lessons
- **The leading-quadrant-only sector-ETF universe structurally caps participation.** On a $10K account with a 20% cap, that is ~4–5 names; when the leading quadrant is all defensives/cyclicals and the market rips on tech, the bot has no participation vehicle. This is now a 2-week pattern: Week 3 +0.46% alpha on a flat tape, Week 4 -1.07% on a risk-on tape — the strategy is structurally tilted to outperform in chop and underperform in rallies.
- **Rule 4 (3 trades/week) is not the binding constraint — the sector-momentum gate is.** The bot left 2 trades on the table because nothing passed the gate, not because it hit the weekly cap.
- **Visa-aware machinery (Rules 13/14/15) continues flawless.** daytrade_count 0/5 all week, every stop placed at close, zero same-day exit risk.

### Adjustments for Next Week
- **Monday pre-market:** re-screen XLF (re-arm only if it rotates into the leading quadrant) and XLU (re-arm if 30Y backs <5.05% and it rotates leading). Neither qualified at any point in Week 4.
- **Watch XLI.** 9 sessions in and still red; if it crosses -7% (Rule 7) or industrials roll out of the leading quadrant (Rule 11), flag for midday hard-close.
- **Monitor XLE** over the long Memorial Day weekend for an Iran/Hormuz oil-driven thesis break — headline risk runs both ways.
- **Universe constraint:** see proposed strategy change below — flagged for human review, not auto-applied.

### Overall Grade: C+

Process was clean — 1 disciplined trade, deployment back in band, no rule violations, visa-aware machinery flawless. But the core mission metric was missed: the bot lagged the S&P by ~1.07% in a risk-on week. The miss is largely structural (a defensive sector-ETF book with no tech exposure cannot keep pace with a tech-led rally) rather than an execution error, and the held book remains green-or-flat with no Rule 7/8/10 triggers. One week of benchmark lag against three of clean process — graded C+ to honestly weight the benchmark miss while crediting the discipline.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Rule 5 / universe (proposed change):** When the leading-quadrant sector-ETF universe is exhausted (all leading-quadrant sectors already held) AND capital deployment is below the 75% floor, permit a broad-market ETF (e.g., RSP equal-weight or SPY) as a deployment-of-last-resort to reduce cash drag — subject to all other buy-side gates (20% cap, weekly cap, daytrade buffer).
- **Rationale:** The leading-quadrant-only universe structurally caps the bot at ~4–5 sector ETFs; when those are all held it sits in idle cash regardless of weekly budget, bleeding relative performance in any up week.
- **Evidence:** TRADE-LOG.md Week 4 — 2-trade weekly budget unused with $2,199.76 (~22%) idle cash because no sector idea passed the gate (market-open runs 2026-05-20/21/22, all "0 armed ideas, structurally nothing to buy"); ~0.28% of the week's 1.07% S&P lag is attributable to cash drag.
- **Conviction: LOW.** Only 2 weeks of data, and a SPY-of-last-resort recovers only the cash-drag portion (~0.28%), not the larger sector-selection lag (~0.79%). Philosophically, buying SPY in a beat-the-S&P challenge is a hedge against cash drag, not alpha. Recommend the human defer a decision until 1–2 more weeks confirm the pattern.

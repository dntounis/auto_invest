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
| Alpha vs SPX (v3) | ±X% (headline) |
| Core/Satellite P&L (v3) | core ±$X / satellite ±$X |
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

## Week ending 2026-05-29

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,076.44 |
| Ending portfolio | $9,979.14 |
| Week return | -$97.30 (-0.97%) |
| S&P 500 week | +1.13% (May 22 7,468.82 → May 29 7,551.07) |
| Bot vs S&P | -2.10% (lagged) |
| Trades | 0 (W:0 / L:0 / open:4 carryover) |
| Win rate | n/a (no closes) |
| Best trade | XLB +2.16% (unrealized) |
| Worst trade | XLE -1.66% (unrealized) |
| Profit factor | n/a (no closes) |
| daytrade_count | 0 (delta vs prior week: 0) |
| Trading sessions | 4 (Memorial Day Mon May 25 closed) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| —      | —     | —    | —   | None — no positions closed this week |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized       | Stop                 |
| ------ | ----------- | -------- | ---------------- | -------------------- |
| XLB    | $50.08      | $51.16   | +$43.20 (+2.16%) | $46.4175 (trail 10%) |
| XLE    | $57.290588  | $56.3396 | -$32.33 (-1.66%) | $55.53 (trail 10%)   |
| XLI    | $173.713636 | $173.41  | -$3.34 (-0.18%)  | $157.374 (trail 10%) |
| XLP    | $84.274348  | $83.04   | -$28.39 (-1.47%) | $78.0255 (trail 10%) |

### What Worked
- **Zero rule violations, zero process drift.** 4 sessions, 0 trades, 0 sells, 0 stop-tighten triggers — every routine ran clean. daytrade_count held 0/5 all week; Rule 13 close-time stop machinery untouched (nothing opened); Rule 14 DTC pre-flight passed each midday; no Rule 7/8/10 trigger fired.
- **Trail stops did their job overnight.** XLB stop ratcheted from $45.45 to $46.4175 on a new $51.575 hwm; XLI stop ratcheted from $157.2525 to $157.374. No position breached its trail despite a broad red close.
- **Deployment held in band.** Capital deployment 77.95% Fri close — 4th consecutive day inside the v2 75–85% target. The XLE drawdown (-1.66% unrealized) shrank position market value but did not push deployment out of band.
- **Sector-momentum gate correctly rejected XLU on the rates-trigger week.** 30Y closed sub-5.05% for the 2nd consecutive session (4.98% Thu) — first time the rates prong cleared in v2 — but stockcharts.com flagged XLU rolling over on the RRG (RS line below horizontal support, price below first support). The gate required BOTH rates AND momentum and held the line. The discipline matters even if it cost optionality.

### What Didn't Work
- **Lagged the S&P by ~2.10% this week and by ~3.07% cumulatively across Weeks 4–5.** This is the dominant fact again, and the lag widened from -1.07% (Week 4) to -2.10% (Week 5). The all-defensive/cyclical book has now underperformed in two consecutive risk-on weeks; SPX printed back-to-back new highs while the bot's equity drifted down.
- **Phase P&L flipped negative.** From +$76.44 / +0.76% (Week 4 close) to -$20.86 / -0.21% (this week's close). First red phase close since deployment. SPX over the same Apr 27 → May 29 phase is up ~10–11% — the absolute gap is widening, not just the relative.
- **XLE thesis is breaking on price.** Energy was +3.84% last week and was -1.66% this week. Three consecutive down sessions (Tue -2.82%, Wed -1.30%, Fri -1.18%) on the post-Memorial-Day Iran-deal headline + Sunday WTI gap-down. The Hormuz-blockade structural intactness is still cited by CSIS/Brookings, but price disagrees and the trail stop is now only 1.3% below current — the book's tightest cushion. Headline-risk asymmetry (a deal breakthrough triggers the stop; a re-escalation only restores prior P&L) is now poor.
- **Buy-side universe exhausted for 2nd straight 5-day week.** All four leading-quadrant sectors held; the recurring XLF/XLU candidates never armed. 3-trade weekly budget went entirely unused — not by choice, by structural absence of a qualifying instrument. The pattern is now confirmed across 8 consecutive trading sessions.
- **Documentation gap May 28.** Thu daily-summary did not run / commit — TRADE-LOG.md jumped from May 27 EOD ($10,051.83) to May 29 EOD with no Wed→Thu reconciliation. Today's snapshot rebuilt the math against broker `last_equity` $10,044.15 (May 28 close) so the figures are correct, but the audit trail has a 1-day hole. Second cadence break this phase (May 8/May 11 was the first).

### Key Lessons
- **The leading-quadrant-only universe is structurally broken in a sustained risk-on tape.** Two-week pattern is now confirmed: when defensives/cyclicals are the only leading sectors and tech rips, the bot has no participation vehicle AND cannot use its weekly budget. This is no longer a single-week anomaly to wait out.
- **XLE concentration risk in commodities-headline tape.** The book has 4 sectors but only XLE is exposed to acute headline risk (oil/Iran). Three days of -1% to -3% on geopolitical noise eroded the position's entire cushion; trail stops are designed to handle this but the 1.3% cushion is uncomfortably tight.
- **Cumulative benchmark divergence matters more than weekly variance.** -3.07% across Weeks 4–5 is a level where the mission ("beat the S&P over the challenge window") is at material risk; one more risk-on week without participation makes the gap hard to close inside the remaining horizon.
- **Visa-aware machinery is bulletproof — that's not where the risk lives.** Rules 13/14/15 ran flawlessly for the 5th consecutive week. The risk lives entirely in strategy selection, not in execution discipline.

### Adjustments for Next Week
- **Monday pre-market (Jun 1, Week 6 Day 1, fresh 3-trade budget):** re-arm XLF only if it rotates into the leading quadrant (currently deep lagging, no near-term rotation signal); re-arm XLU only if it re-rotates leading on the RRG AND 30Y holds <5.05% (rates side firmly met, momentum side must rebuild from Wed's rolled-over warning).
- **Watch XLE.** Stop $55.53 sits 1.3% below current $56.34 — the book's tightest cushion. If oil unwinds further into the holiday weekend / Monday open, the trail stop will likely fire — and Rule 13 will keep that exit clean (no day trade). Do not pre-empt; let the trail do its job.
- **Watch XLP.** Defensive bid unwound Fri; position now -1.47% on-cost. Still well clear of -7% (stop $78.0255 sits 5.8% below $83.04) but the inflation/staples thesis is weakening alongside the rates-pivot setup.
- **No auto-applied strategy mutations** (DECIDED G — rulebook is the safety system). Proposed change below escalated to MEDIUM conviction this week given pattern confirmation; human review required.
- **Cadence guardrail:** daily-summary must run AND commit every weekday — May 28 gap is the second documentation hole this phase. Investigate whether Thu daily-summary failed silently or whether commit was missed; either way the audit trail must be continuous.

### Overall Grade: C-

Process was clean — 0 rule violations, visa-aware machinery flawless, trail stops ratcheted as designed. But the core mission metric — beat the S&P — was missed badly: -2.10% this week, -3.07% cumulatively across Weeks 4–5, and the phase P&L flipped negative on the close while SPX printed a new high. The miss is structural (the strategy underperforms in sustained risk-on tape when leading-quadrant sectors don't include tech), not an execution error, but it's the second consecutive risk-on week the bot has lagged. One half-grade for discipline; another half-grade lost for the widening benchmark gap and the cadence hole on May 28. Graded C- to honestly weight that the strategy in its current form is not on track to beat the benchmark over the challenge window.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Rule 5 / universe (escalated from prior week, conviction now MEDIUM):** When (a) the leading-quadrant sector-ETF universe is exhausted (all leading-quadrant sectors already held) AND (b) capital deployment is below the 75% floor for ≥3 consecutive sessions OR weekly budget unused for 2 consecutive weeks AND (c) all other buy-side gates pass, permit a single broad-market ETF (RSP equal-weight preferred over SPY — broader participation, lower mega-cap concentration) as a deployment-of-last-resort. Subject to 20% cap, weekly cap, and Rule 13 stop placement. Stop trail 10% identical to sector-ETF positions.
- **Rationale:** Two-week pattern (Weeks 4–5) confirms the structural cap-and-lag: 5 unused trade slots, ~22% idle cash through two risk-on weeks, S&P lag widened from -1.07% to -2.10% and the cumulative gap is now -3.07% with the phase flipping negative. The leading-quadrant-only universe cannot keep pace with tech-led rallies because it explicitly excludes the leading-tech sectors.
- **Evidence:**
  - TRADE-LOG.md Week 4 market-open runs 2026-05-20/21/22 ("0 armed ideas, structurally nothing to buy") — 2 unused trade slots.
  - TRADE-LOG.md Week 5 market-open runs 2026-05-25 (holiday), 2026-05-26, 2026-05-27, 2026-05-29 (Thu run missing per documentation gap) — all "0 armed ideas, buy-side mechanically wide open, structurally nothing to buy"; 3 unused trade slots.
  - WEEKLY-REVIEW.md Week 4 stats: bot +0.21% vs SPX +1.28% = -1.07%; Week 5 stats: bot -0.97% vs SPX +1.13% = -2.10%.
  - Phase P&L flipped negative this week while SPX is up ~10–11% across the same window.
- **Conviction: MEDIUM** (up from LOW). Three caveats:
  1. RSP-of-last-resort recovers cash-drag participation (~0.3% per up-week) but does not solve sector-selection lag (~0.8% per up-week); it's a partial fix.
  2. Philosophically suspect — buying RSP in a beat-the-S&P challenge concedes the benchmark cannot be beaten by stock selection alone; it is a hedge, not alpha.
  3. Reverses cleanly the moment the leading quadrant changes (tech rotates leading); in regime change the bot should pivot back to single-sector ETFs and exit RSP.
- **Recommendation to human:** Apply for Week 6 if the leading quadrant remains the same four defensive/cyclical sectors at Monday's pre-market read. Defer if XLF or any tech-adjacent sector (XLK, XLY, XLC) rotates leading — that would obviate the need.

- **Rule 11 / sector-momentum gate (proposed clarification, not a change):** Pre-market should explicitly check the LEADING-QUADRANT membership of XLK / XLY / XLC each Monday. If any rotates leading, it supersedes the RSP-of-last-resort proposal above. Today's screen is implicit (the gate looks at "leading quadrant" without enumerating which sectors) — making it explicit closes the gap.
- **Rationale:** The structural cap exists because the screened universe is implicitly the four defensive/cyclical sectors. Listing the leading-quadrant candidates explicitly each Monday surfaces tech rotations without requiring a rule change.
- **Evidence:** Five consecutive weeks of pre-market never proposed XLK / XLY / XLC; the prompt language defaults to whatever the RRG cites as leading, which has been Energy / Industrials / Materials / Staples throughout the v2-active window.
- **Conviction: HIGH** (this is a transparency/audit fix, not a strategy change).

## Week ending 2026-06-05

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $9,979.14 |
| Ending portfolio | $9,955.40 |
| Week return | -$23.74 (-0.24%) |
| S&P 500 week | ~-2.34% (May 29 7,580.06 → Jun 5 ~7,402 per TradingEconomics post-NFP -2.39% Fri; data noisy across sources) |
| Bot vs S&P | +2.10% (beat) |
| Alpha vs SPX (v3) | **+2.10% (headline)** — first beat-the-benchmark week since Week 3 |
| Core/Satellite P&L (v3) | core +$3.56 / satellite -$27.27 |
| Trades | 2 (W:0 / L:1 / open:1 — CAT carryforward) |
| Win rate | 0% (1 closed, 1 loss) |
| Best trade | XLE +0.89% (unrealized week move) |
| Worst trade | XLP -2.094% (realized — Rule 16 rotation) |
| Profit factor | 0.00 (1 closed loss, 0 wins) |
| daytrade_count | 0 (delta vs prior week: 0) |
| Capital deployment | 77.29% (within v3 75–85% band) |

### Closed Trades
| Ticker | Entry       | Exit    | P&L                  | Notes |
| ------ | ----------- | ------- | -------------------- | ----- |
| XLP    | $84.274348  | $82.51  | -$40.58 (-2.094%)    | Rule 16 momentum-decay rotation Wed Jun 3 (2nd consecutive midday lag; flag=1 Jun 2 + Jun 3); swing exit 21 calendar days from May 13 BUY, DTC=0 untouched. First v3 rotation exit. |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized      | Stop                   | Tier      |
| ------ | ----------- | -------- | --------------- | ---------------------- | --------- |
| CAT    | $915.635    | $903.75  | -$23.77 (-1.30%)| $846.432 (trail 10%)   | satellite |
| XLB    | $50.08      | $50.63   | +$22.00 (+1.10%)| $46.97991 (trail 10%)  | core      |
| XLE    | $57.290588  | $57.71   | +$14.26 (+0.73%)| $55.53 (trail 10%)     | core      |
| XLI    | $173.713636 | $174.18  | +$5.13 (+0.30%) | $158.796 (trail 10%)   | core      |

### What Worked
- **First v3 satellite entry executed clean.** CAT BUY Thu Jun 4 — 15-session HOLD streak broken; passed every prong of the v3 single-stock checklist (price > 50-DMA + 200-DMA; positive 10s/50s-RS vs SPY; adequate liquidity; AI/data-center catalyst documented) AND every prong of the Buy-Side Gate (positions 4/6, weekly cap 2/5, 18.15% equity cost basis 1.85pp under Rule 3 cap, ETF core 76.46% post-fill well above 45% floor, ≤2 satellites/sector at 1/2, DTC=0). Limit fill at $915.635 was $6.835/share better than the $922.47 limit — clean execution.
- **First v3 Rule 16 rotation exit executed clean.** XLP closed Wed Jun 3 on 2nd-consecutive-lag (flag=1 Jun 2 + Jun 3) per `sizing.py decay`: 10-session pos -4.14% vs SPY +2.87%, unrealized -2.08% below entry. Rule 14 DTC=0 pre-flight passed; swing exit 21 calendar days from BUY → DTC untouched; trailing stop id 997935c2 cancelled pre-sell; loss booked at -$40.58 / -2.094% (well above the -7% Rule 7 floor — Rule 16 caught dead-money before it became a hard-close).
- **Beat the benchmark.** Bot -0.24% vs SPX ~-2.34% on the NFP-Friday risk-off → **+2.10% alpha** — first beat-the-benchmark week since Week 3. Held-book cyclical concentration (Materials/Energy/Industrials) outperformed a tech-led tape selloff; the XLP rotation removed the staples drag two days before the broad-market drawdown.
- **v3 strategy fired as designed.** Rule 16 caught a structural laggard (XLP, -2.09% realized loss) and freed cash; the v3 single-stock satellite gate then deployed it (CAT, 18.15% equity). The structural cap-and-lag pattern flagged in Weeks 3–5 broke this week — the v3 satellite sleeve did exactly what it was designed to do.
- **Zero rule violations, visa-aware machinery flawless.** DTC held 0/5 all week; CAT trailing stop placed at 15:00 CT per Rule 13; Rule 15 same-day skip protected CAT on Thu midday; Rule 14 pre-flight passed both Wed (XLP rotation) and every midday. Six straight weeks of clean execution.
- **Capital deployment recovered to band.** After the XLP exit pushed deployment to 59.4% (below 75% floor), the CAT add lifted it back to 77.5% within one trading day — operationally the v3 sleeve closed the cash-drag gap that haunted Weeks 4–5.

### What Didn't Work
- **NFP Friday wiped Thursday's HWM.** Phase P&L hit +$154.63 / +1.55% at Thu close (fresh HWM for the v3 phase) but the NFP-driven -1.75% Fri drawdown unwound the gain. EOD phase P&L closed -$22.99 / -0.23%; live equity at weekly-review read sits $9,955.40 (-$44.60 / -0.45% phase). The week was won on relative performance (alpha) but lost on absolute (still red).
- **CAT absorbed the bulk of Friday's drawdown.** Single-stock satellite -$73.46 intraday from $940.48 hwm to $903.75 close (-3.91% Fri), -$23.77 unrealized on-cost at week end (-1.30%). Stop cushion compressed to 6.34% (was 10.00% fresh Thu close), now the book's second-tightest. The single-stock satellite design accepts higher idiosyncratic vol — but the first satellite entered the day before the binary macro print is a timing tension worth flagging.
- **XLP rotation realized a -2.09% loss.** Rule 16 fired correctly per spec, but the cleanest sell signal still booked a loss. Net of the XLP loss + cyclical mark-to-market lift the core sleeve P&L this week was only +$3.56 — alpha mostly came from satellite absence (not holding what SPX held) rather than core selection skill.
- **Best closed trade of the week was a loss.** Win rate 0%, profit factor 0.00. Both are statistically meaningless on n=1 closed trade but visually noisy in the grade card; will recover as more rotations close out.

### Key Lessons
- **v3 satellite-sleeve activation broke the Weeks-3–5 structural cap.** The pattern flagged for 3 weeks (leading-quadrant universe exhausted → weekly cap unused → cash drag) resolved this week without the proposed RSP-of-last-resort: a *single-stock* satellite (CAT) deployed the freed cash post-rotation. Strong evidence the v3 design (raise weekly cap 3→5 + add single-stock satellite gate) directly addressed the structural problem.
- **Rule 16 momentum-decay rotation is operationally sound.** The chain-state machinery (DECAY-FLAG state rows, prior_flag carryover via TRADE-LOG.md) worked as designed: XLI flagged Tue, chain reset Wed (above entry); XLP flagged Tue, fired Wed (2nd consecutive lag + still below entry). The rule fires on the correct trigger and stays dormant otherwise. Visa-aware swing-only exit confirmed (21 calendar days, DTC untouched).
- **Concentration risk in single-stock satellites is real.** CAT 1 position contributed -$27.27 of the -$23.74 week — i.e., the entire week's loss + a small net offset from the core. With $1,831 cost basis (18.15% equity), a single-stock satellite is large enough to swing the weekly P&L on its own. Risk-parity sizing (Rule 3 cap + 10% trail) is the protection; the trade-off is alpha exposure costs vol.
- **Beat-the-benchmark math rotates with tape regime.** Weeks 4–5 the bot lagged a risk-on rally; Week 6 the bot beat a risk-off NFP-day. The held book (3 cyclical ETFs + 1 industrials stock) is positioned for cyclical leadership; a sustained tech rally would re-open the Weeks 4–5 lag. This is not a permanent fix — just an alignment with the current leading-quadrant.
- **Visa-aware machinery (Rules 13/14/15) bulletproof for the 6th consecutive week.** Six weeks, zero day trades, zero same-day exit risk, every stop placed at close, every pre-flight passed. The risk lives entirely in strategy selection, not execution discipline.

### Adjustments for Next Week
- **Monday pre-market (Jun 8, Week 7 Day 1):** post-NFP-conditioned screen. Re-arm `pm-2026-06-05-AVGO` if 10s-RS turns positive AND XLK rotates leading (NFP-driven risk-off Fri may compress mega-cap growth — both prongs could shift); re-arm `pm-2026-06-05-NVDA` on same conditions (needs ~+5pp relative outperformance vs SPY over 10 sessions); re-arm `pm-2026-06-05-XLU` if XLU re-rotates leading AND 30Y holds <5.05% post-NFP (most likely re-arm path if NFP soft); monitor GE (50s-RS closing fast at -3.17pp from -7.16pp Thu).
- **Watch CAT.** Stop $846.432 cushion 6.34% — book's second-tightest after XLE. If post-NFP risk-off extends into Monday and CAT crosses -7% from entry ($851.54), Rule 7 hard-close fires (Rule 15 no longer applies — CAT now T+2 on Mon). Single-stock satellite vol is the cost of the alpha exposure; let trail/Rule 7 do their job, don't pre-empt.
- **Watch XLE.** Book's tightest cushion at 3.78% ($55.53 stop vs $57.71 close). 7 consecutive weeks of XLE in the book; oil-headline asymmetry remains poor. If oil unwinds further into next week, the trail likely fires — Rule 13 keeps it clean.
- **3 trades remain in Week 7's fresh v3 budget.** Capital deployment 77.29% (within band) — no forced-add pressure. Patience > activity (Rule 12); only deploy if a clean satellite or core ETF passes the gate.
- **No auto-applied strategy mutations** (DECIDED G — rulebook is the safety system). The prior 2 weeks' RSP-of-last-resort proposal is now lower priority — v3 satellite slot activated this week and closed the cash-drag gap operationally. See proposed strategy notes below.

### Overall Grade: B

First v3 mechanics-validation week. Two clean v3 firsts (Rule 16 rotation + single-stock satellite entry) both executed exactly per spec; the structural cap-and-lag pattern that hurt Weeks 4–5 resolved within v3's design (no rule change needed). Beat the benchmark by +2.10% — first benchmark beat since Week 3. Zero rule violations, six straight weeks of bulletproof visa-aware execution. But absolute P&L still red on the week (-0.24%) and phase (-0.45%); the only closed trade was a loss; CAT's NFP-Friday drawdown ate the held-book gains. Graded B to weight v3's first successful end-to-end cycle (the design works) against the absolute miss (still under water) and the cyclical-concentration timing risk into next week's binary macro flow (CPI Jun 11 + FOMC Jun 16–17).

## Proposed strategy changes (NOT auto-applied — human review required)

- **Prior RSP-of-last-resort proposal (Weeks 4–5) — DOWNGRADE to LOW conviction / consider tabling.** This week's CAT entry validated the v3 single-stock satellite sleeve as the operational answer to the cap-and-lag problem the RSP proposal was designed to solve. Capital deployment recovered from 59.4% post-XLP-exit to 77.5% within one trading day via the satellite route — exactly the gap the RSP-of-last-resort was meant to plug. Recommendation: keep the proposal on file for a regime where (a) the single-stock satellite gate fails to find ideas for ≥2 consecutive weeks AND (b) deployment falls below the 75% floor, but defer adoption while v3 satellites are firing.
- **Conviction: LOW (downgraded from MEDIUM).**

- **Rule 8 ladder — no proposed change, but flag for observation.** Held book never crossed the +4% first-tier core threshold this week (XLB +1.10%, XLE +0.73%, XLI +0.30%) — Rule 8 stayed dormant for the 6th straight week. CAT hit +2.73% intraday Thu (above entry $915.635 to $940.48 hwm) but never crossed the +6% first-tier satellite threshold. The ladder remains untested in real conditions; observation continues.

- **Rule 16 momentum-decay — keep as-is.** First firing executed cleanly per spec (XLP). The 10-session window + 2-consecutive-flag chain + below-entry AND lagging-SPY conjunction caught a true laggard and stayed dormant on XLI when it recovered above entry. No proposed change.

- **Cyclical concentration observation (not a proposed change).** Held book is currently Materials + Energy + Industrials (ETF + stock) = 100% cyclical. Industrials concentration alone is 48% of deployed (XLI $1,916 + CAT $1,808). The book is well-positioned for cyclical leadership but vulnerable to a sustained tech-rally regime. If XLK rotates leading next week, the Rule 11 satellite gate should fire (AVGO/NVDA re-arm path) and naturally diversify out of cyclicals. No rule change proposed — flagged for next week's pre-market to surface explicitly.

## Week ending 2026-06-12

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $9,955.40 |
| Ending portfolio | $10,078.31 |
| Week return | +$122.91 (+1.234%) |
| S&P 500 week | +0.14% (7,383.74 → 7,394.30 per S&P Dow Jones Indices) |
| Bot vs S&P | +1.09% (beat) |
| Alpha vs SPX (v3) | **+1.09% (headline)** — 2nd consecutive benchmark-beat week |
| Core/Satellite P&L (v3) | core +$82.46 / satellite +$14.27 (CAT +$13.64 + GE +$0.63 day-1) |
| Trades | 1 (W:0 / L:0 / open:5 — GE entry Fri, CAT/XLB/XLE/XLI carryforward) |
| Win rate | n/a (0 closes this week) |
| Best trade | XLB +$67.60 unrealized week move (+3.36% week, +4.47% vs entry — Rule 8 ladder fired) |
| Worst trade | XLE -$7.14 unrealized week move (-0.36% week — only red book contributor) |
| Profit factor | n/a (0 closes) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) |
| Capital deployment | 87.48% EOD (slightly above v3 75–85% target band post-GE-entry overshoot) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| (none — zero closes this week) | | | | |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized       | Stop                    | Tier      |
| ------ | ----------- | -------- | ---------------- | ----------------------- | --------- |
| CAT    | $915.635    | $910.57  | -$10.13 (-0.55%) | $846.432 (trail 10%)    | satellite |
| GE     | $335.06     | $335.27  | +$0.63 (+0.06%)  | $301.743 (trail 10%)    | satellite |
| XLB    | $50.08      | $52.32   | +$89.60 (+4.47%) | $48.69015 (trail 7%)    | core      |
| XLE    | $57.290588  | $57.50   | +$7.12 (+0.37%)  | $55.53 (trail 10%)      | core      |
| XLI    | $173.713636 | $176.18  | +$27.13 (+1.42%) | $158.949 (trail 10%)    | core      |

### What Worked
- **Beat the benchmark for the 2nd consecutive week.** Bot +1.234% vs SPX +0.14% → **+1.09% alpha**. The held book's cyclical concentration (Materials/Energy/Industrials core + CAT/GE satellites) absorbed the CPI Wed shock (book -2.04% Wed) and rode the PPI Thu / Fri relief bounce (+1.74% Thu + +0.91% Fri). Critically, the structural cap-and-lag pattern from Weeks 3–5 stayed resolved into Week 7.
- **First Rule 8 ladder fire of the v3 phase — XLB.** Fri midday XLB unrealized +4.26% crossed the +4% first-tier core threshold → `sizing.py ladder` returned `target_trail_pct=7, scaleouts_due=0` → trail tightened 10% → 7% (new stop order id 9b627571, stop $48.55065, hwm $52.205). Rule 9 check passed (7% > 3% min distance, stop moved up not down). The v3 ladder machinery proved live and idempotent for the first time in 6 weeks of operation.
- **First Rule 16 decay chain BREAK — CAT.** Wed CPI: CAT flag=1 (10s -5.16% vs SPY -2.63% = -2.54pp lag + below entry). Thu PPI bounce: CAT flag=0 (10s -1.08% vs SPY -3.81% = **+2.72pp outperformance** — chain broken at 1 of 2). Rule 16's 2-consecutive-flag conjunction worked as designed: it caught a true risk-off lag candidate but stayed dormant on the recovery, sparing the satellite from a forced T+1 sell into Thu's biggest day P&L (+4.84% CAT close-to-close). Avoided a -$36 realized loss + a clean +$118.95 → -$36 swing on the held position.
- **2nd v3 satellite entry executed clean — GE Fri.** 50s-RS matured through the binary cycle (Tue +0.60pp razor-thin → Fri +3.82pp durable confirmation, 3.22pp gain through hot-CPI + friendly-PPI = regime not noise). Passed every prong of the v3 single-stock checklist + Buy-Side Gate (positions 4→5, weekly cap 0→1, 9.98% equity cost basis well under Rule 3, ETF core 67.84% post-fill, satellite 2/2 in Industrials at cap, DTC=0). Limit fill at $335.06 was $5.28/share better than the $340.34 limit — clean execution; price improvement $15.84 total.
- **Visa-aware machinery flawless for 7th straight week.** DTC held 0/5 all week; CAT trailing stop carryforward unchanged; GE trail placed at 15:00 CT per Rule 13 (order id 8277f3e8); Rule 15 same-day skip protected GE on Fri midday; Rule 14 pre-flight passed every midday (DTC=0). Seven weeks, zero day trades, zero same-day exit risk.
- **CPI-day stress test passed without intervention.** Wed midday CAT hit 1.14% trail stop cushion + -6.40% vs entry (intraday $855.40 within 1.05% of $846.432 trail stop trigger; within 0.50% of -7% Rule 7 floor). Routine correctly held (Rule 7 stop-loss is intraday-trigger, not midday-action; Rule 16 was 1 of 2). Thu's bounce vindicated the patience: CAT recovered to -1.97% from entry by Thu close.

### What Didn't Work
- **Capital deployment briefly overshot the 75–85% band.** Post-GE-entry Fri midday hit 87.49% (long_market_value $8,820.65 / equity $10,081.66); EOD settled 87.48%. Rule 5 is a target band not a hard cap, but the overshoot is a function of GE entering on an already 77.43% deployed book — the buy-side gate doesn't check deployment ceiling, only the 45% core floor. The math: 4 ETF positions + 1 satellite (CAT) ≈ 77% deployed; adding GE pushed to 87%. Worth flagging whether buy-side should add a deployment-ceiling check or whether the 75–85% band is treated as a soft target.
- **XLE the only red contributor.** -$7.14 week unrealized (-0.36%) on Thu's -2.03% oil-softness day; cushion compressed from 4.80% Wed close to 3.43% Fri close — book's tightest. 8 consecutive weeks of XLE in the book; oil-headline asymmetry remains poor and a single -3.4% session trips the trail.
- **First-week return for GE was day-1 only (+$0.63).** No meaningful contribution to weekly alpha; full read on the satellite gate's quality will need 1–2 weeks of GE position aging. The CAT precedent (CAT -1.30% unrealized week 1, -0.55% week 2) suggests single-stock satellites take time to express their thesis.
- **CPI-day intraday risk was real, not just narrative.** CAT intraday low $855.40 came within 1.05% of the $846.432 trail-stop trigger and within 0.50% of the -7% Rule 7 floor. The system held, but the v3 single-stock satellite design (15% per-idea stop width for sizing → 10% canonical trail at close) accepts higher idiosyncratic vol exposure than ETF core. On a hotter CPI tail, CAT could have stopped out same-day style via the trail.

### Key Lessons
- **Rule 8 ladder works as designed.** First fire (XLB +4.26% → 7% trail) was clean per spec: the deterministic `sizing.py ladder` returned the right target, Rule 9 distance check passed, stop moved up not down, replace-stop call succeeded. The ladder is no longer untested in real conditions — confirmed live for 1 trigger.
- **Rule 16 decay chain BREAK is as important as the chain fire.** Week 6 validated the chain firing (XLP rotation). Week 7 validated the chain breaking (CAT, 1 of 2 → reset). The conjunction logic (below entry AND lagging SPY for 2 consecutive) is what protects the v3 satellite sleeve from over-rotation on transient drawdowns. Without the SPY-relative-strength check, CAT would have stopped out on Wed's CPI absorbing the full -6.40% — Rule 16 correctly distinguished an idiosyncratic-but-recovering position from a structural laggard.
- **Visa-aware machinery (Rules 13/14/15) bulletproof for 7th consecutive week.** Zero day trades, zero same-day exits, every stop placed at close. The risk lives in strategy selection, not execution.
- **Cyclical-concentration regime remains favorable.** Bot beat SPX in 2 of last 2 weeks (Week 6: +2.10% NFP-Friday risk-off; Week 7: +1.09% CPI/PPI binary cycle). Held book is positioned for cyclical leadership; a sustained tech rally would re-open the Weeks 4–5 lag. v3 satellite gate has 1 tech idea (XLK) on deferred carry-forward; AVGO/NVDA need RS recovery.
- **Industrials concentration at 2/2 satellite cap with $4,764.93 = 54% of deployed is a single-sector-kill risk.** Rule 10 (2 consecutive failed Industrials trades → exit all Industrials) would liquidate XLI + CAT + GE in one step. No history of consecutive Industrials losses, but the concentration is structurally high. Worth observing whether the buy-side gate's ≤2 satellites/sector cap is the right ceiling for a single sector at 54% of deployed.
- **Satellite-sleeve check (v3 spec):** Week 6 core +$3.56 / satellite -$27.27 (satellite UNDERperformed); Week 7 core +$82.46 / satellite +$14.27 (satellite again UNDERperformed core, but absolute green). Only 2 weeks of v3 data — the 3+ consecutive-week threshold for the shrink-satellite proposal is not yet met. Observation continues.

### Adjustments for Next Week
- **Monday pre-market (Jun 15, Week 8 Day 1, pre-FOMC):** FOMC Jun 16–17 is the week's primary binary (Fed expected to deliver one more 25bp cut in 2026 per pre-CPI consensus; CPI hot print Wed shifted markets back toward hawkish). Pre-market screen should re-evaluate XLK 10s-RS confirmation (Fri's +0.28pp razor-thin needs a Mon session to validate); AVGO/NVDA need RS recovery (1+ sessions); MPC 50s-RS still negative; XLU DEAD path.
- **Watch XLE.** Book's tightest cushion at 3.43% ($55.53 stop vs $57.50 close). 8 consecutive weeks of XLE in the book; oil-headline asymmetry remains poor. If oil unwinds further into next week, the trail likely fires — Rule 13 keeps it clean. Cushion math: any -3.4% XLE day triggers auto-exit.
- **Watch XLB Rule 8 ladder progression.** Fri's first-tier fire (+4% core → 7% trail) leaves XLB needing +7% vs entry to trigger the 2nd tier (scale-out 1/3 + 5% trail). XLB at $52.32 needs $53.586 close — within reach on 2-3 strong sessions. The first scale-out would book partial gains, free cash for redeployment, and lock in profits at a tighter trail.
- **GE week-2 read.** Day-1 +$0.63 (+0.06%); will get meaningful read on 50s-RS regime confirmation by Wed–Thu. Stop cushion is fresh 10% ($301.743 vs $335.27). If GE breaks down before reaching the +6% satellite first-tier ($355.16), Rule 16 decay-flag risk activates if it lags SPY in the 10s window.
- **4 trades remain in Week 8's fresh v3 budget.** Capital deployment 87.48% — already above the band; no room to add without exiting something. Patience > activity (Rule 12); a scale-out (XLB 2nd-tier ladder) would create capacity.
- **CAT decay chain reset to 0.** Next midday flag would be 1 of 2 again. The Thu+Fri recovery moved CAT from -6.40% Wed close → -0.55% Fri close — close to flat but not yet to ladder thresholds. Watch the 10-session pos vs SPY into Mon.
- **No auto-applied strategy mutations** (DECIDED G — rulebook is the safety system). See proposed strategy notes below.

### Overall Grade: B+

Constructive week with the v3 strategy framework firing cleanly. Two more v3 firsts validated: Rule 8 ladder (XLB +4.26% → 7% trail) and Rule 16 decay chain BREAK (CAT 1 of 2 → reset on Thu bounce). 2nd v3 satellite entry (GE) executed clean — 50s-RS regime confirmation through CPI/PPI binary cycle, every gate passed, $5.28/sh price improvement on fill. Beat the benchmark by +1.09% (2nd consecutive week of alpha). Zero rule violations, 7 straight weeks of bulletproof visa-aware execution. **CPI Wed stress test passed without intervention** — CAT intraday $855.40 was within 1.05% of trail trigger + 0.50% of -7% floor; Thu's bounce vindicated patience. Concerns: (a) capital deployment overshot to 87.48% post-GE-entry (buy-side gate has no deployment ceiling); (b) Industrials concentration at $4,764.93 = 54% of deployed with 2/2 satellite slots at cap = single-sector-kill exposure; (c) XLE cushion 3.43% remains tightest in book. Graded B+ to weight the 2 clean v3 firsts (ladder + decay break) + the 2nd alpha week against the structural concentration risk that didn't bite this week but is structurally present.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Add deployment-ceiling check to buy-side gate (v3.1 proposal).** This week's GE entry pushed deployment from 77.43% pre-fill to 87.48% post-fill — outside the v3 75–85% target band. The buy-side gate currently checks the 45% core floor but has no upper bound. Proposal: add `(deployed_capital + position_cost) / equity ≤ 0.85` as a 10th buy-side gate check. If deployment ≥ 85% pre-fill, defer the buy until a scale-out, sell, or equity growth restores headroom.
- **Rationale:** Capital deployment is a Rule 5 target, but in practice the routine treats it as advisory — there is no enforcement. The 75–85% band exists to keep cash buffer for opportunistic adds and to bound concentration; overshooting to 87% reduces both. The proposed gate enforces what's already in Rule 5.
- **Evidence:** TRADE-LOG.md 2026-06-12 market-open (post-fill deployment 87.49%), 2026-06-12 midday (still 87.49%), 2026-06-12 EOD (87.48%). All midday/EOD notes flagged it explicitly.
- **Conviction: MEDIUM.** Mechanically simple to add; downside is it could occasionally block an otherwise-clean trade in tight-cash regimes.

- **Industrials sector-concentration soft cap (observation, no rule change yet).** Industrials at $4,764.93 = 54% of deployed (XLI + CAT + GE) with 2/2 satellite slots at cap. Rule 10 sector-kill would force a 3-position liquidation in one step. The buy-side gate's ≤2 satellites/sector cap is a per-name check; there is no aggregate sector $ cap. Worth one more week of observation before proposing a fix — the elevated concentration may simply reflect that Industrials is the leading cyclical sub-sector (XLI +12% YTD per Vantage / +13.1% trailing 6mo per Schwab). If a different sector takes the lead next week and the screen doesn't naturally rotate, then propose.
- **Conviction: LOW (observation only).**

- **Rule 8 ladder — keep as-is, first fire was clean.** XLB +4.26% → 7% trail per `sizing.py ladder` worked exactly as specified. No proposed change. Next milestone is the +7% core scale-out tier (XLB $53.586 = 2nd tier trigger).

- **Rule 16 momentum-decay — keep as-is, chain BREAK validated.** CAT 1 of 2 → reset on Thu's +2.72pp SPY outperformance is exactly the protection the conjunction (below entry AND lagging SPY) was designed to provide. The rule held CAT through the CPI shock and was vindicated by the PPI bounce. No proposed change.

- **Satellite-sleeve check (v3 spec):** Week 6 satellite UNDERperformed core (-$27.27 vs +$3.56); Week 7 satellite UNDERperformed core ($14.27 vs $82.46). Only 2 weeks of v3 data — the 3+ consecutive-week threshold for the shrink-satellite proposal is NOT yet met. Continue observation. If Week 8 also shows satellite < core, the shrink proposal lands on Friday Jun 19 weekly-review.
- **Conviction: deferred — observation continues.**

- **Prior RSP-of-last-resort proposal (Weeks 4–5) — kept on file at LOW conviction.** v3 satellite sleeve has now placed 2 entries in 2 weeks (CAT + GE); capital deployment fully utilized (overshooting, actually). No re-promotion needed.

## Week ending 2026-06-19

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,078.31 (Week 7 ending) |
| Ending portfolio | $10,283.16 |
| Week return | +$204.85 (+2.034%) |
| S&P 500 week | +0.93% (7,431.46 Fri Jun 12 → 7,500.58 Thu Jun 18; Fri Jun 19 Juneteenth holiday — no session) |
| Bot vs S&P | **+1.10% (beat)** — 3rd consecutive benchmark-beat week |
| Alpha vs SPX (v3) | **+1.10% (headline)** — 3rd consecutive alpha week (Week 6 +2.10%, Week 7 +1.09%, Week 8 +1.10%) |
| Core/Satellite P&L (v3) | core -$45.95 (-1.13% of ~$4.0K core capital) / satellite +$255.41 (+5.76% of ~$4.4K satellite capital) — **satellite OUTPERFORMED core massively; breaks 2-week underperformance streak** |
| Trades | 1 BUY (BTSG) + 1 CLOSE (XLE) — W:0 / L:1 / open:5 |
| Win rate | 0% (1 closed loss, 0 wins) |
| Best trade | CAT +7.67% unrealized vs entry / +8.27% week move ($910.57 → $985.82) |
| Worst trade | XLE realized -3.62% (Rule 6 trail-stop fire Mon Jun 15) |
| Profit factor | 0.00 (1 closed loss, 0 wins) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) — **8 consecutive weeks of zero day trades** |
| Capital deployment | 82.64% EOD (cleanly inside v3 75–85% target band) |
| Phase P&L | +$283.16 (+2.83%) — **fresh phase HWM reached Thu Jun 18 ($283.49), held flat through Fri holiday** |

### Closed Trades
| Ticker | Entry       | Exit       | P&L                | Notes |
| ------ | ----------- | ---------- | ------------------ | ----- |
| XLE    | $57.290588  | $55.218235 | -$70.46 (-3.62%)   | Rule 6 trail-stop fire Mon Jun 15 08:39 CT (autonomous, pre-routine) on weekend WTI -6.6% gap-down + Iran-ceasefire headline; T+33 from May 13 BUY, DTC untouched. **First Rule 6 trail-stop fire of v3 phase** — rule worked exactly as designed (10% canonical trail caught a structural decline before deeper drawdown). |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized        | Stop                        | Tier      |
| ------ | ----------- | -------- | ----------------- | --------------------------- | --------- |
| BTSG   | $64.45      | $66.25   | +$37.80 (+2.79%)  | $60.003 (trail 10%)         | satellite |
| CAT    | $915.635    | $985.82  | +$140.37 (+7.67%) | $921.4533 (trail 7%)        | satellite |
| GE     | $335.06     | $357.64  | +$67.74 (+6.74%)  | $339.171 (trail 7%)         | satellite |
| XLB    | $50.08      | $51.81   | +$69.20 (+3.45%)  | $49.5783 (trail 7%)         | core      |
| XLI    | $173.713636 | $180.91  | +$79.16 (+4.14%)  | $170.1156 (trail 7%)        | core      |

### What Worked
- **3rd consecutive benchmark-beat week.** Bot +2.034% vs SPX +0.93% → **+1.10% alpha**. The 3-week streak (Week 6 +2.10% NFP-risk-off, Week 7 +1.09% CPI/PPI binary, Week 8 +1.10% FOMC/Warsh + Iran-ceasefire) confirms the v3 design (core + satellites) is delivering across multiple tape regimes — not just one favorable setup.
- **First Rule 6 trail-stop fire of v3 phase — XLE.** Mon Jun 15 08:39 CT autonomous exit on weekend WTI -6.6% gap-down + Iran-ceasefire headline. 34 sh @ $55.218235, -$70.46 / -3.62% realized vs entry $57.290588. T+33 from May 13 BUY = swing exit, DTC untouched, no Rule 14 conflict. The 10% canonical core-ETF trail caught a structural Energy decline before it became a deeper drawdown (XLE went on to print lower lows after the trigger). **Rule 6 is no longer untested — confirmed live for 1 trigger.**
- **Three Rule 8 ladder fires in three consecutive days.** XLI Tue mid (10%→7% on +4.091% first ETF threshold), GE Wed mid (10%→7% on +7.70% first stock threshold), CAT Thu mid (10%→7% on +7.66% first stock threshold). All three fires returned correct targets from `sizing.py ladder`, passed Rule 9 distance checks, moved stops UP (not down), and locked in 5.16–9.45% post-tightening cushions. The ladder machinery is firing reliably across both core (XLB Fri Jun 12 + XLI Tue) and satellite (GE Wed + CAT Thu) — 4 total tier-1 fires across Weeks 7+8.
- **2nd v3 satellite entry — BTSG Healthcare clean execution.** Tue Jun 16 21 sh @ $64.45 = $1,353.45 = 13.29% equity (risk-parity sized via `sizing.py size --stop-frac 0.15`, exact match to pre-market plan). Limit $64.55 (0.10% slippage); fill $64.45 = **$0.10/sh price improvement** = $2.10 saved. Passed all 9 Buy-Side Gate prongs including ETF-core floor 48.8% ≥ 45%, ≤2 satellites/sector check (Healthcare 1 ≤ 2), DTC=0. Stale-quote early-session handling: first quote 13:33Z showed ap=$74.09/bp=$54.72 (26% spread, single-venue IEX) → re-query at 13:37Z returned clean book ap=$64.49. Pre-open quote-staleness lesson from Week 3 captured operationally.
- **Satellite sleeve broke 2-week underperformance streak.** Week 6 satellite -1.51% per-capital vs core +0.06%; Week 7 satellite +0.50% vs core +1.37%; **Week 8 satellite +5.76% vs core -1.13%** — first satellite outperformance of v3 and by a wide margin. CAT alone moved +$150.50 unrealized (+8.27% week), GE moved +$67.11 (+6.67% week), BTSG +$37.80 day-3. The 3+ consecutive-week shrink-satellite trigger is now reset.
- **FOMC + Warsh first presser absorbed cleanly.** Wed Jun 17 FOMC + first Warsh press conference (modestly hawkish dot-plot tone) closed +0.20% on the day for the bot. Materials (XLB -1.33% Wed, -0.40% Thu) compressed on rate-sensitivity as expected, but Industrials cluster (CAT/GE/XLI) and Healthcare (BTSG) all held bid. Book broadly green through the binary — Tue → Thu phase HWM expanded from +$165.55 → +$283.49 (+71% phase-HWM expansion across the binary cycle).
- **Visa-aware machinery flawless for 8th consecutive week.** DTC held 0/5 all week; BTSG trailing stop placed at Wed Jun 17 15:00 CT per Rule 13 (1-day delayed by Tue Alpaca 504 outage — retried successfully); Rule 14 pre-flight passed every midday (DTC=0); Rule 15 same-day skip protected BTSG Tue + XLE was T+33 not same-day. Eight weeks, zero day trades, zero same-day exit risk.
- **Sector diversification improved post-BTSG.** XLE exit + BTSG add rotated Energy → Healthcare, reducing Industrials concentration from Mon's 69.81% peak to Tue–Fri's 58.4–59.4% range. ETF-core floor cleared 48% throughout. First non-Industrials/Materials sector since Week 6 XLP rotation.

### What Didn't Work
- **First realized loss of the v3 phase — XLE -$70.46.** While Rule 6 worked as designed (caught a structural decline before deeper drawdown), the absolute loss matters: XLE was the book anchor for 8 consecutive weeks. The weekend Iran-ceasefire headline + WTI -6.6% gap was an asymmetric headline-risk event the bot's swing-only design cannot pre-empt. Phase realized P&L now -$111.04 (XLP -$40.58 Week 6 + XLE -$70.46 Week 8 = 2 Energy/Staples cyclical-defensive exits).
- **Alpaca paper-API write-path 504 outage left BTSG stop-less for 24h.** Tue Jun 16 15:00–15:11 CT: 7 consecutive POST /v2/orders attempts returned HTTP 504 server-side. Reads succeeded throughout, only the write path failed. BTSG carried NO trailing stop into Wed FOMC binary. URGENT Telegram sent Tue per spec; pre-market Wed retry pattern (re-attempt `bash scripts/alpaca.sh trailing-stop BTSG 21 10` first thing) succeeded at Wed Jun 17 daily-summary T 15:00 CT (order id 2cff1c84-00fd-4dc9-8d27-e755f885591f, stop $57.987 trail 10% hwm $64.43). 24h stop-less window during a FOMC binary represents real risk — bounded by risk-parity sizing (~$200 / 2% equity worst case) but operationally undesirable. Infrastructure issue, not a rule violation; retry pattern worked.
- **XLB cushion compressed to 4.31% Thu close — book's tightest.** Materials hawkish-FOMC pressure (Wed -1.33%, Thu -0.40%) compressed XLB's Rule 8 7%-locked stop cushion to 4.31% vs $51.81 close ($49.5783 stop). The Rule 8 tightening (Fri Jun 12 at +4% threshold) is working as designed — locking in gains at +3.45% on-cost — but any sharp Materials pullback over the 4-day Juneteenth weekend gap will trigger Rule 6 exit. Book carries the most fragile single-position trail-stop risk into the gap.
- **Industrials concentration remained elevated at 59% of deployed.** XLI ETF + CAT + GE = $5,034.57 = 59.24% of deployed at week close. The XLE auto-exit dropped this from Mon's 69.78% peak, but BTSG only displaced 16% (Healthcare) — most of the freed cash kept the cyclical book intact. A Rule 10 Industrials sector-kill (2 consecutive failed Industrials trades) would still liquidate 3 of 5 positions in one step. The structural risk flagged in Week 7 carried into Week 8 unresolved.
- **Capital deployment briefly below band Mon post-XLE exit.** Mon Jun 15 EOD deployment 68.92% (long_market_value $6,958.64 / equity $10,097.06) — below the v3 75% floor for ~24h between XLE auto-exit (Mon 08:39 CT) and BTSG fill (Tue 13:37Z). Operationally the BTSG add restored the band by Tue mid (82.49%), but the Mon overnight gap was an unhedged cash-drag window during a +0.25% market session.

### Key Lessons
- **Rule 6 (10% trailing stop) is operationally validated.** The XLE fire confirmed the core-ETF trail spec works in an asymmetric weekend-headline scenario (Iran ceasefire → WTI -6.6% gap → -3.62% open vs prior close). The trail caught the decline before it became a -7%+ Rule 7 hard-close. Rule 13's "place at close, not at entry" design held — fire was T+33 not same-day. The visa-aware machinery and the trail-stop machinery are now both validated against real-firing scenarios (Week 6 XLP Rule 16 rotation, Week 7 XLB Rule 8 first-tier, Week 8 XLE Rule 6 + multi-day Rule 8 ladder firing).
- **Rule 8 ladder cadence emerges as the dominant intraday-rule firing pattern.** Across Weeks 7–8, 4 ladder fires (XLB Fri Jun 12, XLI Tue Jun 16, GE Wed Jun 17, CAT Thu Jun 18) — all clean, all idempotent (XLB Mon Jun 15 mid had +5.40% but already at 7% trail → no re-tighten), all moved stops up by 3pp. The deterministic `sizing.py ladder` and the replace-stop-at-midday operational pattern are stable. No proposed change.
- **First satellite outperformance week vindicates v3 design.** Weeks 6+7 had satellite sleeve underperforming core on per-capital basis; Week 8 satellite +5.76% vs core -1.13% (per-capital) demonstrates the alpha sleeve can deliver — the Industrials satellites (CAT/GE) caught the post-Empire-State manufacturing momentum + post-FOMC Industrials bid. Single-stock concentration is the cost; this week, the cost paid off. Continue observation — one-week pattern not durable yet.
- **Alpaca paper-API write-path 504 outages happen and the retry-next-session pattern handles them.** First such outage of the phase. The existing pattern (URGENT Telegram on Tue, retry first-action Wed pre-market) worked. 24h stop-less window during FOMC eve + FOMC day is bounded by risk-parity sizing to ~$200 worst-case loss. Worth codifying the retry pattern explicitly as proposed below — but no rule change needed; the operational response was correct.
- **Visa-aware machinery (Rules 13/14/15) bulletproof for 8th consecutive week.** Zero day trades, zero same-day exits, every stop placed at close (XLE auto-fire was T+33 not same-day; BTSG stop placement Wed T+1 = next session not same-day). The risk lives in strategy selection (sector concentration, headline gaps) and infrastructure (Alpaca 504), not execution discipline.
- **Cyclical-leadership regime hasn't yet broken.** Bot beat SPX in 3 of last 3 weeks across NFP-risk-off, CPI/PPI binary, and FOMC/Iran-ceasefire weeks. Industrials cluster (XLI + CAT + GE) is the dominant alpha source. XLK 10s-RS rejected -4.72pp Wed AM signals tech NOT rotating leading post-FOMC; the cyclical book remains correctly positioned. A sustained tech rally would re-open the Weeks 4–5 lag — XLK re-screen Mon Jun 22 pre-market is the key telltale.

### Adjustments for Next Week
- **Monday pre-market (Jun 22, Week 9 Day 1, post-Juneteenth + 4-day market gap):** re-screen XLK 10s-RS for post-FOMC repair (currently rejected -4.72pp Wed Jun 17 AM — needs material reversion); pull weekend news flow (Israel/Iran ceasefire stability, Russia/Ukraine, any unscheduled Fed-speak Jun 19–21); confirm PCE Core Tue Jun 23 release timing; monitor for any BTSG/CAT/GE/XLB/XLI gap-down at the open (4-day gap risk over Juneteenth long weekend); satellite slots 3/3 FULL — no satellite add possible without an exit; ETF-core adds permitted if XLK/XLU/XLF or other leading-quadrant ETF passes the bars gate.
- **Watch XLB.** Book's tightest cushion at 4.31% ($49.5783 stop vs $51.81 close). Rule 8 7% trail locks in +3.45% on-cost gains but any Materials pullback over the 4-day gap fires Rule 6. Cushion math: any -4.3%+ XLB gap-down at Mon open triggers auto-exit. Industrials/Materials hawkish-FOMC pressure may carry into Mon.
- **Watch GE.** 5.16% cushion ($339.171 vs $357.64) — book's 2nd-tightest after XLB. Wed-tightened Rule 8 7% trail; +6.74% on-cost gains locked. Any -5.2% gap-down at Mon open fires Rule 6.
- **Industrials concentration 59.24% — still the single-largest structural risk.** Rule 10 Industrials sector-kill would liquidate 3 of 5 positions (XLI + CAT + GE). No history of consecutive Industrials losses (sector has only winners + carries this week), but the concentration is structural. A different-sector ETF-core add Mon would dilute — but cash is $1,784.94 = 17.36%, and the satellite slots are full.
- **BTSG Wed FOMC stop-less risk closed.** Operational priority from last week resolved. Future Alpaca 504 outages: retry first-action next-session pre-market (already standard); URGENT Telegram already standard. See proposed strategy notes below.
- **Phase P&L +$283.16 / +2.83% — strongest position of the v3 phase.** First time materially clear of the prior phase HWM. 4 unused trade slots roll into Week 9 (fresh 5-slot cap). Patience > activity (Rule 12) — no forced-add pressure.
- **Satellite-sleeve 3-week underperformance trigger RESET.** Week 8 broke the Week 6+7 pattern. No shrink-satellite proposal this week. Observation continues with a 1-week clean satellite outperformance baseline.
- **No auto-applied strategy mutations** (DECIDED G — rulebook is the safety system). See proposed strategy notes below.

### Overall Grade: A-

Strongest week of the v3 phase by every metric: 3rd consecutive benchmark-beat (+1.10% alpha), fresh phase HWM at +$283.16 / +2.83% (best of 41 trading days), 5/5 open positions positive at week end, first Rule 6 trail-stop fire executed cleanly, multiple Rule 8 ladder fires across 3 consecutive days all clean, 2nd v3 satellite entry (BTSG Healthcare) clean with $0.10/sh price improvement, satellite sleeve broke 2-week underperformance streak (+5.76% per-capital vs core -1.13%). Zero rule violations. 8 consecutive weeks of bulletproof visa-aware execution. FOMC Wed + Warsh first presser absorbed cleanly. **The half-grade ding from A is the Tue Alpaca paper-API 504 outage that left BTSG stop-less for 24h through FOMC eve + FOMC day** — infrastructure issue, not strategy failure, retry pattern worked, but the stop-less window during a binary macro print is an operational risk worth acknowledging. Also: first realized loss of the phase (XLE -$70.46 / -3.62%) — though Rule 6 worked exactly as designed catching a weekend headline-gap. XLB 4.31% cushion + Industrials 59% concentration carry structural fragility into the 4-day Juneteenth weekend gap. Graded A- to honestly weight the dominant alpha week + clean v3-machinery firings + 8-week execution discipline against the Alpaca infrastructure risk window + the cyclical-concentration carry-into-gap risk that didn't bite this week but is structurally present.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Codify Alpaca 504 outage handling (v3.1 proposal, NEW THIS WEEK).** Tue Jun 16's 7-consecutive HTTP 504 on POST /v2/orders left BTSG stop-less for 24h through FOMC eve + FOMC Wed. The retry pattern (URGENT Telegram on the failed routine + retry first-action next-session pre-market) worked, but it is currently implicit in the routine prompt rather than explicit in the rulebook. Proposal: add a "Rule 17 (operational, visa-neutral)" — if any Rule 13 trailing-stop placement fails after 3+ Alpaca write-path retries (regardless of HTTP code), (a) URGENT Telegram MUST send (not just normal), (b) the next routine (typically pre-market the following session) MUST execute the retry as its FIRST action before any other gating, (c) if the next-session retry also fails, escalate to operator with explicit "manual stop placement required via Alpaca UI" instruction.
- **Rationale:** The operational response Tue→Wed was correct but ad-hoc. Codifying it removes ambiguity for future outages and ensures the URGENT/retry-first/escalation pattern is invariant regardless of which routine is next.
- **Evidence:** TRADE-LOG.md 2026-06-16 STOP-PLACEMENT-FAILED row (7 consecutive 504s, manual decision to wait for next session); 2026-06-17 STOP PLACED row (retry succeeded as first action at daily-summary, NOT pre-market — proposal would tighten to "first action of next routine"). No prior precedent in 8 weeks of v3 operation.
- **Conviction: MEDIUM.** Operationally simple to add; downside is none (codifies an existing correct pattern).

- **Industrials concentration soft cap (escalated from Week 7 LOW → Week 8 MEDIUM).** Industrials held 58.4–69.8% of deployed for the entire week. Even post-XLE-exit + BTSG-add the concentration only fell to 58.7% (Tue mid) and ratcheted back to 59.24% by Thu close as Industrials marked up. Rule 10 sector-kill (2 consecutive failed Industrials trades) would still liquidate 3 of 5 positions. The buy-side gate's per-name ≤2 satellites/sector check has caught the satellite cap (2/2 in Industrials) but not the aggregate $ concentration (54–59% of deployed across an entire sector). Proposal: add a 10th buy-side gate check — `sector_deployed_pct ≤ 50%` (aggregate, including ETF core + satellites in that sector). If any single sector would exceed 50% of deployed post-fill, defer the add.
- **Rationale:** A 60%+ single-sector concentration in a $10K paper account = a single sector-kill liquidates the majority of the book in one step. The 50% threshold is the minimum diversification floor needed to keep the bot from being a single-sector bet on Industrials (or any sector). 50% chosen as half of deployed = 2 dominant sectors minimum.
- **Evidence:** TRADE-LOG.md weeks 7+8 — Industrials concentration ratcheted from 48% (week 7 start) → 54% (week 7 close, with GE add) → 69.78% Mon Jun 15 EOD (post-XLE exit) → 58.7% Tue mid → 59.24% Thu close (mark-to-market). Three weekly-reviews now flagging this as the single-largest structural book risk.
- **Conviction: MEDIUM** (up from Week 7 LOW). The structural risk has now persisted for 3 consecutive weeks; the satellite-cap check (≤2/sector) is insufficient to contain it; concentration on this account size = sector-kill liquidation risk = operational fragility.

- **Prior deployment-ceiling check (Week 7 proposal) — keep at MEDIUM, no new evidence this week.** Week 8 deployment held in band 82.49–82.70% throughout (Mon's 68.92% post-XLE-exit window restored Tue by BTSG add). No overshoot. Proposal remains on file at MEDIUM conviction; another deployment overshoot would re-promote.

- **Prior RSP-of-last-resort proposal (Weeks 4–5) — keep at LOW conviction.** v3 satellite sleeve has now placed 2 entries in 3 weeks (CAT + GE + BTSG); capital deployment fully utilized. No re-promotion needed.

- **Satellite-sleeve check (v3 spec):** Week 6 satellite -1.51% per-capital vs core +0.06%; Week 7 satellite +0.50% vs core +1.37% — satellite UNDERperformed 2 weeks; **Week 8 satellite +5.76% vs core -1.13% — satellite OUTPERFORMED.** The 3+ consecutive-week shrink-satellite trigger is RESET. No shrink-satellite proposal this week. Observation continues with 1 week of satellite outperformance.
- **Conviction: deferred — observation continues with reset baseline.**

- **Rule 6 (10% trailing stop) — first phase fire, keep as-is.** XLE auto-exit Mon Jun 15 worked exactly per spec; the 10% canonical trail caught a structural decline before deeper drawdown; T+33 swing exit = DTC untouched. No proposed change. Rule 6 is now validated against a real firing scenario.

- **Rule 8 ladder — multi-day firing pattern confirmed, keep as-is.** 4 ladder fires across Weeks 7+8 (XLB Fri Jun 12, XLI Tue Jun 16, GE Wed Jun 17, CAT Thu Jun 18); all clean, all idempotent, all moved stops up by 3pp. The deterministic `sizing.py ladder` + replace-stop-at-midday pattern is stable. No proposed change. Next milestone is a +7% ETF or +10% stock 2nd-tier trigger (scale-out 1/3 + tighten further) — first satellite-tier scale-out tier hit would lock partial gains and free cash; XLB at $52.32 needs $53.586 for 2nd ETF tier; CAT +7.67% on-cost is close to but below +10% 2nd stock tier ($1,007.20 target); GE +6.74% on-cost is below +10% 2nd tier ($368.57 target). All within reach next week if Industrials cluster extends.

- **Rule 16 momentum-decay — silent week 8, no fires.** All 5 positions above entry throughout = not flag-eligible by definition. Rule still validated by Week 6's XLP rotation fire + Week 7's CAT chain-break. No proposed change.

## Week ending 2026-06-26

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,283.16 (Week 8 ending) |
| Ending portfolio | $10,449.80 |
| Week return | +$166.64 (+1.620%) |
| S&P 500 week | -1.984% (Jun 18 close 7,500.58 → Jun 26 close 7,351.82; Jun 19 Juneteenth holiday — no session) |
| Bot vs S&P | **+3.604% (beat)** — 4th consecutive benchmark-beat week; widest weekly alpha of v3 |
| Alpha vs SPX (v3) | **+3.604% (headline)** — 4-week alpha streak now W6 +2.10% / W7 +1.09% / W8 +1.10% / W9 +3.60% |
| Core/Satellite P&L (v3) | core -$1.52 (-0.04% of ~$3.9K core capital) / satellite +$168.18 (+4.01% of ~$4.2K satellite capital) — **satellite OUTPERFORMED core for 2nd consecutive week, massive again** |
| Trades | 0 BUYS + 2 partial SELLS (scale-outs Jun 25 CAT/GE) + 1 FULL EXIT (Jun 26 CAT runner stop fire) — W:3 slices / L:0 / open:4 |
| Win rate | 100% (3 closed slices, all positive: CAT scale-out +14.70%, GE scale-out +11.33%, CAT runner +8.58%) |
| Best trade | CAT scale-out +14.70% ($1050.21 vs $915.635 — Jun 25 PCE-day rip) |
| Worst trade | CAT runner +8.58% ($994.16 vs $915.635 — Jun 26 14:51 CT trail-stop fire on 6% trail from HWM $1057.07) — all 3 slices positive |
| Profit factor | n/a (3 wins / 0 losses — division by zero; total realized +$251.08) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) — **9 consecutive weeks of zero day trades** |
| Capital deployment | 59.78% EOD (BELOW v3 75–85% target band — intentional/expected post-CAT exit; $2,635 cash headroom to 85% ceiling) |
| Phase P&L | +$449.80 (+4.50%) — **fresh phase EOD HWM eclipsed Mon Jun 22 EOD +$361.16 by +$88.64; intraday Thu Jun 25 phase HWM +$577.73 was the absolute peak** |

### Closed Trades
| Ticker | Entry       | Exit         | P&L                       | Notes |
| ------ | ----------- | ------------ | ------------------------- | ----- |
| CAT 1sh | $915.635   | $1050.21     | +$134.575 (+14.70%)       | Jun 25 PCE-day Rule 8 scale-out #1 (2nd stock-tier +10% trigger); satellite, T+21 swing, DTC=0. **2nd Rule 8 scale-out fire of v3 phase** (1st was XLE Week 8 trail-stop — different rule). |
| GE 1sh  | $335.06    | $373.04      | +$37.98 (+11.33%)         | Jun 25 PCE-day Rule 8 scale-out #1 (2nd stock-tier +10% trigger); satellite, T+13 swing, DTC=0. Same midday as CAT — concurrent first satellite scale-outs of v3 phase. |
| CAT 1sh | $915.635   | $994.16      | +$78.525 (+8.58%)         | Jun 26 Rule 6 trail-stop fire 14:51 CT on remaining runner (1sh) — 6% trail (locked Jun 22) from HWM $1057.07 → stop $993.6458; T+22 swing, DTC=0. **First v3 satellite trailing-stop FULL exit on a runner** — Rule 6/8 chain executed cleanly (scale-out at +14.70% locked partial, runner trailed +8.58% before fire). |
| **CAT trade total** | **$915.635** | **avg ~$1022** | **+$213.10 (+11.64%)** | Full CAT 2sh trade closed in 2 events over 22 sessions (Jun 4 BUY → Jun 25 + Jun 26 SELL). Clean Rule 8 ladder + trail-stop pattern. |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized       | Stop                    | Tier      |
| ------ | ----------- | -------- | ---------------- | ----------------------- | --------- |
| BTSG   | $64.45      | $68.98   | +$95.13 (+7.03%) | $65.7696 (trail 7%)     | satellite |
| GE     | $335.06     | $369.00  | +$67.88 (+10.13%) | $351.2686 (trail 6%)   | satellite |
| XLB    | $50.08      | $51.64   | +$62.40 (+3.12%) | $49.5783 (trail 7%)     | core      |
| XLI    | $173.713636 | $181.39  | +$84.44 (+4.42%) | $173.0637 (trail 7%)    | core      |

### What Worked
- **Widest single-week alpha of v3 phase (+3.60%).** Bot +1.620% vs SPX -1.984% on a PCE-week ending with broad-market chop. The 4-week streak (W6 +2.10% NFP risk-off, W7 +1.09% CPI/PPI binary, W8 +1.10% FOMC/Iran-ceasefire, **W9 +3.60% PCE-week**) decisively confirms the v3 design (core + satellites) is delivering across multiple tape regimes. Cumulative alpha across the 4-week streak: +7.89pp vs SPX.
- **First concurrent v3 satellite scale-outs — CAT + GE on PCE-day Thu Jun 25.** Both stocks crossed +10% 2nd-stock-tier intraday post-PCE: CAT +14.71% / GE +11.58%. `sizing.py ladder` returned correct targets for both; the routine executed `replace-stop` (to free qty held by trailing stops) → market scale-out → atomic. Total realized: +$172.555 (CAT slice $134.575 + GE slice $37.98). Cash freed: +$1,423.25. **First v3 PCE-day binary executed actively (not just held through) — fresh phase HWM +$577.73.**
- **Second v3 satellite exit cleanly — CAT runner Rule 6 trail-stop fire Fri Jun 26.** The 1sh runner remaining post-scale-out trailed at the 6% lock-in from HWM $1057.07 (Thu PCE peak); Fri 14:51 CT pullback to $994.16 hit the stop $993.6458 → +$78.525 / +8.58% realized. Combined with Thu's scale-out, full CAT trade banked +$213.10 / +11.64% over 22 sessions — a textbook Rule 8 ladder (scale-out at second tier) + Rule 6 trail-stop (runner trail-out) chain. T+22 = clean swing exit, DTC untouched.
- **Industrials concentration self-resolved through Rule 8 scale-outs.** Sector started week at 59.55% of deployed (over v3.1 50% cap, blocking new Industrials adds), ended week at **43.75%** (cleanly under cap, -15.8pp). The mechanism was organic: Rule 8 second-stock-tier scale-outs (CAT + GE on Thu) trimmed Industrials sat sleeves; CAT runner exit Fri removed the last Industrials sat exposure. The W8 "Industrials soft cap" proposal (MEDIUM conviction) is now effectively addressed by the existing ladder + trail-stop machinery — the structural risk unwinds at +10% stock-tier triggers, faster than any rule could mandate.
- **Visa-aware machinery flawless for 9th consecutive week.** DTC held 0/5 all week; CAT runner exit T+22 = swing (not day trade); both Thu scale-outs T+13 / T+21 = swings; Rule 14 pre-flight passed every midday; Rule 15 N/A (no same-day positions exited). Nine weeks, zero day trades, zero same-day exit risk.
- **PCE Thu binary navigated actively + constructively.** The book absorbed the PCE 08:30 ET print with a +$243.69 / +2.36% Thu rip; all 5 positions green Thu; Rule 8 ladder fired on 2 satellites concurrently. PCE-day is the v3 phase's largest binary so far — system didn't just hold through it but actively unwound concentration into strength.
- **Capital deployment & sector book healthy post-week.** Cash $4,202.33 (40.21% of equity); 4 surviving positions all positive; ETF core 65.00% of deployed (well above 45% floor); Industrials 43.75% / Materials 33.07% / Healthcare 23.18% — most balanced sector mix since Week 6 XLP rotation. 2.0 satellite slots open into Week 10 (Healthcare 1/2 + Industrials 1/2 + Tech/Discretionary/Staples/Energy 0/2).

### What Didn't Work
- **Pre-market routine did NOT run / log on Fri Jun 26.** `RESEARCH-LOG.md` has no Jun 26 entry; `TRADE-LOG.md` Day 46 EOD note explicitly states "no pre-market research run". The EOD snapshot still wrote and Friday's CAT trail-stop fired autonomously (the trail was already armed from Thu), but the audit trail has a 1-session hole at the most consequential session of the week (post-PCE digestion + week close + open Tech/satellite slot screening opportunity). Fourth documentation gap of the phase (May 8 / May 11 / May 28 / Jun 26). Worth flagging cadence guardrail proposal.
- **Sub-unit scale-out skipped Mon Jun 22 CAT (qty=2).** Mon midday CAT crossed +11.66% (2nd stock-tier); Rule 8 returned scaleouts_due=1 → routine attempted scale-out qty `$((2/3))=0` and **SKIPPED** ("sub-unit qty — known v3 limitation"). However, Jun 25 mid called `sizing.py scaleout` directly which returned `sell_qty=1, reason=ok` for cur_qty=2 — inconsistent qty-computation logic between Mon's routine-side arithmetic and Thu's `sizing.py scaleout`. Cost analysis: Mon's CAT close was $1,016.93; Thu's scale-out filled $1,050.21 = +$33.28/sh better → the skip was bailed out by PCE-day rip, but the inconsistency is a real bug surface. Resolution proposed below.
- **CAT runner exited via trail-stop, not 3rd-tier scale-out (+15%).** The CAT runner reached intraday HWM $1057.07 Thu = +15.45% — just barely cleared the +15% 3rd stock-tier (`scaleouts_due=1` for tier 3 per Rule 8: "+15%→trail 4%"). But Rule 8's +15% tier is **trail-only (no scale-out)**: target_trail_pct=4. The trail tightened to 4% would have been $1057.07 × 0.96 = $1,014.79 — actually HIGHER than the 6% lock-in ($993.6458). The routine did NOT tighten to 4% on Thu (`sizing.py ladder` returned the highest threshold met = 6% from +10% tier; the +15% trail-4% threshold is a higher SO_DONE state). **The system missed the +15% trail-4% tighten on Thu intraday.** Cost: CAT runner exited $994.16 instead of potentially $1,014.79 = -$20.63/sh = -$20.63 across the 1sh runner. Small dollar impact ($20), but a real Rule 8 mechanic gap. Resolution proposed below.
- **Capital deployment fell below band post-scale-out (59.78% < 75% floor).** Intentional/expected per Rule 8 design (scale-outs unwind concentration into cash), but the bot now carries 40% cash into Mon Jun 29 — the largest cash drag in the v3 phase. SPX -1.98% week means the cash wasn't hurt this week, but a Mon Jun 29 broad-market rally would expose cash drag. Re-arm headroom is now substantial ($2,635); Mon pre-market must screen aggressively (Tech satellite + XLK ETF core gates).
- **Tue-Wed pullback gave back ~half of Mon's +$78 rip.** Mon's intraday phase HWM was +$382.96; Tue closed at +$218.87 (gave back $164); Wed clawed back to +$334.04. The Mon→Wed chop on Industrials weakness was the "what didn't work" microstructure — CAT pulled back from $1,016.93 Mon close to $984.24 Tue close (-3.22% / -$32.69 unrealized), retracing nearly all of Mon's intraday breakout. The PCE-day Thu rip recovered everything (+$216.57 phase expansion Mon HWM → Thu HWM), but the mid-week vol exposed how concentrated the book was on Industrials pre-Thu scale-outs.

### Key Lessons
- **The v3 ladder + trail-stop chain is now fully validated end-to-end.** Across Weeks 7–9, the bot has now executed: Rule 8 first-tier trail-tighten (XLB Fri Jun 12), Rule 8 first-tier on satellites (XLI Tue Jun 16, GE Wed Jun 17, CAT Thu Jun 18), Rule 8 second-tier scale-outs (CAT + GE Thu Jun 25), Rule 6 trail-stop fire on a satellite runner (CAT Fri Jun 26). The full Rule 8 ladder pattern (first-tier tighten → second-tier scale-out → trail-out via Rule 6) has now fired on at least one full satellite trade (CAT). **The v3 architecture works as designed.** No theoretical gaps remaining.
- **Satellite sleeve sustained outperformance — 2 weeks running.** W8 sat +5.76% vs core -1.13% (per-capital); **W9 sat +4.01% vs core -0.04%** (per-capital). The "shrink satellite" proposal trigger (3+ consecutive weeks of satellite UNDERperformance) is firmly RESET; we now have a 2-week streak of satellite outperformance. The single-stock satellite gate (v3) is paying for its added complexity.
- **Industrials concentration unwinds organically through the ladder.** No rule change was needed to address the 59% Industrials concentration — Rule 8 scale-outs + the trail-out of the CAT runner did the work in 2 sessions. The W8 "Industrials soft cap" proposal is downgradeable to LOW conviction (the mechanism for unwinding already exists). Keep on file for the case where concentration appears in a sector that doesn't reach Rule 8 tiers.
- **Pre-market routine reliability matters most on event days.** The Fri Jun 26 pre-market miss happened on the post-PCE digestion session with newly-freed Healthcare/Industrials sat slot opportunity and substantial cash re-arm room. Even if Fri's decision would have been HOLD (Friday-into-weekend Rule 12 patience), the absence of the audit trail leaves uncertainty about whether ideas were screened at all. The cadence guardrail flagged in W3 (May 8/11) and W5 (May 28) is now a 4-event phase pattern. Worth a small operational rule.
- **Rule 8 +15% tier is trail-only, not scale-out — the routine wasn't checking this tier on Thu.** The current `sizing.py ladder` call pattern queries the **highest tier reached** but the SO_DONE state machine only tracks scale-out completion, not trail-tightening completion. CAT hit +15% intraday Thu and the routine did NOT tighten the trail to 4% — only to 6% (which was already set Jun 22). This is a code/spec gap. Cost was minimal this week ($20 on CAT runner) but is a real Rule 8 mechanic gap.
- **Visa-aware machinery (Rules 13/14/15) bulletproof for 9th consecutive week.** Zero day trades, zero same-day exits, every stop placed at close (all CAT runner trail was armed Jun 4 + tightened Jun 22 + re-placed Jun 25 — all routine post-15:00 CT). The risk lives in strategy selection (sector concentration, satellite gate quality) and infrastructure (Alpaca 504 historical), not execution discipline.

### Adjustments for Next Week
- **Monday pre-market (Jun 29, Week 10 Day 1):** post-PCE Mon, 2.0 open satellite slots, deployment 59.78% (below band, re-arm priority). Screen: (1) **XLK ETF-core** — 10s-RS sustained 2-session confirmation post-PCE (Thu was sustained day-1 at +1.65pp, Fri pre-market not screened — Mon must verify); deployment headroom $2,635 cleanly fits 11sh @ ~$184 = $2,025; (2) **Tech satellite candidates** (AVGO / NVDA / others) if XLK rotates leading + a stock-level RS confirmation; (3) **Healthcare satellite** for 2nd slot (BTSG cluster expansion candidate); (4) **Industrials satellite** for 2nd slot if XLI/cluster keeps leading (1 slot freed by CAT exit); (5) **Discretionary/Staples/Energy** if RS rotates. Rule 12 patience > forced add — only deploy if a clean gate-passing idea emerges.
- **Watch XLB.** Book's tightest cushion at 4.05% ($49.5783 stop vs $51.64 close). Materials hawkish-FOMC compression continues; first-etf-tier trigger ($52.083 = +4%) is within 0.85% — a green Mon could trigger first Rule 8 etf-tier fire (trail 7% → 7% i.e. no further change, but flag for ladder progression).
- **Watch GE.** Locked at 6% trail post-Thu tighten; cushion 4.86%. Remaining 2sh after Thu scale-out is the runner; next scale-out tier at +25% = $418.83 (currently +10.13% — meaningful runway). Operational mirror of how CAT unwound this week.
- **Watch BTSG.** Locked at 7% trail post-Wed Jun 24 tighten; cushion 4.71%. First-stock-tier was Wed at +6%; second-tier +10% would trigger scale-out + 6% trail. Currently +7.03% — needs +2.85% more to fire.
- **Watch XLI.** ETF core 7% trail (Tue Jun 16 lock); first-etf-tier was already met (+4%); next milestone is +7% etf-tier (+5% trail + scale-out 1/3) at $185.87. Currently +4.42% — within reach on 2-3 strong sessions.
- **No same-sector adds in Industrials this week without RS+catalyst.** Although the v3.1 sector cap mechanically permits new Industrials (1 sat slot open + sector at 43.75% < 50%), the post-PCE cyclical rip may have exhausted the easy bid. Default to non-Industrials satellites unless specific catalyst.
- **No auto-applied strategy mutations** (DECIDED G — rulebook is the safety system). See proposed strategy notes below.

### Overall Grade: A

Best week of v3 phase by every meaningful metric. **+3.60% alpha** (widest of phase, 4th consecutive beat), **fresh phase EOD HWM +$449.80 / +4.50%** (eclipses prior Mon +$361.16), **intraday Thu phase HWM +$577.73** (absolute peak), **first concurrent v3 satellite scale-outs** (CAT + GE on PCE-day, both 2nd-tier +10%), **first v3 satellite runner trail-stop full exit** (CAT 1sh Fri +8.58%), **full CAT trade closed +$213.10 / +11.64% over 22 sessions** (textbook Rule 8 ladder + Rule 6 trail-out chain). **9 consecutive weeks of bulletproof visa-aware execution.** Industrials concentration self-resolved 59.55% → 43.75% organically through Rule 8 ladder (no rule needed — mechanism worked). Satellite sleeve OUTperformed core for 2nd consecutive week (+4.01% per-capital vs -0.04%). PCE-day binary navigated actively + constructively (not just held through). **Half-grade ding from A+:** (a) Fri Jun 26 pre-market routine did not run/log — 4th cadence gap of phase; (b) Mon Jun 22 sub-unit scale-out skip on CAT (inconsistent qty arithmetic between routine-side and `sizing.py scaleout`); (c) Rule 8 +15% trail-only tier was missed on CAT Thu (the SO_DONE state doesn't track trail-only thresholds). All three are operational/spec gaps with minor dollar impact this week but are real mechanic gaps. Capital deployment falls to 59.78% — substantial Mon re-arm priority. Graded A to honestly weight 4 v3-firsts + widest alpha + strongest absolute P&L week + 9-week visa discipline against the operational gaps that didn't bite this week but are real spec ambiguities.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Codify pre-market cadence guardrail (v3.2 proposal, NEW THIS WEEK).** Pre-market routine did not run/log on Fri Jun 26 (no `RESEARCH-LOG.md` entry); Thu Jun 25 EOD snapshot also failed to log + commit historically (May 28 / Jun 26 confirmed; May 8/11 earlier). Phase pattern: 4 cadence gaps in 46 trading days = 8.7% session-skip rate on documentation. Proposal: add a "Rule 18 (operational, visa-neutral)" — **every trading day, every routine MUST write to its corresponding log file even if the decision is HOLD or no-op**. The next routine (typically daily-summary at 15:00 CT) MUST, as its FIRST action before any state pull, scan today's prior routines' log entries — if any expected routine (pre-market, market-open, midday) is missing for today, send an URGENT Telegram naming the missing routine and write a placeholder row to the corresponding log noting "MISSING ROUTINE — investigate cron". Rule 18 never places or cancels a trade — it is day-trade-neutral and visa-neutral.
- **Rationale:** Documentation gaps break audit-trail continuity and obscure whether ideas were screened. The Fri Jun 26 gap happened on a post-PCE session with newly-freed satellite slots — the most consequential session of the week. Codifying detection + URGENT escalation closes the operational loop without rule-mutating the trading logic.
- **Evidence:** `RESEARCH-LOG.md` has no 2026-06-26 entry. `TRADE-LOG.md` Day 46 EOD note: "Pre-market plan today: no pre-market research run (RESEARCH-LOG.md has no Jun 26 entry — pre-market routine did not fire/log this morning)". Prior phase gaps: May 8 (no daily-summary), May 11 (no daily-summary), May 28 (no daily-summary — flagged W5).
- **Conviction: HIGH.** Operationally simple (a grep over today's log files + Telegram alert); zero trading-logic impact; addresses a 4-event pattern.

- **Fix sub-unit scale-out qty inconsistency between routine arithmetic and `sizing.py scaleout` (v3.2 proposal, NEW THIS WEEK).** Mon Jun 22 midday: routine attempted scale-out via shell arithmetic `$((CUR_QTY/3))=$((2/3))=0` → SKIPPED. Thu Jun 25 midday: routine called `sizing.py scaleout` → returned `sell_qty=1, reason=ok` for cur_qty=2. Same input (CAT 2sh at second-stock-tier), different output (skip vs sell 1sh). Proposal: **all scale-out qty decisions in the midday routine MUST go through `sizing.py scaleout`** — remove the shell-arithmetic path. Codify the canonical 1/3 policy in `sizing.py` only.
- **Rationale:** The skip on Mon Jun 22 was bailed out by PCE-day rip but is a real operational bug surface. `sizing.py scaleout` should be the single source of truth (mirrors Rule 1 of v3 design: "safety-critical math is deterministic in scripts/sizing.py"). If `sizing.py scaleout` returns 1sh for cur_qty=2, the routine should respect it; if the canonical policy is "ceiling(qty * 1/3)" or "min(1, due) when qty ≥ 2" the routine should not silently override.
- **Evidence:** TRADE-LOG.md 2026-06-22 midday note: "Scale-out SKIPPED (sub-unit qty — known v3 limitation for small-share satellites; flagged for Friday weekly-review proposal)". TRADE-LOG.md 2026-06-25 midday note: "CAT (cur_qty=2, due=1, done=0) → `sell_qty=1, reason=ok`". Inconsistent outputs for same inputs across consecutive midday runs.
- **Conviction: HIGH.** Codifies an existing-but-inconsistent pattern; zero strategy-logic mutation; addresses a Rule-8 mechanic gap.

- **Rule 8 +15% trail-only tier — fix SO_DONE state machine to track trail-only thresholds (v3.2 proposal, NEW THIS WEEK).** CAT hit intraday HWM $1057.07 Thu Jun 25 = +15.45% vs entry $915.635 → would have triggered the Rule 8 +15% trail-4% tier. But `sizing.py ladder` only returned tier 2 (+10% → trail 6%) because the SO_DONE state machine tracks scale-out completion, not trail-tightening completion. The CAT runner exited Fri at $994.16 instead of a potentially $1,014.79 (4% trail from HWM $1057.07) = $20.63/sh foregone. Proposal: extend `sizing.py ladder` to return the **highest tier whose target_trail_pct is strictly less than the current trail**, not just the highest tier that triggers a scale-out. Alternatively, add a separate `TRAIL_LADDER_DONE` state field distinct from `SO_DONE`.
- **Rationale:** Rule 8 lists +15% (trail 4%) and +25% (scale-out 1/3 + trail 3%) as escalating tiers. The current routine implementation conflates "tier reached" with "scale-out fired"; the intermediate trail-only tier (+15%) gets skipped if the position hasn't fired all prior scale-outs in sequence. CAT hit +15% intraday Thu but the trail-tighten was skipped because the +10% scale-out had just fired (1 of 2 SO_DONE).
- **Evidence:** TRADE-LOG.md 2026-06-25 EOD snapshot: CAT HWM $1057.07 (= +15.45% vs $915.635 entry); CAT close $1057.00; trail held at 6% (locked Jun 22 from +10% tier). 2026-06-26 EOD: CAT runner exited $994.16 via 6% trail — would have exited $1,014.79 via 4% trail had it been set. Foregone P&L: $20.63.
- **Conviction: MEDIUM.** Small dollar impact this week (~$20) but a real Rule 8 mechanic gap; will compound on future +15% or +25% intraday spikes. Requires a code change to `sizing.py ladder` semantics.

- **Industrials concentration soft cap (W8 MEDIUM proposal) — DOWNGRADE to LOW conviction.** Week 9 demonstrated the existing Rule 8 ladder + Rule 6 trail-stop machinery organically unwound 59.55% Industrials concentration to 43.75% in 2 sessions without any rule change. The W8 proposal (≤50% aggregate-sector cap) becomes redundant when sat positions reach +10% intraday and scale out. Keep on file for the case where concentration exists in a sector that doesn't reach Rule 8 tiers (e.g., flat-but-non-decaying positions).
- **Conviction: LOW (downgraded from MEDIUM).**

- **Satellite-sleeve check (v3 spec):** W6 sat -1.51% vs core +0.06% (sat under); W7 sat +0.50% vs core +1.37% (sat under); W8 sat +5.76% vs core -1.13% (**sat OVER**); **W9 sat +4.01% vs core -0.04% (sat OVER, 2nd consecutive).** 2 weeks of satellite outperformance; the shrink-sat trigger (3+ consecutive UNDER) is firmly RESET. No proposal this week.
- **Conviction: deferred — observation continues with 2-week satellite outperformance streak; no shrink-sat pressure.**

- **Prior deployment-ceiling check (W7 MEDIUM proposal) — confirmed already in v3.1 rulebook.** Re-reading TRADING-STRATEGY.md Buy-Side Gate v3.1 includes: "Deployment ceiling (v3.1): after this fill, capital deployment stays within the Rule 5 band: `(long_market_value + position_cost) / equity ≤ 0.85`." The check is enforced in practice (Wed Jun 24 pre-market XLK rejected on this exact gate). W7 proposal was already applied; closing this proposal as RESOLVED.
- **Conviction: CLOSED (already implemented in v3.1).**

- **Prior Rule 17 stop-placement-failure escalation (W8 MEDIUM proposal) — already in v3.1 rulebook.** Re-reading TRADING-STRATEGY.md: Rule 17 is present and codified. W8 proposal was already applied; closing this proposal as RESOLVED.
- **Conviction: CLOSED (already implemented in v3.1).**

- **Prior RSP-of-last-resort proposal (Weeks 4–5) — keep at LOW conviction.** v3 satellite sleeve continues to deploy effectively (CAT trade just closed +11.64%; GE/BTSG running). No re-promotion needed.
- **Conviction: LOW (no change).**

- **Rule 6 (10% trailing stop) — 2nd phase fire (CAT runner), keep as-is.** XLE Week 8 was first phase fire on a core ETF; CAT Week 9 is first phase fire on a satellite runner (6% trail post-Rule 8 lock). Both fires worked exactly per spec; visa-aware swing-only exits (T+33 and T+22 respectively). No proposed change.

- **Rule 8 ladder — 2 second-tier scale-outs fired Thu Jun 25, plus the +15% trail-tier gap noted above.** Aside from the +15% gap, the +10% second-tier mechanics worked: `sizing.py ladder` returned correct targets, `sizing.py scaleout` returned correct qtys, `replace-stop` freed qty held by trailing stops, market scale-outs filled at HWM-adjacent prices, stops re-placed for new qtys. Multi-day firing pattern across W7-W9 now totals: 4 first-tier tightenings + 2 second-tier scale-outs + 1 trail-only +15% miss (CAT runner). The machinery is operationally stable but the +15% trail-only state-machine gap warrants a fix (proposal above).

- **Rule 16 momentum-decay — silent week 9, no fires.** All 5 positions above entry throughout = not flag-eligible by definition. Rule still validated by Week 6's XLP rotation fire + Week 7's CAT chain-break. No proposed change.

## Week ending 2026-07-03

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,449.80 (Week 9 ending) |
| Ending portfolio | $10,388.12 |
| Week return | -$61.68 (-0.590%) |
| S&P 500 week | +1.788% (Jun 26 close 7,351.82 → Jul 2 close 7,483.24; Jul 3 full market holiday — NYSE/Nasdaq closed for Independence Day observance) |
| Bot vs S&P | **-2.378% (lagged)** — snaps 4-week benchmark-beat streak; widest weekly negative alpha since Week 5 (-2.10%) |
| Alpha vs SPX (v3) | **-2.378% (headline)** — first negative-alpha week of the 5-week window (W6 +2.10% / W7 +1.09% / W8 +1.10% / W9 +3.60% / W10 **-2.38%**); rolling-5-week cum alpha now +5.51pp |
| Core/Satellite P&L (v3) | core +$42.52 / +1.09% of ~$3.9K core capital; satellite -$104.15 / -2.54% of ~$4.1K satellite capital — **satellite UNDERperformed core; breaks 2-week outperformance streak (W8+W9)** |
| Trades | 1 BUY (KLIC Tue Jun 30) + 1 FULL EXIT (KLIC Thu Jul 2 autonomous trail-stop) — W:0 / L:1 / open:4 (BTSG/GE/XLB/XLI carryforward) |
| Win rate | 0% (1 closed loss, 0 wins) |
| Best trade | GE +12.67% unrealized ($377.52 vs $335.06 — Industrials sat locked at 6% trail; runner runway to +25% next scale-out) |
| Worst trade | KLIC -5.89% realized (-$122.24; Rule 6 autonomous trail-stop fire Thu Jul 2 09:48 CT on NFP-day tape) |
| Profit factor | 0.00 (1 loss / 0 wins) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) — **10 consecutive weeks of zero day trades** |
| Capital deployment | 60.72% EOD (BELOW v3 75–85% target band — carryforward from Thu KLIC-exit cash release; Rule 12 patience overlay deferred Fri re-arm to Mon Jul 6) |
| Phase P&L | +$388.12 (+3.88%) — gives back $61.68 of Week 9's fresh phase EOD HWM +$449.80; Thu Jun 25 intraday phase peak +$577.73 still the untouched ceiling by -$189.61 |
| Trading sessions | 4 (Mon Jun 29, Tue Jun 30, Wed Jul 1, Thu Jul 2; Fri Jul 3 = Independence Day full market holiday, paper routine ran with 0 changes) |

### Closed Trades
| Ticker | Entry    | Exit   | P&L                | Notes |
| ------ | -------- | ------ | ------------------ | ----- |
| KLIC   | $129.64  | $122   | -$122.24 (-5.893%) | Rule 6 autonomous trail-stop fire Thu Jul 2 09:48:39 CT (order id 4d68bf36, 10% trail from HWM $135.80 = stop $122.22 → filled avg $122). T+2 swing exit from 2026-06-30 entry — DTC untouched, not a day trade per Rule 13. First v3 Tech-satellite trade + first v3 satellite trade to close for a loss (prior sat exits: XLP W6 -$40.58 core-rotation, CAT W9 +$213.10 ladder + trail-out — all others were sats winners or ETF exits). |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized        | Stop                        | Tier      |
| ------ | ----------- | -------- | ----------------- | --------------------------- | --------- |
| BTSG   | $64.45      | $69.03   | +$96.18 (+7.11%)  | $65.94165 (trail 7%)        | satellite |
| GE     | $335.06     | $377.52  | +$84.92 (+12.67%) | $359.9918 (trail 6%)        | satellite |
| XLB    | $50.08      | $52.01   | +$77.20 (+3.85%)  | $49.5783 (trail 7%)         | core      |
| XLI    | $173.713636 | $183.91  | +$112.16 (+5.87%) | $173.0637 (trail 7%)        | core      |

### What Worked
- **Rule 6 trail-stop machinery worked as designed on KLIC — first phase fire on a fresh sat.** KLIC entered Tue Jun 30 @ $129.64 → HWM $135.80 Wed EOD (Day-2 peak) → NFP-day Thu Jul 2 09:48 CT tape reversal hit stop $122.22 → filled avg $122 for -5.893% / -$122.24 realized. T+2 = clean swing exit per Rule 13 design; DTC 0/5 untouched. The 10% canonical fresh-sat trail caught a rapid post-hwm reversal (-10.16% from HWM in <24h) before it deepened; the loss was contained inside the risk-parity sizing envelope (~2% equity budgeted per position; realized -1.18% of equity vs the ~2% max). **First Rule 6 fire on a satellite entry-window position** — spec-compliant execution, no lag between hwm decay and stop trigger.
- **Held-book satellites (BTSG + GE) absorbed NFP-day weakness cleanly.** Neither triggered stops; both held above +6% and +10% thresholds respectively. GE ratcheted a fresh HWM to $382.97 Thu intraday (locked 6% trail cushion +4.64% vs close $377.52); BTSG stop ratcheted to $65.94165 on new HWM $70.905 (+4.47% cushion). The v3 ladder locks (Rule 8 6-7% trails post-first-tier) did their job protecting realized-gain locks while the fresh sat (KLIC) took the tape hit.
- **ETF core delivered +$42.52 unrealized delta on the week.** XLB +$14.80 (Materials firm on NFP-day risk-on and H2 rebalance flow), XLI +$27.72 (Industrials extending post-PCE momentum). Core sleeve +1.086% per-capital vs core capital ~$3.9K — the ETF core did its ballast job, offsetting ~40% of the KLIC realized loss. Confirms the v3 architecture (core ballast + sat alpha) provides asymmetric protection: even when a satellite loses, the core sleeve dampens the drawdown.
- **Sector diversification improved via KLIC entry (Tue) even though the trade closed for a loss.** Post-KLIC-entry Tue: Industrials fell from 44.24% → 33.05% of deployed, Tech entered fresh at 25.13%. Post-KLIC-exit Thu: Industrials back to 44.05% but the intra-week diversification meaningfully reduced concentration risk. The buy-side gate correctly identified a 4th-sector opportunity; the exit was tape-driven, not thesis-driven.
- **Zero rule violations, visa-aware machinery flawless for 10th consecutive week.** DTC held 0/5 all week; KLIC trailing stop placed at 15:00 CT Tue Jun 30 per Rule 13 (order id 4d68bf36); Rule 15 same-day skip protected KLIC on Tue midday (T+0); Rule 14 pre-flight passed every midday (DTC=0); Rule 17 first-action scan clean across every routine. Ten weeks, zero day trades, zero same-day exit risk.
- **Rule 12 patience overlay dominated Fri Jul 3.** Pre-market Fri had 1 sat slot re-opened + $2,522 deployment headroom + 4 fresh BUY slots — mechanically wide open to add. But Rule 12 correctly overlaid HOLD given shortened Fri + 3-day holiday weekend + NFP-interpretation ambiguity + KLIC-exit-T+1 anti-revenge friction. The bot's discipline held; deferred re-arm to Mon Jul 6 with a full 5-slot budget and clearer signal.

### What Didn't Work
- **Snapped the 4-week benchmark-beat streak with the widest miss since Week 5.** Bot -0.590% vs SPX +1.788% → **-2.378% alpha** — first negative-alpha week of the 5-week window (W6 +2.10% / W7 +1.09% / W8 +1.10% / W9 +3.60% / W10 **-2.38%**). SPX ripped +1.79% on a broad H2/Q3-open risk-on tape (SPY +2.17% ETF-proxy) driven by tech leadership post-NFP; the bot's non-tech book (Industrials/Materials/Healthcare + failed Tech sat) missed the leadership. **Rolling-5-week cum alpha remains positive at +5.51pp**, but a second consecutive underperformance week would materially erode that.
- **KLIC single-name timing miss dominated the week's P&L.** KLIC realized -$122.24 alone = **199% of the week's negative P&L** (net -$61.68). Held-book unrealized delta was +$60.56 (core +$42.52 + BTSG +$1.05 + GE +$17.04) — without the KLIC round-trip, the bot would have been +$0.12 on the week (essentially flat vs SPX +1.79% = still -1.78% alpha, but no absolute red). The Tue-entry-to-Thu-exit round trip was the singular weight.
- **KLIC entry timing exposed a gap between buy-side momentum screen and macro-binary calendar.** The Tue Jun 30 entry was 2 sessions before Thu Jul 2 NFP — the largest scheduled macro binary of the week. The v3 buy-side gate passed KLIC on all 10 prongs (positions, weekly cap, 20% cap, cash, ETF-core floor, sector cap, deployment ceiling, DTC, single-stock RS/DMA 4/4, catalyst). But there is **no macro-binary-proximity check** — the gate is calendar-blind. KLIC's +14.12pp 10s-RS momentum stack was strong but the position was T+2 vulnerable to NFP interpretation; the tape gave back Wed's +$135.80 HWM below the 10% trail on the Thu print.
- **Capital deployment fell out of band post-KLIC-exit and stayed out for 2 sessions.** Thu Jul 2 EOD 60.72% + Fri Jul 3 EOD 60.72% — 2 consecutive sessions below the v3 75% floor. Intentional/expected per Rule 6 mechanics (trail-stops unwind concentration into cash), but the Rule 12 patience-overlay defer of Fri re-arm means Mon Jul 6 pre-market carries a re-arm priority. $4,080 cash + 1 open sat slot + fresh 5-slot weekly budget = wide re-arm room but no forcing function.
- **XLB nearly triggered its Rule 8 first-tier tighten but stalled 0.13% short.** Fri Jul 3 midday XLB was +3.85% on-cost ($52.01 vs $50.08); first-etf-tier trigger is $52.083 (+4%). XLB stopped $0.07 short of the trigger — the routine's Rule 8 evaluation was correct (no fire). This is not a "didn't work" per se, but it's a "close-but-no" data point: XLB has been chasing the first tier since Fri Jun 12 (first-tier already fired then and locked 7% trail); the flat-flat-flat pattern for 4 weeks limits ladder progression on the sole core position that reached tier 1 early.
- **Fri Jul 3 routine ran with feed-frozen data (change_today=0, balance_asof 2026-07-02).** Alpaca's paper environment did not update the position feed on Jul 3 (US markets closed for Independence Day observance — Alpaca calendar respects the closure). The routine correctly no-op'd but ran through all evaluation steps against the frozen feed, producing an EOD snapshot that's an exact carry-forward of Thu's numbers. This is not a rule violation but is a cadence artifact worth noting for audit clarity (Jul 3 EOD is not a distinct P&L observation).

### Key Lessons
- **The v3 architecture (core + satellite) provides asymmetric drawdown protection — validated in a losing week.** In Week 10 the sat sleeve lost $104.15 while the core sleeve added $42.52 → core dampened ~40% of the sat drawdown. In prior sat-outperformance weeks (W8+W9) the core sleeve added $-0.04% and $-1.13% per-capital while sat added +5.76% and +4.01% — the core was the drag. **The core-satellite architecture is bidirectionally protective:** core dampens sat losses in bad sat weeks, sat drives alpha in good sat weeks. Confirmed across both regimes now.
- **Rule 6 (10% trailing stop) is fully validated across position types.** Phase fires: Week 8 XLE core-ETF trail-out on Iran-ceasefire gap; Week 9 CAT satellite runner trail-out post-Rule 8 lock; **Week 10 KLIC fresh-satellite trail-out on NFP-day tape reversal**. Three distinct scenarios (weekend gap, post-scale-out runner, T+2 fresh position), three clean exits, all T+2 or later = zero day-trade risk. **The 10% canonical trail is spec-correct for fresh-sat entries** — tighter would cost false-fire drag, wider would miss the KLIC-style rapid reversal.
- **Buy-side gate is macro-binary-blind.** The 10-prong gate correctly screens position-level risk (size, sector, deployment, momentum, catalyst) but does not screen against calendar proximity to Tier-1 macro binaries (NFP, CPI, FOMC, PCE). KLIC entered T+2 before NFP; the position could not build cushion before the print. Not a rule violation but a real spec gap — see proposed strategy notes below (LOW conviction, single-week evidence).
- **Rule 12 patience > activity worked correctly on Fri Jul 3 but not on Tue Jun 30.** Fri: all mechanical gates unlocked (1 sat slot open, deployment headroom, weekly cap 4/5 available) but Rule 12 overlay deferred re-arm (shortened session, holiday weekend, KLIC-T+1 anti-revenge). Tue: all gates passed cleanly, no Rule 12 overlay because there wasn't yet an anti-revenge signal — the KLIC loss hadn't happened yet. The pattern suggests Rule 12 could benefit from a forward-looking macro-binary-proximity check on the entry side, not just the post-loss/gap-close side.
- **Visa-aware machinery (Rules 13/14/15) bulletproof for 10th consecutive week.** DTC held 0/5 all week; KLIC T+2 swing exit (not day trade); Rule 15 same-day skip protected KLIC on Tue midday; Rule 14 pre-flight passed every routine. The visa-aware design is a solved problem across 10 weeks and 51 trading days — the risk lives in strategy selection (KLIC timing, cyclical-book tape exposure) and infrastructure (Alpaca 504 historical, feed-frozen holiday sessions), not execution discipline.
- **Satellite sleeve check (v3 spec):** W6 sat -1.51% vs core +0.06% (sat under); W7 sat +0.50% vs core +1.37% (sat under); W8 sat +5.76% vs core -1.13% (sat over); W9 sat +4.01% vs core -0.04% (sat over); **W10 sat -2.54% vs core +1.09% (sat under)**. The 3+ consecutive-week UNDERperformance threshold is NOT met (W10 is 1 of 2 after the W8+W9 outperformance streak). Observation continues; no shrink-sat proposal this week.

### Adjustments for Next Week
- **Monday pre-market (Jul 6, Week 11 Day 1, post-holiday-weekend + fresh 5-slot budget + $2,522 deployment headroom + 1 open sat slot):** re-screen post-holiday liquidity restoration; XLK ETF-core 10s-RS 24th consecutive gate-fail (Thu -2.71% single-session compression of 3.49pp) needs material reversion; Tech sat re-screen candidates from Fri Jul 3 deferred watchlist (MU / WDC / CRDO / MCHP / STRL — Zacks Rank #1 momentum); XLE/XLP sector-diversification alternatives if RS profiles clear. **Default: Rule 12 patience > forced re-arm** — only deploy if a clean gate-passing idea AND no imminent Tier-1 macro binary within T+2 (see proposed strategy notes).
- **Watch XLB.** Fri Jul 3 close $52.01 = +3.85% on-cost — **$0.07 (0.13%) shy of first-etf-tier trigger $52.083 (+4%)**. Imminent Mon Jul 6 fire if XLB opens flat-to-green. First-tier tighten would move trail 7% → 7% (already at 7% from Fri Jun 12 lock — no change), scale-out 0. Effectively a state-machine mark, not a P&L event; watch for the second-etf-tier +7% ($53.586) which fires a real scale-out + tighten to 5%.
- **Watch XLI.** Fri Jul 3 close $183.91 = +5.87% on-cost — **$1.96 (1.07%) shy of first scale-out trigger $185.87 (+7% etf 2nd-tier)**. First real ETF scale-out of the phase if XLI extends. Would trim ~4 sh, free ~$743 cash, tighten trail 7% → 5%.
- **Watch BTSG.** Fri close $69.03 = +7.11% on-cost — $1.865 (2.70%) shy of first-stock-tier scale-out $70.895 (+10% sat 2nd-tier). Locked at 7% trail post-Rule 8 first-tier (Jun 24). Runner path forward.
- **Watch GE.** Fri close $377.52 = +12.67% on-cost — $41.31 (10.94%) shy of 2nd-scale-out $418.83 (+25% sat 3rd-tier). Locked at 6% trail post-Rule 8 second-tier scale-out (Jun 25). Long runway to next fire; sat 1sh runner.
- **KLIC re-screen path.** KLIC's underlying momentum stack (+14.12pp 10s-RS, Q2 EPS beat, AI supercycle tailwind) is unchanged by a -5.89% NFP-day tape reversal. However, per Rule 12 anti-revenge, no re-entry Mon Jul 6. Earliest legitimate re-arm would be Wed Jul 8+ with fresh RS re-screen and momentum re-confirmation post-exit — treat as a fresh idea, not a re-add. Prioritize sector-diversifying satellites (Tech via different names, or non-Tech via XLE/XLP screens) over KLIC re-entry.
- **Deployment re-arm priority Mon.** 40% cash into a post-holiday-weekend Mon = the largest cash carry of the v3 phase into a session with typical mean-reversion vol. If Mon Jul 6 opens with a green tape and 5.51pp cum alpha still positive, the opportunity cost of un-deployed cash rises; if Mon opens with mean-reversion pullback (post-holiday liquidity re-arm), the freed cash gains optionality. Watch the open; Rule 12 patience remains the default until a clean gate-passing idea appears.
- **No auto-applied strategy mutations** (DECIDED G — rulebook is the safety system). See proposed strategy notes below.

### Overall Grade: C+

First losing week of a 4-week streak of green + benchmark-beat weeks (W6-W9), snapping the alpha streak with -2.38% (worst since Week 5's -2.10%). The KLIC single-name round-trip (Tue Jun 30 entry → Thu Jul 2 trail-stop exit at -5.89% / -$122.24) was the singular weight — held-book unrealized delta was actually +$60.56 without KLIC (core +$42.52 + BTSG +$1.05 + GE +$17.04). **What went right:** Rule 6 trail-stop machinery worked exactly per spec on a fresh sat position (first phase fire in T+2 entry-window scenario, contained loss inside the risk-parity ~2% envelope); ETF core delivered +1.09% per-capital vindicating the v3 core-ballast design (asymmetric drawdown protection now validated in both regimes — core dampens sat losses AND sat drives alpha in good regimes); zero rule violations; visa-aware machinery flawless for 10th straight week; Rule 12 patience overlay correctly deferred Fri Jul 3 re-arm despite fully-unlocked mechanical gates. **What went wrong:** the buy-side gate is macro-binary-blind — KLIC entered T+2 before NFP with no built-in cushion, and the Thu print's tape reversal hit the trail; SPX ripped +1.79% while the bot's non-Tech book missed the leadership; capital deployment fell out of band for 2 sessions post-exit (intentional but real cash drag). **Half-grade ding to C+** to weight the KLIC realized loss + 4-week alpha streak break against the clean Rule 6 execution + core-ballast working as designed + zero rule violations. Rolling-5-week cum alpha remains solidly positive at +5.51pp; phase P&L +3.88% is still the 2nd-best phase print of the run (only Fri Jun 26 EOD +4.50% and Thu Jun 25 intraday +5.78% are higher).

## Proposed strategy changes (NOT auto-applied — human review required)

- **Macro-binary-proximity check on the buy-side gate (v3.2 proposal, NEW THIS WEEK).** KLIC Tue Jun 30 entry passed all 10 buy-side gate prongs (positions, weekly cap, 20% cap, cash, ETF-core floor, sector cap, deployment ceiling, DTC, single-stock RS/DMA 4/4, catalyst) but entered T+2 before Thu Jul 2 NFP — the largest scheduled macro binary of the week. The trail-stop fired on the NFP tape reversal for -5.89% / -$122.24. **Proposal:** add an 11th buy-side gate check — `no Tier-1 macro binary scheduled within the next 2 trading sessions from entry date`. Tier-1 binaries: NFP (monthly), CPI (monthly), PPI (monthly), Core PCE (monthly), FOMC decisions (8/year), FOMC minutes release, Powell press conferences. Skip + log the buy if a Tier-1 binary is <T+3 sessions from proposed entry. Applies only to single-stock satellites (higher idiosyncratic vol); ETF core adds bypass this check (broad-market exposure absorbs macro binaries).
- **Rationale:** Fresh single-stock satellites need >2 sessions of cushion before a Tier-1 binary to withstand a full-day tape reversal without hitting the 10% trail. The KLIC pattern is a textbook version: strong momentum stack, clean gate pass, but insufficient time to build HWM cushion before the tape moved 10.16% off HWM in <24h. Rule 12 patience overlay works post-hoc (Fri Jul 3 anti-revenge friction) but not on the entry side — the calendar gap is real.
- **Evidence:** TRADE-LOG.md 2026-06-30 KLIC BUY (Tue entry, all gates pass); 2026-07-02 KLIC SELL (Thu NFP tape reversal, trail fire -5.89%). Single-week evidence, but the pattern is mechanically clear (T+2 fresh sat vs Tier-1 macro binary is asymmetric risk). Prior sat entries: CAT Jun 4 (T+2 before nothing major — held), GE Jun 12 (T+1 before nothing major — held), BTSG Jun 16 (T+2 before FOMC Jun 17-18 — first day was Alpaca 504 outage; would have failed this proposed gate). Note BTSG survived the FOMC binary and went on to +7.11%, so the proposed gate would have skipped a winner — the check is asymmetric protection, not a directional filter.
- **Conviction: LOW.** Single-week evidence; BTSG counter-example shows the gate could skip winners; codifying it requires a calendar-of-known-binaries lookup that adds implementation complexity. Recommend the human defer a decision until 1–2 more weeks confirm the pattern (or KLIC-style loss recurs).

- **Satellite-sleeve check (v3 spec) update.** W6 sat -1.51% vs core +0.06% (sat under); W7 sat +0.50% vs core +1.37% (sat under); W8 sat +5.76% vs core -1.13% (**sat over**); W9 sat +4.01% vs core -0.04% (**sat over**); **W10 sat -2.54% vs core +1.09% (sat under)**. The 3+ consecutive-week UNDERperformance shrink-sat trigger is NOT met (only 1 under after 2 over). No shrink-sat proposal this week. Observation continues.
- **Conviction: deferred — observation continues with mixed signal (sat variance high, but no consecutive-under streak).**

- **Rule 6 (10% trailing stop) — 3rd phase fire (KLIC), keep as-is.** XLE Week 8 first fire (core ETF, weekend gap); CAT Week 9 second fire (sat runner, post-Rule 8 lock); **KLIC Week 10 third fire (fresh sat, T+2 entry-window tape reversal)**. All 3 fires spec-compliant, all T+2 or later = swing-only exits, zero day-trade risk. The 10% canonical trail is validated across 3 distinct scenarios. No proposed change.

- **Rule 8 ladder — no fires Week 10 (all held-book positions stalled just short of next tier).** XLB $0.07 shy of +4% first-etf-tier ($52.083); XLI $1.96 shy of +7% first-etf-scale-out ($185.87); BTSG $1.865 shy of +10% first-sat-scale-out ($70.895); GE $41.31 shy of +25% third-sat-tier ($418.83); KLIC exited before reaching any tier. Rule 8 stayed dormant this week by mechanical spec — no proposed change. Watch Mon Jul 6 for XLB imminent-fire and XLI within-reach fire.

- **Rule 12 (patience > activity) — validated on Fri Jul 3 defer, keep as-is.** All 4 mechanical gates were unlocked on Fri (1 sat slot re-opened, weekly cap 4/5 available, deployment headroom $2,522, ETF-core 65% ≥ 45% floor) but Rule 12 overlay correctly deferred (shortened Fri + holiday weekend + KLIC-T+1 anti-revenge). The pattern demonstrates Rule 12 is not just a mechanical fallback but an active discretionary overlay. No proposed change; the KLIC-timing observation (proposed above) would extend Rule 12's forward-looking coverage.

- **Rule 16 momentum-decay — silent Week 10, no fires.** All held-book positions above entry throughout = not flag-eligible by definition (KLIC exited T+2 via Rule 6 trail before reaching any decay-flag threshold). Rule still validated by W6 XLP rotation + W7 CAT chain-break. No proposed change.

- **Prior deployment-ceiling check (W7 MEDIUM) — CLOSED, already in v3.1 rulebook.** No new evidence this week.

- **Prior Industrials sector-concentration soft cap (W8 MEDIUM → W9 LOW) — remains LOW.** Industrials 44.04% of deployed (well under v3.1 50% cap); GE runner alone at 12% deployed. Concentration self-resolved via W9 CAT scale-outs + trail-out; no re-promotion this week.

- **Prior RSP-of-last-resort proposal (W4-W5 LOW) — remains LOW.** v3 satellite sleeve continues to deploy effectively (BTSG + GE + KLIC round-trip); no re-promotion needed even in a losing sat week (the mechanism worked, the tape didn't).

- **Prior Rule 8 +15% trail-only tier state-machine gap (W9 MEDIUM) — no evidence Week 10 (KLIC didn't reach +15%; no held-book runner crossed +15%).** Keep on file at MEDIUM; would land on the next week where a runner crosses +15% intraday without prior scale-outs firing (CAT-style scenario from W9).

- **Prior pre-market cadence guardrail (W9 HIGH) — no fresh evidence this week.** Fri Jul 3 pre-market DID run and log (RESEARCH-LOG.md 2026-07-03 entry present, TRADE-LOG.md 2026-07-03 market-open + midday + EOD rows all present). Zero cadence gaps Week 10. Proposal remains on file at HIGH; the Fri Jul 3 clean run is one data point in favor of continued discipline, not evidence the guardrail is unnecessary. Recommend the human still apply the proposal for durability.

- **Prior sub-unit scale-out qty inconsistency (W9 HIGH) — no evidence Week 10 (no scale-outs fired; no held-book position crossed a scale-out tier).** Proposal remains on file at HIGH; would land on the next week where a scale-out fires on a 2sh position (BTSG at +10% would be 21sh → sell_qty=7, no issue; GE at +25% would be 2sh → sell_qty=1 via `sizing.py scaleout`, no issue; XLI at +7% ETF-tier would be 11sh → sell_qty=4 via ceiling(11/3)=4, no issue this week).

## Week ending 2026-07-10

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,388.12 (Week 10 ending EOD) |
| Ending portfolio | $10,322.99 (account.equity) |
| Week return | -$65.13 (-0.627%) |
| S&P 500 week | +0.861% (Jul 2 close 7,483.24 → Jul 10 close 7,547.64; Jul 3 Independence Day holiday) |
| Bot vs S&P | **-1.49% (lagged)** — 2nd consecutive negative-alpha week (W10 -2.38% / W11 -1.49%) |
| Alpha vs SPX (v3) | **-1.49% (headline)** — rolling W6→W11 cum alpha now +4.02pp (W6 +2.10 / W7 +1.09 / W8 +1.10 / W9 +3.60 / W10 -2.38 / W11 -1.49) |
| Core/Satellite P&L (v3) | core -$75.26 (-1.23% of ~$6.1K core capital) / satellite +$10.18 (+0.46% of ~$2.2K satellite capital) — **satellite OVERperformed core** (drag was the ETF core this week) |
| Trades | 1 BUY (XLP Mon Jul 6) — realized exits 3: W:2 / L:1 / open:3 (BTSG/XLB/XLI carryforward) |
| Win rate | 67% (2 winning exits / 3 closed) |
| Best trade | BTSG +10.09% realized (Jul 9 scale-out slice, 7sh @ $70.95 vs $64.45) |
| Worst trade | XLP -0.34% realized (Jul 10 Rule 16 rotate-exit, 24sh @ $84.02 vs $84.306667) |
| Profit factor | 13.60 (gains $93.56 / losses $6.88) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) — **11 consecutive weeks of zero day trades** |
| Capital deployment | 48.78% EOD ($5,035.94 / $10,322.99) — **well BELOW the v3 75–85% band**; ~$5.3K cash (51.2%) after GE stop-out + BTSG scale-out + XLP rotation freed cash into a deployment-gated week |
| Phase P&L | +$322.99 (+3.230%) — off Fri Jun 26 EOD phase HWM +$449.80 |
| Trading sessions | 5 (Mon Jul 6 – Fri Jul 10) |

### Closed Trades
| Ticker | Entry       | Exit     | P&L                | Notes |
| ------ | ----------- | -------- | ------------------ | ----- |
| GE     | $335.06     | ~$359.09 | +$48.06 (+7.17%)   | Final 2sh tranche stopped out Wed Jul 8 13:33 UTC via GTC 6% trailing stop (auto-fill, not routine-driven). T+26 aged position from 2026-06-12 → not a day trade; freed ~$718 cash + vacated Industrials satellite slot. A clean satellite runner win. |
| BTSG   | $64.45      | $70.95   | +$45.50 (+10.09%)  | Rule 8 scale-out #1 of 2 (7sh of 21) Thu Jul 9 midday — crossed +10% first stock tier (unrealized +10.23%, hwm-gain +11.19%). Partial exit; 14sh runner continues at 6% trail. T+23 aged, not a day trade. |
| XLP    | $84.306667  | $84.02   | -$6.88 (-0.34%)    | Rule 16 momentum-decay ROTATE-EXIT (full 24sh) Fri Jul 10 midday — 2nd consecutive DECAY-FLAG (below entry AND lagging SPY 10-sessions: -0.35% on-cost vs SPY +2.65%). Cut dead-money laggard 5 sessions after Mon re-entry; freed ~$2,016 cash. T+4 aged, not a day trade. Rule 16's 3rd phase fire. |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized        | Stop                 | Tier      |
| ------ | ----------- | -------- | ----------------- | -------------------- | --------- |
| BTSG   | $64.45      | $71.43   | +$97.72 (+10.83%) | $67.7317 (trail 6%)  | satellite |
| XLB    | $50.08      | $50.90   | +$32.80 (+1.64%)  | $49.5783 (trail 7%)  | core      |
| XLI    | $173.713636 | $181.73  | +$88.18 (+4.62%)  | $176.567 (trail 5%)  | core      |

daytrade_count: 0 (11 consecutive weeks). Positions 3/6; ETF core (XLB+XLI $4,035.03) / deployed $5,035.05 = **80.14%** ≥ 45% floor ✓. Satellite slots: BTSG (Healthcare) 1/2, 2 open. All 3 held-book GTC trailing stops armed; Rule 17 clean.

### What Worked
- **Three clean, disciplined exits — 2 wins + 1 tiny controlled loss, all T+4-or-later swing exits (zero day-trade risk).** GE's final tranche trail-stopped out at +7.17% (auto-fill on the GTC 6% trail, exactly per Rule 6); BTSG scale-out fired the +10% first stock tier for +10.09% on the slice (Rule 8 ladder machinery — replace-stop to free qty, market scale-out, stop re-placed at 6% for the 14sh runner); XLP's Rule 16 rotation cut a dead-money laggard at -0.34% before it could deepen. Every visa-aware guard held (DTC 0/5, no same-day exits, all aged positions).
- **Rule 16 momentum-decay rotation fired correctly for the 3rd phase time.** XLP logged DECAY-FLAG=1 Thu Jul 9 (fresh flag, prior_flag=0 from the Jul 6 re-entry consecutiveness reset) then a 2nd consecutive flag Fri Jul 10 (below entry AND lagging SPY 10-sessions +0.08% vs +2.65%) → rotate=1 → clean exit. The rule did its job: freed $2,016 of capital tied up in a non-participating position for redeployment into leadership next week.
- **Satellite sleeve OVERperformed core again (+0.46% vs -1.23% per-capital).** BTSG (+$47.04 week delta incl. scale-out) carried the book while the ETF core (XLB/XLI gave back unrealized on a choppy tape, XLP round-tripped flat-to-down) was the drag. The core-satellite architecture stayed bidirectionally protective — this week the alpha sleeve was the buffer, not the drag.
- **Zero rule violations for the 11th consecutive week; visa-aware machinery flawless.** DTC held 0/5 all week; every sell (GE auto-trail, BTSG scale-out, XLP rotation) was on an aged position (T+4 to T+26); Rule 14 pre-flight passed every routine; Rule 17 first-action scan clean across all 5 sessions. Eleven weeks, zero day trades, 56 trading days.

### What Didn't Work
- **2nd consecutive negative-alpha week (-1.49%) — the deployment-gate/full-clip deadlock left the bot underdeployed through a rising tape.** SPX rose +0.86% while the bot fell -0.63%. Root cause is structural, not execution: every day Jul 7–10 pre-market surfaced 2 clean core-ETF ideas (XLRE, XLU — both "Improving"-quadrant DMA-confirmed uptrends passing all other gates) but market-open HOLD'd all 5 sessions because a full risk-parity/20%-cap core clip (~$2,058) would breach the 85% deployment ceiling given the available headroom ($514–$1,730). The all-or-nothing full-clip sizing meant incremental cash could not be deployed, so as GE/BTSG/XLP exits freed cash, deployment fell from 80% → **48.78%** and stayed underdeployed into the SPX gain. This is a 4-session recurring deadlock (see proposed change below).
- **Ended the week 51% cash / 48.78% deployed — the lowest deployment of the v3 phase — with no forcing function to redeploy.** The v3 mandate is 75–85% deployed; the bot spent the back half of the week 7–26 points below the floor. Cash isn't free when SPX is grinding up.
- **The ETF core was the P&L drag (-$75.26).** XLB (-$44.40 week delta) and XLI (-$23.98) both gave back unrealized gains on a choppy, rotation-heavy tape, and XLP round-tripped for a small realized loss. The two remaining core positions are still net-green on-cost (XLB +1.64%, XLI +4.62%) but neither reached its next ladder tier, so the ladder stayed dormant and no locks tightened.

### Key Lessons
- **The deployment ceiling + full-clip sizing can deadlock the book into underdeployment.** When freed cash arrives in tranches smaller than one full risk-parity clip, an all-or-nothing entry rule refuses every add and cash piles up. This is now a clear multi-session pattern (Jul 7–10, four consecutive HOLDs on the identical deployment blocker) that cost ~1.5pp of alpha this week and left the book at 48.8% deployed. A partial/fractional-clip mechanism sized to available headroom would let the bot stay inside the 75–85% band without breaching the 85% ceiling — see proposed change.
- **Rule 16 is validated as a capital-recycling tool, not just a loss-cutter.** XLP was only -0.35% on-cost — not a loss worth a Rule 7 hard-close — but it was dead money lagging SPY for 2 straight sessions. Rotating it out freed $2,016 that a full-clip core add can now consume next week. The rule correctly distinguishes "small loser" from "non-participating capital."
- **Satellite variance cuts both ways but the sleeve remains additive.** After W10's -2.54% sat week, W11 flipped back to sat +0.46% vs core -1.23%. Over the last 3 weeks (W9 over, W10 under, W11 over) the satellite sleeve is not on a consecutive-underperformance streak — the shrink-sat trigger stays reset.
- **Visa-aware machinery is a solved problem (11 weeks / 56 days, zero day trades).** As in prior weeks, the residual risk lives in strategy selection (deployment timing, core-vs-leadership positioning) and rule design (the full-clip deadlock), not execution discipline.

**Satellite-sleeve check (v3 spec):** W9 sat +4.01% vs core -0.04% (sat OVER); W10 sat -2.54% vs core +1.09% (sat UNDER); **W11 sat +0.46% vs core -1.23% (sat OVER).** The 3+ consecutive-week UNDERperformance shrink-sat trigger is NOT met (only 1 under in the last 3, and W11 is a fresh over). No shrink-sat proposal this week.

### Adjustments for Next Week
- **Mon Jul 13 (Week 12 Day 1) opens with ~$5.3K cash and 48.8% deployment — a re-arm priority.** The deployment gate now clears easily (a full ~$2,058 core clip lands deployment at ~68%, well inside the band). Re-arm XLRE then XLU in R:R order; re-screen the 2 open satellite slots. But: **CPI Tue Jul 14 (T+1) + PPI Wed Jul 15 (T+2)** block fresh single-stock satellites via the v3.2 macro-proximity gate — core ETF adds are exempt and are the right first move to restore deployment.
- **Watch XLI.** Close $181.73 = +4.62% on-cost — first ETF scale-out at +7% ($185.87, +2.28% away). Would trim ~4sh, free ~$740, tighten trail to 5% (already at 5% — a state mark).
- **Watch BTSG.** Close $71.43 = +10.83% on-cost — next ladder tier +15% ($74.12, +3.77% away, trail-only tighten to 4%). Runner path; 14sh after Thu scale-out.
- **Watch XLB.** Close $50.90 = +1.64% on-cost — first +7% ETF scale-out at $53.59 (+5.28% away). Flat-flat pattern persists; the sole tier-1-locked core position.
- **Macro calendar:** CPI Tue Jul 14, PPI Wed Jul 15, FOMC Jul 28–29. Satellites stay macro-gated early week; core adds are the deployment-restoration lever.
- **No auto-applied strategy mutations** (DECIDED G). See proposed change below.

### Overall Grade: C+

A quiet, disciplined, slightly-red week (-0.63% absolute, -1.49% alpha) whose story is **underdeployment**, not losses. The three exits were all clean — GE trail-stopped for +7.17%, BTSG scale-out for +10.09%, XLP rotated out at -0.34% before it could deepen — and the visa-aware/rule machinery was flawless for the 11th straight week (zero violations, zero day trades). But for the 2nd consecutive week the bot lagged a rising SPX, and this week the cause is a concrete, recurring rule-design deadlock: the 85% deployment ceiling combined with all-or-nothing full-clip sizing refused every core-ETF add for 4 straight sessions while exits kept freeing cash, dragging deployment to 48.8% — the lowest of the phase — through an SPX grind higher. Execution earns a B; the strategy-design drag and 2nd alpha miss pull it to **C+**. Rolling cum alpha remains positive at +4.02pp and phase P&L is +3.23%, but the deployment deadlock needs a fix (proposed below) before it costs a 3rd week.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Partial/fractional core-ETF clip sizing to fill deployment headroom (v3.2 proposal, NEW THIS WEEK — MEDIUM conviction).** For **ETF-core (`tier: core`) ideas only**, when a full risk-parity/20%-cap clip (~$2,058) would breach the 85% deployment ceiling but the idea passes every other buy-side gate, allow market-open to place a **reduced clip sized to the available deployment headroom**, down to a minimum viable size (proposed floor: the greater of ~$800 or ~8% of equity) to avoid dust positions. Skip only if headroom is below that floor. Satellites are excluded (their idiosyncratic vol wants full risk-parity sizing or nothing).
- **Rationale:** The current all-or-nothing full-clip rule deadlocked the book for 4 consecutive sessions (Jul 7–10): 2 clean core ideas (XLRE, XLU) passed every gate but were refused every day because headroom ($514–$1,730) never reached a full ~$2,058 clip, so freed cash from GE/BTSG/XLP exits piled up and deployment fell to 48.78% — 26pts below the v3 75% floor — through a +0.86% SPX week. A partial clip sized to headroom would have kept the book inside the 75–85% band and captured broad-market beta, directly addressing the -1.49% alpha miss without breaching the ceiling or the ETF-core floor.
- **Evidence:** TRADE-LOG.md 2026-07-07/08/09/10 market-open rows (all HOLD, all citing the deployment-ceiling blocker with identical XLRE/XLU ideas); Jul 10 EOD deployment 48.78%; Wk11 alpha -1.49% while SPX +0.86%.
- **Conviction: MEDIUM.** Clear, mechanically-precise 4-session evidence this week; the fix is bounded (core-only, min-clip floor prevents over-trading/dust) and stays within existing ceilings. Recommend the human apply this before Week 12 if the cash carry persists, as the deadlock is likely to recur while positions keep laddering out into cash.

- **Satellite-sleeve check (v3 spec) update.** W9 sat +4.01% / core -0.04% (sat OVER); W10 sat -2.54% / core +1.09% (sat UNDER); W11 sat +0.46% / core -1.23% (sat OVER). 3+ consecutive-week UNDERperformance shrink-sat trigger NOT met. No shrink-sat proposal. Observation continues.
- **Conviction: deferred — no consecutive-under streak.**

- **Prior macro-binary-proximity gate (W10 LOW → codified as v3.2).** The proposed 11th buy-side gate is now in the rulebook (Buy-Side Gate "Macro-binary proximity (v3.2, satellite only)"). It worked as designed this week — Fri Jul 10 pre-market screened all satellites out on CPI-at-T+2. Closing as RESOLVED (already implemented in v3.2).
- **Conviction: CLOSED (already implemented in v3.2).**

- **Prior Rule 8 +15% trail-only tier state-machine gap (W9 MEDIUM) — no evidence Week 11 (no held-book runner crossed +15% intraday without prior scale-outs; BTSG at +10.83% is below the +15% tier). Keep on file at MEDIUM.**

- **Prior pre-market/market-open cadence guardrail (W9 HIGH, now Rule 18) — fresh evidence Week 11 (Jul 8).** Rule 18 tripped correctly on Wed Jul 8 when market-open ran a HOLD but only touched HEARTBEAT.md and never wrote its Market-Open TRADE-LOG row (HOLD-path logging gap). Daily-summary's sweep caught it, sent the URGENT Telegram, and appended a MISSING-ROUTINE placeholder; the Jul 9 market-open row explicitly closes the gap. The guardrail is validated in production. **Residual code fix recommended:** market-open's HOLD path must always append its TRADE-LOG row even on 0 orders (Jul 9/10 rows already do this — confirm the fix is durable in the routine, not one-off).
- **Conviction: HIGH (guardrail validated; underlying HOLD-path logging fix recommended for durability).**

- **Prior sub-unit scale-out qty inconsistency (W9 HIGH) — no adverse evidence Week 11 (BTSG 21sh → sell 7 via ceiling(21/3) worked cleanly). Keep on file at HIGH for the 2sh-position case (GE at +25% would have been 2sh → sell 1; GE exited via trail before reaching that tier).**

- **Prior RSP-of-last-resort (W4-W5 LOW) — remains LOW.** Satellite sleeve deploying effectively (BTSG runner + GE win); no re-promotion.

## Week ending 2026-07-17

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,322.99 (Week 11 ending account.equity) |
| Ending portfolio | $10,212.75 (account.equity; EOD snapshot portfolio $10,216.76) |
| Week return | -$110.24 (-1.068%) |
| S&P 500 week | -0.549% (Jul 10 close 7,575.39 → Jul 17 close 7,533.77; FRED/majority-source. NB: Wk11 review used Jul 10 = 7,547.64 — reconciled to the majority 7,575.39 for a same-source Jul10→Jul17 pair) |
| Bot vs S&P | **-0.52% (lagged)** — 3rd consecutive negative-alpha week but NARROWING (W10 -2.38 / W11 -1.49 / W12 -0.52) |
| Alpha vs SPX (v3) | **-0.52% (headline)** — rolling W6→W12 cum alpha +3.50pp (W6 +2.10 / W7 +1.09 / W8 +1.10 / W9 +3.60 / W10 -2.38 / W11 -1.49 / W12 -0.52) |
| Core/Satellite P&L (v3) | core -$37.30 (-0.5% of ~$8.0K core cap) / satellite -$49.87 (BTSG round-trip, +5.3% on-cost WIN but -$49.87 vs Wk11 mark) — **satellite UNDER core; sleeve wound to 0/3 mid-week** |
| Trades | 2 BUYs (XLRE Mon Jul 13, XLU Wed Jul 15 — both core) — realized exits 1: W:1 / L:0 / open:4 (XLB/XLI/XLRE/XLU) |
| Win rate | 100% (1 winning exit / 1 closed) |
| Best trade | BTSG +5.3% realized (Wed Jul 15 overnight 6% GTC trail stop-out, 14sh runner @ ~$67.87 vs $64.45, ~+$47.85) |
| Worst trade | n/a (no losing close this week) |
| Profit factor | n/a (1 gain, 0 losses) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) — not surfaced in paper /account (cosmetic quirk); pattern_day_trader=false → treated 0; **12 consecutive weeks of zero day trades** |
| Capital deployment | 79.01% EOD ($8,069.26 / $10,212.75) — **squarely in the v3 75–85% band** (recovered from Wk11's 48.78% via XLRE Mon add + XLU Wed re-arm) |
| Phase P&L | +$212.75 (+2.128%) — off Fri Jun 26 EOD phase HWM +$449.80 |
| Trading sessions | 5 (Mon Jul 13 – Fri Jul 17) |

### Closed Trades
| Ticker | Entry   | Exit     | P&L               | Notes |
| ------ | ------- | -------- | ----------------- | ----- |
| BTSG   | $64.45  | ~$67.87  | ~+$47.85 (+5.3%)  | 14sh runner overnight stop-out Wed Jul 15 — 6% GTC trail (id 79f4e88e, stop $67.868, hwm $72.2) fired from the Jun-16 entry. T+29 aged → NOT a day trade; DTC unaffected (auto-fill, no routine sell). A clean satellite runner win that (with the Jul 9 W11 +10.09% scale-out slice) closed the full BTSG trade as a strong multi-week winner. The exit re-armed the XLU core clip. |

### Open Positions at Week End
| Ticker | Entry       | Close    | Unrealized        | Stop                                   | Tier |
| ------ | ----------- | -------- | ----------------- | -------------------------------------- | ---- |
| XLB    | $50.08      | $50.46   | +$15.20 (+0.76%)  | $49.5783 (7% trail, GTC 9b627571, hwm $53.31)  | core |
| XLI    | $173.713636 | $179.26  | +$61.01 (+3.19%)  | $176.567 (5% trail, GTC 4b207f64, hwm $185.86) | core |
| XLRE   | $44.79      | $45.42   | +$28.98 (+1.41%)  | $41.3595 (10% trail, GTC 16d5a6b2, hwm $45.955)| core |
| XLU    | $45.80      | $45.22   | -$25.52 (-1.27%)  | $41.5305 (10% trail, GTC fa8eb3f2, hwm $46.145)| core |

daytrade_count: 0 (12 consecutive weeks; not surfaced in paper API, pattern_day_trader=false). Positions 4/6; ETF core = 100% of deployed ($8,069.26) ≥ 45% floor ✓; sectors evenly balanced (Materials 25.0% / Real Estate 25.9% / Utilities 24.7% / Industrials 24.4%, all ≤50%) ✓. Satellite sleeve 0/3 (all slots open). All 4 held-book GTC trailing stops armed; Rule 17 clean. XLU carries a live DECAY-FLAG=1 (Fri Jul 17) — a 2nd consecutive Mon midday flag triggers Rule 16 rotation.

### What Worked
- **Deployment deadlock self-resolved — book restored from 48.78% to 79.01%, back inside the v3 75–85% band.** Wk11's underdeployment story reversed cleanly: XLRE Mon add (+$2,060, deployment 48.8%→68.6%) then BTSG's Wed overnight stop-out re-armed the XLU core clip (+$2,015, →79.1%). The core-ETF re-arm ladder worked exactly as the Wk11 adjustments prescribed — no partial-clip mechanism was needed this week because exits + a fresh Monday cash base let full clips fit under the ceiling.
- **The only closed trade was a win, and every visa-aware guard held.** BTSG's 14sh runner trail-stopped at +5.3% (T+29 aged, auto-fill on the 6% GTC trail — Rule 6 exactly as designed); zero same-day exits; DTC 0/5 all week; Rule 14 pre-flight and Rule 17 first-action scan clean across all 5 sessions. **12 consecutive weeks / 61 trading days, zero day trades.**
- **Alpha miss narrowed for the 2nd straight week (W10 -2.38 → W11 -1.49 → W12 -0.52).** SPX was itself red (-0.55%) on a risk-off, US-Iran-oil-spike tape; the bot's -1.07% lag is now within ~half a point of the benchmark and the gap is closing. Rolling cum alpha stays positive at +3.50pp.
- **Rule 16 decay machinery tracked correctly across the week** — XLRE flagged Tue (flag=1), reset Wed (flag=0, XLRE re-led SPY), then XLU freshly flagged Fri (flag=1). No false rotations; state consecutiveness handled per spec.

### What Didn't Work
- **The book has drifted to 100% ETF core / 0 satellites — the alpha engine is idle, and it shows.** BTSG's stop-out (Wed) emptied the satellite sleeve, and the standing satellite name AMG was skipped/HOLD'd every remaining session (Wed corrupted wide open quote ~13% spread; Thu/Fri deployment-ceiling + extended-chase risk into risk-off). A pure sector-ETF book is structurally ~market-tracking with minimal tracking error — which is exactly the profile of 3 consecutive sub-benchmark weeks. The satellites are where alpha comes from, and they've been on the bench.
- **The ETF core was the P&L drag again (-$37.30 week delta).** XLI gave back -$25.52 and XLB -$14.80 of unrealized on the choppy/risk-off tape; XLU's fresh Wed clip is already -1.27% on-cost (bought near a local high, now the book's weakest and freshly decay-flagged); only XLRE (+$28.98) carried. Neither XLB nor XLI reached its next ladder tier, so the ladder stayed dormant.
- **The market-open HOLD-path logging gap recurred twice (Jul 14, Jul 16), tripping Rule 18 both times.** Wk11 flagged this exact bug (Jul 8) and recommended a durable code fix; it was not applied, and it fired two more times this week. The guardrail caught it each time (URGENT Telegram + MISSING-ROUTINE placeholder) and Jul 17 finally wrote an explicit HOLD row — but the underlying routine bug is now a clear 3-week recurring pattern, not a one-off.

### Key Lessons
- **A 0/3 satellite sleeve mechanically caps the bot near beta.** The core-satellite architecture depends on the satellite sleeve to generate alpha; with it empty, the bot is a slightly-worse-than-market sector-ETF basket (adds no edge, subtracts a little to churn/timing). The 3-week alpha slump correlates directly with the sleeve winding down (2 sats → 1 → 0). Re-populating the satellite sleeve — cleanly, when quote + deployment + macro-window align — is the single highest-leverage lever for next week, not another core clip.
- **Deployment recovered organically this week, softening (not eliminating) the Wk11 partial-clip case.** The full-clip deadlock bit only once this week (Jul 14 XLU HOLD, resolved Jul 15 when BTSG freed cash). The proposed partial-clip mechanism would still have deployed a day earlier, but the urgency is lower than Wk11's 4-session deadlock. Keep on file; it is not this week's binding constraint.
- **An unfixed operational bug will keep firing.** The HOLD-path logging gap has now tripped Rule 18 three times across two weeks. The guardrail is doing its job, but relying on a downstream sweep to paper over a known upstream bug is fragile — the durable fix (market-open always appends its TRADE-LOG row on the HOLD path) should be applied before it masks a real cron skip.
- **Visa-aware execution remains a solved problem (12 weeks / 61 days, zero day trades).** Residual risk lives entirely in strategy selection (satellite re-entry timing, core-vs-leadership) and one operational logging bug — not in execution discipline.

**Satellite-sleeve check (v3 spec):** W10 sat -2.54% / core +1.09% (sat UNDER); W11 sat +0.46% / core -1.23% (sat OVER); **W12 sat -$49.87 / core -$37.30 (sat UNDER).** The 3+ consecutive-week UNDERperformance shrink-sat trigger is NOT met (W11 broke the streak with a sat-over). No shrink-sat proposal. Caveat: W12's "satellite" figure is a single BTSG round-trip on a sleeve that emptied to 0/3 mid-week — a degenerate sample, not evidence the sleeve is structurally weak. The signal this week is the OPPOSITE of shrink-sat: the sleeve is under-utilized, not over-allocated.

### Adjustments for Next Week
- **Mon Jul 20 (Week 13 Day 1): prioritize satellite re-entry, not another core clip.** The book is 79% deployed and 100% core — full and balanced on the beta side. The gap vs SPX is an alpha gap, and alpha needs the satellite sleeve back in play. Re-screen AMG (Financials, Zacks #1) for a clean quote + a pullback toward its 50-DMA (was extended +8%/10-sessions into risk-off — prefer a base, not a chase); re-run the single-stock momentum/RS/liquidity screen for fresh leadership names. Deployment headroom is ~$606 to the 85% ceiling — a satellite add needs a scale-out/stop-out or equity growth to free room (or a below-full clip if the partial-clip proposal is approved).
- **Watch XLU (fresh DECAY-FLAG=1).** A 2nd consecutive Mon midday flag (below entry AND lagging SPY 10-sessions) triggers a Rule 16 rotation — which would free ~$1,990 and a Utilities slot for redeployment into leadership. -1.27% on-cost, the book's weakest name.
- **Watch XLI.** +3.19% on-cost, first ETF scale-out at +7% ($185.87, ~+3.7% away) — the closest ladder tier in the book.
- **Macro calendar:** no Tier-1 binaries until **FOMC Jul 28–29 + Core PCE ~Jul 30**. The next two weeks are a clean window for satellite entries (v3.2 macro-proximity gate is not blocking early — only re-checks T+1/T+2 as entries approach the FOMC week).
- **Apply the durable market-open HOLD-path logging fix** before it masks a real cron skip.
- **No auto-applied strategy mutations** (DECIDED G). See proposed changes below.

### Overall Grade: C+

A quiet, disciplined, modestly-red week (-1.07% absolute, -0.52% alpha) whose real story is a **structural drift to a 100%-core book**. The mechanics were clean: the Wk11 underdeployment deadlock self-resolved (48.8%→79.0%, back in-band), the sole closed trade was a +5.3% BTSG runner win, and visa-aware execution was flawless for the 12th straight week (zero violations, zero day trades). The alpha miss also narrowed for a 2nd week (-2.38→-1.49→-0.52) on a benchmark that was itself red. But three things keep it at C+: (1) the satellite sleeve emptied to 0/3 with no re-entry, leaving the bot a near-beta sector-ETF basket that structurally can't out-earn the index — the direct cause of the 3-week alpha slump; (2) the ETF core was again the P&L drag (-$37) with a freshly-bought XLU already the weakest, decay-flagged name; (3) a known operational bug (market-open HOLD-path logging gap) recurred twice more, tripping Rule 18. Execution earns a B; the idle alpha engine + the unfixed logging bug pull it to **C+**. Rolling cum alpha is still positive at +3.50pp and phase P&L +2.13%, but re-arming the satellite sleeve — not adding a 5th core ETF — is the lever that turns three straight sub-benchmark weeks around.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Satellite re-entry priority signal (v3.2 proposal, NEW THIS WEEK — MEDIUM conviction, observational).** When the satellite sleeve falls to 0/N *and* the bot has under-performed the benchmark for 2+ consecutive weeks, market-open/pre-market should explicitly rank a qualifying satellite entry ABOVE a marginal 5th core-ETF add for the same deployment headroom (subject to all existing buy-side gates — trend/RS/liquidity/macro-window/sector/quote quality). Rationale: the core-satellite design assigns alpha generation to the satellite sleeve; an empty sleeve mechanically pins the book near beta, which is precisely the 3-week sub-benchmark pattern (W10→W12). This is a prioritization/ranking nudge, not a relaxation of any gate — a satellite that fails a gate is still skipped.
- **Rationale:** The book is 79% deployed, 100% core, 0/3 satellites, and has trailed SPX 3 weeks running while the alpha engine sat idle (BTSG stopped out Wed, AMG skipped every session on quote/deployment/chase grounds). Adding more core ETFs deepens the beta problem; the fix is to get a *clean* satellite back on the book.
- **Evidence:** TRADE-LOG.md 2026-07-15 (BTSG stop-out → sleeve to 0/3), 2026-07-15/16/17 market-open rows (AMG skipped/HOLD'd each session), Wk10→Wk12 alpha -2.38/-1.49/-0.52 tracking the sleeve winding 2→1→0.
- **Conviction: MEDIUM (observational).** One-week signal so far; watch whether Week 13 re-populates the sleeve organically before proposing a rule. If the sleeve stays empty AND the alpha miss persists into W13, elevate.

- **Durable market-open HOLD-path logging fix (carryover from W11 — ELEVATED to HIGH).** Market-open's HOLD/0-order path must ALWAYS append its Market-Open TRADE-LOG row (not only touch HEARTBEAT.md). This was recommended in the Wk11 review (after the Jul 8 trip) and NOT applied; it recurred twice this week (Jul 14, Jul 16), tripping Rule 18 both times. The guardrail catches it, but a known upstream bug masking a downstream sweep is fragile and risks hiding a genuine cron skip.
- **Rationale:** 3 occurrences across 2 weeks (Jul 8, Jul 14, Jul 16) is a durable pattern, not a fluke; the Jul 17 explicit-HOLD row proves the fix is trivial and effective when applied — it just isn't durable in the routine yet.
- **Evidence:** TRADE-LOG.md MISSING-ROUTINE rows 2026-07-14 + 2026-07-16 (both root-caused to the HOLD-path gap, market-open commit touched only HEARTBEAT.md); Wk11 review's identical HIGH-conviction recommendation.
- **Conviction: HIGH (operational).** Trivial, bounded code fix; recurring evidence; recommend applying before Week 13.

- **Partial/fractional core-ETF clip sizing (carryover from W11 — MEDIUM, DOWNGRADED urgency).** The Wk11 proposal stands on file, but the deployment deadlock self-resolved this week (bit only once, Jul 14 XLU, resolved Jul 15). Keep for human review; it is no longer the binding constraint — the satellite-sleeve gap is. Do not prioritize this over the satellite re-entry signal above.
- **Conviction: MEDIUM (deferred — deadlock non-binding this week).**

- **Satellite-sleeve shrink trigger:** NOT met (W10 under / W11 over / W12 under — no 3-consecutive-under streak; and W12's "under" is a degenerate single-name round-trip on a sleeve that emptied to 0/3). No shrink-sat proposal — the signal is under-utilization, not over-allocation. Observation continues.
- **Conviction: no proposal (trigger not met; opposite signal noted).**

## Week ending 2026-07-24

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,216.76 (Jul 17 EOD snapshot; prior-review account.equity basis $10,212.75) |
| Ending portfolio | $10,339.05 (account.equity; Jul 24 EOD snapshot portfolio $10,335.79) |
| Week return | +$122.29 (+1.197%) [snapshot→equity; snapshot→snapshot +$119.03 / +1.165%] |
| S&P 500 week | ~+0.34% (7,457.69 → 7,483.24 — NOISY/LOW-CONFIDENCE; Jul 17 anchor 7,457.69 corroborated by FRED + Statmuse this week, replacing prior review's 7,533.77 vendor drift; Jul 24 close 7,483.24 single-source. A stray Perplexity "+1.76% week" figure was discarded as internally inconsistent with the daily levels) |
| Bot vs S&P | **+0.85%** (BEAT) |
| Alpha vs SPX (v3) | **+0.85% (headline)** — first benchmark BEAT in 4 weeks; ends the 3-week negative-alpha streak (W10 -2.38 / W11 -1.49 / W12 -0.52 → **W13 +0.85**). Rolling W6→W13 cum alpha +4.35pp |
| Core/Satellite P&L (v3) | core **+$123.04** (all of the week's P&L) / satellite **$0.00** (sleeve 0/3 all week — the beat came from core sector-ETF selection, NOT the alpha sleeve) |
| Trades | 0 BUYs (6th–10th consecutive HOLD sessions across the week) — realized exits 0: W:0 / L:0 / open:4 (XLB/XLI/XLRE/XLU) |
| Win rate | n/a (0 closed) |
| Best trade | n/a (0 closes) |
| Worst trade | n/a (0 closes) |
| Profit factor | n/a (0 realized) |
| daytrade_count | 0 (delta vs prior week: 0 -> 0) — null in paper /account (cosmetic quirk), trading_blocked=false → treated 0; **13 consecutive weeks / 66 trading days zero day trades** |
| Capital deployment | 79.26% EOD ($8,192.30 / $10,335.79) — **squarely in the v3 75–85% band** all week |
| Phase P&L | +$339.05 (+3.39%) — **new phase high** (equity basis; EOD-snapshot basis +$335.79 / +3.358%) |
| Trading sessions | 5 (Mon Jul 20 – Fri Jul 24) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| — | — | — | — | No positions closed this week (0 sells, 0 stop-outs, 0 scale-outs). |

### Open Positions at Week End
| Ticker | Entry       | Close   | Unrealized       | Stop                                             | Tier |
| ------ | ----------- | ------- | ---------------- | ------------------------------------------------ | ---- |
| XLB    | $50.08      | $51.06  | +$39.20 (+1.96%) | $49.5783 (7% trail, GTC 9b627571, hwm $53.31)    | core |
| XLI    | $173.713636 | $182.22 | +$93.61 (+4.90%) | $176.567 (5% trail, GTC 4b207f64, hwm $185.86)   | core |
| XLRE   | $44.79      | $45.86  | +$49.22 (+2.39%) | $41.517 (10% trail, GTC 16d5a6b2, hwm $46.13)    | core |
| XLU    | $45.80      | $46.27  | +$20.68 (+1.03%) | $41.9625 (10% trail, GTC fa8eb3f2, hwm $46.625)  | core |

daytrade_count: 0 (13 consecutive weeks; null in paper API, trading_blocked=false → treated 0). Positions 4/6; ETF core = 100% of deployed ($8,192.30) ≥ 45% floor ✓; sectors evenly balanced (Materials/Industrials/Real Estate/Utilities, each ~24.9–25.8%, all ≤50%) ✓. Satellite sleeve 0/3 (all slots open — 2nd consecutive idle week). All 4 held-book GTC trailing stops armed & ratcheted (XLRE + XLU trails stepped up Fri on fresh hwm); Rule 17 clean. All 4 positions closed the week green vs entry — no live DECAY-FLAG (XLU chain reset Fri).

### What Worked
- **Beat the benchmark (+0.85% alpha) and hit a new phase high (+3.39%) — the best week by both metrics since Week 9.** After 3 straight sub-benchmark weeks the bot out-earned SPX on a modestly-green tape (SPX ~+0.34%; bot +1.20%). All 4 core ETFs finished green vs entry, led by XLI +4.90% and XLRE +2.39% (Friday's rate-sensitive real-estate bid). The beat is genuine but came entirely from **core sector selection**, not the (idle) satellite sleeve.
- **Zero money-moving rule violations, 13th straight clean visa-aware week.** 0 sells → Rule 14 gate never exercised; all 4 trailing stops armed and ratcheting up on new highs (Rule 6); no -7% breach (Rule 7); Rule 17 first-action scan clean every session; daytrade_count 0/5 all week. **13 consecutive weeks / 66 trading days, zero day trades.**
- **Rule 16 decay machinery tracked and self-reset correctly.** XLU carried a live flag=1 into Monday (from Fri Jul 17), flag=0 Monday (marginally ahead of SPY), flag=1 Tuesday, then RESET decisively by Thu/Fri as XLU climbed +1.00% above entry. No false rotation fired; the Jul 22 midday cron skip left the chain briefly ambiguous but the Thu/Fri recovery mooted it.
- **A qualified satellite finally appeared.** SCHW (Financials/brokerage, Zacks Strong Buy) became the **first single-stock name in weeks to clear every momentum/RS/liquidity/macro-window screen** on Friday (trend $101.61 > 50-DMA > 200-DMA; RS10 +1.51pp / RS50 +15.58pp both positive — the exact test AMG/APH/DHR each failed). The screening funnel is working; leadership is re-emerging.

### What Didn't Work
- **The satellite sleeve stayed 0/3 for a 2nd straight week — and this week it was NOT a screening problem, it was the deployment ceiling.** SCHW passed every gate except one: the v3.1 deployment ceiling (~$603 headroom to 85% vs a ~$1,580 full risk-parity clip → ~94.5% breach). The alpha engine had a clean, qualified name and could not buy it purely for lack of ~$1K of headroom. This is exactly the scenario the W11 partial-clip proposal anticipated — and it is now the single binding constraint on alpha, not screening or quote quality.
- **Two routine outages this week — one of them genuine.** Market-open's HOLD-path logging gap tripped Rule 18 on Jul 21 AND Jul 24 (now 5–6 recurrences: Jul 8/14/16/20/21/24) — still logging-only, no money-moving action missed. But **Jul 22's midday was a genuine cron skip** (no midday commit existed at all): the Rule 16 XLU decay-chain check did not run that session, leaving the chain state ambiguous for a day. That is a step up in severity from the market-open logging gap — an actual missed evaluation, not just a missing log row.
- **The alpha engine remains idle; this week's beat masks a structural dependency on core beta.** The book is a 100%-core sector-ETF basket for the 2nd week running. It beat this week on favorable sector selection (Materials/Industrials/Real-Estate/Utilities all green), but a pure-core book is structurally near-beta over time — a good week here doesn't change the design's reliance on satellites for durable alpha. The beat is welcome but not evidence the core-only posture is a winning long-run stance.

### Key Lessons
- **The binding constraint on alpha has shifted from screening to the deployment ceiling.** For 3 weeks the story was "no satellite clears the RS screen." This week a name (SCHW) did — and the full-clip-vs-headroom deadlock blocked it anyway. The partial-clip mechanism (proposed W11, kept on file W12) is no longer a nice-to-have; it is the specific fix that would have let the qualified SCHW clip on Friday. Elevate.
- **A benchmark beat from core-only is fragile, not a strategy validation.** W13's +0.85% alpha is real P&L but came from sector-ETF selection on a friendly tape. It should not be read as "the core-only book works" — the core-satellite design still assigns durable alpha to the satellite sleeve, which sat empty. Re-arming a clean satellite (SCHW, if headroom frees) stays the highest-leverage lever.
- **The operational-bug backlog is now compounding.** The market-open HOLD-path logging fix has been recommended for 3 weeks and never applied; it has now recurred 6 times. This week a *second, distinct* outage (Jul 22 midday genuine cron skip) appeared. Relying on the downstream Rule 18 sweep to paper over upstream cron/logging fragility is getting riskier as the number of distinct failure points grows.
- **Visa-aware execution stays a solved problem (13 weeks / 66 days, zero day trades).** All residual risk is in strategy selection (satellite re-entry timing, deployment-ceiling handling) and operational cron/logging reliability — none in execution discipline.

**Satellite-sleeve check (v3 spec):** W11 sat +0.46% / core -1.23% (sat OVER); W12 sat -$49.87 / core -$37.30 (sat UNDER); **W13 sat $0.00 (sleeve 0/3, idle) / core +$123.04.** The 3+ consecutive-week UNDERperformance shrink-sat trigger is NOT met (W11 broke it with a sat-over; W13 has no satellite P&L to compare — degenerate, not underperformance). The signal remains the OPPOSITE of shrink-sat: the sleeve is under-utilized (empty 2 weeks), not over-allocated. No shrink-sat proposal.

### Adjustments for Next Week
- **Mon Jul 27: SCHW is the priority satellite re-entry the moment headroom frees.** It cleared every momentum/RS/liquidity/macro screen Friday and is blocked only by the deployment ceiling (~$1K headroom needed vs a ~$1,580 clip). Nearest capital-freeing catalyst = **XLI first +7% scale-out at $185.87** (Fri close $182.22 / +4.90% — closest ladder tier in the book; a scale-out frees ~$670 and tightens XLI's trail). If the partial-clip mechanism is approved, SCHW can be sized to fit available headroom immediately.
- **Macro week ahead is heavy: FOMC Jul 28–29 (decision + Powell presser Jul 29) + Core PCE Jul 30.** The v3.2 macro-proximity gate blocks a *fresh satellite* entry on T+1/T+2 of a Tier-1 binary — so a SCHW entry Mon Jul 27 (T+0) puts FOMC on T+2 (Jul 29), which the gate would BLOCK. Practical implication: either enter SCHW Monday only if the T+1/T+2 window is clear (it is not — FOMC is Wed), or **defer SCHW to Thu Jul 30 / Fri Jul 31 after the FOMC+PCE binaries clear.** Rate-sensitive XLU/XLRE are two-sided into the FOMC — watch for decay flags if they roll over post-decision.
- **Watch XLI (+4.90%, closest ladder tier).** First ETF scale-out at +7% ($185.87) — a fire frees ~$670 and is the most likely organic headroom source for a satellite clip.
- **Apply the durable market-open HOLD-path logging fix AND investigate the Jul 22 midday cron skip.** Two distinct operational failure points now; the logging fix is trivial and 3-weeks overdue, and the genuine midday skip warrants a cron-config check before it drops a money-moving evaluation on a day that matters.
- **No auto-applied strategy mutations** (DECIDED G). See proposed changes below.

### Overall Grade: B+

The strongest results-week since Week 9: **beat the benchmark (+0.85% alpha, ending a 3-week negative-alpha streak), new phase high (+3.39%), all 4 core positions green, zero money-moving rule violations, 13th straight zero-day-trade week.** Execution earns an A. Three things hold it to B+: (1) the beat came entirely from **core sector selection** while the satellite alpha engine sat idle for a 2nd week — a friendly-tape core beat, not a strategy validation; (2) a qualified satellite (SCHW cleared every screen) was blocked **solely by the deployment ceiling** — the alpha engine now has a name it cannot buy for lack of ~$1K headroom, making the long-proposed partial-clip mechanism the binding constraint; (3) **two operational outages** this week, including a *genuine* Jul 22 midday cron skip (a missed Rule 16 evaluation, not just a logging gap) on top of the 6th recurrence of the market-open HOLD-path logging bug. Rolling cum alpha is back up to +4.35pp and the phase is at a new high — but the durable win requires fixing the deployment-ceiling headroom problem so a clean satellite like SCHW can actually be bought.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Partial-clip / deployment-headroom sizing mechanism (carryover W11→W12, ELEVATED to HIGH — now BINDING).** When a satellite passes every buy-side gate but a full risk-parity clip would breach the 85% deployment ceiling, market-open should size the clip DOWN to fit available headroom (down to a minimum viable clip, e.g. ≥ some floor % of equity to keep it meaningful) rather than skipping the entry entirely. Rationale: this week SCHW cleared trend/RS/liquidity/macro/sector/quote and was rejected on the deployment ceiling ALONE (~$603 headroom vs a ~$1,580 full clip) — the alpha engine could not buy a fully-qualified name purely for lack of ~$1K headroom. This has now blocked a qualified satellite entry across multiple sessions and is the single binding constraint on the bot's alpha.
- **Rationale:** For 3 weeks the satellite blocker was screening (no name cleared RS); this week a name cleared and the full-clip-vs-headroom deadlock blocked it anyway. The constraint has moved from selection to sizing — and a partial clip is the specific fix.
- **Evidence:** TRADE-LOG.md 2026-07-24 market-open/EOD (SCHW cleared every momentum screen, rejected on deployment ceiling only, ~$603 headroom vs ~$1,580 clip); W11 + W12 reviews' identical partial-clip proposal kept on file; book 79% deployed / 100% core / 0-satellite 2 weeks running.
- **Conviction: HIGH.** Bounded, well-specified change; now backed by a concrete blocked entry (SCHW), not a hypothetical. Recommend applying before a clean satellite window opens (post-FOMC/PCE, ~Jul 30–31).

- **Durable market-open HOLD-path logging fix + midday cron reliability (carryover W11→W12, HIGH — now with a 2nd distinct outage).** (a) Market-open's HOLD/0-order path must ALWAYS append its Market-Open TRADE-LOG row (not only touch HEARTBEAT.md) — recommended 3 weeks running, never applied, now 6 recurrences (Jul 8/14/16/20/21/24). (b) NEW: investigate the **Jul 22 midday genuine cron skip** — no midday commit existed at all, so the Rule 16 decay-chain evaluation did not run that session. This is a distinct, more severe failure than the logging gap (a missed evaluation vs a missing log row).
- **Rationale:** The logging gap is a durable, trivial-to-fix pattern the guardrail keeps catching; the midday skip is a genuine outage that dropped a real evaluation. Two distinct operational failure points in one week warrant both the trivial code fix and a cron-config review.
- **Evidence:** TRADE-LOG.md MISSING-ROUTINE rows 2026-07-21 (market-open, logging) + 2026-07-24 (market-open, logging) + 2026-07-22 (midday, genuine cron skip — last commit market-open @ 13:39 UTC, no midday commit); W11 + W12 reviews' identical market-open recommendation.
- **Conviction: HIGH (operational).** Logging fix is trivial and overdue; the midday cron skip is a new, real reliability gap needing investigation.

- **Satellite re-entry priority signal (carryover W12 — MAINTAINED at MEDIUM).** When the satellite sleeve is 0/N and the bot has trailed the benchmark recently, rank a qualifying satellite entry above a marginal 5th core-ETF add for the same headroom (subject to all gates). W13 note: the sleeve stayed empty a 2nd week, and although the bot BEAT the benchmark this week on core strength, that beat is core-beta-dependent and fragile — the priority signal still holds. Superseded in practice by the partial-clip proposal above (the actual blocker this week was headroom sizing, not ranking). Keep on file; do not elevate independently.

## Week ending 2026-07-31

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,339.05 (prior review's ending `account.equity`; Jul 24 EOD snapshot basis $10,335.79) |
| Ending portfolio | $10,120.56 (`account.equity`; Jul 31 EOD snapshot portfolio $10,116.70) |
| Week return | **-$218.49 (-2.113%)** [snapshot→snapshot -$219.09 / -2.120%] |
| S&P 500 week | **+1.10%** (SPY $738.93 Jul 24 [bootstrapped from bars query] → $747.03 Jul 31, Alpaca bars) |
| Bot vs S&P | **-3.21%** (MISS) |
| Alpha vs SPX (v3) | **-3.21pp (headline)** — **the worst alpha week of the phase**, exceeding W10's -2.38pp. Series: W10 -2.38 / W11 -1.49 / W12 -0.52 / W13 +0.85 → **W14 -3.21**. Rolling W6→W14 cum alpha falls +4.35pp → **+1.14pp**. *Methodology note: this is the first week the benchmark is sourced from `alpaca.sh bars SPY` per v3.3. Prior weeks used web-sourced SPX index levels. Per v3.3 no prior figure has been revised; the SPY series is bootstrapped from this week's bars pull and `last_close $747.03 (Jul 31)` is now the cached anchor for next week's `prior_close`.* |
| Core/Satellite P&L (v3) | core **-$188.12** / satellite **-$27.09** (BIIB, 1 session held) |
| Trades | 2 BUYs (BIIB, XLV) — 2/5 weekly budget used; 2 exits → W:1 / L:1 / open:4 |
| Win rate | 50% (1 of 2 closed) |
| Best trade | XLI +1.63% (+$31.09) |
| Worst trade | XLU -2.66% (-$53.68) |
| Profit factor | 0.58 ($31.09 / $53.68) |
| daytrade_count | **0 (source=local, derived — field absent)** (delta vs prior week: 0 -> 0) — **14 consecutive weeks / 71 trading days, zero day trades** |
| Capital deployment | **64.16%** EOD ($6,492.89 / $10,120.56) — **BELOW the v3 75–85% band**, 3rd consecutive session out of band |
| Phase P&L | +$120.56 (+1.206%) — down from last Friday's +3.39% phase high |
| Trading sessions | 5 (Mon Jul 27 – Fri Jul 31) |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| XLI | $173.713636 (2026-05-13) | $176.54 (Jul 29, 11:14 CT) | **+$31.09 (+1.627%)** | GTC trailing stop fired — 5% trail off hwm $185.86, ladder-tightened under Rule 8. Automatic fill, not routine-initiated → Rule 14 N/A. Held ~2.5 months. Fired on the FOMC-day flush; XLI closed the week at $179.84, so the exit gave back ~$3.30/sh (~$36) vs holding — a defensible profit-protecting exit at an unlucky price. |
| XLU | $45.80 (2026-07-15) | $44.58 (Jul 31, 12:04 CT) | **-$53.68 (-2.66%)** | Rule 16 momentum-decay rotation — 2nd consecutive midday flag (Jul 30 flag=1 → Jul 31 flag=1: below entry AND lagging SPY 10-session -1.25% vs +0.25%). `close` first returned HTTP 403 (`qty_available: 0`, shares reserved by GTC stop fa8eb3f2); stop cancelled (a cancel, not a sell — no DTC impact), close re-issued, filled in 4 partials @ $44.58. **Exit printed ABOVE the $44.35 close — Rule 16's timing was good.** Held ~2.5 weeks → not a day trade. |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop | Tier |
| ------ | ----- | ----- | ---------- | ---- | ---- |
| BIIB | $206.82 (Jul 31) | $202.95 | -$27.09 (-1.87%) | $182.655 (10% trail, GTC e39f0198, hwm $202.95) | **satellite** |
| XLB | $50.08 | $50.53 | +$18.00 (+0.90%) | $49.5783 (7% trail, GTC 9b627571, hwm $53.31) | core |
| XLRE | $44.79 | $45.07 | +$12.88 (+0.63%) | $41.8095 (10% trail, GTC 16d5a6b2, hwm $46.455) | core |
| XLV | $161.92 (Jul 31) | $162.97 | +$6.30 (+0.65%) | $146.439 (10% trail, GTC 95b2fc1d, hwm $162.71) | core |

daytrade_count: **0 (source=local — derived, field absent from the paper `/account` payload)**. Positions 4/6. ETF core $5,072.24 / $6,492.89 deployed = **78.12% ≥45% floor ✓**. Satellite sleeve **1/3** (BIIB — the alpha engine is live again after 4 idle weeks); Health Care satellites 1 ≤2 ✓. Sector spread: Health Care 36.94% / Real Estate 31.93% / Materials 31.13% of deployed — all ≤50% ✓. Utilities exposure now zero. Position weights vs equity: XLRE **20.49%** (drift above the 20% cap from a falling denominator — not an entry breach; no add permitted while it sits there), XLB 19.97%, BIIB 14.04%, XLV 9.66%. **All 4 positions carry armed GTC trailing stops** (verified live in `orders open`); Rule 17 clean, zero unprotected names.

### What Worked
- **The satellite sleeve is live again after four idle weeks, and the v3.3 headroom-reservation mechanism worked exactly as designed.** Friday's market-open placed the first TRADE decision in 11 sessions: BIIB (satellite, Health Care — Q2 beat already resolved, RS10 +0.73pp / RS50 +7.68pp, trend above both DMAs) and XLV (core, Health Care — RS50 +12.04pp, best of all 8 sector ETFs). BIIB reserved $1,449.84 of the $2,564.50 headroom at sizing time, which correctly shrank XLV from a 9-sh full clip to 6 sh (`clamped=headroom`). That is precisely the double-consumption bug the v3.3 reservation exists to prevent — **the W11→W13 partial-clip proposal is now resolved and can be retired.**
- **Rule 16 fired cleanly and, unusually, exited well.** The XLU decay chain armed Thursday and confirmed Friday, and the rotation printed $44.58 against a $44.35 close — the rotation captured $0.23/sh over simply holding to the bell. The 403-on-`qty_available` edge case (shares reserved by the open GTC stop) was diagnosed and resolved in-run by cancelling the stop and re-issuing, with the cancel correctly reasoned as DTC-neutral.
- **Money-moving execution stayed clean for a 14th straight week.** All 4 open positions armed with GTC trails; Rule 13 placed both new stops at the 15:00 CT bell so neither could fire same-day; Rule 14 pre-flight ran broker-first on the one routine sell and resolved DTC=0 from `activities` with TRADE-LOG corroboration; Rule 15 correctly excluded both same-day names from midday; no -7% breach. **71 trading days, zero day trades.**
- **The Rule 14 audit-token sweep ran for the first time — and immediately earned its keep.** It found 8 of 10 expected token slots missing (below). A detector that finds a real gap on its first run is a detector worth having.

### What Didn't Work
- **The worst alpha week of the phase (-3.21pp), and the mechanism is identifiable: the book was ~40% cash through a +2.4% two-day SPY rally.** The Jul 29 XLI stop-out returned ~$1.94K to cash at the FOMC-day flush, dropping deployment to 60.18%. It stayed at ~60% through Thursday and Friday — exactly the two sessions SPY rallied +1.68% and +0.72%. Being ~40% uninvested across a +2.41% move costs roughly **0.9–1.0pp**, i.e. close to a third of the week's entire shortfall, and it is pure structural under-deployment, not a bad stock pick.
- **The rest of the shortfall is sector selection: the book was long the two worst places to be into and out of an FOMC.** Rate-sensitive XLU and XLRE led the drag all week (XLU -$74.36 week contribution, XLRE -$36.34), and XLB gave back -$21.20. A core basket of Materials / Real Estate / Utilities is structurally the wrong side of a hawkish-repricing tape, and the bot held it through the binary rather than reducing into it.
- **The Rule 14 audit token was missing from 8 of 10 expected slots — the gate cannot be shown to have run on 4 of 5 sessions.** Expected `2 × 5 sessions = 10`; found **2**, both on Jul 31. Missing on BOTH market-open and midday for Jul 27, 28, 29 and 30. The cause is visible in the log: the token is emitted on the TRADE and sell paths only, while HOLD, NO-ACTION and MISSING-ROUTINE paths write prose like *"daytrade_count field absent... treated 0/5"* instead of the literal token. **This is the exact missing-detector shape that let the original Rule 14 fail-open survive fourteen weeks** — the gate may well have been evaluated each day, but the audit trail cannot prove it.
- **Operational cadence degraded further: 3 routine gaps this week.** A genuine daily-summary skip Jul 27 (no EOD snapshot at all — the 2nd genuine daily-summary gap of the phase) plus market-open logging gaps Jul 28 and Jul 30 (9th and 10th recurrences of a bug first recommended for fix in Week 11). Nothing money-moving was missed on any of the three, but the recommendation is now **four weeks overdue** and the failure count keeps climbing.

### Key Lessons
- **Under-deployment after a forced exit is now a measurable, recurring cost — and no rule currently corrects it.** Rule 5's 75–85% band is stated as a *target* with no mechanism that acts when the book falls out of it. This week a stop-out dumped the book to 60% and it simply sat there for three sessions while the market rallied. The bot re-deployed on Friday only because a qualifying idea happened to appear. The 2:1 R:R entry gate — correct for satellites — is too strict a gate to leave standing between the portfolio and *ballast* re-exposure after an involuntary exit.
- **A trailing stop and a decay rotation both fired within 3 days at local lows; that is a coincidence, not a pattern, but it argues for checking the tape regime.** XLI's ladder-tightened 5% trail fired on the FOMC flush and gave back $3.30/sh vs the week's close. XLU's rotation, by contrast, was well-timed. One good, one unlucky — the exits were rule-correct in both cases and should not be second-guessed individually. What *is* worth noting is that both exits landed in a 3-session window that turned out to be the week's low.
- **An audit that has never run is not a control.** The Rule 14 token sweep was specified in v3.3, described in three files as the thing the weekly review greps for, and had never actually been executed until today. Its first run found an 80% miss rate. The same reasoning applies to every other "the next routine will detect it" guardrail in the rulebook — detection claims should be verified by running them, not by reading them.
- **Execution discipline remains a solved problem; results risk is entirely in selection and deployment.** 14 weeks, 71 sessions, zero day trades, zero unprotected positions, zero money-moving rule breaches. Every point of this week's -3.21pp came from *what* the bot owned and *how much* of the account was working — not from how it traded.

**Satellite-sleeve check (v3 spec):** W12 sat -$49.87 / core -$37.30 (sat UNDER); W13 sat $0.00 (sleeve idle — degenerate, not underperformance) / core +$123.04; **W14 sat -$27.09 on ~$1,448 for 1 session (-1.87%) / core -$188.12 on ~$6,700 average capital (≈-2.8%) → sat OVER on a per-capital basis.** The 3+ consecutive-week UNDERperformance shrink-sat trigger is **NOT met** (W13 degenerate, W14 sat-over). As in prior weeks the signal points the opposite way — the sleeve is under-utilised (1/3 slots, and empty for the 4 weeks before Friday), not over-allocated. **No shrink-sat proposal.**

### Adjustments for Next Week
- **Monday Aug 3's first-order task is re-deployment: 64.16% deployed, ~$3.63K cash, and 3/5 weekly trades unused.** The budget is not the constraint and the macro window is clear (nearest Tier-1 binary is **NFP Fri Aug 7**, so a Monday entry sits at T+4). Target the 75–85% band; ~$1.1–2.1K of adds gets there.
- **Re-screen a 2nd satellite and a 4th core name — and prefer sectors that are not rate-sensitive.** The book is now Health Care 36.9% / Real Estate 31.9% / Materials 31.1% with Utilities at zero. XLV (RS50 +12.04pp, the strongest measured RS in the complex) is the incumbent leader; Health Care sector cap has room to 50% but satellite count there is already 1 of the permitted 2.
- **Watch BIIB closely — it is the only satellite and it closed its first session -1.87%.** Stop is $182.655 (10% trail, hwm $202.95); Rule 7's -7% hard-close level is ~$192.34. It is now aged, so both Rule 7 and Rule 16 apply from Monday's midday onward.
- **Ladder watch is quiet:** XLB +0.90% (hwm-gain +6.45%, target_trail 7% == current — Rule 9 blocks any re-tighten), XLRE +0.63% (hwm-gain +3.72%, below the +4% tier), XLV +0.65%, BIIB -1.87%. No position is near a scale-out tier.
- **Apply the Rule 14 token fix and the market-open HOLD-path logging fix together — they are the same class of bug and both are now overdue.** See proposed changes below.
- **No auto-applied strategy mutations** (DECIDED G).

### Overall Grade: C

**The worst results week of the phase.** -2.11% against a +1.10% S&P is **-3.21pp of alpha**, exceeding W10's prior worst; the phase gave back two-thirds of its cumulative gain (+3.39% → +1.21%) and rolling W6→W14 alpha fell from +4.35pp to +1.14pp. Two things hold the grade at C rather than lower: **money-moving execution was flawless for a 14th straight week** (all positions stopped, both exits rule-correct, Rule 14 gate correctly exercised on the one routine sell, 71 sessions at zero day trades), and the week genuinely **fixed two long-standing structural problems** — the satellite sleeve is live again after 4 idle weeks, and the v3.3 headroom reservation demonstrably worked, retiring a proposal that had been carried since Week 11. Three things hold it down: **(1)** ~40% of the account sat in cash through a +2.4% two-day SPY rally after the Jul 29 XLI stop-out, costing an estimated 0.9–1.0pp — a structural gap with no rule to correct it; **(2)** the core basket (Utilities / Real Estate / Materials) was the wrong side of an FOMC repricing and was held straight through the binary; **(3)** the Rule 14 audit sweep, running for the first time, found the gate's audit token missing from **8 of 10** expected slots — the same missing-detector shape that let the original fail-open survive fourteen weeks. The bot traded its rules correctly and still lost badly to the index, which points the entire remedy at deployment mechanics and sector selection, not at execution discipline.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Rule 14 (proposed change): the `Rule 14 DTC:` audit token must be emitted on EVERY routine path, unconditionally.** `market-open` STEP 7 and `midday` STEP 6 must write the literal token on HOLD, zero-fill, NO-ACTION and DTC-abort paths — not only on TRADE/sell paths. Where the count is not resolvable, the correct output is still the token (`Rule 14 DTC: 0 (source=local)` or `... (source=error)`), never prose.
- **Rationale:** The first-ever run of the v3.3 audit sweep found the token in 2 of 10 expected slots — the day-trade gate cannot be demonstrated to have run on 4 of the week's 5 sessions.
- **Evidence:** TRADE-LOG.md 2026-07-27 through 2026-07-31 — token present only in the Jul 31 market-open and Jul 31 midday blocks; Jul 27/28/29/30 market-open and midday blocks all substitute prose ("daytrade_count field absent... treated 0/5"). Expected count 2 × 5 = 10, found 2.
- **Conviction: HIGH.** Trivial, purely additive logging change; the rule text already mandates it, only the routine prompts fail to comply.

- **Rule 5 (proposed change): add a re-deployment trigger after an involuntary exit.** When deployment falls below the 75% floor and remains there for 2+ consecutive sessions, permit a **core-ETF ballast re-add at a relaxed R:R threshold** (e.g. ≥1.5:1 instead of ≥2:1), sized to restore the lower band. Satellites keep the full ≥2:1 requirement. Rule 5 currently states a target band with no mechanism that acts when the book leaves it.
- **Rationale:** The Jul 29 XLI stop-out dropped the book to 60% deployed and it stayed there through Thursday and Friday — the exact two sessions SPY rallied +2.41%. ~40% in cash across that move costs ~0.9–1.0pp, roughly a third of the week's entire -3.21pp shortfall. Thursday's pre-market explicitly rejected every core candidate on the 2:1 gate alone while sitting on $4.1K of idle cash.
- **Evidence:** TRADE-LOG.md Jul 29 EOD (deployment 60.18%, "first time in weeks the deployment ceiling is NOT the binding constraint"), Jul 30 EOD (59.95%, "today's block is the 2:1 R:R gate... no core ETF clears ≥2:1"), Jul 31 EOD (64.14%); SPY bars Jul 29 $729.46 → Jul 30 $741.69 → Jul 31 $747.03.
- **Conviction: MEDIUM-HIGH.** Well-evidenced and quantified this week, but it deliberately loosens an entry gate — the risk is trading a measured cash drag for lower-quality core entries. Recommend a bounded trial (core only, ≥1.5:1 floor, ballast size only) rather than a blanket change.

- **Market-open HOLD-path logging fix (carryover W11→W12→W13, HIGH — now 10 recurrences and 4 weeks overdue).** Market-open's HOLD/0-order path must ALWAYS append its TRADE-LOG row rather than only touching HEARTBEAT.md. **Now bundled with the Rule 14 token fix above — they are the same class of bug** (a routine path that skips its mandated log write) and should be applied in one pass.
- **Rationale:** Recommended for four consecutive weeks and never applied; recurrences Jul 8/14/16/20/21/22/24/27/28/30. A second failure mode appeared alongside it — the **Jul 27 daily-summary genuine cron skip** (no EOD snapshot written at all), the 2nd genuine daily-summary gap of the phase, which is a missed routine rather than a missed log line and warrants a cron-config check.
- **Evidence:** TRADE-LOG.md MISSING-ROUTINE rows 2026-07-28 and 2026-07-30 (market-open), 2026-07-27 (daily-summary, genuine — no `## Jul 27 — EOD Snapshot` header exists); W11/W12/W13 reviews carrying the identical recommendation.
- **Conviction: HIGH (operational).** Trivial fix, long overdue; the daily-summary cron skip is a separate reliability item needing investigation rather than a code change.

- **Partial-clip / deployment-headroom sizing mechanism (carryover W11→W13) — RESOLVED, retire.** The v3.3 headroom reservation shipped and worked as specified on its first live exercise: BIIB reserved $1,449.84 of $2,564.50 headroom at sizing time, correctly shrinking XLV from 9 sh to 6 sh (`clamped=headroom`) instead of skipping the entry. No further action required; removing from the carryover list.

## Week ending 2026-08-07

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,120.56 (prior review's ending `account.equity`; Jul 31 EOD snapshot basis $10,116.70) |
| Ending portfolio | $10,273.02 (`account.equity`; Aug 7 EOD snapshot portfolio $10,275.90) |
| Week return | **+$152.46 (+1.506%)** [snapshot→snapshot +$159.20 / +1.574%] |
| S&P 500 week | **+3.51%** (SPY $747.03 Jul 31 → $773.26 Aug 07, Alpaca bars) — the strongest SPY week of the phase |
| Bot vs S&P | **-2.00pp (MISS)** |
| Alpha vs SPX (v3) | **-2.00pp (headline)** — 2nd consecutive miss. Series: W10 -2.38 / W11 -1.49 / W12 -0.52 / W13 +0.85 / W14 -3.21 → **W15 -2.00**. Rolling W6→W15 cum alpha falls +1.14pp → **-0.86pp — negative for the first time in the phase.** *Provenance: `prior_close` $747.03 (Jul 31) is the cached anchor recorded in last week's entry, not re-queried; only `last_close` $773.26 (Aug 07) comes from this week's `bars SPY 1Day 10` pull. No prior week's benchmark figure has been revised (v3.3).* |
| Core/Satellite P&L (v3) | core **+$132.84** / satellite **+$22.54** — week-contribution basis (mark-to-market change over the week, not cumulative-from-entry). Core: XLB +$93.20, XLI +$33.52, XLV +$16.26, XLRE -$4.14, XLF -$6.00. Satellite: BIIB +$22.54 (exit $206.17 vs $202.95 week-open mark). ~$3.8 residual vs equity change = fees + close-vs-mark drift |
| Trades | 2 BUYs (XLI, XLF) — 2/5 weekly budget used, 3 expired unused; 2 exits → **W:0 / L:2 / open:4** |
| Win rate | **0%** (0 of 2 closed) |
| Best trade | BIIB **-0.31%** (-$4.55) — no winner closed this week |
| Worst trade | XLF **-1.03%** (-$6.00) |
| Profit factor | **0.00** ($0.00 gains / $10.55 losses) |
| daytrade_count | **0 (source=local, derived — field absent)** (delta vs prior week: 0 -> 0) — **15 consecutive weeks / 76 trading days, zero day trades** |
| Rule 14 audit-token sweep | **10 / 10 expected tokens found** (2 × 5 sessions) — market-open ✓ + midday ✓ on every one of Aug 3, 4, 5, 6, 7. **Zero audit gaps. First clean sweep** (W14: 2/10) |
| Capital deployment | **64.79%** EOD ($6,656.12 / $10,273.02) — below the v3 75–85% band, 1 session (Fri, post-rotation). Mon 78.5% → Tue 78.8% → Wed 84.5% → Thu 84.4% → Fri 64.8% |
| Phase P&L | **+$273.02 (+2.730%)** equity / +$275.90 (+2.759%) snapshot — **new phase closing high** |
| Trading sessions | 5 (Mon Aug 3 – Fri Aug 7) |

**Daily alpha attribution (where the -2.00pp came from):**

| Day | SPY | Book | Deployment | Δ |
|-----|-----|------|-----------|---|
| Mon Aug 3 | +1.42% | +0.35% | 64.1% → 78.5% | **-1.07pp** |
| Tue Aug 4 | +1.80% | +1.10% | 78.8% | **-0.71pp** |
| Wed Aug 5 | -0.20% | +0.22% | 84.5% | +0.42pp |
| Thu Aug 6 | -0.16% | -0.53% | 84.4% | -0.37pp |
| Fri Aug 7 | +0.61% | +0.43% | 84.4% → 64.8% | -0.18pp |

**Monday and Tuesday alone account for -1.78pp of the week's -1.94pp (snapshot basis).** Both were large SPY up-days met by a book that was under-deployed (Monday opened at 64.1%, the 6th consecutive session below the band, carrying $3.6K of idle cash into a +1.42% session) and low-beta (Materials / Real Estate / Health Care against a tech-led index). Friday's out-of-band deployment cost almost nothing — the drag was front-loaded.

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| BIIB | $206.82 (2026-07-31) | $206.17 (Aug 7, 12:06 CT) | **-$4.55 (-0.314%)** | Rule 16 momentum-decay rotation — 2nd consecutive midday flag (Aug 6 flag=1 → Aug 7 flag=1: -0.39% below entry AND 10-session +1.89% vs SPY +4.48%). Held 5 sessions. Stop `e39f0198` cancelled first to free `qty_available: 0` (a cancel, not a sell — no DTC impact), then closed in 2 partials both @ $206.17. The satellite sleeve's only occupant; sleeve now 0/3. |
| XLF | $58.20 (2026-08-05) | $57.60 (Aug 7, 12:07 CT) | **-$6.00 (-1.031%)** | Rule 16 rotation — same double-flag mechanism (-1.01% below entry, 10-session +2.29% vs SPY +4.48%). **Held two sessions — the shortest hold of the phase** — while measuring the **best RS50 in the entire eleven-sector complex (+9.23pp)**. Same `qty_available` pattern: stop `e4f78ff4` cancelled, then closed in 2 partials both @ $57.60. Bought Aug 5, sold Aug 7 → not a day trade. |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop | Tier |
| ------ | ----- | ----- | ---------- | ---- | ---- |
| XLB | $50.08 (2026-05-18) | $52.86 | +$111.20 (+5.55%) | $49.5783 (7% trail, GTC 9b627571, hwm $53.31) | core |
| XLI | $180.99 (2026-08-03) | $185.18 | +$33.52 (+2.32%) | $169.3665 (10% trail, GTC 69d2c5bc, hwm $188.185) | core |
| XLRE | $44.79 (2026-07-13) | $44.98 | +$8.74 (+0.42%) | $41.8095 (10% trail, GTC 16d5a6b2, hwm $46.455) | core |
| XLV | $161.92 (2026-07-31) | $165.68 | +$22.56 (+2.32%) | $150.30 (10% trail, GTC 95b2fc1d, hwm $167.00) | core |

daytrade_count: **0 (source=local — derived, field absent from the paper `/account` payload)**. Positions **4/6**, two slots free. **ETF core = 100.00% of deployed** ≥45% floor ✓ — the first all-core book of the phase. **Satellite sleeve 0/3, all slots free.** Sector spread of deployed: Materials **31.73%** / Real Estate **31.09%** / Industrials 22.26% / Health Care 14.93% — all ≤50% ✓; zero Financials and zero Utilities exposure. Position weights vs equity: XLB **20.56%** and XLRE **20.14%** sit above the Rule 3 20% cap **on appreciation, not on entry** — not a breach, but neither may be added to while there; XLI 14.42%, XLV 9.67%. **All 4 positions carry armed GTC trailing stops** (verified in `orders open`); Rule 17 clean, zero unprotected names, no orphan orders from either rotation. **All four names closed below their high-water marks** despite a green Friday — a bounce that has not yet made new highs.

### What Worked
- **Both long-carried operational proposals shipped, and both are demonstrably working.** The Rule 14 audit-token sweep found **10 of 10** expected tokens — market-open *and* midday on every session, including three HOLD days and one NO-ACTION day, the exact paths that dropped the token in W14 (2/10). And the market-open HOLD-path logging fix — recommended for **four consecutive weeks** across W11→W14 with ten recurrences — held on all three HOLD sessions (Aug 4, 6, 7). **Rule 18 cadence was 20/20 routine slots: 5 pre-market / 5 market-open / 5 midday / 5 EOD. Zero gaps — the first fully clean operational week of the phase.** Two multi-week bug backlogs closed in one week.
- **The week was positive in absolute terms and set a new phase high.** +1.51% on equity, +2.76% phase, all four surviving positions green at the close. XLB (+5.55%) is the book's anchor and is now within ~0.55pp of its +7% scale-out rung.
- **Both rotations executed cleanly against the known `qty_available: 0` edge.** The Jul 31 XLU pattern recurred on both names — all shares reserved by their open GTC trails — and was resolved the same correct way each time: cancel the stop first (correctly reasoned as DTC-neutral), verify availability, then close. Both stops were consumed by their rotations; `orders open` returns exactly the four surviving trails, **no orphans**.
- **Money-moving execution stayed flawless for a 15th straight week.** Rule 14 pre-flight ran broker-first on both sells; Rule 15 correctly found nothing same-day to exclude; Rule 13 armed XLI's and XLF's stops at the 15:00 CT bell so neither could fire same-day; no -7% breach; no stop moved down. **76 trading days, zero day trades.**
- **The double rotation was well-timed on the day it fired.** BIIB and XLF were the two dragging names, and the post-payrolls tape rewarded exactly the cyclical/defensive mix the book kept — the four survivors all closed up while the two sold names were the laggards.

### What Didn't Work
- **The bot captured 43% of the strongest SPY week of the phase.** +1.51% against +3.51% is -2.00pp, the second consecutive miss, and it pushes **rolling W6→W15 cumulative alpha negative (-0.86pp) for the first time.** The phase is still up +2.73%, but it is now behind the index cumulatively — the core-satellite design's entire premise.
- **Under-deployment is now the repeat offender, and it is the same finding as last week, unaddressed.** Monday opened at **64.1% deployed with $3.6K idle** — the 6th consecutive session below the band, dating to the Jul 29 XLI stop-out — straight into a +1.42% SPY session, then a +1.80% Tuesday reached at only 78.8%. Those two days cost **-1.78pp of the week's -1.94pp**. W14 proposed a Rule 5 re-deployment trigger for exactly this; it was not applied, and the same mechanism cost roughly the same again.
- **Rule 16's relative test is misfiring in a breadth-narrow melt-up, and this week made it hard to ignore.** SPY's own 10-session return was **+4.48%** — a bar that **every single one of the six held positions lagged**, and that pushed RS10 negative for **nine of eleven sectors**. The rule then cut the two names that happened to also be a fraction below entry: BIIB at **-0.39%** and XLF at **-1.01%**. XLF was rotated out **after two sessions while carrying the best RS50 in the complex (+9.23pp)**. That is the third consecutive shallow loser cut on relative weakness (XLU -2.66%, BIIB -0.31%, XLF -1.03%; ~$64 realized across the three), and the same +4.48% benchmark simultaneously starved the entry screens — **0 of 9 satellite candidates and 0 of 6 unheld sectors passed on Friday, for a seventh consecutive session.** The rule is selling into a rising index and refusing to buy back into it: the exit gate and the entry gate are both keyed to the same relative-to-SPY measure, so a melt-up makes the book *simultaneously* eager to sell and unable to buy.
- **Eight consecutive sessions of forced buy-side inaction, and 3 of 5 weekly trades expired unused — the third straight under-spent week.** Friday was the cruellest arrangement of the phase: the macro window opened **CLEAR for the first time in seven sessions** on the exact morning the position cap (6/6) and the deployment ceiling ($61.02 of headroom vs a $512.23 minimum clip) were both fully binding. Every constraint was individually correct; their conjunction produced a book that could not act at all.
- **Zero winners closed. Win rate 0%, profit factor 0.00.** The losses are trivially small (-$10.55 combined) and both were momentum exits rather than damaged theses, but a week that closes two positions and books no gain on either is a week the exit rules paid for nothing.

### Key Lessons
- **When the exit gate and the entry gate share a denominator, a melt-up locks the book out in both directions.** Rule 16's rotation test and the pre-market RS screens both measure a candidate against SPY's own 10-session return. When that return is +4.48%, the exit test fires on nearly everything held and the entry test rejects nearly everything available. The bot spent the week selling names it could not replace. This is a structural interaction between two rules that are each individually sound — it is not visible from either rule in isolation, which is precisely why it took a melt-up week to surface.
- **A proposal that is correct, evidenced, and unapplied costs the same amount again next week.** W14 quantified the under-deployment drag at ~0.9–1.0pp and proposed a Rule 5 re-deployment trigger. Nothing was applied. This week the identical mechanism cost -1.78pp. The two operational proposals that *were* applied both worked on their first week (10/10 tokens, 20/20 cadence) — the pattern is that shipping the fix works, and the backlog is where the cost lives.
- **Detectors that ran and found nothing are worth as much as detectors that find something.** The Rule 14 sweep, on its second-ever run, came back 10/10. Last week it came back 2/10 and that was the finding; this week the clean result is itself the evidence that the fix landed. Both runs justify the sweep.
- **Execution discipline remains a solved problem; every point of loss this week was selection and sizing.** 15 weeks, 76 sessions, zero day trades, zero unprotected positions, zero money-moving rule breaches, zero routine gaps. The bot traded its rules correctly and still gave up 2 points to the index — which places the entire remedy in the rulebook, not in the execution.

**Satellite-sleeve check (v3 spec):** W13 sat $0.00 (sleeve idle — degenerate) / core +$123.04; W14 sat -$27.09 on ~$1,448 for 1 session (-1.87%) / core -$188.12 on ~$6,700 (≈-2.8%) → **sat OVER**; **W15 sat +$22.54 on ~$1,421 for 5 sessions (+1.59%) / core +$132.84 on ~$5,900 average capital (≈+2.25%) → sat UNDER on a per-capital basis.** The 3+ consecutive-week UNDERperformance shrink-sat trigger is **NOT met** (W14 was sat-over, so this is week 1 of any streak). And as in every prior week the signal points the opposite way — the sleeve is **under-utilised, now 0/3 and empty again after 5 sessions of its only occupant**, not over-allocated. **No shrink-sat proposal.**

### Adjustments for Next Week
- **Monday Aug 10's first-order task is re-deployment: 64.79% deployed, $3,616.90 cash, 2 open position slots, and a fresh 5-trade budget.** ~$1.1–2.1K of adds restores the 75–85% band. This is the third Monday in a row that opens below the band, and the prior two both cost alpha in the first two sessions of the week.
- **The macro calendar is hostile to satellites almost all week: CPI Wed Aug 12, PPI Thu Aug 13.** Under the v3.2 macro-proximity gate, Mon Aug 10 sits at CPI T+2 (blocked), Tue T+1 (blocked), Wed T+0, Thu is PPI T+0 — **the first clear satellite window is ~Thu Aug 13 / Fri Aug 14.** Core-ETF ballast adds are not macro-gated and are the realistic Monday action.
- **DELL is the standing satellite candidate for the Aug 13 window** — the phase's best single-stock RS50 at **+41.03pp** — but it failed the RS10 arm at -4.50 on Friday, which is exactly the melt-up artifact described above. Re-screen it Thursday. MU has deteriorated to `rs50_negative` and GS has fallen off the watchlist.
- **Watch XLRE — it is one bad session from arming a decay chain.** Worst 10-session performer in the book at **-1.85%**, lagging SPY by 6.33pp, but sits +0.42% above entry so the below-entry leg fails. A single red session flips it, and under the current rule it would be the fourth shallow-loser rotation in three weeks.
- **Ladder watch: XLB is the nearest capital-freeing catalyst.** hwm-gain +6.45%, so the +7% ETF scale-out rung sits at $53.586 (hwm $53.31) — ~0.55pp away; a fire frees ~$700 and tightens the trail. XLI's hwm-gain is **+3.98%, 0.02–0.03pp short of the +4% first rung for a third consecutive session** — a single new high hands Monday's midday its first tightening. XLRE +3.72%, XLV +3.14%.
- **No auto-applied strategy mutations** (DECIDED G). See proposed changes below.

### Overall Grade: B-

**A positive week that lost ground.** +1.51% and a new phase closing high, with **flawless execution for a 15th consecutive week** — 76 sessions at zero day trades, zero unprotected positions, zero money-moving breaches — and, unusually, **two multi-week operational backlogs closed at once**: the Rule 14 audit token came back **10/10** on its second sweep (2/10 last week) and the market-open HOLD-path logging fix held across three HOLD sessions, producing the **first 20/20 routine cadence of the phase**. That is an A on process. What holds the grade to B- is that the bot captured only **43% of the strongest SPY week of the phase**, missing by **-2.00pp** and pushing **rolling cumulative alpha negative (-0.86pp) for the first time** — and the cause is diagnosable and repeated: **-1.78pp of it landed on Monday and Tuesday alone**, against a book that opened the week 64% deployed with $3.6K idle for the sixth straight session, the exact failure W14 quantified and proposed a fix for that was never applied. Underneath it sits a newly visible structural problem: **Rule 16's exit test and the pre-market entry screens share the same relative-to-SPY denominator**, so a +4.48% ten-session benchmark made the book sell three shallow losers it could not replace — including XLF, cut after two sessions while holding the best RS50 in the eleven-sector complex — while rejecting 0 of 9 satellites and 0 of 6 sectors for a seventh straight session. **Zero winners closed, 0% win rate, profit factor 0.00.** The rules were followed exactly and the rules are what cost the money.

## Proposed strategy changes (NOT auto-applied — human review required)

- **Rule 16 (proposed change): add a melt-up guard to the momentum-decay rotation.** Suppress the rotation when BOTH (a) the position's absolute drawdown is shallower than a floor (suggest **> -2.0% vs entry**) and (b) the benchmark's own 10-session return exceeds a threshold (suggest **> +3.0%**). Under that guard the position stays flagged and the chain keeps its state, but no sell fires — the rotation resumes the moment the name deepens past the floor or the benchmark cools.
- **Rationale:** Three consecutive rotations have now cut names that were barely below entry, purely because a fast-rising SPY made *everything* lag. On Aug 7 all six held names lagged SPY's +4.48% and only the two that happened to be fractionally red were eligible; XLF was sold after **two sessions** while measuring the **best RS50 in the entire eleven-sector complex (+9.23pp)**. The rule is measuring "not one of the handful of names carrying the index," not genuine momentum decay.
- **Evidence:** TRADE-LOG.md 2026-07-31 (XLU -2.66%), 2026-08-07 midday (BIIB -0.31% at -0.39% vs entry, 10-session +1.89% vs SPY +4.48%; XLF -1.03% at -1.01% vs entry, 10-session +2.29%, held 2 sessions, RS50 +9.23pp best-in-complex); Aug 7 EOD decay-flag block showing all six names lagging SPY; Aug 7 pre-market showing RS10 negative for 9 of 11 sectors on the same +4.48% bar.
- **Conviction: HIGH.** Bounded, two-condition, fail-safe (it only ever *withholds* a sell on a shallow loser), and now backed by three live exits and ~$64 of realized loss that bought nothing. This is the single highest-leverage change on the list.

- **Rule 5 (proposed change): add a re-deployment trigger after an involuntary exit — CARRYOVER W14, ELEVATED to HIGH.** When deployment falls below the 75% floor and remains there for 2+ consecutive sessions, permit a **core-ETF ballast re-add at a relaxed R:R threshold** (≥1.5:1 instead of ≥2:1), sized to restore the lower band. Satellites keep the full ≥2:1 requirement.
- **Rationale:** Proposed at MEDIUM-HIGH last week on ~0.9–1.0pp of measured cost; not applied; **the identical mechanism cost -1.78pp this week.** The book opened Monday at 64.1% deployed with $3.6K idle — the 6th consecutive session below the band — and met a +1.42% SPY session with a third of the account uninvested. Rule 5 still states a target band with no mechanism that acts when the book leaves it, and the book has now started three consecutive Mondays below it.
- **Evidence:** Daily alpha attribution table above (Mon -1.07pp at 64.1%→78.5%, Tue -0.71pp at 78.8%); TRADE-LOG.md 2026-08-03 market-open (deployment 64.11%, "6th consecutive session below the v3 75–85% band"); Aug 7 EOD (64.80%, "restoring deployment is Monday's market-open task"); W14 review's identical proposal.
- **Conviction: HIGH (raised from MEDIUM-HIGH).** Two consecutive weeks of quantified cost from the same unaddressed gap. Still recommend the bounded form — core only, ≥1.5:1 floor, ballast sizing only — rather than a blanket loosening.

- **Pre-market RS screen (proposed change): make the relative-strength test rank-based rather than absolute-vs-SPY.** Replace "RS10/RS50 must be positive vs SPY" with "candidate must sit in the **top quartile of its comparison complex**" (top ~3 of 11 sectors; top quartile of the satellite watchlist). Keep the trend/liquidity/macro gates unchanged.
- **Rationale:** Same root cause as the Rule 16 change above, on the entry side. A +4.48% ten-session SPY pushed RS10 negative for **9 of 11 sectors**, so the screen rejected the entire complex on Friday — including DELL at **+41.03pp RS50**, the phase's best single-stock reading, which failed only the RS10 arm at -4.50. An absolute-vs-benchmark test cannot distinguish "weak" from "not the index leader" during a narrow melt-up, and it produced **0 of 9 satellites and 0 of 6 unheld sectors passing, for a seventh consecutive session**, at the same time the book was 35% cash.
- **Evidence:** TRADE-LOG.md 2026-08-07 EOD ("SPY's own 10-session return was +4.48%, a bar that pushed RS10 negative for nine of eleven sectors"; "zero of nine satellite candidates passed"; DELL RS50 +41.03pp failing RS10 at -4.50); RESEARCH-LOG.md 2026-08-04 through 2026-08-07 (four consecutive HOLD decisions with every candidate rejected on the RS arm); eight consecutive sessions of buy-side inaction; 3 of 5 weekly trades expired unused for a third straight week.
- **Conviction: MEDIUM-HIGH.** Well-evidenced and it addresses the same structural flaw as the Rule 16 proposal from the opposite side — but it genuinely loosens an entry gate, so it should ship *with* the Rule 16 guard, not instead of it, and ideally as a bounded trial (core sectors first, satellites unchanged for one week).

- **Rule 14 (proposed change): count only genuine round trips in the STEP 5 mid-loop increment.** Midday's sell loop currently adds *every* sell it executes to the derived DTC. It should add a sell only when that symbol also has a **buy fill on the same date** — i.e. only when the sell actually completes a round trip.
- **Rationale:** On Aug 7 the audit line recorded `DTC: 2 (source=local)` after two rotations, when **the true day-trade count was 0** — neither name was bought that day, or on any day either was sold. Under the current convention **any two-sell midday exhausts the ≤1 buffer**, so a third exit — a Rule 7 hard-close arriving after two rotations — would be blocked on arithmetic rather than on risk. STEP 4's ordering puts hard-closes first, which contains the risk today, but the recorded number is also simply wrong and a future audit sweep could read it as a breach.
- **Evidence:** TRADE-LOG.md 2026-08-07 midday (`Rule 14 DTC: 2 (source=local)`, with the run's own note that "the true day-trade count for 2026-08-07 is ZERO"); Aug 7 EOD snapshot repeating the clarification; `activities` for Aug 3/4/5/6/7 showing zero same-day buy+sell pairs on any symbol.
- **Conviction: MEDIUM.** Real and worth fixing, but it *tightens* nothing and *loosens* a safety gate, so it ranks below the two alpha proposals. The conservative convention is fail-safe by design; the argument for changing it is accuracy of the audit record and avoiding a spurious block on a legitimate third exit. Prefer keeping the conservative number as a logged secondary (`DTC 0 true / 2 conservative`) over removing it outright.

- **Rule 14 audit-token fix (W14 proposal) — RESOLVED, retire.** Shipped and verified: the sweep found **10 of 10** expected tokens this week (market-open + midday on all five sessions, including three HOLD days and one NO-ACTION day) against 2 of 10 last week. No further action.

- **Market-open HOLD-path logging fix (carryover W11→W14) — RESOLVED, retire.** Shipped and verified: all three HOLD sessions this week (Aug 4, 6, 7) wrote their market-open TRADE-LOG rows. Rule 18 cadence was **20/20 routine slots** — the first fully clean operational week of the phase, after ten recurrences across four weeks. No further action.

## Week ending 2026-08-14

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $10,273.02 (prior review's ending `account.equity`; Aug 7 EOD snapshot basis $10,275.90) |
| Ending portfolio | $10,296.91 (`account.equity`; Aug 14 EOD snapshot portfolio $10,289.08) |
| Week return | **+$23.89 (+0.233%)** [snapshot→snapshot +$13.18 / +0.128%] |
| S&P 500 week | **+0.40%** (SPY $773.26 Aug 07 → $776.34 Aug 14, Alpaca bars) — the quietest SPY week of the phase |
| Bot vs S&P | **-0.27pp (MISS)** |
| Alpha vs SPX (v3) | **-0.27pp (headline, from `metrics.py rollup`)** — 3rd consecutive miss, but **the smallest of the phase since W12** and roughly one-seventh of last week's. Series: W10 -2.38 / W11 -1.49 / W12 -0.52 / W13 +0.85 / W14 -3.21 / W15 -2.00 → **W16 -0.27**. Rolling W6→W16 cum alpha -0.86pp → **-1.13pp**. **Decomposition (rollup): cash drag -0.05pp / selection alpha -0.23pp** — for the first time in the phase the miss is overwhelmingly *selection*, not idle cash. *Provenance: `prior_close` $773.26 (Aug 07) is the cached anchor recorded in last week's entry, not re-queried; only `last_close` $776.34 (Aug 14) comes from this week's `bars SPY 1Day 10` pull. No prior week's benchmark figure has been revised (v3.3).* |
| Core/Satellite P&L (v3) | core **+$15.43** / satellite **-$2.16** — week-contribution basis (mark-to-market change over the week). Core: XLRE +$12.88, XLV +$10.14, XLI +$8.81 (8 sh from Aug 7 close + 3 sh from the Aug 11 add), XLB **-$16.40**. Satellite: FERG -$2.16 (1.5 sessions held). Sum +$13.27 vs the +$13.18 snapshot equity change — **$0.09 residual, the tightest reconciliation of the phase** (two CAT fees) |
| Trades | 2 BUYs (XLI ballast add Aug 11, FERG Aug 13) — 2/5 weekly budget used, 3 expired unused; **0 exits** → **W:0 / L:0 / open:5** |
| Win rate | **n/a — zero closed trades** (first such week of the phase) |
| Best trade | **n/a — no closed trades.** Best *open* mark: XLB +4.73% (+$94.80) |
| Worst trade | **n/a — no closed trades.** Worst *open* mark: FERG -0.15% (-$2.16) |
| Profit factor | **n/a — no realized gains or losses this week** |
| daytrade_count | **0 (source=local, derived — field absent) [conservative: 0]** (delta vs prior week: **0 -> 0**) — **16 consecutive weeks / 81 trading days, zero day trades** |
| Rule 14 audit-token sweep | **10 / 10 expected tokens found** (2 × 5 sessions) — market-open ✓ + midday ✓ on every one of Aug 10, 11, 12, 13, 14. **Zero audit gaps, second consecutive clean sweep** (W15: 10/10, W14: 2/10) |
| Capital deployment | **84.59%** EOD ($8,703.23 / $10,289.08) — **inside the v3 75–85% band, 3rd consecutive session.** Path: Mon **64.79%** → Tue **70.21%** → Wed **70.23%** → Thu **84.59%** → Fri **84.59%**. `sessions_in_band` 2 of 5 |
| Phase P&L | **+$296.91 (+2.969%)** equity / +$289.08 (+2.891%) snapshot — **new phase closing high** |
| Trading sessions | 5 (Mon Aug 10 – Fri Aug 14) |

**Daily alpha attribution (where the -0.27pp came from):**

| Day | SPY | Book | Deployment | Δ |
|-----|-----|------|-----------|---|
| Mon Aug 10 | -0.03% | -0.04% | 64.79% | -0.01pp |
| Tue Aug 11 | -0.32% | -0.06% | 70.21% | **+0.26pp** |
| Wed Aug 12 | +0.25% | +0.04% | 70.23% | -0.21pp |
| Thu Aug 13 | +0.70% | +0.18% | 84.59% | **-0.52pp** |
| Fri Aug 14 | -0.20% | +0.01% | 84.59% | **+0.21pp** |

**Thursday alone (-0.52pp) is larger than the whole week's -0.27pp; the other four sessions net +0.25pp.** And the shape has inverted from W15: the two down-SPY days were both *positive* alpha (+0.26pp, +0.21pp) and the up-SPY days were negative. That is a low-beta book behaving exactly as a low-beta book should — it is a beta signature, not a defect, and it is the first week where the drag came from *what was owned* (-0.23pp selection) rather than *how much cash sat idle* (-0.05pp).

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |
| ------ | ----- | ---- | --- | ----- |
| — | — | — | — | **None. Zero exits of any kind this week** — no Rule 7 hard-close, no Rule 8 scale-out, no Rule 16 rotation, no Rule 10 sector-kill, no stop fired. The first fully sell-free week of the phase, and the direct product of a book in which every name spent almost the whole week above entry. |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop | Tier |
| ------ | ----- | ----- | ---------- | ---- | ---- |
| XLB | $50.08 (2026-05-18) | $52.45 | +$94.80 (+4.73%) | $50.806 (**5% trail**, GTC b6cec1cf, hwm $53.48) | core |
| XLI | $182.4618 blended (2026-05-13 / 08-03 / **08-11 add**) | $186.31 | +$42.33 (+2.11%) | $169.3665 (10%, GTC 69d2c5bc, 8 sh, hwm $188.185) + $168.651 (10%, GTC 8658afd4, 3 sh, hwm $187.39) | core |
| XLRE | $44.79 (2026-07-13) | $45.26 | +$21.62 (+1.05%) | $41.8095 (10% trail, GTC 16d5a6b2, hwm $46.455) | core |
| XLV | $161.92 (2026-07-31) | $167.37 | +$32.70 (+3.37%) | $157.7144 (**7% trail**, GTC 20f0bdbd, hwm $169.5854) | core |
| FERG | $245.30 (2026-08-13) | $244.94 | -$2.16 (-0.15%) | $225.1935 (10% trail, GTC cd5cdaa6, hwm $250.215) | **satellite** |

daytrade_count: **0 (source=local — derived, field absent from the paper `/account` payload) [conservative: 0]**. Positions **5/6**, one slot free (unfillable all week for want of headroom). **ETF core $7,233.59 = 83.11% of deployed** ≥45% floor ✓. **Satellite sleeve 1/3 — occupied for the first time since Aug 7**, and the first satellite entry since BIIB. Sector spread of deployed: **Industrials 40.43%** (XLI $2,049.41 + FERG $1,469.64) / Materials 24.11% / Real Estate 23.92% / Health Care 11.54% — all ≤50% ✓; ≤2 satellites/sector ✓ (1). Position weights vs equity: XLB **20.38%** and XLRE **20.25%** sit above the Rule 3 20% cap **on appreciation, not on entry** — not a breach, but neither may be added to while there; XLI 19.92% (at the cap), XLV 9.76%, FERG 14.29%. **All 5 names carry armed GTC trailing stops across 6 orders** (verified in `orders open`); Rule 17 clean, zero unprotected names, zero `STOP-PLACEMENT-FAILED` headers, no orphan orders.

### Go-live scorecard (v3.4)

```
Go-live scorecard — TRIAL WINDOW 2026-08-06..2026-08-14 (7 sessions). Verdict: FAIL.
Weekly scorecard (2026-08-10..2026-08-14, informational only): FAIL.
```

**`--since "$TRIAL_START"` (2026-08-06) — the go/no-go verdict:**

| Criterion | Result | Detail |
|---|---|---|
| `cadence` | **PASS** | 28/28 routine slots |
| `rule14_tokens` | **PASS** | 14/14 Rule 14 audit tokens |
| `rule14_accuracy` | **FAIL** | inaccurate on `['2026-08-07']` |
| `unprotected` | **PASS** | zero unprotected positions |
| `breaches` | **PASS** | zero money-moving rule breaches |
| `rule16_meltup` | **FAIL** | 2 shallow melt-up rotations |
| `deployment` | **FAIL** | 2026-08-11: 3 consecutive sessions below the 75.0% floor |

`alpha_informational` (**NOT a gate**): cum_alpha **-0.82pp** / cash_drag **-0.24pp** / selection **-0.58pp** over 7 sessions.

**Weekly window (2026-08-10..2026-08-14), informational progress read:** `cadence` 20/20 PASS · `rule14_tokens` 10/10 PASS · `rule14_accuracy` PASS · `unprotected` PASS · `breaches` PASS · `rule16_meltup` **PASS (0 shallow rotations)** · `deployment` **FAIL (2026-08-12: 3 consecutive sessions below the floor)**. `alpha_informational`: -0.27pp / drag -0.05pp / selection -0.23pp.

**The two verdicts disagree on two criteria, and the divergence is entirely explained — this is the `trial_start` defect, not a trading finding.** `rule14_accuracy` and `rule16_meltup` FAIL in the trial window on **one date only, 2026-08-07**, and pass on every session from Aug 10 onward. `memory/PROJECT-CONTEXT.md` says this in advance, in terms: `trial_start: UNSET`, and while it reads UNSET "the scorecard falls back to the earliest record in `memory/METRICS.jsonl`, which is the deliberately defective 2026-08-06/07 seed pair… Those two sessions predate the Rule 16 guard and the Rule 14 round-trip fix and will FAIL `rule16_meltup` and `rule14_accuracy` forever, so an unset value guarantees a no-go verdict for the life of the trial." That is precisely what happened. **The verdict stands as computed** — the criteria are not being edited to fit the result, and the fix is to set the line, which is a human action (proposed below), not to relax the bar.

`deployment` FAILs in **both** windows, and that one is real. It is also the textbook straddle the two-window rule exists to catch: the below-floor run is **Aug 7 → Aug 10 → Aug 11 → Aug 12, four consecutive sessions**, which the weekly window sees as 3 (Aug 10–12) and the trial window sees as 3 ending Aug 11. Either way it breaks the ≤2 rule.

**`deployment` FAIL diagnostics — `rule5_triggers` vs `rule5_acted`, side by side:**

| Window | `rule5_triggers` | `rule5_acted` |
|---|---|---|
| Week (Aug 10–14) | **3** (Aug 11, 12, 13) | **1** (Aug 11) |
| Trial (Aug 06–14) | **3** | **1** |

**This is a third failure mode, and neither of the two the routine anticipates.** It is not `triggers > 0, acted == 0` (the melt-up RS hole — screens admit nothing), and it is not `acted == 0, triggers == 0` (Rule 5 never armed). The trigger **armed on three sessions and acted on one**: Aug 11's XLI ballast add went in at the relaxed 1.5:1 core floor exactly as designed — and still could not restore the band, because Rule 3's 20% position cap clamped the clip to roughly 54% of the required restore. On Aug 12 and Aug 13 the trigger armed again and `acted` was false for a different reason: the `restore_dollars` budget (~$485) was **smaller than the minimum legal clip** (~$514), so every candidate returned `clamped=floor_skip`. **Rule 5's restore mechanism is working and is simply too small to reach the floor from below.** Deployment was ultimately restored on Aug 13 by the FERG *satellite* entry — a discretionary trade at the full 2:1 floor — not by the ballast mechanism at all.

### What Worked
- **The v3.4 melt-up guard fired live, three times, and was vindicated at zero cost — the single most important result of the week.** XLRE armed a decay chain on Aug 10 at -1.09%, confirmed it Aug 11 at **-1.18%**, and the pre-guard rule would have sold it. The guard withheld (drawdown shallower than the -2.0% floor, SPY 10-session +4.04% above the +3.0% threshold), preserved the chain, suppressed again Aug 12 at -0.79%, and on **Aug 13 the chain broke at flag=0 with XLRE back above entry at +0.46%** — `since_suppressed: +1.25%`, **+1.65pp cumulative** from the point the sell was withheld — while SPY's 10-session return *cooled* 5.98% → 4.79%. That is the exact "fast benchmark cools, shallow loser recovers" shape the guard was written for, on its first live test. XLRE closed the week **+1.05% and contributed +$12.88, the book's best week-contribution**. `rule16_shallow_rotations` = **0**. The W15 review called this "the single highest-leverage change on the list"; it shipped and it paid on week one.
- **The Rule 5 re-deployment trigger shipped and armed correctly** — three armed sessions, one acted (Aug 11 XLI, sized as ballast at the relaxed 1.5:1 core floor with the reasoning recorded on the BUY row). It did not finish the job (see below), but the mechanism the last two reviews asked for exists, ran, and is now producing *diagnosable* failures instead of silent drift.
- **The Rule 14 round-trip convention shipped, and `rule14_accuracy` is now clean on every session since.** The W15 proposal to count only genuine round trips is in force; the only inaccurate row in the entire metrics file is 2026-08-07, which predates it.
- **The satellite sleeve reopened after five weeks empty.** FERG passed on the **primary `rs10_positive` arm** (RS10 +2.49pp, RS50 +7.17pp), not the constructive-pullback exception door, at only +4.45% extension — the least-extended passing candidate by 2.5×, on a genuine earnings catalyst with the next print ~December. The honest caveat was recorded rather than buried: **the 50-DMA still sits below the 200-DMA**, so this is a base recovery, not a clean stage-2 uptrend, and the entry was taken deliberately with that known.
- **A third consecutive flawless operational week, and the best single one yet.** Rule 18 cadence **20/20**; Rule 14 tokens **10/10**; zero unprotected positions on all five EODs; zero money-moving breaches; zero Rule 14 aborts; **81 trading days / 16 weeks at zero day trades**; Rule 15 correctly held XLI read-only on Aug 11 and FERG on Aug 13; Rule 13 armed both new stops at the 15:00 CT bell so neither could fire same-day. The reconciliation between attribution and equity came in at **$0.09**.
- **Rule 9 refused three tightenings in the protective direction rather than loosening a live trail.** XLB and XLV both returned `target_trail_pct: 7` against live 5% and 7% trails on Aug 13 and again Aug 14; "not strictly less" was correctly read as *no-tighten*, not as an instruction to widen. The rule held on the side that costs nothing to hold.

### What Didn't Work
- **`deployment` failed the go-live criterion, and it failed with the fix already installed.** Three sessions below the 75% floor this week — four consecutive across the Friday boundary. The trigger armed three times and acted once, and the one action could not reach the band because **Rule 3's 20% cap clamped the clip to ~54% of the restore**. Then on Aug 12–13 the restore budget itself (~$485) fell **below the minimum legal clip (~$514)**, so the mechanism was armed and structurally unable to fire. **The band was ultimately restored by a discretionary satellite entry, not by the ballast mechanism** — Rule 5 has never once completed a restore.
- **The same minimum-clip clamp then bound at the *opposite* end of the band on Friday.** Headroom to the 85% ceiling was **$41.51** against a $514.78 minimum clip, leaving every candidate **$473.27 short of its own smallest legal size** — ANET, CRDO, CRWD and an XLI core add would each have returned `clamped=floor_skip`. Friday was the first HOLD of the phase whose binding constraint was **capital rather than conviction**, on a session where the macro window was genuinely CLEAR. **One clamp, both ends of the band, in the same week.** Three of five weekly trade slots expired unused for a fourth straight week — but for the first time not because no idea qualified.
- **Rule 16 branch 1 (the ETF sector-quadrant exit) has now been evaluated on ten consecutive middays and never once exercised, and it still has no operational definition.** This is no longer academic: branch 1 is the **only path that overrides the melt-up guard**, so every suppression this week depended on a discretionary reading of an undefined test. It nearly bit twice — XLRE's RS50 at -0.68pp on Aug 11, then XLB's RS50 flipping negative (-0.65pp Aug 13 → -1.06pp Aug 14) for the first time. Both were resolved *against* an exit on defensible reasoning (`rscreen` is a buy-side entry screen; reading its `pass: 0` as an exit would invent a rule the strategy does not contain, and would today also demand selling XLI at +4.30pp RS50 and XLV at +10.77pp), and Friday's tape vindicated it — XLB's RS10 flipped **positive** to +0.26pp with a +4.12% 10-session return that **beat SPY**. But a rule that survives on judgement is a rule that will eventually be judged differently.
- **Thursday gave back twice the week's entire alpha in one session.** SPY +0.70% against a book at +0.18% — **-0.52pp**, on a day the book was fully deployed at 84.59%. That is pure selection: cash drag was only -0.11pp of it. The low-beta core did what low-beta cores do into a strong tape.
- **XLB was the week's only losing core name (-$16.40) and cost itself a ladder rung for a fifth consecutive session.** Tuesday's `replace-stop` **reset its trailing high-water mark $53.595 → $53.085**, and the tape has still not re-ratcheted past the old peak — so a hwm-gain that had already cleared the +7% rung reads below it. Harmless in this instance because Rule 9 blocks in the protective direction, but the defect is now five sessions old and unaddressed: on a position well above its current print, a *tighten* would **lower** the effective stop despite a smaller trail percentage, and Rule 9's check on `stop_price` would not necessarily catch it.
- **Zero closed trades means the exit rules produced no evidence at all this week.** Win rate, best/worst and profit factor are all `n/a`. That is a benign consequence of a book that stayed green — but it means the only exit-side evidence the week generated is a *withheld* sell.

### Key Lessons
- **A fix that lands can still fail its criterion, and that is the most useful result a trial produces.** Rule 5's re-deployment trigger was the most-repeated proposal in this log — carried W14, elevated W15, shipped for W16 — and `deployment` failed anyway. It failed *informatively*: `triggers 3 / acted 1` shows the mechanism armed and executed, and the residual is a **sizing interaction** (Rule 3's cap on the way up, the minimum-clip floor on the way down) that no amount of R:R relaxation can reach. Two weeks ago the diagnosis was "nothing acts when the book leaves the band." Now it is "the actor cannot take a step small enough or large enough to matter." That is a different, narrower, and far more fixable problem.
- **The melt-up guard's value is measurable precisely because it does nothing visible.** It produced no trade, no P&L row, and no entry in the closed-trades table — and it is the week's best outcome: **+1.65pp on a position the prior rulebook would have sold**, plus the counterfactual loss avoided. Suppression rows are the record; without `DECAY-SUPPRESSED` and `since_suppressed` in the log this result would be invisible and the guard unevaluable. **Instrument the withheld action, not just the taken one.**
- **A single position-sizing floor can lock the book at both ends of a band simultaneously.** The same ~$514 minimum clip blocked Rule 5's restore *from below* on Aug 12–13 and every discretionary entry *from above* on Aug 14. The gates were each individually correct; the clamp is the shared term. This is structurally the same class of finding as W15's "exit gate and entry gate share a denominator" — **when two opposing controls are governed by one parameter, the book gets stuck, not balanced.**
- **The go/no-go window is only as honest as the date that defines it.** `trial_start: UNSET` makes the scorecard permanently unpassable by including two sessions that predate the fixes being tested — and PROJECT-CONTEXT.md predicted exactly this in writing before the data existed. The criteria did their job; the window did not. **Setting one line is worth more than a week of trading to the go-live decision.**
- **Execution discipline remains solved, for a 16th week.** 81 sessions, zero day trades, zero unprotected positions, zero money-moving breaches, three consecutive weeks of perfect cadence and audit tokens. Every point of drag this week was selection, sizing, or a missing definition — none of it was execution.

**Satellite-sleeve check (v3 spec):** W14 sat -1.87% per-capital / core ≈-2.8% → **sat OVER**; W15 sat +1.59% on ~$1,421 / core ≈+2.25% on ~$5,900 → **sat UNDER**; **W16 sat -$2.16 on $1,471.80 for 1.5 sessions (-0.15%) / core +$15.43 on ~$7,000 average capital (≈+0.22%) → sat UNDER.** That is **2 consecutive weeks of sat underperformance — the 3+ week shrink-sat trigger is NOT met.** And as in every prior week the signal points the opposite way: the sleeve is **under-utilised at 1/3**, newly reoccupied after five weeks empty, and 1.5 sessions is not a measurement. **No shrink-sat proposal.**

### Adjustments for Next Week
- **Monday Aug 17 opens with the band already restored (84.59%) and one free position slot that is unfillable without a trim** — headroom to the ceiling is ~$42 against a ~$515 minimum clip. The slot becomes usable only via a drawdown, a Rule 8 scale-out, or equity growth. **Do not force it.**
- **Rule 8 watch: XLB is the nearest capital-freeing catalyst and has been for three sessions**, blocked only by the hwm reset. hwm $53.48 vs the pre-reset peak $53.595; a new high re-ratchets and re-arms the +7% rung, which frees ~$700 and would simultaneously resolve the Rule 3 20.38% drift and the headroom squeeze. XLV sits at hwm-gain +4.73% against a live 7% trail (equal, not less → no-tighten). XLI and XLRE below the first rung.
- **FERG is the week's live variable.** Entered Aug 13, gave back its entire day-one +1.20% on Friday (-1.28%), and is the book's only red name at -0.15%. It reaches T+2 Monday, so it is fully actionable — Rule 7 at -7%, Rule 16 flag-eligible the moment it is below entry *and* lagging. Its 10-session return **beat SPY on Friday (+5.12% vs +3.87%)**, so the decay leg is not close yet.
- **Macro:** empty Mon/Tue; **FOMC minutes at T+2 from Monday.** Under the v3.2 macro-proximity gate the satellite window is open early in the week and closes toward the minutes.
- **Watch Industrials concentration.** XLI + FERG = **40.43% of deployed**, the highest single-sector reading of the phase, against a 50% cap. Any further Industrials idea is close to blocked, and the ≤2-satellites-per-sector rule is already at 1.
- **No auto-applied strategy mutations** (DECIDED G). See proposed changes below.

### Overall Grade: B+

**The best-executed week of the phase, and the first in three where the strategy visibly earned something.** The alpha miss shrank from **-2.00pp to -0.27pp** — the smallest since W12 — on the quietest SPY week of the phase, and the decomposition finally separates the causes: **-0.05pp cash drag, -0.23pp selection**, with Thursday alone accounting for -0.52pp and the other four sessions netting +0.25pp. Both v3.4 fixes shipped and both worked: **the melt-up guard withheld a sell on XLRE at -1.18% and the position recovered +1.65pp to close the week green** with `shallow_rotations` at **0**, and the Rule 14 round-trip convention has produced a clean `rule14_accuracy` on every session since it landed. Process was immaculate for a third straight week — **20/20 cadence, 10/10 audit tokens, zero unprotected positions, zero breaches, 81 sessions at zero day trades** — and the attribution reconciled to **$0.09**. What holds it below an A is that **`deployment` still FAILs**, now with the fix installed: Rule 5 armed three times, acted once, and could not reach the band because Rule 3's cap clamped the clip from above and the minimum clip exceeded the restore budget from below — the band was finally restored by a discretionary satellite entry, not by the mechanism. **The same clamp then blocked every entry at the top of the band on Friday.** And the go-live verdict is **FAIL** on a technicality that is nobody's trading decision: `trial_start` is still `UNSET`, so the window drags in the deliberately defective Aug 6–7 seed pair, which fails `rule14_accuracy` and `rule16_meltup` by construction and will do so forever. Every criterion the *fixes* were meant to address passed on every session from Aug 10 on.

## Proposed strategy changes (NOT auto-applied — human review required)

- **`memory/PROJECT-CONTEXT.md` (proposed change): set `trial_start: 2026-08-10`.** Replace the literal `UNSET` on line 43 with the first trading day on which all five routine prompts were running v3.4 text.
- **Rationale:** While the line reads `UNSET` the go-live scorecard falls back to the earliest METRICS.jsonl row and permanently includes the 2026-08-06/07 seed pair, which predates both v3.4 fixes and fails `rule14_accuracy` and `rule16_meltup` by construction — guaranteeing a no-go verdict for the life of the trial regardless of how the bot trades.
- **Evidence:** This week's two scorecards, run side by side: trial window (2026-08-06..) FAILs `rule14_accuracy` on `['2026-08-07']` and `rule16_meltup` on 2 shallow rotations, both dated Aug 7; the weekly window (2026-08-10..) PASSes both. PROJECT-CONTEXT.md lines 41–52 state this outcome in advance, in writing, before the data existed.
- **Conviction: HIGH — and it is the single highest-leverage item on this list.** It is a one-line human edit, it changes no trading behaviour whatsoever, and without it the go/no-go decision cannot be made on evidence at all. **Verify before applying:** Aug 10 is the correct date only if the v3.4 re-paste was complete before Monday's pre-market; if any routine still ran v3.3 text that day, set it to the first session that did not.

- **Rule 3 / position-sizing floor (proposed change): let a Rule 5 ballast restore be sized to the *restore budget* rather than to the standard minimum clip.** When the Rule 5 re-deployment trigger is armed and `restore_dollars` is smaller than the 5%-of-equity minimum position, permit a `tier: core` **add to an existing holding** at exactly `restore_dollars`, bypassing the minimum-clip floor (which exists to prevent uneconomically small *new* positions, not to block a top-up of a position already held). Adds remain subject to the Rule 3 20% cap and the 85% ceiling.
- **Rationale:** Rule 5 shipped, armed on three sessions, and **completed zero restores.** Aug 11 acted and reached only ~54% of the band because Rule 3 clamped the clip; Aug 12 and Aug 13 armed and could not act at all because the ~$485 restore budget was smaller than the ~$514 minimum clip. The mechanism is structurally unable to close a gap smaller than one minimum position — which is precisely the gap it exists to close. The band was ultimately restored by an unrelated discretionary satellite entry.
- **Evidence:** `metrics.py rollup --since 2026-08-10` → `rule5_triggers: 3, rule5_acted: 1`; TRADE-LOG.md 2026-08-11 market-open (XLI add, "the max legal XLI clip bought ~54% of the restore before Rule 3 stopped it"); 2026-08-12 and 2026-08-13 armed-but-unable rows; Aug 14 EOD ("a $485 restore budget against a $514 minimum clip — unresolved and simply no longer visible; it will re-arm the next time the book drifts below 75%"). Go-live `deployment` criterion FAILed in both windows this week.
- **Conviction: HIGH.** Narrowly scoped (armed-trigger only, core only, existing holdings only, all other caps intact), it addresses a **measured** and now precisely-diagnosed failure, and it is the only remaining blocker on the one go-live criterion that failed for genuine trading reasons.

- **Rule 16 branch 1 (proposed change): give the ETF sector-quadrant exit an operational definition, or remove it.** Suggested test: rotate a core ETF when its **RS50 vs SPY is negative for 3 consecutive sessions AND its close is below a falling 50-DMA** — both legs absolute-ish and neither satisfiable by a single day's noise. If no such definition is agreed, delete the branch and let the decay chain plus the melt-up guard govern ETF exits alone.
- **Rationale:** Branch 1 has been evaluated on **ten consecutive middays and never exercised**, always on a written judgement call. It is the **only path that overrides the melt-up guard**, so every suppression this week rested on it. It nearly bit twice — XLRE RS50 -0.68pp on Aug 11, XLB RS50 flipping negative -0.65pp → -1.06pp on Aug 13–14 — and both times the resolution turned on the (correct) argument that `rscreen` is a buy-side entry screen whose `pass: 0` is not an exit signal. That argument is sound and is nowhere in the rulebook. An undefined override on a sell path is the same missing-detector shape that let the Rule 14 fail-open survive fourteen weeks.
- **Evidence:** TRADE-LOG.md middays 2026-08-11 ("seventh consecutive midday to decline it on the same undefined test"), 2026-08-12 ("eighth"), 2026-08-13 ("ninth… the first on which the discretion actually bit… if XLB's RS50 deepens, the next midday needs a rule, not a judgement call"), 2026-08-14 EOD ("tenth… remains operationally undefined (DECIDED-G) and is the top item for the weekly review"). Flagged as the week's #1 item by three separate sessions.
- **Conviction: HIGH on the need, MEDIUM on the specific thresholds.** The thresholds above are a starting point offered for review, not a measured optimum; the non-negotiable part is that the branch stops being adjudicated by prose.

- **`replace-stop` hwm handling (proposed change): carry the existing high-water mark forward through a trail-percentage change instead of resetting it to the current price.** If the broker cannot preserve hwm on replacement, record the pre-replacement hwm in the STOP UPDATE row and have Rule 8 read hwm-gain from the logged peak rather than the live order field.
- **Rationale:** Tuesday's XLB tighten (7% → 5%) reset the trailing hwm **$53.595 → $53.085**, and five sessions later the tape has still not re-ratcheted past the old peak — so a hwm-gain that had genuinely cleared the +7% rung reads below it, and XLB has been denied the same ladder rung for five consecutive sessions. **The forward-looking risk is larger than the cost so far:** on a position trading well below a much higher prior peak, a tighten would *lower* the effective stop level despite a smaller trail percentage, and Rule 9's "never move a stop down" check reads `stop_price` at replacement time, which would not necessarily catch it.
- **Evidence:** TRADE-LOG.md 2026-08-11 STOP UPDATE rows (XLB hwm $53.595 → $53.085; XLV hwm $169.66 → $167.86, both flagged in the midday run's Rule 9 note); 2026-08-13 midday ("still costing XLB the same rung for a third session"); 2026-08-14 EOD ("standing defect, fifth session"). XLB was the only core name to lose money this week (-$16.40) while sitting on an un-armed scale-out.
- **Conviction: MEDIUM-HIGH.** The realized cost is one deferred rung, but the mechanism is a latent Rule 9 bypass on a protective order, and it has now recurred every session since it was introduced.

- **Operational (proposed change): set `TRADING_MODE=paper` explicitly in the routine UI.** Thirteen consecutive sessions — three full weeks — have now run on the unset default. The default is correct and every routine's mode guard verified it against the endpoint on every session, but the guard's entire purpose is to catch a half-done live switch, and it cannot compare a mode that was never set against an endpoint that was. **This is free, changes nothing, and is a prerequisite before any live switch is contemplated.** Carried for a third week.

- **Rule 16 melt-up guard (W15 proposal) — SHIPPED and VINDICATED, retire.** Live on Aug 11–12 (XLRE, two suppressions), resolved Aug 13 by recovery: the withheld sell at -1.18% became a +0.46% position, **+1.65pp**, while SPY's 10-session return cooled 5.98% → 4.79%. `rule16_shallow_rotations` = 0 for the week; the criterion PASSes in the weekly window and FAILs the trial window only on the pre-guard Aug 7 seed row. No further action.

- **Rule 14 round-trip convention (W15 proposal) — SHIPPED, retire.** `rule14_accuracy` is true on every session from Aug 10 onward; the only inaccurate row in the metrics file is 2026-08-07, which predates the change. The `[conservative: M]` secondary is being logged as recommended. No further action.

- **Rule 5 re-deployment trigger (W14→W15 proposal) — SHIPPED but INCOMPLETE, superseded.** The trigger exists, armed 3× and acted 1× this week. It did not restore the band and `deployment` still FAILs. **Superseded by the Rule 3 / sizing-floor proposal above** — the residual is a sizing interaction, not an R:R threshold, so no further loosening of the R:R floor is proposed.

- **Pre-market RS screen → rank-based (W15 proposal) — DOWNGRADED to LOW, keep open.** The v3.3 `constructive_pullback` exception (not the proposed quartile form) remains what shipped, and this week it was **not the binding constraint**: FERG passed on the primary `rs10_positive` arm as the melt-up cooled, and Friday's HOLD bound on **capital, not merit** — three candidates screened and passed, none could be sized. The evidence that motivated the change has weakened considerably. Re-evaluate only if a fast tape recurs; do not ship it into the current squeeze, where loosening entries would produce ideas the book cannot fund.

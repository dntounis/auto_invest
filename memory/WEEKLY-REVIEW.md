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

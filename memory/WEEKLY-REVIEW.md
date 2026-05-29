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

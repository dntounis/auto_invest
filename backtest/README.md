# Backtest — v3.4 routine chain replay (v3.5 work)

Deterministic replay of pre-market → market-open → intraday GTC stops → midday →
daily-summary on Alpaca historical bars. All sizing / ladder / decay / rscreen /
redeploy math calls production `scripts/sizing.py`. Data via the read-only
`alpaca.sh bars-range` (never raw curl).

```bash
python3 backtest/fetch.py --daily-start 2021-01-04   # cache bars (gitignored)
python3 backtest/attempt2.py                         # dev selection, 2022-01 → 2026-09-02
python3 backtest/evaluate.py U results-attempt2.json # pre-registered test, 2026-09-03 → 11-03
python3 backtest/posthoc.py                          # post-hoc: every candidate on test
```

## Fidelity
v3.4 replay seeded with the real 2026-09-02 book: **−1.27%**, book flat by Sep 22.
Real account over the same window: **−2.08%**, flat by Oct 9. Same shape
(liquidate, then deadlock at 100% cash); the gap is mostly the LLM's looser reading of
"sector left the leading quadrant" than the simulator's proxy.

## Result: goal NOT met — no rule set beat v3.4 on the last two months

Protocol: `PREREGISTRATION.md` (attempt 1) and `PREREGISTRATION-2.md` (attempt 2),
each committed and pushed before its test run.

| Attempt | Selected on dev | Test A (seeded) v3.5 / v3.4 | Test B (cold) | E jitter wins | Verdict |
|---|---|---|---|---|---|
| 1 | `um` (Jan–Sep 2026 dev: +18.9% vs 0.0%) | −2.85% / −1.27% | −8.03% / 0.00% | 0/10 | FAIL |
| 2 | `U` (2022–Sep 2026 dev: +62.0% vs +2.3%) | −2.04% / −1.27% | −2.27% / 0.00% | 0/10 | FAIL |

Post-hoc, all 12 attempt-2 candidates lose to v3.4 in test scenario A
(`posthoc-attempt2.json`). Searching further on these 43 sessions would be fitting the test.

## Why
- **The test window rewards cash.** SPY −1.17% with broad chop; v3.4 sat 100% cash
  from Sep 22 (real: Oct 9). Any variant that deploys 60–70% loses against that.
- **The same cash cost v3.4 ~60pp over 4.7 years.** 2022-01-03 → 2026-09-02: v3.4 +2.3%
  (4% avg deployed), `U` +62.0% (Sharpe 0.90 vs 0.13, beats v3.4 in 7/10 half-year folds),
  SPY +71.2%.
- **The deadlock is real and fully explained:** with an empty book the ≥45% core floor
  refuses every satellite, the 50% sector cap refuses every sector ETF, and the
  200-bar-high R:R scores every trend leader ≈0. `U` = W25–W27 proposals 1a + 2 + 3.
- **Churn controls (Rule 16 min-hold, quadrant confirmation) hurt over 4.7 years** even
  though attempt 1's failure pointed at churn — a diagnosis drawn from one window did
  not generalise.

## Recommendation (human decision, DECIDED G — not auto-applied)
Adopting proposals 1a + 2 + 3 (`U`) is strongly supported long-run, but it would have
lost money over the last two months, and it raises drawdown (−16.9% vs −5.6% on dev).
It is a regime bet: deploy into trends and accept losing to cash in a falling chop.
The rulebook is unchanged pending that decision.

## Limitations
LLM catalyst judgement / Perplexity research not simulated (screen stands in);
pre-2026 intraday path synthesized from daily bars; pre-2026 macro calendar approximate;
category-defined universe of 123 symbols (`universe.py`). All apply equally to every variant.

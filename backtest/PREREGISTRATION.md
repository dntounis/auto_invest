# Backtest pre-registration — v3.4 → v3.5

Committed **before** any candidate rule set was run on the test window, so the
test result cannot have shaped the rules. (The only test-window run that preceded
this file is the v3.4 *baseline*, used to validate simulator fidelity against the
real equity line.)

## Windows
- **Dev (design + selection):** 2026-01-05 → 2026-09-02, cold start, $10,000.
  Every rule choice is made here. Sub-windows reported: Jan–Mar, Apr–May, Jun–Sep 2.
- **Test ("last two months", out-of-sample):** 2026-09-03 → 2026-11-03 (43 sessions).
  Evaluated **once** per scenario with the frozen v3.5 config.

## Test scenarios
- **A (primary):** seeded with the real book at the 2026-09-02 close
  (TRADE-LOG `## Sep 02 — EOD Snapshot`), 5 bps slippage per side.
- **B:** cold start (flat $10,000) on 2026-09-03.
- **C:** continuous run from 2026-01-05, scored on the test window only.
- **D:** scenario A with slippage tripled (15 bps per side).
- **E:** cold starts on each of the first 10 test sessions (start-date jitter), each scored to 2026-11-03.

## Metric and success criteria
Performance = account total return (P&L) over the test window.

1. **Primary (the goal's 10% bar):** in scenario A, `P&L(v3.5) − P&L(v3.4) ≥ 10% × |P&L(v3.4)|`,
   and `P&L(v3.5) > P&L(v3.4)`.
2. **Robustness:** v3.5 beats v3.4 on total return in **every** scenario B, C, D and in
   **≥ 80%** of the E start dates.
3. **Not just leverage to a falling tape:** v3.5 Sharpe > v3.4 Sharpe in A, and
   v3.5 alpha vs SPY > 0 in A.

All three must hold. Absolute numbers (return, alpha, Sharpe, max drawdown,
deployment, trade count, win rate) are reported for every scenario regardless of outcome.

## Fixed inputs
- Universe: `backtest/universe.py` (category-defined, frozen before any results).
- Macro calendar: dates transcribed from `memory/RESEARCH-LOG.md`.
- All sizing / ladder / decay / rscreen / redeploy math: production `scripts/sizing.py`.
- Simulator: `backtest/sim.py`; modelling choices (fill at open + slippage, stops on
  30-min RTH bars, midday at 13:00 ET bar close) apply identically to every variant.

## Known limitations (apply to every variant equally)
- The LLM's catalyst judgement and Perplexity research are not simulated; the
  deterministic screen stands in for idea generation.
- Two months is a short window; results are evidence, not proof of future edge.

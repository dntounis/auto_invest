# Backtest pre-registration — attempt 2

## Attempt 1 outcome (recorded, not revised)
Frozen candidate `um` (W27 proposals 1a + 2 + 3 + risk-adjusted momentum ranking),
selected on the 2026-01-05 → 2026-09-02 dev window, **FAILED every pre-registered
criterion** on the test window (`results-attempt1.json`):
A seeded −2.85% vs v3.4 −1.27%; B cold −8.03% vs 0.00%; E jitter 0/10.
Failure analysis: most test-window sells were Rule 16 rotations / quadrant exits
2–5 sessions after entry, almost all losers (churn); and the 8-month dev window
was a single trending regime that rewarded fast rotation.

## Disclosure
The test window (2026-09-03 → 2026-11-03) has now been **viewed once**. Attempt-2
candidates include churn controls (H, Q below) whose motivation draws partly on
the attempt-1 failure analysis, and partly on prior dev evidence (quadrant exits
were the largest dev P&L leak; `hold10` raised the dev win rate). Selection below
uses **dev data only**; the test window is evaluated once, after selection.

## Dev window (selection)
2022-01-03 → 2026-09-02, continuous cold-start run, $10,000 (daily-bar intraday
fallback before 2026-01; approximate Tier-1 calendar before 2026 — identical for
every variant). Folds: calendar half-years H1-2022 … H1-2026, plus 2026-07-01 →
2026-09-02 (10 folds); fold metric = return of the continuous run within the fold.

## Candidates (fixed now)
Knobs: U = proposals 1a+2+3 · M = risk-adjusted momentum ranking ·
H = Rule 16 only after 10 sessions held · Q = quadrant exit needs close < 50-DMA on
2 consecutive middays · C = 10-session re-entry cooldown after a losing exit ·
N = ≤2 new buys per run · R50 / R200 = no new buys while SPY < its 50 / 200-DMA.

1 v3.4 · 2 v3.4+HQ · 3 U · 4 U+HQ · 5 U+HQ+R200 · 6 UM · 7 UM+HQ · 8 UM+HQ+R200 ·
9 UM+HQ+R50 · 10 UM+HQ+C+N · 11 U+HQ+C+N+R200 · 12 UM+HQ+C+N+R200

## Selection rule
Eligible = beats v3.4's fold return in ≥ 7 of 10 folds. Choose the eligible
candidate with the highest full-dev Sharpe; ties → fewer knobs. If none is
eligible, choose the highest full-dev Sharpe among candidates that beat v3.4 on
full-dev return.

## Test
Identical scenarios A–E and criteria 1–3 as `PREREGISTRATION.md`, run once on the
selected candidate.

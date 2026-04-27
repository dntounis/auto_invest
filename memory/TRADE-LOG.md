# Trade Log

Trades and end-of-day snapshots are appended here.

In v1, only EOD snapshots are written (by the `daily-summary` routine). Trade rows are added in v2 by `market-open` and `midday`.

## Entry Schemas

### Trade row (v2)
```
### YYYY-MM-DD — TRADE: TICKER side=buy|sell qty=N
- Entry: $X (or Exit: $X)
- Stop level: $X (trailing N% / fixed $X)
- Thesis: ...
- Catalyst: ... (link to RESEARCH-LOG entry)
- Target: $X (R:R X:1)
- Realized P&L (on exits only): $X
```

### EOD snapshot (v1)
```
### MMM DD — EOD Snapshot (Day N, Weekday)
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** ±$X (±X%) | **Phase P&L:** ±$X (±X%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |

**Notes:** one-paragraph plain-english summary.
```

---

## Day 0 — EOD Snapshot (pre-launch baseline)
**Portfolio:** $10,000.00 | **Cash:** $10,000.00 (100%) | **Day P&L:** $0.00 (0.00%) | **Phase P&L:** $0.00 (0.00%)

No positions yet. v1 launches on the next weekday's `pre-market` routine. The `daily-summary` routine will reconcile this baseline against the actual paper-account equity on Day 1.

<!-- New EOD snapshots appended below -->

## Apr 27 — EOD Snapshot (Day 1, Monday)
**Portfolio:** $10,000.00 | **Cash:** $10,000.00 (100%) | **Day P&L:** $0.00 (0.00%) | **Phase P&L:** $0.00 (0.00%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |
| ------ | ------ | ----- | ----- | ------- | -------------- | ---- |
| —      | —      | —     | —     | —       | —              | —    |

**Notes:** Day 1 v1 paper, kill-switch active — no orders placed, no positions, no fills. Equity reconciles cleanly to the $10,000 Day 0 baseline (account `balance_asof` 2026-04-24, account created 2026-04-26). Pre-market research (two passes today) flagged this as a HOLD week into Wed FOMC + Powell presser and MSFT/GOOG earnings AMC; carrying XLE / XLI / XLP as the v2 hand-off queue. Macro tape was calm: WTI ~$95, Brent ~$106 on stalled US–Iran talks; VIX 19.31 last print; SPX 6,824.66 prior close. Light US data day (Dallas Fed Mfg only), VZ marquee BMO. Patience > activity.

# auto_invest v3 — Design Backlog

Findings collected during v2 operation that should inform v3 design. Not locked
decisions — open questions and proposed fixes. Promote items to a dated v3 spec
when ready to design.

---

## Stale-quote miss on market-open (logged 2026-05-17, observed 2026-05-12)

> **PROMOTED** into `docs/superpowers/specs/2026-06-02-auto-invest-v3-design.md` §3.6 and implemented in `market-open` STEP 5a (prior-close limit fallback) — 2026-06-02.

### Finding

Market-open routine fired 2026-05-12 at 8:30 CT. Alpaca returned:
- XLE: bid $56.02, ask $0 → skipped (refused to size off bid)
- XLP: bid $81.95, ask $0 → skipped (same)
- XLI: bid $168.86, ask $180.03 → order placed, did not fill

Re-entered all three on 2026-05-13 after PPI print.

### Cost

| Ticker | May 12 bid (skipped entry) | May 13 actual entry | Slippage |
|--------|----------------------------|---------------------|----------|
| XLE    | ~$56                       | $57.29              | +2.3%    |
| XLP    | ~$82                       | $84.27              | +2.8%    |

Plus one day of missed upside exposure on XLE/XLP (~+1% on XLE that day).

### Why this matters more than the trade cap

- **Trade cap "cost":** speculative. We don't know if XLB/XLU would have been
  profitable this week.
- **Stale-quote cost:** real. Measurably worse entries on May 13 than May 12.
  Locked-in worse cost basis on ~$4K of positions.

### Proposed v3 fix

Add a fallback path to market-open's STEP 5a (quote-fetch). If `ap=0` but bid
exists and the spread looks reasonable vs the prior session's close:

- **(a)** Defer to a later check that day instead of skipping entirely (e.g.,
  retry at 9:00 CT after regular session opens and liquidity arrives), OR
- **(b)** Place a limit order at `prior_close + MAX_ENTRY_SLIPPAGE_PCT` and
  rely on the order's day-TIF to fill once the ask materializes.

Either path recovers the day-one exposure without sizing off a bad quote.

### Open design questions

- How to define "reasonable spread" — % of prior close? Absolute $?
- Retry cadence: one retry at +30min, or poll until ask appears (with timeout)?
- Does (b) interact safely with the `MAX_ENTRY_SLIPPAGE_PCT` env var already
  used for fill-side slippage?
- Should the stale-quote condition be Telegram-noted (not URGENT) on first
  occurrence so we can see how often it actually fires?

---

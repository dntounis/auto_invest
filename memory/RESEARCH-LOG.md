# Research Log

Daily pre-market research entries are appended below by the `pre-market` routine.

## Entry Schema

```
## YYYY-MM-DD — Pre-market Research

### Account
- Equity: $X
- Cash: $X
- Buying power: $X
- Daytrade count: N

### Market Context
- WTI / Brent oil:
- S&P 500 futures:
- VIX:
- Today's catalysts:
- Earnings before open:
- Economic calendar:
- Sector momentum:

### Trade Ideas
1. TICKER — catalyst, entry $X, stop $X, target $X, R:R X:1
2. ...

### Risk Factors
- ...

### Decision
TRADE or HOLD (default HOLD if no edge)

### Sources
- Perplexity citations: <list>
- WebSearch fallback used: yes/no (which queries)
```

---

<!-- Daily entries appended below this line -->

## 2026-04-27 — Pre-market Research

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none

### Market Context
- WTI: ~$94–96/bbl; Brent: ~$105–107/bbl (Brent steady ~$105 amid US–Iran talks tempering rally; Brent +66% YoY)
- S&P 500 futures: front-month E-mini ~7,195 (+0.73% on Apr 25 close); premarket flat-to-slightly-up
- VIX: 19.31 (Apr 23 close), recent range 18.87–19.50 — calm regime
- Today's catalysts: light. Dallas Fed Manufacturing Survey 10:30 AM ET. No CPI/PPI/FOMC/jobs today.
- Earnings before open: HBT Financial (HBT) confirmed BMO; otherwise small/illiquid names
- Economic calendar: empty top-tier today; ECI Apr 30, CPI/NFP May 12, FOMC minutes May 21
- Sector momentum YTD: Energy leading (USO +77%, OIH +41%), Semis strong (PSI +44%), Telecom/AI (XTL +37%); broad SPX flattish

### Trade Ideas
*(v1 paper — kill-switch active, documentation only; verify live prices at v2 market-open before any entry)*

1. **XLE** — Energy sector momentum (oil firm, sector YTD leader). Indicative entry ~$95, stop ~$85.50 (-10%), target ~$114 (+20%), R:R ~2:1. Sector-ETF play to ride momentum without single-name idiosyncratic risk.
2. **SMH** — Semis momentum (PSI ETF +44% YTD; AI capex thesis intact). Indicative entry ~$295, stop ~$265.50 (-10%), target ~$354 (+20%), R:R ~2:1. Broad semi exposure preferred over single name on Day 1.
3. **AVGO** — Analyst Strong Buy in tech, AI/semi tailwind. Indicative entry ~$1,650, stop ~$1,485 (-10%), target ~$1,980 (+20%), R:R ~2:1. *Caveat: single share cost is high relative to $2K position cap — would need fractional or substitute (e.g., MU as cheaper proxy).*

Buy-side gate (forward check): all three pass position count (0/6), trades-this-week (0/3), 20%-cap, sector-momentum, stock-only. Final cash/PDT check belongs at execution.

### Risk Factors
- **Macro:** US–Iran talks could deflate oil rally; energy ideas have geopolitical headline risk
- **Sector:** Semis stretched after +44% YTD run; chasing strength carries pullback risk
- **Idiosyncratic:** AVGO share price > 20% cap for $10K account; need fractional support or skip
- **Calendar:** Earnings season ramping; single names carry event risk into May

### Decision
**HOLD** — v1 is paper-only with `TRADING_ENABLED=false`; wrapper kill-switch refuses orders. Ideas documented for v2 `market-open` handoff. Patience > activity on Day 1.

### Sources
- Perplexity citations: oilprice.com, tradingeconomics.com, businessinsider.com, cmegroup.com, robinhood.com prediction markets, investing.com VIX historical, bls.gov, tradingeconomics.com US calendar, stocktitan.net YTD gainers, marketbeat.com, wtop.com ETFs, tipranks.com, earningswhispers.com, marketbeat.com HBT
- WebSearch fallback used: no

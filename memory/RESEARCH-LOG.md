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

## 2026-04-27 — Pre-market Research (refreshed)

*Prior 2026-04-27 entry refreshed: corrected SPX futures level, added FOMC Wed Apr 29 + Big Tech earnings (MSFT/GOOG) Wed which were missing from prior version. Original preserved in git history (commit abf37e7).*

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- Note: Alpaca account shows `options_trading_level: 3` — irrelevant per hard rule "NO OPTIONS, ever"; wrapper kill-switch + buy-side gate (stocks only) prevent any options path.

### Market Context
- WTI: ~$92–94/bbl (Apr 23 close ~$92.92; prediction markets imply ~$94 today). Brent: not directly quoted today; recent ~$105 area, softer on supply talk.
- S&P 500 futures: E-mini ~6,865 area in premarket (+2 pts); SPX cash 6,824.66 last close after 7-day up streak. Premarket flat-to-slightly-up. NDX futures +48, Dow futures -2.
- VIX: 19.31 (Apr 23 close), range 18.87–19.50 — calm regime.
- Today's catalysts: Dallas Fed Manufacturing Survey 10:30 AM ET. VZ earnings BMO. Otherwise light.
- Earnings before open: VZ (Verizon) is the marquee BMO name; smaller: SSYS (Stratasys), BH (Biglari), GWRS, UFI, EARN. After close: minor.
- This-week event risk (high): **FOMC statement + Powell presser Wed Apr 29 (2:00 / 2:30 PM ET)**; **MSFT + GOOG earnings Wed Apr 29 (most likely AMC)**; META/AMZN/AAPL likely later in week; ECI Q1 Thu Apr 30.
- 10Y yield: 4.289% (~unch). Crude/Brent/natgas softer overnight.
- Sector momentum YTD (recent reads): Energy leading (~+26% YTD, oil-firm + AI-power demand); Industrials #2 (~+9–16%, defense/AI infra); Consumer Staples #3 (~+10%); Tech/Semis still strong with IT +45% forward EPS revisions.

### Trade Ideas
*(v1 paper — kill-switch active, documentation only; verify live prices at v2 market-open before any entry. With FOMC + Big Tech earnings Wed, prudent stance is to defer fresh entries until post-event.)*

1. **XLE** — Energy sector remains YTD leader; oil firm in low-$90s; non-binary, sector-ETF avoids single-name event risk. Indicative entry ~$95, stop ~$85.50 (-10%), target ~$114 (+20%), R:R ~2:1.
2. **XLI** — Industrials #2 YTD; defense + AI-infrastructure tailwind, not directly exposed to MSFT/GOOG print. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1.
3. **SMH** — Semis broad ETF; AI capex thesis intact, but **carries indirect Big-Tech-earnings spillover Wed**. Indicative entry ~$295, stop ~$265.50 (-10%), target ~$354 (+20%), R:R ~2:1. Prefer waiting until after MSFT/GOOG print.

Buy-side gate (forward check): all three pass position count (0/6), trades-this-week (0/3), 20%-cap, sector-momentum, stock-only. Final cash / PDT check belongs at execution.

### Risk Factors
- **Macro / event:** FOMC Wed is the dominant risk; any hawkish surprise hits multiples broadly. Powell tone matters more than statement.
- **Earnings concentration:** ~40% of S&P 500 market cap reports this week; MSFT/GOOG Wed dictate sentiment for tech and semis.
- **Sector:** Energy headline risk if US–Iran/OPEC+ talk deflates oil; semis stretched after multi-quarter run.
- **Idiosyncratic:** Single-name high-priced AI plays (AVGO, etc.) breach 20% cap on $10K account; favor sector ETFs.
- **Liquidity:** Pre-FOMC, Mon–Tue chop is common; thin conviction trades tend to underperform.

### Decision
**HOLD** — Day 1, v1 paper-only, kill-switch active. Even ignoring the kill-switch, the rational stance is to wait through FOMC (Wed) and Big Tech prints before deploying capital. Patience > activity.

### Sources
- Perplexity citations: robinhood.com prediction markets (WTI), polymarket.com, twelvedata.com (WTI hist), alfred.stlouisfed.org (WTISPLC), capis.com (SPX premarket Apr 10 note), tradingview.com (VIX), investing.com (VIX hist), tipranks.com (earnings week), capyfin.com (earnings cal), kiplinger.com (econ cal), bls.gov (BLS schedule), newyorkfed.org (econ cal), guggenheiminvestments.com (US cal), ftportfolios.com (sector YTD), morningstar.com (rotation), schwab.com (sector outlook), thestreet.com (EPS prospects).
- WebSearch fallback used: no

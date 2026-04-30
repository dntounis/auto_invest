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

---

## 2026-04-27 — Pre-market Research (second pass / re-run)

*Same date re-run of pre-market routine. No material change vs. earlier 2026-04-27 refreshed entry; deltas noted inline. Original retained above.*

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-04-24 (account created 2026-04-26; Day 0 baseline still intact, no fills)

### Market Context
- WTI: ~$95.32/bbl (Apr 26 late). Brent: ~$106.44/bbl (Apr 26 late), tradingeconomics quotes 106.92 Apr 27 (+1.51% d/d). Crude firmer than yesterday's read on stalled US–Iran talks.
- S&P 500 futures: ESM26 quoted ~6,657 in one premarket source today, but inconsistent with Friday SPX cash 6,824.66 + ESM26 +0.72% close — treat as data noise; bias is flat-to-slightly-up. Polymarket prediction market: ~67% probability SPX opens up vs. Friday close.
- VIX: 19.31 (Apr 23 close, last available); regime still calm <20. No Apr 24/27 print yet in feeds.
- Today's catalysts: light US data day. Dallas Fed Manufacturing Survey 10:30 AM ET. Geopolitical: stalled US–Iran negotiations + reported Iran proposal supporting oil bid.
- Earnings BMO today: VZ (Verizon — marquee), LKFN (Lakeland Financial), plus smaller (SSYS, BH, GWRS, UFI, EARN). Big tech (MSFT, GOOG) Wed AMC; META/AMZN/AAPL later in week.
- Economic calendar this week: **FOMC statement + Powell presser Wed Apr 29 (2:00 / 2:30 PM ET — fed funds expected unchanged 3.50–3.75%)**; Tue Apr 28 Case-Shiller HPI + Consumer Confidence; Thu Apr 30 PCE / Core PCE + ECI Q1. No CPI / PPI / NFP this week (those release mid-May).
- Sector momentum YTD (refreshed read): **Energy ~+38% YTD** (firmer than prior +26% read); Consumer Staples +10–11%; Industrials +9–16%. Tech / Comm / Cons. Disc. / Financials in lagging quadrant per momentum screens; 6-mo Tech –7.8%, Financials –7.5%. Rotation from 2025 tech leadership into defensives + cyclicals continues.

### Trade Ideas
*(v1 paper — kill-switch active. Documentation only. Pre-FOMC posture: do NOT initiate fresh entries before Wed Powell presser; ideas tracked for v2 hand-off.)*

1. **XLE** — Energy sector leader (+38% YTD); oil firm low-$90s WTI / mid-$100s Brent on Iran-talks stall. ETF sidesteps single-name event risk. Indicative entry ~$95, stop ~$85.50 (-10%), target ~$114 (+20%), R:R ~2:1. Pass buy-side gate (0/6 positions, 0/3 trades, ≤20% cap, sector-momentum aligned, stock).
2. **XLI** — Industrials #2/#3 YTD; defense + AI-infra / power-grid tailwind, no direct MSFT/GOOG print exposure. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1. Passes gate.
3. **XLP** — Consumer Staples #2 YTD (+10–11%), defensive bid into FOMC + heavy earnings week. Indicative entry ~$80, stop ~$72 (-10%), target ~$96 (+20%), R:R ~2:1. Passes gate. (Replaces SMH from prior entry — semis carry indirect MSFT/GOOG print exposure Wed AMC; staples is a cleaner pre-FOMC tilt.)

### Risk Factors
- **Macro / event:** FOMC Wed dominates. Statement likely unchanged at 3.50–3.75%; Powell tone is the swing factor. Hawkish surprise compresses multiples broadly.
- **Earnings concentration:** ~40% of S&P 500 mkt cap reports this week; MSFT/GOOG Wed AMC sets tape for tech/semis Thu.
- **Geopolitical:** Stalled US–Iran talks keeping crude bid; sudden de-escalation = oil-down / energy-down risk to XLE thesis. Iran proposal headlines moving Asia/EM today.
- **Sector:** Energy stretched on YTD basis; fade risk on any oil reversal. Tech/semis multi-quarter overshoot fragile into prints.
- **Idiosyncratic:** Single-name AI mega-caps (AVGO, NVDA, etc.) breach 20% cap on $10K equity — favor sector ETFs. PDT room intact (3/5 daytrades available).
- **Liquidity:** Mon–Tue chop pre-FOMC standard; low-conviction trades typically underperform.

### Decision
**HOLD** — Day 1 (Mon), v1 paper, kill-switch active. Even ignoring the kill-switch, rational stance is wait through FOMC (Wed) + MSFT/GOOG (Wed AMC) before deploying. Patience > activity. Ideas above carried into v2 market-open queue.

### Sources
- Perplexity citations: oilprice.com, tradingeconomics.com (Brent), markets.businessinsider.com (oil), eia.gov (spot), markets.businessinsider.com (premarket), robinhood.com prediction markets (SPX), polymarket.com (SPX open dir), barchart.com (ESM26), investing.com (VIX hist), tradingview.com (VIX futures), kiplinger.com (econ cal week of 4/27), bls.gov (BLS sched), whitehouse.gov (PFEI sched), calendarx.com (CPI Apr), marketbeat.com (LKFN), capyfin.com (earnings 4/27), investing.com earnings (VZ), earningswhispers.com, ftportfolios.com (sector YTD 3/6), investing.com (sector rotation), novelinvestor.com (sector returns), schwab.com (sector outlook), longtermtrends.com (sector RS), timesofindia.indiatimes.com (Iran-US headlines).
- WebSearch fallback used: no

---

## 2026-04-27 — Pre-market Research (third pass / re-run)

*Same date re-run. Material corrections vs. earlier 2026-04-27 entries flagged inline. Prior entries retained above; this entry is append-only.*

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-04-24 (account created 2026-04-26; baseline intact, no fills)
- options_trading_level=3 on the account is irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only) make options unreachable.

### Market Context
- **CORRECTION (vs. prior 2026-04-27 entries):** SPX cash closed at a record **7,165.08 on Apr 24, 2026** (intellectia.ai), +0.80% on the session and +8.70% MTD; the "6,824.66" figure used in the two prior 2026-04-27 entries was stale/incorrect. Q1 2026 was -4.33%, with April recovery driving the index to new highs.
- ES (E-mini S&P 500, ESM26): **~7,189.25** last (CME, -0.08% / -5.50), prior settle ~7,178.25 Apr 26; intraday high 7,200.75 Apr 27 (investing.com). Premarket flat-to-slightly-down on Iran-Hormuz headlines; Dow futures edged lower per thestreet.com.
- WTI: **~$95.27/bbl**, broken above descending trend (fxdailyreport); prediction markets imply ~68% close above $95, ~53% above $96. Apr 24 close $94.87, Apr 23 $96.99 (twelvedata).
- Brent: not directly quoted in fresh feed today; recent context ~$106.
- VIX: **19.06** (Apr 27 last available, +1.87% d/d); range 18.92–19.26; calm regime <20 holds.
- Today's catalysts: **Iran reportedly proposed reopening Strait of Hormuz via Pakistani mediators**, with nuclear talks deferred (thestreet.com); Trump canceled related peace talks. Oil bid, equities mixed. Dallas Fed Manufacturing 10:30 AM ET (light data day).
- Earnings BMO: **VZ (Verizon)** is the sole marquee BMO confirmed by tipranks for Mon Apr 27.
- This-week event risk: **CONFLICT —** prior 2026-04-27 entries had FOMC + Powell Wed Apr 29; today's investech-sourced calendar shows Wed Apr 29 as Case-Shiller HPI / Consumer Confidence and **FOMC + PCE on Thu Apr 30**, citing residual delays from the 2025 government shutdown. Treat the FOMC date as **Wed Apr 29 OR Thu Apr 30 — confirm at v2 market-open**; in either case the pre-FOMC posture is the same. Big Tech: MSFT/GOOG Wed AMC; META/AMZN/AAPL later in week. ECI Q1 expected this week. GDP Q1 advance + ISM Mfg Fri May 1.
- Sector momentum YTD (refreshed): **Energy still leader (~+38.3% YTD)** (novelinvestor / sector tracker), reinforced by today's Hormuz / Iran headlines bidding crude. Tech regaining leadership intra-month on AI capex (DELL +$64B AI server backlog raised by Barclays to $168 PT; NVDA, TSMC, TSLA momentum). Industrials and Consumer Staples remain in middle-of-pack with positive earnings momentum (FactSet 18.6% CY2026 EPS growth, 8 of 11 sectors growing y/y).

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Pre-FOMC posture: do NOT initiate fresh entries before the policy decision + presser. Three-pass consensus across today's entries is the same idea queue, with sector logic re-validated below.)*

1. **XLE** — Energy +38.3% YTD; oil firm $95+ on stalled US–Iran talks + Hormuz reopen-proposal headline-bid. ETF avoids single-name event risk. Indicative entry ~$95, stop ~$85.50 (-10%), target ~$114 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades, ≤20% cap (~$950 = 9.5% on a $10K equity at 10 sh), sector-momentum aligned, stock — passes.
2. **XLI** — Industrials in middle-of-pack with positive EPS surprises; defense + AI-infra / power-grid tailwind, no direct MSFT/GOOG print exposure. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1. Passes gate.
3. **XLP** — Consumer Staples defensive bid into FOMC + heavy earnings week; cleaner pre-event tilt than semis. Indicative entry ~$80, stop ~$72 (-10%), target ~$96 (+20%), R:R ~2:1. Passes gate.

### Risk Factors
- **Macro / event:** FOMC + Powell presser this week (Wed OR Thu — confirm date). Statement consensus unchanged at 3.50–3.75%; Powell tone is the swing. Hawkish surprise compresses multiples broadly.
- **Earnings concentration:** ~40% of S&P 500 mkt cap reports this week; MSFT/GOOG Wed AMC sets tape for tech/semis.
- **Geopolitical:** Iran-Hormuz reopen proposal is two-sided — could deflate crude (XLE down) on de-escalation, or spike if talks collapse. Trump-cancels-peace-talks headline today is the risk-off catalyst.
- **Sector:** Energy stretched on YTD basis; fade risk on any oil reversal. Tech/semis multi-quarter overshoot fragile into prints (forward P/E 20.9, above 5y avg per FactSet).
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, etc.) breach 20% cap on $10K — sector ETFs are the right structural fit. PDT room intact (3/5 daytrades available).
- **Liquidity:** Mon–Tue chop pre-FOMC standard; low-conviction trades underperform.
- **Data quality:** Material correction this run on SPX cash level (7,165 vs. prior 6,824) and FOMC date (Thu Apr 30 vs. Wed Apr 29). Verify both at v2 market-open before any execution.

### Decision
**HOLD** — Day 1 (Mon), v1 paper, kill-switch active. Even setting the kill-switch aside, rational stance is wait through FOMC + Big Tech prints. Patience > activity. XLE / XLI / XLP carried as the v2 market-open queue.

### Sources
- Perplexity citations: fxdailyreport.com (WTI technicals), twelvedata.com (WTI hist), robinhood.com prediction markets (WTI/SPX), polymarket.com (WTI/SPX), cmegroup.com (ESM6), investing.com (ESM6 hist), barchart.com (ESH27), tradingview.com (VIX futures), investing.com (VIX hist), wallstreetzen.com (stocks to watch 4/27), thestreet.com (Hormuz / Dow futures Apr 27), zacks.com (strong sells 4/27), tipranks.com (earnings 4/27 wk), investech.com (econ cal 2026 PDF), bls.gov (May sched), us.econoday.com, yelza.com (econ cal 4/27–5/1), guggenheiminvestments.com (US econ cal), intellectia.ai (SPX record 7,165.08 Apr 24), insight.factset.com (CY2026 EPS 18.6%), novelinvestor.com (sector returns), cmegroup.com (Apr 2026 equity recap), spglobal.com (S&P 500 Momentum Index), ssga.com (sector tracker).
- WebSearch fallback used: no (Perplexity 503 hit on first call, recovered on retry — no native fallback used)

---

## 2026-04-30 — Pre-market Research

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-04-28 (account snapshot lags by 2d — no fills, no reconciliation event; baseline intact)
- options_trading_level=3 on the account is irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only) make options unreachable.

### Market Context
- **WTI: ~$111/bbl** (sharp escalation vs. Mon's ~$95 read; twelvedata Apr 30 print 111.25). Driver: Middle East military action (per EIA Q1 note) + unresolved peace talks; WTI up in 5 of last 6 sessions, 3-week highs. Prediction markets imply ~40% chance close >$110 today.
- **Brent:** no clean spot quote in feeds today; recent context $107 (Apr 7 Statista) and $111 (Mar 30 Fortune); intraday dipped <$100 on talks then rebid. Implied $100–$115.
- **S&P 500 cash: 7,137.90 close Apr 29** (just below ATH 7,147 from Apr 22). Q1 -4.3%; April recovered +8%+ MTD.
- **ES (ESM26) premarket:** data conflict — markets.businessinsider quotes 6,657 area (treat as stale/wrong; inconsistent with cash 7,138 + ESM26 +0.14–0.21% Apr 29 close per barchart). Better read: ES roughly flat-to-slightly-up around 7,150 area on a normalized basis.
- **VIX: 17.81 close Apr 29** (range 17.84–18.13, +1.63% d/d); calm regime <20 holds despite oil spike + heavy event tape. Markets shrugging — AI/earnings complacency.
- **FOMC Apr 29 outcome:** **HELD at 3.50–3.75%** (1 dissenter, Miran, favored ¼ pt cut). Powell: PCE ~3.5% "elevated"; energy/Middle East cited as inflation driver; policy stance "appropriate"; data-dependent on next move. Slightly hawkish vs. dovish setup; SPX still closed near ATH so market took it well.
- **Today's catalysts (8:30 AM ET print stack):**
  - Q1 GDP advance estimate (BEA)
  - Personal Income & Outlays + **Core PCE** (March)
  - Employment Cost Index Q1
  - Weekly Jobless Claims
  - Construction Spending + ISM Mfg later (10:00)
  - FOMC Minutes 1:00 PM ET (per Thomson cal)
  - **AMC: META + AMZN earnings** (after MSFT/GOOG Wed AMC)
- **Wed AMC results (key for tape today):**
  - **MSFT:** rev $82.9B (beat $81.3B); Azure guide 39–40% (beat 36.7%); **$190B 2026 capex** (vs $150B est — massive AI infra spend); EPS $4.27 vs $4.05; gross margin 68% (down y/y on AI capex); shares -2% AH then flat. Capex shock + headcount-down guide = mixed.
  - **GOOG:** **Cloud +63%** (vs 50.1% est) — clean beat. AH positive.
  - Headline framing: "Big Tech Split: Google/Amazon surge, Microsoft/Meta lag" — META not yet reported (tonight); treat that headline as forward-looking commentary.
- **Sector momentum YTD (refreshed):** **Energy still leader ~+38–40%+ YTD** (likely higher post-WTI $111 spike); Real Estate #2 +2.8%; Tech rotation back leading April (+2.2% one-session XLK); 6-mo: Energy +40.4%, Materials +11.0%, Staples +7.7%, IT -7.8%. S&P 500 Momentum Index +17.26% QTD/YTD as of 4/24.

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Posture: pre-event 8:30 macro stack + META/AMZN AMC = HOLD into Friday open at minimum. Three-day-running queue continues.)*

1. **XLE** — Energy +38–40%+ YTD, oil $111 spike reinforces leadership; sector ETF avoids single-name event risk. Indicative entry ~$100, stop ~$90 (-10%), target ~$120 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades, ≤20% cap (10 sh ≈ $1,000 = 10% equity), sector-momentum aligned, stock — passes. Caveat: stretched on YTD basis; entry into weakness preferred over chase.
2. **XLI** — Industrials middle-of-pack with positive earnings momentum; defense + AI-infra/power-grid tailwind, no direct META/AMZN print exposure. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1. Passes gate.
3. **XLP** — Consumer Staples +7.7% trailing 6-mo, defensive bid sensible into Core PCE + GDP print + META/AMZN AMC. Indicative entry ~$80, stop ~$72 (-10%), target ~$96 (+20%), R:R ~2:1. Passes gate.

### Risk Factors
- **Macro / event:** Today's 8:30 stack is dense — GDP advance + Core PCE + ECI Q1 + Claims all at once. PCE is the highest-impact print given Powell's "elevated 3.5%" framing yesterday; an upside surprise reignites no-cut/hike-on-table narrative. FOMC Minutes 1:00 PM secondary.
- **Earnings concentration:** META + AMZN AMC tonight set tape for tech/discretionary Friday open. MSFT $190B capex + headcount-down already priced AH — watch for read-through to AI infra (NVDA/AVGO/SMH) Thursday session.
- **Geopolitical / energy:** WTI $111 driven by Middle East military action; oil supply shock = inflation tailwind = hawkish-Fed risk. Two-sided — sudden de-escalation = oil-down / XLE down. No Hormuz closure to-date.
- **Sector:** Energy stretched on YTD; fade risk on any oil reversal. Tech earnings binary (MSFT mixed, GOOG good — META/AMZN tonight); semis still fragile into AI-capex commentary.
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, MSFT, GOOG) all breach 20% cap on $10K — sector ETFs (XLE/XLI/XLP/SMH) remain the structural fit. PDT room intact (3/5 daytrades available).
- **Liquidity:** Post-FOMC + pre-PCE chop; thin conviction trades underperform.
- **Data quality:** ESM26 quote 6,657 from one source clearly stale vs. cash 7,138 — treat with skepticism. Account `balance_asof` lags 2d (no fills, no reconciliation event); baseline intact.

### Decision
**HOLD** — Day 4 (Thu), v1 paper, kill-switch active. Even setting the kill-switch aside, rational stance is wait through 8:30 macro stack (esp. Core PCE) + META/AMZN AMC before any deployment. Friday's GDP/ISM Mfg + post-print digestion sets cleaner entry. XLE / XLI / XLP carried as the v2 market-open queue. Trades this week: 0/3. Patience > activity.

### Sources
- Perplexity citations: twelvedata.com (WTI hist Apr 30), robinhood.com prediction markets (WTI/Brent/SPX), eia.gov (Q1 oil note + military action context), barchart.com (ESM26, CLJ26, QAJ26), markets.businessinsider.com (premarket — flagged as stale), investing.com (S&P futures), tradingeconomics.com (VIX), fred.stlouisfed.org (VIX Apr 28/29), investing.com (VIX hist), federalreserve.gov (FOMC statement Apr 29 + Mar 18), propfirmscan.com (Powell Apr 29 analysis), bea.gov (release schedule Apr 30 GDP/PCE), thomsoninvestmentgroup.com (econ cal Apr 30), us.econoday.com, marketbeat.com (MSFT/GOOG Q3 results), microsoft.com investor (FY26 Q2/Q3), economictimes.com (MSFT Azure guide + $190B capex), businessinsider.com (MSFT headcount), moomoo.com (Big Tech split commentary), morningstar.com (tech earnings preview), ftportfolios.com (sector YTD), novelinvestor.com (sector returns), schwab.com (sector outlook), spglobal.com (S&P 500 Momentum Index), ssga.com (sector tracker), cmegroup.com (Apr 2026 equity recap), octagonai.co (Brent), statista.com (Brent Apr 7), fortune.com (oil Mar 30).
- WebSearch fallback used: no

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

---

## 2026-04-30 — Pre-market Research (second pass / re-run)

*Same date re-run. Material corrections vs. earlier 2026-04-30 entry flagged inline. Prior entry retained above; this entry is append-only.*

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-04-29 (refreshed +1d vs. morning entry; baseline intact, no fills)
- options_trading_level=3 on the account is irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only) make options unreachable.

### Market Context
- **CORRECTION (earnings calendar) vs. morning entry:** **META + AMZN both reported Wed Apr 29 AMC**, alongside MSFT/GOOG — not tonight as morning entry stated. **AAPL is the lone marquee AMC tonight (Thu Apr 30, 5:00 PM ET conference call)** — Q2 FY2026 results. Tape today digests four-name Big Tech print + AAPL into the close.
- **Wed AMC additional results:**
  - **AMZN:** Q1 results released Apr 29 AMC. Q1 net income includes **$16.8B pre-tax gains from Anthropic investments** (non-operating income). Pre-print consensus was EPS $1.63 / rev $177.28B / AWS ~$36.6B (+25% y/y). AMZN +30% in the prior month into the print on AWS strength + Meta-AI Graviton partnership + up to $25B Anthropic investments. Detailed beat/miss not yet in feeds.
  - **META:** Q1 results released Apr 29 AMC. Susquehanna reiterated Positive rating "amid capex increase" (per Investing.com Apr 30) — i.e., META joined the Big Tech AI-capex hike alongside MSFT $190B.
  - Headline framing: AI capex arms race intact; "no leaderboard but companies competing like there is one" (BI). MSFT $190B capex remains the standout single number.
- **WTI:** **~$108.34 close Apr 30** (investing.com, +1.37% d/d) — softer than morning entry's $111 read, still elevated vs. Mon's ~$95. WTI sequence: Apr 28 $99.93 → Apr 29 $106.88 (+6.95%) → Apr 30 $108.34. Prediction markets imply 67¢ WTI ≥$108, 60¢ ≥$109, 54¢ ≥$100. Three-week highs hold; supply-shock narrative intact.
- **Brent:** no fresh spot today; recent context $96–$107 range. Indirect proxy via WTI.
- **ES (ESM26):** ~**7,171** last (CME quote) — premarket **+0.14% to flat** per barchart Apr 30 morning. Underlying SPX cash 7,137.90 close Apr 29 (just below Apr 22 ATH 7,147). NQM26 +0.27% premarket.
- **VIX:** **17.83 close Apr 28** (FRED — next release today after market close). Apr 27 close 18.02; Apr 29 open 18.81. Calm regime <20 holds despite oil + earnings + macro stack.
- **Today's catalysts (8:30 AM ET print stack — unchanged from morning entry):**
  - Q1 GDP advance estimate (BEA) — consensus **+2.2 to +2.6% annualized** (vs. Q4 2025 0.5% revised). Philly Fed SPF: +2.6%.
  - March Personal Income & Outlays + **Core PCE** — recent core PCE 3.0% y/y (Feb), still elevated vs. 2% target. Powell flagged 3.5% headline as "elevated" Wed.
  - Q1 Employment Cost Index
  - Weekly Jobless Claims
  - Construction Spending + ISM Mfg later
  - FOMC Minutes 1:00 PM ET (per Thomson cal)
  - **AMC: AAPL only** (5:00 PM ET call)
- **Sector momentum YTD (refined / corrected):** **S&P 500 Energy YTD +26.27% as of Apr 27 (S&P Global, price return; index level 867.90)** — meaningfully lower than the +38–40% read in earlier 2026-04-27/30 entries (those numbers conflated longer-window or different-methodology sources). Energy still clear leader, but the magnitude is more like high-20s%, not high-30s%. Real Estate #2 ~+2.8%; Tech regaining intra-month leadership on AI capex (XLK ~+2.2% one-session). FactSet CY2026 EPS growth 18.6%, 8 of 11 sectors growing y/y. S&P 500 Momentum Index +17.26% YTD.

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Posture: pre-print 8:30 macro stack + AAPL AMC = HOLD into Friday open at minimum. Same three-name queue from morning entry, sector logic re-validated against revised Energy YTD.)*

1. **XLE** — Energy +26%+ YTD (revised from 38%+); oil $108 still firm, Iran/Hormuz overhang intact. Sector ETF avoids single-name event risk. Indicative entry ~$100, stop ~$90 (-10%), target ~$120 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades, ≤20% cap (10 sh ≈ $1,000 = 10% equity), sector-momentum aligned, stock — passes. Caveat: less stretched than prior 38% read implied; entry into weakness still preferred over chase.
2. **XLI** — Industrials middle-of-pack with positive earnings momentum; defense + AI-infra/power-grid tailwind, no direct AAPL print exposure. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1. Passes gate.
3. **XLP** — Consumer Staples defensive bid sensible into Core PCE + GDP print + AAPL AMC. Indicative entry ~$80, stop ~$72 (-10%), target ~$96 (+20%), R:R ~2:1. Passes gate.

### Risk Factors
- **Macro / event:** 8:30 stack dense (GDP advance + Core PCE + ECI Q1 + Claims). Core PCE highest-impact given Powell's "elevated 3.5%" framing Wed; upside surprise reignites no-cut narrative. FOMC Minutes 1:00 PM secondary.
- **Earnings:** Big Tech four-name (MSFT/GOOG/META/AMZN) all printed Wed AMC — split tape (MSFT mixed on capex, GOOG strong cloud, META capex hike priced as positive by sell-side, AMZN Anthropic gain skewed result). AAPL AMC tonight is the last marquee mega-cap; Services and China data are the swing.
- **Geopolitical / energy:** WTI $108 still driven by Middle East military action; supply shock = inflation tailwind = hawkish-Fed risk. Two-sided — sudden de-escalation = oil-down / XLE down.
- **Sector:** Revised Energy +26% YTD less stretched than prior 38% read — but still leader and dependent on oil bid. Tech AI-capex narrative now externally validated by all four mega-cap prints; semis/AI-infra read-through positive on net.
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, MSFT, GOOG, META, AMZN, AAPL) all breach 20% cap on $10K — sector ETFs (XLE/XLI/XLP/SMH) remain the structural fit. PDT room intact (3/5).
- **Liquidity:** Post-FOMC + pre-PCE chop; thin conviction trades underperform.
- **Data quality:** Energy YTD corrected from ~+38% (earlier entries) to +26.27% (S&P Global Apr 27). Account `balance_asof` refreshed to 2026-04-29 (was 2026-04-28 morning).

### Decision
**HOLD** — Day 4 (Thu), v1 paper, kill-switch active. Even setting the kill-switch aside, rational stance is wait through 8:30 macro stack (esp. Core PCE) + AAPL AMC + Friday GDP/ISM digestion before any deployment. XLE / XLI / XLP carried as the v2 market-open queue. Trades this week: 0/3. Patience > activity.

### Sources
- Perplexity citations: investing.com (WTI hist Apr 30 — close $108.34), robinhood.com prediction markets (WTI/SPX), barchart.com (ESM26, CLJ26 Apr 30), cmegroup.com (ESM26 7,171), fred.stlouisfed.org (VIX Apr 28 17.83), investing.com (VIX hist), tradingeconomics.com (VIX monthly Apr), bea.gov (release schedule Apr 30), philadelphiafed.org (SPF Q1 +2.6%), biggo.com / kraken blog (GDP Q1 forecast), tradingeconomics.com (Core PCE Feb 3.0%), marketbeat.com (AMZN Q1 4/29, META Q1 4/29), ir.aboutamazon.com (AMZN $16.8B Anthropic gain), investor.atmeta.com (META 4/29 AMC confirmed), wallstreethorizon.com (META 4/29, AAPL 4/30 confirmed), investor.apple.com (AAPL 4/30 5:00 PM ET call), businessinsider.com (Big Tech earnings recap), ca.investing.com (Susquehanna META capex), spglobal.com (Energy YTD 26.27% Apr 27), novelinvestor.com (sector returns), ycharts.com (Energy YTD).
- WebSearch fallback used: no

---

## 2026-05-01 — Pre-market Research

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-04-30 (refreshed +1d vs. Thu second-pass; baseline intact, no fills)
- options_trading_level=3 on the account is irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only) make options unreachable.

### Market Context
- **WTI: ~$103–105/bbl** (perplexity front-month $105.07 with -1.69% intraday tilt; Robinhood prediction markets imply 73¢ ≥$104, 64¢ ≥$105 at today's settle). Off Apr 30's spike print (Polymarket-noted intraday high $110.90 on Apr 30 driven by Middle East geopolitics) — softer but elevated vs. Mon's ~$95 baseline. Sequence: Apr 28 $99.93 → Apr 29 $106.88 → Apr 30 $108.34 → May 1 ~$103–105. WTI in 5 of last 6 sessions up; 3-week highs holding.
- **Brent: ~$110.84/bbl** (perplexity front-month, +0.36% intraday); Robinhood prediction markets imply 81¢ ≥$109.99, 58¢ ≥$111.99 at 5:00 PM EDT settle. Brent–WTI spread ~$5–7, normal.
- **SPX cash: 7,137.90 close Apr 29** (last clean print available; Apr 30 close not yet in feeds). E-mini ESM26 quoted ~7,255–7,259 with +0.21% (+15.50) intraday; data conflict vs. cash close suggests post-AAPL bid, premarket flat-to-slightly-up. Treat ES level cautiously until cash settles. Apr 22 ATH 7,147 still the resistance reference.
- **VIX: 16.89 close Apr 30** (gurufocus / CBOE) — DOWN from 17.83 Apr 28 / 18.02 Apr 27, calm regime <20 holds firmly despite oil + earnings + dense macro tape. VIK26 May futures 20.25 (-2.45% 3M); one feed shows May 1 open 18.68 (treat as intraday noise, not confirmed close).
- **AAPL Apr 30 AMC outcome (key for tech tape today):** **BEAT.** Q2 FY2026 revenue **$111.2B (+17% YoY)** vs. est $109.73B; EPS **$2.01 (+22% YoY)** vs. est $1.94; iPhone $57B (+22%, March-quarter record); Services $31.0B (all-time high); gross margin **49.3%** (+2.2pp YoY); operating cash flow $28.7B; $11B buyback + $0.27 dividend (+4%). Net cash $62B. Records across revenue/EPS/iPhone/Services/cash flow. Friday tape carries this positive print into the close — Big Tech four-name (MSFT/GOOG/META/AMZN) digested Wed, AAPL clean-beat Thu = AI/tech narrative externally validated heading into May.
- **Today's catalysts:**
  - **10:00 AM ET — ISM Manufacturing PMI** (March prior 52.7); **ISM Mfg Employment forecast 49.0 vs. prior 48.7** (highest-impact print today; jobs-data leading indicator into June 5 NFP).
  - 9:45 AM ET — S&P Global Mfg PMI final (flash 50.1 vs. consensus 50.5, near-stall).
  - **No NFP today** — Employment Situation for May data scheduled Friday June 5.
  - **Energy supermajors BMO**: **XOM (Exxon, ~$615B mkt cap)** and **CVX (Chevron, ~$372B mkt cap)** — direct read-through to XLE and the energy thesis.
  - Other BMO: FFIV (~$17B), SFM (Sprouts Farmers Market, ~$16B), TLK, ISNPY. AMC: minor.
- **FOMC Apr 29 outcome carry-over:** Held at **3.50–3.75%** (1 dissenter Miran for ¼-cut); Powell flagged PCE "elevated" + Middle East energy as inflation drivers; policy "appropriate", data-dependent. Slightly hawkish vs. dovish setup but market shrugged (SPX ~ATH).
- **Sector momentum YTD (refreshed):** **Energy still leader** — First Trust thru 3/6: +26.47% YTD; trailing 6-mo +40.4% (per Schwab); only positive sector in March; all 5 subsectors top-15. **Consumer Staples** #2 +10.66% YTD (6-mo +7.7%). **Industrials** #3 +9.61% YTD (6-mo +5.5%). **Materials** in leading quadrant, breakout potential (XLB targeting $56.8 cup-handle). **Lagging quadrant**: Tech (XLK 6-mo -7.8%), Financials (-7.5%), Cons Disc, Comm — though April saw tech regaining intra-month leadership on AI capex (XLK +2.2% one-session). S&P 500 Momentum Index YTD +12.09%, 1-yr +41.36%. Three-day-running thesis (Energy/Staples/Industrials leadership) **fully intact**.

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Posture: Day 5 / Friday, end of Week 1; AAPL clean-beat removes the last marquee Big Tech overhang; ISM Mfg + XOM/CVX prints are today's swing factors. Three-day-running queue continues.)*

1. **XLE** — Energy +26.5% YTD / +40.4% 6-mo, clear leader; sector ETF avoids XOM/CVX single-name binary today. Indicative entry ~$100, stop ~$90 (-10%), target ~$120 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades, ≤20% cap (10 sh ≈ $1,000 = 10% equity), sector-momentum aligned, stock — passes. Caveat: XOM + CVX BMO are a two-sided event for XLE today; entry into post-print weakness (oil-down or guide-disappoint) preferred over chase.
2. **XLI** — Industrials +9.6% YTD; defense + AI-infra/power-grid tailwind; no direct earnings exposure today. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1. Passes gate.
3. **XLP** — Consumer Staples +10.66% YTD, defensive bid sensible into ISM Mfg + post-AAPL digestion. Indicative entry ~$80, stop ~$72 (-10%), target ~$96 (+20%), R:R ~2:1. Passes gate.

### Risk Factors
- **Macro / event:** ISM Mfg Employment 49.0 forecast — sub-50 contraction read sets soft-jobs tone into June 5 NFP; surprise upside reignites no-cut narrative. ISM Mfg headline 52.7 prior is a high bar — miss = growth-scare, beat = inflation-tailwind for hawkish-Fed thesis.
- **Earnings (today):** XOM + CVX BMO are direct XLE catalysts. Strong beats on production/cash flow = energy bid extends; capex-cut or weak guide = oil-stocks fade despite firm spot. AAPL after-effect: tech tape opens green, AI-capex narrative now externally validated by all five mega-cap prints (MSFT/GOOG/META/AMZN/AAPL).
- **Geopolitical / energy:** WTI off Apr 30's $110.90 spike but holding low-$100s on Middle East supply-shock narrative. Two-sided as always — sudden de-escalation = oil-down / XLE down; Hormuz closure scenario unrealized but tail risk live.
- **Sector:** Energy stretched on YTD basis even at +26%; fade risk on any oil reversal, magnified by today's XOM/CVX prints. Tech AI-capex narrative externally validated post-AAPL but forward P/E 20.9 leaves room for digestion.
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, MSFT, GOOG, META, AMZN, AAPL) all breach 20% cap on $10K — sector ETFs (XLE/XLI/XLP/SMH) remain the structural fit. PDT room intact (3/5 daytrades available).
- **Liquidity:** Friday + month-start + post-AAPL digestion + ISM print = chop risk; thin-conviction trades typically underperform.
- **Data quality:** Apr 30 SPX cash close not yet in feeds (relying on Apr 29 7,137.90 + ESM26 7,255 area extrapolation); VIX Apr 30 close 16.89 confirmed by gurufocus/CBOE. Account `balance_asof` refreshed to 2026-04-30 (was 2026-04-29 Thu PM).

### Decision
**HOLD** — Day 5 (Fri), v1 paper, kill-switch active. End of Week 1: trades 0/3 (week-quota does not roll into next week — new 3-trade budget Monday). Even setting the kill-switch aside, rational stance is wait through ISM Mfg + XOM/CVX prints + Friday close before any deployment; v2 market-open will get a clean three-day-running XLE / XLI / XLP queue plus the AAPL-beat tech-tape context. Patience > activity.

### Sources
- Perplexity citations: oilprice.com (WTI/Brent charts), robinhood.com prediction markets (WTI May 1 / Brent May 1 / SPX), polymarket.com (WTI Apr 30 high $110.90), barchart.com (CLK26, CBK26, B1K26, ESM6, VI*0), fred.stlouisfed.org (DCOILWTICO Apr 27 99.89, Apr 24 98.42), cmegroup.com (ESM6 7,259.25 +0.21%), investing.com (S&P futures 7,255.25, VIX hist), gurufocus.com (VIX 16.89 Apr 30), spglobal.com (S&P 500 Momentum Index YTD 12.09% / 1-yr 41.36%), ftportfolios.com (sector YTD thru 3/6: Energy +26.47%, Staples +10.66%, Industrials +9.61%), schwab.com (sector outlook 6-mo: Energy +40.4%, Materials +11.0%, Staples +7.7%, IT -7.8%, Financials -7.5%), investing.com sector rotation (XLB cup-handle), slickcharts.com (S&P YTD), digrin.com (earnings cal May 1: XOM/CVX BMO), earningswhispers.com (May 1), investing.com (Manufacturing PMI + ISM headline), tradingeconomics.com (ISM Mfg Mar 52.7), bls.gov (NFP June 5 schedule), apple.com newsroom (AAPL Q2 FY26 press release), 9to5mac.com (AAPL Q2 +17%), macrumors.com (AAPL $29.6B net income), marketbeat.com (AAPL beats, Q2 FY26), investor.apple.com (Q2 FY26 conference call confirmed), thomsoninvestmentgroup.com (econ cal carry-over).
- WebSearch fallback used: no

---

## 2026-05-04 — Pre-market Research

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-05-01 (refreshed +1d vs. Fri PM; baseline intact, no fills, no reconciliation event)
- options_trading_level=3 on the account is irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only) make options unreachable.

### Market Context
- **WTI: ~$101.50/bbl** (fxdailyreport May 4; symmetrical-triangle setup bounded $90 (lower) / $110 (upper)). Sequence: Apr 28 $99.93 → Apr 29 $106.88 → Apr 30 $108–111 intraday spike (Polymarket-noted high $110.90) → May 1 close $102.50 → May 4 ~$101.50. **Off the Apr 30 spike, holding low-$100s.** Robinhood prediction markets imply 69¢ ≥$101, 59¢ ≥$102, 39¢ ≥$103. Economic Times notes "crude dips below $110 for second session" — Gulf de-escalation proposals are easing the supply-shock premium.
- **Brent: ~$116.10/bbl** (Fortune, May 1 reference — no fresh May 4 spot in feeds; ~$53/bbl higher YoY). Brent–WTI spread unusually wide (~$14) vs. typical $5–7 — likely stale Brent print or genuine geopolitical premium dispersion; treat with skepticism, prefer WTI as the cleaner read today.
- **SPX cash: 7,137.90 close Apr 29** remains the last crisp print in feeds; Apr 30 / May 1 cash closes still not in feeds. **ESM26 ~+0.23% premarket** per BBH/Investing.com. **Goldman Sachs flagged SPX > 7,100 as unsustainable "froth"** (Investing.com analyst note carried through May reports) — first explicit sell-side push-back vs. the ATH run. AI/Nasdaq momentum noted as still leading the tape into May (Investors Underground May 4 scan).
- **VIX: 16.89** last clean print (April monthly read; Apr 30 close confirmed in prior entries). No fresh May 4 spot in feeds; calm regime <20 holds. May VIX futures 20.25 area — typical contango.
- **FOMC carry-over (Apr 29):** held 3.50–3.75% (1 dissenter Miran), Powell flagged Core PCE 3.5% as "elevated", policy "appropriate", data-dependent. Fed funds futures imply steady rates through year-end with potential for one 25bps cut (BBH).
- **This week — economic calendar (BBH):**
  - **Mon May 4:** light US data day, no major releases.
  - **Tue May 5:** **March JOLTS** (labor market stabilization read); RBA policy decision (consensus +25bp to 4.35%); ADP Employment Change (consensus +62K) and Initial Jobless Claims (~205K) flagged by tradingeconomics for the week.
  - **Wed May 6:** National Bank of Poland (hold 3.75%); Norges Bank to hike, Riksbank on hold.
  - **Thu May 7:** **Q1 nonfarm productivity** (consensus +1.0% SAAR vs. Q4 +1.8%) — relevant for unit-labor-cost / inflation read given 3.4% wage growth.
  - **Fri May 8:** **April nonfarm payrolls — consensus +62K vs. March +178K, unemployment 4.3% unchanged.** Highest-impact print of the week. Soft-jobs path of consensus = dovish setup; upside surprise reignites no-cut narrative.
  - **No CPI/PPI/FOMC this week** (CPI/PPI mid-May; next FOMC June).
- **Today's catalysts:**
  - **AMC: PLTR (Palantir, ~$345B mkt cap) reports** — biggest single-name AI catalyst this week; sets tape for AI/data-analytics names Tue. Pre-print AI/Nasdaq momentum noted still constructive.
  - **BMO: small regional banks** (CCBG, MCB, CATY, HBCP) — no marquee tape-mover BMO.
  - News-driven: GME on potential EBAY-bid headlines (Investors Underground May 4 scan); KTB / GILD / AMRX flagged in WallStreetZen weekly-watch.
- **Sector momentum YTD / 6-mo (refreshed May 4):**
  - **Energy still leader** — 6-mo trailing **+30.3%** (Schwab May 1 sector outlook); YTD +26.47% thru 3/6 (FT Portfolios). All five Energy subsectors top-15. Energy and Consumer Staples both noted at all-time highs.
  - **Materials 6-mo +17.2%** (Schwab) — breakout in progress; carrying XLB cup-handle setup.
  - **Industrials 6-mo +11.4%**, YTD +9.61%.
  - **Consumer Staples** YTD +10.66%, 6-mo +7.7% — defensive bid intact.
  - **Lagging quadrant:** Tech, Communications, Consumer Discretionary, Financials. Tech 12-mo +52.7% but recent momentum weak (XLK 6-mo -7.8%). Healthcare weakening; Real Estate and Utilities improving.
  - **Index composition:** IT 32.95%, Financials 12.54%, Comm 10.53% — tech weight still dominates the index even as momentum rotates underneath.

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Posture: Day 6 / Week 2 Day 1, light data Mon, no positions held, three-day-running queue continues. Defer to NFP Fri before any deployment given Goldman "froth" call + soft-jobs consensus + PLTR AMC tonight.)*

1. **XLE** — Energy +26%+ YTD / +30.3% 6-mo, clear leader; sector ETF avoids single-name binary risk (XOM/CVX prints already in rear-view from Fri). Indicative entry ~$100, stop ~$90 (-10%), target ~$120 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades this new week, ≤20% cap (10 sh ≈ $1,000 = 10% equity), sector-momentum aligned, stock — passes. Caveat: WTI rolling off Apr 30 $111 spike toward triangle midpoint ($101) — entry into post-de-escalation weakness preferred over chase.
2. **XLI** — Industrials +9.6% YTD / +11.4% 6-mo; defense + AI-infra/power-grid tailwind, no direct PLTR-print read-through. Indicative entry ~$160, stop ~$144 (-10%), target ~$192 (+20%), R:R ~2:1. Passes gate.
3. **XLB** — *(NEW — replaces XLP rotation)* Materials 6-mo **+17.2%** (Schwab #2 ranked), breakout setup (cup-handle to $56.8 per investing.com sector rotation). Sector-leading momentum behind only Energy on a 6-mo basis; cleaner cyclical/inflation-beneficiary tilt vs. defensive XLP given soft-jobs / dovish-setup tape. Indicative entry ~$54, stop ~$48.60 (-10%), target ~$64.80 (+20%), R:R ~2:1. Passes buy-side gate (0/6, 0/3, ≤20% cap at 18 sh ≈ $972 = 9.7% equity, sector-momentum aligned, stock). XLP retained as the defensive alternate if NFP surprises hot or VIX breaks 20.

### Risk Factors
- **Macro / event:** **Friday April NFP is the dominant risk this week.** +62K consensus vs. +178K prior is a sharp deceleration; in-line print = soft-landing/dovish-setup positive for cyclicals (XLE/XLI/XLB) and tech; downside surprise = growth-scare / risk-off; upside surprise = no-cut narrative reignites and hits multiples. JOLTS (Tue) + Q1 productivity (Thu) provide directional setup.
- **Sentiment / positioning:** **Goldman "froth" call** above SPX 7,100 is the first major sell-side push-back at ATH — sentiment risk. AI/Nasdaq momentum-extended; PLTR AMC tonight ($345B mkt cap) sets tape for AI/data-analytics Tue.
- **Geopolitical / energy:** Gulf de-escalation proposals taking the Middle East supply-shock premium out of crude (WTI off $111 toward triangle midpoint $101). Two-sided as always — fresh escalation = oil-up / XLE-up; further de-escalation = oil-down / XLE-down. WTI < $100 is the technical break level for the symmetrical triangle thesis.
- **Sector:** Energy YTD-stretched even at +26%; XOM/CVX prints already digested last week, so today's risk is oil-spot-driven. Tech AI-capex narrative externally validated by all five mega-cap prints (MSFT/GOOG/META/AMZN/AAPL) — but Goldman froth call + recent 6-mo XLK -7.8% says momentum has rotated. Energy + Consumer Staples both at ATH = late-cycle leadership signature.
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, MSFT, GOOG, META, AMZN, AAPL, PLTR) all breach the 20% cap on $10K equity — sector ETFs (XLE/XLI/XLB/XLP/SMH) remain the structural fit. PDT room intact (3/5 daytrades available).
- **Liquidity:** Mon Day 1 Week 2, light data, post-AAPL/post-XOM/CVX digestion — chop risk; thin-conviction trades typically underperform pre-NFP weeks.
- **Data quality:** Apr 30 / May 1 SPX cash closes still not in fresh feeds (extrapolating from Apr 29 7,137.90 + ESM26 ~+0.23% premarket). VIX May 4 spot also missing from feeds — relying on Apr 30 16.89 close. Brent $116 spot (Fortune May 1 ref) appears stale or anomalous vs. WTI $101 — unusually wide $14 spread; treat with skepticism. Account `balance_asof` refreshed to 2026-05-01.

### Decision
**HOLD** — Day 6 (Mon, Week 2 Day 1), v1 paper, kill-switch active. Even setting the kill-switch aside, rational stance is wait through the Tue–Thu setup data (JOLTS, productivity) and **Fri NFP** before any deployment; PLTR AMC tonight is single-name binary (not in queue) but sets AI tape for Tue. New 3-trade week budget intact (0/3). Goldman "froth" call introduces material sentiment risk at ATH; XLE / XLI / XLB carried as the v2 market-open queue (XLB rotates in vs. last week's XLP based on +17.2% 6-mo Materials breakout vs. defensive Staples). Patience > activity.

### Sources
- Perplexity citations: fxdailyreport.com (WTI May 4 analysis $101.50, symmetrical triangle), fortune.com (Brent $116.10 May 1), economictimes.com (WTI < $110 second session), robinhood.com prediction markets (WTI May 4), polymarket.com (WTI May 4 thresholds), twelvedata.com (WTI hist May 1 close $102.65, Apr 30 $111.25, Apr 29 $102.21), eia.gov (Q1 oil + military action), fedprimerate.com (May 1 close $102.50), markets.businessinsider.com (premarket — flagged as stale Apr 7 data), barchart.com (B4K26 VIX, ESM6, VI*0), cmegroup.com (CSXJ6/CSXK6/CSXM6 swap futures), investing.com (S&P futures hist + Goldman "froth" call), tradingeconomics.com (VIX 16.89 Apr 2026), cboe.com (VIX hist), bbh.com (Drivers Week of May 4: NFP +62K, JOLTS, productivity, RBA, no FOMC), us.econoday.com, mortgageelements.com (May 2026 econ cal), whitehouse.gov (PFEI cal 2026), bls.gov (NFP June 5 schedule, May 4 last update), guggenheiminvestments.com (econ cal), capyfin.com (earnings May 4 BMO: CCBG/BBT/MCB/CATY/HBCP), earningswhispers.com (May 4 confirmed BMO), ainvest.com (May 4 earnings), investing.com earnings (PLTR May 4 AMC, $345B mkt cap), nasdaq.com (earnings), marketchameleon.com (earnings cal), investorsunderground.com (May 4 scan: AI/Nasdaq momentum, INTC/AMSC/BE/GME/TEAM/CAR), wallstreetzen.com (5 stocks May 4: KTB/GILD), youtube/Adam Taggart (overbought-pullback warning), zacks.com (May value picks), stocktitan.net (May gainers), ftportfolios.com (sector YTD thru 3/6: Energy +26.47%, Staples +10.66%, Industrials +9.61%), investing.com analysis (sector rotation: leading Staples/Industrials/Materials/Energy, lagging Tech/Comm/Disc/Financials, XLB cup-handle), schwab.com sector outlook May 1 (6-mo: Energy +30.3%, Materials +17.2%, Industrials +11.4%, Staples +7.7%; Tech 12-mo +52.7%), spglobal.com (Momentum Index), macromicro.me (5-yr cumulative Energy +138%, Tech weight), lazyportfolioetf.com (sector returns thru Apr 30), slickcharts.com (S&P YTD), fidelity.com (sector research), digital.fidelity.com.
- WebSearch fallback used: no

---

## 2026-05-05 — Pre-market Research

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-05-01 (no refresh today, expected — no fills, no reconciliation event since Fri close)
- options_trading_level=3 on the account is irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only) make options unreachable.

### Market Context
- **GEOPOLITICAL SHOCK — Iran attacked UAE on Mon May 4 (Strait of Hormuz crisis re-opens).** UAE Defense Ministry says air defenses engaged **15 missiles + 4 drones**; one drone sparked a fire at a Fujairah oil facility (3 Indian nationals wounded). Fujairah hosts the terminus of UAE's pipeline used to bypass the Strait + extensive oil storage. **US Navy fought back, sinking 6–7 small Iranian boats** targeting civilian ships in the strait. Trump launched **Operation Project Freedom** to escort neutral ships. Iran says the US effort violates the Apr ceasefire. **First UAE attack since the early-April fragile ceasefire took hold.** Wikipedia entry "2026 Strait of Hormuz crisis" already created. Gas prices reported at $4.46 (AAA national avg).
- **WTI: $106.42/bbl close May 4** (+4.0%+ on the day, CNBC confirmed). Sequence: Apr 28 $99.93 → Apr 29 $106.88 → Apr 30 $108.34 → May 1 $102.50 → May 4 **$106.42** (re-spike on UAE attack). Off Mon's pre-Iran ~$101.50 read in yesterday's research — the de-escalation premium that was being taken out has fully reversed in one session.
- **Brent: $114.44/bbl close May 4** (+5.7%+, CNBC confirmed). Brent–WTI spread ~$8 (now closer to normal vs. last Friday's anomalous ~$14).
- **SPX cash: 7,200.75 close May 4** (-0.41% on the day, lines.com / polymarket / multiple CNBC). **First crisp cash print confirmed since Apr 29 7,137.90** — index up ~0.9% in the intervening sessions despite Mon's geopolitical tape. Goldman "froth" call (>7,100 = froth) now further extended; SPX still at/near ATH despite oil-shock close. ESM26 +0.23% premarket Mon (last clean print).
- **VIX: 16.99 close May 4** (CBOE). **Material data anomaly** vs. magnitude of the geopolitical shock — VIX ticked up only ~0.10pt from 16.89 Apr 30 close despite UAE strikes + naval action + 4–6% crude spike. Either (a) market judges the strait-attempt as bounded/contained, (b) options dealers absorbing supply, or (c) intraday VIX print not yet reflecting Mon-night escalation. Calm regime <20 holds *for now* — first sign of breakout above 20 = re-evaluation trigger for any deployment.
- **FOMC carry-over (Apr 29):** held 3.50–3.75% (1 dissenter Miran), Powell flagged Core PCE 3.5% as "elevated", policy "appropriate". Hormuz oil shock is exactly the inflation tail Powell warned about — slightly hawkish-bias rhetoric now reinforced by tape.
- **Today's catalysts (Tue May 5):**
  - **PLTR aftermarket reaction (key tape-setter for AI/data-analytics today).** **PLTR BEAT Q1 2026:** non-GAAP EPS **$0.33** vs. est $0.28; revenue **$1.63B** vs. est $1.54B (**+85% YoY**); net income surged $214M Q1'25 → **$870.5M Q1'26**; **eleven consecutive quarters of accelerating revenue growth**; **management raised both revenue + income full-year guidance**. Rallied ~4% pre-print on positioning; Wedbush Outperform $230 (calls it potential "trillion-dollar AI company"); Oppenheimer initiated Outperform $200. Counter-view (Yahoo Finance): "Prediction: Palantir Stock Is Going to Plunge on May 5" — single contrarian piece, not consensus. Net read: positive AI tape today, single-name binary (not in queue).
  - **JOLTS (March)** — labor-market stabilization read; first week-leg of Fri May 8 NFP setup.
  - **RBA decision** at 2:30 PM AEST — major banks consensus +25bp to **4.35%**; CBA flagged "line ball decision" — not foregone.
  - Iran/Hormuz situation primary live-risk; any fresh escalation = oil-up / risk-off, fresh ceasefire = oil-down / risk-on.
  - BMO earnings: Earnings Whispers May 5 calendar gated behind login; no marquee mega-cap BMO confirmed in unsealed feeds. **Bank of Montreal (BMO ticker) is NOT reporting May 5** — next print May 26 (data quality flag for last week's queue mention).
- **This week — economic calendar (carry-over from Mon):**
  - **Tue May 5:** **JOLTS** (today), **RBA decision** (today), **ISM Services** (week-leg per Godocm).
  - **Wed May 6:** ADP Employment Change (consensus +62K, week feed); National Bank of Poland (hold 3.75%); Norges Bank to hike, Riksbank on hold.
  - **Thu May 7:** **Q1 nonfarm productivity** (consensus +1.0% SAAR vs. Q4 +1.8%); jobless claims (~205K).
  - **Fri May 8:** **April nonfarm payrolls — consensus +62K vs. March +178K, U-rate 4.3% unchanged.** Highest-impact print of the week.
  - **No CPI/PPI/FOMC this week** (CPI/PPI mid-May; next FOMC June).
- **Sector momentum YTD (refreshed May 4–5):**
  - **Energy still leader — now +30.7% YTD** (Investing.com sector rotation; up from +26.47% thru 3/6 FT Portfolios). Hormuz crisis is direct positive catalyst — oil shock → earnings upgrades. Energy + Consumer Staples both at all-time highs.
  - **Materials +15.54% YTD thru 2/10**, **Staples +12.32% YTD**, **Industrials +12.11% YTD** (24/7WallSt cite of broad sector data) — all four cyclical/defensive cohorts double-digit.
  - **2026 leadership has shifted decisively away from 2025 tech-giant momentum** toward Energy + Staples (defensive/cyclical) — Investing.com says markets now rotating from "momentum-based investing" to "fundamental analysis of profitability, margins, FCF growth".
  - Industrials beneficiary of capex into electricity capacity, AI-infra buildout, defense, energy — supports XLI thesis directly.
  - 6-mo trailing reads (Schwab May 1, carried): Energy +30.3%, Materials +17.2%, Industrials +11.4%, Staples +7.7%; XLK 6-mo -7.8%. **Three-day-running thesis (Energy / Industrials / Materials or Staples) intact and reinforced.**

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Posture: Day 7 / Week 2 Day 2; Iran/Hormuz oil shock + PLTR clean beat + Tue–Thu data setup + Fri NFP. Wait-stance reinforced — late entry into oil spike has poor R:R, dovish-NFP path still not de-risked, Goldman froth call still standing.)*

1. **XLE** — Energy +30.7% YTD / +30.3% 6-mo, leader; oil shock direct tailwind. Indicative entry ~$102 (post-spike weakness preferred — chasing $106 WTI = poor R:R), stop ~$92 (-10%), target ~$122 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades this week, ≤20% cap (10 sh ≈ $1,020 = 10.2% equity), sector-momentum aligned, stock — **passes**. **Caveat:** entry into post-spike retracement (oil-down / ceasefire headlines) preferred; chasing into Hormuz tape = buying the spike, which violates patience > activity.
2. **XLI** — Industrials +12.11% YTD / +11.4% 6-mo; defense + AI-infra/power-grid + capex tailwind; defense names benefit directly from sustained Mid-East conflict. Indicative entry ~$162, stop ~$146 (-10%), target ~$194 (+20%), R:R ~2:1. **Passes gate.**
3. **XLB** — *(carried from Mon)* Materials +15.54% YTD / +17.2% 6-mo (Schwab #2 ranked); cyclical/inflation-beneficiary tilt. Indicative entry ~$54, stop ~$48.60 (-10%), target ~$64.80 (+20%), R:R ~2:1. **Passes buy-side gate.** XLP retained as defensive alternate if Hormuz escalates / VIX breaks 20.

### Risk Factors
- **Geopolitical (PRIMARY today):** Iran/Hormuz crisis active, US naval action ongoing, UAE under attack — first since Apr ceasefire. Two-sided live: fresh escalation = oil-up + risk-off + XLE-up but broad market down; ceasefire / Hormuz stabilization = oil-down + XLE-down + risk-on. Hormuz closure scenario is the genuine tail — real-economy hit.
- **Macro / event:** **Friday April NFP** dominant week-risk: +62K consensus vs. +178K prior. Hormuz oil shock complicates Fed dovish-pivot read — Powell's "Core PCE 3.5% elevated + Mid-East energy as inflation driver" framing now directly playing out. JOLTS (today) + ADP (Wed) + Q1 productivity (Thu) provide directional setup.
- **VIX anomaly:** 16.99 close on Mon's UAE-attack tape is mechanically inconsistent — either market judges contained, or print lags. **VIX > 20 is the regime-break trigger** for a re-evaluation of any deployment plan.
- **Sentiment / positioning:** Goldman "froth" call >7,100 still standing (SPX 7,200.75); single contrarian Yahoo "PLTR plunge May 5" call against consensus AI tape. PLTR AMC clean beat externally validates AI-capex narrative for an eleventh consecutive quarter.
- **Sector:** Energy +30%+ YTD even before today's spike — late-cycle leadership signature stretched but reinforced by Hormuz. Tech AI-capex narrative still externally validated (5 mega-caps + PLTR) but momentum has rotated to cyclicals/defensives.
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, MSFT, GOOG, META, AMZN, AAPL, PLTR) all breach 20% cap on $10K — sector ETFs (XLE/XLI/XLB/XLP/SMH) remain the structural fit. PDT room intact (3/5 daytrades).
- **Liquidity:** Tue post-Iran-attack tape, RBA + JOLTS + PLTR-reaction = chop risk; thin-conviction trades typically underperform in oil-shock weeks.
- **Data quality:** PERPLEXITY_API_KEY not set in this routine — fell back to native WebSearch (flagged in Sources). Earnings Whispers May 5 calendar behind login; specific BMO list not unsealed. VIX 16.99 close May 4 sourced; intraday May 5 spot not yet in feeds. SPX cash close May 4 = 7,200.75 (lines.com / polymarket / CNBC concurrence). Brent–WTI spread normalized to $8 (vs. last Friday's anomalous $14 read). Last week's research erroneously listed BMO (Bank of Montreal) tonight — BMO actually reports May 26; correction noted.

### Decision
**HOLD** — Day 7 (Tue, Week 2 Day 2), v1 paper, kill-switch active. Even setting the kill-switch aside, rational stance is **wait** — Iran/UAE/Hormuz tail just expanded, oil already spiked +4–6% in one session (chasing has poor R:R), VIX print mechanically inconsistent with shock magnitude (regime risk under-priced), Fri NFP still not de-risked, PLTR-driven AI tape is single-name not queue. Three-day-running queue **XLE / XLI / XLB** (XLP defensive alternate) carried into v2 market-open. Trades this week: 0/3. Patience > activity.

### Sources
- Perplexity citations: NONE — wrapper exited 3 (PERPLEXITY_API_KEY not set in this routine), fell back to native WebSearch.
- WebSearch fallback used: **YES** (all queries). Sources:
  - cnbc.com (Iran attacks UAE; oil prices today; US sinks Iranian boats; market-news May 4 2026); aljazeera.com (Iran war updates Tehran/Hormuz May 4); ms.now (Iran war live updates May 4); npr.org (US fights to reopen Strait of Hormuz, UAE attacked); cnn.com (US-Iranian militaries trade shots); thehill.com (US-led task force Hormuz reopen); cbsnews.com (US sinks 7 small Iranian boats); cbc.ca (UAE Iran attacks resume); abcnews.com (UAE intercepts missiles drones); en.wikipedia.org ("2026 Strait of Hormuz crisis"); fortune.com (price of oil May 4 2026); oilprice.com (live WTI/Brent); oilpriceapi.com ($110.24 Brent live); fred.stlouisfed.org (DCOILWTICO; VIXCLS); tradingeconomics.com (Brent + WTI commodity; CBOE Volatility VIX 2026 data; US stock market); investing.com (S&P 500 Futures; SPX historical; sector-rotation momentum guide); cnn.com markets/premarkets; barchart.com (ES*0; ESH26); cmegroup.com (E-mini S&P quotes); finance.yahoo.com (^VIX charts/history; ^GSPC history; PLTR; PN/RLYB premarket); cboe.com (VIX tradable products); seekingalpha.com (SP500 historical); polymarket.com (SPX up/down May 4 2026; SPX close Dec 2026); lines.com (SPY closes above 700 May 4); cnbc.com (S&P closes record May 1 oil cools); fool.com (Palantir Q1 2026 transcript; "Just Delivered Another Quarterly Beat" May 4; "May 5 Will Be a Huge Day for PLTR" May 2); bloomberg.com (Palantir Q1 strong revenue outlook); finance.yahoo.com (Palantir Reports Earnings; "Prediction: PLTR going to plunge May 5"); timothysykes.com (PLTR bold targets AI deals); tradingkey.com (PLTR earnings preview $144); tipranks.com (PLTR Q1 Wall Street eyes 115% jump); us.econoday.com (2026 econ cal); bls.gov (May 2026 release schedule; JOLTS schedule); jmdmortgages.com.au (RBA May 5 decision); godocm.com (week ahead May 4 2026: RBA + ISM Services + JOLTS + ADP + jobless claims); fxstreet.com (JOLTS US 2026 cal); rba.gov.au (Coming Up; calendar); fnarena.com (Monday Report May 4 2026); ssga.com (sector tracker); schwab.com (Monthly Stock Sector Outlook 2026); ftportfolios.com (S&P 500 sector commentary); spglobal.com (US Sector Dashboard); finance.yahoo.com (sectors dashboard); insight.factset.com (S&P 500 earnings May 1 2026); 247wallst.com (S&P 500 sectors 2026 May 4); marketchameleon.com (premarket trading; earnings cal); earningswhispers.com (May 5 2026 calendar — gated); marketbeat.com (BMO earnings May 26 2026); nasdaq.com (BMO earnings forecasts); zacks.com (BMO earnings cal); wallstreetzen.com (BMO earnings 2016-2026); seekingalpha.com (BMO earnings); public.com (BMO forecast); coincodex.com (BMO earnings history); stockanalysis.com (premarket movers); benzinga.com (premarket); thestockcatalyst.com (NYSE PM movers); stockmarketwatch.com (premarket); gurufocus.com (PLTR + MU premarket gains); cnn.com (PLTR quote/forecast); cnbc.com (^VX.1 VIX May'26).

---

## 2026-05-05 — Pre-market Research (refreshed)

*Prior 2026-05-05 entry refreshed: Perplexity now reachable (PERPLEXITY_API_KEY set in this routine; prior entry fell back to native WebSearch and flagged the wrapper exit-3). **Key data correction: VIX actually closed 18.51 on May 4 (+8.95% intraday from May 1's 16.99 close), NOT 16.99 as stated in prior entry — the "VIX anomaly / mechanically inconsistent" thesis was based on stale data. VIX did react materially to the Hormuz shock.** Original preserved in git history.*

### Account
- Equity: $10,000.00
- Cash: $10,000.00
- Buying power: $20,000.00
- Daytrade count: 0
- Positions: none | Open orders: none
- balance_asof: 2026-05-01 (no refresh today, expected — no fills, no reconciliation event)
- options_trading_level=3 irrelevant — hard rule "NO OPTIONS" + wrapper kill-switch + buy-side gate (stocks only).

### Market Context
- **Iran/Hormuz UPDATE (Tue May 5):** Ceasefire **on the brink of collapse** (Defense Post May 5, "US-Iran Ceasefire on Brink as UAE Reports Attacks"). Iran officially "**remains committed to ceasefire**" (analyst Zohreh Kharazmi) but parliament speaker blames US for blockade violations; Iran says it will not negotiate until US accepts Iranian control of Hormuz. US "**Project Freedom**" continuing — guided-missile destroyers transiting strait, US-flagged merchant vessels attempting passage; Iran's IRGC disputes commercial transits actually succeeded. UAE intercepted **~12 ballistic missiles + 4 drones + 3 cruise missiles** Mon (numbers slightly higher than prior entry's "15 missiles + 4 drones" — multiple sources reconciling). Net: **no fresh escalation overnight, no formal ceasefire breakdown** — but situation acutely fragile, two-sided binary intact.
- **WTI: ~$105.13/bbl close May 4** (Twelve Data; consistent with prior entry's $106.42 CNBC read — minor source dispersion). **Oil EASING in premarket** (TheStreet May 5: "oil prices were easing as investors watched developments in U.S.-Iran conflict") — early signs of post-spike retracement consistent with the "entry-into-weakness" thesis. Robinhood prediction markets imply **61¢ ≥$102, 0¢ ≥$104** at today's settle (skew strongly suggests $102–104 path, not chase higher).
- **Brent: ~$114.44/bbl close May 4** (carried). Brent–WTI spread ~$8 (normalized).
- **SPX cash: 7,200.75 close May 4** (-0.41% on the day, carried). **ESM26 7,243–7,249 area, +0.18% premarket** (CME Group last update May 5 12:03 UTC; Investing.com 7,249.00). **Dow + S&P futures rising** on US-Iran ceasefire-monitoring tape (Benzinga May 5; TheStreet May 5: "Dow futures rise on Iran war developments"). Goldman "froth" call (>7,100) still standing.
- **VIX: 18.51 close May 4 (+8.95% intraday)** — **CORRECTED** vs. prior entry's 16.99. Day range 17.15–19.08; opened 17.38. May 1 close 16.99 (carried as anchor). VIK26 May futures **19.45** (-6.70% 3M, normal contango compression toward May 19 expiration). **Calm regime <20 still holds, but barely** — VIX > 20 remains the regime-break trigger; Mon's intraday high 19.08 came within 1pt. Prior entry's "VIX anomaly" / "mechanically inconsistent" framing is **withdrawn** — VIX did react proportionally to the shock; the stale 16.99 print was the data error.
- **Today's catalysts (Tue May 5) — refined:**
  - **10:00 AM ET — JOLTS (March)**: BLS confirmed schedule. Feb prior 6.882M (vs. Feb forecast 6.926M, prior 7.240M Jan). Continued labor-market cooling read into Fri NFP.
  - **ISM Services + March Trade Balance**: Saxo Bank Quick Take May 5 lists both as today's macro stack (perplexity econ-calendar query returned uncertain timing — defer to Saxo).
  - **RBA delivered "relatively dovish guidance"** overnight (Saxo) — AUD weaker vs. stronger USD.
  - **PLTR Mon AMC carry-over (already digested):** Beat Q1 2026 — non-GAAP EPS $0.33 vs. $0.28, revenue $1.63B vs. $1.54B (+85% YoY), 11 consecutive quarters accelerating revenue, mgmt **raised both revenue + income guidance**. Wedbush Outperform $230, Oppenheimer initiated Outperform $200. Single-name binary — not in queue.
  - **BMO earnings Tue May 5:** HSBC ($317.62B mkt cap; Q1 rev est $18.55B +5.09% YoY, EPS est $2.17 +11.28%), SUN ($9.34B), AGCO ($8.78B), ATKR ($2.49B), TSAT ($2.48B). **None in XLE/XLI/XLB queue; AGCO is a small-cap industrial machinery name — read-through to XLI minimal.**
  - **Iran/Hormuz situation = primary live-risk** all session.
- **FOMC carry-over (Apr 29):** held 3.50–3.75%, Powell flagged Core PCE 3.5% as "elevated" + Mid-East energy as inflation driver. Hormuz oil shock + 18.51 VIX is exactly the inflation-tail risk Powell warned about.
- **Sector momentum YTD (refreshed May 1 / 5):**
  - **Energy still leader — XLE +32.45% YTD as of May 1** ($SREN 898.26 vs. Jan 2 683.94; per Barchart). Was +14% Feb 12 → +22% Mar 2 → +30.7% May 4 → +32.45% May 1 — **acceleration, not stall**. $SREN -1.32% on May 1 (single-session pullback before Mon's Hormuz spike). Investing.com: dominant 2026 leader, hedge against sticky inflation, fueled by oil + AI power demand + geopolitics.
  - **Materials (XLB)** in leading momentum quadrant; SSGA tracker May 2 shows daily +1.00%; cup-handle setup intact.
  - **Industrials (XLI)** in leading quadrant; capex into electricity / AI infra / defense / energy = direct tailwind from sustained Mid-East conflict.
  - **Consumer Staples (XLP)** in leading quadrant, ATH; Schwab 6-mo +7.2%.
  - **Lagging quadrant unchanged:** Tech, Comm, Consumer Disc, Financials.

### Trade Ideas
*(v1 paper — kill-switch active, documentation only. Posture vs. prior entry: identical queue, but VIX correction tightens the regime-break-trigger calculus — VIX 18.51 close + 19.08 intraday high vs. 20 threshold is now ~1pt away, not >3pt as prior 16.99 read implied.)*

1. **XLE** — Energy +32.45% YTD (refreshed up from +30.7%); leader and accelerating. **Oil easing in premarket** = early post-spike retracement window opening (per Mon's "entry-into-weakness preferred over chase" framing). Indicative entry ~$102 (post-spike retracement zone), stop ~$92 (-10%), target ~$122 (+20%), R:R ~2:1. Buy-side gate: 0/6 positions, 0/3 trades this week, ≤20% cap (10 sh ≈ $1,020 = 10.2% equity), sector-momentum aligned (#1 leader), stock — **passes**. Caveat: if Hormuz re-escalates intraday, oil ramps and entry zone disappears; if ceasefire genuinely holds, oil retraces further toward $90 lower-triangle bound.
2. **XLI** — Industrials in leading quadrant; defense + AI-infra + capex tailwind, sustained Mid-East conflict adds defense kicker. Indicative entry ~$162, stop ~$146 (-10%), target ~$194 (+20%), R:R ~2:1. **Passes gate.**
3. **XLB** — Materials leading quadrant; cup-handle setup, daily +1.00% May 2 (SSGA). Indicative entry ~$54, stop ~$48.60 (-10%), target ~$64.80 (+20%), R:R ~2:1. **Passes buy-side gate.** XLP retained as defensive alternate if Hormuz escalates / VIX breaks 20.

### Risk Factors
- **Geopolitical (PRIMARY):** Iran/Hormuz ceasefire "on the brink" but technically intact; Iran "committed to ceasefire" rhetoric paired with US-Iran armed-shot exchanges = textbook strategic ambiguity. Two-sided live binary: fresh escalation = oil-up + risk-off + XLE-up / broad-tape-down; ceasefire stabilization = oil-down + XLE-down + risk-on. Hormuz closure scenario remains the genuine tail.
- **Macro / event:** **Friday April NFP** dominant week-risk (+62K consensus vs. +178K prior). Today's JOLTS + ISM Services + Trade Balance = three-leg setup. Powell's "Core PCE 3.5% elevated + Mid-East energy as inflation driver" framing now externally reinforced by tape.
- **VIX (CORRECTED):** 18.51 close + 19.08 intraday high May 4 = volatility regime-break **<1pt away from 20 trigger**. Calm regime still holds technically, but margin of safety thin. Any fresh Hormuz escalation likely breaks 20 immediately.
- **Sentiment / positioning:** Goldman "froth" >7,100 call standing (SPX 7,200.75); PLTR clean beat externally validates AI-capex narrative for 11th consecutive quarter, but tape rotation away from tech to cyclicals/defensives intact.
- **Sector:** Energy +32% YTD = late-cycle leadership signature stretched but reinforced by Hormuz. Single-day -1.32% pullback May 1 ($SREN) shows two-sided sensitivity to oil headlines.
- **Idiosyncratic:** AI mega-caps (NVDA, AVGO, MSFT, GOOG, META, AMZN, AAPL, PLTR) all breach 20% cap on $10K — sector ETFs (XLE/XLI/XLB/XLP/SMH) remain the structural fit. PDT room intact (3/5 daytrades).
- **Liquidity:** Tue post-Iran-shot-exchange tape, RBA-dovish + JOLTS + ISM Services = chop risk; thin-conviction trades typically underperform in oil-shock weeks.
- **Data quality:** Perplexity reachable today (key fix vs. prior entry). VIX 18.51 May 4 close confirmed (Investing.com hist + Barchart VIK26 19.45 corroborates); WTI $105.13 (Twelve Data) reconciles with prior $106.42 (CNBC) within source-dispersion. Saxo + Benzinga + TheStreet concur on premarket "futures rising / oil easing" tape. Account `balance_asof` still 2026-05-01.

### Decision
**HOLD** — Day 7 (Tue, Week 2 Day 2), v1 paper, kill-switch active. Refresh does **not** change the decision but does sharpen the rationale: VIX correction reveals real-shock reaction (18.51 vs. stale 16.99), volatility regime-break trigger now <1pt away rather than >3pt; oil easing premarket = post-spike retracement window may open intraday, but Hormuz two-sided binary intact, NFP Fri still un-de-risked, Goldman froth call standing. Three-day-running queue **XLE / XLI / XLB** (XLP defensive alternate) carried into v2 market-open. Trades this week: 0/3. Patience > activity.

### Sources
- Perplexity citations: home.saxo (Market Quick Take May 5: oil + tariff worries, ISM Services + JOLTS + Trade Balance, RBA dovish), benzinga.com (Stock Market Today May 5: Dow + S&P futures rising on US-Iran ceasefire monitoring), thestreet.com (Stock Market Today May 5: Dow futures rise on Iran war developments, oil easing), thedefensepost.com (US-Iran Ceasefire on Brink as UAE Reports Attacks May 5), youtube/MSNBC (Iran-US Ceasefire Over? Deadly Fighting In Hormuz May 5), youtube/Bloomberg (US and Iran Trade Fire in Gulf, Jolting Four-Week-Old Truce May 5), youtube (analyst: Iran remains committed to ceasefire, US blockade), twelvedata.com (WTI hist May 1 $107.65, Apr 30 $111.25, Apr 29 $102.21, Apr 28 $99.29; CL2605 reference), robinhood.com prediction markets (WTI May 5: 61¢ ≥$102, 0¢ ≥$104), fortune.com (price of oil May 1), kalshi.com (WTI weekly range May 8), eia.gov (Brent-WTI spread Q1), fxpro.com (CL2605 specs), cmegroup.com (ESM6 7,243.00 +0.18% May 5 12:03 UTC), investing.com (S&P 500 Futures 7,249.00; VIX hist May 4 18.51 +8.95%, range 17.15–19.08, May 1 16.99; sector rotation momentum guide; energy +22% mid-March), tradingeconomics.com (VIX April monthly 16.89; earnings cal May 5; PCTY est), barchart.com ($SREN performance May 1 -1.32%, 898.26; VIK26 19.45 -6.70% 3M, VXX 28.40, VXZ 55.18; WIK26 spec), macroption.com (VIX expiration May 19 2026), markets.financialcontent.com (Energy dominance: XLE +14% early-2026 → 2026 rotation), schwab.com (Monthly Stock Sector Outlook May 1), spglobal.com (S&P 500 Momentum Index), ssga.com (sector tracker May 2: Energy 59.65 +1.05%, Materials 51.47 +1.00%), stockanalysis.com (earnings cal May 5: 353 names, HSBC/SUN/AGCO/ATKR/TSAT BMO), nasdaq.com (earnings reports), investing.com (earnings cal), marketbeat.com (S&P 500 earnings cal), marketchameleon.com (US Stock Market Earnings Cal), markets.businessinsider.com (Earnings Cal), tradingeconomics.com (Earnings Cal — Open Text, Paylocity), earningswhispers.com (May 5 cal — gated), fxmacrodata.com (USD JOLTS May 5 pre-release), bls.gov (JOLTS Home; JOLTS schedule May 5 10:00 AM; Feb 6.882M), mql5.com (JOLTS 2026), epi.org (JOLTS analysis), cmegroup.com econoday (US JOLTS May 5).
- WebSearch fallback used: **NO** (Perplexity reachable today; correction vs. prior entry which used WebSearch fallback for all queries).

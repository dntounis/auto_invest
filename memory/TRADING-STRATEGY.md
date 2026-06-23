# Trading Strategy (v3 — core-satellite momentum)

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Capital & Constraints
- Starting capital: ~$10,000 (paper in v1)
- Platform: Alpaca
- Instruments: Stocks ONLY
- PDT limit: 3 day trades per 5 rolling business days (account < $25k)

## Portfolio Structure (v3 — core/satellite)
- **ETF core:** ≥45% of *deployed* equity, 2–3 sector ETFs (leading-quadrant rotation). Market-tracking ballast.
- **Single-stock satellites:** ≤3 names, remainder of deployed equity. Alpha sleeve.
- Max 5–6 total positions. Max 2 satellite names per GICS sector.
- **No single GICS sector may exceed 50% of deployed equity** (ETF core + satellites combined) — an aggregate-dollar cap on top of the per-name ≤2-satellites/sector limit, enforced forward-looking by the buy-side gate *(v3.1)*.
- ETF core may never fall below 45% of deployed — market-open refuses a satellite buy that would breach this.

## Hard Rules (non-negotiable)
1. **NO OPTIONS** — ever
2. Maximum 5–6 open positions at a time
3. Maximum 20% of equity per position (~$2,000 on a $10K account)
4. Maximum 5 new trades per week *(v3 — raised from 3; swing entries only, no day-trade impact)*
5. Target 75–85% of capital deployed
6. Every position gets a 10% trailing stop placed as a real GTC Alpaca order. Never mental. *(v2)*
7. Cut any losing position at -7% from entry. Manual sell. No hoping, no averaging down. *(v2)*
8. **Profit ladder (v3 — scale-out + tighter trail).** Tiers below are evaluated at midday; targets come from `scripts/sizing.py ladder`. All scale-outs are partial sells on positions opened ≥1 trading day ago (Rules 14/15 apply).
   - ETF core: +4%→trail 7%; +7%→scale-out 1/3 + trail 5%; +10%→trail 4%; +15%→scale-out 1/3 + trail 3%.
   - Single-stock satellite: +6%→trail 7%; +10%→scale-out 1/3 + trail 6%; +15%→trail 4%; +25%→scale-out 1/3 + trail 3%.
9. Never tighten a stop to within 3% of current price. Never move a stop down. *(v2)*
10. Exit an entire sector after 2 consecutive failed trades in that sector. *(v2)*
11. Follow sector momentum. Don't force a thesis if the whole sector is rolling over.
12. **Patience > activity.** A week with zero trades can be the right answer.
13. **Stops are placed at market close on the entry day, not at entry.** *(v2, visa-aware)* Trailing stops placed at 8:30 CT on T can fire intraday → same-day exit → day trade. PDT designation (4+ day trades in 5 rolling business days) jeopardizes international-student visa status. The `daily-summary` routine (T 15:00 CT, exact market close) places trailing stops for positions opened today. By construction these cannot fire on T (regular session is over and stop orders don't run in extended hours), so the earliest possible exit is T+1 — never a day trade. Intraday T is stop-less; risk is bounded by Rule 3 (20% position cap) and the risk-parity sizing target (2% of equity per trade).
14. **Pre-flight `daytrade_count` check before every sell.** *(v2, visa-aware)* Before placing any sell order — midday hard-close, sector-kill, weekly-review-proposed close, manual `/trade` invocation — the routine MUST read `account.daytrade_count` from Alpaca. If `daytrade_count >= 2`, abort the sell, send a Telegram URGENT alert, and require human review. PDT triggers at 4 in 5 rolling business days; the 2-buffer leaves room for one accidental day trade without immediately blocking all sells. v3 (live) keeps this rule.
15. **Midday hard-close (-7%) and sector-kill skip positions opened today.** *(v2, visa-aware)* Closing a position the same day it was opened is a day trade. Rule 7 (-7% hard close) and Rule 10 (sector-kill on 2 consecutive failures) only act on positions whose entry timestamp is at least one trading day old. A fresh position rides out T stop-less — accepted risk per Rule 13.
16. **Momentum-decay rotation (v3, visa-aware).** At midday, a held position is flagged when it is BOTH below entry AND lagging SPY over the trailing 10 sessions (`scripts/sizing.py decay`). On the *second consecutive* flagged midday, rotate out (T+1 sell). ETFs additionally rotate if the sector exits the leading quadrant. Never acts on a same-day position (Rule 15); aborts if `daytrade_count ≥ 2` (Rule 14). The flag state for each position is recorded in TRADE-LOG.md so the next midday can detect consecutiveness.
17. **Stop-placement-failure escalation (Rule 17, v3.1, operational, visa-neutral).** If a Rule 13 trailing-stop placement fails after 3+ Alpaca write-path retries (any HTTP code — 504s observed 2026-06-16), the routine MUST: (a) send a Telegram **URGENT** alert naming the unprotected ticker, qty, and intended trail; (b) append a `STOP-PLACEMENT-FAILED TICKER QTY TRAIL` row to TRADE-LOG.md; (c) NOT mark the position protected. The next scheduled routine MUST, as its FIRST action before any gating or research, scan for an unresolved `STOP-PLACEMENT-FAILED` marker (one with no later `STOP PLACED` for that ticker) and retry the placement. If the retry also fails after 3+ attempts, escalate with URGENT Telegram instructing manual stop placement via the Alpaca UI. This rule never places or cancels a sell — it is day-trade-neutral.

## Buy-Side Gate
Before placing any buy order, every one of these must pass. If any fail, the trade is skipped and the reason is logged. *(In v1: pre-market filters trade ideas through this gate. v2's market-open enforces it before orders.)*
- Total positions after this fill ≤ 6
- Trades placed this week (including this one) ≤ 5
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- ETF core stays ≥ 45% of deployed equity after this fill (if the idea is a satellite)
- ≤ 2 satellite names in the idea's GICS sector after this fill
- **Sector concentration cap (v3.1):** after this fill, no single GICS sector (ETF core + satellites combined) exceeds **50% of deployed** equity. Formula: `(sector_mv_existing + position_cost) / (long_market_value + position_cost) ≤ 0.50`. Applies to **every** idea (core and satellite). Skip + log if it would breach. Forward-looking only — does not force a sell of existing concentration; that unwinds via Rule 8 scale-outs / Rule 16 rotation.
- **Deployment ceiling (v3.1):** after this fill, capital deployment stays within the Rule 5 band: `(long_market_value + position_cost) / equity ≤ 0.85`. Skip + log if it would overshoot; defer the add until a scale-out, sell, or equity growth restores headroom.
- `daytrade_count` leaves room (PDT: 3/5 rolling business days under $25k)
- A specific catalyst is documented in today's `RESEARCH-LOG.md` entry
- The instrument is a stock (not an option, not anything else)

## Sell-Side Rules *(v3 — evaluated at midday and opportunistically)*
- If unrealized loss is -7% or worse, close immediately.
- If the thesis has broken (catalyst invalidated, sector rolling over, news event), close, even if not yet at -7%.
- Apply the Rule 8 profit ladder (scale-out + tighter trail) per tier; see Rule 8.
- Apply Rule 16 momentum-decay rotation on dead-money laggards.
- If a sector has two consecutive failed trades, exit all positions in that sector.

## Entry Checklist
Before documenting any trade idea in `RESEARCH-LOG.md`:
- What is the specific catalyst today?
- Is the sector in momentum?
- What is the stop level (7–10% below entry)?
- What is the target (minimum 2:1 risk/reward)?

### Single-stock satellite checklist (v3)
- Price above both 50-DMA and 200-DMA (`alpaca.sh bars`)?
- Positive relative strength vs SPY over 10 and 50 sessions?
- Adequate liquidity: average daily volume and a tight quoted spread (also guards against stale-open quotes)?
- Specific catalyst documented (earnings/guidance/upgrade/sector tailwind)?
- Per-idea stop width set (drives risk-parity sizing); R:R ≥ 2:1?

## Strategy Update Cadence
This file is updated **only by the Friday weekly-review routine** (v3), and only if a rule has proven itself for 2+ weeks or failed badly. The pre-market and daily-summary routines read this file but do not modify it.

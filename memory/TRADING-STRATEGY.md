# Trading Strategy

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Capital & Constraints
- Starting capital: ~$10,000 (paper in v1)
- Platform: Alpaca
- Instruments: Stocks ONLY
- PDT limit: 3 day trades per 5 rolling business days (account < $25k)

## Hard Rules (non-negotiable)
1. **NO OPTIONS** — ever
2. Maximum 5–6 open positions at a time
3. Maximum 20% of equity per position (~$2,000 on a $10K account)
4. Maximum 3 new trades per week
5. Target 75–85% of capital deployed
6. Every position gets a 10% trailing stop placed as a real GTC Alpaca order. Never mental. *(v2)*
7. Cut any losing position at -7% from entry. Manual sell. No hoping, no averaging down. *(v2)*
8. Tighten the trailing stop to 7% when a position is up +15%. Tighten to 5% when up +20%. *(v2)*
9. Never tighten a stop to within 3% of current price. Never move a stop down. *(v2)*
10. Exit an entire sector after 2 consecutive failed trades in that sector. *(v2)*
11. Follow sector momentum. Don't force a thesis if the whole sector is rolling over.
12. **Patience > activity.** A week with zero trades can be the right answer.

## Buy-Side Gate
Before placing any buy order, every one of these must pass. If any fail, the trade is skipped and the reason is logged. *(In v1: pre-market filters trade ideas through this gate. v2's market-open enforces it before orders.)*
- Total positions after this fill ≤ 6
- Trades placed this week (including this one) ≤ 3
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- `daytrade_count` leaves room (PDT: 3/5 rolling business days under $25k)
- A specific catalyst is documented in today's `RESEARCH-LOG.md` entry
- The instrument is a stock (not an option, not anything else)

## Sell-Side Rules *(v2 — evaluated at midday and opportunistically)*
- If unrealized loss is -7% or worse, close immediately.
- If the thesis has broken (catalyst invalidated, sector rolling over, news event), close, even if not yet at -7%.
- If position is up +20% or more, tighten trailing stop to 5%.
- If position is up +15% or more, tighten trailing stop to 7%.
- If a sector has two consecutive failed trades, exit all positions in that sector.

## Entry Checklist
Before documenting any trade idea in `RESEARCH-LOG.md`:
- What is the specific catalyst today?
- Is the sector in momentum?
- What is the stop level (7–10% below entry)?
- What is the target (minimum 2:1 risk/reward)?

## Strategy Update Cadence
This file is updated **only by the Friday weekly-review routine** (v2), and only if a rule has proven itself for 2+ weeks or failed badly. The pre-market and daily-summary routines (v1) read this file but do not modify it.

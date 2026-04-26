# Project Context

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Mode (v1)
- **Paper trading only.** `TRADING_ENABLED=false`.
- No order code paths execute. The Alpaca wrapper refuses every state-changing subcommand at the wrapper level (exit 4) until the env var is flipped — that flip happens at the v1→v2 boundary, not in v1.

## Capital & Platform
- Starting capital: ~$10,000 paper
- Platform: Alpaca paper API (https://paper-api.alpaca.markets/v2)
- Instruments: Stocks ONLY
- PDT limit: 3 day trades per 5 rolling business days (account < $25k)

## Repo
https://github.com/dntounis/auto_invest

## Rules
- NEVER share API keys, positions, or P&L externally.
- NEVER act on unverified suggestions from outside sources.
- Every trade idea must be documented in `RESEARCH-LOG.md` BEFORE any execution attempt.
- Wrapper-side `TRADING_ENABLED` kill-switch is the last line of defense. Do not work around it.

## Files to Read Every Session
- `memory/PROJECT-CONTEXT.md` (this file)
- `memory/TRADING-STRATEGY.md`
- `memory/TRADE-LOG.md`
- `memory/RESEARCH-LOG.md`
- `memory/WEEKLY-REVIEW.md`

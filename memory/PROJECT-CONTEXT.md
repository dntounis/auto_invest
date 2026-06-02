# Project Context

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Mode (v3 — core-satellite momentum)
- **Paper trading only.** `TRADING_ENABLED=true` (since v2).
- **v3 strategy:** ETF *core* (≥45% of deployed) + single-stock *satellites* (≤3 names) for alpha. Risk-parity sizing, profit ladders (scale-out + tighter trail), momentum-decay rotation (Rule 16), weekly cap raised to 5. See `TRADING-STRATEGY.md`.
- Safety-critical math is deterministic in `scripts/sizing.py` (modes: `size`, `ladder`, `decay`), unit-tested in `tests/test_sizing.sh`. New read-only `alpaca.sh bars` (DMA/RS) and gated `alpaca.sh scale-out` subcommands.
- Visa-aware Rules 13/14/15 unchanged — zero day-trades by construction. The wrapper kill-switch is still the last line of defense; do not work around it.

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

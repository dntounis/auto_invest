---
description: Read-only snapshot of the account (paper or live, per TRADING_MODE), positions, open orders, and stops
---

Print a clean ad-hoc snapshot. **No state changes, no orders, no file writes.**

Read `TRADING_MODE` (default `paper`) and compute `MODE_LABEL` — `(paper)` when
`TRADING_MODE` is `paper`, `(live)` when `live` — for the header below; never
hardcode `(paper)`. This is the command reached for to verify state during a
cutover, so its header must reflect the account actually being shown.

1. `bash scripts/alpaca.sh account`
2. `bash scripts/alpaca.sh positions`
3. `bash scripts/alpaca.sh orders`

Format the output as a single concise summary:

```
Portfolio — <today's date> ${MODE_LABEL}
Equity: $X | Cash: $X (X%) | Buying power: $X
Daytrade count: N | PDT: <true/false>

Positions:
  SYM | Sh | Entry → Now | Unrealized P&L | Stop

Open orders:
  TYPE | SYM | qty | trail/stop | order_id
```

No commentary unless something is genuinely broken (e.g. a position without a stop, a stop below current price). Keep output ≤ 25 lines.

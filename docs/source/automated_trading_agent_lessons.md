# Important Lessons for an Automated Trading Agent

> This document distills the operational lessons from the Bull Trading Bot screenshot extraction into a practical steering guide for an automated trading agent. It is intended for system design, agent prompting, risk controls, and evaluation. It is **not** financial advice.

---

## 1. Core Agent Philosophy

The trading agent should behave less like a hyperactive day trader and more like a disciplined portfolio operator.

The most important lesson is:

> Follow sector momentum, buy dips in leading sectors, use sufficiently wide trailing stops, hold patiently, avoid options, and trade less than the agent thinks it should.

The agent should optimize for repeatable decision quality, not for activity. Many bad automated trading systems fail because they confuse “doing something” with “improving expected return.” The agent should be explicitly biased toward inaction unless a trade thesis is clear, current, and supported by catalysts.

---

## 2. Scheduling: Split the Trading Day into Distinct Agent Roles

A useful automated trading system should not run one generic “trade now” prompt repeatedly. Each scheduled run should have a different purpose.

### Recommended weekday cadence

| Time | Routine | Primary role | Trading allowed? | Notification behavior |
|---:|---|---|---|---|
| 6:00 AM CT | Pre-market research | Read portfolio, scan catalysts, identify 2–3 actionable ideas | Usually no | Silent unless urgent |
| 8:30 AM CT | Market open | Re-check positions, execute pre-planned trades, set stops | Yes | Notify only if trade placed |
| 12:00 PM CT | Midday scan | Check P&L, evaluate thesis breaks, adjust stops | Yes, mostly exits/risk management | Notify only if action taken |
| 3:00 PM CT | Daily summary | Summarize portfolio, decisions, lessons, and next-day context | Usually no | Send summary |
| Friday close or weekend | Weekly review | Evaluate performance, mistakes, sector behavior, and prompt/rule updates | No, except planning | Send review |

### Design lesson

Each routine should begin by reading the current state and end by writing an updated state. The routines should be narrow, purposeful, and predictable.

---

## 3. Memory Architecture: Files Are the Agent’s Discipline

The source material’s strongest engineering lesson is that an agent needs durable memory outside the model context window. Every scheduled run wakes up relatively stateless, so it must reconstruct the trading context from files.

### Recommended memory files

| File | Purpose |
|---|---|
| `STRATEGY.md` | Stable trading philosophy, allowed instruments, preferred setups, hard constraints |
| `PORTFOLIO.md` | Current holdings, entry prices, thesis, catalysts, stop status, max positions |
| `RESEARCH-LOG.md` | Daily catalyst scans, sector momentum notes, trade ideas, rejected ideas |
| `TRADE-LOG.md` | All executed trades, reason, price, quantity, stop order, outcome |
| `RISK-RULES.md` | Position sizing, stop policy, PDT rules, max loss rules, allowed order types |
| `DAILY-SUMMARIES.md` | End-of-day summaries and next-day watchlist |
| `WEEKLY-REVIEWS.md` | Performance review, lessons, mistakes, rule updates |
| `API-RUNBOOK.md` | Broker endpoints, environment variable names, order schemas, known API gotchas |

### Mandatory run lifecycle

Every scheduled routine should follow this lifecycle:

1. Read `STRATEGY.md`, `PORTFOLIO.md`, `RISK-RULES.md`, and the relevant recent logs.
2. Fetch live account state from the broker.
3. Reconcile file state against broker state.
4. Perform the routine-specific job.
5. Take action only if the action passes the risk rules.
6. Log every decision, including rejected trades.
7. Update the relevant memory files.
8. Notify the user only when the routine’s notification policy says to.

---

## 4. Strategy Lessons: What the Agent Should Prefer

### 4.1 Ride sector momentum

The agent should pay close attention to sector-level strength. In the source material, the profitable trades clustered in the leading sector rather than being evenly spread across many areas.

Operational rule:

> Prefer high-conviction trades in sectors already showing sustained momentum over speculative attempts to bottom-fish weak sectors.

The agent should track:

- Which sectors are leading over multiple time windows.
- Whether current holdings are aligned with those leaders.
- Whether new ideas are trying to fight the prevailing tape.
- Whether a thesis is sector-driven, company-specific, macro-driven, or purely technical.

### 4.2 Buy dips in leading sectors

The agent should distinguish between:

- A pullback inside a strong sector.
- A breakdown in a weak or deteriorating sector.

A dip in a leading sector can be an entry opportunity. A dip in a failing sector is often just weakness continuing.

### 4.3 Concentrate rather than over-diversify

The source notes favor 4–5 meaningful positions rather than 10–15 small ones.

Agent rule:

> The agent should only open a new position if it is strong enough to deserve one of a small number of portfolio slots.

This forces opportunity ranking. The agent should maintain a “replace or ignore” discipline: if the portfolio is at max positions, a new idea must be better than an existing position to justify action.

### 4.4 Patience beats activity

The agent should not equate frequent trades with intelligence. The source material explicitly notes that the best week involved no trades, while the worst week involved heavy trading.

Agent rule:

> Inaction is a valid and often preferred decision. Every trade must overcome friction, slippage, risk, and opportunity cost.

The agent should log “no trade” decisions with the same seriousness as trades.

---

## 5. Risk Lessons: Stops Must Be Real, Wide Enough, and Never Relaxed

### 5.1 Use real broker-side stops, not mental stops

A planned stop that exists only in the agent’s memory is not a stop. The extracted notes emphasize that if a stop is not a GTC order at the broker, it does not exist.

Agent rule:

> Every open position must have an explicit stop-management plan, preferably represented by an actual broker order when allowed.

The agent should verify stops by querying open orders, not by trusting its logs.

### 5.2 Avoid very tight stops

The source material identifies 2–3% stops as too tight because normal volatility can trigger them and prematurely close winners.

Baseline rule from the notes:

> Use a 10% trailing stop as the default, because it gives room for normal volatility while protecting against real breakdowns.

### 5.3 Tighten stops only after meaningful gains

The visible stop-adjustment rules imply a simple ratchet:

- If position is up 15%+, tighten trailing stop to 7%.
- If position is up 20%+, tighten trailing stop to 5%.
- Never tighten a stop to within 3% of the current price.
- Never move a stop down.

This is a strong rule because it encodes asymmetric discipline: protect gains gradually, but never loosen risk after entry.

### 5.4 Cut losers fast

The source uses a -7% loss threshold for manual exits.

Agent rule:

> If a position reaches -7% from entry, exit immediately unless an explicit pre-approved exception exists in `RISK-RULES.md`.

The agent should not “hope,” average down impulsively, or invent a new thesis after the trade starts losing.

---

## 6. Exit Logic: The Agent Needs Clear Sell Signals

The system should define exits before or immediately after entries.

### Automatic exit

- A 10% trailing stop hits → sell via broker.

### Manual/agent-evaluated exits

The agent should consider exiting when:

- Position reaches -7% from entry.
- The original thesis breaks.
- The relevant sector stops working.
- Two consecutive trades fail in the same sector.
- The position is flat for 5+ days with no catalyst.
- A better opportunity appears while the portfolio is already at max positions.

### Thesis-break examples

A thesis break is not merely price noise. It is a factual change that invalidates the reason for owning the position. For example, if an energy trade depends on geopolitical tension and that tension resolves, the thesis may be dead even before price reacts.

Agent instruction:

> The agent must always distinguish between price movement and thesis validity. Price can be noisy; a broken thesis is a reason to exit.

---

## 7. Instrument Discipline: Avoid Complexity the Agent Cannot Reliably Manage

### 7.1 Avoid options unless explicitly enabled

The extracted material gives a strong negative lesson from an options trade that lost heavily and erased stock gains.

Agent rule:

> Do not trade options unless the user has explicitly enabled options and the system has dedicated options-specific risk logic.

For a general-purpose autonomous agent, stocks/ETFs are easier to manage because position risk, stop logic, and broker execution are simpler.

### 7.2 Prefer simple order types

The important order types are:

- `market` for entries when immediate fill is desired.
- `trailing_stop` for automated exit protection.
- `stop` as a fallback when trailing stops are blocked or inappropriate.

The agent should avoid complex order chains unless they are tested and logged.

---

## 8. Broker/API Lessons

### 8.1 Query account state before every action

Before placing trades, the agent should fetch:

- Account equity.
- Cash.
- Buying power.
- Open positions.
- Open orders.
- Day trade count.
- Pattern day trader status.

The agent should never assume its local files are perfectly synced with the broker.

### 8.2 Verify every order after placement

After placing an order, the agent should:

1. Store the request payload.
2. Store the broker response.
3. Query open orders and/or positions to confirm state.
4. Update `TRADE-LOG.md` and `PORTFOLIO.md`.
5. Notify the user if the order was placed, rejected, partially filled, or anomalous.

### 8.3 Treat open orders as part of portfolio state

Stops, limits, and trailing stops are not secondary details. They define the actual risk of the portfolio.

The agent should periodically call:

- `GET /v2/orders?status=open`
- `GET /v2/positions`

Then reconcile:

- Every position has the expected protective order or an explicit reason why not.
- Every protective order corresponds to a current position.
- No stale order remains after a position is closed.

---

## 9. PDT and Execution Gotchas

The extracted notes highlight a practical issue for accounts under $25K: Pattern Day Trader restrictions.

### PDT lesson

- Accounts under $25K have limits on day trades.
- A day trade means buying and selling the same stock on the same day.
- Same-day stop orders may be rejected because triggering them would create a day trade.
- The agent should check `daytrade_count` before trading.

### Agent rule

> Before opening a same-day position, the agent must verify whether protective stops can be placed under the account’s PDT constraints. If not, the trade requires either a safer fallback or no trade.

Possible mitigations:

- Place stops the next day when appropriate.
- Use a stop far enough away that same-day trigger risk is reduced.
- Skip trades when a protective exit cannot be implemented.
- Keep the user informed when PDT blocks risk controls.

---

## 10. Anti-Patterns the Agent Must Avoid

### Overtrading

Bad behavior:

- Opening trades just because a routine fired.
- Chasing every catalyst.
- Replacing positions too often.
- Treating every news item as actionable.

Correct behavior:

- Rank opportunities.
- Demand a clear thesis.
- Prefer no trade when conviction is low.
- Track slippage/friction as real costs.

### Tight stops

Bad behavior:

- Using 2–3% stops in volatile names.
- Getting shaken out by normal volatility.
- Re-entering repeatedly after stop-outs.

Correct behavior:

- Use wider stops consistent with the strategy.
- Tighten only after substantial gains.
- Never move stops down.

### Diversifying into weak sectors

Bad behavior:

- Buying many sectors to appear diversified.
- Entering losing sectors while strong sectors continue to lead.

Correct behavior:

- Track sector momentum explicitly.
- Prefer concentrated exposure to validated leading sectors.
- Exit or pause sectors after repeated failed trades.

### Mental stops

Bad behavior:

- Recording an intended exit in a file but not placing a broker order.

Correct behavior:

- Place real stop/trailing-stop orders when possible.
- Query broker state to verify them.

### Options without dedicated logic

Bad behavior:

- Adding options because they offer leverage.

Correct behavior:

- Ban options unless explicitly enabled and separately risk-managed.

---

## 11. Minimum Guardrails for an Automated Trading Agent

A robust trading agent should have hard constraints that cannot be overridden by routine-level enthusiasm.

Recommended guardrails:

- Paper trade before live deployment.
- No options by default.
- Max 4–5 active positions.
- No trade unless thesis, catalyst, entry, exit, and risk are logged.
- Default 10% trailing stop where allowed.
- -7% loss threshold unless explicitly overridden.
- Never move a stop down.
- Never tighten a stop to within 3% of current price.
- Do not enter a new trade if no protective exit can be implemented.
- Check PDT/day-trade state before opening or closing same-day positions.
- Notify user on trades, rejected orders, missing stops, and risk anomalies.
- Log all actions and non-actions.
- Require weekly review before changing strategy rules.

---

## 12. Suggested Agent Decision Checklist

Before entering a trade, the agent should answer:

1. What is the trade thesis?
2. What is the catalyst?
3. Is the sector showing momentum?
4. Is this a dip in a leading sector or weakness in a losing sector?
5. What is the entry price and intended position size?
6. What is the stop policy?
7. Can the stop actually be placed at the broker?
8. Does PDT/day-trade state allow this trade and its risk controls?
9. Is this better than existing positions if the portfolio is full?
10. What would invalidate the thesis?
11. When should the position be reviewed again?
12. What will be written to the logs?

Before exiting a trade, the agent should answer:

1. Did the stop trigger?
2. Has the position hit -7% from entry?
3. Did the thesis break?
4. Did the sector stop working?
5. Has the position been flat for 5+ days without a catalyst?
6. Is there a better opportunity and no available slot?
7. Are there stale open orders that must be canceled after exit?
8. What lesson should be logged?

---

## 13. Daily Summary Template

The daily summary should be short but information-dense.

```md
# Daily Trading Summary — YYYY-MM-DD

## Portfolio State
- Equity:
- Cash:
- Buying power:
- Open positions:
- Open orders/stops:
- Day trade count:

## Actions Taken
- Buys:
- Sells:
- Stop adjustments:
- Canceled/replaced orders:

## No-Trade Decisions
- Rejected idea 1 + reason:
- Rejected idea 2 + reason:

## Thesis Checks
- Position:
  - Thesis still valid? yes/no
  - Catalyst status:
  - Sector status:
  - Stop status:

## Risk Flags
- Missing stops:
- PDT constraints:
- Concentration concerns:
- API/order anomalies:

## Lessons / Updates
- What worked:
- What failed:
- Rule update proposed? yes/no

## Tomorrow Watchlist
- 1:
- 2:
- 3:
```

---

## 14. Weekly Review Template

The weekly review should focus on improving the agent’s behavior, not just reporting P&L.

```md
# Weekly Trading Review — Week Ending YYYY-MM-DD

## Performance
- Weekly return:
- Benchmark return:
- Relative performance:
- Best position:
- Worst position:

## Trade Quality
- Number of trades:
- Winning trades:
- Losing trades:
- Trades that followed rules:
- Trades that violated or stretched rules:

## Sector Review
- Leading sectors:
- Losing sectors:
- Sectors to avoid next week:
- Sectors with valid dip-buy setups:

## Stop Review
- Stops triggered:
- Premature stop-outs:
- Missing/failed stops:
- Stop adjustments made correctly?

## Behavioral Review
- Did the agent overtrade?
- Did the agent hold winners patiently?
- Did the agent cut losers quickly?
- Did the agent invent new theses after losses?

## Rule Changes Proposed
- Proposed change:
- Evidence:
- Risk of change:
- Accept/reject/defer:

## Next Week Plan
- Max new positions:
- Priority sectors:
- Avoid list:
- Watchlist:
```

---

## 15. Implementation Notes for Agent Prompts

Every trading routine prompt should contain these non-negotiable instructions:

```md
You are an automated trading agent. Before doing anything, read the strategy, portfolio, risk rules, trade log, and recent research logs. Then query the broker account, positions, and open orders. Reconcile broker state against memory files.

Do not trade unless the action passes the risk rules. Prefer no trade when conviction is low. Log all decisions, including rejected trades. After any action, verify broker state and update the relevant memory files.

Never use API keys from files committed to the repository. Use environment variables only. If credentials are missing or broker state cannot be verified, stop and notify the user.
```

For routines that can place trades, add:

```md
Before placing an order, explicitly check buying power, position count, existing exposure, daytrade_count, pattern_day_trader status, and whether a protective stop can be placed. If the stop cannot be placed or verified, do not enter the trade unless the risk rules explicitly allow the fallback.
```

For exit/risk-management routines, add:

```md
For every open position, verify thesis status, P&L from entry, sector status, catalyst status, and protective order status. Exit positions that hit sell criteria. Never move a stop down. Cancel stale orders after closing a position.
```

---

## 16. Best Single-Sentence Operating Policy

> The agent should be a patient, catalyst-aware, sector-momentum follower with real broker-side risk controls, strict loss cutting, wide trailing stops, low trade frequency, and persistent memory of every decision.

---

## 17. Highest-Priority Lessons to Encode as Hard Rules

1. **No trade is better than a weak trade.**
2. **Stops must be real broker orders, not memory-file intentions.**
3. **A 10% trailing stop is the default risk-control primitive unless the strategy file says otherwise.**
4. **Never move stops down.**
5. **Cut losers around -7% rather than waiting and hoping.**
6. **Let winners run; tighten stops only after meaningful gains.**
7. **Avoid options unless the system is specifically designed for options.**
8. **Avoid overtrading; every trade pays friction.**
9. **Favor leading sectors and avoid diversifying into weakness.**
10. **Check PDT constraints before opening positions or placing protective exits.**
11. **Reconcile memory files with broker truth every run.**
12. **Write down what happened so the next run can inherit discipline.**

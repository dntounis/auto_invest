# auto_invest v2 — Execution Layer Design (DRAFT)

**Status:** DRAFT — not yet brainstormed with user. Contains `OPEN DECISION` markers where dialogue is required before implementation. Do not start the writing-plans phase until every `OPEN DECISION` block is resolved.

**Author:** Claude (drafted 2026-05-04 while v1 criterion #1 still pending — 3/5 clean cron weekdays).

**Predecessor:** `docs/superpowers/specs/2026-04-25-auto-invest-design.md` (v1 spec; v1 § 11 is the v2 baseline).

---

## 1. Goal

Add the **execution layer** on top of v1's research layer. v1 produces `RESEARCH-LOG.md` entries with 2–3 actionable trade ideas per day; v2 actually places paper orders for them, manages stops, and grades itself weekly.

Still paper. Still no options. Still ≤$10K. The kill-switch flips OFF (`TRADING_ENABLED=true`) only after every v1 exit criterion is closed.

**v2 success looks like:** the bot runs autonomously for 2 weeks of paper trading, every position has a real Alpaca trailing-stop GTC order, no rule violations land in `TRADE-LOG.md`, and the Friday weekly-review actually grades performance and proposes strategy refinements.

---

## 2. Confirmed decisions (carried from v1 § 11)

1. **Three new routines** added on top of v1's two:
   - `routines/market-open.md` — cron `30 8 * * 1-5` America/Chicago (08:30 CT = market open + 30 min equilibration)
   - `routines/midday.md` — cron `0 12 * * 1-5` America/Chicago
   - `routines/weekly-review.md` — cron `0 16 * * 5` America/Chicago (Friday 4 PM, after market close)

2. **Local mirrors** in `.claude/commands/`:
   - `market-open.md`, `midday.md`, `weekly-review.md`, `trade.md` (one-off ad-hoc trade entry)

3. **`TRADING_ENABLED=true`** in all routine envs. Wrapper kill-switch in `scripts/alpaca.sh` then permits `order`, `cancel`, `cancel-all`, `close`, `close-all` subcommands.

4. **`TRADING-STRATEGY.md` becomes write-eligible only by `weekly-review`.** Other routines read it but never modify it.

5. **All hard rules from `TRADING-STRATEGY.md` enforce server-side at market-open and midday.** No mental stops. No "I'll watch this position." Every safety rail is a real Alpaca order or a wrapper-side guard.

6. **TRADE-LOG.md schema** for trade rows (already defined at top of file, but unused in v1) goes live in v2.

---

## 3. Architecture

### Daily flow (Mon–Thu)

```
06:00 CT  pre-market        reads strategy + memory, runs Perplexity, writes RESEARCH-LOG entry with 2-3 trade ideas (or HOLD)
08:30 CT  market-open       reads today's RESEARCH-LOG, applies buy-side gate, places limit orders + GTC trailing stops; Telegram on each fill or reject
12:00 CT  midday            reads positions, checks unrealized P&L vs hard rules; tightens stops at +15%/+20%; closes losers at -7%; Telegram if action taken
15:00 CT  daily-summary     EOD snapshot with realized + unrealized P&L, fills, position table; Telegram once
```

### Friday extension

```
06:00 CT  pre-market        same as above (still produces ideas; market-open may consume them or skip into Friday close)
08:30 CT  market-open       same
12:00 CT  midday            same
15:00 CT  daily-summary     same
16:00 CT  weekly-review     reads week's RESEARCH-LOGs + TRADE-LOGs, grades the bot, optionally proposes TRADING-STRATEGY edits
```

### Trade lifecycle (one position)

```
1. pre-market T:    idea written to RESEARCH-LOG (TICKER, entry, stop, target, R:R, catalyst)
2. market-open T:   buy-side gate validates → limit order placed @ ask + slippage budget → Alpaca trailing-stop GTC stop placed once filled
3. midday T..T+N:   position health checked daily; stop tightened on gains; closed on -7% loss or thesis break
4. exit:            stop fires automatically OR midday closes manually; exit row appended to TRADE-LOG
5. weekly-review F: trade graded (win/loss, hit ratio, R:R realized, rule adherence)
```

### State boundaries

- **Source of truth for positions:** Alpaca account (`bash scripts/alpaca.sh positions`).
- **Source of truth for orders:** Alpaca account (`bash scripts/alpaca.sh orders`).
- **Source of truth for narrative + decisions:** `memory/TRADE-LOG.md`, `memory/RESEARCH-LOG.md`, `memory/WEEKLY-REVIEW.md` — all append-only, all on `main`.
- **No local state files.** Every routine starts from a fresh clone + a fresh Alpaca state pull.

---

## 4. Open decisions (REQUIRES BRAINSTORMING)

These are the design questions the brainstorming dialogue must answer before writing-plans can run. Each block has my recommendation + the alternatives I considered. Treat my recommendation as a starting position to either confirm or push back on.

### OPEN DECISION A — Stop-loss implementation

**Strategy says:** "Every position gets a 10% trailing stop placed as a real GTC Alpaca order. Never mental." (`TRADING-STRATEGY.md` rule 6)

Three options:

1. **Pure server-side trailing stops.** Place a `trailing_stop` GTC order with Alpaca right after entry fills. Alpaca tracks the high-water mark and fires automatically. Tightening on +15%/+20% gains requires `cancel` + new `trailing_stop` order at narrower trail.
2. **Computed each midday.** Read current price + entry, compute stop level, place a fixed `stop` GTC order, replace daily.
3. **Hybrid.** Server-side `trailing_stop` for the safety net; midday recomputes and adjusts only when crossing tightening thresholds.

**Recommendation:** Option 1 (pure server-side trailing stops). Rationale: matches strategy text literally ("real GTC Alpaca order"), survives between routine fires, doesn't depend on midday running successfully. Tightening at +15%/+20% becomes a `cancel` + `re-place` operation in midday — straightforward.

**Action item if Option 1 chosen:** add `trailing-stop` subcommand to `scripts/alpaca.sh` (Alpaca API supports `type=trailing_stop` with `trail_percent` field).

### OPEN DECISION B — Order type for entries

Three options:

1. **Market orders.** Guarantee fill; accept slippage.
2. **Limit at the ask.** No slippage; might miss fast-moving stocks.
3. **Limit at ask + small slippage budget** (e.g., +0.10% above current ask). Compromise.

**Recommendation:** Option 3 with a `MAX_ENTRY_SLIPPAGE_PCT` env var (default 0.10%). Rationale: paper-trading slippage is fictional anyway, but Option 3 keeps the same code path that v3 (live) will use safely, and avoids accidentally blowing past the 20%-per-position cap if a market order fills at a much higher price than expected.

### OPEN DECISION C — How many of pre-market's ideas to execute

Pre-market produces 2–3 ideas (or HOLD). At market-open, when ideas exist:

1. **All ideas that pass the buy-side gate.** Could be 2–3 buys in one morning; bumps against "max 3/week" cap fast.
2. **Top-conviction only.** Pre-market would need to rank ideas; pick #1.
3. **Up to N where N respects the weekly trade budget.** E.g., if 2 trades already this week, place at most 1 more today even if 3 ideas pass the gate.

**Recommendation:** Option 3. Rationale: respects the existing weekly cap as a hard constraint, doesn't require pre-market to do conviction ranking (it currently doesn't). Selection rule when N < ideas-passing-gate: take the highest-R:R idea first. Tie-breaker: alphabetical ticker.

### OPEN DECISION D — Position sizing

Strategy: "Maximum 20% of equity per position (~$2,000 on a $10K account)."

Three sizing rules:

1. **Always exactly 20%.** Predictable; max diversification at 5 positions.
2. **Sized by R:R.** Higher R:R → larger position. Variable; harder to reason about.
3. **Risk-parity sizing.** Size such that the stop distance × shares = a fixed dollar risk per trade (e.g., $200 = 2% of $10K). Variable position size, fixed risk.

**Recommendation:** Option 3 with `RISK_PER_TRADE_PCT` env var (default 2.0% = $200). Rationale: this is the textbook approach — fixed-risk, variable-size — and it makes the stop distance directly meaningful. A tight 5%-stop trade gets a $4K position (capped at 20% = $2K so really $2K); a wide 10%-stop trade gets a $2K position. Both risk $200 if stopped out. Capped at 20% per `TRADING-STRATEGY.md` rule 3.

**Worth pushing back on if:** user prefers Option 1's simplicity for v2 launch and wants Option 3 deferred to v2.5.

### OPEN DECISION E — Midday triggers and actions

Midday runs at 12:00 CT every weekday. What it does:

1. Pull positions, current quotes, open stop orders.
2. For each position: compute unrealized P&L %, check thresholds.
3. **Hard exits (always close):** unrealized loss ≤ -7% (rule 7). This means a `close` order at market, even though the trailing stop would eventually fire wider.
4. **Stop tightening:** at +15% gain → re-place trailing stop with `trail_percent=7`. At +20% → `trail_percent=5`.
5. **Sector kill:** if `TRADE-LOG.md` shows 2 consecutive losses in a sector, close all open positions in that sector (rule 10).
6. **Telegram:** silent if no action; one message summarizing actions taken if any. URGENT prefix on hard exits.

**OPEN sub-questions:**
- How does midday detect "thesis broken" (rule from sell-side)? Recommendation: out of scope for midday — relies on pre-market to flag thesis breaks in next morning's research, then midday acts. v2.5 could add a Perplexity check on each held ticker.
- What's the failure mode if midday can't reach Alpaca? Recommendation: Telegram alert with `URGENT` prefix, do nothing else, exit. Trailing stops still in place server-side.

### OPEN DECISION F — Sell-side: midday hard exits vs trailing stops

Tension: rule 7 says "Cut any losing position at -7%". Rule 6 says "10% trailing stop". A 10% trail can let a position drop to -10% from the high before firing. If a position drops -7% from entry without ever ticking up, the trailing stop hasn't moved and won't fire at -7%.

Three resolutions:

1. **Hard -7% stop on entry.** Place a `stop` GTC at -7% from entry alongside the trailing stop. Whichever fires first wins.
2. **Midday checks unrealized P&L vs entry.** If ≤ -7%, market-close immediately, ignore trailing stop.
3. **Both.** Belt-and-suspenders.

**Recommendation:** Option 2. Rationale: keeps order book clean (one stop per position, not two), gives midday a real job, matches the strategy text ("Cut losers at -7% manually"). Risk: a -8% gap between midday firings goes undefended. Acceptable for paper; revisit in v3.

### OPEN DECISION G — Weekly-review: write-eligible to TRADING-STRATEGY?

Original v1 spec § 12 deferred this question. Two paths:

1. **Auto-edit:** weekly-review can directly edit `TRADING-STRATEGY.md`, commit, push. Friday afternoons mutate the rulebook.
2. **Propose-only:** weekly-review writes proposals to `WEEKLY-REVIEW.md` + sends a Telegram with the proposed diff. Human applies (or rejects) by hand on Saturday morning.

**Recommendation:** Option 2 for v2. Rationale: the rulebook is the safety system. An autonomous bot mutating its own safety rules is the kind of thing that creates the next post-mortem. Option 1 becomes considerable in v3 once the trust history is longer.

### OPEN DECISION H — Idempotency on rerun

What happens if `market-open` fires twice on the same morning (cron + manual run-now)?

1. **Strict idempotency:** routine reads today's open orders + fills BEFORE placing anything; if a buy for ticker X is already open or filled today, skip.
2. **Naive replay:** routine just runs again, possibly placing duplicate orders.
3. **Lock file in repo:** routine writes a date-stamped lock file at start; refuses to run if a lock for today's date exists.

**Recommendation:** Option 1. Rationale: the routine has read access to Alpaca state — it should USE that state to decide whether work is already done. Lock files via git commits are racy and brittle.

### OPEN DECISION I — Trade-row schema in TRADE-LOG.md

Schema already exists at top of `TRADE-LOG.md` (defined in v1 for v2 use):

```
### YYYY-MM-DD — TRADE: TICKER side=buy|sell qty=N
- Entry: $X (or Exit: $X)
- Stop level: $X (trailing N% / fixed $X)
- Thesis: ...
- Catalyst: ... (link to RESEARCH-LOG entry)
- Target: $X (R:R X:1)
- Realized P&L (on exits only): $X
```

Open question: how to link a trade row to its RESEARCH-LOG idea? Three options:

1. **By date:** "see 2026-05-04 entry" — fuzzy if multiple ideas.
2. **By idea ID:** add `id: pm-2026-05-04-XLE-1` to RESEARCH-LOG ideas; reference it in trade rows.
3. **By idea hash:** ticker + date.

**Recommendation:** Option 3 (`pm-YYYY-MM-DD-TICKER`). Rationale: simple, deterministic, no schema change to RESEARCH-LOG. Ambiguous only if pre-market generates two ideas for the same ticker same day, which violates max-1-position-per-ticker anyway.

### OPEN DECISION J — Telegram message volume in v2

v1 sends ~1 Telegram per weekday (EOD). v2 message budget:

- Pre-market: silent (unchanged).
- Market-open: 1 message per fill or reject (typical: 0–2/day).
- Midday: silent unless action taken (typical: 0–1/day).
- Daily-summary: 1/day (unchanged but richer content).
- Weekly-review: 1/Friday with grade card.

**Estimated weekly volume:** 5 (EOD) + 0–10 (market-open fills) + 0–5 (midday actions) + 1 (Fri review) = ~6–21/week. Acceptable.

**OPEN sub-question:** should there be a daily heartbeat from market-open even when no orders placed (e.g., "market-open ran, 0 ideas executed today, 2 positions held")? My instinct: no — `git log` is the heartbeat.

---

## 5. Repository layout additions

```
routines/
  market-open.md        NEW
  midday.md             NEW
  weekly-review.md      NEW
  pre-market.md         (v1, prompt may expand to reference v2 schema)
  daily-summary.md      (v1, prompt expands to include positions/fills/P&L)
  README.md             (update setup section for new routines)
.claude/commands/
  market-open.md        NEW
  midday.md             NEW
  weekly-review.md      NEW
  trade.md              NEW (one-off manual trade entry, mirrors market-open's flow)
scripts/
  alpaca.sh             EDIT — add `trailing-stop` subcommand; possibly `replace-stop`
                        (cancel + re-place atomic helper)
memory/
  TRADE-LOG.md          (schema activated; existing v1 entries unchanged)
  WEEKLY-REVIEW.md      (template activated)
docs/superpowers/specs/
  2026-05-04-auto-invest-v2-design.md   (this file, after brainstorming → committed final)
docs/superpowers/plans/
  2026-05-XX-auto-invest-v2.md          (writing-plans output)
```

---

## 6. Wrapper additions (`scripts/alpaca.sh`)

New subcommands needed:

- **`trailing-stop <ticker> <qty> <trail_percent>`** — place a sell-side trailing stop GTC order. Requires `TRADING_ENABLED=true`.
- **`replace-stop <order_id> <new_trail_percent>`** — cancel an existing stop + re-place at new trail. Atomic from caller's perspective; in practice it's `cancel` then `trailing-stop`.
- **`activities [date]`** — fetch fills + non-trade activities for a given date (defaults to today). Used by daily-summary for realized P&L.

All three go through the same kill-switch gate (`require_trading_enabled` for state-changing ones; `activities` is read-only).

Existing subcommands untouched: `account`, `positions`, `position`, `quote`, `orders`, `order`, `cancel`, `cancel-all`, `close`, `close-all`.

---

## 7. Routine prompt structure (each new routine)

Each new routine prompt follows the same template as v1's `pre-market.md`/`daily-summary.md`:

1. **Hard rules block** at the top (paper, no options, ultra-concise)
2. **OVERRIDE — Branch Policy** block (push to `main`, ignore Anthropic's `claude/*` directive)
3. **Date resolution** with `TZ=America/Chicago` (carried over from v1 fix `131d526`)
4. **IMPORTANT — ENVIRONMENT VARIABLES** block (include all required env vars; STOP + Telegram-alert if any missing; sanity check `ALPACA_ENDPOINT` contains `paper-api`; refuse `.env` creation)
5. **IMPORTANT — PERSISTENCE** block (fresh clone, must commit + push)
6. **IMPORTANT — KILL SWITCH** block
   - In v2 with `TRADING_ENABLED=true`, the kill-switch is OFF — wrappers will execute orders. The hard rules of `TRADING-STRATEGY.md` are now the only line of defense.
   - For market-open and midday, this block must explicitly remind the agent: "do not bypass the buy-side gate; do not place orders for ideas that fail the gate."
7. **STEP 1..N** with concrete commands and exact file paths
8. **STEP N — COMMIT AND PUSH** (mandatory)

### market-open prompt skeleton

```
STEP 1 — Read memory: TRADING-STRATEGY.md (rules), today's RESEARCH-LOG.md entry (ideas)
STEP 2 — Pull state: account, positions, orders, daytrade_count
STEP 3 — Apply buy-side gate to each idea (skip with logged reason on failure)
STEP 4 — Compute position sizes per OPEN DECISION D
STEP 5 — Place limit orders per OPEN DECISION B; wait for fills (poll up to 60s)
STEP 6 — On each fill: place trailing-stop GTC (per OPEN DECISION A)
STEP 7 — Append trade rows + initial stop info to TRADE-LOG.md (schema per OPEN DECISION I)
STEP 8 — Send Telegram per OPEN DECISION J: one msg per fill or reject
STEP 9 — Commit + push to main
```

### midday prompt skeleton

```
STEP 1 — Read memory: TRADING-STRATEGY.md (sell-side rules), tail of TRADE-LOG.md (entries + stops + sector tally)
STEP 2 — Pull state: positions, current quotes, open stop orders
STEP 3 — For each position: compute unrealized P&L %, check thresholds (per OPEN DECISIONS E + F)
STEP 4 — Take actions: hard-close losers; tighten stops on gains; sector-kill on 2-loss streak
STEP 5 — Append action rows to TRADE-LOG.md (sells = exit rows with realized P&L)
STEP 6 — Send Telegram per OPEN DECISION J: silent if no action, one summary if any
STEP 7 — Commit + push to main (skip if no changes)
```

### weekly-review prompt skeleton

```
STEP 1 — Read memory: TRADING-STRATEGY.md, this week's RESEARCH-LOG.md entries (Mon-Fri), this week's TRADE-LOG.md entries
STEP 2 — Pull state: account, positions, fills via `activities`
STEP 3 — Compute weekly grade card:
  - Trades placed (target ≤3)
  - Win/loss ratio
  - Realized + unrealized P&L for the week
  - R:R realized vs target on each closed trade
  - Sector-level summary
  - Rule violations (e.g., did any position exceed 20%? did midday miss a -7% close?)
STEP 4 — Append week summary to TRADE-LOG.md (use schema TBD during brainstorming)
STEP 5 — Append entry to WEEKLY-REVIEW.md including any proposed strategy mutations
STEP 6 — Telegram: send the grade card (1 message)
STEP 7 — Per OPEN DECISION G: do NOT auto-edit TRADING-STRATEGY.md; propose via WEEKLY-REVIEW + Telegram
STEP 8 — Commit + push to main
```

---

## 8. Wrapper test plan additions

Each new alpaca.sh subcommand needs:

1. **Kill-switch test:** with `TRADING_ENABLED` unset, exit 4.
2. **Missing-arg test:** with no ticker/qty, exit 1 with usage message.
3. **Happy-path test:** mock the Alpaca endpoint (or hit paper sandbox), assert the request payload matches Alpaca API docs.

These extend the existing test pattern in v1's `tests/test_alpaca.sh`.

---

## 9. Bootstrap order (for the v2 implementation plan)

1. Resolve every OPEN DECISION via brainstorming.
2. Write the v2 implementation plan with writing-plans.
3. Wrapper changes first (new alpaca.sh subcommands + tests). No routine touches Alpaca state-changing endpoints until the wrapper supports them safely.
4. Local mirrors (`.claude/commands/*.md`) before cloud routines — test interactively with the kill-switch still ON.
5. Flip `TRADING_ENABLED=true` ONE routine at a time, smoke-test with Run now, observe one cron firing before adding the next routine.
6. Order of routine activation: `market-open` → `midday` → `weekly-review`. (Each builds on the prior week's data.)
7. v2 exit criteria observation period.

---

## 10. v2 exit criteria

System is v2-stable when **all** observed (refined from v1 § 11):

1. All five routines fire successfully on cloud cron for **2 consecutive weeks** (10 weekdays) with no manual intervention.
2. Every position held at any point during the observation window had a real trailing-stop GTC order present (verifiable in `bash scripts/alpaca.sh orders` history).
3. No `TRADING-STRATEGY.md` rule was violated (audit by re-reading `TRADE-LOG.md`).
4. Midday took the right action on every threshold cross (≥-7% loser closed; +15%/+20% stops tightened); auditable from order history vs price history.
5. Weekly-review actually graded the bot both weeks (not just "no trades, no comment").
6. Zero `.env` files in the cloud clone (carry-forward from v1 #5).
7. No Alpaca API errors propagated to Telegram URGENT alerts that required human cleanup (transient errors with successful retry don't count).

Then v3 (live) becomes its own design discussion.

---

## 11. Out of scope for v2

- Live trading (v3)
- Options (banned forever)
- Crypto, forex, futures
- After-hours / pre-market trading (only RTH 9:30 ET → 4:00 ET)
- Multi-strategy portfolios (one bot, one strategy)
- Backtesting infrastructure
- Web UI / mobile app
- Auto-mutating `TRADING-STRATEGY.md` (deferred per OPEN DECISION G)
- Perplexity-driven thesis-break detection on held positions (deferred to v2.5 per OPEN DECISION E)

---

## 12. Notes for the brainstorming session

When the user pings to start brainstorming (after v1 criterion #1 closes):

1. Walk OPEN DECISIONS A–J in order. Each is a single multiple-choice question plus my recommendation.
2. After each decision, replace the OPEN DECISION block with a **DECIDED** block stating the chosen option and any user-provided rationale.
3. Once all decisions are DECIDED, run the spec self-review (placeholder scan, internal consistency, scope check).
4. Then transition to writing-plans.

Estimated brainstorming time: ~30 minutes (10 decisions × ~2–3 minutes each, mostly user confirming recommendations).

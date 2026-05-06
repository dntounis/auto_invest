# auto_invest v2 — Execution Layer Design (LOCKED)

**Status:** LOCKED 2026-05-05 after brainstorming dialogue. All decisions DECIDED. Visa-aware safety rules added (Rules 13–15 in `TRADING-STRATEGY.md`). Ready for writing-plans.

**Author:** Claude (drafted 2026-05-04 while v1 criterion #1 still pending — 3/5 clean cron weekdays; locked 2026-05-05 after brainstorming).

**Predecessor:** `docs/superpowers/specs/2026-04-25-auto-invest-design.md` (v1 spec; v1 § 11 is the v2 baseline).

**Critical user constraint:** International student visa. PDT designation (4+ day trades in 5 rolling business days) creates visa risk. The design avoids day trades by construction (stop placement timing + same-day gating on hard-closes) plus a runtime pre-flight on `daytrade_count`.

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
08:30 CT  market-open       reads today's RESEARCH-LOG, applies buy-side gate, places limit-with-slippage entry orders; NO stop placed today (visa-aware)
12:00 CT  midday            reads positions, checks unrealized P&L vs hard rules; tightens stops at +15%/+20%; closes losers at -7%; sector-kill on 2 failures
                            ALL same-day-skip gated (positions opened today are not eligible for any close action)
                            ALL sells gated by daytrade_count pre-flight (abort + URGENT Telegram if >= 2)
15:00 CT  daily-summary     EOD snapshot with realized + unrealized P&L; PLACES trailing-stop GTC for any positions opened today (post-close, can't fire same-day)
                            Sends one EOD Telegram message per day; fires the 48h-silence heartbeat if applicable
```

### Friday extension

```
06:00 CT  pre-market        same as above
08:30 CT  market-open       same
12:00 CT  midday            same
15:00 CT  daily-summary     same
16:00 CT  weekly-review     reads week's RESEARCH-LOGs + TRADE-LOGs, grades the bot, proposes TRADING-STRATEGY edits to Telegram (never auto-applies)
```

### Trade lifecycle (one position)

```
1. pre-market T:    idea written to RESEARCH-LOG (id pm-T-TICKER; TICKER, entry, stop, target, R:R, catalyst)
2. market-open T:   buy-side gate validates → limit order @ ask × (1 + MAX_ENTRY_SLIPPAGE_PCT) → wait for fill (poll up to 60s)
3. (intraday T):    position is stop-less; bounded by Rule 3 (20% cap) + risk-parity sizing (2% of equity = ~$200 expected loss)
4. daily-summary T: trailing-stop GTC placed at 15:00 CT (= 16:00 ET = market close); cannot fire same-day, queues for T+1
5. midday T+1..N:   position health checked daily; stop tightened on +15%/+20% gains via cancel + re-place trailing stop; closed on -7% loss or thesis break
6. exit:            stop fires (T+1+ only) OR midday closes manually (T+1+ only) → exit row appended to TRADE-LOG with realized P&L
7. weekly-review F: trade graded (win/loss, hit ratio, R:R realized, rule adherence, day-trade count delta)
```

### State boundaries (unchanged from v1)

- Source of truth for positions: Alpaca (`bash scripts/alpaca.sh positions`)
- Source of truth for orders: Alpaca (`bash scripts/alpaca.sh orders`)
- Source of truth for `daytrade_count`: Alpaca (`bash scripts/alpaca.sh account` — the field is in the JSON response)
- Source of truth for narrative: append-only memory files on `main`

---

## 4. Locked decisions (DECIDED 2026-05-05)

All decisions resolved during brainstorming. Each block records the chosen option + rationale.

### DECIDED A — Stop-loss implementation: server-side trailing stops, placed at daily-summary on T

**Choice:** Pure server-side `trailing_stop` GTC orders. Placed by the `daily-summary` routine at 15:00 CT (= market close on T) for any positions opened today. Positions opened on prior days have their stops already in place from their own daily-summary run.

**Why:** Matches strategy Rule 6 literally ("real GTC Alpaca order, never mental"). Placement at market close ensures the stop cannot fire same-day (regular session is over; stop orders don't run in extended hours), eliminating the day-trade vector while still giving overnight protection. Tightening on +15%/+20% gains is a `cancel` + re-place at narrower trail, run by midday on T+1 onward.

**Action items:**
- Add `trailing-stop <ticker> <qty> <trail_percent>` subcommand to `scripts/alpaca.sh` (POST `/v2/orders` with `type=trailing_stop`, `trail_percent=N`, `time_in_force=gtc`, `extended_hours=false`).
- Add `replace-stop <order_id> <new_trail_percent>` helper (`cancel` + `trailing-stop`).

### DECIDED B — Order type for entries: limit @ ask + 0.10% slippage budget

**Choice:** Limit orders priced at `ask × (1 + MAX_ENTRY_SLIPPAGE_PCT)`. Default `MAX_ENTRY_SLIPPAGE_PCT=0.10%`, settable via env var.

**Why:** Same code path as v3 (live) will use safely. Bounds slippage to a known cap; refuses to fill on a fast-moving stock that's run away from the idea's entry price. Avoids accidentally blowing past the 20% position cap.

### DECIDED C — Idea selection: up to N respecting weekly cap, ranked by R:R

**Choice:** At market-open, rank passing ideas by R:R (descending), tie-breaker alphabetical ticker. Place the top `min(passing_ideas, weekly_cap_remaining)` orders.

**Why:** Respects the existing 3/week cap. Highest-conviction-first is approximately R:R-first.

**Visa-aware addition:** market-open never closes a position (entries only). Therefore market-open cannot itself create a day trade. The `daytrade_count` pre-flight (Rule 14) gates only sells.

### DECIDED D — Position sizing: risk-parity (2% risk per trade, 20% cap)

**Choice:** Size each position so that `(entry_price - stop_price) × shares = RISK_PER_TRADE_PCT × equity`. Default `RISK_PER_TRADE_PCT=2.0` (= $200 risk on $10K equity). Hard-capped at 20% of equity per position (Rule 3).

**Why:** Textbook fixed-risk variable-size sizing. Stop distance becomes economically meaningful: a tight-stop trade gets more shares, a wide-stop trade gets fewer, both risk the same dollars on stop-out.

**Stop_price for sizing:** the entry-day risk uses the trail percent target (default 10% trail = stop at entry × 0.90). Once midday tightens the trail, position size is unchanged; only the dollar-risk profile narrows.

### DECIDED E — Midday triggers: hard-close losers, tighten stops, sector-kill (all same-day-skip gated)

**Choice:** At 12:00 CT, midday:
1. Pulls positions, current quotes, open stop orders, `account.daytrade_count`.
2. For each position with `entry_date < today` (visa gate, Rule 15):
   - **Hard-close** if unrealized P&L ≤ -7% (Rule 7) → market sell, after `daytrade_count` pre-flight.
   - **Tighten** trailing stop to 7% trail at +15% gain; to 5% trail at +20% gain (Rule 8).
   - **Sector-kill** if `TRADE-LOG.md` tail shows 2 consecutive losses in this position's sector → close all positions in that sector with `entry_date < today`.
3. Same-day positions (`entry_date == today`) are **read-only** in midday — observed but never acted on.
4. Telegram silent if no action; one message summarizing actions taken if any.

**Failure mode:** if Alpaca unreachable, send URGENT Telegram, do nothing else, exit. Trailing stops still in place server-side from prior daily-summary runs.

**Out of scope for v2:** thesis-break detection (deferred to v2.5). Pre-market is responsible for flagging thesis breaks in next morning's research; midday only acts on rules 7, 8, 10.

### DECIDED F — Midday checks unrealized P&L vs entry, gated to skip same-day positions

**Choice:** Midday computes `(current_price - entry_price) / entry_price * 100` for each position with `entry_date < today` (Rule 15 gate). If ≤ -7%, market-close after `daytrade_count` pre-flight.

**Why:** Trailing stop alone doesn't enforce -7%-from-entry on a position that never ticks up (it fires at -10% from high, which on a never-ticking-up position is -10% from entry). Midday is the active enforcer of Rule 7.

**Risk accepted:** a fresh position can fall through -7% on T (its first day) and ride the loss to overnight. The trailing stop placed at daily-summary will catch it the next day if it's still down 10% from entry. Bounded by risk-parity sizing: a 2%-of-equity risk budget caps the dollar exposure.

### DECIDED G — Weekly-review proposes only, never auto-edits TRADING-STRATEGY

**Choice:** Friday's `weekly-review` writes proposed changes to `WEEKLY-REVIEW.md` and sends a Telegram with the proposed diff. Human applies (or rejects) by hand. Never commits an edit to `TRADING-STRATEGY.md` directly.

**Why:** The rulebook is the safety system. An autonomous bot mutating its own safety rules creates the next post-mortem. v3 (live) might revisit this once trust history is longer.

### DECIDED H — Idempotency: read Alpaca state, skip duplicates

**Choice:** Every routine that places orders (market-open) reads today's orders + fills from Alpaca BEFORE placing anything. If an order or fill for ticker X already exists today, skip ticker X. No lock files, no committed run-state.

**Why:** Alpaca state is the source of truth. Lock files via git commits are racy on cron-fired runs.

### DECIDED I — Trade-row → idea linkage via `pm-YYYY-MM-DD-TICKER` ID

**Choice:** Each pre-market idea is referenced as `pm-YYYY-MM-DD-TICKER`. RESEARCH-LOG entries gain an `**ID:** pm-2026-05-04-XLE` line per idea. Trade rows in TRADE-LOG.md include the same ID in their Catalyst field.

**Why:** Simple, deterministic, no breaking schema change. Ambiguous only on duplicate-ticker-same-day, which already violates Rule 2 (max 5–6 positions, and implicitly max 1 per ticker).

### DECIDED J — Telegram volume: 6–21/week + 48-hour silence heartbeat

**Choice:**
- Pre-market: silent unless macro-urgent (unchanged from v1).
- Market-open: 1 message per fill, 1 per reject. Typical 0–2/day.
- Midday: silent unless action taken; 1 summary message if any. URGENT prefix on hard-close.
- Daily-summary: 1/day, richer content (positions, fills, P&L, stops placed today).
- Weekly-review: 1/Friday with grade card.
- **Heartbeat:** if `daily-summary` notes that no Telegram message has been sent (by any routine) in the last 48 hours, it appends a one-line heartbeat to its EOD message ("Heartbeat: 48h silence — system alive, last action <date>"). Detected by reading the routine's own commit history on `main` and the timestamp of the last `telegram.sh` invocation logged via a small commit-ledger trick or a git-grep over recent commit messages mentioning Telegram.

**Why:** Day-trader-conscious silence + an explicit liveness signal so a stretch of pure-HOLD weeks (which is *expected* and on-strategy) doesn't read as "is the bot still alive?".

**Heartbeat detection mechanism:** out of scope for the spec; the implementation plan picks one of: (a) parse routine commit messages for "Telegram delivered" markers, (b) maintain a `memory/HEARTBEAT.md` file with last-Telegram-timestamp updated by `telegram.sh`. Recommend option (b) — single source of truth, no string parsing.

---

## 4a. New visa-aware safety rules (added to TRADING-STRATEGY.md)

Three rules added during the brainstorming dialogue, all marked `(v2, visa-aware)`:

- **Rule 13** — Stops are placed at market close on the entry day (daily-summary, T 15:00 CT), not at entry. This guarantees stops cannot fire same-day, eliminating the trailing-stop day-trade vector.
- **Rule 14** — Pre-flight `daytrade_count` check before every sell. If `account.daytrade_count >= 2`, abort the sell, send Telegram URGENT, require human review. Buffer of 2 leaves room for one accidental day trade.
- **Rule 15** — Midday hard-close (-7%) and sector-kill skip positions opened today. Same-day exits are day trades; same-day positions ride out T stop-less.

These three rules together create defense-in-depth: by-design avoidance (Rules 13, 15) plus runtime guard (Rule 14).

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
STEP 2 — Pull state: account (incl. daytrade_count), positions, orders. Idempotency: skip any ticker already filled or open today.
STEP 3 — For each idea: apply buy-side gate. Compute R:R. Skip and log reason on failure.
STEP 4 — Rank passing ideas by R:R desc, ticker asc. Take top min(passing, weekly_cap_remaining).
STEP 5 — For each selected idea: compute risk-parity size:
           dollar_risk = RISK_PER_TRADE_PCT × equity (default 2.0% = $200 on $10k)
           stop_distance_pct = trail_percent (default 10% from entry)
           shares = floor(dollar_risk / (entry × stop_distance_pct))
           cap shares so that shares × entry ≤ MAX_POSITION_PCT × equity (default 20%)
STEP 6 — Place limit BUY orders at price = ask × (1 + MAX_ENTRY_SLIPPAGE_PCT), TIF=day.
           Poll up to 60s for fill. NO trailing stops placed in this routine (Rule 13 — stops at daily-summary).
STEP 7 — On each fill: append BUY trade row to TRADE-LOG.md (schema with id pm-YYYY-MM-DD-TICKER, sector, planned trail percent).
STEP 8 — Telegram: 1 message per fill, 1 per reject. Silent if no orders placed.
STEP 9 — Commit + push to main.
```

### midday prompt skeleton

```
STEP 1 — Read memory: TRADING-STRATEGY.md (sell-side rules + Rules 13–15), tail of TRADE-LOG.md (entries, sector tally).
STEP 2 — Pull state: account (incl. daytrade_count), positions, current quotes, open stop orders.
STEP 3 — Filter positions to "actionable": entry_date < today (Rule 15 same-day skip). Same-day positions are read-only.
STEP 4 — For each actionable position:
           a. Compute unrealized P&L % vs entry.
           b. If ≤ -7% (Rule 7): hard-close candidate.
           c. If ≥ +20% gain: tighten trailing stop to 5%.
           d. If ≥ +15% gain (and not already at 5% trail): tighten trailing stop to 7%.
           e. If sector has 2 consecutive losses in TRADE-LOG.md tail: sector-kill candidate.
STEP 5 — Pre-flight before any sell (Rule 14):
           if account.daytrade_count >= 2:
               abort all sells; send Telegram URGENT; commit a "midday: aborted sells, daytrade_count=N" note; exit
STEP 6 — Execute actions:
           - Hard-close: market sell. Append exit trade row with realized P&L.
           - Tighten stop: cancel existing trailing stop, place new trailing-stop with narrower trail_percent.
           - Sector-kill: market-close all actionable positions in that sector (each pre-flighted).
STEP 7 — Telegram: silent if no actions. One summary message if any. URGENT prefix on hard-close or sector-kill.
STEP 8 — Commit + push to main (skip if no changes).
```

### daily-summary prompt skeleton (v2 expansion)

```
STEP 1 — Read memory: tail of TRADE-LOG.md (yesterday's equity, today's BUY rows from market-open).
STEP 2 — Pull final state: account, positions, orders, fills via `activities` (today only).
STEP 3 — Compute Day P&L (realized + unrealized vs yesterday's equity), Phase P&L (vs $10K Day 0).
STEP 4 — Place trailing-stop GTC orders for any positions opened today and not yet stopped (Rule 13):
           For each position with entry_date == today and no existing trailing-stop:
               trail_percent = idea.trail_percent (default 10)
               bash scripts/alpaca.sh trailing-stop TICKER QTY TRAIL_PERCENT
           Append "STOP PLACED" row to TRADE-LOG.md for each (links to the BUY row by ID).
STEP 5 — Append EOD snapshot to TRADE-LOG.md (existing v1 schema, now with non-empty positions table + realized fills).
STEP 6 — Heartbeat check: read memory/HEARTBEAT.md (last Telegram timestamp). If now - last > 48h, prepend
           "Heartbeat: 48h silence — system alive" to the EOD Telegram body.
STEP 7 — Telegram: 1 EOD message (always), with optional heartbeat prefix.
STEP 8 — Commit + push to main. (TRADE-LOG.md + memory/HEARTBEAT.md updates.)
```

### weekly-review prompt skeleton

```
STEP 1 — Read memory: TRADING-STRATEGY.md, this week's RESEARCH-LOG.md entries (Mon-Fri), this week's TRADE-LOG.md entries.
STEP 2 — Pull state: account, positions, all fills this week via `activities`.
STEP 3 — Compute weekly grade card:
           - Trades placed this week (target ≤3) and how many cleared the buy-side gate
           - Win/loss ratio on closed trades
           - Realized + unrealized P&L for the week (vs week-open equity)
           - R:R realized vs target on each closed trade
           - Sector-level summary
           - daytrade_count delta this week (target: 0)
           - Rule violations: positions > 20%, missed -7% closes, missed stop-tightening, etc.
STEP 4 — Append week-summary block to TRADE-LOG.md.
STEP 5 — Append entry to WEEKLY-REVIEW.md following the existing template; include any proposed
           changes to TRADING-STRATEGY.md as a `## Proposed strategy changes` block with diff markers.
           DO NOT edit TRADING-STRATEGY.md (Rule G).
STEP 6 — Telegram: send the grade card (1 message). If proposed strategy changes exist, prepend
           "*Strategy changes proposed* — review WEEKLY-REVIEW.md before Mon".
STEP 7 — Commit + push to main.
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

1. ~~Resolve every OPEN DECISION via brainstorming.~~ DONE 2026-05-05.
2. Write the v2 implementation plan with writing-plans. **Current step.**
3. Update `memory/TRADING-STRATEGY.md` with new Rules 13–15. (DONE in same brainstorming commit as this lock.)
4. Wrapper changes first: add `trailing-stop`, `replace-stop`, `activities` subcommands to `scripts/alpaca.sh` with tests. No routine touches state-changing endpoints until wrappers exist + tests pass.
5. Local mirrors (`.claude/commands/{market-open,midday,weekly-review,trade}.md`) before cloud routines — test interactively with `TRADING_ENABLED=false` still in place.
6. Flip `TRADING_ENABLED=true` ONE routine at a time:
   - `daily-summary` first (it gains stop-placement responsibility, lowest risk to enable since it only places stops on positions that already exist from market-open).
   - `market-open` second (entries only, never sells).
   - `midday` third (sells gated by Rules 14–15).
   - `weekly-review` fourth (read-only against Alpaca; only writes to memory + Telegram).
7. After each routine flip: smoke-test with Run now, observe one cron firing before flipping the next.
8. v2 exit criteria observation period (§ 10).

---

## 10. v2 exit criteria

System is v2-stable when **all** observed (refined from v1 § 11):

1. All five routines fire successfully on cloud cron for **2 consecutive weeks** (10 weekdays) with no manual intervention.
2. Every position held overnight during the observation window had a real trailing-stop GTC order present by 15:30 CT on its entry day (verifiable in `bash scripts/alpaca.sh orders` history).
3. No `TRADING-STRATEGY.md` rule was violated, including new Rules 13–15 (audit by re-reading `TRADE-LOG.md`).
4. Midday took the right action on every threshold cross for *actionable* (= entry_date < today) positions; auditable from order history vs price history.
5. Weekly-review graded both weeks (not just "no trades, no comment") and produced at least one parseable proposed-changes block for human review.
6. Zero `.env` files in the cloud clone (carry-forward from v1 #5).
7. No Alpaca API errors propagated to Telegram URGENT alerts that required human cleanup (transient errors with successful retry don't count).
8. **`account.daytrade_count` never exceeded 2 during the observation window** (Rule 14 buffer never breached → no PDT designation risk realized).
9. Telegram heartbeat fired correctly on any 48h+ silence stretch within the observation window.

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
- Auto-mutating `TRADING-STRATEGY.md` (deferred per DECIDED G)
- Perplexity-driven thesis-break detection on held positions (deferred to v2.5 per DECIDED E)

---

## 12. Brainstorming history (resolved)

Brainstorming dialogue completed 2026-05-05. All decisions DECIDED in § 4.

User-provided constraint that shaped the design: **international student visa**. PDT designation creates real visa risk. This converted three sub-decisions:

1. **Stop placement timing** moved from market-open (T 08:30) to daily-summary (T 15:00, market close) so stops cannot fire same-day.
2. **Midday hard-close + sector-kill** added a same-day-skip gate so they cannot create a same-day exit.
3. **New Rule 14**: pre-flight `daytrade_count` check before every sell, abort + URGENT Telegram if `>= 2` (buffer of 2 leaves room for accidental day trades without immediately freezing the system).

Brainstorming time: ~25 minutes. Outcome: spec locked, Rules 13–15 added to `TRADING-STRATEGY.md`, ready for writing-plans.

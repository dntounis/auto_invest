# auto_invest v3.1 — Hardening Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the four production risks surfaced by the first 3 weeks of v3 cloud runs: the sub-unit scale-out bug, unbounded single-sector concentration, silent stop-placement-failure windows, and missing deployment-ceiling enforcement.

**Architecture:** One deterministic-math change (`sizing.py` gains a `scaleout` subcommand, unit-tested) plus three rulebook/routine-prompt changes (two new Buy-Side Gate checks + one operational rule). All sells stay visa-safe (Rules 13/14/15 untouched). No new dependencies, no network code added.

**Tech Stack:** Python 3 stdlib (`argparse`/`json`/`math`), Bash test harness (`tests/_lib.sh`, `assert_contains` — no pytest), Markdown routine prompts.

## Global Constraints

- **Paper only. `TRADING_ENABLED=true`.** Wrapper kill-switch still gates state-changing subcommands. *(copied from CLAUDE.md)*
- **NO OPTIONS — ever.** *(Rule 1)*
- **Never create, write, or source a `.env` file.** Credentials come from process env vars. *(CLAUDE.md Secrets Discipline)*
- **Safety-critical math is deterministic in `scripts/sizing.py`** — unit-tested in `tests/test_sizing.sh`. Routines never do money arithmetic inline. *(CLAUDE.md Mode)*
- **Visa-aware Rules 13/14/15 are byte-unchanged by this plan.** Zero day trades by construction must still hold.
- **Test harness:** `bash tests/test_sizing.sh` (no pytest). Assertions use `start_test` + `assert_contains "$out" '"key": value'`.
- **CRITICAL deployment caveat:** routine PROMPT edits in `routines/*.md` do NOT auto-propagate to the cloud. The Anthropic Routines UI stores each routine's prompt in a textbox; the operator must **manually re-paste** every changed routine. `scripts/sizing.py`, `scripts/alpaca.sh`, and `memory/*.md` DO go live automatically (cloud clones `main`). Each task notes which artifact type it touches. `.claude/commands/*.md` local mirrors must stay byte-identical to their `routines/*.md` cloud twin.

---

## File Structure

| File | Type | Responsibility | Tasks |
|------|------|----------------|-------|
| `scripts/sizing.py` | code (auto-live) | new `scaleout` mode: deterministic partial-sell qty | 1 |
| `tests/test_sizing.sh` | test | unit tests for `scaleout` | 1 |
| `routines/midday.md` + `.claude/commands/midday.md` | prompt (re-paste) | call `scaleout` instead of inline `$((CUR_QTY/3))` | 2 |
| `memory/TRADING-STRATEGY.md` | rulebook (auto-live) | Rule 17 + 2 new Buy-Side Gate checks + Portfolio Structure sector cap | 3,4 |
| `routines/daily-summary.md` + mirror | prompt (re-paste) | Rule 17: URGENT + record failure on stop-placement failure | 3 |
| `routines/pre-market.md` + mirror | prompt (re-paste) | Rule 17: STEP 0 pending-stop retry as first action | 3 |
| `routines/market-open.md` + mirror | prompt (re-paste) | sector-cap + deployment-ceiling gate checks | 4 |
| `MEMORY.md` + `memory/auto_invest_v3_live.md` | memory (auto-live) | record v3.1 active + re-paste checklist | 5 |

---

## Task 1: Deterministic `scaleout` subcommand in sizing.py

**Why:** Today midday computes the partial-sell quantity inline as `$((CUR_QTY/3))`. For a 2-share satellite (CAT), `floor(2/3)=0` → the scale-out is unrepresentable and silently skipped. The scale-out half of the Rule 8 profit ladder has therefore **never fired in production**. This moves the quantity decision into deterministic, unit-tested code with an explicit minimum-1-share rule that always leaves a runner.

**Files:**
- Modify: `scripts/sizing.py` (add `cmd_scaleout` + subparser; current file is 96 lines, ends at the `if __name__` guard)
- Test: `tests/test_sizing.sh` (append a `--- scaleout ---` block before `print_summary` on line 75)

**Interfaces:**
- Produces: `python3 scripts/sizing.py scaleout --cur-qty N --scaleouts-due D --scaleouts-done K` → prints one JSON object `{"sell_qty": <int>, "reason": "ok"|"none_due"|"sub_unit"}`.
  - `none_due`: `D <= K` — every owed scale-out already logged; no sell.
  - `sub_unit`: a scale-out is owed but `cur_qty < 2`, so no quantity can be sold while leaving ≥1 share runner → defer to the trail-tighten that fires in the same tier.
  - `ok`: `sell_qty = min(max(1, floor(cur_qty/3)), cur_qty-1)` — at least 1 share, never the whole position.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_sizing.sh` immediately before the `print_summary` line (line 75):

```bash
# --- scaleout ---
# none owed: due == done → no sell
start_test "scaleout: none due → sell 0"
out=$(python3 scripts/sizing.py scaleout --cur-qty 9 --scaleouts-due 0 --scaleouts-done 0 2>&1)
assert_contains "$out" '"sell_qty": 0'
assert_contains "$out" '"reason": "none_due"'

# standard 1/3 on a 9-share lot
start_test "scaleout: 9 shares, 1 due → sell 3"
out=$(python3 scripts/sizing.py scaleout --cur-qty 9 --scaleouts-due 1 --scaleouts-done 0 2>&1)
assert_contains "$out" '"sell_qty": 3'
assert_contains "$out" '"reason": "ok"'

# the CAT bug case: 2-share satellite, floor(2/3)=0 → min-1-share rule sells 1, leaves 1
start_test "scaleout: 2 shares, 1 due → sell 1 (min-1, leaves runner)"
out=$(python3 scripts/sizing.py scaleout --cur-qty 2 --scaleouts-due 1 --scaleouts-done 0 2>&1)
assert_contains "$out" '"sell_qty": 1'
assert_contains "$out" '"reason": "ok"'

# 3-share lot: floor(3/3)=1, leaves 2
start_test "scaleout: 3 shares, 1 due → sell 1 (leaves 2)"
out=$(python3 scripts/sizing.py scaleout --cur-qty 3 --scaleouts-due 1 --scaleouts-done 0 2>&1)
assert_contains "$out" '"sell_qty": 1'
assert_contains "$out" '"reason": "ok"'

# 1-share lot: owed but can't leave a runner → sub_unit, defer to trail
start_test "scaleout: 1 share, 1 due → sell 0 (sub_unit)"
out=$(python3 scripts/sizing.py scaleout --cur-qty 1 --scaleouts-due 1 --scaleouts-done 0 2>&1)
assert_contains "$out" '"sell_qty": 0'
assert_contains "$out" '"reason": "sub_unit"'

# second scale-out already logged: due 2, done 1 → still owes 1, 6 shares → sell 2
start_test "scaleout: 6 shares, 2 due 1 done → sell 2"
out=$(python3 scripts/sizing.py scaleout --cur-qty 6 --scaleouts-due 2 --scaleouts-done 1 2>&1)
assert_contains "$out" '"sell_qty": 2'
assert_contains "$out" '"reason": "ok"'
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `argument mode: invalid choice: 'scaleout'` (subparser not yet defined).

- [ ] **Step 3: Add `cmd_scaleout` to `scripts/sizing.py`**

Insert this function after `cmd_decay` (after line 59, before `def main()`):

```python
def cmd_scaleout(a):
    # Deterministic partial-sell qty for a Rule 8 scale-out tier.
    # none_due: every owed scale-out already logged.
    # sub_unit: owed but cur_qty < 2, so no qty leaves a runner -> defer to trail.
    # ok: min(max(1, floor(cur_qty/3)), cur_qty-1) -> >=1 share, never the whole lot.
    if a.scaleouts_due <= a.scaleouts_done:
        return {"sell_qty": 0, "reason": "none_due"}
    if a.cur_qty < 2:
        return {"sell_qty": 0, "reason": "sub_unit"}
    qty = min(max(1, math.floor(a.cur_qty / 3)), a.cur_qty - 1)
    return {"sell_qty": qty, "reason": "ok"}
```

Then register the subparser inside `main()`, after the `decay` parser block (after line 88, before `args = p.parse_args()`):

```python
    so = sub.add_parser("scaleout")
    so.add_argument("--cur-qty", type=int, required=True, dest="cur_qty")
    so.add_argument("--scaleouts-due", type=int, required=True, dest="scaleouts_due")
    so.add_argument("--scaleouts-done", type=int, required=True, dest="scaleouts_done")
    so.set_defaults(func=cmd_scaleout)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test_sizing.sh`
Expected: PASS — all assertions including the 6 new `scaleout` cases. Confirm the final line reads `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh
git commit -m "feat(v3.1): deterministic scaleout qty (min-1-share, always leaves runner)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Wire `scaleout` into the midday routine

**Why:** Replace the inline `$((CUR_QTY/3))` (the source of the silent-skip bug) with the deterministic helper, and add an explicit `sub_unit` log path so a deferred scale-out is visible in the audit trail instead of vanishing.

**Files:**
- Modify: `routines/midday.md` (the Scale-out bullet at lines 117-120; the execution example at line 168)
- Modify: `.claude/commands/midday.md` (keep byte-identical to the cloud twin's shared section)

**Interfaces:**
- Consumes: Task 1's `scaleout` subcommand and its `sell_qty`/`reason` JSON.

- [ ] **Step 1: Replace the Scale-out bullet in `routines/midday.md`**

Replace lines 117-120 (the `**Scale-out:**` bullet) with:

````markdown
   - **Scale-out (deterministic — v3.1):** count existing `SCALE-OUT` rows for this
     position in TRADE-LOG.md → `SO_DONE`. Then ask the sizer for the qty (never
     compute it inline):
     ```
     SO_JSON=$(python3 scripts/sizing.py scaleout --cur-qty "$CUR_QTY" \
         --scaleouts-due "$SCALEOUTS_DUE" --scaleouts-done "$SO_DONE")
     ```
     - `reason == "ok"` (sell_qty ≥ 1): this is a SELL — re-check Rule 14 `DTC` (< 2),
       then `bash scripts/alpaca.sh scale-out TICKER $SELL_QTY`. Log a `SCALE-OUT` row.
     - `reason == "sub_unit"`: a scale-out is owed but the lot is too small to trim and
       still leave a runner (e.g. a 2-share $900 satellite where 1/3 < 1 share, but the
       min-1-share rule already applies at qty ≥ 2, so `sub_unit` only hits qty 1).
       **Do NOT sell.** Log `SCALE-OUT-DEFERRED TICKER reason=sub_unit` (STEP 6) and rely
       on the same-tier trail-tighten below to capture the gain. No `DTC` impact.
     - `reason == "none_due"`: scale-out already logged for this tier — no action.
````

- [ ] **Step 2: Update the execution example at line 168 in `routines/midday.md`**

Replace line 168:

```
bash scripts/alpaca.sh scale-out TICKER PARTIAL_QTY
```

with:

```
bash scripts/alpaca.sh scale-out TICKER $SELL_QTY   # $SELL_QTY from sizing.py scaleout (reason==ok only)
```

- [ ] **Step 3: Add the `SCALE-OUT-DEFERRED` row format to the logging section**

In `routines/midday.md`, find the `### YYYY-MM-DD — SCALE-OUT:` row template (near line 205) and add immediately after that block:

```markdown
For each deferred (sub-unit) scale-out, append instead (no sell occurred):

### YYYY-MM-DD — SCALE-OUT-DEFERRED: TICKER reason=sub_unit
- Tier ladder owed a scale-out but qty too small to leave a runner; trail tightened instead.
```

- [ ] **Step 4: Mirror the changes into `.claude/commands/midday.md`**

Apply the same three edits (Steps 1-3) to `.claude/commands/midday.md` so the local mirror matches. Then verify the shared body matches:

Run: `diff <(sed -n '/Scale-out (deterministic/,/none_due/p' routines/midday.md) <(sed -n '/Scale-out (deterministic/,/none_due/p' .claude/commands/midday.md)`
Expected: no output (identical).

- [ ] **Step 5: Verify the helper call is well-formed**

Run: `python3 scripts/sizing.py scaleout --cur-qty 2 --scaleouts-due 1 --scaleouts-done 0`
Expected: `{"sell_qty": 1, "reason": "ok"}` — the exact CAT case the routine will hit next time CAT crosses +10%.

- [ ] **Step 6: Commit**

```bash
git add routines/midday.md .claude/commands/midday.md
git commit -m "feat(v3.1): midday calls sizing.py scaleout; logs sub-unit deferrals" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Rule 17 — stop-placement-failure escalation

**Why:** On 2026-06-16, 7 consecutive Alpaca `POST /v2/orders` HTTP 504s left BTSG stop-less for 24h through FOMC. The recovery (URGENT Telegram + retry next session) worked but was ad-hoc. This codifies it as an invariant: any failed stop placement MUST raise URGENT, record a machine-detectable marker, and be retried as the FIRST action of the next routine.

**Files:**
- Modify: `memory/TRADING-STRATEGY.md` (add Rule 17 after line 36; this file auto-deploys)
- Modify: `routines/daily-summary.md` + `.claude/commands/daily-summary.md` (failure path on stop placement)
- Modify: `routines/pre-market.md` + `.claude/commands/pre-market.md` (STEP 0 pending-retry as first action)

**Interfaces:**
- Produces: a `STOP-PLACEMENT-FAILED TICKER QTY TRAIL` marker row in TRADE-LOG.md, cleared by a later `STOP PLACED` row for the same ticker. The pre-market STEP 0 scans for an unresolved marker (a `STOP-PLACEMENT-FAILED` with no subsequent `STOP PLACED` for that ticker).

- [ ] **Step 1: Add Rule 17 to `memory/TRADING-STRATEGY.md`**

Insert after line 36 (the Rule 16 line), before the blank line that precedes `## Buy-Side Gate`:

```markdown
17. **Stop-placement-failure escalation (v3.1, operational, visa-neutral).** If a Rule 13 trailing-stop placement fails after 3+ Alpaca write-path retries (any HTTP code — 504s observed 2026-06-16), the routine MUST: (a) send a Telegram **URGENT** alert naming the unprotected ticker, qty, and intended trail; (b) append a `STOP-PLACEMENT-FAILED TICKER QTY TRAIL` row to TRADE-LOG.md; (c) NOT mark the position protected. The next scheduled routine MUST, as its FIRST action before any gating or research, scan for an unresolved `STOP-PLACEMENT-FAILED` marker (one with no later `STOP PLACED` for that ticker) and retry the placement. If the retry also fails after 3+ attempts, escalate with URGENT Telegram instructing manual stop placement via the Alpaca UI. This rule never places or cancels a sell — it is day-trade-neutral.
```

- [ ] **Step 2: Add the failure path to `routines/daily-summary.md`**

Find the step that places Rule 13 trailing stops (search for `trailing-stop` or `Rule 13`). Immediately after the placement call, add:

```markdown
**Rule 17 failure handling (v3.1).** If a `trailing-stop` / `replace-stop` call returns
non-2xx after 3 retries (retry with a short backoff; 504/5xx are the observed failure):
- Send URGENT: `bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — STOP PLACEMENT FAILED for TICKER QTYsh trail N% after 3 retries. Position is UNPROTECTED. Will retry first thing next routine (Rule 17)."`
- Append a marker row to TRADE-LOG.md:
  ```
  ### YYYY-MM-DD — STOP-PLACEMENT-FAILED: TICKER QTY TRAIL
  - N consecutive Alpaca write-path failures (HTTP <code>); position unprotected; Rule 17 retry pending.
  ```
- Continue the routine (do not abort the snapshot/commit). The marker is cleared when a later `STOP PLACED` row for TICKER lands.
```

- [ ] **Step 3: Add STEP 0 to `routines/pre-market.md`**

Insert a new step immediately before `## STEP 1 — Read memory for context` (line 57 region):

```markdown
## STEP 0 — Rule 17: clear any pending stop-placement failure (FIRST action)

Before any research or env checks, tail `memory/TRADE-LOG.md` for a
`STOP-PLACEMENT-FAILED TICKER QTY TRAIL` row that has **no later `STOP PLACED`** row
for the same ticker. If one exists, retry the placement as the very first action:
```
bash scripts/alpaca.sh trailing-stop TICKER QTY TRAIL
```
- On success: append a `STOP PLACED` row (clears the marker) and send a non-URGENT
  Telegram note "Rule 17 retry succeeded — TICKER now protected".
- On failure after 3 retries: send URGENT Telegram instructing manual placement via the
  Alpaca UI, leave the marker open, and continue the routine.
If no unresolved marker exists, proceed to STEP 1.
```

- [ ] **Step 4: Mirror into `.claude/commands/*.md`**

Apply Step 2's block to `.claude/commands/daily-summary.md` and Step 3's STEP 0 to `.claude/commands/pre-market.md`, adjusting only for the local-mirror header (no commit/push, no env-var section) — the Rule 17 logic body must be identical.

Run: `grep -c "Rule 17" memory/TRADING-STRATEGY.md routines/daily-summary.md routines/pre-market.md .claude/commands/daily-summary.md .claude/commands/pre-market.md`
Expected: each file ≥ 1.

- [ ] **Step 5: Commit**

```bash
git add memory/TRADING-STRATEGY.md routines/daily-summary.md routines/pre-market.md .claude/commands/daily-summary.md .claude/commands/pre-market.md
git commit -m "feat(v3.1): Rule 17 stop-placement-failure escalation + retry" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Aggregate sector-cap + deployment-ceiling Buy-Side Gate checks

**Why:** (a) Industrials has held 54–69% of deployed for 3 weeks; the per-name "≤2 satellites/sector" check bounds *names* but not *dollars*, so a Rule 10 sector-kill would liquidate 3 of 5 positions. (b) The GE entry once pushed deployment to 87.5% — the gate checks the core floor but has no upper bound. Both are forward-looking buy-side checks (they block new adds; they never force a sell), consistent with the existing prompt-evaluated gates.

**Files:**
- Modify: `memory/TRADING-STRATEGY.md` (Buy-Side Gate list ~line 47 + Portfolio Structure ~line 15; auto-deploys)
- Modify: `routines/market-open.md` (STEP 3 gate list, after line 99) + `.claude/commands/market-open.md`

**Interfaces:**
- Consumes: `positions` market values and `account.equity` / `long_market_value` already read in market-open STEP 1-2. Pure prompt arithmetic with exact formulas (no new code — matches the existing core-floor gate style).

- [ ] **Step 1: Add both checks to the Buy-Side Gate in `memory/TRADING-STRATEGY.md`**

Insert after line 45 (the `≤ 2 satellite names in the idea's GICS sector` line):

```markdown
- **Sector concentration cap (v3.1):** after this fill, no single GICS sector (ETF core + satellites combined) exceeds **50% of deployed** equity. Formula: `(sector_mv_existing + position_cost) / (long_market_value + position_cost) ≤ 0.50`. Applies to **every** idea (core and satellite). Skip + log if it would breach. Forward-looking only — does not force a sell of existing concentration; that unwinds via Rule 8 scale-outs / Rule 16 rotation.
- **Deployment ceiling (v3.1):** after this fill, capital deployment stays within the Rule 5 band: `(long_market_value + position_cost) / equity ≤ 0.85`. Skip + log if it would overshoot; defer the add until a scale-out, sell, or equity growth restores headroom.
```

- [ ] **Step 2: Note the aggregate sector cap in Portfolio Structure**

In `memory/TRADING-STRATEGY.md`, after line 15 (`Max 5–6 total positions. Max 2 satellite names per GICS sector.`), append:

```markdown
- **No single GICS sector may exceed 50% of deployed equity** (ETF core + satellites combined) — an aggregate-dollar cap on top of the per-name ≤2-satellites/sector limit, enforced forward-looking by the buy-side gate *(v3.1)*.
```

- [ ] **Step 3: Add both checks to market-open STEP 3 in `routines/market-open.md`**

Insert after line 99 (the `≤ 2 satellite names ... GICS sector` bullet):

```markdown
- **(v3.1, all ideas)** Sector concentration cap: compute `deployed_after = long_market_value + position_cost` and `sector_after = (sum of this sector's existing position market values) + position_cost`. If `sector_after / deployed_after > 0.50`, skip + log "sector cap: TICKER sector would be X% of deployed (> 50%)".
- **(v3.1, all ideas)** Deployment ceiling: if `(long_market_value + position_cost) / equity > 0.85`, skip + log "deployment ceiling: post-fill X% > 85% — deferring add".
```

- [ ] **Step 4: Mirror into `.claude/commands/market-open.md`**

Apply Step 3's two bullets to the same location in the local mirror.

Run: `diff <(grep -n "v3.1, all ideas" routines/market-open.md) <(grep -n "v3.1, all ideas" .claude/commands/market-open.md | sed 's/^[0-9]*//') ; grep -c "0.50\|0.85\|50%\|85%" memory/TRADING-STRATEGY.md`
Expected: both files contain the two new bullets; rulebook grep ≥ 2.

- [ ] **Step 5: Reasoning check against the live book**

The current book is Industrials 59.46% of deployed. Manually confirm the new gate would block any Industrials add: with `deployed_after ≈ 8576 + position_cost` and `sector_after ≈ 5099 + position_cost`, the ratio stays > 0.50 for any positive `position_cost` → correctly blocked. Note this in the commit body as the validating case.

- [ ] **Step 6: Commit**

```bash
git add memory/TRADING-STRATEGY.md routines/market-open.md .claude/commands/market-open.md
git commit -m "feat(v3.1): sector-cap (50%) + deployment-ceiling (85%) buy-side gates" -m "Validated against live book: Industrials 59% would be correctly blocked from further adds." -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Record v3.1 active + operator re-paste checklist

**Why:** Three of the four fixes live in routine PROMPTS that the cloud does not auto-update. The operator must re-paste them. Memory must record what shipped and exactly which routines need re-pasting, or the cloud silently runs the old prompts against the new rulebook (a mismatch identical to the v3 launch caveat).

**Files:**
- Modify: `/Users/dntounis/.claude/projects/-Users-dntounis-Documents-apps-auto-invest/memory/auto_invest_v3_live.md` (append v3.1 section)
- Modify: `/Users/dntounis/.claude/projects/-Users-dntounis-Documents-apps-auto-invest/memory/MEMORY.md` (update the v3 pointer line)

- [ ] **Step 1: Append a v3.1 section to the project memory**

Add to `auto_invest_v3_live.md` under a new heading:

```markdown
## v3.1 hardening (2026-06-22)

Four production fixes from the first 3 weeks of v3 cloud runs:
1. **Sub-unit scale-out** — `sizing.py scaleout` (min-1-share, always leaves a runner); midday calls it instead of inline `$((CUR_QTY/3))`. The scale-out half of Rule 8 had never fired (CAT qty=2 → floor(2/3)=0).
2. **Sector cap** — new buy-side gate: no GICS sector > 50% of deployed (Industrials sat at 59%).
3. **Rule 17** — stop-placement-failure escalation: URGENT + `STOP-PLACEMENT-FAILED` marker + retry-first-action next routine (Alpaca 504 left BTSG stop-less 24h through FOMC).
4. **Deployment ceiling** — new buy-side gate: post-fill deployment ≤ 85% (GE once pushed it to 87.5%).

**Re-paste REQUIRED (cloud does not auto-update prompts):** `midday`, `daily-summary`, `pre-market`, `market-open`. Auto-live (no action): `sizing.py`, `TRADING-STRATEGY.md`. `daily-summary` now changed (was unchanged in v3) — re-paste it this time.
```

- [ ] **Step 2: Update the MEMORY.md pointer**

Edit the existing v3 line in `MEMORY.md` to note v3.1:

```markdown
- [auto_invest v3 core-satellite shipped to main](auto_invest_v3_live.md) — v3 merged 2026-06-02; v3.1 hardening (scaleout/sector-cap/Rule17/deploy-ceiling) 2026-06-22; routine PROMPTS need manual re-paste (midday, daily-summary, pre-market, market-open)
```

- [ ] **Step 3: Run the full test suite as a regression gate**

Run: `bash tests/test_sizing.sh && bash tests/test_alpaca.sh`
Expected: both print `ALL TESTS PASSED`. Confirms Task 1 didn't regress sizing and the alpaca wrapper is intact.

- [ ] **Step 4: Commit**

```bash
git add /Users/dntounis/.claude/projects/-Users-dntounis-Documents-apps-auto-invest/memory/auto_invest_v3_live.md /Users/dntounis/.claude/projects/-Users-dntounis-Documents-apps-auto-invest/memory/MEMORY.md
git commit -m "docs(v3.1): record hardening fixes + operator re-paste checklist" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Verification (whole-plan)

- **Unit:** `bash tests/test_sizing.sh` green incl. 6 new `scaleout` cases; `bash tests/test_alpaca.sh` green (no regression).
- **The CAT case:** `python3 scripts/sizing.py scaleout --cur-qty 2 --scaleouts-due 1 --scaleouts-done 0` → `{"sell_qty": 1, "reason": "ok"}` (the bug is fixed — a 2-share satellite now scales out 1 share instead of skipping).
- **Mirror parity:** the shared body of each changed `routines/*.md` matches its `.claude/commands/*.md` twin.
- **Visa-safety regression:** grep-confirm Rules 13/14/15 text in `memory/TRADING-STRATEGY.md` is byte-unchanged; the only sells touched (scale-out) still re-check `DTC` (Rule 14) and run on T+1+ positions (Rule 15).
- **Gate logic:** dry-run `pre-market` then `market-open` (local) — confirm an Industrials idea is rejected by the new sector cap, and that no idea is sized past 85% deployment.
- **Operator handoff:** memory records the re-paste list (midday, daily-summary, pre-market, market-open).

## Self-review notes

- **Scope coverage:** all four user-named fixes map to tasks — scale-out→T1/T2, sector cap→T4, Rule 17→T3, deployment ceiling→T4. ✓
- **Determinism boundary:** only the sell *quantity* (safety-critical) moved into `sizing.py`; the gates stay prompt-evaluated to match the existing core-floor/sector-count gates (no inconsistent half-deterministic gate layer). ✓
- **No forced sells:** both new gates are forward-looking buy-side only; existing 59% Industrials concentration is grandfathered and unwinds via Rule 8 scale-out (now functional) / Rule 16 rotation — coherent with fixing the scale-out bug first. ✓
- **Deployment caveat surfaced:** Task 5 lists exactly which prompts need re-pasting, incl. the newly-changed `daily-summary` (was untouched in v3). ✓

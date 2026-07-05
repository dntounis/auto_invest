# auto_invest v3.2 — Hardening Round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the three open weekly-review proposals from Weeks 9–10: HWM-aware trail-tightening (fixes the +15% intraday-spike miss), a Rule 18 cadence guardrail (detects skipped routine logs), and a macro-binary-proximity buy-side gate (blocks fresh satellites entered <T+3 before an NFP/CPI/PPI/PCE/FOMC print).

**Architecture:** One deterministic-math change (`sizing.py ladder` gains an optional `--hwm-pct` so the trail target can lead the scale-out tier, unit-tested) plus three prompt/rulebook changes across the four routines. All sells stay visa-safe (Rules 13/14/15 byte-unchanged; the new gate and Rule 18 never place or cancel a sell).

**Tech Stack:** Python 3 stdlib (`argparse`/`json`/`math`), Bash test harness (`tests/_lib.sh`, `assert_contains` — no pytest), Markdown routine prompts, existing Perplexity economic-calendar research (no new dependency).

## Global Constraints

- **Paper only. `TRADING_ENABLED=true`.** Wrapper kill-switch still gates state-changing subcommands. *(CLAUDE.md)*
- **NO OPTIONS — ever.** *(Rule 1)*
- **Never create, write, or source a `.env` file.** Credentials come from process env vars. *(CLAUDE.md Secrets Discipline)*
- **Safety-critical math is deterministic in `scripts/sizing.py`** — unit-tested in `tests/test_sizing.sh`. Routines never do safety-critical money arithmetic inline. *(CLAUDE.md Mode)*
- **Visa-aware Rules 13/14/15 are byte-unchanged by this plan.** Zero day trades by construction must still hold.
- **Test harness:** `bash tests/test_sizing.sh` (no pytest). Assertions use `start_test` + `assert_contains "$out" '"key": value'`.
- **`sizing.py ladder` backward compatibility:** existing callers pass only `--tier` and `--unrealized-pct`. `--hwm-pct` MUST be optional and, when omitted, produce byte-identical output to today. `scaleouts_due` MUST remain computed from `--unrealized-pct` (current price) only — never from HWM. Only `target_trail_pct` may use the HWM basis.
- **Macro-binary gate scope:** applies to `tier: satellite` ideas ONLY. `tier: core` (ETF) adds bypass it (broad-market exposure absorbs macro binaries). Block if a Tier-1 binary (NFP, CPI, PPI, Core PCE, FOMC decision, FOMC minutes, Powell press conference) falls on **T+1 or T+2** — the two trading sessions after the entry day (entry = T+0). Clear if the nearest such binary is ≥ T+3.
- **Rule 18 and the macro gate are day-trade-neutral** — neither places nor cancels an order.
- **CRITICAL deployment caveat:** routine PROMPT edits in `routines/*.md` do NOT auto-propagate to the cloud — the operator must manually re-paste each changed routine into the Anthropic Routines UI. `scripts/sizing.py` and `memory/TRADING-STRATEGY.md` DO auto-deploy (cloud clones `main`). `.claude/commands/*.md` local mirrors must stay byte-identical to their `routines/*.md` twin in the shared logic body.

---

## File Structure

| File | Type | Responsibility | Tasks |
|------|------|----------------|-------|
| `scripts/sizing.py` | code (auto-live) | `ladder` gains optional `--hwm-pct`; trail target off `max(unrealized,hwm)`, scaleouts off unrealized | 1 |
| `tests/test_sizing.sh` | test | unit tests for HWM-aware ladder + backward-compat | 1 |
| `routines/midday.md` + `.claude/commands/midday.md` | prompt (re-paste) | compute HWM-gain from open stop, pass `--hwm-pct` for the tighten | 2 |
| `memory/TRADING-STRATEGY.md` | rulebook (auto-live) | Rule 18 + 11th buy-side gate (macro-binary) | 3,4 |
| `routines/daily-summary.md` + mirror | prompt (re-paste) | Rule 18 STEP 0 day-sweep | 3 |
| `routines/pre-market.md` + mirror | prompt (re-paste) | Rule 18 yesterday-EOD check in STEP 0; macro-window screen + idea tag | 3,4 |
| `routines/market-open.md` + mirror | prompt (re-paste) | 11th gate reads the `macro-window:` idea tag | 4 |
| `MEMORY.md` + `memory/auto_invest_v3_live.md` | memory (auto-live) | record v3.2 active + re-paste checklist | 5 |

---

## Task 1: HWM-aware ladder in sizing.py

**Why:** On 2026-06-25 CAT was +14.71% at midday (→ correct trail 6%), then spiked to +15.45% HWM *after* midday. Midday runs once/day, so the +15% tier's trail-4% was never applied; the runner exited on the looser 6% trail (~$20 foregone). Root cause is evaluation timing, not a sizing bug — `sizing.py ladder` already returns trail 4% when fed +15.45%. Fix: let the routine feed the ladder the position's high-water-mark gain so the trail target reflects the highest tier the position ever reached, while the scale-out tier stays tied to the current-price gain (never realize gains the position no longer has).

**Files:**
- Modify: `scripts/sizing.py` — `cmd_ladder` (lines 43-52) + the `ladder` subparser (lines 75-79)
- Test: `tests/test_sizing.sh` — extend the `--- ladder ---` block (append new cases before `print_summary`)

**Interfaces:**
- Produces: `python3 scripts/sizing.py ladder --tier etf|stock --unrealized-pct X [--hwm-pct H]` → `{"tier", "target_trail_pct", "scaleouts_due"}`.
  - `scaleouts_due`: highest tier's cumulative scale-out count using `unrealized_pct` only (unchanged).
  - `target_trail_pct`: highest tier's trail using `max(unrealized_pct, hwm_pct)` when `--hwm-pct` given; else using `unrealized_pct` (backward compatible).

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_sizing.sh` immediately before the `print_summary` line:

```bash
# --- ladder HWM-aware (v3.2) ---
# backward compat: no --hwm-pct → identical to today (stock +14.71 → trail 6, 1 scaleout)
start_test "ladder: no hwm-pct unchanged (stock +14.71)"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 14.71 2>&1)
assert_contains "$out" '"target_trail_pct": 6'
assert_contains "$out" '"scaleouts_due": 1'

# the CAT case: current +12, HWM +15.45 → trail from +15 tier (4), scaleouts from +12 tier (1)
start_test "ladder: hwm lifts trail tier, scaleouts stay on current (CAT case)"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 12 --hwm-pct 15.45 2>&1)
assert_contains "$out" '"target_trail_pct": 4'
assert_contains "$out" '"scaleouts_due": 1'

# hwm below current → max() ignores it, behaves as current
start_test "ladder: hwm below current is ignored (stock +15 hwm +10)"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 15 --hwm-pct 10 2>&1)
assert_contains "$out" '"target_trail_pct": 4'
assert_contains "$out" '"scaleouts_due": 1'

# etf: trail tier can lead the scaleout tier (current +5 → 0 scaleouts, hwm +8 → trail 5)
start_test "ladder: etf trail leads scaleouts (current +5, hwm +8)"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 5 --hwm-pct 8 2>&1)
assert_contains "$out" '"target_trail_pct": 5'
assert_contains "$out" '"scaleouts_due": 0'
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `unrecognized arguments: --hwm-pct` on the new cases.

- [ ] **Step 3: Implement the HWM-aware ladder**

Replace `cmd_ladder` (lines 43-52) with:

```python
def cmd_ladder(a):
    tiers = LADDERS[a.tier]
    # scaleouts_due tracks the current-price tier — never realize gains the
    # position no longer holds.
    scaleouts = 0
    for trigger, trail, so in tiers:
        if a.unrealized_pct >= trigger:
            scaleouts = so
    # target_trail may lead the scaleout tier: if the position's high-water-mark
    # reached a higher tier intraday, ratchet the trail to it (Rule 9 still guards
    # the 3% floor; a stop never loosens).
    trail_basis = a.unrealized_pct
    if a.hwm_pct is not None:
        trail_basis = max(a.unrealized_pct, a.hwm_pct)
    target_trail = None
    for trigger, trail, so in tiers:
        if trail_basis >= trigger:
            target_trail = trail
    return {"tier": a.tier, "target_trail_pct": target_trail,
            "scaleouts_due": scaleouts}
```

Then add the optional argument to the `ladder` subparser (after the existing `--unrealized-pct` line in the `l = sub.add_parser("ladder")` block):

```python
    l.add_argument("--hwm-pct", type=float, default=None, dest="hwm_pct")
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test_sizing.sh`
Expected: PASS — all assertions, ending in `ALL TESTS PASSED`. The pre-existing ladder tests (no `--hwm-pct`) must still pass, proving backward compatibility.

- [ ] **Step 5: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh
git commit -m "feat(v3.2): HWM-aware ladder trail target (scaleouts stay current-price)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Wire HWM-gain into the midday tighten

**Why:** Feed the ladder the position's high-water-mark gain so an intraday spike past a trail tier (CAT +15.45% post-midday) still tightens the trail on the next evaluation. The open trailing-stop order already tracks `hwm`; midday reads that order for the OID/qty/trail anyway.

**Files:**
- Modify: `routines/midday.md` — the ladder block (lines 113-124)
- Modify: `.claude/commands/midday.md` — keep the shared logic body byte-identical

**Interfaces:**
- Consumes: Task 1's optional `--hwm-pct` on `sizing.py ladder`. The `hwm` field of the position's open trailing-stop order (from `bash scripts/alpaca.sh orders`).

- [ ] **Step 1: Replace the ladder-call line in `routines/midday.md`**

Replace the fenced block at lines 114-116:

```
   LADDER_JSON=$(python3 scripts/sizing.py ladder --tier "$TIER" --unrealized-pct "$UPCT")
```

with:

````markdown
   ```
   # HWM-gain from the position's open trailing-stop order (the same order you read for
   # OID/QTY/trail_percent). hwm is the peak price Alpaca tracked since the stop was placed.
   # HWM_GAIN = (hwm - avg_entry_price) / avg_entry_price * 100
   # If the position has no open trailing stop yet (no hwm), omit --hwm-pct entirely.
   LADDER_JSON=$(python3 scripts/sizing.py ladder --tier "$TIER" --unrealized-pct "$UPCT" --hwm-pct "$HWM_GAIN")
   ```
   `--hwm-pct` makes `target_trail_pct` reflect the highest tier the position reached
   intraday (catching a post-midday spike that reversed), while `scaleouts_due` stays on
   the current-price `$UPCT` (v3.2). When no open stop exists, drop `--hwm-pct` — the call
   is backward-compatible and behaves exactly as before.
````

- [ ] **Step 2: Confirm the tighten bullet already consumes `target_trail_pct` correctly**

No edit needed — verify the existing Tighten bullet (lines 121-124) reads:
"if `target_trail_pct` is non-null AND strictly less than the current open stop's `trail_percent` ... `replace-stop`". This already does the right thing with the now-HWM-aware `target_trail_pct`; Rule 9's "never within 3% of price / never move a stop down" guard is unchanged. Note this in the report.

- [ ] **Step 3: Apply the identical edit to `.claude/commands/midday.md`**

Apply Step 1's replacement to the mirror.

Run: `diff <(sed -n '/HWM-gain from the position/,/backward-compatible/p' routines/midday.md) <(sed -n '/HWM-gain from the position/,/backward-compatible/p' .claude/commands/midday.md)`
Expected: no output (identical).

- [ ] **Step 4: Verify the CAT scenario end-to-end**

Run: `python3 scripts/sizing.py ladder --tier stock --unrealized-pct 12 --hwm-pct 15.45`
Expected: `{"tier": "stock", "target_trail_pct": 4, "scaleouts_due": 1}` — the trail would tighten to 4% (the +15% tier) that CAT missed, while the scale-out stays at the +10% tier.

- [ ] **Step 5: Commit**

```bash
git add routines/midday.md .claude/commands/midday.md
git commit -m "feat(v3.2): midday feeds HWM-gain to ladder so trail catches intraday spikes" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Rule 18 — cadence guardrail

**Why:** Pre-market did not run/log on Fri Jun 26 (no RESEARCH-LOG entry) — the 4th documentation gap in 46 sessions, on a post-PCE day with open satellite slots. Codify detection: every routine already writes its log even on HOLD; the next routine sweeps for missing entries and raises URGENT + a placeholder so a silent cron skip can't hide.

**Files:**
- Modify: `memory/TRADING-STRATEGY.md` — add Rule 18 after Rule 17 (auto-deploys)
- Modify: `routines/daily-summary.md` + `.claude/commands/daily-summary.md` — new STEP 0 day-sweep
- Modify: `routines/pre-market.md` + `.claude/commands/pre-market.md` — extend STEP 0 with a yesterday-EOD check

**Interfaces:**
- Produces: a `MISSING ROUTINE` placeholder row in the relevant log and an URGENT Telegram when an expected routine's entry is absent for the target date.

- [ ] **Step 1: Add Rule 18 to `memory/TRADING-STRATEGY.md`**

Insert after the Rule 17 line (the last numbered rule before `## Buy-Side Gate`):

```markdown
18. **Cadence guardrail (v3.2, operational, visa-neutral).** Every routine writes to its log every trading day even on a HOLD or no-op decision. Detection is enforced by the *next* routine: as its FIRST action it scans the current day's expected prior-routine log entries and, for any that is missing, (a) sends a Telegram **URGENT** naming the missing routine, and (b) writes a `MISSING ROUTINE — investigate cron` placeholder row to that routine's log. `daily-summary` performs the full-day sweep (pre-market → RESEARCH-LOG, market-open + midday → TRADE-LOG); `pre-market` additionally verifies the *prior* trading day's `daily-summary` EOD snapshot exists. Rule 18 never places or cancels a trade — it is day-trade-neutral and visa-neutral.
```

- [ ] **Step 2: Add a STEP 0 day-sweep to `routines/daily-summary.md`**

Insert immediately before `## STEP 1 — Read memory for continuity` (line 55 region):

```markdown
## STEP 0 — Rule 18: cadence sweep (FIRST action, v3.2)

Before pulling state, resolve `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` and verify today's
prior routines logged. On a US market holiday (no session) skip this sweep — the routines
correctly no-op.
- **pre-market** → `memory/RESEARCH-LOG.md` MUST have a `$DATE` entry.
- **market-open** → `memory/TRADE-LOG.md` MUST have a `market-open $DATE` row.
- **midday** → `memory/TRADE-LOG.md` MUST have a `$DATE — Midday` row.
For each missing routine:
```
bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — MISSING ROUTINE: <name> did not log today. Investigate cron. (Rule 18)"
```
and append a placeholder to that routine's log:
```
### $DATE — MISSING ROUTINE: <name> (Rule 18 cadence guardrail)
- No <name> entry found for $DATE at daily-summary sweep; cron skip suspected. Investigate.
```
Then continue to STEP 1. If all three logged, proceed silently.
```

- [ ] **Step 3: Extend `routines/pre-market.md` STEP 0 with the yesterday-EOD check**

In `routines/pre-market.md`, inside the existing `## STEP 0 — Rule 17` block, add before the closing `If no unresolved marker exists, proceed to STEP 1.` line:

```markdown

**Rule 18 (v3.2) — verify the prior session's daily-summary logged.** Also as a first
action, confirm `memory/TRADE-LOG.md` contains an `EOD Snapshot` row for the most recent
prior trading day (skip if that day was a US market holiday). If it is missing, send
`bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — MISSING ROUTINE: daily-summary did not log for <prior_date>. Investigate cron. (Rule 18)"` and append a
`### <prior_date> — MISSING ROUTINE: daily-summary (Rule 18)` placeholder to TRADE-LOG.md.
Then continue.
```

Also update the STEP 0 heading to name both rules: change `## STEP 0 — Rule 17: clear any pending stop-placement failure (FIRST action)` to `## STEP 0 — Rules 17 + 18: pending-stop retry + cadence check (FIRST action)`.

- [ ] **Step 4: Mirror into `.claude/commands/*.md`**

Apply Step 2's STEP 0 block to `.claude/commands/daily-summary.md` and Step 3's additions to `.claude/commands/pre-market.md`, adjusting only for the local-mirror header (no commit/push section) — the Rule 18 logic body must be identical.

Run: `grep -c "Rule 18" memory/TRADING-STRATEGY.md routines/daily-summary.md routines/pre-market.md .claude/commands/daily-summary.md .claude/commands/pre-market.md`
Expected: each file ≥ 1.

- [ ] **Step 5: Commit**

```bash
git add memory/TRADING-STRATEGY.md routines/daily-summary.md routines/pre-market.md .claude/commands/daily-summary.md .claude/commands/pre-market.md
git commit -m "feat(v3.2): Rule 18 cadence guardrail (day-sweep + yesterday-EOD check)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Macro-binary-proximity buy-side gate

**Why:** KLIC (Tue Jun 30) passed all 10 gate prongs but entered T+2 before Thu NFP; the print's tape reversal hit its trail for −$122.24. Fresh single-stock satellites need >2 sessions of cushion before a Tier-1 macro binary. Add an 11th gate that blocks a satellite buy when a Tier-1 binary falls on T+1 or T+2. ETF-core adds bypass (broad-market exposure absorbs the binary). This is asymmetric protection, accepted to occasionally skip a winner (documented: BTSG would have been skipped and went +7%).

**Files:**
- Modify: `memory/TRADING-STRATEGY.md` — Buy-Side Gate list (11th check) + Single-stock satellite checklist (auto-deploys)
- Modify: `routines/pre-market.md` + mirror — extend the calendar research + tag each satellite idea with `macro-window:`
- Modify: `routines/market-open.md` + mirror — 11th gate reads the tag

**Interfaces:**
- Produces: a `macro-window:` field on each satellite idea line in RESEARCH-LOG. Values: `clear` (nearest Tier-1 binary ≥ T+3) or `<BINARY> T+N` (a Tier-1 binary on T+1 or T+2 → the market-open gate skips it).
- Consumes (market-open): the `tier:` and `macro-window:` fields already parsed from the idea line.

- [ ] **Step 1: Add the 11th gate to `memory/TRADING-STRATEGY.md`**

Insert into the `## Buy-Side Gate` list after the v3.1 deployment-ceiling bullet:

```markdown
- **Macro-binary proximity (v3.2, satellite only):** no Tier-1 macro binary (NFP, CPI, PPI, Core PCE, FOMC decision, FOMC minutes, Powell press conference) is scheduled on **T+1 or T+2** — the two trading sessions after the entry day (T+0). If one is, skip the satellite buy and log it. ETF-core (`tier: core`) adds bypass this check — broad-market exposure absorbs macro binaries. Rationale: a fresh single-stock satellite needs >2 sessions to build trailing-stop cushion before a full-day macro tape reversal (evidence: KLIC entered T+2 before NFP, exited −5.89%). Asymmetric protection — accepted that it may skip an occasional winner.
```

Also add to the `### Single-stock satellite checklist (v3)` section a line:

```markdown
- Is the entry clear of a Tier-1 macro binary on T+1/T+2? *(v3.2 — NFP/CPI/PPI/PCE/FOMC; ETF core exempt)*
```

- [ ] **Step 2: Extend the pre-market satellite screen to compute + tag `macro-window`**

In `routines/pre-market.md`, in the STEP 3 research query list, change the economic-calendar query from today-only to a forward window. Replace:

```
- "Economic calendar today (CPI/PPI/FOMC/jobs data)"
```

with:

```
- "US economic calendar next 5 trading days: NFP jobs report, CPI, PPI, Core PCE, FOMC decision, FOMC minutes, Powell press conference — with dates"
```

Then, in the **Single-stock satellite screen (v3)** block, add a bullet:

```markdown
- **Macro-window (v3.2):** from the economic-calendar result, determine whether any Tier-1
  binary (NFP, CPI, PPI, Core PCE, FOMC decision/minutes, Powell presser) falls on T+1 or
  T+2 (the next two trading sessions after today's entry). Tag the idea line
  `macro-window: clear` if the nearest such binary is ≥ T+3, else
  `macro-window: <BINARY> T+N`. Do NOT propose a satellite whose macro-window is not clear
  (screen it out like a failed DMA/RS check, and note why). Core ETF ideas are exempt —
  always tag them `macro-window: n/a (core)`.
```

Finally, extend the idea-line schema (the `**ID:** ... planned trail percent: N` format block) by appending `, macro-window: clear|<BINARY> T+N|n/a (core)` to the documented format so market-open can parse it.

- [ ] **Step 3: Add the 11th gate to `routines/market-open.md` STEP 3**

Insert after the v3.1 deployment-ceiling bullet in the STEP 3 gate list:

```markdown
- **(v3.2, satellite only)** Macro-binary proximity: read the idea's `macro-window:` tag. If `tier` is `satellite` AND the tag names a Tier-1 binary on T+1/T+2 (anything other than `clear`), skip + log "macro-binary gate: TICKER blocked by <BINARY> at T+N". `tier: core` ideas (tag `n/a (core)`) bypass this check.
```

- [ ] **Step 4: Mirror into `.claude/commands/*.md`**

Apply Step 2 to `.claude/commands/pre-market.md` and Step 3 to `.claude/commands/market-open.md`.

Run: `grep -c "macro-window\|Macro-binary" routines/pre-market.md routines/market-open.md memory/TRADING-STRATEGY.md .claude/commands/pre-market.md .claude/commands/market-open.md`
Expected: each file ≥ 1.
Run: `diff <(grep "v3.2, satellite only" routines/market-open.md) <(grep "v3.2, satellite only" .claude/commands/market-open.md)`
Expected: no output (identical gate bullet in both).

- [ ] **Step 5: Reasoning check against the KLIC case**

Confirm the gate would have blocked KLIC: entry Tue Jun 30 (T+0), NFP Thu Jul 2 = T+2 → tag `macro-window: NFP T+2` → satellite gate skips. Confirm an ETF-core idea with the same calendar is unaffected (tag `n/a (core)` → bypass). Note both in the commit body.

- [ ] **Step 6: Commit**

```bash
git add memory/TRADING-STRATEGY.md routines/pre-market.md routines/market-open.md .claude/commands/pre-market.md .claude/commands/market-open.md
git commit -m "feat(v3.2): macro-binary-proximity gate (satellites, T+1/T+2 block)" -m "Validated: KLIC would be blocked (NFP T+2); ETF-core adds bypass." -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Record v3.2 active + operator re-paste checklist

**Why:** Three of the changes live in routine PROMPTS the cloud does not auto-update; the operator must re-paste them or the cloud runs old prompts against the new rulebook.

**Files:**
- Modify: `/Users/dntounis/.claude/projects/-Users-dntounis-Documents-apps-auto-invest/memory/auto_invest_v3_live.md` (append v3.2 section)
- Modify: `/Users/dntounis/.claude/projects/-Users-dntounis-Documents-apps-auto-invest/memory/MEMORY.md` (update the v3 pointer line)

These files are outside the git repo (session auto-memory) — edit them directly with the Write/Edit tools; there is no git commit for them.

- [ ] **Step 1: Append a v3.2 section to `auto_invest_v3_live.md`**

```markdown
## v3.2 hardening round 2 (2026-07-05, branch `v3.2-round2`)

Three open weekly-review proposals (Weeks 9–10). Plan: `docs/superpowers/plans/2026-07-05-auto-invest-v3.2-round2.md`.
1. **HWM-aware trail** — `sizing.py ladder` gains optional `--hwm-pct`; midday feeds the open stop's HWM-gain so `target_trail_pct` reflects the highest tier the position reached intraday (fixes CAT +15% miss). `scaleouts_due` stays on current price.
2. **Rule 18 cadence guardrail** — daily-summary sweeps today's pre-market/market-open/midday logs; pre-market verifies yesterday's EOD; missing → URGENT + `MISSING ROUTINE` placeholder. (4 doc gaps in 46 sessions motivated this.)
3. **Macro-binary-proximity gate** — 11th buy-side gate, satellites only: block if NFP/CPI/PPI/PCE/FOMC falls on T+1/T+2. ETF-core bypasses. (KLIC entered T+2 before NFP → −$122.24.)

**Diagnosis note:** the W9 "+15% trail-only / SO_DONE" proposal was misdiagnosed — `sizing.py ladder` already returns trail 4% at +15%; the real bug was midday evaluating current-price gain once/day and missing a post-midday intraday spike. Fixed via HWM basis, not a state-machine change. The W9 "sub-unit scale-out" proposal was already resolved in v3.1.

**Re-paste REQUIRED (cloud does not auto-update prompts):** `midday`, `daily-summary`, `pre-market`, `market-open`. Auto-live (no action): `sizing.py`, `TRADING-STRATEGY.md`.
```

- [ ] **Step 2: Update the MEMORY.md pointer line**

Replace the existing v3 pointer line with one naming v3.2:

```markdown
- [auto_invest v3 core-satellite shipped to main](auto_invest_v3_live.md) — v3 merged 2026-06-02; v3.1 (scaleout/sector-cap/Rule17/deploy-ceiling) 2026-06-22; v3.2 (HWM-trail/Rule18-cadence/macro-binary-gate) 2026-07-05; routine PROMPTS need manual re-paste (midday, daily-summary, pre-market, market-open)
```

- [ ] **Step 3: Run the full test suite as a regression gate**

Run: `bash tests/test_sizing.sh && bash tests/test_alpaca.sh`
Expected: both print `ALL TESTS PASSED` (sizing now includes the 4 new HWM-ladder cases).

---

## Verification (whole-plan)

- **Unit:** `bash tests/test_sizing.sh` green incl. 4 new HWM-ladder cases; `bash tests/test_alpaca.sh` green (no regression).
- **The CAT case:** `python3 scripts/sizing.py ladder --tier stock --unrealized-pct 12 --hwm-pct 15.45` → `{"target_trail_pct": 4, "scaleouts_due": 1}`.
- **Backward compat:** `python3 scripts/sizing.py ladder --tier stock --unrealized-pct 14.71` → unchanged `{"target_trail_pct": 6, "scaleouts_due": 1}` (no `--hwm-pct`).
- **Mirror parity:** the shared body of each changed `routines/*.md` matches its `.claude/commands/*.md` twin (targeted diffs empty).
- **Visa-safety regression:** grep-confirm Rules 13/14/15 text in `memory/TRADING-STRATEGY.md` is byte-unchanged; Rule 18 and the macro gate place/cancel no orders; the HWM change only tightens (never loosens) a stop and is still Rule 9-guarded.
- **Gate logic:** the macro gate blocks a satellite with a T+1/T+2 binary and bypasses ETF-core; Rule 18 sweep raises URGENT + placeholder on a missing routine log and stays silent when all logged.
- **Operator handoff:** memory records the re-paste list (midday, daily-summary, pre-market, market-open).

## Self-review notes

- **Scope coverage:** the three open proposals map to tasks — HWM trail→T1/T2, Rule 18→T3, macro gate→T4. The W9 "+15% SO_DONE" framing is corrected (HWM basis) and the W9 "sub-unit" proposal is noted already-done in v3.1. ✓
- **Determinism boundary:** the ladder tier math (safety-critical) stays in `sizing.py`; the HWM-gain % the routine computes parallels the existing inline `UPCT` calc and is not safety-critical (worst case sets a valid ladder tier; Rule 9 guards the floor). The two prose gates (macro, Rule 18) match the existing prose-gate pattern. ✓
- **Backward compatibility:** `--hwm-pct` optional, `scaleouts_due` untouched, pre-existing ladder tests must still pass — enforced by Task 1 Step 4. ✓
- **No forced sells / no visa impact:** HWM change only ratchets a stop tighter; macro gate is buy-side; Rule 18 is logging + alerting. Rules 13/14/15 byte-unchanged. ✓
- **Deployment caveat surfaced:** Task 5 lists all four routines needing re-paste. ✓

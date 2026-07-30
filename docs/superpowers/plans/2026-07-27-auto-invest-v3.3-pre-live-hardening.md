# auto_invest v3.3 — Pre-Live Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the six defects that block the v3 core-satellite strategy from being testable — the sizer's 4-position lock, Rule 18's detect-but-never-recover gap, market-open's HOLD-path logging hole, Rule 14's fail-open, vendor-drifting benchmark data, and the RS-screen catch-22 — so the final paper trial produces a real signal before the real-money decision.

**Architecture:** All new decision math goes into `scripts/sizing.py` as pure functions with bash unit tests, following the established v3 pattern (routines shell out; no LLM arithmetic on safety-critical paths). Routine prompt files in `routines/` are edited to call the new helpers and to close the logging/recovery gaps; `.claude/commands/` local mirrors get the equivalent (condensed) edit in the same task. `memory/TRADING-STRATEGY.md` is the rulebook of record and is updated by whichever task owns the rule.

**Tech Stack:** Python 3 stdlib only (`argparse`, `json`, `math`), bash 3.2 (macOS default), `curl`, the custom bash test harness in `tests/_lib.sh`. **No pytest.** No new dependencies.

## Global Constraints

- **NO OPTIONS — ever.** Stocks only.
- **Paper only.** `ALPACA_ENDPOINT` must contain `paper-api.alpaca.markets`. Do not change this.
- **Never create, write, or source a `.env` file** in any routine. Credentials come from process env vars.
- **Never log secrets. Never print API keys.**
- **Never `curl` Alpaca / Perplexity / Telegram directly** — always `scripts/alpaca.sh`, `scripts/perplexity.sh`, `scripts/telegram.sh`.
- **Rules 13, 14, 15 are visa-critical.** No task may weaken them. Rule 13 (stops placed at daily-summary, never at entry), Rule 14 (DTC pre-flight before every sell), and Rule 15 (never act on a same-day position) must remain byte-equivalent in intent. Task 4 *strengthens* Rule 14; no other task touches them.
- **Tests:** `bash tests/test_sizing.sh` and `bash tests/test_alpaca.sh` must both report `0 failed` at the end of every task.
- **Commits:** one commit per task, conventional-commit style, `feat(v3.3):` or `fix(v3.3):` prefix.
- **Mirror parity:** every edit to a `routines/<name>.md` file requires the equivalent edit in `.claude/commands/<name>.md`. The mirrors are *condensed* (lowercase `## Step N` headings, shorter prose) — they are NOT byte-identical and must not be made so. Port the substance, match the mirror's existing terseness.
- **Deployment caveat (do not attempt to automate):** `scripts/*` and `memory/TRADING-STRATEGY.md` auto-deploy (the cloud clones `main` at runtime). `routines/*.md` prompt bodies do NOT — the user re-pastes them into the Routines UI manually. Do not add code that tries to sync them.

## File Structure

| File | Responsibility | Tasks |
|---|---|---|
| `scripts/sizing.py` | All deterministic decision math (`size`, `ladder`, `decay`, `scaleout`, new `rscreen`) | 1, 7 |
| `tests/test_sizing.sh` | Unit tests for the above | 1, 7 |
| `scripts/alpaca.sh` | Alpaca API wrapper; new read-only `dtc` subcommand | 3 |
| `tests/test_alpaca.sh` | Wrapper tests (arg validation, kill-switch) | 3 |
| `routines/market-open.md` + mirror | Buy-side gate, sizing, order placement, new STEP 0 catch-up, HOLD-path logging | 2, 4, 5 |
| `routines/midday.md` + mirror | Position management; Rule 14 source handling | 4 |
| `routines/daily-summary.md` + mirror | EOD + Rule 13 stops + Rule 18 sweep, now with catch-up execution | 5 |
| `routines/weekly-review.md` + mirror | Grade card; benchmark now from SPY bars | 6 |
| `routines/pre-market.md` + mirror | Research + satellite screen, now calling `rscreen` | 7 |
| `memory/TRADING-STRATEGY.md` | Rulebook of record | 1, 4, 5, 7 |

---

### Task 1: Headroom-aware sizing and a 16% sizing cap

**Root cause being fixed.** In `cmd_size`, `raw = equity × risk_pct / stop_frac` and `cap = equity × max_pos_pct`. With the defaults `risk_pct=0.02` and `max_pos_pct=0.20`, and an ETF stop width of `0.10`, `raw == cap` exactly. Every core clip is therefore exactly 20% of equity, four of them saturate the 75–85% deployment band, and the fifth is refused by the 85% ceiling. The strategy mandates 5–6 positions with up to 3 satellites; that is unreachable arithmetic. Two changes: lower the default sizing cap to 16% (so 5 clips fit under 85%), and let the caller pass the actual dollar headroom so a clip shrinks to fit instead of being refused outright.

**Files:**
- Modify: `scripts/sizing.py:17-32` (`cmd_size`), `scripts/sizing.py:89-96` (`size` subparser)
- Modify: `tests/test_sizing.sh:10-15` (the existing 20%-cap test, which this change intentionally breaks)
- Modify: `memory/TRADING-STRATEGY.md` (Rule 3 and Portfolio Structure)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `sizing.py size --equity E --price P --stop-frac S [--risk-pct 0.02] [--max-pos-pct 0.16] [--min-pos-pct 0.05] [--headroom H]` → JSON `{"shares": int, "cost": float, "pct_equity": float, "clamped": "none"|"cap"|"headroom"|"floor_skip"}`. Task 2 consumes `--headroom` and the `"headroom"` clamped value.

- [ ] **Step 1: Update the existing cap test that this change breaks**

`tests/test_sizing.sh` currently asserts a 20% cap. Replace lines 10–15 (the block starting with the `# tight 5% stop:` comment) with:

```bash
# tight 5% stop: raw=200/0.05=4000 > 1600 cap → floor(1600/100)=16, clamped cap
# (v3.3: default max-pos-pct lowered 0.20 → 0.16 so five clips fit under the 85% ceiling)
start_test "size: tight stop clamps to 16% cap (v3.3)"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 2>&1)
assert_contains "$out" '"shares": 16'
assert_contains "$out" '"clamped": "cap"'
```

- [ ] **Step 2: Write the failing tests for `--headroom`**

Append to `tests/test_sizing.sh`, immediately **before** the final `print_summary` line:

```bash
# --- v3.3 headroom-aware sizing ---

# headroom below the cap binds: dollars = 900 → floor(900/100)=9, clamped headroom
start_test "size: headroom binds below cap"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 --headroom 900 2>&1)
assert_contains "$out" '"shares": 9'
assert_contains "$out" '"clamped": "headroom"'

# headroom above the cap is ignored: cap 1600 still binds
start_test "size: headroom above cap is ignored"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 --headroom 5000 2>&1)
assert_contains "$out" '"shares": 16'
assert_contains "$out" '"clamped": "cap"'

# headroom so thin the clip lands under the 5% min-pos floor → floor_skip (no dust positions)
start_test "size: headroom under min-pos floor → floor_skip"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 --headroom 400 2>&1)
assert_contains "$out" '"shares": 0'
assert_contains "$out" '"clamped": "floor_skip"'

# omitting --headroom is backward compatible (stock 13% stop, raw 1538 < cap 1600 → uncapped)
start_test "size: no --headroom is backward compatible"
out=$(python3 scripts/sizing.py size --equity 10000 --price 150 --stop-frac 0.13 2>&1)
assert_contains "$out" '"shares": 10'
assert_contains "$out" '"clamped": "none"'

# the SCHW case (blocked live 2026-07-24): after an XLI scale-out frees ~$670, headroom
# ~$1254 vs a raw clip of $1590 → clip shrinks to fit instead of being refused
start_test "size: SCHW case — headroom-fit clip after scale-out frees room"
out=$(python3 scripts/sizing.py size --equity 10335 --price 101.61 --stop-frac 0.13 --headroom 1254 2>&1)
assert_contains "$out" '"shares": 12'
assert_contains "$out" '"clamped": "headroom"'

# the SCHW case at Friday's actual headroom (~$584): 5sh = $508.05 < the $516.75 floor
# → correctly still skipped. Headroom-fit is not a licence to buy dust.
start_test "size: SCHW case — thin headroom still floor_skips"
out=$(python3 scripts/sizing.py size --equity 10335 --price 101.61 --stop-frac 0.13 --headroom 584 2>&1)
assert_contains "$out" '"shares": 0'
assert_contains "$out" '"clamped": "floor_skip"'
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `bash tests/test_sizing.sh`
Expected: FAIL. The `--headroom` tests fail with `unrecognized arguments: --headroom` (argparse exits 2, so `out` contains the usage error and the asserts miss). The updated cap test fails with `'"shares": 16' not in output` because the current default still yields 20 shares.

- [ ] **Step 4: Implement `--headroom` and the 16% default**

In `scripts/sizing.py`, replace `cmd_size` (lines 17–32) entirely with:

```python
def cmd_size(a):
    risk_dollars = a.equity * a.risk_pct
    cap_dollars = a.equity * a.max_pos_pct
    raw_dollars = risk_dollars / a.stop_frac
    clamped = "none"
    dollars = raw_dollars
    if raw_dollars > cap_dollars:
        dollars = cap_dollars
        clamped = "cap"
    # v3.3: shrink the clip to the caller's remaining deployment headroom rather
    # than refusing the entry. Headroom never *raises* a clip — only lowers it.
    # The min-pos floor below still rejects anything that would be a dust position.
    if a.headroom is not None and a.headroom < dollars:
        dollars = a.headroom
        clamped = "headroom"
    shares = math.floor(dollars / a.price)
    cost = shares * a.price
    if shares < 1 or cost < a.equity * a.min_pos_pct:
        return {"shares": 0, "cost": 0.0, "pct_equity": 0.0,
                "clamped": "floor_skip"}
    return {"shares": shares, "cost": round(cost, 2),
            "pct_equity": round(cost / a.equity, 4), "clamped": clamped}
```

Then in `main()`, change the `--max-pos-pct` default and add `--headroom`. Replace line 94:

```python
    s.add_argument("--max-pos-pct", type=float, default=0.16, dest="max_pos_pct")
```

and add immediately after the `--min-pos-pct` line (line 95):

```python
    s.add_argument("--headroom", type=float, default=None,
                   help="remaining deployment dollars to the 85%% ceiling; "
                        "clip shrinks to fit rather than being refused")
```

Finally, update the module docstring usage line (line 8-9) to:

```
  sizing.py size   --equity E --price P --stop-frac S [--risk-pct 0.02]
                   [--max-pos-pct 0.16] [--min-pos-pct 0.05] [--headroom H]
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tests/test_sizing.sh`
Expected: PASS — final line reads `Results: <N> passed, 0 failed`.

- [ ] **Step 6: Update the rulebook**

In `memory/TRADING-STRATEGY.md`, under `## Portfolio Structure (v3 — core/satellite)`, append this bullet after the ETF-core-floor bullet:

```markdown
- **Sizing target is 16% of equity per position (v3.3), not the 20% Rule 3 ceiling.** Rule 3's 20% remains the hard maximum, but `sizing.py size` now defaults `--max-pos-pct` to 0.16 so that five clips fit inside the 85% deployment ceiling. At the prior 20% default a 10%-stop clip sized to exactly 20% of equity, four positions saturated the band, and the mandated 5–6 position book (with up to 3 satellites) was arithmetically unreachable — the sole cause of the empty satellite sleeve across Weeks 12–14.
```

In `## Hard Rules (non-negotiable)`, replace rule 3 with:

```markdown
3. Maximum 20% of equity per position (~$2,000 on a $10K account) — a hard ceiling. Routine sizing targets **16%** (`sizing.py --max-pos-pct 0.16`) so five positions fit under the 85% deployment ceiling *(v3.3)*.
```

- [ ] **Step 7: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh memory/TRADING-STRATEGY.md
git commit -m "feat(v3.3): headroom-aware sizing + 16% sizing cap

The 20% cap and a 10% ETF stop made raw == cap exactly, so four clips
saturated the 75-85% band and the mandated 5-6 position book was
unreachable. Lower the sizing default to 16% and let callers pass the
remaining deployment headroom so a clip shrinks to fit instead of being
refused. The 5% min-pos floor still rejects dust.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Wire headroom into market-open and always log the HOLD path

**Root cause being fixed (part A).** `routines/market-open.md:101` checks the deployment ceiling as a binary pass/fail against a `position_cost` that STEP 5c has not computed yet, then STEP 5c calls `sizing.py size` with no knowledge of headroom. Result: a fully-qualified idea is refused outright whenever a full clip overshoots. Reorder so headroom is computed once in STEP 2, passed to the sizer, and the ceiling gate becomes a post-sizing assertion.

**Root cause being fixed (part B).** `routines/market-open.md:88` sends the HOLD branch to STEP 8, jumping over STEP 7, and STEP 7 (`routines/market-open.md:211`) is scoped "**Filled orders only**". The HOLD path therefore cannot write a TRADE-LOG row by design. This tripped Rule 18 on Jul 8, Jul 14 and Jul 24 (the Jul 24 commit touched only `HEARTBEAT.md`) and has been recommended for repair in three consecutive weekly reviews.

**Files:**
- Modify: `routines/market-open.md:73-79` (STEP 2), `:88` (HOLD branch), `:101` (ceiling gate), `:157-173` (STEP 5c), `:210-233` (STEP 7)
- Modify: `.claude/commands/market-open.md:26-34` (Step 2), `:35-52` (Step 3), `:58-114` (Step 5), `:142-163` (Step 7)

**Interfaces:**
- Consumes: `sizing.py size --headroom H` and the `"clamped": "headroom"` value from Task 1.
- Produces: a guaranteed `- market-open $DATE:` TRADE-LOG row on every execution path — Task 5's daily-summary sweep and Rule 18 both depend on this token existing.

- [ ] **Step 1: Compute headroom in STEP 2**

In `routines/market-open.md`, in `## STEP 2 — Pull live paper-account state`, append after the code block (after line 79):

```markdown
From that payload compute, once, for the whole run *(v3.3)*:

```
DEPLOY_CEILING = 0.85
HEADROOM = (EQUITY * DEPLOY_CEILING) - LONG_MARKET_VALUE
```

`HEADROOM` is the dollar room remaining before the Rule 5 deployment ceiling.
It may be negative (book already over the ceiling) — in that case no buy of any
size is permitted; skip every idea and log
`deployment ceiling: already at X% — no headroom, 0 buys`.
```

- [ ] **Step 2: Turn the ceiling gate into a post-sizing assertion**

In `routines/market-open.md`, replace the deployment-ceiling bullet at line 101 with:

```markdown
- **(v3.1, all ideas — restated v3.3)** Deployment ceiling: this gate no longer refuses an idea pre-sizing. `HEADROOM` (STEP 2) is passed to the sizer in STEP 5c, which shrinks the clip to fit. Here, only skip the idea outright if `HEADROOM <= 0` — log "deployment ceiling: already at X% — no headroom". After sizing, STEP 5c re-asserts `(long_market_value + position_cost) / equity <= 0.85` as a belt-and-braces check and skips + logs if it somehow fails.
```

- [ ] **Step 3: Pass headroom to the sizer in STEP 5c**

In `routines/market-open.md`, replace the code block and the paragraph following it in STEP 5c (lines 163–173) with:

```markdown
```
SLIPPAGE_PCT=${MAX_ENTRY_SLIPPAGE_PCT:-0.10}
SIZE_JSON=$(python3 scripts/sizing.py size \
    --equity "$EQUITY" --price "$LIVE_ASK" --stop-frac "$STOP_FRAC" \
    --headroom "$HEADROOM")
```

Parse `shares`, `cost` and `clamped` from `SIZE_JSON`.

- If `clamped == "floor_skip"` or `shares < 1`: skip the idea and log the reason
  (`floor_skip` = the risk budget, the 16% cap, or the remaining headroom left too
  little to build a position above the 5%-of-equity minimum — a dust position is
  worse than no position).
- If `clamped == "headroom"`: the clip was deliberately shrunk to fit the remaining
  deployment room *(v3.3)*. This is a normal, expected outcome — proceed with the
  order and log `sized to headroom: TICKER N sh ($COST, X.X% of equity, full clip
  would have been $RAW)`.
- If `clamped == "cap"` or `"none"`: full risk-parity or 16%-capped clip; proceed.

Then re-assert the ceiling: `(LONG_MARKET_VALUE + cost) / EQUITY` MUST be `<= 0.85`.
If it is not, skip the idea and log "deployment ceiling re-assert failed" — this
should be unreachable and indicates a headroom computation bug worth a Telegram note.

**Multi-idea runs:** after each order is placed, decrement
`HEADROOM = HEADROOM - cost` before sizing the next idea, so two ideas in one
session cannot each consume the same headroom.

This keeps the same risk-parity logic (2% equity at risk, clamped to the 16% v3.3
sizing target and to remaining headroom) deterministic and unit-tested in
`tests/test_sizing.sh`.
```

- [ ] **Step 4: Make STEP 7 unconditional**

In `routines/market-open.md`, replace the STEP 7 heading and its first paragraph (lines 210–213) with:

```markdown
## STEP 7 — Append entries to `memory/TRADE-LOG.md`

**This step is MANDATORY on every execution path — including a pre-market HOLD,
a gate-rejected-everything run, and a zero-fill run.** Rule 18's cadence sweep
looks for the literal token `- market-open $DATE:` in this file; a run that
writes nothing is indistinguishable from a cron skip. This gap tripped Rule 18
on 2026-07-08, 2026-07-14 and 2026-07-24.

**Always, first — the Market-Open Run row.** Before any per-order rows, append:

```
## $DATE — Market-Open Run (Day N, <Weekday>, Week W Day D)

- market-open $DATE: <N> orders placed, <K> filled. Pre-market Decision=<TRADE|HOLD>.
  <One paragraph: for each idea, whether it passed or which gate rejected it and by
  how much; HEADROOM at STEP 2; deployment %, ETF-core % of deployed, sector spread;
  satellite slots used; week trade budget used/5; Rule 13/14/15 applicability.>
```

On a HOLD or zero-order run this row is the *entire* output of the step — write it
and proceed to STEP 8. Never skip STEP 7.

**Filled orders** — additionally append a full TRADE row matching the schema at the
top of `TRADE-LOG.md`:
```

- [ ] **Step 5: Fix the HOLD branch's jump target**

In `routines/market-open.md`, replace the HOLD bullet at line 88 with:

```markdown
- If `Decision: HOLD` → send Telegram "market-open $DATE (paper) — pre-market HOLD decision: no orders placed", then skip to **STEP 7** (NOT STEP 8 — STEP 7 must still write the mandatory Market-Open Run row, or Rule 18 will report a false cron skip).
```

- [ ] **Step 6: Port all five edits to the mirror**

Apply the equivalent, condensed edits to `.claude/commands/market-open.md`:

In `## Step 2 — Pull state`, append:

```markdown
Then compute once for the run *(v3.3)*: `HEADROOM = (EQUITY * 0.85) - LONG_MARKET_VALUE`.
If `HEADROOM <= 0`, no buy of any size is permitted — skip all ideas.
```

In `## Step 3 — Apply buy-side gate`, replace the deployment-ceiling bullet with:

```markdown
- **(v3.1, restated v3.3)** Deployment ceiling: no longer a pre-sizing refusal. `HEADROOM` is passed to the sizer in Step 5, which shrinks the clip to fit. Skip outright only if `HEADROOM <= 0`.
```

In `## Step 5 — Per-idea loop: quote, size, limit`, add a `**5c. Compute position size**` block:

```markdown
**5c. Compute position size**

```
SIZE_JSON=$(python3 scripts/sizing.py size --equity "$EQUITY" --price "$LIVE_ASK" \
    --stop-frac "$STOP_FRAC" --headroom "$HEADROOM")
```

`clamped == "floor_skip"` or `shares < 1` → skip + log. `clamped == "headroom"` →
clip deliberately shrunk to fit; proceed and log it. Re-assert
`(LONG_MARKET_VALUE + cost) / EQUITY <= 0.85`. After each order, decrement
`HEADROOM = HEADROOM - cost`.
```

In `## Step 7 — Append to `memory/TRADE-LOG.md` (locally)`, replace the first line with:

```markdown
**MANDATORY on every path — including HOLD and zero-fill.** Always write the run row
first (Rule 18 looks for the literal `- market-open $DATE:` token):

```
## $DATE — Market-Open Run (Day N, <Weekday>, Week W Day D)

- market-open $DATE: <N> orders placed, <K> filled. Pre-market Decision=<TRADE|HOLD>.
  <gate outcomes per idea, HEADROOM, deployment %, core %, sector spread, week budget>
```

**Filled orders** — additionally append a full TRADE row using the schema at the top of TRADE-LOG.md:
```

- [ ] **Step 7: Verify no other path skips STEP 7**

Run: `grep -n "skip to STEP 8\|skip to Step 8\|STEP 8 with no orders" routines/market-open.md`
Expected: the only remaining match is in STEP 4 (`may be zero — in which case skip to STEP 8 with no orders placed`). Fix that one too — replace it with `may be zero — in which case skip to STEP 7 (which still writes the mandatory Market-Open Run row) with no orders placed`. Re-run the grep; expected: no matches that bypass STEP 7.

- [ ] **Step 8: Commit**

```bash
git add routines/market-open.md .claude/commands/market-open.md
git commit -m "feat(v3.3): headroom-fit sizing + mandatory market-open run row

Pass STEP 2's computed HEADROOM to sizing.py so a clip shrinks to fit the
85% ceiling instead of being refused (SCHW cleared all 11 gates on Jul 24
and was rejected on headroom alone). Decrement headroom between ideas.

STEP 7 was scoped 'filled orders only' and the HOLD branch jumped to STEP
8, so a HOLD run wrote nothing and Rule 18 reported a false cron skip on
Jul 8/14/24. STEP 7 is now mandatory on every path.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: `alpaca.sh dtc` — surface day-trade count with an explicit source

**Root cause being fixed.** The Alpaca paper `/account` payload omits `daytrade_count`. Routines log "field ABSENT — treated 0/5" and proceed (TRADE-LOG 2026-07-20, 07-21, 07-23, 07-27). Rule 14 — the single gate protecting the user's visa status — has therefore never actually executed a check in fourteen weeks, and it fails *open*. This task adds a wrapper subcommand that reports the value **and whether it is real**; Task 4 wires the routines to act on that distinction.

**Files:**
- Modify: `scripts/alpaca.sh:50-52` (add `dtc` next to `account`), `scripts/alpaca.sh:177-179` (usage line), `scripts/alpaca.sh:5-6` (header comment)
- Modify: `tests/test_alpaca.sh` (append tests before `print_summary`)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `bash scripts/alpaca.sh dtc` → exactly one JSON object on stdout, one of:
  - `{"daytrade_count": <int>, "source": "api"}` — the field was present and numeric
  - `{"daytrade_count": null, "source": "unavailable"}` — the field was absent or null
  Task 4 branches on `source`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_alpaca.sh`, immediately **before** the final `rm -rf tests/.tmp/alp.*` and `print_summary` lines:

```bash
# Test: dtc is a read-only subcommand — allowed even with the kill switch off
start_test "dtc is read-only (not blocked by TRADING_ENABLED=false)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="false"
    bash scripts/alpaca.sh dtc 2>&1
)
# Not refused by the kill switch, AND not fallen through to the unknown-subcommand
# usage branch (which is how this test fails before the case arm exists).
assert_not_contains "$out" "REFUSED"
assert_not_contains "$out" "Usage: bash scripts/alpaca.sh"

# Test: dtc appears in the usage line
start_test "dtc listed in usage"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    bash scripts/alpaca.sh bogus-subcommand 2>&1
)
assert_contains "$out" "dtc"

# The next two tests mirror the parser embedded in `alpaca.sh dtc` rather than
# invoking it, because the real subcommand curls Alpaca first and these must run
# offline with no credentials. The mirrored block is the parser's CONTRACT under
# test — if you change the parser in alpaca.sh, change it here too. Keep the two
# byte-identical; that coupling is the point, not an accident.

# Test: the dtc parser reports source=unavailable when the field is absent
start_test "dtc parser: absent field → source unavailable"
out=$(echo '{"equity":"10000","cash":"2000"}' | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
v = d.get("daytrade_count")
if v is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": int(v), "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "unavailable"'
assert_contains "$out" '"daytrade_count": null'

# Test: the dtc parser reports source=api when the field is present
start_test "dtc parser: present field → source api"
out=$(echo '{"equity":"10000","daytrade_count":3}' | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
v = d.get("daytrade_count")
if v is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": int(v), "source": "api"}))
' 2>&1)
assert_contains "$out" '"source": "api"'
assert_contains "$out" '"daytrade_count": 3'
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_alpaca.sh`
Expected: FAIL — `dtc is read-only` and `dtc listed in usage` both fail (the subcommand falls through to the `*)` usage branch, which does not yet mention `dtc`). The two parser tests pass already (they test the inline Python, which is the exact code Step 3 embeds).

- [ ] **Step 3: Implement the `dtc` subcommand**

In `scripts/alpaca.sh`, insert immediately after the `account)` case block (after line 52, before `positions)`):

```bash
    dtc)
        # Rule 14 support (v3.3): emit the day-trade count AND whether it is real.
        # The paper /account payload omits daytrade_count entirely; routines used to
        # log "field absent, treated 0" and proceed, which made the visa-critical
        # Rule 14 gate fail OPEN. Callers must branch on "source".
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/account" | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
v = d.get("daytrade_count")
if v is None:
    print(json.dumps({"daytrade_count": None, "source": "unavailable"}))
else:
    print(json.dumps({"daytrade_count": int(v), "source": "api"}))
'
        ;;
```

Update the header comment on line 6 to:

```bash
#   account, dtc, positions, position SYM, quote SYM, orders [status]
```

Update the usage line (line 178) to:

```bash
        echo "Usage: bash scripts/alpaca.sh <account|dtc|positions|position|quote|orders|order|cancel|cancel-all|close|close-all|trailing-stop|replace-stop|activities|bars|scale-out> [args]" >&2
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_alpaca.sh`
Expected: PASS — final line reads `Results: <N> passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/alpaca.sh tests/test_alpaca.sh
git commit -m "feat(v3.3): alpaca.sh dtc reports day-trade count with source

The paper /account payload omits daytrade_count, so Rule 14 - the gate
protecting visa status - has never actually run a check and fails open.
The new read-only dtc subcommand distinguishes a real count (source=api)
from an absent one (source=unavailable) so callers can fail safe.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Make Rule 14 fail safe instead of fail open

**Root cause being fixed.** With `daytrade_count` absent, `routines/midday.md:68` captures `DTC` as nothing and the routine proceeds as if it were 0. Blocking all sells when the field is missing would be worse — it would strand a -7% loser — so the fallback is a *locally derived* count from TRADE-LOG.md. Rules 13 and 15 make a day trade structurally impossible, so the local count should always be 0; a non-zero local count is itself an alarm worth surfacing.

**Files:**
- Modify: `routines/midday.md:34-36` (Rule 14 preamble), `:60-79` (STEP 2)
- Modify: `routines/market-open.md:103-107` (the DTC buy-side gate bullet)
- Modify: `.claude/commands/midday.md` (Step 2 equivalent), `.claude/commands/market-open.md:35-39` (Step 3 DTC text)
- Modify: `memory/TRADING-STRATEGY.md` (Rule 14)

**Interfaces:**
- Consumes: `bash scripts/alpaca.sh dtc` → `{"daytrade_count", "source"}` from Task 3.
- Produces: the variables `DTC` (integer) and `DTC_SOURCE` (`api` | `local` | `none`), and the log token `Rule 14 DTC: N (source=api|local|none)`. Task 5's catch-up path re-uses this same pre-flight.

- [ ] **Step 1: Replace midday's DTC capture with the three-source resolution**

In `routines/midday.md`, replace the code block and the two paragraphs under `## STEP 2 — Pull live paper-account state` (lines 62–79) with:

```markdown
```
bash scripts/alpaca.sh dtc         # day-trade count + source (CRITICAL for Rule 14)
bash scripts/alpaca.sh account     # equity
bash scripts/alpaca.sh positions   # current positions with avg_entry_price + market_value
bash scripts/alpaca.sh orders open # open trailing-stop orders (for replace-stop)
```

**Resolve `DTC` and `DTC_SOURCE` (Rule 14, v3.3 — fail safe, never fail open):**

1. Parse `bash scripts/alpaca.sh dtc`. If `source == "api"`, set `DTC` to
   `daytrade_count` and `DTC_SOURCE=api`. Done.
2. If `source == "unavailable"` (the paper endpoint omits the field), derive the
   count locally: scan `memory/TRADE-LOG.md` over the **last 5 business days** and
   count tickers that have BOTH a `side=buy` row AND a `side=sell` / `SCALE-OUT` /
   `ROTATE-EXIT` row dated the **same calendar day**. That count is `DTC`, with
   `DTC_SOURCE=local`. Rules 13 and 15 make this structurally 0 — if it is **not**
   0, send a Telegram URGENT ("Rule 14: local day-trade count is N — Rule 13/15 may
   have been bypassed") and treat it as a genuine DTC.
3. If TRADE-LOG.md cannot be read at all, set `DTC_SOURCE=none`. **Block every
   routine-initiated sell**, send Telegram URGENT ("Rule 14: day-trade count
   unresolvable — sells blocked, manual review required"), and continue with
   non-sell actions only (stop tightenings are not sells and remain permitted;
   already-placed GTC stops are unaffected).

Never record "field absent, treated 0". Every routine that evaluates Rule 14 MUST
log the literal token `Rule 14 DTC: <N> (source=api|local|none)` in its TRADE-LOG
row so the weekly review can audit whether the gate was genuinely exercised.

If `DTC >= 2` (from any source), jump immediately to the abort path described in
Rule 14 (skip steps 3–6, write the abort note to TRADE-LOG.md, Telegram URGENT,
commit, exit).

On DTC abort, append to memory/TRADE-LOG.md:
```
### YYYY-MM-DD — MIDDAY ABORT: daytrade_count=N (source=api|local|none)
- Reason: Rule 14 pre-flight tripped (DTC >= 2, or source=none)
- Pending actions skipped: <list of would-be actions>
- Resolution: manual human review required
```
```

- [ ] **Step 2: Update midday's Rule 14 preamble**

In `routines/midday.md`, replace the Rule 14 bullet (lines 34–36) with:

```markdown
- **Rule 14 (pre-flight):** Before placing ANY sell, you MUST resolve `DTC` and
  `DTC_SOURCE` per STEP 2 *(v3.3 — `alpaca.sh dtc`, with a TRADE-LOG-derived
  fallback; never treat an absent field as 0)*. If `DTC >= 2` OR
  `DTC_SOURCE == none`, ABORT all sell actions, send a Telegram URGENT alert
  "midday $DATE: aborted sells, daytrade_count=N source=S",
```

Leave the remainder of that bullet (the text that follows on line 36 and after) unchanged.

- [ ] **Step 3: Update market-open's DTC gate**

In `routines/market-open.md`, replace the DTC gate bullet and its WHY block (lines 103–107) with:

```markdown
- Resolve `DTC` / `DTC_SOURCE` via `bash scripts/alpaca.sh dtc` using the same
  three-source procedure as midday STEP 2 *(v3.3)*. `DTC` MUST be ≤ 1 to allow new
  entries (Rule 14 buffer). If `DTC_SOURCE == none`, allow buys but log the
  degraded state — a buy cannot itself create a day trade (Rule 13 defers the stop
  to market close), so this gate fails safe on the buy side.
  WHY: a buy today could trigger a stop-fired sell tomorrow, bumping DTC by 1; a
  buffer of 1 keeps us well below the FINRA PDT threshold of 4 day trades in 5
  rolling business days even if a same-day stop fires unexpectedly (rare but
  possible if Rule 13 is bypassed in an edge case).
```

- [ ] **Step 4: Update the rulebook**

In `memory/TRADING-STRATEGY.md`, replace rule 14 in `## Hard Rules (non-negotiable)` with:

```markdown
14. **Pre-flight `daytrade_count` check before every sell.** *(v2, visa-aware; hardened v3.3)* Before placing any sell order — midday hard-close, sector-kill, Rule 18 catch-up, weekly-review-proposed close, manual `/trade` invocation — the routine MUST resolve the day-trade count via `bash scripts/alpaca.sh dtc`, which returns `{"daytrade_count", "source"}`. Resolution order: (a) `source=api` → use it; (b) `source=unavailable` (the paper endpoint omits the field) → derive the count from `TRADE-LOG.md` over the last 5 business days by counting tickers with a buy and a sell on the same calendar day, `source=local` — Rules 13/15 make this structurally 0, so a non-zero result is itself an URGENT-worthy alarm; (c) neither available → `source=none`, **block all routine-initiated sells** and send Telegram URGENT (already-placed GTC stops are unaffected; stop tightenings are not sells and remain permitted). If `daytrade_count >= 2`, abort the sell, send a Telegram URGENT alert, and require human review. **An absent field must NEVER be silently treated as 0** — that made this gate fail open for the whole of Weeks 1–14, during which it never once actually executed. Every routine evaluating this rule MUST log `Rule 14 DTC: <N> (source=api|local|none)` so the weekly review can audit that the gate ran. PDT triggers at 4 in 5 rolling business days; the 2-buffer leaves room for one accidental day trade without immediately blocking all sells.
```

- [ ] **Step 5: Port to the mirrors**

In `.claude/commands/midday.md`, find the Step 2 block that captures `DTC` from `account` and replace its DTC sentence with:

```markdown
Resolve Rule 14 via `bash scripts/alpaca.sh dtc` *(v3.3)*: `source=api` → use the
value; `source=unavailable` → derive locally from TRADE-LOG.md (same-day buy+sell
pairs over the last 5 business days, `source=local`, structurally 0 under Rules
13/15 — non-zero is URGENT); unreadable → `source=none`, block all sells + URGENT.
Never treat an absent field as 0. Log `Rule 14 DTC: <N> (source=...)`.
If `DTC >= 2` or `source=none`, abort sells.
```

In `.claude/commands/market-open.md`, replace the first paragraph of `## Step 3 — Apply buy-side gate` with:

```markdown
Per `TRADING-STRATEGY.md`. Resolve `DTC`/`DTC_SOURCE` via `bash scripts/alpaca.sh dtc`
*(v3.3, same three-source procedure as midday)*. Reject ideas where `DTC > 1` to
preserve the Rule 14 buffer (a buy today + a stop-triggered sell tomorrow could
bump DTC; buffer of 1 keeps us well below the FINRA PDT threshold of 4 day
trades in 5 rolling business days even if a same-day stop fires unexpectedly).
`source=none` allows buys but must be logged — a buy cannot itself create a day
trade because Rule 13 defers the stop to market close.
```

- [ ] **Step 6: Verify no "treated 0" language survives**

Run: `grep -rn "treated 0\|treat.*absent.*0\|field ABSENT" routines/ .claude/commands/ memory/TRADING-STRATEGY.md`
Expected: no matches in `routines/`, `.claude/commands/`, or `TRADING-STRATEGY.md`. (Matches inside `memory/TRADE-LOG.md` are historical log entries — leave them.)

Run: `bash tests/test_sizing.sh && bash tests/test_alpaca.sh`
Expected: both report `0 failed` (this task changes no code paths under test, but the suites must stay green).

- [ ] **Step 7: Commit**

```bash
git add routines/midday.md routines/market-open.md \
        .claude/commands/midday.md .claude/commands/market-open.md \
        memory/TRADING-STRATEGY.md
git commit -m "fix(v3.3): Rule 14 fails safe instead of fail open

Routines logged 'daytrade_count field ABSENT - treated 0/5' and proceeded,
so the visa-critical gate never actually executed in 14 weeks. Resolve the
count via alpaca.sh dtc with a TRADE-LOG-derived fallback, and block sells
outright when it is unresolvable. Always log the source so the weekly
review can audit that the gate ran.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Rule 18 recovers instead of only reporting

**Root cause being fixed.** `routines/daily-summary.md:63-71` sends a Telegram and writes a `MISSING ROUTINE` placeholder, then continues. On 2026-07-22 the midday cron genuinely did not fire (no commit exists) and the Rule 7 hard-close, Rule 8 ladder and Rule 16 decay evaluations were simply never run — the Rule 16 consecutiveness chain was left ambiguous for a day, as the Jul 23 market-open row records. Three genuine skips occurred in eleven sessions (Jul 16 market-open, Jul 21 market-open, Jul 22 midday). Detection without recovery is not a guardrail.

**Design.** daily-summary runs at 15:00 CT, at the close. Stop *replacements* are GTC orders with no fill risk and no day-trade impact, so they execute immediately. Market *sells* at the closing bell have real fill risk, so they are deferred to the next market-open via a `CATCH-UP PENDING` marker — which is also safe under Rule 15, because any position eligible at T's close is aged by T+1's open.

**Files:**
- Modify: `routines/daily-summary.md:55-72` (STEP 0)
- Modify: `routines/market-open.md` (insert a new STEP 0 before `## STEP 1`, line 59)
- Modify: `.claude/commands/daily-summary.md:10-25` (STEP 0), `.claude/commands/market-open.md:13` (before Step 1)
- Modify: `memory/TRADING-STRATEGY.md` (Rule 18)

**Interfaces:**
- Consumes: `sizing.py ladder` / `decay` / `scaleout` (existing), the `DTC`/`DTC_SOURCE` pre-flight from Task 4, and the guaranteed `- market-open $DATE:` token from Task 2.
- Produces: two new TRADE-LOG row types, `CATCH-UP PENDING` and `CATCH-UP CLEARED`, keyed by ticker. A `CATCH-UP PENDING` row is *unresolved* when no later `CATCH-UP CLEARED` row names the same ticker.

- [ ] **Step 1: Replace daily-summary STEP 0 with detect-then-recover**

In `routines/daily-summary.md`, replace everything from `## STEP 0 — Rule 18: cadence sweep (FIRST action, v3.2)` through the line `Then continue to STEP 1. If all three logged, proceed silently.` (lines 55–72) with:

```markdown
## STEP 0 — Rule 18: cadence sweep + catch-up (FIRST action, v3.2; recovery added v3.3)

Before pulling state, resolve `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` and verify today's
prior routines logged. On a US market holiday (no session) skip this sweep — the routines
correctly no-op.
- **pre-market** → `memory/RESEARCH-LOG.md` MUST have a `$DATE` entry.
- **market-open** → `memory/TRADE-LOG.md` MUST have a `market-open $DATE` row.
- **midday** → `memory/TRADE-LOG.md` MUST have a `$DATE — Midday Run` row.

For each missing routine, send the alert and write the placeholder as before:
```
bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — MISSING ROUTINE: <name> did not log today. Investigate cron. (Rule 18)"
```
```
### $DATE — MISSING ROUTINE: <name> (Rule 18 cadence guardrail)
- No <name> entry found for $DATE at daily-summary sweep; cron skip suspected. Investigate.
```

**Then, if the missing routine is `midday`, RUN ITS EVALUATION NOW (v3.3 catch-up).**
A missed midday is a missed Rule 7 hard-close, a missed Rule 8 ladder step and a
break in the Rule 16 consecutiveness chain — detection alone let all three lapse on
2026-07-22. Pull `bash scripts/alpaca.sh positions` and `bash scripts/alpaca.sh orders open`
early (before STEP 2 if needed) and execute midday's STEP 3 + STEP 4 decision logic
verbatim — same Rule 15 same-day filter, same `sizing.py ladder` / `scaleout` / `decay`
calls, same Rule 14 pre-flight (Task 4's `DTC` / `DTC_SOURCE` resolution). Then split
the outcome by whether it requires a market sell:

- **Stop tightenings (Rule 8 `target_trail_pct`) — EXECUTE NOW.** `bash scripts/alpaca.sh
  replace-stop OID TICKER QTY $target_trail_pct`. A stop replacement is a GTC order,
  not a sell: no fill risk at the close, no `DTC` impact, and Rule 9 still applies
  (only ever tighten, never within 3% of price). Log the normal `STOP UPDATE` row with
  `(Rule 18 catch-up)` appended to its Trigger line.
- **`DECAY-FLAG` rows (Rule 16) — ALWAYS WRITE.** This is the state the next midday
  reads for consecutiveness; skipping it is what left the chain ambiguous on Jul 22.
  Write the row exactly as midday would.
- **Market sells (Rule 7 hard-close, Rule 16 `rotate == 1`, Rule 10 sector-kill) —
  DEFER.** Do NOT sell at the closing bell; fill quality is poor and the order may not
  complete. Instead write one row per ticker:
```
### $DATE — CATCH-UP PENDING: TICKER action=<hard-close|rotate-exit|sector-kill>
- Missed midday $DATE (Rule 18). Evaluation run at daily-summary; a sell is owed.
- Trigger: <Rule 7 unrealized -X% | Rule 16 2nd consecutive decay flag | Rule 10 sector S>
- Deferred to next market-open STEP 0 (closing-bell fill risk). Position is aged → Rule 15 safe.
```
  and send `bash scripts/telegram.sh "🚨 URGENT $DATE (paper) — CATCH-UP PENDING: TICKER <action> owed from missed midday; next market-open will execute. (Rule 18)"`.

If `market-open` is the missing routine, no catch-up is possible — the entry window has
closed. Write the placeholder only.

Then continue to STEP 1. If all three logged, proceed silently.
```

- [ ] **Step 2: Add STEP 0 to market-open to clear pending catch-ups**

In `routines/market-open.md`, insert immediately before `## STEP 1 — Read memory for context` (line 59):

```markdown
## STEP 0 — Rule 18: clear pending catch-ups (FIRST action, v3.3)

Before reading research or gating any idea, scan the tail of `memory/TRADE-LOG.md`
for **unresolved** `CATCH-UP PENDING` rows — a `CATCH-UP PENDING: TICKER` row with no
later `CATCH-UP CLEARED: TICKER` row for the same ticker. These are sells that a
missed midday owed and that daily-summary deferred rather than execute at the
closing bell.

For each unresolved row, in order:

1. **Re-evaluate against live state.** Pull `bash scripts/alpaca.sh positions`. If the
   ticker is no longer held (its GTC trailing stop fired overnight), the sell is moot:
   write `CATCH-UP CLEARED: TICKER reason=already-exited` and move on.
2. **Re-check the trigger.** Recompute the condition that raised it (Rule 7
   `unrealized_pl_pct <= -7`; Rule 16 via `sizing.py decay`; Rule 10 sector-kill).
   If it no longer holds — the position recovered overnight — write
   `CATCH-UP CLEARED: TICKER reason=trigger-no-longer-met` and move on. Do not sell.
3. **Otherwise execute the sell.** Apply the full Rule 14 pre-flight (`DTC`/`DTC_SOURCE`
   per STEP 3; abort on `DTC >= 2` or `DTC_SOURCE == none`) and the Rule 15 same-day
   filter (a catch-up position is aged by construction — it was open at yesterday's
   close — so Rule 15 cannot block it, but verify rather than assume). Then
   `bash scripts/alpaca.sh close TICKER` (or the sector-kill batch for Rule 10).
   Write the normal EXIT row, then `CATCH-UP CLEARED: TICKER reason=executed`.

Row format:
```
### $DATE — CATCH-UP CLEARED: TICKER reason=<executed|already-exited|trigger-no-longer-met>
- Resolves the CATCH-UP PENDING row of <original date>.
```

Send one Telegram per cleared row. If there are no unresolved rows, proceed silently
to STEP 1.
```

- [ ] **Step 3: Update the rulebook**

In `memory/TRADING-STRATEGY.md`, replace rule 18 in `## Hard Rules (non-negotiable)` with:

```markdown
18. **Cadence guardrail with catch-up (v3.2; recovery added v3.3, operational, visa-neutral).** Every routine writes to its log every trading day even on a HOLD or no-op decision. Detection is enforced by the *next* routine: as its FIRST action it scans the current day's expected prior-routine log entries and, for any that is missing, (a) sends a Telegram **URGENT** naming the missing routine, and (b) writes a `MISSING ROUTINE — investigate cron` placeholder row to that routine's log. `daily-summary` performs the full-day sweep (pre-market → RESEARCH-LOG, market-open + midday → TRADE-LOG); `pre-market` additionally verifies the *prior* trading day's `daily-summary` EOD snapshot exists. **Detection alone is not sufficient (v3.3):** when the missing routine is `midday`, daily-summary MUST also RUN midday's evaluation — Rule 7, Rule 8 and Rule 16 — because a skipped midday is a skipped stop-loss and a broken decay chain (2026-07-22). Stop tightenings and `DECAY-FLAG` state rows execute immediately (GTC orders, no fill risk, no day-trade impact). Market sells are deferred to the next `market-open`, which clears them from its own STEP 0 via `CATCH-UP PENDING` / `CATCH-UP CLEARED` rows, re-validating the trigger against live state and applying the full Rule 14 pre-flight before selling. Deferring avoids closing-bell fill risk; the deferred position is aged by construction, so Rule 15 is satisfied. Rule 18 itself never originates a trade — it only re-runs evaluations that were already owed.
```

- [ ] **Step 4: Port to the mirrors**

In `.claude/commands/daily-summary.md`, replace the line `Then continue to STEP 1. If all three logged, proceed silently.` with:

```markdown
**v3.3 catch-up:** if the missing routine is `midday`, also RUN midday's Step 3+4
evaluation now. Execute stop tightenings immediately (`replace-stop` — GTC, no fill
risk, no DTC impact) and always write `DECAY-FLAG` rows (the Rule 16 consecutiveness
state). Do NOT market-sell at the bell — instead write, per ticker:

```
### $DATE — CATCH-UP PENDING: TICKER action=<hard-close|rotate-exit|sector-kill>
- Missed midday $DATE (Rule 18). Sell owed; deferred to next market-open STEP 0.
- Trigger: <condition>
```

and send an URGENT Telegram. A missing `market-open` gets a placeholder only — the
entry window has closed.

Then continue to Step 1. If all three logged, proceed silently.
```

In `.claude/commands/market-open.md`, insert immediately before `## Step 1 — Read memory`:

```markdown
## Step 0 — Rule 18: clear pending catch-ups (v3.3)
Scan the TRADE-LOG tail for unresolved `CATCH-UP PENDING: TICKER` rows (no later
`CATCH-UP CLEARED` for that ticker). For each: if no longer held → clear
`reason=already-exited`; if the trigger no longer holds → clear
`reason=trigger-no-longer-met`; else apply the Rule 14 pre-flight and Rule 15 check,
`bash scripts/alpaca.sh close TICKER`, write the EXIT row, then clear
`reason=executed`. Telegram once per cleared row. Silent if none.
```

- [ ] **Step 5: Verify the sweep tokens still match what the producers write**

The sweep only works if its search strings match real output. Verify each against the log:

Run: `grep -c "^- market-open 2026-07-27:" memory/TRADE-LOG.md`
Expected: `1` — confirms the `market-open $DATE` token Task 2 now guarantees.

Run: `grep -c "^## 2026-07-27 — Midday Run" memory/TRADE-LOG.md`
Expected: `1` — confirms the `$DATE — Midday Run` token.

Run: `grep -c "^## 2026-07-27" memory/RESEARCH-LOG.md`
Expected: `1` — confirms the pre-market `$DATE` token.

If any returns `0`, the sweep string in STEP 0 is wrong and must be corrected to match
the producer before this task is complete. (The v3.2 round shipped an EOD-header
mismatch of exactly this kind — ISO dates vs `MMM DD` — so do not skip this step.)

- [ ] **Step 6: Run the test suites**

Run: `bash tests/test_sizing.sh && bash tests/test_alpaca.sh`
Expected: both report `0 failed`.

- [ ] **Step 7: Commit**

```bash
git add routines/daily-summary.md routines/market-open.md \
        .claude/commands/daily-summary.md .claude/commands/market-open.md \
        memory/TRADING-STRATEGY.md
git commit -m "feat(v3.3): Rule 18 catch-up — recover, don't just report

Jul 22's midday cron genuinely never fired and Rules 7/8/16 were never
evaluated; the decay chain was left ambiguous for a day. daily-summary now
runs the missed midday evaluation: stop tightenings and DECAY-FLAG rows
execute immediately, market sells defer to the next market-open via
CATCH-UP PENDING/CLEARED rows to avoid closing-bell fill risk.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Benchmark from SPY bars instead of web search

**Root cause being fixed.** `routines/weekly-review.md:96` sources the S&P 500 week return "from Perplexity if available". Week 13's review silently revised the Jul 17 SPX close from 7,533.77 to 7,457.69 — a 1.0% correction, larger than three of the last four weekly alpha figures — and Week 13's own stats line flags the Jul 24 close as "single-source" and describes discarding a Perplexity figure as "internally inconsistent". Every alpha number in the record, and therefore the real-money decision itself, rests on this. `alpaca.sh bars SPY` is already available, deterministic, and the same source the bot uses for its own returns.

**Note on SPY vs SPX:** SPY is a price proxy and will differ from the SPX index by a small, slowly-varying amount (dividends, tracking). That is acceptable and in fact preferable here — alpha is a *week-over-week comparison*, so a consistent source matters more than absolute index fidelity, and the bot's own return is measured on tradeable prices too.

**Files:**
- Modify: `routines/weekly-review.md:76-86` (STEP 2 state pull), `:96-98` (the three benchmark metric rows)
- Modify: `.claude/commands/weekly-review.md` (equivalent metric rows)

**Interfaces:**
- Consumes: `bash scripts/alpaca.sh bars SPY 1Day <count>` (existing wrapper subcommand, read-only).
- Produces: no new interfaces; changes only how three grade-card rows are computed.

- [ ] **Step 1: Add the SPY bars pull to STEP 2**

In `routines/weekly-review.md`, append to the code block in STEP 2 (after the `activities` line, before the closing fence at line 85):

```
# Benchmark (v3.3): SPY daily bars are the single source of truth for the weekly
# S&P comparison. 10 bars covers a 5-session week plus margin for holidays.
bash scripts/alpaca.sh bars SPY 1Day 10
```

- [ ] **Step 2: Replace the three benchmark metric rows**

In `routines/weekly-review.md`, replace the three table rows at lines 96–98 with:

```markdown
| S&P 500 week | **From `alpaca.sh bars SPY 1Day 10` (v3.3) — never from web search.** Take the SPY close on the prior review's ending date (`prior_close`) and the most recent SPY close (`last_close`); `spy_week_return = (last_close - prior_close) / prior_close * 100`. Report as `X.XX% (SPY $A → $B, Alpaca bars)`. If the prior review's ending date is not present in the 10 bars (long holiday gap), pull `bars SPY 1Day 20` and retry; only if that also fails, mark "n/a" — do NOT substitute a web-sourced figure |
| Bot vs S&P | `week_return - spy_week_return` (positive = beat the market). Both legs now come from Alpaca prices, so the comparison is internally consistent |
| Alpha vs SPX (v3) | same as Bot vs S&P — state explicitly as the headline alpha number. **Never revise a prior week's benchmark figure** *(v3.3)*: with a deterministic source there is nothing to reconcile, and silently restating history (as happened to the Jul 17 close, revised 7,533.77 → 7,457.69) makes the rolling alpha series meaningless. If a prior figure looks wrong, add a footnote — do not overwrite it |
```

- [ ] **Step 3: Add a benchmark-source note to the review body**

In `routines/weekly-review.md`, immediately after the metric table in STEP 3, add:

```markdown
**Benchmark provenance (v3.3).** The `S&P 500 week` figure MUST cite its two SPY
closes and their dates inline, e.g. `+0.34% (SPY $748.32 Jul 17 → $750.87 Jul 24,
Alpaca bars)`. A Perplexity or WebSearch index level may be quoted alongside as a
sanity check, but it is never the number of record; if the two diverge by more than
0.25pp, note the divergence and keep the Alpaca figure.
```

- [ ] **Step 4: Port to the mirror**

In `.claude/commands/weekly-review.md`, find the `S&P 500 week` metric row and replace it (and the `Bot vs S&P` / `Alpha vs SPX` rows if present) with:

```markdown
| S&P 500 week | **`bash scripts/alpaca.sh bars SPY 1Day 10` (v3.3) — never web search.** `(last_close - prior_review_close) / prior_review_close * 100`. Cite both SPY closes and dates inline. Mark "n/a" rather than substituting a web figure |
| Bot vs S&P | `week_return - spy_week_return`; both legs from Alpaca prices |
| Alpha vs SPX (v3) | same as Bot vs S&P. **Never revise a prior week's benchmark figure** — footnote instead |
```

- [ ] **Step 5: Verify the wrapper returns usable SPY bars**

Run: `grep -n "bars)" -A 14 scripts/alpaca.sh | head -20`
Expected: the `bars` case sets a `start` window and trims to the last N bars (the v3 fix for Alpaca returning `null` on a limit-only request). Confirm the subcommand signature is `bars SYM [timeframe] [count]`, matching the `bars SPY 1Day 10` call added in Step 1.

- [ ] **Step 6: Commit**

```bash
git add routines/weekly-review.md .claude/commands/weekly-review.md
git commit -m "fix(v3.3): benchmark from SPY bars, not web search

Week 13 silently revised the Jul 17 SPX close 7,533.77 -> 7,457.69, a 1.0%
correction larger than three of the last four weekly alphas. Source the
benchmark from alpaca.sh bars SPY instead - deterministic, same prices the
bot trades on, and consistent week over week. Prior figures are footnoted,
never overwritten.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: Break the RS-screen catch-22

**Root cause being fixed.** `routines/pre-market.md:116` requires 10- *and* 50-session relative strength vs SPY to be positive. In practice this creates a contradiction with the analyst's own judgement, visible across Weeks 12–14: names that pass RS10 are by construction extended, and the market-open row then rejects them as chase risk ("AMG still extended ~+8%/10-sessions → chase risk", Jul 17 and Jul 20); names that have pulled back into a buyable base fail RS10 ("AMG ret10 −5.32% → RS10 −5.40pp now LAGGING SPY", Jul 22; "APH ret10 −0.45% → RS10 −0.72pp… same failure mode as AMG", Jul 23). The sleeve sat at 0/3 for three weeks. The fix keeps the medium-term leadership requirement absolutely intact and admits one specific, bounded exception: a constructive pullback to a rising 50-DMA.

**Files:**
- Modify: `scripts/sizing.py` (add `cmd_rscreen` + subparser)
- Modify: `tests/test_sizing.sh` (append tests before `print_summary`)
- Modify: `routines/pre-market.md:114-118` (satellite screen)
- Modify: `.claude/commands/pre-market.md` (satellite screen equivalent)
- Modify: `memory/TRADING-STRATEGY.md` (satellite checklist)

**Interfaces:**
- Consumes: `LADDERS` and the existing `main()` subparser pattern in `sizing.py`.
- Produces: `sizing.py rscreen --rs10 X --rs50 Y --close C --dma50 D --dma50-prior P` → JSON `{"pass": 0|1, "reason": "rs50_negative"|"rs10_positive"|"constructive_pullback"|"rs10_negative_extended"}`. Consumed by `routines/pre-market.md` only.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_sizing.sh`, immediately **before** the final `print_summary` line:

```bash
# --- v3.3 rscreen: medium-term leadership required; short-term pullback tolerated ---

# RS50 negative → rejected regardless of anything else (leadership requirement intact)
start_test "rscreen: negative RS50 rejects even with positive RS10"
out=$(python3 scripts/sizing.py rscreen --rs10 5 --rs50 -1 --close 100 --dma50 98 --dma50-prior 97 2>&1)
assert_contains "$out" '"pass": 0'
assert_contains "$out" '"reason": "rs50_negative"'

# classic pass: both RS positive
start_test "rscreen: RS10 and RS50 both positive → pass"
out=$(python3 scripts/sizing.py rscreen --rs10 1.5 --rs50 15.6 --close 101.61 --dma50 95 --dma50-prior 94 2>&1)
assert_contains "$out" '"pass": 1'
assert_contains "$out" '"reason": "rs10_positive"'

# the APH case: RS10 -0.72pp, RS50 +21.62pp, close $157.51 vs 50-DMA $149.72.
# (157.51-149.72)/149.72 = +5.2% above the DMA → too extended for the pullback
# exception. Correctly still rejected.
start_test "rscreen: APH case — extended above 50-DMA, still rejected"
out=$(python3 scripts/sizing.py rscreen --rs10 -0.72 --rs50 21.62 --close 157.51 --dma50 149.72 --dma50-prior 147.0 2>&1)
assert_contains "$out" '"pass": 0'
assert_contains "$out" '"reason": "rs10_negative_extended"'

# constructive pullback: RS50 strong, RS10 slightly negative, price 2% above a RISING
# 50-DMA → this is the base the analyst wanted and the old screen rejected
start_test "rscreen: constructive pullback to a rising 50-DMA → pass"
out=$(python3 scripts/sizing.py rscreen --rs10 -0.72 --rs50 21.62 --close 152.71 --dma50 149.72 --dma50-prior 147.0 2>&1)
assert_contains "$out" '"pass": 1'
assert_contains "$out" '"reason": "constructive_pullback"'

# same pullback but the 50-DMA is FALLING → not constructive, reject
start_test "rscreen: pullback to a falling 50-DMA is not constructive"
out=$(python3 scripts/sizing.py rscreen --rs10 -0.72 --rs50 21.62 --close 152.71 --dma50 149.72 --dma50-prior 151.0 2>&1)
assert_contains "$out" '"pass": 0'
assert_contains "$out" '"reason": "rs10_negative_extended"'

# price BELOW the 50-DMA is not a constructive pullback either (trend gate also
# rejects this upstream, but rscreen must not pass it on its own)
start_test "rscreen: price below the 50-DMA is not constructive"
out=$(python3 scripts/sizing.py rscreen --rs10 -2 --rs50 21.62 --close 148.00 --dma50 149.72 --dma50-prior 147.0 2>&1)
assert_contains "$out" '"pass": 0'
assert_contains "$out" '"reason": "rs10_negative_extended"'

# exactly at the 3% band edge → still constructive (inclusive boundary)
start_test "rscreen: 3.0% above a rising 50-DMA is inclusive"
out=$(python3 scripts/sizing.py rscreen --rs10 -0.5 --rs50 10 --close 103 --dma50 100 --dma50-prior 99 2>&1)
assert_contains "$out" '"pass": 1'
assert_contains "$out" '"reason": "constructive_pullback"'
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — every `rscreen` test fails with `invalid choice: 'rscreen'` (argparse rejects the unknown subcommand, exits 2, and none of the expected substrings appear).

- [ ] **Step 3: Implement `cmd_rscreen`**

In `scripts/sizing.py`, add after `cmd_scaleout` (after line 82):

```python
# Constructive-pullback band: how far above the 50-DMA a name may sit and still
# count as "based" rather than "extended". 3% is deliberately tight.
PULLBACK_BAND = 0.03


def cmd_rscreen(a):
    # v3.3 satellite relative-strength screen.
    #
    # The v3 screen required BOTH 10- and 50-session RS vs SPY to be positive.
    # That is a catch-22: a name with positive RS10 is by construction extended
    # (and gets rejected downstream as chase risk), while a name that has pulled
    # back into a buyable base fails RS10. The sleeve sat empty for three weeks.
    #
    # Medium-term leadership (RS50) stays a hard requirement. The single bounded
    # exception is a constructive pullback: price still above, but within
    # PULLBACK_BAND of, a 50-DMA that is itself rising.
    if a.rs50 <= 0:
        return {"pass": 0, "reason": "rs50_negative"}
    if a.rs10 > 0:
        return {"pass": 1, "reason": "rs10_positive"}
    above = (a.close - a.dma50) / a.dma50
    constructive = (0 <= above <= PULLBACK_BAND) and (a.dma50 > a.dma50_prior)
    if constructive:
        return {"pass": 1, "reason": "constructive_pullback"}
    return {"pass": 0, "reason": "rs10_negative_extended"}
```

Add the subparser in `main()`, after the `scaleout` block (after line 118):

```python
    rs = sub.add_parser("rscreen")
    rs.add_argument("--rs10", type=float, required=True,
                    help="ticker 10-session return minus SPY's, in pp")
    rs.add_argument("--rs50", type=float, required=True,
                    help="ticker 50-session return minus SPY's, in pp")
    rs.add_argument("--close", type=float, required=True)
    rs.add_argument("--dma50", type=float, required=True)
    rs.add_argument("--dma50-prior", type=float, required=True, dest="dma50_prior",
                    help="the 50-DMA 10 sessions ago; used to test that it is rising")
    rs.set_defaults(func=cmd_rscreen)
```

Update the module docstring, appending after the `decay` usage lines (line 12):

```
  sizing.py rscreen --rs10 X --rs50 Y --close C --dma50 D --dma50-prior P
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_sizing.sh`
Expected: PASS — final line reads `Results: <N> passed, 0 failed`.

- [ ] **Step 5: Wire the screen into pre-market**

In `routines/pre-market.md`, replace the second bullet of the satellite screen (line 116) with:

```markdown
- `bash scripts/alpaca.sh bars SPY 1Day 60` → compute the candidate's 10- and 50-session
  returns and SPY's over the same windows; `RS10 = ret10_ticker - ret10_SPY` and
  `RS50 = ret50_ticker - ret50_SPY`, both in percentage points. (60 bars gives margin
  for the 50-session lookback, which needs 51 closes.) From the 200-bar ticker pull
  above, also compute `DMA50` (mean of the last 50 closes) and `DMA50_PRIOR` (mean of
  the 50 closes ending 10 sessions ago). Then ask the unit-tested screen — never judge
  this by eye *(v3.3)*:
  ```
  RS_JSON=$(python3 scripts/sizing.py rscreen --rs10 "$RS10" --rs50 "$RS50" \
      --close "$LAST_CLOSE" --dma50 "$DMA50" --dma50-prior "$DMA50_PRIOR")
  ```
  Reject the candidate if `pass == 0`, quoting `reason`. `rs50_negative` = no
  medium-term leadership. `rs10_negative_extended` = short-term lagging AND not in a
  constructive base. A `pass == 1` with `reason == "constructive_pullback"` is a name
  that is lagging over 10 sessions but sitting within 3% of a *rising* 50-DMA — the
  base the v3 screen used to reject on RS10 alone while the market-open row rejected
  the alternative as chase risk (AMG Jul 17/20/22, APH Jul 23; sleeve 0/3 for three weeks).
  Tag the idea line: `rs: RS10 <+X.XX>pp / RS50 <+X.XX>pp / screen=<reason>`.
```

- [ ] **Step 6: Update the rulebook**

In `memory/TRADING-STRATEGY.md`, in `### Single-stock satellite checklist (v3)`, replace the relative-strength bullet with:

```markdown
- Relative strength via `sizing.py rscreen` *(v3.3 — deterministic, unit-tested)*: `RS50 > 0` is a hard requirement (medium-term leadership). `RS10 > 0` passes outright; if `RS10 <= 0` the name may still pass as a **constructive pullback** — price above but within 3% of a 50-DMA that is itself rising over the last 10 sessions. Anything else is rejected as `rs10_negative_extended`. Rationale: requiring both RS windows positive was a catch-22 — passing names were extended enough to be rejected downstream as chase risk, and based names failed RS10 — which left the satellite sleeve empty for Weeks 12–14.
```

- [ ] **Step 7: Port to the mirror**

In `.claude/commands/pre-market.md`, replace the relative-strength line in the satellite screen with:

```markdown
- `bash scripts/alpaca.sh bars SPY 1Day 60` → `RS10`/`RS50` (ticker minus SPY, pp).
  Compute `DMA50` and `DMA50_PRIOR` (50-DMA now vs 10 sessions ago) from the 200-bar pull.
  Then *(v3.3, never by eye)*:
  ```
  python3 scripts/sizing.py rscreen --rs10 "$RS10" --rs50 "$RS50" \
      --close "$LAST_CLOSE" --dma50 "$DMA50" --dma50-prior "$DMA50_PRIOR"
  ```
  Reject on `pass == 0`, quoting `reason`. `RS50 > 0` is mandatory; `RS10 <= 0` can
  still pass as a `constructive_pullback` (within 3% of a rising 50-DMA).
  Tag the idea: `rs: RS10 <X>pp / RS50 <Y>pp / screen=<reason>`.
```

- [ ] **Step 8: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh routines/pre-market.md \
        .claude/commands/pre-market.md memory/TRADING-STRATEGY.md
git commit -m "feat(v3.3): rscreen — allow a constructive pullback to a rising 50-DMA

Requiring both RS10 and RS50 positive was a catch-22: names passing RS10
were extended enough that market-open rejected them as chase risk (AMG Jul
17/20), and names that had based failed RS10 (AMG Jul 22, APH Jul 23). The
satellite sleeve sat 0/3 for three weeks. RS50 > 0 stays mandatory; RS10 <=
0 now passes only within 3% of a rising 50-DMA.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Final verification (run after Task 7)

- [ ] **Both suites green**

Run: `bash tests/test_sizing.sh && bash tests/test_alpaca.sh`
Expected: both end in `0 failed`.

- [ ] **Visa-critical rules unchanged in intent**

Run: `git diff 502d3fc..HEAD -- memory/TRADING-STRATEGY.md | grep -E "^[-+].*(Rule 13|Rule 15|13\.|15\.)"`
Expected: no changes to rules 13 or 15. Rule 14 changes must only *add* restrictions (the `source=none` sell block, the mandatory log token) — never remove the `>= 2` abort or the pre-flight requirement.

- [ ] **No gate deadlock introduced**

Reason through, and record the answer in the completion report: with the 16% sizing cap and headroom-fit sizing, can the buy-side gate reach a state where *no* idea of any tier can ever pass? (Expected answer: no. Four 16% clips leave ~21% headroom, well above the 5% min-pos floor; and a scale-out, stop-out, or equity growth always restores headroom. The macro-binary gate remains satellite-only, so ETF core stays deployable through any binary.)

- [ ] **Re-paste list for the user**

All five routine prompts changed in this round. Confirm the list before reporting completion:
Run: `git diff --name-only 502d3fc..HEAD -- routines/`
Expected: `market-open.md`, `midday.md`, `daily-summary.md`, `weekly-review.md`, `pre-market.md` — **all five need manual re-paste into the Routines UI.** `scripts/*` and `memory/TRADING-STRATEGY.md` auto-deploy and need no action.

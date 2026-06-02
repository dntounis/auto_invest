# auto_invest v3 — Core-Satellite Momentum Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evolve the v2 sector-ETF bot into a core-satellite book — ETF core plus single-stock satellites — with deterministic risk-parity sizing, scale-out + tighter-trail profit ladders, momentum-decay rotation, a raised weekly cap, and a stale-quote fallback, while preserving every visa-aware day-trade safeguard.

**Architecture:** Safety-critical math (position sizing, profit-ladder targets, momentum-decay decision) moves out of LLM prose into a deterministic, unit-tested Python helper `scripts/sizing.py` that the routines shell out to. Routine markdown prompts (`routines/*.md` + `.claude/commands/*` mirrors) are edited to call the helper and enforce the new core/satellite gates. The Alpaca wrapper gains a read-only `bars` subcommand (for moving averages / relative strength) and a `scale-out` partial-sell convenience. `memory/TRADING-STRATEGY.md` is rewritten to the v3 rulebook.

**Tech Stack:** Bash (wrapper + test harness in `tests/_lib.sh`), Python 3 (`sizing.py`, inline JSON in wrappers), Alpaca paper API, Markdown routine prompts. Tests are bash files under `tests/` run via `tests/run_all.sh`. No pytest (not installed).

**Spec:** `docs/superpowers/specs/2026-06-02-auto-invest-v3-design.md`

---

## File structure

| File | Responsibility | New/Modified |
|------|----------------|--------------|
| `scripts/sizing.py` | Pure functions: risk-parity `size`, profit-`ladder` target, momentum-`decay` decision. No network. | **New** |
| `tests/test_sizing.sh` | Bash unit tests for `sizing.py` (all three modes). | **New** |
| `scripts/alpaca.sh` | Add read-only `bars` subcommand; gated `scale-out` subcommand. | Modify |
| `tests/test_alpaca.sh` | Add cases for `bars` (read-only) and `scale-out` (gated + arg-check). | Modify |
| `memory/TRADING-STRATEGY.md` | Rewrite to v3 rulebook (core-satellite, ladders, Rule 4→5, new rotation rule). | Modify |
| `routines/pre-market.md` (+ `.claude/commands/pre-market.md`) | Single-stock screen, per-idea stop width, `tier: core|satellite`. | Modify |
| `routines/market-open.md` (+ mirror) | Cap 5; sizing via `sizing.py`; core-floor + sector-diversification gates; stale-quote fallback. | Modify |
| `routines/midday.md` (+ mirror) | Profit ladders + scale-out via `sizing.py ladder`; momentum-decay exit via `sizing.py decay` + `alpaca.sh bars`. | Modify |
| `routines/daily-summary.md` (+ mirror) | (No logic change; verify stop placement still works for stock positions.) | Verify |
| `routines/weekly-review.md` (+ mirror) | Alpha-vs-SPX + core/satellite attribution. | Modify |
| `memory/MEMORY.md`, `memory/PROJECT-CONTEXT.md` | Mark v3 active; note new helper. | Modify |
| `docs/superpowers/specs/v3-backlog.md` | Mark stale-quote item promoted. | Modify |

**Convention notes for the implementer:**
- Bash tests copy `scripts/` into a temp dir, set dummy env vars, and assert exit codes / output substrings (see existing `tests/test_alpaca.sh`). They never hit the network — use bogus keys so curl fails *after* the logic you're testing, or assert kill-switch/usage paths that exit before any curl.
- Every git commit message ends with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Routine files and their `.claude/commands/` mirrors must stay in sync; the mirror omits the commit/push step and the branch-policy override.
- Do NOT create or source a `.env`. Helper math reads CLI args only.

---

## Task 1: `sizing.py` — risk-parity `size` mode

**Files:**
- Create: `scripts/sizing.py`
- Test: `tests/test_sizing.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_sizing.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"
cd "$ROOT"

echo "test_sizing.sh"

# size: tight 5% stop → raw $4000 > $2000 cap → clamps, floor(2000/100)=20 sh
start_test "size: tight stop clamps to 20% cap"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 2>&1)
assert_contains "$out" '"shares": 20'
assert_contains "$out" '"clamped": "cap"'

# size: stock, 13% stop, $150 px → $200/0.13=$1538 < $2000 cap → floor(1538/150)=10 sh
start_test "size: stock 13% stop risk-parity (uncapped)"
out=$(python3 scripts/sizing.py size --equity 10000 --price 150 --stop-frac 0.13 2>&1)
assert_contains "$out" '"shares": 10'
assert_contains "$out" '"clamped": "none"'

# size: wide 50% stop → raw $400, floor(400/100)=4 sh, cost $400 < 5% floor ($500) → skip
start_test "size: tiny risk budget below min-pos floor → floor_skip"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.5 2>&1)
assert_contains "$out" '"shares": 0'
assert_contains "$out" '"clamped": "floor_skip"'

print_summary
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `python3: can't open file '.../sizing.py'`.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/sizing.py`:

```python
#!/usr/bin/env python3
"""Deterministic trade-sizing and exit math for auto_invest v3.

Pure functions, no network. Routines shell out to this so position sizing,
profit-taking, and rotation decisions are deterministic instead of LLM
arithmetic. All modes print one JSON object to stdout.

  sizing.py size   --equity E --price P --stop-frac S [--risk-pct 0.02]
                   [--max-pos-pct 0.20] [--min-pos-pct 0.05]
  sizing.py ladder --tier etf|stock --unrealized-pct X
  sizing.py decay  --unrealized-pct X --pos-ret-10d A --spy-ret-10d B
                   --prior-flag 0|1
"""
import argparse, json, math, sys


def cmd_size(a):
    risk_dollars = a.equity * a.risk_pct
    cap_dollars = a.equity * a.max_pos_pct
    raw_dollars = risk_dollars / a.stop_frac
    clamped = "none"
    dollars = raw_dollars
    if raw_dollars > cap_dollars:
        dollars = cap_dollars
        clamped = "cap"
    shares = math.floor(dollars / a.price)
    cost = shares * a.price
    if shares < 1 or cost < a.equity * a.min_pos_pct:
        return {"shares": 0, "cost": 0.0, "pct_equity": 0.0,
                "clamped": "floor_skip"}
    return {"shares": shares, "cost": round(cost, 2),
            "pct_equity": round(cost / a.equity, 4), "clamped": clamped}


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="mode", required=True)

    s = sub.add_parser("size")
    s.add_argument("--equity", type=float, required=True)
    s.add_argument("--price", type=float, required=True)
    s.add_argument("--stop-frac", type=float, required=True, dest="stop_frac")
    s.add_argument("--risk-pct", type=float, default=0.02, dest="risk_pct")
    s.add_argument("--max-pos-pct", type=float, default=0.20, dest="max_pos_pct")
    s.add_argument("--min-pos-pct", type=float, default=0.05, dest="min_pos_pct")
    s.set_defaults(func=cmd_size)

    args = p.parse_args()
    print(json.dumps(args.func(args)))


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/test_sizing.sh`
Expected: PASS — 6 assertions pass (size cases only).

- [ ] **Step 5: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh
git commit -m "feat(v3): deterministic risk-parity size helper

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: `sizing.py` — profit `ladder` mode

**Files:**
- Modify: `scripts/sizing.py`
- Test: `tests/test_sizing.sh`

- [ ] **Step 1: Add failing tests** to `tests/test_sizing.sh` (before `print_summary`):

```bash
# ladder ETF: below first tier (+4) → no change
start_test "ladder: ETF below first tier → no action"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 3 2>&1)
assert_contains "$out" '"target_trail_pct": null'
assert_contains "$out" '"scaleouts_due": 0'

# ladder ETF: +7 → trail 5, one scale-out due
start_test "ladder: ETF +7% → trail 5, 1 scale-out"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 7 2>&1)
assert_contains "$out" '"target_trail_pct": 5'
assert_contains "$out" '"scaleouts_due": 1'

# ladder ETF: +15 → trail 3 (floor), two scale-outs due
start_test "ladder: ETF +15% → trail 3, 2 scale-outs"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 15 2>&1)
assert_contains "$out" '"target_trail_pct": 3'
assert_contains "$out" '"scaleouts_due": 2'

# ladder stock: +10 → trail 6, one scale-out
start_test "ladder: stock +10% → trail 6, 1 scale-out"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 10 2>&1)
assert_contains "$out" '"target_trail_pct": 6'
assert_contains "$out" '"scaleouts_due": 1'

# ladder stock: +25 → trail 3, two scale-outs
start_test "ladder: stock +25% → trail 3, 2 scale-outs"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 25 2>&1)
assert_contains "$out" '"target_trail_pct": 3'
assert_contains "$out" '"scaleouts_due": 2'
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `invalid choice: 'ladder'`.

- [ ] **Step 3: Implement `ladder`.** Add to `scripts/sizing.py` above `main()`:

```python
# Each tier: (unrealized_pct_trigger, target_trail_pct, cumulative_scaleouts).
# Ordered ascending. Trail floor is 3 (Rule 9: never inside 3% of price).
LADDERS = {
    "etf":   [(4, 7, 0), (7, 5, 1), (10, 4, 1), (15, 3, 2)],
    "stock": [(6, 7, 0), (10, 6, 1), (15, 4, 1), (25, 3, 2)],
}


def cmd_ladder(a):
    tiers = LADDERS[a.tier]
    target_trail = None
    scaleouts = 0
    for trigger, trail, so in tiers:
        if a.unrealized_pct >= trigger:
            target_trail = trail
            scaleouts = so
    return {"tier": a.tier, "target_trail_pct": target_trail,
            "scaleouts_due": scaleouts}
```

And register it in `main()` after the `size` parser:

```python
    l = sub.add_parser("ladder")
    l.add_argument("--tier", choices=["etf", "stock"], required=True)
    l.add_argument("--unrealized-pct", type=float, required=True,
                   dest="unrealized_pct")
    l.set_defaults(func=cmd_ladder)
```

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/test_sizing.sh`
Expected: PASS — all size + ladder assertions pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh
git commit -m "feat(v3): profit-ladder target helper (scale-out + trail tiers)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: `sizing.py` — momentum `decay` mode

**Files:**
- Modify: `scripts/sizing.py`
- Test: `tests/test_sizing.sh`

- [ ] **Step 1: Add failing tests** to `tests/test_sizing.sh` (before `print_summary`):

```bash
# decay: below entry, lagging SPY, prior flag set → rotate
start_test "decay: 2nd consecutive lag → rotate"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2 --pos-ret-10d -3 --spy-ret-10d 1 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 1'
assert_contains "$out" '"rotate": 1'

# decay: below entry, lagging SPY, but first occurrence (prior 0) → flag only, no rotate
start_test "decay: 1st occurrence → flag set, no rotate"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2 --pos-ret-10d -3 --spy-ret-10d 1 --prior-flag 0 2>&1)
assert_contains "$out" '"flag": 1'
assert_contains "$out" '"rotate": 0'

# decay: above entry → never flags regardless of RS
start_test "decay: above entry → no flag"
out=$(python3 scripts/sizing.py decay --unrealized-pct 1 --pos-ret-10d -3 --spy-ret-10d 1 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 0'
assert_contains "$out" '"rotate": 0'

# decay: below entry but beating SPY → no flag
start_test "decay: below entry but beating SPY → no flag"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2 --pos-ret-10d 2 --spy-ret-10d 1 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 0'
assert_contains "$out" '"rotate": 0'
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `invalid choice: 'decay'`.

- [ ] **Step 3: Implement `decay`.** Add to `scripts/sizing.py` above `main()`:

```python
def cmd_decay(a):
    # Flag when below entry AND lagging SPY over the trailing window.
    flag = 1 if (a.unrealized_pct < 0 and a.pos_ret_10d < a.spy_ret_10d) else 0
    rotate = 1 if (flag and a.prior_flag) else 0
    return {"flag": flag, "rotate": rotate}
```

And register in `main()`:

```python
    d = sub.add_parser("decay")
    d.add_argument("--unrealized-pct", type=float, required=True,
                   dest="unrealized_pct")
    d.add_argument("--pos-ret-10d", type=float, required=True, dest="pos_ret_10d")
    d.add_argument("--spy-ret-10d", type=float, required=True, dest="spy_ret_10d")
    d.add_argument("--prior-flag", type=int, choices=[0, 1], required=True,
                   dest="prior_flag")
    d.set_defaults(func=cmd_decay)
```

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/test_sizing.sh`
Expected: PASS — all assertions across size/ladder/decay pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh
git commit -m "feat(v3): momentum-decay rotation decision helper

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: `alpaca.sh bars` — read-only historical bars

**Files:**
- Modify: `scripts/alpaca.sh` (add case before the `*)` default, after `activities)`)
- Test: `tests/test_alpaca.sh`

- [ ] **Step 1: Add failing tests** to `tests/test_alpaca.sh` (before the final `rm -rf` / `print_summary`):

```bash
# bars is read-only: must NOT be kill-switch gated
start_test "bars works without TRADING_ENABLED (read-only)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"; cp -r "$ROOT/scripts" .; rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh bars SPY 2>&1
)
rc=$?
if [[ "$rc" == "4" ]]; then fail "bars was kill-switch-gated but is read-only"; else pass; fi
assert_not_contains "$out" "Usage: bash scripts/alpaca.sh"

# bars requires a symbol arg
start_test "bars exits 1 with usage when symbol missing"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"; cp -r "$ROOT/scripts" .; rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    bash scripts/alpaca.sh bars 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: bars"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/test_alpaca.sh`
Expected: FAIL — `bars` falls through to the `*)` default and prints `Usage: bash scripts/alpaca.sh ...` (so the read-only assertion fails) / the missing-symbol case returns the wrong usage string.

- [ ] **Step 3: Implement.** In `scripts/alpaca.sh`, add this case immediately after the `activities)` block (before `*)`):

```bash
    bars)
        # Read-only — no kill-switch gate. Daily bars for moving-average / RS.
        sym="${1:?usage: bars SYM [timeframe] [limit]}"
        timeframe="${2:-1Day}"
        limit="${3:-60}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" \
            "$DATA/stocks/$sym/bars?timeframe=$timeframe&limit=$limit&adjustment=all"
        ;;
```

Also add `bars` to the usage string in the `*)` default case so it reads:
`...|trailing-stop|replace-stop|activities|bars> [args]`

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/test_alpaca.sh`
Expected: PASS — bars read-only + usage cases pass; all prior cases still pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/alpaca.sh tests/test_alpaca.sh
git commit -m "feat(v3): alpaca.sh bars read-only subcommand for MA/RS

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: `alpaca.sh scale-out` — gated partial sell

**Files:**
- Modify: `scripts/alpaca.sh`
- Test: `tests/test_alpaca.sh`

- [ ] **Step 1: Add failing tests** to `tests/test_alpaca.sh` (before final `rm -rf`):

```bash
# scale-out is gated by TRADING_ENABLED
start_test "exits 4 on scale-out when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"; cp -r "$ROOT/scripts" .; rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh scale-out XLE 5 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"

# scale-out with missing args → usage
start_test "exits 1 on scale-out with missing args"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"; cp -r "$ROOT/scripts" .; rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="true"
    bash scripts/alpaca.sh scale-out 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: scale-out"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/test_alpaca.sh`
Expected: FAIL — `scale-out` hits the `*)` default (exit 1, "Usage" not "TRADING_ENABLED"), so the gated case fails.

- [ ] **Step 3: Implement.** In `scripts/alpaca.sh`, add this case after the `close-all)` block:

```bash
    scale-out)
        require_trading_enabled
        sym="${1:?usage: scale-out SYM QTY}"
        qty="${2:?usage: scale-out SYM QTY}"
        body=$(python3 -c "
import json, sys
print(json.dumps({
    'symbol': sys.argv[1],
    'qty': sys.argv[2],
    'side': 'sell',
    'type': 'market',
    'time_in_force': 'day',
}))" "$sym" "$qty")
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
```

Add `scale-out` to the `*)` usage string.

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/test_alpaca.sh` then `bash tests/run_all.sh`
Expected: PASS — scale-out gated + usage cases pass; ALL TESTS PASSED.

- [ ] **Step 5: Commit**

```bash
git add scripts/alpaca.sh tests/test_alpaca.sh
git commit -m "feat(v3): alpaca.sh scale-out gated partial-sell subcommand

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Rewrite `memory/TRADING-STRATEGY.md` to v3

**Files:**
- Modify: `memory/TRADING-STRATEGY.md`

This is the canonical rulebook the routines read. No code test — verification is a content review + grep. Make these specific changes (preserve all existing visa-aware Rules 13–15 verbatim):

- [ ] **Step 1: Add v3 structure section** under "Capital & Constraints":

```markdown
## Portfolio Structure (v3 — core/satellite)
- **ETF core:** ≥45% of *deployed* equity, 2–3 sector ETFs (leading-quadrant rotation). Market-tracking ballast.
- **Single-stock satellites:** ≤3 names, remainder of deployed equity. Alpha sleeve.
- Max 5–6 total positions. Max 2 satellite names per GICS sector.
- ETF core may never fall below 45% of deployed — market-open refuses a satellite buy that would breach this.
```

- [ ] **Step 2: Edit Rule 4** from `Maximum 3 new trades per week` to:

```markdown
4. Maximum 5 new trades per week *(v3 — raised from 3; swing entries only, no day-trade impact)*
```

- [ ] **Step 3: Replace Rule 8** (the +15%/+20% tighten) with the v3 dual-ladder, and note scale-outs:

```markdown
8. **Profit ladder (v3 — scale-out + tighter trail).** Tiers below are evaluated at midday; sizing/targets come from `scripts/sizing.py ladder`. All scale-outs are partial sells on positions opened ≥1 trading day ago (Rules 14/15 apply).
   - ETF core: +4%→trail 7%; +7%→scale-out 1/3 + trail 5%; +10%→trail 4%; +15%→scale-out 1/3 + trail 3%.
   - Single-stock satellite: +6%→trail 7%; +10%→scale-out 1/3 + trail 6%; +15%→trail 4%; +25%→scale-out 1/3 + trail 3%.
```

- [ ] **Step 4: Add Rule 16** (new) after Rule 15:

```markdown
16. **Momentum-decay rotation (v3, visa-aware).** At midday, a held position is flagged when it is BOTH below entry AND lagging SPY over the trailing 10 sessions (`scripts/sizing.py decay`). On the *second consecutive* flagged midday, rotate out (T+1 sell). ETFs additionally rotate if the sector exits the leading quadrant. Never acts on a same-day position (Rule 15); aborts if `daytrade_count ≥ 2` (Rule 14). The flag state for each position is recorded in TRADE-LOG.md so the next midday can detect consecutiveness.
```

- [ ] **Step 5: Update the Buy-Side Gate** — change `Trades placed this week (including this one) ≤ 3` to `≤ 5`, and add two lines:

```markdown
- ETF core stays ≥ 45% of deployed equity after this fill (if the idea is a satellite)
- ≤ 2 satellite names in the idea's GICS sector after this fill
```

- [ ] **Step 6: Add a single-stock entry checklist** under "Entry Checklist":

```markdown
### Single-stock satellite checklist (v3)
- Price above both 50-DMA and 200-DMA (`alpaca.sh bars`)?
- Positive relative strength vs SPY over 10 and 50 sessions?
- Adequate liquidity: average daily volume and a tight quoted spread (also guards against stale-open quotes)?
- Specific catalyst documented (earnings/guidance/upgrade/sector tailwind)?
- Per-idea stop width set (drives risk-parity sizing); R:R ≥ 2:1?
```

- [ ] **Step 7: Bump the version note** at the top and the Strategy Update Cadence line to mention v3.

- [ ] **Step 8: Verify + commit**

Run: `grep -nE "Maximum 5 new|Profit ladder|Momentum-decay rotation|core/satellite|≥45%" memory/TRADING-STRATEGY.md`
Expected: each phrase present.

```bash
git add memory/TRADING-STRATEGY.md
git commit -m "feat(v3): rewrite rulebook for core-satellite momentum

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: `routines/pre-market.md` — single-stock screen

**Files:**
- Modify: `routines/pre-market.md` and mirror `.claude/commands/pre-market.md`

- [ ] **Step 1: Extend STEP 3 research** — add single-stock screening queries after the existing sector queries:

```markdown
- "Top momentum stocks today with bullish catalysts (earnings beat, guidance raise, analyst upgrade)"
- For each single-stock candidate, fetch bars to confirm trend:
  `bash scripts/alpaca.sh bars TICKER 1Day 200` → confirm last close > 50-DMA and > 200-DMA.
  `bash scripts/alpaca.sh bars SPY 1Day 50` → compute candidate vs SPY 10- and 50-session returns (relative strength).
- Reject candidates failing the liquidity filter (thin average volume / wide spread).
```

- [ ] **Step 2: Extend the STEP 4 idea schema** — change the idea line format to carry tier and stop width:

```markdown
1. **ID:** `pm-YYYY-MM-DD-TICKER` — **tier:** core|satellite, TICKER, catalyst, entry $X, stop $X (stop width N% → risk-parity sizing), target $X, R:R X:1, planned trail percent: N
```

Add: "At least one satellite idea should be present on a TRADE day unless none pass the single-stock checklist (then note why). Rank all ideas (core + satellite) together by R:R descending."

- [ ] **Step 3: Sync the mirror** — apply the same STEP 3 / STEP 4 edits to `.claude/commands/pre-market.md` (it has no commit/push step and no branch-policy override; keep those omissions).

- [ ] **Step 4: Verify + commit**

Run: `grep -n "tier:.*core|satellite\|momentum stocks\|relative strength\|bars TICKER" routines/pre-market.md .claude/commands/pre-market.md`
Expected: present in both.

```bash
git add routines/pre-market.md .claude/commands/pre-market.md
git commit -m "feat(v3): pre-market single-stock satellite screen

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 8: `routines/market-open.md` — cap 5, deterministic sizing, core/satellite gates, stale-quote fallback

**Files:**
- Modify: `routines/market-open.md` and mirror `.claude/commands/market-open.md`

- [ ] **Step 1: Raise the weekly cap.** In STEP 3 change `Trades placed this week (incl. this one) ≤ 3` → `≤ 5`. In STEP 4 change `weekly_cap_remaining = 3 - trades_this_week` → `5 - trades_this_week`.

- [ ] **Step 2: Add core/satellite gates** to the STEP 3 Buy-Side Gate list:

```markdown
- If this idea's `tier` is `satellite`: ETF-core market value after this fill must stay ≥ 45% of deployed equity (sum of position market values). Compute from `positions`. Skip + log if it would breach.
- If this idea's `tier` is `satellite`: count existing + pending satellite names in the same GICS sector; skip + log if this would make > 2.
```

- [ ] **Step 3: Replace inline sizing math (STEP 5c) with the deterministic helper:**

```markdown
**5c. Compute position size (deterministic helper)**

Use the idea's stop width as `stop-frac` (e.g. ETF 0.10, stock 0.13 from the pm idea line; fall back to trail_pct/100 if no explicit stop width).

```
SIZE_JSON=$(python3 scripts/sizing.py size \
    --equity "$EQUITY" --price "$LIVE_ASK" --stop-frac "$STOP_FRAC")
```

Parse `shares` and `clamped` from `SIZE_JSON`. If `clamped == "floor_skip"` or `shares < 1`, skip the idea and log the reason. This replaces the prior hand-computed `shares_by_risk`/`shares_by_cap` formula (same logic, now deterministic and unit-tested).
```

- [ ] **Step 4: Add the stale-quote fallback to STEP 5a.** Replace `If live_ask is zero or null, skip this idea and log "no ask price available".` with:

```markdown
If `live_ask` is zero or null but a bid exists and `bid` is within
`MAX_ENTRY_SLIPPAGE_PCT` of the prior session close (`alpaca.sh bars TICKER 1Day 2`):
set `limit_price = round(prior_close * (1 + MAX_ENTRY_SLIPPAGE_PCT/100), 2)` and place
a **day-TIF limit** at that price (it fills when the ask materializes intraday) instead
of skipping. Telegram-note (non-URGENT) "stale-open quote on TICKER — placed prior-close
limit fallback". If bid is also absent or spread is unreasonable, skip and log as before.
```

- [ ] **Step 5: Record `tier` in the TRADE-LOG row (STEP 7)** so midday and weekly-review can tell core from satellite — add `tier=core|satellite` to the appended trade row.

- [ ] **Step 6: Sync the mirror** `.claude/commands/market-open.md` with the same edits.

- [ ] **Step 7: Verify + commit**

Run: `grep -nE "≤ 5|5 - trades_this_week|sizing.py size|stale-open|45% of deployed" routines/market-open.md`
Expected: all present.

```bash
git add routines/market-open.md .claude/commands/market-open.md
git commit -m "feat(v3): market-open cap5, helper sizing, core/satellite gates, stale-quote fallback

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 9: `routines/midday.md` — profit ladders + momentum-decay rotation

**Files:**
- Modify: `routines/midday.md` and mirror `.claude/commands/midday.md`

- [ ] **Step 1: Replace the +15%/+20% stop-tighten step** with the helper-driven dual ladder. For each actionable position (entry_date < today, Rule 15):

```markdown
Determine `tier` (core|satellite) from its TRADE-LOG entry. Compute unrealized %.
```
LADDER_JSON=$(python3 scripts/sizing.py ladder --tier "$TIER" --unrealized-pct "$UPCT")
```
- If `scaleouts_due` > scale-outs already executed for this position (counted from TRADE-LOG SCALE-OUT rows): sell 1/3 of *current* qty via `bash scripts/alpaca.sh scale-out TICKER $(qty/3)` — but FIRST run the Rule 14 `daytrade_count` pre-flight; abort all sells if ≥ 2.
- If `target_trail_pct` is non-null and tighter than the current stop's trail (never move a stop down, never inside 3% — Rule 9): `bash scripts/alpaca.sh replace-stop OID TICKER QTY $target_trail_pct`.
Log a SCALE-OUT and/or STOP-TIGHTEN row in TRADE-LOG.md for each action.
```

- [ ] **Step 2: Add the momentum-decay rotation block** after the existing −7% hard-close (Rule 7) step:

```markdown
### Momentum-decay rotation (Rule 16)
For each actionable position (Rule 15 — skip same-day):
- `POS_RET=$(...)` 10-session return from `bash scripts/alpaca.sh bars TICKER 1Day 11` (last close vs close 10 bars ago).
- `SPY_RET=$(...)` 10-session return from `bash scripts/alpaca.sh bars SPY 1Day 11`.
- `PRIOR_FLAG` = 1 if the most recent midday DECAY-FLAG row for this ticker in TRADE-LOG.md is set, else 0.
```
DECAY_JSON=$(python3 scripts/sizing.py decay --unrealized-pct "$UPCT" \
    --pos-ret-10d "$POS_RET" --spy-ret-10d "$SPY_RET" --prior-flag "$PRIOR_FLAG")
```
- Append a `DECAY-FLAG TICKER flag=<flag>` row to TRADE-LOG.md (state for tomorrow).
- If `rotate == 1`: run Rule 14 pre-flight; if DTC < 2, close the position (`alpaca.sh close TICKER`) and log a ROTATE-EXIT row + Telegram note. If DTC ≥ 2, abort + URGENT Telegram.
```

- [ ] **Step 3: Sync mirror** `.claude/commands/midday.md`.

- [ ] **Step 4: Verify + commit**

Run: `grep -nE "sizing.py ladder|sizing.py decay|scale-out|Momentum-decay rotation|DECAY-FLAG" routines/midday.md`
Expected: all present.

```bash
git add routines/midday.md .claude/commands/midday.md
git commit -m "feat(v3): midday profit ladders + momentum-decay rotation

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 10: `routines/weekly-review.md` — alpha + core/satellite attribution

**Files:**
- Modify: `routines/weekly-review.md` and mirror `.claude/commands/weekly-review.md`; template in `memory/WEEKLY-REVIEW.md`

- [ ] **Step 1: Add two grade-card metrics** to STEP 3:

```markdown
| Alpha vs SPX | week_return − SPX week return (already partly present; make explicit) |
| Core vs satellite attribution | sum unrealized+realized P&L of `tier=core` rows vs `tier=satellite` rows this week |
```

- [ ] **Step 2: Add satellite-underperformance proposal logic** to STEP 5:

```markdown
If the satellite sleeve has underperformed the ETF core (lower P&L contribution per unit of capital) for 3+ consecutive weeks, append a `## Proposed strategy changes` block proposing to shrink the satellite allocation. Never auto-apply (DECIDED G).
```

- [ ] **Step 3: Extend the `memory/WEEKLY-REVIEW.md` stats template** with `Alpha vs SPX` and `Core/Satellite P&L` rows.

- [ ] **Step 4: Sync mirror + commit**

Run: `grep -nE "Alpha vs SPX|attribution|satellite" routines/weekly-review.md`
Expected: present.

```bash
git add routines/weekly-review.md .claude/commands/weekly-review.md memory/WEEKLY-REVIEW.md
git commit -m "feat(v3): weekly-review alpha + core/satellite attribution

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 11: Activate v3 in memory + mark backlog promoted

**Files:**
- Modify: `memory/PROJECT-CONTEXT.md`, `memory/MEMORY.md` (repo memory index, not the auto-memory), `docs/superpowers/specs/v3-backlog.md`, `CLAUDE.md`

- [ ] **Step 1: `docs/superpowers/specs/v3-backlog.md`** — add at the top of the stale-quote section: `> **PROMOTED** into 2026-06-02-auto-invest-v3-design.md §3.6 (2026-06-02).`

- [ ] **Step 2: `memory/PROJECT-CONTEXT.md` + `CLAUDE.md`** — update the Mode section to note v3 active (core-satellite), reference `scripts/sizing.py`, raised cap (5), and the new Rule 16. Update the daily-workflow bullets for midday (ladders + rotation) and pre-market (single-stock screen).

- [ ] **Step 3: Verify + commit**

```bash
git add memory/PROJECT-CONTEXT.md docs/superpowers/specs/v3-backlog.md CLAUDE.md
git commit -m "docs(v3): activate v3 in memory, mark stale-quote backlog promoted

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 12: Full regression + push

- [ ] **Step 1: Run the whole bash suite**

Run: `bash tests/run_all.sh`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 2: Live read-only smoke test** (uses real paper keys from `.env`; read-only only):

```bash
bash scripts/alpaca.sh bars SPY 1Day 5        # expect JSON bars
python3 scripts/sizing.py size --equity "$(bash scripts/alpaca.sh account | python3 -c 'import sys,json;print(json.load(sys.stdin)["equity"])')" --price 100 --stop-frac 0.10
```
Expect: bars JSON returns; sizing prints `shares`/`pct_equity` respecting the 20% cap.

- [ ] **Step 3: Push** (per repo convention — local SSH remote):

```bash
git push origin main
```

Expected: all v3 commits land on `main`. Next scheduled pre-market reads the v3 rulebook from a fresh clone.

---

## Verification (end-to-end, post-merge)

- **Sizing dry-run:** `python3 scripts/sizing.py size` with live equity for an ETF (0.10 stop) and a stock (0.13 stop) — both respect ≤20% cap and ~2% risk target. Confirmed by Task 1 tests + Task 12 Step 2.
- **Routine smoke:** manual `pre-market` → RESEARCH-LOG has ≥1 `tier: satellite` idea passing the gate with a liquidity note; manual `market-open` (paper) → core/satellite gates fire and a single-stock limit places/fills.
- **Profit-ladder + visa:** trigger a scale-out path → confirms Rule 14 pre-flight runs, Rule 15 skips same-day, `daytrade_count` unchanged.
- **Stale-quote fallback:** simulate `ap=0` → market-open places a prior-close limit instead of skipping.
- **Regression:** `bash tests/run_all.sh` green; `daytrade_count` stays 0 across a simulated week; no position > 20%; ETF core ≥ 45% of deployed.
- **Grading:** first v3 weekly-review reports alpha vs SPX + core/satellite attribution.

---

## Self-review notes (author)
- **Spec coverage:** §3.1 structure→T6/T8; §3.2 sizing→T1/T8 (existing infra hardened); §3.3 ladders→T2/T9; §3.4 rotation+cap→T3/T6/T9; §3.5 stock screen→T7; §3.6 stale-quote→T8; §3.7 grading→T10; §3.8 visa→preserved in T6/T9. All covered.
- **Type consistency:** helper JSON keys (`shares`, `clamped`, `target_trail_pct`, `scaleouts_due`, `flag`, `rotate`) are used identically in tests and routine steps.
- **Placeholder scan:** no TBD/TODO; every code step shows full code; routine edits show exact insert blocks + grep verification.
```

# auto_invest v3.4 — Final Pre-Live Hardening + Instrumentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the three rule defects that cost measurable alpha in Weeks 14–15, add a mode-aware endpoint guard so going live is a single env-var change, and instrument the two-week paper trial so the go-live decision is made against machine-computed pass/fail criteria agreed *before* the data arrives.

**Architecture:** All new decision math is a pure function in `scripts/sizing.py` or the new `scripts/metrics.py`, unit-tested by the existing bash harness — routines shell out, never compute. A new append-only `memory/METRICS.jsonl` carries one machine-readable record per session; `weekly-review` consumes it via `metrics.py` instead of hand-assembling numbers in prose. The endpoint guard becomes `TRADING_MODE`-aware so the live flip needs no prompt re-paste.

**Tech Stack:** Python 3 stdlib only (`argparse`, `json`, `math`, `statistics`). Bash 3.2. Custom bash test harness in `tests/_lib.sh`. **No pytest.** No new dependencies.

## Global Constraints

- **NO OPTIONS — ever.** Stocks and ETFs only.
- **This branch does NOT go live.** `TRADING_MODE` defaults to `paper` and every routine still asserts the paper endpoint under that default. The live flip is a later, deliberate env-var change by the user.
- **Never create, write, or source a `.env` file** in any routine. Credentials come from process env vars.
- **Never log secrets. Never print API keys.**
- **Never `curl` an API outside `scripts/alpaca.sh`.**
- **Rules 13 and 15 are visa-critical and MUST NOT be weakened.** Rule 14 may only be changed as Task 6 specifies — that change *corrects an over-count*, and must not remove the `>= 2` abort, the pre-flight requirement, or the `source=none|error` sell-block.
- **Tests:** `bash tests/run_all.sh` must report `ALL TESTS PASSED` at the end of every task.
- **Commits:** one per task, `feat(v3.4):` / `fix(v3.4):` prefix, ending with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Mirror parity:** every `routines/<name>.md` edit needs the equivalent edit in `.claude/commands/<name>.md`. The mirrors are *condensed* (`## Step N`, terser) — port substance, match each file's voice, do NOT make them byte-identical.
- **Deployment caveat:** `scripts/*` and `memory/TRADING-STRATEGY.md` auto-deploy (cloud clones `main`). `routines/*.md` prompt bodies do NOT — the user re-pastes them manually. Do not automate that.

## Why each change exists (evidence)

| # | Defect | Measured cost | Task |
|---|---|---|---|
| 1 | Rule 16 rotates on relative weakness during a melt-up; exit gate and entry screens share the SPY-relative denominator, so the book sells shallow losers it cannot replace | 3 rotations, ~$64 realized, buying nothing. XLF cut after 2 sessions holding the best RS50 in the complex (+9.23pp). 8 consecutive sessions of buy-side inaction | 3, 4 |
| 2 | Rule 5 states a 75–85% target band with no mechanism that acts when the book leaves it | ~0.9–1.0pp (W14), then **−1.78pp of a −1.94pp week** (W15) from the identical mechanism. Three consecutive Mondays opened below band | 5 |
| 3 | Rule 14's mid-loop increment counts every sell, not same-day round trips | Aug 7 logged `DTC: 2` when the true count was **0**. Any two-sell midday exhausts the ≤1 buffer, so a third exit is blocked on arithmetic rather than risk | 6 |
| 4 | Five routines hard-assert the paper endpoint; going live means editing and re-pasting all five | Operational — the re-paste has been this project's largest recurring friction | 7 |
| 5 | Weekly numbers are hand-assembled prose; the rolling alpha series mixes two measurement bases and cannot be recomputed | The 8 weeks scored on web-sourced SPX are not decision-grade. Only W14–W15 are trustworthy, and both are misses | 1, 2, 8 |

## File Structure

| File | Responsibility | Tasks |
|---|---|---|
| `scripts/metrics.py` | **NEW.** Deterministic session metrics, rollups, and the go-live scorecard | 1 |
| `tests/test_metrics.sh` | **NEW.** Unit tests for the above | 1 |
| `memory/METRICS.jsonl` | **NEW.** Append-only, one JSON object per session | 2 |
| `scripts/sizing.py` | Adds the melt-up guard to `decay`; adds a `redeploy` subcommand | 3, 5 |
| `tests/test_sizing.sh` | Unit tests | 3, 5 |
| `routines/midday.md` + mirror | Melt-up guard wiring; Rule 14 round-trip counting | 4, 6 |
| `routines/daily-summary.md` + mirror | Emits the METRICS.jsonl record | 2 |
| `routines/pre-market.md` + mirror | Rule 5 relaxed R:R when the trigger is armed | 5 |
| `routines/market-open.md` + mirror | Rule 5 trigger read; Rule 14 STEP 0 round-trip counting | 5, 6 |
| `routines/weekly-review.md` + mirror | Consumes METRICS.jsonl; emits the go-live scorecard | 8 |
| All 5 `routines/*.md` + mirrors | `TRADING_MODE`-aware endpoint guard | 7 |
| `memory/TRADING-STRATEGY.md` | Rules 5, 14, 16 | 3, 5, 6 |
| `memory/PROJECT-CONTEXT.md`, `CLAUDE.md` | Mode statement | 7 |
| `docs/LIVE-SMOKE-TEST.md` | **NEW.** Manual $200 live-path validation runbook | 8 |

---

### Task 1: `scripts/metrics.py` — deterministic session metrics, rollup, scorecard

**Why.** Every number in the weekly review is currently assembled by hand in prose. That is how the rolling alpha series ended up mixing two measurement bases with no way to recompute it. The go-live decision now rests on a two-week window, so those numbers must be machine-computed, reproducible, and unit-tested — the same reason `sizing.py` exists.

**Files:**
- Create: `scripts/metrics.py`
- Create: `tests/test_metrics.sh`
- Modify: `tests/run_all.sh` (register the new suite)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces three subcommands. Tasks 2, 5 and 8 depend on these exact names and output keys:
  - `metrics.py daily …` → one JSON object, the METRICS.jsonl record body
  - `metrics.py rollup --file F --since DATE` → aggregate over a window
  - `metrics.py scorecard --file F --since DATE` → `{"verdict": "PASS"|"FAIL", "criteria": [...]}`

- [ ] **Step 1: Write the failing tests**

Create `tests/test_metrics.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"
cd "$ROOT"

echo "test_metrics.sh"

# --- daily ---
# equity 10273.02 vs prior 10231.65 -> +0.4043%; SPY 773.26 vs 768.58 -> +0.6089%
# alpha = 0.4043 - 0.6089 = -0.2046pp
# deployment = 6656.12/10273.02 = 64.79%; cash share 35.21%
# cash_drag = -(1 - 0.6479) * 0.6089 = -0.2144pp
# selection = alpha - cash_drag = -0.2046 - (-0.2144) = +0.0098pp
start_test "daily: alpha, deployment, and cash-drag decomposition"
out=$(python3 scripts/metrics.py daily --date 2026-08-07 --equity 10273.02 \
      --prior-equity 10231.65 --lmv 6656.12 --spy-close 773.26 \
      --spy-prior-close 768.58 2>&1)
assert_contains "$out" '"day_return_pct": 0.4043'
assert_contains "$out" '"spy_day_return_pct": 0.6089'
assert_contains "$out" '"daily_alpha_pp": -0.2046'
assert_contains "$out" '"deployment_pct": 64.79'
assert_contains "$out" '"cash_drag_pp": -0.2144'
assert_contains "$out" '"selection_alpha_pp": 0.0098'
assert_contains "$out" '"in_band": false'

# a fully deployed book has zero cash drag: all alpha is selection
start_test "daily: 100% deployed -> cash_drag 0, alpha all selection"
out=$(python3 scripts/metrics.py daily --date 2026-08-07 --equity 10000 \
      --prior-equity 10000 --lmv 10000 --spy-close 101 --spy-prior-close 100 2>&1)
assert_contains "$out" '"cash_drag_pp": 0.0'
assert_contains "$out" '"selection_alpha_pp": -1.0'

# in-band check: 75.0 and 85.0 are inclusive bounds
start_test "daily: band bounds are inclusive"
out=$(python3 scripts/metrics.py daily --date 2026-08-07 --equity 10000 \
      --prior-equity 10000 --lmv 7500 --spy-close 100 --spy-prior-close 100 2>&1)
assert_contains "$out" '"in_band": true'
out=$(python3 scripts/metrics.py daily --date 2026-08-07 --equity 10000 \
      --prior-equity 10000 --lmv 8500 --spy-close 100 --spy-prior-close 100 2>&1)
assert_contains "$out" '"in_band": true'
out=$(python3 scripts/metrics.py daily --date 2026-08-07 --equity 10000 \
      --prior-equity 10000 --lmv 7499 --spy-close 100 --spy-prior-close 100 2>&1)
assert_contains "$out" '"in_band": false'

# --- rollup ---
start_test "rollup: sums alpha and counts band sessions"
mkdir -p tests/.tmp
cat > tests/.tmp/m.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":-1.07,"cash_drag_pp":-0.80,"selection_alpha_pp":-0.27,"in_band":false,"deployment_pct":64.1,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false}}
{"date":"2026-08-04","daily_alpha_pp":-0.71,"cash_drag_pp":-0.38,"selection_alpha_pp":-0.33,"in_band":true,"deployment_pct":78.8,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":1,"shallow_rotations":0},"rule5":{"triggered":true}}
EOF
out=$(python3 scripts/metrics.py rollup --file tests/.tmp/m.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"sessions": 2'
assert_contains "$out" '"cum_alpha_pp": -1.78'
assert_contains "$out" '"cum_cash_drag_pp": -1.18'
assert_contains "$out" '"cum_selection_alpha_pp": -0.6'
assert_contains "$out" '"sessions_in_band": 1'
assert_contains "$out" '"rule16_suppressed": 1'

# --- scorecard (process-only criteria) ---
start_test "scorecard: clean window PASSes and ignores negative alpha"
cat > tests/.tmp/pass.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":-5.0,"cash_drag_pp":0.0,"selection_alpha_pp":-5.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/pass.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "PASS"'

start_test "scorecard: a missing routine slot FAILs cadence"
cat > tests/.tmp/fail1.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":3,"missing":["midday"],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/fail1.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'cadence'

start_test "scorecard: an unprotected position FAILs"
cat > tests/.tmp/fail2.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":1},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/fail2.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'unprotected'

start_test "scorecard: an inaccurate Rule 14 count FAILs"
cat > tests/.tmp/fail3.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":2,"source":"local","tokens_expected":2,"tokens_found":2,"accurate":false},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/fail3.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'rule14_accuracy'

start_test "scorecard: a shallow melt-up rotation FAILs the Rule 16 criterion"
cat > tests/.tmp/fail4.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":1,"suppressed":0,"shallow_rotations":1},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/fail4.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'rule16_meltup'

start_test "scorecard: out-of-band without a Rule 5 trigger FAILs deployment"
cat > tests/.tmp/fail5.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-04","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-05","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/fail5.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'deployment'

start_test "scorecard: a recorded breach FAILs"
cat > tests/.tmp/fail6.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":["stop moved down on XLB"]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/fail6.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'breaches'

rm -rf tests/.tmp/m.jsonl tests/.tmp/pass.jsonl tests/.tmp/fail*.jsonl
print_summary
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/test_metrics.sh`
Expected: FAIL — `python3: can't open file 'scripts/metrics.py'` on every case.

- [ ] **Step 3: Implement `scripts/metrics.py`**

**A deliberate choice, do not "fix" it:** `rollup` and `scorecard` index required
keys directly (`r["rule14"]["accurate"]`, `r["ops"]["missing"]`, …) rather than
using `.get()` with defaults. A malformed or partial metrics record must raise,
not silently default to a passing value — a scorecard that quietly treats a
missing field as clean is worse than one that crashes, and silently-defaulted
absence is precisely the failure shape that let the Rule 14 fail-open survive
fourteen weeks. The only tolerated absence is `breaches`, which uses
`r.get("breaches", [])` because an empty list is its normal state.

```python
#!/usr/bin/env python3
"""Deterministic session metrics, window rollups, and the go-live scorecard.

Pure functions, no network. `daily-summary` shells out to `daily` once per
session and appends the result to memory/METRICS.jsonl; `weekly-review` shells
out to `rollup` and `scorecard`. Every number that feeds a go/no-go decision is
computed here rather than assembled by hand in prose — the v3 rolling-alpha
series became unusable precisely because it was prose.

  metrics.py daily     --date D --equity E --prior-equity P --lmv L
                       --spy-close C --spy-prior-close PC [--positions N] ...
  metrics.py rollup    --file F --since DATE
  metrics.py scorecard --file F --since DATE
"""
import argparse, json, sys

BAND_LO, BAND_HI = 75.0, 85.0        # Rule 5 deployment band, inclusive
MELTUP_SHALLOW_FLOOR = -2.0          # Rule 16 guard: drawdown floor (pct vs entry)
REDEPLOY_GRACE_SESSIONS = 2          # sessions out of band before Rule 5 must arm


def _pct(new, old):
    return 0.0 if old == 0 else (new - old) / old * 100.0


def cmd_daily(a):
    day_return = round(_pct(a.equity, a.prior_equity), 4)
    spy_return = round(_pct(a.spy_close, a.spy_prior_close), 4)
    alpha = round(day_return - spy_return, 4)
    deployment = round(0.0 if a.equity == 0 else a.lmv / a.equity * 100.0, 2)
    # Cash drag: the return the uninvested share would have earned at the
    # benchmark's rate. Negative on an up day, positive on a down day. This is
    # the decomposition the W14/W15 reviews did by hand.
    cash_share = max(0.0, 1.0 - deployment / 100.0)
    cash_drag = round(-cash_share * spy_return, 4)
    return {
        "date": a.date,
        "mode": a.mode,
        "equity": a.equity,
        "prior_equity": a.prior_equity,
        "day_return_pct": day_return,
        "lmv": a.lmv,
        "deployment_pct": deployment,
        "in_band": BAND_LO <= deployment <= BAND_HI,
        "positions": a.positions,
        "spy_close": a.spy_close,
        "spy_prior_close": a.spy_prior_close,
        "spy_day_return_pct": spy_return,
        "daily_alpha_pp": alpha,
        "cash_drag_pp": cash_drag,
        # Residual after removing the cash-drag term: the part attributable to
        # what the book owned rather than how much of it was working.
        "selection_alpha_pp": round(alpha - cash_drag, 4),
    }


def _load(path, since):
    rows = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            r = json.loads(line)
            if r.get("date", "") >= since:
                rows.append(r)
    rows.sort(key=lambda r: r["date"])
    return rows


def cmd_rollup(a):
    rows = _load(a.file, a.since)
    if not rows:
        return {"sessions": 0}
    return {
        "sessions": len(rows),
        "first_date": rows[0]["date"],
        "last_date": rows[-1]["date"],
        "cum_alpha_pp": round(sum(r["daily_alpha_pp"] for r in rows), 4),
        "cum_cash_drag_pp": round(sum(r["cash_drag_pp"] for r in rows), 4),
        "cum_selection_alpha_pp": round(
            sum(r["selection_alpha_pp"] for r in rows), 4),
        "sessions_in_band": sum(1 for r in rows if r["in_band"]),
        "rule16_rotations": sum(r["rule16"]["rotations"] for r in rows),
        "rule16_suppressed": sum(r["rule16"]["suppressed"] for r in rows),
        "rule16_shallow_rotations": sum(
            r["rule16"]["shallow_rotations"] for r in rows),
        "rule5_triggers": sum(1 for r in rows if r["rule5"]["triggered"]),
    }


def _deployment_ok(rows):
    # Out of band is acceptable only if Rule 5 arms within REDEPLOY_GRACE_SESSIONS.
    run = 0
    for r in rows:
        if r["in_band"]:
            run = 0
            continue
        run += 1
        if r["rule5"]["triggered"]:
            run = 0
            continue
        if run > REDEPLOY_GRACE_SESSIONS:
            return False, (f"{r['date']}: {run} consecutive sessions below the "
                           f"{BAND_LO}% band with no Rule 5 trigger")
    return True, ""


def cmd_scorecard(a):
    rows = _load(a.file, a.since)
    criteria = []

    def check(name, ok, detail):
        criteria.append({"name": name, "pass": bool(ok), "detail": detail})

    if not rows:
        return {"verdict": "FAIL",
                "criteria": [{"name": "data", "pass": False,
                              "detail": "no sessions in window"}]}

    slots_exp = sum(r["ops"]["routines_expected"] for r in rows)
    slots_got = sum(r["ops"]["routines_logged"] for r in rows)
    miss = [f"{r['date']}:{m}" for r in rows for m in r["ops"]["missing"]]
    check("cadence", slots_exp == slots_got and not miss,
          f"{slots_got}/{slots_exp} routine slots" +
          (f"; missing {miss}" if miss else ""))

    tok_exp = sum(r["rule14"]["tokens_expected"] for r in rows)
    tok_got = sum(r["rule14"]["tokens_found"] for r in rows)
    check("rule14_tokens", tok_exp == tok_got,
          f"{tok_got}/{tok_exp} Rule 14 audit tokens")

    bad = [r["date"] for r in rows if not r["rule14"]["accurate"]]
    check("rule14_accuracy", not bad,
          "all recorded DTC values accurate" if not bad
          else f"inaccurate on {bad}")

    unprot = [r["date"] for r in rows if r["ops"]["unprotected_positions"]]
    check("unprotected", not unprot,
          "zero unprotected positions" if not unprot
          else f"unprotected on {unprot}")

    breaches = [f"{r['date']}:{b}" for r in rows for b in r.get("breaches", [])]
    check("breaches", not breaches,
          "zero money-moving rule breaches" if not breaches else str(breaches))

    shallow = sum(r["rule16"]["shallow_rotations"] for r in rows)
    check("rule16_meltup", shallow == 0,
          f"{shallow} shallow melt-up rotations (guard should make this 0)")

    ok, detail = _deployment_ok(rows)
    check("deployment", ok,
          detail or f"never more than {REDEPLOY_GRACE_SESSIONS} sessions "
                    f"out of band without a Rule 5 trigger")

    verdict = "PASS" if all(c["pass"] for c in criteria) else "FAIL"
    roll = cmd_rollup(a)
    return {
        "verdict": verdict,
        "window": f"{rows[0]['date']}..{rows[-1]['date']}",
        "sessions": len(rows),
        "criteria": criteria,
        # Recorded for the record, NOT a gate: two weeks cannot measure alpha.
        "alpha_informational": {
            "cum_alpha_pp": roll["cum_alpha_pp"],
            "cum_cash_drag_pp": roll["cum_cash_drag_pp"],
            "cum_selection_alpha_pp": roll["cum_selection_alpha_pp"],
        },
    }


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="mode_", required=True)

    d = sub.add_parser("daily")
    d.add_argument("--date", required=True)
    d.add_argument("--mode", default="paper")
    d.add_argument("--equity", type=float, required=True)
    d.add_argument("--prior-equity", type=float, required=True,
                   dest="prior_equity")
    d.add_argument("--lmv", type=float, required=True)
    d.add_argument("--spy-close", type=float, required=True, dest="spy_close")
    d.add_argument("--spy-prior-close", type=float, required=True,
                   dest="spy_prior_close")
    d.add_argument("--positions", type=int, default=0)
    d.set_defaults(func=cmd_daily)

    r = sub.add_parser("rollup")
    r.add_argument("--file", required=True)
    r.add_argument("--since", required=True)
    r.set_defaults(func=cmd_rollup)

    s = sub.add_parser("scorecard")
    s.add_argument("--file", required=True)
    s.add_argument("--since", required=True)
    s.set_defaults(func=cmd_scorecard)

    args = p.parse_args()
    print(json.dumps(args.func(args), indent=2))


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Register the suite**

Add `test_metrics.sh` to `tests/run_all.sh` alongside the existing suites. Read the file first and match its existing loop/list style exactly — do not restructure it.

- [ ] **Step 5: Run to verify pass**

Run: `bash tests/test_metrics.sh` → `0 failed`.
Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 6: Commit**

```bash
git add scripts/metrics.py tests/test_metrics.sh tests/run_all.sh
git commit -m "feat(v3.4): metrics.py — deterministic session metrics + go-live scorecard

Every number feeding the go/no-go decision is now computed by a unit-tested
pure function instead of assembled by hand in prose. Adds the cash-drag /
selection-alpha decomposition the W14-W15 reviews did manually, and a
process-only scorecard whose criteria are fixed before the data arrives.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: `daily-summary` emits the METRICS.jsonl record

**Files:**
- Modify: `routines/daily-summary.md` (new STEP 6b after the EOD snapshot), `.claude/commands/daily-summary.md`
- Create (at runtime): `memory/METRICS.jsonl`

**Interfaces:**
- Consumes: `metrics.py daily` from Task 1.
- Produces: one JSON line per session in `memory/METRICS.jsonl`. Tasks 5 and 8 read it.

- [ ] **Step 1: Add STEP 6b to the cloud routine**

In `routines/daily-summary.md`, insert immediately after STEP 6 and before `## STEP 7`:

```markdown
## STEP 6b — Append the machine-readable metrics record (v3.4, MANDATORY)

The EOD snapshot in STEP 6 is prose for humans. This step writes the same
session as one JSON line for `weekly-review`'s scorecard. **It runs on every
session, including no-action days** — a missing line is indistinguishable from a
missing session and will FAIL the cadence criterion.

Compute the base record deterministically — never by hand:

```
# SPY closes: last two daily bars. spy_prior_close is the second-to-last.
bash scripts/alpaca.sh bars SPY 1Day 3
BASE=$(python3 scripts/metrics.py daily \
    --date "$DATE" --mode "${TRADING_MODE:-paper}" \
    --equity "$EQUITY" --prior-equity "$PRIOR_EQUITY" --lmv "$LONG_MARKET_VALUE" \
    --spy-close "$SPY_CLOSE" --spy-prior-close "$SPY_PRIOR_CLOSE" \
    --positions "$POS_COUNT")
```

Then merge in the observed fields for the session and append **one single-line**
JSON object to `memory/METRICS.jsonl` (compact, no indentation — one record per
line, the file is append-only and is never rewritten):

| Field | Source |
|---|---|
| `rule14.dtc` / `.source` | today's `Rule 14 DTC:` audit token |
| `rule14.tokens_expected` | `2` on a normal session (market-open + midday); `1` if a routine legitimately did not run (holiday) |
| `rule14.tokens_found` | count of `Rule 14 DTC:` tokens in today's TRADE-LOG rows |
| `rule14.accurate` | `false` if the recorded count differs from the true same-day round-trip count, else `true` *(see Task 6)* |
| `rule16.rotations` | ROTATE-EXIT rows written today |
| `rule16.suppressed` | `DECAY-SUPPRESSED` rows written today *(Task 4)* |
| `rule16.shallow_rotations` | rotations today whose position was shallower than **-2.0%** vs entry AND where SPY's 10-session return exceeded **+3.0%** — the exact condition the Task 3 guard exists to prevent. Should be 0 once the guard ships |
| `rule5.triggered` | `true` if today's market-open armed the re-deployment trigger *(Task 5)* |
| `rule8.scaleouts` / `.tightenings` | SCALE-OUT and STOP UPDATE rows today |
| `ops.routines_expected` | `4` on a normal session (pre-market, market-open, midday, daily-summary) |
| `ops.routines_logged` | how many of those four actually logged, per STEP 0's sweep |
| `ops.missing` | array of names STEP 0 found missing (`[]` when clean) |
| `ops.unprotected_positions` | held positions with no open GTC trailing stop after STEP 4 |
| `ops.stops_placed` | stops placed this session |
| `trades.buys` / `.sells` | fills today |
| `breaches` | array of one-line descriptions of any money-moving rule breach observed today (`[]` when clean). A day trade, a stop moved down, a -7% position left open, or a sell placed with `DTC >= 2` all belong here |

Add `memory/METRICS.jsonl` to STEP 8's `git add`.

**Never rewrite or reorder existing lines.** If today's line is already present
(a re-run), replace only that line and leave every other line byte-identical.
```

- [ ] **Step 2: Add the STEP 8 commit path**

In `routines/daily-summary.md` STEP 8, add `memory/METRICS.jsonl` to the `git add` list.

- [ ] **Step 3: Mirror**

Add the condensed equivalent to `.claude/commands/daily-summary.md` — the `metrics.py daily` call, the merge-fields list in brief, the append-one-line rule, and the never-rewrite constraint.

- [ ] **Step 4: Seed the file with the two known-good sessions**

So `weekly-review` has something to read before the trial starts, and so the schema is exercised once by hand. Create `memory/METRICS.jsonl` containing exactly two lines, for 2026-08-06 and 2026-08-07, using the real figures from the Aug 6 and Aug 7 EOD snapshots in `memory/TRADE-LOG.md`. Read those snapshots for the equity, LMV and position counts; get the SPY closes from `bash scripts/alpaca.sh bars SPY 1Day 5`. Mark `rule16.shallow_rotations: 2` on 2026-08-07 — BIIB (-0.39% vs entry) and XLF (-1.01%) both rotated while SPY's 10-session return was +4.48%, which is exactly the condition the Task 3 guard targets. Mark `rule14.accurate: false` on 2026-08-07 (recorded `DTC: 2`, true count 0).

This makes the seed data a *demonstration that the scorecard catches the two known defects* — running `metrics.py scorecard --file memory/METRICS.jsonl --since 2026-08-06` must return `FAIL` on both `rule14_accuracy` and `rule16_meltup`. Verify that it does and record the output in your report.

- [ ] **Step 5: Verify**

Run: `python3 scripts/metrics.py scorecard --file memory/METRICS.jsonl --since 2026-08-06`
Expected: `"verdict": "FAIL"` with `rule14_accuracy` and `rule16_meltup` both failing.
Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 6: Commit**

```bash
git add routines/daily-summary.md .claude/commands/daily-summary.md memory/METRICS.jsonl
git commit -m "feat(v3.4): daily-summary emits METRICS.jsonl every session

One machine-readable record per session so the go-live scorecard reads data
rather than prose. Seeded with Aug 6-7, which the scorecard correctly FAILs on
the two known defects (DTC over-count, shallow melt-up rotations).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: `sizing.py decay` — Rule 16 melt-up guard

**Root cause.** `cmd_decay` flags on `unrealized_pct < 0 AND pos_ret_10d < spy_ret_10d`. When the benchmark's own 10-session return is large, the second condition is true for nearly every holding, so the rule cuts whichever names happen to be fractionally red. On 2026-08-07 SPY's 10-session return was **+4.48%**; all six held names lagged it; the two that were fractionally below entry (BIIB -0.39%, XLF -1.01%) were rotated out. XLF had been held two sessions and carried the best RS50 in the eleven-sector complex.

**The guard.** Suppress the *sell* — not the flag — when BOTH: the position's drawdown is shallower than `-2.0%` vs entry, AND the benchmark's 10-session return exceeds `+3.0%`. The chain keeps its state, so the rotation resumes the moment the name deepens or the benchmark cools. It is fail-safe by construction: it can only ever withhold a sell on a shallow loser.

**Files:**
- Modify: `scripts/sizing.py` (`cmd_decay`, `decay` subparser, module docstring)
- Modify: `tests/test_sizing.sh`
- Modify: `memory/TRADING-STRATEGY.md` (Rule 16)

**Interfaces:**
- Produces: `sizing.py decay … [--meltup-floor -2.0] [--meltup-benchmark 3.0]` → `{"flag": 0|1, "rotate": 0|1, "suppressed": 0|1, "reason": "..."}`. `reason` ∈ `no_flag` | `first_flag` | `rotate` | `meltup_suppressed`. Task 4 branches on `suppressed` and `reason`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_sizing.sh` immediately before `print_summary`:

```bash
# --- v3.4 Rule 16 melt-up guard ---

# baseline unchanged: no flag when above entry
start_test "decay: above entry -> no flag (unchanged)"
out=$(python3 scripts/sizing.py decay --unrealized-pct 1.5 --pos-ret-10d 2.0 \
      --spy-ret-10d 4.48 --prior-flag 0 2>&1)
assert_contains "$out" '"flag": 0'
assert_contains "$out" '"rotate": 0'
assert_contains "$out" '"reason": "no_flag"'

# baseline unchanged: first flag never rotates
start_test "decay: first flag arms the chain but does not rotate (unchanged)"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.89 \
      --spy-ret-10d 4.48 --prior-flag 0 2>&1)
assert_contains "$out" '"flag": 1'
assert_contains "$out" '"rotate": 0'
assert_contains "$out" '"reason": "first_flag"'

# the BIIB case: 2nd flag, -0.39% vs entry, SPY 10-session +4.48% -> SUPPRESSED
start_test "decay: BIIB case — shallow loser in a melt-up is suppressed"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.89 \
      --spy-ret-10d 4.48 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 1'
assert_contains "$out" '"rotate": 0'
assert_contains "$out" '"suppressed": 1'
assert_contains "$out" '"reason": "meltup_suppressed"'

# the XLF case: same shape, also suppressed
start_test "decay: XLF case — shallow loser in a melt-up is suppressed"
out=$(python3 scripts/sizing.py decay --unrealized-pct -1.01 --pos-ret-10d 2.29 \
      --spy-ret-10d 4.48 --prior-flag 1 2>&1)
assert_contains "$out" '"rotate": 0'
assert_contains "$out" '"suppressed": 1'

# the XLU case: -2.66% is DEEPER than the -2.0% floor -> still rotates
start_test "decay: XLU case — deep enough to rotate even in a melt-up"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2.66 --pos-ret-10d -1.25 \
      --spy-ret-10d 4.48 --prior-flag 1 2>&1)
assert_contains "$out" '"rotate": 1'
assert_contains "$out" '"suppressed": 0'
assert_contains "$out" '"reason": "rotate"'

# calm benchmark: a shallow loser rotates normally (guard must not fire)
start_test "decay: shallow loser rotates when the benchmark is calm"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d -1.00 \
      --spy-ret-10d 0.25 --prior-flag 1 2>&1)
assert_contains "$out" '"rotate": 1'
assert_contains "$out" '"suppressed": 0'

# both boundaries are exclusive: exactly -2.0% and exactly +3.0% do NOT suppress
start_test "decay: guard boundaries are exclusive"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2.0 --pos-ret-10d 1.0 \
      --spy-ret-10d 4.48 --prior-flag 1 2>&1)
assert_contains "$out" '"rotate": 1'
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.0 \
      --spy-ret-10d 3.0 --prior-flag 1 2>&1)
assert_contains "$out" '"rotate": 1'

# suppression must NOT reset the chain — flag stays 1 so the next session can act
start_test "decay: suppression preserves the flag chain"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.89 \
      --spy-ret-10d 4.48 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 1'

# thresholds are overridable
start_test "decay: thresholds are overridable"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.89 \
      --spy-ret-10d 4.48 --prior-flag 1 --meltup-benchmark 99 2>&1)
assert_contains "$out" '"rotate": 1'
assert_contains "$out" '"suppressed": 0'
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `unrecognized arguments: --meltup-benchmark` on the last case, and `'"reason": "no_flag"' not in output` on the rest (the current `cmd_decay` returns only `flag` and `rotate`).

- [ ] **Step 3: Implement**

Replace `cmd_decay` in `scripts/sizing.py`:

```python
# Rule 16 melt-up guard (v3.4). When the benchmark's own 10-session return is
# large, "lagging SPY" stops meaning "decaying" and starts meaning "not one of
# the handful of names carrying the index" — every holding lags, and the rule
# cuts whichever ones happen to be fractionally red. Observed 2026-08-07: SPY
# 10-session +4.48%, all six holdings lagging, BIIB (-0.39% vs entry) and XLF
# (-1.01%, held two sessions, best RS50 in the complex) both rotated out.
MELTUP_DRAWDOWN_FLOOR = -2.0   # shallower than this and the guard may apply
MELTUP_BENCHMARK_PCT = 3.0     # benchmark 10-session return above this arms it


def cmd_decay(a):
    # Flag when below entry AND lagging the benchmark over the trailing window.
    flag = 1 if (a.unrealized_pct < 0 and a.pos_ret_10d < a.spy_ret_10d) else 0
    if not flag:
        return {"flag": 0, "rotate": 0, "suppressed": 0, "reason": "no_flag"}
    if not a.prior_flag:
        return {"flag": 1, "rotate": 0, "suppressed": 0, "reason": "first_flag"}
    # Second consecutive flag — the rotation is owed. Withhold the SELL (never
    # the flag) if this is a shallow loser in a fast-rising benchmark. Both
    # bounds are exclusive, so a position exactly at the floor still rotates.
    shallow = a.unrealized_pct > a.meltup_floor
    meltup = a.spy_ret_10d > a.meltup_benchmark
    if shallow and meltup:
        # Chain state is preserved: the rotation resumes the moment the
        # position deepens past the floor or the benchmark cools.
        return {"flag": 1, "rotate": 0, "suppressed": 1,
                "reason": "meltup_suppressed"}
    return {"flag": 1, "rotate": 1, "suppressed": 0, "reason": "rotate"}
```

Add to the `decay` subparser in `main()`:

```python
    d.add_argument("--meltup-floor", type=float, default=MELTUP_DRAWDOWN_FLOOR,
                   dest="meltup_floor",
                   help="drawdown pct vs entry; shallower than this may suppress")
    d.add_argument("--meltup-benchmark", type=float,
                   default=MELTUP_BENCHMARK_PCT, dest="meltup_benchmark",
                   help="benchmark 10-session return pct above which the guard arms")
```

Update the module docstring's `decay` usage line to show both new flags.

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/test_sizing.sh` → `0 failed`. Run `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 5: Update the rulebook**

In `memory/TRADING-STRATEGY.md`, replace rule 16 with:

```markdown
16. **Momentum-decay rotation (v3, visa-aware; melt-up guard added v3.4).** At midday, a held position is flagged when it is BOTH below entry AND lagging SPY over the trailing 10 sessions (`scripts/sizing.py decay`). On the *second consecutive* flagged midday, rotate out (T+1 sell). ETFs additionally rotate if the sector exits the leading quadrant. Never acts on a same-day position (Rule 15); aborts if `daytrade_count ≥ 2` (Rule 14). The flag state for each position is recorded in TRADE-LOG.md so the next midday can detect consecutiveness. **Melt-up guard (v3.4):** the *sell* is withheld — the flag is not — when the position's drawdown is shallower than **-2.0%** vs entry AND the benchmark's own 10-session return exceeds **+3.0%**. In that regime "lagging SPY" no longer means "decaying"; it means "not one of the handful of names carrying the index", and the rule cuts whichever holdings happen to be fractionally red. Evidence: 2026-08-07, SPY 10-session +4.48%, all six holdings lagging, BIIB (-0.39% vs entry) and XLF (-1.01%, held two sessions, best RS50 in the eleven-sector complex at +9.23pp) both rotated for ~$10.55 of realized loss that bought nothing. The chain keeps its state under suppression, so the rotation resumes the moment the position deepens past the floor or the benchmark cools. The guard is fail-safe by construction: it can only ever withhold a sell on a shallow loser, never originate one.
```

- [ ] **Step 6: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh memory/TRADING-STRATEGY.md
git commit -m "feat(v3.4): Rule 16 melt-up guard

When the benchmark's own 10-session return is large, every holding lags it and
Rule 16 cuts whichever names are fractionally red. Aug 7: SPY +4.48% over 10
sessions, all six holdings lagging, BIIB (-0.39%) and XLF (-1.01%, held two
sessions with the best RS50 in the complex) both rotated. Withhold the sell -
never the flag - on a shallow loser in a fast benchmark.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Wire the melt-up guard into midday, with shadow tracking

**Why shadow tracking.** A guard that withholds a sell must be auditable: we need to know whether suppression was *right*. Every suppression writes a `DECAY-SUPPRESSED` row, and the next midday records what the position did since — that is the evidence the guard is helping rather than just holding losers.

**Files:**
- Modify: `routines/midday.md` (STEP 4 item 3, STEP 6 row templates), `.claude/commands/midday.md`

**Interfaces:**
- Consumes: `sizing.py decay`'s `suppressed` / `reason` from Task 3.
- Produces: `DECAY-SUPPRESSED` TRADE-LOG rows. Task 2's `rule16.suppressed` counts them.

- [ ] **Step 1: Update STEP 4 item 3**

In `routines/midday.md`, replace the Rule 16 block's action bullets (everything from "- Always append a `DECAY-FLAG TICKER flag=<flag>` row" through the sector-quadrant bullet) with:

```markdown
   - Always append a `DECAY-FLAG TICKER flag=<flag>` row (STEP 6) — this is the state
     the next midday reads for consecutiveness. **Write it on every outcome,
     including a suppression** *(v3.4 — suppression preserves the chain; dropping
     the row would silently reset it)*.
   - If `suppressed == 1` *(v3.4 melt-up guard)*: **do NOT sell.** The position is a
     shallow loser (drawdown shallower than -2.0% vs entry) in a fast benchmark
     (SPY 10-session > +3.0%), where "lagging SPY" means "not carrying the index"
     rather than "decaying". Append a `DECAY-SUPPRESSED` row (STEP 6) recording the
     drawdown, the benchmark's 10-session return, and how many consecutive middays
     this name has now been suppressed. No `DTC` impact — nothing is sold.
   - If `rotate == 1`: re-check Rule 14 `DTC`; if `DTC < 2`, `bash scripts/alpaca.sh close TICKER`
     (a ROTATE-EXIT) and Telegram-note it. If `DTC ≥ 2`, abort + URGENT Telegram.
   - A core ETF additionally rotates (treat as `rotate=1`) if its sector has exited the
     leading momentum quadrant per the rotation read. **The melt-up guard does not
     apply to that path** — a sector leaving the leading quadrant is an absolute
     signal, not a relative one.
   - **Shadow tracking** *(v3.4)*: before writing today's row, scan TRADE-LOG.md for a
     `DECAY-SUPPRESSED` row for this ticker on the previous trading day. If one
     exists, include in today's row what the position has done since that
     suppression (`since_suppressed: <pct>`) so the weekly review can judge whether
     withholding the sell was correct. This is the guard's own audit trail.
```

- [ ] **Step 2: Add the STEP 6 row template**

In `routines/midday.md` STEP 6, after the `DECAY-FLAG` template, add:

```markdown
For each melt-up-suppressed rotation, append a DECAY-SUPPRESSED row (v3.4):
```
### YYYY-MM-DD — DECAY-SUPPRESSED: TICKER
- Rule 16 melt-up guard: rotation owed (2nd consecutive flag) but WITHHELD.
- unrealized %X vs entry (floor -2.0%) | benchmark 10-session %Y (threshold +3.0%)
- Consecutive suppressed middays: N | since_suppressed: %Z (blank on the first)
- Chain preserved — rotation resumes when the position deepens past the floor or
  the benchmark cools. No sell placed; no DTC impact.
```
```

- [ ] **Step 3: Mirror**

Port both edits to `.claude/commands/midday.md` in its terser voice: the `suppressed == 1` branch, the no-DTC-impact note, the sector-quadrant carve-out, shadow tracking, and the row template.

- [ ] **Step 4: Verify the guard cannot silently reset a chain**

Run: `grep -n "DECAY-FLAG\|DECAY-SUPPRESSED\|suppressed" routines/midday.md .claude/commands/midday.md`
Confirm by reading the output that (a) the `DECAY-FLAG` row is written on every outcome including suppression, (b) no path writes `DECAY-SUPPRESSED` *instead of* `DECAY-FLAG`, and (c) the sector-quadrant rotation path is explicitly exempt. Record the reasoning in your report.

Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add routines/midday.md .claude/commands/midday.md
git commit -m "feat(v3.4): wire the Rule 16 melt-up guard into midday

Suppression writes a DECAY-SUPPRESSED row alongside (never instead of) the
DECAY-FLAG row, so the chain is preserved. Shadow-tracks what a suppressed
position does next, so the weekly review can judge whether withholding the
sell was correct. Sector-quadrant rotations are exempt - that signal is
absolute, not relative.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Rule 5 re-deployment trigger

**Root cause.** Rule 5 states a 75–85% target band with no mechanism that acts when the book leaves it. The Jul 29 XLI stop-out dropped deployment to 60% and it sat there for three sessions; the following Monday opened at 64.1% with $3.6K idle into a +1.42% SPY day. W14 measured ~0.9–1.0pp of cost, proposed the fix, and it was not applied; W15 cost **−1.78pp of a −1.94pp week** from the identical mechanism. Three consecutive Mondays opened below the band.

**The mechanism.** When deployment sits below 75% for 2+ consecutive sessions, permit a **core-ETF ballast add at a relaxed R:R floor of 1.5:1** (from 2:1), sized only to restore the lower band. Satellites keep the full 2:1. Bounded deliberately: core only, ballast sizing only, and it expires the moment the band is restored.

**Files:**
- Modify: `scripts/sizing.py` (new `redeploy` subcommand), `tests/test_sizing.sh`
- Modify: `routines/market-open.md` (STEP 2 computes the trigger), `.claude/commands/market-open.md`
- Modify: `routines/pre-market.md` (relaxed R:R when armed), `.claude/commands/pre-market.md`
- Modify: `memory/TRADING-STRATEGY.md` (Rule 5, Entry Checklist)

**Interfaces:**
- Consumes: `memory/METRICS.jsonl` from Task 2 for the consecutive-sessions count.
- Produces: `sizing.py redeploy --equity E --lmv L --sessions-below-band N` → `{"deployment_pct", "below_band", "triggered", "rr_floor", "restore_dollars"}`. Task 2's `rule5.triggered` records it.

- [ ] **Step 1: Write the failing tests**

Append to `tests/test_sizing.sh` before `print_summary`:

```bash
# --- v3.4 Rule 5 re-deployment trigger ---

# in band -> not triggered, full 2:1
start_test "redeploy: in band -> no trigger, R:R stays 2.0"
out=$(python3 scripts/sizing.py redeploy --equity 10000 --lmv 8000 \
      --sessions-below-band 0 2>&1)
assert_contains "$out" '"below_band": false'
assert_contains "$out" '"triggered": false'
assert_contains "$out" '"rr_floor": 2.0'

# first session below band -> below_band true but NOT yet triggered (grace)
start_test "redeploy: first session below band is grace, not a trigger"
out=$(python3 scripts/sizing.py redeploy --equity 10000 --lmv 6400 \
      --sessions-below-band 1 2>&1)
assert_contains "$out" '"below_band": true'
assert_contains "$out" '"triggered": false'
assert_contains "$out" '"rr_floor": 2.0'

# the Aug 3 case: 64.11% deployed for a 6th consecutive session -> triggered
start_test "redeploy: Aug 3 case — 2+ sessions below band arms the trigger"
out=$(python3 scripts/sizing.py redeploy --equity 10120.56 --lmv 6492.89 \
      --sessions-below-band 6 2>&1)
assert_contains "$out" '"triggered": true'
assert_contains "$out" '"rr_floor": 1.5'

# restore_dollars is the gap to the 75% floor, never negative
start_test "redeploy: restore_dollars is the gap to the 75% floor"
out=$(python3 scripts/sizing.py redeploy --equity 10000 --lmv 6400 \
      --sessions-below-band 2 2>&1)
assert_contains "$out" '"restore_dollars": 1100.0'

start_test "redeploy: restore_dollars is 0 when in band"
out=$(python3 scripts/sizing.py redeploy --equity 10000 --lmv 8000 \
      --sessions-below-band 0 2>&1)
assert_contains "$out" '"restore_dollars": 0.0'

# above the ceiling is not "below band" and never triggers
start_test "redeploy: above the ceiling never triggers"
out=$(python3 scripts/sizing.py redeploy --equity 10000 --lmv 8600 \
      --sessions-below-band 0 2>&1)
assert_contains "$out" '"below_band": false'
assert_contains "$out" '"triggered": false'
```

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/test_sizing.sh`
Expected: FAIL — `invalid choice: 'redeploy'`.

- [ ] **Step 3: Implement**

Add to `scripts/sizing.py` after `cmd_rscreen`:

```python
# Rule 5 re-deployment trigger (v3.4). Rule 5 stated a 75-85% target band with
# no mechanism that acted when the book left it. Measured cost: ~0.9-1.0pp
# (W14), then -1.78pp of a -1.94pp week (W15) from the same mechanism.
DEPLOY_FLOOR_PCT = 75.0
DEPLOY_CEIL_PCT = 85.0
REDEPLOY_GRACE_SESSIONS = 2   # below band this many sessions before arming
RR_FLOOR_NORMAL = 2.0
RR_FLOOR_RELAXED = 1.5        # core ETF ballast only


def cmd_redeploy(a):
    deployment = 0.0 if a.equity == 0 else a.lmv / a.equity * 100.0
    below = deployment < DEPLOY_FLOOR_PCT
    triggered = below and a.sessions_below_band >= REDEPLOY_GRACE_SESSIONS
    restore = max(0.0, a.equity * DEPLOY_FLOOR_PCT / 100.0 - a.lmv)
    return {
        "deployment_pct": round(deployment, 2),
        "below_band": below,
        "triggered": triggered,
        # The relaxed floor applies to tier=core ballast adds ONLY. Satellites
        # keep the full 2:1 requirement in every regime.
        "rr_floor": RR_FLOOR_RELAXED if triggered else RR_FLOOR_NORMAL,
        "restore_dollars": round(restore, 2),
    }
```

Add the subparser in `main()`:

```python
    rd = sub.add_parser("redeploy")
    rd.add_argument("--equity", type=float, required=True)
    rd.add_argument("--lmv", type=float, required=True)
    rd.add_argument("--sessions-below-band", type=int, required=True,
                    dest="sessions_below_band",
                    help="consecutive prior sessions with deployment < 75%%")
    rd.set_defaults(func=cmd_redeploy)
```

Update the module docstring.

- [ ] **Step 4: Run to verify pass**

Run: `bash tests/test_sizing.sh` → `0 failed`. Run `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 5: Wire into market-open STEP 2**

In `routines/market-open.md` STEP 2, after the `COMMITTED_*` accumulator block, add:

```markdown
**Rule 5 re-deployment trigger** *(v3.4)*. Count how many consecutive prior
sessions closed below the 75% floor by reading `memory/METRICS.jsonl` backwards
from the most recent line, counting entries with `"in_band": false` until the
first `true` (0 if the last line is in band; 0 if the file is absent). Then:

```
REDEPLOY_JSON=$(python3 scripts/sizing.py redeploy \
    --equity "$EQUITY" --lmv "$LONG_MARKET_VALUE" \
    --sessions-below-band "$SESSIONS_BELOW_BAND")
```

Parse `triggered`, `rr_floor` and `restore_dollars`. When `triggered` is true:
- The R:R floor for **`tier: core` ideas only** drops to `rr_floor` (1.5). Satellites
  keep 2:1 in every regime.
- Size core ballast adds to restore the band — target `restore_dollars`, and never
  exceed it purely to fill headroom.
- Record the trigger in the mandatory Market-Open Run row (STEP 7) as
  `Rule 5 REDEPLOY: armed (deployment X%, N sessions below band, restore $Y, R:R floor 1.5)`.

When `triggered` is false, note `Rule 5 REDEPLOY: not armed` in the same row. Task 2's
metrics record reads this line for `rule5.triggered`, so it must appear on every run.
```

- [ ] **Step 6: Wire into pre-market**

In `routines/pre-market.md`, in the section that ranks ideas by R:R, add:

```markdown
**Rule 5 relaxed R:R** *(v3.4)*. Before screening, compute the re-deployment
trigger exactly as market-open STEP 2 does (`sizing.py redeploy`, with the
consecutive-below-band count read from `memory/METRICS.jsonl`). If `triggered`
is true, a **`tier: core` idea qualifies at R:R ≥ 1.5:1** instead of ≥ 2:1;
satellites are unchanged at ≥ 2:1. Tag any idea admitted under the relaxed floor
`rr-relaxed: yes (Rule 5 redeploy)` on its idea line so market-open and the
weekly review can see which entries used it. When the trigger is not armed, the
floor is 2:1 for everything and no tag is written.

This exists because the 2:1 gate — correct for satellites — was the sole blocker
on ballast re-exposure after an involuntary exit on 2026-07-30, while the book
sat 40% in cash through a rallying tape.
```

- [ ] **Step 7: Update the rulebook**

In `memory/TRADING-STRATEGY.md`, replace rule 5:

```markdown
5. Target 75–85% of capital deployed. **Re-deployment trigger (v3.4):** when deployment sits below the 75% floor for **2+ consecutive sessions**, a `tier: core` ETF ballast add qualifies at a relaxed **R:R ≥ 1.5:1** (instead of ≥ 2:1), sized only to restore the lower band (`sizing.py redeploy` returns `restore_dollars`). Satellites keep the full ≥ 2:1 requirement in every regime. The relaxation expires the moment deployment re-enters the band. Rationale: Rule 5 previously stated a target with no mechanism that acted when the book left it — a stop-out dropped deployment to 60% on 2026-07-29 and it stayed there for three sessions, then opened the following Monday at 64.1% with $3.6K idle into a +1.42% SPY session. Measured cost ~0.9–1.0pp (Week 14) and **−1.78pp of a −1.94pp week** (Week 15) from the identical mechanism.
```

In the `## Entry Checklist`, change the R:R line to:

```markdown
- What is the target (minimum 2:1 risk/reward — or 1.5:1 for a `tier: core` ballast add while the Rule 5 re-deployment trigger is armed)?
```

- [ ] **Step 8: Mirrors**

Port the market-open STEP 2 trigger block and the pre-market relaxed-R:R paragraph to `.claude/commands/market-open.md` and `.claude/commands/pre-market.md` in their terser voice.

- [ ] **Step 9: Verify the relaxation cannot leak to satellites**

Run: `grep -n "1.5\|rr_floor\|rr-relaxed" routines/market-open.md routines/pre-market.md memory/TRADING-STRATEGY.md .claude/commands/market-open.md .claude/commands/pre-market.md`
Read every hit and confirm each one is scoped to `tier: core`. Record the confirmation in your report. A relaxed floor reaching satellites would loosen the entry gate on exactly the sleeve that carries idiosyncratic risk.

Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 10: Commit**

```bash
git add scripts/sizing.py tests/test_sizing.sh routines/market-open.md \
        routines/pre-market.md .claude/commands/market-open.md \
        .claude/commands/pre-market.md memory/TRADING-STRATEGY.md
git commit -m "feat(v3.4): Rule 5 re-deployment trigger

Rule 5 stated a 75-85% band with no mechanism that acted when the book left it.
Cost ~1.0pp in W14 and -1.78pp of a -1.94pp week in W15 from the same
mechanism. Below the floor for 2+ sessions now relaxes the R:R floor to 1.5:1
for core ETF ballast adds only, sized to restore the band. Satellites unchanged.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Rule 14 — count only genuine round trips

**Root cause (mine, from the v3.3 spec).** The v3.3 mid-loop instruction says to add *every* sell executed in the batch to the derived count. On 2026-08-07 two rotations produced `Rule 14 DTC: 2 (source=local)` when the true day-trade count was **0** — neither name was bought that day. Consequence: any two-sell midday exhausts the ≤1 buffer, so a third exit (a Rule 7 hard-close) is blocked on arithmetic rather than risk. Contained today only because STEP 4 orders hard-closes first. **This is more dangerous live**, where a transient API failure drops the resolution to `source=local` and the over-count can block a genuine stop-loss.

**The fix.** A sell increments the derived count **only when the same symbol also has a buy fill on the same date** — i.e. only when it actually completes a round trip. Keep the conservative figure as a logged secondary so nothing is lost from the audit trail.

**Files:**
- Modify: `routines/midday.md` (STEP 2 resolution, STEP 5 mid-loop), `.claude/commands/midday.md`
- Modify: `routines/market-open.md` (STEP 0 catch-up batch accumulation), `.claude/commands/market-open.md`
- Modify: `memory/TRADING-STRATEGY.md` (Rule 14 clause (b))

**Interfaces:**
- Consumes: `alpaca.sh dtc` and `alpaca.sh activities` (both existing).
- Produces: the audit token gains a second figure — `Rule 14 DTC: <N> (source=…) [conservative: <M>]`. Task 2's `rule14.accurate` is `true` when `N` equals the true round-trip count.

- [ ] **Step 1: Correct the derivation in midday STEP 2**

In `routines/midday.md` STEP 2, in the local-derivation branch (clause 2 of the three-source resolution), replace the derivation sentence with:

```markdown
   count same-day **round trips**: a symbol contributes 1 only when `activities`
   shows BOTH a buy fill AND a sell fill for that symbol on the **same calendar
   date**. A sell with no same-date buy for that symbol is not a day trade and
   MUST NOT increment the count *(v3.4 — the prior convention counted every sell,
   which produced `DTC: 2` on 2026-08-07 when the true count was 0)*. Corroborate
   against TRADE-LOG.md; on disagreement take the higher and send an URGENT.
```

- [ ] **Step 2: Correct the STEP 5 mid-loop accumulation**

In `routines/midday.md` STEP 5, replace the batch-accumulation sentence with:

```markdown
When `source=unavailable`, re-derive the local count and add **only those sells
already executed earlier in this STEP 5 loop whose symbol also has a buy fill
today** — not the raw loop count *(v3.4)*. Track the raw count separately as
`DTC_CONSERVATIVE` and log both. Under Rules 13 and 15 a rotation or hard-close
can never be a same-day round trip, so in normal operation the derived count
stays 0 through any number of sells; a non-zero value means Rule 13 or 15 was
bypassed and is itself URGENT-worthy.
```

- [ ] **Step 3: Update the audit token format**

Everywhere the `Rule 14 DTC:` token is emitted (`routines/midday.md` STEP 6, `routines/market-open.md` STEP 7, and both mirrors), extend the literal to:

```
- Rule 14 DTC: <N> (source=api|local|none|error) [conservative: <M>]
```

`N` is the round-trip count that gates the ≤1 buffer and the `>= 2` abort. `M` is the raw sell count, retained for the audit trail. When `source=api`, `M` is omitted — the broker figure needs no secondary. **The literal prefix `Rule 14 DTC:` must not change**; the weekly-review sweep greps for it.

- [ ] **Step 4: Apply the same correction to market-open STEP 0**

In `routines/market-open.md` STEP 0's catch-up sell path, the batch accumulation has the identical defect. Apply the same round-trip rule and the same `[conservative: M]` logging.

- [ ] **Step 5: Update the rulebook**

In `memory/TRADING-STRATEGY.md` Rule 14, replace clause (b) with:

```markdown
(b) `source=unavailable` (the paper endpoint omits the field) → derive the count from `alpaca.sh activities` over the last 5 business days as primary and `TRADE-LOG.md` as corroboration, counting only **same-day round trips** — a symbol contributes 1 only when it has BOTH a buy fill and a sell fill on the same calendar date. A sell with no same-date buy is not a day trade and does not increment the count *(v3.4 — the prior convention counted every sell and recorded `DTC: 2` on 2026-08-07 against a true count of 0, which would block a legitimate third exit on arithmetic)*. Tag `source=local`. Rules 13/15 make this structurally 0, so a non-zero result is itself an URGENT-worthy alarm. The raw sell count is retained as a logged secondary (`[conservative: M]`) but does not gate anything.
```

- [ ] **Step 6: Mirrors**

Port all four edits to `.claude/commands/midday.md` and `.claude/commands/market-open.md`.

- [ ] **Step 7: Verify the gate was only corrected, never weakened**

Run: `grep -n "DTC\|daytrade" memory/TRADING-STRATEGY.md | head -20`
Confirm by reading that Rule 14 still contains: the pre-flight requirement, the `>= 2` abort, the `source=none`/`error` sell-block, and the mandatory audit token. Confirm Rules 13 and 15 are byte-unchanged versus the branch point. Record both confirmations in your report.

Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 8: Commit**

```bash
git add routines/midday.md routines/market-open.md \
        .claude/commands/midday.md .claude/commands/market-open.md \
        memory/TRADING-STRATEGY.md
git commit -m "fix(v3.4): Rule 14 counts round trips, not sells

The v3.3 convention added every sell in a batch to the derived count, logging
DTC: 2 on Aug 7 against a true count of 0. Any two-sell midday then exhausts
the <=1 buffer and blocks a third exit on arithmetic rather than risk - more
dangerous live, where an API failure drops resolution to source=local. A sell
now counts only when the symbol also has a same-date buy fill.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: `TRADING_MODE`-aware endpoint guard

**Why.** Five routines hard-assert `paper-api.alpaca.markets` and halt otherwise. Going live currently means editing and re-pasting all five — the largest recurring friction in this project, and a step that can be done half-way. A mode-aware guard makes the flip a single env-var change, catches half-done configuration, and needs no further prompt re-paste ever.

**This task does not go live.** `TRADING_MODE` defaults to `paper`; under that default every guard behaves exactly as today.

**Files:**
- Modify: all five `routines/*.md` env-var blocks + all five `.claude/commands/*.md`
- Modify: `scripts/alpaca.sh` (header comment only)
- Modify: `memory/PROJECT-CONTEXT.md`, `CLAUDE.md`
- Modify: `routines/README.md` (the setup checklist references the paper assertion)

**Interfaces:**
- Produces: `TRADING_MODE` ∈ `paper` | `live`. Task 2 records it as `mode` in each metrics line; Task 8's runbook sets it.

- [ ] **Step 1: Replace the guard in each of the five cloud routines**

In each of `routines/pre-market.md`, `market-open.md`, `midday.md`, `daily-summary.md`, `weekly-review.md`, replace the two sanity-check bullets (`ALPACA_ENDPOINT MUST contain paper-api...` and the `TRADING_ENABLED` one) with:

```markdown
- **Mode guard (v3.4).** Read `TRADING_MODE` (default `paper` when unset). It MUST be
  exactly `paper` or `live`; any other value → STOP, Telegram-alert, exit.
  - `paper` → `ALPACA_ENDPOINT` MUST contain `paper-api.alpaca.markets`.
  - `live` → `ALPACA_ENDPOINT` MUST contain `api.alpaca.markets` and MUST NOT contain
    `paper-api`.

  A mismatch in **either** direction → STOP, Telegram-alert naming both the mode and
  the endpoint, exit. This is the point: the guard catches a half-done switch — a mode
  flipped without the endpoint, or an endpoint changed without the mode — rather than
  silently trading the wrong account. Never infer the mode from the endpoint or the
  endpoint from the mode; both must be set and must agree.
- Sanity check: `TRADING_ENABLED` MUST equal `true`. If not, STOP, Telegram-alert, exit.
- **In `live` mode, prefix every Telegram message with `🔴 LIVE`** so no live alert can
  be mistaken for a paper one.
```

Add `TRADING_MODE` to each routine's required-env-var list and to its verification loop.

Leave the existing "Before exiting on ANY of the STOPs above, append the run row and commit" instruction exactly as it is — it already covers these paths.

- [ ] **Step 2: Update `scripts/alpaca.sh`**

Header comment only — no logic change. The wrapper stays mode-agnostic; the routines own the guard. Update the `ALPACA_ENDPOINT` error string to mention `TRADING_MODE`:

```bash
: "${ALPACA_ENDPOINT:?ALPACA_ENDPOINT not set in environment (paper: https://paper-api.alpaca.markets/v2 with TRADING_MODE=paper; live: https://api.alpaca.markets/v2 with TRADING_MODE=live — the two must agree)}"
```

- [ ] **Step 3: Update the memory files and CLAUDE.md**

`memory/PROJECT-CONTEXT.md` line 14 — replace the hard paper statement with one that names the mode variable and states the current value is `paper`.

`CLAUDE.md` `## Mode` section — replace "**Paper only.**" with a line stating the account follows `TRADING_MODE` (currently `paper`), that `live` requires both the mode and the endpoint to be changed together, and that no routine infers one from the other.

`routines/README.md` item 3 — update the sanity-check description to the mode-aware form.

- [ ] **Step 4: Mirrors**

Port the mode guard to all five `.claude/commands/*.md` files in their terser voice.

- [ ] **Step 5: Verify no unconditional paper assertion survives**

Run: `grep -rn "paper-api" routines/*.md .claude/commands/*.md scripts/*.sh CLAUDE.md memory/PROJECT-CONTEXT.md | grep -vi "TRADING_MODE\|paper:" `
Expected: no hit that asserts the paper endpoint unconditionally. Every surviving mention must be inside a mode-conditional branch or an explanatory string.

Run: `grep -rn "TRADING_MODE" routines/*.md | wc -l` — expect a hit in all five routines.

Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 6: Commit**

```bash
git add routines/ .claude/commands/ scripts/alpaca.sh CLAUDE.md memory/PROJECT-CONTEXT.md
git commit -m "feat(v3.4): TRADING_MODE-aware endpoint guard

Five routines hard-asserted the paper endpoint, so going live meant editing and
re-pasting all five - a step that can be done half-way. The guard now asserts
the endpoint matching TRADING_MODE and halts on a mismatch in either direction,
making the live flip a single env-var change with no further re-paste. Defaults
to paper; behaviour is unchanged until the user sets it otherwise.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 8: weekly-review scorecard + live smoke-test runbook

**Files:**
- Modify: `routines/weekly-review.md` (STEP 2 pull, STEP 3 grade card, STEP 5 entry), `.claude/commands/weekly-review.md`
- Create: `docs/LIVE-SMOKE-TEST.md`

**Interfaces:**
- Consumes: `metrics.py rollup` / `scorecard` (Task 1), `memory/METRICS.jsonl` (Task 2).

- [ ] **Step 1: weekly-review reads the metrics file**

In `routines/weekly-review.md` STEP 2, add:

```
# v3.4 — the week's numbers come from the metrics file, not from prose.
python3 scripts/metrics.py rollup    --file memory/METRICS.jsonl --since "$WEEK_START"
python3 scripts/metrics.py scorecard --file memory/METRICS.jsonl --since "$WEEK_START"
```

- [ ] **Step 2: Grade card sources numbers from the rollup**

In `routines/weekly-review.md` STEP 3, add above the metric table:

```markdown
**Source of record (v3.4).** `Week return`, `Bot vs S&P`, `Alpha vs SPX`, and the
daily attribution all come from `metrics.py rollup` — do NOT recompute them by
hand. The rollup also supplies the **cash-drag / selection-alpha decomposition**
(`cum_cash_drag_pp` vs `cum_selection_alpha_pp`), which separates the cost of
being uninvested from the cost of what was owned. Report both; a miss driven by
cash drag and a miss driven by selection call for different fixes, and the
W14–W15 reviews had to derive this split by hand.

If `memory/METRICS.jsonl` is missing sessions for the week, say so explicitly in
the entry and mark the affected figures `incomplete` rather than filling gaps by
hand — a partially hand-assembled series is how the pre-v3.3 alpha record became
unusable.
```

- [ ] **Step 3: Add the go-live scorecard section**

In `routines/weekly-review.md` STEP 5, add before the proposed-changes section:

```markdown
### Go-live scorecard (v3.4)

Paste `metrics.py scorecard`'s output verbatim, then one line per criterion in a
table: name, PASS/FAIL, detail. State the headline `verdict` explicitly.

**These criteria were fixed before the data was collected and are process-only —
alpha is recorded but is NOT a gate.** Two weeks cannot measure alpha (weekly
noise is ~±1pp), so gating on it would gate on a coin flip. What the window can
establish is that the Week 14–15 defects are fixed, deployment stays in band,
and no new defect has appeared:

| Criterion | Passes when |
|---|---|
| `cadence` | every expected routine slot logged, zero missing |
| `rule14_tokens` | every expected `Rule 14 DTC:` audit token present |
| `rule14_accuracy` | every recorded DTC equals the true round-trip count |
| `unprotected` | zero held positions without a GTC trailing stop at any EOD |
| `breaches` | zero money-moving rule breaches |
| `rule16_meltup` | zero rotations of a position shallower than -2.0% while the benchmark's 10-session return exceeded +3.0% |
| `deployment` | never more than 2 consecutive sessions below the 75% floor without the Rule 5 trigger arming |

**Do not edit these criteria to fit the result.** If a criterion looks wrong in
hindsight, say so in the review and leave the verdict as computed — changing the
bar after seeing the data is how a decision gets rationalised in either direction.
Also report `alpha_informational` alongside, clearly labelled as not a gate.
```

- [ ] **Step 4: Mirror**

Port all three edits to `.claude/commands/weekly-review.md`.

- [ ] **Step 5: Write the live smoke-test runbook**

Create `docs/LIVE-SMOKE-TEST.md`. This is a **manual, local, one-off procedure** for the $200 live account — it is deliberately not a cron routine, because the cloud routines point at one set of credentials and the strategy stays on the $10K paper account.

The runbook must cover, in order:

1. **Why this exists and what it does not do.** At $200 the strategy is inert — a 16% clip is $32 and the cheapest sector SPDR is ~$45, so `sizing.py size` returns `floor_skip` for every instrument in the universe. Include the actual command output demonstrating it. This account validates the *plumbing*, not the strategy: the strategy's evidence continues to come from the paper account.
2. **The five things paper has never proven**, each as a numbered check with the exact command and the expected result: (a) live credentials authenticate — `alpaca.sh account` returns an account with `status: ACTIVE`; (b) `alpaca.sh dtc` returns `source=api` with a real integer, the first genuine exercise of Rule 14's primary path in 15 weeks; (c) a limit BUY of one share of a sub-$32 liquid ETF fills; (d) `alpaca.sh trailing-stop` is **accepted by the live broker** for that position and appears in `orders open`; (e) `alpaca.sh close` exits cleanly and no orphan stop remains.
3. **Env setup**: `TRADING_MODE=live`, live `ALPACA_ENDPOINT`, live keys, `TRADING_ENABLED=true` — and an explicit warning that these must never be set in the cloud Routines UI while the paper trial is running, since that would point the strategy at the live account.
4. **The Rule 13 caveat**: buy and place the stop on the same day for this test, accepting that it *could* fire same-day. Note plainly that this deliberately departs from Rule 13, that it is acceptable only because it is a single manual one-share test outside the strategy, and that it must never be done from a routine.
5. **A results table to fill in**, one row per check: check, command, expected, actual, pass/fail.
6. **Teardown**: close the position, cancel any remaining orders, verify `positions` and `orders open` are both empty, then unset the live env vars.
7. **What a failure means for go-live** — specifically, that a rejected trailing stop on the live broker would invalidate Rule 6 and Rule 13, i.e. the entire visa-aware safety design, and is a hard blocker rather than a nuisance.

- [ ] **Step 6: Verify**

Run: `python3 scripts/metrics.py scorecard --file memory/METRICS.jsonl --since 2026-08-06`
Confirm the output format is what the STEP 5 template expects to paste.

Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Step 7: Commit**

```bash
git add routines/weekly-review.md .claude/commands/weekly-review.md docs/LIVE-SMOKE-TEST.md
git commit -m "feat(v3.4): go-live scorecard in weekly-review + live smoke-test runbook

Weekly numbers now come from metrics.py rollup rather than hand-assembled
prose, including the cash-drag vs selection-alpha split the W14-W15 reviews
derived manually. Adds the process-only go-live scorecard whose criteria are
fixed before the data arrives, and a manual runbook for validating the live
order path on the \$200 account without running the strategy there.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Final verification (run after Task 8)

- [ ] **All suites green**

Run: `bash tests/run_all.sh` → `ALL TESTS PASSED`.

- [ ] **Visa-critical rules unchanged**

Run: `git diff <branch-point>..HEAD -- memory/TRADING-STRATEGY.md | grep -E "^[-+]1[35]\. "`
Expected: no changes to rules 13 or 15. Rule 14's diff must only *correct the count* and *add* the conservative secondary — never remove the pre-flight, the `>= 2` abort, or the `source=none|error` sell-block.

- [ ] **Nothing goes live by accident**

Run: `grep -rn "TRADING_MODE" routines/ .claude/commands/ CLAUDE.md memory/PROJECT-CONTEXT.md`
Confirm every occurrence defaults to `paper` when unset, and that no file sets `TRADING_MODE=live` or a live endpoint anywhere in the repo.

- [ ] **The scorecard catches the known defects**

Run: `python3 scripts/metrics.py scorecard --file memory/METRICS.jsonl --since 2026-08-06`
Expected: `FAIL`, with `rule14_accuracy` and `rule16_meltup` both failing on the seeded Aug 6–7 data. A scorecard that passes the two weeks we *know* were defective is not a scorecard.

- [ ] **No gate deadlock**

Reason through and record in the completion report: with the 16% sizing cap, headroom-fit sizing, the sector cap, the ETF-core floor, the deployment ceiling, the macro-binary gate, the revised RS screen, **and** the new Rule 5 relaxation all active, can the buy-side gate reach a state where no idea of any tier can pass? Note specifically that Rule 5 only ever *loosens*, so it cannot introduce a deadlock — but confirm the interaction with the `rscreen` melt-up hole documented in Week 15 (the entry screens can still reject everything in a melt-up; Rule 5 relaxes R:R, not RS). State plainly whether that combination can still lock the book out, since it is a known-live failure mode this plan does **not** fix.

- [ ] **Re-paste list**

Run: `git diff --name-only <branch-point>..HEAD -- routines/ | grep -v README`
Expected: all five routine prompts. Report them as needing a manual re-paste, and state explicitly that this is the **last** re-paste — after v3.4 the live flip is an env-var change only.

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

# --- deployment grace-window boundary (pins REDEPLOY_GRACE_SESSIONS=2) ---
# Every criterion besides deployment is clean in these fixtures, so the
# verdict tracks the deployment criterion exactly and a boundary shift is
# visible as a flipped PASS/FAIL rather than hiding behind another failure.
start_test "scorecard boundary: exactly 2 consecutive out-of-band sessions PASSes"
cat > tests/.tmp/boundary2.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-04","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/boundary2.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "PASS"'

start_test "scorecard boundary: exactly 3 consecutive out-of-band sessions FAILs deployment with the count named"
cat > tests/.tmp/boundary3.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-04","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-05","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/boundary3.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" '3 consecutive sessions'

start_test "scorecard boundary: an in-band session resets the consecutive-OOB run"
cat > tests/.tmp/boundary-reset-inband.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-04","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-05","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":true,"deployment_pct":80.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-06","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-07","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/boundary-reset-inband.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "PASS"'

# --- v3.4: the deployment criterion measures the OUTCOME, not the arming ---
# `rule5.triggered` records that market-open ARMED the relaxed R:R floor in its
# STEP 2 — before the `Decision: HOLD` short-circuit — not that any core ballast
# was bought. Resetting the run on it made this criterion structurally unfailable:
# a melt-up window where every candidate is screened out logs `in_band:false` +
# `triggered:true` on every session and used to score PASS. It no longer does.
start_test "scorecard: a Rule 5 trigger no longer resets the consecutive-below-floor run"
cat > tests/.tmp/boundary-reset-rule5.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-04","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":true},"breaches":[]}
{"date":"2026-08-05","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
{"date":"2026-08-06","daily_alpha_pp":1.0,"cash_drag_pp":0.0,"selection_alpha_pp":1.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":false},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/boundary-reset-rule5.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'deployment'

# The reviewer's exact melt-up scenario: `rscreen` rejects every candidate, so
# pre-market HOLDs every day while market-open still arms the trigger. Ten
# sessions at 60% deployment, every row out of band and `triggered:true`. This
# is the Week-15 mechanism (-1.78pp) verbatim; it MUST be a no-go.
start_test "scorecard: 10 below-floor sessions with triggered:true on every row FAIL deployment"
python3 - <<'PY' > tests/.tmp/meltup10.jsonl
import json
for d in range(3, 13):
    print(json.dumps({
        "date": f"2026-08-{d:02d}", "daily_alpha_pp": -1.0, "cash_drag_pp": -1.0,
        "selection_alpha_pp": 0.0, "in_band": False, "deployment_pct": 60.0,
        "ops": {"routines_expected": 4, "routines_logged": 4, "missing": [],
                "unprotected_positions": 0},
        "rule14": {"dtc": 0, "source": "api", "tokens_expected": 2,
                   "tokens_found": 2, "accurate": True},
        "rule16": {"rotations": 0, "suppressed": 0, "shallow_rotations": 0},
        "rule5": {"triggered": True, "acted": False}, "breaches": []}))
PY
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/meltup10.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "FAIL"'
assert_contains "$out" 'consecutive sessions below'
assert_contains "$out" '"name": "deployment"'

# Out of band ABOVE the ceiling is not a cash-drag problem — the ceiling gates
# new buys, not mark-to-market — so a rally that marks the book past 85% must
# not be counted as a below-floor run.
start_test "scorecard: an above-ceiling run is not a below-floor run"
python3 - <<'PY' > tests/.tmp/aboveceiling.jsonl
import json
for d, dep in ((3, 86.0), (4, 87.0), (5, 88.2)):
    print(json.dumps({
        "date": f"2026-08-{d:02d}", "daily_alpha_pp": 1.0, "cash_drag_pp": 0.0,
        "selection_alpha_pp": 1.0, "in_band": False, "deployment_pct": dep,
        "ops": {"routines_expected": 4, "routines_logged": 4, "missing": [],
                "unprotected_positions": 0},
        "rule14": {"dtc": 0, "source": "api", "tokens_expected": 2,
                   "tokens_found": 2, "accurate": True},
        "rule16": {"rotations": 0, "suppressed": 0, "shallow_rotations": 0},
        "rule5": {"triggered": False, "acted": False}, "breaches": []}))
PY
out=$(python3 scripts/metrics.py scorecard --file tests/.tmp/aboveceiling.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"verdict": "PASS"'

# `rule5.acted` is the diagnostic that makes a deployment FAIL interpretable:
# armed-but-nothing-available vs armed-and-re-deployed.
start_test "rollup: rule5_acted separates an armed trigger from an executed ballast add"
cat > tests/.tmp/acted.jsonl <<'EOF'
{"date":"2026-08-03","daily_alpha_pp":0.0,"cash_drag_pp":0.0,"selection_alpha_pp":0.0,"in_band":false,"deployment_pct":60.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":true,"acted":false},"breaches":[]}
{"date":"2026-08-04","daily_alpha_pp":0.0,"cash_drag_pp":0.0,"selection_alpha_pp":0.0,"in_band":true,"deployment_pct":78.0,"ops":{"routines_expected":4,"routines_logged":4,"missing":[],"unprotected_positions":0},"rule14":{"dtc":0,"source":"api","tokens_expected":2,"tokens_found":2,"accurate":true},"rule16":{"rotations":0,"suppressed":0,"shallow_rotations":0},"rule5":{"triggered":true,"acted":true},"breaches":[]}
EOF
out=$(python3 scripts/metrics.py rollup --file tests/.tmp/acted.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"rule5_triggers": 2'
assert_contains "$out" '"rule5_acted": 1'

# Records written before `acted` existed must not crash the rollup.
start_test "rollup: a record with no rule5.acted field counts as not acted"
out=$(python3 scripts/metrics.py rollup --file tests/.tmp/m.jsonl --since 2026-08-01 2>&1)
assert_contains "$out" '"rule5_acted": 0'

rm -rf tests/.tmp/m.jsonl tests/.tmp/pass.jsonl tests/.tmp/fail*.jsonl \
       tests/.tmp/boundary*.jsonl tests/.tmp/meltup10.jsonl \
       tests/.tmp/aboveceiling.jsonl tests/.tmp/acted.jsonl
print_summary

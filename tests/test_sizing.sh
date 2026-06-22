#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"
cd "$ROOT"

echo "test_sizing.sh"

# --- size ---
# tight 5% stop: raw=200/0.05=4000 > 2000 cap → floor(2000/100)=20, clamped cap
start_test "size: tight stop clamps to 20% cap"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 2>&1)
assert_contains "$out" '"shares": 20'
assert_contains "$out" '"clamped": "cap"'

# stock 13% stop: raw=200/0.13=1538 < 2000 → floor(1538/150)=10, clamped none
start_test "size: stock 13% stop risk-parity (uncapped)"
out=$(python3 scripts/sizing.py size --equity 10000 --price 150 --stop-frac 0.13 2>&1)
assert_contains "$out" '"shares": 10'
assert_contains "$out" '"clamped": "none"'

# wide 50% stop: raw=200/0.5=400 → floor(400/100)=4, cost 400 < 500 floor → floor_skip
start_test "size: tiny risk budget below min-pos floor → floor_skip"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.5 2>&1)
assert_contains "$out" '"shares": 0'
assert_contains "$out" '"clamped": "floor_skip"'

# --- ladder ---
start_test "ladder: ETF below first tier → no action"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 3 2>&1)
assert_contains "$out" '"target_trail_pct": null'
assert_contains "$out" '"scaleouts_due": 0'

start_test "ladder: ETF +7% → trail 5, 1 scale-out"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 7 2>&1)
assert_contains "$out" '"target_trail_pct": 5'
assert_contains "$out" '"scaleouts_due": 1'

start_test "ladder: ETF +15% → trail 3, 2 scale-outs"
out=$(python3 scripts/sizing.py ladder --tier etf --unrealized-pct 15 2>&1)
assert_contains "$out" '"target_trail_pct": 3'
assert_contains "$out" '"scaleouts_due": 2'

start_test "ladder: stock +10% → trail 6, 1 scale-out"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 10 2>&1)
assert_contains "$out" '"target_trail_pct": 6'
assert_contains "$out" '"scaleouts_due": 1'

start_test "ladder: stock +25% → trail 3, 2 scale-outs"
out=$(python3 scripts/sizing.py ladder --tier stock --unrealized-pct 25 2>&1)
assert_contains "$out" '"target_trail_pct": 3'
assert_contains "$out" '"scaleouts_due": 2'

# --- decay ---
start_test "decay: 2nd consecutive lag → rotate"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2 --pos-ret-10d -3 --spy-ret-10d 1 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 1'
assert_contains "$out" '"rotate": 1'

start_test "decay: 1st occurrence → flag set, no rotate"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2 --pos-ret-10d -3 --spy-ret-10d 1 --prior-flag 0 2>&1)
assert_contains "$out" '"flag": 1'
assert_contains "$out" '"rotate": 0'

start_test "decay: above entry → no flag"
out=$(python3 scripts/sizing.py decay --unrealized-pct 1 --pos-ret-10d -3 --spy-ret-10d 1 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 0'
assert_contains "$out" '"rotate": 0'

start_test "decay: below entry but beating SPY → no flag"
out=$(python3 scripts/sizing.py decay --unrealized-pct -2 --pos-ret-10d 2 --spy-ret-10d 1 --prior-flag 1 2>&1)
assert_contains "$out" '"flag": 0'
assert_contains "$out" '"rotate": 0'

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

print_summary

#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"
cd "$ROOT"

echo "test_sizing.sh"

# --- size ---
# tight 5% stop: raw=200/0.05=4000 > 1600 cap → floor(1600/100)=16, clamped cap
# (v3.3: default max-pos-pct lowered 0.20 → 0.16 so five clips fit under the 85% ceiling)
start_test "size: tight stop clamps to 16% cap (v3.3)"
out=$(python3 scripts/sizing.py size --equity 10000 --price 100 --stop-frac 0.05 2>&1)
assert_contains "$out" '"shares": 16'
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
assert_contains "$out" '"suppressed": 0'
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.0 \
      --spy-ret-10d 3.0 --prior-flag 1 2>&1)
assert_contains "$out" '"rotate": 1'
assert_contains "$out" '"suppressed": 0'

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

# --meltup-floor is overridable too, pinned in both directions so a dropped
# override (e.g. cmd_decay hardcoding MELTUP_DRAWDOWN_FLOOR instead of reading
# a.meltup_floor) cannot pass either way.
# BIIB shape (default floor would suppress): overriding the floor to 0 makes
# -0.39% no longer "shallower than the floor" -> the guard must not fire.
start_test "decay: --meltup-floor override to 0 forces a rotate"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.89 \
      --spy-ret-10d 4.48 --prior-flag 1 --meltup-floor 0 2>&1)
assert_contains "$out" '"rotate": 1'
assert_contains "$out" '"suppressed": 0'

# same BIIB shape, floor overridden to -5: still shallower than -5, so the
# guard still fires. Paired with the case above, this pins the argument in
# both directions -- a hardcoded default could only satisfy one of the two.
start_test "decay: --meltup-floor override to -5 still suppresses"
out=$(python3 scripts/sizing.py decay --unrealized-pct -0.39 --pos-ret-10d 1.89 \
      --spy-ret-10d 4.48 --prior-flag 1 --meltup-floor -5 2>&1)
assert_contains "$out" '"suppressed": 1'
assert_contains "$out" '"reason": "meltup_suppressed"'

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

print_summary

#!/usr/bin/env python3
"""Deterministic trade-sizing and exit math for auto_invest v3.

Pure functions, no network. Routines shell out to this so position sizing,
profit-taking, and rotation decisions are deterministic instead of LLM
arithmetic. All modes print one JSON object to stdout.

  sizing.py size   --equity E --price P --stop-frac S [--risk-pct 0.02]
                   [--max-pos-pct 0.16] [--min-pos-pct 0.05] [--headroom H]
  sizing.py ladder --tier etf|stock --unrealized-pct X
  sizing.py decay  --unrealized-pct X --pos-ret-10d A --spy-ret-10d B
                   --prior-flag 0|1 [--meltup-floor -2.0]
                   [--meltup-benchmark 3.0]
  sizing.py rscreen --rs10 X --rs50 Y --close C --dma50 D --dma50-prior P
  sizing.py redeploy --equity E --lmv L --sessions-below-band N
"""
import argparse, json, math


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


# Each tier: (unrealized_pct_trigger, target_trail_pct, cumulative_scaleouts).
# Ordered ascending. Trail floor is 3 (Rule 9: never inside 3% of price).
LADDERS = {
    "etf":   [(4, 7, 0), (7, 5, 1), (10, 4, 1), (15, 3, 2)],
    "stock": [(6, 7, 0), (10, 6, 1), (15, 4, 1), (25, 3, 2)],
}


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


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="mode", required=True)

    s = sub.add_parser("size")
    s.add_argument("--equity", type=float, required=True)
    s.add_argument("--price", type=float, required=True)
    s.add_argument("--stop-frac", type=float, required=True, dest="stop_frac")
    s.add_argument("--risk-pct", type=float, default=0.02, dest="risk_pct")
    s.add_argument("--max-pos-pct", type=float, default=0.16, dest="max_pos_pct")
    s.add_argument("--min-pos-pct", type=float, default=0.05, dest="min_pos_pct")
    s.add_argument("--headroom", type=float, default=None,
                   help="remaining deployment dollars to the 85%% ceiling; "
                        "clip shrinks to fit rather than being refused")
    s.set_defaults(func=cmd_size)

    l = sub.add_parser("ladder")
    l.add_argument("--tier", choices=["etf", "stock"], required=True)
    l.add_argument("--unrealized-pct", type=float, required=True,
                   dest="unrealized_pct")
    l.add_argument("--hwm-pct", type=float, default=None, dest="hwm_pct")
    l.set_defaults(func=cmd_ladder)

    d = sub.add_parser("decay")
    d.add_argument("--unrealized-pct", type=float, required=True,
                   dest="unrealized_pct")
    d.add_argument("--pos-ret-10d", type=float, required=True, dest="pos_ret_10d")
    d.add_argument("--spy-ret-10d", type=float, required=True, dest="spy_ret_10d")
    d.add_argument("--prior-flag", type=int, choices=[0, 1], required=True,
                   dest="prior_flag")
    d.add_argument("--meltup-floor", type=float, default=MELTUP_DRAWDOWN_FLOOR,
                   dest="meltup_floor",
                   help="drawdown pct vs entry; shallower than this may suppress")
    d.add_argument("--meltup-benchmark", type=float,
                   default=MELTUP_BENCHMARK_PCT, dest="meltup_benchmark",
                   help="benchmark 10-session return pct above which the guard arms")
    d.set_defaults(func=cmd_decay)

    so = sub.add_parser("scaleout")
    so.add_argument("--cur-qty", type=int, required=True, dest="cur_qty")
    so.add_argument("--scaleouts-due", type=int, required=True, dest="scaleouts_due")
    so.add_argument("--scaleouts-done", type=int, required=True, dest="scaleouts_done")
    so.set_defaults(func=cmd_scaleout)

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

    rd = sub.add_parser("redeploy")
    rd.add_argument("--equity", type=float, required=True)
    rd.add_argument("--lmv", type=float, required=True)
    rd.add_argument("--sessions-below-band", type=int, required=True,
                    dest="sessions_below_band",
                    help="consecutive prior sessions with deployment < 75%%")
    rd.set_defaults(func=cmd_redeploy)

    args = p.parse_args()
    print(json.dumps(args.func(args)))


if __name__ == "__main__":
    main()

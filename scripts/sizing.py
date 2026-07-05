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


def cmd_decay(a):
    # Flag when below entry AND lagging SPY over the trailing window.
    flag = 1 if (a.unrealized_pct < 0 and a.pos_ret_10d < a.spy_ret_10d) else 0
    rotate = 1 if (flag and a.prior_flag) else 0
    return {"flag": flag, "rotate": rotate}


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
    d.set_defaults(func=cmd_decay)

    so = sub.add_parser("scaleout")
    so.add_argument("--cur-qty", type=int, required=True, dest="cur_qty")
    so.add_argument("--scaleouts-due", type=int, required=True, dest="scaleouts_due")
    so.add_argument("--scaleouts-done", type=int, required=True, dest="scaleouts_done")
    so.set_defaults(func=cmd_scaleout)

    args = p.parse_args()
    print(json.dumps(args.func(args)))


if __name__ == "__main__":
    main()

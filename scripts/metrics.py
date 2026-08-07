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


def _round(x, nd=4):
    # round() preserves IEEE-754 signed zero (e.g. round(-0.0, 4) == -0.0),
    # and json.dumps renders that as "-0.0" — numerically equal to 0.0 but a
    # different string. Normalize so a zero-drag/zero-return session prints
    # the same way every time instead of depending on multiplication order.
    v = round(x, nd)
    return 0.0 if v == 0 else v


def cmd_daily(a):
    day_return = _round(_pct(a.equity, a.prior_equity))
    spy_return = _round(_pct(a.spy_close, a.spy_prior_close))
    alpha = _round(day_return - spy_return)
    deployment = round(0.0 if a.equity == 0 else a.lmv / a.equity * 100.0, 2)
    # Cash drag: the return the uninvested share would have earned at the
    # benchmark's rate. Negative on an up day, positive on a down day. This is
    # the decomposition the W14/W15 reviews did by hand.
    cash_share = max(0.0, 1.0 - deployment / 100.0)
    cash_drag = _round(-cash_share * spy_return)
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
        "selection_alpha_pp": _round(alpha - cash_drag),
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
        "cum_alpha_pp": _round(sum(r["daily_alpha_pp"] for r in rows)),
        "cum_cash_drag_pp": _round(sum(r["cash_drag_pp"] for r in rows)),
        "cum_selection_alpha_pp": _round(
            sum(r["selection_alpha_pp"] for r in rows)),
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

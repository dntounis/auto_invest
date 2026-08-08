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
import argparse, json

BAND_LO, BAND_HI = 75.0, 85.0        # Rule 5 deployment band, inclusive
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
        # `triggered` is "market-open armed the relaxed floor"; `acted` is "a
        # core ballast add actually filled under it". Reported side by side so
        # a deployment FAIL can be read as armed-but-nothing-available versus
        # armed-and-re-deployed. Absent on pre-v3.4 records -> counts as 0.
        "rule5_acted": sum(1 for r in rows if r["rule5"].get("acted")),
    }


def _below_floor(r):
    # Only the LOWER breach counts. `in_band` is false above the 85% ceiling
    # too, but the ceiling gates new buys rather than mark-to-market, so a rally
    # that marks the book past it costs nothing and nothing acts on it —
    # counting those sessions would produce a false no-go with a detail line
    # that literally says "below the floor". A record missing the field counts
    # as below-floor: absent evidence must never silently clear a go-live gate.
    return r.get("deployment_pct", 0.0) < BAND_LO


def _deployment_ok(rows):
    # More than REDEPLOY_GRACE_SESSIONS consecutive sessions below the floor is
    # a FAIL, full stop. An in-band session resets the run; nothing else does.
    #
    # Until v3.4 the run was ALSO reset by `rule5.triggered`, which made this
    # criterion structurally impossible to fail. `triggered` records that
    # market-open ARMED the relaxed R:R floor — computed in its STEP 2, before
    # the `Decision: HOLD` short-circuit — not that any core ballast was bought.
    # A melt-up window where `rscreen` rejects every candidate therefore logs
    # out-of-band + `triggered:true` on every session and used to score PASS:
    # the exact Week-15 mechanism (-1.78pp of a -1.94pp week) this scorecard
    # exists to catch.
    #
    # A legitimately blocked window — nothing passes the screens — now FAILs.
    # That is intended, not collateral damage: it is precisely the state that
    # cost the phase 1.78pp, and a go-live decision should not pass through it.
    # `rule5.acted` (surfaced as `rule5_acted` in the rollup) is the diagnostic
    # that makes the failure interpretable: armed but nothing available, versus
    # armed and actually re-deployed.
    run = 0
    for r in rows:
        if not _below_floor(r):
            run = 0
            continue
        run += 1
        if run > REDEPLOY_GRACE_SESSIONS:
            return False, (f"{r['date']}: {run} consecutive sessions below the "
                           f"{BAND_LO}% floor")
    return True, ""


def cmd_scorecard(a):
    rows = _load(a.file, a.since)
    criteria = []

    def check(name, ok, detail):
        criteria.append({"name": name, "pass": bool(ok), "detail": detail})

    if not rows:
        return {"verdict": "FAIL",
                "window": None,
                "sessions": 0,
                "criteria": [{"name": "data", "pass": False,
                              "detail": "no sessions in window"}],
                "alpha_informational": {
                    "cum_alpha_pp": None,
                    "cum_cash_drag_pp": None,
                    "cum_selection_alpha_pp": None,
                }}

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
          detail or f"never more than {REDEPLOY_GRACE_SESSIONS} consecutive "
                    f"sessions below the {BAND_LO}% floor")

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

#!/usr/bin/env python3
"""Attempt-2 dev selection (PREREGISTRATION-2.md). Never touches the test window."""
import json, sys
from dataclasses import replace
from datetime import date
from multiprocessing import Pool
from sim import *
U_ = dict(core_floor_bootstrap=True, sector_cap_first_exempt=True, core_trend_exempt=True)
M_ = dict(rank_mode="momentum")
H_ = dict(decay_min_hold=10)
Q_ = dict(quadrant_needs_dma=True, quadrant_confirm=2)
C_ = dict(reentry_cooldown=10)
N_ = dict(max_new_per_day=2)
def mk(name, *parts):
    kw = {}
    for p in parts: kw.update(p)
    return name, replace(BASELINE, name=name, **kw), len(parts)
CANDS = [mk("v3.4"), mk("v3.4+HQ", H_, Q_), mk("U", U_), mk("U+HQ", U_, H_, Q_),
         mk("U+HQ+R200", U_, H_, Q_, dict(regime="all200")), mk("UM", U_, M_), mk("UM+HQ", U_, M_, H_, Q_),
         mk("UM+HQ+R200", U_, M_, H_, Q_, dict(regime="all200")), mk("UM+HQ+R50", U_, M_, H_, Q_, dict(regime="all50")),
         mk("UM+HQ+C+N", U_, M_, H_, Q_, C_, N_), mk("U+HQ+C+N+R200", U_, H_, Q_, C_, N_, dict(regime="all200")),
         mk("UM+HQ+C+N+R200", U_, M_, H_, Q_, C_, N_, dict(regime="all200"))]
D0, D1 = date(2022, 1, 3), date(2026, 9, 2)
FOLDS = [(date(y, m, 1), date(y, m + 5, 30 if m == 1 else 31)) for y in range(2022, 2027) for m in (1, 7)]
FOLDS = [(a, min(b, D1)) for a, b in FOLDS if a <= D1]
FOLDS[-1] = (date(2026, 7, 1), D1)
data = Data()
def one(c):
    name, cfg, nk = c
    r = run(cfg, data, D0, D1)
    full = metrics(r, data, D0, D1)
    folds = [metrics(r, data, a, b)["ret_pct"] for a, b in FOLDS]
    return name, nk, full, folds
if __name__ == "__main__":
    with Pool(6) as p:
        res = p.map(one, CANDS)
    base = res[0][3]
    rows = []
    for name, nk, full, folds in res:
        beats = sum(1 for f, b in zip(folds, base) if f > b)
        rows.append(dict(name=name, knobs=nk, beats=beats, full=full, folds=folds))
        print(f"{name:16s} ret {full['ret_pct']:+7.2f} spy {full['spy_pct']:+6.2f} sh {full['sharpe']:+5.2f} dd {full['max_dd_pct']:+6.2f} dep {full['avg_deploy_pct']:5.1f} buys {full['buys']:4d} beats {beats}/10 | " + " ".join(f"{f:+5.1f}" for f in folds))
    elig = [r for r in rows if r["beats"] >= 7 and r["name"] != "v3.4"]
    if not elig:
        elig = [r for r in rows if r["full"]["ret_pct"] > rows[0]["full"]["ret_pct"] and r["name"] != "v3.4"]
    pick = sorted(elig, key=lambda r: (-r["full"]["sharpe"], r["knobs"]))[0]
    print("SELECTED:", pick["name"])
    json.dump(dict(folds=[[str(a), str(b)] for a, b in FOLDS], rows=rows, selected=pick["name"]),
              open("attempt2-dev.json", "w"), indent=1, default=float)

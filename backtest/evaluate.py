#!/usr/bin/env python3
"""Pre-registered test-window evaluation (see PREREGISTRATION.md). Writes results.json."""
import json
from dataclasses import replace
from datetime import date
from sim import *
import sys
from attempt2 import CANDS
SEL = sys.argv[1]
V35 = [c for n, c, k in CANDS if n == SEL][0]
OUT = sys.argv[2]
data = Data()
T0, T1 = date(2026, 9, 3), date(2026, 11, 3)
CFG = {"v3.4": BASELINE, "v3.5": V35}
out = {}
def m(cfg, start, book=None, slip=None):
    c = replace(cfg, slip=slip) if slip else cfg
    r = run(c, data, start, T1, book=book)
    return metrics(r, data, max(start, T0), T1), r
for k, cfg in CFG.items():
    out[k] = {}
    out[k]["A_seeded"], rA = m(cfg, T0, book=seed_book_2026_09_02())
    out[k]["B_cold"], _ = m(cfg, T0)
    out[k]["C_continuous_from_Jan5"], _ = m(cfg, date(2026, 1, 5))
    out[k]["D_seeded_slip15bps"], _ = m(cfg, T0, book=seed_book_2026_09_02(), slip=0.0015)
    days = [d for d in data.days if T0 <= d <= T1][:10]
    out[k]["E_jitter"] = [m(cfg, d)[0] for d in days]
    out[k]["A_events"] = [[str(e[0]), e[1], e[2], int(e[3]), float(e[4]), e[5], float(e[6])] for e in rA["events"]]
b, n = out["v3.4"], out["v3.5"]
pa, pb = n["A_seeded"]["pnl"], b["A_seeded"]["pnl"]
c1 = pa > pb and (pa - pb) >= 0.10 * abs(pb)
c2a = all(n[s]["ret_pct"] > b[s]["ret_pct"] for s in ["B_cold", "C_continuous_from_Jan5", "D_seeded_slip15bps"])
wins = sum(1 for x, y in zip(n["E_jitter"], b["E_jitter"]) if x["ret_pct"] > y["ret_pct"])
c2b = wins >= 0.8 * len(n["E_jitter"])
c3 = n["A_seeded"]["sharpe"] > b["A_seeded"]["sharpe"] and n["A_seeded"]["alpha_pp"] > 0
out["criteria"] = {"1_primary_10pct": bool(c1), "improvement_pnl": round(pa - pb, 2),
                   "improvement_rel_pct": round((pa - pb) / abs(pb) * 100, 1) if pb else None,
                   "2a_B_C_D_all_better": bool(c2a), "2b_E_jitter_wins": f"{wins}/{len(n['E_jitter'])}",
                   "2b_pass": bool(c2b), "3_sharpe_and_alpha": bool(c3), "ALL_PASS": bool(c1 and c2a and c2b and c3)}
out["selected"] = SEL
json.dump(out, open(OUT, "w"), indent=1, default=float)
for s in ["A_seeded", "B_cold", "C_continuous_from_Jan5", "D_seeded_slip15bps"]:
    for k in CFG:
        x = out[k][s]
        print(f"{s:24s} {k}  ret {x['ret_pct']:+6.2f}%  pnl {x['pnl']:+8.2f}  spy {x['spy_pct']:+5.2f}  alpha {x['alpha_pp']:+6.2f}  sharpe {x['sharpe']:+5.2f}  dd {x['max_dd_pct']:+6.2f}  dep {x['avg_deploy_pct']:5.1f}  buys {x['buys']}  wr {x['win_rate']}")
for k in CFG:
    print("E_jitter", k, [x["ret_pct"] for x in out[k]["E_jitter"]])
print(json.dumps(out["criteria"], indent=1))

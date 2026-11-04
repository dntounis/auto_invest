"""POST-HOC sensitivity (not a selection step): every attempt-2 candidate on the test window."""
import json
from datetime import date
from multiprocessing import Pool
from sim import *
from attempt2 import CANDS
data = Data()
T0, T1 = date(2026, 9, 3), date(2026, 11, 3)
def one(c):
    n, cfg, k = c
    a = metrics(run(cfg, data, T0, T1, book=seed_book_2026_09_02()), data, T0, T1)
    b = metrics(run(cfg, data, T0, T1), data, T0, T1)
    return n, a, b
if __name__ == "__main__":
    with Pool(6) as p:
        res = p.map(one, CANDS)
    for n, a, b in res:
        print(f"{n:16s} A ret {a['ret_pct']:+6.2f} sh {a['sharpe']:+5.2f} dep {a['avg_deploy_pct']:5.1f} | B ret {b['ret_pct']:+6.2f}")
    json.dump([[n, a, b] for n, a, b in res], open("posthoc-attempt2.json", "w"), indent=1, default=float)

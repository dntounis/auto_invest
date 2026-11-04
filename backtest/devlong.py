"""Dev-window comparison (2026-01-05 -> 2026-09-02, cold start). Never touches the test window."""
import sys
from dataclasses import replace
from datetime import date
from sim import *
from variants import V
data = Data()
D0, D1 = date(2026, 1, 5), date(2026, 9, 2)
SUB = [("Jan-Mar", date(2026,1,5), date(2026,3,31)), ("Apr-May", date(2026,4,1), date(2026,5,29)), ("Jun-Sep", date(2026,6,1), D1)]
for k in (sys.argv[1:] or list(V)):
    r = run(V[k], data, D0, D1)
    m = metrics(r, data, D0, D1)
    subs = " ".join(f"{n} {metrics(r, data, a, b)['ret_pct']:+6.2f}" for n, a, b in SUB)
    print(f"{k:26s} ret {m['ret_pct']:+7.2f} spy {m['spy_pct']:+6.2f} a {m['alpha_pp']:+7.2f} dd {m['max_dd_pct']:+6.2f} sh {m['sharpe']:+5.2f} dep {m['avg_deploy_pct']:5.1f} buys {m['buys']:3d} wr {m['win_rate']} | {subs}", flush=True)

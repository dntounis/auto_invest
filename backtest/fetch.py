#!/usr/bin/env python3
"""Cache historical bars for the backtest universe via the read-only
`alpaca.sh bars-range` wrapper (never curls Alpaca directly).

  python3 backtest/fetch.py [--daily-start 2025-03-01] [--intraday-start 2026-05-15]
                            [--end 2026-11-04]
Writes backtest/data/{1Day,30Min}/SYM.json (gitignored).
"""
import argparse, json, os, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from universe import ALL  # noqa: E402


def fetch(sym, tf, start, end, force):
    out = os.path.join(HERE, "data", tf, f"{sym}.json")
    if os.path.exists(out) and not force:
        return sym, tf, "cached"
    for attempt in range(5):
        r = subprocess.run(["bash", os.path.join(ROOT, "scripts", "alpaca.sh"),
                            "bars-range", sym, tf, start, end],
                           capture_output=True, text=True)
        if r.returncode == 0:
            break
        time.sleep(2 ** attempt)  # 429 rate limit backoff
    if r.returncode != 0:
        return sym, tf, f"ERROR {r.stderr.strip()[:120]}"
    d = json.loads(r.stdout)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(d, f, separators=(",", ":"))
    return sym, tf, f"{len(d['bars'])} bars"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--daily-start", default="2025-03-01")
    p.add_argument("--intraday-start", default="2026-05-15")
    p.add_argument("--end", default="2026-11-03")
    p.add_argument("--force", action="store_true")
    p.add_argument("--daily-only", action="store_true")
    a = p.parse_args()
    jobs = [(s, "1Day", a.daily_start) for s in ALL]
    if not a.daily_only:
        jobs += [(s, "30Min", a.intraday_start) for s in ALL]
    bad = 0
    with ThreadPoolExecutor(max_workers=1) as ex:
        for sym, tf, msg in ex.map(lambda j: fetch(j[0], j[1], j[2], a.end, a.force), jobs):
            if msg.startswith("ERROR") or msg.startswith("0 "):
                bad += 1
                print(sym, tf, msg)
    print(f"done: {len(jobs)} series, {bad} problems")


if __name__ == "__main__":
    main()

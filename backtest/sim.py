#!/usr/bin/env python3
"""Deterministic replay of the auto_invest routine chain on historical bars.

Models the parts of the system that are rule-based, using the production
`scripts/sizing.py` functions for every sizing / ladder / decay / rscreen /
redeploy decision:

  pre-market   (T, data through T-1 close)  screen -> R:R-ranked ideas
  market-open  (T open)                     buy-side gate -> limit-ish fills
  intraday     (T, 30-min RTH bars)         live GTC trailing stops fire
  midday       (T 12:00 CT = 13:00 ET)      Rule 7 / 8 / 10 / 16 (Rule 15 aware)
  daily-summary(T close)                    Rule 13 stops for today's entries

What it cannot model: the LLM's catalyst judgement and Perplexity research.
The screen stands in for idea generation; that limitation applies equally to
every variant compared, so differences between variants are attributable to
the rule changes alone.
"""
import importlib.util, json, math, os, sys
from dataclasses import dataclass, field, replace
from datetime import date, datetime
from types import SimpleNamespace
from zoneinfo import ZoneInfo

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import universe as U  # noqa: E402

_spec = importlib.util.spec_from_file_location("sizing", os.path.join(ROOT, "scripts", "sizing.py"))
SZ = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(SZ)

ET = ZoneInfo("America/New_York")


# --------------------------------------------------------------------------- config
@dataclass(frozen=True)
class Config:
    name: str = "v3.4-baseline"
    # --- reward leg used for R:R --------------------------------------------
    # "hi200":  overhead to the 200-bar closing high (the convention the
    #           pre-market routine converged on and logs every session).
    # "drift":  momentum-consistent measured move (v3.5) — see reward().
    reward_mode: str = "hi200"
    core_stop: float = 0.10
    sat_stop: float = 0.12
    rr_floor: float = 2.0
    rr_floor_relaxed: float = 1.5
    max_ideas: int = 4
    # --- buy-side gate repairs (W22-W27 proposals) --------------------------
    core_floor_post_trade: bool = False     # (1b) floor on post-trade core MV
    core_floor_bootstrap: bool = False      # (1a) waive floor for first position
    sector_cap_first_exempt: bool = False   # (2)  first-position sector exemption
    core_trend_exempt: bool = False         # (3)  core: trend test replaces R:R
    decay_arbitration: bool = False         # (4)  no Rule 16 liquidation below floor
    # --- v3.5 additions -----------------------------------------------------
    rank_mode: str = "rr"                   # "rr" | "momentum"
    regime_filter: bool = False             # satellites only when SPY > 50-DMA
    decay_min_hold: int = 0                 # Rule 16 only after N sessions held
    arbitration_trail: float = 5.0          # proposal (4) downgrade; None = just hold
    quadrant_confirm: int = 1               # consecutive middays before quadrant exit
    ladder: str = "v3"                      # "v3" | "wide"
    rr_gate: bool = True                    # False: trend/RS screens are the gate
    min_score: float = None                 # rank score floor (non-rr modes)
    reentry_cooldown: int = 0               # sessions; no re-buy after a losing exit
    max_corr: float = None                  # skip idea if 60d corr with a holding > this
    max_new_per_day: int = None             # cap on buys per market-open run
    regime: str = None                      # None | "all50" | "all200": no new buys
                                            # of any tier while SPY < its 50/200-DMA
    rule16: bool = True
    quadrant: bool = True
    rule10: bool = True
    rule7: bool = True
    # --- modelling (not a rule): how the LLM reads "left the leading quadrant"
    quadrant_needs_dma: bool = False        # also require close < 50-DMA
    # --- constants from TRADING-STRATEGY.md ---------------------------------
    max_positions: int = 6
    max_week_trades: int = 5
    max_satellites: int = 3
    max_sat_per_sector: int = 2
    core_floor: float = 0.45
    sector_cap: float = 0.50
    ceiling: float = 0.85
    risk_pct: float = 0.02
    max_pos_pct: float = 0.16
    hard_stop: float = -0.07
    trail: float = 10.0
    slip: float = 0.0005
    min_adv: float = 100e6
    sector_kill_n: int = 2


# --------------------------------------------------------------------------- data
class Data:
    def __init__(self, syms=None, intraday_dir="30Min"):
        syms = syms or U.ALL
        self.syms = []
        self.d = {}      # sym -> dict(date->idx), arrays
        self.intra = {}  # sym -> {date: [(hhmm, o, h, l, c)]}
        for s in syms:
            p = os.path.join(HERE, "data", "1Day", f"{s}.json")
            if not os.path.exists(p):
                continue
            bars = json.load(open(p))["bars"]
            dates = [datetime.fromisoformat(b["t"].replace("Z", "+00:00")).astimezone(ET).date()
                     for b in bars]
            arr = {k: np.array([b[k] for b in bars], dtype=float) for k in "ohlcv"}
            arr["dates"] = dates
            arr["idx"] = {dt: i for i, dt in enumerate(dates)}
            self.d[s] = arr
            self.syms.append(s)
            ip = os.path.join(HERE, "data", intraday_dir, f"{s}.json")
            byday = {}
            if os.path.exists(ip):
                for b in json.load(open(ip))["bars"]:
                    t = datetime.fromisoformat(b["t"].replace("Z", "+00:00")).astimezone(ET)
                    hhmm = t.hour * 100 + t.minute
                    if 930 <= hhmm < 1600:
                        byday.setdefault(t.date(), []).append((hhmm, b["o"], b["h"], b["l"], b["c"]))
            self.intra[s] = byday
        self.days = self.d["SPY"]["dates"]

    def bar(self, s, dt):
        a = self.d[s]
        i = a["idx"].get(dt)
        if i is None:
            return None
        return {k: a[k][i] for k in "ohlcv"}

    def intraday(self, s, dt):
        b = self.intra.get(s, {}).get(dt)
        if b:
            return b
        db = self.bar(s, dt)  # fallback: synthesize O->L->H->C path from the daily bar
        if db is None:
            return []
        return [(930, db["o"], db["o"], db["l"], db["l"]), (1230, db["l"], db["h"], db["l"], db["h"]),
                (1530, db["h"], db["h"], db["c"], db["c"])]

    def midday_px(self, s, dt):
        bars = self.intraday(s, dt)
        pre = [b for b in bars if b[0] < 1300]
        return pre[-1][4] if pre else None


# --------------------------------------------------------------------------- features
def features(data, s, dt_prev):
    """Screen inputs computed strictly from closes through dt_prev (no look-ahead)."""
    a = data.d[s]
    i = a["idx"].get(dt_prev)
    if i is None or i < 210:
        return None
    c = a["c"][: i + 1]
    spy = data.d["SPY"]
    j = spy["idx"][dt_prev]
    sc = spy["c"][: j + 1]
    C = c[-1]
    f = dict(C=C, dma50=c[-50:].mean(), dma200=c[-200:].mean(),
             dma50_prior=c[-60:-10].mean(),
             ret10=C / c[-11] - 1, ret50=C / c[-51] - 1,
             spy10=sc[-1] / sc[-11] - 1, spy50=sc[-1] / sc[-51] - 1,
             hi200=c[-200:].max(),
             adv=(a["c"][i - 19:i + 1] * a["v"][i - 19:i + 1]).mean())
    f["rs10"] = (f["ret10"] - f["spy10"]) * 100
    f["rs50"] = (f["ret50"] - f["spy50"]) * 100
    # median of the name's own trailing 50-session returns over the last 150 windows
    w = c[-200:]
    r50 = w[50:] / w[:-50] - 1
    f["med50"] = float(np.median(r50[-150:]))
    # 63-session (one quarter) momentum, skipping the most recent 5 sessions
    f["mom63"] = c[-6] / c[-69] - 1
    f["rs63"] = (C / c[-64] - sc[-1] / sc[-64]) * 100
    f["rs126"] = (C / c[-127] - sc[-1] / sc[-127]) * 100
    daily = np.diff(np.log(c[-64:]))
    f["vol"] = float(daily.std() * math.sqrt(252))
    return f


_CORR = {}


def corr60(data, a, b, dt_prev):
    key = (min(a, b), max(a, b), dt_prev)
    if key not in _CORR:
        ra = np.diff(np.log(data.d[a]["c"][: data.d[a]["idx"][dt_prev] + 1][-61:]))
        rb = np.diff(np.log(data.d[b]["c"][: data.d[b]["idx"][dt_prev] + 1][-61:]))
        _CORR[key] = float(np.corrcoef(ra, rb)[0, 1])
    return _CORR[key]


def reward(cfg, f):
    if cfg.reward_mode == "hi200":
        return f["hi200"] / f["C"] - 1
    if cfg.reward_mode == "drift":
        # v3.5 measured-move target: the larger of (a) overhead to the 200-bar
        # high and (b) the name's own median 50-session drift *if positive*,
        # projected one holding period. A leader at a new high keeps a reward
        # leg equal to what it has actually been delivering, instead of 0.
        return max(f["hi200"] / f["C"] - 1, max(f["med50"], 0.0))
    raise ValueError(cfg.reward_mode)


WIDE_LADDERS = {  # v3.5 candidate: give trends room before tightening
    "etf":   [(7, 8, 0), (10, 6, 1), (15, 5, 1), (20, 4, 2)],
    "stock": [(10, 9, 0), (15, 7, 1), (25, 5, 1), (35, 4, 2)],
}


def ladder(cfg, a):
    if cfg.ladder == "none":
        return {"tier": a.tier, "target_trail_pct": None, "scaleouts_due": 0}
    if cfg.ladder == "v3":
        return SZ.cmd_ladder(a)
    saved = SZ.LADDERS
    try:
        SZ.LADDERS = WIDE_LADDERS
        return SZ.cmd_ladder(a)
    finally:
        SZ.LADDERS = saved


# --------------------------------------------------------------------------- state
@dataclass
class Pos:
    sym: str
    qty: int
    entry: float
    entry_date: date
    core: bool
    sector: str
    trail: float = None        # None until Rule 13 places the stop at close
    stop_hwm: float = None     # Alpaca trailing-stop high-water mark
    hwm: float = None          # position high since entry (ladder hwm_pct)
    scaleouts_done: int = 0
    decay_flag: int = 0
    quad_n: int = 0
    cost_basis: float = 0.0    # original cost (for win/loss accounting)
    realized: float = 0.0


class Book:
    def __init__(self, cash):
        self.cash = cash
        self.pos = {}
        self.trades = []       # closed/partial fills log
        self.buys = []
        self.week_trades = {}
        self.exits = []        # (date, sector, pnl) for the Rule 10 30-day window
        self.sym_exits = []    # (sym, date, pnl)
        self.dep_hist = []

    def mv(self, px):
        return sum(p.qty * px[p.sym] for p in self.pos.values())


# --------------------------------------------------------------------------- simulator
def trading_days_after(days, dt, n):
    i = days.index(dt) if not hasattr(days, "_di") else days._di[dt]
    return days[i + 1:i + 1 + n]


def run(cfg, data, start, end, cash=10000.0, book=None, log=False):
    days = [d for d in data.days if start <= d <= end]
    all_days = data.days
    DI = {d: i for i, d in enumerate(all_days)}
    macro = {date.fromisoformat(x) for x in U.MACRO_DATES}
    book = book or Book(cash)
    eq_curve = []
    events = []

    def sell(p, qty, px, dt, why):
        qty = min(qty, p.qty)
        fill = px * (1 - cfg.slip)
        book.cash += qty * fill
        pnl = qty * (fill - p.entry)
        p.realized += pnl
        p.qty -= qty
        events.append((dt, "SELL", p.sym, qty, round(fill, 2), why, round(pnl, 2)))
        if p.qty == 0:
            del book.pos[p.sym]
            book.exits.append((dt, p.sector, p.realized))
            book.sym_exits.append((p.sym, dt, p.realized))
            book.trades.append(dict(sym=p.sym, core=p.core, entry_date=p.entry_date, exit_date=dt,
                                    pnl=p.realized, cost=p.cost_basis, why=why))

    for dt in days:
        di = DI[dt]
        prev = all_days[di - 1]
        week = dt.isocalendar()[:2]
        streak = {}
        for xd, sec, pnl in book.exits:
            if sec != "Broad" and (dt - xd).days <= 30:
                streak[sec] = streak.get(sec, 0) + 1 if pnl < 0 else 0
        killed = {sec for sec, n in streak.items() if n >= cfg.sector_kill_n}

        # ---------------- pre-market: screen on T-1 data -----------------------
        equity_prev = book.cash + sum(p.qty * data.d[p.sym]["c"][data.d[p.sym]["idx"][prev]]
                                      for p in book.pos.values())
        lmv_prev = equity_prev - book.cash
        below = 0
        for dep in reversed(book.dep_hist):
            if dep < 75.0:
                below += 1
            else:
                break
        rd = SZ.cmd_redeploy(SimpleNamespace(equity=equity_prev, lmv=lmv_prev, sessions_below_band=below))
        armed = rd["triggered"]
        next2 = trading_days_after(all_days, dt, 2)
        macro_clear = not any(d in macro for d in next2)
        spyf = features(data, "SPY", prev)
        risk_on = spyf["C"] > spyf["dma50"]

        ideas = []
        for s in data.syms:
            if s in book.pos:
                continue
            f = features(data, s, prev)
            if f is None or data.bar(s, dt) is None:
                continue
            core = U.is_core(s)
            if not (f["C"] > f["dma50"] and f["C"] > f["dma200"]):
                continue  # Rule 11: trend-intact only
            if core and s in U.SECTOR_ETF and f["rs50"] <= 0:
                continue  # sector fund must be in leading momentum
            if not core:
                if f["adv"] < cfg.min_adv or not macro_clear:
                    continue
                if cfg.regime_filter and not risk_on:
                    continue
                rs = SZ.cmd_rscreen(SimpleNamespace(rs10=f["rs10"], rs50=f["rs50"], close=f["C"],
                                                    dma50=f["dma50"], dma50_prior=f["dma50_prior"]))
                if not rs["pass"]:
                    continue
            stop = cfg.core_stop if core else cfg.sat_stop
            rr = reward(cfg, f) / stop
            if not cfg.rr_gate:
                pass
            elif core:
                floor = cfg.rr_floor_relaxed if armed else cfg.rr_floor
                trend_ok = cfg.core_trend_exempt and f["rs50"] > 0 and f["rs10"] > 0
                if rr < floor and not trend_ok:
                    continue
            else:
                if rr < cfg.rr_floor:
                    continue
            if cfg.rank_mode == "rr":
                score = rr
            elif cfg.rank_mode == "momentum":
                score = f["mom63"] / max(f["vol"], 0.05)
            elif cfg.rank_mode == "dualrs":
                score = (f["rs63"] + f["rs126"]) / 2
            else:
                raise ValueError(cfg.rank_mode)
            if cfg.min_score is not None and cfg.rank_mode != "rr" and score < cfg.min_score:
                continue
            if cfg.reentry_cooldown and any(x[0] == s and x[2] < 0 and
                                            0 <= DI[dt] - DI[x[1]] <= cfg.reentry_cooldown
                                            for x in book.sym_exits):
                continue
            ideas.append(dict(sym=s, core=core, sector=U.sector_of(s), stop=stop, rr=rr,
                              score=score, relaxed=cfg.rr_gate and core and armed and rr < cfg.rr_floor))
        if cfg.regime == "all50" and not risk_on:
            ideas = []
        if cfg.regime == "all200" and not spyf["C"] > spyf["dma200"]:
            ideas = []
        ideas.sort(key=lambda x: (-x["score"], x["sym"]))
        ideas = ideas[: cfg.max_ideas]

        # ---------------- market-open: gate + size + fill at the open ---------
        opx = {s: data.bar(s, dt)["o"] for s in set([p for p in book.pos] + [x["sym"] for x in ideas])}
        equity = book.cash + sum(p.qty * opx[p.sym] for p in book.pos.values())
        restore_left = rd["restore_dollars"] if armed else 0.0
        bought_today = 0
        for idea in ideas:
            if cfg.max_new_per_day is not None and bought_today >= cfg.max_new_per_day:
                break
            s = idea["sym"]
            lmv = sum(p.qty * opx[p.sym] for p in book.pos.values())
            core_mv = sum(p.qty * opx[p.sym] for p in book.pos.values() if p.core)
            sat_n = sum(1 for p in book.pos.values() if not p.core)
            if len(book.pos) + 1 > cfg.max_positions:
                break
            if book.week_trades.get(week, 0) + 1 > cfg.max_week_trades:
                break
            if cfg.rule10 and idea["sector"] in killed:
                continue  # Rule 10: sector exited after 2 failed trades
            headroom = cfg.ceiling * equity - lmv
            if idea["relaxed"]:
                headroom = min(headroom, restore_left)
            price = opx[s] * (1 + cfg.slip)
            sz = SZ.cmd_size(SimpleNamespace(equity=equity, price=price, stop_frac=idea["stop"],
                                             risk_pct=cfg.risk_pct, max_pos_pct=cfg.max_pos_pct,
                                             min_pos_pct=0.05, headroom=max(headroom, 0.0)))
            if sz["shares"] == 0:
                continue
            cost = sz["shares"] * price
            if cost > book.cash:
                continue
            first = len(book.pos) == 0
            if cfg.max_corr is not None and book.pos:
                if max(corr60(data, s, q, prev) for q in book.pos) > cfg.max_corr:
                    continue
            if not idea["core"]:
                if sat_n + 1 > cfg.max_satellites:
                    continue
                if sum(1 for p in book.pos.values() if not p.core and p.sector == idea["sector"]) + 1 > cfg.max_sat_per_sector:
                    continue
                base_core = core_mv
                floor_ok = base_core / (lmv + cost) >= cfg.core_floor
                if not floor_ok and cfg.core_floor_bootstrap and first:
                    floor_ok = True
                if not floor_ok:
                    continue
            if idea["sector"] != "Broad":
                sec_mv = sum(p.qty * opx[p.sym] for p in book.pos.values() if p.sector == idea["sector"])
                share = (sec_mv + cost) / (lmv + cost)
                ok = share <= cfg.sector_cap
                if not ok and cfg.sector_cap_first_exempt and first and idea["core"]:
                    ok = True
                if not ok:
                    continue
            book.cash -= cost
            book.pos[s] = Pos(sym=s, qty=sz["shares"], entry=price, entry_date=dt, core=idea["core"],
                              sector=idea["sector"], hwm=price, cost_basis=cost)
            book.week_trades[week] = book.week_trades.get(week, 0) + 1
            if idea["relaxed"]:
                restore_left -= cost
            events.append((dt, "BUY", s, sz["shares"], round(price, 2), f"rr={idea['rr']:.2f}", 0))
            book.buys.append((dt, s))
            bought_today += 1

        # ---------------- intraday: GTC trailing stops + midday ---------------
        def run_stops(p, bars):
            for hhmm, o, h, l, c in bars:
                if p.sym not in book.pos or p.trail is None:
                    return
                stop = p.stop_hwm * (1 - p.trail / 100)
                if l <= stop:
                    sell(p, p.qty, min(o, stop) / (1 - cfg.slip), dt, f"trail{p.trail:g}")
                    return
                p.stop_hwm = max(p.stop_hwm, h)

        for p in list(book.pos.values()):
            run_stops(p, [b for b in data.intraday(p.sym, dt) if b[0] < 1300])

        # midday — Rule 15: only positions opened before today
        mpx = {}
        for p in list(book.pos.values()):
            mpx[p.sym] = data.midday_px(p.sym, dt) or data.bar(p.sym, dt)["c"]
        spy_mid = data.midday_px("SPY", dt) or data.bar("SPY", dt)["c"]
        spyc = data.d["SPY"]["c"]
        spy_i = data.d["SPY"]["idx"][dt]
        spy10 = (spy_mid / spyc[spy_i - 10] - 1) * 100
        for p in list(book.pos.values()):
            if p.entry_date == dt:
                continue
            px = mpx[p.sym]
            un = px / p.entry - 1
            if cfg.rule7 and un <= cfg.hard_stop:
                sell(p, p.qty, px, dt, "rule7")
                continue
            if cfg.rule10 and p.sector in killed:
                sell(p, p.qty, px, dt, "rule10")
                continue
            # Rule 16 decay
            a = data.d[p.sym]
            ii = a["idx"][dt]
            pos10 = (px / a["c"][ii - 10] - 1) * 100
            dec = SZ.cmd_decay(SimpleNamespace(unrealized_pct=un * 100, pos_ret_10d=pos10, spy_ret_10d=spy10,
                                               prior_flag=p.decay_flag, meltup_floor=-2.0, meltup_benchmark=3.0))
            held = DI[dt] - DI.get(p.entry_date, DI[dt])
            if held < cfg.decay_min_hold:
                dec = {"flag": 0, "rotate": 0}
            p.decay_flag = dec["flag"]
            quad_exit = False
            if p.core and p.sym in U.SECTOR_ETF:
                f = features(data, p.sym, prev)
                quad_exit = f is not None and f["rs50"] < 0 and f["rs10"] < 0
                if quad_exit and cfg.quadrant_needs_dma:
                    quad_exit = f["C"] < f["dma50"]
                p.quad_n = p.quad_n + 1 if quad_exit else 0
                quad_exit = p.quad_n >= cfg.quadrant_confirm
            if not cfg.rule16:
                dec = dict(dec, rotate=0)
            if not cfg.quadrant:
                quad_exit = False
            if dec["rotate"] or quad_exit:
                if cfg.decay_arbitration and not quad_exit:
                    lmv_after = sum(q.qty * mpx[q.sym] for q in book.pos.values()) - p.qty * px
                    eq_now = book.cash + lmv_after + p.qty * px
                    if lmv_after / eq_now < 0.75:
                        # downgrade the rotation to a trail-tighten (proposal 4)
                        at = cfg.arbitration_trail
                        if at is not None and p.trail is not None and p.trail > at:
                            p.trail, p.stop_hwm = at, px
                        continue
                sell(p, p.qty, px, dt, "rule16" if not quad_exit else "quadrant")
                continue
            # Rule 8 ladder
            p.hwm = max(p.hwm, px)
            lad = ladder(cfg, SimpleNamespace(tier="etf" if p.core else "stock", unrealized_pct=un * 100,
                                                hwm_pct=(p.hwm / p.entry - 1) * 100))
            so = SZ.cmd_scaleout(SimpleNamespace(cur_qty=p.qty, scaleouts_due=lad["scaleouts_due"],
                                                 scaleouts_done=p.scaleouts_done))
            if so["sell_qty"] > 0:
                sell(p, so["sell_qty"], px, dt, "rule8-scaleout")
                p.scaleouts_done += 1
            tt = lad["target_trail_pct"]
            if p.sym in book.pos and tt is not None and p.trail is not None and tt < p.trail:
                p.trail, p.stop_hwm = float(tt), px  # replace-stop: new order tracks from now

        for p in list(book.pos.values()):
            run_stops(p, [b for b in data.intraday(p.sym, dt) if b[0] >= 1300])

        # ---------------- daily-summary: Rule 13 stops at close + EOD mark -----
        cpx = {}
        for p in book.pos.values():
            cpx[p.sym] = data.bar(p.sym, dt)["c"]
            p.hwm = max(p.hwm, data.bar(p.sym, dt)["h"])
            if p.trail is None:
                p.trail, p.stop_hwm = cfg.trail, cpx[p.sym]
        lmv = sum(p.qty * cpx[p.sym] for p in book.pos.values())
        eq = book.cash + lmv
        dep = lmv / eq * 100
        book.dep_hist.append(dep)
        eq_curve.append((dt, eq, dep, len(book.pos)))
    return dict(curve=eq_curve, events=events, book=book)


# --------------------------------------------------------------------------- metrics
def metrics(res, data, start, end):
    curve = [c for c in res["curve"] if start <= c[0] <= end]
    if not curve:
        return {}
    days = data.days
    d0 = days[days.index(curve[0][0]) - 1]
    # starting equity = equity at the close before the window
    pre = [c for c in res["curve"] if c[0] == d0]
    e0 = pre[0][1] if pre else 10000.0
    eq = np.array([e0] + [c[1] for c in curve])
    spy = np.array([data.d["SPY"]["c"][data.d["SPY"]["idx"][d0]]] +
                   [data.d["SPY"]["c"][data.d["SPY"]["idx"][c[0]]] for c in curve])
    r = np.diff(eq) / eq[:-1]
    sr = np.diff(spy) / spy[:-1]
    tot = eq[-1] / eq[0] - 1
    spy_tot = spy[-1] / spy[0] - 1
    dd = (eq / np.maximum.accumulate(eq) - 1).min()
    sharpe = r.mean() / r.std() * math.sqrt(252) if r.std() > 0 else 0.0
    ex = r - sr
    ir = ex.mean() / ex.std() * math.sqrt(252) if ex.std() > 0 else 0.0
    trades = [t for t in res["book"].trades if start <= t["exit_date"] <= end]
    wins = sum(1 for t in trades if t["pnl"] > 0)
    buys = [b for b in res["book"].buys if start <= b[0] <= end]
    return dict(start=str(curve[0][0]), end=str(curve[-1][0]), sessions=len(curve),
                ret_pct=round(tot * 100, 3), spy_pct=round(spy_tot * 100, 3),
                alpha_pp=round((tot - spy_tot) * 100, 3), pnl=round(eq[-1] - eq[0], 2),
                max_dd_pct=round(dd * 100, 3), sharpe=round(sharpe, 2), info_ratio=round(ir, 2),
                avg_deploy_pct=round(float(np.mean([c[2] for c in curve])), 1),
                buys=len(buys), closed=len(trades),
                win_rate=round(wins / len(trades), 2) if trades else None)


BASELINE = Config()


def seed_book_2026_09_02():
    """The real book at the 2026-09-02 close (TRADE-LOG `## Sep 02 — EOD Snapshot`)."""
    b = Book(2910.91)
    rows = [  # sym, qty, entry, entry_date, core, sector, trail, stop_hwm, hwm, scaleouts_done
        ("XLB", 27, 50.08, date(2026, 5, 18), True, "Materials", 4.1, 53.80, 53.80, 1),
        ("XLV", 11, 169.7473, date(2026, 8, 20), True, "Health Care", 10.0, 175.82, 176.025, 0),
        ("XLE", 25, 64.79, date(2026, 9, 2), True, "Energy", 10.0, 65.10, 65.10, 0),
        ("GILD", 11, 144.3136, date(2026, 8, 21), False, "Health Care", 10.0, 152.54, 152.54, 0),
        ("MPC", 2, 377.96, date(2026, 9, 1), False, "Energy", 10.0, 391.98, 391.98, 0),
    ]
    for sym, q, e, ed, core, sec, tr, sh, hw, so in rows:
        b.pos[sym] = Pos(sym=sym, qty=q, entry=e, entry_date=ed, core=core, sector=sec, trail=tr,
                         stop_hwm=sh, hwm=hw, scaleouts_done=so, cost_basis=q * e)
    b.week_trades[(2026, 36)] = 2
    # Rule 10 30-day window exits (midday 2026-09-03 log)
    b.exits = [(date(2026, 8, 7), "Health Care", -4.55), (date(2026, 8, 7), "Financials", -6.00),
               (date(2026, 8, 19), "Industrials", -6.12), (date(2026, 8, 20), "Industrials", -22.35),
               (date(2026, 8, 31), "Real Estate", -41.40),
               (date(2026, 9, 1), "Information Technology", -9.12)]
    # METRICS.jsonl deployment history (Rule 5 below-band counter)
    b.dep_hist = [84.38, 64.8, 64.79, 70.21, 70.23, 84.59, 84.59, 84.54, 84.47, 66.91, 59.29,
                  75.02, 75.07, 75.12, 68.3, 68.17, 80.78, 61.18, 55.75, 71.73]
    return b

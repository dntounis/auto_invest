"""Fixed, ex-ante backtest universe (v3.5).

Chosen by *category*, not by performance: every SPDR sector fund, the common
broad/factor funds the pre-market screen pulls, the industry funds it has named
in RESEARCH-LOG, and ~75 liquid large caps spread across all eleven GICS
sectors. No name was added or removed after looking at backtest results.
"""

# Multi-sector funds: exempt from the single-sector concentration cap on
# look-through (largest GICS weight in each < 50%).
BROAD = ["SPY", "QQQ", "IWM", "DIA", "MDY", "IJR", "RSP", "VTV", "VUG", "MTUM",
         "SPMO", "QUAL", "USMV", "SCHD", "IWD", "IWF", "VB", "VO"]

# Sector / industry funds -> GICS sector.
SECTOR_ETF = {
    "XLB": "Materials", "XLC": "Communication Services", "XLE": "Energy",
    "XLF": "Financials", "XLI": "Industrials", "XLK": "Information Technology",
    "XLP": "Consumer Staples", "XLRE": "Real Estate", "XLU": "Utilities",
    "XLV": "Health Care", "XLY": "Consumer Discretionary",
    "SOXX": "Information Technology", "SMH": "Information Technology",
    "IGV": "Information Technology", "IHI": "Health Care", "XBI": "Health Care",
    "IBB": "Health Care", "ITA": "Industrials", "IYT": "Industrials",
    "KBE": "Financials", "KRE": "Financials", "XOP": "Energy", "IEO": "Energy",
    "XHB": "Consumer Discretionary", "ITB": "Consumer Discretionary",
    "XRT": "Consumer Discretionary", "XME": "Materials", "GDX": "Materials",
}

STOCKS = {
    "Information Technology": ["AAPL", "MSFT", "NVDA", "AVGO", "AMD", "ORCL", "CRM",
                               "ADBE", "QCOM", "MU", "AMAT", "PLTR", "ANET", "KLAC"],
    "Communication Services": ["GOOGL", "META", "NFLX", "TMUS", "DIS"],
    "Consumer Discretionary": ["AMZN", "TSLA", "HD", "MCD", "NKE", "BKNG", "TJX"],
    "Consumer Staples": ["WMT", "COST", "PG", "KO", "PEP"],
    "Health Care": ["LLY", "UNH", "JNJ", "ABBV", "MRK", "TMO", "ISRG", "GILD",
                    "AMGN", "HCA", "VRTX"],
    "Financials": ["JPM", "BAC", "GS", "MS", "V", "MA", "SCHW", "AXP"],
    "Industrials": ["GE", "CAT", "RTX", "HON", "UBER", "DE", "ETN", "LMT"],
    "Energy": ["XOM", "CVX", "COP", "SLB", "EOG", "MPC", "PSX"],
    "Materials": ["LIN", "FCX", "NEM", "SHW"],
    "Utilities": ["NEE", "SO", "DUK", "CEG", "VST"],
    "Real Estate": ["PLD", "AMT", "EQIX"],
}

STOCK_SECTOR = {s: sec for sec, names in STOCKS.items() for s in names}
ETFS = BROAD + list(SECTOR_ETF)
ALL = ETFS + list(STOCK_SECTOR)


def sector_of(sym):
    if sym in BROAD:
        return "Broad"
    return SECTOR_ETF.get(sym) or STOCK_SECTOR[sym]


def is_core(sym):
    return sym in BROAD or sym in SECTOR_ETF


# Tier-1 macro binaries (NFP, CPI, PPI, Core PCE, FOMC decision, FOMC minutes),
# transcribed from the dates the pre-market routine itself recorded in
# memory/RESEARCH-LOG.md (most-cited date per release).
MACRO_DATES = [
    "2026-06-05", "2026-06-10", "2026-06-11", "2026-06-17", "2026-06-25",
    "2026-07-02", "2026-07-08", "2026-07-14", "2026-07-15", "2026-07-29", "2026-07-30",
    "2026-08-07", "2026-08-12", "2026-08-13", "2026-08-19", "2026-08-26",
    "2026-09-04", "2026-09-10", "2026-09-11", "2026-09-16", "2026-09-30",
    "2026-10-02", "2026-10-07", "2026-10-14", "2026-10-15", "2026-10-28", "2026-10-29",
    "2026-11-06", "2026-11-10", "2026-11-13", "2026-11-18",
]


# Pre-2026 history (long dev window, v3.5 attempt 2): approximate Tier-1 calendar.
# FOMC decisions are the published dates; NFP = first Friday; CPI ~ second
# Wednesday; Core PCE ~ last Friday. Applied identically to every variant.
_FOMC = """2021-11-03 2021-12-15 2022-01-26 2022-03-16 2022-05-04 2022-06-15 2022-07-27 2022-09-21
2022-11-02 2022-12-14 2023-02-01 2023-03-22 2023-05-03 2023-06-14 2023-07-26 2023-09-20 2023-11-01
2023-12-13 2024-01-31 2024-03-20 2024-05-01 2024-06-12 2024-07-31 2024-09-18 2024-11-07 2024-12-18
2025-01-29 2025-03-19 2025-05-07 2025-06-18 2025-07-30 2025-09-17 2025-10-29 2025-12-10""".split()


def _approx_calendar():
    import calendar
    out = list(_FOMC)
    for y in range(2021, 2026):
        for m in range(1, 13):
            cal = calendar.Calendar()
            days = [d for d in cal.itermonthdates(y, m) if d.month == m]
            fridays = [d for d in days if d.weekday() == 4]
            weds = [d for d in days if d.weekday() == 2]
            out += [fridays[0].isoformat(), weds[1].isoformat(), fridays[-1].isoformat()]
    return out


MACRO_DATES = sorted(set(MACRO_DATES + _approx_calendar()))

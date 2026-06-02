# auto_invest v3 — Core-Satellite Momentum Design

**Status:** DRAFT 2026-06-02 from brainstorming dialogue. Awaiting user spec review → writing-plans.

**Author:** Claude (drafted 2026-06-02 after a 3-week v2 performance review).

**Predecessor:** `docs/superpowers/specs/2026-05-04-auto-invest-v2-design.md` (v2 execution layer). v3 keeps the v2 execution/visa machinery and changes the *strategy* it executes.

**Critical user constraint (unchanged):** International student visa. PDT designation (4+ day trades in 5 rolling business days) creates visa risk. v3 avoids day trades by construction exactly as v2 does — every sell (including new partial/scale-out/rotation sells) acts only on positions opened ≥1 trading day earlier, gated by `daytrade_count` pre-flight. Rules 13/14/15 carry over verbatim.

---

## 1. Why v3 — the v2 performance problem

After ~3 weeks of v2 paper trading (state 2026-06-02):

- Equity **$10,003.84 — +0.04% from the $10K start.** A +0.55% Week-1 gain round-tripped back to flat.
- 4 positions, **all broad sector ETFs**: XLB +1.82%, XLE −0.16%, XLI −1.97%, XLP +0.42%. ~78% deployed.

Root causes, priority-ordered:

1. **Universe is broad sector ETFs only.** XLB/XLE/XLI/XLP move ~1:1 with the market and each other. Four of them ≈ a defensively-tilted S&P 500 — almost no *dispersion* to harvest, so beating SPX is structurally impossible.
2. **No profit capture — winners round-trip.** XLE hit +3.7% (May 15) and is now −0.16%. Only exits are a 10% trail + tighten-triggers at +15%/+20% that low-vol ETFs never reach.
3. **Defensive tilt in a rising tape** (XLP/XLU lagged record-high SPX).
4. **Slow then static** — 3-trade/week cap → weeks to deploy, then the book sits; XLI bled −2% for 3 weeks, never rotated.

**v3 success looks like:** an ETF core + single-stock satellites book that runs ≥2 weeks autonomously, captures partial gains on winners (no full round-trips), rotates out of dead-money laggards within ~1 week, keeps `daytrade_count` at 0, and is graded on **alpha vs SPX** with core/satellite attribution.

---

## 2. Confirmed decisions (brainstorming 2026-06-02)

| # | Decision | Choice |
|---|----------|--------|
| A | Universe | **Add single stocks** alongside ETFs |
| B | Profit capture | **Both** scale-out + tighter trail |
| C | Scope | **Formal v3 spec** (this doc is the v3 trigger) |
| D | Structure | **ETF core + single-stock satellites** |
| E | Cadence | **Raise weekly cap 3 → 5 new trades** |
| F | Stock sizing | **Risk-parity**, ~2% equity at risk per stop-out |

Carried-over locked items from v2: paper only, no options, ≤$10K, `TRADING_ENABLED=true`, `TRADING-STRATEGY.md` write-eligible only by `weekly-review`, all hard rules enforce server-side, visa-aware Rules 13/14/15.

---

## 3. Strategy design

### 3.1 Portfolio structure — core + satellites
- **ETF core: ≥45% of *deployed* equity, 2–3 sector ETFs** from the existing leading-quadrant rotation read. Market-tracking ballast; dampens single-name blowups.
- **Single-stock satellites: ≤3 names**, the remainder of deployed equity. The alpha sleeve.
- Total positions cap **unchanged at 5–6** (e.g. 3 ETF + 3 stock, 2 ETF + 3 stock).
- **Diversification guards:** max **2 satellite names per GICS sector**; ETF core may never fall below 45% of deployed (market-open refuses a satellite buy that would breach the floor).

### 3.2 Risk-parity sizing (replaces flat 20% sizing)
- Risk budget per position = **2% of equity** (~$200 on $10K).
- `shares = floor( risk_budget / (stop_distance_frac × entry_price) )`, where `stop_distance_frac` is the position's initial stop width (ETF 0.10; stock per-idea, typically 0.12–0.15 from the research entry).
- **Rule 3 (≤20% equity per position) remains the hard ceiling**; risk-parity sits beneath it and clamps down. Position floor: skip if computed cost < 5% of equity (avoid dust).
- Worked examples on $10K:
  - ETF, 10% stop: $200 / 0.10 = $2,000 exposure = 20% (clamped at cap). Matches v2.
  - Stock, 13% stop, $150 px: $200 / (0.13×150) ≈ 10 sh → $1,500 = 15%.
  - Stock, 20% stop: $200 / 0.20 = $1,000 = 10% (volatile name auto-shrinks).

### 3.3 Profit ladder — scale-out + tighter trail (both)
Replaces the v2 +15%/+20% ladder. All actions are sells on ≥T+1 positions → Rule 14 pre-flight + Rule 15 same-day skip apply. ETFs bank sooner (lower vol); stocks given more room.

**ETF core ladder:**
| Unrealized | Action |
|-----------|--------|
| +4% | tighten trail 10% → 7% |
| +7% | **scale out 1/3**, tighten trail → 5% |
| +10% | tighten trail → 4% |
| +15% | **scale out 1/3 of remainder**, tighten trail → 3% (Rule 9 floor) |

**Single-stock satellite ladder:**
| Unrealized | Action |
|-----------|--------|
| +6% | tighten trail to 7% |
| +10% | **scale out 1/3**, tighten trail → 6% |
| +15% | tighten trail → 4% |
| +25% | **scale out 1/3 of remainder**, tighten trail → 3% (Rule 9 floor) |

Partial sells use the existing `order` endpoint (sell qty). Trail tightening uses `replace-stop`. Never move a stop down or inside 3% of price (Rule 9).

### 3.4 Faster rotation / cut laggards
- **Rule 4 raised: max 5 new trades/week** (was 3). Swing entries, not day trades — `daytrade_count` unaffected.
- **New momentum-decay rotation exit (midday).** A held position is flagged for T+1 rotation if, on **2 consecutive midday checks**, BOTH hold:
  1. unrealized P&L < 0 (below entry), AND
  2. **relative strength vs SPX is negative over the trailing 10 sessions** (position 10-session return < SPY 10-session return).
  - ETFs additionally rotate if the sector exits the leading momentum quadrant.
  - Visa-aware: never acts on a same-day position (Rule 15); aborts if `daytrade_count ≥ 2` (Rule 14). Directly fixes the "XLI dead-money for 3 weeks" failure.

### 3.5 Single-stock selection engine (pre-market)
Extend research to screen single names, ranked by R:R alongside ETF ideas, each tagged `core` or `satellite`:
- **Momentum:** price > 50-DMA and > 200-DMA; positive relative strength vs SPX (10- and 50-session).
- **Catalyst:** earnings beat/guidance raise, analyst upgrade, or sector tailwind — documented per the Buy-Side Gate.
- **Liquidity filter:** minimum average daily volume + tight quoted spread. Doubles as the **stale-quote fix** — only trade names that actually quote at the open.
- Each satellite idea carries its own stop width (drives risk-parity sizing) and an R:R ≥ 2:1.

### 3.6 Stale-quote fallback (folds in v3-backlog)
market-open STEP 5a: if `ap=0` but `bid` exists and the implied spread vs prior close is within `MAX_ENTRY_SLIPPAGE_PCT`, either (a) defer to a single 9:00 CT retry, or (b) place a limit at `prior_close × (1 + MAX_ENTRY_SLIPPAGE_PCT)` with day TIF. The liquidity filter (3.5) reduces how often this fires. (Implementation picks one path; default (b).)

### 3.7 Benchmark-relative grading (weekly-review)
Add to the grade card: **alpha vs SPX** for the week and **core-vs-satellite attribution** (P&L contribution of each sleeve) so we can judge whether satellites earn their incremental risk. If the satellite sleeve underperforms the ETF core on a risk-adjusted basis for 3+ weeks, weekly-review *proposes* (never auto-applies) shrinking the satellite allocation.

### 3.8 Visa-aware rules — unchanged
Rules 13/14/15 apply identically to single stocks and to every new sell type (partial, scale-out, rotation). Every sell is on a position opened ≥1 trading day earlier → zero day trades by construction; `daytrade_count` pre-flight still aborts at ≥2.

---

## 4. Component changes

| Component | Change |
|-----------|--------|
| `memory/TRADING-STRATEGY.md` | Rewrite to v3: core-satellite structure, risk-parity sizing, ETF/stock profit ladders, Rule 4 → 5/week, momentum-decay exit (new rule), single-stock entry checklist, diversification guards. Version markers `(v3)`. |
| `scripts/alpaca.sh` | Add read-only `bars SYM [timeframe] [limit]` (Alpaca `/stocks/{sym}/bars`) for DMA/RS; optional `scale-out SYM QTY` convenience (partial sell via `order`, kill-switch gated). |
| `routines/pre-market.md` | Single-stock screen (momentum + catalyst + liquidity + RS-vs-SPX); RESEARCH-LOG idea schema gains `tier: core|satellite` and per-idea stop width. |
| `routines/market-open.md` | Risk-parity sizing calc; core/satellite allocation + sector-diversification gates; raised weekly cap (5); stale-quote fallback (STEP 5a). |
| `routines/midday.md` | New ETF/stock profit ladders (scale-out + tighter trail); momentum-decay rotation exit (Rule 14/15 gated). |
| `routines/daily-summary.md` | Place stops at risk-parity distances for new positions (Rule 13 timing unchanged). |
| `routines/weekly-review.md` | Alpha-vs-SPX + core/satellite attribution; satellite-underperformance proposal logic. |
| `memory/MEMORY.md` + memory files | Mark v3 active; archive v2 spec pointer. |
| `docs/superpowers/specs/v3-backlog.md` | Mark stale-quote item promoted into this spec. |

---

## 5. Risks & mitigations

- **Single-name blowup** → risk-parity caps dollar risk at ~2%/position; ETF core ≥45% floor; ≤2 satellites/sector.
- **Over-trading from raised cap** → cap is 5, not unlimited; Buy-Side Gate + R:R ≥2:1 still bind; patience rule (12) retained.
- **Scale-out creating an accidental day trade** → impossible: Rule 15 skips same-day; Rule 14 pre-flight aborts at DTC ≥2.
- **Whipsaw on volatile stocks** → wider per-idea stops + risk-parity sizing absorb noise; momentum-decay exit needs 2 consecutive confirmations, not 1.
- **Bars/RS data unavailable** → `bars` is read-only; on failure, satellite screen degrades to catalyst+liquidity only and flags it in RESEARCH-LOG.

---

## 6. Open items resolved in this spec
- ETF vs stock ladder split → §3.3 (concrete tables).
- Momentum-decay metric → §3.4 (P&L<0 AND 10-session RS<SPX, 2 consecutive checks).
- Core floor / max satellites → §3.1 (≥45% of deployed; ≤3 satellites).
- Single-stock sleeve cap → governed by the core floor + Rule 3 per-position cap (no separate sleeve cap needed).

---

## 7. Next step
On user spec approval → invoke writing-plans to produce the dated implementation plan in `docs/superpowers/plans/2026-06-02-auto-invest-v3.md`, then implement §4 component changes.

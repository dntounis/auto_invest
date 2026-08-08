# Live Smoke Test — one-off manual runbook (v3.4)

**Status:** manual, local, one-off. This is deliberately **not** a cron routine
and deliberately **not** something you paste into the cloud Routines UI. The
cloud routines stay pointed at the paper account for the entire paper trial;
this procedure runs from your own shell, once, against the live $200 account,
and then you tear it down.

## 1. Why this exists, and what it does not do

The owner has set aside **$200** for the live account. At that size the
strategy itself cannot run: risk-parity sizing clips a full-risk position to
16% of equity by default (`--max-pos-pct 0.16`), which on $200 is **$32**, and
the cheapest instrument in the traded universe (the sector SPDRs) trades
around **$45** — above the clip before a single share is even considered.
`sizing.py size` returns `floor_skip` for every candidate in the universe.
Verified directly, using the exact invocation `market-open` makes (equity,
price, stop-frac, everything else defaulted) and a real recent close for XLRE,
the cheapest ETF actually held this phase ($44.79 on 2026-08-06):

```
$ python3 scripts/sizing.py size --equity 200 --price 44.79 --stop-frac 0.10
{"shares": 0, "cost": 0.0, "pct_equity": 0.0, "clamped": "floor_skip"}
```

Zero shares, `floor_skip`. This is not a bug to work around — it is the
correct output of the same deterministic sizer the strategy relies on for
safety, and it means **the $200 account cannot be used to run the strategy at
all**, at any position the buy-side gate would otherwise pass. Do not lower
`--max-pos-pct` or otherwise coax a real clip out of `sizing.py` to make this
account "work" — that would be sizing a real position for a reason the
strategy itself never generated.

**What this account is for instead:** validating the *plumbing* — that live
credentials authenticate, that a live order actually reaches the live broker,
fills, and can be protected and closed cleanly. **What it is not for:**
producing any evidence about the strategy. That evidence keeps coming
exclusively from the $10,000 paper account, for as long as the paper trial
runs. A single $45 one-share trade on $200 of capital has no statistical
content about whether core-satellite momentum works; it only tells you
whether the order path works.

## 2. The five things paper has never proven

Fifteen weeks of paper trading have exercised the strategy logic thoroughly,
but paper is a simulated broker: it never validates real authentication, a
real `daytrade_count` from a real account, or a real broker's acceptance of a
real GTC order. These five checks are the entire point of this runbook — do
them in order, and do not skip any of them even if earlier ones look obviously
fine.

**(a) Live credentials authenticate.**
```
bash scripts/alpaca.sh account
```
Expected: a JSON account object with `"status": "ACTIVE"`. Anything else
(auth error, non-2xx, missing `status`) is a hard stop — fix credentials
before proceeding.

**(b) `dtc` returns `source=api` with a real integer.**
```
bash scripts/alpaca.sh dtc
```
Expected: `{"daytrade_count": <int>, "source": "api"}`. This is the first
genuine exercise of Rule 14's *primary* path (`source=api`) in 15 weeks — the
paper endpoint has omitted the `daytrade_count` field every single time,
forcing the local-derivation fallback (`source=local`/`unavailable`) on every
prior session. If this still returns `source=unavailable` or `source=error` on
a live account, that is itself a finding worth recording, not just a retry.

**(c) A limit BUY of one share of a sub-$32 liquid ETF fills.**
Pick a liquid ETF priced under $32 so the single-share cost fits inside what
$200 can plausibly absorb alongside the eventual GTC stop and fees headroom
(the sector SPDRs run ~$45+, so this will not be one of them — use a
lower-priced, liquid single-digit-to-$20s ETF instead, checked live via
`bash scripts/alpaca.sh quote <SYM>` immediately before placing the order).
```
bash scripts/alpaca.sh quote <SYM>
bash scripts/alpaca.sh order '{"symbol":"<SYM>","qty":"1","side":"buy","type":"limit","limit_price":"<PRICE>","time_in_force":"day"}'
bash scripts/alpaca.sh orders all
bash scripts/alpaca.sh positions
```
Expected: the order reaches `filled` status and `positions` shows 1 share of
`<SYM>`.

**(d) A GTC trailing stop is accepted by the live broker.**
```
bash scripts/alpaca.sh trailing-stop <SYM> 1 10
bash scripts/alpaca.sh orders open
```
Expected: the trailing-stop order is accepted (no rejection from the API) and
appears in `orders open` with `type: trailing_stop`, `time_in_force: gtc`.
This is the check that matters most — see §7.

**(e) A clean close leaves no orphan.**
```
bash scripts/alpaca.sh close <SYM>
bash scripts/alpaca.sh orders open
bash scripts/alpaca.sh positions
```
Expected: the position closes, and the GTC trailing stop that was covering it
is cancelled by the broker as part of the position close (Alpaca cancels
dependent open orders on a position close) — `orders open` must show nothing
left for `<SYM>` and `positions` must not list it.

## 3. Env setup

Export these in your own shell for this session only — never commit them,
never put them in a `.env` file, never paste them into the cloud Routines UI:

```
export TRADING_MODE=live
export ALPACA_ENDPOINT=https://api.alpaca.markets/v2
export ALPACA_DATA_ENDPOINT=https://data.alpaca.markets/v2
export ALPACA_API_KEY=<live key>
export ALPACA_SECRET_KEY=<live secret>
export TRADING_ENABLED=true
```

**Warning — read this before exporting anything.** These must never be set as
env vars on any cloud Routine (`pre-market`, `market-open`, `midday`,
`daily-summary`, `weekly-review`) while the paper trial is running. Setting
live credentials there — even temporarily, even for "just a quick check" —
would point the automated *strategy* at the live account the next time that
routine's cron fires. The `TRADING_MODE`/`ALPACA_ENDPOINT` mode guard in each
routine prompt catches a mismatch *between those two values*, but it cannot
catch "both values correctly say live" if that's genuinely what the cloud env
config says — so the only real safeguard is never putting live credentials in
the cloud UI in the first place. This procedure runs exclusively in your own
local shell, only for the duration of the test, and never in the cloud.

## 4. The Rule 13 caveat

Rule 13 places trailing stops at market close on the entry day specifically so
they cannot fire same-day — that is the entire mechanism that keeps this bot
at zero day trades by construction. **This test deliberately does not follow
that pattern**: check (d) places the buy and the GTC stop in the same manual
session, whatever time of day you happen to be running this, accepting that
the stop *could* fire intraday and turn this into a real day trade.

This is acceptable **only** because:
- it is a single manual one-share test, run once, outside the strategy
  entirely — not a routine, not repeated, not scheduled;
- the position size is one share of a liquid, low-priced ETF, so the worst
  case (an intraday stop-out) costs at most a few dollars of slippage;
- it is the fastest way to prove the stop is real without waiting a full
  session for Rule 13's normal T / T+1 split.

**It must never be done from a routine, and never repeated as a habit.** Every
future live order the strategy places must go through the ordinary Rule 13
path (stop placed at close, not at entry). If this test needs to be re-run for
any reason, treat each re-run with the same one-off caution, not as a new
normal.

## 5. Results table (fill in during the run)

| # | Check | Command | Expected | Actual | Pass/Fail |
|---|-------|---------|----------|--------|-----------|
| a | Live auth | `alpaca.sh account` | `status: ACTIVE` | | |
| b | DTC primary path | `alpaca.sh dtc` | `source=api`, integer count | | |
| c | Limit BUY fills | `alpaca.sh order '{...}'` | order `filled`, 1 share in `positions` | | |
| d | GTC trailing stop accepted | `alpaca.sh trailing-stop <SYM> 1 10` | accepted, visible in `orders open` | | |
| e | Clean close, no orphan | `alpaca.sh close <SYM>` | position gone, `orders open` empty for `<SYM>` | | |

## 6. Teardown

Regardless of pass/fail on any individual check, leave the account flat and
your shell clean before ending the session:

```
bash scripts/alpaca.sh close <SYM>       # no-op if already closed in step (e)
bash scripts/alpaca.sh cancel-all        # cancel anything still open
bash scripts/alpaca.sh positions         # must print an empty list
bash scripts/alpaca.sh orders open       # must print an empty list
```

Then unset every live env var from §3:

```
unset TRADING_MODE ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT ALPACA_API_KEY ALPACA_SECRET_KEY TRADING_ENABLED
```

Confirm your shell no longer has any of them set before closing the terminal.

## 7. What a failure means for go-live

Checks (a)–(c) and (e) failing point at credentials, connectivity, or account
funding/permissions — real problems, but fixable ones, and not indictments of
the design.

**Check (d) is different.** If the live broker rejects the GTC trailing stop —
for any reason: unsupported order type on the account tier, insufficient
buying power for the stop, a rejected `extended_hours: false` trailing-stop
order, anything — that is not a nuisance to route around. Rule 6 ("every
position gets a real GTC trailing stop, never mental") and Rule 13 ("stops
placed at close so they cannot fire same-day") both assume the broker will in
fact accept a GTC trailing-stop order on request. If the live broker won't
take that order, then the entire visa-aware safety design — every position
protected, zero day trades by construction — silently does not hold on the
live account.

The system *does* detect an unprotected position after the fact: Rule 17 fires
an URGENT Telegram and writes a `STOP-PLACEMENT-FAILED` marker that the next
routine retries as its first action, and `ops.unprotected_positions` in the
nightly metrics record FAILs the `unprotected` go-live criterion. So this is not
an undetected failure. What makes it a blocker is that **both of those are
after-the-fact detectors of a condition that would then be permanent**: they
report and retry, and the retry hits the same broker-side refusal every time.
Rule 6 ("every position gets a real GTC trailing stop, never mental") and
Rule 13 ("stops placed at close so they cannot fire same-day") both assume the
broker will accept the order *eventually*. If it never will, the retry loop
never converges, every live position rides unprotected, and the alerting just
tells you so once per routine.

**A rejected trailing stop on live is therefore a hard blocker on going live at
any size**, not a "note it and proceed." Do not flip `TRADING_MODE=live` on
any routine until check (d) has passed cleanly at least once.

## 8. Known open failure mode — the melt-up RS hole (NOT fixed)

Recorded deliberately, as a known limitation carried into the trial rather than
a defect awaiting a patch.

**The shape.** In a strong-breadth melt-up, `sizing.py rscreen` can reject
*every* satellite candidate: RS10 and RS50 are computed against SPY, and when
the index itself is the strongest thing in the tape, almost nothing shows
positive relative strength. Rule 5's re-deployment trigger relaxes the **R:R**
floor for core ballast (2:1 → 1.5:1); it does **not** relax **RS**. So the book
can sit below the 75% deployment floor for an extended run with the trigger
armed every single morning and still buy nothing — pre-market HOLDs, market-open
has no ideas to gate, and the cash drag compounds against a rising benchmark.
This is the Week-15 mechanism: −1.78pp of a −1.94pp week, entirely cash drag.

**Why it is not being fixed here.** Loosening RS in exactly the regime where
relative strength is hardest to demonstrate is how a momentum strategy ends up
buying laggards at the top. The screen is doing what it was designed to do; the
question of what the *right* melt-up behaviour is (broad-index ballast? an
explicit cash-drag budget? nothing?) is a strategy question, not a bug fix, and
it should not be answered under go-live pressure.

**What was done instead.** The `deployment` go-live criterion is now built to
**catch** this state rather than mask it (v3.4): `metrics.py` no longer resets
its consecutive-below-floor run on `rule5.triggered`, because arming a
relaxation that admits nothing is not re-deployment. More than two consecutive
sessions below the 75% floor FAILs, whatever the reason. A blocked melt-up
window is therefore a **no-go**, by design — the go-live decision does not get
to pass through the exact state that cost the phase 1.78pp.

**Reading it in the review.** When `deployment` FAILs, compare the rollup's
`rule5_triggers` and `rule5_acted`:

| Pattern | Meaning |
|---|---|
| `triggers > 0`, `acted == 0` | this hole: armed daily, screens admitted nothing |
| `triggers > 0`, `acted > 0` | Rule 5 worked, the adds were just too small or too late |
| `triggers == 0` | the trigger never armed — Rule 5 itself, not this hole |

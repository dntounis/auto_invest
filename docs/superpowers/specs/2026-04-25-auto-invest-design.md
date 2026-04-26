# auto_invest — v1 Design Spec

**Date:** 2026-04-25
**Author:** Brainstorm session, Claude Code (Opus 4.7)
**Status:** Awaiting user approval before plan-writing
**Repo:** https://github.com/dntounis/auto_invest
**Source material:**
- `docs/source/automated_trading_agent_lessons.md` — strategy & risk philosophy
- `docs/source/agentic_ai_system_steering_spec.md` — files-as-memory architecture pattern
- `docs/source/Opus 4.7 Trading Bot — Setup Guide.pdf` — Nate Herk's Claude-Code-native blueprint

---

## 1. Goal

Build an autonomous, scheduled trading agent that runs as Claude Code cloud routines, follows a disciplined swing-trading strategy, and uses a Git repo as durable memory.

**v1 is research-only on a paper Alpaca account.** No order code paths execute. The system proves out the "Claude wakes up, reads memory, calls APIs, writes memory, commits, pushes, notifies" loop on the lowest-stakes routines first. v2 adds execution; v3 (out of scope) adds live trading.

---

## 2. Confirmed decisions

| # | Decision | Choice |
|---|---|---|
| Q1 | Trading mode for v1 | **Paper trading only.** Live mode gated behind explicit toggle change in v3. |
| Q2 | Notification channel | **Slack** via incoming webhook URL (replaces PDF's ClickUp). |
| Q3 | Dependency strategy | **Pure bash + `curl` + stdlib Python.** No SDKs, no `pip install` in cloud. Same code path local & cloud. |
| Q4 | v1 scope | **MVP = `pre-market` + `daily-summary` routines + wrappers + memory files.** No `market-open`/`midday`/`weekly-review` until v2. |
| — | Research stack | **Perplexity required in v1.** All research goes through `scripts/perplexity.sh`, with WebSearch fallback retained for resilience only. |
| — | GitHub repo | **Already created** at https://github.com/dntounis/auto_invest. Local git init + `gh` (from conda `base` env) connects to it. |
| — | Local dev tooling | Conda `base` env (which has authenticated `gh`) used during setup. Trading code itself remains pure bash + stdlib Python — conda is purely a developer convenience layer. |

---

## 3. Architecture

### 3.1 The big idea (inherited from PDF)

> Claude *is* the bot. There is no Python process running 24/7. Each cron firing spins up a fresh Claude Code container that clones the repo at `main`, reads memory files, calls a few bash wrapper scripts, writes memory back, commits & pushes. Git is the durable state.

### 3.2 v1 component diagram

```
                 ┌────────────────────────────────────┐
                 │  Anthropic Cloud Routines          │
                 │  (cron triggers, ephemeral         │
                 │   containers, env vars in UI)      │
                 └─────────────┬──────────────────────┘
                               │ (cron fires, container starts)
                               ▼
            ┌──────────────────────────────────┐
            │  git clone github.com/dntounis/   │
            │  auto_invest @ main              │
            └─────────────┬────────────────────┘
                          ▼
            ┌──────────────────────────────────┐
            │  Claude Code reads:              │
            │  - CLAUDE.md (auto-loaded)       │
            │  - routines/<routine>.md (prompt)│
            │  - memory/*.md                   │
            └─────────────┬────────────────────┘
                          ▼
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ alpaca.sh    │  │ perplexity.sh│  │ slack.sh     │
│ (paper API)  │  │ (research)   │  │ (webhook)    │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          ▼
            ┌──────────────────────────────────┐
            │  Claude Code writes memory       │
            │  + git commit + git push origin  │
            │  main                            │
            └─────────────┬────────────────────┘
                          ▼
                    Container destroyed
```

### 3.3 Two execution modes share the same code

| Mode | When | Trigger | Credentials |
|---|---|---|---|
| **Local** | You testing on your Mac | `/portfolio`, `/pre-market`, `/daily-summary` slash commands in interactive Claude Code | `.env` at repo root (gitignored) |
| **Cloud** | Production | Cron in Anthropic Routines UI | Process env vars set in the routine config — **no `.env` file ever in cloud** |

Same wrapper scripts, same memory format, same prompts (modulo the env-var-check + commit-push blocks the cloud routines need).

---

## 4. Repository layout

```
auto_invest/                     (this dir → git working tree)
├── CLAUDE.md                    # ★ Agent rulebook, auto-loaded every session
├── README.md                    # Human-facing quickstart & bootstrap checklist
├── env.template                 # Documents required env vars; commit this
├── .env                         # Local credentials only — GITIGNORED
├── .gitignore                   # Excludes .env, *.log, .DS_Store
│
├── .claude/
│   └── commands/                # Local-mode ad-hoc slash commands
│       ├── portfolio.md         # ★ Read-only snapshot
│       ├── pre-market.md        # ★ Local mirror of pre-market routine
│       └── daily-summary.md     # ★ Local mirror of daily-summary routine
│
├── routines/                    # Cloud-mode prompts (paste into routine UI verbatim)
│   ├── README.md                # TZ, env vars, "Allow unrestricted branch pushes" notes
│   ├── pre-market.md            # ★ Cron: 0 6 * * 1-5  America/Chicago
│   └── daily-summary.md         # ★ Cron: 0 15 * * 1-5 America/Chicago
│
├── scripts/                     # All external API calls flow through here
│   ├── alpaca.sh                # ★ account/positions/orders/quote (+ gated order/cancel/close for v2)
│   ├── perplexity.sh            # ★ research wrapper, exit 3 fallback to WebSearch
│   └── slack.sh                 # ★ replaces clickup.sh; POSTs to incoming webhook
│
├── memory/                      # Agent's persistent state — committed to main
│   ├── PROJECT-CONTEXT.md       # ★ Mission, paper-mode flag, repo URL
│   ├── TRADING-STRATEGY.md      # ★ Strategy + hard rules (from lessons doc)
│   ├── RESEARCH-LOG.md          # ★ Pre-market entries appended here daily
│   ├── TRADE-LOG.md             # ★ Seeded w/ Day 0 baseline; daily-summary appends EOD snapshots
│   └── WEEKLY-REVIEW.md         # Seeded empty; written by v2
│
└── docs/
    ├── source/                  # Reference docs, moved out of working dir
    │   ├── automated_trading_agent_lessons.md
    │   ├── agentic_ai_system_steering_spec.md
    │   └── Opus 4.7 Trading Bot — Setup Guide.pdf
    └── superpowers/
        └── specs/
            └── 2026-04-25-auto-invest-design.md   # this file
```

★ = built and active in MVP. Unmarked = seeded so structure is in place; first written-to in v2.

### 4.1 Deviations from the PDF

| # | What | Why |
|---|---|---|
| 1 | `scripts/slack.sh` replaces `scripts/clickup.sh` | User doesn't use ClickUp. Same interface, same fallback behavior, simpler one-URL config. |
| 2 | `docs/source/` keeps reference material out of working tree | Agent shouldn't read these on each run; they're for humans + future Claude sessions. |
| 3 | `docs/superpowers/specs/` for design docs | Per brainstorming skill convention. Separates planning artifacts from agent memory. |
| 4 | `TRADING_ENABLED` kill-switch contract enforced in `alpaca.sh` itself | Belt-and-suspenders. v1 has no order code paths, so the wrapper-side gate makes accidental order-placement impossible until v2 explicitly flips it. |
| 5 | `ALPACA_ENDPOINT` is **required**, never defaults to live URL | The PDF defaults to `https://api.alpaca.markets/v2` (live!). For paper safety we explicitly require the paper URL `https://paper-api.alpaca.markets/v2` and the wrapper refuses to run if unset. |

---

## 5. Memory schema

### 5.1 `CLAUDE.md` — agent identity (project root)

Auto-loaded by Claude Code at session start (local) and explicitly read in step 1 of every routine prompt (cloud).

Contains:
- Persona: "autonomous AI trading bot, ~$10K **paper** Alpaca account, stocks only ever, ultra-concise"
- Read-me-first list (5 memory files in order)
- Hard-rules quick reference (so even off-script ad-hoc invocations respect them)
- API wrapper pointer ("never `curl` these APIs directly, always use `scripts/*.sh`")
- Communication style ("short bullets, no preamble")

### 5.2 `memory/PROJECT-CONTEXT.md` — static, rarely changes

| Field | Value (v1) |
|---|---|
| Mission | Beat the S&P 500 over the challenge window |
| Mode | **Paper only.** `TRADING_ENABLED=false` |
| Starting capital | ~$10,000 paper |
| Platform | Alpaca paper API |
| Repo | https://github.com/dntounis/auto_invest |
| Files to read every session | List pointer to the 5 memory files |

Written by hand only, when project parameters change.

### 5.3 `memory/TRADING-STRATEGY.md` — the rulebook

Distilled from `docs/source/automated_trading_agent_lessons.md`:

**Hard rules (non-negotiable):**
1. NO OPTIONS — ever
2. Max 5–6 open positions
3. Max 20% of equity per position (~$2,000 on $10K)
4. Max 3 new trades per week
5. Target 75–85% capital deployed
6. Every position gets a 10% trailing stop as a real GTC Alpaca order (v2)
7. Cut losers at -7% manually (v2)
8. Tighten trail to 7% at +15%, 5% at +20% (v2)
9. Never within 3% of current price; never move a stop down (v2)
10. Exit a sector after 2 consecutive failed trades (v2)
11. Patience > activity; "no trade" is a valid decision

**Buy-side gate** (referenced by v1 pre-market for filtering trade *ideas*; enforced by v2 market-open before orders):
- Total positions after fill ≤ 6
- Trades this week + 1 ≤ 3
- Position cost ≤ 20% equity
- Position cost ≤ available cash
- daytrade_count leaves room (PDT: 3/5 rolling business days under $25K)
- Specific catalyst documented in today's RESEARCH-LOG
- Instrument is a stock (not option, not anything else)

**Sell-side rules** (v2): exit at -7%, exit on broken thesis, tighten trails, sector-failure exit.

Written: only on Friday weekly-review (v2). Read by every routine.

### 5.4 `memory/RESEARCH-LOG.md` — daily pre-market output

Append-only, one dated entry per weekday. Schema per entry:

```md
## YYYY-MM-DD — Pre-market Research

### Account
- Equity / Cash / Buying power / Daytrade count

### Market Context
- WTI / Brent oil
- S&P 500 futures
- VIX
- Today's catalysts
- Earnings before open
- Economic calendar
- Sector momentum

### Trade Ideas
1. TICKER — catalyst, entry $X, stop $X, target $X, R:R X:1
2. ...
3. ...

### Risk Factors
- ...

### Decision
TRADE or HOLD (default HOLD if no edge)
```

Each cited claim notes whether it came from Perplexity (citations included) or WebSearch fallback (flagged as "WebSearch fallback").

Written by `pre-market` routine. Read by `daily-summary` (to recap morning plan vs. day) and by `market-open` in v2.

### 5.5 `memory/TRADE-LOG.md` — trades + EOD snapshots

**v1 content:** Day 0 baseline + EOD snapshots only. No trade rows (no order code).

EOD schema:
```md
### MMM DD — EOD Snapshot (Day N, Weekday)
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** ±$X (±X%) | **Phase P&L:** ±$X (±X%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |

**Notes:** one-paragraph plain-english summary.
```

Day 0 baseline (seeded at first commit) lets `daily-summary` compute Day-1 P&L against it.

Written by `daily-summary` (v1) and by `market-open`/`midday` (v2).

### 5.6 `memory/WEEKLY-REVIEW.md` — Friday recaps (v2)

Header + template only in v1, no entries written. Template includes stats table, closed-trades table, open positions, what-worked / what-didn't, key lessons, adjustments for next week, letter grade A-F.

Written by `weekly-review` routine (v2 only).

### 5.7 Routine read/write contract (v1)

| Routine | Reads | Writes |
|---|---|---|
| `pre-market` | `CLAUDE.md`, `TRADING-STRATEGY.md`, tail of `TRADE-LOG.md`, tail of `RESEARCH-LOG.md` | `RESEARCH-LOG.md` (append today) |
| `daily-summary` | tail of `TRADE-LOG.md` (yesterday's equity), today's `RESEARCH-LOG.md` entry | `TRADE-LOG.md` (append today's EOD snapshot) |

Both routines additionally: `bash scripts/alpaca.sh account|positions|orders` for live state, then `git commit && git push origin main`.

---

## 6. Scheduling, timezone, notifications

### 6.1 Cron schedules (cloud routines, MVP)

Both crons run in **`America/Chicago`** (US market timezone — schedule follows the markets the bot trades, not where the user lives):

| Routine | Cron | CT meaning | Why this time |
|---|---|---|---|
| `pre-market` | `0 6 * * 1-5` | 6:00 AM CT, weekdays | 2.5 hr pre-open: catalysts/earnings public, before the open is hectic |
| `daily-summary` | `0 15 * * 1-5` | 3:00 PM CT, weekdays | Right at the close (US closes 3 PM CT): final equity settled, nothing more to react to |

Notifications land in Slack in the user's local time automatically (Slack timestamps based on client). For Athens (UTC+3 in DST): pre-market ≈ 14:00, daily-summary ≈ 23:00.

`weekly-review` (`0 16 * * 5`) added in v2.

### 6.2 Notification policy (v1)

| Routine | Slack message? | Content if sent |
|---|---|---|
| `pre-market` | **Silent unless urgent.** v1 "urgent" = major macro event (geopolitical, big macro release surprise). No held-position alerts in v1 (no positions). Default: no message. | One-line summary if urgent. |
| `daily-summary` | **Always.** Once per weekday, ≤15 lines. | Equity, day-Δ%, phase-Δ%, positions list, "no trades today" or summary, one-line tomorrow plan. |

Result: typically **one Slack message per weekday** in v1. Silent failures are observable from `git log origin/main` (no commit at the expected time = the routine didn't run or didn't write).

Every Slack message includes a `(paper)` suffix in v1 to make confusion with future live-mode messages impossible.

### 6.3 Slack message format

Slack incoming webhooks accept `{"text": "..."}` JSON with markdown enabled. Supported: `*bold*`, `_italic_`, `` `code` ``, bullets. Format kept minimal so the same string renders cleanly in the local fallback file.

Sample EOD message (8 lines):
```
*EOD Apr 27* (paper)
Equity: $10,012.40 (+0.12% day, +0.12% phase)
Cash: $10,012.40 (100%)
Trades today: none (v1 = research only)
Open positions: none
Pre-market plan today: HOLD — VIX elevated, no clear catalyst
Tomorrow: pre-market checks at 6:00 CT
```

---

## 7. Secrets handling

The single biggest first-run footgun (per PDF Part 9): in the cloud, the agent sees "`KEY not set in environment`" from a wrapper, helpfully creates a `.env` file as a "fix," commits it, and **leaks credentials to GitHub**. Both wrappers and prompts enforce the prohibition.

### 7.1 Storage by mode

| Mode | Where credentials live | How wrappers find them |
|---|---|---|
| Local | `.env` at repo root (gitignored) | Wrapper sources `.env` if present, then falls back to process env |
| Cloud routine | Set in routine's environment config UI | Wrapper reads process env directly; **no `.env` ever exists in cloud clone** |

### 7.2 Required env vars (v1)

```
ALPACA_API_KEY              # paper account key
ALPACA_SECRET_KEY           # paper account secret
ALPACA_ENDPOINT             # = https://paper-api.alpaca.markets/v2 for paper (REQUIRED, no default)
ALPACA_DATA_ENDPOINT        # = https://data.alpaca.markets/v2 (same for paper & live)
PERPLEXITY_API_KEY          # required in v1
PERPLEXITY_MODEL            # optional, defaults to 'sonar'
SLACK_WEBHOOK_URL           # required for non-fallback notifications
TRADING_ENABLED             # = "false" in v1
```

### 7.3 .gitignore (minimum)

```
.env
.env.*
*.log
.DS_Store
DAILY-SUMMARY.md            # local fallback file when Slack unavailable
```

### 7.4 Anti-leak guards (defense in depth)

1. **Wrapper-side**: every wrapper that reads `.env` reads only at script start, never writes one
2. **Prompt-side**: every cloud routine prompt has an explicit, loud "DO NOT create, write, or source a .env file" block
3. **Git-side**: `.env` and `.env.*` in `.gitignore` from the first commit
4. **Detection**: README documents how to verify with `git log -- .env` (should be empty)

---

## 8. Wrapper script specs

### 8.1 `scripts/alpaca.sh`

**Active in v1:**
- `account` — `GET /v2/account`. Returns equity, cash, buying_power, daytrade_count, pattern_day_trader.
- `positions` — `GET /v2/positions`. All open positions with unrealized P&L.
- `orders [status]` — `GET /v2/orders?status=$status`. Default `status=open`.
- `quote SYM` — `GET data.alpaca.markets/v2/stocks/$SYM/quotes/latest`. Latest bid/ask. (Uses `data.alpaca.markets`, not `api.alpaca.markets`.)
- `position SYM` — `GET /v2/positions/$SYM`. Single-position lookup.

**Built but kill-switch-gated for v2:**
- `order '<json>'` — `POST /v2/orders`. **Refuses with exit 4 if `TRADING_ENABLED != "true"`.**
- `cancel ORDER_ID` — same gate.
- `cancel-all` — same gate.
- `close SYM` — same gate.
- `close-all` — same gate.

**Translation rules baked in:**
- Env var `ALPACA_API_KEY` → HTTP header `APCA-API-KEY-ID`
- Env var `ALPACA_SECRET_KEY` → HTTP header `APCA-API-SECRET-KEY`
- All numeric JSON fields (`qty`, `trail_percent`, `stop_price`) sent as **strings**

**Behavior contract:**
- `set -euo pipefail`
- Sources `.env` if present at repo root (local mode); doesn't otherwise
- Exits 1 on missing required env vars (not 0, not silent)
- Exits 4 on kill-switch-gated subcommand attempt
- Writes errors to stderr, JSON responses to stdout

### 8.2 `scripts/perplexity.sh`

- One subcommand: `bash scripts/perplexity.sh "<query>"`
- POSTs to `api.perplexity.ai/chat/completions` with system message: "You are a precise financial research assistant. Cite every claim. Be concise."
- Model from `${PERPLEXITY_MODEL:-sonar}`
- Exits 3 with stderr warning if `PERPLEXITY_API_KEY` unset → `pre-market` prompt instructs agent to fall back to native `WebSearch` and **flag the fallback in the research-log entry**
- Resilience-only: in v1 we expect Perplexity to be present, but the fallback path stays so an expired key doesn't break the run

### 8.3 `scripts/slack.sh`

- Usage: `bash scripts/slack.sh "<markdown message>"` (or pipe via stdin)
- POSTs `{"text": "<msg>"}` to `$SLACK_WEBHOOK_URL`
- Uses Python `json.dumps` for payload escaping (handles backticks, quotes, newlines safely)
- **Fallback if `SLACK_WEBHOOK_URL` unset:** appends to `DAILY-SUMMARY.md` at repo root with timestamp header `--- ## YYYY-MM-DD HH:MM TZ (fallback — Slack not configured)`, exits 0. Agent never crashes on missing notification creds.
- `DAILY-SUMMARY.md` is gitignored so fallback writes don't accidentally get committed

---

## 9. Routine prompts

Both routine prompts follow the PDF's prompt scaffold (persona → env-var check → persistence warning → numbered work steps → notification → commit/push). Three load-bearing invariants:

1. **Environment check first** — fails fast with a clear message instead of cryptic curl errors downstream
2. **Persistence warning is loud** — without the reminder, Claude skips the final push in ~10% of runs (PDF observation)
3. **Rebase on conflict, never force-push** — guarantees no overwrite of another run's memory

### 9.1 `routines/pre-market.md`

6 work steps (after the env-check + persistence preamble):
1. Read memory: `CLAUDE.md`, `TRADING-STRATEGY.md`, tail `TRADE-LOG.md`, tail `RESEARCH-LOG.md`
2. Pull live state: `account`, `positions`, `orders` via `alpaca.sh`
3. Research via Perplexity (oil, S&P futures, VIX, catalysts, earnings, economic calendar, sector momentum, news on each held ticker — none in v1). Fall back to WebSearch on exit code 3 and flag.
4. Write dated entry to `RESEARCH-LOG.md`: account snapshot, market context, 2-3 trade ideas (each with catalyst+entry/stop/target), risk factors, DECISION (default HOLD)
5. Notification: silent unless macro-urgent
6. `git add memory/RESEARCH-LOG.md && git commit -m "pre-market research $DATE" && git push origin main`. On push divergence: `git pull --rebase`, retry. Never `--force`.

(v1-specific note in the prompt: "There are no held positions in v1 because no order code runs. Skip the per-ticker news step. Trade ideas should be documented for tracking purposes only — they will not be executed.")

### 9.2 `routines/daily-summary.md`

6 work steps (after the env-check + persistence preamble):
1. Read tail of `TRADE-LOG.md` to find yesterday's EOD equity (needed for Day P&L)
2. Pull final state of day: `account`, `positions`, `orders` via `alpaca.sh`
3. Compute: Day P&L ($ and %), phase cumulative P&L, trades today (always "none" in v1), trades-this-week running total
4. Append EOD snapshot to `TRADE-LOG.md`
5. Send ONE Slack message via `slack.sh` (always, even on no-trade days). ≤15 lines. Includes `(paper)` suffix.
6. `git add memory/TRADE-LOG.md && git commit -m "EOD snapshot $DATE" && git push origin main`. Mandatory commit (tomorrow's Day-P&L math depends on it). Rebase on conflict.

### 9.3 Local-mode slash command mirrors

`.claude/commands/{portfolio,pre-market,daily-summary}.md` — same content as routines, minus the env-check block (local `.env` handles credentials) and minus the commit/push step (you'll commit by hand when iterating locally).

`portfolio.md` is a v1 ad-hoc helper: read-only snapshot of account/positions/orders, no state changes, no file writes, no orders.

---

## 10. Bootstrap order (for the implementation plan)

The writing-plans skill will produce the detailed implementation plan. Suggested phasing:

1. Move source docs into `docs/source/`. `git init`. Connect to existing GitHub remote via `gh`. Initial empty commit + push.
2. Write `.gitignore`, `env.template`, `README.md`, `CLAUDE.md`. Commit.
3. Write `scripts/alpaca.sh`, `scripts/perplexity.sh`, `scripts/slack.sh`. `chmod +x`. Commit.
4. Seed `memory/*.md` (5 files, with appropriate v1 starter content). Commit.
5. Write `.claude/commands/{portfolio,pre-market,daily-summary}.md`. Commit.
6. Write `routines/{README,pre-market,daily-summary}.md`. Commit. Push.
7. **Local smoke test gate (manual):** user pastes Alpaca paper keys + Perplexity key + Slack webhook URL into local `.env`. Runs `/portfolio` in Claude Code. Must see clean account/positions output with no errors before proceeding to cloud routine setup.
8. **Cloud routine setup gate (manual, web UI):** user creates the two routines in Anthropic's UI per `routines/README.md`, pastes the prompts verbatim, enables "Allow unrestricted branch pushes", sets env vars, hits "Run now" once each.
9. Observe 5 weekday cycles. If clean → v1 done.

Steps 1–6 are codable. Steps 7–9 are operational gates the user does.

---

## 11. v1 → v2 → v3 phased path

### v1 exit criteria

System is v1-stable when **all** observed:

1. Both routines have fired successfully on cloud cron for **5 consecutive weekdays** with no manual intervention
2. Each successful run produced a commit on `main` from the routine container, visible in `git log origin/main`
3. Slack receives expected notifications: silent pre-market, EOD message every weekday
4. Perplexity calls succeed (cited research in `RESEARCH-LOG.md`); WebSearch fallback triggered & logged at least once during testing
5. Zero `.env` files have ever appeared in the cloud clone (`git log -- .env` empty)
6. At least one rebase-on-conflict has occurred cleanly (induced manually to test the path)

### v2 — add execution (still paper)

Built only after v1 exit criteria met:
- Add `routines/market-open.md` (cron `30 8 * * 1-5`)
- Add `routines/midday.md` (cron `0 12 * * 1-5`)
- Add `routines/weekly-review.md` (cron `0 16 * * 5`)
- Add `.claude/commands/{market-open,midday,weekly-review,trade}.md`
- Flip `TRADING_ENABLED=true` (still paper account)
- `weekly-review` is when `TRADING-STRATEGY.md` first becomes write-eligible

v2 exit: full 5-routine system runs cleanly for **2 weeks of paper trading**, no rule violations in trade log, no missing-stop incidents, weekly review actually grades the bot.

### v3 — live mode (out of scope for this spec)

Becomes its own design discussion. Will involve at minimum:
- Rotating credentials to live Alpaca keys
- Swapping `ALPACA_ENDPOINT` to `https://api.alpaca.markets/v2`
- Adding a starting-capital cap
- Possibly a daily-loss circuit-breaker enforced wrapper-side

---

## 12. Open questions / known unknowns

None blocking v1 implementation. Items deferred:
- Exact Perplexity prompt wording for sector-momentum query (will tune after first week of research-log entries)
- Whether to add a heartbeat Slack ping on pre-market success (user's preference: no — `git log` is the heartbeat)
- Whether the v2 weekly-review should auto-edit `TRADING-STRATEGY.md` or just propose changes via Slack for human approval (deferred to v2 spec)

---

## 13. Out of scope

- Live trading
- Options trading (banned forever per strategy)
- Crypto, forex, futures
- After-hours trading
- Backtesting infrastructure
- Multi-account support
- Web UI for the agent
- Mobile app
- Anything that depends on a position existing (in v1)

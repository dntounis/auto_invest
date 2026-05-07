# Cloud Routines — setup notes

Each `.md` file in this directory is a prompt for a Claude Code cloud routine. Paste the contents **verbatim** into the routine UI.

## One-time prerequisites

1. **Install the Claude GitHub App on this repo.** Visit the install page, select only `dntounis/auto_invest` (least privilege), and grant access. Without this, the cloud container cannot clone or push.
2. **Enable "Allow unrestricted branch pushes" on the routine's environment.** Without this, `git push origin main` fails silently with a proxy error in the cloud. This is the #1 first-run failure mode.

## Per-routine setup (Pre-market and Daily-summary)

In Claude Code cloud → Routines → New Routine:

1. **Name:** "auto_invest pre-market" (or "auto_invest daily-summary")
2. **Repository:** `dntounis/auto_invest`
3. **Branch:** `main`
4. **Environment variables** — set ALL of these in the routine's env config (not in a `.env` file):
   - `ALPACA_API_KEY` (paper)
   - `ALPACA_SECRET_KEY` (paper)
   - `ALPACA_ENDPOINT` = `https://paper-api.alpaca.markets/v2`
   - `ALPACA_DATA_ENDPOINT` = `https://data.alpaca.markets/v2`
   - `PERPLEXITY_API_KEY`
   - `PERPLEXITY_MODEL` = `sonar` (optional)
   - `TELEGRAM_BOT_TOKEN` (from @BotFather, looks like `123456789:ABC...`)
   - `TELEGRAM_CHAT_ID` (your numeric chat ID — visit `https://api.telegram.org/bot<TOKEN>/getUpdates` after sending `/start` to your bot)
   - `TRADING_ENABLED` = `false`
5. **"Allow unrestricted branch pushes":** ON
6. **Cron schedule + timezone** — both routines run in `America/Chicago`:
   - Pre-market: `0 6 * * 1-5` (6:00 AM weekdays)
   - Daily-summary: `0 15 * * 1-5` (3:00 PM weekdays — US market close)
7. **Prompt:** paste the contents of `pre-market.md` (or `daily-summary.md`) **verbatim**. Do not paraphrase — the env-var-check and commit/push blocks are load-bearing.
8. **Save**, then click **"Run now"** to do a smoke test before waiting for the cron.

## v2 routines (active)

Three additional routines plus expanded daily-summary. Set up in this order;
flip `TRADING_ENABLED=true` only after each successful smoke test.

### Order of routine activation

1. **`auto_invest daily-summary`** (already exists from v1 — re-paste prompt with v2 changes; flip `TRADING_ENABLED=true`)
2. **`auto_invest market-open`** — `30 8 * * 1-5` America/Chicago
3. **`auto_invest midday`** — `0 12 * * 1-5` America/Chicago
4. **`auto_invest weekly-review`** — `0 16 * * 5` America/Chicago

### Per-v2-routine env vars

In addition to the v1 set (Alpaca, Perplexity, Telegram, `TRADING_ENABLED`),
add these to the env-vars textbox:

- `TRADING_ENABLED=true` (was `false` in v1)
- `MAX_ENTRY_SLIPPAGE_PCT=0.10` (default 0.10%)
- `RISK_PER_TRADE_PCT=2.0` (default 2% of equity)
- `MAX_POSITION_PCT=20` (default 20% cap)

### Per-routine prompt re-paste

For each of the four routines, copy the entire contents of the corresponding
`routines/<name>.md` file and paste verbatim into the routine's Prompt field.
Save. Smoke-test with Run now before relying on cron.

### Visa-aware safety chain

The v2 system avoids day trades by construction:

- `market-open` only places BUYs. It cannot create a same-day exit.
- `daily-summary` places trailing stops at 15:00 CT (= market close). They
  enter the GTC book but cannot fire same-day (regular session is over and
  `extended_hours: false`). Earliest possible fire is T+1.
- `midday` and `weekly-review` skip positions opened today (Rule 15) and
  pre-flight `account.daytrade_count` before any sell (Rule 14).

If `daytrade_count` ever reaches 2, the routines abort all sells and Telegram
URGENT — leaving manual sells to a human review (one buffer slot before the
PDT designation threshold of 4).

## Why "no `.env` file in cloud"

The wrapper scripts read `.env` at startup if present. In the cloud, `.env` should never exist. If a routine prompt is paraphrased and loses the explicit "DO NOT create a .env file" block, Claude has been observed to "helpfully" create one to fix a missing-key error — which would commit credentials to GitHub. Every routine prompt has the prohibition stated loudly.

## Branch policy override (load-bearing)

Anthropic's Routines runtime injects a hidden system-prompt directive instructing the agent to push to a `claude/<random>-<id>` feature branch instead of `main`. Our v1 architecture requires direct-to-`main` pushes (each routine's commit must be visible to the next routine's clone). Each prompt file in this directory has an explicit **`## OVERRIDE — Branch Policy`** block near the top instructing the agent to ignore the runtime's branch directive. Do not remove or paraphrase that block.

If a routine push ever lands on a `claude/...` branch instead of `main`, the override was lost — re-paste the prompt verbatim from this directory.

## Environment variables — exact names matter

The Anthropic Routines runtime does no fuzzy matching of env-var names. A typo like `ALPACA_API_SECRET` vs `ALPACA_SECRET_KEY` causes silent absence (`KEY not set in environment`) instead of the intended value. The 9 names above must match the wrapper scripts and routine prompts letter-for-letter, case-sensitive, no leading/trailing whitespace, no spaces around `=`.

Validation happens **inside the routine prompt** (where Claude runs), not in the setup script — see next section for why.

## Setup script — keep it trivial (load-bearing discovery)

In the Anthropic Routines product, the per-environment **Setup script** runs in a phase *before* Claude Code launches. The env vars you configure in the same form are **scoped to Claude's process, not to the setup script's process**. Anything the setup script tries to read from env will appear empty regardless of what's in the env-vars textbox. This caused multiple days of silent cron failures during initial setup until we figured it out.

**Use this exact setup script** in the Anthropic Routines UI (paste verbatim into the Setup script textbox):

```bash
#!/bin/bash
echo "Setup script: passing through. Env validation deferred to routine prompt (where env vars are visible)."
exit 0
```

That's the entire script. No env checks, no polling, no validation. Just exits 0 so the runtime moves on to launching Claude.

### Why this works

Three layers of validation already run **inside Claude's process** (where env vars are visible):

1. **Routine prompt env-var loop** — the `IMPORTANT — ENVIRONMENT VARIABLES` block in each `routines/*.md` file runs `for v in ALPACA_API_KEY ...; do [[ -n "${!v:-}" ]] && echo "$v: set" || echo "$v: MISSING"; done` and instructs Claude to STOP + Telegram-alert if any var is missing.
2. **Wrapper script env guards** — every `scripts/*.sh` wrapper has `: "${ALPACA_API_KEY:?ALPACA_API_KEY not set in environment}"`-style guards that exit 1 with a clear message if a required var is unset.
3. **Sanity-check on `ALPACA_ENDPOINT`** — both routine prompts include an explicit check that the endpoint contains `paper-api.alpaca.markets` to prevent accidental live-mode runs in v1.

### What NOT to put in the setup script

Avoid all of these. They will cause failures:

- ❌ Anything that reads env vars (they aren't there)
- ❌ Comments containing em-dashes (`—`) or other non-ASCII chars (the textbox can mangle them, breaking comment parsing)
- ❌ Backslash line continuations (`\` followed by newline) — the textbox sometimes adds trailing whitespace that breaks bash continuation parsing
- ❌ Polling loops trying to wait for env vars — they will never appear in this phase

### How this differs from the original PDF guide

The PDF (`docs/source/Opus 4.7 Trading Bot — Setup Guide.pdf`) was written for an earlier Claude Code cloud routines product that had a single shell context: env vars were injected before Claude launched, so a setup script could see them. The current Anthropic Routines UI splits these into two phases. The PDF's Part 7 description ("It injects the environment variables you configured on the routine into the shell. It starts Claude with the prompt") no longer matches the runtime — env injection is now Claude-process-scoped.

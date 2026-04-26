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
   - `SLACK_WEBHOOK_URL`
   - `TRADING_ENABLED` = `false`
5. **"Allow unrestricted branch pushes":** ON
6. **Cron schedule + timezone** — both routines run in `America/Chicago`:
   - Pre-market: `0 6 * * 1-5` (6:00 AM weekdays)
   - Daily-summary: `0 15 * * 1-5` (3:00 PM weekdays — US market close)
7. **Prompt:** paste the contents of `pre-market.md` (or `daily-summary.md`) **verbatim**. Do not paraphrase — the env-var-check and commit/push blocks are load-bearing.
8. **Save**, then click **"Run now"** to do a smoke test before waiting for the cron.

## v2 routines (not built yet)

- `market-open.md` — `30 8 * * 1-5`
- `midday.md` — `0 12 * * 1-5`
- `weekly-review.md` — `0 16 * * 5`

These get added once v1 has run cleanly for 5 consecutive weekdays. See `docs/superpowers/specs/2026-04-25-auto-invest-design.md` § 11 for the full v1→v2→v3 phased path.

## Why "no `.env` file in cloud"

The wrapper scripts read `.env` at startup if present. In the cloud, `.env` should never exist. If a routine prompt is paraphrased and loses the explicit "DO NOT create a .env file" block, Claude has been observed to "helpfully" create one to fix a missing-key error — which would commit credentials to GitHub. Every routine prompt has the prohibition stated loudly.

# auto_invest

Autonomous, cloud-scheduled stock trading agent built on Claude Code.
**v1 is paper-only, research-only.** No real orders execute — the wrapper-side `TRADING_ENABLED` kill-switch refuses every state-changing Alpaca subcommand.

See [`docs/superpowers/specs/2026-04-25-auto-invest-design.md`](docs/superpowers/specs/2026-04-25-auto-invest-design.md) for the full v1 design and the v1→v2→v3 phased path.

## What v1 does

Two cloud routines fire on a cron in Anthropic's Claude Code cloud:

| Routine | Cron (America/Chicago) | What it does |
|---|---|---|
| `pre-market` | `0 6 * * 1-5` | Reads memory, pulls paper-account state, researches via Perplexity, writes a dated entry to `memory/RESEARCH-LOG.md`, commits, pushes. Silent on Slack unless macro-urgent. |
| `daily-summary` | `0 15 * * 1-5` | Reads memory, pulls final state, appends EOD snapshot to `memory/TRADE-LOG.md`, commits, pushes, sends one Slack message (always, ≤15 lines). |

Each cron firing spins up a fresh Claude Code container that clones this repo at `main`, runs the routine prompt, writes memory back, and pushes. Git is the only durable state.

## Repo layout

```
CLAUDE.md                 # agent identity (auto-loaded by Claude Code)
README.md                 # this file
env.template              # env var documentation; copy to .env locally
.gitignore
.claude/commands/         # local-mode slash commands (portfolio, pre-market, daily-summary)
routines/                 # cloud-mode prompts (paste verbatim into the routine UI)
scripts/                  # bash wrappers — never curl APIs directly
memory/                   # agent's persistent state, committed to main
tests/                    # bash tests for wrapper safety paths
docs/source/              # reference docs (lessons, agentic spec, setup guide)
docs/superpowers/specs/   # design specs
docs/superpowers/plans/   # implementation plans
```

## Bootstrap (do this once)

You'll need three external accounts: Alpaca **paper** (free), Perplexity Sonar (paid), Slack (workspace + incoming webhook).

### 1. Local setup

```bash
# Activate the conda env that has gh authenticated
source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate base

# Clone (if you haven't already — this is the working tree)
cd /Users/dntounis/Documents/apps/auto_invest

# Copy the env template and fill in real credentials
cp env.template .env
$EDITOR .env

# Run the wrapper safety tests (no credentials needed)
bash tests/run_all.sh
# Expected: ALL TESTS PASSED
```

### 2. Local smoke test

Open this directory in Claude Code and run the read-only snapshot:

```
/portfolio
```

You should see your paper account equity (≈$100,000 — Alpaca's default paper balance), no positions, no open orders, and no errors. If you see an `ALPACA_*` not-set error, double-check `.env`.

### 3. Cloud routine setup

See [`routines/README.md`](routines/README.md). Two routines to create, both pointing at this repo on `main` with all env vars set in the routine UI (NOT a `.env` file).

### 4. Verify no secrets leaked

After your first push:
```bash
git log -- .env
# Expected: empty output (no commits ever touched .env)
```

## Operational discipline

- **Never** `curl` Alpaca/Perplexity/Slack directly. Always go through `scripts/*.sh`.
- **Never** create a `.env` file in cloud routines. Credentials come from process env vars set in the routine UI.
- **Never** `git push --force`. The routine prompts use `git pull --rebase` on conflict.
- **Never** flip `TRADING_ENABLED=true` until v1 exit criteria are met (5 clean weekdays of cron firings, no missed commits, no `.env` leaks). See spec § 11.

## Tests

```bash
bash tests/run_all.sh
```

Tests cover the safety-critical paths (env-var requirements, `TRADING_ENABLED` kill-switch, Slack fallback, JSON escaping). Real-API paths (Alpaca account fetch, Perplexity query, Slack POST) are covered by the local smoke test in step 2 above.

## License

Private. Not for distribution.

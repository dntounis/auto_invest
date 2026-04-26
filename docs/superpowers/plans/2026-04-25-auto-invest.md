# auto_invest v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the v1 (research-only, paper-trading) auto_invest agent per `docs/superpowers/specs/2026-04-25-auto-invest-design.md`: two cloud routines (`pre-market`, `daily-summary`), three bash wrappers (Alpaca paper API, Perplexity, Slack), five memory files, three local slash commands, and the GitHub remote wired up — committable & cloud-deployable.

**Architecture:** Pure bash + `curl` + stdlib Python. Same code runs locally (with `.env`) and in Anthropic's cloud routines (with process env vars). Git is the only durable state. The Alpaca wrapper has a wrapper-side `TRADING_ENABLED` kill-switch so order subcommands cannot fire in v1 even if the LLM tries.

**Tech Stack:** bash 3.2+ (macOS default), `curl`, system `python3` (stdlib only), `git`, `gh` (from user's conda `base` env), GitHub repo `dntounis/auto_invest`, Alpaca paper API, Perplexity Sonar API, Slack incoming webhook.

---

## File structure (created/modified by this plan)

**Created:**
```
docs/source/                           # 3 source docs moved here
docs/superpowers/plans/2026-04-25-auto-invest.md   # this file (already exists)
env.template                           # documents required env vars
README.md                              # human-facing bootstrap checklist
CLAUDE.md                              # agent identity, auto-loaded
.claude/commands/portfolio.md          # local read-only snapshot
.claude/commands/pre-market.md         # local mirror of pre-market routine
.claude/commands/daily-summary.md      # local mirror of daily-summary routine
routines/README.md                     # cloud routine setup notes
routines/pre-market.md                 # cron 0 6 * * 1-5  America/Chicago
routines/daily-summary.md              # cron 0 15 * * 1-5 America/Chicago
scripts/slack.sh                       # webhook POST + fallback
scripts/perplexity.sh                  # research wrapper, exit 3 fallback
scripts/alpaca.sh                      # paper account + kill-switched orders
memory/PROJECT-CONTEXT.md              # mission, mode flag, repo URL
memory/TRADING-STRATEGY.md             # rulebook
memory/RESEARCH-LOG.md                 # daily entries appended here
memory/TRADE-LOG.md                    # Day 0 baseline + EOD snapshots
memory/WEEKLY-REVIEW.md                # template only in v1
tests/test_slack.sh                    # fallback path, JSON escaping
tests/test_perplexity.sh               # exit-3 + arg validation
tests/test_alpaca.sh                   # env checks, kill-switch
tests/run_all.sh                       # runs all test files
```

**Modified:**
- `.gitignore` (extend with `DAILY-SUMMARY.md` and `tests/.tmp/`)

**Already present (from brainstorm phase):**
- `.git/` (initialized, on branch `main`, root commit `84209b7` is the spec)
- `.gitignore` (currently: `.env`, `.env.*`, `*.log`, `.DS_Store`)
- `docs/superpowers/specs/2026-04-25-auto-invest-design.md`

---

## Phase 0 — Repo bootstrapping

### Task 0: Move source docs into `docs/source/`

**Files:**
- Move: `automated_trading_agent_lessons.md` → `docs/source/`
- Move: `agentic_ai_system_steering_spec.md` → `docs/source/`
- Move: `Opus 4.7 Trading Bot — Setup Guide.pdf` → `docs/source/`

- [ ] **Step 1: Create the directory and move the three files**

```bash
mkdir -p docs/source
git mv automated_trading_agent_lessons.md docs/source/
git mv agentic_ai_system_steering_spec.md docs/source/
git mv "Opus 4.7 Trading Bot — Setup Guide.pdf" docs/source/
```

(Note: these aren't tracked by git yet — `git mv` will fall through to a regular `mv`. That's fine; we add them in step 2.)

- [ ] **Step 2: Verify the working tree is clean of stray top-level docs**

```bash
ls -la
```

Expected: only `.git`, `.gitignore`, `docs/`. No stray `.md` or `.pdf` at top level.

- [ ] **Step 3: Stage and commit**

```bash
git add docs/source/
git commit -m "chore: move source reference docs into docs/source/"
```

---

### Task 1: Connect to GitHub remote (do not push yet)

**Files:** none.

**Context for engineer:** The repo `dntounis/auto_invest` already exists on GitHub (created by the user). `gh` is authenticated in the user's conda `base` env. Activate it for any `gh` calls.

- [ ] **Step 1: Activate conda base env and verify gh auth**

```bash
source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate base
gh auth status
```

Expected: "Logged in to github.com account dntounis" (or similar). If not authenticated, stop and ask user to run `gh auth login` themselves.

- [ ] **Step 2: Verify the remote repo exists and is accessible**

```bash
gh repo view dntounis/auto_invest --json name,visibility,defaultBranchRef
```

Expected: JSON returned with `"name":"auto_invest"`. If the repo doesn't exist or isn't accessible, stop and surface the error to the user.

- [ ] **Step 3: Add the remote**

```bash
git remote add origin https://github.com/dntounis/auto_invest.git
git remote -v
```

Expected: `origin  https://github.com/dntounis/auto_invest.git (fetch)` and `(push)` lines.

- [ ] **Step 4: Confirm we are on `main` branch**

```bash
git branch --show-current
```

Expected: `main`. (Brainstorm phase already initialized with `-b main`.)

**Do not push yet.** First push happens in Task 18 after all v1 files are committed.

---

## Phase 1 — Test harness (write the safety net first)

### Task 2: Create the bash test runner

**Files:**
- Create: `tests/run_all.sh`
- Create: `tests/_lib.sh` (shared assertions)

- [ ] **Step 1: Write the shared assertion library**

Create `tests/_lib.sh`:
```bash
#!/usr/bin/env bash
# Shared test assertions. Source this from each test_*.sh.

set -uo pipefail

TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

start_test() {
    CURRENT_TEST="$1"
    echo "  - $CURRENT_TEST"
}

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "    FAIL: $1" >&2
}

assert_eq() {
    # assert_eq EXPECTED ACTUAL [MESSAGE]
    local expected="$1"
    local actual="$2"
    local msg="${3:-values not equal}"
    if [[ "$expected" == "$actual" ]]; then
        pass
    else
        fail "$msg: expected '$expected', got '$actual'"
    fi
}

assert_exit_code() {
    # assert_exit_code EXPECTED_CODE COMMAND_OUTPUT_VAR
    # Usage: out=$(some_cmd 2>&1) ; rc=$? ; assert_exit_code 4 "$rc"
    local expected="$1"
    local actual="$2"
    if [[ "$expected" == "$actual" ]]; then
        pass
    else
        fail "expected exit code $expected, got $actual"
    fi
}

assert_contains() {
    # assert_contains HAYSTACK NEEDLE [MESSAGE]
    local haystack="$1"
    local needle="$2"
    local msg="${3:-substring not found}"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass
    else
        fail "$msg: '$needle' not in output"
    fi
}

assert_file_exists() {
    local path="$1"
    if [[ -f "$path" ]]; then
        pass
    else
        fail "file does not exist: $path"
    fi
}

print_summary() {
    echo ""
    echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}
```

- [ ] **Step 2: Write the runner**

Create `tests/run_all.sh`:
```bash
#!/usr/bin/env bash
# Runs every tests/test_*.sh, reports summary, exits nonzero if any failed.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TOTAL_FAIL=0

for f in tests/test_*.sh; do
    [[ -f "$f" ]] || continue
    echo "=== $f ==="
    bash "$f" || TOTAL_FAIL=$((TOTAL_FAIL + 1))
    echo ""
done

if [[ $TOTAL_FAIL -gt 0 ]]; then
    echo "FAILED: $TOTAL_FAIL test file(s) had failures"
    exit 1
fi

echo "ALL TESTS PASSED"
```

- [ ] **Step 3: Make both executable**

```bash
chmod +x tests/run_all.sh tests/_lib.sh
```

- [ ] **Step 4: Run the runner with no test files yet (sanity check)**

```bash
bash tests/run_all.sh
```

Expected: `ALL TESTS PASSED` (the for-loop just no-ops when no `test_*.sh` files match).

- [ ] **Step 5: Commit**

```bash
git add tests/_lib.sh tests/run_all.sh
git commit -m "test: add bash test harness with shared assertions"
```

---

## Phase 2 — Slack wrapper (simplest wrapper first)

### Task 3: TDD `scripts/slack.sh` — fallback path

**Files:**
- Create: `tests/test_slack.sh`
- Create: `scripts/slack.sh`

**Context:** The Slack wrapper has two behaviors: (1) if `SLACK_WEBHOOK_URL` is set, POST `{"text": "msg"}` to it; (2) if unset, append to `DAILY-SUMMARY.md` with a timestamp header and exit 0. We test (2) first because it doesn't need a real webhook.

- [ ] **Step 1: Write the failing test for the fallback path**

Create `tests/test_slack.sh`:
```bash
#!/usr/bin/env bash
# Tests for scripts/slack.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp
TMPHOME="$(mktemp -d tests/.tmp/slack.XXXXXX)"

echo "test_slack.sh"

# Test 1: fallback path writes to DAILY-SUMMARY.md when webhook unset
start_test "fallback writes to DAILY-SUMMARY.md when SLACK_WEBHOOK_URL unset"
(
    cd "$TMPHOME"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset SLACK_WEBHOOK_URL
    out=$(bash scripts/slack.sh "hello world" 2>&1)
    rc=$?
    assert_exit_code 0 "$rc"
    assert_file_exists "DAILY-SUMMARY.md"
    body="$(cat DAILY-SUMMARY.md)"
    assert_contains "$body" "hello world"
    assert_contains "$body" "fallback — Slack not configured"
)

# Cleanup tmp
rm -rf tests/.tmp/slack.*

print_summary
```

```bash
chmod +x tests/test_slack.sh
```

- [ ] **Step 2: Run test to verify it fails (no script yet)**

```bash
bash tests/test_slack.sh
```

Expected: fails because `scripts/slack.sh` doesn't exist yet.

- [ ] **Step 3: Write the slack wrapper**

Create `scripts/slack.sh`:
```bash
#!/usr/bin/env bash
# Notification wrapper. Posts to a Slack incoming webhook channel.
# Usage: bash scripts/slack.sh "<message>"  (or pipe via stdin)
# Falls back to appending to DAILY-SUMMARY.md if SLACK_WEBHOOK_URL unset.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
FALLBACK="$ROOT/DAILY-SUMMARY.md"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

if [[ $# -gt 0 ]]; then
    msg="$*"
else
    msg="$(cat)"
fi

if [[ -z "${msg// /}" ]]; then
    echo "usage: bash scripts/slack.sh \"<message>\"" >&2
    exit 1
fi

stamp="$(date '+%Y-%m-%d %H:%M %Z')"

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
    {
        printf '\n---\n## %s (fallback — Slack not configured)\n%s\n' \
            "$stamp" "$msg"
    } >> "$FALLBACK"
    echo "[slack fallback] appended to DAILY-SUMMARY.md"
    exit 0
fi

payload="$(python3 -c "
import json, sys
print(json.dumps({'text': sys.argv[1]}))
" "$msg")"

curl -fsS -X POST \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "$SLACK_WEBHOOK_URL"
echo
```

```bash
chmod +x scripts/slack.sh
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test_slack.sh
```

Expected: `Results: 4 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/slack.sh tests/test_slack.sh
git commit -m "feat: add slack.sh wrapper with DAILY-SUMMARY.md fallback"
```

---

### Task 4: Add JSON-escape test for `slack.sh`

**Files:**
- Modify: `tests/test_slack.sh` (add a second test)

- [ ] **Step 1: Add the test**

Edit `tests/test_slack.sh` — insert this block before `print_summary`:
```bash
# Test 2: payload escaping handles awkward characters via fallback path
start_test "fallback preserves multi-line markdown content verbatim"
(
    TMP2="$(mktemp -d tests/.tmp/slack.XXXXXX)"
    cd "$TMP2"
    cp -r "$ROOT/scripts" .
    unset SLACK_WEBHOOK_URL
    msg=$'*EOD Apr 27* (paper)\nEquity: $10,012.40 (+0.12% day)\nNotes: "test" `code`'
    bash scripts/slack.sh "$msg" >/dev/null 2>&1
    body="$(cat DAILY-SUMMARY.md)"
    assert_contains "$body" "EOD Apr 27"
    assert_contains "$body" "Equity: \$10,012.40"
    assert_contains "$body" '"test"'
    assert_contains "$body" '`code`'
)
rm -rf tests/.tmp/slack.*
```

- [ ] **Step 2: Run test to verify it passes**

```bash
bash tests/test_slack.sh
```

Expected: `Results: 8 passed, 0 failed`.

- [ ] **Step 3: Commit**

```bash
git add tests/test_slack.sh
git commit -m "test: cover slack.sh content preservation in fallback path"
```

---

## Phase 3 — Perplexity wrapper

### Task 5: TDD `scripts/perplexity.sh` — exit 3 on missing key

**Files:**
- Create: `tests/test_perplexity.sh`
- Create: `scripts/perplexity.sh`

- [ ] **Step 1: Write the failing tests**

Create `tests/test_perplexity.sh`:
```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp

echo "test_perplexity.sh"

# Test 1: exits 3 with stderr warning if PERPLEXITY_API_KEY unset
start_test "exits 3 when PERPLEXITY_API_KEY is unset"
(
    TMP="$(mktemp -d tests/.tmp/ppx.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset PERPLEXITY_API_KEY
    out=$(bash scripts/perplexity.sh "anything" 2>&1)
    rc=$?
    assert_exit_code 3 "$rc"
    assert_contains "$out" "PERPLEXITY_API_KEY not set"
)

# Test 2: exits 1 with usage hint if no query passed
start_test "exits 1 with usage when called with no args"
(
    TMP="$(mktemp -d tests/.tmp/ppx.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    out=$(bash scripts/perplexity.sh 2>&1)
    rc=$?
    assert_exit_code 1 "$rc"
    assert_contains "$out" "usage"
)

rm -rf tests/.tmp/ppx.*
print_summary
```

```bash
chmod +x tests/test_perplexity.sh
```

- [ ] **Step 2: Run to verify it fails**

```bash
bash tests/test_perplexity.sh
```

Expected: fails (no script yet).

- [ ] **Step 3: Write the wrapper**

Create `scripts/perplexity.sh`:
```bash
#!/usr/bin/env bash
# Research wrapper. All market research goes through Perplexity.
# Usage: bash scripts/perplexity.sh "<query>"
# Exits 3 if PERPLEXITY_API_KEY is unset, so callers can fall back.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

query="${1:-}"
if [[ -z "$query" ]]; then
    echo "usage: bash scripts/perplexity.sh \"<query>\"" >&2
    exit 1
fi

if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
    echo "WARNING: PERPLEXITY_API_KEY not set. Fall back to native WebSearch." >&2
    exit 3
fi

MODEL="${PERPLEXITY_MODEL:-sonar}"

payload="$(python3 -c "
import json, sys
print(json.dumps({
    'model': sys.argv[1],
    'messages': [
        {'role': 'system', 'content': 'You are a precise financial research assistant. Cite every claim. Be concise.'},
        {'role': 'user', 'content': sys.argv[2]},
    ],
}))
" "$MODEL" "$query")"

curl -fsS https://api.perplexity.ai/chat/completions \
    -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload"
echo
```

```bash
chmod +x scripts/perplexity.sh
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test_perplexity.sh
```

Expected: `Results: 4 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/perplexity.sh tests/test_perplexity.sh
git commit -m "feat: add perplexity.sh research wrapper with exit-3 fallback"
```

---

## Phase 4 — Alpaca wrapper (the most safety-critical)

### Task 6: TDD `scripts/alpaca.sh` — env-var requirements & paper-endpoint enforcement

**Files:**
- Create: `tests/test_alpaca.sh`
- Create: `scripts/alpaca.sh`

**Context:** The Alpaca wrapper has the largest behavior surface. We test the safety paths first (no real API calls): missing env vars → exit 1; `ALPACA_ENDPOINT` unset → exit 1 (refuses to default to live URL); kill-switch refuses orders when `TRADING_ENABLED != "true"`.

- [ ] **Step 1: Write the failing tests**

Create `tests/test_alpaca.sh`:
```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"

cd "$ROOT"
mkdir -p tests/.tmp

echo "test_alpaca.sh"

# Test 1: refuses to run if ALPACA_API_KEY unset
start_test "exits 1 when ALPACA_API_KEY unset"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    unset ALPACA_API_KEY ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT TRADING_ENABLED
    out=$(bash scripts/alpaca.sh account 2>&1)
    rc=$?
    assert_exit_code 1 "$rc"
    assert_contains "$out" "ALPACA_API_KEY"
)

# Test 2: refuses to run if ALPACA_SECRET_KEY unset
start_test "exits 1 when ALPACA_SECRET_KEY unset"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy"
    unset ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT TRADING_ENABLED
    out=$(bash scripts/alpaca.sh account 2>&1)
    rc=$?
    assert_exit_code 1 "$rc"
    assert_contains "$out" "ALPACA_SECRET_KEY"
)

# Test 3: refuses to run if ALPACA_ENDPOINT unset (no defaulting to live URL)
start_test "exits 1 when ALPACA_ENDPOINT unset (no implicit live default)"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    unset ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT TRADING_ENABLED
    out=$(bash scripts/alpaca.sh account 2>&1)
    rc=$?
    assert_exit_code 1 "$rc"
    assert_contains "$out" "ALPACA_ENDPOINT"
)

# Test 4: refuses to run if ALPACA_DATA_ENDPOINT unset
start_test "exits 1 when ALPACA_DATA_ENDPOINT unset"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    unset ALPACA_DATA_ENDPOINT TRADING_ENABLED
    out=$(bash scripts/alpaca.sh account 2>&1)
    rc=$?
    assert_exit_code 1 "$rc"
    assert_contains "$out" "ALPACA_DATA_ENDPOINT"
)

# Test 5: kill-switch refuses 'order' when TRADING_ENABLED != true
start_test "exits 4 on 'order' subcommand when TRADING_ENABLED != true"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="false"
    out=$(bash scripts/alpaca.sh order '{"symbol":"X","qty":"1","side":"buy","type":"market","time_in_force":"day"}' 2>&1)
    rc=$?
    assert_exit_code 4 "$rc"
    assert_contains "$out" "TRADING_ENABLED"
)

# Test 6: kill-switch also refuses cancel/cancel-all/close/close-all
start_test "exits 4 on cancel-all when TRADING_ENABLED != true"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED=""
    out=$(bash scripts/alpaca.sh cancel-all 2>&1)
    rc=$?
    assert_exit_code 4 "$rc"
)

# Test 7: prints usage on bad subcommand
start_test "exits 1 with usage on bad subcommand"
(
    TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    out=$(bash scripts/alpaca.sh nonsense 2>&1)
    rc=$?
    assert_exit_code 1 "$rc"
    assert_contains "$out" "Usage"
)

rm -rf tests/.tmp/alp.*
print_summary
```

```bash
chmod +x tests/test_alpaca.sh
```

- [ ] **Step 2: Run to verify the tests fail**

```bash
bash tests/test_alpaca.sh
```

Expected: fails (no script yet).

- [ ] **Step 3: Write the wrapper**

Create `scripts/alpaca.sh`:
```bash
#!/usr/bin/env bash
# Alpaca API wrapper. All trading API calls go through here.
# Usage: bash scripts/alpaca.sh <subcommand> [args...]
#
# Read-only subcommands (always allowed):
#   account, positions, position SYM, quote SYM, orders [status]
#
# State-changing subcommands (gated by TRADING_ENABLED="true"):
#   order '<json>', cancel ORDER_ID, cancel-all, close SYM, close-all

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

# Required env vars — fail loudly, never silently default to live URLs.
: "${ALPACA_API_KEY:?ALPACA_API_KEY not set in environment}"
: "${ALPACA_SECRET_KEY:?ALPACA_SECRET_KEY not set in environment}"
: "${ALPACA_ENDPOINT:?ALPACA_ENDPOINT not set in environment (set to https://paper-api.alpaca.markets/v2 for paper, https://api.alpaca.markets/v2 for live)}"
: "${ALPACA_DATA_ENDPOINT:?ALPACA_DATA_ENDPOINT not set in environment (typically https://data.alpaca.markets/v2)}"

API="$ALPACA_ENDPOINT"
DATA="$ALPACA_DATA_ENDPOINT"

H_KEY="APCA-API-KEY-ID: $ALPACA_API_KEY"
H_SEC="APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY"

cmd="${1:-}"
shift || true

# Kill-switch helper for state-changing subcommands.
require_trading_enabled() {
    if [[ "${TRADING_ENABLED:-false}" != "true" ]]; then
        echo "REFUSED: TRADING_ENABLED is not 'true' (current: '${TRADING_ENABLED:-unset}'). Set TRADING_ENABLED=true to allow this subcommand." >&2
        exit 4
    fi
}

case "$cmd" in
    account)
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/account"
        ;;
    positions)
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/positions"
        ;;
    position)
        sym="${1:?usage: position SYM}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/positions/$sym"
        ;;
    quote)
        sym="${1:?usage: quote SYM}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$DATA/stocks/$sym/quotes/latest"
        ;;
    orders)
        status="${1:-open}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" "$API/orders?status=$status"
        ;;
    order)
        require_trading_enabled
        body="${1:?usage: order '<json>'}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
    cancel)
        require_trading_enabled
        oid="${1:?usage: cancel ORDER_ID}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/orders/$oid"
        ;;
    cancel-all)
        require_trading_enabled
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/orders"
        ;;
    close)
        require_trading_enabled
        sym="${1:?usage: close SYM}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/positions/$sym"
        ;;
    close-all)
        require_trading_enabled
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/positions"
        ;;
    *)
        echo "Usage: bash scripts/alpaca.sh <account|positions|position|quote|orders|order|cancel|cancel-all|close|close-all> [args]" >&2
        exit 1
        ;;
esac
echo
```

```bash
chmod +x scripts/alpaca.sh
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test_alpaca.sh
```

Expected: `Results: 14 passed, 0 failed`.

- [ ] **Step 5: Run the full test runner**

```bash
bash tests/run_all.sh
```

Expected: `ALL TESTS PASSED`.

- [ ] **Step 6: Commit**

```bash
git add scripts/alpaca.sh tests/test_alpaca.sh
git commit -m "feat: add alpaca.sh wrapper with kill-switch and required-endpoint guards"
```

---

### Task 7: Update `.gitignore` to exclude fallback file and tmp test artifacts

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Append entries**

Read `.gitignore` first to see current state, then append:
```
DAILY-SUMMARY.md
tests/.tmp/
```

The full file should read:
```
.env
.env.*
*.log
.DS_Store
DAILY-SUMMARY.md
tests/.tmp/
```

- [ ] **Step 2: Verify**

```bash
cat .gitignore
git status
```

Expected: `.gitignore` is modified (M), `DAILY-SUMMARY.md` (if created by tests) is no longer untracked.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore slack fallback file and test tmp dir"
```

---

## Phase 5 — `env.template`

### Task 8: Write `env.template`

**Files:**
- Create: `env.template`

- [ ] **Step 1: Write the file**

Create `env.template`:
```bash
# auto_invest — environment template
# Copy to .env locally and fill in your credentials. The .env file is gitignored.
# In cloud routines, set these as environment variables on the routine config — DO NOT create a .env file in the cloud.

# --- Alpaca (PAPER trading in v1) ---------------------------------
# Paper account: get keys from https://alpaca.markets/ (paper dashboard)
ALPACA_API_KEY=your_alpaca_paper_api_key_here
ALPACA_SECRET_KEY=your_alpaca_paper_secret_key_here

# Endpoint MUST be set explicitly. No defaulting to live URL.
# Paper: https://paper-api.alpaca.markets/v2
# Live:  https://api.alpaca.markets/v2  (do NOT use until v3)
ALPACA_ENDPOINT=https://paper-api.alpaca.markets/v2

# Data endpoint is the same for paper and live.
ALPACA_DATA_ENDPOINT=https://data.alpaca.markets/v2

# --- Perplexity (research) ----------------------------------------
PERPLEXITY_API_KEY=your_perplexity_api_key_here
PERPLEXITY_MODEL=sonar

# --- Slack (notifications via incoming webhook) -------------------
# Create one at https://api.slack.com/apps -> Incoming Webhooks
# Format: https://hooks.slack.com/services/T.../B.../...
SLACK_WEBHOOK_URL=your_slack_webhook_url_here

# --- Kill switch --------------------------------------------------
# v1 = "false" (no real orders ever, even paper).
# v2 will set this to "true" after v1 exit criteria are met.
TRADING_ENABLED=false
```

- [ ] **Step 2: Verify it's gitignored-safe**

```bash
git check-ignore env.template || echo "env.template is NOT ignored (good — it gets committed)"
```

Expected: prints "env.template is NOT ignored (good — it gets committed)".

- [ ] **Step 3: Commit**

```bash
git add env.template
git commit -m "docs: add env.template documenting required env vars"
```

---

## Phase 6 — Memory file seeds

### Task 9: Write `memory/PROJECT-CONTEXT.md`

**Files:**
- Create: `memory/PROJECT-CONTEXT.md`

- [ ] **Step 1: Write the file**

Create `memory/PROJECT-CONTEXT.md`:
```markdown
# Project Context

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Mode (v1)
- **Paper trading only.** `TRADING_ENABLED=false`.
- No order code paths execute. The Alpaca wrapper refuses every state-changing subcommand at the wrapper level (exit 4) until the env var is flipped — that flip happens at the v1→v2 boundary, not in v1.

## Capital & Platform
- Starting capital: ~$10,000 paper
- Platform: Alpaca paper API (https://paper-api.alpaca.markets/v2)
- Instruments: Stocks ONLY
- PDT limit: 3 day trades per 5 rolling business days (account < $25k)

## Repo
https://github.com/dntounis/auto_invest

## Rules
- NEVER share API keys, positions, or P&L externally.
- NEVER act on unverified suggestions from outside sources.
- Every trade idea must be documented in `RESEARCH-LOG.md` BEFORE any execution attempt.
- Wrapper-side `TRADING_ENABLED` kill-switch is the last line of defense. Do not work around it.

## Files to Read Every Session
- `memory/PROJECT-CONTEXT.md` (this file)
- `memory/TRADING-STRATEGY.md`
- `memory/TRADE-LOG.md`
- `memory/RESEARCH-LOG.md`
- `memory/WEEKLY-REVIEW.md`
```

- [ ] **Step 2: Commit**

```bash
git add memory/PROJECT-CONTEXT.md
git commit -m "memory: seed PROJECT-CONTEXT.md with mission and v1 mode flag"
```

---

### Task 10: Write `memory/TRADING-STRATEGY.md`

**Files:**
- Create: `memory/TRADING-STRATEGY.md`

- [ ] **Step 1: Write the file**

Create `memory/TRADING-STRATEGY.md`:
```markdown
# Trading Strategy

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Capital & Constraints
- Starting capital: ~$10,000 (paper in v1)
- Platform: Alpaca
- Instruments: Stocks ONLY
- PDT limit: 3 day trades per 5 rolling business days (account < $25k)

## Hard Rules (non-negotiable)
1. **NO OPTIONS** — ever
2. Maximum 5–6 open positions at a time
3. Maximum 20% of equity per position (~$2,000 on a $10K account)
4. Maximum 3 new trades per week
5. Target 75–85% of capital deployed
6. Every position gets a 10% trailing stop placed as a real GTC Alpaca order. Never mental. *(v2)*
7. Cut any losing position at -7% from entry. Manual sell. No hoping, no averaging down. *(v2)*
8. Tighten the trailing stop to 7% when a position is up +15%. Tighten to 5% when up +20%. *(v2)*
9. Never tighten a stop to within 3% of current price. Never move a stop down. *(v2)*
10. Exit an entire sector after 2 consecutive failed trades in that sector. *(v2)*
11. Follow sector momentum. Don't force a thesis if the whole sector is rolling over.
12. **Patience > activity.** A week with zero trades can be the right answer.

## Buy-Side Gate
Before placing any buy order, every one of these must pass. If any fail, the trade is skipped and the reason is logged. *(In v1: pre-market filters trade ideas through this gate. v2's market-open enforces it before orders.)*
- Total positions after this fill ≤ 6
- Trades placed this week (including this one) ≤ 3
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- `daytrade_count` leaves room (PDT: 3/5 rolling business days under $25k)
- A specific catalyst is documented in today's `RESEARCH-LOG.md` entry
- The instrument is a stock (not an option, not anything else)

## Sell-Side Rules *(v2 — evaluated at midday and opportunistically)*
- If unrealized loss is -7% or worse, close immediately.
- If the thesis has broken (catalyst invalidated, sector rolling over, news event), close, even if not yet at -7%.
- If position is up +20% or more, tighten trailing stop to 5%.
- If position is up +15% or more, tighten trailing stop to 7%.
- If a sector has two consecutive failed trades, exit all positions in that sector.

## Entry Checklist
Before documenting any trade idea in `RESEARCH-LOG.md`:
- What is the specific catalyst today?
- Is the sector in momentum?
- What is the stop level (7–10% below entry)?
- What is the target (minimum 2:1 risk/reward)?

## Strategy Update Cadence
This file is updated **only by the Friday weekly-review routine** (v2), and only if a rule has proven itself for 2+ weeks or failed badly. The pre-market and daily-summary routines (v1) read this file but do not modify it.
```

- [ ] **Step 2: Commit**

```bash
git add memory/TRADING-STRATEGY.md
git commit -m "memory: seed TRADING-STRATEGY.md rulebook from lessons doc"
```

---

### Task 11: Write `memory/RESEARCH-LOG.md`

**Files:**
- Create: `memory/RESEARCH-LOG.md`

- [ ] **Step 1: Write the file**

Create `memory/RESEARCH-LOG.md`:
```markdown
# Research Log

Daily pre-market research entries are appended below by the `pre-market` routine.

## Entry Schema

```
## YYYY-MM-DD — Pre-market Research

### Account
- Equity: $X
- Cash: $X
- Buying power: $X
- Daytrade count: N

### Market Context
- WTI / Brent oil:
- S&P 500 futures:
- VIX:
- Today's catalysts:
- Earnings before open:
- Economic calendar:
- Sector momentum:

### Trade Ideas
1. TICKER — catalyst, entry $X, stop $X, target $X, R:R X:1
2. ...

### Risk Factors
- ...

### Decision
TRADE or HOLD (default HOLD if no edge)

### Sources
- Perplexity citations: <list>
- WebSearch fallback used: yes/no (which queries)
```

---

<!-- Daily entries appended below this line -->
```

- [ ] **Step 2: Commit**

```bash
git add memory/RESEARCH-LOG.md
git commit -m "memory: seed RESEARCH-LOG.md with entry schema"
```

---

### Task 12: Write `memory/TRADE-LOG.md` with Day 0 baseline

**Files:**
- Create: `memory/TRADE-LOG.md`

**Context:** The Day 0 baseline is required so the first `daily-summary` run has a previous-day equity to diff against. Use $10,000 as the planning baseline; the agent will reconcile against the actual paper-account equity on its first run.

- [ ] **Step 1: Write the file**

Create `memory/TRADE-LOG.md`:
```markdown
# Trade Log

Trades and end-of-day snapshots are appended here.

In v1, only EOD snapshots are written (by the `daily-summary` routine). Trade rows are added in v2 by `market-open` and `midday`.

## Entry Schemas

### Trade row (v2)
```
### YYYY-MM-DD — TRADE: TICKER side=buy|sell qty=N
- Entry: $X (or Exit: $X)
- Stop level: $X (trailing N% / fixed $X)
- Thesis: ...
- Catalyst: ... (link to RESEARCH-LOG entry)
- Target: $X (R:R X:1)
- Realized P&L (on exits only): $X
```

### EOD snapshot (v1)
```
### MMM DD — EOD Snapshot (Day N, Weekday)
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** ±$X (±X%) | **Phase P&L:** ±$X (±X%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |

**Notes:** one-paragraph plain-english summary.
```

---

## Day 0 — EOD Snapshot (pre-launch baseline)
**Portfolio:** $10,000.00 | **Cash:** $10,000.00 (100%) | **Day P&L:** $0.00 (0.00%) | **Phase P&L:** $0.00 (0.00%)

No positions yet. v1 launches on the next weekday's `pre-market` routine. The `daily-summary` routine will reconcile this baseline against the actual paper-account equity on Day 1.

<!-- New EOD snapshots appended below -->
```

- [ ] **Step 2: Commit**

```bash
git add memory/TRADE-LOG.md
git commit -m "memory: seed TRADE-LOG.md with Day 0 baseline and entry schemas"
```

---

### Task 13: Write `memory/WEEKLY-REVIEW.md` template

**Files:**
- Create: `memory/WEEKLY-REVIEW.md`

- [ ] **Step 1: Write the file**

Create `memory/WEEKLY-REVIEW.md`:
```markdown
# Weekly Review

Friday weekly reviews are appended below by the `weekly-review` routine *(v2)*. **No entries in v1.**

## Entry Template

```
## Week ending YYYY-MM-DD

### Stats
| Metric | Value |
|--------|-------|
| Starting portfolio | $X |
| Ending portfolio | $X |
| Week return | ±$X (±X%) |
| S&P 500 week | ±X% |
| Bot vs S&P | ±X% |
| Trades | N (W:X / L:Y / open:Z) |
| Win rate | X% |
| Best trade | SYM +X% |
| Worst trade | SYM -X% |
| Profit factor | X.XX |

### Closed Trades
| Ticker | Entry | Exit | P&L | Notes |

### Open Positions at Week End
| Ticker | Entry | Close | Unrealized | Stop |

### What Worked
- ...

### What Didn't Work
- ...

### Key Lessons
- ...

### Adjustments for Next Week
- ...

### Overall Grade: X
```

---

<!-- Weekly entries appended below -->
```

- [ ] **Step 2: Commit**

```bash
git add memory/WEEKLY-REVIEW.md
git commit -m "memory: seed WEEKLY-REVIEW.md with v2 template"
```

---

## Phase 7 — `CLAUDE.md`

### Task 14: Write `CLAUDE.md`

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write the file**

Create `CLAUDE.md`:
```markdown
# auto_invest — Agent Instructions

You are an autonomous AI trading bot managing a **paper** ~$10,000 Alpaca account. Goal: beat the S&P 500 over the challenge window. Stocks only — **no options, ever.** Communicate ultra-concise: short bullets, no preamble, no fluff.

## Mode (v1)
- **Paper only.** `TRADING_ENABLED=false`.
- Wrapper-side kill-switch in `scripts/alpaca.sh` refuses every state-changing subcommand (exit 4). Do not attempt to work around it. v1 routines do not need it.

## Read-Me-First (every session)
Open these in order before doing anything else:
1. `memory/PROJECT-CONTEXT.md` — mission, mode, repo
2. `memory/TRADING-STRATEGY.md` — the rulebook (never violate)
3. `memory/TRADE-LOG.md` — tail for last EOD snapshot, entries (v2), stops (v2)
4. `memory/RESEARCH-LOG.md` — today's research before any reasoning about ideas
5. `memory/WEEKLY-REVIEW.md` — Friday template (v2)

## Daily Workflows
Local mirrors live in `.claude/commands/`. Cloud production prompts live in `routines/`. v1 active routines:
- `pre-market` — research only, writes `RESEARCH-LOG.md`, silent unless macro-urgent
- `daily-summary` — EOD snapshot, writes `TRADE-LOG.md`, sends ONE Slack message

v2 will add `market-open`, `midday`, `weekly-review`.

## Strategy Hard Rules (quick reference)
- NO OPTIONS — ever
- Max 5–6 open positions, max 20% per position
- Max 3 new trades per week
- 75–85% capital deployed
- 10% trailing stop on every position as a real GTC order *(v2)*
- Cut losers at -7% manually *(v2)*
- Tighten trail to 7% at +15%, 5% at +20% *(v2)*
- Never within 3% of current price; never move a stop down *(v2)*
- Follow sector momentum; exit a sector after 2 failed trades *(v2)*
- Patience > activity

## API Wrappers
**Always** use these. Never `curl` Alpaca / Perplexity / Slack APIs directly.
- `bash scripts/alpaca.sh <subcommand>` — paper account state and (gated) orders
- `bash scripts/perplexity.sh "<query>"` — research; exits 3 if key unset → fall back to native `WebSearch` and flag in research log
- `bash scripts/slack.sh "<message>"` — webhook notification; falls back to `DAILY-SUMMARY.md` if webhook unset

## Secrets Discipline
- **Never create, write, or source a `.env` file** in cloud routines. Credentials come from process env vars set in the routine UI.
- If a wrapper prints `KEY not set in environment` in cloud, **stop and notify via Slack**. Do NOT create a `.env` as a workaround.
- Never log secrets. Never print API keys.

## Communication Style
Ultra-concise. No preamble. Short bullets. Match existing memory file formats exactly — don't reinvent tables.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md agent identity and operating instructions"
```

---

## Phase 8 — Local-mode slash commands

### Task 15: Write `.claude/commands/portfolio.md`

**Files:**
- Create: `.claude/commands/portfolio.md`

- [ ] **Step 1: Write the file**

Create `.claude/commands/portfolio.md`:
```markdown
---
description: Read-only snapshot of paper account, positions, open orders, and stops
---

Print a clean ad-hoc snapshot. **No state changes, no orders, no file writes.**

1. `bash scripts/alpaca.sh account`
2. `bash scripts/alpaca.sh positions`
3. `bash scripts/alpaca.sh orders`

Format the output as a single concise summary:

```
Portfolio — <today's date> (paper)
Equity: $X | Cash: $X (X%) | Buying power: $X
Daytrade count: N | PDT: <true/false>

Positions:
  SYM | Sh | Entry → Now | Unrealized P&L | Stop

Open orders:
  TYPE | SYM | qty | trail/stop | order_id
```

No commentary unless something is genuinely broken (e.g. a position without a stop, a stop below current price). Keep output ≤ 25 lines.
```

- [ ] **Step 2: Commit**

```bash
mkdir -p .claude/commands
git add .claude/commands/portfolio.md
git commit -m "feat: add /portfolio local slash command"
```

---

### Task 16: Write `.claude/commands/pre-market.md`

**Files:**
- Create: `.claude/commands/pre-market.md`

**Context:** This is the local mirror of the cloud `pre-market` routine. It has the same work steps but **no env-var preamble** (local `.env` handles credentials) and **no commit/push step** (you commit by hand when iterating locally).

- [ ] **Step 1: Write the file**

Create `.claude/commands/pre-market.md`:
```markdown
---
description: Pre-market research run (local mirror of cloud routine; no commit/push)
---

You are running the **pre-market research workflow** locally. Resolve today's date with `DATE=$(date +%Y-%m-%d)`.

This is a v1 paper-only research run. **No orders execute.** The Alpaca wrapper refuses state-changing subcommands.

## Step 1 — Read memory for context
- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md`
- Tail of `memory/TRADE-LOG.md`
- Tail of `memory/RESEARCH-LOG.md`

## Step 2 — Pull live paper-account state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders
```

## Step 3 — Research market context via Perplexity
Run `bash scripts/perplexity.sh "<query>"` for each:
- "WTI and Brent oil price right now"
- "S&P 500 futures premarket today"
- "VIX level today"
- "Top stock market catalysts today $DATE"
- "Earnings reports today before market open"
- "Economic calendar today (CPI/PPI/FOMC/jobs data)"
- "S&P 500 sector momentum YTD"
- News on each currently-held ticker (in v1 there are no held positions — skip this)

If `perplexity.sh` exits 3, fall back to native `WebSearch` and **flag the fallback in the research-log entry** ("Sources: WebSearch fallback used for queries: ...").

## Step 4 — Append a dated entry to `memory/RESEARCH-LOG.md`
Use the entry schema documented at the top of `RESEARCH-LOG.md`. Include:
- Account snapshot (equity, cash, buying power, daytrade count)
- Market context (oil, indices, VIX, today's releases)
- 2–3 actionable trade ideas with catalyst + entry + stop + target + R:R
- Risk factors for the day
- Decision: TRADE or HOLD (default HOLD — patience > activity)
- Sources section with Perplexity citations and any WebSearch fallback flags

## Step 5 — No notification by default
Local mode is interactive — you'll see the result in the chat. No Slack call needed unless you want to test the path.

## Step 6 — Skip commit
Local mode does not auto-commit. Review the appended entry in `memory/RESEARCH-LOG.md` and commit by hand if it's worth keeping.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/commands/pre-market.md
git commit -m "feat: add /pre-market local slash command"
```

---

### Task 17: Write `.claude/commands/daily-summary.md`

**Files:**
- Create: `.claude/commands/daily-summary.md`

- [ ] **Step 1: Write the file**

Create `.claude/commands/daily-summary.md`:
```markdown
---
description: End-of-day summary (local mirror of cloud routine; no commit/push)
---

You are running the **daily-summary workflow** locally. Resolve today's date with `DATE=$(date +%Y-%m-%d)`.

This is a v1 paper-only run. No trades fired today (v1 = research only). EOD snapshot is the only output.

## Step 1 — Read memory for continuity
- Tail of `memory/TRADE-LOG.md` — find the most recent EOD snapshot to get yesterday's equity (needed for Day P&L)
- Today's `memory/RESEARCH-LOG.md` entry (if present)

## Step 2 — Pull final state of the day
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders
```

## Step 3 — Compute metrics
- Day P&L ($ and %) = today's equity − yesterday's equity (from prior EOD snapshot or Day 0 baseline)
- Phase cumulative P&L ($ and %) = today's equity − $10,000 starting baseline
- Trades today: always "none" in v1
- Trades this week (running total): always 0 in v1

## Step 4 — Append EOD snapshot to `memory/TRADE-LOG.md`
Use the schema at the top of `TRADE-LOG.md`:
```
### MMM DD — EOD Snapshot (Day N, Weekday)
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** ±$X (±X%) | **Phase P&L:** ±$X (±X%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |

**Notes:** one-paragraph plain-english summary (e.g. "Quiet session, no trades fired, equity unchanged from market drift").
```

## Step 5 — Send ONE Slack message via `slack.sh`
≤ 15 lines. Always include the `(paper)` suffix. Sample:
```
bash scripts/slack.sh "*EOD MMM DD* (paper)
Equity: \$X (±X% day, ±X% phase)
Cash: \$X
Trades today: none (v1 research only)
Open positions: none
Pre-market plan today: <decision from research log>
Tomorrow: pre-market checks at 6:00 CT"
```

(Locally, if `SLACK_WEBHOOK_URL` is unset in `.env`, the wrapper appends to `DAILY-SUMMARY.md` and exits 0 — that's expected behavior for local testing.)

## Step 6 — Skip commit
Local mode does not auto-commit. Review the appended snapshot and commit by hand if it's worth keeping.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/commands/daily-summary.md
git commit -m "feat: add /daily-summary local slash command"
```

---

## Phase 9 — Cloud routine prompts

### Task 18: Write `routines/README.md`

**Files:**
- Create: `routines/README.md`

- [ ] **Step 1: Write the file**

Create `routines/README.md`:
```markdown
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
```

- [ ] **Step 2: Commit**

```bash
mkdir -p routines
git add routines/README.md
git commit -m "docs: add routines/README.md with cloud setup walkthrough"
```

---

### Task 19: Write `routines/pre-market.md`

**Files:**
- Create: `routines/pre-market.md`

**Context:** This is the prompt that gets pasted **verbatim** into the cloud routine UI. The env-var-check block, the persistence warning, and the commit/push step are all load-bearing — never paraphrase.

- [ ] **Step 1: Write the file**

Create `routines/pre-market.md`:
````markdown
You are an autonomous AI trading bot managing a **paper** ~$10,000 Alpaca account.
Hard rule: stocks only — **NEVER touch options.** Ultra-concise: short bullets, no preamble, no fluff.

You are running the **pre-market research workflow** (v1, paper, research-only).
Resolve today's date via:
```
DATE=$(date +%Y-%m-%d)
```

## IMPORTANT — ENVIRONMENT VARIABLES

- Every API key is ALREADY exported as a process env var:
  `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `ALPACA_ENDPOINT`, `ALPACA_DATA_ENDPOINT`,
  `PERPLEXITY_API_KEY`, `PERPLEXITY_MODEL`, `SLACK_WEBHOOK_URL`, `TRADING_ENABLED`.
- There is NO `.env` file in this repo and you MUST NOT create, write, or source one.
  The wrapper scripts read directly from the process env.
- If a wrapper prints `"KEY not set in environment"` → STOP, send one Slack alert
  naming the missing var via `bash scripts/slack.sh "<msg>"`, then exit. Do NOT
  create a `.env` as a workaround.
- Verify env vars BEFORE any wrapper call:
```
for v in ALPACA_API_KEY ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT \
         PERPLEXITY_API_KEY SLACK_WEBHOOK_URL TRADING_ENABLED; do
    [[ -n "${!v:-}" ]] && echo "$v: set" || echo "$v: MISSING"
done
```
- Sanity check: `ALPACA_ENDPOINT` MUST contain `paper-api.alpaca.markets` in v1.
  If it contains `api.alpaca.markets` (without `paper-`), STOP, Slack-alert, exit.

## IMPORTANT — PERSISTENCE

- This workspace is a fresh clone. File changes VANISH unless you commit and push to `main`.
- You MUST `git add` + `git commit` + `git push origin main` at STEP 6.

## IMPORTANT — KILL SWITCH

- v1 has `TRADING_ENABLED=false`. The Alpaca wrapper will refuse `order`, `cancel`,
  `cancel-all`, `close`, `close-all` with exit 4. You will not call those subcommands
  in this routine — only `account`, `positions`, `orders`. If you accidentally call
  a state-changing subcommand and get exit 4, that is the kill-switch working
  correctly. Log it in the research entry as a behavior anomaly and continue.

---

## STEP 1 — Read memory for context

- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md`
- Tail of `memory/TRADE-LOG.md` (last EOD snapshot)
- Tail of `memory/RESEARCH-LOG.md` (yesterday's entry)

## STEP 2 — Pull live paper-account state

```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders
```

## STEP 3 — Research market context via Perplexity

Run `bash scripts/perplexity.sh "<query>"` for each:

- "WTI and Brent oil price right now"
- "S&P 500 futures premarket today"
- "VIX level today"
- "Top stock market catalysts today $DATE"
- "Earnings reports today before market open"
- "Economic calendar today (CPI/PPI/FOMC/jobs data)"
- "S&P 500 sector momentum YTD"
- News on each currently-held ticker (in v1 there are no held positions — skip this query)

If `perplexity.sh` exits 3, fall back to native `WebSearch` and **flag the fallback
in the research-log entry's Sources section.**

## STEP 4 — Write a dated entry to `memory/RESEARCH-LOG.md`

Use the schema documented at the top of `RESEARCH-LOG.md`. Include:

- **Account snapshot:** equity, cash, buying power, daytrade count
- **Market context:** oil, indices, VIX, today's releases, sector momentum
- **2–3 actionable trade ideas:** TICKER — catalyst, entry $X, stop $X, target $X, R:R X:1
  - Each idea must satisfy the buy-side gate in `TRADING-STRATEGY.md` (≤6 positions,
    ≤3 trades/week, ≤20% equity, sector momentum aligned, etc.). Skip ideas that fail.
- **Risk factors:** macro, sector, idiosyncratic
- **Decision:** TRADE or HOLD (default HOLD — patience > activity)
- **Sources:** Perplexity citations + any WebSearch fallback flags

> v1 reminder: trade ideas are documented for tracking only. The kill-switch
> prevents execution. v2 will hand these ideas to a separate `market-open` routine.

## STEP 5 — Notification: silent unless macro-urgent

Send a Slack message ONLY if a major macro event broke (geopolitical, big macro
release surprise) that would require immediate human attention. Otherwise: silent.

If urgent:
```
bash scripts/slack.sh "*Pre-market URGENT $DATE* (paper) — <one-line reason>"
```

## STEP 6 — COMMIT AND PUSH (mandatory)

```
git add memory/RESEARCH-LOG.md
git commit -m "pre-market research $DATE"
git push origin main
```

On push failure (non-fast-forward / divergence):
```
git pull --rebase origin main
git push origin main
```

**Never use `--force` or `--force-with-lease`.** If the rebase has actual conflicts
(extremely unlikely with append-only entries), Slack-alert and stop — do not
overwrite another run's memory.
````

- [ ] **Step 2: Commit**

```bash
git add routines/pre-market.md
git commit -m "feat: add cloud pre-market routine prompt"
```

---

### Task 20: Write `routines/daily-summary.md`

**Files:**
- Create: `routines/daily-summary.md`

- [ ] **Step 1: Write the file**

Create `routines/daily-summary.md`:
````markdown
You are an autonomous AI trading bot managing a **paper** ~$10,000 Alpaca account.
Stocks only — NEVER options. Ultra-concise.

You are running the **daily-summary workflow** (v1, paper, EOD snapshot only).
Resolve today's date via:
```
DATE=$(date +%Y-%m-%d)
```

## IMPORTANT — ENVIRONMENT VARIABLES

- Required process env vars:
  `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `ALPACA_ENDPOINT`, `ALPACA_DATA_ENDPOINT`,
  `SLACK_WEBHOOK_URL`, `TRADING_ENABLED`. (Perplexity is not used by this routine.)
- There is NO `.env` file in this repo and you MUST NOT create, write, or source one.
- If a wrapper prints `"KEY not set in environment"` → STOP, send one Slack alert
  naming the missing var via `bash scripts/slack.sh "<msg>"`, then exit. Do NOT
  create a `.env` as a workaround.
- Verify env vars BEFORE any wrapper call:
```
for v in ALPACA_API_KEY ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT \
         SLACK_WEBHOOK_URL TRADING_ENABLED; do
    [[ -n "${!v:-}" ]] && echo "$v: set" || echo "$v: MISSING"
done
```
- Sanity check: `ALPACA_ENDPOINT` MUST contain `paper-api.alpaca.markets` in v1.

## IMPORTANT — PERSISTENCE

- Fresh clone. File changes VANISH unless committed and pushed to `main`.
- You MUST commit and push at STEP 6. **This commit is mandatory** — tomorrow's Day P&L
  math depends on this snapshot persisting.

## IMPORTANT — KILL SWITCH

- v1 has `TRADING_ENABLED=false`. This routine never calls state-changing Alpaca
  subcommands; it is purely read-only state + computation + log append.

---

## STEP 1 — Read memory for continuity

- Tail of `memory/TRADE-LOG.md` — find the most recent EOD snapshot to extract
  **yesterday's equity** (this is needed for Day P&L). On Day 1, the source is the
  Day 0 baseline ($10,000.00).
- Today's entry in `memory/RESEARCH-LOG.md` (if present) — used for the
  one-line "pre-market plan today" in the Slack message.

## STEP 2 — Pull final state of the day

```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders
```

## STEP 3 — Compute metrics

- **Day P&L** ($ and %) = today's equity − yesterday's equity from STEP 1
- **Phase cumulative P&L** ($ and %) = today's equity − $10,000 starting baseline
- **Trades today**: always "none" in v1 (no order code runs)
- **Trades this week** running total: always 0 in v1

## STEP 4 — Append EOD snapshot to `memory/TRADE-LOG.md`

Match the schema at the top of `TRADE-LOG.md` exactly:
```
### MMM DD — EOD Snapshot (Day N, Weekday)
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** ±$X (±X%) | **Phase P&L:** ±$X (±X%)

| Ticker | Shares | Entry | Close | Day Chg | Unrealized P&L | Stop |

**Notes:** one-paragraph plain-english summary.
```

In v1 the positions table will be empty (or just a "No positions" row). Notes should
mention what the morning's research said and whether anything notable happened.

## STEP 5 — Send ONE Slack message (always)

≤ 15 lines. Always include the `(paper)` suffix in v1.

```
bash scripts/slack.sh "*EOD <MMM DD>* (paper)
Equity: \$<X> (<±X%> day, <±X%> phase)
Cash: \$<X>
Trades today: none (v1 research only)
Open positions: none
Pre-market plan today: <decision from today's research log>
Tomorrow: pre-market checks at 6:00 CT"
```

If `SLACK_WEBHOOK_URL` is unset, the wrapper falls back to `DAILY-SUMMARY.md`
(gitignored). That fallback should never trigger in cloud — if it does, the env var
is missing; treat it as a routine failure and stop.

## STEP 6 — COMMIT AND PUSH (mandatory)

```
git add memory/TRADE-LOG.md
git commit -m "EOD snapshot $DATE"
git push origin main
```

On push failure: `git pull --rebase origin main` then push again. Never `--force`.
````

- [ ] **Step 2: Commit**

```bash
git add routines/daily-summary.md
git commit -m "feat: add cloud daily-summary routine prompt"
```

---

## Phase 10 — README

### Task 21: Write `README.md` (project root)

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write the file**

Create `README.md`:
```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with bootstrap checklist and operational discipline"
```

---

## Phase 11 — Final verification before push

### Task 22: Sanity-sweep the working tree

**Files:** none (read-only checks).

- [ ] **Step 1: Confirm tree structure matches the spec**

```bash
ls -la
ls -la docs/ memory/ scripts/ tests/ routines/ .claude/commands/
```

Expected directories present: `docs/source/`, `docs/superpowers/specs/`, `docs/superpowers/plans/`, `memory/`, `scripts/`, `tests/`, `routines/`, `.claude/commands/`. Expected top-level files: `CLAUDE.md`, `README.md`, `env.template`, `.gitignore`.

- [ ] **Step 2: Confirm scripts are executable**

```bash
ls -l scripts/*.sh tests/*.sh
```

Expected: all `.sh` files have an `x` permission bit.

- [ ] **Step 3: Run the full test suite once more**

```bash
bash tests/run_all.sh
```

Expected: `ALL TESTS PASSED`.

- [ ] **Step 4: Confirm no `.env` is tracked**

```bash
git ls-files | grep -E "(^|/)\.env" && echo "LEAK!" || echo "OK: no .env tracked"
```

Expected: `OK: no .env tracked`.

- [ ] **Step 5: Confirm `env.template` IS tracked**

```bash
git ls-files | grep "^env.template$"
```

Expected: prints `env.template`.

- [ ] **Step 6: View the commit log to confirm history is clean**

```bash
git log --oneline
```

Expected: roughly 18–22 commits, all sensibly named, none containing secrets in their messages or diffs.

---

### Task 23: First push to GitHub

**Files:** none.

- [ ] **Step 1: Activate conda base env**

```bash
source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate base
gh auth status
```

Expected: authenticated as `dntounis`.

- [ ] **Step 2: Push `main` to origin with upstream tracking**

```bash
git push -u origin main
```

Expected: push succeeds, `Branch 'main' set up to track remote branch 'main' from 'origin'.`

If push fails because the remote has its own initial commit (e.g. an auto-created `README` or `.gitignore` from GitHub's UI), do:
```bash
git pull --rebase origin main
# resolve any trivial conflicts (likely none if the remote was empty)
git push -u origin main
```

If `gh repo view` from Task 1 showed the remote has a `defaultBranchRef`, the remote has been initialized — pull-rebase will be needed.

- [ ] **Step 3: Verify on GitHub**

```bash
gh repo view dntounis/auto_invest --json defaultBranchRef,pushedAt
gh browse
```

Expected: `gh browse` opens the repo in the default browser. Confirm visually that `CLAUDE.md`, `README.md`, `routines/`, `scripts/`, etc. are all present at HEAD on `main`.

---

## Phase 12 — User-driven operational gates (manual, not codable)

These are **not** for the implementing engineer to execute. They are for the user (Dimitris) to perform after the code is pushed. The plan documents them so the implementing engineer knows when to stop and hand off.

### Task 24 (USER): Local smoke test

**To be done by user, in Claude Code interactive session:**

1. Get Alpaca paper API keys from https://alpaca.markets/ (paper dashboard)
2. Get Perplexity API key from https://www.perplexity.ai/settings/api
3. Create a Slack incoming webhook at https://api.slack.com/apps → New App → Incoming Webhooks → Add New Webhook to Workspace → pick the channel
4. `cp env.template .env`, paste all credentials in
5. Open the project in Claude Code, run `/portfolio`. Should see paper account snapshot with no errors.
6. Optionally run `/pre-market` and `/daily-summary` to see the full local flow.

### Task 25 (USER): Cloud routine setup

**To be done by user, in Anthropic Routines web UI:**

Follow `routines/README.md`. Create both routines (`auto_invest pre-market`, `auto_invest daily-summary`) with their respective crons, env vars, "Allow unrestricted branch pushes" toggled ON, and the prompts pasted verbatim from `routines/pre-market.md` and `routines/daily-summary.md`. Hit "Run now" once on each to confirm.

### Task 26 (USER): Observe v1 exit criteria

Watch for 5 consecutive weekdays. Per spec § 11:
1. Both routines fire successfully on cloud cron with no manual intervention
2. Each successful run produces a commit on `main` from the routine container (visible in `git log origin/main`)
3. Slack receives expected notifications (silent pre-market, EOD always)
4. Perplexity calls succeed (cited entries in `RESEARCH-LOG.md`); WebSearch fallback observed at least once during a controlled test
5. `git log -- .env` is empty at all times
6. At least one rebase-on-conflict path exercised cleanly

When all six observed → v1 done → start the v2 spec & plan.

---

## Self-review (run after writing the plan)

**1. Spec coverage:** Walked through spec § 1–13. Each item maps to a task:
- § 2 confirmed decisions → encoded in env.template (Task 8) and CLAUDE.md (Task 14)
- § 3 architecture → reflected in repo layout & wrapper design
- § 4 repo layout → Tasks 0, 8–21 create every file with a ★
- § 5 memory schema → Tasks 9–13 seed all 5 memory files; routines (Tasks 19–20) follow the read/write contract
- § 6 schedules + notifications → routines/README (Task 18) + per-routine prompts (Tasks 19–20)
- § 7 secrets → env.template (Task 8), CLAUDE.md (Task 14), routine env-var blocks (Tasks 19–20), test guards (Task 6)
- § 8 wrappers → Tasks 3–6 with TDD
- § 9 routines → Tasks 19–20
- § 10 bootstrap order → matches Phase 0–10 here
- § 11 phased path → encoded in PROJECT-CONTEXT.md, README, routines/README, and Task 26
- § 12 open questions → noted in spec, no plan changes needed
- § 13 out of scope → not built (kill-switch enforces in v1)

**2. Placeholder scan:** No "TBD", "TODO", "implement later", or "similar to Task N" in the plan body. Every code step has the actual code. Every command step has the exact command + expected output.

**3. Type/name consistency:**
- `scripts/slack.sh`, `scripts/perplexity.sh`, `scripts/alpaca.sh` — same names everywhere
- `SLACK_WEBHOOK_URL` env var — same in env.template, wrappers, routine prompts, README
- `TRADING_ENABLED` — same in env.template, alpaca.sh kill-switch, CLAUDE.md, routine prompts
- `ALPACA_ENDPOINT` (paper URL) — required in alpaca.sh, documented in env.template, sanity-checked in both routine prompts
- `memory/TRADE-LOG.md` EOD schema — defined in Task 12 (TRADE-LOG seed), referenced in Task 17 (local daily-summary), Task 20 (cloud daily-summary). Same schema in all three.
- `memory/RESEARCH-LOG.md` entry schema — defined in Task 11 (seed), referenced in Tasks 16 & 19. Same.

No inconsistencies found.

**Plan is ready for execution.**

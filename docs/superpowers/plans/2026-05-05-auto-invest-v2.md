# auto_invest v2 — Execution Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the execution layer (market-open, midday, weekly-review routines + stop-placement at daily-summary) on top of v1's research layer, with visa-aware safety guards (Rules 13–15) preventing day trades by construction.

**Architecture:** Three new cloud routines + a daily-summary expansion + three new alpaca.sh subcommands. All state lives in Alpaca and append-only memory files on `main`. Visa-safety: stops placed at market close (cannot fire same-day); midday hard-close + sector-kill skip same-day positions; pre-flight `daytrade_count` check before every sell.

**Tech Stack:** Bash + curl + stdlib Python (no SDKs, same as v1). Alpaca paper API. Telegram Bot API. Anthropic Routines for cloud cron.

**Spec:** `docs/superpowers/specs/2026-05-04-auto-invest-v2-design.md` (LOCKED 2026-05-05).

**Strategy rules added:** `memory/TRADING-STRATEGY.md` Rules 13–15 (committed in spec-lock commit `5939501`).

---

## Critical pre-implementation gate

**Do not start Task 1 until v1 criterion #1 has closed** (5 consecutive clean cron weekdays). Verify with:

```bash
cd /Users/dntounis/Documents/apps/auto_invest
git log --oneline --since='14 days ago' origin/main | grep -E "pre-market research|EOD snapshot" | head -20
```

Expected: 5 consecutive weekday entries each from pre-market and daily-summary. If not present, stop and wait.

---

## Phasing

| Phase | Tasks | Output |
|-------|-------|--------|
| 1. Wrappers | T1–T3 | Three new `alpaca.sh` subcommands + tests |
| 2. Heartbeat | T4–T5 | `memory/HEARTBEAT.md` + `telegram.sh` ledger update |
| 3. Pre-market enhancements | T6 | Idea ID format + R:R ranking |
| 4. market-open | T7–T8 | Cloud + local mirror |
| 5. midday | T9–T10 | Cloud + local mirror |
| 6. daily-summary expansion | T11–T12 | Cloud + local mirror |
| 7. weekly-review | T13–T14 | Cloud + local mirror |
| 8. manual /trade | T15 | Local mirror only |
| 9. Docs + cloud setup | T16–T18 | README, CLAUDE.md, cloud setup checklist |

Total: 18 tasks. Subagent-driven dispatch recommended (each task is self-contained).

---

## Task 1: Add `trailing-stop` subcommand to `scripts/alpaca.sh`

**Files:**
- Modify: `scripts/alpaca.sh:46-93` (add new case branch, update usage line)
- Modify: `tests/test_alpaca.sh` (add tests for the new subcommand)

- [ ] **Step 1: Write the failing kill-switch test**

Add to `tests/test_alpaca.sh` after the existing `cancel-all` kill-switch test (around line 102):

```bash
# Test: trailing-stop subcommand gated by TRADING_ENABLED
start_test "exits 4 on trailing-stop when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh trailing-stop XLE 5 10 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dntounis/Documents/apps/auto_invest
bash tests/test_alpaca.sh
```

Expected: FAIL on the new test with "Usage:" output (subcommand falls through to default case).

- [ ] **Step 3: Write the missing-arg test**

Add immediately after the previous test:

```bash
# Test: trailing-stop with missing args
start_test "exits 1 on trailing-stop with missing args"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="true"
    bash scripts/alpaca.sh trailing-stop 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: trailing-stop"
```

- [ ] **Step 4: Run tests, verify both fail**

```bash
bash tests/test_alpaca.sh
```

Expected: 2 new FAILs.

- [ ] **Step 5: Implement `trailing-stop` in `scripts/alpaca.sh`**

Edit `scripts/alpaca.sh`. After the `close-all)` case branch (line 87), before the wildcard `*)` case, add:

```bash
    trailing-stop)
        require_trading_enabled
        sym="${1:?usage: trailing-stop SYM QTY TRAIL_PCT}"
        qty="${2:?usage: trailing-stop SYM QTY TRAIL_PCT}"
        trail="${3:?usage: trailing-stop SYM QTY TRAIL_PCT}"
        body=$(python3 -c "
import json, sys
print(json.dumps({
    'symbol': sys.argv[1],
    'qty': sys.argv[2],
    'side': 'sell',
    'type': 'trailing_stop',
    'trail_percent': sys.argv[3],
    'time_in_force': 'gtc',
    'extended_hours': False,
}))" "$sym" "$qty" "$trail")
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
```

Update the usage line (line 90) to include the new subcommand:

```bash
        echo "Usage: bash scripts/alpaca.sh <account|positions|position|quote|orders|order|cancel|cancel-all|close|close-all|trailing-stop|replace-stop|activities> [args]" >&2
```

- [ ] **Step 6: Run tests, verify both pass**

```bash
bash tests/test_alpaca.sh
```

Expected: all tests pass including the 2 new ones.

- [ ] **Step 7: Commit**

```bash
git add scripts/alpaca.sh tests/test_alpaca.sh
git commit -m "feat(alpaca): add trailing-stop subcommand for v2 execution layer

Places a sell-side trailing-stop GTC order with extended_hours=false so it
cannot fire in pre/post-market sessions. Kill-switch gated as a state-
changing subcommand. Used by daily-summary at 15:00 CT (market close) per
TRADING-STRATEGY.md Rule 13."
```

---

## Task 2: Add `replace-stop` helper to `scripts/alpaca.sh`

**Files:**
- Modify: `scripts/alpaca.sh` (add new case branch)
- Modify: `tests/test_alpaca.sh` (add kill-switch + missing-arg tests)

`replace-stop` is `cancel ORDER_ID` followed by `trailing-stop SYM QTY TRAIL_PCT` for the same ticker. Used by midday to tighten trailing stops at +15%/+20% gain thresholds (Rule 8).

- [ ] **Step 1: Write the kill-switch test**

Add to `tests/test_alpaca.sh` after Task 1's tests:

```bash
# Test: replace-stop subcommand gated by TRADING_ENABLED
start_test "exits 4 on replace-stop when TRADING_ENABLED != true"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh replace-stop dummy-id XLE 5 7 2>&1
)
rc=$?
assert_exit_code 4 "$rc"
assert_contains "$out" "TRADING_ENABLED"
```

- [ ] **Step 2: Write the missing-arg test**

```bash
# Test: replace-stop with missing args
start_test "exits 1 on replace-stop with missing args"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    export TRADING_ENABLED="true"
    bash scripts/alpaca.sh replace-stop 2>&1
)
rc=$?
assert_exit_code 1 "$rc"
assert_contains "$out" "usage: replace-stop"
```

- [ ] **Step 3: Run tests, verify both fail**

```bash
bash tests/test_alpaca.sh
```

Expected: 2 new FAILs.

- [ ] **Step 4: Implement `replace-stop` in `scripts/alpaca.sh`**

Add immediately after the `trailing-stop)` case branch:

```bash
    replace-stop)
        require_trading_enabled
        oid="${1:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        sym="${2:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        qty="${3:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        trail="${4:?usage: replace-stop ORDER_ID SYM QTY NEW_TRAIL_PCT}"
        # Cancel existing stop. If it already fired or doesn't exist, Alpaca returns 422 — accept.
        curl -fsS -H "$H_KEY" -H "$H_SEC" -X DELETE "$API/orders/$oid" || true
        body=$(python3 -c "
import json, sys
print(json.dumps({
    'symbol': sys.argv[1],
    'qty': sys.argv[2],
    'side': 'sell',
    'type': 'trailing_stop',
    'trail_percent': sys.argv[3],
    'time_in_force': 'gtc',
    'extended_hours': False,
}))" "$sym" "$qty" "$trail")
        curl -fsS -H "$H_KEY" -H "$H_SEC" -H "Content-Type: application/json" \
            -X POST -d "$body" "$API/orders"
        ;;
```

- [ ] **Step 5: Run tests, verify both pass**

```bash
bash tests/test_alpaca.sh
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/alpaca.sh tests/test_alpaca.sh
git commit -m "feat(alpaca): add replace-stop helper (cancel + new trailing-stop)

Atomic-from-caller's-perspective stop replacement. The cancel allows '|| true'
because if the original stop already fired the cancel returns 422 (order not
cancelable) and we still want to place the replacement. Used by midday to
tighten trail percent at +15%/+20% gain thresholds per TRADING-STRATEGY.md
Rule 8."
```

---

## Task 3: Add `activities` subcommand to `scripts/alpaca.sh`

**Files:**
- Modify: `scripts/alpaca.sh` (add new case branch)
- Modify: `tests/test_alpaca.sh` (add usage test)

`activities` returns fills + non-trade activities. Used by daily-summary for realized P&L and by weekly-review for the weekly grade card. Read-only (no kill-switch gate).

- [ ] **Step 1: Write the bad-subcommand test still works**

Verify the existing "exits 1 with usage on bad subcommand" test (line 105 in test_alpaca.sh) still passes after future changes. No new test needed for `activities` itself beyond verifying it doesn't get gated by the kill switch.

- [ ] **Step 2: Add the read-only behavior test**

Add to `tests/test_alpaca.sh`:

```bash
# Test: activities does NOT require TRADING_ENABLED (read-only)
start_test "activities works without TRADING_ENABLED (read-only subcommand)"
TMP="$(mktemp -d tests/.tmp/alp.XXXXXX)"
out=$(
    cd "$TMP"
    cp -r "$ROOT/scripts" .
    rm -f .env
    # Use bogus keys so the curl call fails with 401, not exits 4
    export ALPACA_API_KEY="dummy" ALPACA_SECRET_KEY="dummy"
    export ALPACA_ENDPOINT="https://paper-api.alpaca.markets/v2"
    export ALPACA_DATA_ENDPOINT="https://data.alpaca.markets/v2"
    unset TRADING_ENABLED
    bash scripts/alpaca.sh activities 2>&1
)
rc=$?
# Expect non-4 exit (real auth failure from curl returning 22, or similar). Just NOT 4.
if [[ "$rc" == "4" ]]; then
    fail "activities was kill-switch-gated but should be read-only"
else
    pass
fi
```

- [ ] **Step 3: Run tests, verify the new one fails**

```bash
bash tests/test_alpaca.sh
```

Expected: new test FAILs because `activities` falls through to default case (exit 1, not 4 — but the test would actually pass on exit 1; let me re-check).

Actually exit 1 ≠ 4 so the test would currently pass with exit 1. To make this an honest fail-first test, prepend a check for the activities subcommand existing at all:

Update the test body to add this assertion before the kill-switch check:

```bash
# Must not be "Usage:" — that means subcommand isn't recognized
assert_not_contains "$out" "Usage: bash scripts/alpaca.sh"
```

If `assert_not_contains` doesn't exist in `_lib.sh`, add it now:

```bash
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-string should not contain substring}"
    if [[ "$haystack" != *"$needle"* ]]; then
        pass
    else
        fail "$msg: '$needle' was present in output"
    fi
}
```

- [ ] **Step 4: Run tests, confirm new test fails because subcommand not yet implemented**

```bash
bash tests/test_alpaca.sh
```

Expected: FAIL — output contains "Usage:" because `activities` isn't a known subcommand yet.

- [ ] **Step 5: Implement `activities` in `scripts/alpaca.sh`**

Add immediately after the `replace-stop)` case branch:

```bash
    activities)
        # Read-only — no kill-switch gate.
        # Optional first arg: date (YYYY-MM-DD). Defaults to today in America/Chicago.
        date_filter="${1:-$(TZ=America/Chicago date +%Y-%m-%d)}"
        curl -fsS -H "$H_KEY" -H "$H_SEC" \
            "$API/account/activities?date=$date_filter"
        ;;
```

- [ ] **Step 6: Run tests, verify all pass**

```bash
bash tests/test_alpaca.sh
```

Expected: all tests pass (the new test confirms `activities` exits with a non-4, non-1-with-usage code — likely curl's 22 due to bogus keys).

- [ ] **Step 7: Commit**

```bash
git add scripts/alpaca.sh tests/_lib.sh tests/test_alpaca.sh
git commit -m "feat(alpaca): add activities subcommand for fills + non-trade activity feed

Read-only (no kill-switch gate). Defaults date filter to today in
America/Chicago to match the rest of the routine TZ. Used by daily-summary
for realized P&L and by weekly-review for the weekly grade card."
```

---

## Task 4: Create `memory/HEARTBEAT.md` ledger

**Files:**
- Create: `memory/HEARTBEAT.md`

The heartbeat ledger is a single-line file storing the ISO timestamp of the most recent successful Telegram message. Daily-summary reads it; if `now - last > 48h`, prepends a heartbeat to its EOD message body.

- [ ] **Step 1: Create the file with initial content**

Create `memory/HEARTBEAT.md` with this exact content:

```markdown
# Heartbeat ledger

Single-line ledger updated by `scripts/telegram.sh` on every successful send.
Read by `daily-summary` to detect 48h+ silence and prepend a heartbeat line
to the EOD Telegram body.

last_telegram: 2026-05-05T00:00:00Z
```

The placeholder `2026-05-05T00:00:00Z` is fine for bootstrap. The first successful Telegram run after deploy will overwrite it.

- [ ] **Step 2: Verify file structure**

```bash
test -f memory/HEARTBEAT.md && grep -q "^last_telegram: " memory/HEARTBEAT.md && echo OK
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add memory/HEARTBEAT.md
git commit -m "feat(memory): add HEARTBEAT.md ledger for v2 silence detection

Single-line file tracking last_telegram ISO timestamp. Updated by
telegram.sh on success; read by daily-summary for the 48h-silence
heartbeat per spec § 4 DECIDED J."
```

---

## Task 5: Update `scripts/telegram.sh` to refresh `HEARTBEAT.md` on success

**Files:**
- Modify: `scripts/telegram.sh` (append a successful-send hook)
- Modify: `tests/test_telegram.sh` (add heartbeat-update test)

- [ ] **Step 1: Write the heartbeat-update test**

Add to `tests/test_telegram.sh`:

```bash
# Test: telegram.sh updates HEARTBEAT.md on successful send (using fallback path)
start_test "telegram.sh updates memory/HEARTBEAT.md on fallback (no TELEGRAM_BOT_TOKEN)"
TMP="$(mktemp -d tests/.tmp/tg.XXXXXX)"
(
    cd "$TMP"
    mkdir -p scripts memory
    cp "$ROOT/scripts/telegram.sh" scripts/
    cat > memory/HEARTBEAT.md <<'EOF'
# Heartbeat ledger

last_telegram: 2020-01-01T00:00:00Z
EOF
    rm -f .env
    unset TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
    bash scripts/telegram.sh "test heartbeat update" >/dev/null 2>&1
    grep "^last_telegram: " memory/HEARTBEAT.md
)
rc=$?
ledger_line=$(grep "^last_telegram: " "$TMP/memory/HEARTBEAT.md" 2>/dev/null || echo "")
# Should NOT be the bootstrap timestamp anymore
assert_exit_code 0 "$rc"
if [[ "$ledger_line" == "last_telegram: 2020-01-01T00:00:00Z" ]]; then
    fail "HEARTBEAT.md was not refreshed (still has bootstrap timestamp)"
else
    pass
fi
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test_telegram.sh
```

Expected: FAIL — the bootstrap timestamp is unchanged because telegram.sh doesn't yet update HEARTBEAT.md.

- [ ] **Step 3: Implement HEARTBEAT.md update in `telegram.sh`**

Edit `scripts/telegram.sh`. Locate the section after both the curl-success and fallback-append paths. The curl block ends around line 54 with `echo`; the fallback block ends with `exit 0`.

Add a helper near the top of the script (right after the `set -euo pipefail` line, before `ROOT="..."`):

```bash
update_heartbeat() {
    local hb="$ROOT/memory/HEARTBEAT.md"
    if [[ -f "$hb" ]]; then
        local now
        now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        # Replace any existing "last_telegram:" line; append if absent.
        if grep -q "^last_telegram: " "$hb"; then
            python3 - "$hb" "$now" <<'PY'
import sys, re
path, now = sys.argv[1], sys.argv[2]
with open(path) as f:
    txt = f.read()
new = re.sub(r"^last_telegram: .*$", f"last_telegram: {now}", txt, flags=re.MULTILINE)
with open(path, "w") as f:
    f.write(new)
PY
        else
            echo "last_telegram: $now" >> "$hb"
        fi
    fi
}
```

Then call `update_heartbeat` at the end of both success paths. After the curl `echo` line:

```bash
curl -fsS -X POST \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
echo
update_heartbeat
```

And inside the fallback block, immediately before `exit 0`:

```bash
if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    {
        printf '\n---\n## %s (fallback — Telegram not configured)\n%s\n' \
            "$stamp" "$msg"
    } >> "$FALLBACK"
    echo "[telegram fallback] appended to DAILY-SUMMARY.md"
    update_heartbeat
    exit 0
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test_telegram.sh
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/telegram.sh tests/test_telegram.sh
git commit -m "feat(telegram): refresh memory/HEARTBEAT.md on every successful send

Updates last_telegram ISO timestamp on both curl-success and fallback paths.
Routines that call telegram.sh must include memory/HEARTBEAT.md in their
final git add so the ledger persists to main. Used by daily-summary's 48h
silence detection per spec DECIDED J."
```

---

## Task 6: Update pre-market routines for idea ID + R:R ranking

**Files:**
- Modify: `routines/pre-market.md` (Step 4 instructions)
- Modify: `.claude/commands/pre-market.md` (Step 4 instructions)

Pre-market needs two small changes for v2: assign each idea a `pm-YYYY-MM-DD-TICKER` ID (per DECIDED I) and present ideas in R:R-descending order so market-open can pick top-N (per DECIDED C).

- [ ] **Step 1: Read current pre-market routine STEP 4 section**

```bash
grep -n "## STEP 4" routines/pre-market.md
```

Note the line number for the next edit.

- [ ] **Step 2: Update `routines/pre-market.md` STEP 4**

Find the section that begins `## STEP 4 — Write a dated entry to memory/RESEARCH-LOG.md`. Replace its body (everything between this header and the next `## STEP` header) with:

```markdown
## STEP 4 — Write a dated entry to `memory/RESEARCH-LOG.md`

Use the schema documented at the top of `RESEARCH-LOG.md`. Include:

- **Account snapshot:** equity, cash, buying power, daytrade count
- **Market context:** oil, indices, VIX, today's releases, sector momentum
- **2–3 actionable trade ideas, ranked by R:R descending** (tie-break: ticker ascending). Each idea MUST include:
  - **ID:** `pm-YYYY-MM-DD-TICKER` — used by `market-open` to link trades to ideas
  - TICKER — catalyst, entry $X, stop $X, target $X, R:R X:1, **planned trail percent** (default 10)
  - Each idea must satisfy the buy-side gate in `TRADING-STRATEGY.md` (≤6 positions,
    ≤3 trades/week, ≤20% equity, sector momentum aligned, etc.). Skip ideas that fail.
- **Risk factors:** macro, sector, idiosyncratic
- **Decision:** TRADE or HOLD (default HOLD — patience > activity)
- **Sources:** Perplexity citations + any WebSearch fallback flags

> v2 reminder: `market-open` reads this entry and places limit orders for the top
> `min(passing_ideas, weekly_cap_remaining)` ideas in R:R order. Stops are placed
> by `daily-summary` at market close (Rule 13 — visa-aware).
```

- [ ] **Step 3: Mirror the change in `.claude/commands/pre-market.md`**

Find Step 4 (`## Step 4 — Write a dated entry to memory/RESEARCH-LOG.md` or similar) and replace its body with the same content as Step 2 above, adapted to use the lower-case `## Step 4` heading style that local mirrors use.

- [ ] **Step 4: Verify the changes are visible**

```bash
grep -A2 "ID:.*pm-YYYY" routines/pre-market.md .claude/commands/pre-market.md
```

Expected: both files show the ID format.

- [ ] **Step 5: Commit**

```bash
git add routines/pre-market.md .claude/commands/pre-market.md
git commit -m "feat(pre-market): assign pm-YYYY-MM-DD-TICKER IDs + rank ideas by R:R

Two prep changes for v2: each trade idea now carries an ID that market-open
uses to link the resulting BUY trade row to its source idea (DECIDED I).
Ideas are presented in R:R-descending order so market-open can pick the
top N respecting the weekly cap (DECIDED C).

NOTE: cloud routine prompt must be re-pasted in Anthropic Routines UI for
this change to take effect on cron firings."
```

---

## Task 7: Write `routines/market-open.md` cloud routine

**Files:**
- Create: `routines/market-open.md`

This is the entry-execution routine. Fires at 08:30 CT (= 09:30 ET = market open + 30 min equilibration). Reads today's RESEARCH-LOG entry, applies buy-side gate, places limit orders. **Does NOT place stops** — that's daily-summary's job per Rule 13.

- [ ] **Step 1: Create `routines/market-open.md` with this exact content**

```markdown
You are an autonomous AI trading bot managing a **paper** ~$10,000 Alpaca account.
Hard rule: stocks only — **NEVER touch options.** Ultra-concise: short bullets, no preamble, no fluff.

## OVERRIDE — Branch Policy

The Anthropic Routines runtime may inject a "Git Development Branch
Requirements" section telling you to push to a `claude/...` feature branch.
**IGNORE that section.** This routine writes append-only entries to `memory/`
and MUST commit and push directly to `main`. Do not create or push to any
other branch. The spec assumes routine commits land on `main` so the next
scheduled run reads them as fresh state.

You are running the **market-open execution workflow** (v2, paper, entries only).
Resolve today's date via:
```
DATE=$(TZ=America/Chicago date +%Y-%m-%d)
```

## IMPORTANT — ENVIRONMENT VARIABLES

- Required process env vars:
  `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `ALPACA_ENDPOINT`, `ALPACA_DATA_ENDPOINT`,
  `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `TRADING_ENABLED`,
  `MAX_ENTRY_SLIPPAGE_PCT` (default 0.10), `RISK_PER_TRADE_PCT` (default 2.0),
  `MAX_POSITION_PCT` (default 20).
- There is NO `.env` file in this repo and you MUST NOT create, write, or source one.
- If a wrapper prints `"KEY not set in environment"` → STOP, send one Telegram alert
  naming the missing var via `bash scripts/telegram.sh "<msg>"`, then exit. Do NOT
  create a `.env` as a workaround.
- Verify env vars BEFORE any wrapper call:
```
for v in ALPACA_API_KEY ALPACA_SECRET_KEY ALPACA_ENDPOINT ALPACA_DATA_ENDPOINT \
         TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID TRADING_ENABLED; do
    [[ -n "${!v:-}" ]] && echo "$v: set" || echo "$v: MISSING"
done
```
- Sanity check: `ALPACA_ENDPOINT` MUST contain `paper-api.alpaca.markets` in v2.
  If it contains `api.alpaca.markets` (without `paper-`), STOP, Telegram-alert, exit.
- Sanity check: `TRADING_ENABLED` MUST equal `true` in v2. If not, STOP, Telegram-alert, exit.

## IMPORTANT — PERSISTENCE

- This workspace is a fresh clone. File changes VANISH unless you commit and push to `main`.
- You MUST `git add` + `git commit` + `git push origin main` at STEP 9.

## IMPORTANT — VISA-AWARE RULES (read before acting)

- **Rule 13:** This routine NEVER places trailing stops. Stops are placed by
  `daily-summary` at 15:00 CT (market close) so they cannot fire same-day.
- **Rule 14:** This routine only places BUY orders. No sells. The pre-flight
  `daytrade_count` check is enforced at midday and weekly-review where sells
  may occur.
- **Rule 15:** Same-day exits are forbidden. Since this routine never sells,
  Rule 15 does not constrain it directly — but it must NOT cancel an existing
  position or close anything.

---

## STEP 1 — Read memory for context

- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md` (rules, especially the Buy-Side Gate)
- Today's `memory/RESEARCH-LOG.md` entry — the 2-3 ranked trade ideas
- Tail of `memory/TRADE-LOG.md` (positions opened today, week's trade count)

If today's RESEARCH-LOG entry does not exist (e.g., pre-market failed to commit),
STOP, send Telegram alert "market-open $DATE: no RESEARCH-LOG entry found — skipping execution",
exit. Do NOT make up trade ideas.

## STEP 2 — Pull live paper-account state

```
bash scripts/alpaca.sh account     # equity, cash, buying_power, daytrade_count
bash scripts/alpaca.sh positions   # currently held tickers
bash scripts/alpaca.sh orders open # open orders (used for idempotency check)
```

Idempotency (DECIDED H): if today's orders already include any BUY for a ticker
that's also a candidate today, SKIP that ticker. The routine ran already — don't
double-buy.

## STEP 3 — Apply buy-side gate to each idea

For each idea in today's RESEARCH-LOG entry, run the Buy-Side Gate from
`TRADING-STRATEGY.md`. Skip and log reason for any failure:

- Total positions after this fill ≤ 6
- Trades placed this week (incl. this one) ≤ 3
- Position cost ≤ 20% of account equity
- Position cost ≤ available cash
- `account.daytrade_count` MUST be ≤ 1 to allow new entries (Rule 14 buffer)
- Specific catalyst is documented in today's RESEARCH-LOG entry (true by construction)
- Instrument is a stock (not option/crypto/forex/futures)

## STEP 4 — Rank passing ideas, take top N

- Already ranked by R:R descending in pre-market output (DECIDED C).
- `weekly_cap_remaining = 3 - trades_this_week`
- Take `min(len(passing_ideas), weekly_cap_remaining)`. May be zero — in which
  case skip to STEP 8 with no orders placed.

## STEP 5 — Compute risk-parity position size per idea (DECIDED D)

```
RISK_PCT=${RISK_PER_TRADE_PCT:-2.0}        # default 2% of equity
MAX_POS_PCT=${MAX_POSITION_PCT:-20}        # default 20% cap
SLIPPAGE_PCT=${MAX_ENTRY_SLIPPAGE_PCT:-0.10}

dollar_risk = (RISK_PCT / 100) * account.equity                   # e.g., 200 on 10k
stop_distance_pct = idea.trail_percent / 100                      # e.g., 0.10
shares_by_risk = floor(dollar_risk / (idea.entry * stop_distance_pct))
shares_by_cap  = floor((MAX_POS_PCT / 100) * account.equity / idea.entry)
shares = min(shares_by_risk, shares_by_cap)
```

Must be ≥ 1, else skip the idea (cap or risk budget too small).

## STEP 6 — Place limit BUY orders

For each idea:

1. Pull current quote: `bash scripts/alpaca.sh quote TICKER` → extract ask price.
2. Compute limit price: `limit = round(ask * (1 + SLIPPAGE_PCT/100), 2)`.
3. Place the order:
```
ORDER_JSON=$(python3 -c "
import json
print(json.dumps({
    'symbol': 'TICKER',
    'qty': SHARES,
    'side': 'buy',
    'type': 'limit',
    'limit_price': str(LIMIT),
    'time_in_force': 'day',
}))")
bash scripts/alpaca.sh order "$ORDER_JSON"
```
4. Poll up to 60 seconds for fill: `bash scripts/alpaca.sh orders open` and look
   for the order ID. If still open after 60 s, leave it (will fill or cancel at
   close). Telegram-alert "TICKER limit order placed, not yet filled".

DO NOT place a trailing stop here — that is `daily-summary`'s job (Rule 13).

## STEP 7 — Append BUY trade rows to `memory/TRADE-LOG.md`

For each filled order (or open-pending), append a row matching the schema at the
top of `TRADE-LOG.md`:

```
### YYYY-MM-DD — TRADE: TICKER side=buy qty=N
- Entry: $X
- Stop level: pending (placed at daily-summary T 15:00 CT per Rule 13)
- Thesis: <copied from RESEARCH-LOG entry>
- Catalyst: pm-YYYY-MM-DD-TICKER (link to RESEARCH-LOG entry)
- Target: $X (R:R X:1)
- Realized P&L: n/a (open position)
```

## STEP 8 — Telegram

- 1 message per filled order: `*FILLED MMM DD* (paper) — TICKER N shares @ $X (catalyst: <one line>)`
- 1 message per rejected/expired order: `*REJECT MMM DD* (paper) — TICKER reason: <reason>`
- Silent if zero orders attempted.

## STEP 9 — COMMIT AND PUSH (mandatory)

```
git add memory/TRADE-LOG.md memory/HEARTBEAT.md
git commit -m "market-open $DATE: <N> orders, <K> filled"
git push origin main
```

On push failure (non-fast-forward / divergence):
```
git pull --rebase origin main
git push origin main
```

**Never use `--force` or `--force-with-lease`.**
```

- [ ] **Step 2: Verify the file has all required sections**

```bash
grep -E "^## (OVERRIDE|IMPORTANT|STEP)" routines/market-open.md
```

Expected: lines for OVERRIDE, IMPORTANT — ENVIRONMENT VARIABLES, IMPORTANT — PERSISTENCE, IMPORTANT — VISA-AWARE RULES, and STEP 1 through STEP 9.

- [ ] **Step 3: Sanity-check it bans options + mentions visa rules**

```bash
grep -c "NEVER touch options" routines/market-open.md
grep -c "Rule 13\|Rule 14\|Rule 15" routines/market-open.md
```

Expected: ≥1 for the first; ≥3 for the second.

- [ ] **Step 4: Commit**

```bash
git add routines/market-open.md
git commit -m "feat(routines): add market-open cloud routine (entries only)

Fires at 08:30 CT, reads today's RESEARCH-LOG ideas, applies buy-side gate,
places limit-with-slippage entry orders. Does NOT place stops (Rule 13 —
that's daily-summary's job at market close). Includes idempotency check
against open orders + today's BUYs to prevent double-buy on rerun (DECIDED H).
Risk-parity sizing per DECIDED D."
```

---

## Task 8: Write `.claude/commands/market-open.md` local mirror

**Files:**
- Create: `.claude/commands/market-open.md`

The local mirror is for hand-testing with `/market-open`. Same logic but no commit/push (skip STEP 9), and it should run with `TRADING_ENABLED=false` initially so the kill-switch refuses orders — proving the wrapper guard works before going live.

- [ ] **Step 1: Create `.claude/commands/market-open.md` with this content**

```markdown
---
description: Market-open execution (local mirror of cloud routine; no commit/push, kill-switch-gated)
---

You are running the **market-open execution workflow** locally. Resolve today's
date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)` — match the cloud routine's
TZ so local entries align with cron-fired entries.

This is a v2 paper run. **Orders may execute** if `TRADING_ENABLED=true` in your
local `.env`. Otherwise the wrapper refuses with exit 4 — that's the kill-switch
working correctly. The cloud routine ALWAYS has TRADING_ENABLED=true in v2.

## Step 1 — Read memory
- `memory/PROJECT-CONTEXT.md`
- `memory/TRADING-STRATEGY.md`
- Today's `memory/RESEARCH-LOG.md` entry
- Tail of `memory/TRADE-LOG.md`

## Step 2 — Pull state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
```

Idempotency: skip any ticker with an existing today BUY.

## Step 3 — Apply buy-side gate
Per `TRADING-STRATEGY.md`. Reject ideas where `account.daytrade_count > 1` to
preserve Rule 14 buffer.

## Step 4 — Rank, take top N
Ideas already ranked R:R-desc by pre-market. Take `min(passing, 3 - trades_this_week)`.

## Step 5 — Risk-parity sizing
```
dollar_risk = (RISK_PER_TRADE_PCT / 100) * equity        # default 2% = $200
shares_by_risk = floor(dollar_risk / (entry * trail_pct/100))
shares_by_cap  = floor((MAX_POSITION_PCT/100) * equity / entry)  # default 20%
shares = min(shares_by_risk, shares_by_cap)
```

## Step 6 — Place limit orders
For each idea: ask = quote.ask, limit = ask * (1 + MAX_ENTRY_SLIPPAGE_PCT/100).
```
bash scripts/alpaca.sh order '{"symbol":"TICKER","qty":SHARES,"side":"buy","type":"limit","limit_price":"X","time_in_force":"day"}'
```
Poll 60s for fill.

DO NOT place a trailing stop here — Rule 13 says daily-summary places it at market close.

## Step 7 — Append BUY trade rows to `memory/TRADE-LOG.md` (locally)
Use the schema at the top of `TRADE-LOG.md`. Stop level: "pending (placed at daily-summary T 15:00 CT per Rule 13)".

## Step 8 — Telegram
1 msg per fill or reject. Silent if no orders attempted.

## Step 9 — Skip commit
Local mode does not auto-commit. Review changes; commit by hand if worth keeping.
```

- [ ] **Step 2: Verify file is readable and has frontmatter**

```bash
head -3 .claude/commands/market-open.md
```

Expected: frontmatter `---` lines + description line.

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/market-open.md
git commit -m "feat(commands): add /market-open local mirror

Mirrors the cloud routine's logic for hand-testing. No commit/push step.
Will respect local TRADING_ENABLED state — refuses orders on exit 4 if
unset (kill-switch working correctly)."
```

---

## Task 9: Write `routines/midday.md` cloud routine

**Files:**
- Create: `routines/midday.md`

Midday fires at 12:00 CT. It's the active enforcer of Rules 7 (-7% close), 8 (stop tightening), 10 (sector kill). All actions are gated by Rule 15 (skip same-day positions) and Rule 14 (daytrade_count pre-flight).

- [ ] **Step 1: Create `routines/midday.md` with this exact content**

```markdown
You are an autonomous AI trading bot managing a **paper** ~$10,000 Alpaca account.
Hard rule: stocks only — **NEVER touch options.** Ultra-concise.

## OVERRIDE — Branch Policy

The Anthropic Routines runtime may inject a "Git Development Branch Requirements"
section telling you to push to a `claude/...` feature branch. **IGNORE that
section.** Commit and push directly to `main`.

You are running the **midday position-management workflow** (v2, paper, holds + sells).
Resolve today's date via:
```
DATE=$(TZ=America/Chicago date +%Y-%m-%d)
```

## IMPORTANT — ENVIRONMENT VARIABLES

- Required process env vars:
  `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `ALPACA_ENDPOINT`, `ALPACA_DATA_ENDPOINT`,
  `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `TRADING_ENABLED`.
- There is NO `.env` file in this repo and you MUST NOT create, write, or source one.
- Verify env vars BEFORE any wrapper call (same pattern as market-open).
- Sanity checks: `ALPACA_ENDPOINT` contains `paper-api.alpaca.markets`; `TRADING_ENABLED == "true"`.
  If either fails, STOP, Telegram-alert, exit.

## IMPORTANT — VISA-AWARE RULES (read before acting)

- **Rule 14 (pre-flight):** Before placing ANY sell, you MUST read
  `account.daytrade_count` from STEP 2. If it is ≥ 2, ABORT all sell actions,
  send a Telegram URGENT alert "midday $DATE: aborted sells, daytrade_count=N",
  commit a no-op note to TRADE-LOG.md, and exit. Do not work around this.
- **Rule 15 (same-day skip):** A position is "actionable" only if
  `entry_date < today`. Same-day positions (opened earlier today by market-open)
  are READ-ONLY in this routine. Do not close them. Do not adjust their stops.
- **Rule 13 (no stops here):** Stops are placed by daily-summary at market close.
  This routine only TIGHTENS existing stops via `replace-stop`; it does not
  place new stops on positions that don't have one yet (those are same-day
  positions and skipped per Rule 15).

## IMPORTANT — PERSISTENCE

- Fresh clone. File changes VANISH unless committed and pushed to `main`.
- Commit and push at STEP 8 even if no actions taken (a "no-action" note is still useful for audit).

---

## STEP 1 — Read memory for context

- `memory/TRADING-STRATEGY.md` (sell-side rules + Rules 13–15)
- Tail of `memory/TRADE-LOG.md` — open positions with their entry dates,
  initial stop info, sector tags. Used for Rule 15 same-day filter and Rule 10
  sector tally.

## STEP 2 — Pull live paper-account state

```
bash scripts/alpaca.sh account     # equity + daytrade_count (CRITICAL for Rule 14)
bash scripts/alpaca.sh positions   # current positions with avg_entry_price + market_value
bash scripts/alpaca.sh orders open # open trailing-stop orders (for replace-stop)
```

Capture `account.daytrade_count` as `DTC`. If `DTC >= 2`, jump immediately to
the abort path described in Rule 14 (skip steps 3–6, write the abort note to
TRADE-LOG.md, Telegram URGENT, commit, exit).

## STEP 3 — Filter positions to actionable

For each position, compute:
- `entry_date` (from TRADE-LOG.md latest BUY row for this ticker, OR from
  Alpaca if the ticker isn't in TRADE-LOG.md — fall back to assuming entry_date == today)
- `unrealized_pl_pct = (current_price - avg_entry_price) / avg_entry_price * 100`

Drop positions where `entry_date == today` (Rule 15). The remaining list is
"actionable". If the list is empty, skip to STEP 7.

## STEP 4 — Decide actions per actionable position

For each position, check thresholds in this order. Only the FIRST matching
threshold triggers an action:

1. **Hard-close** (Rule 7) — `unrealized_pl_pct ≤ -7`:
   - Action: market sell entire position
   - This is a sell → `DTC` pre-flight already passed (it's < 2 by virtue of reaching this step)

2. **Tighten to 5%** (Rule 8) — `unrealized_pl_pct ≥ +20`:
   - Action: `replace-stop` with `trail_percent=5` for the position's current trailing stop
   - This is NOT a sell — it's a stop replacement. No `DTC` impact.

3. **Tighten to 7%** (Rule 8) — `unrealized_pl_pct ≥ +15` AND current trail isn't already ≤ 7:
   - Action: `replace-stop` with `trail_percent=7`

4. **Sector-kill** (Rule 10) — sector has 2 consecutive losses in TRADE-LOG.md tail:
   - Action: market sell ALL actionable positions in this sector
   - Each sell counts toward `DTC` — if multiple sector positions exist, the
     pre-flight may pass for the first but fail mid-execution. Re-check `DTC`
     before each individual sell within the sector kill loop.

5. Otherwise: no action.

## STEP 5 — Execute actions

For each scheduled action:

```
# Hard-close or sector-kill
bash scripts/alpaca.sh close TICKER

# Tighten stop
bash scripts/alpaca.sh replace-stop EXISTING_ORDER_ID TICKER QTY NEW_TRAIL_PCT
```

After each individual sell, refresh `account.daytrade_count`:
```
DTC=$(bash scripts/alpaca.sh account | python3 -c "import json,sys; print(json.load(sys.stdin)['daytrade_count'])")
```

If `DTC` reaches 2 mid-loop, ABORT remaining sells (sector-kill or otherwise),
send URGENT Telegram, commit progress so far, exit.

## STEP 6 — Append action rows to `memory/TRADE-LOG.md`

For each completed sell, append an EXIT trade row:
```
### YYYY-MM-DD — TRADE: TICKER side=sell qty=N
- Exit: $X
- Stop level: <was: trail N% / fixed $X — fired: yes/no/manual>
- Thesis: <closed via Rule 7 / 8 / 10 — one phrase>
- Catalyst: <links back to original BUY's pm-YYYY-MM-DD-TICKER>
- Target: <was $X, R:R X:1>
- Realized P&L: $X (X.X%)
```

For each stop tightening, append a STOP UPDATE row:
```
### YYYY-MM-DD — STOP UPDATE: TICKER trail %X -> %Y
- Trigger: +15% gain / +20% gain (Rule 8)
- New stop order ID: <id from replace-stop response>
```

## STEP 7 — Telegram

- Silent if no actions taken AND `DTC < 2`.
- Otherwise: ONE summary message listing actions taken (or aborts).
  - URGENT prefix on hard-close, sector-kill, or DTC abort.
  - Format: `*MIDDAY MMM DD* (paper)\nActions: <ticker actions>\nDTC: <N>`

## STEP 8 — COMMIT AND PUSH (mandatory)

```
git add memory/TRADE-LOG.md memory/HEARTBEAT.md
git commit -m "midday $DATE: <summary>"
git push origin main
```

On push failure: `git pull --rebase origin main` then push again. Never `--force`.
```

- [ ] **Step 2: Verify required sections present**

```bash
grep -E "^## (OVERRIDE|IMPORTANT|STEP)" routines/midday.md
```

Expected: OVERRIDE, IMPORTANT — ENVIRONMENT VARIABLES, IMPORTANT — VISA-AWARE RULES, IMPORTANT — PERSISTENCE, STEP 1 through STEP 8.

- [ ] **Step 3: Verify visa rules + DTC pre-flight present**

```bash
grep -c "Rule 14\|daytrade_count\|DTC" routines/midday.md
```

Expected: ≥6 mentions.

- [ ] **Step 4: Commit**

```bash
git add routines/midday.md
git commit -m "feat(routines): add midday cloud routine (Rule 7 + 8 + 10 enforcer)

Fires at 12:00 CT. Hard-closes losers ≤-7%, tightens trails at +15%/+20%,
sector-kills on 2 consecutive sector losses. All sells gated by Rule 14
DTC pre-flight (abort if DTC >= 2). All actions skip same-day positions
per Rule 15."
```

---

## Task 10: Write `.claude/commands/midday.md` local mirror

**Files:**
- Create: `.claude/commands/midday.md`

- [ ] **Step 1: Create `.claude/commands/midday.md`**

```markdown
---
description: Midday position management (local mirror of cloud routine; no commit/push)
---

You are running the **midday position-management workflow** locally. Resolve
today's date with `DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

This is a v2 paper run. Sells may execute if `TRADING_ENABLED=true`.

## Visa-aware gates (READ FIRST)
- Rule 14: pre-flight `account.daytrade_count`. If ≥ 2, abort all sells.
- Rule 15: positions opened today are read-only. Do not act on them.

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md`
- Tail of `memory/TRADE-LOG.md` (positions, entry dates, sector tally)

## Step 2 — Pull state
```
bash scripts/alpaca.sh account     # capture daytrade_count as DTC
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
```
If `DTC >= 2`, abort all sells; just print which sells you would have done; exit.

## Step 3 — Filter actionable
Drop positions where `entry_date == today` (per TRADE-LOG.md tail). Compute
`unrealized_pl_pct` for the rest.

## Step 4 — Decide actions (in priority order, first match wins)
1. ≤ -7% → hard-close (Rule 7)
2. ≥ +20% → replace-stop trail=5 (Rule 8)
3. ≥ +15% (and current trail > 7) → replace-stop trail=7 (Rule 8)
4. Sector with 2 consecutive losses → close all actionable positions in sector (Rule 10)
5. Else: no action

## Step 5 — Execute
```
bash scripts/alpaca.sh close TICKER                                  # hard-close / sector-kill
bash scripts/alpaca.sh replace-stop ORDER_ID TICKER QTY NEW_TRAIL    # tighten
```
Refresh DTC between sells. Abort if DTC reaches 2.

## Step 6 — Append action rows to `memory/TRADE-LOG.md` (locally)
Use the EXIT or STOP UPDATE schemas in the top of TRADE-LOG.md.

## Step 7 — Telegram
Silent if no actions and DTC < 2. Otherwise one summary with URGENT prefix on hard-close/sector-kill/abort.

## Step 8 — Skip commit
Local mode does not auto-commit.
```

- [ ] **Step 2: Verify**

```bash
test -f .claude/commands/midday.md && grep -c "Rule 14\|DTC" .claude/commands/midday.md
```

Expected: file exists, ≥3 mentions.

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/midday.md
git commit -m "feat(commands): add /midday local mirror"
```

---

## Task 11: Update `routines/daily-summary.md` for stop placement + heartbeat

**Files:**
- Modify: `routines/daily-summary.md`

Daily-summary in v2 gains two responsibilities: place trailing-stop GTC orders for any positions opened today (Rule 13) and check the 48h heartbeat ledger.

- [ ] **Step 1: Locate the v1 `## STEP 4 — Append EOD snapshot` section**

```bash
grep -n "^## STEP" routines/daily-summary.md
```

Note line numbers.

- [ ] **Step 2: Insert a new STEP 4 (stop placement) before the existing snapshot step, and renumber subsequent steps**

The new full step list will be:
- STEP 1 (existing) — Read memory for continuity
- STEP 2 (existing) — Pull final state of the day
- STEP 3 (existing) — Compute metrics
- **STEP 4 (NEW)** — Place trailing stops for today's new positions
- **STEP 5 (NEW)** — Heartbeat check
- STEP 6 (was STEP 4) — Append EOD snapshot to TRADE-LOG.md
- STEP 7 (was STEP 5) — Send Telegram
- STEP 8 (was STEP 6) — Commit and push

Edit `routines/daily-summary.md`. Find the line `## STEP 4 — Append EOD snapshot to memory/TRADE-LOG.md`. Insert the following two NEW steps immediately before it:

```markdown
## STEP 4 — Place trailing stops for today's new positions (Rule 13, visa-aware)

For each position opened today (entry_date == today, identifiable from
TRADE-LOG.md BUY rows committed earlier today by `market-open`), place a
trailing-stop GTC order. This routine fires at 15:00 CT exactly = 16:00 ET =
NYSE close, so the order queues in Alpaca's GTC book without firing same-day
(`extended_hours=false` is set in the wrapper).

For each today-opened position with no existing trailing stop:
```
TRAIL_PCT=10  # default per TRADING-STRATEGY.md Rule 6 unless idea specified otherwise
bash scripts/alpaca.sh trailing-stop TICKER QTY $TRAIL_PCT
```

If a today-opened position already has a trailing stop in `bash scripts/alpaca.sh orders open`,
SKIP it (idempotency — daily-summary may have run before via Run-now).

After each successful stop placement, append a STOP PLACED row to TRADE-LOG.md:

```
### YYYY-MM-DD — STOP PLACED: TICKER trail %N
- Order ID: <from response>
- Trigger reason: routine placement at market close (Rule 13)
- Links to BUY: pm-YYYY-MM-DD-TICKER
```

## STEP 5 — Heartbeat check (DECIDED J)

Read `memory/HEARTBEAT.md`:
```
LAST_TG=$(grep "^last_telegram: " memory/HEARTBEAT.md | sed 's/last_telegram: //')
```

Compute hours since:
```
NOW=$(date -u +%s)
LAST_S=$(date -u -d "$LAST_TG" +%s 2>/dev/null || python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$LAST_TG'.replace('Z','+00:00')).timestamp()))")
HOURS_SINCE=$(( (NOW - LAST_S) / 3600 ))
```

If `HOURS_SINCE >= 48`, set `HEARTBEAT_PREFIX` to:
`"Heartbeat: ${HOURS_SINCE}h silence — system alive\n"`

Otherwise empty string. The prefix gets prepended to the EOD Telegram body in STEP 7.
```

- [ ] **Step 3: Renumber existing steps 4-6 to 6-8**

In the same file, change:
- `## STEP 4 — Append EOD snapshot to memory/TRADE-LOG.md` → `## STEP 6 — Append EOD snapshot to memory/TRADE-LOG.md`
- `## STEP 5 — Send ONE Telegram message (always)` → `## STEP 7 — Send ONE Telegram message (always)`
- `## STEP 6 — COMMIT AND PUSH (mandatory)` → `## STEP 8 — COMMIT AND PUSH (mandatory)`

- [ ] **Step 4: Update STEP 7 (Telegram body) to include the heartbeat prefix**

In the renumbered STEP 7, find the `bash scripts/telegram.sh "*EOD ...` block. Modify it to prepend the heartbeat prefix:

```
bash scripts/telegram.sh "${HEARTBEAT_PREFIX}*EOD <MMM DD>* (paper)
Equity: \$<X> (<±X%> day, <±X%> phase)
Cash: \$<X>
Trades today: <N opened, K closed>
Open positions: <N tickers> (<sector breakdown>)
Stops placed at close: <K positions>
Pre-market plan today: <decision from today's research log>
Tomorrow: pre-market checks at 6:00 CT"
```

- [ ] **Step 5: Update STEP 8 git add to include HEARTBEAT.md**

In the renumbered STEP 8, change:
```
git add memory/TRADE-LOG.md
```
to:
```
git add memory/TRADE-LOG.md memory/HEARTBEAT.md
```

- [ ] **Step 6: Verify section structure**

```bash
grep -E "^## STEP" routines/daily-summary.md
```

Expected: 8 STEP headers, numbered 1–8 in order.

- [ ] **Step 7: Verify visa rule + heartbeat references**

```bash
grep -c "Rule 13\|HEARTBEAT" routines/daily-summary.md
```

Expected: ≥3.

- [ ] **Step 8: Commit**

```bash
git add routines/daily-summary.md
git commit -m "feat(daily-summary): place trailing stops at close + 48h heartbeat

Two v2 expansions:
1. STEP 4 — place trailing-stop GTC for today's new positions (per Rule 13,
   placed at 15:00 CT = market close so cannot fire same-day).
2. STEP 5 — read memory/HEARTBEAT.md, compute hours since last Telegram;
   if >= 48h, prepend heartbeat marker to the EOD Telegram body.

Existing STEPs 4-6 renumbered to 6-8. Step 8 git add now includes
memory/HEARTBEAT.md so the ledger persists.

NOTE: cloud routine prompt must be re-pasted in Anthropic Routines UI."
```

---

## Task 12: Mirror daily-summary changes in `.claude/commands/daily-summary.md`

**Files:**
- Modify: `.claude/commands/daily-summary.md`

- [ ] **Step 1: Read existing local mirror**

```bash
cat .claude/commands/daily-summary.md
```

- [ ] **Step 2: Edit to add stop placement and heartbeat steps**

Replace the existing STEP block (after the frontmatter and intro) with:

```markdown
This is a v2 paper run. EOD snapshot + stop placement + heartbeat check.

## Step 1 — Read memory for continuity
- Tail of `memory/TRADE-LOG.md` — yesterday's equity + today's BUY rows
- Today's `memory/RESEARCH-LOG.md` entry (for pre-market summary in EOD body)

## Step 2 — Pull final state of the day
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
bash scripts/alpaca.sh activities  # for realized P&L from any closes today
```

## Step 3 — Compute metrics
- Day P&L (realized + unrealized vs yesterday's equity)
- Phase P&L (vs $10K Day 0 baseline)
- Trades today: count BUY rows + EXIT rows committed today

## Step 4 — Place trailing stops for today's new positions (Rule 13)
For each position opened today with no existing trailing stop:
```
bash scripts/alpaca.sh trailing-stop TICKER QTY 10  # default 10% trail per Rule 6
```
Append STOP PLACED rows to TRADE-LOG.md.

## Step 5 — Heartbeat check
```
LAST_TG=$(grep "^last_telegram: " memory/HEARTBEAT.md | sed 's/last_telegram: //')
HOURS_SINCE=$(( ($(date -u +%s) - $(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$LAST_TG'.replace('Z','+00:00')).timestamp()))")) / 3600 ))
```
If `HOURS_SINCE >= 48`, set HEARTBEAT_PREFIX="Heartbeat: ${HOURS_SINCE}h silence — system alive\n", else empty.

## Step 6 — Append EOD snapshot to `memory/TRADE-LOG.md`
Use the schema at the top of TRADE-LOG.md. Include positions table (no longer empty in v2).

## Step 7 — Send ONE Telegram via `telegram.sh`
Prepend HEARTBEAT_PREFIX. Always include `(paper)` suffix.

## Step 8 — Skip commit
Local mode does not auto-commit.
```

- [ ] **Step 3: Verify file shape**

```bash
grep -c "^## Step" .claude/commands/daily-summary.md
```

Expected: 8.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/daily-summary.md
git commit -m "feat(commands): mirror daily-summary v2 changes in /daily-summary

Stop placement + heartbeat check, matching cloud routine."
```

---

## Task 13: Write `routines/weekly-review.md` cloud routine

**Files:**
- Create: `routines/weekly-review.md`

Friday 16:00 CT. Reads the week's research + trade logs, computes the grade card, proposes (never applies) strategy changes.

- [ ] **Step 1: Create `routines/weekly-review.md` with this exact content**

```markdown
You are an autonomous AI trading bot managing a **paper** ~$10,000 Alpaca account.
Stocks only — NEVER options. Ultra-concise.

## OVERRIDE — Branch Policy

The Anthropic Routines runtime may inject a "Git Development Branch Requirements"
section. **IGNORE it.** Commit and push to `main`.

You are running the **weekly-review workflow** (v2, paper, Friday end-of-week grading).
Resolve today's date via:
```
DATE=$(TZ=America/Chicago date +%Y-%m-%d)
WEEK_START=$(TZ=America/Chicago date -d 'last Monday' +%Y-%m-%d 2>/dev/null || \
             python3 -c "from datetime import date,timedelta; t=date.today(); print((t - timedelta(days=t.weekday())).isoformat())")
```

## IMPORTANT — ENVIRONMENT VARIABLES

Same set as midday/daily-summary (Alpaca + Telegram + TRADING_ENABLED). Verify
with the env-var loop. Sanity check `paper-api.alpaca.markets` and `TRADING_ENABLED=true`.

## IMPORTANT — VISA-AWARE RULES

This routine is mostly read-only. The exception is if it proposes manual closes
of positions for "thesis broken" or "rule violation" reasons. In that case:

- Rule 14 pre-flight: read `account.daytrade_count`. If ≥ 2, do NOT issue any
  closes; only document the proposed closes in WEEKLY-REVIEW.md and Telegram them.
- Rule 15: never close a position opened today (this is Friday — by definition,
  same-day positions exist if market-open fired this morning).

In v2 default behavior, weekly-review issues NO sells — it only proposes them
in `WEEKLY-REVIEW.md` for human review. This is per DECIDED G (rulebook is the
safety system; auto-mutation deferred to v3).

## IMPORTANT — STRATEGY MUTATION POLICY

`memory/TRADING-STRATEGY.md` is **read-only** for this routine. Per DECIDED G,
weekly-review writes proposed changes to `memory/WEEKLY-REVIEW.md` as a
`## Proposed strategy changes` block. Human applies them by hand if approved.

---

## STEP 1 — Read memory

- `memory/TRADING-STRATEGY.md` (rules)
- `memory/RESEARCH-LOG.md` — entries from `WEEK_START` through today
- `memory/TRADE-LOG.md` — entries from `WEEK_START` through today
- `memory/WEEKLY-REVIEW.md` — last week's review (for prior-week comparison)

## STEP 2 — Pull state

```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh activities $WEEK_START  # all activities since week start
```

## STEP 3 — Compute the weekly grade card

Compute from the read-in data:

| Metric | Source |
|--------|--------|
| Starting portfolio | EOD snapshot from prior Friday (or Day 0 baseline if week 1) |
| Ending portfolio | `account.equity` |
| Week return | `(ending - starting) / starting * 100`, $ and % |
| S&P 500 week | from Perplexity if available, else mark "n/a" |
| Trades placed | count of BUY rows in TRADE-LOG.md this week |
| Win rate | (closed winners) / (closed total) |
| Best trade | highest realized P&L % |
| Worst trade | lowest realized P&L % |
| Profit factor | sum(gains) / abs(sum(losses)) |
| daytrade_count delta | `account.daytrade_count` now vs prior Friday |
| Rule violations (audit) | scan TRADE-LOG.md for: positions > 20% (Rule 3); missing trailing stops (Rule 6); -7% closes that exceeded -10% (Rule 7 timeout); Rule 13 violations (stop placed before market close); Rule 14 abort events |

## STEP 4 — Append week-summary to `memory/TRADE-LOG.md`

```
### YYYY-MM-DD — WEEK SUMMARY (Week ending DATE)
- Trades placed: N (W:X / L:Y / open:Z)
- Week P&L: $X (X.X%)
- Phase P&L: $X (X.X%)
- Best: TICKER +X%
- Worst: TICKER -X%
- daytrade_count delta: 0 -> N
- Rule violations: <list, or "none">
```

## STEP 5 — Append entry to `memory/WEEKLY-REVIEW.md`

Use the template at the top of `memory/WEEKLY-REVIEW.md`. Fill in every section
(stats table, closed trades, open positions, what worked, what didn't, lessons,
adjustments, grade A/B/C/D/F).

If proposed strategy changes exist, append a `## Proposed strategy changes` block:

```
## Proposed strategy changes (NOT auto-applied — human review required)

- Rule X (proposed change): <description>
- Rationale: <one sentence>
- Evidence: <reference to TRADE-LOG.md entries supporting this>
```

## STEP 6 — Telegram (1 message)

```
bash scripts/telegram.sh "*WEEK $WEEK_START → $DATE* (paper)
Week return: \$<X> (<±X%>)
Trades: <N> (W:<X> / L:<Y> / open:<Z>)
Best: <TICKER +X%> | Worst: <TICKER -X%>
DTC delta: 0 -> <N>
Rule violations: <count>
<if proposed changes:> Strategy changes proposed — review WEEKLY-REVIEW.md before Mon"
```

## STEP 7 — COMMIT AND PUSH (mandatory)

```
git add memory/TRADE-LOG.md memory/WEEKLY-REVIEW.md memory/HEARTBEAT.md
git commit -m "weekly-review $DATE"
git push origin main
```

On push failure: `git pull --rebase origin main` then push again. Never `--force`.
```

- [ ] **Step 2: Verify required sections + DECIDED G language**

```bash
grep -E "^## (OVERRIDE|IMPORTANT|STEP)" routines/weekly-review.md
grep -c "DECIDED G\|read-only\|propose-only\|auto-applied" routines/weekly-review.md
```

Expected: 7 STEPs + IMPORTANT blocks; ≥3 mentions of read-only/propose semantics.

- [ ] **Step 3: Commit**

```bash
git add routines/weekly-review.md
git commit -m "feat(routines): add weekly-review cloud routine

Friday 16:00 CT. Computes weekly grade card, audits TRADE-LOG.md for rule
violations, appends entry to WEEKLY-REVIEW.md. Per DECIDED G,
TRADING-STRATEGY.md is read-only — proposed changes go to WEEKLY-REVIEW.md
under '## Proposed strategy changes' for human review only."
```

---

## Task 14: Write `.claude/commands/weekly-review.md` local mirror

**Files:**
- Create: `.claude/commands/weekly-review.md`

- [ ] **Step 1: Create file**

```markdown
---
description: Weekly review (local mirror of cloud routine; no commit/push)
---

You are running the **weekly-review workflow** locally for week ending today.
`DATE=$(TZ=America/Chicago date +%Y-%m-%d)`.

## Strategy mutation policy
`memory/TRADING-STRATEGY.md` is read-only here. Proposed changes go to
`memory/WEEKLY-REVIEW.md` under `## Proposed strategy changes`. Human applies
them by hand.

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md`
- This week's `memory/RESEARCH-LOG.md` and `memory/TRADE-LOG.md` entries
- Last week's `memory/WEEKLY-REVIEW.md` entry

## Step 2 — Pull state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh activities $(TZ=America/Chicago date -d 'last Monday' +%Y-%m-%d)
```

## Step 3 — Compute grade card
Stats: starting/ending portfolio, week return, S&P comparison if known, trades placed,
win rate, best/worst, profit factor, daytrade_count delta, rule violations audit.

## Step 4 — Append week-summary to `memory/TRADE-LOG.md`

## Step 5 — Append entry to `memory/WEEKLY-REVIEW.md`
Use the template at the top of WEEKLY-REVIEW.md. Add `## Proposed strategy changes` block if any.

## Step 6 — Telegram (1 message)

## Step 7 — Skip commit
Local mode does not auto-commit.
```

- [ ] **Step 2: Verify**

```bash
test -f .claude/commands/weekly-review.md && grep -c "Step" .claude/commands/weekly-review.md
```

Expected: file exists, 7 step headers.

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/weekly-review.md
git commit -m "feat(commands): add /weekly-review local mirror"
```

---

## Task 15: Write `.claude/commands/trade.md` for manual one-off trades

**Files:**
- Create: `.claude/commands/trade.md`

For ad-hoc manual trades (e.g., user wants to enter a single position outside the routine schedule). Same buy-side gate, same risk-parity sizing, but operates on a user-specified ticker without going through pre-market.

- [ ] **Step 1: Create file**

```markdown
---
description: Manual one-off trade entry (subject to all v2 buy-side gates and risk rules)
---

You are running a **manual trade entry**. Args from the user: `TICKER`, optional
`THESIS`, optional `STOP_PCT` (default 10).

ALL routine gates apply: Buy-Side Gate from `TRADING-STRATEGY.md`, Rule 14
daytrade_count pre-flight, Rule 15 same-day skip (not relevant here since this
IS a same-day buy — but no sell will happen until T+1).

## Step 1 — Read memory
- `memory/TRADING-STRATEGY.md`
- `memory/TRADE-LOG.md` tail
- Today's `memory/RESEARCH-LOG.md` if it exists (for sector context)

## Step 2 — Pull state
```
bash scripts/alpaca.sh account
bash scripts/alpaca.sh positions
bash scripts/alpaca.sh orders open
bash scripts/alpaca.sh quote TICKER
```

## Step 3 — Apply Buy-Side Gate
- Total positions ≤ 6
- Trades this week ≤ 3 (use TRADE-LOG.md tail to count)
- Position cost ≤ 20% equity
- Position cost ≤ available cash
- `account.daytrade_count <= 1` (Rule 14 buffer)
- TICKER is a stock

If any check fails, STOP and report which.

## Step 4 — Risk-parity size
```
dollar_risk = (RISK_PER_TRADE_PCT/100) * equity         # default 2% = $200
shares_by_risk = floor(dollar_risk / (entry * STOP_PCT/100))
shares_by_cap  = floor((MAX_POSITION_PCT/100) * equity / entry)
shares = min(shares_by_risk, shares_by_cap)
```

## Step 5 — Place limit order
```
limit = round(quote.ask * (1 + MAX_ENTRY_SLIPPAGE_PCT/100), 2)
bash scripts/alpaca.sh order '{"symbol":"TICKER","qty":SHARES,"side":"buy","type":"limit","limit_price":"X","time_in_force":"day"}'
```

## Step 6 — Append BUY trade row
Schema from TRADE-LOG.md. Catalyst: `manual-YYYY-MM-DD-TICKER` (use a `manual-`
prefix so it's distinguishable from `pm-` ideas).

## Step 7 — Telegram one fill confirmation

## Step 8 — Stop placement deferred
Like market-open, this command does NOT place a trailing stop. The next
`daily-summary` run at 15:00 CT will place it (Rule 13).

## Step 9 — Skip commit
Local mode does not auto-commit. Review and commit by hand if keeping.
```

- [ ] **Step 2: Verify**

```bash
test -f .claude/commands/trade.md && grep -c "Buy-Side Gate\|Rule 14\|Rule 13" .claude/commands/trade.md
```

Expected: file exists, ≥3 mentions.

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/trade.md
git commit -m "feat(commands): add /trade manual one-off entry slash command

Same Buy-Side Gate + risk-parity sizing as market-open. Catalyst prefix
'manual-' distinguishes hand-entered trades from pm-routine ideas. No stop
placement (Rule 13 — daily-summary handles it)."
```

---

## Task 16: Update `routines/README.md` with v2 routine setup

**Files:**
- Modify: `routines/README.md`

- [ ] **Step 1: Find the v2 placeholder section**

```bash
grep -n "## v2 routines (not built yet)" routines/README.md
```

- [ ] **Step 2: Replace it with active v2 setup instructions**

Find the section beginning `## v2 routines (not built yet)` and replace its body (including the next paragraph or two until the following `##` heading) with:

```markdown
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
```

- [ ] **Step 3: Verify**

```bash
grep "v2 routines (active)" routines/README.md
grep -c "Rule 14\|Rule 15\|daytrade_count" routines/README.md
```

Expected: section exists; ≥3 visa-rule mentions.

- [ ] **Step 4: Commit**

```bash
git add routines/README.md
git commit -m "docs(routines): document v2 setup, env vars, activation order

Replaces v1 'not built yet' placeholder. Includes the visa-aware safety
chain summary so anyone forking the repo understands why stops are placed
at market close instead of at entry."
```

---

## Task 17: Update root `CLAUDE.md` with v2 changes

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Read current CLAUDE.md to see what to update**

```bash
cat CLAUDE.md
```

- [ ] **Step 2: Update the Mode + Daily Workflows + Strategy Hard Rules sections**

Edit `CLAUDE.md`:

In the **Mode (v1)** section, change the heading and content to:

```markdown
## Mode (v2)
- **Paper only.** `TRADING_ENABLED=true` (was `false` in v1).
- Wrapper-side kill-switch in `scripts/alpaca.sh` still gates state-changing subcommands; in v2 the env says `true` so they execute.
- Visa-aware: zero day trades by construction (Rules 13–15). If `daytrade_count` ever ≥ 2, all sells abort with Telegram URGENT.
```

In the **Daily Workflows** section, replace the active-routine list with:

```markdown
- `pre-market` — research only, writes `RESEARCH-LOG.md` with R:R-ranked ideas (each tagged `pm-YYYY-MM-DD-TICKER`)
- `market-open` — applies Buy-Side Gate, places limit-with-slippage entries (no stops)
- `midday` — hard-closes losers ≤-7%, tightens stops at +15%/+20%, sector-kills on 2 consecutive losses; all gated by Rule 14 + 15
- `daily-summary` — places trailing stops for today's new positions (Rule 13), writes EOD snapshot + heartbeat
- `weekly-review` — Friday 16:00 CT grade card; proposes strategy changes (never auto-applies — DECIDED G)
```

In **Strategy Hard Rules**, append three new lines after the existing list:

```markdown
- **Rule 13** — stops placed at daily-summary T 15:00 CT (market close), not entry, so they cannot fire same-day *(v2, visa-aware)*
- **Rule 14** — pre-flight `daytrade_count` before every sell; abort + Telegram URGENT if ≥2 *(v2, visa-aware)*
- **Rule 15** — midday hard-close + sector-kill skip positions opened today *(v2, visa-aware)*
```

- [ ] **Step 3: Verify**

```bash
grep -c "Rule 13\|Rule 14\|Rule 15" CLAUDE.md
grep -c "market-open\|midday\|weekly-review" CLAUDE.md
```

Expected: ≥3 for visa rules, ≥3 for v2 routines.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): update agent identity for v2 (5 routines, Rules 13-15)

Mode flipped to v2 (TRADING_ENABLED=true). Daily Workflows lists all five
active routines. Strategy Hard Rules quick-reference includes the three
visa-aware rules added during v2 brainstorming."
```

---

## Task 18: Document the Anthropic Routines cloud setup checklist

**Files:**
- Create: `routines/v2-cloud-setup-checklist.md`

A step-by-step ordered checklist for setting up the three new routines + re-pasting the two updated routines in the Anthropic Routines UI. This is the operational artifact the user runs through when going from "code merged to main" to "cloud routines firing".

- [ ] **Step 1: Create the checklist file**

```markdown
# auto_invest v2 — Cloud Setup Checklist

Run through this checklist after merging v2 to `main`. Each routine is set up
the same way as v1: copy the file's contents into the Anthropic Routines UI's
Prompt field, set env vars in the env-vars textbox, set the cron schedule and
TZ, save, smoke-test with Run now.

**Pre-flight (one-time):**

- [ ] All v2 commits on `main`. Verify: `git log --oneline -20 origin/main` shows
      tasks 1–17 above.
- [ ] v1 criterion #1 closed (5/5 clean cron weekdays). Verify: see plan header.
- [ ] Local tests pass: `bash tests/run_all.sh`.

## Stage 1 — Re-paste pre-market with v2 idea-ID + R:R ranking

- [ ] Open `auto_invest pre-market` routine in Anthropic Routines UI.
- [ ] Copy entire contents of `routines/pre-market.md`. Paste into Prompt field. Save.
- [ ] Click "Run now". Watch the live log:
      - Env-var loop should print 7 vars `set` (Perplexity may be `MISSING` if you removed it during fallback test — restore it).
      - RESEARCH-LOG entry appears with `**ID:** pm-YYYY-MM-DD-TICKER` lines per idea.
      - Ideas listed in R:R-descending order.
- [ ] Pull main locally: `git pull --rebase origin main`. Verify the new entry shape.

## Stage 2 — Re-paste daily-summary with stop placement + heartbeat

- [ ] Add new env vars to the routine's textbox (in addition to v1 set):
      - `TRADING_ENABLED=true` (replace the v1 `false`)
      - `MAX_ENTRY_SLIPPAGE_PCT=0.10`
      - `RISK_PER_TRADE_PCT=2.0`
      - `MAX_POSITION_PCT=20`
- [ ] Copy entire contents of `routines/daily-summary.md`. Paste into Prompt field. Save.
- [ ] Click "Run now". Watch the live log:
      - `TRADING_ENABLED=true` printed in env-var loop.
      - If positions are open from earlier today (none expected at this stage): trailing stops placed.
      - Heartbeat check runs (almost certainly NOT prepended — last_telegram is recent).
      - EOD message sent.
- [ ] Pull main locally. Verify HEARTBEAT.md timestamp updated to ~just now.

## Stage 3 — Set up `auto_invest market-open` (NEW)

- [ ] In Anthropic Routines UI: New Routine.
- [ ] Name: `auto_invest market-open`
- [ ] Repository: `dntounis/auto_invest`
- [ ] Branch: `main`
- [ ] Cron schedule: `30 8 * * 1-5`, TZ: `America/Chicago`
- [ ] Env vars (copy entire set from daily-summary including the new v2 ones).
- [ ] Setup script: same trivial passthrough as v1 (`#!/bin/bash; echo ...; exit 0`).
- [ ] "Allow unrestricted branch pushes": ON.
- [ ] Prompt: paste entire contents of `routines/market-open.md` verbatim.
- [ ] Save.
- [ ] Click "Run now" smoke test (the routine will likely no-op if no fresh
      RESEARCH-LOG entry exists yet — verify the no-op path runs cleanly).

## Stage 4 — Set up `auto_invest midday` (NEW)

- [ ] New Routine. Name: `auto_invest midday`. Branch: main. Cron: `0 12 * * 1-5` America/Chicago.
- [ ] Env vars: same as market-open.
- [ ] Setup script: same trivial passthrough.
- [ ] Allow unrestricted branch pushes: ON.
- [ ] Prompt: paste entire contents of `routines/midday.md` verbatim.
- [ ] Save.
- [ ] Click "Run now" smoke test (will no-op if no actionable positions — verify clean run).

## Stage 5 — Set up `auto_invest weekly-review` (NEW)

- [ ] New Routine. Name: `auto_invest weekly-review`. Branch: main. Cron: `0 16 * * 5` America/Chicago.
- [ ] Env vars: same as midday.
- [ ] Setup script: same trivial passthrough.
- [ ] Allow unrestricted branch pushes: ON.
- [ ] Prompt: paste entire contents of `routines/weekly-review.md` verbatim.
- [ ] Save. (Don't smoke-test yet — wait for first natural Friday firing OR
      manually invoke after Stage 4 runs are done.)

## Stage 6 — First-day observation

- [ ] Wait for Monday's natural firings:
      - 06:00 CT pre-market: silent unless macro-urgent
      - 08:30 CT market-open: 0–N orders depending on RESEARCH-LOG ideas
      - 12:00 CT midday: silent unless action; placeholder run with no
        actionable positions on Day 1
      - 15:00 CT daily-summary: EOD with stop placements for any new positions
- [ ] Verify each fired by checking `git log --oneline origin/main` for the
      four expected commits.
- [ ] Inspect `bash scripts/alpaca.sh orders` — every position opened should
      have a corresponding trailing-stop GTC by 15:30 CT.
- [ ] Inspect `bash scripts/alpaca.sh account` — `daytrade_count` should be 0
      (no day trades possible by Day 1 design).

## v2 exit criteria observation

After the first clean day, observe for 2 weeks (10 weekdays). All v2 exit
criteria from the spec § 10 must hold. If `daytrade_count` ever exceeds 2,
investigate immediately — the visa-safety design has a leak.
```

- [ ] **Step 2: Verify**

```bash
test -f routines/v2-cloud-setup-checklist.md && wc -l routines/v2-cloud-setup-checklist.md
```

Expected: file exists, ≥80 lines.

- [ ] **Step 3: Commit**

```bash
git add routines/v2-cloud-setup-checklist.md
git commit -m "docs(routines): v2 cloud setup checklist for Anthropic Routines UI

Step-by-step from 'merged to main' to 'all 5 routines firing'. Six stages:
re-paste pre-market, re-paste daily-summary, set up market-open, midday,
weekly-review, then Day 1 observation."
```

---

## Self-review (post-write check)

After all 18 tasks above are written, verify:

**1. Spec coverage:**
- DECIDED A (server-side trailing stops at daily-summary) → covered by Tasks 1, 11, 12
- DECIDED B (limit @ ask + slippage) → covered by Tasks 7, 8, 15
- DECIDED C (R:R rank, weekly-cap respect) → covered by Tasks 6, 7, 8
- DECIDED D (risk-parity sizing) → covered by Tasks 7, 8, 15
- DECIDED E (midday actions, same-day skip) → covered by Tasks 9, 10
- DECIDED F (midday -7% with same-day skip) → covered by Tasks 9, 10
- DECIDED G (weekly-review propose-only) → covered by Tasks 13, 14
- DECIDED H (idempotency from Alpaca state) → covered by Tasks 7, 8
- DECIDED I (pm-YYYY-MM-DD-TICKER ID) → covered by Task 6 (pre-market) + Tasks 7, 8, 15 (consumers)
- DECIDED J (Telegram volume + heartbeat) → covered by Tasks 4, 5, 11, 12
- Rules 13, 14, 15 in TRADING-STRATEGY.md → already committed in spec-lock commit `5939501`
- Cloud setup → covered by Task 18

**2. Placeholder scan:** None. Every step has full code or full content.

**3. Type/name consistency:** `pm-YYYY-MM-DD-TICKER` used uniformly. `daytrade_count`/`DTC` aliasing is clear (DTC is the local var name, daytrade_count is the API field). `MAX_ENTRY_SLIPPAGE_PCT`, `RISK_PER_TRADE_PCT`, `MAX_POSITION_PCT` used consistently. `trailing-stop` and `replace-stop` subcommand names match between alpaca.sh and the routine prompts.

**4. Note for the implementer:** the routine prompt files in `routines/` change behavior in cloud only after they are re-pasted into the Anthropic Routines UI's Prompt field. The git fix does not auto-propagate. This is documented in Task 18 (cloud setup checklist).

---

## Plan complete

Plan saved to `docs/superpowers/plans/2026-05-05-auto-invest-v2.md`.

**Recommended execution mode:** Subagent-Driven Development. Each task is self-contained with full code and exact commands; subagents can be dispatched in sequence with two-stage review (spec compliance + code quality) per the subagent-driven-development skill.

**Sequencing constraints:**

- Tasks 1–3 (wrappers) must come first; nothing else uses the new subcommands until they exist + tests pass.
- Task 4 (HEARTBEAT.md) before Task 5 (telegram.sh update).
- Task 5 before Tasks 11, 12, 13, 14, 18 (which all reference HEARTBEAT.md).
- Task 6 (pre-market enhancements) before Tasks 7, 8 (market-open consumes the new ID format).
- Within each routine pair (cloud + local mirror), the local mirror can be implemented either before or after the cloud routine — they don't depend on each other.
- Task 18 (cloud setup checklist) is the last task — it operationalizes everything else.

**Estimated implementation time:** ~6–10 hours of focused work (each task is 20–45 min for an implementer plus review).

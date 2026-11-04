#!/usr/bin/env bash
# v3.5: every cloud routine prompt and local command mirror pins the same model.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tests/_lib.sh"
cd "$ROOT"

echo "test_routines.sh"

MODEL="claude-opus-5-5"

for f in routines/pre-market.md routines/market-open.md routines/midday.md \
         routines/daily-summary.md routines/weekly-review.md; do
    start_test "$f pins $MODEL on line 1"
    assert_contains "$(head -1 "$f")" "model: $MODEL"
done

for f in .claude/commands/*.md; do
    start_test "$f frontmatter pins $MODEL"
    fm="$(awk 'NR==1 && /^---$/ {in_fm=1; next} in_fm && /^---$/ {exit} in_fm {print}' "$f")"
    assert_contains "$fm" "model: $MODEL"
done

start_test "no routine or mirror names a different claude model"
stray="$(grep -hoE 'claude-(opus|sonnet|haiku|fable)-[0-9a-z.-]+' routines/*.md .claude/commands/*.md \
         | grep -v "^$MODEL\$" | sort -u)"
assert_eq "" "$stray" "stray model ids"

print_summary

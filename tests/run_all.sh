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

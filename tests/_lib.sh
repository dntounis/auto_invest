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

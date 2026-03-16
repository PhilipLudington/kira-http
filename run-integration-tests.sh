#!/bin/bash
# Integration test runner for kira-http
# Runs tests that require network access (real HTTP requests)
#
# Usage: ./run-integration-tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests/integration"

# Check network connectivity
if ! curl -s --max-time 5 -o /dev/null "https://httpbin.org/get" 2>/dev/null; then
    echo "ERROR: Cannot reach httpbin.org — network required for integration tests"
    exit 1
fi

echo "=== kira-http Integration Tests ==="
echo ""

# Initialize counters
total_passed=0
total_failed=0
total_tests=0

# Run each integration test file
for test_file in "$TESTS_DIR"/test_*.ki; do
    if [ -f "$test_file" ]; then
        echo "Running: $(basename "$test_file")"
        echo ""

        # Capture output, allow non-zero exit
        output=$(kira test "$test_file" 2>&1) || true

        # Parse results
        if echo "$output" | grep -q "All.*tests passed"; then
            summary=$(echo "$output" | grep "All.*tests passed")
            passed=$(echo "$summary" | sed 's/All \([0-9][0-9]*\) tests passed.*/\1/')
            if [ -n "$passed" ] && [ "$passed" -gt 0 ] 2>/dev/null; then
                total_passed=$((total_passed + passed))
                total_tests=$((total_tests + passed))
            fi
        elif echo "$output" | grep -q "passed.*failed.*out of"; then
            summary=$(echo "$output" | grep "passed.*failed.*out of")
            passed=$(echo "$summary" | awk '{print $1}')
            failed=$(echo "$summary" | awk '{print $3}')

            if [ -n "$passed" ] && [ "$passed" -gt 0 ] 2>/dev/null; then
                total_passed=$((total_passed + passed))
            fi
            if [ -n "$failed" ] && [ "$failed" -gt 0 ] 2>/dev/null; then
                total_failed=$((total_failed + failed))
            fi
            if [ -n "$passed" ] && [ -n "$failed" ]; then
                total_tests=$((total_tests + passed + failed))
            fi
        fi

        echo "$output"
        echo ""
    fi
done

echo "=========================================="
echo "Integration: $total_passed passed, $total_failed failed out of $total_tests tests"

if [ "$total_failed" -gt 0 ]; then
    exit 1
fi

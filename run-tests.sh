#!/bin/bash
# GitStat test runner wrapper for kira-http
# Runs all Kira tests and writes results to .test-results.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="$SCRIPT_DIR/.test-results.json"
TESTS_DIR="$SCRIPT_DIR/tests"

# Initialize counters
total_passed=0
total_failed=0
total_tests=0
failures=""

# Run tests on each test file
for test_file in "$TESTS_DIR"/test_*.ki; do
    if [ -f "$test_file" ]; then
        echo "Running: $(basename "$test_file")"

        # Capture output, allow non-zero exit
        output=$(kira test "$test_file" 2>&1) || true

        # Parse the summary line: "X passed, Y failed out of Z tests." or "All X tests passed."
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

        # Collect failure messages
        while IFS= read -r line; do
            if echo "$line" | grep -q "^  FAIL:"; then
                test_name=$(echo "$line" | sed 's/.*FAIL: test "\([^"]*\)".*/\1/')
                if [ -n "$failures" ]; then
                    failures="$failures, \"$test_name\""
                else
                    failures="\"$test_name\""
                fi
            fi
        done <<< "$output"

        echo "$output"
        echo ""
    fi
done

# Write JSON results
if [ -n "$failures" ]; then
    cat > "$RESULTS_FILE" << EOF
{
  "passed": $total_passed,
  "failed": $total_failed,
  "total": $total_tests,
  "failures": [$failures]
}
EOF
else
    cat > "$RESULTS_FILE" << EOF
{
  "passed": $total_passed,
  "failed": $total_failed,
  "total": $total_tests,
  "failures": []
}
EOF
fi

echo "=========================================="
echo "Total: $total_passed passed, $total_failed failed out of $total_tests tests"
echo "Results written to .test-results.json"

# Exit with error if any tests failed
if [ "$total_failed" -gt 0 ]; then
    exit 1
fi

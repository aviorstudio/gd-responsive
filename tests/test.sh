#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

"$SCRIPT_DIR/gate_self_test.sh"

TESTS=(
    tests/responsive_editor_test.gd
    tests/responsive_flex_test.gd
    tests/responsive_grid_test.gd
    tests/responsive_layout_test.gd
    tests/responsive_package_test.gd
    tests/responsive_scale_module_test.gd
)

for test in "${TESTS[@]}"; do
    echo "Running ${test##*/}..."
    "$SCRIPT_DIR/run_godot_test.sh" "$test"
done

echo "TEST_SUITE_PASS scripts=${#TESTS[@]}"

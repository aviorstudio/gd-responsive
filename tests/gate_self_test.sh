#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
RUNNER="$SCRIPT_DIR/run_godot_test.sh"
PARSE_FIXTURE="$SCRIPT_DIR/.gate_parse_failure.gd"
trap 'rm -f "$PARSE_FIXTURE"' EXIT

expect_failure() {
    local name=$1
    shift
    if "$@"; then
        echo "gate control unexpectedly passed: $name" >&2
        exit 1
    fi
    echo "GATE_CONTROL_FAIL_CONFIRMED name=$name"
}

expect_failure missing_script "$RUNNER" tests/does_not_exist.gd

cat > "$PARSE_FIXTURE" <<'EOF'
extends SceneTree
func this_will_not_parse( -> void:
	pass
EOF
expect_failure parse_failure "$RUNNER" tests/.gate_parse_failure.gd

for control in assertion_failure runtime_error unexpected_log_error no_sentinel; do
    expect_failure "$control" env GD_RESPONSIVE_GATE_CONTROL="$control" "$RUNNER" tests/gate_fixture.gd
done
expect_failure timeout env GD_RESPONSIVE_GATE_CONTROL=hang TEST_TIMEOUT_SECONDS=1 "$RUNNER" tests/gate_fixture.gd

"$RUNNER" tests/gate_fixture.gd
echo "GATE_CONTROLS_RESTORED_PASS count=7"

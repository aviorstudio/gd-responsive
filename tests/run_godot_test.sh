#!/usr/bin/env bash
set -uo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 TEST_SCRIPT" >&2
    exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
TEST_SCRIPT=$1
TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-30}

if [ ! -f "$ROOT_DIR/$TEST_SCRIPT" ]; then
    echo "missing test script: $TEST_SCRIPT" >&2
    exit 2
fi

if [ -n "${GODOT_CMD:-}" ]; then
    read -r -a GODOT <<< "$GODOT_CMD"
else
    GODOT=("${GODOT_BIN:-godot}")
fi

LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT

GODOT_ARGS=(--headless)
if [[ "$TEST_SCRIPT" == *_editor_test.gd ]]; then
    GODOT_ARGS+=(--editor)
fi

set +e
timeout --foreground "${TIMEOUT_SECONDS}s" "${GODOT[@]}" "${GODOT_ARGS[@]}" --path "$ROOT_DIR" --script "$TEST_SCRIPT" >"$LOG_FILE" 2>&1
STATUS=$?
set -e

while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line"
done < "$LOG_FILE"

if [ "$STATUS" -eq 124 ]; then
    echo "test timed out after ${TIMEOUT_SECONDS}s: $TEST_SCRIPT" >&2
    exit 1
fi
if [ "$STATUS" -ne 0 ]; then
    echo "test process failed with status $STATUS: $TEST_SCRIPT" >&2
    exit 1
fi

SENTINEL_COUNT=0
ASSERTIONS=0
FAILURES=0
LOG_ERROR=0
while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^GDTEST_SENTINEL\ assertions=([0-9]+)\ failures=([0-9]+)$ ]]; then
        SENTINEL_COUNT=$((SENTINEL_COUNT + 1))
        ASSERTIONS=${BASH_REMATCH[1]}
        FAILURES=${BASH_REMATCH[2]}
    fi
    if [[ "$TEST_SCRIPT" == *_editor_test.gd && ( \
        "$line" == "ERROR: "*" RID allocations of type 'N16RendererViewport8ViewportE' were leaked at exit." \
        || "$line" == "ERROR: "*" RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit." \
        || "$line" == "ERROR: "*" RID allocations of type 'N17RendererSceneCull8ScenarioE' were leaked at exit." \
        || "$line" == "ERROR: "*" RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit." \
        || "$line" == "ERROR: "*" RID allocations of type 'PN18TextServerAdvanced12FontAdvancedE' were leaked at exit." \
    ) ]]; then
        continue
    fi
    if [[ "$line" == ERROR:* || "$line" == "SCRIPT ERROR:"* ]]; then
        LOG_ERROR=1
    fi
done < "$LOG_FILE"

if [ "$SENTINEL_COUNT" -ne 1 ] || [ "$ASSERTIONS" -le 0 ] || [ "$FAILURES" -ne 0 ]; then
    echo "invalid test reach summary: sentinels=$SENTINEL_COUNT assertions=$ASSERTIONS failures=$FAILURES" >&2
    exit 1
fi
if [ "$LOG_ERROR" -ne 0 ]; then
    echo "unexpected Godot error output: $TEST_SCRIPT" >&2
    exit 1
fi

echo "STRICT_TEST_PASS script=$TEST_SCRIPT assertions=$ASSERTIONS"

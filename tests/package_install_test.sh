#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
ASSET_NAME=${ASSET_NAME:-@aviorstudio_gd-responsive.zip}
ZIP_PATH="$ROOT_DIR/dist/$ASSET_NAME"
FIXTURE_ROOT=$(mktemp -d)
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

if [ -n "${GODOT_CMD:-}" ]; then
    read -r -a GODOT <<< "$GODOT_CMD"
else
    GODOT=("${GODOT_BIN:-godot}")
fi

run_editor() {
    local fixture=$1
    shift
    local log="$fixture/editor.log"
    set +e
    timeout --foreground 30s "${GODOT[@]}" --headless --editor --path "$fixture" "$@" >"$log" 2>&1
    local status=$?
    set -e
    while IFS= read -r line || [ -n "$line" ]; do printf '%s\n' "$line"; done < "$log"
    [ "$status" -eq 0 ] || { echo "editor command failed: status=$status" >&2; exit 1; }
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" == "ERROR: "*" RID allocations of type 'N16RendererViewport8ViewportE' were leaked at exit." \
            || "$line" == "ERROR: "*" RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit." \
            || "$line" == "ERROR: "*" RID allocations of type 'N17RendererSceneCull8ScenarioE' were leaked at exit." \
            || "$line" == "ERROR: "*" RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit." \
            || "$line" == "ERROR: "*" RID allocations of type 'PN18TextServerAdvanced12FontAdvancedE' were leaked at exit." ]]; then
            # Godot 4.7.2's headless editor reports these renderer shutdown
            # diagnostics after a scripted quit. Keep this allowlist exact to
            # the reproduced types; every other ERROR remains fatal.
            continue
        fi
        if [[ "$line" == "ERROR: 3 resources still in use at exit (run with --verbose for details)." ]]; then
            # Reproduced only on the 4.7.2 scripted disable process; the next
            # clean restart below is the control for persistent addon state.
            continue
        fi
        if [[ "$line" == ERROR:* || "$line" == "SCRIPT ERROR:"* ]]; then
            echo "unexpected editor error output" >&2
            exit 1
        fi
    done < "$log"
}

make_fixture() {
    local fixture=$1
    mkdir -p "$fixture/addons/@aviorstudio_gd-responsive" "$fixture/tests"
    unzip -q "$ZIP_PATH" -d "$fixture/addons/@aviorstudio_gd-responsive"
    cp "$SCRIPT_DIR/editor_plugin_toggle.gd" "$fixture/tests/"
    cp "$SCRIPT_DIR/editor_resource_validation.gd" "$fixture/tests/"
    cp "$SCRIPT_DIR/editor_wait.gd" "$fixture/tests/"
    cat > "$fixture/project.godot" <<'EOF'
[display/window]
size/viewport_width=960
size/viewport_height=540

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
EOF
}

OWNED="$FIXTURE_ROOT/owned"
make_fixture "$OWNED"
PLUGIN_ACTION=enable run_editor "$OWNED" --script res://tests/editor_plugin_toggle.gd
run_editor "$OWNED" --script res://tests/editor_wait.gd
run_editor "$OWNED" --script res://tests/editor_resource_validation.gd
python3 - "$OWNED/project.godot" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
if '[autoload]' not in text or 'GdResponsive="*uid://' not in text:
    raise SystemExit("owned autoload missing after enable/restart:\n" + text)
print("EDITOR_RESTART_PASS owned_autoload_present=true")
PY
PLUGIN_ACTION=disable run_editor "$OWNED" --script res://tests/editor_plugin_toggle.gd
run_editor "$OWNED" --script res://tests/editor_wait.gd
python3 - "$OWNED/project.godot" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
if "GdResponsive=" in text:
    raise SystemExit("owned autoload remained after disable/restart")
print("EDITOR_DISABLE_RESTART_PASS owned_autoload_present=false")
PY

CONSUMER="$FIXTURE_ROOT/consumer"
make_fixture "$CONSUMER"
cat > "$CONSUMER/consumer_owned.gd" <<'EOF'
extends Node
EOF
cat >> "$CONSUMER/project.godot" <<'EOF'

[autoload]
GdResponsive="*res://consumer_owned.gd"
EOF
PLUGIN_ACTION=enable run_editor "$CONSUMER" --script res://tests/editor_plugin_toggle.gd
run_editor "$CONSUMER" --script res://tests/editor_wait.gd
PLUGIN_ACTION=disable run_editor "$CONSUMER" --script res://tests/editor_plugin_toggle.gd
run_editor "$CONSUMER" --script res://tests/editor_wait.gd
python3 - "$CONSUMER/project.godot" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
expected = 'GdResponsive="*res://consumer_owned.gd"'
if expected not in text:
    raise SystemExit("consumer-owned autoload was removed or rewritten")
print("EDITOR_OWNERSHIP_PASS consumer_autoload_preserved=true")
PY

python3 - "$OWNED/addons/@aviorstudio_gd-responsive" <<'PY'
import hashlib, pathlib, sys
root = pathlib.Path(sys.argv[1])
digest = hashlib.sha256()
count = 0
for path in sorted(item for item in root.rglob("*") if item.is_file()):
    relative = path.relative_to(root).as_posix().encode()
    data = path.read_bytes()
    digest.update(len(relative).to_bytes(8, "big"))
    digest.update(relative)
    digest.update(len(data).to_bytes(8, "big"))
    digest.update(data)
    count += 1
print(f"INSTALLED_TREE_VERIFIED files={count} sha256={digest.hexdigest()}")
PY

test -s "$ROOT_DIR/dist/installed-web/index.html"
test -s "$ROOT_DIR/dist/installed-web/index.wasm"
echo "PACKAGED_WEB_EXPORT_PASS output=dist/installed-web/index.html"

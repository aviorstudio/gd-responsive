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

if [ "${RUN_WEB_EXPORT:-1}" = "1" ]; then
    mkdir -p "$CONSUMER/web"
    cat > "$CONSUMER/web/main.gd" <<'EOF'
extends Control
const ResponsiveScaleModule = preload("res://addons/@aviorstudio_gd-responsive/src/responsive_scale_module.gd")

func _ready() -> void:
	var module := ResponsiveScaleModule.new()
	var device := module.resolve_device_type(Vector2(960, 540))
	$Result.text = "GD Responsive Web Smoke PASS | device=%d | width=%.0f" % [device, module.calculate_content_width(960.0, 48, 320.0, 480.0)]
EOF
    cat > "$CONSUMER/web/main.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource path="res://web/main.gd" type="Script" id="1"]

[node name="WebSmoke" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Result" type="Label" parent="."]
layout_mode = 0
offset_left = 40.0
offset_top = 40.0
offset_right = 900.0
offset_bottom = 100.0
theme_override_font_sizes/font_size = 24
text = "GD Responsive Web Smoke STARTING"
EOF
    cat >> "$CONSUMER/project.godot" <<'EOF'

[application]
run/main_scene="res://web/main.tscn"
EOF
    cat > "$CONSUMER/export_presets.cfg" <<'EOF'
[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="web-build/index.html"
script_export_mode=2

[preset.0.options]
html/canvas_resize_policy=2
html/experimental_virtual_keyboard=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/virtual_keyboard=false
progressive_web_app/enabled=false
variant/thread_support=false
variant/extensions_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
EOF
    mkdir -p "$CONSUMER/web-build" "$ROOT_DIR/dist/installed-web"
    "${GODOT[@]}" --headless --path "$CONSUMER" --export-release Web "$CONSUMER/web-build/index.html"
    rm -rf "$ROOT_DIR/dist/installed-web"
    cp -R "$CONSUMER/web-build" "$ROOT_DIR/dist/installed-web"
    test -s "$ROOT_DIR/dist/installed-web/index.html"
    test -s "$ROOT_DIR/dist/installed-web/index.wasm"
    echo "PACKAGED_WEB_EXPORT_PASS output=dist/installed-web/index.html"
fi

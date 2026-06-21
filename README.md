# gd-responsive

Build responsive Godot 4 UI that adapts to phone, tablet, desktop, and web viewports.

Use this addon to compute layout scale, margins, content width, breakpoints, flex rows, and grids without hardcoding every screen size.

## Installation

### Via gdam

`gdam install @aviorstudio/gd-responsive`

### Manual

Copy `addon/` into `res://addons/@aviorstudio_gd-responsive/` and enable the plugin.

Enabling the plugin adds the `GdResponsive` autoload and registers these editor-visible types:

- `ResponsiveLayout`
- `ResponsiveFlex`
- `ResponsiveGrid`
- `ResponsiveFlexItem`
- `ResponsiveGridItem`
- `ResponsiveLayoutConfig`

## Quick Start

```gdscript
const ResponsiveScaleModule = preload("res://addons/@aviorstudio_gd-responsive/src/responsive_scale_module.gd")

var responsive := ResponsiveScaleModule.new()
var viewport_size := get_viewport_rect().size
var device_type := responsive.resolve_device_type(viewport_size)
var scale := responsive.compute_scale(viewport_size, 1.0)
var margin := responsive.resolve_margin(device_type, false)
```

## Responsive Layout Scene

Use `ResponsiveLayout` when you want a reusable `Control` base that applies computed margins, content widths, and optional font scaling.

`ResponsiveLayout` is editor-first: it runs as a `@tool` script, so margin, content width, and spacing changes are visible while authoring scenes. Instance `res://addons/@aviorstudio_gd-responsive/src/responsive_layout.tscn`, then tune or duplicate its `layout_config` resource in the inspector.

The bundled default config lives at:

`res://addons/@aviorstudio_gd-responsive/config/default_responsive_layout_config.tres`

Bundled presets live under:

- `res://addons/@aviorstudio_gd-responsive/presets/compact_layout_config.tres`
- `res://addons/@aviorstudio_gd-responsive/presets/app_shell_layout_config.tres`

An inspectable app-shell example scene lives at:

`res://addons/@aviorstudio_gd-responsive/examples/app_shell/responsive_example_main.tscn`

Useful editor-facing fields:

- `layout_config`: reusable `.tres` settings for widths, margins, scale, breakpoints, spacing, and base font sizes.
- `editor_preview_enabled`: enables live editor layout preview.
- `editor_preview_viewport_size`: optional phone/tablet/desktop preview size override. Leave at zero to use the control size.

If one of the configured child paths is missing or points at the wrong node type, `ResponsiveLayout` reports a Godot node configuration warning in the Scene dock.

Configurable child paths:

- `scroll_path`, default `ScrollContainer`
- `margin_path`, default `ScrollContainer/MarginContainer`
- `center_path`, default `ScrollContainer/MarginContainer/CenterContainer`
- `content_path`, default `ScrollContainer/MarginContainer/CenterContainer/VBoxContainer`

`ResponsiveLayout.adjust_font_sizes` defaults to `false`; enable it only when you want recursive font rewriting.

## What You Get

- `ResponsiveScaleModule`: viewport classification and scale/margin/content-width calculations.
- `ResponsiveLayoutConfig`: reusable artist-authored layout config resource.
- `ResponsiveLayout`: reusable base layout scene/script.
- `ResponsiveFlex` / `ResponsiveFlexItem`: row and column flow helpers.
- `ResponsiveGrid` / `ResponsiveGridItem`: breakpoint-aware grid helpers.
- `GdResponsiveAutoload`: optional facade for global access.

## Font Scaling

- `apply_font_scaling_on_node(...)`: scale one node.
- `apply_font_scaling_recursive(...)`: scale a subtree explicitly.

## Notes

- Works in Godot 4.x native and web exports.
- You can use only the scale module if you already have custom UI containers.
- Route, page, and HUD composition stay in your game project.

## Repository Layout

- `addon/`: Godot plugin source packaged for GDAM and manual installation.
- `addon/plugin.cfg`: plugin name, version, description, and entry script.
- `addon/src/`: reusable GDScript modules.
- `tests/`: Godot test project/scripts for addon behavior.
- `.github/workflows/ci.yml`: validates package shape and runs tests.
- `.github/workflows/release.yml`: creates GitHub release ZIPs and publishes to GDAM.

## Versioning And Releases

The version in `addon/plugin.cfg` is the addon package version. Releases are created from `main` with the manual release workflow and plain semver tags like `v0.0.1`; the workflow verifies `plugin.cfg`, builds `@aviorstudio_gd-responsive.zip`, and publishes `@aviorstudio/gd-responsive` to GDAM.

## Testing

Run locally with:

```sh
./tests/test.sh
```

CI runs the same test script when available.

## License

MIT

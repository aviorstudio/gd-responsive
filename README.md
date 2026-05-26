# gd-responsive

Build responsive Godot 4 UI that adapts to phone, tablet, desktop, and web viewports.

Use this addon to compute layout scale, margins, content width, breakpoints, flex rows, and grids without hardcoding every screen size.

## Installation

### Via gdam

`gdam install @aviorstudio/gd-responsive`

### Manual

Copy `addon/` into `res://addons/@aviorstudio_gd-responsive/` and enable the plugin.

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

Configurable child paths:

- `scroll_path`, default `ScrollContainer`
- `margin_path`, default `ScrollContainer/MarginContainer`
- `center_path`, default `ScrollContainer/MarginContainer/CenterContainer`
- `content_path`, default `ScrollContainer/MarginContainer/CenterContainer/VBoxContainer`

`ResponsiveLayout.adjust_font_sizes` defaults to `false`; enable it only when you want recursive font rewriting.

## What You Get

- `ResponsiveScaleModule`: viewport classification and scale/margin/content-width calculations.
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

## Testing

`./tests/test.sh`

## License

MIT

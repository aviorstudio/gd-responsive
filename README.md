# gd-responsive

Viewport classification and layout-value helpers for Godot 4.

This addon is intentionally a toolkit, not a full page framework.

## Installation

### Via gdpm
`gdpm install @aviorstudio/gd-responsive`

### Manual
Copy this directory into `addons/@aviorstudio_gd-responsive/` and enable the plugin.

## API Reference

- `ResponsiveScaleModule`: viewport classification plus scale/margin/content-width calculations.
- `ResponsiveLayout`: optional base `Control` scene that applies computed values.
- `GdResponsiveAutoload`: optional facade for projects that still prefer autoload access.

Font scaling APIs:

- `apply_font_scaling_on_node(...)`: scales one node only.
- `apply_font_scaling_recursive(...)`: explicit recursive scaling for a subtree.

`ResponsiveLayout.adjust_font_sizes` defaults to `false` so recursive font rewriting is opt-in.

## Scope Boundary

- In scope: compute responsive values and selectively apply them.
- Out of scope: full page orchestration, route-level lifecycle behavior, and mandatory global mutation.

## ResponsiveLayout Paths

`ResponsiveLayout` supports configurable hierarchy paths via exported `NodePath` properties:

- `scroll_path` (default: `ScrollContainer`)
- `margin_path` (default: `ScrollContainer/MarginContainer`)
- `center_path` (default: `ScrollContainer/MarginContainer/CenterContainer`)
- `content_path` (default: `ScrollContainer/MarginContainer/CenterContainer/VBoxContainer`)

Defaults match the existing scene structure so current layouts work unchanged.

## Testing

`./tests/test.sh`

## License

MIT
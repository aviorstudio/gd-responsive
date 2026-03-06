# gd-responsive

Game-agnostic responsive scaling and layout helpers for Godot 4.

## Installation

### Via gdpm
`gdpm install @aviorstudio/gd-responsive`

### Manual
Copy this directory into `addons/@aviorstudio_gd-responsive/` and enable the plugin.

## API Reference

- `ResponsiveScaleModule`: responsive scaling, breakpoints, margins, and content width helpers.
- `ResponsiveLayout`: reusable base `Control` + scene for responsive pages.
- `GdResponsiveAutoload`: optional autoload facade for layout scale/update/apply flows.

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
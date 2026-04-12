## Computes responsive scale and sizing values for UI layouts.
class_name ResponsiveScaleModule
extends RefCounted

## Configuration for responsive scale and layout behavior.
class ResponsiveConfig extends RefCounted:
	## Design-time baseline width.
	var base_width: float = 720.0
	## Design-time baseline height.
	var base_height: float = 1280.0
	## Minimum allowed UI scale.
	var min_scale: float = 0.75
	## Maximum allowed UI scale.
	var max_scale: float = 1.5
	## Minimum delta required before updating current scale.
	var scale_change_threshold: float = 0.01
	## Maximum width to classify as mobile.
	var mobile_breakpoint: int = 768
	## Maximum width to classify as tablet.
	var tablet_breakpoint: int = 1024
	## Margin used on mobile layouts.
	var mobile_margin: int = 24
	## Margin used on desktop layouts.
	var desktop_margin: int = 48
	## Margin used for mobile landscape layouts.
	var landscape_margin: int = 36
	## Spacing used between mobile content blocks.
	var content_separation_mobile: int = 24
	## Spacing used between desktop content blocks.
	var content_separation_desktop: int = 48

## Device categories resolved from viewport dimensions.
enum DeviceType { MOBILE, TABLET, DESKTOP }

var _config: ResponsiveConfig = ResponsiveConfig.new()

## Replaces runtime config values.
func configure(config: ResponsiveConfig) -> void:
	if config == null:
		return
	_config = config

## Returns current runtime config.
func get_config() -> ResponsiveConfig:
	return _config

## Computes a clamped scale from viewport size and previous value.
func compute_scale(viewport_size: Vector2, current_scale: float) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return current_scale
	if _config.base_width <= 0.0 or _config.base_height <= 0.0:
		return current_scale
	var width_scale: float = viewport_size.x / _config.base_width
	var height_scale: float = viewport_size.y / _config.base_height
	var new_scale: float = clamp(min(width_scale, height_scale), _config.min_scale, _config.max_scale)
	if abs(new_scale - current_scale) <= _config.scale_change_threshold:
		return current_scale
	return new_scale

## Resolves device type from viewport dimensions.
func resolve_device_type(viewport_size: Vector2) -> DeviceType:
	if viewport_size.x < float(_config.mobile_breakpoint) or viewport_size.y < float(_config.mobile_breakpoint):
		return DeviceType.MOBILE
	if (
		(viewport_size.x >= float(_config.mobile_breakpoint) and viewport_size.x < float(_config.tablet_breakpoint))
		or (viewport_size.y >= float(_config.mobile_breakpoint) and viewport_size.y < float(_config.tablet_breakpoint))
	):
		return DeviceType.TABLET
	return DeviceType.DESKTOP

## Resolves margin from device type and orientation.
func resolve_margin(device_type: DeviceType, is_landscape: bool) -> int:
	if device_type == DeviceType.MOBILE and is_landscape:
		return _config.landscape_margin
	if device_type == DeviceType.MOBILE:
		return _config.mobile_margin
	return _config.desktop_margin

## Computes a clamped content width from viewport width and margins.
func calculate_content_width(viewport_width: float, margin: int, min_width: float, max_width: float) -> float:
	var available_width: float = viewport_width - float(margin * 2)
	return clamp(available_width, min_width, max_width)

## Applies responsive font scaling to a single node without walking children.
func apply_font_scaling_on_node(node: Node, base_sizes: Dictionary[String, int], scale: float) -> void:
	if node == null:
		return
	_apply_font_scaling_on_node(node, base_sizes, scale)

## Applies responsive font scaling recursively to a node tree.
func apply_font_scaling_recursive(node: Node, base_sizes: Dictionary[String, int], scale: float) -> void:
	if node == null:
		return
	_apply_font_scaling_on_node(node, base_sizes, scale)
	for child: Node in node.get_children():
		if child is Button or child is Label or child is LineEdit or child.get_child_count() > 0:
			apply_font_scaling_recursive(child, base_sizes, scale)

## Backward-compatible alias kept for existing callers.
func apply_font_scaling(node: Node, base_sizes: Dictionary[String, int], scale: float) -> void:
	apply_font_scaling_recursive(node, base_sizes, scale)

func _apply_font_scaling_on_node(node: Node, base_sizes: Dictionary[String, int], scale: float) -> void:
	if node is Button:
		var button: Button = node
		var target: int = int(base_sizes.get("button", 28) * scale)
		if button.has_theme_font_size_override("font_size"):
			if button.get_theme_font_size("font_size") == target:
				return
		button.add_theme_font_size_override("font_size", target)
	if node is Label:
		var label: Label = node
		var key: String = "body"
		if label.theme_type_variation == "HeaderLarge":
			key = "header"
		elif label.theme_type_variation == "SubHeader":
			key = "subheader"
		var target: int = int(base_sizes.get(key, 24) * scale)
		if label.has_theme_font_size_override("font_size"):
			if label.get_theme_font_size("font_size") == target:
				return
		label.add_theme_font_size_override("font_size", target)
	if node is LineEdit:
		var line_edit: LineEdit = node
		var target: int = int(base_sizes.get("body", 24) * scale)
		if line_edit.has_theme_font_size_override("font_size"):
			if line_edit.get_theme_font_size("font_size") == target:
				return
		line_edit.add_theme_font_size_override("font_size", target)

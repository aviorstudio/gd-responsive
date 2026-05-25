## Autoload facade for responsive layout computations.
class_name GdResponsiveAutoload
extends Node

const ResponsiveScaleModule = preload("src/responsive_scale_module.gd")
const ResponsiveLayout = preload("src/responsive_layout.gd")

var _scale_module: ResponsiveScaleModule = ResponsiveScaleModule.new()

func _ready() -> void:
	var config: ResponsiveScaleModule.ResponsiveConfig = ResponsiveScaleModule.ResponsiveConfig.new()
	_scale_module.configure(config)

## Overrides responsive runtime configuration.
func configure(config: ResponsiveScaleModule.ResponsiveConfig) -> void:
	_scale_module.configure(config)

## Returns current responsive runtime configuration.
func get_config() -> ResponsiveScaleModule.ResponsiveConfig:
	return _scale_module.get_config()

## Calculates and stores current scale on target layout.
func calculate_scale(layout: ResponsiveLayout) -> void:
	var viewport_size: Vector2 = layout.get_viewport().size if layout.get_viewport() != null else Vector2.ZERO
	layout.current_scale = _scale_module.compute_scale(viewport_size, layout.current_scale)

## Applies responsive margins/content width/separation to target layout.
func update_layout(layout: ResponsiveLayout) -> void:
	if not layout.is_inside_tree():
		return
	var viewport_size: Vector2 = layout.get_viewport().size if layout.get_viewport() != null else Vector2.ZERO
	var device_type: ResponsiveScaleModule.DeviceType = _scale_module.resolve_device_type(viewport_size)
	var is_landscape: bool = viewport_size.x > viewport_size.y
	var margin: int = _scale_module.resolve_margin(device_type, is_landscape)
	layout.margin_container.add_theme_constant_override("margin_left", margin)
	layout.margin_container.add_theme_constant_override("margin_right", margin)
	layout.margin_container.add_theme_constant_override("margin_top", margin)
	layout.margin_container.add_theme_constant_override("margin_bottom", margin)
	var content_width: float = _scale_module.calculate_content_width(
		viewport_size.x,
		margin,
		layout.min_content_width,
		layout.max_content_width
	)
	layout.content_container.custom_minimum_size.x = content_width
	layout.content_container.custom_minimum_size.y = 0.0
	for child: Node in layout.content_container.get_children():
		if child is Control:
			(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var separation: int = _scale_module.get_config().content_separation_mobile
	if device_type != ResponsiveScaleModule.DeviceType.MOBILE:
		separation = _scale_module.get_config().content_separation_desktop
	layout.content_container.add_theme_constant_override("separation", separation)

## Applies font scaling to target layout content container.
func apply_responsive_sizing(layout: ResponsiveLayout) -> void:
	if not layout.adjust_font_sizes:
		return
	var base_sizes: Dictionary[String, int] = {
		"button": layout.button_font_size,
		"body": layout.body_font_size,
		"header": layout.header_font_size,
		"subheader": layout.subheader_font_size
	}
	var viewport_size: Vector2 = layout.get_viewport().size if layout.get_viewport() != null else Vector2.ZERO
	var device_type: ResponsiveScaleModule.DeviceType = _scale_module.resolve_device_type(viewport_size)
	var font_scale: float = 1.0
	if device_type == ResponsiveScaleModule.DeviceType.TABLET:
		font_scale = 0.95
	elif device_type == ResponsiveScaleModule.DeviceType.DESKTOP:
		font_scale = 0.85
	_scale_module.apply_font_scaling_recursive(layout.content_container, base_sizes, layout.current_scale * font_scale)

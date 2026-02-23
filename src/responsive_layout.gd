## Reusable responsive base layout control.
class_name ResponsiveLayout
extends Control

const ResponsiveScaleModule = preload("responsive_scale_module.gd")

## Maximum content width constraint.
@export var max_content_width: float = 480.0
## Minimum content width constraint.
@export var min_content_width: float = 320.0
## Enables recursive font size scaling.
@export var adjust_font_sizes: bool = true

## Baseline layout width for scale calculations.
@export var base_width: float = 720.0
## Baseline layout height for scale calculations.
@export var base_height: float = 1280.0
## Minimum allowed computed scale.
@export var min_scale: float = 0.75
## Maximum allowed computed scale.
@export var max_scale: float = 1.5

## Font base sizes used by `apply_font_scaling`.
@export var button_font_size: int = 28
## Font base sizes used by `apply_font_scaling`.
@export var body_font_size: int = 24
## Font base sizes used by `apply_font_scaling`.
@export var header_font_size: int = 32
## Font base sizes used by `apply_font_scaling`.
@export var subheader_font_size: int = 28

## Current responsive scale.
var current_scale: float = 1.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var margin_container: MarginContainer = $ScrollContainer/MarginContainer
@onready var center_container: CenterContainer = $ScrollContainer/MarginContainer/CenterContainer
@onready var content_container: VBoxContainer = $ScrollContainer/MarginContainer/CenterContainer/VBoxContainer

var _scale_module: ResponsiveScaleModule = ResponsiveScaleModule.new()
var _last_viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	_apply_runtime_config()
	scroll_container.clip_contents = true
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_last_viewport_size = get_viewport().size if get_viewport() else Vector2.ZERO
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_apply_viewport_size")

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport().size if get_viewport() else Vector2.ZERO
	if viewport_size == _last_viewport_size:
		return
	_last_viewport_size = viewport_size
	_apply_viewport_size()

func _apply_runtime_config() -> void:
	var config: ResponsiveScaleModule.ResponsiveConfig = ResponsiveScaleModule.ResponsiveConfig.new()
	config.base_width = base_width
	config.base_height = base_height
	config.min_scale = min_scale
	config.max_scale = max_scale
	_scale_module.configure(config)

func _apply_viewport_size() -> void:
	_calculate_scale()
	_update_layout()
	_apply_responsive_sizing()

func _calculate_scale() -> void:
	var viewport_size: Vector2 = get_viewport().size if get_viewport() else Vector2.ZERO
	current_scale = _scale_module.compute_scale(viewport_size, current_scale)

func _update_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport().size if get_viewport() else Vector2.ZERO
	var device_type: ResponsiveScaleModule.DeviceType = _scale_module.resolve_device_type(viewport_size)
	var is_landscape: bool = viewport_size.x > viewport_size.y
	var margin: int = _scale_module.resolve_margin(device_type, is_landscape)
	margin_container.add_theme_constant_override("margin_left", margin)
	margin_container.add_theme_constant_override("margin_right", margin)
	margin_container.add_theme_constant_override("margin_top", margin)
	margin_container.add_theme_constant_override("margin_bottom", margin)
	var content_width: float = _scale_module.calculate_content_width(
		viewport_size.x,
		margin,
		min_content_width,
		max_content_width
	)
	content_container.custom_minimum_size.x = content_width
	content_container.custom_minimum_size.y = 0.0
	for child: Node in content_container.get_children():
		if child is Control:
			(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var separation: int = _scale_module.get_config().content_separation_mobile
	if device_type != ResponsiveScaleModule.DeviceType.MOBILE:
		separation = _scale_module.get_config().content_separation_desktop
	content_container.add_theme_constant_override("separation", separation)

func _apply_responsive_sizing() -> void:
	if not adjust_font_sizes:
		return
	var base_sizes: Dictionary[String, int] = {
		"button": button_font_size,
		"body": body_font_size,
		"header": header_font_size,
		"subheader": subheader_font_size
	}
	var device_type: ResponsiveScaleModule.DeviceType = _scale_module.resolve_device_type(get_viewport().size)
	var font_scale: float = 1.0
	if device_type == ResponsiveScaleModule.DeviceType.TABLET:
		font_scale = 0.95
	elif device_type == ResponsiveScaleModule.DeviceType.DESKTOP:
		font_scale = 0.85
	_scale_module.apply_font_scaling(content_container, base_sizes, current_scale * font_scale)

## Returns true if current viewport resolves to mobile.
func is_mobile() -> bool:
	return _scale_module.resolve_device_type(get_viewport().size) == ResponsiveScaleModule.DeviceType.MOBILE

## Returns true if current viewport resolves to tablet.
func is_tablet() -> bool:
	return _scale_module.resolve_device_type(get_viewport().size) == ResponsiveScaleModule.DeviceType.TABLET

## Returns true if current viewport resolves to desktop.
func is_desktop() -> bool:
	return _scale_module.resolve_device_type(get_viewport().size) == ResponsiveScaleModule.DeviceType.DESKTOP

## Returns container where page content should be attached.
func get_content_container() -> VBoxContainer:
	return content_container

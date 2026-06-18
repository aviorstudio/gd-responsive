## Reusable responsive base layout control.
@tool
class_name ResponsiveLayout
extends Control

const ResponsiveScaleModule = preload("responsive_scale_module.gd")
const ResponsiveLayoutConfig = preload("responsive_layout_config.gd")

@export_group("Editor Preview")

## Applies responsive layout in the editor so artists can tune scenes visually.
@export var editor_preview_enabled: bool = true:
	set(value):
		if value == editor_preview_enabled:
			return
		editor_preview_enabled = value
		_queue_apply_viewport_size()

## Optional editor-only viewport size override. Zero uses the control's current size.
@export var editor_preview_viewport_size: Vector2 = Vector2.ZERO:
	set(value):
		editor_preview_viewport_size = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_queue_apply_viewport_size()

@export_group("Responsive Config")

## Reusable artist-authored layout settings. When unset, the legacy exports below are used.
@export var layout_config: ResponsiveLayoutConfig = null:
	set(value):
		if layout_config != null and layout_config.changed.is_connected(_on_layout_config_changed):
			layout_config.changed.disconnect(_on_layout_config_changed)
		layout_config = value
		if layout_config != null and not layout_config.changed.is_connected(_on_layout_config_changed):
			layout_config.changed.connect(_on_layout_config_changed)
		_apply_runtime_config()
		_queue_apply_viewport_size()

@export_group("Layout")

## Maximum content width constraint.
@export var max_content_width: float = 480.0
## Minimum content width constraint.
@export var min_content_width: float = 320.0
## Enables recursive font size scaling (can be expensive for large trees).
@export var adjust_font_sizes: bool = false
## Path to the root ScrollContainer node.
@export var scroll_path: NodePath = NodePath("ScrollContainer")
## Path to the MarginContainer node.
@export var margin_path: NodePath = NodePath("ScrollContainer/MarginContainer")
## Path to the CenterContainer node.
@export var center_path: NodePath = NodePath("ScrollContainer/MarginContainer/CenterContainer")
## Path to the content VBoxContainer node.
@export var content_path: NodePath = NodePath("ScrollContainer/MarginContainer/CenterContainer/VBoxContainer")

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

var scroll_container: ScrollContainer = null
var margin_container: MarginContainer = null
var center_container: CenterContainer = null
var content_container: Container = null

var _scale_module: ResponsiveScaleModule = ResponsiveScaleModule.new()
var _last_viewport_size: Vector2 = Vector2.ZERO
var _layout_service: Node = null
var _apply_queued: bool = false

## Sets an external layout service to delegate layout computations to.
## The service must implement calculate_scale(layout), update_layout(layout), apply_responsive_sizing(layout).
func set_layout_service(service: Node) -> void:
	_layout_service = service

func _ready() -> void:
	_resolve_layout_nodes()
	if scroll_container == null or margin_container == null or center_container == null or content_container == null:
		push_error("ResponsiveLayout: invalid layout paths configuration")
		return
	if layout_config != null and not layout_config.changed.is_connected(_on_layout_config_changed):
		layout_config.changed.connect(_on_layout_config_changed)
	_apply_runtime_config()
	scroll_container.clip_contents = true
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_last_viewport_size = _resolve_viewport_size()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	if not resized.is_connected(_on_control_resized):
		resized.connect(_on_control_resized)
	call_deferred("_apply_viewport_size")

func _exit_tree() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.disconnect(_on_viewport_size_changed)
	if resized.is_connected(_on_control_resized):
		resized.disconnect(_on_control_resized)
	if layout_config != null and layout_config.changed.is_connected(_on_layout_config_changed):
		layout_config.changed.disconnect(_on_layout_config_changed)

func _resolve_layout_nodes() -> void:
	scroll_container = get_node_or_null(scroll_path) as ScrollContainer
	margin_container = get_node_or_null(margin_path) as MarginContainer
	center_container = get_node_or_null(center_path) as CenterContainer
	content_container = get_node_or_null(content_path) as Container

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = _resolve_viewport_size()
	if viewport_size == _last_viewport_size:
		return
	_last_viewport_size = viewport_size
	_apply_viewport_size()

func _on_control_resized() -> void:
	if Engine.is_editor_hint():
		_queue_apply_viewport_size()

func _on_layout_config_changed() -> void:
	_apply_runtime_config()
	_queue_apply_viewport_size()

## Re-applies responsive sizing after external code changes child content or config.
func refresh_layout() -> void:
	_resolve_layout_nodes()
	_apply_runtime_config()
	_apply_viewport_size()

func _apply_runtime_config() -> void:
	if _scale_module == null:
		return
	if layout_config != null:
		_scale_module.configure(layout_config.to_scale_config())
		return
	var config: ResponsiveScaleModule.ResponsiveConfig = ResponsiveScaleModule.ResponsiveConfig.new()
	config.base_width = base_width
	config.base_height = base_height
	config.min_scale = min_scale
	config.max_scale = max_scale
	_scale_module.configure(config)

func _queue_apply_viewport_size() -> void:
	if not is_inside_tree() or _apply_queued:
		return
	_apply_queued = true
	call_deferred("_flush_apply_viewport_size")

func _flush_apply_viewport_size() -> void:
	_apply_queued = false
	if is_inside_tree():
		_apply_viewport_size()

func _resolve_viewport_size() -> Vector2:
	if Engine.is_editor_hint() and editor_preview_enabled:
		if editor_preview_viewport_size.x > 0.0 and editor_preview_viewport_size.y > 0.0:
			return editor_preview_viewport_size
		if size.x > 0.0 and size.y > 0.0:
			return size
	return get_viewport().size if get_viewport() else size

func _apply_viewport_size() -> void:
	_resolve_layout_nodes()
	if scroll_container == null or margin_container == null or center_container == null or content_container == null:
		return
	_calculate_scale()
	_update_layout()
	_apply_responsive_sizing()

func _calculate_scale() -> void:
	if _layout_service and _layout_service.has_method("calculate_scale"):
		_layout_service.calculate_scale(self)
		return
	var viewport_size: Vector2 = _resolve_viewport_size()
	current_scale = _scale_module.compute_scale(viewport_size, current_scale)

func _update_layout() -> void:
	if _layout_service and _layout_service.has_method("update_layout"):
		_layout_service.update_layout(self)
		return
	if not is_inside_tree():
		return
	var viewport_size: Vector2 = _resolve_viewport_size()
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
		_effective_min_content_width(),
		_effective_max_content_width()
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
	if _layout_service and _layout_service.has_method("apply_responsive_sizing"):
		_layout_service.apply_responsive_sizing(self)
		return
	if not adjust_font_sizes:
		return
	var base_sizes: Dictionary[String, int] = {
		"button": _effective_button_font_size(),
		"body": _effective_body_font_size(),
		"header": _effective_header_font_size(),
		"subheader": _effective_subheader_font_size()
	}
	var device_type: ResponsiveScaleModule.DeviceType = _scale_module.resolve_device_type(_resolve_viewport_size())
	var font_scale: float = 1.0
	if device_type == ResponsiveScaleModule.DeviceType.TABLET:
		font_scale = 0.95
	elif device_type == ResponsiveScaleModule.DeviceType.DESKTOP:
		font_scale = 0.85
	_scale_module.apply_font_scaling_recursive(content_container, base_sizes, current_scale * font_scale)

## Returns true if current viewport resolves to mobile.
func is_mobile() -> bool:
	return _scale_module.resolve_device_type(_resolve_viewport_size()) == ResponsiveScaleModule.DeviceType.MOBILE

## Returns true if current viewport resolves to tablet.
func is_tablet() -> bool:
	return _scale_module.resolve_device_type(_resolve_viewport_size()) == ResponsiveScaleModule.DeviceType.TABLET

## Returns true if current viewport resolves to desktop.
func is_desktop() -> bool:
	return _scale_module.resolve_device_type(_resolve_viewport_size()) == ResponsiveScaleModule.DeviceType.DESKTOP

## Returns container where page content should be attached.
func get_content_container() -> Container:
	return content_container

func _effective_max_content_width() -> float:
	return layout_config.max_content_width if layout_config != null else max_content_width

func _effective_min_content_width() -> float:
	return layout_config.min_content_width if layout_config != null else min_content_width

func _effective_button_font_size() -> int:
	return layout_config.button_font_size if layout_config != null else button_font_size

func _effective_body_font_size() -> int:
	return layout_config.body_font_size if layout_config != null else body_font_size

func _effective_header_font_size() -> int:
	return layout_config.header_font_size if layout_config != null else header_font_size

func _effective_subheader_font_size() -> int:
	return layout_config.subheader_font_size if layout_config != null else subheader_font_size

@tool
extends EditorPlugin

const AUTOLOAD_NAME := "GdResponsive"
const AUTOLOAD_SCRIPT := "autoload.gd"
const ResponsiveLayoutScript = preload("src/responsive_layout.gd")
const ResponsiveFlexScript = preload("src/responsive_flex.gd")
const ResponsiveGridScript = preload("src/responsive_grid.gd")
const ResponsiveFlexItemScript = preload("src/responsive_flex_item.gd")
const ResponsiveGridItemScript = preload("src/responsive_grid_item.gd")
const ResponsiveLayoutConfigScript = preload("src/responsive_layout_config.gd")

var _added_autoload: bool = false

func _enter_tree() -> void:
	add_custom_type("ResponsiveLayout", "Control", ResponsiveLayoutScript, _editor_icon("Control", "Control"))
	add_custom_type("ResponsiveFlex", "Container", ResponsiveFlexScript, _editor_icon("HBoxContainer", "Container"))
	add_custom_type("ResponsiveGrid", "Container", ResponsiveGridScript, _editor_icon("GridContainer", "Container"))
	add_custom_type("ResponsiveFlexItem", "Control", ResponsiveFlexItemScript, _editor_icon("Control", "Control"))
	add_custom_type("ResponsiveGridItem", "Control", ResponsiveGridItemScript, _editor_icon("Control", "Control"))
	add_custom_type("ResponsiveLayoutConfig", "Resource", ResponsiveLayoutConfigScript, _editor_icon("Resource", "Resource"))

func _exit_tree() -> void:
	remove_custom_type("ResponsiveLayoutConfig")
	remove_custom_type("ResponsiveGridItem")
	remove_custom_type("ResponsiveFlexItem")
	remove_custom_type("ResponsiveGrid")
	remove_custom_type("ResponsiveFlex")
	remove_custom_type("ResponsiveLayout")

func _enable_plugin() -> void:
	var key: String = "autoload/" + AUTOLOAD_NAME
	if ProjectSettings.has_setting(key):
		_added_autoload = false
		return

	add_autoload_singleton(AUTOLOAD_NAME, _autoload_path())
	_added_autoload = true

func _disable_plugin() -> void:
	if _added_autoload or _autoload_setting_matches_plugin():
		remove_autoload_singleton(AUTOLOAD_NAME)
	_added_autoload = false

func _autoload_path() -> String:
	var base_dir: String = str(get_script().resource_path).get_base_dir()
	return base_dir.path_join(AUTOLOAD_SCRIPT)

func _autoload_setting_matches_plugin() -> bool:
	var key: String = "autoload/" + AUTOLOAD_NAME
	if not ProjectSettings.has_setting(key):
		return false
	var value: String = str(ProjectSettings.get_setting(key))
	return value.trim_prefix("*") == _autoload_path()

func _editor_icon(preferred_name: String, fallback_name: String) -> Texture2D:
	var editor_interface: EditorInterface = get_editor_interface()
	if editor_interface == null:
		return null
	var base_control: Control = editor_interface.get_base_control()
	if base_control == null:
		return null
	if base_control.has_theme_icon(preferred_name, "EditorIcons"):
		return base_control.get_theme_icon(preferred_name, "EditorIcons")
	if base_control.has_theme_icon(fallback_name, "EditorIcons"):
		return base_control.get_theme_icon(fallback_name, "EditorIcons")
	return null

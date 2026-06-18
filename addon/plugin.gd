@tool
extends EditorPlugin

const AUTOLOAD_NAME := "GdResponsive"
const AUTOLOAD_SCRIPT := "autoload.gd"

var _added_autoload: bool = false

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

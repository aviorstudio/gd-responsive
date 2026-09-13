extends SceneTree

const ConfigScript = preload("res://addons/@aviorstudio_gd-responsive/src/responsive_layout_config.gd")
var _assertions: int = 0
var _failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var filesystem := EditorInterface.get_resource_filesystem()
	while filesystem != null and filesystem.is_scanning():
		await process_frame
	_check(EditorInterface.is_plugin_enabled("@aviorstudio_gd-responsive"), "package plugin is enabled in the editor")
	var config = ConfigScript.new()
	config.max_content_width = 300.0
	config.min_content_width = 500.0
	config.max_scale = 0.5
	config.min_scale = 1.25
	config.tablet_breakpoint = 600
	config.mobile_breakpoint = 900
	_check(config.get_validation_warnings().size() == 3, "invalid package resource exposes three warnings")
	_check(config.min_scale == 1.25 and config.max_scale == 0.5, "package resource preserves invalid values")
	var path := "user://invalid-reopen-control.tres"
	_check(ResourceSaver.save(config, path) == OK, "invalid package resource saves")
	var reopened = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_check(reopened != null and reopened.get_validation_warnings().size() == 3, "invalid package resource reopens with warnings")
	EditorInterface.inspect_object(reopened)
	for ignored in range(10):
		await process_frame
	_check(_has_visible_warning(EditorInterface.get_inspector()), "enabled plugin renders the resource warning in the Inspector")
	reopened.min_content_width = 200.0
	reopened.min_scale = 0.25
	reopened.mobile_breakpoint = 500
	for ignored in range(3):
		await process_frame
	_check(reopened.get_validation_warnings().is_empty(), "live correction clears package warnings")
	_check(not _has_visible_warning(EditorInterface.get_inspector()), "Inspector warning hides after recovery")
	_check(ResourceSaver.save(reopened, path) == OK, "recovered package resource saves")
	var recovered = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_check(recovered != null and recovered.get_validation_warnings().is_empty(), "recovered package resource reopens valid")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("EDITOR_RESOURCE_VALIDATION_PASS assertions=%d failures=%d" % [_assertions, _failures])
	quit(1 if _failures > 0 else 0)

func _has_visible_warning(node: Node) -> bool:
	if node is Label and node.is_visible_in_tree() and "Responsive layout configuration warning" in node.text:
		return true
	for child in node.get_children():
		if _has_visible_warning(child):
			return true
	return false

func _check(condition: bool, message: String) -> void:
	_assertions += 1
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)

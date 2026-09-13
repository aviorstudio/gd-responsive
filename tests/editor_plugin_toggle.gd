extends SceneTree

const PLUGIN_NAME := "@aviorstudio_gd-responsive"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var enable: bool = OS.get_environment("PLUGIN_ACTION") == "enable"
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	while filesystem != null and filesystem.is_scanning():
		await process_frame
	if EditorInterface.is_plugin_enabled(PLUGIN_NAME) != enable:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME, enable)
	await process_frame
	await process_frame
	var actual: bool = EditorInterface.is_plugin_enabled(PLUGIN_NAME)
	if actual != enable:
		push_error("plugin toggle did not reach requested state")
		quit(1)
		return
	ProjectSettings.save()
	print("EDITOR_PLUGIN_TOGGLE_PASS enabled=%s" % enable)
	quit(0)

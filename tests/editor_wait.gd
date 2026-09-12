extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	while filesystem != null and filesystem.is_scanning():
		await process_frame
	for ignored in range(10):
		await process_frame
	print("EDITOR_SETTLED_PASS")
	quit(0)

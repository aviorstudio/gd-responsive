extends SceneTree

const REQUIRED_FILES: PackedStringArray = [
	"res://addon/plugin.cfg",
	"res://addon/plugin.gd",
	"res://addon/autoload.gd",
	"res://addon/src/responsive_scale_module.gd",
	"res://addon/src/responsive_layout.gd",
	"res://addon/src/responsive_layout.tscn",
	"res://addon/src/responsive_layout_config.gd",
	"res://addon/src/responsive_flex.gd",
	"res://addon/src/responsive_flex_item.gd",
	"res://addon/src/responsive_grid.gd",
	"res://addon/src/responsive_grid_item.gd",
	"res://addon/config/default_responsive_layout_config.tres",
	"res://addon/presets/compact_layout_config.tres",
	"res://addon/presets/app_shell_layout_config.tres",
	"res://addon/examples/app_shell/responsive_example_main.tscn",
	"res://addon/examples/app_shell/responsive_example_main.gd",
]

const CUSTOM_TYPES: PackedStringArray = [
	"ResponsiveLayout",
	"ResponsiveFlex",
	"ResponsiveGrid",
	"ResponsiveFlexItem",
	"ResponsiveGridItem",
	"ResponsiveLayoutConfig",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_required_package_files_exist()
	_test_plugin_registers_custom_types()
	_test_packaged_resources_load()
	quit()

func _test_required_package_files_exist() -> void:
	for path in REQUIRED_FILES:
		_assert(FileAccess.file_exists(path), "required package file exists: %s" % path)

func _test_plugin_registers_custom_types() -> void:
	var plugin_source: String = FileAccess.get_file_as_string("res://addon/plugin.gd")
	for type_name in CUSTOM_TYPES:
		_assert(plugin_source.contains("add_custom_type(\"%s\"" % type_name), "plugin registers %s" % type_name)
		_assert(plugin_source.contains("remove_custom_type(\"%s\")" % type_name), "plugin removes %s" % type_name)

func _test_packaged_resources_load() -> void:
	var default_config: Resource = load("res://addon/config/default_responsive_layout_config.tres")
	_assert(default_config != null, "default layout config loads")
	var compact_config: Resource = load("res://addon/presets/compact_layout_config.tres")
	_assert(compact_config != null, "compact preset loads")
	var app_shell_config: Resource = load("res://addon/presets/app_shell_layout_config.tres")
	_assert(app_shell_config != null, "app shell preset loads")
	var layout_scene: PackedScene = load("res://addon/src/responsive_layout.tscn")
	_assert(layout_scene != null, "responsive layout scene loads")
	var layout: Node = layout_scene.instantiate()
	_assert(layout != null, "responsive layout scene instantiates")
	layout.queue_free()
	var example_scene: PackedScene = load("res://addon/examples/app_shell/responsive_example_main.tscn")
	_assert(example_scene != null, "responsive app shell example loads")
	var example: Node = example_scene.instantiate()
	_assert(example != null, "responsive app shell example instantiates")
	example.queue_free()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: %s" % message)
		quit(1)
	else:
		print("PASS: %s" % message)

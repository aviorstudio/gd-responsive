extends SceneTree

const ResponsiveLayout = preload("res://addon/src/responsive_layout.gd")
const ResponsiveLayoutConfig = preload("res://addon/src/responsive_layout_config.gd")
const TestHarness = preload("res://tests/test_harness.gd")

var _test := TestHarness.new()
var _changed_count: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test.check(Engine.is_editor_hint(), "resource checks execute in a real editor process")
	var config: ResponsiveLayoutConfig = ResponsiveLayoutConfig.new()
	config.changed.connect(_on_config_changed)
	_test.check(config.get_validation_warnings().is_empty(), "known-good resource has no validation warnings")
	config.max_content_width = 300.0
	config.min_content_width = 500.0
	config.max_scale = 0.5
	config.min_scale = 1.25
	config.tablet_breakpoint = 600
	config.mobile_breakpoint = 900
	_test.check(config.get_validation_warnings().size() == 3, "live invalid cross-field edits report width, scale, and breakpoint warnings")
	_test.check(config.min_content_width == 500.0 and config.max_content_width == 300.0, "invalid content widths preserve artist values")
	_test.check(config.min_scale == 1.25 and config.max_scale == 0.5, "invalid scales preserve artist values")
	_test.check(config.mobile_breakpoint == 900 and config.tablet_breakpoint == 600, "invalid breakpoints preserve artist values")
	_test.check(_changed_count == 6, "every live editor edit emits changed")
	var resource_path := "user://gd-responsive-invalid-config.tres"
	_test.check(ResourceSaver.save(config, resource_path) == OK, "invalid resource serializes without retuning")
	var reopened := ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as ResponsiveLayoutConfig
	_test.check(reopened != null, "serialized invalid resource reopens")
	_test.check(reopened.get_validation_warnings().size() == 3, "reopened invalid resource retains warnings")
	_test.check(reopened.min_content_width == 500.0 and reopened.max_content_width == 300.0, "reopen preserves invalid artist widths")
	_test.check(reopened.min_scale == 1.25 and reopened.max_scale == 0.5, "reopen preserves invalid artist scales")
	_test.check(reopened.mobile_breakpoint == 900 and reopened.tablet_breakpoint == 600, "reopen preserves invalid artist breakpoints")
	var layout := _make_layout()
	layout.layout_config = reopened
	root.add_child(layout)
	await process_frame
	layout.refresh_layout()
	_test.check(layout._get_configuration_warnings().size() == 3, "layout surfaces all resource warnings in the editor")
	_test.check(is_finite(layout.content_container.custom_minimum_size.x), "invalid resource leaves layout lifecycle stable")
	reopened.min_content_width = 200.0
	reopened.min_scale = 0.25
	reopened.mobile_breakpoint = 500
	await process_frame
	layout.refresh_layout()
	_test.check(reopened.get_validation_warnings().is_empty(), "live recovery clears resource warnings")
	_test.check(layout._get_configuration_warnings().is_empty(), "live recovery clears layout warnings")
	_test.check(is_equal_approx(layout.content_container.custom_minimum_size.x, 300.0), "layout recovers using unchanged valid values")
	_test.check(ResourceSaver.save(reopened, resource_path) == OK, "recovered resource serializes")
	var recovered := ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as ResponsiveLayoutConfig
	_test.check(recovered != null and recovered.get_validation_warnings().is_empty(), "recovered resource reopens valid")
	EditorInterface.inspect_object(recovered)
	await process_frame
	_test.check(EditorInterface.get_inspector() != null, "reopened resource is inspectable in the editor")
	layout.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(resource_path))
	await process_frame
	_test.finish(self)

func _on_config_changed() -> void:
	_changed_count += 1

func _make_layout() -> ResponsiveLayout:
	var layout := ResponsiveLayout.new()
	layout.size = Vector2(900, 1400)
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	var content := VBoxContainer.new()
	content.name = "VBoxContainer"
	center.add_child(content)
	margin.add_child(center)
	scroll.add_child(margin)
	layout.add_child(scroll)
	return layout

extends SceneTree

const ResponsiveLayout = preload("res://addon/src/responsive_layout.gd")
const ResponsiveLayoutConfig = preload("res://addon/src/responsive_layout_config.gd")

var _root: Window = null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_root = root
	_test_config_resource_maps_to_scale_config()
	_test_layout_uses_resource_config()
	quit()

func _make_layout() -> ResponsiveLayout:
	var layout: ResponsiveLayout = ResponsiveLayout.new()
	layout.size = Vector2(900, 1400)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	var center: CenterContainer = CenterContainer.new()
	center.name = "CenterContainer"
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "VBoxContainer"
	var label: Label = Label.new()
	label.text = "Preview"
	content.add_child(label)
	center.add_child(content)
	margin.add_child(center)
	scroll.add_child(margin)
	layout.add_child(scroll)
	return layout

func _test_config_resource_maps_to_scale_config() -> void:
	var config: ResponsiveLayoutConfig = ResponsiveLayoutConfig.new()
	config.base_width = 800.0
	config.base_height = 600.0
	config.mobile_breakpoint = 500
	config.tablet_breakpoint = 900
	config.mobile_margin = 12
	config.desktop_margin = 40
	config.content_separation_desktop = 18
	var scale_config = config.to_scale_config()
	_assert(scale_config.base_width == 800.0, "config maps base_width")
	_assert(scale_config.base_height == 600.0, "config maps base_height")
	_assert(scale_config.mobile_breakpoint == 500, "config maps mobile breakpoint")
	_assert(scale_config.tablet_breakpoint == 900, "config maps tablet breakpoint")
	_assert(scale_config.mobile_margin == 12, "config maps mobile margin")
	_assert(scale_config.desktop_margin == 40, "config maps desktop margin")
	_assert(scale_config.content_separation_desktop == 18, "config maps desktop separation")

func _test_layout_uses_resource_config() -> void:
	_root.size = Vector2i(900, 1400)
	var config: ResponsiveLayoutConfig = ResponsiveLayoutConfig.new()
	config.mobile_breakpoint = 700
	config.tablet_breakpoint = 1000
	config.mobile_margin = 11
	config.desktop_margin = 22
	config.landscape_margin = 33
	config.min_content_width = 100.0
	config.max_content_width = 400.0
	config.content_separation_mobile = 7
	config.content_separation_desktop = 13
	var layout: ResponsiveLayout = _make_layout()
	layout.layout_config = config
	_root.add_child(layout)
	await process_frame
	layout.refresh_layout()
	var margin: MarginContainer = layout.margin_container
	var content: VBoxContainer = layout.content_container as VBoxContainer
	_assert(margin.get_theme_constant("margin_left") == 22, "tablet/desktop margin comes from resource")
	_assert(margin.get_theme_constant("margin_right") == 22, "right margin comes from resource")
	_assert(is_equal_approx(content.custom_minimum_size.x, 400.0), "content width clamps to resource max")
	_assert(content.get_theme_constant("separation") == 13, "desktop separation comes from resource")
	config.max_content_width = 300.0
	layout.refresh_layout()
	_assert(is_equal_approx(content.custom_minimum_size.x, 300.0), "resource edits update layout width")
	layout.queue_free()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: %s" % message)
		quit(1)
	else:
		print("PASS: %s" % message)

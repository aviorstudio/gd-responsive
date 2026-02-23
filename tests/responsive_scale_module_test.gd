extends SceneTree

const ResponsiveScaleModule = preload("res://src/responsive_scale_module.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_compute_scale()
	_test_resolve_device_type_and_margin()
	_test_calculate_content_width()
	quit()

func _test_compute_scale() -> void:
	var module: ResponsiveScaleModule = ResponsiveScaleModule.new()
	var config: ResponsiveScaleModule.ResponsiveConfig = ResponsiveScaleModule.ResponsiveConfig.new()
	config.base_width = 720.0
	config.base_height = 1280.0
	config.min_scale = 0.75
	config.max_scale = 1.5
	config.scale_change_threshold = 0.01
	module.configure(config)

	var scale_mobile: float = module.compute_scale(Vector2(360, 640), 1.0)
	_assert(scale_mobile == 0.75, "small viewport should clamp to min_scale")

	var scale_large: float = module.compute_scale(Vector2(2160, 3840), 1.0)
	_assert(scale_large == 1.5, "large viewport should clamp to max_scale")

func _test_resolve_device_type_and_margin() -> void:
	var module: ResponsiveScaleModule = ResponsiveScaleModule.new()
	var config: ResponsiveScaleModule.ResponsiveConfig = ResponsiveScaleModule.ResponsiveConfig.new()
	config.mobile_breakpoint = 768
	config.tablet_breakpoint = 1024
	config.mobile_margin = 24
	config.desktop_margin = 48
	config.landscape_margin = 36
	module.configure(config)

	var mobile_type: ResponsiveScaleModule.DeviceType = module.resolve_device_type(Vector2(600, 900))
	_assert(mobile_type == ResponsiveScaleModule.DeviceType.MOBILE, "600x900 should resolve to mobile")
	_assert(module.resolve_margin(mobile_type, true) == 36, "mobile landscape should use landscape margin")

	var tablet_type: ResponsiveScaleModule.DeviceType = module.resolve_device_type(Vector2(900, 1400))
	_assert(tablet_type == ResponsiveScaleModule.DeviceType.TABLET, "900x1400 should resolve to tablet")
	_assert(module.resolve_margin(tablet_type, false) == 48, "tablet should use desktop margin")

	var desktop_type: ResponsiveScaleModule.DeviceType = module.resolve_device_type(Vector2(1280, 1440))
	_assert(desktop_type == ResponsiveScaleModule.DeviceType.DESKTOP, "1280x1440 should resolve to desktop")

func _test_calculate_content_width() -> void:
	var module: ResponsiveScaleModule = ResponsiveScaleModule.new()
	var width_small: float = module.calculate_content_width(300.0, 24, 320.0, 480.0)
	_assert(width_small == 320.0, "content width should honor minimum clamp")
	var width_large: float = module.calculate_content_width(1600.0, 24, 320.0, 480.0)
	_assert(width_large == 480.0, "content width should honor maximum clamp")
	var width_mid: float = module.calculate_content_width(700.0, 24, 320.0, 480.0)
	_assert(width_mid == 480.0, "content width should clamp to max when available width exceeds max")

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)

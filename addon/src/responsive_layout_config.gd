@tool
class_name ResponsiveLayoutConfig
extends Resource

const ResponsiveScaleModule = preload("responsive_scale_module.gd")

@export_group("Content")

@export var max_content_width: float = 480.0:
	set(value):
		max_content_width = maxf(value, 1.0)
		emit_changed()

@export var min_content_width: float = 320.0:
	set(value):
		min_content_width = maxf(value, 1.0)
		emit_changed()

@export var content_separation_mobile: int = 24:
	set(value):
		content_separation_mobile = maxi(value, 0)
		emit_changed()

@export var content_separation_desktop: int = 48:
	set(value):
		content_separation_desktop = maxi(value, 0)
		emit_changed()

@export_group("Scale")

@export var base_width: float = 720.0:
	set(value):
		base_width = maxf(value, 1.0)
		emit_changed()

@export var base_height: float = 1280.0:
	set(value):
		base_height = maxf(value, 1.0)
		emit_changed()

@export var min_scale: float = 0.75:
	set(value):
		min_scale = maxf(value, 0.01)
		emit_changed()

@export var max_scale: float = 1.5:
	set(value):
		max_scale = maxf(value, min_scale)
		emit_changed()

@export var scale_change_threshold: float = 0.01:
	set(value):
		scale_change_threshold = maxf(value, 0.0)
		emit_changed()

@export_group("Breakpoints")

@export var mobile_breakpoint: int = 768:
	set(value):
		mobile_breakpoint = maxi(value, 1)
		emit_changed()

@export var tablet_breakpoint: int = 1024:
	set(value):
		tablet_breakpoint = maxi(value, mobile_breakpoint + 1)
		emit_changed()

@export var mobile_margin: int = 24:
	set(value):
		mobile_margin = maxi(value, 0)
		emit_changed()

@export var desktop_margin: int = 48:
	set(value):
		desktop_margin = maxi(value, 0)
		emit_changed()

@export var landscape_margin: int = 36:
	set(value):
		landscape_margin = maxi(value, 0)
		emit_changed()

@export_group("Fonts")

@export var button_font_size: int = 28:
	set(value):
		button_font_size = maxi(value, 1)
		emit_changed()

@export var body_font_size: int = 24:
	set(value):
		body_font_size = maxi(value, 1)
		emit_changed()

@export var header_font_size: int = 32:
	set(value):
		header_font_size = maxi(value, 1)
		emit_changed()

@export var subheader_font_size: int = 28:
	set(value):
		subheader_font_size = maxi(value, 1)
		emit_changed()

func to_scale_config() -> ResponsiveScaleModule.ResponsiveConfig:
	var config: ResponsiveScaleModule.ResponsiveConfig = ResponsiveScaleModule.ResponsiveConfig.new()
	config.base_width = base_width
	config.base_height = base_height
	config.min_scale = min_scale
	config.max_scale = max_scale
	config.scale_change_threshold = scale_change_threshold
	config.mobile_breakpoint = mobile_breakpoint
	config.tablet_breakpoint = tablet_breakpoint
	config.mobile_margin = mobile_margin
	config.desktop_margin = desktop_margin
	config.landscape_margin = landscape_margin
	config.content_separation_mobile = content_separation_mobile
	config.content_separation_desktop = content_separation_desktop
	return config

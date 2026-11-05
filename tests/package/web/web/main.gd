extends Control
const ResponsiveScaleModule = preload("res://addons/@aviorstudio_gd-responsive/src/responsive_scale_module.gd")

func _ready() -> void:
	var module := ResponsiveScaleModule.new()
	var device := module.resolve_device_type(Vector2(960, 540))
	$Result.text = "GD Responsive Web Smoke PASS | device=%d | width=%.0f" % [device, module.calculate_content_width(960.0, 48, 320.0, 480.0)]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.title = 'GD Responsive Web Smoke PASS | device=%d | width=480'" % device)

@tool
extends EditorInspectorPlugin

const ResponsiveLayoutConfigScript = preload("responsive_layout_config.gd")

class ValidationPanel extends PanelContainer:
	var _resource: Resource
	var _label: Label

	func bind(resource: Resource) -> void:
		_resource = resource
		_label = Label.new()
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_label)
		if not _resource.changed.is_connected(_refresh):
			_resource.changed.connect(_refresh)
		_refresh()

	func _exit_tree() -> void:
		if _resource != null and _resource.changed.is_connected(_refresh):
			_resource.changed.disconnect(_refresh)

	func _refresh() -> void:
		var warnings: PackedStringArray = _resource.get_validation_warnings()
		visible = not warnings.is_empty()
		_label.text = "Responsive layout configuration warning:\n• " + "\n• ".join(warnings)

func _can_handle(object: Object) -> bool:
	return object is Resource and object.get_script() == ResponsiveLayoutConfigScript

func _parse_begin(object: Object) -> void:
	var panel := ValidationPanel.new()
	panel.bind(object as Resource)
	add_custom_control(panel)

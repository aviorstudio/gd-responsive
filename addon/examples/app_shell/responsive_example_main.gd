@tool
extends Control

@export var viewport_label_path: NodePath = ^"ResponsiveLayout/ScrollContainer/MarginContainer/CenterContainer/VBoxContainer/Header/ViewportLabel"

@onready var _viewport_label: Label = get_node_or_null(viewport_label_path)

func _ready() -> void:
	_update_viewport_label()
	resized.connect(_update_viewport_label)

func _update_viewport_label() -> void:
	if _viewport_label == null:
		return
	_viewport_label.text = "Viewport: %d x %d" % [roundi(size.x), roundi(size.y)]

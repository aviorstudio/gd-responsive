## Attach this script to a plain Control child of a `ResponsiveFlex` to expose
## `flex_grow` and `align_self` as inspector-editable properties.
##
## For Controls that already have their own script (e.g. Buttons, Labels with
## custom behavior), use the static helpers instead:
##     ResponsiveFlex.set_grow(child, 2)
##     ResponsiveFlex.set_align_self(child, ResponsiveFlex.Align.CENTER)
## or declare `@export var flex_grow: int` / `@export var align_self: int` on
## that script — the container picks them up via duck typing.
@tool
class_name ResponsiveFlexItem
extends Control

const _FLEX = preload("res://src/responsive_flex.gd")

## Share of remaining main-axis space (>= 0). 0 = no grow.
@export var flex_grow: int = 0:
	set(value):
		var v: int = maxi(value, 0)
		if v == flex_grow:
			return
		flex_grow = v
		_notify_parent()

## Cross-axis alignment override. -1 inherits the container's `align_items`.
## Values match `ResponsiveFlex.Align`: 0=START, 1=CENTER, 2=END, 3=STRETCH.
@export_range(-1, 3) var align_self: int = -1:
	set(value):
		if value == align_self:
			return
		align_self = value
		_notify_parent()

func _notify_parent() -> void:
	var p: Node = get_parent()
	if p is _FLEX:
		p._invalidate()

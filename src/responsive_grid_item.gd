## Attach this script to a plain Control child of a `ResponsiveGrid` to expose
## `column_span`, `justify_self`, `align_self` as inspector-editable properties.
##
## For Controls that already have their own script, use the static helpers
## instead:
##     ResponsiveGrid.set_span(child, 2)
##     ResponsiveGrid.set_justify_self(child, ResponsiveGrid.Align.CENTER)
##     ResponsiveGrid.set_align_self(child, ResponsiveGrid.Align.CENTER)
## or declare `@export var column_span: int` etc. on that script — the container
## picks them up via duck typing.
@tool
class_name ResponsiveGridItem
extends Control

const _GRID = preload("res://src/responsive_grid.gd")

## Number of columns this cell occupies (>= 1).
@export_range(1, 32) var column_span: int = 1:
	set(value):
		var v: int = maxi(value, 1)
		if v == column_span:
			return
		column_span = v
		_notify_parent()

## Horizontal alignment within the cell. -1 inherits `justify_items`.
## 0=START, 1=CENTER, 2=END, 3=STRETCH.
@export_range(-1, 3) var justify_self: int = -1:
	set(value):
		if value == justify_self:
			return
		justify_self = value
		_notify_parent()

## Vertical alignment within the cell. -1 inherits `align_items`.
## 0=START, 1=CENTER, 2=END, 3=STRETCH.
@export_range(-1, 3) var align_self: int = -1:
	set(value):
		if value == align_self:
			return
		align_self = value
		_notify_parent()

func _notify_parent() -> void:
	var p: Node = get_parent()
	if p is _GRID:
		p._invalidate()

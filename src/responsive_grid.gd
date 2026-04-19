## CSS-grid-inspired container for Godot.
##
## Lays children out in a uniform grid. Supports:
##   - Fixed column count (`columns > 0`)
##   - Auto-fill (`columns = 0`, `min_column_width > 0`): computes column count
##     from the container's current width, like CSS
##     `grid-template-columns: repeat(auto-fill, minmax(min_column_width, 1fr))`.
##
## Container properties (inspector):
##   - columns: int. 0 = auto-fill from `min_column_width`.
##   - min_column_width: float. Minimum column width when auto-filling.
##   - column_gap / row_gap: gutters between cells.
##   - justify_items: horizontal alignment within each cell (START/CENTER/END/STRETCH).
##   - align_items: vertical alignment within each cell (START/CENTER/END/STRETCH).
##   - row_height: float. 0 = use each row's max child minimum height. >0 = fixed row height.
##
## Per-child properties via set_meta:
##   - META_COLUMN_SPAN (int): number of columns this cell occupies. Default 1.
##   - META_JUSTIFY_SELF (int, Align enum or -1 to inherit justify_items).
##   - META_ALIGN_SELF (int, Align enum or -1 to inherit align_items).
##
## Reports horizontal minimum size of 0 so parents can always shrink it.
@tool
class_name ResponsiveGrid
extends Container

enum Align { START, CENTER, END, STRETCH }

## Metadata key for per-child column span. Int >= 1.
const META_COLUMN_SPAN: String = "grid_column_span"
## Metadata key for per-child horizontal alignment override.
const META_JUSTIFY_SELF: String = "grid_justify_self"
## Metadata key for per-child vertical alignment override.
const META_ALIGN_SELF: String = "grid_align_self"

## Fixed column count. 0 = auto-fill using `min_column_width`.
@export_range(0, 32) var columns: int = 0:
	set(value):
		var v: int = maxi(value, 0)
		if v == columns:
			return
		columns = v
		_invalidate()

## Minimum column width used when auto-filling (`columns = 0`).
@export var min_column_width: float = 80.0:
	set(value):
		var v: float = maxf(value, 1.0)
		if v == min_column_width:
			return
		min_column_width = v
		_invalidate()

@export var column_gap: float = 0.0:
	set(value):
		var v: float = maxf(value, 0.0)
		if v == column_gap:
			return
		column_gap = v
		_invalidate()

@export var row_gap: float = 0.0:
	set(value):
		var v: float = maxf(value, 0.0)
		if v == row_gap:
			return
		row_gap = v
		_invalidate()

@export var justify_items: Align = Align.STRETCH:
	set(value):
		if value == justify_items:
			return
		justify_items = value
		_invalidate()

@export var align_items: Align = Align.STRETCH:
	set(value):
		if value == align_items:
			return
		align_items = value
		_invalidate()

## Explicit row height. 0 = auto (use row's max child minimum height).
@export var row_height: float = 0.0:
	set(value):
		var v: float = maxf(value, 0.0)
		if v == row_height:
			return
		row_height = v
		_invalidate()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	child_order_changed.connect(_invalidate)

func _on_resized() -> void:
	_invalidate()

func _invalidate() -> void:
	update_minimum_size()
	queue_sort()

# --- column computation ---

## Returns the number of columns given the container's available width.
func compute_column_count(available_width: float) -> int:
	if columns > 0:
		return columns
	if min_column_width + column_gap <= 0.0:
		return 1
	return maxi(1, int((available_width + column_gap) / (min_column_width + column_gap)))

func _column_width(available_width: float, col_count: int) -> float:
	if col_count <= 0:
		return 0.0
	var gap_total: float = column_gap * float(col_count - 1)
	return maxf((available_width - gap_total) / float(col_count), 0.0)

# --- minimum size ---

func _get_minimum_size() -> Vector2:
	var available: float = size.x
	if available <= 0.0:
		available = min_column_width * maxi(columns, 1)
	var col_count: int = compute_column_count(available)
	var children: Array = _visible_children()
	if children.is_empty() or col_count <= 0:
		return Vector2(0.0, 0.0)
	var height: float = _compute_total_height(children, col_count)
	return Vector2(0.0, height)

func _compute_total_height(children: Array, col_count: int) -> float:
	var rows: Array = _pack_rows(children, col_count)
	var total: float = 0.0
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		total += float(row["height"])
		if i < rows.size() - 1:
			total += row_gap
	return total

# --- layout ---

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_impl()

func _sort_impl() -> void:
	var available: float = size.x
	if available <= 0.0:
		return
	var children: Array = _visible_children()
	if children.is_empty():
		return
	var col_count: int = compute_column_count(available)
	var col_width: float = _column_width(available, col_count)
	var rows: Array = _pack_rows(children, col_count)
	var y: float = 0.0
	for r in range(rows.size()):
		var row: Dictionary = rows[r]
		var row_h: float = float(row["height"])
		var items: Array = row["items"]
		for it in items:
			var child: Control = it["child"]
			var col_idx: int = int(it["col"])
			var span: int = int(it["span"])
			var cell_x: float = float(col_idx) * (col_width + column_gap)
			var cell_w: float = col_width * float(span) + column_gap * float(span - 1)
			var js: int = int(it["justify_self"])
			if js < 0:
				js = int(justify_items)
			var als: int = int(it["align_self"])
			if als < 0:
				als = int(align_items)
			var min_size: Vector2 = child.get_combined_minimum_size()
			var item_w: float = cell_w
			var item_h: float = row_h
			var x_offset: float = 0.0
			var y_offset: float = 0.0
			match js:
				Align.START:
					item_w = min_size.x
				Align.CENTER:
					item_w = min_size.x
					x_offset = (cell_w - item_w) * 0.5
				Align.END:
					item_w = min_size.x
					x_offset = cell_w - item_w
				Align.STRETCH:
					item_w = cell_w
			match als:
				Align.START:
					item_h = min_size.y
				Align.CENTER:
					item_h = min_size.y
					y_offset = (row_h - item_h) * 0.5
				Align.END:
					item_h = min_size.y
					y_offset = row_h - item_h
				Align.STRETCH:
					item_h = row_h
			fit_child_in_rect(
				child,
				Rect2(
					Vector2(cell_x + x_offset, y + y_offset),
					Vector2(item_w, item_h)
				)
			)
		y += row_h
		if r < rows.size() - 1:
			y += row_gap

# --- row packing ---

func _pack_rows(children: Array, col_count: int) -> Array:
	var rows: Array = []
	var current: Dictionary = _new_row()
	var cursor: int = 0
	for child in children:
		var ctrl: Control = child
		var span: int = maxi(int(ctrl.get_meta(META_COLUMN_SPAN, 1)), 1)
		span = mini(span, col_count)
		if cursor + span > col_count and not (current["items"] as Array).is_empty():
			rows.append(current)
			current = _new_row()
			cursor = 0
		var min_size: Vector2 = ctrl.get_combined_minimum_size()
		var item: Dictionary = {
			"child": ctrl,
			"col": cursor,
			"span": span,
			"min_height": min_size.y,
			"justify_self": int(ctrl.get_meta(META_JUSTIFY_SELF, -1)),
			"align_self": int(ctrl.get_meta(META_ALIGN_SELF, -1)),
		}
		(current["items"] as Array).append(item)
		cursor += span
		var row_h_value: float
		if row_height > 0.0:
			row_h_value = row_height
		else:
			row_h_value = maxf(float(current["height"]), min_size.y)
		current["height"] = row_h_value
		if cursor >= col_count:
			rows.append(current)
			current = _new_row()
			cursor = 0
	if not (current["items"] as Array).is_empty():
		rows.append(current)
	return rows

func _new_row() -> Dictionary:
	return {
		"items": [],
		"height": 0.0,
	}

func _visible_children() -> Array:
	var out: Array = []
	for c in get_children():
		if c is Control and (c as Control).visible:
			out.append(c)
	return out

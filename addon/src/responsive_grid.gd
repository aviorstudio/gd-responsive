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
##   - row_height: float. -1 = auto (max child min height). >=0 = fixed row height.
##
## Per-child configuration — use the static helpers instead of metadata keys:
##   - ResponsiveGrid.set_span(child, 2)
##   - ResponsiveGrid.set_justify_self(child, ResponsiveGrid.Align.CENTER)
##   - ResponsiveGrid.set_align_self(child, ResponsiveGrid.Align.CENTER)
## Or attach `ResponsiveGridItem` to a Control child for inspector-editable
## `column_span` / `justify_self` / `align_self` exports.
##
## Breakpoints — set `columns_breakpoints` / `min_column_width_breakpoints` to
## a Dictionary of {min_width_px: value}. The largest key ≤ the container's
## current width wins. Example: `{0: 1, 400: 2, 700: 3}` gives 1 column when
## narrower than 400px, 2 columns from 400–699, 3 columns at ≥700.
## Empty dict = disabled.
##
## Reports horizontal minimum size of 0 so parents can always shrink it.
@tool
class_name ResponsiveGrid
extends Container

enum Align { START, CENTER, END, STRETCH }

const _ALIGN_SELF_INHERIT: int = -1

# Internal metadata keys. Not part of the public API — use the static helpers.
const _META_SPAN: String = "grid_column_span"
const _META_JUSTIFY_SELF: String = "grid_justify_self"
const _META_ALIGN_SELF: String = "grid_align_self"

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

## Explicit row height. -1 = auto (max child min height per row). >=0 = fixed.
@export var row_height: float = -1.0:
	set(value):
		if value == row_height:
			return
		row_height = value
		_invalidate()

## Inner padding (left, top, right, bottom). CSS `padding` analog.
@export var padding: Vector4 = Vector4.ZERO:
	set(value):
		var v: Vector4 = Vector4(maxf(value.x, 0.0), maxf(value.y, 0.0), maxf(value.z, 0.0), maxf(value.w, 0.0))
		if v == padding:
			return
		padding = v
		_invalidate()

## When true (default) the container reports 0 minimum width so parents can
## shrink it freely. When false, reports the natural min width like a native
## GridContainer — useful when replacing a fixed-width GridContainer.
@export var shrink: bool = true:
	set(value):
		if value == shrink:
			return
		shrink = value
		_invalidate()

@export_group("Breakpoints")

## Columns per container width: {min_width_px: int}.
## Largest key ≤ size.x wins. Empty = disabled, use `columns`.
@export var columns_breakpoints: Dictionary = {}:
	set(value):
		columns_breakpoints = value
		_invalidate()

## Min column width per container width: {min_width_px: float}.
## Largest key ≤ size.x wins. Empty = disabled, use `min_column_width`.
@export var min_column_width_breakpoints: Dictionary = {}:
	set(value):
		min_column_width_breakpoints = value
		_invalidate()

# --- public static helpers (per-child configuration) ---

## Set a child's column span (number of columns to occupy). Min 1.
static func set_span(child: Control, span: int) -> void:
	if child == null:
		return
	var v: int = maxi(span, 1)
	if "column_span" in child:
		child.column_span = v
	else:
		child.set_meta(_META_SPAN, v)
	_notify_grid_parent(child)

static func get_span(child: Control) -> int:
	if child == null:
		return 1
	if "column_span" in child:
		return maxi(int(child.column_span), 1)
	return maxi(int(child.get_meta(_META_SPAN, 1)), 1)

## Override a child's horizontal alignment within its cell. -1 to inherit.
static func set_justify_self(child: Control, align: int) -> void:
	if child == null:
		return
	if "justify_self" in child:
		child.justify_self = align
	else:
		child.set_meta(_META_JUSTIFY_SELF, align)
	_notify_grid_parent(child)

static func get_justify_self(child: Control) -> int:
	if child == null:
		return _ALIGN_SELF_INHERIT
	if "justify_self" in child:
		return int(child.justify_self)
	return int(child.get_meta(_META_JUSTIFY_SELF, _ALIGN_SELF_INHERIT))

## Override a child's vertical alignment within its cell. -1 to inherit.
static func set_align_self(child: Control, align: int) -> void:
	if child == null:
		return
	if "align_self" in child:
		child.align_self = align
	else:
		child.set_meta(_META_ALIGN_SELF, align)
	_notify_grid_parent(child)

static func get_align_self(child: Control) -> int:
	if child == null:
		return _ALIGN_SELF_INHERIT
	if "align_self" in child:
		return int(child.align_self)
	return int(child.get_meta(_META_ALIGN_SELF, _ALIGN_SELF_INHERIT))

static func _notify_grid_parent(child: Control) -> void:
	# Poke parent to re-layout if it looks like a ResponsiveGrid (duck-typed
	# to avoid class_name resolution issues when running scripts directly).
	if child == null:
		return
	var p: Node = child.get_parent()
	if p != null and p.has_method("_invalidate") and "columns_breakpoints" in p:
		p._invalidate()

# --- lifecycle ---

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	child_order_changed.connect(_invalidate)

func _on_resized() -> void:
	_invalidate()

func _invalidate() -> void:
	update_minimum_size()
	queue_sort()

# --- breakpoint resolution ---

func resolve_columns(for_width: float) -> int:
	if columns_breakpoints.is_empty():
		return columns
	var v: Variant = _resolve_breakpoint(columns_breakpoints, for_width)
	if v == null:
		return columns
	return int(v)

func resolve_min_column_width(for_width: float) -> float:
	if min_column_width_breakpoints.is_empty():
		return min_column_width
	var v: Variant = _resolve_breakpoint(min_column_width_breakpoints, for_width)
	if v == null:
		return min_column_width
	return float(v)

static func _resolve_breakpoint(bp: Dictionary, width: float) -> Variant:
	var best_key: float = -INF
	var best_val: Variant = null
	for k in bp.keys():
		var kf: float = float(k)
		if kf <= width and kf > best_key:
			best_key = kf
			best_val = bp[k]
	if best_key == -INF:
		return null
	return best_val

# --- column computation ---

## Returns the number of columns given the container's available width.
func compute_column_count(available_width: float) -> int:
	var cols: int = resolve_columns(size.x)
	if cols > 0:
		return cols
	var min_w: float = resolve_min_column_width(size.x)
	if min_w + column_gap <= 0.0:
		return 1
	return maxi(1, int((available_width + column_gap) / (min_w + column_gap)))

func _column_width(available_width: float, col_count: int) -> float:
	if col_count <= 0:
		return 0.0
	var gap_total: float = column_gap * float(col_count - 1)
	return maxf((available_width - gap_total) / float(col_count), 0.0)

# --- minimum size ---

func _get_minimum_size() -> Vector2:
	var pad_h: float = padding.x + padding.z
	var pad_v: float = padding.y + padding.w
	var available: float = size.x - pad_h
	var cols: int = resolve_columns(size.x)
	var min_w: float = resolve_min_column_width(size.x)
	if available <= 0.0:
		available = min_w * maxi(cols, 1)
	var col_count: int = compute_column_count(available)
	var children: Array = _visible_children()
	if children.is_empty() or col_count <= 0:
		return Vector2(pad_h, pad_v)
	var height: float = _compute_total_height(children, col_count)
	var width_min: float = 0.0
	if not shrink:
		width_min = min_w * float(col_count) + column_gap * float(maxi(col_count - 1, 0))
	return Vector2(width_min + pad_h, height + pad_v)

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
	var pad_l: float = padding.x
	var pad_t: float = padding.y
	var pad_r: float = padding.z
	var pad_b: float = padding.w
	var available: float = size.x - pad_l - pad_r
	if available <= 0.0:
		return
	var children: Array = _visible_children()
	if children.is_empty():
		return
	var col_count: int = compute_column_count(available)
	var col_width: float = _column_width(available, col_count)
	var rows: Array = _pack_rows(children, col_count)
	var y: float = pad_t
	for r in range(rows.size()):
		var row: Dictionary = rows[r]
		var row_h: float = float(row["height"])
		var items: Array = row["items"]
		for it in items:
			var child: Control = it["child"]
			var col_idx: int = int(it["col"])
			var span: int = int(it["span"])
			var cell_x: float = pad_l + float(col_idx) * (col_width + column_gap)
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
	var _unused: float = pad_b

# --- row packing ---

func _pack_rows(children: Array, col_count: int) -> Array:
	var rows: Array = []
	var current: Dictionary = _new_row()
	var cursor: int = 0
	for child in children:
		var ctrl: Control = child
		var span: int = get_span(ctrl)
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
			"justify_self": get_justify_self(ctrl),
			"align_self": get_align_self(ctrl),
		}
		(current["items"] as Array).append(item)
		cursor += span
		var row_h_value: float
		if row_height >= 0.0:
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

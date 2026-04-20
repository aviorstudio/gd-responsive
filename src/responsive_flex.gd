## CSS-flex-inspired container for Godot.
##
## Lays children out in a single direction, optionally wrapping. Reports
## minimum cross-axis size of 0 so parents can always shrink this container
## freely. Mirrors CSS flex box semantics where practical.
##
## Container properties (inspector):
##   - direction: ROW or COLUMN
##   - justify_content: START / CENTER / END / SPACE_BETWEEN / SPACE_AROUND / SPACE_EVENLY
##   - align_items: START / CENTER / END / STRETCH (cross-axis alignment within a line)
##   - gap: spacing between items (main axis)
##   - cross_gap: spacing between wrapped lines (cross axis). Use -1 to inherit `gap`.
##   - wrap: if true, items wrap onto new lines when they overflow.
##
## Per-child configuration — use the static helpers instead of metadata keys:
##   - ResponsiveFlex.set_grow(child, 2)
##   - ResponsiveFlex.set_align_self(child, ResponsiveFlex.Align.CENTER)
## Or attach `ResponsiveFlexItem` to a Control child for inspector-editable
## `flex_grow` / `align_self` exports.
##
## Breakpoints — set `direction_breakpoints` / `gap_breakpoints` to a Dictionary
## of {min_width_px: value}. The largest key ≤ the container's current width
## wins. Example: `{0: Direction.COLUMN, 600: Direction.ROW}` makes the flex
## a column when narrower than 600px and a row otherwise. Empty dict = disabled.
##
## See tests/responsive_flex_test.gd for examples.
@tool
class_name ResponsiveFlex
extends Container

enum Direction { ROW, COLUMN }
enum Justify { START, CENTER, END, SPACE_BETWEEN, SPACE_AROUND, SPACE_EVENLY }
enum Align { START, CENTER, END, STRETCH }

const _ALIGN_SELF_INHERIT: int = -1

# Internal metadata keys. Not part of the public API — use the static helpers.
const _META_GROW: String = "flex_grow"
const _META_ALIGN_SELF: String = "align_self"

@export var direction: Direction = Direction.ROW:
	set(value):
		if value == direction:
			return
		direction = value
		_invalidate()

@export var justify_content: Justify = Justify.START:
	set(value):
		if value == justify_content:
			return
		justify_content = value
		_invalidate()

@export var align_items: Align = Align.STRETCH:
	set(value):
		if value == align_items:
			return
		align_items = value
		_invalidate()

@export var gap: float = 0.0:
	set(value):
		if value == gap:
			return
		gap = value
		_invalidate()

## Spacing between wrapped lines. -1 (default) inherits `gap`.
@export var cross_gap: float = -1.0:
	set(value):
		if value == cross_gap:
			return
		cross_gap = value
		_invalidate()

@export var wrap: bool = false:
	set(value):
		if value == wrap:
			return
		wrap = value
		_invalidate()

## Inner padding (left, top, right, bottom). CSS `padding` analog.
@export var padding: Vector4 = Vector4.ZERO:
	set(value):
		var v: Vector4 = Vector4(maxf(value.x, 0.0), maxf(value.y, 0.0), maxf(value.z, 0.0), maxf(value.w, 0.0))
		if v == padding:
			return
		padding = v
		_invalidate()

## When true (default) the container reports 0 on its main axis so parent
## containers can shrink it freely — matches CSS flex-item behavior. When
## false, reports the sum of children's min sizes + gaps + padding like a
## native HBox/VBox, making this a drop-in replacement for those containers.
@export var shrink: bool = true:
	set(value):
		if value == shrink:
			return
		shrink = value
		_invalidate()

@export_group("Breakpoints")

## Direction per container width: {min_width_px: Direction}.
## Largest key ≤ size.x wins. Empty = disabled, use `direction`.
@export var direction_breakpoints: Dictionary = {}:
	set(value):
		direction_breakpoints = value
		_invalidate()

## Main-axis gap per container width: {min_width_px: float}.
## Largest key ≤ size.x wins. Empty = disabled, use `gap`.
@export var gap_breakpoints: Dictionary = {}:
	set(value):
		gap_breakpoints = value
		_invalidate()

# --- public static helpers (per-child configuration) ---

## Set a child's flex-grow factor (share of remaining main-axis space).
static func set_grow(child: Control, grow: int) -> void:
	if child == null:
		return
	if "flex_grow" in child:
		child.flex_grow = maxi(grow, 0)
	else:
		child.set_meta(_META_GROW, maxi(grow, 0))
	_notify_flex_parent(child)

## Return a child's flex-grow factor. Falls back to 1 when the child's
## Godot `size_flags` expand bit is set on the main axis (matches native
## HBox/VBox intuition: `SIZE_EXPAND_FILL` == fill remaining space).
static func get_grow(child: Control, is_row: bool = true) -> int:
	if child == null:
		return 0
	var explicit: int = -1
	if "flex_grow" in child:
		explicit = int(child.flex_grow)
	elif child.has_meta(_META_GROW):
		explicit = int(child.get_meta(_META_GROW))
	if explicit >= 0:
		return explicit
	var flags: int = child.size_flags_horizontal if is_row else child.size_flags_vertical
	if flags & Control.SIZE_EXPAND:
		return 1
	return 0

## Override a child's cross-axis alignment within its line. Pass -1 to inherit
## the container's `align_items`.
static func set_align_self(child: Control, align: int) -> void:
	if child == null:
		return
	if "align_self" in child:
		child.align_self = align
	else:
		child.set_meta(_META_ALIGN_SELF, align)
	_notify_flex_parent(child)

## Return a child's cross-axis override (or -1 if inheriting).
static func get_align_self(child: Control) -> int:
	if child == null:
		return _ALIGN_SELF_INHERIT
	if "align_self" in child:
		return int(child.align_self)
	return int(child.get_meta(_META_ALIGN_SELF, _ALIGN_SELF_INHERIT))

static func _notify_flex_parent(child: Control) -> void:
	# Poke parent to re-layout if it looks like a ResponsiveFlex (duck-typed
	# to avoid class_name resolution issues when running scripts directly).
	if child == null:
		return
	var p: Node = child.get_parent()
	if p != null and p.has_method("_invalidate") and "direction_breakpoints" in p:
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

## Public so callers can debug which direction/gap would apply at a given width.
func resolve_direction(for_width: float) -> Direction:
	if direction_breakpoints.is_empty():
		return direction
	var v: Variant = _resolve_breakpoint(direction_breakpoints, for_width)
	if v == null:
		return direction
	return int(v) as Direction

func resolve_gap(for_width: float) -> float:
	if gap_breakpoints.is_empty():
		return gap
	var v: Variant = _resolve_breakpoint(gap_breakpoints, for_width)
	if v == null:
		return gap
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

# --- minimum size ---

func _get_minimum_size() -> Vector2:
	var dir: int = resolve_direction(size.x)
	var g: float = resolve_gap(size.x)
	var is_row: bool = dir == Direction.ROW
	var pad_main: float = (padding.x + padding.z) if is_row else (padding.y + padding.w)
	var pad_cross: float = (padding.y + padding.w) if is_row else (padding.x + padding.z)
	var visible: Array = _visible_children()
	if visible.is_empty():
		if is_row:
			return Vector2(pad_main, pad_cross)
		return Vector2(pad_cross, pad_main)
	# Cross axis: for wrap=true we need the total stacked line height so that
	# parents (e.g. ScrollContainer) reserve enough space for every wrapped
	# row. For wrap=false it's just the tallest child.
	var available_main: float = (size.x if is_row else size.y) - pad_main
	var lines: Array = _compute_lines(maxf(available_main, 0.0), is_row, g)
	var cross_total: float = _sum_line_cross(lines, g)
	# Main axis: 0 when shrink=true (flex-item semantics); natural content
	# size otherwise (drop-in HBox/VBox replacement).
	var main_total: float = 0.0
	var main_max: float = 0.0
	for child in visible:
		var ctrl: Control = child
		var ms: Vector2 = ctrl.get_combined_minimum_size()
		var m: float = ms.x if is_row else ms.y
		main_total += m
		main_max = maxf(main_max, m)
	main_total += g * maxf(float(visible.size() - 1), 0.0)
	var main_min: float = 0.0
	if not shrink:
		main_min = main_max if wrap else main_total
	var final_main: float = main_min + pad_main
	var final_cross: float = cross_total + pad_cross
	if is_row:
		return Vector2(final_main, final_cross)
	return Vector2(final_cross, final_main)

# --- layout ---

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_impl()

func _sort_impl() -> void:
	var dir: int = resolve_direction(size.x)
	var g: float = resolve_gap(size.x)
	var is_row: bool = dir == Direction.ROW
	var pad_main_start: float = padding.x if is_row else padding.y
	var pad_main_end: float = padding.z if is_row else padding.w
	var pad_cross_start: float = padding.y if is_row else padding.x
	var pad_cross_end: float = padding.w if is_row else padding.z
	var main_size: float = (size.x if is_row else size.y) - pad_main_start - pad_main_end
	var cross_size: float = (size.y if is_row else size.x) - pad_cross_start - pad_cross_end
	if main_size <= 0.0:
		return
	var lines: Array = _compute_lines(main_size, is_row, g)
	if lines.is_empty():
		return
	var cross_cursor: float = pad_cross_start
	if not wrap and lines.size() == 1:
		lines[0]["cross"] = cross_size
	var line_gap: float = cross_gap if cross_gap >= 0.0 else g
	for i in range(lines.size()):
		var line: Dictionary = lines[i]
		_layout_line(line, main_size, pad_main_start, cross_cursor, is_row, g)
		cross_cursor += float(line["cross"])
		if i < lines.size() - 1:
			cross_cursor += line_gap

func _layout_line(line: Dictionary, main_size: float, main_start: float, cross_start: float, is_row: bool, g: float) -> void:
	var items: Array = line["items"]
	var line_cross: float = float(line["cross"])
	var base_main: float = float(line["base_main"])
	var grow_total: int = int(line["grow_total"])
	var free: float = maxf(main_size - base_main, 0.0)
	var extra_lead: float = 0.0
	var extra_between: float = g
	if grow_total == 0 and items.size() > 0:
		match justify_content:
			Justify.CENTER:
				extra_lead = free * 0.5
			Justify.END:
				extra_lead = free
			Justify.SPACE_BETWEEN:
				if items.size() > 1:
					extra_between = g + free / float(items.size() - 1)
			Justify.SPACE_AROUND:
				var around: float = free / float(items.size())
				extra_lead = around * 0.5
				extra_between = g + around
			Justify.SPACE_EVENLY:
				var evenly: float = free / float(items.size() + 1)
				extra_lead = evenly
				extra_between = g + evenly
			_:
				pass
	var main_cursor: float = main_start + extra_lead
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var child: Control = item["child"]
		var main_px: float = float(item["main"])
		if grow_total > 0:
			main_px += free * float(item["grow"]) / float(grow_total)
		var cross_px: float = float(item["cross"])
		var self_align: int = int(item["align_self"])
		if self_align < 0:
			self_align = int(align_items)
		var cross_offset: float = 0.0
		var final_cross: float = cross_px
		match self_align:
			Align.START:
				cross_offset = 0.0
			Align.CENTER:
				cross_offset = (line_cross - cross_px) * 0.5
			Align.END:
				cross_offset = line_cross - cross_px
			Align.STRETCH:
				final_cross = line_cross
				cross_offset = 0.0
		var rect: Rect2
		if is_row:
			rect = Rect2(Vector2(main_cursor, cross_start + cross_offset), Vector2(main_px, final_cross))
		else:
			rect = Rect2(Vector2(cross_start + cross_offset, main_cursor), Vector2(final_cross, main_px))
		fit_child_in_rect(child, rect)
		main_cursor += main_px
		if i < items.size() - 1:
			main_cursor += extra_between

# --- line packing ---

func _compute_lines(available_main: float, is_row: bool, g: float) -> Array:
	var children: Array = _visible_children()
	if children.is_empty():
		return []
	var lines: Array = []
	var current: Dictionary = _new_line()
	for child in children:
		var ctrl: Control = child
		var min_size: Vector2 = ctrl.get_combined_minimum_size()
		var main_px: float = min_size.x if is_row else min_size.y
		var cross_px: float = min_size.y if is_row else min_size.x
		var grow: int = get_grow(ctrl, is_row)
		var align_self_val: int = get_align_self(ctrl)
		var item: Dictionary = {
			"child": ctrl,
			"main": main_px,
			"cross": cross_px,
			"grow": maxi(grow, 0),
			"align_self": align_self_val,
		}
		var projected: float = float(current["base_main"]) + main_px
		if not (current["items"] as Array).is_empty():
			projected += g
		var would_overflow: bool = wrap and projected > available_main
		if would_overflow and not (current["items"] as Array).is_empty():
			lines.append(current)
			current = _new_line()
		(current["items"] as Array).append(item)
		var line_items: Array = current["items"]
		var line_base: float = 0.0
		for it in line_items:
			line_base += float(it["main"])
		line_base += g * maxf(float(line_items.size() - 1), 0.0)
		current["base_main"] = line_base
		current["grow_total"] = int(current["grow_total"]) + item["grow"]
		current["cross"] = maxf(float(current["cross"]), cross_px)
	if not (current["items"] as Array).is_empty():
		lines.append(current)
	return lines

func _new_line() -> Dictionary:
	return {
		"items": [],
		"base_main": 0.0,
		"grow_total": 0,
		"cross": 0.0,
	}

func _sum_line_cross(lines: Array, g: float) -> float:
	if lines.is_empty():
		return 0.0
	var line_gap: float = cross_gap if cross_gap >= 0.0 else g
	var total: float = 0.0
	for i in range(lines.size()):
		total += float(lines[i]["cross"])
		if i < lines.size() - 1:
			total += line_gap
	return total

func _visible_children() -> Array:
	var out: Array = []
	for c in get_children():
		if c is Control and (c as Control).visible:
			out.append(c)
	return out

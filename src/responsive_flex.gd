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
##   - cross_gap: spacing between wrapped lines (cross axis). 0 falls back to `gap`.
##   - wrap: if true, items wrap onto new lines when they overflow.
##
## Per-child properties via set_meta:
##   - META_FLEX_GROW (int): share of remaining free space along the main axis. Default 0.
##   - META_ALIGN_SELF (int, Align enum or -1 = inherit align_items). Default -1.
##
## See tests/responsive_flex_test.gd for examples.
@tool
class_name ResponsiveFlex
extends Container

enum Direction { ROW, COLUMN }
enum Justify { START, CENTER, END, SPACE_BETWEEN, SPACE_AROUND, SPACE_EVENLY }
enum Align { START, CENTER, END, STRETCH }

## Metadata key for per-child main-axis grow factor. Int >= 0.
const META_FLEX_GROW: String = "flex_grow"
## Metadata key for per-child cross-axis override (int matching `Align`, or -1 to inherit).
const META_ALIGN_SELF: String = "align_self"

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
		var v: float = maxf(value, 0.0)
		if v == gap:
			return
		gap = v
		_invalidate()

## Spacing between wrapped lines. If 0 (default), falls back to `gap`.
@export var cross_gap: float = 0.0:
	set(value):
		var v: float = maxf(value, 0.0)
		if v == cross_gap:
			return
		cross_gap = v
		_invalidate()

@export var wrap: bool = false:
	set(value):
		if value == wrap:
			return
		wrap = value
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

# --- minimum size ---

func _get_minimum_size() -> Vector2:
	# Report 0 on main axis so parent containers can shrink us freely (matches
	# CSS `min-width: 0` / `min-height: 0` pattern for flex items).
	var is_row: bool = direction == Direction.ROW
	var available_main: float = size.x if is_row else size.y
	var lines: Array = _compute_lines(available_main)
	var cross_total: float = _sum_line_cross(lines)
	if is_row:
		return Vector2(0.0, cross_total)
	return Vector2(cross_total, 0.0)

# --- layout ---

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_impl()

func _sort_impl() -> void:
	var is_row: bool = direction == Direction.ROW
	var main_size: float = size.x if is_row else size.y
	var cross_size: float = size.y if is_row else size.x
	if main_size <= 0.0:
		return
	var lines: Array = _compute_lines(main_size)
	if lines.is_empty():
		return
	var total_cross: float = _sum_line_cross(lines)
	# Cross-axis start offset: align_content ≈ START for MVP; wrap lines stack
	# from the top/left. If there is a single line we still honor align_items
	# within the line, but do not vertically center the whole set.
	var cross_cursor: float = 0.0
	if not wrap and lines.size() == 1:
		# In no-wrap single-line mode, use full cross size for stretch math
		lines[0]["cross"] = cross_size
	var line_gap: float = cross_gap if cross_gap > 0.0 else gap
	for i in range(lines.size()):
		var line: Dictionary = lines[i]
		_layout_line(line, main_size, cross_cursor, is_row)
		cross_cursor += float(line["cross"])
		if i < lines.size() - 1:
			cross_cursor += line_gap
	# Silence unused warning when total_cross not needed
	var _unused: float = total_cross

func _layout_line(line: Dictionary, main_size: float, cross_start: float, is_row: bool) -> void:
	var items: Array = line["items"]
	var line_cross: float = float(line["cross"])
	var base_main: float = float(line["base_main"])
	var grow_total: int = int(line["grow_total"])
	var free: float = maxf(main_size - base_main, 0.0)
	var gap_count: int = maxi(items.size() - 1, 0)
	# justify-content only applies when there is no grow to consume free space.
	var extra_lead: float = 0.0
	var extra_between: float = gap
	if grow_total == 0 and items.size() > 0:
		match justify_content:
			Justify.CENTER:
				extra_lead = free * 0.5
			Justify.END:
				extra_lead = free
			Justify.SPACE_BETWEEN:
				if items.size() > 1:
					extra_between = gap + free / float(items.size() - 1)
			Justify.SPACE_AROUND:
				var around: float = free / float(items.size())
				extra_lead = around * 0.5
				extra_between = gap + around
			Justify.SPACE_EVENLY:
				var evenly: float = free / float(items.size() + 1)
				extra_lead = evenly
				extra_between = gap + evenly
			_:
				pass
	var main_cursor: float = extra_lead
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

func _compute_lines(available_main: float) -> Array:
	var children: Array = _visible_children()
	if children.is_empty():
		return []
	var is_row: bool = direction == Direction.ROW
	var lines: Array = []
	var current: Dictionary = _new_line()
	for child in children:
		var ctrl: Control = child
		var min_size: Vector2 = ctrl.get_combined_minimum_size()
		var main_px: float = min_size.x if is_row else min_size.y
		var cross_px: float = min_size.y if is_row else min_size.x
		var grow: int = int(ctrl.get_meta(META_FLEX_GROW, 0))
		var align_self: int = int(ctrl.get_meta(META_ALIGN_SELF, -1))
		var item: Dictionary = {
			"child": ctrl,
			"main": main_px,
			"cross": cross_px,
			"grow": maxi(grow, 0),
			"align_self": align_self,
		}
		var projected: float = float(current["base_main"]) + main_px
		if not (current["items"] as Array).is_empty():
			projected += gap
		var would_overflow: bool = wrap and projected > available_main
		if would_overflow and not (current["items"] as Array).is_empty():
			lines.append(current)
			current = _new_line()
		(current["items"] as Array).append(item)
		var line_items: Array = current["items"]
		var line_base: float = 0.0
		for it in line_items:
			line_base += float(it["main"])
		line_base += gap * maxf(float(line_items.size() - 1), 0.0)
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

func _sum_line_cross(lines: Array) -> float:
	if lines.is_empty():
		return 0.0
	var line_gap: float = cross_gap if cross_gap > 0.0 else gap
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

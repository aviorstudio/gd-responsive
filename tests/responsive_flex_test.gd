extends SceneTree

const ResponsiveFlex = preload("res://src/responsive_flex.gd")
const ResponsiveFlexItem = preload("res://src/responsive_flex_item.gd")

var _root: Window = null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_root = root
	_test_row_wrap_distributes_cards()
	_test_row_no_wrap_single_line()
	_test_flex_grow_shares_remaining_space()
	_test_justify_center_offsets_start()
	_test_column_direction()
	_test_align_self_override()
	_test_zero_width_does_not_crash()
	_test_hidden_children_ignored()
	_test_minimum_size_reports_zero_main_axis()
	_test_shrink_false_reports_content_size()
	_test_padding_offsets_layout()
	_test_static_helpers_set_and_get()
	_test_direction_breakpoints()
	_test_gap_breakpoints()
	_test_flex_item_script_duck_typing()
	quit()

func _make_child(min_size: Vector2, grow: int = 0, align_self: int = -1) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = min_size
	if grow != 0:
		ResponsiveFlex.set_grow(c, grow)
	if align_self >= 0:
		ResponsiveFlex.set_align_self(c, align_self)
	return c

func _mount(flex: ResponsiveFlex, container_size: Vector2) -> void:
	_root.add_child(flex)
	flex.size = container_size
	flex.notification(Container.NOTIFICATION_SORT_CHILDREN)

func _cleanup(flex: ResponsiveFlex) -> void:
	flex.queue_free()

func _test_row_wrap_distributes_cards() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = true
	flex.gap = 4.0
	flex.justify_content = ResponsiveFlex.Justify.START
	flex.align_items = ResponsiveFlex.Align.START
	var children: Array[Control] = []
	for i in range(6):
		var c: Control = _make_child(Vector2(80, 100))
		flex.add_child(c)
		children.append(c)
	_mount(flex, Vector2(260, 400))
	# Available width 260; item 80 + gap 4; fits floor((260+4)/(80+4))=3 per row
	var row1_count: int = 0
	var row2_count: int = 0
	var first_row_y: float = children[0].position.y
	for c in children:
		if is_equal_approx(c.position.y, first_row_y):
			row1_count += 1
		else:
			row2_count += 1
	_assert(row1_count == 3, "row1 should have 3 items, got %d" % row1_count)
	_assert(row2_count == 3, "row2 should have 3 items, got %d" % row2_count)
	_assert(children[0].position.x == 0.0, "first item starts at x=0 with justify=START")
	_cleanup(flex)

func _test_row_no_wrap_single_line() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = false
	flex.gap = 4.0
	for i in range(3):
		flex.add_child(_make_child(Vector2(60, 40)))
	_mount(flex, Vector2(200, 100))
	var ys: Array[float] = []
	for c in flex.get_children():
		ys.append((c as Control).position.y)
	_assert(ys[0] == ys[1] and ys[1] == ys[2], "no-wrap means all children on one line")
	_cleanup(flex)

func _test_flex_grow_shares_remaining_space() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = false
	flex.gap = 0.0
	var a: Control = _make_child(Vector2(50, 20), 1)
	var b: Control = _make_child(Vector2(50, 20), 3)
	flex.add_child(a)
	flex.add_child(b)
	_mount(flex, Vector2(200, 40))
	# Free space = 200 - 100 = 100; share 1:3 -> a gets 25, b gets 75
	_assert(is_equal_approx(a.size.x, 75.0), "a should be 50 + 25 = 75, got %f" % a.size.x)
	_assert(is_equal_approx(b.size.x, 125.0), "b should be 50 + 75 = 125, got %f" % b.size.x)
	_cleanup(flex)

func _test_justify_center_offsets_start() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = false
	flex.gap = 0.0
	flex.justify_content = ResponsiveFlex.Justify.CENTER
	flex.add_child(_make_child(Vector2(80, 20)))
	flex.add_child(_make_child(Vector2(80, 20)))
	_mount(flex, Vector2(200, 40))
	# Content width 160; free space 40; centered start = 20
	var first: Control = flex.get_child(0)
	_assert(is_equal_approx(first.position.x, 20.0), "centered first item x should be 20, got %f" % first.position.x)
	_cleanup(flex)

func _test_column_direction() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.COLUMN
	flex.wrap = false
	flex.gap = 4.0
	flex.add_child(_make_child(Vector2(50, 20)))
	flex.add_child(_make_child(Vector2(50, 20)))
	_mount(flex, Vector2(100, 200))
	var a: Control = flex.get_child(0)
	var b: Control = flex.get_child(1)
	_assert(is_equal_approx(a.position.y, 0.0), "first column item at y=0")
	_assert(is_equal_approx(b.position.y, 24.0), "second column item at y=24, got %f" % b.position.y)
	_cleanup(flex)

func _test_align_self_override() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = false
	flex.align_items = ResponsiveFlex.Align.START
	flex.add_child(_make_child(Vector2(50, 20)))
	flex.add_child(_make_child(Vector2(50, 20), 0, ResponsiveFlex.Align.CENTER))
	_mount(flex, Vector2(200, 100))
	var start_child: Control = flex.get_child(0)
	var center_child: Control = flex.get_child(1)
	_assert(is_equal_approx(start_child.position.y, 0.0), "align_items=START yields y=0")
	_assert(is_equal_approx(center_child.position.y, 40.0), "align_self=CENTER yields y=(100-20)/2=40, got %f" % center_child.position.y)
	_cleanup(flex)

func _test_zero_width_does_not_crash() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = true
	flex.add_child(_make_child(Vector2(80, 100)))
	_root.add_child(flex)
	flex.size = Vector2(0.0, 0.0)
	flex.notification(Container.NOTIFICATION_SORT_CHILDREN)
	_assert(true, "zero-width container should not crash")
	_cleanup(flex)

func _test_hidden_children_ignored() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = true
	flex.gap = 4.0
	var a: Control = _make_child(Vector2(80, 40))
	var b: Control = _make_child(Vector2(80, 40))
	b.visible = false
	var c: Control = _make_child(Vector2(80, 40))
	flex.add_child(a)
	flex.add_child(b)
	flex.add_child(c)
	_mount(flex, Vector2(260, 100))
	_assert(a.position.y == c.position.y, "hidden item should not push c to a new row")
	_cleanup(flex)

func _test_minimum_size_reports_zero_main_axis() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = true
	flex.add_child(_make_child(Vector2(500, 100)))
	_root.add_child(flex)
	flex.size = Vector2(200, 400)
	var min_size: Vector2 = flex._get_minimum_size()
	_assert(is_equal_approx(min_size.x, 0.0), "minimum_size.x must be 0 for flex row")
	_cleanup(flex)

func _test_shrink_false_reports_content_size() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = false
	flex.gap = 4.0
	flex.shrink = false
	flex.add_child(_make_child(Vector2(50, 20)))
	flex.add_child(_make_child(Vector2(60, 30)))
	_root.add_child(flex)
	var min_size: Vector2 = flex._get_minimum_size()
	# no-wrap: sum of mains + gap = 50 + 60 + 4 = 114; cross = max(20,30) = 30
	_assert(is_equal_approx(min_size.x, 114.0), "shrink=false row min.x should be 114, got %f" % min_size.x)
	_assert(is_equal_approx(min_size.y, 30.0), "shrink=false row min.y should be 30, got %f" % min_size.y)
	_cleanup(flex)

func _test_padding_offsets_layout() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.wrap = false
	flex.gap = 0.0
	flex.padding = Vector4(10, 8, 6, 4)  # l, t, r, b
	var a: Control = _make_child(Vector2(40, 30))
	var b: Control = _make_child(Vector2(40, 30))
	flex.add_child(a)
	flex.add_child(b)
	_mount(flex, Vector2(200, 100))
	_assert(is_equal_approx(a.position.x, 10.0), "padded first child should start at pad.x=10, got %f" % a.position.x)
	_assert(is_equal_approx(a.position.y, 8.0), "padded first child should start at pad.y=8, got %f" % a.position.y)
	_assert(is_equal_approx(b.position.x, 50.0), "second child x=10+40=50, got %f" % b.position.x)
	# Cross axis available = 100 - 8 - 4 = 88; STRETCH means child height = 88
	_assert(is_equal_approx(a.size.y, 88.0), "STRETCH cross size = 100-pad=88, got %f" % a.size.y)
	_cleanup(flex)

func _test_static_helpers_set_and_get() -> void:
	var c: Control = Control.new()
	_assert(ResponsiveFlex.get_grow(c) == 0, "default grow is 0")
	_assert(ResponsiveFlex.get_align_self(c) == -1, "default align_self is -1")
	ResponsiveFlex.set_grow(c, 3)
	ResponsiveFlex.set_align_self(c, ResponsiveFlex.Align.CENTER)
	_assert(ResponsiveFlex.get_grow(c) == 3, "grow persists after set_grow")
	_assert(ResponsiveFlex.get_align_self(c) == int(ResponsiveFlex.Align.CENTER), "align_self persists after set_align_self")
	# Clamps negatives to 0
	ResponsiveFlex.set_grow(c, -5)
	_assert(ResponsiveFlex.get_grow(c) == 0, "negative grow clamped to 0")
	c.queue_free()

func _test_direction_breakpoints() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.direction_breakpoints = {
		0: ResponsiveFlex.Direction.COLUMN,
		600: ResponsiveFlex.Direction.ROW,
	}
	flex.add_child(_make_child(Vector2(50, 20)))
	flex.add_child(_make_child(Vector2(50, 20)))
	_mount(flex, Vector2(400, 200))
	var a: Control = flex.get_child(0)
	var b: Control = flex.get_child(1)
	# Below 600 → COLUMN → children stack vertically at x=0
	_assert(is_equal_approx(a.position.x, 0.0) and is_equal_approx(b.position.x, 0.0), "width<600 stacks as column (x=0)")
	_assert(b.position.y > a.position.y, "width<600 column places b below a")
	# At 700 → ROW → children sit at same y
	flex.size = Vector2(700, 200)
	flex.notification(Container.NOTIFICATION_SORT_CHILDREN)
	_assert(is_equal_approx(a.position.y, b.position.y), "width>=600 row aligns on y")
	_cleanup(flex)

func _test_gap_breakpoints() -> void:
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.gap = 4.0
	flex.gap_breakpoints = { 0: 2.0, 500: 16.0 }
	flex.add_child(_make_child(Vector2(50, 20)))
	flex.add_child(_make_child(Vector2(50, 20)))
	_mount(flex, Vector2(300, 100))
	var b: Control = flex.get_child(1)
	# Below 500 → gap=2 → b starts at 50+2=52
	_assert(is_equal_approx(b.position.x, 52.0), "gap_breakpoints[0]=2 yields b.x=52, got %f" % b.position.x)
	flex.size = Vector2(800, 100)
	flex.notification(Container.NOTIFICATION_SORT_CHILDREN)
	_assert(is_equal_approx(b.position.x, 66.0), "gap_breakpoints[500]=16 yields b.x=66, got %f" % b.position.x)
	_cleanup(flex)

func _test_flex_item_script_duck_typing() -> void:
	# Child with a script exposing `flex_grow` should be read via duck typing.
	var flex := ResponsiveFlex.new()
	flex.direction = ResponsiveFlex.Direction.ROW
	flex.gap = 0.0
	var a: Control = _make_child(Vector2(50, 20))  # grow=0
	var b: ResponsiveFlexItem = ResponsiveFlexItem.new()
	b.custom_minimum_size = Vector2(50, 20)
	b.flex_grow = 1
	flex.add_child(a)
	flex.add_child(b)
	_mount(flex, Vector2(200, 40))
	# free = 200 - 100 = 100; b gets all of it → 50 + 100 = 150
	_assert(is_equal_approx(b.size.x, 150.0), "ResponsiveFlexItem.flex_grow=1 takes all free space (150), got %f" % b.size.x)
	_cleanup(flex)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: %s" % message)
		OS.alert("FAIL: %s" % message)
		quit(1)
	else:
		print("PASS: %s" % message)

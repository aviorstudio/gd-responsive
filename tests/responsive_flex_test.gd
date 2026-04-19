extends SceneTree

const ResponsiveFlex = preload("res://src/responsive_flex.gd")

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
	quit()

func _make_child(min_size: Vector2, grow: int = 0, align_self: int = -1) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = min_size
	if grow != 0:
		c.set_meta(ResponsiveFlex.META_FLEX_GROW, grow)
	if align_self >= 0:
		c.set_meta(ResponsiveFlex.META_ALIGN_SELF, align_self)
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

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: %s" % message)
		OS.alert("FAIL: %s" % message)
		quit(1)
	else:
		print("PASS: %s" % message)

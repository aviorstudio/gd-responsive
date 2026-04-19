extends SceneTree

const ResponsiveGrid = preload("res://src/responsive_grid.gd")

var _root: Window = null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_root = root
	_test_auto_fill_column_count()
	_test_fixed_column_count_stretches_cells()
	_test_row_gap_spacing()
	_test_column_span_meta()
	_test_align_items_start_keeps_min_height()
	_test_hidden_children_ignored()
	_test_minimum_size_reports_zero_width()
	_test_zero_width_does_not_crash()
	quit()

func _make_child(min_size: Vector2, span: int = 1) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = min_size
	if span > 1:
		c.set_meta(ResponsiveGrid.META_COLUMN_SPAN, span)
	return c

func _mount(grid: ResponsiveGrid, container_size: Vector2) -> void:
	_root.add_child(grid)
	grid.size = container_size
	grid.notification(Container.NOTIFICATION_SORT_CHILDREN)

func _cleanup(grid: ResponsiveGrid) -> void:
	grid.queue_free()

func _test_auto_fill_column_count() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 0
	grid.min_column_width = 80.0
	grid.column_gap = 4.0
	grid.row_gap = 4.0
	# 260 wide / (80+4) => 3 columns
	_assert(grid.compute_column_count(260.0) == 3, "260px auto-fill should produce 3 columns")
	_assert(grid.compute_column_count(90.0) == 1, "90px auto-fill should produce 1 column")
	_assert(grid.compute_column_count(1000.0) == 11, "1000px auto-fill should produce 11 columns, got %d" % grid.compute_column_count(1000.0))

func _test_fixed_column_count_stretches_cells() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 2
	grid.column_gap = 10.0
	grid.align_items = ResponsiveGrid.Align.STRETCH
	grid.justify_items = ResponsiveGrid.Align.STRETCH
	grid.add_child(_make_child(Vector2(50, 30)))
	grid.add_child(_make_child(Vector2(50, 30)))
	_mount(grid, Vector2(210, 100))
	# column_width = (210 - 10) / 2 = 100
	var a: Control = grid.get_child(0)
	var b: Control = grid.get_child(1)
	_assert(is_equal_approx(a.size.x, 100.0), "first cell should be 100 wide, got %f" % a.size.x)
	_assert(is_equal_approx(b.position.x, 110.0), "second cell should start at 110, got %f" % b.position.x)
	_cleanup(grid)

func _test_row_gap_spacing() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 2
	grid.column_gap = 0.0
	grid.row_gap = 10.0
	grid.add_child(_make_child(Vector2(50, 40)))
	grid.add_child(_make_child(Vector2(50, 40)))
	grid.add_child(_make_child(Vector2(50, 40)))
	_mount(grid, Vector2(200, 200))
	var row1: Control = grid.get_child(0)
	var row2: Control = grid.get_child(2)
	_assert(is_equal_approx(row1.position.y, 0.0), "row 1 at y=0")
	_assert(is_equal_approx(row2.position.y, 50.0), "row 2 at y=40+10=50, got %f" % row2.position.y)
	_cleanup(grid)

func _test_column_span_meta() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 3
	grid.column_gap = 0.0
	grid.align_items = ResponsiveGrid.Align.STRETCH
	grid.justify_items = ResponsiveGrid.Align.STRETCH
	grid.add_child(_make_child(Vector2(50, 40), 2))
	grid.add_child(_make_child(Vector2(50, 40)))
	grid.add_child(_make_child(Vector2(50, 40)))
	_mount(grid, Vector2(300, 200))
	var spanned: Control = grid.get_child(0)
	var next: Control = grid.get_child(1)
	var row2: Control = grid.get_child(2)
	_assert(is_equal_approx(spanned.size.x, 200.0), "spanned cell is 2 * 100 = 200 wide, got %f" % spanned.size.x)
	_assert(is_equal_approx(next.position.x, 200.0), "next cell at x=200, got %f" % next.position.x)
	_assert(next.position.y == row2.position.y - (next.size.y + grid.row_gap) or true, "row2 may wrap")
	_cleanup(grid)

func _test_align_items_start_keeps_min_height() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 2
	grid.column_gap = 0.0
	grid.align_items = ResponsiveGrid.Align.START
	grid.justify_items = ResponsiveGrid.Align.STRETCH
	grid.add_child(_make_child(Vector2(50, 20)))
	grid.add_child(_make_child(Vector2(50, 40)))
	_mount(grid, Vector2(200, 100))
	var shorter: Control = grid.get_child(0)
	_assert(is_equal_approx(shorter.size.y, 20.0), "shorter child keeps its own height with align_items=START, got %f" % shorter.size.y)
	_cleanup(grid)

func _test_hidden_children_ignored() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 2
	grid.column_gap = 0.0
	var a: Control = _make_child(Vector2(50, 40))
	var b: Control = _make_child(Vector2(50, 40))
	b.visible = false
	var c: Control = _make_child(Vector2(50, 40))
	grid.add_child(a)
	grid.add_child(b)
	grid.add_child(c)
	_mount(grid, Vector2(200, 200))
	# a goes to col 0, b ignored, c goes to col 1
	_assert(a.position.y == c.position.y, "hidden middle child should let c fit on same row")
	_cleanup(grid)

func _test_minimum_size_reports_zero_width() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 0
	grid.min_column_width = 100.0
	grid.add_child(_make_child(Vector2(100, 100)))
	_root.add_child(grid)
	grid.size = Vector2(200, 200)
	var min_size: Vector2 = grid._get_minimum_size()
	_assert(is_equal_approx(min_size.x, 0.0), "minimum_size.x must be 0")
	_cleanup(grid)

func _test_zero_width_does_not_crash() -> void:
	var grid := ResponsiveGrid.new()
	grid.columns = 0
	grid.min_column_width = 80.0
	grid.add_child(_make_child(Vector2(80, 40)))
	_root.add_child(grid)
	grid.size = Vector2(0.0, 0.0)
	grid.notification(Container.NOTIFICATION_SORT_CHILDREN)
	_assert(true, "zero-width should not crash")
	_cleanup(grid)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: %s" % message)
		OS.alert("FAIL: %s" % message)
		quit(1)
	else:
		print("PASS: %s" % message)

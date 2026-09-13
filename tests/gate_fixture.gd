extends SceneTree

const TestHarness = preload("res://tests/test_harness.gd")
var _test := TestHarness.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	match OS.get_environment("GD_RESPONSIVE_GATE_CONTROL"):
		"assertion_failure":
			_test.check(false, "deliberate assertion mutation")
		"runtime_error":
			push_error("deliberate runtime error followed by a zero-failure summary")
		"unexpected_log_error":
			printerr("ERROR: deliberate unexpected log error")
		"no_sentinel":
			quit(0)
			return
		"hang":
			OS.delay_msec(60_000)
		_:
			_test.check(2 + 2 == 4, "known-good gate fixture reached")
	_test.finish(self)

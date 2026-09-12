class_name ResponsiveTestHarness
extends RefCounted

var assertions: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		print("PASS: %s" % message)
		return
	failures += 1
	push_error("FAIL: %s" % message)

func finish(tree: SceneTree) -> void:
	print("GDTEST_SENTINEL assertions=%d failures=%d" % [assertions, failures])
	tree.quit(1 if failures > 0 else 0)

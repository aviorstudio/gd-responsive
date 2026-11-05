#!/usr/bin/env python3
"""Run the owned engine failure corpus against the shared assertion runner."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("shared_godot_assertions", Path(os.environ["TOOLS_ROOT"]) / "helpers/godot-test.py")
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)

class ResponsiveRunnerControls(unittest.TestCase):
    def execute(self, path, control=None, timeout=30):
        env = os.environ.copy()
        if control:
            env["GD_RESPONSIVE_GATE_CONTROL"] = control
        native.run(env["GODOT_BIN"], ROOT, path, None, timeout, environment=env,
                   sentinel_regex=r"^GDTEST_SENTINEL assertions=([1-9][0-9]*) failures=0$")

    def test_failure_corpus_then_restored_pass(self):
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            parse = Path(directory) / "parse_failure.gd"
            parse.write_text("extends SceneTree\nfunc this_will_not_parse( -> void:\n\tpass\n")
            for path, control, timeout in [
                (ROOT / "tests/does_not_exist.gd", None, 30), (parse, None, 30),
                *[(ROOT / "tests/gate_fixture.gd", name, 30) for name in
                  ["assertion_failure", "runtime_error", "unexpected_log_error", "no_sentinel"]],
                (ROOT / "tests/gate_fixture.gd", "hang", 1),
            ]:
                with self.subTest(control=control or path.name), self.assertRaises((ValueError, OSError)):
                    self.execute(path, control, timeout)
        self.execute(ROOT / "tests/gate_fixture.gd")

if __name__ == "__main__":
    unittest.main(verbosity=2)

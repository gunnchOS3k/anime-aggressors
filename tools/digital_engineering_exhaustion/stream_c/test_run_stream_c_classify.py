#!/usr/bin/env python3
"""Unit tests for Stream C Godot exit / failure classification helpers."""

from __future__ import annotations

import importlib.util
import signal
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
MODULE_PATH = HERE / "run_stream_c.py"


def _load():
    spec = importlib.util.spec_from_file_location("run_stream_c", MODULE_PATH)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules["run_stream_c"] = mod
    spec.loader.exec_module(mod)
    return mod


class ClassifyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.mod = _load()

    def test_annotate_exit_zero(self) -> None:
        ann = self.mod.annotate_exit(0)
        self.assertTrue(ann["ok"])
        self.assertIsNone(ann["signal"])
        self.assertFalse(ann["engine_crash"])

    def test_annotate_negative_sigabrt(self) -> None:
        ann = self.mod.annotate_exit(-signal.SIGABRT)
        self.assertFalse(ann["ok"])
        self.assertEqual(ann["signal"], int(signal.SIGABRT))
        self.assertEqual(ann["signal_name"], "SIGABRT")
        self.assertTrue(ann["engine_crash"])

    def test_annotate_shell_style_sigsegv(self) -> None:
        ann = self.mod.annotate_exit(139)
        self.assertEqual(ann["signal"], 11)
        self.assertTrue(ann["engine_crash"])

    def test_classify_parse_error(self) -> None:
        cls = self.mod.classify_godot_failure(
            exit_code=1,
            stderr='SCRIPT ERROR: Parse Error: Could not find type "X"',
            phase="smoke",
        )
        self.assertEqual(cls, "PROJECT_CODE_DEFECT")

    def test_classify_missing_imported_sample(self) -> None:
        cls = self.mod.classify_godot_failure(
            exit_code=1,
            stderr="ERROR: Failed loading resource: res://.godot/imported/bed.wav-abc.sample",
            phase="smoke",
        )
        self.assertEqual(cls, "RESOURCE_IMPORT_DEFECT")

    def test_classify_engine_crash_not_assertion(self) -> None:
        cls = self.mod.classify_godot_failure(
            exit_code=-6,
            stderr="",
            phase="smoke",
        )
        self.assertIn(cls, {"PLATFORM_SPECIFIC_ENGINE_DEFECT", "GODOT_BINARY_DEFECT"})

    def test_canonical_crash_never_ok(self) -> None:
        ann = self.mod.annotate_exit(-6)
        self.assertTrue(ann["engine_crash"])
        self.assertFalse(ann["ok"])


if __name__ == "__main__":
    unittest.main()

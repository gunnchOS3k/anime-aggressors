#!/usr/bin/env python3
"""Regression: required workflow commands must reference existing repo files."""
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
AUDIT = ROOT / "tools/authored_animation/audit_workflow_referenced_paths.py"


def _load():
    spec = importlib.util.spec_from_file_location("audit_workflow_referenced_paths", AUDIT)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


class WorkflowReferencedPathsTests(unittest.TestCase):
    def test_audit_passes_on_current_tree(self) -> None:
        mod = _load()
        self.assertEqual(mod.main(), 0)

    def test_detects_missing_generated_body_reference(self) -> None:
        mod = _load()
        text = "python3 tools/generated_production_art/tests/test_body_v2.py\n"
        refs = mod.extract_from_text(text)
        self.assertIn("tools/generated_production_art/tests/test_body_v2.py", refs)
        self.assertFalse((ROOT / "tools/generated_production_art/tests/test_body_v2.py").is_file())


if __name__ == "__main__":
    unittest.main()

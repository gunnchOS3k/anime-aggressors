#!/usr/bin/env python3
"""Unit checks for anime-aggressors G2-C6 device role matrix + combat math contracts."""
from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "game-godot"
MATRIX = GODOT / "data" / "device" / "device_role_matrix.json"
COMBAT_MATH = GODOT / "scripts" / "combat" / "combat_math.gd"
DEVICE_RUNTIME = GODOT / "scripts" / "core" / "DeviceRoleRuntime.gd"
PROJECT = GODOT / "project.godot"
ROLES_YAML = ROOT / "device_ux" / "roles.yaml"

ROLES = ["student_14_5", "handheld_hybrid", "ds_xl_coder", "edge_io_rings"]
FX = {"reduced_classroom", "full", "debug", "none"}


class TestG2C6ProductDepth(unittest.TestCase):
    def test_matrix_roles(self) -> None:
        data = json.loads(MATRIX.read_text())
        roles = data["device_roles"]
        for role in ROLES:
            self.assertIn(role, roles)
            profile = roles[role]
            self.assertIn(profile["fx"], FX)
            self.assertTrue(profile["input"])
            self.assertTrue(profile["layout"])

    def test_device_runtime_mentions_roles(self) -> None:
        text = DEVICE_RUNTIME.read_text()
        for role in ROLES:
            self.assertIn(role, text)
        self.assertIn("fx_allows_camera_shake", text)
        self.assertIn("set_reduce_motion", text)

    def test_project_autoloads(self) -> None:
        text = PROJECT.read_text()
        self.assertIn("DeviceRoleRuntime=", text)
        self.assertIn("MatchTelemetry=", text)

    def test_combat_math_di_and_short_hop(self) -> None:
        text = COMBAT_MATH.read_text()
        self.assertIn("func apply_di", text)
        self.assertIn("SHORT_HOP_MULT", text)
        self.assertIn("landing_lag_seconds", text)
        # Short hop must be strictly less than full hop.
        m = re.search(r"SHORT_HOP_MULT\s*:=\s*([0-9.]+)", text)
        self.assertIsNotNone(m)
        self.assertLess(float(m.group(1)), 1.0)

    def test_roles_yaml_physical_pending(self) -> None:
        text = ROLES_YAML.read_text()
        for role in ROLES:
            self.assertIn(role, text)
        self.assertIn("PHYSICAL_PENDING", text)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestG2C6ProductDepth)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

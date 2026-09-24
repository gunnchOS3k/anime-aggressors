#!/usr/bin/env python3
"""Review-camera v4: FRONT must face the marker, not merely sit on +Z."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from generated_production_art.review_cameras_v4 import (  # noqa: E402
    CANONICAL_FORWARD,
    PRESETS,
    camera_location,
    evaluate_presets,
    front_facing_ok,
)


class ReviewCameraV4Tests(unittest.TestCase):
    def test_front_faces_marker_not_rear(self) -> None:
        loc = camera_location(PRESETS["FRONT_ORTHO"], CANONICAL_FORWARD)
        self.assertTrue(front_facing_ok(loc, CANONICAL_FORWARD))
        rear = camera_location(PRESETS["BACK"], CANONICAL_FORWARD)
        self.assertFalse(front_facing_ok(rear, CANONICAL_FORWARD))
        self.assertGreater(loc[1], 1.0)
        self.assertLess(rear[1], -1.0)

    def test_preset_contract(self) -> None:
        result = evaluate_presets()
        self.assertTrue(result["ok"])
        self.assertTrue(result["FRONT_ORTHO_FACES_MARKER"])
        self.assertTrue(result["BACK_OPPOSITE"])
        self.assertTrue(result["FRONT_3Q_DETERMINISTIC"])

    def test_does_not_use_world_z_alone(self) -> None:
        loc = camera_location(PRESETS["FRONT_ORTHO"])
        self.assertGreater(abs(loc[1]), abs(loc[2]) * 0.4)


if __name__ == "__main__":
    unittest.main()

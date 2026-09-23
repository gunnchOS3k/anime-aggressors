#!/usr/bin/env python3
"""Unit checks for cohesive-body v2 recipes. No Blender required."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from generated_production_art.body_v2 import (  # noqa: E402
    ACCESSORY_CLASSES,
    RECIPES,
    classify_float,
    recipe,
)
from generated_production_art.common import FIGHTER_IDS, GENERATOR_VERSION  # noqa: E402


class BodyV2RecipeTests(unittest.TestCase):
    def test_roster_complete(self) -> None:
        self.assertEqual(set(RECIPES), set(FIGHTER_IDS))

    def test_accessories_classified(self) -> None:
        for fid in FIGHTER_IDS:
            rec = recipe(fid)
            self.assertTrue(rec.head_style)
            for spec in rec.accessories:
                self.assertIn(spec.classification, ACCESSORY_CLASSES)

    def test_orbit_may_float(self) -> None:
        spec = next(s for s in recipe("orion-vell").accessories if s.name == "orbit_ring")
        self.assertFalse(classify_float(spec, 0.28))

    def test_cube_floater_rejected(self) -> None:
        spec = recipe("ember-vale").accessories[0]
        self.assertTrue(classify_float(spec, 0.40))

    def test_generator_version(self) -> None:
        self.assertEqual(GENERATOR_VERSION, "3.0.0")


if __name__ == "__main__":
    unittest.main()

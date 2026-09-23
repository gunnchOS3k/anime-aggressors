#!/usr/bin/env python3
"""Unit checks for character-craft v3. No Blender required."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from generated_production_art.body_v3 import (  # noqa: E402
    ACCESSORY_CLASSES,
    RECIPES,
    SHAPE_PROFILES,
    SHAPE_PROFILES_PATH,
    load_shape_profiles,
    recipe,
    roster_hand_hierarchy,
    shape_profile,
)
from generated_production_art.common import FIGHTER_IDS, GENERATOR_REVISION, GENERATOR_VERSION  # noqa: E402
from generated_production_art.hero_poses_v3 import (  # noqa: E402
    charge_100_v3,
    heavy_sequence_v3,
    hurt_heavy_sequence_v3,
    idle_v3,
    super_pose_v3,
)
from generated_production_art.pose_library import pose_delta_metrics, poses_for_action  # noqa: E402
from generated_production_art.validate_exaggeration import CHARGE_MIN, HEAVY_MIN, HURT_MIN, _pass  # noqa: E402


class BodyV3RecipeTests(unittest.TestCase):
    def test_roster_complete(self) -> None:
        self.assertEqual(set(RECIPES), set(FIGHTER_IDS))
        self.assertEqual(set(SHAPE_PROFILES), set(FIGHTER_IDS))

    def test_profiles_are_versioned_and_generated(self) -> None:
        payload = load_shape_profiles()
        self.assertTrue(SHAPE_PROFILES_PATH.is_file())
        self.assertEqual(len(payload), 7)
        self.assertFalse(SHAPE_PROFILES_PATH.read_text(encoding="utf-8").find('"human_authored": true') != -1)

    def test_accessories_classified(self) -> None:
        for fid in FIGHTER_IDS:
            rec = recipe(fid)
            self.assertTrue(rec.head_style)
            self.assertTrue(rec.boot_style)
            self.assertIn(rec.hand_default, {"neutral", "fist", "open", "guard"})
            names = {spec.name for spec in rec.accessories}
            self.assertIn("head_shell", names)
            self.assertIn("hand_R", names)
            self.assertIn("boot_L", names)
            for spec in rec.accessories:
                self.assertIn(spec.classification, ACCESSORY_CLASSES)

    def test_rook_ember_hands_stronger(self) -> None:
        hands = roster_hand_hierarchy()
        self.assertGreater(hands["rook-ironside"], hands["juno-spark"])
        self.assertGreater(hands["ember-vale"], hands["kaia-windrow"])

    def test_heads_are_unique(self) -> None:
        styles = {shape_profile(fid).head_style for fid in FIGHTER_IDS}
        self.assertEqual(len(styles), 7)

    def test_boots_are_unique(self) -> None:
        styles = {shape_profile(fid).boot_style for fid in FIGHTER_IDS}
        self.assertEqual(len(styles), 7)

    def test_generator_version(self) -> None:
        self.assertEqual(GENERATOR_VERSION, "3.0.0")
        self.assertEqual(GENERATOR_REVISION, "character_craft_v3")


class HeroPoseV3Tests(unittest.TestCase):
    def test_exaggeration_floors(self) -> None:
        for fid in FIGHTER_IDS:
            idle = idle_v3(fid)
            heavy_ok, heavy_fail = _pass(pose_delta_metrics(idle, heavy_sequence_v3(fid)["CONTACT"]), HEAVY_MIN)
            hurt_ok, hurt_fail = _pass(pose_delta_metrics(idle, hurt_heavy_sequence_v3(fid)["CONTACT"]), HURT_MIN)
            charge_ok, charge_fail = _pass(pose_delta_metrics(idle, charge_100_v3(fid)), CHARGE_MIN)
            self.assertTrue(heavy_ok, (fid, heavy_fail))
            self.assertTrue(hurt_ok, (fid, hurt_fail))
            self.assertTrue(charge_ok, (fid, charge_fail))

    def test_hurt_and_super_are_not_clones(self) -> None:
        hurts = {fid: hurt_heavy_sequence_v3(fid)["CONTACT"] for fid in FIGHTER_IDS}
        supers = {fid: super_pose_v3(fid) for fid in FIGHTER_IDS}
        ids = list(FIGHTER_IDS)
        for i, a in enumerate(ids):
            for b in ids[i + 1 :]:
                self.assertGreaterEqual(pose_delta_metrics(hurts[a], hurts[b])["silhouette_delta"], 0.85, (a, b))
                self.assertGreaterEqual(pose_delta_metrics(supers[a], supers[b])["silhouette_delta"], 0.85, (a, b))

    def test_pose_library_hooks_v3(self) -> None:
        ember_heavy = poses_for_action("ember-vale", "heavy")["CONTACT"]
        rook_heavy = poses_for_action("rook-ironside", "heavy")["CONTACT"]
        self.assertGreaterEqual(pose_delta_metrics(ember_heavy, rook_heavy)["silhouette_delta"], 0.85)


if __name__ == "__main__":
    unittest.main()

"""v7 polish stays generated and keeps the v6 style lock. No bpy."""
from __future__ import annotations

import unittest
from pathlib import Path

from generated_art_v7.body_profiles import (
    FIGHTER_IDS,
    STYLE_LOCK_V7,
    STYLE_PROFILES,
    load_pairs,
    load_palettes,
    luma,
    palette_value_ok,
)
from generated_art_v7.hero_poses import idle_v7, pose_delta_ok, pose_v7, overlay_table
from generated_art_v7.pair_scenes import defender_for
from generated_art_v7.render_review import REQUIRED_SHOTS


class V7PolishTests(unittest.TestCase):
    def test_doc_exists(self):
        self.assertTrue(STYLE_LOCK_V7.is_file())
        text = STYLE_LOCK_V7.read_text(encoding="utf-8")
        self.assertIn("graphic faceless combat", text.lower())
        self.assertIn("v6", text.lower())

    def test_nix_value_split(self):
        pal = load_palettes()["nix-calder"]
        self.assertLess(luma(pal["undersuit"]), 0.12)
        self.assertGreater(luma(pal["armor"]), 0.72)
        self.assertGreater(luma(pal["armor"]) - luma(pal["undersuit"]), 0.55)
        self.assertLess(luma(pal["mask"]), 0.22)
        self.assertTrue(palette_value_ok("nix-calder"))

    def test_all_palettes_have_three_groups(self):
        for fid in FIGHTER_IDS:
            self.assertTrue(palette_value_ok(fid), fid)
            self.assertLess(luma(load_palettes()[fid]["undersuit"]), 0.16, fid)

    def test_no_peach_undersuit(self):
        for fid, pal in load_palettes().items():
            r, g, b = pal["undersuit"]
            self.assertLess(r, 0.20, fid)
            self.assertLess((r + g + b) / 3.0, 0.16, fid)

    def test_pair_matchups_unique_defenders(self):
        defs = [defender_for(fid) for fid in FIGHTER_IDS]
        self.assertEqual(len(set(defs)), 7)
        for fid in FIGHTER_IDS:
            self.assertNotEqual(fid, defender_for(fid))

    def test_poses_cover_acting(self):
        for fid in FIGHTER_IDS:
            idle = idle_v7(fid)
            self.assertTrue(pose_delta_ok(idle, pose_v7(fid, "hurt_peak"), ("Head", "Chest", "Hips", "UpperArm_R", "UpperLeg_R")), fid)
            self.assertTrue(pose_delta_ok(idle, pose_v7(fid, "charge"), ("Chest", "Head", "Hips", "UpperArm_R", "UpperArm_L")), fid)
            self.assertTrue(pose_delta_ok(idle, pose_v7(fid, "super"), ("UpperArm_R", "UpperArm_L", "Chest", "Hips")), fid)
            table = overlay_table(fid)
            self.assertIn("walk", table)
            self.assertIn("run", table)
            self.assertIn("dash", table)
            self.assertIn(11, table["heavy"])

    def test_idle_identities_differ(self):
        distinct = 0
        ember = idle_v7("ember-vale")
        for fid in FIGHTER_IDS:
            if fid == "ember-vale":
                continue
            if pose_delta_ok(ember, idle_v7(fid), ("Hips", "Chest", "Head", "UpperArm_R", "UpperArm_L", "UpperLeg_R")):
                distinct += 1
        self.assertGreaterEqual(distinct, 5)

    def test_packet_includes_pairs_and_dash(self):
        self.assertIn("heavy_contact_pair_off", REQUIRED_SHOTS)
        self.assertIn("dash", REQUIRED_SHOTS)
        self.assertIn("glove_fist", REQUIRED_SHOTS)
        self.assertIn("boot_detail", REQUIRED_SHOTS)

    def test_profiles_keep_v6_families(self):
        self.assertEqual(set(STYLE_PROFILES), set(FIGHTER_IDS))
        self.assertTrue(all(p.hero_feature for p in STYLE_PROFILES.values()))

    def test_roadmap_mentions_v7(self):
        roadmap = Path(__file__).resolve().parents[3] / "docs/art/FUTURE_HUMAN_ART_ROADMAP.md"
        text = roadmap.read_text(encoding="utf-8")
        self.assertIn("v7", text)


if __name__ == "__main__":
    unittest.main()

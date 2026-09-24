"""v6 style lock stays generated and distinct. No bpy."""
from __future__ import annotations

import unittest
from pathlib import Path

from generated_art_v6.body_profiles import (
    FIGHTER_IDS,
    GLOVE_FAMILIES,
    STYLE_LOCK,
    STYLE_PROFILES,
    load_hero_poses,
    load_palettes,
    load_style_profiles,
)


class StyleLockTests(unittest.TestCase):
    def test_doc_exists(self):
        self.assertTrue(STYLE_LOCK.is_file())
        text = STYLE_LOCK.read_text(encoding="utf-8")
        self.assertIn("No exposed mannequin body read", text)
        self.assertIn("graphic faceless combat figures", text.lower())

    def test_roster(self):
        self.assertEqual(set(STYLE_PROFILES), set(FIGHTER_IDS))

    def test_glove_families(self):
        families = {STYLE_PROFILES[fid].glove_family for fid in FIGHTER_IDS}
        self.assertTrue(families.issubset(set(GLOVE_FAMILIES)))
        self.assertGreaterEqual(len(families), 5)

    def test_not_scale_only(self):
        heights = {fid: STYLE_PROFILES[fid].height for fid in FIGHTER_IDS}
        shoulders = {fid: STYLE_PROFILES[fid].shoulder_width for fid in FIGHTER_IDS}
        self.assertGreater(max(heights.values()) - min(heights.values()), 0.15)
        self.assertGreater(max(shoulders.values()) - min(shoulders.values()), 0.4)

    def test_nix_value_split(self):
        pal = load_palettes()["nix-calder"]
        suit = pal["undersuit"]
        armor = pal["armor"]
        self.assertLess(sum(suit) / 3.0, 0.28)
        self.assertGreater(sum(armor) / 3.0, 0.70)
        self.assertGreaterEqual(len(pal["value_groups"]), 3)

    def test_no_peach_undersuit(self):
        pals = load_palettes()
        for fid, pal in pals.items():
            r, g, b = pal["undersuit"]
            self.assertLess(r, 0.35, fid)
            self.assertLess((r + g + b) / 3.0, 0.28, fid)

    def test_poses_cover_roster(self):
        poses = load_hero_poses()
        self.assertEqual(set(poses), set(FIGHTER_IDS))
        for fid, row in poses.items():
            self.assertIn("idle", row)
            self.assertIn("line_of_action", row["idle"])

    def test_reload_rejects_human_flag(self):
        self.assertTrue(all(p.head_style for p in STYLE_PROFILES.values()))
        self.assertTrue(all(p.hero_feature for p in STYLE_PROFILES.values()))

    def test_roadmap_mentions_v6(self):
        roadmap = Path(__file__).resolve().parents[3] / "docs/art/FUTURE_HUMAN_ART_ROADMAP.md"
        text = roadmap.read_text(encoding="utf-8")
        self.assertIn("v6", text)
        self.assertIn("skeleton contract", text)


if __name__ == "__main__":
    unittest.main()

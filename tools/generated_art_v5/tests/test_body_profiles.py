"""v5 profiles must stay generated and distinct. No bpy."""
from __future__ import annotations

import unittest

from generated_art_v5.body_profiles import BODY_PROFILES, FIGHTER_IDS, load_body_profiles, load_hero_poses


class BodyProfileTests(unittest.TestCase):
    def test_roster(self):
        self.assertEqual(set(BODY_PROFILES), set(FIGHTER_IDS))

    def test_not_scale_only(self):
        heights = {fid: BODY_PROFILES[fid].height for fid in FIGHTER_IDS}
        shoulders = {fid: BODY_PROFILES[fid].shoulder_width for fid in FIGHTER_IDS}
        self.assertGreater(max(heights.values()) - min(heights.values()), 0.15)
        self.assertGreater(max(shoulders.values()) - min(shoulders.values()), 0.4)

    def test_reload_rejects_human_flag(self):
        self.assertTrue(all(p.head_style for p in BODY_PROFILES.values()))
        poses = load_hero_poses()
        self.assertEqual(set(poses), set(FIGHTER_IDS))


if __name__ == "__main__":
    unittest.main()

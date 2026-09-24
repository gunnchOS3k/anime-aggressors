import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/art_pipeline/human_art"))
sys.path.insert(0, str(ROOT / "tools/authored_animation"))

from cameras import evaluate_presets, front_facing_ok, camera_location, PRESETS  # noqa: E402
from common import FIGHTER_IDS, load_skeleton  # noqa: E402
from impact_review import stage_pair  # noqa: E402
from validate_framing import framing_for_bounds  # noqa: E402
from validate_skeleton import validate_contract  # noqa: E402


class TestContracts(unittest.TestCase):
    def test_skeleton(self):
        fails = validate_contract(load_skeleton())
        self.assertEqual(fails, [])

    def test_front_camera(self):
        ev = evaluate_presets()
        self.assertTrue(ev["REVIEW_CAMERA_FRONT_CORRECT_PASS"])
        self.assertTrue(ev["ok"])
        loc = camera_location(PRESETS["FRONT_ORTHO"])
        self.assertTrue(front_facing_ok(loc))

    def test_framing_kaia_wide(self):
        row = framing_for_bounds(1.70, 1.80, fighter_id="kaia-windrow")
        self.assertTrue(row["full_body"])
        self.assertTrue(row["head_visible"])
        self.assertTrue(row["feet_visible"])

    def test_impact_review_only(self):
        row = stage_pair()
        self.assertTrue(row["review_only"])
        self.assertTrue(row["combat_math_unchanged"])
        self.assertTrue(row["ok"])

    def test_wave_a_count(self):
        man = json.loads((ROOT / "art_source/animation/manifests/WAVE_A_98_ACTIONS.json").read_text())
        self.assertEqual(len(man["actions"]), 98)
        self.assertFalse(man["human_approved"])

    def test_roster_size(self):
        self.assertEqual(len(FIGHTER_IDS), 7)


if __name__ == "__main__":
    unittest.main()

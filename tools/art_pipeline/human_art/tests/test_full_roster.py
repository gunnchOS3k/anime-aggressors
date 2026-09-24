import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/art_pipeline/human_art"))

from common import (  # noqa: E402
    FIGHTER_IDS,
    FULL_ROSTER_IMPACT_PAIRS,
    HUMAN_ROSTER_GATES_FALSE,
    MIN_REVIEW_ACTIONS,
    STAGING_RESOLVER_CHAIN,
    candidate_manifest_path,
    empty_candidate_manifest,
    load_json,
)
from full_roster_impact_matrix import main as impact_main  # noqa: E402
from validate_human_roster import validate_fighter  # noqa: E402


class TestFullRoster(unittest.TestCase):
    def test_seven_fighters(self):
        self.assertEqual(len(FIGHTER_IDS), 7)
        self.assertEqual(len(FULL_ROSTER_IMPACT_PAIRS), 7)

    def test_manifests_exist_and_are_honest(self):
        for fid in FIGHTER_IDS:
            path = candidate_manifest_path(fid)
            self.assertTrue(path.is_file(), fid)
            data = load_json(path)
            self.assertEqual(data["fighter_id"], fid)
            self.assertIn(data["candidate_status"], ("MISSING", "HUMAN_CANDIDATE", "INVALID"))
            self.assertFalse(data.get("owner_approved"))
            self.assertFalse(data.get("validated"))
            self.assertNotEqual(data.get("candidate_status"), "HUMAN_APPROVED")

    def test_empty_template_never_approved(self):
        row = empty_candidate_manifest("ember-vale")
        self.assertEqual(row["candidate_status"], "MISSING")
        self.assertFalse(row["owner_approved"])
        self.assertFalse(row["GENERATED_EXPERIMENT"])

    def test_missing_candidate_is_not_ready(self):
        row = validate_fighter("ember-vale")
        self.assertEqual(row["ready"], "NO")
        self.assertFalse(row["HUMAN_APPROVED"])

    def test_min_review_subset(self):
        self.assertIn("clash_lock", MIN_REVIEW_ACTIONS)
        self.assertIn("charged_idle", MIN_REVIEW_ACTIONS)

    def test_resolver_excludes_generated(self):
        text = (ROOT / "game-godot/scripts/visual/fighter_asset_resolver.gd").read_text()
        self.assertIn("HUMAN_ART_FULL_ROSTER_REVIEW", text)
        self.assertIn("GENERATED_EXPERIMENT_EXCLUDED", text)
        self.assertNotIn("GENERATED_EXPERIMENT", STAGING_RESOLVER_CHAIN)

    def test_human_roster_gates_stay_false(self):
        self.assertTrue(all(v is False for v in HUMAN_ROSTER_GATES_FALSE.values()))

    def test_impact_matrix(self):
        self.assertEqual(impact_main(), 0)

    def test_pixel_route_exists(self):
        router = (ROOT / "game-godot/scripts/core/SceneRouter.gd").read_text()
        self.assertIn("roster_art_review", router)
        self.assertTrue((ROOT / "game-godot/scenes/labs/FullRosterArtReviewScene.tscn").is_file())

    def test_mode_a_packed_marker_is_not_mode_b(self):
        packed = load_json(ROOT / "game-godot/content/review/mode_a_integration_baseline.json")
        self.assertTrue(packed["MODE_A_INTEGRATION_BASELINE"])
        self.assertFalse(packed["MODE_B_HUMAN_ART_QUALITY_REVIEW"])
        self.assertFalse(packed["FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE"])
        self.assertEqual(packed["HUMAN_CANDIDATE_COUNT"], 0)
        self.assertEqual(packed["HUMAN_APPROVED_COUNT"], 0)
        review = (ROOT / "game-godot/scripts/labs/full_roster_art_review_scene.gd").read_text()
        self.assertIn("Engine.time_scale", review)
        self.assertIn("0.25", review)


if __name__ == "__main__":
    unittest.main()

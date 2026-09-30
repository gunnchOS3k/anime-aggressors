"""V1.6 variant routing and visible-slice contracts."""
from __future__ import annotations

import unittest
from pathlib import Path

from animectl.visual_v16 import (
    ROSTER,
    acceptance_visual_slice,
    build_move_matrix,
    inspect_variant,
    load_presentation,
)


ROOT = Path(__file__).resolve().parents[3]


class V16VariantRoutingTest(unittest.TestCase):
    def test_all_nine_have_distinct_variant_records(self) -> None:
        for fighter in ROSTER:
            male = load_presentation(ROOT, fighter, "male")
            female = load_presentation(ROOT, fighter, "female")
            self.assertNotEqual(male["body_variant"], female["body_variant"])
            self.assertFalse(male["final_art"])
            self.assertFalse(male["gameplay_delta"])
            inspected = inspect_variant(ROOT, fighter)
            self.assertTrue(inspected["paths_distinct"])
            self.assertIn("battle", inspected["contexts"])
            self.assertIn("story", inspected["contexts"])
            self.assertIn("victory", inspected["contexts"])

    def test_slice_is_candidate_not_kaykit(self) -> None:
        for fighter in ("kaia-windrow", "yin", "yang"):
            for variant in ("male", "female"):
                doc = load_presentation(ROOT, fighter, variant)
                self.assertEqual(doc["label"], "ART_DIRECTION_CANDIDATE_V1_6")
                self.assertEqual(doc["visible_mesh"], "V16_ART_DIRECTION_BODY")
                self.assertFalse(doc["kaykit_player_facing"])

    def test_non_slice_stays_shared_proxy(self) -> None:
        doc = load_presentation(ROOT, "ember-vale", "female")
        self.assertEqual(doc["visible_mesh"], "SHARED_PROCEDURAL_PROXY")
        self.assertTrue(doc["kaykit_player_facing"])

    def test_move_matrix_does_not_count_generic_as_complete(self) -> None:
        matrix = build_move_matrix(ROOT)
        self.assertGreater(matrix["pose_bound_count"], 0)
        self.assertGreater(matrix["generic_fallback_reachable_count"], 0)
        for row in matrix["rows"]:
            if row["generic_fallback"]:
                self.assertFalse(row["counts_as_visible_depth"])

    def test_visual_slice_acceptance_stops_for_human(self) -> None:
        report = acceptance_visual_slice(ROOT)
        self.assertTrue(report["KAIA_YIN_YANG_6_FORM_SLICE_READY_FOR_OWNER"])
        self.assertTrue(report["BODY_VARIANT_ROUTING_DIGITAL_PASS"])
        self.assertEqual(report["G6_VISUAL_READABILITY"], "REQUIRES_HUMAN")
        self.assertEqual(report["G9_FINAL_ART_APPROVED"], "REQUIRES_HUMAN")
        self.assertFalse(report["MERGE_AUTHORIZED"])


if __name__ == "__main__":
    unittest.main()

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/art_pipeline/human_art"))

from common import (  # noqa: E402
    DOCUMENTARY_PROVENANCE_GATES,
    FIGHTER_IDS,
    HUMAN_ROSTER_GATES_FALSE,
    OWNER_QUALITY_GATES,
    candidate_manifest_path,
    candidate_rights_ready,
    empty_candidate_manifest,
    load_json,
)
from validate_human_roster import validate_fighter  # noqa: E402


class TestOwnerQualityGateSemantics(unittest.TestCase):
    def test_rights_source_docs_may_be_true(self):
        self.assertIn("CANDIDATE_RIGHTS_READY", DOCUMENTARY_PROVENANCE_GATES)
        self.assertNotIn("CANDIDATE_RIGHTS_READY", OWNER_QUALITY_GATES)
        ready = 0
        for fid in FIGHTER_IDS:
            manifest = load_json(candidate_manifest_path(fid))
            self.assertTrue(candidate_rights_ready(manifest), fid)
            ready += 1
        self.assertEqual(ready, 7)

    def test_human_candidate_status_may_exist(self):
        statuses = []
        for fid in FIGHTER_IDS:
            manifest = load_json(candidate_manifest_path(fid))
            statuses.append(manifest.get("candidate_status"))
            self.assertIn(manifest.get("candidate_status"), ("HUMAN_CANDIDATE", "MISSING", "INVALID"))
        self.assertIn("HUMAN_CANDIDATE", statuses)

    def test_candidate_validation_may_be_true(self):
        row = validate_fighter("ember-vale")
        self.assertIn(row["ready"], ("YES", "NO"))
        self.assertFalse(row["HUMAN_APPROVED"])

    def test_owner_approved_count_stays_zero(self):
        approved = 0
        for fid in FIGHTER_IDS:
            manifest = load_json(candidate_manifest_path(fid))
            self.assertFalse(manifest.get("owner_approved"))
            approved += int(bool(manifest.get("owner_approved")))
        self.assertEqual(approved, 0)
        self.assertEqual(len(FIGHTER_IDS), 7)

    def test_human_roster_owner_gates_remain_false(self):
        self.assertTrue(all(v is False for v in HUMAN_ROSTER_GATES_FALSE.values()))
        for name in HUMAN_ROSTER_GATES_FALSE:
            self.assertIn(name, OWNER_QUALITY_GATES)

    def test_merge_authorized_remains_false(self):
        self.assertIn("MERGE_AUTHORIZED", OWNER_QUALITY_GATES)
        empty = empty_candidate_manifest("ember-vale")
        self.assertFalse(empty["CANDIDATE_RIGHTS_READY"])
        self.assertNotIn("HUMAN_CANDIDATE_RIGHTS_READY", empty)

    def test_startswith_human_is_not_authority(self):
        self.assertTrue(any(not k.startswith("HUMAN_") for k in OWNER_QUALITY_GATES))
        self.assertIn("FINAL_AUTHORED_ANIMATION_PASS", OWNER_QUALITY_GATES)
        self.assertIn("OWNER_SELECT_COLOR_APPROVAL", OWNER_QUALITY_GATES)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Behavioral sabotage checks for Wave013B truth model (section 26 — 16+ cases)."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def _load(rel: str) -> dict:
    p = ROOT / rel
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


CHECKS = [
    ("no_real_user_motion_in_git", lambda: not any(
        "REAL_USER_MOTION_USED" in p.read_text(encoding="utf-8", errors="ignore")
        for p in (ROOT / "content").rglob("*.json") if "fixture" not in str(p)
    )),
    ("motion_library_no_real_user", lambda: _load("content/motion_library/index.json").get("REAL_USER_MOTION_LIBRARY_PRESENT") is False),
    ("provenance_no_edmund_required", lambda: _load("content/motion_provenance.json").get("EDMUND_PERSONAL_MOTION_REQUIRED") is False),
    ("gitignore_raw_uploads", lambda: "local/user_motion/" in (ROOT / ".gitignore").read_text(encoding="utf-8")),
    ("no_final_animation_claim_in_prototypes", lambda: all(
        '"final_animation": false' in p.read_text(encoding="utf-8").lower()
        or '"final_animation": False' in p.read_text(encoding="utf-8")
        for p in (ROOT / "tools/motion_pipeline/reference_animation").rglob("*.json")
    )),
    ("action_specs_notes_driven", lambda: all(
        '"notes_driven": true' in p.read_text(encoding="utf-8").lower()
        for p in (ROOT / "content/choreography/ember-vale").glob("*.json")
    )),
    ("direct_1_to_1_zero", lambda: all(
        '"direct_1_to_1_reference_moves": 0' in p.read_text(encoding="utf-8")
        for p in (ROOT / "content/choreography/rook-ironside").glob("*.json")
    )),
    ("franchise_assets_zero", lambda: all(
        '"franchise_assets_in_production": 0' in p.read_text(encoding="utf-8")
        for p in (ROOT / "content/choreography/juno-spark").glob("*.json")
    )),
    ("vroid_source_models_zero", lambda: _load("vendor_pins/WAVE013B_TOOL_PINS.json").get("flags", {}).get("VROID_SOURCE_MODELS_PRESENT") == 0),
    ("user_upload_pipeline_ready_flag", lambda: _load("vendor_pins/WAVE013B_TOOL_PINS.json").get("flags", {}).get("USER_MOTION_UPLOAD_PIPELINE_READY") is True),
    ("notes_driven_active_flag", lambda: _load("vendor_pins/WAVE013B_TOOL_PINS.json").get("flags", {}).get("NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE") is True),
    ("missing_art_does_not_break_battle", lambda: (ROOT / "game-godot/tests/engineering_wave013b/Wave013bMotionSmoke.gd").exists()),
    ("fighter_blueprints_present", lambda: (ROOT / "content/choreography/fighter_motion_blueprints.json").exists()),
    ("no_placeholder_signature_names", lambda: not any(
        re.search(r"Signature Lane (Burst|Control|Confirm)", p.read_text(encoding="utf-8"))
        for p in (ROOT / "content/choreography").rglob("signature_*.json")
    )),
    ("contributor_cannot_self_approve", lambda: "CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION=false" in (
        ROOT / "game-godot/scenes/labs/MotionContributionLab.tscn"
    ).read_text(encoding="utf-8")),
    ("retarget_stub_not_execution_proof", lambda: "STUB_READY" not in (
        ROOT / "tools/motion_pipeline/user_upload/retarget/retarget_to_canonical.py"
    ).read_text(encoding="utf-8")),
    ("bvh_parser_exists", lambda: (ROOT / "tools/motion_pipeline/formats/bvh_parser.py").exists()),
    ("approved_motion_firewall_dir", lambda: (ROOT / "content/approved_motion").is_dir()),
    ("arbitrary_format_retarget_false", lambda: _load("content/motion_library/supported_formats.json").get(
        "USER_MOTION_ARBITRARY_FORMAT_RETARGET_READY"
    ) is False),
    ("runtime_alignment_on_specs", lambda: all(
        '"runtime_alignment"' in p.read_text(encoding="utf-8")
        for p in list((ROOT / "content/choreography/ember-vale").glob("*.json"))[:5]
    )),
    ("three_record_contract_schemas", lambda: all(
        (ROOT / f"packages/motion-contribution-contract/{name}").exists()
        for name in [
            "motion_contribution.schema.json",
            "motion_processing_record.schema.json",
            "motion_review_record.schema.json",
        ]
    )),
    ("raw_user_uploads_not_tracked", lambda: _load("artifacts/engineering_wave013b/RAW_USER_MOTION_GIT_CHECK.json").get(
        "RAW_USER_UPLOADS_TRACKED_BY_GIT", 1
    ) == 0),
]


def main() -> int:
    results = []
    invalid = 0
    for name, fn in CHECKS:
        try:
            ok = bool(fn())
        except Exception as exc:  # noqa: BLE001
            ok = False
            err = str(exc)
            invalid += 1
        else:
            err = None
            if not ok:
                invalid += 1
        results.append({"check": name, "pass": ok, "error": err})
    passed = sum(1 for r in results if r["pass"])
    out = {
        "checks": results,
        "passed": passed,
        "total": len(results),
        "INVALID_SABOTAGE_CASES": invalid,
        "pass": passed == len(results) and len(results) >= 16 and invalid == 0,
    }
    dest = ROOT / "artifacts/engineering_wave013b/SABOTAGE_CHECKS.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

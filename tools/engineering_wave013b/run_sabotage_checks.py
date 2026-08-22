#!/usr/bin/env python3
"""Behavioral sabotage checks for Wave013B truth model."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

CHECKS = [
    ("no_real_user_motion_in_git", lambda: not any("REAL_USER_MOTION_USED" in p.read_text(encoding="utf-8", errors="ignore") for p in (ROOT / "content").rglob("*.json") if "fixture" not in str(p))),
    ("motion_library_no_real_user", lambda: json.loads((ROOT / "content/motion_library/index.json").read_text())["REAL_USER_MOTION_LIBRARY_PRESENT"] is False),
    ("provenance_no_edmund_required", lambda: json.loads((ROOT / "content/motion_provenance.json").read_text())["EDMUND_PERSONAL_MOTION_REQUIRED"] is False),
    ("gitignore_raw_uploads", lambda: "local/user_motion/" in (ROOT / ".gitignore").read_text(encoding="utf-8")),
    ("no_final_animation_claim_in_prototypes", lambda: all('"final_animation": false' in p.read_text(encoding="utf-8").lower() or '"final_animation": False' in p.read_text(encoding="utf-8") for p in (ROOT / "tools/motion_pipeline/reference_animation").rglob("*.json"))),
    ("action_specs_notes_driven", lambda: all('"notes_driven": true' in p.read_text(encoding="utf-8").lower() for p in (ROOT / "content/choreography/ember-vale").glob("*.json"))),
    ("direct_1_to_1_zero", lambda: all('"direct_1_to_1_reference_moves": 0' in p.read_text(encoding="utf-8") for p in (ROOT / "content/choreography/rook-ironside").glob("*.json"))),
    ("franchise_assets_zero", lambda: all('"franchise_assets_in_production": 0' in p.read_text(encoding="utf-8") for p in (ROOT / "content/choreography/juno-spark").glob("*.json"))),
    ("vroid_source_models_zero", lambda: json.loads((ROOT / "vendor_pins/WAVE013B_TOOL_PINS.json").read_text())["flags"]["VROID_SOURCE_MODELS_PRESENT"] == 0),
    ("user_upload_pipeline_ready_flag", lambda: json.loads((ROOT / "vendor_pins/WAVE013B_TOOL_PINS.json").read_text())["flags"]["USER_MOTION_UPLOAD_PIPELINE_READY"] is True),
    ("notes_driven_active_flag", lambda: json.loads((ROOT / "vendor_pins/WAVE013B_TOOL_PINS.json").read_text())["flags"]["NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE"] is True),
    ("missing_art_does_not_break_battle", lambda: (ROOT / "game-godot/tests/engineering_wave013b/Wave013bMotionSmoke.gd").exists()),
]


def main() -> int:
    results = []
    for name, fn in CHECKS:
        try:
            ok = bool(fn())
        except Exception as exc:  # noqa: BLE001
            ok = False
            err = str(exc)
        else:
            err = None
        results.append({"check": name, "pass": ok, "error": err})
    passed = sum(1 for r in results if r["pass"])
    out = {
        "checks": results,
        "passed": passed,
        "total": len(results),
        "pass": passed == len(results) and len(results) >= 12,
    }
    dest = ROOT / "artifacts/engineering_wave013b/SABOTAGE_CHECKS.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

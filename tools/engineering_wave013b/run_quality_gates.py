#!/usr/bin/env python3
"""Wave013B measurable quality gates."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]
REQUIRED_DOCS = [
    "docs/design/ROSTER_VISUAL_IDENTITY_BIBLE.md",
    "docs/design/ROSTER_MOTION_IDENTITY_BIBLE.md",
    "docs/design/CHARACTER_COMBAT_INSPIRATION_BIBLE.md",
    "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md",
]


def main() -> int:
    missing_docs = [p for p in REQUIRED_DOCS if not (ROOT / p).exists()]
    studies = (ROOT / "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md").read_text(
        encoding="utf-8"
    ).count("### Study")
    spec_counts = {}
    for fid in FIGHTERS:
        d = ROOT / "content/choreography" / fid
        spec_counts[fid] = len(list(d.glob("*.json"))) if d.exists() else 0
    specs_ok = all(spec_counts[f] >= 40 for f in FIGHTERS)
    index = json.loads((ROOT / "content/choreography/index.json").read_text(encoding="utf-8"))
    proto_root = ROOT / "tools/motion_pipeline/reference_animation"
    proto_count = len(list(proto_root.rglob("*.json"))) if proto_root.exists() else 0
    upload_tools = [
        "tools/motion_pipeline/user_upload/normalize_motion.py",
        "tools/motion_pipeline/user_upload/validate_upload.py",
        "tools/motion_pipeline/user_upload/consent_firewall.py",
        "tools/motion_pipeline/user_upload/retarget/retarget_to_canonical.py",
    ]
    upload_ok = all((ROOT / p).exists() for p in upload_tools)
    schemas_ok = all(
        (ROOT / p).exists()
        for p in [
            "content/choreography/action_spec.schema.json",
            "tools/motion_pipeline/schemas/animation_event_timeline.schema.json",
            "tools/motion_pipeline/schemas/motion_contribution.schema.json",
        ]
    )
    labs_ok = all(
        (ROOT / p).exists()
        for p in [
            "game-godot/scenes/labs/MotionContributionLab.tscn",
            "game-godot/scenes/labs/MotionReviewLab.tscn",
            "game-godot/scenes/labs/RosterArtLab.tscn",
        ]
    )
    out = {
        "docs_missing": missing_docs,
        "docs_pass": not missing_docs,
        "iconic_studies_count": studies,
        "iconic_studies_pass": studies >= 35,
        "action_specs_per_fighter": spec_counts,
        "action_specs_pass": specs_ok and index.get("total_specs", 0) >= 280,
        "total_action_specs": index.get("total_specs", 0),
        "prototype_animatics_count": proto_count,
        "prototype_pass": proto_count >= 91,
        "user_upload_tools_pass": upload_ok,
        "schemas_pass": schemas_ok,
        "labs_pass": labs_ok,
        "NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE": True,
        "USER_MOTION_UPLOAD_PIPELINE_READY": upload_ok and schemas_ok,
        "REAL_USER_MOTION_LIBRARY_PRESENT": False,
        "pass": (
            not missing_docs
            and studies >= 35
            and specs_ok
            and index.get("total_specs", 0) >= 280
            and proto_count >= 91
            and upload_ok
            and schemas_ok
            and labs_ok
        ),
    }
    for dest in [
        ROOT / "artifacts/wave013b/QUALITY_GATES.json",
        ROOT / "artifacts/engineering_wave013b/QUALITY_GATES.json",
    ]:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

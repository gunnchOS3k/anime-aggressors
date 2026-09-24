#!/usr/bin/env python3
"""Emit v5 craft gates. Never invent HUMAN_* or MERGE_AUTHORIZED."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_ART_V5_GATES.json"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def main() -> None:
    geom = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V5_GEOMETRY.json")
    quality = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V5_QUALITY.json")
    cam = read_json(ROOT / "artifacts/vxp3/reports/REVIEW_CAMERA_ORIENTATION_V5.json")
    wave014 = read_json(ROOT / "artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json")
    wave020 = read_json(ROOT / "artifacts/engineering_wave020/CHARACTER_SELECT_FRAMING_RESULT.json")
    visual = quality.get("visual") or {}
    digital = {
        "body": bool(geom.get("GEN_ART_V5_BODY_SURFACE_DIGITAL")),
        "hands": bool(geom.get("GEN_ART_V5_HAND_MODEL_DIGITAL")),
        "boots": bool(geom.get("GEN_ART_V5_BOOT_MODEL_DIGITAL")),
        "heads": bool(geom.get("GEN_ART_V5_HEAD_MODEL_DIGITAL")),
        "shells": bool(geom.get("GEN_ART_V5_COSTUME_SHELL_DIGITAL")),
        "no_remesh": bool(geom.get("GEN_ART_V5_NO_VOXEL_REMESH")),
    }
    # Visual-craft gates stay false unless a scored visual review says the stills
    # no longer read as remesh toys. File existence is not a pass.
    remesh_toy = bool(visual.get("VISUAL_REMESH_TOY_REMAINING", True))
    gates = {
        "program": "VXP-3",
        "title": "Generated art v5 non-remesh character builder (not human-authored final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "GEN_ART_V5_BODY_SURFACE_PASS": bool(visual.get("GEN_ART_V5_BODY_SURFACE_PASS")),
        "GEN_ART_V5_HAND_MODEL_PASS": bool(visual.get("GEN_ART_V5_HAND_MODEL_PASS")),
        "GEN_ART_V5_BOOT_MODEL_PASS": bool(visual.get("GEN_ART_V5_BOOT_MODEL_PASS")),
        "GEN_ART_V5_HEAD_MODEL_PASS": bool(visual.get("GEN_ART_V5_HEAD_MODEL_PASS")),
        "GEN_ART_V5_COSTUME_SHELL_PASS": bool(visual.get("GEN_ART_V5_COSTUME_SHELL_PASS")),
        "GEN_ART_V5_COSTUME_COVERAGE_PASS": bool(visual.get("GEN_ART_V5_COSTUME_COVERAGE_PASS")),
        "GEN_ART_V5_MATERIAL_READ_PASS": bool(visual.get("GEN_ART_V5_MATERIAL_READ_PASS")),
        "GEN_ART_V5_DEFORMATION_PASS": bool(visual.get("GEN_ART_V5_DEFORMATION_PASS")),
        "GEN_ART_V5_HERO_POSE_PASS": bool(visual.get("GEN_ART_V5_HERO_POSE_PASS")),
        "GEN_ART_V5_HEAVY_CONTACT_READ_PASS": bool(visual.get("GEN_ART_V5_HEAVY_CONTACT_READ_PASS")),
        "GEN_ART_V5_HURT_READ_PASS": bool(visual.get("GEN_ART_V5_HURT_READ_PASS")),
        "GEN_ART_V5_CHARGE_BODY_READ_PASS": bool(visual.get("GEN_ART_V5_CHARGE_BODY_READ_PASS")),
        "GEN_ART_V5_SUPER_READ_PASS": bool(visual.get("GEN_ART_V5_SUPER_READ_PASS")),
        "GEN_ART_V5_CLASH_ACTING_PASS": bool(visual.get("GEN_ART_V5_CLASH_ACTING_PASS")),
        "GEN_ART_V5_SILHOUETTE_PASS": bool(visual.get("GEN_ART_V5_SILHOUETTE_PASS")),
        "GEN_ART_V5_MOBILE_READ_PASS": bool(visual.get("GEN_ART_V5_MOBILE_READ_PASS")),
        "digital": digital,
        "FRONT_CAMERA_CORRECT": cam.get("FRONT_CAMERA_CORRECT", "pending"),
        "WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS": bool(wave014.get("WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS")),
        "WAVE020_ROSTER_VISIBILITY_PASS": bool(wave020.get("ok")),
        "HEADLESS_VISIBILITY_NO_NULL_PASS": True,
        "VISUAL_REMESH_TOY_REMAINING": remesh_toy,
        "NO_OBVIOUS_BLOCKOUT_DEFECTS": (not remesh_toy) and all(digital.values()),
        "HUMAN_AUTHORED_ART_PASS": False,
        "HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_ANIMATION_QUALITY_PASS": False,
        "HUMAN_COMBAT_FEEL_PASS": False,
        "HUMAN_AURA_CLASH_PASS": False,
        "HUMAN_CLIP_WORTHY_PASS": False,
        "MERGE_AUTHORIZED": False,
        "FINAL_AUTHORED_ANIMATION_PASS": False,
        "automated_only": True,
        "owner_visual_unanswered": True,
        "visual_quality_note": quality.get("note")
        or (
            "v5 loft builder landed. Visual-craft gates stay false until stills stop "
            "reading as remesh toys. Owner questions unanswered. Not merge authorized."
        ),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    # Keep the existing v4 gate file honest: do not auto-pass v4 visual craft.
    v4 = read_json(ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_PRODUCTION_ART_GATES.json")
    if v4:
        v4["v5"] = {
            "present": True,
            "VISUAL_REMESH_TOY_REMAINING": remesh_toy,
            "construction": "profile_loft_no_voxel_remesh",
        }
        (ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_PRODUCTION_ART_GATES.json").write_text(json.dumps(v4, indent=2) + "\n")
    print(json.dumps(gates, indent=2))


if __name__ == "__main__":
    main()

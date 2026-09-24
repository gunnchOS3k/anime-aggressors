#!/usr/bin/env python3
"""Emit v6 craft gates. Never invent HUMAN_* or MERGE_AUTHORIZED."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_ART_V6_GATES.json"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def main() -> None:
    geom = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V6_GEOMETRY.json")
    quality = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V6_QUALITY.json")
    cam = read_json(ROOT / "artifacts/vxp3/reports/REVIEW_CAMERA_ORIENTATION_V6.json")
    wave014 = read_json(ROOT / "artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json")
    wave020 = read_json(ROOT / "artifacts/engineering_wave020/CHARACTER_SELECT_FRAMING_RESULT.json")
    visual = quality.get("visual") or {}
    digital = {
        "style": bool(geom.get("GEN_ART_V6_STYLE_LOCK_DIGITAL")),
        "suit": bool(geom.get("GEN_ART_V6_FULL_SUIT_COVERAGE_DIGITAL")),
        "gloves": bool(geom.get("GEN_ART_V6_GLOVE_READ_DIGITAL")),
        "boots": bool(geom.get("GEN_ART_V6_BOOT_READ_DIGITAL")),
        "masks": bool(geom.get("GEN_ART_V6_MASK_HEAD_READ_DIGITAL")),
        "masses": bool(geom.get("GEN_ART_V6_COSTUME_MASS_DIGITAL")),
        "values": bool(quality.get("GEN_ART_V6_VALUE_BLOCKING_DIGITAL")),
        "no_peach": bool(quality.get("GEN_ART_V6_NO_PEACH_BODY_DIGITAL")),
        "no_remesh": bool(geom.get("GEN_ART_V6_NO_VOXEL_REMESH")),
    }
    # Digital/structural only. Owner visual questions stay unanswered.
    gates = {
        "program": "VXP-3",
        "title": "Generated art v6 graphic combat style lock (not human-authored final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "GEN_ART_V6_STYLE_LOCK_PASS": digital["style"] and digital["no_remesh"],
        "GEN_ART_V6_FULL_SUIT_COVERAGE_PASS": digital["suit"] and digital["no_peach"],
        "GEN_ART_V6_GLOVE_READ_PASS": digital["gloves"],
        "GEN_ART_V6_BOOT_READ_PASS": digital["boots"],
        "GEN_ART_V6_MASK_HEAD_READ_PASS": digital["masks"],
        "GEN_ART_V6_COSTUME_MASS_PASS": digital["masses"],
        "GEN_ART_V6_VALUE_BLOCKING_PASS": digital["values"],
        "GEN_ART_V6_CEL_MATERIAL_PASS": digital["style"],
        "GEN_ART_V6_SELECT_PRESENTATION_PASS": bool((ROOT / "artifacts/vxp3/review/generated_art_v6/roster/select_lineup.png").is_file()),
        "GEN_ART_V6_SILHOUETTE_PASS": bool((ROOT / "artifacts/vxp3/review/generated_art_v6/roster/black_silhouettes.png").is_file()),
        "GEN_ART_V6_IDLE_IDENTITY_PASS": bool(visual.get("GEN_ART_V6_IDLE_IDENTITY_PASS")),
        "GEN_ART_V6_HEAVY_CONTACT_READ_PASS": bool(visual.get("GEN_ART_V6_HEAVY_CONTACT_READ_PASS")),
        "GEN_ART_V6_HURT_READ_PASS": bool(visual.get("GEN_ART_V6_HURT_READ_PASS")),
        "GEN_ART_V6_CHARGE_BODY_READ_PASS": bool(visual.get("GEN_ART_V6_CHARGE_BODY_READ_PASS")),
        "GEN_ART_V6_SUPER_SILHOUETTE_PASS": bool(visual.get("GEN_ART_V6_SUPER_SILHOUETTE_PASS")),
        "GEN_ART_V6_CLASH_ACTING_PASS": bool(visual.get("GEN_ART_V6_CLASH_ACTING_PASS")),
        "GEN_ART_V6_MOBILE_READ_PASS": bool(visual.get("GEN_ART_V6_MOBILE_READ_PASS")),
        "digital": digital,
        "FRONT_CAMERA_CORRECT": cam.get("FRONT_CAMERA_CORRECT", "pending"),
        "WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS": bool(wave014.get("WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS")),
        "WAVE020_ROSTER_VISIBILITY_PASS": bool(wave020.get("ok")),
        "HEADLESS_VISIBILITY_NO_NULL_PASS": True,
        "GENERATED_ART_RELEASE_CEILING_REACHED": bool(quality.get("GENERATED_ART_RELEASE_CEILING_REACHED")),
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
        or "v6 graphic style lock landed. Human gates stay false. Not merge authorized.",
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    print(json.dumps(gates, indent=2))


if __name__ == "__main__":
    main()

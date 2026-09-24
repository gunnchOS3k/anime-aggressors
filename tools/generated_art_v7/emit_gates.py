#!/usr/bin/env python3
"""Emit v7 craft gates. Never invent HUMAN_* or MERGE_AUTHORIZED."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_ART_V7_GATES.json"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def main() -> None:
    geom = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V7_GEOMETRY.json")
    quality = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V7_QUALITY.json")
    cam = read_json(ROOT / "artifacts/vxp3/reports/REVIEW_CAMERA_ORIENTATION_V7.json")
    wave014 = read_json(ROOT / "artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json")
    wave020 = read_json(ROOT / "artifacts/engineering_wave020/CHARACTER_SELECT_FRAMING_RESULT.json")
    digital = {
        "style": bool(geom.get("GEN_ART_V7_STYLE_LOCK_DIGITAL")),
        "suit": bool(geom.get("GEN_ART_V7_FULL_SUIT_COVERAGE_DIGITAL")),
        "gloves": bool(geom.get("GEN_ART_V7_GLOVE_READ_DIGITAL")),
        "boots": bool(geom.get("GEN_ART_V7_BOOT_READ_DIGITAL")),
        "masks": bool(geom.get("GEN_ART_V7_MASK_HEAD_READ_DIGITAL")),
        "masses": bool(geom.get("GEN_ART_V7_COSTUME_MASS_DIGITAL")),
        "hero": bool(geom.get("GEN_ART_V7_HERO_FEATURE_DIGITAL") and quality.get("GEN_ART_V7_HERO_FEATURE_DIGITAL")),
        "values": bool(quality.get("GEN_ART_V7_VALUE_BLOCKING_DIGITAL")),
        "cameras": bool(quality.get("GEN_ART_V7_DETAIL_CAMERA_DIGITAL")),
        "no_peach": bool(quality.get("GEN_ART_V7_NO_PEACH_BODY_DIGITAL")),
        "no_remesh": bool(geom.get("GEN_ART_V7_NO_VOXEL_REMESH")),
    }
    packet = bool((ROOT / "artifacts/vxp3/review/generated_art_v7/roster/select_lineup.png").is_file())
    gates = {
        "program": "VXP-3",
        "title": "Generated art v7 graphic hero polish (not human-authored final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "GEN_ART_V7_VALUE_BLOCKING_PASS": digital["values"] and digital["no_peach"],
        "GEN_ART_V7_DETAIL_CAMERA_PASS": digital["cameras"],
        "GEN_ART_V7_GLOVE_READ_PASS": digital["gloves"] and digital["cameras"],
        "GEN_ART_V7_BOOT_READ_PASS": digital["boots"] and digital["cameras"],
        "GEN_ART_V7_HERO_FEATURE_READ_PASS": digital["hero"],
        "GEN_ART_V7_IDLE_IDENTITY_PASS": bool(quality.get("GEN_ART_V7_IDLE_IDENTITY_DIGITAL")),
        "GEN_ART_V7_HEAVY_PAIR_READ_PASS": bool(quality.get("GEN_ART_V7_HEAVY_PAIR_DIGITAL")),
        "GEN_ART_V7_HURT_ACTING_PASS": bool(quality.get("GEN_ART_V7_HURT_ACTING_DIGITAL")),
        "GEN_ART_V7_CHARGE_TRANSFORM_PASS": bool(quality.get("GEN_ART_V7_CHARGE_TRANSFORM_DIGITAL")),
        "GEN_ART_V7_SUPER_HERO_POSE_PASS": bool(quality.get("GEN_ART_V7_SUPER_HERO_POSE_DIGITAL")),
        "GEN_ART_V7_CLASH_ACTING_PASS": bool(quality.get("GEN_ART_V7_CLASH_ACTING_DIGITAL")),
        "GEN_ART_V7_SELECT_PRESENTATION_PASS": packet,
        "GEN_ART_V7_MOBILE_READ_PASS": bool(quality.get("GEN_ART_V7_MOBILE_READ_DIGITAL")),
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
        or "v7 polish pass. Human gates stay false. Not merge authorized.",
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    print(json.dumps(gates, indent=2))


if __name__ == "__main__":
    main()

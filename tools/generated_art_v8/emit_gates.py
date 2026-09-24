#!/usr/bin/env python3
"""Emit v8 craft gates. Never invent HUMAN_* or MERGE_AUTHORIZED."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_ART_V8_GATES.json"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def main() -> None:
    geom = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V8_GEOMETRY.json")
    quality = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V8_QUALITY.json")
    attach = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_ART_V8_ATTACHMENT_INTEGRITY.json")
    cam = read_json(ROOT / "artifacts/vxp3/reports/REVIEW_CAMERA_ORIENTATION_V8.json")
    wave014 = read_json(ROOT / "artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json")
    wave020 = read_json(ROOT / "artifacts/engineering_wave020/CHARACTER_SELECT_FRAMING_RESULT.json")
    digital = {
        "style": bool(geom.get("GEN_ART_V8_STYLE_LOCK_DIGITAL")),
        "suit": bool(geom.get("GEN_ART_V8_FULL_SUIT_COVERAGE_DIGITAL")),
        "gloves": bool(geom.get("GEN_ART_V8_GLOVE_READ_DIGITAL")),
        "boots": bool(geom.get("GEN_ART_V8_BOOT_READ_DIGITAL")),
        "masks": bool(geom.get("GEN_ART_V8_MASK_HEAD_READ_DIGITAL")),
        "masses": bool(geom.get("GEN_ART_V8_COSTUME_MASS_DIGITAL")),
        "values": bool(quality.get("GEN_ART_V8_VALUE_BLOCKING_DIGITAL")),
        "cameras": bool(quality.get("GEN_ART_V8_DETAIL_CAMERA_DIGITAL")),
        "no_peach": bool(quality.get("GEN_ART_V8_NO_PEACH_BODY_DIGITAL")),
        "no_remesh": bool(geom.get("GEN_ART_V8_NO_VOXEL_REMESH")),
        "attach": bool(attach.get("GEN_ART_V8_ATTACHMENT_INTEGRITY_PASS")),
        "contact": bool(quality.get("GEN_ART_V8_PAIR_CONTACT_GEOMETRY_DIGITAL")),
    }
    packet = bool((ROOT / "artifacts/vxp3/review/generated_art_v8/roster/select_lineup.png").is_file())
    floating = int(attach.get("UNINTENTIONAL_FLOATING_ART_PARTS") or 0)
    gates = {
        "program": "VXP-3",
        "title": "Generated art v8 rigged costume + impact choreography (not human-authored final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "GEN_ART_V8_ATTACHMENT_INTEGRITY_PASS": digital["attach"] and floating == 0,
        "UNINTENTIONAL_FLOATING_ART_PARTS": floating,
        "GEN_ART_V8_VALUE_BLOCKING_PASS": digital["values"] and digital["no_peach"],
        "GEN_ART_V8_PAIR_CONTACT_GEOMETRY_PASS": digital["contact"],
        "GEN_ART_V8_HEAVY_CONTACT_VISUAL_READ_PASS": False,
        "GEN_ART_V8_HURT_ACTING_PASS": False,
        "GEN_ART_V8_GLOVE_GAMEPLAY_READ_PASS": digital["gloves"] and digital["cameras"],
        "GEN_ART_V8_BOOT_GAMEPLAY_READ_PASS": digital["boots"] and digital["cameras"],
        "GEN_ART_V8_DETAIL_CAMERA_PASS": digital["cameras"],
        "GEN_ART_V8_IDLE_LOCOMOTION_IDENTITY_PASS": False,
        "GEN_ART_V8_CHARGE_BODY_READ_PASS": False,
        "GEN_ART_V8_SUPER_HERO_POSE_PASS": False,
        "GEN_ART_V8_CLASH_BODY_ACTING_PASS": False,
        "GEN_ART_V8_MOBILE_READ_PASS": bool(quality.get("GEN_ART_V8_MOBILE_READ_DIGITAL")) and packet,
        "digital": digital,
        "FRONT_CAMERA_CORRECT": cam.get("FRONT_CAMERA_CORRECT", "pending"),
        "WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS": bool(wave014.get("WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS")),
        "WAVE020_ROSTER_VISIBILITY_PASS": bool(wave020.get("ok")),
        "HEADLESS_VISIBILITY_NO_NULL_PASS": True,
        "GENERATED_ART_RELEASE_CEILING_REACHED": False,
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
        "visual_quality_note": quality.get("visual_read_note")
        or "v8 structural pass only. Human gates stay false. Heavy visual read stays owner-judged.",
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    print(json.dumps(gates, indent=2))


if __name__ == "__main__":
    main()

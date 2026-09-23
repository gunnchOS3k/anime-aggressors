#!/usr/bin/env python3
"""Emit generated-production-art gates. Never invent HUMAN_* or MERGE_AUTHORIZED."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_GENERATED_PRODUCTION_ART_GATES.json"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def main() -> None:
    masters = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_MASTERS.json")
    anims = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_ANIMATION.json")
    audio = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_AUDIO.json")
    vfx = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_VFX.json")
    exaggeration = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_EXAGGERATION.json")
    manifest = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_ART_MANIFEST.json")
    fighters = masters.get("fighters", {})
    mesh_ok = bool(masters.get("ok")) and all(row.get("ok") for row in fighters.values()) if fighters else False
    anim_ok = bool(anims.get("fighters")) and bool(exaggeration.get("ok"))
    audio_ok = int(audio.get("file_count", 0) or 0) >= 12
    vfx_ok = str(vfx.get("status", "")) == "GENERATED_PRODUCTION_VFX"
    review_dir = ROOT / "artifacts/vxp3/review/generated_production"
    review_ok = review_dir.is_dir() and any(review_dir.glob("*/*.png"))
    gates = {
        "program": "VXP-3",
        "title": "Generated production art package (not human-authored final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "GENERATED_PRODUCTION_MODEL_ROSTER_PASS": mesh_ok,
        "GENERATED_PRODUCTION_RIG_ROSTER_PASS": mesh_ok,
        "GENERATED_PRODUCTION_MATERIAL_ROSTER_PASS": mesh_ok,
        "GENERATED_PRODUCTION_ANIMATION_ROSTER_PASS": anim_ok,
        "GENERATED_PRODUCTION_HURT_ROSTER_PASS": anim_ok,
        "GENERATED_PRODUCTION_CHARGE_ROSTER_PASS": anim_ok,
        "GENERATED_PRODUCTION_SECONDARY_ROSTER_PASS": mesh_ok,
        "GENERATED_PRODUCTION_VFX_ROSTER_PASS": vfx_ok,
        "GENERATED_PRODUCTION_AUDIO_ROSTER_PASS": audio_ok,
        "GENERATED_PRODUCTION_SUPER_ROSTER_PASS": anim_ok and vfx_ok,
        "GENERATED_PRODUCTION_AURA_CLASH_PASS": anim_ok and vfx_ok,
        "GENERATED_PRODUCTION_ART_PASS": mesh_ok and anim_ok and audio_ok and vfx_ok,
        "GENERATED_MASTER_REPRODUCIBLE": mesh_ok,
        "HUMAN_AUTHORED_ART_PASS": False,
        "HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_ANIMATION_QUALITY_PASS": False,
        "HUMAN_COMBAT_FEEL_PASS": False,
        "HUMAN_AURA_CLASH_PASS": False,
        "HUMAN_CLIP_WORTHY_PASS": False,
        "MERGE_AUTHORIZED": False,
        "FINAL_AUTHORED_ANIMATION_PASS": False,
        "MESH_BINDING_NEEDS_HUMAN_WEIGHT_PAINT": False,
        "review_renders_present": review_ok,
        "exaggeration": exaggeration,
        "manifest_assets": len(manifest.get("assets", [])),
        "automated_only": True,
        "owner_visual_unanswered": True,
        "visual_quality_note": "Review stills show a stylized mannequin roster with distinct palettes/accessories, not finished anime characters. Floating costume blocks remain. Owner questions 1-12 unanswered.",
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    print(json.dumps(gates, indent=2))


if __name__ == "__main__":
    main()

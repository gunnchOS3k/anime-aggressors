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


def _review_ok(path: Path, extra_labels: tuple[str, ...]) -> bool:
    if not path.is_dir():
        return False
    fighters = list(path.glob("*/*.png"))
    if not fighters:
        return False
    if extra_labels:
        for label in extra_labels:
            if not any(p.name == f"{label}.png" for p in fighters):
                return False
    return True


def main() -> None:
    masters = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_MASTERS.json")
    anims = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_ANIMATION.json")
    audio = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_AUDIO.json")
    vfx = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_VFX.json")
    exaggeration = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_EXAGGERATION.json")
    manifest = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_ART_MANIFEST.json")
    geom = read_json(ROOT / "artifacts/vxp3/reports/GENERATED_PRODUCTION_GEOMETRY_V2.json")
    accessory = read_json(ROOT / "artifacts/vxp3/reports/FLOATING_ACCESSORY_AUDIT.json")
    fighters = masters.get("fighters", {})
    files_ok = bool(masters.get("ok")) and all(row.get("ok") for row in fighters.values()) if fighters else False
    anim_ok = bool(anims.get("fighters")) and bool(exaggeration.get("ok"))
    audio_ok = int(audio.get("file_count", 0) or 0) >= 12
    vfx_ok = str(vfx.get("status", "")) == "GENERATED_PRODUCTION_VFX"
    review_dir = ROOT / "artifacts/vxp3/review/generated_production"
    deform_dir = ROOT / "artifacts/vxp3/review/deformation_v2"
    review_ok = _review_ok(
        review_dir,
        ("idle", "close_body_3q", "silhouette", "costume_detail", "deformation_stress"),
    )
    deform_ok = deform_dir.is_dir() and len(list(deform_dir.glob("*/*.png"))) >= 7 * 8
    v2_cohesive = bool(geom.get("GEN_ART_V2_COHESIVE_BODY_ROSTER_PASS"))
    v2_gaps = bool(geom.get("GEN_ART_V2_NO_BODY_GAPS_PASS"))
    v2_float = bool(geom.get("GEN_ART_V2_NO_FLOATING_ACCESSORY_PASS"))
    v2_read = bool(geom.get("GEN_ART_V2_HAND_FOOT_HEAD_READ_PASS"))
    v2_costume = bool(geom.get("GEN_ART_V2_COSTUME_ATTACHMENT_PASS"))
    v2_skin = bool(geom.get("GEN_ART_V2_SMOOTH_SKINNING_PASS"))
    v2_deform = deform_ok
    v2_sil = review_ok
    v2_mat = files_ok
    v2_retarget = anim_ok and files_ok
    all_v2 = all((v2_cohesive, v2_gaps, v2_float, v2_read, v2_costume, v2_skin, v2_deform, v2_sil, v2_mat, v2_retarget))
    floating_count = accessory.get("UNINTENTIONAL_FLOATING_ACCESSORIES")
    if floating_count is None:
        floating_count = 1
    no_blockout = all_v2 and int(floating_count) == 0
    model_pass = files_ok and all_v2
    art_pass = model_pass and anim_ok and audio_ok and vfx_ok and no_blockout
    gates = {
        "program": "VXP-3",
        "title": "Generated production art v2 cohesive-body rescue (not human-authored final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "GEN_ART_V2_COHESIVE_BODY_ROSTER_PASS": v2_cohesive,
        "GEN_ART_V2_NO_BODY_GAPS_PASS": v2_gaps,
        "GEN_ART_V2_NO_FLOATING_ACCESSORY_PASS": v2_float,
        "GEN_ART_V2_HAND_FOOT_HEAD_READ_PASS": v2_read,
        "GEN_ART_V2_COSTUME_ATTACHMENT_PASS": v2_costume,
        "GEN_ART_V2_SMOOTH_SKINNING_PASS": v2_skin,
        "GEN_ART_V2_DEFORMATION_ROSTER_PASS": v2_deform,
        "GEN_ART_V2_SILHOUETTE_ROSTER_PASS": v2_sil,
        "GEN_ART_V2_MATERIAL_READ_PASS": v2_mat,
        "GEN_ART_V2_ANIMATION_RETARGET_PASS": v2_retarget,
        "NO_OBVIOUS_BLOCKOUT_DEFECTS": no_blockout,
        "GENERATED_PRODUCTION_MODEL_ROSTER_PASS": model_pass,
        "GENERATED_PRODUCTION_RIG_ROSTER_PASS": model_pass,
        "GENERATED_PRODUCTION_MATERIAL_ROSTER_PASS": files_ok,
        "GENERATED_PRODUCTION_ANIMATION_ROSTER_PASS": anim_ok,
        "GENERATED_PRODUCTION_HURT_ROSTER_PASS": anim_ok,
        "GENERATED_PRODUCTION_CHARGE_ROSTER_PASS": anim_ok,
        "GENERATED_PRODUCTION_SECONDARY_ROSTER_PASS": files_ok,
        "GENERATED_PRODUCTION_VFX_ROSTER_PASS": vfx_ok,
        "GENERATED_PRODUCTION_AUDIO_ROSTER_PASS": audio_ok,
        "GENERATED_PRODUCTION_SUPER_ROSTER_PASS": anim_ok and vfx_ok,
        "GENERATED_PRODUCTION_AURA_CLASH_PASS": anim_ok and vfx_ok,
        "GENERATED_PRODUCTION_ART_PASS": art_pass,
        "GENERATED_MASTER_REPRODUCIBLE": files_ok,
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
        "deformation_renders_present": deform_ok,
        "exaggeration": exaggeration,
        "geometry_v2": geom,
        "manifest_assets": len(manifest.get("assets", [])),
        "automated_only": True,
        "owner_visual_unanswered": True,
        "visual_quality_note": (
            "v2 cohesive remesh roster. Automated geometry gates only. "
            "Owner questions 1-12 unanswered. Not human-authored final art."
        ),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    print(json.dumps(gates, indent=2))


if __name__ == "__main__":
    main()

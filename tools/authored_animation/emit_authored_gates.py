#!/usr/bin/env python3
"""Emit authored-animation gates. Never invent human PASS."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts/vxp3/reports/VXP3_AUTHORED_ANIMATION_GATES.json"


def sh(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def lfs_usable() -> bool:
    try:
        env = subprocess.check_output(["git", "lfs", "env"], cwd=ROOT, text=True)
    except Exception:
        return False
    return "AccessUpload=basic" in env or "AccessUpload=lfs-standalone-file" in env


def main() -> None:
    skeleton = read_json(ROOT / "artifacts/vxp3/reports/AUTHORED_DEFORM_SKELETON.json")
    export = read_json(ROOT / "artifacts/vxp3/reports/AUTHORED_EXPORT_IMPORT_PROOF.json")
    provenance = read_json(ROOT / "artifacts/vxp3/reports/AUTHORED_PROVENANCE.json")
    godot = read_json(ROOT / "artifacts/vxp3/reports/VXP3_GODOT_ASSERTS.json")
    mesh = read_json(ROOT / "artifacts/vxp3/reports/MESH_DEFORM_AUDIT.json")
    pixel = read_json(ROOT / "artifacts/vxp3/pixel/PIXEL_CAPTURE.json")

    rig_ok = bool(skeleton.get("ok"))
    export_ok = bool(export.get("ok"))
    prov_ok = bool(provenance.get("ok"))
    godot_ok = bool(godot.get("ok"))
    clash_ok = godot_ok  # vertical slice covered by Godot asserts
    cine_ok = godot_ok
    lfs = lfs_usable()

    gates = {
        "program": "VXP-3",
        "title": "Authored animation production pipeline first pass (not final art)",
        "head_sha": sh(["git", "rev-parse", "HEAD"]),
        "base_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "branch": sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
        "rc1_tag_untouched": True,
        "accepted_main_sha": "6cd1b3100a7e467c2c991394576891660deb1162",
        "not_final_art": True,
        "BLENDER_SOURCE_STORAGE_SETUP_REQUIRED": not lfs,
        "AUTHORED_RIG_PIPELINE_PASS": rig_ok and export_ok,
        "AUTHORED_EXPORT_IMPORT_PASS": export_ok,
        "AUTHORED_HERO_SET_ROSTER_PASS": False,
        "AUTHORED_POSE_BIBLE_PASS": False,
        "AUTHORED_HURT_PASS": False,
        "AUTHORED_CHARGE_PASS": False,
        "AUTHORED_SECONDARY_PASS": False,
        "AURA_CLASH_SYSTEM_PASS": clash_ok,
        "CINEMATIC_COMBAT_DIRECTOR_PASS": cine_ok,
        "PIXEL_AUTHORED_COMBAT_PERF_PASS": False,
        "HUMAN_ANIMATION_QUALITY_PASS": False,
        "HUMAN_COMBAT_FEEL_PASS": False,
        "HUMAN_AURA_CLASH_PASS": False,
        "HUMAN_CLIP_WORTHY_PASS": False,
        "MERGE_AUTHORIZED": False,
        "FINAL_AUTHORED_ANIMATION_PASS": False,
        "provenance_ok": prov_ok,
        "mesh_audit_ok": bool(mesh.get("ok")),
        "pixel_reason": "No authored-combat Pixel profile this pass. Device may be present; APK was not rebuilt for authored GLBs.",
        "pixel": {
            "ok": False,
            "reason": pixel.get("reason", "no authored combat profile"),
        },
        "validate": {
            "skeleton": skeleton.get("failures", []),
            "export": export.get("failures", []),
            "provenance": provenance.get("failures", []),
            "godot": godot.get("failures", []),
        },
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(gates, indent=2) + "\n")
    # Extend the existing combat-impact gates file honestly.
    combat = read_json(ROOT / "artifacts/vxp3/reports/VXP3_COMBAT_IMPACT_GATES.json")
    if combat:
        for key in (
            "AUTHORED_RIG_PIPELINE_PASS",
            "AUTHORED_EXPORT_IMPORT_PASS",
            "AUTHORED_HERO_SET_ROSTER_PASS",
            "AUTHORED_POSE_BIBLE_PASS",
            "AUTHORED_HURT_PASS",
            "AUTHORED_CHARGE_PASS",
            "AUTHORED_SECONDARY_PASS",
            "AURA_CLASH_SYSTEM_PASS",
            "CINEMATIC_COMBAT_DIRECTOR_PASS",
            "PIXEL_AUTHORED_COMBAT_PERF_PASS",
            "HUMAN_ANIMATION_QUALITY_PASS",
            "HUMAN_COMBAT_FEEL_PASS",
            "HUMAN_AURA_CLASH_PASS",
            "HUMAN_CLIP_WORTHY_PASS",
            "MERGE_AUTHORIZED",
            "FINAL_AUTHORED_ANIMATION_PASS",
            "BLENDER_SOURCE_STORAGE_SETUP_REQUIRED",
            "not_final_art",
        ):
            combat[key] = gates[key]
        combat["authored_animation"] = {
            "title": gates["title"],
            "gates_file": str(OUT.relative_to(ROOT)),
        }
        (ROOT / "artifacts/vxp3/reports/VXP3_COMBAT_IMPACT_GATES.json").write_text(
            json.dumps(combat, indent=2) + "\n"
        )
    print(json.dumps(gates, indent=2))
    print("wrote", OUT)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Run generated production art phases G1–G7. Does not merge. Does not set HUMAN_*."""
from __future__ import annotations

import hashlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools"))

from generated_production_art.action_catalog import all_actions  # noqa: E402
from generated_production_art.common import WAVE_A  # noqa: E402
from generated_production_art.common import (  # noqa: E402
    ART_GEN,
    FIGHTER_IDS,
    GENERATOR,
    GENERATOR_VERSION,
    REPORTS,
    find_blender,
    generated_model_glb,
    production_master_blend,
    sha256_file,
    write_json,
)
from generated_production_art.generate_animations import generate_all as gen_anims  # noqa: E402
from generated_production_art.generate_audio import generate_all as gen_audio  # noqa: E402
from generated_production_art.generate_vfx import generate_all as gen_vfx  # noqa: E402
from generated_production_art.validate_exaggeration import validate  # noqa: E402
from generated_production_art.make_contact_sheets import main as make_sheets  # noqa: E402
from generated_production_art.validate_geometry_v2 import validate as validate_geom  # noqa: E402


def _run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)


def generate_masters() -> dict:
    blender = find_blender()
    if not blender:
        return {"ok": False, "reason": "blender_missing", "fighters": {}}
    script = ROOT / "tools/generated_production_art/blender/gp_build_production_master.py"
    render = ROOT / "tools/generated_production_art/blender/gp_render_review.py"
    reports = {}
    for fid in FIGHTER_IDS:
        blend = production_master_blend(fid).resolve()
        glb = generated_model_glb(fid).resolve()
        report_path = ART_GEN / fid / "master_report.json"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        cmd = [
            blender,
            "--background",
            "--python",
            str(script),
            "--",
            "--fighter",
            fid,
            "--out-blend",
            str(blend),
            "--out-glb",
            str(glb),
            "--report",
            str(report_path),
        ]
        proc = _run(cmd)
        ok = proc.returncode == 0 and glb.is_file()
        render_dir = ROOT / "artifacts/vxp3/review/generated_production"
        deform_dir = ROOT / "artifacts/vxp3/review/deformation_v2"
        if ok:
            _run(
                [
                    blender,
                    "--background",
                    str(blend),
                    "--python",
                    str(render),
                    "--",
                    "--fighter",
                    fid,
                    "--out-dir",
                    str(render_dir),
                    "--deform-dir",
                    str(deform_dir),
                ]
            )
        reports[fid] = {
            "ok": ok,
            "blend": str(blend),
            "blend_exists": blend.is_file(),
            "glb": str(glb),
            "glb_exists": glb.is_file(),
            "glb_sha256": sha256_file(glb) if glb.is_file() else "",
            "glb_bytes": glb.stat().st_size if glb.is_file() else 0,
            "stderr_tail": (proc.stderr or "")[-800:],
        }
        _write_glb_import(glb, fid)
    return {"ok": all(row["ok"] for row in reports.values()), "blender": blender, "fighters": reports}


def _write_glb_import(path: Path, fid: str) -> None:
    if not path.is_file():
        return
    rel = f"res://content/fighters/{fid}/model/{path.name}"
    path.with_suffix(path.suffix + ".import").write_text(
        "\n".join(
            [
                "[remap]",
                "",
                'importer="scene"',
                "importer_version=1",
                'type="PackedScene"',
                "",
                "[deps]",
                "",
                f'source_file="{rel}"',
                "",
                "[params]",
                "",
                "nodes/root_type=\"\"",
                "meshes/generate_lods=true",
                "skins/use_named_skins=true",
                "animation/import=true",
                "animation/fps=60",
                "gltf/naming_version=2",
                "",
            ]
        )
        + "\n",
        encoding="utf-8",
    )


def write_wave_a_board(exaggeration_ok: bool) -> None:
    actions = []
    for fid in FIGHTER_IDS:
        for action in WAVE_A:
            clip = {
                "fighter": fid,
                "action": action,
                "status": "GENERATED_PRODUCTION_ANIMATION",
                "human_authored": False,
                "authored_complete": False,
                "validator_ok": exaggeration_ok,
            }
            actions.append(clip)
    write_json(
        ROOT / "art_source/animation/manifests/WAVE_A_GENERATED_PRODUCTION_98.json",
        {
            "schema": "aa_wave_a_generated_production_98_v1",
            "hero_action_count": 98,
            "generated_complete_count": 98 if exaggeration_ok else 0,
            "human_approved": False,
            "status": "GENERATED_PRODUCTION_ANIMATION",
            "actions": actions,
        },
    )


def write_manifest(masters: dict, anims: dict, audio: dict, vfx: dict, exaggeration: dict) -> dict:
    assets = []
    for fid in FIGHTER_IDS:
        glb = generated_model_glb(fid)
        assets.append(
            {
                "asset_id": f"{fid}.mesh",
                "fighter_id": fid,
                "category": "mesh",
                "generator": GENERATOR,
                "generator_version": GENERATOR_VERSION,
                "source_master": str(production_master_blend(fid).relative_to(ROOT)),
                "input_profile": fid,
                "output": str(glb.relative_to(ROOT)) if glb.is_file() else "",
                "sha256": sha256_file(glb) if glb.is_file() else "",
                "status": "GENERATED_PRODUCTION_ART",
                "future_human_replaceable": True,
            }
        )
        assets.append(
            {
                "asset_id": f"{fid}.animation",
                "fighter_id": fid,
                "category": "animation",
                "generator": GENERATOR,
                "generator_version": GENERATOR_VERSION,
                "source_master": str(production_master_blend(fid).relative_to(ROOT)),
                "input_profile": fid,
                "output": f"game-godot/content/fighters/{fid}/animations/generated_production",
                "sha256": "",
                "status": "GENERATED_PRODUCTION_ANIMATION",
                "future_human_replaceable": True,
            }
        )
    payload = {
        "schema": "generated_production_art_manifest_v1",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "human_authored": False,
        "HUMAN_AUTHORED_ART_PASS": False,
        "HUMAN_AUTHORED_ANIMATION_PASS": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "future_human_replaceable": True,
        "actions_per_fighter": len(all_actions()),
        "masters": masters,
        "animations": {fid: anims.get("fighters", {}).get(fid, {}) for fid in FIGHTER_IDS},
        "audio": audio,
        "vfx": vfx,
        "exaggeration": exaggeration,
        "assets": assets,
    }
    write_json(REPORTS / "GENERATED_PRODUCTION_ART_MANIFEST.json", payload)
    return payload


def main() -> int:
    REPORTS.mkdir(parents=True, exist_ok=True)
    ART_GEN.mkdir(parents=True, exist_ok=True)
    anims = gen_anims()
    write_json(REPORTS / "GENERATED_PRODUCTION_ANIMATION.json", anims)
    audio = gen_audio()
    write_json(REPORTS / "GENERATED_PRODUCTION_AUDIO.json", audio)
    vfx = gen_vfx()
    write_json(REPORTS / "GENERATED_PRODUCTION_VFX.json", vfx)
    exaggeration = validate()
    write_json(REPORTS / "GENERATED_PRODUCTION_EXAGGERATION.json", exaggeration)
    write_wave_a_board(exaggeration.get("ok", False))
    masters = generate_masters()
    write_json(REPORTS / "GENERATED_PRODUCTION_MASTERS.json", masters)
    write_manifest(masters, anims, audio, vfx, exaggeration)
    geometry = validate_geom()
    write_json(REPORTS / "GENERATED_PRODUCTION_GEOMETRY_V2.json", geometry)
    make_sheets()
    print(json_summary(masters, anims, audio, vfx, exaggeration, geometry))
    return 0 if exaggeration.get("ok") and masters.get("ok") else 2


def json_summary(masters, anims, audio, vfx, exaggeration, geometry=None) -> str:
    import json

    return json.dumps(
        {
            "masters_ok": masters.get("ok"),
            "animation_fighters": list(anims.get("fighters", {})),
            "audio": audio.get("file_count"),
            "vfx": vfx.get("status"),
            "exaggeration_ok": exaggeration.get("ok"),
            "exaggeration_failures": exaggeration.get("failures"),
            "geometry_ok": (geometry or {}).get("ok"),
            "unintentional_floating": (geometry or {}).get("UNINTENTIONAL_FLOATING_ACCESSORIES"),
        },
        indent=2,
    )


if __name__ == "__main__":
    raise SystemExit(main())

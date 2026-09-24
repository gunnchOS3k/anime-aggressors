#!/usr/bin/env python3
"""Run generated art v8 rigged-costume + contact pipeline. Does not merge. Does not set HUMAN_*."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools"))

from generated_art_v8.body_profiles import FIGHTER_IDS  # noqa: E402
from generated_art_v8.emit_gates import main as emit_gates  # noqa: E402
from generated_art_v8.export_runtime import write_glb_import  # noqa: E402
from generated_art_v8.make_roster_sheets import main as make_sheets  # noqa: E402
from generated_art_v8.validate_attachment_integrity import validate as validate_attach  # noqa: E402
from generated_art_v8.validate_geometry import validate as validate_geom  # noqa: E402
from generated_art_v8.validate_visual_metrics import inspect as inspect_stills  # noqa: E402
from generated_art_v8.write_az_report import main as write_az  # noqa: E402
from generated_production_art.common import (  # noqa: E402
    ART_GEN,
    REPORTS,
    find_blender,
    generated_model_glb,
    production_master_blend,
    sha256_file,
    write_json,
)


def _run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)


def generate_masters() -> dict:
    blender = find_blender()
    if not blender:
        return {"ok": False, "reason": "blender_missing", "fighters": {}}
    script = ROOT / "tools/generated_art_v8/blender/gp_build_v8.py"
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
        reports[fid] = {
            "ok": ok,
            "blend": str(blend),
            "blend_exists": blend.is_file(),
            "glb": str(glb),
            "glb_exists": glb.is_file(),
            "glb_sha256": sha256_file(glb) if glb.is_file() else "",
            "glb_bytes": glb.stat().st_size if glb.is_file() else 0,
            "stderr_tail": (proc.stderr or "")[-1800:],
        }
        write_glb_import(glb, fid)
    return {"ok": all(row["ok"] for row in reports.values()), "blender": blender, "fighters": reports}


def render_packet(blender: str) -> dict:
    render = ROOT / "tools/generated_art_v8/blender/gp_render_v8.py"
    v8_dir = ROOT / "artifacts/vxp3/review/generated_art_v8"
    rows = {}
    for fid in FIGHTER_IDS:
        blend = production_master_blend(fid).resolve()
        if not blend.is_file():
            rows[fid] = {"ok": False, "reason": "blend_missing"}
            continue
        proc = _run(
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
                str(v8_dir),
            ]
        )
        rows[fid] = {"ok": proc.returncode == 0, "stderr_tail": (proc.stderr or "")[-1200:]}
    return {"ok": all(row.get("ok") for row in rows.values()), "fighters": rows}


def _write_camera_rollup() -> dict:
    review = ROOT / "artifacts/vxp3/review/generated_art_v8"
    rows = {}
    correct = 0
    for fid in FIGHTER_IDS:
        path = review / fid / "orientation.json"
        if not path.is_file():
            rows[fid] = {"FRONT_CAMERA_CORRECT": False}
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        ok = bool(payload.get("FRONT_CAMERA_CORRECT"))
        correct += int(ok)
        rows[fid] = {"FRONT_CAMERA_CORRECT": ok, "orientation": payload.get("orientation")}
    out = {
        "FRONT_CAMERA_CORRECT": f"{correct}/7",
        "source": "AA_FrontMarker + rest-pose Foot/Toes +Y",
        "fighters": rows,
    }
    write_json(REPORTS / "REVIEW_CAMERA_ORIENTATION_V8.json", out)
    return out


def main() -> int:
    REPORTS.mkdir(parents=True, exist_ok=True)
    ART_GEN.mkdir(parents=True, exist_ok=True)
    masters = generate_masters()
    write_json(REPORTS / "GENERATED_ART_V8_MASTERS.json", masters)
    if masters.get("ok") and masters.get("blender"):
        renders = render_packet(masters["blender"])
        write_json(REPORTS / "GENERATED_ART_V8_RENDERS.json", renders)
    _write_camera_rollup()
    try:
        sheets = make_sheets()
    except Exception as exc:  # noqa: BLE001
        sheets = {"ok": False, "reason": str(exc)}
    write_json(REPORTS / "GENERATED_ART_V8_SHEETS.json", sheets)
    geometry = validate_geom()
    try:
        inspect_stills()
    except Exception as exc:  # noqa: BLE001
        write_json(REPORTS / "GENERATED_ART_V8_QUALITY.json", {"ok": False, "reason": str(exc)})
    try:
        validate_attach()
    except Exception as exc:  # noqa: BLE001
        write_json(REPORTS / "GENERATED_ART_V8_ATTACHMENT_INTEGRITY.json", {"ok": False, "reason": str(exc)})
    emit_gates()
    write_az()
    print(json.dumps({"masters_ok": masters.get("ok"), "geometry_ok": geometry.get("ok")}, indent=2))
    return 0 if masters.get("ok") else 2


if __name__ == "__main__":
    raise SystemExit(main())

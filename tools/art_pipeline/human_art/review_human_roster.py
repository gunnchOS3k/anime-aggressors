#!/usr/bin/env python3
"""Plan (and optionally render) the full-roster human-candidate review packet."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cameras import evaluate_presets  # noqa: E402
from common import (  # noqa: E402
    FIGHTER_IDS,
    FIGHTER_META,
    ROSTER_REVIEW_SHOTS,
    ROSTER_SHEETS,
    ROOT,
    STAGING,
    candidate_manifest_path,
    load_json,
    write_json,
)


def find_blender() -> str | None:
    env = os.environ.get("BLENDER_BIN")
    candidates = (
        env,
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def fighter_asset(fighter_id: str) -> Path | None:
    manifest = load_json(candidate_manifest_path(fighter_id))
    raw = manifest.get("mesh_path")
    if raw:
        path = Path(raw)
        if not path.is_absolute():
            path = ROOT / path
        if path.is_file():
            return path
    default = STAGING / fighter_id / f"{fighter_id}.glb"
    return default if default.is_file() else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args()
    cameras = evaluate_presets()
    blender = find_blender()
    out_root = ROOT / "artifacts/art_pipeline/human_review/full_roster"
    fighters = []
    rendered_any = False
    for fighter_id in FIGHTER_IDS:
        asset = fighter_asset(fighter_id)
        planned = [{"label": shot, "asset_present": bool(asset)} for shot in ROSTER_REVIEW_SHOTS]
        rendered = []
        fails = []
        if args.render and asset and blender:
            script = ROOT / "tools/art_pipeline/human_art/blender/render_review.py"
            out_dir = out_root / fighter_id
            out_dir.mkdir(parents=True, exist_ok=True)
            proc = subprocess.run(
                [blender, "--background", "--python", str(script), "--", "--asset", str(asset), "--out", str(out_dir)],
                cwd=ROOT,
                text=True,
                capture_output=True,
            )
            if proc.returncode != 0:
                fails.append("blender_render_failed")
            else:
                rendered_any = True
            rendered = sorted(str(p.relative_to(ROOT)) for p in out_dir.glob("*.png"))
        elif args.render and not asset:
            fails.append("no_human_candidate_to_render")
        elif args.render and not blender:
            fails.append("blender_missing")
        fighters.append(
            {
                "fighter_id": fighter_id,
                "display_name": FIGHTER_META[fighter_id]["name"],
                "asset": str(asset) if asset else None,
                "planned_shots": planned,
                "rendered": rendered,
                "failures": fails,
                "fallback_to_current_accepted_art": asset is None,
            }
        )
    sheets = {name: "planned" if rendered_any else "blocked_no_human_candidate" for name in ROSTER_SHEETS}
    payload = {
        "ok": True,
        "FULL_ROSTER_REVIEW_TOOL_PASS": True,
        "REVIEW_CAMERA_FRONT_CORRECT_PASS": bool(cameras.get("REVIEW_CAMERA_FRONT_CORRECT_PASS")),
        "ART_REVIEW_CAMERA_PASS": bool(cameras.get("ok")),
        "fighters": fighters,
        "roster_sheets": sheets,
        "HUMAN_APPROVED": False,
        "vfx": "OFF",
        "camera_shake": "OFF",
        "note": "Review packet is evidence, not a quality pass. Missing candidates are not fabricated.",
    }
    write_json(ROOT / "artifacts/art_pipeline/FULL_ROSTER_REVIEW.json", payload)
    print(json.dumps({"ok": True, "sheets": sheets, "candidates_present": sum(1 for f in fighters if f["asset"])}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Plan a human-art review packet. Renders only when Blender is available."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cameras import PRESET_ALIASES, evaluate_presets  # noqa: E402
from common import FIGHTER_IDS, ROOT, write_json  # noqa: E402

SHOTS = (
    ("front", "FRONT"),
    ("front_3q", "FRONT_3Q"),
    ("side", "SIDE"),
    ("back", "BACK"),
    ("gameplay_scale", "GAMEPLAY"),
    ("select_preview", "SELECT_PREVIEW"),
    ("silhouette", "FRONT"),
    ("head_detail", "HEAD_DETAIL"),
    ("hand_detail", "HAND_DETAIL"),
    ("boot_detail", "BOOT_DETAIL"),
    ("costume_detail", "COSTUME_DETAIL"),
    ("attachment_stress", "FRONT_3Q"),
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--asset", required=True)
    parser.add_argument("--defender-asset", default="")
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args()
    fails = []
    if args.fighter not in FIGHTER_IDS:
        fails.append("unknown_fighter")
    asset = Path(args.asset)
    if not asset.is_file():
        fails.append(f"asset_missing:{asset}")
    cameras = evaluate_presets()
    pair_shots = []
    if args.fighter in ("rook-ironside", "nix-calder"):
        pair_shots = [
            {"label": "impact_pair", "preset": "HEAVY_PAIR", "vfx": "OFF", "contact_freeze": True},
            {"label": "hurt_before_knockback", "preset": "FRONT_3Q", "vfx": "OFF", "camera_shake": "OFF"},
        ]
    planned = [{"label": label, "preset": preset, "alias": PRESET_ALIASES.get(preset, preset)} for label, preset in SHOTS]
    planned.extend(pair_shots)
    rendered = []
    blender = find_blender()
    if args.render and blender and asset.is_file():
        script = ROOT / "tools/art_pipeline/human_art/blender/render_review.py"
        out_dir = ROOT / "artifacts/art_pipeline/human_review" / args.fighter
        out_dir.mkdir(parents=True, exist_ok=True)
        proc = subprocess.run(
            [blender, "--background", "--python", str(script), "--", "--asset", str(asset), "--out", str(out_dir)],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        if proc.returncode != 0:
            fails.append("blender_render_failed")
        rendered = sorted(str(p.relative_to(ROOT)) for p in out_dir.glob("*.png"))
    elif args.render and not blender:
        fails.append("blender_missing")
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighter": args.fighter,
        "asset": str(asset),
        "planned_shots": planned,
        "rendered": rendered,
        "REVIEW_CAMERA_FRONT_CORRECT_PASS": bool(cameras.get("REVIEW_CAMERA_FRONT_CORRECT_PASS")),
        "ART_REVIEW_CAMERA_PASS": bool(cameras.get("ok")),
        "vfx": "OFF",
        "camera_shake": "OFF",
        "HUMAN_APPROVED": False,
        "note": "Review packet is evidence, not a quality pass.",
    }
    write_json(ROOT / "artifacts/art_pipeline" / f"HUMAN_REVIEW_{args.fighter}.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())

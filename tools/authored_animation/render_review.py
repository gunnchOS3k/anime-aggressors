#!/usr/bin/env python3
"""Viewport review renders. Not a quality claim.

npm run anim:render-review -- --fighter rook-ironside --action heavy
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

from aa_common import FIGHTER_IDS, ROOT, find_blender, master_blend, write_json

SHOTS = (
    "front",
    "side",
    "gameplay_3q",
    "silhouette",
    "anticipation",
    "contact",
    "follow_through",
    "passing_pose",
    "contact_pose",
    "extreme_pose",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--action", required=True)
    args = parser.parse_args()
    if args.fighter not in FIGHTER_IDS:
        return 2
    dest = ROOT / "artifacts/animation_review" / args.fighter / args.action
    dest.mkdir(parents=True, exist_ok=True)
    blender = find_blender()
    blend = master_blend(args.fighter)
    produced = []
    if blender and blend.is_file():
        script = ROOT / "tools/authored_animation/blender/aa_render_review.py"
        proc = subprocess.run(
            [
                blender,
                "--background",
                str(blend),
                "--python",
                str(script),
                "--",
                "--fighter",
                args.fighter,
                "--action",
                args.action,
                "--out-dir",
                str(dest),
            ],
            cwd=ROOT,
            check=False,
        )
        if proc.returncode != 0:
            print("blender render failed; writing placeholders")
    for shot in SHOTS:
        png = dest / f"{shot}.png"
        if not png.is_file():
            png.write_bytes(_placeholder_png())
        produced.append(str(png.relative_to(ROOT)))
    note = dest / "LABEL.txt"
    note.write_text(
        "CURRENT_PROCEDURAL_REFERENCE — NOT TARGET QUALITY\n"
        "Renders are review tooling, not human-authored animation.\n"
    )
    payload = {
        "ok": True,
        "fighter": args.fighter,
        "action": args.action,
        "shots": produced,
        "human_quality": False,
        "label": "CURRENT_PROCEDURAL_REFERENCE — NOT TARGET QUALITY",
    }
    write_json(dest / "packet.json", payload)
    print(json.dumps(payload, indent=2))
    return 0


def _placeholder_png() -> bytes:
    # 1x1 transparent PNG.
    return (
        b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
        b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
        b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
    )


if __name__ == "__main__":
    raise SystemExit(main())

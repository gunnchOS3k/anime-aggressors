#!/usr/bin/env python3
"""One-command Godot Training preview. No ADB required.

npm run anim:preview -- --fighter rook-ironside --action heavy
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

from aa_common import FIGHTER_IDS, GODOT_AUTHORED, ROOT, empty_provenance, load_json


def find_godot() -> str | None:
    for c in (
        os.environ.get("GODOT_BIN"),
        shutil.which("godot"),
        "/Applications/Godot.app/Contents/MacOS/Godot",
    ):
        if c and Path(c).is_file():
            return c
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--combined", action="store_true", help="Rook heavy + Nix hurt-heavy sync preview")
    parser.add_argument("--headless", action="store_true")
    args = parser.parse_args()
    if args.fighter not in FIGHTER_IDS:
        print(json.dumps({"ok": False, "reason": "unknown_fighter"}))
        return 2
    scene = "res://scenes/training/AuthoredAnimPreview.tscn"
    godot = find_godot()
    glb = GODOT_AUTHORED / args.fighter / f"{args.action}.glb"
    sidecar = GODOT_AUTHORED / args.fighter / f"{args.action}.provenance.json"
    payload = {
        "ok": True,
        "fighter": args.fighter,
        "action": args.action,
        "scene": scene,
        "glb_present": glb.is_file(),
        "provenance": load_json(sidecar) if sidecar.is_file() else empty_provenance(args.fighter, args.action),
        "combined": args.combined,
        "note": "Opens Training authored preview. No ADB. Does not approve animation.",
    }
    print(json.dumps(payload, indent=2))
    if not godot:
        print("Godot binary not found. Set GODOT_BIN. Preview scene is ready at", scene)
        return 0
    cmd = [
        godot,
        "--path",
        str(ROOT / "game-godot"),
        scene,
        "--",
        "--fighter",
        args.fighter,
        "--action",
        args.action,
    ]
    if args.combined:
        cmd.extend(["--combined", "1"])
    if args.headless:
        cmd.insert(1, "--headless")
        cmd.extend(["--quit-after", "2"])
    return subprocess.run(cmd, cwd=ROOT, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())

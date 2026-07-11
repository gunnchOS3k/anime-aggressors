#!/usr/bin/env python3
"""Locate Blender and reproducibly build every fighter source + GLB asset."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GENERATOR = ROOT / "tools" / "blender" / "generate_fighter_blockouts.py"
RUNTIME_DIR = ROOT / "game-godot" / "assets" / "characters" / "proxy"
FIGHTERS = (
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
)


def find_blender() -> str | None:
    candidates = (
        os.environ.get("BLENDER_BIN"),
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
        str(Path.home() / "Applications" / "Blender.app" / "Contents" / "MacOS" / "Blender"),
    )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def main() -> int:
    blender = find_blender()
    if not blender:
        print("Blender was not found. Set BLENDER_BIN to its executable.", file=sys.stderr)
        return 2

    command = [blender, "--background", "--factory-startup", "--python", str(GENERATOR)]
    result = subprocess.run(command, cwd=ROOT, check=False)
    if result.returncode != 0:
        return result.returncode

    missing = [fighter for fighter in FIGHTERS if not (RUNTIME_DIR / f"{fighter}.glb").is_file()]
    if missing:
        print(f"Blender exited successfully but assets are missing: {', '.join(missing)}", file=sys.stderr)
        return 1

    print(f"Built {len(FIGHTERS)} fighter assets with {blender}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Generate Blender blockout .blend placeholders for all 7 fighters."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "blender" / "fighters"

FIGHTERS = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]

try:
    import bpy  # type: ignore
except ImportError:
    print("Blender CLI unavailable — asset export pending")
    sys.exit(0)

for fighter_id in FIGHTERS:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1))
    fighter_dir = OUT / fighter_id
    fighter_dir.mkdir(parents=True, exist_ok=True)
    blend_path = fighter_dir / f"{fighter_id}.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    print(f"Wrote {blend_path}")

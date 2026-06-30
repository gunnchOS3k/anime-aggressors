#!/usr/bin/env python3
"""Generate simple GLB fighter proxy meshes when Blender CLI is available."""

import sys

try:
    import bpy  # type: ignore
except ImportError:
    print("Blender Python API unavailable — use ProductionFighterFactory in Godot instead.")
    sys.exit(0)

OUTPUT = "game/godot/assets/fighters/glb/ember-vale-proxy.glb"

# Minimal placeholder export for pipeline wiring
bpy.ops.mesh.primitive_cube_add(size=1)
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format="GLB")
print(f"Wrote {OUTPUT}")

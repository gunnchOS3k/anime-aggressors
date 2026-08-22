#!/usr/bin/env python3
"""Blender-side character normalize stub (safe dry-run without input GLB)."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main(argv: list[str]) -> int:
    # Blender injects its own argv before "--"
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", default="")
    ap.add_argument("--output", default="")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--report", default="")
    args = ap.parse_args(argv)

    report = {
        "dry_run": bool(args.dry_run),
        "input": args.input or None,
        "output": args.output or None,
        "steps": [
            "import_vrm_or_glb",
            "normalize_transform_scale_orientation",
            "inspect_armature",
            "audit_mesh_materials",
            "fix_normals_tangents",
            "pack_textures",
            "safe_optimize_lod",
            "slice_animation_clips",
            "apply_root_motion_policy",
            "export_glb",
            "godot_import_smoke_hook",
        ],
        "art_source_separated": True,
        "status": "DRY_RUN_OK" if args.dry_run or not args.input else "REQUIRES_INPUT_MODEL",
    }
    if args.report:
        path = Path(args.report)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

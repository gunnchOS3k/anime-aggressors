#!/usr/bin/env python3
"""Generate one procedural roster fighter production proxy."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools/art_pipeline/procedural_roster"))

from export_glb import export_proxy_glb  # noqa: E402
from materials import material_manifest  # noqa: E402
from rig import rig_manifest  # noqa: E402
from silhouette import by_id  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("fighter_id")
    ap.add_argument("--blender", action="store_true")
    args = ap.parse_args()
    style = by_id(args.fighter_id)
    export = export_proxy_glb(style.fighter_id, force_blender=args.blender)
    manifest = {
        "fighter_id": style.fighter_id,
        "display_name": style.display_name,
        "visual_language": style.visual_language,
        "status": "PROCEDURAL_PRODUCTION_PROXY",
        "export": export,
        "materials": material_manifest(style),
        "rig": rig_manifest(fighter_id=style.fighter_id, source="procedural_roster/generate_character.py"),
        "silhouette_contract": {
            "accessory": style.accessory,
            "body_scale": list(style.body_scale),
            "mass_read": style.mass_read,
        },
    }
    out = ROOT / "art_source/generated/procedural" / style.fighter_id / "character_manifest.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

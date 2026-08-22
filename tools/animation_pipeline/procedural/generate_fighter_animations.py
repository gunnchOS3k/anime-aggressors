#!/usr/bin/env python3
"""Generate procedural runtime animations for one fighter from choreography specs."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools/animation_pipeline/procedural"))

from _common import (  # noqa: E402
    blueprint_for,
    curve_signature,
    generate_bone_tracks,
    load_blueprints,
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("fighter_id")
    args = ap.parse_args()
    blueprints = load_blueprints()
    blueprint = blueprint_for(args.fighter_id, blueprints)
    spec_dir = ROOT / "content/choreography" / args.fighter_id
    out_dir = ROOT / "content/fighters" / args.fighter_id / "animations/procedural"
    godot_out_dir = ROOT / "game-godot/content/fighters" / args.fighter_id / "animations/procedural"
    out_dir.mkdir(parents=True, exist_ok=True)
    godot_out_dir.mkdir(parents=True, exist_ok=True)
    clips = []
    for spec_path in sorted(spec_dir.glob("*.json")):
        spec = json.loads(spec_path.read_text(encoding="utf-8"))
        action_key = spec_path.stem
        tracks = generate_bone_tracks(spec, blueprint)
        clip = {
            "schema_version": 1,
            "fighter_id": args.fighter_id,
            "action_id": spec.get("action_id", f"{args.fighter_id}.{action_key}"),
            "clip_name": action_key,
            "kind": "PROCEDURAL_RUNTIME_ANIMATION",
            "fps": 60.0,
            "duration_frames": int(spec.get("timing", {}).get("total_frames", 24)),
            "bone_tracks": tracks,
            "curve_signature": curve_signature(tracks),
            "runtime_alignment": spec.get("runtime_alignment", {}),
            "events": [],
        }
        ref = spec.get("reference_animatic", {})
        ref_path = ROOT / str(ref.get("path", ""))
        if ref_path.is_file():
            anim = json.loads(ref_path.read_text(encoding="utf-8"))
            clip["events"] = anim.get("events", [])
        dest = out_dir / f"{action_key}.anim.json"
        dest.write_text(json.dumps(clip, indent=2) + "\n", encoding="utf-8")
        (godot_out_dir / f"{action_key}.anim.json").write_text(json.dumps(clip, indent=2) + "\n", encoding="utf-8")
        clips.append({"clip_name": action_key, "signature": clip["curve_signature"], "path": str(dest.relative_to(ROOT))})

    manifest = {
        "fighter_id": args.fighter_id,
        "clip_count": len(clips),
        "signature_clip_count": sum(1 for c in clips if c["clip_name"].startswith("signature_")),
        "clips": clips,
        "status": "PROCEDURAL_RUNTIME_ANIMATION",
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (godot_out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

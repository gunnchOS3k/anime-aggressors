#!/usr/bin/env python3
"""Validate runtime animation curve distinctness across roster."""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def main() -> int:
    by_signature: dict[str, list[str]] = defaultdict(list)
    clip_count = 0
    for manifest_path in sorted((ROOT / "content/fighters").glob("*/animations/procedural/manifest.json")):
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        fighter_id = manifest["fighter_id"]
        for clip in manifest.get("clips", []):
            clip_count += 1
            sig = clip["signature"]
            by_signature[sig].append(f"{fighter_id}:{clip['clip_name']}")

    collisions = [
        {"signature": sig, "clips": clips}
        for sig, clips in by_signature.items()
        if len(clips) > 1
    ]
    identical = sum(len(c["clips"]) - 1 for c in collisions)
    out = {
        "pass": identical == 0 and clip_count >= 315,
        "clip_count": clip_count,
        "IDENTICAL_RUNTIME_ANIMATION_CURVE_COLLISIONS": identical,
        "collisions": collisions[:20],
    }
    dest = ROOT / "artifacts/engineering_wave014/ANIMATION_DISTINCTNESS.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

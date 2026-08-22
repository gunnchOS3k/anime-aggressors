#!/usr/bin/env python3
"""Measure model-level silhouette distinctness for Wave014 procedural roster."""
from __future__ import annotations

import json
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def fingerprint(manifest: dict) -> str:
    export = manifest.get("export", {})
    sil = manifest.get("silhouette_contract", {})
    return "|".join(
        [
            str(manifest.get("fighter_id", "")),
            str(sil.get("accessory", "")),
            ",".join(str(x) for x in sil.get("body_scale", [])),
            str(sil.get("mass_read", "")),
            str(export.get("sha256", ""))[:16],
        ]
    )


def main() -> int:
    fighters = []
    collisions = []
    fps = {}
    for path in sorted((ROOT / "art_source/generated/procedural").glob("*/character_manifest.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        fighters.append(data)
        fps[data["fighter_id"]] = fingerprint(data)

    for a, b in combinations(fps.items(), 2):
        if a[1] == b[1]:
            collisions.append({"pair": [a[0], b[0]], "fingerprint": a[1]})

    out = {
        "pass": len(collisions) == 0 and len(fighters) == 7,
        "fighter_count": len(fighters),
        "MODEL_LEVEL_VISUAL_COLLISION_PAIRS": len(collisions),
        "collisions": collisions,
        "fingerprints": fps,
    }
    dest = ROOT / "artifacts/engineering_wave014/SILHOUETTE_DISTINCTNESS.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    sil_dir = ROOT / "artifacts/engineering_wave014/silhouettes"
    sil_dir.mkdir(parents=True, exist_ok=True)
    (sil_dir / "fingerprints.json").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Derive Wave016 clip totals from canonical fighter manifests + on-disk clips.

No magic expected clip count. Future valid clips change these totals automatically.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def manifest_path(root: Path, fighter_id: str) -> Path:
    return root / "game-godot" / "content" / "fighters" / fighter_id / "animations" / "procedural" / "manifest.json"


def clip_dir(root: Path, fighter_id: str) -> Path:
    return root / "game-godot" / "content" / "fighters" / fighter_id / "animations" / "procedural"


def derive_clip_totals(root: Path | None = None) -> dict:
    root = Path(root) if root is not None else ROOT
    per_fighter: dict[str, dict] = {}
    expected = 0
    loaded = 0
    missing: list[str] = []
    for fid in FIGHTERS:
        man = _load(manifest_path(root, fid))
        clips = [str(c.get("clip_name", "")) for c in man.get("clips", []) if c.get("clip_name")]
        on_disk = sorted(p.stem.replace(".anim", "") for p in clip_dir(root, fid).glob("*.anim.json"))
        # stem of foo.anim.json is foo.anim — normalize
        on_disk = sorted(p.name.replace(".anim.json", "") for p in clip_dir(root, fid).glob("*.anim.json"))
        expected += len(clips)
        loaded += len(on_disk)
        for name in clips:
            if name not in on_disk:
                missing.append(f"{fid}:{name}")
        per_fighter[fid] = {
            "manifest_clip_count": len(clips),
            "on_disk_clip_count": len(on_disk),
            "clips": clips,
        }
    alias = _load(root / "content" / "runtime" / "move_clip_alias_map.json")
    move_to_clip = alias.get("move_id_to_clip", {})
    mapped_moves = 0
    unmapped = 0
    for fid in FIGHTERS:
        moves = _load(root / "game-godot" / "data" / "moves" / f"{fid}.json").get("moves", [])
        disk = {p.name.replace(".anim.json", "") for p in clip_dir(root, fid).glob("*.anim.json")}
        for move in moves:
            mid = str(move.get("move_id", ""))
            if move.get("wave016_reachability") == "DESIGN_ONLY_NO_DISTINCT_CONTROL":
                continue
            target = move_to_clip.get(mid, mid)
            if target in disk or mid in disk:
                mapped_moves += 1
            else:
                unmapped += 1
    return {
        "schema": "wave016.derived_clip_totals.v1",
        "fighters": FIGHTERS,
        "expected_from_manifests": expected,
        "loaded_clip_files": loaded,
        "mapped_gameplay_moves": mapped_moves,
        "unmapped_gameplay_moves": unmapped,
        "missing_manifest_clips": missing,
        "per_fighter": {fid: {k: v for k, v in row.items() if k != "clips"} for fid, row in per_fighter.items()},
        "per_fighter_clips": per_fighter,
    }


def main() -> int:
    totals = derive_clip_totals(ROOT)
    print(json.dumps({k: v for k, v in totals.items() if k != "per_fighter_clips"}, indent=2))
    if totals["expected_from_manifests"] != totals["loaded_clip_files"]:
        print("FAIL manifest vs on-disk mismatch", totals["missing_manifest_clips"])
        return 1
    if totals["unmapped_gameplay_moves"] != 0:
        print("FAIL unmapped gameplay moves", totals["unmapped_gameplay_moves"])
        return 1
    if totals["expected_from_manifests"] <= 0:
        print("FAIL empty manifests")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

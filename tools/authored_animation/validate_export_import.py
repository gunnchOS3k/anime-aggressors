#!/usr/bin/env python3
"""Prove each fighter has a real GLB (glTF binary + animation), not a JSON dump."""
from __future__ import annotations

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)


def inspect_glb(path: Path) -> dict:
    raw = path.read_bytes()
    info = {
        "path": str(path.relative_to(ROOT)),
        "bytes": len(raw),
        "magic_ok": raw[:4] == b"glTF",
        "has_json_chunk": False,
        "has_bin_chunk": False,
        "animation_names": [],
        "node_count": 0,
        "skin_count": 0,
        "is_json_key_dump": False,
    }
    if not info["magic_ok"]:
        if raw[:1] == b"{":
            info["is_json_key_dump"] = True
        return info
    offset = 12
    while offset + 8 <= len(raw):
        (chunk_len,) = struct.unpack_from("<I", raw, offset)
        chunk_type = raw[offset + 4 : offset + 8]
        payload = raw[offset + 8 : offset + 8 + chunk_len]
        if chunk_type == b"JSON":
            info["has_json_chunk"] = True
            data = json.loads(payload)
            info["animation_names"] = [a.get("name") for a in data.get("animations", [])]
            info["node_count"] = len(data.get("nodes", []))
            info["skin_count"] = len(data.get("skins", []))
        elif chunk_type == b"BIN\x00":
            info["has_bin_chunk"] = True
        offset += 8 + chunk_len
    return info


def main() -> int:
    fails = []
    fighters = {}
    for fid in FIGHTERS:
        src = ROOT / f"art_source/animation/fighters/{fid}/export/pipeline_proof.glb"
        dst = ROOT / f"game-godot/assets/characters/authored/{fid}/pipeline_proof.glb"
        if not src.is_file():
            fails.append(f"missing source export {src}")
            continue
        if not dst.is_file():
            fails.append(f"missing godot copy {dst}")
        info = inspect_glb(src)
        fighters[fid] = info
        if info.get("is_json_key_dump"):
            fails.append(f"{fid} is a JSON key dump labeled as authored")
        if not info.get("magic_ok"):
            fails.append(f"{fid} not a GLB")
        if not info.get("has_bin_chunk"):
            fails.append(f"{fid} GLB missing BIN chunk")
        names = info.get("animation_names", [])
        if not names:
            fails.append(f"{fid} missing animations")
        if info.get("skin_count", 0) < 1:
            fails.append(f"{fid} missing skin")
        if info.get("bytes", 0) > 100 * 1024 * 1024:
            fails.append(f"{fid} GLB exceeds 100MB")
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighters": fighters,
        "not_final_art": True,
        "status": "AUTHORED_WIP",
        "human_approved": False,
    }
    out = ROOT / "artifacts/vxp3/reports/AUTHORED_EXPORT_IMPORT_PROOF.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

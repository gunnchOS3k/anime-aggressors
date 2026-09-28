#!/usr/bin/env python3
"""Mesh deformation audit: proxy + authored-proof skins exist; weights not claimed final."""
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


def glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    chunk_len = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20 : 20 + chunk_len])


def audit(path: Path) -> dict:
    if not path.is_file():
        return {"exists": False}
    data = glb_json(path)
    meshes = data.get("meshes", [])
    skins = data.get("skins", [])
    accessors = data.get("accessors", [])
    joints = 0
    for skin in skins:
        joints += len(skin.get("joints", []))
    return {
        "exists": True,
        "path": str(path.relative_to(ROOT)),
        "mesh_count": len(meshes),
        "skin_count": len(skins),
        "joint_count": joints,
        "accessor_count": len(accessors),
        "has_weights": any("WEIGHTS_0" in (p.get("attributes") or {}) for m in meshes for p in m.get("primitives", [])),
        "final_weights": False,
    }


def main() -> int:
    rows = []
    fails = []
    for fid in FIGHTERS:
        proxy = ROOT / f"game-godot/assets/characters/proxy/{fid}.glb"
        proof = ROOT / f"game-godot/assets/characters/authored/{fid}/pipeline_proof.glb"
        p = audit(proxy) if proxy.is_file() else {"exists": False}
        a = audit(proof)
        row = {"fighter_id": fid, "proxy": p, "authored_proof": a}
        rows.append(row)
        if not a.get("exists"):
            fails.append(f"{fid} missing authored proof GLB")
        elif not a.get("has_weights"):
            fails.append(f"{fid} authored proof has no WEIGHTS_0")
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighters": rows,
        "note": "Proxy weights are procedural. Authored proof is a skinned cylinder for import path, not final character art.",
        "AUTHORED_HURT_PASS": False,
        "final_character_weights": False,
    }
    out = ROOT / "artifacts/vxp3/reports/MESH_DEFORM_AUDIT.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

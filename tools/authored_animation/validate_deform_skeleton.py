#!/usr/bin/env python3
"""Validate canonical deform skeleton contract + optional GLB node names."""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json"


def read_contract() -> dict:
    return json.loads(CONTRACT.read_text())


def validate_contract(data: dict) -> list[str]:
    fails = []
    bones = data.get("required_bones", [])
    hierarchy = data.get("hierarchy", {})
    sockets = data.get("required_sockets", {})
    if len(bones) < 22:
        fails.append("required_bones < 22")
    if hierarchy.get("Root") is not None:
        fails.append("Root must have null parent")
    if hierarchy.get("Hips") != "Root":
        fails.append("Hips must parent to Root")
    for b in bones:
        if b != "Root" and b not in hierarchy:
            fails.append(f"missing hierarchy {b}")
    if "aura_root" not in sockets and "aura_root" not in data.get("required_sockets", []):
        fails.append("aura_root socket missing")
    if data.get("visual_root_motion_authoritative") is True:
        fails.append("visual root motion must not be authoritative")
    return fails


def glb_json(path: Path) -> dict:
    raw = path.read_bytes()
    if raw[:4] != b"glTF":
        raise ValueError("not glTF")
    chunk_len = struct.unpack_from("<I", raw, 12)[0]
    chunk_type = raw[16:20]
    if chunk_type != b"JSON":
        raise ValueError("first chunk not JSON")
    return json.loads(raw[20 : 20 + chunk_len])


def validate_glb(path: Path, required: list[str]) -> list[str]:
    fails = []
    data = glb_json(path)
    names = {n.get("name") for n in data.get("nodes", [])}
    missing = [b for b in required if b not in names]
    if missing:
        fails.append(f"{path.name} missing bones: {missing}")
    if not data.get("animations"):
        fails.append(f"{path.name} has no animations")
    if not data.get("skins"):
        fails.append(f"{path.name} has no skins")
    return fails


def main() -> int:
    contract = read_contract()
    fails = validate_contract(contract)
    required = contract.get("required_bones", [])
    authored = ROOT / "game-godot/assets/characters/authored"
    glb_checked = 0
    for glb in sorted(authored.glob("*/pipeline_proof.glb")):
        glb_checked += 1
        fails.extend(validate_glb(glb, required))
    payload = {
        "ok": not fails,
        "failures": fails,
        "glb_checked": glb_checked,
        "required_bones": required,
    }
    out = ROOT / "artifacts/vxp3/reports/AUTHORED_DEFORM_SKELETON.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

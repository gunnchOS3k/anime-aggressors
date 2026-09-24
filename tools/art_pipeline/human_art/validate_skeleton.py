#!/usr/bin/env python3
"""Validate the canonical deform skeleton contract and optional GLB node names."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ROOT, glb_json, load_skeleton, write_json  # noqa: E402


def validate_contract(data: dict) -> list[str]:
    fails = []
    bones = data.get("required_bones", [])
    hierarchy = data.get("hierarchy", {})
    sockets = data.get("required_sockets", [])
    if len(bones) < 22:
        fails.append("required_bones < 22")
    if hierarchy.get("Root") is not None:
        fails.append("Root must have null parent")
    if hierarchy.get("Hips") != "Root":
        fails.append("Hips must parent to Root")
    for bone in bones:
        if bone != "Root" and bone not in hierarchy:
            fails.append(f"missing hierarchy {bone}")
    if "aura_root" not in sockets:
        fails.append("aura_root socket missing")
    if data.get("visual_root_motion_authoritative") is True:
        fails.append("visual root motion must not be authoritative")
    return fails


def validate_glb(path: Path, required_bones: list[str], required_sockets: list[str]) -> list[str]:
    fails = []
    data = glb_json(path)
    names = {n.get("name") for n in data.get("nodes", [])}
    missing_bones = [b for b in required_bones if b not in names]
    if missing_bones:
        fails.append(f"{path.name} missing bones: {missing_bones}")
    missing_sockets = [s for s in required_sockets if s not in names]
    if missing_sockets:
        fails.append(f"{path.name} missing sockets: {missing_sockets}")
    if not data.get("skins"):
        fails.append(f"{path.name} has no skins")
    return fails


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset", default="", help="Optional GLB to check against the contract")
    args = parser.parse_args()
    contract = load_skeleton()
    fails = validate_contract(contract)
    glb_checked = 0
    if args.asset:
        asset = Path(args.asset)
        if not asset.is_file():
            fails.append(f"asset_missing:{asset}")
        else:
            glb_checked = 1
            fails.extend(
                validate_glb(
                    asset,
                    contract.get("required_bones", []),
                    contract.get("required_sockets", []),
                )
            )
    payload = {
        "ok": not fails,
        "failures": fails,
        "glb_checked": glb_checked,
        "required_bones": contract.get("required_bones", []),
        "required_sockets": contract.get("required_sockets", []),
        "ART_SKELETON_CONTRACT_PASS": not fails,
        "ART_SOCKET_CONTRACT_PASS": not any("socket" in f or "aura_root" in f for f in fails),
    }
    write_json(ROOT / "artifacts/art_pipeline/ART_SKELETON_CONTRACT.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())

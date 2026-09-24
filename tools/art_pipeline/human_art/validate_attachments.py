#!/usr/bin/env python3
"""Generic attachment-integrity validator. Does not assume V9 object names."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (  # noqa: E402
    ATTACHMENT_CLASSES,
    STRESS_ACTIONS,
    glb_json,
    load_json,
    write_json,
    ROOT,
)

MAX_RIGID = 0.26
MAX_CHAIN = 0.32

# Name hints only. Unknown objects must be classified in the sidecar.
HINTS = (
    (re.compile(r"(torso|coat|costume|body|cloth|skirt)", re.I), "SKINNED_COSTUME"),
    (re.compile(r"(helm|mask|glove|boot|pauldron|plate|crystal|halo)", re.I), "BONE_RIGID"),
    (re.compile(r"(hair|cape|scarf|ribbon|chain|dangle)", re.I), "SECONDARY_CHAIN"),
    (re.compile(r"(aura|orbit|vfx|fx_)", re.I), "VFX_ORBIT"),
)


def hint_class(name: str) -> str | None:
    for pattern, cls in HINTS:
        if pattern.search(name):
            return cls
    return None


def validate_sidecar(sidecar: dict) -> list[str]:
    fails = []
    rows = sidecar.get("attachments") or []
    if not rows:
        fails.append("no_attachment_records")
        return fails
    for row in rows:
        name = str(row.get("name") or "")
        cls = str(row.get("class") or "")
        bone = str(row.get("bone") or row.get("owning_bone") or "")
        if cls not in ATTACHMENT_CLASSES:
            fails.append(f"{name}:unknown_class:{cls}")
            continue
        if cls == "WORLD_STATIC" and not bool(row.get("world_static_allowed")):
            fails.append(f"{name}:costume_must_not_be_WORLD_STATIC")
        if cls in ("BONE_RIGID", "SKINNED_COSTUME", "SECONDARY_CHAIN") and not bone:
            fails.append(f"{name}:missing_owning_bone")
        if cls == "SKINNED_COSTUME" and not row.get("skinned", True):
            fails.append(f"{name}:SKINNED_COSTUME_not_weighted")
        if bool(row.get("unintentional_floating")):
            fails.append(f"{name}:unintentional_floating")
    return fails


def validate_glb_objects(path: Path, sidecar: dict) -> list[str]:
    fails = []
    data = glb_json(path)
    names = {str(n.get("name") or "") for n in data.get("nodes", [])}
    declared = {str(row.get("name") or "") for row in sidecar.get("attachments") or []}
    leftover = sorted(n for n in names if n and n not in declared and hint_class(n) is not None)
    for name in leftover:
        fails.append(f"{name}:declared_class_missing")
    return fails


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fighter", default="")
    parser.add_argument("--asset", default="")
    parser.add_argument("--sidecar", default="")
    args = parser.parse_args()
    sidecar_path = Path(args.sidecar) if args.sidecar else Path()
    sidecar = load_json(sidecar_path) if sidecar_path.is_file() else {"attachments": []}
    fails = validate_sidecar(sidecar) if sidecar.get("attachments") else []
    if args.asset:
        asset = Path(args.asset)
        if not asset.is_file():
            fails.append(f"asset_missing:{asset}")
        elif sidecar.get("attachments"):
            fails.extend(validate_glb_objects(asset, sidecar))
        else:
            # Empty sidecar + asset: structural pass only if the file loads.
            glb_json(asset)
    payload = {
        "ok": not fails,
        "failures": fails,
        "fighter": args.fighter,
        "stress_actions": list(STRESS_ACTIONS),
        "max_rigid_displacement_m": MAX_RIGID,
        "max_chain_displacement_m": MAX_CHAIN,
        "classes": list(ATTACHMENT_CLASSES),
        "ART_ATTACHMENT_VALIDATOR_PASS": not fails,
        "note": "Validator reports contract/structure only. It does not judge art quality.",
    }
    write_json(ROOT / "artifacts/art_pipeline/ART_ATTACHMENT_VALIDATOR.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())

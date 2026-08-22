#!/usr/bin/env python3
"""Validate user motion upload — structural parsing for BVH, JSON schemas, GLB header."""
from __future__ import annotations

import json
import mimetypes
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))
RAW_DIR = ROOT / "local/user_motion/raw"
MAX_BYTES = 50 * 1024 * 1024
ALLOWED_EXT = {".json", ".bvh", ".glb", ".fbx", ".txt", ".csv"}


def _path_allowed(path: Path) -> bool:
    try:
        return path.resolve().is_relative_to(RAW_DIR.resolve())
    except (ValueError, OSError):
        return False


def validate_json_structure(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return {"ok": True, "type": type(data).__name__}
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": str(exc)}


def validate_bvh_structure(path: Path) -> dict:
    from tools.motion_pipeline.formats.bvh_parser import validate_bvh_structure as bvh_val

    return bvh_val(path)


def validate_glb_header(path: Path) -> dict:
    header = path.read_bytes()[:12]
    if len(header) < 12:
        return {"ok": False, "error": "truncated_glb"}
    magic, version, length = struct.unpack("<4sII", header)
    if magic != b"glTF":
        return {"ok": False, "error": "invalid_glb_magic"}
    return {"ok": True, "version": version, "declared_length": length}


def validate(path: Path) -> dict:
    if not path.exists():
        return {"ok": False, "error": "missing_file"}
    if not _path_allowed(path):
        return {"ok": False, "error": "path_outside_gitignored_raw_dir"}
    if path.is_symlink():
        return {"ok": False, "error": "symlinks_forbidden"}
    size = path.stat().st_size
    if size > MAX_BYTES:
        return {"ok": False, "error": "file_too_large", "max_bytes": MAX_BYTES}
    ext = path.suffix.lower()
    if ext not in ALLOWED_EXT:
        return {"ok": False, "error": "extension_not_allowed", "allowed": sorted(ALLOWED_EXT)}
    mime, _ = mimetypes.guess_type(str(path))
    structural: dict = {"checked": False}
    if ext == ".json":
        structural = validate_json_structure(path)
    elif ext == ".bvh":
        structural = validate_bvh_structure(path)
    elif ext == ".glb":
        structural = validate_glb_header(path)
    else:
        structural = {"ok": True, "note": "extension_allowlist_only"}
    return {
        "ok": structural.get("ok", True),
        "size_bytes": size,
        "extension": ext,
        "mime_guess": mime,
        "structural_validation": structural,
        "raw_committed_to_git": False,
        "biometric_inference": False,
    }


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--fixture-bvh", action="store_true")
    args = parser.parse_args()

    if args.fixture_bvh:
        fixture = ROOT / "tools/motion_pipeline/fixtures/sample_humanoid.bvh"
        result = validate_bvh_structure(fixture)
        print(json.dumps({**result, "BVH_VALIDATION_READY": result.get("ok", False)}))
        return 0

    if args.input is None:
        print(json.dumps({"ok": True, "mode": "ready", "raw_dir": "local/user_motion/raw"}))
        return 0
    result = validate(args.input)
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

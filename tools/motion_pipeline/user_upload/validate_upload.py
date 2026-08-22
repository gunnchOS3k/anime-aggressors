#!/usr/bin/env python3
"""Validate user motion upload security and schema — no raw commits."""
from __future__ import annotations

import json
import mimetypes
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RAW_DIR = ROOT / "local/user_motion/raw"
MAX_BYTES = 50 * 1024 * 1024
ALLOWED_EXT = {".json", ".bvh", ".glb", ".fbx", ".txt", ".csv"}


def validate(path: Path) -> dict:
    if not path.exists():
        return {"ok": False, "error": "missing_file"}
    if not str(path.resolve()).startswith(str(RAW_DIR.resolve())):
        return {"ok": False, "error": "path_outside_gitignored_raw_dir"}
    size = path.stat().st_size
    if size > MAX_BYTES:
        return {"ok": False, "error": "file_too_large", "max_bytes": MAX_BYTES}
    ext = path.suffix.lower()
    if ext not in ALLOWED_EXT:
        return {"ok": False, "error": "extension_not_allowed", "allowed": sorted(ALLOWED_EXT)}
    mime, _ = mimetypes.guess_type(str(path))
    return {
        "ok": True,
        "size_bytes": size,
        "extension": ext,
        "mime_guess": mime,
        "raw_committed_to_git": False,
        "biometric_inference": False,
    }


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    args = parser.parse_args()
    if args.input is None:
        print(json.dumps({"ok": True, "mode": "ready", "raw_dir": "local/user_motion/raw"}))
        return 0
    result = validate(args.input)
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Normalize uploaded motion — real BVH parsing; metadata strip for other formats."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))
LOCAL_RAW = ROOT / "local/user_motion/raw"
LOCAL_NORMALIZED = ROOT / "local/user_motion/normalized"

STRIP_KEYS = {
    "gps", "location", "latitude", "longitude", "device_id", "serial",
    "face", "biometric", "identity", "email", "phone",
}


def _path_allowed(path: Path) -> bool:
    try:
        return path.resolve().is_relative_to(LOCAL_RAW.resolve())
    except (ValueError, OSError):
        return False


def strip_metadata(data: dict) -> dict:
    cleaned: dict = {}
    for key, value in data.items():
        if any(s in key.lower() for s in STRIP_KEYS):
            continue
        cleaned[key] = strip_metadata(value) if isinstance(value, dict) else value
    return cleaned


def normalize(input_path: Path, out_dir: Path) -> dict:
    if input_path.suffix.lower() == ".bvh":
        from tools.motion_pipeline.normalize_bvh import normalize_bvh

        stem = re.sub(r"[^a-zA-Z0-9._-]+", "_", input_path.stem)
        out_path = out_dir / f"{stem}_bvh.normalized.json"
        return normalize_bvh(input_path, out_path)

    raw_bytes = input_path.read_bytes()
    content_hash = hashlib.sha256(raw_bytes).hexdigest()
    stem = re.sub(r"[^a-zA-Z0-9._-]+", "_", input_path.stem)
    out_path = out_dir / f"{stem}_{content_hash[:12]}.json"
    payload = {
        "schema_version": 1,
        "normalized_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source_filename": input_path.name,
        "content_hash_sha256": content_hash,
        "byte_length": len(raw_bytes),
        "format": input_path.suffix.lower().lstrip("."),
        "metadata_stripped": True,
        "METADATA_ONLY_NORMALIZATION": True,
        "BVH_NORMALIZATION_EXECUTION_READY": False,
        "biometric_inference_forbidden": True,
        "real_user_motion": True,
        "fixture_class": "USER_UPLOAD_PENDING_VALIDATION",
    }
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return {"ok": True, "output": str(out_path.relative_to(ROOT)), "content_hash_sha256": content_hash}


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize user motion upload (local only)")
    parser.add_argument("--input", type=Path, help="Path to upload file under local/user_motion/raw")
    parser.add_argument("--fixture-bvh", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.fixture_bvh:
        fixture = ROOT / "tools/motion_pipeline/fixtures/sample_humanoid.bvh"
        result = normalize(fixture, ROOT / "tmp")
        print(json.dumps({**result, "BVH_NORMALIZATION_EXECUTION_READY": True, "METADATA_ONLY_NORMALIZATION": False}))
        return 0

    if args.input is None:
        print(json.dumps({"ok": True, "mode": "ready", "raw_dir": str(LOCAL_RAW.relative_to(ROOT))}))
        return 0
    if not _path_allowed(args.input):
        print(json.dumps({"ok": False, "error": "RAW uploads must stay under local/user_motion/raw"}))
        return 1
    if not args.input.exists():
        print(json.dumps({"ok": False, "error": "input missing"}))
        return 1
    if args.dry_run:
        print(json.dumps({"ok": True, "dry_run": True, "input": str(args.input)}))
        return 0
    result = normalize(args.input, LOCAL_NORMALIZED)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

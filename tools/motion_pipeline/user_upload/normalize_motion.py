#!/usr/bin/env python3
"""Normalize uploaded motion metadata — privacy-first, no biometric inference."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
LOCAL_RAW = ROOT / "local/user_motion/raw"
LOCAL_NORMALIZED = ROOT / "local/user_motion/normalized"

STRIP_KEYS = {
    "gps",
    "location",
    "latitude",
    "longitude",
    "device_id",
    "serial",
    "face",
    "biometric",
    "identity",
    "email",
    "phone",
}


def strip_metadata(data: dict) -> dict:
    cleaned: dict = {}
    for key, value in data.items():
        if any(s in key.lower() for s in STRIP_KEYS):
            continue
        if isinstance(value, dict):
            cleaned[key] = strip_metadata(value)
        else:
            cleaned[key] = value
    return cleaned


def normalize(input_path: Path, out_dir: Path) -> dict:
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
        "metadata_stripped": True,
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
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.input is None:
        print(json.dumps({"ok": True, "mode": "ready", "raw_dir": str(LOCAL_RAW.relative_to(ROOT))}))
        return 0
    if not str(args.input.resolve()).startswith(str(LOCAL_RAW.resolve())):
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

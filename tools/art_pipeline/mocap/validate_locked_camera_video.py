#!/usr/bin/env python3
"""Validate locked-camera mocap plate metadata (no paid cloud)."""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("meta_json", type=Path)
    args = ap.parse_args()
    meta = json.loads(args.meta_json.read_text())
    errors = []
    if meta.get("camera_mode") != "locked":
        errors.append("camera_mode must be locked")
    if not meta.get("tpose_bookends", False):
        errors.append("tpose_bookends required")
    if int(meta.get("performers", 0)) not in (1, 2):
        errors.append("performers must be 1 or 2")
    out = {"pass": not errors, "errors": errors}
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 2

if __name__ == "__main__":
    raise SystemExit(main())

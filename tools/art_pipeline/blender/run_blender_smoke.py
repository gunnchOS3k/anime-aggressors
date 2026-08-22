#!/usr/bin/env python3
"""Blender CLI smoke: verify Blender can run headless and load pipeline scripts."""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BLENDER = Path("/Applications/Blender.app/Contents/MacOS/Blender")
OUT = ROOT / "artifacts/wave012/BLENDER_PIPELINE_SMOKE.json"


def main() -> int:
    script = ROOT / "tools/art_pipeline/blender/normalize_character.py"
    result = {
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "blender_path": str(BLENDER),
        "blender_present": BLENDER.exists(),
        "script": str(script.relative_to(ROOT)),
        "smoke_ok": False,
        "version": None,
        "log_tail": "",
    }
    if not BLENDER.exists():
        result["error"] = "Blender not found"
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result, indent=2))
        return 1
    ver = subprocess.run([str(BLENDER), "--version"], capture_output=True, text=True)
    result["version"] = (ver.stdout or "").splitlines()[0] if ver.stdout else None
    # Headless execute normalize script in dry-run mode
    cmd = [
        str(BLENDER), "--background", "--python", str(script), "--",
        "--dry-run", "--report", str(ROOT / "artifacts/wave012/BLENDER_NORMALIZE_DRY_RUN.json"),
    ]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    result["log_tail"] = ((p.stdout or "") + (p.stderr or ""))[-2000:]
    result["smoke_ok"] = p.returncode == 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"smoke_ok": result["smoke_ok"], "version": result["version"]}, indent=2))
    return 0 if result["smoke_ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

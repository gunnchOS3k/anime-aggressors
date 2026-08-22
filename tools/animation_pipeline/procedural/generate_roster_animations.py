#!/usr/bin/env python3
"""Generate procedural runtime animations for the full roster."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "tools/animation_pipeline/procedural/generate_fighter_animations.py"
sys.path.insert(0, str(ROOT / "tools/animation_pipeline/procedural"))
from _common import FIGHTERS  # noqa: E402


def main() -> int:
    records = []
    total_clips = 0
    signature_clips = 0
    for fighter_id in FIGHTERS:
        proc = subprocess.run(
            [sys.executable, str(SCRIPT), fighter_id],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            print(proc.stderr or proc.stdout, file=sys.stderr)
            return proc.returncode
        manifest = json.loads(proc.stdout)
        records.append(manifest)
        total_clips += int(manifest.get("clip_count", 0))
        signature_clips += int(manifest.get("signature_clip_count", 0))

    out = {
        "pass": total_clips >= 315 and all(r.get("clip_count", 0) >= 45 for r in records) and signature_clips >= 56,
        "fighter_count": len(records),
        "total_clips": total_clips,
        "signature_clips": signature_clips,
        "fighters": records,
        "PROCEDURAL_RUNTIME_ANIMATION_PASS": total_clips >= 315,
        "status": "PROCEDURAL_RUNTIME_ANIMATION",
    }
    dest = ROOT / "artifacts/engineering_wave014/PROCEDURAL_ANIMATION_RESULT.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

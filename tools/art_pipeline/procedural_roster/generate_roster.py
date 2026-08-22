#!/usr/bin/env python3
"""Generate all seven procedural roster production-proxy fighters."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "tools/art_pipeline/procedural_roster/generate_character.py"


def main() -> int:
    fighters = [
        "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
        "nix-calder", "orion-vell", "vesper-nyx",
    ]
    records = []
    for fighter_id in fighters:
        proc = subprocess.run(
            [sys.executable, str(SCRIPT), fighter_id],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            print(proc.stderr or proc.stdout, file=sys.stderr)
            return proc.returncode
        records.append(json.loads(proc.stdout))
    manifest = {
        "schema_version": 1,
        "status": "PROCEDURAL_PRODUCTION_PROXY",
        "fighter_count": len(records),
        "fighters": records,
    }
    dest = ROOT / "artifacts/engineering_wave014/PROCEDURAL_CHARACTER_RESULT.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "fighter_count": len(records)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

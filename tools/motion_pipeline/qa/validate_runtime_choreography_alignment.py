#!/usr/bin/env python3
"""Validate runtime_alignment blocks on all choreography specs."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "artifacts/engineering_wave013b/RUNTIME_CHOREOGRAPHY_ALIGNMENT.json"


def main() -> int:
    choreo = ROOT / "content/choreography"
    specs = []
    missing_alignment = []
    for path in sorted(choreo.glob("*/*.json")):
        if path.name in {"index.json", "action_spec.schema.json", "fighter_motion_blueprints.json"}:
            continue
        spec = json.loads(path.read_text(encoding="utf-8"))
        specs.append(spec)
        ra = spec.get("runtime_alignment")
        if not ra or not ra.get("moves_json_key"):
            missing_alignment.append(spec["action_id"])

    aligned = len(specs) - len(missing_alignment)
    out = {
        "total_specs": len(specs),
        "aligned_specs": aligned,
        "missing_alignment": missing_alignment[:20],
        "missing_count": len(missing_alignment),
        "pass": len(missing_alignment) == 0,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

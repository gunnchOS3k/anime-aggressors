#!/usr/bin/env python3
"""Motion QA for reference animatics and synthetic fixtures."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def qa_timeline(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    events = data.get("events", [])
    frames = [e.get("frame", -1) for e in events]
    monotonic = all(frames[i] <= frames[i + 1] for i in range(len(frames) - 1)) if frames else False
    kind = data.get("kind", "")
    return {
        "path": str(path.relative_to(ROOT)),
        "ok": monotonic and kind in ("REFERENCE_ANIMATIC", "PROTOTYPE_ANIMATION"),
        "event_count": len(events),
        "final_animation_claimed": data.get("provenance", {}).get("final_animation", True) is True,
    }


def main() -> int:
    ref_root = ROOT / "tools/motion_pipeline/reference_animation"
    results = []
    for path in sorted(ref_root.rglob("*.json")):
        results.append(qa_timeline(path))
    failed = [r for r in results if not r["ok"] or r["final_animation_claimed"]]
    out = {
        "checked": len(results),
        "failed": len(failed),
        "pass": len(failed) == 0 and len(results) >= 91,
        "results_sample": results[:5],
    }
    dest = ROOT / "artifacts/wave013b/MOTION_QA.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

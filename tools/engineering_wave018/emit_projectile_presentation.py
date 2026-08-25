#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import emit_wave018_bundle as b
if __name__ == "__main__":
    ART = Path(__file__).resolve().parents[2] / "artifacts" / "engineering_wave018"
    ART.mkdir(parents=True, exist_ok=True)
    out = b.emit_projectile()
    if out is not None:
        import json
        print(json.dumps(out if isinstance(out, dict) else {"ok": True}, indent=2))

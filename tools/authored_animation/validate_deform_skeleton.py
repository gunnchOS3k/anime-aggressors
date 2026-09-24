#!/usr/bin/env python3
"""Validate canonical deform skeleton contract + optional human/authored GLB."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art_pipeline/human_art"))
from validate_skeleton import main as _main  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(_main())

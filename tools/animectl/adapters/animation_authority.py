"""Thin adapter: wrap animation_authority validators."""
from __future__ import annotations

from pathlib import Path

from ..process import run


def validate_playable_v1_3(root: Path):
    script = root / "tools/animation_authority/validate_playable_runtime_v1_3.py"
    if not script.exists():
        return None
    return run(["python3", str(script)], cwd=root)

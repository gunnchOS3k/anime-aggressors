"""Blender adapter — wraps repo-owned tools/blender scripts."""
from __future__ import annotations

from pathlib import Path


def blender_pipeline_present(root: Path) -> bool:
    return (root / "tools/blender").is_dir()

"""Existing engineering-wave tool discovery stub."""
from __future__ import annotations

from pathlib import Path


def list_wave_tools(root: Path) -> list[str]:
    tools = root / "tools"
    return sorted(p.name for p in tools.glob("engineering_wave*") if p.is_dir())

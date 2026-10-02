"""Maestro adapter — optional host-side Android UI driver."""
from __future__ import annotations

import shutil
from pathlib import Path


def maestro_present() -> bool:
    return shutil.which("maestro") is not None


def flow_dir(root: Path) -> Path:
    return root / ".maestro" / "anime"

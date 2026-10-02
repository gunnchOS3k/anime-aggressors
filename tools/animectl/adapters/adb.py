"""ADB adapter — thin consolidation over existing device scripts."""
from __future__ import annotations

from pathlib import Path

from ..adb_probe import probe_adb


def list_devices(root: Path) -> list[str]:
    return list(probe_adb(root).devices)

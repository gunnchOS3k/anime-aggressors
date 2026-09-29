"""ADB adapter — thin consolidation over existing device scripts."""
from __future__ import annotations

from pathlib import Path

from ..process import run


def list_devices(root: Path) -> list[str]:
    cp = run(["adb", "devices"], cwd=root)
    out = []
    for ln in (cp.stdout or "").splitlines()[1:]:
        parts = ln.split()
        if len(parts) >= 2 and parts[1] == "device":
            out.append(parts[0])
    return out

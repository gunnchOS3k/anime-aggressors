"""Process helpers."""
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Sequence


def run(cmd: Sequence[str], cwd: Path, timeout: int | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(list(cmd), cwd=cwd, text=True, capture_output=True, timeout=timeout)

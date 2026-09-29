"""Process helpers."""
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Sequence


def run(cmd: Sequence[str], cwd: Path, timeout: int | None = None) -> subprocess.CompletedProcess[str]:
    argv = list(cmd)
    try:
        return subprocess.run(argv, cwd=cwd, text=True, capture_output=True, timeout=timeout)
    except FileNotFoundError as exc:
        # Digital CI often lacks optional binaries (adb). Never crash the control plane.
        return subprocess.CompletedProcess(
            args=argv,
            returncode=127,
            stdout="",
            stderr=f"FileNotFoundError: {exc}",
        )

#!/usr/bin/env python3
"""Ensure no raw user motion uploads are tracked by git."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FORBIDDEN_PREFIXES = [
    ROOT / "local/user_motion",
    ROOT / "user_motion_uploads",
]
EXECUTABLE_SUFFIXES = {".exe", ".sh", ".bat", ".cmd", ".app"}


def git_tracked_files() -> list[str]:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    return [line.strip() for line in out.splitlines() if line.strip()]


def is_under_forbidden(path: Path) -> bool:
    resolved = path.resolve()
    for prefix in FORBIDDEN_PREFIXES:
        try:
            if resolved.is_relative_to(prefix.resolve()):
                return True
        except ValueError:
            continue
    return False


def main() -> int:
    tracked_violations = []
    symlink_escapes = []
    executable_violations = []

    for rel in git_tracked_files():
        path = ROOT / rel
        if is_under_forbidden(path):
            tracked_violations.append(rel)
        if path.is_symlink():
            target = path.resolve()
            if not target.is_relative_to(ROOT.resolve()):
                symlink_escapes.append(rel)
        if path.suffix.lower() in EXECUTABLE_SUFFIXES and "tools/" not in rel:
            executable_violations.append(rel)

    out = {
        "RAW_USER_UPLOADS_TRACKED_BY_GIT": len(tracked_violations),
        "tracked_violations": tracked_violations,
        "symlink_escapes": symlink_escapes,
        "executable_violations": executable_violations,
        "path_containment": "resolve().is_relative_to()",
        "pass": len(tracked_violations) == 0 and len(symlink_escapes) == 0,
    }
    dest = ROOT / "artifacts/engineering_wave013b/RAW_USER_MOTION_GIT_CHECK.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

"""Git exact-head truth helpers."""
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Any


def run_git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def git_truth(root: Path) -> dict[str, Any]:
    sha = run_git(root, "rev-parse", "HEAD")
    branch = run_git(root, "rev-parse", "--abbrev-ref", "HEAD")
    dirty = bool(run_git(root, "status", "--porcelain"))
    try:
        base = run_git(root, "merge-base", "HEAD", "origin/main")
    except Exception:
        base = ""
    return {
        "repo": "gunnchOS3k/anime-aggressors",
        "branch": branch,
        "git_sha": sha,
        "git_dirty": dirty,
        "base_main_merge_base": base,
    }


def assert_exact_head(artifact: dict[str, Any], current_sha: str) -> tuple[bool, str]:
    claimed = artifact.get("git_sha") or artifact.get("head_sha") or artifact.get("head")
    if not claimed:
        return False, "artifact missing git_sha/head_sha"
    if str(claimed) != str(current_sha):
        return False, f"stale evidence: artifact={claimed} current={current_sha}"
    return True, "exact-head match"

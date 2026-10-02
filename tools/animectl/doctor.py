"""animectl doctor — toolchain + disk."""
from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

from .git_truth import git_truth
from .result import EXIT_ENV_MISSING, EXIT_OK, AnimectlResult


def _which(name: str) -> str | None:
    return shutil.which(name)


def _version(cmd: list[str]) -> str:
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT, timeout=10)
        return out.strip().splitlines()[0][:120]
    except Exception as exc:
        return f"error:{exc}"


def disk_free(path: Path) -> dict[str, Any]:
    usage = shutil.disk_usage(path)
    return {
        "disk_free_bytes": usage.free,
        "disk_free_human": f"{usage.free / (1024**3):.2f} GiB",
        "disk_total_human": f"{usage.total / (1024**3):.2f} GiB",
        "android_build_space_risk": usage.free < 4 * 1024**3,
        "blender_build_space_risk": usage.free < 2 * 1024**3,
    }


SAFE_CLEAN_GLOBS = [
    "apps/web/dist/**",
    "apps/web/node_modules/.vite/**",
    "packages/*/dist/**",
    ".acceptance/**",
    "tmp/**",
    "**/__pycache__/**",
]


def safe_clean(root: Path) -> list[str]:
    removed: list[str] = []
    targets = [
        root / "apps/web/dist",
        root / ".acceptance",
        root / "tmp",
    ]
    for pkg in (root / "packages").glob("*/dist"):
        targets.append(pkg)
    vite = root / "apps/web/node_modules/.vite"
    if vite.exists():
        targets.append(vite)
    for t in targets:
        if t.exists():
            if t.is_file():
                t.unlink()
            else:
                shutil.rmtree(t, ignore_errors=True)
            removed.append(str(t.relative_to(root)))
    return removed


def run_doctor(root: Path, *, safe_clean_flag: bool = False) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command="doctor", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    tools = {
        "git": (_which("git"), ["git", "--version"]),
        "node": (_which("node"), ["node", "--version"]),
        "npm": (_which("npm"), ["npm", "--version"]),
        "python3": (_which("python3"), ["python3", "--version"]),
        "ffmpeg": (_which("ffmpeg"), ["ffmpeg", "-version"]),
        "adb": (_which("adb"), ["adb", "version"]),
        "blender": (_which("blender") or _which("/Applications/Blender.app/Contents/MacOS/Blender"), None),
        "godot": (_which("godot") or _which("Godot"), None),
        "java": (_which("java"), ["java", "-version"]),
        "maestro": (_which("maestro"), ["maestro", "--version"]),
        "playwright": (_which("playwright"), ["playwright", "--version"]),
    }
    versions: dict[str, Any] = {}
    for name, (path, ver_cmd) in tools.items():
        if not path:
            versions[name] = {"status": "MISSING", "path": None, "version": None}
            optional = name in {"blender", "godot", "maestro", "playwright", "adb", "java", "ffmpeg"}
            res.add_check(
                f"TOOL_{name.upper()}",
                "PASS_WITH_NOTES" if optional else "FAIL",
                "OPTIONAL_MISSING" if optional else "REQUIRED_MISSING",
            )
            if not optional:
                res.exit_code = EXIT_ENV_MISSING
                res.status = "FAIL"
        else:
            ver = _version(ver_cmd) if ver_cmd else "FOUND"
            versions[name] = {"status": "FOUND", "path": path, "version": ver}
            res.add_check(f"TOOL_{name.upper()}", "PASS", ver)
    disk = disk_free(root)
    versions["disk"] = disk
    res.tool_versions = versions
    res.data["largest_regenerable_repo_caches"] = [
        "apps/web/dist",
        "packages/*/dist",
        ".acceptance/",
        "tmp/",
        "apps/web/node_modules/.vite",
    ]
    res.add_check(
        "DISK_FREE",
        "PASS_WITH_NOTES" if disk["android_build_space_risk"] else "PASS",
        disk["disk_free_human"],
    )
    if safe_clean_flag:
        removed = safe_clean(root)
        res.data["safe_clean_removed"] = removed
        res.add_check("SAFE_CLEAN", "PASS", f"removed {len(removed)} regenerable paths")
        res.tool_versions["disk_after_clean"] = disk_free(root)
    if res.status == "PASS" or res.status == "PASS_WITH_NOTES":
        res.exit_code = EXIT_OK
    return res

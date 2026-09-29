#!/usr/bin/env python3
"""Stamp review/dev build identity at export time. Never writes UNKNOWN when git is available."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

REPO_DEFAULT = "gunnchOS3k/anime-aggressors"
PACKAGE_DEFAULT = "com.gunnchos.animeaggressors"
OUT_DEFAULT = "game-godot/data/runtime/build_identity.json"


def _git(repo: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=repo, text=True).strip()


def _parse_export_version(presets: Path) -> tuple[str, int]:
    name = "0.0.0"
    code = 0
    if not presets.is_file():
        return name, code
    for line in presets.read_text(encoding="utf-8").splitlines():
        if line.startswith("version/name="):
            name = line.split("=", 1)[1].strip().strip('"')
        elif line.startswith("version/code="):
            try:
                code = int(line.split("=", 1)[1].strip())
            except ValueError:
                code = 0
    return name, code


def generate(repo_root: Path, flavor: str) -> dict:
    # Prefer GITHUB_SHA on Actions so detached/checkout SHA is exact-head.
    env_sha = (os.environ.get("GITHUB_SHA") or "").strip()
    if env_sha:
        sha = env_sha
        short = env_sha[:12]
    else:
        sha = _git(repo_root, "rev-parse", "HEAD")
        if not sha or sha.upper() == "UNKNOWN":
            raise SystemExit("build identity refused to embed UNKNOWN SHA")
        short = _git(repo_root, "rev-parse", "--short=12", "HEAD")
    try:
        ref = _git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
    except subprocess.CalledProcessError:
        ref = "DETACHED"
    if os.environ.get("GITHUB_REF_NAME"):
        ref = os.environ["GITHUB_REF_NAME"]
    version_name, version_code = _parse_export_version(repo_root / "game-godot" / "export_presets.cfg")
    build_source = "github_actions" if os.environ.get("GITHUB_ACTIONS") == "true" else "local"
    workflow_run_id = os.environ.get("GITHUB_RUN_ID") or ""
    return {
        "repo": REPO_DEFAULT,
        "git_sha": sha,
        "git_sha_short": short,
        "git_short_sha": short,
        "ref": ref,
        "version_name": version_name,
        "version_code": version_code,
        "build_timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "build_flavor": flavor,
        "build_source": build_source,
        "workflow_run_id": workflow_run_id,
        "package_id": PACKAGE_DEFAULT,
        "watermark": f"AA {short}",
    }


def write_identity(repo_root: Path, out: Path, flavor: str) -> dict:
    payload = generate(repo_root, flavor)
    if payload["git_sha"].upper() == "UNKNOWN":
        raise SystemExit("build identity refused to write UNKNOWN SHA")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--out", default=OUT_DEFAULT)
    parser.add_argument("--flavor", default="owner-review-debug")
    args = parser.parse_args()
    repo_root = Path(args.repo_root).resolve()
    out = Path(args.out)
    if not out.is_absolute():
        out = repo_root / out
    payload = write_identity(repo_root, out, args.flavor)
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

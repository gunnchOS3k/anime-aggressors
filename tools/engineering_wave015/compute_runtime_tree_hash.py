#!/usr/bin/env python3
"""Compute deterministic tree hash over runtime-affecting paths."""
from __future__ import annotations

import fnmatch
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = Path(__file__).resolve().parent / "runtime_affecting_paths.json"


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def git_ls_files() -> list[str]:
    out = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    return [p.decode() for p in out.split(b"\0") if p]


def excluded(path: str, excludes: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pat) for pat in excludes)


def included(path: str, includes: list[str], excludes: list[str]) -> bool:
    if excluded(path, excludes):
        return False
    return any(fnmatch.fnmatch(path, pat) for pat in includes)


def tree_hash(paths: list[str]) -> str:
    h = hashlib.sha256()
    for rel in sorted(paths):
        full = ROOT / rel
        if not full.is_file():
            continue
        blob = full.read_bytes()
        h.update(rel.encode())
        h.update(b"\0")
        h.update(hashlib.sha256(blob).digest())
    return h.hexdigest()


def main() -> int:
    manifest = load_manifest()
    includes = manifest.get("include_globs", [])
    excludes = manifest.get("exclude_globs", [])
    tracked = [p for p in git_ls_files() if included(p, includes, excludes)]
    digest = tree_hash(tracked)
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    out = {
        "schema": "engineering_wave015.runtime_tree_hash.v1",
        "HEAD_SHA": head,
        "RUNTIME_TREE_HASH": digest,
        "tracked_file_count": len(tracked),
        "manifest": str(MANIFEST.relative_to(ROOT)),
    }
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

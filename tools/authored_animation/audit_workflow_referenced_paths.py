#!/usr/bin/env python3
"""Fail if workflow run steps invoke missing repository scripts.

Checks interpreter-invoked paths (python3/bash/node/…) and PYTHONPATH=tools
style imports. Skips build/evidence outputs (dist/, out/, artifacts/).

Emits WORKFLOW_REFERENCED_PATHS_EXIST_PASS. No PyYAML dependency.
Does not weaken human/final-art gates.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
REPORT = ROOT / "artifacts" / "vxp3" / "reports" / "WORKFLOW_REFERENCED_PATHS.json"

# Longer extensions first so ".json" is not truncated to ".js".
EXT = r"(?:json|mjs|cjs|tsx|ts|py|sh|gd|js)"
RUN_FILE_RE = re.compile(
    rf"(?:^|[\s;|&])(?:python3?|bash|sh|node|tsx|npx)\s+([A-Za-z0-9_./-]+\.{EXT})",
    re.MULTILINE,
)
IMPORT_RE = re.compile(
    r"""from\s+([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+)\s+import""",
)
IMPORT_PREFIXES = (
    "generated_production_art",
    "generated_art",
    "authored_animation",
    "art_pipeline",
)
OUTPUT_MARKERS = (
    "/dist/",
    "/out/",
    "/artifacts/",
    "/node_modules/",
)


def _normalize(raw: str) -> str | None:
    path = raw.strip().strip("'\"`")
    if not path:
        return None
    if path.startswith("./"):
        path = path[2:]
    if path.startswith("/") or "://" in path or "${{" in path:
        return None
    for marker in OUTPUT_MARKERS:
        if marker in f"/{path}":
            return None
    return path


def extract_from_text(text: str) -> set[str]:
    found: set[str] = set()
    for match in RUN_FILE_RE.finditer(text):
        norm = _normalize(match.group(1))
        if norm:
            found.add(norm)
    for match in IMPORT_RE.finditer(text):
        mod = match.group(1)
        if not mod.startswith(IMPORT_PREFIXES):
            continue
        parts = mod.split(".")
        candidate = str(Path("tools", *parts[:-1], parts[-1] + ".py"))
        norm = _normalize(candidate)
        if norm:
            found.add(norm)
    return found


def iter_workflow_run_bodies(path: Path) -> list[str]:
    """Collect indented run: | / > blocks without a YAML parser."""
    lines = path.read_text(encoding="utf-8").splitlines()
    bodies: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        if stripped.startswith("run:"):
            indent = len(line) - len(stripped)
            rest = stripped[4:].strip()
            if rest in ("|", ">", "|-", ">-", "|+", ">+"):
                chunk: list[str] = []
                i += 1
                while i < len(lines):
                    nxt = lines[i]
                    if nxt.strip() == "":
                        chunk.append(nxt)
                        i += 1
                        continue
                    nxt_indent = len(nxt) - len(nxt.lstrip())
                    if nxt_indent <= indent:
                        break
                    chunk.append(nxt)
                    i += 1
                bodies.append("\n".join(chunk))
                continue
            if rest:
                bodies.append(rest)
        i += 1
    return bodies


def main() -> int:
    missing: list[dict] = []
    checked: list[dict] = []
    if not WORKFLOWS.is_dir():
        print("missing .github/workflows", file=sys.stderr)
        return 1
    for wf in sorted(WORKFLOWS.glob("*.yml")) + sorted(WORKFLOWS.glob("*.yaml")):
        refs: set[str] = set()
        for body in iter_workflow_run_bodies(wf):
            refs |= extract_from_text(body)
        for rel in sorted(refs):
            abs_path = ROOT / rel
            row = {
                "workflow": str(wf.relative_to(ROOT)),
                "path": rel,
                "exists": abs_path.is_file(),
            }
            checked.append(row)
            if not abs_path.is_file():
                missing.append(row)

    payload = {
        "ok": not missing,
        "WORKFLOW_REFERENCED_PATHS_EXIST_PASS": not missing,
        "checked": len(checked),
        "missing": missing,
        "note": (
            "Generated-production-art paths are EXPERIMENT_ONLY after PR106 salvage; "
            "workflows must call current authored/art_pipeline validators instead."
        ),
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))
    if missing:
        print("WORKFLOW_REFERENCED_PATHS_EXIST_PASS=false", file=sys.stderr)
        return 1
    print("WORKFLOW_REFERENCED_PATHS_EXIST_PASS=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

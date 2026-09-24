#!/usr/bin/env python3
"""Headless visibility evidence contract.

Structural visibility and rendered-pixel visibility are distinct.
Never blindly call unsupported viewport-image paths such as texture_2d_get.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ROOT, write_json  # noqa: E402

FORBIDDEN_CALLS = ("texture_2d_get", "viewport.get_texture().get_image()")


def classify_evidence_mode() -> str:
    display = os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY")
    if os.environ.get("GODOT_HEADLESS") == "1" or os.environ.get("CI") == "true":
        if not display:
            return "STRUCTURAL_HEADLESS"
    if display:
        return "RENDERED_PIXEL"
    return "STRUCTURAL_HEADLESS"


def scan_repo_for_forbidden_reads() -> list[str]:
    hits = []
    roots = [
        ROOT / "game-godot/scripts",
        ROOT / "game-godot/tests",
        ROOT / "tools/art_pipeline/human_art",
    ]
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.suffix.lower() not in {".gd", ".py", ".md"}:
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            lowered = text.lower()
            documents_ban = "never blindly" in lowered or "never call texture_2d_get" in lowered or "forbidden_calls" in lowered
            for needle in FORBIDDEN_CALLS:
                if needle in text and not documents_ban:
                    hits.append(f"{path.relative_to(ROOT)}:{needle}")
    return hits


def main() -> int:
    mode = classify_evidence_mode()
    hits = scan_repo_for_forbidden_reads()
    payload = {
        "ok": not hits,
        "failures": hits,
        "EVIDENCE_MODE": mode,
        "structural_visibility_is_not_rendered_pixel": True,
        "ART_HEADLESS_VISIBILITY_PASS": not hits,
        "note": "CI must label the evidence mode used. texture_2d_get is unsupported under dummy/headless.",
    }
    write_json(ROOT / "artifacts/art_pipeline/ART_HEADLESS_VISIBILITY.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())

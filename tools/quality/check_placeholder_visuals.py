#!/usr/bin/env python3
"""Detect player-facing unapproved placeholder visuals in production paths.

Emits PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS count and detail findings.
Does not assign quality ladder Q5.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

SCAN_ROOTS = [
    ROOT / "game-godot" / "scenes" / "combat",
    ROOT / "game-godot" / "scripts" / "combat",
    ROOT / "game-godot" / "scripts" / "fighters",
    ROOT / "game-godot" / "scenes" / "fighters",
    ROOT / "game-godot" / "scenes" / "battle",
]

MODEL_PENDING_RE = re.compile(r"MODEL_PENDING")
DEFAULT_ICON_HINTS = (
    "icon.svg",
    "icon.png",
    "Godot_icon",
    "res://icon.svg",
)


def _iter_files() -> list[Path]:
    out: list[Path] = []
    for base in SCAN_ROOTS:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if path.suffix.lower() in {".gd", ".tscn", ".tres", ".json"}:
                out.append(path)
    return out


def main() -> int:
    findings: list[dict] = []
    for path in _iter_files():
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue

        if ("Projectile2D" in rel or rel.endswith("projectile.gd")) and (
            "debug_rect.visible = true" in text
            or ("DebugRect" in text and "ColorRect" in text)
        ):
            findings.append(
                {
                    "code": "PROJECTILE_COLORRECT_PRIMARY",
                    "path": rel,
                    "severity": "T1",
                    "note": "Projectile uses ColorRect as player-facing visual",
                }
            )

        if "BoxMesh" in text and ("projectile" in rel.lower() or "Projectile" in text):
            findings.append(
                {
                    "code": "PROJECTILE_BOXMESH",
                    "path": rel,
                    "severity": "T1",
                    "note": "BoxMesh associated with projectile path",
                }
            )

        if MODEL_PENDING_RE.search(text):
            findings.append(
                {
                    "code": "MODEL_PENDING_IN_PRODUCTION",
                    "path": rel,
                    "severity": "T0",
                    "note": "MODEL_PENDING marker in production path",
                }
            )

        for hint in DEFAULT_ICON_HINTS:
            if hint in text and ("fighter" in rel.lower() or "battle" in rel.lower()):
                findings.append(
                    {
                        "code": "DEFAULT_ICON_REFERENCE",
                        "path": rel,
                        "severity": "T1",
                        "note": f"Default/engine icon hint: {hint}",
                    }
                )
                break

    proj_script = ROOT / "game-godot" / "scripts" / "combat" / "projectile.gd"
    if proj_script.exists():
        t = proj_script.read_text(encoding="utf-8")
        if "debug_rect.visible = true" in t:
            findings.append(
                {
                    "code": "PROJECTILE_COLORRECT_FORCED_VISIBLE",
                    "path": "game-godot/scripts/combat/projectile.gd",
                    "severity": "T1",
                    "note": (
                        "ColorRect DebugRect forced visible for launch readability "
                        "(unapproved final art); TASTE-001"
                    ),
                }
            )

    uniq = {(f["code"], f["path"]): f for f in findings}
    findings = list(uniq.values())
    count = len(findings)

    out = {
        "ok": True,
        "PLAYER_FACING_UNAPPROVED_PLACEHOLDER_VISUALS": count,
        "findings": sorted(findings, key=lambda x: (x["severity"], x["code"], x["path"])),
        "scan_roots": [str(p.relative_to(ROOT)) for p in SCAN_ROOTS if p.exists()],
        "HUMAN_Q5": False,
        "note": "Count is detector hits, not quality ladder level.",
    }
    dest = ROOT / "artifacts" / "taste_gate" / "PLACEHOLDER_VISUALS.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    t0 = sum(1 for f in findings if f.get("severity") == "T0")
    return 1 if t0 else 0


if __name__ == "__main__":
    sys.exit(main())

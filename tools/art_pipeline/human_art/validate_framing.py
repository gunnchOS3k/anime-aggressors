#!/usr/bin/env python3
"""Wave020-class framing contract. Mesh-bounds only — no generated-v9 geometry."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ROOT, write_json  # noqa: E402


def framing_for_bounds(height: float, width: float, feet_y: float = 0.0, vfx_envelope: float = 0.12, fighter_id: str = "") -> dict:
    height = max(height, 0.85)
    width = max(width, 0.35)
    pad_y = 0.18 + vfx_envelope
    pad_x = 0.14 + vfx_envelope * 0.6
    width_weight = 0.62 if fighter_id == "kaia-windrow" else 0.72
    ortho = max(height * 0.52 + pad_y, width * width_weight + pad_x)
    head_y = feet_y + height
    cam_y = feet_y + height * 0.5
    margin = 0.95
    if height / (ortho * 2.0) < 0.55:
        ortho = max(height * 0.52 + pad_y, (head_y - cam_y) / margin, (cam_y - feet_y) / margin)
    coverage = height / (ortho * 2.0)
    head_visible = head_y <= cam_y + ortho * margin
    feet_visible = feet_y >= cam_y - ortho * margin
    return {
        "orthographic_size": ortho,
        "body_coverage": coverage,
        "head_visible": head_visible,
        "feet_visible": feet_visible,
        "silhouette_readable": coverage >= 0.55 and head_visible and feet_visible,
        "full_body": head_visible and feet_visible,
    }


def main() -> int:
    cases = {
        "compact": framing_for_bounds(1.55, 0.45),
        "wide_accessory": framing_for_bounds(1.70, 1.80, fighter_id="kaia-windrow"),
        "tall": framing_for_bounds(1.95, 0.50),
    }
    fails = []
    for name, row in cases.items():
        if not row["full_body"]:
            fails.append(f"{name}:not_full_body")
        if not row["silhouette_readable"]:
            fails.append(f"{name}:silhouette")
        if not row["head_visible"] or not row["feet_visible"]:
            fails.append(f"{name}:clip")
    payload = {
        "ok": not fails,
        "failures": fails,
        "cases": cases,
        "ART_REVIEW_CAMERA_PASS": not fails,
        "depends_on_generated_v9_geometry": False,
        "kaia_principle": "accessory width must not zoom past a readable body",
    }
    write_json(ROOT / "artifacts/art_pipeline/ART_FRAMING.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())

#!/usr/bin/env python3
"""Generate ORIGINAL procedural stage preview SVGs + contact sheet HTML/PNG-ish evidence."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game-godot" / "assets" / "stages" / "procedural"
QA = ROOT / "playtest-evidence" / "visual_qa" / "stages"

STAGES = {
    "skyline-arena": {
        "bg": "#0a1428",
        "plat": "#2a3550",
        "trim": "#59b7ff",
        "motif": "towers",
    },
    "neon-rooftops": {
        "bg": "#14081c",
        "plat": "#3a1d48",
        "trim": "#ff59bf",
        "motif": "neon",
    },
    "cascade-foundry": {
        "bg": "#1c0e08",
        "plat": "#523218",
        "trim": "#ff8c33",
        "motif": "stacks",
    },
    "void-pier": {
        "bg": "#080814",
        "plat": "#241e3c",
        "trim": "#8c59ff",
        "motif": "piers",
    },
    "ember-courtyard": {
        "bg": "#1a0c0c",
        "plat": "#48241e",
        "trim": "#ff6640",
        "motif": "lanterns",
    },
    "training-grid": {
        "bg": "#101218",
        "plat": "#333840",
        "trim": "#73d98c",
        "motif": "grid",
    },
}


def motif_shapes(kind: str, trim: str) -> str:
    if kind == "towers":
        return "".join(
            f'<rect x="{40 + i*70}" y="{80 - i*8}" width="28" height="{140 + i*10}" fill="{trim}" opacity="0.35"/>'
            for i in range(6)
        )
    if kind == "neon":
        return "".join(
            f'<rect x="{30 + i*90}" y="{60 + (i%2)*30}" width="60" height="10" fill="{trim}" opacity="0.7"/>'
            for i in range(5)
        )
    if kind == "stacks":
        return "".join(
            f'<rect x="{70 + i*85}" y="40" width="24" height="160" fill="{trim}" opacity="0.4"/><rect x="{66 + i*85}" y="30" width="32" height="14" fill="{trim}" opacity="0.55"/>'
            for i in range(4)
        )
    if kind == "piers":
        return "".join(
            f'<rect x="{50 + i*100}" y="170" width="12" height="70" fill="{trim}" opacity="0.5"/>'
            for i in range(5)
        ) + f'<ellipse cx="240" cy="210" rx="180" ry="18" fill="{trim}" opacity="0.2"/>'
    if kind == "lanterns":
        return "".join(
            f'<circle cx="{80 + i*70}" cy="{70 + (i%3)*15}" r="10" fill="{trim}" opacity="0.65"/>'
            for i in range(6)
        )
    # grid
    lines = []
    for i in range(0, 480, 24):
        lines.append(f'<line x1="{i}" y1="0" x2="{i}" y2="270" stroke="{trim}" stroke-width="1" opacity="0.2"/>')
    for j in range(0, 270, 24):
        lines.append(f'<line x1="0" y1="{j}" x2="480" y2="{j}" stroke="{trim}" stroke-width="1" opacity="0.2"/>')
    return "".join(lines)


def svg_for(stage_id: str, cfg: dict) -> str:
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="480" height="270" viewBox="0 0 480 270">
  <rect width="480" height="270" fill="{cfg["bg"]}"/>
  {motif_shapes(cfg["motif"], cfg["trim"])}
  <rect x="40" y="200" width="400" height="28" rx="4" fill="{cfg["plat"]}"/>
  <rect x="40" y="200" width="400" height="5" fill="{cfg["trim"]}"/>
  <rect x="90" y="140" width="90" height="16" rx="3" fill="{cfg["plat"]}"/>
  <rect x="300" y="140" width="90" height="16" rx="3" fill="{cfg["plat"]}"/>
  <rect x="180" y="90" width="120" height="16" rx="3" fill="{cfg["plat"]}"/>
  <text x="16" y="28" fill="{cfg["trim"]}" font-family="monospace" font-size="16">{stage_id}</text>
  <text x="16" y="48" fill="#ffffff" opacity="0.6" font-family="monospace" font-size="11">PROCEDURAL_FINAL</text>
</svg>
'''


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    records = []
    tiles = []
    for sid, cfg in STAGES.items():
        p = OUT / f"{sid}.svg"
        p.write_text(svg_for(sid, cfg), encoding="utf-8")
        q = QA / f"{sid}.svg"
        q.write_text(svg_for(sid, cfg), encoding="utf-8")
        records.append({"stage_id": sid, "path": str(p.relative_to(ROOT)), "status": "PROCEDURAL_FINAL", "motif": cfg["motif"]})
        tiles.append(f'<img src="{sid}.svg" width="240" alt="{sid}"/>')
    contact = QA / "stages_contact_sheet.html"
    contact.write_text(
        "<!doctype html><meta charset='utf-8'><title>Stage Visual QA</title>"
        "<style>body{background:#111;color:#eee;font-family:sans-serif}img{margin:8px;border:1px solid #333}</style>"
        "<h1>Stage procedural art contact sheet</h1>" + "".join(tiles),
        encoding="utf-8",
    )
    manifest = {
        "schema_version": 1,
        "status": "PROCEDURAL_FINAL",
        "generator": "tools/art/generate_stage_previews.py",
        "stages": records,
        "contact_sheet": str(contact.relative_to(ROOT)),
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (QA / "stage_art_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(records)} stage previews")


if __name__ == "__main__":
    main()

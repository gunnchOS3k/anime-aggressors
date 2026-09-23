#!/usr/bin/env python3
"""Compose v3 roster sheets from the generated-art v3 packet."""
from __future__ import annotations

import json
from pathlib import Path

from .common import FIGHTER_IDS, REPORTS, write_json

REVIEW = Path(__file__).resolve().parents[2] / "artifacts/vxp3/review/generated_art_v3"
OUT = REVIEW / "roster"

LABELS = (
    "idle",
    "silhouette",
    "head_detail",
    "hand_detail",
    "foot_detail",
    "heavy_contact",
    "hurt_heavy",
    "charge_100_vfx_off",
    "super",
)


def _try_sheet(paths: list[Path], dest: Path) -> bool:
    try:
        from PIL import Image
    except ImportError:
        return False
    images = [Image.open(p).convert("RGB") for p in paths if p.is_file()]
    if not images:
        return False
    w, h = images[0].size
    sheet = Image.new("RGB", (w * len(images), h), (12, 12, 14))
    for i, img in enumerate(images):
        sheet.paste(img.resize((w, h)), (i * w, 0))
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)
    return True


def main() -> dict:
    written = []
    html_rows = []
    mapping = {
        "roster silhouettes": "silhouette",
        "roster heads": "head_detail",
        "roster hands/feet": "hand_detail",
        "roster heavy contacts": "heavy_contact",
        "roster hurt poses": "hurt_heavy",
        "roster charge 100": "charge_100_vfx_off",
    }
    for label in LABELS:
        paths = [REVIEW / fid / f"{label}.png" for fid in FIGHTER_IDS]
        dest = OUT / f"roster_{label}.png"
        if _try_sheet(paths, dest):
            written.append(str(dest.relative_to(dest.parents[4])))
        cells = "".join(
            f'<td><img src="../{fid}/{label}.png" width="140"><br>{fid}</td>'
            for fid in FIGHTER_IDS
        )
        html_rows.append(f"<tr><th>{label}</th>{cells}</tr>")
    for title, label in mapping.items():
        paths = [REVIEW / fid / f"{label}.png" for fid in FIGHTER_IDS]
        dest = OUT / f"{title.replace(' ', '_')}.png"
        _try_sheet(paths, dest)
    OUT.mkdir(parents=True, exist_ok=True)
    html = (
        "<html><body style='background:#111;color:#eee;font-family:sans-serif'>"
        "<h1>Generated art v3 roster</h1>"
        "<p>Not human-authored final art. Digital packet only.</p>"
        f"<table border=0 cellspacing=6>{''.join(html_rows)}</table></body></html>"
    )
    (OUT / "roster_compare.html").write_text(html, encoding="utf-8")
    payload = {"ok": True, "sheets": written, "html": str((OUT / "roster_compare.html"))}
    write_json(REPORTS / "GENERATED_ART_V3_CONTACT_SHEETS.json", payload)
    return payload


if __name__ == "__main__":
    print(json.dumps(main(), indent=2))

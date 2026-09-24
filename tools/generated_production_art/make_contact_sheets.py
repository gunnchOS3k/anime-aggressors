#!/usr/bin/env python3
"""Compose roster comparison sheets from review stills."""
from __future__ import annotations

import json
from pathlib import Path

from .common import FIGHTER_IDS, REPORTS, write_json

REVIEW = Path(__file__).resolve().parents[2] / "artifacts/vxp3/review/generated_production"
OUT = Path(__file__).resolve().parents[2] / "artifacts/vxp3/review/generated_production/roster"

LABELS = ("idle", "heavy_contact", "hurt_heavy", "charge_100", "silhouette", "close_body_3q")


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
    for label in LABELS:
        paths = [REVIEW / fid / f"{label}.png" for fid in FIGHTER_IDS]
        dest = OUT / f"roster_{label}.png"
        if _try_sheet(paths, dest):
            written.append(str(dest.relative_to(dest.parents[4])))
        cells = "".join(
            f'<td><img src="../../generated_production/{fid}/{label}.png" width="140"><br>{fid}</td>'
            for fid in FIGHTER_IDS
        )
        html_rows.append(f"<tr><th>{label}</th>{cells}</tr>")
    OUT.mkdir(parents=True, exist_ok=True)
    html = (
        "<html><body style='background:#111;color:#eee;font-family:sans-serif'>"
        "<h1>Generated production v2 roster</h1>"
        "<p>Not human-authored final art.</p>"
        f"<table border=0 cellspacing=6>{''.join(html_rows)}</table></body></html>"
    )
    (OUT / "roster_compare.html").write_text(html, encoding="utf-8")
    payload = {"ok": True, "sheets": written, "html": str((OUT / "roster_compare.html").relative_to(OUT.parents[3]))}
    write_json(REPORTS / "GENERATED_PRODUCTION_CONTACT_SHEETS.json", payload)
    print(json.dumps(payload, indent=2))
    return payload


if __name__ == "__main__":
    main()

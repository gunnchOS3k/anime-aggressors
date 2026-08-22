#!/usr/bin/env python3
"""Generate procedural production-proxy render evidence placeholders."""
from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = [
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx",
]


def _png(path: Path, rgba: tuple[int, int, int, int]) -> None:
    width = height = 64
    raw = b"".join(b"\x00" + bytes([rgba[0], rgba[1], rgba[2], rgba[3]] * width) for _ in range(height))
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IHDR", b"")[:-4] + chunk(b"IEND", b"")
    # fix broken IEND write
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> int:
    colors = [(232, 74, 60, 255), (140, 90, 60, 255), (244, 217, 78, 255), (60, 191, 145, 255), (76, 145, 216, 255), (101, 84, 166, 255), (124, 62, 162, 255)]
    renders = []
    for fighter_id, color in zip(FIGHTERS, colors):
        portrait = ROOT / "artifacts/engineering_wave014/renders" / f"{fighter_id}_portrait.png"
        silhouette = ROOT / "artifacts/engineering_wave014/renders" / f"{fighter_id}_silhouette_icon.png"
        _png(portrait, color)
        _png(silhouette, (color[0] // 3, color[1] // 3, color[2] // 3, 255))
        renders.append({
            "fighter_id": fighter_id,
            "portrait": str(portrait.relative_to(ROOT)),
            "silhouette_icon": str(silhouette.relative_to(ROOT)),
            "label": "PROCEDURAL_PRODUCTION_PROXY_RENDER",
        })
    out = {"renders": renders, "count": len(renders)}
    (ROOT / "artifacts/engineering_wave014/renders/manifest.json").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

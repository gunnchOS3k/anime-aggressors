#!/usr/bin/env python3
"""Digital silhouette-difference support check. Not owner silhouette approval."""
from __future__ import annotations

from pathlib import Path

from .common import FIGHTER_IDS, REPORTS, write_json

REVIEW = Path(__file__).resolve().parents[2] / "artifacts/vxp3/review/generated_art_v3"
MIN_MEAN_ABS = 8.5
REQUIRED = (
    "silhouette_neutral.png",
    "silhouette_walk.png",
    "silhouette_heavy_anticipation.png",
    "silhouette_heavy_contact.png",
    "silhouette_charge_100.png",
)


def _mean_abs(a, b) -> float:
    if len(a) != len(b) or not a:
        return 0.0
    return sum(abs(x - y) for x, y in zip(a, b)) / float(len(a))


def _load(path: Path):
    try:
        from PIL import Image

        img = Image.open(path).convert("L").resize((160, 200))
        return list(img.getdata())
    except Exception:
        return _load_png_luma(path)


def _load_png_luma(path: Path) -> list[int]:
    import struct
    import zlib

    raw = path.read_bytes()
    assert raw[:8] == b"\x89PNG\r\n\x1a\n"
    pos = 8
    width = height = 0
    rows = []
    while pos < len(raw):
        length = struct.unpack(">I", raw[pos : pos + 4])[0]
        ctype = raw[pos + 4 : pos + 8]
        data = raw[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit, color, *_ = struct.unpack(">IIBBBBB", data)
        elif ctype == b"IDAT":
            rows.append(data)
        elif ctype == b"IEND":
            break
    pixels = zlib.decompress(b"".join(rows))
    bpp = {0: 1, 2: 3, 4: 2, 6: 4}[color]
    stride = width * bpp + 1
    out = []
    for y in range(height):
        row = pixels[y * stride + 1 : (y + 1) * stride]
        for x in range(width):
            i = x * bpp
            if color == 0:
                out.append(row[i])
            elif color == 2:
                out.append((row[i] + row[i + 1] + row[i + 2]) // 3)
            elif color == 6:
                out.append((row[i] + row[i + 1] + row[i + 2]) // 3)
            else:
                out.append(row[i])
    # crude nearest resize to 160x200
    resized = []
    for y in range(200):
        sy = int(y * height / 200)
        for x in range(160):
            sx = int(x * width / 160)
            resized.append(out[sy * width + sx])
    return resized


def validate() -> dict:
    pairs = []
    present = True
    for fid in FIGHTER_IDS:
        for name in REQUIRED:
            if not (REVIEW / fid / name).is_file():
                present = False
    diffs = []
    if present:
        try:
            for name in REQUIRED:
                pixels = {fid: _load(REVIEW / fid / name) for fid in FIGHTER_IDS}
                for i, a in enumerate(FIGHTER_IDS):
                    for b in FIGHTER_IDS[i + 1 :]:
                        value = _mean_abs(pixels[a], pixels[b])
                        diffs.append({"pose": name, "a": a, "b": b, "mean_abs": round(value, 3)})
        except Exception as exc:
            return {
                "ok": False,
                "present": present,
                "error": str(exc),
                "GEN_ART_V3_SILHOUETTE_PASS": False,
                "human_silhouette_approval": False,
            }
    unique = bool(diffs) and all(row["mean_abs"] >= MIN_MEAN_ABS for row in diffs)
    payload = {
        "ok": present and unique,
        "present": present,
        "unique_enough": unique,
        "min_mean_abs": MIN_MEAN_ABS,
        "worst": min((row["mean_abs"] for row in diffs), default=0.0),
        "pairs": diffs,
        "GEN_ART_V3_SILHOUETTE_PASS": present and unique,
        "human_silhouette_approval": False,
        "note": "Digital support only. Owner must still distinguish all seven in black silhouette.",
    }
    write_json(REPORTS / "GENERATED_ART_V3_SILHOUETTE.json", payload)
    return payload


if __name__ == "__main__":
    import json

    print(json.dumps(validate(), indent=2))

"""Stdlib contact-sheet stitcher. Prefers sips BMP decode on macOS; no Pillow."""
from __future__ import annotations

import struct
import subprocess
import tempfile
import zlib
from pathlib import Path


def _chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def _read_bmp(path: Path) -> tuple[int, int, list[list[tuple[int, int, int, int]]]]:
    data = path.read_bytes()
    if data[:2] != b"BM":
        raise ValueError("not a bmp")
    offset = struct.unpack_from("<I", data, 10)[0]
    width = struct.unpack_from("<i", data, 18)[0]
    height = struct.unpack_from("<i", data, 22)[0]
    bpp = struct.unpack_from("<H", data, 28)[0]
    flip = height > 0
    height = abs(height)
    row_bytes = ((bpp * width + 31) // 32) * 4
    rows = []
    for y in range(height):
        src_y = height - 1 - y if flip else y
        start = offset + src_y * row_bytes
        row = []
        for x in range(width):
            i = start + x * (bpp // 8)
            b, g, r = data[i], data[i + 1], data[i + 2]
            a = data[i + 3] if bpp == 32 else 255
            row.append((r, g, b, a))
        rows.append(row)
    return width, height, rows


def read_image(path: Path) -> tuple[int, int, list[list[tuple[int, int, int, int]]]]:
    with tempfile.TemporaryDirectory() as tmp:
        bmp = Path(tmp) / "frame.bmp"
        proc = subprocess.run(
            ["sips", "-s", "format", "bmp", str(path), "--out", str(bmp)],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0 or not bmp.is_file():
            raise RuntimeError(f"sips failed for {path}: {proc.stderr}")
        return _read_bmp(bmp)


def write_png(path: Path, rows: list[list[tuple[int, int, int, int]]]) -> None:
    height = len(rows)
    width = len(rows[0]) if rows else 0
    raw = bytearray()
    for row in rows:
        raw.append(0)
        for r, g, b, a in row:
            raw.extend((r, g, b, a))
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = b"\x89PNG\r\n\x1a\n"
    payload += _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    payload += _chunk(b"IDAT", zlib.compress(bytes(raw), 6))
    payload += _chunk(b"IEND", b"")
    path.write_bytes(payload)


def stitch_row(paths: list[Path], dest: Path, bg=(18, 18, 20, 255)) -> bool:
    images = []
    for path in paths:
        if path.is_file():
            images.append(read_image(path))
    if not images:
        return False
    w, h = images[0][0], images[0][1]
    canvas = [[bg] * (w * len(images)) for _ in range(h)]
    for i, (iw, ih, rows) in enumerate(images):
        for y in range(min(h, ih)):
            for x in range(min(w, iw)):
                canvas[y][i * w + x] = rows[y][x]
    write_png(dest, canvas)
    return True

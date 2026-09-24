"""Scripted still checks. Digital only — does not set HUMAN_*."""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from generated_art_v6.body_profiles import FIGHTER_IDS, ROOT

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v6"
REPORTS = ROOT / "artifacts/vxp3/reports"


def _open(path: Path):
    from generated_art_v6.png_sheet import read_image

    _w, _h, rows = read_image(path)

    class _Img:
        def __init__(self, rows):
            self._rows = rows
            self.size = (len(rows[0]), len(rows))

        def getpixel(self, xy):
            x, y = xy
            return self._rows[y][x][:3]

    return _Img(rows)


def _peach_ratio(img) -> float:
    w, h = img.size
    peach = 0
    total = 0
    step = max(1, w // 80)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b < 40:
                continue
            total += 1
            mx = max(r, g, b) / 255.0
            mn = min(r, g, b) / 255.0
            sat = 0.0 if mx == 0 else (mx - mn) / mx
            if r > 170 and g > 120 and b > 80 and r > b + 20 and 0.12 <= sat <= 0.55 and mx > 0.55:
                peach += 1
    return peach / total if total else 0.0


def _value_groups(img, bins=12) -> int:
    hist = Counter()
    w, h = img.size
    step = max(1, w // 80)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b < 40:
                continue
            luma = int((0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0 * (bins - 1))
            hist[luma] += 1
    if not hist:
        return 0
    peak = max(hist.values())
    return sum(1 for count in hist.values() if count >= peak * 0.12)


def _mean_luma(img) -> float:
    w, h = img.size
    acc = 0.0
    n = 0
    step = max(1, w // 80)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b < 40:
                continue
            acc += 0.2126 * r + 0.7152 * g + 0.0722 * b
            n += 1
    return (acc / n / 255.0) if n else 0.0


def inspect() -> dict:
    fighters = {}
    peach_ok = True
    nix_ok = True
    values_ok = True
    for fid in FIGHTER_IDS:
        front = REVIEW / fid / "front.png"
        gray = REVIEW / fid / "grayscale_values.png"
        if not front.is_file():
            fighters[fid] = {"missing": True}
            peach_ok = False
            values_ok = False
            continue
        img = _open(front)
        peach = _peach_ratio(img)
        groups = _value_groups(_open(gray) if gray.is_file() else img)
        luma = _mean_luma(img)
        peach_fail = peach > 0.18
        value_fail = groups < 3
        nix_fail = fid == "nix-calder" and luma > 0.82 and groups < 3
        peach_ok = peach_ok and not peach_fail
        values_ok = values_ok and not value_fail
        nix_ok = nix_ok and not nix_fail
        fighters[fid] = {
            "peach_ratio": round(peach, 4),
            "value_groups": groups,
            "mean_luma": round(luma, 4),
            "peach_dominant": peach_fail,
            "value_collapse": value_fail or nix_fail,
        }
    payload = {
        "ok": peach_ok and values_ok and nix_ok,
        "GEN_ART_V6_NO_PEACH_BODY_DIGITAL": peach_ok,
        "GEN_ART_V6_VALUE_BLOCKING_DIGITAL": values_ok and nix_ok,
        "fighters": fighters,
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "GENERATED_ART_V6_QUALITY.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


if __name__ == "__main__":
    print(json.dumps(inspect(), indent=2))

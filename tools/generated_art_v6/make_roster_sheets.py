"""Compose v6 roster sheets from per-fighter stills."""
from __future__ import annotations

from pathlib import Path

from generated_art_v6.body_profiles import FIGHTER_IDS, ROOT

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v6"

SHEETS = {
    "select_lineup": "select_preview.png",
    "black_silhouettes": "silhouette_idle.png",
    "grayscale_values": "grayscale_values.png",
    "heads": "head_front.png",
    "gloves": "glove_fist.png",
    "boots": "boot_side.png",
    "costumes": "costume_front.png",
    "heavies": "heavy_contact_pair_vfx_off.png",
    "hurt": "hurt_peak_no_knockback.png",
    "charge": "charge_100_vfx_off.png",
    "supers": "super.png",
    "clashes": "clash_lock.png",
    "value_group_compare": "grayscale_values.png",
}


def main() -> dict:
    from generated_art_v6.png_sheet import stitch_row

    out_dir = REVIEW / "roster"
    out_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    for sheet, filename in SHEETS.items():
        paths = [REVIEW / fid / filename for fid in FIGHTER_IDS]
        dest = out_dir / f"{sheet}.png"
        written[sheet] = stitch_row(paths, dest)
    return written


if __name__ == "__main__":
    print(main())

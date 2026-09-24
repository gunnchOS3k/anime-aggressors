"""Compose v7 roster sheets from per-fighter stills."""
from __future__ import annotations

from generated_art_v6.png_sheet import stitch_row
from generated_art_v7.body_profiles import FIGHTER_IDS, ROOT

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v7"

SHEETS = {
    "select_lineup": "select_preview.png",
    "color_lineup": "front_3q_color.png",
    "grayscale_lineup": "front_3q_grayscale.png",
    "silhouettes": "silhouette_idle.png",
    "gloves": "glove_fist.png",
    "boots": "boot_detail.png",
    "masks": "head_detail.png",
    "hero_features": "costume_detail.png",
    "idle_identities": "idle.png",
    "heavy_pairs": "heavy_contact_pair_off.png",
    "hurt_peaks": "hurt_peak_no_knockback.png",
    "charge_transformation": "charge_100_off.png",
    "supers": "super_off.png",
    "clash_presets": "clash_lock.png",
    "value_groups": "grayscale_values.png",
}


def main() -> dict:
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

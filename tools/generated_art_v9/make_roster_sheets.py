"""Compose v9 roster sheets from per-fighter stills."""
from __future__ import annotations

from generated_art_v6.png_sheet import stitch_row
from generated_art_v9.body_profiles import FIGHTER_IDS, ROOT

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v9"

SHEETS = {
    "select_lineup": "select_preview.png",
    "color_lineup": "front_3q_color.png",
    "grayscale_lineup": "front_3q_grayscale.png",
    "silhouettes": "silhouette_idle.png",
    "idle_silhouettes": "silhouette_idle.png",
    "masks": "mask_detail.png",
    "gloves": "glove_fist.png",
    "glove_silhouettes": "glove_fist_silhouette.png",
    "boots": "boot_detail.png",
    "boot_silhouettes": "boot_silhouette.png",
    "hero_features": "costume_detail.png",
    "idle_identities": "idle.png",
    "heavy_pairs": "heavy_contact_off.png",
    "heavy_contact_grid": "heavy_contact_off.png",
    "hurt_peaks": "hurt_peak.png",
    "hurt_grid": "hurt_peak.png",
    "charge_transformation": "charge_100_off.png",
    "charge_compare": "charge_100_silhouette.png",
    "supers": "super_off.png",
    "super_silhouettes": "super_silhouette.png",
    "clash_presets": "clash_lock_off.png",
    "clash_grid": "clash_lock_off.png",
    "value_groups": "grayscale_values.png",
    "attachment_stress": "attachment_stress.png",
}


def _stitch_locomotion() -> bool:
    dest = REVIEW / "roster" / "locomotion_strips.png"
    dest.parent.mkdir(parents=True, exist_ok=True)
    paths = []
    for fid in FIGHTER_IDS:
        paths.extend([REVIEW / fid / f"walk_f{i}.png" for i in range(4)])
        paths.extend([REVIEW / fid / f"run_f{i}.png" for i in range(4)])
    if not all(p.is_file() for p in paths):
        paths = [REVIEW / fid / "walk.png" for fid in FIGHTER_IDS] + [REVIEW / fid / "run.png" for fid in FIGHTER_IDS]
    return stitch_row(paths, dest)


def _compare_charge() -> bool:
    dest = REVIEW / "roster" / "charge_idle_silhouette_compare.png"
    paths = []
    for fid in FIGHTER_IDS:
        paths.append(REVIEW / fid / "charge_0_silhouette.png")
        paths.append(REVIEW / fid / "charge_100_silhouette.png")
    return stitch_row(paths, dest)


def main() -> dict:
    out_dir = REVIEW / "roster"
    out_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    for sheet, filename in SHEETS.items():
        paths = [REVIEW / fid / filename for fid in FIGHTER_IDS]
        dest = out_dir / f"{sheet}.png"
        written[sheet] = stitch_row(paths, dest)
    written["locomotion_strips"] = _stitch_locomotion()
    written["charge_idle_silhouette_compare"] = _compare_charge()
    return written


if __name__ == "__main__":
    print(main())

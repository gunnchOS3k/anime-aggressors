"""Compose v5 roster contact sheets from per-fighter stills."""
from __future__ import annotations

from pathlib import Path

from generated_art_v5.body_profiles import FIGHTER_IDS, ROOT

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v5"

SHEETS = {
    "bodies": "front.png",
    "heads": "head_detail_front.png",
    "hands": "hand_fist.png",
    "boots": "boot_detail.png",
    "costumes": "costume_front.png",
    "gameplay_silhouettes": "silhouette_idle.png",
    "heavy_contacts": "heavy_contact_pair_vfx_off.png",
    "hurt_reactions": "hurt_heavy_no_knockback.png",
    "charge_0_vs_100": "charge_100_vfx_off.png",
    "supers": "super_vfx_off.png",
    "clash_poses": "clash_lock.png",
}


def _open(path: Path):
    from PIL import Image

    return Image.open(path).convert("RGBA")


def main() -> dict:
    from PIL import Image

    out_dir = REVIEW / "roster"
    out_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    for sheet, filename in SHEETS.items():
        images = []
        for fid in FIGHTER_IDS:
            path = REVIEW / fid / filename
            if path.is_file():
                images.append(_open(path))
        if not images:
            written[sheet] = False
            continue
        w, h = images[0].size
        canvas = Image.new("RGBA", (w * len(images), h), (18, 18, 20, 255))
        for i, img in enumerate(images):
            canvas.paste(img.resize((w, h)), (i * w, 0))
        dest = out_dir / f"{sheet}.png"
        canvas.save(dest)
        written[sheet] = True
    return written


if __name__ == "__main__":
    print(main())

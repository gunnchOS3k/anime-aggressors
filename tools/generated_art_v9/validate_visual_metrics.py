"""Scripted still checks for v8. Digital/structural only — does not set HUMAN_*."""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from generated_art_v9.body_profiles import FIGHTER_IDS, ROOT, load_palettes, luma, palette_value_ok
from generated_art_v9.hero_poses import idle_v9, pose_delta_ok, pose_v9
from generated_art_v9.impact_pair_solver import geometry_ok
from generated_art_v9.pair_scenes import defender_for

REVIEW = ROOT / "artifacts/vxp3/review/generated_art_v9"
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


def _value_groups(img) -> int:
    bands = Counter()
    w, h = img.size
    step = max(1, w // 80)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b < 40:
                continue
            val = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            if val < 0.24:
                bands["dark"] += 1
            elif val < 0.55:
                bands["mid"] += 1
            else:
                bands["pale"] += 1
    total = sum(bands.values())
    if total < 12:
        return 0
    return sum(1 for count in bands.values() if count / total >= 0.024)


def _subject_bbox(img):
    w, h = img.size
    xs, ys = [], []
    step = max(1, w // 120)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b > 45:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return (min(xs), min(ys), max(xs), max(ys))


def _crop_ok(img, min_cover=0.04) -> bool:
    box = _subject_bbox(img)
    if box is None:
        return False
    x0, y0, x1, y1 = box
    w, h = img.size
    cover = ((x1 - x0) / w) * ((y1 - y0) / h)
    if cover < min_cover:
        return False
    edges = int(x0 <= 2) + int(y0 <= 2) + int(x1 >= w - 3) + int(y1 >= h - 3)
    if edges >= 3 and cover > 0.88:
        return False
    return True


def _two_figures(img) -> bool:
    w, h = img.size
    left = 0
    right = 0
    step = max(1, w // 90)
    mid = w // 2
    for y in range(int(h * 0.15), int(h * 0.85), step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b < 45:
                continue
            if x < mid - 8:
                left += 1
            elif x > mid + 8:
                right += 1
    return left > 12 and right > 12 and min(left, right) / max(left, right) > 0.22


def _nix_split(img) -> bool:
    w, h = img.size
    dark = pale = mid = 0
    step = max(1, w // 80)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b = img.getpixel((x, y))
            if r + g + b < 40:
                continue
            val = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            if val < 0.22:
                dark += 1
            elif val > 0.58:
                pale += 1
            elif 0.28 <= val <= 0.56:
                mid += 1
    total = dark + pale + mid
    if total < 20:
        return False
    return dark / total > 0.14 and pale / total > 0.028 and mid / total > 0.035


def _contact_row(fid: str) -> dict:
    path = REVIEW / fid / "orientation.json"
    if not path.is_file():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    contact = payload.get("contact") or {}
    return contact.get("heavy_contact_off") or contact.get("heavy_contact_pair_off") or {}


def inspect() -> dict:
    palettes = load_palettes()
    fighters = {}
    peach_ok = True
    values_ok = True
    nix_ok = True
    camera_ok = True
    pair_ok = True
    contact_ok = True
    idle_ok = True
    hurt_ok = True
    charge_ok = True
    super_ok = True
    clash_ok = True
    mobile_ok = True
    hero_ok = True
    for fid in FIGHTER_IDS:
        front = REVIEW / fid / "front.png"
        gray = REVIEW / fid / "grayscale_values.png"
        glove = REVIEW / fid / "glove_fist.png"
        boot = REVIEW / fid / "boot_detail.png"
        head = REVIEW / fid / "mask_detail.png"
        pair = REVIEW / fid / "heavy_contact_pair_off.png"
        gameplay = REVIEW / fid / "gameplay_scale.png"
        costume = REVIEW / fid / "costume_detail.png"
        if not front.is_file():
            fighters[fid] = {"missing": True}
            peach_ok = values_ok = False
            continue
        img = _open(front)
        gray_img = _open(gray) if gray.is_file() else img
        peach = _peach_ratio(img)
        groups = _value_groups(gray_img)
        peach_fail = peach > 0.18
        value_fail = groups < 3 or not palette_value_ok(fid)
        nix_fail = fid == "nix-calder" and (not _nix_split(gray_img) or luma(palettes[fid]["undersuit"]) > 0.14)
        glove_ok = glove.is_file() and _crop_ok(_open(glove), min_cover=0.05)
        boot_ok = boot.is_file() and _crop_ok(_open(boot), min_cover=0.04)
        head_ok = head.is_file() and _crop_ok(_open(head), min_cover=0.04)
        pair_img_ok = pair.is_file() and _two_figures(_open(pair))
        contact = _contact_row(fid)
        contact_geom = geometry_ok(contact) if contact else False
        mobile = gameplay.is_file() and _value_groups(_open(gameplay)) >= 2
        idle = pose_delta_ok(idle_v9(fid), pose_v9("ember-vale", "idle") if fid != "ember-vale" else pose_v9("rook-ironside", "idle"), ("Hips", "Chest", "Head", "UpperArm_R", "UpperArm_L", "UpperLeg_R"))
        hurt = pose_delta_ok(idle_v9(fid), pose_v9(fid, "hurt_peak"), ("Head", "Chest", "Hips", "UpperArm_R", "UpperLeg_R"))
        charge = pose_delta_ok(idle_v9(fid), pose_v9(fid, "charge"), ("Chest", "Head", "Hips", "UpperArm_R", "UpperArm_L"))
        super_p = pose_delta_ok(idle_v9(fid), pose_v9(fid, "super"), ("UpperArm_R", "UpperArm_L", "Chest", "Hips"))
        clash = pose_delta_ok(idle_v9(fid), pose_v9(fid, "clash_lock"), ("Chest", "UpperArm_R", "UpperArm_L", "UpperLeg_R", "UpperLeg_L"))
        peach_ok = peach_ok and not peach_fail
        values_ok = values_ok and not value_fail
        nix_ok = nix_ok and not nix_fail
        camera_ok = camera_ok and glove_ok and boot_ok and head_ok
        pair_ok = pair_ok and pair_img_ok
        contact_ok = contact_ok and contact_geom
        idle_ok = idle_ok and idle
        hurt_ok = hurt_ok and hurt
        charge_ok = charge_ok and charge
        super_ok = super_ok and super_p
        clash_ok = clash_ok and clash
        mobile_ok = mobile_ok and mobile
        hero_ok = hero_ok and costume.is_file()
        fighters[fid] = {
            "peach_ratio": round(peach, 4),
            "value_groups": groups,
            "peach_dominant": peach_fail,
            "value_collapse": value_fail or nix_fail,
            "nix_split": (not nix_fail) if fid == "nix-calder" else None,
            "glove_camera_ok": glove_ok,
            "boot_camera_ok": boot_ok,
            "head_camera_ok": head_ok,
            "pair_two_figures": pair_img_ok,
            "pair_contact_geometry": contact_geom,
            "contact_distance": contact.get("contact_distance"),
            "body_overlap": contact.get("body_overlap"),
            "defender": defender_for(fid),
            "idle_identity_digital": idle,
            "hurt_acting_digital": hurt,
            "charge_transform_digital": charge,
            "super_pose_digital": super_p,
            "clash_acting_digital": clash,
            "mobile_read_digital": mobile,
        }
    payload = {
        "ok": peach_ok and values_ok and nix_ok,
        "generator": "aa_generated_art_v9",
        "generator_version": "9.0.0",
        "human_authored": False,
        "GEN_ART_V9_NO_PEACH_BODY_DIGITAL": peach_ok,
        "GEN_ART_V9_VALUE_BLOCKING_DIGITAL": values_ok and nix_ok,
        "GEN_ART_V9_DETAIL_CAMERA_DIGITAL": camera_ok,
        "GEN_ART_V9_HEAVY_PAIR_TWO_FIGURES_DIGITAL": pair_ok,
        "GEN_ART_V9_PAIR_CONTACT_GEOMETRY_DIGITAL": contact_ok,
        "GEN_ART_V9_IDLE_IDENTITY_DIGITAL": idle_ok,
        "GEN_ART_V9_HURT_ACTING_DIGITAL": hurt_ok,
        "GEN_ART_V9_CHARGE_TRANSFORM_DIGITAL": charge_ok,
        "GEN_ART_V9_SUPER_HERO_POSE_DIGITAL": super_ok,
        "GEN_ART_V9_CLASH_ACTING_DIGITAL": clash_ok,
        "GEN_ART_V9_MOBILE_READ_DIGITAL": mobile_ok,
        "GEN_ART_V9_HERO_FEATURE_DIGITAL": hero_ok,
        "visual_read_note": "Digital pair/hurt/charge/clash gates are structural prerequisites only. They are not a visual-complete claim.",
        "fighters": fighters,
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "GENERATED_ART_V9_QUALITY.json").write_text(json.dumps(payload, indent=2) + "\n")
    return payload


if __name__ == "__main__":
    print(json.dumps(inspect(), indent=2))

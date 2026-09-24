"""v6 review packet. Cameras stay on the v4 contract plus bound-aimed details."""
from __future__ import annotations

# label, action, frame, preset, silhouette, grayscale, outline, aim
PACKET = (
    ("front", "", 1, "FRONT_ORTHO", False, False, False, ""),
    ("front_3q", "", 1, "FRONT_3Q", False, False, False, ""),
    ("side", "", 1, "SIDE", False, False, False, ""),
    ("back", "", 1, "BACK", False, False, False, ""),
    ("select_preview", "idle", 1, "FRONT_3Q", False, False, True, ""),
    ("gameplay_scale", "idle", 1, "GAMEPLAY_LEFT", False, False, False, ""),
    ("head_front", "idle", 1, "DETAIL_HEAD", False, False, True, "head"),
    ("head_3q", "idle", 1, "DETAIL_HEAD", False, False, True, "head"),
    ("glove_fist", "idle", 1, "DETAIL_HANDS", False, False, False, "glove"),
    ("glove_open", "idle", 1, "DETAIL_HANDS", False, False, False, "glove"),
    ("boot_side", "idle", 1, "DETAIL_FEET", False, False, False, "boot"),
    ("costume_front", "idle", 1, "DETAIL_COSTUME", False, False, False, ""),
    ("costume_3q", "idle", 1, "FRONT_3Q", False, False, False, ""),
    ("grayscale_values", "idle", 1, "FRONT_ORTHO", False, True, False, ""),
    ("silhouette_idle", "idle", 1, "SILHOUETTE", True, False, False, ""),
    ("silhouette_super", "signature_lane_finisher", 16, "SILHOUETTE", True, False, False, ""),
    ("idle", "idle", 1, "FRONT_3Q", False, False, False, ""),
    ("walk", "walk", 8, "FRONT_3Q", False, False, False, ""),
    ("run", "run", 6, "GAMEPLAY_LEFT", False, False, False, ""),
    ("charge_0_vfx_off", "idle", 1, "FRONT_3Q", False, False, False, ""),
    ("charge_100_vfx_off", "charged_idle", 12, "FRONT_3Q", False, False, False, ""),
    ("charge_100_vfx_on", "charged_idle", 12, "FRONT_3Q", False, False, False, ""),
    ("heavy_anticipation", "heavy", 4, "FRONT_3Q", False, False, False, ""),
    ("heavy_contact_pair_vfx_off", "heavy", 11, "FRONT_3Q", False, False, False, ""),
    ("heavy_contact_pair_vfx_on", "heavy", 11, "FRONT_3Q", False, False, False, ""),
    ("heavy_follow", "heavy", 16, "FRONT_3Q", False, False, False, ""),
    ("hurt_peak_no_knockback", "hurt_heavy", 6, "FRONT_3Q", False, False, False, ""),
    ("aura", "aura_signature", 12, "FRONT_3Q", False, False, False, ""),
    ("super", "signature_lane_finisher", 16, "FRONT_3Q", False, False, False, ""),
    ("clash_lock", "clash_lock", 12, "FRONT_3Q", False, False, False, ""),
    ("KO", "ko", 12, "FRONT_3Q", False, False, False, ""),
)

REQUIRED_SHOTS = tuple(row[0] for row in PACKET)

ROSTER_SHEETS = (
    "select_lineup",
    "black_silhouettes",
    "grayscale_values",
    "heads",
    "gloves",
    "boots",
    "costumes",
    "heavies",
    "hurt",
    "charge",
    "supers",
    "clashes",
    "value_group_compare",
)

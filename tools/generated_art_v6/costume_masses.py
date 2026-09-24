"""Large readable costume masses. Undersuit + shells + one hero feature."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts, torso_stations
from generated_art_v6.body_profiles import StyleProfile, as_v5_body
from generated_art_v6.cel_materials import assign
from generated_art_v6.geom import box_mesh, loft_stack


def _shell(name, stations, scale=1.20, start=1, end=7):
    subset = stations[start:end]
    stacked = []
    for station in subset:
        stacked.append(
            (
                station["center"],
                station["width"] * scale,
                station["depth"] * scale,
                station["front"] * 0.6,
                Vector((0.0, 0.0, 1.0)),
            )
        )
    obj = loft_stack(name, stacked, n=14)
    obj["aa_costume_shell"] = 1
    obj["aa_costume_mass"] = 1
    return obj


def _guard(name, a, b, radius):
    a, b = Vector(a), Vector(b)
    direction = b - a
    obj = loft_stack(
        name,
        [
            (a, radius * 2.2, radius * 2.0, 0.06, direction),
            ((a + b) * 0.5, radius * 2.4, radius * 2.1, 0.08, direction),
            (b, radius * 1.8, radius * 1.6, 0.04, direction),
        ],
        n=12,
    )
    obj["aa_costume_mass"] = 1
    return obj


def build_costume(profile: StyleProfile, arm_obj, mats: dict):
    v5 = as_v5_body(profile)
    stations = torso_stations(v5, arm_obj)
    pieces = []
    fid = profile.fighter_id

    def add(obj, mat_key="armor"):
        assign(obj, mats.get(mat_key, mats["armor"]))
        pieces.append(obj)
        return obj

    # Chest cuirass only — a full-torso second skin reads as nude/peach.
    add(_shell("torso_shell", stations, scale=1.28 if fid == "rook-ironside" else 1.22, start=1, end=4), "armor")
    la_h, la_t = bone_pts(arm_obj, "LowerArm_R")
    la_hl, la_tl = bone_pts(arm_obj, "LowerArm_L")
    ua_h, ua_t = bone_pts(arm_obj, "UpperArm_R")
    ua_hl, ua_tl = bone_pts(arm_obj, "UpperArm_L")
    ul_h, ul_t = bone_pts(arm_obj, "UpperLeg_R")
    ul_hl, ul_tl = bone_pts(arm_obj, "UpperLeg_L")
    ll_h, ll_t = bone_pts(arm_obj, "LowerLeg_R")
    ll_hl, ll_tl = bone_pts(arm_obj, "LowerLeg_L")
    chest_h, chest_t = bone_pts(arm_obj, "Chest")
    hips_h, _hips_t = bone_pts(arm_obj, "Hips")
    add(_guard("forearm_mass_r", la_h, la_t, 0.058 * profile.forearm_mass), "glove")
    add(_guard("forearm_mass_l", la_hl, la_tl, 0.058 * profile.forearm_mass), "glove")
    add(_guard("thigh_mass_r", ul_h, ul_t, 0.078 * profile.thigh_mass), "secondary")
    add(_guard("thigh_mass_l", ul_hl, ul_tl, 0.078 * profile.thigh_mass), "secondary")
    add(_guard("shin_mass_r", ll_h, ll_t, 0.052 * profile.calf_mass), "boot")
    add(_guard("shin_mass_l", ll_hl, ll_tl, 0.052 * profile.calf_mass), "boot")
    mid = (chest_h + chest_t) * 0.5

    if fid == "ember-vale":
        add(_guard("shoulder_wedge_r", ua_h, ua_t, 0.070), "armor")
        add(box_mesh("heat_cuirass", mid + Vector((0.0, 0.08, 0.0)), (0.22, 0.10, 0.18)), "accent")
        add(box_mesh("heat_vent", mid + Vector((0.0, 0.10, -0.02)), (0.12, 0.05, 0.10)), "emit")
        add(box_mesh("shoulder_accent", chest_t + Vector((-0.16, 0.05, 0.03)), (0.14, 0.12, 0.12)), "accent")
    elif fid == "rook-ironside":
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        sr_h, sr_t = bone_pts(arm_obj, "Shoulder_R")
        add(box_mesh("shoulder_pad_l", sl_t + Vector((0.05, 0.03, 0.04)), (0.26, 0.18, 0.18)), "armor")
        add(box_mesh("shoulder_pad_r", sr_t + Vector((-0.05, 0.03, 0.04)), (0.26, 0.18, 0.18)), "armor")
        add(box_mesh("belt_plate", hips_h + Vector((0.0, 0.05, 0.03)), (0.34, 0.16, 0.12)), "accent")
        add(box_mesh("back_plate", mid + Vector((0.0, -0.10, 0.0)), (0.30, 0.12, 0.22)), "armor")
    elif fid == "juno-spark":
        add(box_mesh("volt_panel_a", mid + Vector((0.08, 0.07, 0.02)), (0.12, 0.07, 0.16)), "accent")
        add(box_mesh("volt_sash", mid + Vector((0.02, 0.06, 0.0)), (0.30, 0.06, 0.08)), "emit")
        add(_guard("sharp_calf_r", ll_h, ll_t, 0.042), "accent")
        add(_guard("sharp_calf_l", ll_hl, ll_tl, 0.042), "accent")
    elif fid == "kaia-windrow":
        _nh, nt = bone_pts(arm_obj, "Neck")
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        sr_h, sr_t = bone_pts(arm_obj, "Shoulder_R")
        add(box_mesh("scarf_collar", nt + Vector((0.0, 0.03, 0.0)), (0.18, 0.12, 0.08)), "accent")
        add(box_mesh("scarf_fall", nt + Vector((0.06, 0.08, -0.18)), (0.08, 0.12, 0.34)), "accent")
        add(box_mesh("airfoil_l", sl_t + Vector((0.06, 0.03, 0.10)), (0.10, 0.05, 0.24)), "accent")
        add(box_mesh("airfoil_r", sr_t + Vector((-0.06, 0.03, 0.10)), (0.10, 0.05, 0.24)), "accent")
    elif fid == "nix-calder":
        add(box_mesh("crystal_core", mid + Vector((0.0, 0.09, 0.02)), (0.12, 0.08, 0.12)), "emit")
        add(box_mesh("frost_cuirass", mid + Vector((0.0, 0.07, 0.0)), (0.20, 0.08, 0.16)), "armor")
        add(_guard("forearm_plate_r", la_h, la_t, 0.050), "armor")
        add(_guard("forearm_plate_l", la_hl, la_tl, 0.050), "armor")
    elif fid == "orion-vell":
        add(_shell("coat_layer", stations, scale=1.28, start=1, end=7), "secondary")
        add(box_mesh("authority_panel", mid + Vector((0.0, 0.10, 0.0)), (0.18, 0.07, 0.16)), "accent")
        add(box_mesh("orbit_trim", mid + Vector((0.0, 0.03, 0.10)), (0.24, 0.20, 0.05)), "emit")
        add(box_mesh("orbit_ring", Vector((0.06, 0.12, chest_t.z + 0.10)), (0.30, 0.24, 0.04)), "emit")
    elif fid == "vesper-nyx":
        add(box_mesh("coat_panel_l", hips_h + Vector((0.14, 0.05, 0.10)), (0.16, 0.12, 0.28)), "secondary")
        add(box_mesh("coat_tail_l", hips_h + Vector((0.16, 0.03, -0.10)), (0.08, 0.16, 0.32)), "secondary")
        add(box_mesh("coat_tail_r", hips_h + Vector((-0.08, 0.02, -0.08)), (0.06, 0.12, 0.24)), "secondary")
        add(box_mesh("void_trim", mid + Vector((0.0, 0.09, 0.0)), (0.14, 0.05, 0.12)), "void")
    return pieces

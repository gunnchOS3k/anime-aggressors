"""v8 costume masses. Enlarge mid/pale groups and classify every piece."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.torso_loft import bone_pts, torso_stations
from generated_art_v6.body_profiles import StyleProfile, as_v5_body
from generated_art_v6.geom import box_mesh, loft_stack
from generated_art_v9.attachment_map import tag_object
from generated_art_v9.body_profiles import hero_feature_scale
from generated_art_v9.cel_materials import assign


def _shell(name, stations, scale=1.16, start=1, end=4):
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
    obj["aa_hero_feature"] = 0
    return obj


def _guard(name, a, b, radius):
    a, b = Vector(a), Vector(b)
    direction = b - a
    obj = loft_stack(
        name,
        [
            (a, radius * 2.0, radius * 1.8, 0.06, direction),
            ((a + b) * 0.5, radius * 2.2, radius * 1.9, 0.08, direction),
            (b, radius * 1.6, radius * 1.4, 0.04, direction),
        ],
        n=12,
    )
    obj["aa_costume_mass"] = 1
    return obj


def _mark_hero(obj):
    obj["aa_hero_feature"] = 1
    obj["aa_costume_mass"] = 1
    return obj


def build_costume(profile: StyleProfile, arm_obj, mats: dict):
    v5 = as_v5_body(profile)
    stations = torso_stations(v5, arm_obj)
    pieces = []
    fid = profile.fighter_id

    def add(obj, mat_key="armor", hero=False):
        assign(obj, mats.get(mat_key, mats["armor"]))
        if hero:
            _mark_hero(obj)
        tag_object(obj)
        pieces.append(obj)
        return obj

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
    mid = (chest_h + chest_t) * 0.5

    if fid == "ember-vale":
        add(_shell("torso_shell", stations, scale=1.18, start=1, end=4), "armor")
        add(_guard("forearm_mass_r", la_h, la_t, 0.062 * profile.forearm_mass), "glove")
        add(_guard("forearm_mass_l", la_hl, la_tl, 0.050 * profile.forearm_mass), "glove")
        add(_guard("thigh_mass_r", ul_h, ul_t, 0.070 * profile.thigh_mass), "armor")
        add(_guard("thigh_mass_l", ul_hl, ul_tl, 0.070 * profile.thigh_mass), "armor")
        add(box_mesh("heat_cuirass", mid + Vector((0.04, 0.11, 0.02)), (0.30, 0.14, 0.22)), "accent", hero=True)
        add(box_mesh("heat_vent", mid + Vector((0.02, 0.13, -0.01)), (0.12, 0.05, 0.10)), "emit")
        add(box_mesh("shoulder_heat_wedge", chest_t + Vector((-0.18, 0.07, 0.05)), (0.16, 0.14, 0.14)), "accent", hero=True)
        add(_guard("shoulder_wedge_r", ua_h, ua_t, 0.074), "armor")
    elif fid == "rook-ironside":
        add(_shell("torso_shell", stations, scale=1.30, start=1, end=5), "armor")
        add(_guard("forearm_mass_r", la_h, la_t, 0.078 * profile.forearm_mass), "armor", hero=True)
        add(_guard("forearm_mass_l", la_hl, la_tl, 0.078 * profile.forearm_mass), "armor", hero=True)
        add(_guard("thigh_mass_r", ul_h, ul_t, 0.086 * profile.thigh_mass), "secondary")
        add(_guard("thigh_mass_l", ul_hl, ul_tl, 0.086 * profile.thigh_mass), "secondary")
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        sr_h, sr_t = bone_pts(arm_obj, "Shoulder_R")
        add(box_mesh("shoulder_pad_l", sl_t + Vector((0.06, 0.04, 0.05)), (0.30, 0.20, 0.20)), "armor", hero=True)
        add(box_mesh("shoulder_pad_r", sr_t + Vector((-0.06, 0.04, 0.05)), (0.30, 0.20, 0.20)), "armor", hero=True)
        add(box_mesh("belt_plate", hips_h + Vector((0.0, 0.06, 0.04)), (0.38, 0.18, 0.14)), "accent")
        add(box_mesh("chest_mass", mid + Vector((0.0, 0.12, 0.02)), (0.28, 0.10, 0.22)), "armor")
    elif fid == "juno-spark":
        add(_shell("torso_shell", stations, scale=1.20, start=1, end=4), "secondary")
        add(box_mesh("speed_panel_chest", mid + Vector((0.02, 0.13, 0.02)), (0.38, 0.18, 0.28)), "armor", hero=True)
        add(box_mesh("hip_panel_r", hips_h + Vector((-0.14, 0.09, 0.02)), (0.22, 0.16, 0.18)), "armor")
        add(box_mesh("hip_panel_l", hips_h + Vector((0.14, 0.09, 0.02)), (0.22, 0.16, 0.18)), "armor")
        add(_guard("thigh_mass_r", ul_h, ul_t, 0.062 * profile.thigh_mass), "armor")
        add(_guard("thigh_mass_l", ul_hl, ul_tl, 0.062 * profile.thigh_mass), "armor")
        add(_guard("sharp_calf_r", ll_h, ll_t, 0.044), "accent")
        add(_guard("sharp_calf_l", ll_hl, ll_tl, 0.044), "accent")
        add(box_mesh("volt_sash", mid + Vector((0.06, 0.13, 0.00)), (0.52, 0.12, 0.34)), "accent", hero=True)
        add(box_mesh("volt_panel_a", mid + Vector((0.14, 0.15, 0.04)), (0.26, 0.12, 0.26)), "accent", hero=True)
        add(box_mesh("volt_panel_b", mid + Vector((-0.10, 0.09, -0.02)), (0.20, 0.10, 0.20)), "accent")
    elif fid == "kaia-windrow":
        add(_shell("torso_shell", stations, scale=1.16, start=1, end=4), "secondary")
        add(box_mesh("chest_panel", mid + Vector((0.0, 0.13, 0.02)), (0.30, 0.14, 0.24)), "armor", hero=True)
        add(_guard("forearm_mass_r", la_h, la_t, 0.050 * profile.forearm_mass), "armor")
        add(_guard("forearm_mass_l", la_hl, la_tl, 0.050 * profile.forearm_mass), "armor")
        add(_guard("thigh_mass_r", ul_h, ul_t, 0.058 * profile.thigh_mass), "armor")
        add(_guard("thigh_mass_l", ul_hl, ul_tl, 0.058 * profile.thigh_mass), "armor")
        _nh, nt = bone_pts(arm_obj, "Neck")
        sl_h, sl_t = bone_pts(arm_obj, "Shoulder_L")
        sr_h, sr_t = bone_pts(arm_obj, "Shoulder_R")
        add(box_mesh("scarf_collar", nt + Vector((0.0, 0.05, 0.02)), (0.24, 0.14, 0.12)), "accent", hero=True)
        add(box_mesh("scarf_fall", nt + Vector((0.10, 0.10, -0.16)), (0.12, 0.14, 0.36)), "accent", hero=True)
        add(box_mesh("airfoil_l", sl_t + Vector((0.07, 0.04, 0.10)), (0.14, 0.06, 0.26)), "accent")
        add(box_mesh("airfoil_r", sr_t + Vector((-0.07, 0.04, 0.10)), (0.14, 0.06, 0.26)), "accent")
    elif fid == "nix-calder":
        add(box_mesh("frost_cuirass", mid + Vector((0.0, 0.12, 0.02)), (0.42, 0.18, 0.32)), "pale", hero=True)
        add(box_mesh("frost_plastron", mid + Vector((0.0, 0.16, -0.02)), (0.26, 0.12, 0.20)), "pale", hero=True)
        add(box_mesh("frost_pauldron_r", ua_h + Vector((-0.04, 0.04, 0.04)), (0.20, 0.14, 0.14)), "pale", hero=True)
        add(box_mesh("frost_pauldron_l", ua_hl + Vector((0.04, 0.04, 0.04)), (0.20, 0.14, 0.14)), "pale")
        add(box_mesh("crystal_core", mid + Vector((0.0, 0.16, 0.03)), (0.10, 0.06, 0.10)), "emit")
        add(box_mesh("crystal_trim", mid + Vector((0.0, 0.08, 0.12)), (0.24, 0.18, 0.05)), "accent")
        add(_guard("forearm_plate_r", la_h, la_t, 0.064), "armor", hero=True)
        add(_guard("forearm_plate_l", la_hl, la_tl, 0.064), "armor", hero=True)
        add(_guard("shin_facet_r", ll_h, ll_t, 0.048), "armor")
        add(_guard("shin_facet_l", ll_hl, ll_tl, 0.048), "armor")
        add(box_mesh("waist_band", hips_h + Vector((0.0, 0.05, 0.02)), (0.24, 0.12, 0.10)), "accent")
    elif fid == "orion-vell":
        add(_shell("coat_layer", stations, scale=1.36, start=1, end=7), "secondary")
        add(_shell("torso_shell", stations, scale=1.16, start=1, end=4), "secondary")
        add(box_mesh("authority_panel", mid + Vector((0.0, 0.15, 0.03)), (0.34, 0.14, 0.28)), "pale", hero=True)
        add(box_mesh("orbit_trim", mid + Vector((0.0, 0.05, 0.13)), (0.32, 0.24, 0.06)), "accent", hero=True)
        add(box_mesh("orbit_ring", Vector((0.00, 0.16, chest_t.z + 0.14)), (0.38, 0.30, 0.05)), "emit")
        add(_guard("forearm_mass_r", la_h, la_t, 0.048 * profile.forearm_mass), "glove")
        add(_guard("forearm_mass_l", la_hl, la_tl, 0.048 * profile.forearm_mass), "glove")
    elif fid == "vesper-nyx":
        add(_shell("torso_shell", stations, scale=1.14, start=1, end=3), "secondary")
        add(box_mesh("coat_cowl", mid + Vector((0.06, 0.08, 0.06)), (0.26, 0.16, 0.20)), "armor", hero=True)
        add(box_mesh("coat_panel_l", hips_h + Vector((0.18, 0.08, 0.10)), (0.22, 0.16, 0.38)), "armor", hero=True)
        add(box_mesh("coat_tail_l", hips_h + Vector((0.24, 0.07, -0.16)), (0.20, 0.24, 0.56)), "pale", hero=True)
        add(box_mesh("coat_tail_r", hips_h + Vector((-0.14, 0.05, -0.14)), (0.16, 0.18, 0.46)), "pale")
        add(box_mesh("void_trim", mid + Vector((0.02, 0.12, 0.02)), (0.18, 0.07, 0.16)), "accent")
        add(_guard("forearm_mass_r", la_h, la_t, 0.046 * profile.forearm_mass), "glove")
        add(_guard("forearm_mass_l", la_hl, la_tl, 0.040 * profile.forearm_mass), "glove")
    scale = hero_feature_scale(fid)
    if abs(scale - 1.0) > 1e-3:
        for obj in pieces:
            if obj.get("aa_hero_feature"):
                obj.scale = obj.scale * scale
    return pieces

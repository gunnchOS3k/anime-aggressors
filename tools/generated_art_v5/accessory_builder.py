"""Secondary silhouette accessories. Original designs only."""
from __future__ import annotations

from mathutils import Vector

from generated_art_v5.body_profiles import BodyProfile
from generated_art_v5.costume_builder import _panel
from generated_art_v5.torso_loft import bone_pts


def build_accessories(profile: BodyProfile, arm_obj, mats: dict):
    pieces = []
    fid = profile.fighter_id

    def add(obj, mat_key="emit"):
        obj.data.materials.append(mats.get(mat_key, mats["emit"]))
        obj["aa_accessory"] = 1
        pieces.append(obj)
        return obj

    if fid == "ember-vale":
        _hr, ht = bone_pts(arm_obj, "Hand_R")
        _hl, hlt = bone_pts(arm_obj, "Hand_L")
        add(_panel("flame_tongue_r", ht + Vector((0.01, 0.06, 0.01)), 0.04, 0.08, 0.08, 0.20), "emit")
        add(_panel("flame_tongue_l", hlt + Vector((-0.01, 0.05, 0.01)), 0.03, 0.07, 0.07, 0.20), "emit")
    elif fid == "orion-vell":
        _ch, ct = bone_pts(arm_obj, "Chest")
        add(_panel("orbit_ring", Vector((0.06, 0.10, ct.z + 0.08)), 0.28, 0.22, 0.03, 0.04), "emit")
    elif fid == "kaia-windrow":
        _hh, ht = bone_pts(arm_obj, "Head")
        add(_panel("ribbon", ht + Vector((0.05, 0.04, -0.02)), 0.03, 0.08, 0.16, 0.10), "accent")
    return pieces

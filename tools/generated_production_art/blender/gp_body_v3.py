"""Character-craft v3: remesh body core, then attach designed extremities and costume."""
from __future__ import annotations

import math

import bpy
from mathutils import Vector

from generated_production_art.body_v3 import MAX_ATTACH_M, recipe, shape_profile
from generated_production_art.profiles import FighterProfile

from gp_body_v2 import (  # noqa: E402
    _active,
    _apply,
    _assign,
    _bone_pts,
    _capsule,
    _connected_components,
    _join,
    _prim_cone,
    _prim_cube,
    _prim_cylinder,
    _prim_ico,
    _prim_sphere,
    _prim_torus,
    _smooth_and_decimate,
    _voxel_remesh,
    bind_smooth,
    foot_ground_gap,
    snap_to_ground,
)


def _bevel(obj, width=0.010, segments=2) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bev = obj.modifiers.new("AA_Bevel", "BEVEL")
    bev.width = max(0.003, width)
    bev.segments = segments
    bev.limit_method = "ANGLE"
    bev.angle_limit = math.radians(30.0)
    bpy.ops.object.modifier_apply(modifier=bev.name)


def _orient(obj, track: Vector, up=Vector((0.0, 0.0, 1.0))) -> None:
    if track.length < 1e-5:
        return
    obj.rotation_euler = track.normalized().to_track_quat("Z", "Y").to_euler()
    _apply(obj)


def _toon_mat_v3(name, color, emit=0.05, bands=3, rim=0.28, metallic=0.04, rough=0.62, shadow_hue=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (720, 0)
    diffuse = nt.nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.inputs["Color"].default_value = (color[0], color[1], color[2], 1.0)
    diffuse.inputs["Roughness"].default_value = rough
    diffuse.location = (0, 80)
    to_rgb = nt.nodes.new("ShaderNodeShaderToRGB")
    to_rgb.location = (180, 80)
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    while len(ramp.color_ramp.elements) < bands:
        ramp.color_ramp.elements.new(0.5)
    stops = [0.16, 0.48, 0.80][:bands]
    hue = shadow_hue or (color[0] * 0.55, color[1] * 0.42, color[2] * 0.62)
    shades = [
        (hue[0] * 0.35, hue[1] * 0.32, hue[2] * 0.40, 1.0),
        (color[0] * 0.58, color[1] * 0.56, color[2] * 0.60, 1.0),
        (min(1.0, color[0] * 1.12), min(1.0, color[1] * 1.10), min(1.0, color[2] * 1.08), 1.0),
    ]
    for i, (pos, shade) in enumerate(zip(stops, shades)):
        ramp.color_ramp.elements[i].position = pos
        ramp.color_ramp.elements[i].color = shade
    ramp.location = (360, 80)
    emit_n = nt.nodes.new("ShaderNodeEmission")
    emit_n.inputs["Color"].default_value = (color[0], color[1], color[2], 1.0)
    emit_n.inputs["Strength"].default_value = emit
    emit_n.location = (360, -140)
    add = nt.nodes.new("ShaderNodeAddShader")
    add.location = (540, 20)
    fresnel = nt.nodes.new("ShaderNodeFresnel")
    fresnel.inputs["IOR"].default_value = 1.42
    fresnel.location = (180, -160)
    rim_n = nt.nodes.new("ShaderNodeEmission")
    rim_n.inputs["Color"].default_value = (
        min(1.0, color[0] * 1.35),
        min(1.0, color[1] * 1.35),
        min(1.0, color[2] * 1.35),
        1.0,
    )
    rim_n.inputs["Strength"].default_value = rim
    rim_n.location = (360, -300)
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.location = (640, -80)
    nt.links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    nt.links.new(to_rgb.outputs["Color"], ramp.inputs["Fac"])
    emission_from_ramp = nt.nodes.new("ShaderNodeEmission")
    emission_from_ramp.inputs["Strength"].default_value = 0.92
    emission_from_ramp.location = (520, 120)
    nt.links.new(ramp.outputs["Color"], emission_from_ramp.inputs["Color"])
    nt.links.new(emission_from_ramp.outputs["Emission"], add.inputs[0])
    nt.links.new(emit_n.outputs["Emission"], add.inputs[1])
    nt.links.new(fresnel.outputs["Fac"], mix.inputs["Fac"])
    nt.links.new(add.outputs["Shader"], mix.inputs[1])
    nt.links.new(rim_n.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    if metallic > 0.08:
        gloss = nt.nodes.new("ShaderNodeBsdfGlossy")
        gloss.inputs["Roughness"].default_value = 0.22
        gloss.inputs["Color"].default_value = (min(1.0, color[0] * 1.2), min(1.0, color[1] * 1.2), min(1.0, color[2] * 1.2), 1.0)
    mat.diffuse_color = (color[0], color[1], color[2], 1.0)
    mat["aa_toon_bands"] = bands
    mat["aa_charge_ready"] = 1
    return mat


def _plate(loc, scale, name, rot=None, bevel=0.012):
    obj = _prim_cube(loc, scale, name)
    if rot is not None:
        obj.rotation_euler = rot
        _apply(obj)
    _bevel(obj, bevel)
    return obj


def _taper_limb(obj, axis="z", tip=0.72) -> None:
    for v in obj.data.vertices:
        t = (getattr(v.co, axis) + 0.5) if axis != "z" else (v.co.z + obj.dimensions.z * 0.25)
        factor = 1.0 - (1.0 - tip) * max(0.0, min(1.0, (v.co.z + 0.2)))
        v.co.x *= factor
        v.co.y *= factor


def _wrap_bone(arm_obj, bone_name, radius, name, extra=0.03):
    """Cylinder larger than the remesh limb so costume actually covers it."""
    h, t = _bone_pts(arm_obj, bone_name)
    mid = (h + t) * 0.5
    length = max(0.07, (t - h).length + extra)
    cyl = _prim_cylinder(mid, radius, length, name, verts=10)
    _orient(cyl, t - h)
    _bevel(cyl, min(0.010, radius * 0.18))
    return cyl


def _torso_shell(arm_obj, name, sx, sy, sz, y_bias=0.03):
    """Front cuirass with a keel back to the chest bone so attach audit stays honest."""
    chest_h, chest_t = _bone_pts(arm_obj, "Chest")
    mid = (chest_h + chest_t) * 0.5
    shell = _plate(mid + Vector((0.0, 0.20 + y_bias, 0.0)), (sx, sy, sz), name + "_shell", bevel=0.016)
    keel = _plate(mid + Vector((0.0, 0.10, 0.0)), (sx * 0.42, 0.22, sz * 0.48), name + "_keel", bevel=0.006)
    return _join([shell, keel], name)


def build_core_volumes(fid: str, p: FighterProfile, arm_obj):
    s = shape_profile(fid)
    sx, _sy, sz = p.body_scale
    lean = p.lean
    parts = []
    hips_h, _hips_t = _bone_pts(arm_obj, "Hips")
    spine_h, _spine_t = _bone_pts(arm_obj, "Spine")
    chest_h, chest_t = _bone_pts(arm_obj, "Chest")
    _neck_h, neck_t = _bone_pts(arm_obj, "Neck")
    head_h, _head_t = _bone_pts(arm_obj, "Head")

    def lean_y(z):
        return 0.04 * lean * (z / max(sz, 0.01))

    pelvis_r = 0.148 * s.pelvis_width
    waist_r = 0.112 * s.waist_width
    chest_rx = 0.168 * s.shoulder_width
    neck_r = 0.056 * s.neck_thickness
    parts.extend(_capsule(hips_h, spine_h, pelvis_r, "pelvis"))
    parts.append(_prim_sphere((0.0, lean_y(hips_h.z), hips_h.z), pelvis_r * 1.04, "pelvis_ball"))
    parts.extend(_capsule(spine_h, chest_h, waist_r, "waist"))
    chest = _prim_sphere(
        (0.0, 0.04 * lean + lean_y(chest_h.z) + 0.02 * s.chest_depth, (chest_h.z + chest_t.z) * 0.5),
        chest_rx,
        "chest_ball",
    )
    chest.scale = (1.18 + 0.12 * s.shoulder_width, 0.62 + 0.22 * s.chest_depth, 1.06)
    _apply(chest)
    parts.append(chest)
    parts.extend(_capsule(chest_t, neck_t, neck_r, "neck"))
    # Head/hand/foot stubs only — designed shells attach after remesh.
    parts.append(_prim_sphere(head_h, 0.038 * s.head_scale, "head_stub", segs=8))
    parts.append(_prim_sphere((0.0, lean_y(1.12 * sz), 1.12 * sz), 0.12 * s.waist_width, "torso_fill"))
    parts.append(_prim_sphere((0.18 * sx, lean_y(1.34 * sz), 1.34 * sz), 0.068 * s.shoulder_width, "clav_l"))
    parts.append(_prim_sphere((-0.18 * sx, lean_y(1.34 * sz), 1.34 * sz), 0.068 * s.shoulder_width, "clav_r"))

    for side, sgn in (("L", 1.0), ("R", -1.0)):
        sh_h, sh_t = _bone_pts(arm_obj, f"Shoulder_{side}")
        ua_h, ua_t = _bone_pts(arm_obj, f"UpperArm_{side}")
        la_h, la_t = _bone_pts(arm_obj, f"LowerArm_{side}")
        hd_h, _hd_t = _bone_pts(arm_obj, f"Hand_{side}")
        ul_h, ul_t = _bone_pts(arm_obj, f"UpperLeg_{side}")
        ll_h, ll_t = _bone_pts(arm_obj, f"LowerLeg_{side}")
        ft_h, _ft_t = _bone_pts(arm_obj, f"Foot_{side}")
        asy = 1.0 + (s.asymmetry * 0.35 if side == "R" else -s.asymmetry * 0.12)
        shoulder_r = 0.082 * s.shoulder_width * asy
        parts.append(_prim_sphere(sh_t, shoulder_r, f"shoulder_{side}"))
        parts.extend(_capsule(ua_h, ua_t, 0.056 * s.shoulder_width * 0.92, f"upper_arm_{side}"))
        parts.append(_prim_sphere(ua_t, 0.048, f"elbow_{side}"))
        parts.extend(_capsule(la_h, la_t, 0.046 * s.forearm_mass, f"forearm_{side}"))
        parts.append(_prim_sphere(la_t, 0.036 * s.forearm_mass, f"wrist_{side}"))
        parts.append(_prim_sphere(hd_h, 0.016 * s.hand_scale, f"hand_stub_{side}"))
        parts.extend(_capsule(ul_h, ul_t, 0.076 * s.pelvis_width, f"thigh_{side}"))
        parts.append(_prim_sphere(ul_t, 0.058 * s.calf_shape, f"knee_{side}"))
        shin = _capsule(ll_h, ll_t, 0.048 * s.calf_shape, f"shin_{side}")
        parts.extend(shin)
        parts.append(_prim_sphere(ll_t, 0.038 * s.calf_shape, f"ankle_{side}"))
        parts.append(_prim_sphere((ft_h.x, ft_h.y, max(0.02, ft_h.z * 0.35)), 0.018 * s.foot_boot_scale, f"foot_stub_{side}"))
    return parts


def _designed_hand(loc, side_sign, scale, strength, style, name):
    """Stylized low-poly hand: wide palm, side thumb wedge, grouped fingers, wrist cuff."""
    loc = Vector(loc)
    hs = scale * (2.45 if strength > 1.1 else 2.15)
    # Palm is a flat slab, not a cube. +Y is canonical front.
    palm = _plate(
        loc + Vector((0.006 * side_sign, 0.012, 0.0)),
        (0.088 * hs, 0.028 * hs, 0.052 * hs),
        name + "_palm",
        bevel=0.008,
    )
    if style == "fist":
        fingers = _plate(
            loc + Vector((0.008 * side_sign, 0.046 * hs, 0.006)),
            (0.082 * hs, 0.052 * hs, 0.056 * hs),
            name + "_fingers",
            bevel=0.010,
        )
        knuckle = _plate(
            loc + Vector((0.008 * side_sign, 0.028 * hs, 0.030 * hs)),
            (0.080 * hs, 0.016 * hs, 0.016 * hs),
            name + "_knuckle",
            bevel=0.003,
        )
        thumb = _plate(
            loc + Vector((0.095 * side_sign, 0.012, 0.012)),
            (0.048 * hs, 0.032 * hs, 0.028 * hs),
            name + "_thumb",
            rot=(0.10, 0.0, 0.35 * side_sign),
            bevel=0.006,
        )
    elif style == "open":
        fingers = _plate(
            loc + Vector((0.008 * side_sign, 0.078 * hs, 0.004)),
            (0.078 * hs, 0.088 * hs, 0.018 * hs),
            name + "_fingers",
            bevel=0.006,
        )
        knuckle = _plate(
            loc + Vector((0.008 * side_sign, 0.030 * hs, 0.022 * hs)),
            (0.076 * hs, 0.016 * hs, 0.012 * hs),
            name + "_knuckle",
            bevel=0.003,
        )
        thumb = _plate(
            loc + Vector((0.078 * side_sign, 0.028 * hs, 0.012)),
            (0.026 * hs, 0.052 * hs, 0.018 * hs),
            name + "_thumb",
            rot=(0.10, 0.0, 0.70 * side_sign),
            bevel=0.005,
        )
    else:  # guard / relaxed
        fingers = _plate(
            loc + Vector((0.006 * side_sign, 0.052 * hs, 0.016)),
            (0.074 * hs, 0.056 * hs, 0.028 * hs),
            name + "_fingers",
            rot=(0.55, 0.0, 0.0),
            bevel=0.007,
        )
        knuckle = _plate(
            loc + Vector((0.006 * side_sign, 0.026 * hs, 0.024 * hs)),
            (0.072 * hs, 0.014 * hs, 0.012 * hs),
            name + "_knuckle",
            bevel=0.003,
        )
        thumb = _plate(
            loc + Vector((0.070 * side_sign, 0.016, 0.016)),
            (0.032 * hs, 0.034 * hs, 0.020 * hs),
            name + "_thumb",
            rot=(0.40, 0.0, 0.48 * side_sign),
            bevel=0.005,
        )
    cuff = _prim_cylinder(
        loc + Vector((-0.022 * side_sign, -0.006, 0.0)),
        0.034 * hs,
        0.055 * hs,
        name + "_wrist",
        rot=(0.0, 1.57, 0.0),
        verts=10,
    )
    _bevel(cuff, 0.005)
    return _join([palm, fingers, knuckle, thumb, cuff], name)


def _designed_boot(fid, loc, scale, style, name):
    loc = Vector(loc)
    fs = scale * 1.72
    y = loc.y + 0.05 * fs  # toe toward +Y
    parts = []
    if style == "armored_heavy":
        parts.append(_plate((loc.x, y + 0.02, 0.062 * fs), (0.086 * fs, 0.078 * fs, 0.062 * fs), name + "_body", bevel=0.016))
        parts.append(_plate((loc.x, y - 0.05 * fs, 0.022), (0.078 * fs, 0.048 * fs, 0.020), name + "_heel", bevel=0.008))
        parts.append(_plate((loc.x, y + 0.14 * fs, 0.028), (0.074 * fs, 0.072 * fs, 0.022), name + "_toe", bevel=0.010))
        parts.append(_plate((loc.x, y + 0.04 * fs, 0.008), (0.090 * fs, 0.16 * fs, 0.012), name + "_sole", bevel=0.003))
        parts.append(_prim_cylinder((loc.x, y, 0.12 * fs), 0.048 * fs, 0.10 * fs, name + "_ankle", verts=10))
        parts.append(_plate((loc.x, y, 0.16 * fs), (0.070 * fs, 0.040 * fs, 0.055 * fs), name + "_shin", bevel=0.010))
    elif style == "speed_shoe":
        parts.append(_plate((loc.x, y + 0.05, 0.032 * fs), (0.052 * fs, 0.100 * fs, 0.024 * fs), name + "_body", bevel=0.006))
        parts.append(_prim_cone((loc.x, y + 0.14 * fs, 0.018), 0.024 * fs, 0.008, 0.062 * fs, name + "_toe", rot=(1.57, 0.0, 0.0)))
        parts.append(_plate((loc.x, y + 0.04, 0.006), (0.054 * fs, 0.14 * fs, 0.010), name + "_sole", bevel=0.002))
        parts.append(_plate((loc.x, y - 0.04 * fs, 0.018), (0.046 * fs, 0.028 * fs, 0.014), name + "_heel", bevel=0.004))
        parts.append(_prim_cylinder((loc.x, y, 0.055), 0.024 * fs, 0.048, name + "_ankle", verts=8))
    elif style == "aerial_boot":
        parts.append(_plate((loc.x, y + 0.04, 0.036 * fs), (0.050 * fs, 0.088 * fs, 0.026 * fs), name + "_body", bevel=0.007))
        parts.append(_plate((loc.x, y + 0.12 * fs, 0.018), (0.042 * fs, 0.050 * fs, 0.014), name + "_toe", bevel=0.004))
        parts.append(_plate((loc.x, y + 0.04, 0.006), (0.052 * fs, 0.13 * fs, 0.010), name + "_sole", bevel=0.002))
        parts.append(_plate((loc.x, y - 0.03 * fs, 0.016), (0.044 * fs, 0.026 * fs, 0.012), name + "_heel", bevel=0.003))
        parts.append(_prim_cylinder((loc.x, y, 0.08 * fs), 0.026 * fs, 0.062 * fs, name + "_ankle", verts=8))
    elif style == "frost_geometric":
        parts.append(_plate((loc.x, y + 0.02, 0.046 * fs), (0.066 * fs, 0.076 * fs, 0.040 * fs), name + "_body", bevel=0.004))
        parts.append(_prim_ico((loc.x, y + 0.12 * fs, 0.026), 0.030 * fs, name + "_toe", 1))
        parts.append(_plate((loc.x, y + 0.03, 0.008), (0.070 * fs, 0.14 * fs, 0.012), name + "_sole", bevel=0.002))
        parts.append(_plate((loc.x, y - 0.04 * fs, 0.018), (0.056 * fs, 0.030 * fs, 0.014), name + "_heel", bevel=0.003))
        parts.append(_prim_cylinder((loc.x, y, 0.10 * fs), 0.034 * fs, 0.07 * fs, name + "_ankle", verts=6))
    elif style == "cosmic_layered":
        parts.append(_plate((loc.x, y + 0.02, 0.046 * fs), (0.064 * fs, 0.078 * fs, 0.038 * fs), name + "_body", bevel=0.010))
        parts.append(_plate((loc.x, y + 0.02, 0.066 * fs), (0.072 * fs, 0.084 * fs, 0.012), name + "_layer", bevel=0.004))
        parts.append(_plate((loc.x, y + 0.13 * fs, 0.020), (0.052 * fs, 0.054 * fs, 0.016), name + "_toe", bevel=0.005))
        parts.append(_plate((loc.x, y + 0.04, 0.008), (0.068 * fs, 0.14 * fs, 0.012), name + "_sole", bevel=0.002))
        parts.append(_prim_cylinder((loc.x, y, 0.10 * fs), 0.032 * fs, 0.062 * fs, name + "_ankle", verts=10))
    elif style == "asymmetric_narrow":
        offset = 0.014 if "R" in name else -0.008
        parts.append(_plate((loc.x + offset, y + 0.04, 0.034 * fs), (0.042 * fs, 0.100 * fs, 0.022 * fs), name + "_body", bevel=0.005))
        parts.append(_prim_cone((loc.x + offset, y + 0.14 * fs, 0.016), 0.018 * fs, 0.006, 0.055, name + "_toe", rot=(1.57, 0.0, 0.0)))
        parts.append(_plate((loc.x + offset, y + 0.04, 0.006), (0.044 * fs, 0.14 * fs, 0.008), name + "_sole", bevel=0.002))
        parts.append(_plate((loc.x + offset, y - 0.04 * fs, 0.016), (0.036 * fs, 0.024 * fs, 0.012), name + "_heel", bevel=0.003))
        parts.append(_prim_cylinder((loc.x, y, 0.07 * fs), 0.022 * fs, 0.050, name + "_ankle", verts=8))
    else:  # heat_resistant
        parts.append(_plate((loc.x, y + 0.04, 0.046 * fs), (0.066 * fs, 0.086 * fs, 0.036 * fs), name + "_body", bevel=0.010))
        parts.append(_plate((loc.x, y - 0.04 * fs, 0.020), (0.058 * fs, 0.040 * fs, 0.016), name + "_heel", bevel=0.006))
        parts.append(_prim_cone((loc.x, y + 0.14 * fs, 0.022), 0.028 * fs, 0.010, 0.060 * fs, name + "_toe", rot=(1.45, 0.0, 0.0)))
        parts.append(_plate((loc.x, y + 0.04, 0.008), (0.070 * fs, 0.14 * fs, 0.012), name + "_sole", bevel=0.003))
        parts.append(_prim_cylinder((loc.x, y, 0.10 * fs), 0.034 * fs, 0.07 * fs, name + "_ankle", verts=10))
        parts.append(_plate((loc.x, y, 0.14 * fs), (0.048 * fs, 0.028 * fs, 0.040 * fs), name + "_shin", bevel=0.008))
    return _join(parts, name)


def _designed_head(fid, p, arm_obj, mats):
    s = shape_profile(fid)
    head_h, head_t = _bone_pts(arm_obj, "Head")
    center = (head_h + head_t) * 0.5
    center = Vector((center.x, center.y + 0.01 * p.lean, center.z + 0.02))
    hs = s.head_scale * 1.38
    style = s.head_style
    parts = []
    if style == "ember_crest_heat_mask":
        core = _prim_ico(center, 0.155 * hs, "head_core", 2)
        for v in core.data.vertices:
            v.co.x *= 1.10
            v.co.y *= 0.86
            v.co.z *= 0.92
            if v.co.y < 0.0:
                v.co.y *= 0.62
        parts.append(core)
        parts.append(_plate((center.x, center.y + 0.14 * hs, center.z + 0.008), (0.16 * hs, 0.055, 0.090 * hs), "heat_mask", bevel=0.006))
        parts.append(_plate((center.x, center.y + 0.04, center.z + 0.18 * hs), (0.16 * hs, 0.12 * hs, 0.070 * hs), "ember_cap_a", bevel=0.010))
        parts.append(_plate((center.x + 0.03, center.y + 0.06, center.z + 0.26 * hs), (0.090 * hs, 0.070 * hs, 0.050 * hs), "ember_cap_b", bevel=0.008))
        parts.append(_plate((center.x + 0.08 * hs, center.y + 0.01, center.z + 0.06), (0.032, 0.070, 0.10), "crest_fin", bevel=0.005))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.11), 0.058 * hs, 0.07, "neck_ring", verts=10))
    elif style == "plate_helm_void":
        parts.append(_plate(center, (0.20 * hs, 0.18 * hs, 0.18 * hs), "helm", bevel=0.022))
        parts.append(_plate((center.x, center.y + 0.08 * hs, center.z + 0.10 * hs), (0.22 * hs, 0.055, 0.048), "helm_brow", bevel=0.010))
        parts.append(_plate((center.x, center.y + 0.12 * hs, center.z + 0.01), (0.14 * hs, 0.028, 0.050), "visor_void", bevel=0.003))
        parts.append(_plate((center.x, center.y - 0.06, center.z + 0.04), (0.18 * hs, 0.050, 0.12 * hs), "helm_rear", bevel=0.012))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.12), 0.090, 0.08, "helm_neck", verts=10))
    elif style == "arc_crown_cap":
        cap = _prim_ico(center, 0.138 * hs, "head_core", 2)
        for v in cap.data.vertices:
            v.co.z *= 0.80
            v.co.x *= 1.12
            v.co.y *= 0.94
        parts.append(cap)
        parts.append(_plate((center.x, center.y + 0.10 * hs, center.z + 0.02), (0.12 * hs, 0.036, 0.060), "cap_mask", bevel=0.004))
        parts.append(_prim_torus((center.x, center.y + 0.02, center.z + 0.14 * hs), 0.14 * hs, 0.022, "arc_crown"))
        parts.append(_plate((center.x + 0.07, center.y + 0.06, center.z + 0.08), (0.055, 0.028, 0.070), "cap_fin", bevel=0.004))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.10), 0.050, 0.06, "neck_ring", verts=8))
    elif style == "ribbon_veil":
        core = _prim_ico(center, 0.140 * hs, "head_core", 2)
        for v in core.data.vertices:
            v.co.z *= 1.18
            v.co.x *= 0.86
            v.co.y *= 0.94
        parts.append(core)
        parts.append(_plate((center.x, center.y + 0.10 * hs, center.z + 0.02), (0.11 * hs, 0.032, 0.058), "veil_mask", bevel=0.004))
        parts.append(_plate((center.x, center.y + 0.04, center.z + 0.12 * hs), (0.16 * hs, 0.10, 0.032), "veil_band", bevel=0.006))
        parts.append(_plate((center.x + 0.05, center.y + 0.10, center.z - 0.06), (0.030, 0.14, 0.022), "veil_fall", bevel=0.004))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.10), 0.048, 0.06, "neck_ring", verts=8))
    elif style == "crystal_facet_mask":
        crystal = _prim_ico(center, 0.148 * hs, "head_core", 1)
        for v in crystal.data.vertices:
            v.co.x *= 1.08
            v.co.y *= 0.90
            v.co.z *= 1.16
        parts.append(crystal)
        parts.append(_prim_ico((center.x, center.y + 0.10 * hs, center.z + 0.02), 0.072, "facet_mask", 1))
        parts.append(_prim_ico((center.x + 0.07, center.y + 0.04, center.z + 0.10), 0.040, "facet_accent", 1))
        parts.append(_plate((center.x, center.y + 0.08 * hs, center.z + 0.08), (0.11, 0.024, 0.036), "facet_brow", bevel=0.003))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.11), 0.052, 0.06, "neck_ring", verts=6))
    elif style == "authority_orbit_halo":
        core = _prim_ico(center, 0.145 * hs, "head_core", 2)
        for v in core.data.vertices:
            v.co.z *= 1.18
            v.co.x *= 1.00
            v.co.y *= 0.86
        parts.append(core)
        parts.append(_plate((center.x, center.y + 0.10 * hs, center.z + 0.02), (0.12, 0.036, 0.060), "authority_plane", bevel=0.006))
        parts.append(_prim_torus((center.x + 0.05, center.y + 0.07, center.z + 0.14), 0.15 * hs, 0.016, "orbit_halo"))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.11), 0.054, 0.06, "neck_ring", verts=10))
    else:  # smoke_cowl_void
        cowl = _prim_ico(center + Vector((0.04, 0.03, 0.05)), 0.18 * hs, "cowl", 2)
        for v in cowl.data.vertices:
            v.co.y *= 1.22
            v.co.z *= 1.20
            if v.co.x > 0.03:
                v.co.x *= 1.28
        parts.append(cowl)
        parts.append(_prim_sphere(center, 0.100 * hs, "cowl_core", segs=10))
        parts.append(_plate((center.x - 0.03, center.y + 0.12 * hs, center.z), (0.11, 0.032, 0.070), "void_plane", bevel=0.003))
        parts.append(_plate((center.x + 0.08, center.y - 0.02, center.z + 0.05), (0.055, 0.080, 0.10), "cowl_asymm", bevel=0.008))
        parts.append(_prim_cylinder((center.x, center.y, center.z - 0.11), 0.054, 0.07, "neck_ring", verts=8))
    head = _join(parts, "head_shell")
    _assign(head, mats["hair"])
    return head


def build_designed_extremities(fid: str, p: FighterProfile, arm_obj, mats: dict):
    s = shape_profile(fid)
    rec = recipe(fid)
    pieces = []
    head = _designed_head(fid, p, arm_obj, mats)
    pieces.append((head, next(x for x in rec.accessories if x.name == "head_shell")))
    for side, sgn in (("L", 1.0), ("R", -1.0)):
        hd_h, _hd_t = _bone_pts(arm_obj, f"Hand_{side}")
        ft_h, _ft_t = _bone_pts(arm_obj, f"Foot_{side}")
        hand = _designed_hand(hd_h, sgn, s.hand_scale, s.hand_strength, rec.hand_default, f"hand_{side}")
        _assign(hand, mats["accent"])
        boot = _designed_boot(fid, ft_h, s.foot_boot_scale, rec.boot_style, f"boot_{side}")
        _assign(boot, mats["accent"])
        pieces.append((hand, next(x for x in rec.accessories if x.name == f"hand_{side}")))
        pieces.append((boot, next(x for x in rec.accessories if x.name == f"boot_{side}")))
    return pieces


def build_costume_v3(fid: str, p: FighterProfile, arm_obj, mats: dict):
    rec = recipe(fid)
    pieces = []

    def add(obj, spec_name, mat_key="accent"):
        spec = next((s for s in rec.accessories if s.name == spec_name), None)
        _assign(obj, mats.get(mat_key, mats["accent"]))
        pieces.append((obj, spec))
        return obj

    if fid == "ember-vale":
        _hr, ht = _bone_pts(arm_obj, "Hand_R")
        _hl, hlt = _bone_pts(arm_obj, "Hand_L")
        _sr, srt = _bone_pts(arm_obj, "Shoulder_R")
        add(_wrap_bone(arm_obj, "LowerArm_R", 0.125, "gauntlet_r", extra=0.06), "gauntlet_r", "accent")
        add(_wrap_bone(arm_obj, "LowerArm_L", 0.115, "gauntlet_l", extra=0.06), "gauntlet_l", "accent")
        add(_torso_shell(arm_obj, "chest_vent", 0.40, 0.12, 0.34, y_bias=0.04), "chest_vent", "charged")
        add(_wrap_bone(arm_obj, "UpperLeg_R", 0.135, "heat_guard_r", extra=0.05), "heat_guard_r", "secondary")
        add(_wrap_bone(arm_obj, "UpperLeg_L", 0.135, "heat_guard_l", extra=0.05), "heat_guard_l", "secondary")
        add(_plate(srt + Vector((0.02, 0.02, 0.03)), (0.12, 0.10, 0.10), "shoulder_accent", bevel=0.016), "shoulder_accent", "accent")
        add(_prim_cone((ht.x + 0.01, ht.y + 0.06, ht.z + 0.01), 0.030, 0.010, 0.08, "flame_tongue_r", rot=(1.2, 0.0, 0.0)), "flame_tongue_r", "charged")
        add(_prim_cone((hlt.x - 0.01, hlt.y + 0.05, hlt.z + 0.01), 0.024, 0.008, 0.07, "flame_tongue_l", rot=(1.2, 0.0, 0.0)), "flame_tongue_l", "charged")
    elif fid == "rook-ironside":
        _sl, slt = _bone_pts(arm_obj, "Shoulder_L")
        _sr, srt = _bone_pts(arm_obj, "Shoulder_R")
        _hp, hpt = _bone_pts(arm_obj, "Hips")
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_torso_shell(arm_obj, "chest_plate", 0.42, 0.24, 0.34, y_bias=0.04), "chest_plate", "secondary")
        add(_plate(slt + Vector((0.03, 0.02, 0.03)), (0.20, 0.16, 0.16), "shoulder_pad_l", bevel=0.022), "shoulder_pad_l", "secondary")
        add(_plate(srt + Vector((-0.03, 0.02, 0.03)), (0.20, 0.16, 0.16), "shoulder_pad_r", bevel=0.022), "shoulder_pad_r", "secondary")
        add(_wrap_bone(arm_obj, "LowerArm_L", 0.072, "forearm_plate_l", extra=0.04), "forearm_plate_l", "secondary")
        add(_wrap_bone(arm_obj, "LowerArm_R", 0.072, "forearm_plate_r", extra=0.04), "forearm_plate_r", "secondary")
        add(_plate((0.0, hpt.y + 0.04, hpt.z + 0.02), (0.28, 0.12, 0.10), "belt_plate", bevel=0.014), "belt_plate", "accent")
        add(_plate((0.0, ct.y - 0.08, ct.z), (0.28, 0.10, 0.22), "back_plate", bevel=0.016), "back_plate", "secondary")
    elif fid == "juno-spark":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        mid = Vector((0.0, ct.y + 0.18, ct.z))
        add(_plate(mid + Vector((0.09, 0.02, 0.02)), (0.14, 0.08, 0.18), "volt_panel_a", bevel=0.006), "volt_panel_a", "accent")
        add(_plate(mid + Vector((-0.07, 0.01, -0.02)), (0.12, 0.07, 0.15), "volt_panel_b", bevel=0.006), "volt_panel_b", "accent")
        sash = _plate(mid + Vector((0.02, 0.03, 0.0)), (0.36, 0.08, 0.10), "volt_sash", rot=(0.0, 0.0, 0.72), bevel=0.006)
        add(sash, "volt_sash", "charged")
        add(_plate(mid + Vector((0.10, 0.05, 0.04)), (0.060, 0.045, 0.080), "volt_tag", bevel=0.004), "volt_tag", "charged")
    elif fid == "kaia-windrow":
        _nh, nt = _bone_pts(arm_obj, "Neck")
        _hh, ht = _bone_pts(arm_obj, "Head")
        _sl, slt = _bone_pts(arm_obj, "Shoulder_L")
        _sr, srt = _bone_pts(arm_obj, "Shoulder_R")
        scarf = _join(
            [
                _plate((nt.x, nt.y + 0.02, nt.z), (0.16, 0.10, 0.08), "scarf_collar", bevel=0.012),
                _plate((nt.x + 0.04, nt.y + 0.06, nt.z - 0.16), (0.070, 0.10, 0.28), "scarf_fall_a", bevel=0.010),
                _plate((nt.x + 0.07, nt.y + 0.04, nt.z - 0.32), (0.050, 0.08, 0.20), "scarf_fall_b", bevel=0.008),
            ],
            "scarf",
        )
        add(scarf, "scarf", "accent")
        add(_plate((ht.x + 0.05, ht.y + 0.04, ht.z - 0.02), (0.032, 0.08, 0.18), "ribbon", bevel=0.005), "ribbon", "accent")
        add(_plate(slt + Vector((0.05, 0.02, 0.12)), (0.10, 0.055, 0.22), "airfoil_l", bevel=0.008), "airfoil_l", "accent")
        add(_plate(srt + Vector((-0.05, 0.02, 0.12)), (0.10, 0.055, 0.22), "airfoil_r", bevel=0.008), "airfoil_r", "accent")
        add(_torso_shell(arm_obj, "core_panel", 0.28, 0.16, 0.24, y_bias=0.03), "core_panel", "cloth")
    elif fid == "nix-calder":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        _sl, slt = _bone_pts(arm_obj, "Shoulder_L")
        add(_prim_ico((0.0, ct.y + 0.06, ct.z + 0.02), 0.070, "crystal_core", 1), "crystal_core", "charged")
        add(_torso_shell(arm_obj, "chest_plate", 0.32, 0.18, 0.26, y_bias=0.03), "chest_plate", "secondary")
        add(_prim_ico((slt.x, slt.y + 0.03, slt.z + 0.02), 0.058, "crystal_shoulder", 1), "crystal_shoulder", "accent")
        add(_wrap_bone(arm_obj, "LowerArm_R", 0.062, "forearm_plate_r", extra=0.03), "forearm_plate_r", "accent")
        add(_wrap_bone(arm_obj, "LowerArm_L", 0.062, "forearm_plate_l", extra=0.03), "forearm_plate_l", "accent")
    elif fid == "orion-vell":
        _ch, ct = _bone_pts(arm_obj, "Chest")
        add(_torso_shell(arm_obj, "vest_layer", 0.30, 0.16, 0.26, y_bias=0.04), "vest_layer", "secondary")
        add(_torso_shell(arm_obj, "coat_layer", 0.36, 0.14, 0.34, y_bias=0.00), "coat_layer", "cloth")
        add(_prim_torus((0.0, ct.y + 0.05, ct.z + 0.02), 0.12, 0.016, "orbit_trim"), "orbit_trim", "accent")
        ring = _prim_torus((0.06, 0.10, ct.z + 0.08), 0.20, 0.014, "orbit_ring")
        for v in ring.data.vertices:
            if abs(v.co.x) > 0.10:
                v.co.z *= 1.12
        add(ring, "orbit_ring", "charged")
    elif fid == "vesper-nyx":
        hp, _ht = _bone_pts(arm_obj, "Hips")
        add(_plate((0.12, hp.y + 0.04, hp.z + 0.10), (0.14, 0.10, 0.26), "coat_panel_l", bevel=0.014), "coat_panel_l", "secondary")
        add(_plate((-0.06, hp.y + 0.03, hp.z + 0.08), (0.10, 0.08, 0.20), "coat_panel_r", bevel=0.010), "coat_panel_r", "secondary")
        add(_plate((0.14, hp.y + 0.02, hp.z - 0.06), (0.06, 0.14, 0.28), "coat_tail_l", bevel=0.008), "coat_tail_l", "secondary")
        add(_plate((-0.07, hp.y + 0.01, hp.z - 0.04), (0.045, 0.10, 0.22), "coat_tail_r", bevel=0.006), "coat_tail_r", "secondary")
        add(_torso_shell(arm_obj, "void_trim", 0.24, 0.12, 0.20, y_bias=0.04), "void_trim", "accent")
    return pieces


def character_ground_gap(meshes) -> float:
    zs = []
    for obj in meshes:
        if obj is None or obj.type != "MESH":
            continue
        zs.extend((obj.matrix_world @ v.co).z for v in obj.data.vertices)
    return abs(min(zs)) if zs else 99.0


def bind_to_bone(obj, arm_obj, bone_name: str) -> None:
    """Rigid-follow a designed part. Auto-weights left these stuck in rest pose."""
    bpy.ops.object.mode_set(mode="OBJECT")
    mw = obj.matrix_world.copy()
    obj.parent = arm_obj
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = mw


def _purge_stray_meshes(keep_names: set[str]) -> None:
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            continue
        if obj.name.startswith("AA_Ref") or obj.name in keep_names:
            continue
        bpy.data.objects.remove(obj, do_unlink=True)


def snap_character(meshes) -> float:
    zs = []
    for obj in meshes:
        if obj is None or obj.type != "MESH":
            continue
        zs.extend((obj.matrix_world @ v.co).z for v in obj.data.vertices)
    if not zs:
        return 99.0
    minz = min(zs)
    if abs(minz) <= 0.002:
        return abs(minz)
    for obj in meshes:
        if obj is None or obj.type != "MESH":
            continue
        inv = obj.matrix_world.inverted()
        delta = inv.to_3x3() @ Vector((0.0, 0.0, -minz))
        for vert in obj.data.vertices:
            vert.co += delta
        obj.data.update()
    return character_ground_gap(meshes)


def paint_regions_v3(mesh_obj, arm_obj, mats: dict) -> None:
    mesh_obj.data.materials.clear()
    # Cloth first: an unpainted poly must read as costume, never nude skin.
    order = ["cloth", "secondary", "accent", "hair", "skin"]
    for key in order:
        mesh_obj.data.materials.append(mats[key])
    index = {k: i for i, k in enumerate(order)}
    bone_region = {
        "Head": "hair",
        "Neck": "cloth",
        "Chest": "cloth",
        "Spine": "cloth",
        "Hips": "cloth",
        "Shoulder_L": "cloth",
        "Shoulder_R": "cloth",
        "UpperArm_L": "cloth",
        "UpperArm_R": "cloth",
        "LowerArm_L": "secondary",
        "LowerArm_R": "secondary",
        "Hand_L": "accent",
        "Hand_R": "accent",
        "UpperLeg_L": "secondary",
        "UpperLeg_R": "secondary",
        "LowerLeg_L": "secondary",
        "LowerLeg_R": "secondary",
        "Foot_L": "accent",
        "Foot_R": "accent",
        "Toes_L": "accent",
        "Toes_R": "accent",
    }
    from mathutils.kdtree import KDTree

    bones = [b for b in arm_obj.data.bones if b.name in bone_region]
    tree = KDTree(len(bones))
    for i, bone in enumerate(bones):
        mid = arm_obj.matrix_world @ ((bone.head_local + bone.tail_local) * 0.5)
        tree.insert(mid, i)
    tree.balance()
    mw = mesh_obj.matrix_world
    neck_h, _neck_t = _bone_pts(arm_obj, "Neck")
    hips_h, _hips_t = _bone_pts(arm_obj, "Hips")
    for poly in mesh_obj.data.polygons:
        center = mw @ poly.center
        _co, idx, _dist = tree.find(center)
        key = bone_region[bones[idx].name]
        if center.z >= neck_h.z + 0.02:
            key = "hair"
        elif center.z >= hips_h.z + 0.02:
            key = "cloth"
        elif center.z >= 0.14:
            key = "secondary"
        else:
            key = "accent"
        if bones[idx].name.startswith("Hand"):
            key = "accent"
        poly.material_index = index[key]
    # Remesh must never read as nude skin. Keep skin only as an unused slot.
    if mats["skin"] in list(mesh_obj.data.materials):
        slot = list(mesh_obj.data.materials).index(mats["skin"])
        mesh_obj.data.materials[slot] = mats["cloth"]
    mesh_obj.data.update()


def audit_accessories(arm_obj, piece_pairs) -> tuple[list[dict], int]:
    rows = []
    unintentional = 0
    for obj, spec in piece_pairs:
        if spec is None or obj is None or obj.name not in bpy.data.objects:
            continue
        bone = arm_obj.data.bones.get(spec.parent_bone)
        if bone is None or not obj.data.vertices:
            continue
        attach = arm_obj.matrix_world @ bone.tail_local
        dist = min((obj.matrix_world @ vert.co - attach).length for vert in obj.data.vertices)
        floating = (not spec.intentional_float) and dist > MAX_ATTACH_M
        if floating:
            unintentional += 1
        rows.append(
            {
                "name": obj.name,
                "classification": spec.classification,
                "parent_bone": spec.parent_bone,
                "distance_m": round(dist, 4),
                "intentional_float": spec.intentional_float,
                "unintentional_floating": floating,
                "vertex_count": len(obj.data.vertices),
                "designed": True,
            }
        )
    return rows, unintentional


def build_crafted_fighter(fid: str, p: FighterProfile, arm_obj):
    s = shape_profile(fid)
    rec = recipe(fid)
    mats = {
        "skin": _toon_mat_v3(f"{fid}.mat.skin", p.skin, 0.01, 3, 0.08, 0.0, 0.62, shadow_hue=(0.28, 0.16, 0.22)),
        "cloth": _toon_mat_v3(f"{fid}.mat.cloth", p.primary, 0.03, 3, 0.20, 0.02, 0.58, shadow_hue=(p.secondary[0], p.secondary[1], p.secondary[2])),
        "secondary": _toon_mat_v3(f"{fid}.mat.secondary", p.secondary, 0.02, 3, 0.16, 0.28, 0.42),
        "accent": _toon_mat_v3(f"{fid}.mat.accent", p.accent, 0.18, 2, 0.24, 0.34, 0.28),
        "hair": _toon_mat_v3(f"{fid}.mat.hair", p.hair, 0.05, 3, 0.18, 0.02, 0.46),
        "charged": _toon_mat_v3(f"{fid}.mat.charged", p.charged, 0.28, 2, 0.22, 0.12, 0.26),
    }
    construction = build_core_volumes(fid, p, arm_obj)
    body = _join(construction, f"{fid}.mesh")
    _voxel_remesh(body, 0.013)
    if len(body.data.vertices) < 200:
        _voxel_remesh(body, 0.010)
    _smooth_and_decimate(body, target_tris=18000)
    islands = _connected_components(body)
    if islands > 1:
        _voxel_remesh(body, 0.018)
        _smooth_and_decimate(body, target_tris=18000)
        islands = _connected_components(body)
    paint_regions_v3(body, arm_obj, mats)
    extremities = build_designed_extremities(fid, p, arm_obj, mats)
    costume = build_costume_v3(fid, p, arm_obj, mats)
    attached = extremities + costume
    visible_meshes = [body] + [obj for obj, spec in attached if spec and not obj.hide_render]
    snap_character(visible_meshes)
    weight_info = bind_smooth(body, arm_obj)
    keep = {body.name}
    for obj, spec in attached:
        if spec is None:
            continue
        bind_to_bone(obj, arm_obj, spec.parent_bone)
        keep.add(obj.name)
    marker = bpy.data.objects.new("AA_FrontMarker", None)
    marker.empty_display_type = "ARROWS"
    marker.empty_display_size = 0.18
    chest_h, chest_t = _bone_pts(arm_obj, "Chest")
    marker.location = ((chest_h + chest_t) * 0.5) + Vector((0.0, 0.16, 0.0))
    marker.rotation_euler = (0.0, 0.0, 0.0)
    marker["aa_forward"] = (0.0, 1.0, 0.0)
    bpy.context.collection.objects.link(marker)
    bind_to_bone(marker, arm_obj, "Chest")
    keep.add(marker.name)
    _purge_stray_meshes(keep)
    accessory_rows, unintentional = audit_accessories(arm_obj, attached)
    visible = [(obj, spec) for obj, spec in attached if spec and not obj.hide_render]
    tris = len(body.data.polygons)
    for obj, _spec in visible:
        tris += len(obj.data.polygons)
    report = {
        "fighter": fid,
        "generator_revision": "character_craft_v4",
        "front_marker": "AA_FrontMarker",
        "canonical_forward": [0.0, 1.0, 0.0],
        "body_connected_components": islands,
        "triangles": tris,
        "body_triangles": len(body.data.polygons),
        "material_count": len(body.data.materials) + len({obj.name for obj, _ in visible}),
        "foot_ground_gap_m": round(character_ground_gap(visible_meshes), 4),
        "weight": weight_info,
        "accessories": accessory_rows,
        "unintentional_floating_accessories": unintentional,
        "shape_profile": {
            "head_style": s.head_style,
            "boot_style": s.boot_style,
            "hand_default": rec.hand_default,
            "hand_scale": s.hand_scale,
            "hand_strength": s.hand_strength,
            "costume_profile": s.costume_profile,
        },
        "designed_head": True,
        "designed_hands": True,
        "designed_boots": True,
        "designed_costume": True,
        "toon_bands": 3,
        "hand_shapes": list(rec.hand_shapes),
    }
    return body, [obj for obj, _ in attached], report

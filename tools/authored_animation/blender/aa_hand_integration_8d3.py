"""Editable palm/forearm interface sculpt on the exact corrected 8D2 sources.

No rebuilt rig, moved joint, copied body acting or gameplay change. Localized
surface edits retain topology/materials, with immutable before meshes. This is
a WIP art candidate; mesh validation does not approve anatomy or paired grip.
"""
import math
import bpy
import bmesh
from mathutils import Vector
from aa_controls_8d import points, digest
from aa_hand_anatomy_8d2 import preserve_part


def smooth(t):
    t = max(0., min(1., t))
    return t*t*(3-2*t)


def gaussian(value, centre, radius):
    return math.exp(-((value-centre)/radius)**2)


def verify_surface(ob, closed=True):
    bm = bmesh.new(); bm.from_mesh(ob.data)
    # Preserve face order and outward orientation. Reject folds/degeneracy,
    # rather than repairing an arbitrary corrupt surface into a passing one.
    result = {'vertices': len(bm.verts), 'faces': len(bm.faces),
              'boundary_edges': sum(e.is_boundary for e in bm.edges),
              'nonmanifold_edges': sum(not e.is_manifold for e in bm.edges),
              'minimum_face_area_m2': min(f.calc_area() for f in bm.faces),
              'signed_volume_m3': bm.calc_volume(signed=True)}
    bm.free()
    assert result['minimum_face_area_m2'] > 1e-14, ('Degenerate edited surface', ob.name, result)
    if closed:
        assert result['nonmanifold_edges'] == 0 and result['signed_volume_m3'] > 0, (ob.name, result)
    assert all(abs(sum(g.weight for g in v.groups)-1) < 1e-5 for v in ob.data.vertices)
    return result


def sculpt_palm(arm, hand, profile, archive):
    """Metacarpal pads and thenar volume on the existing connected surface.

    Retains digit lengths, joint locations, web topology and hand width. Raised
    masses follow actual Hand-bound vertices; no outward bone translations.
    """
    ob = bpy.data.objects[hand['mesh']]
    assert ob.data.shape_keys is None, 'Do not bypass existing hand morph authority'
    before = preserve_part(ob, archive)
    matrix = arm.matrix_world.inverted() @ ob.matrix_world; inverse = matrix.inverted()
    wrist = Vector(hand['wrist']); forward = Vector(hand['chains'][0]['axis']).normalized()
    normal = Vector(hand['chains'][0]['normal']).normalized()
    across = Vector((1 if hand['side'] == 'L' else -1, 0, 0))
    width, depth = hand['width_m'], hand['depth_m']; base = hand['distal_envelope_m']*.52
    hand_group = ob.vertex_groups['Hand_'+hand['side']].index
    changes = []
    for v in ob.data.vertices:
        bound = sum(g.weight for g in v.groups if g.group == hand_group)
        if bound < .05:
            continue
        original = matrix @ v.co; p = original-wrist
        u, f, n = p.dot(across), p.dot(forward), p.dot(normal)
        # Retain the closed wrist seam and original four finger origins.
        mask = smooth((f+.010)/.025)*(1-smooth((f-base*.72)/(base*.34)))
        thenar = gaussian(u, width*.28, width*.24)*gaussian(f, base*.43, base*.34)
        hypothenar = gaussian(u, -width*.30, width*.24)*gaussian(f, base*.42, base*.38)
        palmar = profile['thenar_depth']*thenar+profile['ulnar_depth']*hypothenar
        dorsal = 0.
        for cell in range(4):
            centre = (-.5+(cell+.5)*.25)*width*.96
            dorsal += gaussian(u, centre, width*.085)*gaussian(f, base*.77, base*.16)
        relief = palmar if n >= 0 else -profile['knuckle_depth']*dorsal
        displacement = normal*(depth*relief*mask*bound)
        v.co = inverse @ (original+displacement); changes.append(displacement.length)
    assert changes and max(changes) > .0002, 'No actual palm surface change'
    ob.data.update()
    return {'mesh': ob.name, 'before': before, 'max_surface_displacement_m': max(changes),
            'sculpt': 'Individual thenar/hypothenar/metacarpal relief; existing digit lengths, wrist and weights retained',
            'validation': verify_surface(ob)}


def forearm_interface(arm, hand, profile, archive, armor=False):
    """Resculpt only distal cap into the existing source wrist envelope.

    The old source capsule extends beyond its wrist, obscuring the palm. Keep
    proximal shape and length landmarks; use a monotone distal parameter and
    an elliptical wrist section measured from this hand, not character scale.
    Rook's armor is an open cuff: cap vertices are never welded onto skin.
    """
    side = hand['side']; name = 'Forearm '+side
    if armor:
        matches = [o for o in bpy.data.objects if o.name.startswith('Bastion forearm') and
                   any(g.name == 'LowerArm_'+side for g in o.vertex_groups)]
        assert len(matches) == 1, ('Exact Bastion cuff required', side)
        ob = matches[0]
    else:
        ob = bpy.data.objects[name]
    assert ob.data.shape_keys is None, 'Do not bypass source costume morphs'
    before = preserve_part(ob, archive)
    matrix = arm.matrix_world.inverted() @ ob.matrix_world; inverse = matrix.inverted()
    wrist = arm.data.bones['Hand_'+side].head_local.copy()
    elbow = arm.data.bones['LowerArm_'+side].head_local.copy()
    axis = (wrist-elbow).normalized(); length = (wrist-elbow).length
    coords = points(arm, ob); longitudinal = [(p-wrist).dot(axis) for p in coords]
    maximum = max(longitudinal); start = -length*profile['taper_fraction']
    # Open armor ends behind the actual wrist/palm. No new cuff slicing or
    # decorative cover: move existing distal surface vertices coherently.
    end = -.006 if armor else .003
    assert maximum > end and start < end and length > .03, ('No valid distal source cap', ob.name)
    across = Vector((1, 0, 0)); across = (across-axis*across.dot(axis)).normalized()
    normal = axis.cross(across).normalized()
    # Skin fits inside source palm wrist; armor surrounds it with clearance.
    rx = hand['width_m']*.5*.72 + (.006 if armor else 0.)
    ry = hand['depth_m']*.5*.80 + (.006 if armor else 0.)
    lower = ob.vertex_groups.get('LowerArm_'+side)
    assert lower is not None
    hg = ob.vertex_groups.get('Hand_'+side) or ob.vertex_groups.new(name='Hand_'+side)
    displacements = []; proximal_unchanged = 0
    for v, original, s in zip(ob.data.vertices, coords, longitudinal):
        if s <= start:
            proximal_unchanged += 1
            continue
        t = (s-start)/(maximum-start); blend = smooth(t)
        # Strictly monotone remap: no flattened rings or zero-area cap faces.
        ns = start+t*(end-start)
        radial = original-wrist-axis*s
        x, y = radial.dot(across), radial.dot(normal)
        radius = math.sqrt((x/rx)**2+(y/ry)**2)
        factor = 1. if radius <= 1 else 1+(1/radius-1)*blend
        new = wrist+axis*ns+radial*factor
        v.co = inverse @ new; displacements.append((new-original).length)
        if not armor:
            # Dual-bone wrist transition; preserve unit weights, avoid a rigid
            # forearm cap rotating through the palm during fist closure.
            w = smooth((s+.025)/.035)*.70
            for g in list(v.groups):
                ob.vertex_groups[g.group].remove([v.index])
            lower.add([v.index], 1-w, 'REPLACE'); hg.add([v.index], w, 'REPLACE')
    assert proximal_unchanged > 0 and displacements and max(displacements) > .001
    ob.data.update()
    return {'mesh': ob.name, 'before': before, 'armor': armor,
            'max_surface_displacement_m': max(displacements), 'proximal_vertices_preserved': proximal_unchanged,
            'distal_before_m': maximum, 'distal_after_m': max((p-wrist).dot(axis) for p in points(arm, ob)),
            'wrist_ellipse_m': [rx, ry], 'validation': verify_surface(ob, not armor)}


def author_auxiliary(arm, old_document, profile):
    """New editable digit acting, retaining existing character body actions.

    This owns hand closure only. It is not a paired-grip or full-body claim.
    Existing 8D2 source actions remain byte-for-byte unchanged.
    """
    clips = {}
    for category, clip in old_document['clips'].items():
        if category not in ('grip', 'fist', 'release'):
            clips[category] = dict(clip)
            continue
        original = bpy.data.actions[clip['source_action']]
        name = 'ANI08D3_'+category
        assert name not in bpy.data.actions
        action = original.copy(); action.name = name; action.use_fake_user = True
        if category in ('grip', 'fist', 'release'):
            for curve in action.fcurves:
                if not curve.data_path.startswith('pose.bones["D8_Finger_'):
                    continue
                digit = int(curve.data_path.split('D8_Finger_')[1].split('_')[1])
                # The source's own rotations/axes remain authoritative. A
                # character-specific staged closure controls thumb opposition
                # and individual finger cadence, not a copied torso pose.
                strength = profile['digit_curl'][digit]
                for key in curve.keyframe_points:
                    key.co.y *= strength
                    key.handle_left.y *= strength; key.handle_right.y *= strength
        clips[category] = {**clip, 'source_action': name}
    return clips

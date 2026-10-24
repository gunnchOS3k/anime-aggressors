"""Read preserved original GLB bind data without Blender or Godot imports.

No source writes, export, image/video processing or publication. Callers keep
per-source geometry/pose measurements in the existing encrypted workspace.
The result is SOURCE_GEOMETRY_ONLY, not source skin/native/human acceptance.
"""
import hashlib
import json
import struct
from pathlib import Path

from paired_animation_8d4 import read_glb
from arm_pose_space import (add, sub, mul, length, dot, cross, body_frame,
                            rigid_inverse_column_major, pole_direction,
                            solve_two_bone, qrotate)


def sha(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''):
            value.update(block)
    return value.hexdigest()


def inspect_bind(path):
    doc, binary = read_glb(path)
    if len(doc.get('skins', [])) != 1:
        raise ValueError('One preserved original source rig required')
    skin = doc['skins'][0]
    accessor = doc['accessors'][skin['inverseBindMatrices']]
    if accessor.get('componentType') != 5126 or accessor.get('type') != 'MAT4' or accessor.get('sparse') or accessor.get('normalized'):
        raise ValueError('Explicit FLOAT original inverse binds required')
    view = doc['bufferViews'][accessor['bufferView']]
    start = view.get('byteOffset', 0)+accessor.get('byteOffset', 0)
    stride = view.get('byteStride', 64)
    count = accessor['count']
    if (not isinstance(count, int) or count < 1 or view.get('buffer', 0) != 0 or stride < 64 or stride % 4
            or start < view.get('byteOffset', 0) or start+(count-1)*stride+64 > view.get('byteOffset', 0)+view['byteLength']
            or start+(count-1)*stride+64 > len(binary)):
        raise ValueError('Inverse bind accessor escapes original buffer')
    matrices = [struct.unpack_from('<16f', binary, start+i*stride) for i in range(count)]
    if len(matrices) != len(skin['joints']):
        raise ValueError('Original joint/bind count mismatch')
    bones = {}
    for node, matrix in zip(skin['joints'], matrices):
        name = doc['nodes'][node]['name']
        if name in bones:
            raise ValueError('Duplicate original joint identity')
        bones[name] = rigid_inverse_column_major(matrix)
    position = lambda name: tuple(row[3] for row in bones[name][:3])
    frame = body_frame(position('UpperArm_L'), position('UpperArm_R'), position('Chest'), position('Head'))
    foot_forward = add(sub(position('Toes_L'), position('Foot_L')),
                       sub(position('Toes_R'), position('Foot_R')))
    if dot(foot_forward, frame['forward']) <= 0:
        raise ValueError('Measured body forward disagrees with original toes')
    arms = {}
    for side in ('L', 'R'):
        u, e, w = [position(name+'_'+side) for name in ('UpperArm', 'LowerArm', 'Hand')]
        upper, lower = length(sub(e, u)), length(sub(w, e))
        # Child origins must follow actual bone Y, never an assumed global X.
        for name, vector in [('UpperArm_'+side, sub(e, u)), ('LowerArm_'+side, sub(w, e))]:
            axis = tuple(row[1] for row in bones[name][:3])
            if dot(vector, axis)/length(vector) < .99998:
                raise ValueError('Original bone roll/chain convention changed')
        arms[side] = {'shoulder': u, 'elbow': e, 'wrist': w,
                      'upper_length': upper, 'forearm_length': lower}
    return {'bone_count': len(bones), 'frame': frame, 'arms': arms,
            'bind_matrices': bones, 'forward_verified_by_original_toes': True}


def verify_original_sources(archive):
    base = Path(archive)
    runtime = base/'runtime'
    manifest = json.loads((runtime/'PRODUCTION_MANIFEST.json').read_text())
    rows = manifest['rows']
    expected = {(f, b) for f in ('ember-vale', 'rook-ironside', 'juno-spark', 'kaia-windrow',
                                 'nix-calder', 'orion-vell', 'vesper-nyx', 'yin', 'yang')
                for b in ('male', 'female')}
    if len(rows) != 18 or {(r['fighter'], r['body']) for r in rows} != expected:
        raise ValueError('Complete original18rig inventory required')
    result = []
    for row in rows:
        resource = runtime/row['resource']
        source = base/row['saved_source']
        if sha(resource) != row['resource_sha256'] or sha(source) != row['saved_source_sha256']:
            raise ValueError(('Immutable original source hash mismatch', row['fighter'], row['body']))
        result.append({'fighter': row['fighter'], 'body': row['body'],
                       'source_sha256': row['saved_source_sha256'],
                       'resource_sha256': row['resource_sha256'], **inspect_bind(resource)})
    return result


def verify_targets(bind, frames):
    """Check authored target samples against actual source length, both facings.

    Targets are armature-space directions/locations; this does not evaluate
    skin or create editable Blender curves. Failures are retained by callers.
    """
    records = []
    for facing in (1, -1):
        q = (0., 0. if facing == 1 else 1., 0., 1. if facing == 1 else 0.)
        rotate = lambda p: qrotate(q, p)
        for sample in frames:
            for side in ('L', 'R'):
                arm = bind['arms'][side]
                u = arm['shoulder']
                forward, up, right = (bind['frame'][x] for x in ('forward', 'up', 'right'))
                reach = arm['upper_length']+arm['forearm_length']
                offset = sample[side]
                target = add(u, mul(add(add(mul(forward, offset['forward']),
                                          mul(up, offset['up'])),
                                      mul(right, offset['outward']*(1 if side == 'R' else -1))), reach))
                pole = pole_direction(bind['frame'], side, **offset['pole'])
                solution = solve_two_bone(rotate(u), rotate(target), arm['upper_length'], arm['forearm_length'], rotate(pole))
                if not solution['reachable']:
                    raise ValueError(('Authored original arm target blocked', sample['frame'], side, solution))
                # Rotating the complete actor must rotate the solution exactly;
                # facing must not negate individual bone Euler components.
                canonical = solve_two_bone(u, target, arm['upper_length'], arm['forearm_length'], pole)
                error = length(sub(solution['elbow'], rotate(canonical['elbow'])))
                if error > 1e-10:
                    raise ValueError('Arm solve is not facing-equivariant')
                records.append({'frame': sample['frame'], 'side': side, 'facing': facing,
                                'elbow': solution['elbow'], 'wrist': solution['wrist'],
                                'flexion_radians': solution['flexion_radians'], 'rotation_error_m': error})
    return records

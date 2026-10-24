"""Source-bound orthographic observations, never an inferred shared 3D stage.

The native v2 ledger gives a rank-two projection. Its null space is a depth
direction, not a measured depth origin. Do not manufacture 3D contact from it.
This module has no Blender dependency so failure paths can be checked locally.
"""
import hashlib
import json
import math

SOURCE_RUN = 39886629245
SOURCE_SHA = 'ced4b78a141b5bf2bac05d4fc06488340c9aef2a'


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def cross(a, b):
    return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]


def finite_vector(value, length):
    if not isinstance(value, (list, tuple)) or len(value) != length or not all(isinstance(x, (int, float)) and math.isfinite(x) for x in value):
        raise ValueError('Missing/nonfinite measured vector')
    return list(value)


def projection_basis(observation):
    if observation.get('projection_version') not in (2, 3) or observation.get('camera_projection') != 1:
        raise ValueError('Exact orthographic v2/v3 observation required')
    right = finite_vector(observation['source_right_delta_px'], 2)
    up = finite_vector(observation['source_up_delta_px'], 2)
    forward = finite_vector(observation['source_forward_delta_px'], 2)
    # Blender x,y,z -> Godot x,z,-y. All points are armature-local metres.
    rows = [[right[i], -forward[i], up[i]] for i in range(2)]
    norm = [math.sqrt(dot(r, r)) for r in rows]
    depth = cross(*rows)
    area = math.sqrt(dot(depth, depth))
    if min(norm) < 1e-8 or area/min(norm)/max(norm) < 1e-6:
        raise ValueError('Degenerate native projection basis')
    return rows, [x/area for x in depth]


def project(observation, source_point):
    rows, _ = projection_basis(observation)
    origin = finite_vector(observation['origin'], 2)
    point = finite_vector(source_point, 3)
    return [origin[i]+dot(rows[i], point) for i in range(2)]


def require_3d_stage(measurement, holder_hash, victim_hash):
    """Fail closed: even full independent cameras do not define a shared stage."""
    if measurement['hand_sources'] != {'holder': holder_hash, 'victim': victim_hash}:
        raise ValueError('Paired observation does not match exact saved source hashes')
    for role in ('holder', 'victim'):
        p = measurement[role+'_projection']
        projection_basis(p)
        if p.get('projection_version') != 3:
            raise ValueError('Projection v2 has no measured depth/transforms; 3D bake blocked')
        for name in ('rig_world_transform', 'camera_world_transform'):
            matrix = p.get(name)
            if not isinstance(matrix, list) or len(matrix) != 4:
                raise ValueError('Missing measured '+name)
            for row in matrix:
                finite_vector(row, 4)
            if matrix[3] != [0, 0, 0, 1]:
                raise ValueError('Invalid affine transform')
            a, b, c = [row[:3] for row in matrix[:3]]
            axes = (a, b, c)
            if abs(dot(a, cross(b, c))-1) > 1e-4 or any(abs(dot(axes[i], axes[j])-int(i == j)) > 1e-4 for i in range(3) for j in range(3)):
                raise ValueError('Transform scales/distorts source anatomy')
    stage = measurement.get('shared_physical_stage')
    if not stage or stage.get('authority') != 'measured_common_metric_space':
        raise ValueError('Independent viewports have no measured shared physical stage')
    return stage


def ledger_report(ledger, manifest):
    if manifest.get('source_sha') != SOURCE_SHA or int(manifest.get('run_id', 0)) != SOURCE_RUN or not manifest.get('complete'):
        raise ValueError('Not the completed corrected 8D2 input')
    if not ledger.get('PASS') or not ledger.get('complete'):
        raise ValueError('Incomplete native input ledger')
    hashes = {(r['fighter'], r['body']): r['saved_source_sha256'] for r in manifest['rows']}
    if len(hashes) != 18:
        raise ValueError('Eighteen unique saved bodies required')
    ids = list(dict.fromkeys(r['fighter'] for r in manifest['rows']))
    source_identity = {value: key for key, value in hashes.items()}
    if len(source_identity) != 18:
        raise ValueError('Saved source identities must be unique')
    cases = []
    coverage = set()
    for row in ledger['rows']:
        fid, body, facing = row['fighter'], row['body'], row['facing']
        if facing not in (-1, 1) or (fid, body) not in hashes:
            raise ValueError('Unknown source/body/facing')
        other = ids[(ids.index(fid)+1) % len(ids)]
        hh = hashes[fid, body]
        for phase, m in row['measurements'].items():
            sources = m.get('hand_sources', {})
            vh = sources.get('victim')
            # Escape fixtures intentionally use the opposite body. Bind it by
            # actual imported source hash, never infer it from the holder body.
            if sources.get('holder') != hh or source_identity.get(vh, (None, None))[0] != other:
                raise ValueError('Source mismatch: '+row['case']+':'+phase)
            projection_basis(m['holder_projection']); projection_basis(m['victim_projection'])
            try:
                require_3d_stage(m, hh, vh)
                reason = None
            except ValueError as error:
                reason = str(error)
            cases.append({'case': row['case'], 'phase': phase, 'holder_sha256': hh, 'victim_sha256': vh,
                          'victim_fighter': other, 'victim_body': source_identity[vh][1],
                          'projection_2d_verified': True, 'paired_3d_ready': reason is None, 'blocker': reason})
            coverage.add((fid, body, facing))
    if coverage != {(f, b, face) for f, b in hashes for face in (-1, 1)}:
        raise ValueError('Missing body/facing contact observations')
    return {'schema': 'paired_projection_readiness_8d3.v1', 'source_run': SOURCE_RUN, 'source_sha': SOURCE_SHA,
            'configurations': len(coverage), 'measurements': len(cases), 'cases': cases,
            'paired_3d_ready': all(c['paired_3d_ready'] for c in cases), 'human_approved': False,
            'ledger_sha256': hashlib.sha256(json.dumps(ledger, sort_keys=True).encode()).hexdigest()}

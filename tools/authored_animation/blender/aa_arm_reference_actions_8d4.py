"""Bake fighter-authored arm references on preserved original body acting.

The direction score is PRIVATE, outside Git. This module contains no character
curves. It never starts Blender, selects a roster subset, replaces old actions,
or authorizes export. The guarded local producer must own execution. Reference
clip timing is offline acting; no gameplay move is mapped automatically.
"""
import bpy
from mathutils import Quaternion, Vector

from aa_arm_foundation_8d4 import rest_frame, solve_original_arm
from aa_metric_pair_reference_8d4 import sample_action, assert_preserved


def author_reference_action(actor, profile, *, new_name=None):
    """All arms use measured rest/chest space, including nonleading guard.

    The character's existing body action supplies pelvis/legs/head. Only its
    invalid arm chain is replaced here. Original torso/foot acting is retained
    as a candidate, not certified by this correction. No generic body action
    is copied from another fighter or presentation.
    """
    arm = actor['arm']
    source = actor['actions'][profile['source_action']]
    name = new_name or profile['new_action']
    if name in bpy.data.actions:
        raise ValueError('Do not overwrite an existing original/candidate action')
    frames = profile['frames']
    if not frames or [s['frame'] for s in frames] != list(range(len(frames))):
        raise ValueError('Explicit consecutive authored source clock required')
    if profile['fps'] != 60 or profile['gameplay_timing_authority'] is not False:
        raise ValueError('This action has no authority to retime gameplay')
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    action['art_status'] = 'ORIGINAL_ARM_REFERENCE_NATIVE_AND_HUMAN_PENDING'
    action['source_action'] = source.name
    action['fighter'] = profile['fighter']
    action['bible_sha256'] = profile['bible_sha256']
    body = rest_frame(arm)
    first, last = source.frame_range
    prior_quaternions = {}
    reports = []
    # Bake full ORIGINAL body with the corrected arms. There are no armature
    # object/root shifts, bone translation tracks or anatomical scale changes.
    for sample in frames:
        f = sample['frame']
        sample_action(actor, source, first+(last-first)*f/max(1, len(frames)-1))
        for side in ('L', 'R'):
            fields = sample[side]
            chest = arm.pose.bones['Chest']
            delta = chest.matrix @ arm.data.bones['Chest'].matrix_local.inverted()
            u = delta @ arm.data.bones['UpperArm_'+side].head_local
            reach = ((arm.data.bones['LowerArm_'+side].head_local-arm.data.bones['UpperArm_'+side].head_local).length
                     +(arm.data.bones['Hand_'+side].head_local-arm.data.bones['LowerArm_'+side].head_local).length)
            offset = (Vector(body['forward'])*fields['forward']+Vector(body['up'])*fields['up']
                      +Vector(body['right'])*fields['outward']*(1 if side == 'R' else -1))*reach
            wrist = u+delta.to_quaternion() @ offset
            report = solve_original_arm(arm, side, wrist, **fields['pole'])
            if not report['reachable']:
                raise ValueError(('Blocked original source target', actor['role'], f, side, report))
            reports.append({'frame': f, 'side': side, **report})
        # Preserve source quaternion hemisphere across keys; no Euler branch
        # flip or L/R sign hack. Sampling source action and baking are separate.
        values = {p.name: (p.matrix_basis.to_quaternion().copy(), p.location.copy()) for p in arm.pose.bones}
        arm.animation_data.action = action
        for p in arm.pose.bones:
            q, location = values[p.name]
            if p.name in prior_quaternions and q.dot(prior_quaternions[p.name]) < 0:
                q.negate()
            prior_quaternions[p.name] = q.copy()
            p.rotation_mode = 'QUATERNION'
            p.rotation_quaternion = q
            p.location = location
            p.keyframe_insert(data_path='rotation_quaternion', frame=f, group=p.name)
            # Only existing body translations survive. Arm chains cannot gain
            # location/scale tracks to make a target artificially reachable.
            if p.name == 'Hips':
                p.keyframe_insert(data_path='location', frame=f, group=p.name)
    for curve in action.fcurves:
        for key in curve.keyframe_points:
            key.interpolation = 'LINEAR'
    arm.animation_data.action = action
    assert_preserved(actor)
    return {'action': name, 'source_action': source.name, 'frames': len(frames),
            'arm_reports': reports, 'native_visual_verified': False,
            'paired_surface_verified': False, 'human_approved': False}

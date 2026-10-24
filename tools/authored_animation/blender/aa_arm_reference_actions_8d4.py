"""Bake fighter-authored arm references on preserved original body acting.

The direction score is PRIVATE, outside Git. This module contains no character
curves. It never starts Blender, selects a roster subset, replaces old actions,
or authorizes export. The guarded local producer must own execution. Reference
clip timing is offline acting; no gameplay move is mapped automatically.
"""
import bpy
from mathutils import Vector

from aa_arm_foundation_8d4 import rest_frame, solve_original_arm
from aa_metric_pair_reference_8d4 import sample_action, assert_preserved
from arm_pose_space import validate_direction_profile


def apply_reference_arm_pose(arm, sample, *, wrist_targets=None):
    """One shared posed-rig boundary for independent or paired authoring.

    A paired target must be an actual source-space point supplied by the
    surface author. It never changes bone lengths/actor placement. Palm
    orientation is neutral here; the mesh-grip stage owns explicit contact.
    """
    body = rest_frame(arm)
    reports = []
    for side in ('L', 'R'):
        fields = sample[side]
        delta = arm.pose.bones['Chest'].matrix @ arm.data.bones['Chest'].matrix_local.inverted()
        u = delta @ arm.data.bones['UpperArm_'+side].head_local
        reach = ((arm.data.bones['LowerArm_'+side].head_local-arm.data.bones['UpperArm_'+side].head_local).length
                 +(arm.data.bones['Hand_'+side].head_local-arm.data.bones['LowerArm_'+side].head_local).length)
        offset = (Vector(body['forward'])*fields['forward']+Vector(body['up'])*fields['up']
                  +Vector(body['right'])*fields['outward']*(1 if side == 'R' else -1))*reach
        wrist = (wrist_targets or {}).get(side, u+delta.to_quaternion() @ offset)
        report = solve_original_arm(arm, side, wrist, **fields['pole'])
        if not report['reachable']:
            raise ValueError(('Blocked original source target', sample['frame'], side, report))
        reports.append({'frame': sample['frame'], 'side': side, **report})
    return reports


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
    identity = actor['observation']
    frames = validate_direction_profile(profile, fighter=identity['fighter'], body=identity['body'])
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    action['art_status'] = 'ORIGINAL_ARM_REFERENCE_NATIVE_AND_HUMAN_PENDING'
    action['source_action'] = source.name
    action['fighter'] = profile['fighter']
    action['bible_sha256'] = profile['bible_sha256']
    first, last = source.frame_range
    original_modes = {p.name:p.rotation_mode for p in arm.pose.bones}
    if any(mode != 'XYZ' for mode in original_modes.values()):
        raise ValueError('Explicit rotation-mode compatibility migration required for this source')
    prior_eulers = {}
    reports = []
    # Bake full ORIGINAL body with the corrected arms. There are no armature
    # object/root shifts, bone translation tracks or anatomical scale changes.
    for sample in frames:
        f = sample['frame']
        sample_action(actor, source, first+(last-first)*f/max(1, len(frames)-1))
        reports.extend(apply_reference_arm_pose(arm, sample))
        # Derive every local rotation from the solved original pose. Filter
        # Euler branches without changing the original XYZ rotation modes;
        # switching bones to QUATERNION would disable their old Euler actions.
        values = {p.name: (p.matrix_basis.to_quaternion().copy(), p.location.copy()) for p in arm.pose.bones}
        arm.animation_data.action = action
        for p in arm.pose.bones:
            q, location = values[p.name]
            if p.name != 'Hips' and location.length > .00001:
                raise ValueError(('Unhandled original translation must not be dropped', p.name))
            if max(abs(s-1.) for s in p.scale) > .00001:
                raise ValueError(('Unhandled original scale must not be dropped', p.name))
            euler = q.to_euler('XYZ')
            if p.name in prior_eulers:
                euler.make_compatible(prior_eulers[p.name])
            prior_eulers[p.name] = euler.copy()
            p.rotation_mode = 'XYZ'
            p.rotation_euler = euler
            p.location = location
            p.keyframe_insert(data_path='rotation_euler', frame=f, group=p.name)
            # Only existing body translations survive. Arm chains cannot gain
            # location/scale tracks to make a target artificially reachable.
            if p.name == 'Hips':
                p.keyframe_insert(data_path='location', frame=f, group=p.name)
    for curve in action.fcurves:
        for key in curve.keyframe_points:
            key.interpolation = 'LINEAR'
    arm.animation_data.action = action
    if any(p.rotation_mode != original_modes[p.name] for p in arm.pose.bones):
        raise ValueError('Original action rotation modes changed')
    assert_preserved(actor)
    return {'action': name, 'source_action': source.name, 'frames': len(frames),
            'arm_reports': reports, 'native_visual_verified': False,
            'paired_surface_verified': False, 'human_approved': False}

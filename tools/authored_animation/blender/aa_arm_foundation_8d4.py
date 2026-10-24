"""Original-rig arm authoring in measured rest/chest space (Blender 4.0).

This replaces inherited elbow poles and accumulated bad pose roll. It changes
POSES only. Original rest bones, source anatomy, roots and skinning survive.
Source export/native visual review are still required before shipping use.
"""
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from arm_pose_space import body_frame, pole_direction, solve_two_bone


def rest_frame(arm):
    bones = arm.data.bones
    return body_frame(bones['UpperArm_L'].head_local, bones['UpperArm_R'].head_local,
                      bones['Chest'].head_local, bones['Head'].head_local)


def solve_original_arm(arm, side, wrist, hand_q=None, *, pole=None,
                       clavicle_delta=None, outward=.65, down=.75, forward=.10):
    """Targets and optional orientations are in armature space.

    Pole is a direction, never a screen point or a previous elbow. With no
    explicit palm orientation, transport the ORIGINAL hand-to-forearm rest
    relation; do not reset wrist Euler angles in an assumed universal axis.
    """
    if side not in ('L', 'R'):
        raise ValueError('Explicit original arm side required')
    b = arm.data.bones
    shoulder = arm.pose.bones['Shoulder_'+side]
    upper = arm.pose.bones['UpperArm_'+side]
    lower = arm.pose.bones['LowerArm_'+side]
    hand = arm.pose.bones['Hand_'+side]
    chest = arm.pose.bones['Chest']
    # The original 8B action's shoulder/upper-arm roll is NOT a reference.
    # Follow the authored torso, then apply a declared clavicle rotation in
    # chest-local rest space. Never invert L/R or mirror the actor transform.
    torso_delta = chest.matrix @ b['Chest'].matrix_local.inverted()
    shoulder_reference = torso_delta @ b[shoulder.name].matrix_local
    delta = clavicle_delta or Quaternion()
    if abs(delta.magnitude-1.) > 1e-5:
        raise ValueError('Clavicle delta must be a unit rotation')
    shoulder_reference = (Matrix.Translation(shoulder_reference.translation)
                          @ (chest.matrix.to_quaternion() @ delta
                             @ chest.matrix.to_quaternion().inverted()).to_matrix().to_4x4()
                          @ shoulder_reference.to_quaternion().to_matrix().to_4x4())
    upper_reference = shoulder_reference @ b[shoulder.name].matrix_local.inverted() @ b[upper.name].matrix_local
    u = upper_reference.translation
    a = (b[lower.name].head_local-b[upper.name].head_local).length
    c = (b[hand.name].head_local-b[lower.name].head_local).length
    distance = (Vector(wrist)-u).length
    # Retain the original Blender producer's 10-micrometre reach margin.
    # The portable analytic solver's numerical epsilon is not permission to
    # move a quantised source rig closer to singular full extension.
    if distance >= a+c-.00001 or distance <= abs(a-c)+.00001:
        return {'reachable':False, 'reason':'original_source_reach_margin',
                'reach_excess_m':max(distance-a-c, abs(a-c)-distance, 0.)}
    if pole is None:
        direction = Vector(pole_direction(rest_frame(arm), side, outward=outward, down=down, forward=forward))
        pole = torso_delta.to_quaternion() @ direction
    solution = solve_two_bone(u, wrist, a, c, pole)
    if not solution['reachable']:
        return solution  # No partial pose mutation on failure.
    elbow = Vector(solution['elbow'])
    shoulder.matrix = shoulder_reference
    bpy.context.view_layer.update()
    # Swing from each rest-transported bone. Reusing a bad current matrix
    # carries its axial roll into the result even if the wrist position fits.
    rest_axis = upper_reference.to_quaternion() @ Vector((0, 1, 0))
    q = rest_axis.rotation_difference(elbow-u) @ upper_reference.to_quaternion()
    upper.matrix = Matrix.LocRotScale(u, q, Vector((1, 1, 1)))
    bpy.context.view_layer.update()
    lower_reference = upper.matrix @ b[upper.name].matrix_local.inverted() @ b[lower.name].matrix_local
    e = lower.matrix.translation.copy()
    axis = lower_reference.to_quaternion() @ Vector((0, 1, 0))
    q = axis.rotation_difference(Vector(wrist)-e) @ lower_reference.to_quaternion()
    lower.matrix = Matrix.LocRotScale(e, q, Vector((1, 1, 1)))
    bpy.context.view_layer.update()
    neutral_hand = lower.matrix @ b[lower.name].matrix_local.inverted() @ b[hand.name].matrix_local
    hand.matrix = Matrix.LocRotScale(hand.matrix.translation,
                                   hand_q if hand_q is not None else neutral_hand.to_quaternion(), Vector((1, 1, 1)))
    bpy.context.view_layer.update()
    residual = (hand.matrix.translation-Vector(wrist)).length
    if residual >= .00005:
        raise ValueError(('Original arm residual', side, residual))
    for p in (shoulder, upper, lower, hand):
        if p.location.length > .00005 or max(abs(x-1) for x in p.scale) > .00005:
            raise ValueError(('Original arm must not translate/stretch', p.name))
    return {**solution, 'wrist_residual_m': residual,
            'reference': 'original_rest_transported_by_authored_chest',
            'wrist_rest_relative_angle_rad': neutral_hand.to_quaternion().rotation_difference(hand.matrix.to_quaternion()).angle}

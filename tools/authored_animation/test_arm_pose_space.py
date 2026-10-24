"""Solver failure boundaries and coordinate invariance; not visual approval."""
import math
import unittest

from arm_pose_space import (add, sub, mul, dot, length, body_frame,
                            pole_direction, solve_two_bone, qrotate,
                            rigid_inverse_column_major, validate_direction_profile)


class OriginalArmGeometry(unittest.TestCase):
    def setUp(self):
        self.frame = body_frame((-.2, 0, .7), (.2, 0, .7), (0, 0, .6), (0, 0, .9))

    def test_blender_to_godot_forward_and_both_sides(self):
        self.assertEqual(self.frame['forward'], (0., -1., 0.))
        for side in ('L', 'R'):
            pole = pole_direction(self.frame, side)
            self.assertGreater(dot(pole, mul(self.frame['right'], 1 if side == 'R' else -1)), 0)
            self.assertLess(dot(pole, self.frame['up']), 0)

    def test_exact_lengths_and_no_inward_elbow(self):
        for side in ('L', 'R'):
            shoulder = ((1 if side == 'R' else -1)*.2, 0, .7)
            wrist = add(shoulder, (0, -.26, -.025))
            result = solve_two_bone(shoulder, wrist, .19, .14, pole_direction(self.frame, side))
            self.assertTrue(result['reachable'])
            self.assertAlmostEqual(length(sub(result['elbow'], shoulder)), .19)
            self.assertAlmostEqual(length(sub(wrist, result['elbow'])), .14)
            self.assertGreater((result['elbow'][0]-shoulder[0])*(1 if side == 'R' else -1), 0)

    def test_opposite_facing_is_a_rotation_not_a_side_swap(self):
        shoulder = (.2, 0, .7)
        wrist = (.18, -.27, .65)
        pole = pole_direction(self.frame, 'R')
        first = solve_two_bone(shoulder, wrist, .19, .14, pole)
        for angle in (math.pi, .37, -1.1):
            q = (0, 0, math.sin(angle/2), math.cos(angle/2))
            rotate = lambda v: qrotate(q, v)
            second = solve_two_bone(rotate(shoulder), rotate(wrist), .19, .14, rotate(pole))
            self.assertLess(length(sub(second['elbow'], rotate(first['elbow']))), 1e-12)

    def test_source_space_units_do_not_introduce_dimensions(self):
        base = solve_two_bone((0, 0, 0), (0, -.25, .02), .19, .14, (1, 0, -1))
        for scale in (.7, 1.2):
            result = solve_two_bone((0, 0, 0), (0, -.25*scale, .02*scale), .19*scale, .14*scale, (1, 0, -1))
            self.assertLess(length(sub(result['elbow'], mul(base['elbow'], scale))), 1e-12)

    def test_unreachable_and_parallel_pole_are_blocked(self):
        for wrist in ((0, 0, 0), (0, 0, .4), (0, 0, .001)):
            self.assertFalse(solve_two_bone((0, 0, 0), wrist, .19, .14, (1, 0, 0))['reachable'])
        self.assertEqual(solve_two_bone((0, 0, 0), (0, 0, .2), .19, .14, (0, 0, 1))['reason'],
                         'explicit_pole_parallel_to_reach')

    def test_nonfinite_and_unknown_side_rejected(self):
        with self.assertRaises(ValueError):
            solve_two_bone((0, 0, 0), (float('nan'), 0, 0), .19, .14, (1, 0, 0))
        with self.assertRaises(ValueError):
            pole_direction(self.frame, 'left')

    def test_inverse_bind_is_not_the_exported_display_pose(self):
        # Inverse bind with 90-degree Z rotation and translation.
        matrix = (0., 1., 0., 0., -1., 0., 0., 0., 0., 0., 1., 0., 2., 3., 4., 1.)
        inverse = rigid_inverse_column_major(matrix)
        self.assertEqual(inverse[0], (0., 1., 0., -3.))
        self.assertEqual(inverse[1], (-1., 0., 0., 2.))
        self.assertEqual(inverse[2], (0., 0., 1., -4.))

    def test_no_mirrors_or_limb_scaling_in_bind(self):
        for x in (-1., 1.1):
            with self.assertRaises(ValueError):
                rigid_inverse_column_major((x,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1))

    def test_projective_bind_is_not_silently_treated_as_rigid(self):
        with self.assertRaises(ValueError):
            rigid_inverse_column_major((1,0,0,.1, 0,1,0,0, 0,0,1,0, 0,0,0,1))

    def test_reference_direction_cannot_cross_fighter_or_gameplay_authority(self):
        fields = {'forward':.6, 'up':0., 'outward':0.,
                  'pole':{'outward':.6,'down':.7,'forward':.1}}
        profile = {'fighter':'yin', 'fps':60, 'gameplay_timing_authority':False,
                   'frames':[{'frame':f,'L':fields,'R':fields} for f in (0,1)]}
        self.assertEqual(len(validate_direction_profile(profile,fighter='yin',body='female')),2)
        with self.assertRaises(ValueError):
            validate_direction_profile(profile,fighter='yang',body='female')
        profile['gameplay_timing_authority'] = True
        with self.assertRaises(ValueError):
            validate_direction_profile(profile,fighter='yin',body='female')


if __name__ == '__main__':
    unittest.main()

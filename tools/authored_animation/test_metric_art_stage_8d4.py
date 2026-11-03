"""Rigid stage algebra and negative authority checks; fixtures are labelled."""
import copy
import math
import unittest
from metric_art_stage_8d4 import IDENTITY, C, mul, inverse, point, rigid, make_stage as _make_stage, feasibility, source_to_reference, length


def fixture():
    yaw=[[.8,0,.6,0],[0,1,0,0],[-.6,0,.8,0],[0,0,0,1]]
    projection = {'projection_version':3,'camera_projection':1,'origin':[0,100],
                  'source_right_delta_px':[80,0],'source_forward_delta_px':[60,0],
                  'source_up_delta_px':[0,-100],'rig_world_transform':copy.deepcopy(yaw),
                  'camera_world_transform':copy.deepcopy(IDENTITY),'rig_to_camera_transform':copy.deepcopy(yaw),
                  'camera_size':3.2,'viewport_size':[256,320],'display_scale':'(1, 1)'}
    a = {'fighter':'fixtureA','body':'male','facing':1,'source_sha256':'a'*64,
         'gameplay_root_px':[0,0],'projection':projection}
    b = copy.deepcopy(a); b.update(fighter='fixtureB',source_sha256='b'*64,facing=-1,gameplay_root_px=[24,-8])
    policy = {'status':'OWNER_SELECTED_OFFLINE_REFERENCE','owner_selection_receipt':'SYNTHETIC_UNIT_FIXTURE_ONLY',
              'runtime_equivalence_claim':False,'depth_policy':'authored_offline_scene_not_recovered_runtime_depth',
              'camera_role':'OFFLINE_FRAMING_ONLY_NEVER_METRIC_SPACING',
              'source_unit_metres':1,'reference_observation':a}
    return policy,[a,b],{'fixtureA:male':'a'*64,'fixtureB:male':'b'*64}


def placement(actors):
    return {'method':'authored_opposed_axes_evaluated_torso_support_planes',
            'scope':'SYNTHETIC_UNIT_FIXTURE_ONLY',
            'source_hashes':[a['source_sha256']for a in actors],
            'torso_axis_extents_m':[[-.12,.12],[-.16,.16]]}


def make_stage(p,a,h):return _make_stage(p,a,h,placement(a))


class MetricStage(unittest.TestCase):
    def test_actual_orthogonal_basis_is_not_a_body_scale(self):
        p,actors,hashes=fixture();s=make_stage(p,actors,hashes)
        for a in s['actors']:rigid(a['rig_blender_metres_to_stage'])
        self.assertAlmostEqual(s['actors'][1]['rig_godot_metres_to_stage'][0][3],.28)
        self.assertAlmostEqual(s['actors'][1]['rig_godot_metres_to_stage'][1][3],0.)
        self.assertFalse(s['actor_roots_solver_owned']);self.assertFalse(s['actor_scale_changed'])

    def test_source_stage_inverse_roundtrip(self):
        p,a,h=fixture();s=make_stage(p,a,h)
        for actor in s['actors']:
            t=actor['rig_blender_metres_to_stage']
            for q in ([0,0,0],[.15,-.3,1.2],[-.4,.25,.006]):
                self.assertLess(length(point(inverse(t),point(t,q)),q),1e-12)

    def test_source_axes_have_explicit_handedness(self):
        self.assertEqual(point(C,[1,2,3]),[1,3,-2])
        rigid(C)

    def test_camera_mismatch_never_scales_actor_or_claims_runtime(self):
        p,a,h=fixture()
        for key in ['source_right_delta_px','source_up_delta_px','source_forward_delta_px']:
            a[1]['projection'][key]=[v*1.08 for v in a[1]['projection'][key]]
        a[1]['projection']['camera_size']/=1.08
        s=make_stage(p,a,h)
        self.assertAlmostEqual(s['native_scale_mismatches'][1]['native_scale_relative_error'],.08)
        self.assertFalse(s['shipping_alignment_verified'])
        rigid(s['actors'][1]['rig_godot_metres_to_stage'])

    def test_depth_changes_3d_distance_with_same_screen_pixel(self):
        p,a,h=fixture();s=make_stage(p,a,h);actor=s['actors'][0]
        one=[0,0,1];two=[.1,0,1] # Along the offline art camera nullspace in Blender.
        self.assertEqual(source_to_reference(s,actor,one),source_to_reference(s,actor,two))
        self.assertAlmostEqual(length(point(actor['rig_blender_metres_to_stage'],one),point(actor['rig_blender_metres_to_stage'],two)),.1)

    def test_native_pixel_displacement_cannot_change_physical_art_spacing(self):
        p,a,h=fixture();s=make_stage(p,a,h)
        before=s['actors'][1]['rig_godot_metres_to_stage']
        a[1]['gameplay_root_px'][0]+=200
        after=make_stage(p,a,h)['actors'][1]['rig_godot_metres_to_stage']
        self.assertEqual(before,after)

    def test_evaluated_source_placement_changes_physical_spacing(self):
        p,a,h=fixture();physical=placement(a)
        before=_make_stage(p,a,h,physical)['actors'][1]['rig_godot_metres_to_stage']
        physical['torso_axis_extents_m'][0][1]+=.2
        after=_make_stage(p,a,h,physical)['actors'][1]['rig_godot_metres_to_stage']
        self.assertAlmostEqual(length(point(before,[0,0,0]),point(after,[0,0,0])),.2)

    def test_framing_camera_cannot_change_physical_placement(self):
        p,a,h=fixture();before=make_stage(p,a,h)['actors'][1]['rig_godot_metres_to_stage']
        p=copy.deepcopy(p)
        for key in ['source_right_delta_px','source_up_delta_px','source_forward_delta_px']:
            p['reference_observation']['projection'][key]=[v*2 for v in p['reference_observation']['projection'][key]]
        p['reference_observation']['projection']['camera_size']/=2
        self.assertEqual(before,make_stage(p,a,h)['actors'][1]['rig_godot_metres_to_stage'])

    def test_pixel_mapping_without_source_placement_is_rejected(self):
        p,a,h=fixture()
        with self.assertRaisesRegex(ValueError,'Source-space art placement'):_make_stage(p,a,h)

    def test_no_owner_calibration_no_stage(self):
        p,a,h=fixture();p['status']='PROPOSED'
        with self.assertRaisesRegex(ValueError,'Missing authority'):make_stage(p,a,h)

    def test_mismatched_source_and_transform_rejected(self):
        p,a,h=fixture();a[1]['source_sha256']='c'*64
        with self.assertRaisesRegex(ValueError,'Wrong saved source'):make_stage(p,a,h)
        p,a,h=fixture();a[1]['projection']['rig_to_camera_transform'][0][3]=1
        with self.assertRaisesRegex(ValueError,'roundtrip'):make_stage(p,a,h)

    def test_shear_scale_nan_and_reflection_fail_closed(self):
        for field,value in [(0,2),(0,-1),(3,float('nan'))]:
            m=copy.deepcopy(IDENTITY);m[0][field]=value
            with self.assertRaises(ValueError):rigid(m)
        m=copy.deepcopy(IDENTITY);m[0][1]=.2
        with self.assertRaises(ValueError):rigid(m)

    def test_anatomical_reach_rejects_impossible_targets(self):
        q=([0,0,0],[.2,.1,0],[.4,0,0])
        self.assertFalse(feasibility(*q,[1,0,0])['reachable'])
        self.assertTrue(feasibility(*q,[.3,.1,0])['reachable'])
        self.assertFalse(feasibility(*q,[1,0,0])['stretch_permitted'])


if __name__=='__main__':unittest.main()

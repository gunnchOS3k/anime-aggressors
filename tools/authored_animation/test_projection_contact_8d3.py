"""Targeted provenance/projection tests. No Blender/Godot imports or exports."""
import copy
import json
import unittest
from pathlib import Path
from projection_contact_8d3 import project, projection_basis, ledger_report, require_3d_stage
ROOT = Path(__file__).resolve().parents[2]


class ContactObservations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        directory = ROOT/'artifacts/v1_closure/production_8d'
        cls.ledger = json.loads((directory/'hands_engine_39887494881/PUBLIC_CASE_LEDGER.json').read_text())
        cls.manifest = json.loads((directory/'hands_remote_39886629245/PRODUCTION_MANIFEST.json').read_text())
        cls.observation = cls.ledger['rows'][0]['measurements']['hold']['holder_projection']

    def test_real_36_configurations_are_2d_only(self):
        result = ledger_report(self.ledger, self.manifest)
        self.assertEqual(result['configurations'], 36)
        self.assertEqual(result['measurements'], 324)
        self.assertFalse(result['paired_3d_ready'])
        self.assertTrue(all('depth' in r['blocker'] for r in result['cases']))

    def test_actual_blender_forward_and_up_conversion(self):
        p = self.observation
        self.assertEqual(project(p, [0, 0, 0]), p['origin'])
        self.assertEqual(project(p, [0, -1, 0]), [p['origin'][i]+p['source_forward_delta_px'][i] for i in range(2)])
        self.assertEqual(project(p, [0, 0, 1]), [p['origin'][i]+p['source_up_delta_px'][i] for i in range(2)])

    def test_depth_nullspace_does_not_establish_contact(self):
        rows, depth = projection_basis(self.observation)
        point = [.2, -.3, .4]
        a = project(self.observation, point)
        b = project(self.observation, [point[i]+100*depth[i] for i in range(3)])
        for x, y in zip(a, b): self.assertAlmostEqual(x, y, places=8)
        # A hundred metres of unobserved depth can share the same image pixel.
        self.assertAlmostEqual(sum(d*d for d in depth), 1)

    def test_source_mismatch_is_rejected(self):
        ledger = copy.deepcopy(self.ledger)
        ledger['rows'][0]['measurements']['hold']['hand_sources']['holder'] = '0'*64
        with self.assertRaisesRegex(ValueError, 'Source mismatch'): ledger_report(ledger, self.manifest)

    def test_opponent_identity_mismatch_is_rejected(self):
        ledger = copy.deepcopy(self.ledger)
        ledger['rows'][0]['measurements']['hold']['hand_sources']['victim'] = self.manifest['rows'][4]['saved_source_sha256']
        with self.assertRaisesRegex(ValueError, 'Source mismatch'): ledger_report(ledger, self.manifest)

    def test_mixed_body_escapes_bind_actual_victim_source(self):
        result = ledger_report(self.ledger, self.manifest)
        escapes = [c for c in result['cases'] if ':escape' in c['case']]
        self.assertEqual(len(escapes), 36)
        self.assertTrue(all(c['victim_body'] != c['case'].split(':')[1] for c in escapes))

    def test_bad_measurements_fail_closed(self):
        for value in (float('nan'), float('inf')):
            p = copy.deepcopy(self.observation); p['source_right_delta_px'][0] = value
            with self.assertRaises(ValueError): projection_basis(p)
        p = copy.deepcopy(self.observation)
        for key in ('source_forward_delta_px', 'source_up_delta_px', 'source_right_delta_px'): p[key] = [1, 0]
        with self.assertRaisesRegex(ValueError, 'Degenerate'): projection_basis(p)
        p['camera_projection'] = 0
        with self.assertRaisesRegex(ValueError, 'orthographic'): projection_basis(p)

    def test_missing_depth_and_shared_stage_rejected(self):
        m = copy.deepcopy(self.ledger['rows'][0]['measurements']['hold'])
        args = [m['hand_sources']['holder'], m['hand_sources']['victim']]
        with self.assertRaisesRegex(ValueError, 'v2'): require_3d_stage(m, *args)
        identity = [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
        for role in ('holder', 'victim'):
            m[role+'_projection'].update(projection_version=3, rig_world_transform=identity, camera_world_transform=identity)
        with self.assertRaisesRegex(ValueError, 'shared physical stage'): require_3d_stage(m, *args)
        m['holder_projection']['rig_world_transform'] = [[2,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
        with self.assertRaisesRegex(ValueError, 'distorts'): require_3d_stage(m, *args)
        # Determinant-one shear must not masquerade as a rigid source stage.
        m['holder_projection']['rig_world_transform'] = [[1,.2,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
        with self.assertRaisesRegex(ValueError, 'distorts'): require_3d_stage(m, *args)


if __name__ == '__main__': unittest.main()

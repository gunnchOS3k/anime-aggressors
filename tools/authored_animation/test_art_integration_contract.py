"""Negative acceptance boundaries, never stand-in original art evidence."""
import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

from art_integration_contract import CANONICAL, checked_file, validate_row


class ArtHandoff(unittest.TestCase):
    def setUp(self):
        self.moves = ['existing_'+str(i) for i in range(24)]
        self.forms = ['BASE']
        self.row = {'fighter':'kaia-windrow', 'body':'female',
                    'rig':{'bones':list(CANONICAL), 'forward':'+Z', 'up':'+Y',
                           'rest_policy':'PRESERVE_ORIGINAL_BIND',
                           'facing_policy':'PROPER_ACTOR_ROTATION_NO_BONE_MIRROR'},
                    'root_motion':'PRESENTATION_ONLY_GAMEPLAY_ROOT_UNCHANGED',
                    'exported_clips':['original_hand_grip'],
                    'moves':{m:{'clock_owner':'RESOLVED_RUNTIME_MOVE_PHASE',
                                'contact_owner':'CONFIRMED_COMBAT_COLLISION',
                                'cancel_owner':'EXISTING_GAMEPLAY_STATE',
                                'facings':[-1,1], 'exported_clip':None, 'native_verified':False}
                             for m in self.moves}, 'forms':self.forms,
                    'integration_ready':False,
                    'acceptance':{k:False for k in ('HUMAN_ART_APPROVED', 'RUNTIME_PAIRED_CONTACT_VERIFIED',
                                                   'RC2_READY', 'V1_0_0_RELEASE_AUTHORIZED')}}

    def check_row(self, row=None, **options):
        return validate_row(row or self.row, self.moves, self.forms, **options)

    def test_inventory_does_not_mean_finished_moves(self):
        result = self.check_row()
        self.assertEqual(result['moves_with_exported_clips'], 0)
        self.assertFalse(result['full_move_export_verified'])
        with self.assertRaises(ValueError):
            self.check_row(full_move_export=True)

    def test_unknown_export_or_missing_move_rejected(self):
        self.row['moves'][self.moves[0]]['exported_clip'] = 'invented_final_attack'
        with self.assertRaises(ValueError): self.check_row()
        self.row['moves'].pop(self.moves[0])
        with self.assertRaises(ValueError): self.check_row()

    def test_damage_input_and_facing_authority_not_reassigned(self):
        for field, value in [('contact_owner','ACTIVE_HITBOX'), ('clock_owner','RAW_MANIFEST'),
                             ('cancel_owner','ANIMATION_FINISHED'), ('facings',[1])]:
            row = copy.deepcopy(self.row)
            row['moves'][self.moves[0]][field] = value
            with self.assertRaises(ValueError): self.check_row(row)

    def test_no_source_candidate_or_ci_autoapproval(self):
        self.row['integration_ready'] = True
        with self.assertRaises(ValueError): self.check_row()
        self.row['acceptance']['HUMAN_ART_APPROVED'] = True
        with self.assertRaisesRegex(ValueError, 'human/release'): self.check_row()

    def test_string_flags_do_not_authorize_runtime_installation(self):
        self.row['integration_ready'] = True
        for key in ('new_arm_blender_saved','native_skin_reviewed','runtime_event_alignment_verified'):
            self.row['acceptance'][key] = 'false'
        with self.assertRaises(ValueError): self.check_row()

    def test_cosmic_fighters_cannot_inherit_story_puppet_forms(self):
        self.row['fighter'] = 'yin'
        self.row['forms'] = ['BASE','BLACK_PUPPET']
        with self.assertRaises(ValueError):
            validate_row(self.row,self.moves,self.row['forms'])

    def test_rig_and_body_mismatch(self):
        for field, value in [('body','generic'), ('fighter','recolored_kaia'), ('root_motion','MOVE_GAMEPLAY_ROOT')]:
            row = copy.deepcopy(self.row);row[field] = value
            with self.assertRaises(ValueError): self.check_row(row)
        self.row['rig']['bones'].remove('Shoulder_R')
        with self.assertRaises(ValueError): self.check_row()

    def test_no_unverified_file_or_path_escape(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            file = root/'review.json';file.write_bytes(b'bounded test fixture')
            declaration = {'path':'review.json','sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
            self.assertEqual(checked_file(root,declaration),file.resolve())
            file.write_bytes(b'changed')
            with self.assertRaises(ValueError): checked_file(root,declaration)
            declaration['path']='../not_our_art'
            with self.assertRaises(ValueError): checked_file(root,declaration)


if __name__ == '__main__':
    unittest.main()

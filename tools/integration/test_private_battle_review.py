"""Boundary/timing checks; never original-art or native gameplay acceptance."""
import json
import struct
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import private_battle_review as review


class PrivateBinding(unittest.TestCase):
    def test_failed_environment_prevents_source_open(self):
        class Failed:
            def check(self): raise ValueError('fresh reader fault')
        with patch.object(Path,'open') as opened:
            with self.assertRaisesRegex(ValueError,'reader fault'):
                review.checked({'path':'unread.glb','sha256':'unread'},Failed())
            opened.assert_not_called()

    def test_unfinished_observation_cannot_enable_private_reads(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'gate.json';p.write_text(json.dumps({'status':'OBSERVING_NO_PRODUCTION','seconds':899,'failures':[]}))
            with patch.object(review,'reader') as reader:
                with self.assertRaisesRegex(ValueError,'15minute'): review.Continuity(p)
                reader.assert_not_called()

    def test_landmarks_require_original_catalog_agreement(self):
        move={'startup_frames':3,'active_frames':2,'recovery_frames':7}
        export={'frames':13,'FPS':60,'source_phase_landmarks':{'contact':3}}
        self.assertEqual(review.landmarks(export,move),{'contact':3,'active_end':5,'last':12})
        with self.assertRaisesRegex(ValueError,'do not invent'):review.landmarks({**export,'frames':17},move)
        with self.assertRaises(ValueError):review.landmarks({**export,'source_phase_landmarks':{'contact':4}},move)
        own_range=review.landmarks(export,{'startup_frames':4,'active_frames':3,'recovery_frames':10})
        self.assertEqual(own_range['contact'],3)
        self.assertAlmostEqual(own_range['active_end'],84/17)

    def test_protected_path_escape_and_symlink_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)/'private';root.mkdir();outside=Path(tmp)/'other';outside.mkdir()
            (root/'link').symlink_to(outside,target_is_directory=True)
            with self.assertRaises(ValueError):review.confined(root/'../other/model.glb',root)
            with self.assertRaises(ValueError):review.confined(root/'link/model.glb',root)

    def test_glb_skin_identity_and_external_dependencies(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'technical.glb'
            doc={'nodes':[{'name':'Root'}],'skins':[{'joints':[0]}],'animations':[{'name':'clip'}],'meshes':[{'primitives':[{'attributes':{'WEIGHTS_0':0,'JOINTS_0':1}}]}]}
            def save():
                raw=json.dumps(doc).encode();raw+=b' '*((-len(raw))%4)
                p.write_bytes(struct.pack('<4sIII',b'glTF',2,20+len(raw),len(raw))+struct.pack('<I',0x4e4f534a)+raw)
            save();review.glb_contract(p,{'clip':'clip'},['Root'])
            with self.assertRaises(ValueError):review.glb_contract(p,{'clip':'wrong'},['Root'])
            doc['images']=[{'uri':'../unverified.png'}];save()
            with self.assertRaisesRegex(ValueError,'dependency'):review.glb_contract(p,{'clip':'clip'},['Root'])


if __name__=='__main__': unittest.main()

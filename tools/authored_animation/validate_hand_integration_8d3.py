"""Saved source/export boundary for the bounded wrist integration increment."""
import json
import struct
import sys
from pathlib import Path
from validate_hands_8d2 import sha, exported_hand_volumes
from projection_contact_8d3 import SOURCE_RUN, SOURCE_SHA
ROOT = Path(__file__).resolve().parents[2]
CANONICAL = {'Root', 'Hips', 'Spine', 'Chest', 'Neck', 'Head',
             'Shoulder_L', 'UpperArm_L', 'LowerArm_L', 'Hand_L',
             'Shoulder_R', 'UpperArm_R', 'LowerArm_R', 'Hand_R',
             'UpperLeg_L', 'LowerLeg_L', 'Foot_L', 'Toes_L',
             'UpperLeg_R', 'LowerLeg_R', 'Foot_R', 'Toes_R'}


def validate(folder, sources=True):
    m = json.loads((folder/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert m['schema'] == 'hand_interface_production_8d3.v1' and m['complete']
    assert not m['human_approved'] and not m['paired_3d_verified']
    assert int(m['input_run']) == SOURCE_RUN and m['input_sha'] == SOURCE_SHA
    prior = json.loads((ROOT/'artifacts/v1_closure/production_8d/hands_remote_39886629245/PRODUCTION_MANIFEST.json').read_text())
    expected = {(r['fighter'], r['body']): r for r in prior['rows']}
    assert len(m['rows']) == 18 and {(r['fighter'], r['body']) for r in m['rows']} == set(expected)
    for r in m['rows']:
        previous = expected[r['fighter'], r['body']]
        assert r['input_source_sha256'] == previous['saved_source_sha256']
        assert all(r['source_preservation'].values()) and r['old_action_curves_sha256'] == previous['all_previous_action_curves_sha256']
        assert r['preserved_actions'] == previous['preserved_actions'] and len(r['new_actions']) == 3
        assert r['max_actual_fist_mesh_motion_m'] > .005 and not r['paired_3d_verified'] and not r['human_approved']
        if sources: assert sha(folder/r['saved_source']) == r['saved_source_sha256']
        names = {e['mesh'] for e in r['edits']}
        required = {'Palm L', 'Palm R', 'Forearm L', 'Forearm R'}
        if r['fighter'] == 'rook-ironside': required |= {'Bastion forearm', 'Bastion forearm.001'}
        assert names == required and len(r['edits']) == len(required)
        for e in r['edits']:
            assert e['max_surface_displacement_m'] > .0002
            assert e['validation']['minimum_face_area_m2'] > 1e-14
            if not e.get('armor', False):
                assert e['validation']['nonmanifold_edges'] == 0 and e['validation']['signed_volume_m3'] > 0
            if 'distal_after_m' in e: assert e['distal_after_m'] < e['distal_before_m'] and e['proximal_vertices_preserved'] > 0
        data = folder/'runtime'/r['runtime']; asset = folder/'runtime'/r['resource']
        assert sha(data) == r['runtime_sha256'] and sha(asset) == r['resource_sha256']
        d = json.loads(data.read_text())
        assert d['schema'] == 'saved_original_hands_8d3.v1' and d['source_sha256'] == r['saved_source_sha256']
        assert d['input_8d2_sha256'] == r['input_source_sha256'] and not d['paired_3d_verified'] and not d['human_approved']
        assert d['resource'].startswith('res://assets/characters/hands_8d3/') and d['resource_sha256'] == r['resource_sha256']
        assert len(d['canonical_bones']) == 22 and set(d['canonical_bones']) == CANONICAL
        assert d['expected_finger_joints'] == 28 and set(d['clips']) == {'grip', 'fist', 'release', 'idle', 'recoil'}
        assert {d['clips'][c]['source_action'] for c in ('grip', 'fist', 'release')} == set(r['new_actions'])
        assert d['clips']['idle']['source_action'] == 'ANI08D2_idle' and d['clips']['recoil']['source_action'] == 'ANI08D2_recoil'
        raw = asset.read_bytes(); assert raw[:4] == b'glTF'
        g = json.loads(raw[20:20+struct.unpack_from('<I', raw, 12)[0]])
        exported_hand_volumes(raw, g)
        nodes = {n.get('name') for n in g['nodes']}
        assert set(d['canonical_bones']) <= nodes
        assert all(n in nodes for chain in d['chains'] for n in chain['bones'])
        assert not any(n and n.startswith('ORIGINAL_8D_') for n in nodes)
        assert {c['source_action'] for c in d['clips'].values()} <= {a.get('name') for a in g['animations']}
        assert sum(bool(x.get('extras', {}).get('targetNames')) for x in g['meshes']) >= 12
    return {'PASS': True, 'saved_sources_checked': sources, 'rigs': 18, 'hands': 36, 'new_hand_actions': 54,
            'scope': 'Editable source preservation/export, not final anatomy, paired physical grip or human acceptance',
            'paired_3d_verified': False, 'human_approved': False}


if __name__ == '__main__':
    print(json.dumps(validate(Path(sys.argv[1]), '--runtime-only' not in sys.argv), indent=2))

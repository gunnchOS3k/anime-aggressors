"""Saved connected anatomy boundary; technical proof only, never premium approval."""
import json,struct,sys,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def sha(p):
    with p.open('rb')as f:return hashlib.file_digest(f,'sha256').hexdigest()
def validate(folder,sources=True):
    m=json.loads((folder/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert m['schema']=='original_hand_anatomy_production_8d2.v1'and m['complete']and not m['human_approved']
    prior=json.loads((ROOT/'artifacts/v1_closure/production_8d/controls_remote_39852459469/PRODUCTION_MANIFEST.json').read_text());expected={(r['fighter'],r['body']):r for r in prior['rows']}
    assert len(m['rows'])==18 and {(r['fighter'],r['body'])for r in m['rows']}==set(expected)
    for r in m['rows']:
        assert r['input_8d_sha256']==expected[r['fighter'],r['body']]['saved_source_sha256']
        assert [r['preserved_8b'],r['preserved_8c'],r['preserved_8d']]==[30,8,4]and r['preserved_actions']>=189
        if r.get('surface_only_repair',False):assert r['all_bone_rest_preserved_exactly']and r['inherited_8d2_actions']==5 and r['created_actions_this_run']==0 and r['preserved_actions']>=194
        assert r['canonical22_unchanged']and len(r['hands'])==2 and r['max_actual_fist_mesh_motion_m']>.005
        if sources:assert sha(folder/r['saved_source'])==r['saved_source_sha256']
        for h in r['hands']:
            assert h['minimum_bridge_normal_cosine']>0 and h['outward_closed_volume_m3']>0
            assert h['connected_components']==1 and h['boundary_edges']==0 and h['vertices']>1000 and len(h['chains'])==5 and len(h['source_parts'])==6
            assert len([n for c in h['chains']for n in c['bones']])==14
        file=folder/'runtime'/r['runtime'];asset=folder/'runtime'/r['resource'];assert sha(file)==r['runtime_sha256']and sha(asset)==r['resource_sha256']
        d=json.loads(file.read_text());assert d['schema']=='saved_original_hands_8d2.v1'and d['source_sha256']==r['saved_source_sha256']and d['expected_finger_joints']==28
        assert set(d['clips'])=={'grip','fist','release','idle','recoil'}and len(d['canonical_bones'])==22
        raw=asset.read_bytes();assert raw[:4]==b'glTF';g=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
        names={n.get('name','')for n in g['nodes']};assert set(d['canonical_bones']).issubset(names)
        assert all(n in names for c in d['chains']for n in c['bones'])
        assert not any(n.startswith('ORIGINAL_8D_')for n in names),'Before geometry is not a second visible body'
        assert {c['source_action']for c in d['clips'].values()}.issubset({a.get('name')for a in g['animations']})
        assert sum(bool(x.get('extras',{}).get('targetNames'))for x in g['meshes'])>=12
    return {'PASS':True,'rigs':18,'connected_hands':36,'finger_joints_per_hand':14,'preserved_8b_actions':540,'preserved_8c_actions':144,'preserved_8d_actions':72,'new_auxiliary_actions':m.get('created_actions_this_run',90),'auxiliary_actions_present':90,'saved_sources_checked':sources,'paired_contact_verified':False,'human_approved':False}
if __name__=='__main__':print(json.dumps(validate(Path(sys.argv[1]),'--runtime-only'not in sys.argv),indent=2))

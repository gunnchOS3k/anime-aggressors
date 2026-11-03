"""Paired saved-source/export boundary; unreachability remains explicitly open."""
import json,hashlib,sys
from pathlib import Path
from validate_hands_8d2 import sha

def validate(folder,sources=True):
    m=json.loads((folder/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert m['schema']=='paired_hand_production_8d2.v1'and m['complete']and not m['human_approved']
    ids=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
    assert len(m['rows'])==18 and {(r['fighter'],r['body'])for r in m['rows']}=={(f,b)for f in ids for b in ['male','female']}
    blocked=0;deep=0;sampled=0
    for r in m['rows']:
        if sources:assert sha(folder/r['saved_source'])==r['saved_source_sha256']
        assert r['all_geometry_weights_rest_preserved']and r['all_previous_curves_preserved']and len(r['new_paired_actions'])==14
        assert r['source_stage']=='PAIRED_SOURCE_NATIVE_CONTACT_PENDING'
        assert r['source_runtime_verification']['PASS']and r['source_runtime_verification']['max_matrix_component_error']<.0002
        p=folder/'runtime'/r['paired_runtime'];assert sha(p)==r['paired_runtime_sha256'];d=json.loads(p.read_text())
        assert d['schema']=='paired_mesh_grab_acting_8d2.v1'and d['source_actions_saved']and d['source_runtime_verified']and not d['human_approved']and d['source_saved_blend_sha256']==r['saved_source_sha256']
        assert len(d['clips'])==14 and all(c['source_action'].startswith('ANI08D2_PAIRED_')and len(c['bone_tracks'])==21 for c in d['clips'].values())
        assert sha(folder/'runtime'/r['runtime'])==r['runtime_sha256']and sha(folder/'runtime'/r['resource'])==r['resource_sha256']
        for report in r['paired_reports']:
            blocked+=report['blocked_arm_frames']
            for sample in report['samples']:
                sampled+=1;deep+=sample['deep_overlap_sample_count']
                if sample['reachable']:assert sample['wrist_residual_m']<.00005 and abs(sample['after_contact_m']-sample['penetration_target_m'])<.0001
                assert sample['victim_surface_vertices']>100 and len(sample['victim_meshes'])>0
        for name,c in d['clips'].items():
            assert all(len(keys)==c['duration_frames']+1 for keys in c['bone_tracks'].values())
    assert sampled>0
    return {'PASS':True,'source_rigs':18,'new_paired_actions':252,'actual_mesh_contact_samples':sampled,'blocked_arm_frames':blocked,'deep_overlap_vertex_samples':deep,'runtime_contact_verified':False,'art_quality_pass':False,'human_approved':False}
if __name__=='__main__':print(json.dumps(validate(Path(sys.argv[1]),'--runtime-only'not in sys.argv),indent=2))

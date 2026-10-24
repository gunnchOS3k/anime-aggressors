"""Strict18-rig saved form action/model boundary; no human approval inference."""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]


def digest(path):
    h=hashlib.sha256()
    with path.open('rb')as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()


def glb_json(path):
    data=path.read_bytes();assert data[:4]==b'glTF';size=struct.unpack_from('<I',data,12)[0];assert data[16:20]==b'JSON';return json.loads(data[20:20+size])


def validate(folder,require_sources=True):
    manifest=json.loads((folder/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert manifest['schema']=='form_production_8c.v1' and manifest['complete']is True and manifest['human_approved']is False
    index=json.loads((ROOT/'data/bibles/FIGHTER_BIBLE_INDEX.json').read_text())['fighters'];expected={(f['id'],b)for f in index for b in ('male','female')}
    assert len(manifest['rows'])==18 and {(r['fighter'],r['body'])for r in manifest['rows']}==expected
    count=0
    for row in manifest['rows']:
        path=folder/row['runtime_file'];assert digest(path)==row['runtime_sha256'];doc=json.loads(path.read_text())
        assert doc['schema']=='original_form_acting_8c.v1' and doc['source_actions_saved']is True and doc['source_runtime_verified']is True
        assert doc['fighter_id']==row['fighter']and doc['body_variant']==row['body']and doc['human_approved']is False
        assert doc['source_saved_blend_sha256']==row['saved_source_sha256'] and doc['source_input_8b_sha256']==row['input_8b_sha256']
        assert row['source_runtime_verification']['PASS']and row['source_runtime_verification']['max_matrix_component_error']<.0002
        assert row['original_actions_preserved']>=177 and row['preserved_8b_actions']==30 and len(row['rig_bones'])==22
        assert doc['attachments']==row['attachments'] and len(row['new_saved_actions'])==8
        assert row['source_runtime_verification']['frames_evaluated']==sum(c['duration_frames']+1 for c in doc['clips'].values())
        prior=json.loads((ROOT/'artifacts/v1_closure/elemental_grab_throw_8b/PRODUCTION_MANIFEST_39733087497.json').read_text())
        expected_prior=next(r for r in prior['rows'] if r['fighter']==row['fighter'] and r['body']==row['body'])
        assert row['input_8b_sha256']==expected_prior['saved_source_sha256']
        assert row['source_geometry_rest_weights_sha256']==expected_prior['source_geometry_rest_weights_sha256']
        forms=json.loads((ROOT/f"game-godot/data/forms/{row['fighter']}.json").read_text());stages=[forms['forms'][i]for i in forms['form_ladder'][1:]]
        required=set()
        for entry in stages:
            step=entry['ladder_step'].lower();required|={f'form_{kind}_{step}'+suffix for kind in ('transform','idle')for suffix in ('','_left')}
            stage=doc['stages'][entry['form_id']];assert stage['transform_frames']==round(entry['transform_in_seconds']*60)
            for suffix in ('','_left'):assert doc['clips'][stage['transition_clip']+suffix]['duration_frames']==stage['transform_frames']
            attachment=doc['attachments'][entry['form_id']];resource=folder/'runtime/game-godot'/attachment['path'].removeprefix('res://')
            assert digest(resource)==attachment['sha256']and resource.stat().st_size==attachment['bytes']<1024**2
            assert attachment['triangles']<=3000 and attachment['vertices']<=2048 and attachment['independent_hair_cloth']is False
            glb=glb_json(resource);assert not glb.get('skins')and not glb.get('animations')and len(glb.get('meshes',[]))>0
            nodes={n.get('name'):n for n in glb['nodes']}
            for part in attachment['parts']:
                assert part['canonical_bone']in row['rig_bones']and part['node']in nodes
                assert nodes[part['node']]['extras']['canonical_bone']==part['canonical_bone']
                assert len(part['source_rest_transform_godot'])==4
                assert all(name in nodes for name in part['children'])
            count+=1
        assert set(doc['clips'])==required and set(row['new_saved_actions'])=={'ANI08C_WIP_'+n for n in required}
        for name,clip in doc['clips'].items():
            assert clip['source_action']=='ANI08C_WIP_'+name and clip['source_blend_sha256']==row['saved_source_sha256']
            assert set(clip['bone_tracks'])==set(row['rig_bones'])-{'Root'}
            for bone,keys in clip['bone_tracks'].items():
                assert len(keys)==clip['duration_frames']+1
                for frame,key in enumerate(keys):
                    assert abs(key['time_s']-frame/60)<.000001
                    q=key['rotation_quat'];assert len(q)==4 and all(math.isfinite(v)for v in q)and abs(sum(v*v for v in q)-1)<.00001
        if require_sources:assert digest(folder/row['saved_source'])==row['saved_source_sha256']
    assert count==36
    return dict(PASS=True,rigs=18,saved_actions=144,model_attachment_resources=36,source_binaries_checked=require_sources,native_visual_verified=False,human_approved=False)


if __name__=='__main__':print(json.dumps(validate(Path(sys.argv[1]),'--runtime-only'not in sys.argv),indent=2))

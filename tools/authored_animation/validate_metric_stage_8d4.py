"""Validate saved offline references without promoting them to runtime grips."""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path
from metric_art_stage_8d4 import rigid, make_stage
from private_production_8d4 import validate_manifest_context

ROOT=Path(__file__).resolve().parents[2]


def sha(path):
    h=hashlib.sha256()
    with path.open('rb')as stream:
        for block in iter(lambda:stream.read(1024*1024),b''):h.update(block)
    return h.hexdigest()


def finite_tree(value):
    if isinstance(value,float):assert math.isfinite(value),'Non-finite physical measurement'
    elif isinstance(value,dict):
        for v in value.values():finite_tree(v)
    elif isinstance(value,list):
        for v in value:finite_tree(v)


def validate(folder):
    folder=Path(folder);runtime=folder/'runtime'
    inputs=json.loads((runtime/'STAGE_INPUTS.json').read_text())
    assert inputs==json.loads((ROOT/'art_source/staging/metric_8d4/inputs_v1.json').read_text())
    manifest=json.loads((runtime/'PRODUCTION_MANIFEST.json').read_text());finite_tree(manifest)
    validate_manifest_context(manifest)
    assert manifest['schema']=='metric_pair_reference_sources_8d4.v1'and manifest['complete']
    assert manifest['input_run']==39910149332 and not manifest['shipping_alignment_verified']and not manifest['human_approved']
    expected={c['case']:c for c in inputs['reference_cases']}
    assert len(manifest['rows'])==8 and {r['case']for r in manifest['rows']}==set(expected)
    blocked=[];max_gap=0.;crossings=0;references=0
    for row in manifest['rows']:
        assert not row['grip_accepted']and not row['shipping_alignment_verified']and not row['human_approved']
        case=expected[row['case']];stage=row['stage']
        assert stage==make_stage(inputs['policy'],case['actors'],inputs['source_hashes'],stage['physical_placement'])
        for actor in stage['actors']:rigid(actor['rig_blender_metres_to_stage'])
        assert not stage['physical_placement']['native_px_offsets_used_for_physical_placement']
        assert sha(folder/row['saved_source'])==row['saved_source_sha256']
        assert len(row['source_actions'])==2 and all(a.startswith('ANI08D4_REFERENCE_HOLD_')for a in row['source_actions'])
        assert len(row['source_preservation'])==2 and len(row['contact_frames'])==25
        assert len(row['saved_reopened_pose_samples'])==25
        assert all(h['pre_save_pad_error_m']<.00005 for f in row['saved_reopened_pose_samples']for h in f['hands'])
        for frame in row['contact_frames']:
            assert len(frame['hands'])==2
            assert all(h['material_binding']==row['contact_frames'][0]['hands'][i]['material_binding']for i,h in enumerate(frame['hands']))
            for h in frame['hands']:
                assert not h['source_root_changed']and not h['source_scale_changed']and not h['stretch_permitted']
                assert h['after_pad_gap_m']>=0 and len(h['segment_lengths_m'])==2
                max_gap=max(max_gap,h['after_pad_gap_m']);crossings+=h['surface_intersections']['strict_surface_crossings']
                if not h['reachable']:blocked.append({'case':row['case'],'frame':frame['frame'],'hand':h['side'],'reason':'unreachable restraint'})
        probes=row['surface_sensitivity'];assert not probes['impossible_reach']['reachable']
        assert len(probes['probes'])==2 and all(p['distance_changed']for p in probes['probes'])
        assert len(row['floor_observations'])==4
        assert {s['state']for s in row['snapshots']}=={'open','closed','held'}
        for snapshot in row['snapshots']:
            path=runtime/snapshot['resource'];assert sha(path)==snapshot['sha256']
            raw=path.read_bytes();assert raw[:4]==b'glTF'and struct.unpack_from('<I',raw,4)[0]==2
            doc=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
            assert not doc.get('animations')and not doc.get('skins'),'Snapshots must not claim animated-source equivalence'
            assert snapshot['bounds']and all(b['samples_m']for b in snapshot['bounds']);references+=1
    return {'PASS':True,'saved_reference_scenes':8,'static_snapshots':references,
            'source_preservation_scope':'Save/reopen hashes of original actions, geometry, skin weights and rest; actual producer required',
            'unreachable_restraints':blocked,'max_measured_pad_gap_m':max_gap,'total_triangle_surface_crossings':crossings,
            'scope':'Artifact/provenance validation, not accepted grip quality, animation equivalence or gameplay',
            'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False}


if __name__=='__main__':print(json.dumps(validate(Path(sys.argv[1])),indent=2))

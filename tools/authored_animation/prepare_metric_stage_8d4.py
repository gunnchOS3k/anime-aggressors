"""Read retained8D3 proof and prepare, never assume, offline stage authority."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
from metric_art_stage_8d4 import validate_observation, measured_scale
ROOT=Path(__file__).resolve().parents[2]
ARCHIVE=Path('/Volumes/gunnchOS-Archives/10-Anime-Aggressors/art-source-snapshots/2026-10-23_8d3_hands_42baaab8_39910149332')


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(archive):
    raw_path=archive/'engine_review/grab_acting_runtime_8b.json'
    manifest_path=archive/'runtime/PRODUCTION_MANIFEST.json'
    receipt=json.loads((archive/'DURABLE_SOURCE_RECEIPT.json').read_text())
    assert receipt['PASS'] and receipt['producer_sha']=='42baaab8cc5167798aea7f3aebb22edae9f21007' and receipt['run_id']==39910149332
    for path in [raw_path,manifest_path]:
        record=next(r for r in receipt['files'] if r['path']==str(path))
        assert path.stat().st_size==record['bytes'] and sha(path)==record['sha256']
    raw=json.loads(raw_path.read_text());manifest=json.loads(manifest_path.read_text())
    sources={r['fighter']+':'+r['body']:r['saved_source_sha256'] for r in manifest['rows']}
    assert len(sources)==18 and raw['PASS'] and len(raw['rows'])==180
    samples={};checked=0
    for row in raw['rows']:
        if row['kind']!='public_throw':continue
        for phase in ['hold','sustained_hold']:
            measure=row[phase]
            a,b=measure['holder'],measure['victim']
            delta=[b['global_position'][i]-a['global_position'][i] for i in range(2)]
            assert abs(delta[0]-24*row['facing'])<1e-5 and abs(delta[1]+8)<1e-5,'Captured grab placement differs from existing authority'
            for role in ['holder','victim']:
                pose=measure[role];source=measure[role+'_hand_source'];projection=measure[role+'_projection']
                item={'fighter':pose['fighter'],'body':pose['body'],'facing':pose['facing'],
                      'source_sha256':source['source_sha256'],'gameplay_root_px':pose['global_position'],
                      'projection':projection,'basis_source_case':row['case'],'basis_source_phase':phase,
                      'original_role':role,'source_action_clip':pose['clip'],'source_animation_time_s':pose['animation_time'],
                      'floor_observations':[f for f in measure['floor_observations'] if f['fighter']==pose['fighter']]}
                validate_observation(item,sources[pose['fighter']+':'+pose['body']]);checked+=1
                samples.setdefault((pose['fighter'],pose['body'],pose['facing'],role),item)
    ref=copy.deepcopy(samples['ember-vale','male',1,'holder'])
    policy={'schema':'offline_metric_stage_authority_8d4.v1','status':'PROPOSED_REQUIRES_OWNER_SELECTION',
            'owner_selection_receipt':None,'source_unit_metres':1,'source_unit_authority':'art_source/animation/CONTRACT.md; actual glTF source export; Blender scene unit/rest check required before source bake',
            'depth_policy':'authored_offline_scene_not_recovered_runtime_depth','runtime_equivalence_claim':False,
            'camera_role':'OFFLINE_FRAMING_ONLY_NEVER_METRIC_SPACING',
            'source_placement_policy':'authored_opposed_axes_evaluated_torso_support_planes',
            'native_gameplay_roots_are_comparison_only':True,'reference_observation':ref,
            'spacing_authority':{'path':'game-godot/scripts/fighters/fighter.gd','sha256':sha(ROOT/'game-godot/scripts/fighters/fighter.gd'),
                                 'scope':'Native 2D comparison only; never convert this offset to art metres',
                                 'rule':'Held target root = owner root + (24*facing,-8) in gameplay pixels; validated against all retained throw holds'},
            'floor_policy':'Source Blender z=0 is the art ground. Runtime collision floor is a separate measured overlay; neither actor root is moved to erase its residual.'}
    cases=[]
    for fid,other in [('ember-vale','juno-spark'),('rook-ironside','kaia-windrow')]:
        for body in ['male','female']:
            for facing in [1,-1]:
                a=copy.deepcopy(samples[fid,body,facing,'holder']);b=copy.deepcopy(samples[other,body,-facing,'victim'])
                previous=b['gameplay_root_px'];target=[a['gameplay_root_px'][0]+24*facing,a['gameplay_root_px'][1]-8]
                shift=[target[i]-previous[i] for i in range(2)]
                b['composition_translation_px']=shift
                b['basis_source_gameplay_root_px']=previous
                b['gameplay_root_px']=target
                b['projection']['origin']=[b['projection']['origin'][i]+shift[i] for i in range(2)]
                cases.append({'case':fid+'__'+other+'__'+body+'__'+str(facing),'actors':[a,b],
                              'scope':'New offline reference composition from actual per-model native calibration and shared grab placement rule; NOT a captured Ember/Juno or Rook/Kaia runtime interaction'})
    scales=[]
    for (fid,body,facing,role),s in samples.items():
        if role=='holder' and facing==1:scales.append({'fighter':fid,'body':body,'px_per_source_metre':measured_scale(s['projection'])})
    return {'schema':'metric_art_stage_inputs_8d4.v1','source_run':39910149332,'producer_sha':manifest['source_sha'],
            'raw_path':str(raw_path),'raw_sha256':sha(raw_path),'manifest_sha256':sha(manifest_path),
            'validated_camera_observations':checked,'source_hashes':sources,'policy':policy,'reference_cases':cases,
            'measured_body_scales':scales,'shared_runtime_scale_exists':max(s['px_per_source_metre']for s in scales)-min(s['px_per_source_metre']for s in scales)<1e-4,
            'source_stage_produced':False,'paired_3d_verified':False,'human_approved':False}


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--archive',type=Path,default=ARCHIVE);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();d=prepare(args.archive)
    assert not args.output.exists(),'Preserve previous stage inputs; choose a new version label'
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(d,indent=2)+'\n')
    print(json.dumps({'camera_observations_verified':d['validated_camera_observations'],'reference_cases_prepared':len(d['reference_cases']),
                      'policy_status':d['policy']['status'],'shared_runtime_scale_exists':d['shared_runtime_scale_exists'],'source_stage_produced':False}))

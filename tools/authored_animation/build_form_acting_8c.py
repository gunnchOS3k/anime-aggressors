"""Finite original form scores on original rigs; only saved Blender actions may ship.

No balance values, collision geometry, source meshes or rig proportions change.
The offline limb/support solver preserves segment lengths; residuals are reported.
"""
import copy
import json
import sys
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/authored_animation'))
from bake_directed_performance import bake,neutral_pose,pose_fields
SCORE=ROOT/'art_source/animation/form_acting_8c/score_v1.json'


def make_pack(fid,body,reference):
    from bake_directed_performance import rig,fk
    r,model_hash=rig(fid,body)
    baseline=json.loads((ROOT/f'game-godot/data/animation/combat_choreography/{fid}_{body}.json').read_text())
    forms=json.loads((ROOT/f'game-godot/data/forms/{fid}.json').read_text())
    spec=json.loads(SCORE.read_text())['fighters'][fid]
    neutral=neutral_pose(r,baseline['clips']['idle_primary'])
    guard=pose_fields(r,neutral,reference)
    height=float(fk(r,{}, {})['Head'][1][1])
    clips={};stages={};previous=guard
    for stage in spec['stages']:
        entry=next(f for f in forms['forms'].values() if f['ladder_step']==stage['ladder_step'])
        total=int(round(float(entry['transform_in_seconds'])*60))
        poses={}
        for key,fields in stage['poses'].items():
            pose=copy.deepcopy(guard)
            for field,value in fields.items():
                if field in ('pelvis','R','L'):pose[field]=list(np.array(guard[field])+np.array(value)*height)
                elif field in ('front','back'):pose[field]=list(np.array(value)*height)
                else:pose[field]=value
            poses[key]=pose
        step=stage['ladder_step'].lower()
        beats=[(0,previous,'guard' if not stages else 'prior_form_supported_pose'),
               (max(1,round(total*stage['beats']['anticipation'])),poses['compression'],'anticipation'),
               (round(total*stage['beats']['gather']),poses['gather'],'energy_gather'),
               (round(total*stage['beats']['climax']),poses['climax'],'transformation_climax'),
               (round(total*stage['beats']['reveal']),poses['ready'],'identity_reveal'),
               (total,poses['ready'],'empowered_ready')]
        idle=int(stage['idle_frames'])
        for category,sequence,loop in [('transform',beats,False),('idle',[(0,poses['ready'],'supported_ready'),(idle//2,poses['breath'],'contained_weight_exchange'),(idle,poses['ready'],'loop_seam')],True)]:
            for facing in (1,-1):
                name=f'form_{category}_{step}'+('_left' if facing==-1 else '')
                clip=bake(r,fid,body,reference,neutral,dict(duration_frames=sequence[-1][0],loop=loop,relative_to_rest=False),sequence,name,SCORE,facing)
                clip.update(source_action='ANI08C_WIP_'+name,source_blend='PENDING_SAVED_ACTION',form_id=entry['form_id'],ladder_step=stage['ladder_step'],acting_category='8C_original_form_acting',human_approved=False)
                clips[name]=clip
        stages[entry['form_id']]=dict(ladder_step=stage['ladder_step'],transform_frames=total,transition_clip='form_transform_'+step,idle_clip='form_idle_'+step,design_intent=stage['intent'],shape=spec['shape'])
        previous=poses['ready']
    return dict(schema='original_form_acting_8c.v1',fighter_id=fid,body_variant=body,source_model_sha256=model_hash,source_score=str(SCORE.relative_to(ROOT)),source_actions_saved=False,source_runtime_verified=False,status='UNSAVED_POSE_CANDIDATE_NOT_RUNTIME_AUTHORITY',human_approved=False,source_bible=spec['bible'],intent=spec['intent'],clips=clips,stages=stages)


def inspect_all():
    refs=json.loads((ROOT/'artifacts/v1_closure/parity_foundation/rig_controls_in_memory.json').read_text())['rows']
    rows=[]
    for row in refs:
        ref={'soles':{}}
        for side,sole in row['sole_references'].items():
            x,y,z=sole['sole_rig_blender_m'];ref['soles'][side]={'world_rest_m':[x,z,-y],'foot_local_m':sole['foot_local_m']}
        doc=make_pack(row['fighter'],row['body'],ref)
        rows.append(dict(fighter=row['fighter'],body=row['body'],clips=len(doc['clips']),transform_frames={k:v['transform_frames'] for k,v in doc['stages'].items()},largest_hand_constraint_residual_m=max(c['max_hand_target_clamp_m'] for c in doc['clips'].values()),largest_baked_support_slip_m=max(c['max_baked_support_slip_m'] for c in doc['clips'].values()),source_actions_saved=False))
    print(json.dumps(dict(rows=rows,scope='Finite source score only, no Blender save or native/human visual acceptance'),indent=2))


if __name__=='__main__':inspect_all()

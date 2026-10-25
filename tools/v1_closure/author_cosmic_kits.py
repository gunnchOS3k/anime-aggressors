"""Original Yin/Yang playable candidates, preserving the seven accepted kits.

Existing move IDs, body/hurt/attack rectangles and throw ownership remain. These
numeric candidates are not owner-approved balance. No imported art or audio.
"""
import argparse, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IDS = ['yin', 'yang']
NORMALS = ['jab_1','jab_2','jab_finisher','forward_tilt','up_tilt','down_tilt','dash_attack','heavy_attack','neutral_air','forward_air','back_air','up_air','down_air']
SPECS = {
 'yin': {
  'tag':'cosmic_reduction', 'element':'void', 'signature':'Toward Zero',
  'startup':[5,4,6,7,6,6,7,11,5,6,6,6,7],
  'recovery':[10,11,14,15,14,13,18,22,11,13,13,12,14],
  'damage':[2.1,2.8,4.6,6.1,5.4,4.3,6.8,10.5,4.8,6.1,6.1,5.1,6.8],
  'angle':[100,110,125,115,88,260,110,130,100,115,145,90,270],
  'names':['Still Palm','Folded Return','Closing Spiral','Inward Fold','Quiet Rise','Low Collapse','Shortened Path','Event Horizon','Quiet Orbit','Returning Palm','Rear Aperture','Suspended Fold','Settling Void'],
  'speed':[270,300,330,360], 'life':[40,44,48,52], 'shot_damage':[6,7,8,9],
 },
 'yang': {
  'tag':'cosmic_definition', 'element':'radiance', 'signature':'Perfect Definition',
  'startup':[4,5,7,6,7,5,6,10,4,6,6,5,6],
  'recovery':[8,10,13,13,12,12,16,20,10,12,12,12,13],
  'damage':[2.2,3.1,5.2,6.7,5.8,4.8,7.4,10.8,5.4,6.5,6.5,5.8,7.2],
  'angle':[38,55,62,40,85,280,35,42,60,35,150,88,270],
  'names':['First Principle','Second Principle','Declared Pattern','Radiant Axis','Pillar Rise','Low Definition','Vector Step','Absolute Form','Lattice Turn','Projected Palm','Reverse Facet','Zenith Frame','Descending Plane'],
  'speed':[440,480,520,560], 'life':[44,48,52,56], 'shot_damage':[6,7,8,10],
 },
}


def save(path, data):
 path.parent.mkdir(parents=True, exist_ok=True)
 path.write_text(json.dumps(data, indent=2)+'\n')


def author():
 for fid in IDS:
  s=SPECS[fid];path=ROOT/f'game-godot/data/moves/{fid}.json';d=json.loads(path.read_text())
  d.update(combat_tag=s['tag'],status='TUNING_CANDIDATE',owner_approved=False,kit_authority='source/ANIME_AGGRESSORS_COMPLETE_CHARACTER_MOVEMENT_ANIMATION_BIBLE_V1.md sections16–18',candidate_mechanics='bounded reduction' if fid=='yin' else 'finite construction')
  for m in d['moves']:
   mid=m['move_id'];m.update(fighter_id=fid,combat_tag=s['tag'],status='TUNING_CANDIDATE',owner_approved=False)
   m['element_effect']={'type':s['element'],'effect':'reduction' if fid=='yin' else 'definition','strength':1}
   shape='subtractive_aperture' if fid=='yin' else 'constructed_hex_radiance'
   m['v3_vfx_shape']=shape;m['v3_particle_library']=shape
   m['feedback'].update(vfx_event=f'{fid}.{mid}.{shape}',sfx_event=f'{fid}.{mid}.sfx',particle_profile=f'{fid}.{shape}',screen_flash=False)
   if 'h2h_string_id' in m:m['h2h_string_id']=m['h2h_string_id'].replace('ember-vale:',fid+':')
   m['v3_fantasy']='Original inward reduction and economical palm chain' if fid=='yin' else 'Original outward definition and ordered palm chain'
   # Existing rectangles are preserved; distinct authored rhythm and force are
   # candidates only for the two previously unapproved copied cosmic kits.
   if mid in NORMALS:
    i=NORMALS.index(mid);m.update(startup_frames=s['startup'][i],recovery_frames=s['recovery'][i],damage=s['damage'][i],angle_deg=s['angle'][i],training_display_name=s['names'][i])
    if mid in ['jab_1','jab_2']:
     end=m['startup_frames']+m['active_frames']+m['recovery_frames']-1
     m['cancel_windows']=[{'start':m['startup_frames']+m['active_frames'],'end':end,'requires':'hit_confirm','to':'jab_2' if mid=='jab_1' else 'jab_finisher'}]
   elif mid=='neutral_special_projectile':
    m.update(startup_frames=8 if fid=='yin' else 7,recovery_frames=18 if fid=='yin' else 16,damage=s['shot_damage'][0],angle_deg=120 if fid=='yin' else 42,training_display_name='Aperture Pulse' if fid=='yin' else 'Defined Ray')
    p=m['projectile'];p.update(type='null_aperture' if fid=='yin' else 'radiant_facet',speed_by_aura=s['speed'],damage_by_aura=s['shot_damage'],lifetime_frames_by_aura=s['life'],behavior_by_aura=['straight']*4,speed=s['speed'][0],lifetime_frames=s['life'][0],pierce=False,spawn_frame=m['startup_frames'])
   elif mid=='side_special':
    m.update(startup_frames=9 if fid=='yin' else 8,recovery_frames=20 if fid=='yin' else 18,damage=7.5 if fid=='yin' else 8.0,angle_deg=120 if fid=='yin' else 35,training_display_name='Distance Fold' if fid=='yin' else 'Declared Vector')
    m['self_movement']={'x':100 if fid=='yin' else 140,'y':0}
   elif mid=='up_special_recovery':
    m.update(startup_frames=7,recovery_frames=20,damage=6.0,angle_deg=90,training_display_name='Quiet Ascent' if fid=='yin' else 'Constructed Ascent')
    m['self_movement']={'x':0,'y':-320} # Existing authorized recovery impulse retained.
   elif mid=='down_special':
    m.update(startup_frames=9 if fid=='yin' else 10,active_frames=6 if fid=='yin' else 2,recovery_frames=24,damage=0 if fid=='yin' else 4,training_display_name='Absorption Window' if fid=='yin' else 'Definition Panel')
    if fid=='yin':m.update(move_type='counter',cosmic_counter={'max_integrity':1,'aura_cost':25.0,'max_per_activation':1})
    else:
     m.update(move_type='projectile')
     m['projectile']={'type':'definition_panel','offset_x':46,'offset_y':-12,'angle_deg':0,'spawn_frame':10,'speed_by_aura':[0]*4,'damage_by_aura':[4]*4,'size_by_aura':[20]*4,'lifetime_frames_by_aura':[36]*4,'behavior_by_aura':['straight']*4,'pierce':False,'max_active_per_move':1}
   elif mid=='aura_burst':
    m.update(startup_frames=14 if fid=='yin' else 12,recovery_frames=28,damage=15 if fid=='yin' else 16,angle_deg=125 if fid=='yin' else 55,training_display_name=s['signature'])
  save(path,d)
  p=ROOT/f'game-godot/data/fighters/{fid}.json';f=json.loads(p.read_text())
  f.update(signatureMove=s['signature'],combatTag=s['tag'],moveListPath=f'res://data/moves/{fid}.json',animationManifestPath=f'res://data/fighters/{fid}_animations.json',modelPath=f'res://assets/characters/collectible_v1/{fid}/male/BASE.glb',defaultSkin=f'collectible_v1_{fid}',balancePath=f'res://data/balance/{fid}.json',cpuBehaviorTags=['control','projectile','shield'],candidate_kit=True)
  f.pop('portraitPlaceholder',None);f['game001']['identity_depth']='CANDIDATE_RUNTIME_NOT_ACCEPTED';save(p,f)
  states=['idle','walk','run','dash','jump','fall','land','shield','hurt_light','hurt_heavy','launched','ko']
  save(ROOT/f'game-godot/data/fighters/{fid}_animations.json',{'fighter_id':fid,'clips':list(dict.fromkeys(states+[m['move_id'] for m in d['moves']])),'status':'ORIGINAL_AUTHORED_RUNTIME_CANDIDATE','modelPath':f['modelPath']})
  save(ROOT/f'game-godot/data/balance/{fid}.json',{'schema':'game001_fighter_balance/v1','fighter_id':fid,'combat_tag':s['tag'],'status':'TUNING_CANDIDATE','owner_approved':False,'authority':'No inherited Ember profile; current fighter stats retained, cosmic frame/mechanic candidates require owner balance review.',
    'mobility':{'run_mult':1,'dash_mult':1,'air_mult':1,'jump_mult':1,'fall_mult':1},
    'defense':{'shield_mult':1,'dodge_invuln_frames':10,'spot_dodge_frames':18,'air_dodge_frames':22},
    'aura':{'charge_rate_mult':.86 if fid=='yin' else 1.03,'burst_damage_mult':1,'scaling_curve':'controlled_candidate'},
    'recovery':{'up_b_distance':420,'side_b_distance':100 if fid=='yin' else 140,'ledge_snap_priority':'normal'},
    'ai_weights':{'approach':.4,'projectile':.4,'grab':.2,'shield':.4,'aerial':.25},'h2h_priority':['jab_1','jab_2','jab_finisher','side_special']})
 p=ROOT/'game-godot/data/combat/projectile_interactions.json';d=json.loads(p.read_text());d['fighters']['yang']['down_special']={'eligible_behaviors':['straight'],'integrity_by_aura':[1]*5,'residual_damage_exponent':1.0};save(p,d)


def bake():
 # Existing original FK/constraint authoring on the four actual preserved rigs.
 # No GLB regeneration, model transforms, runtime IK layer or external motion.
 from build_combat_choreography import rig, make_clip
 from refine_combat_performance import refine, guard_transition, reaction
 for fid in IDS:
  moves=json.loads((ROOT/f'game-godot/data/moves/{fid}.json').read_text())['moves']
  for body in ['male','female']:
   r,h=rig(fid,body);path=ROOT/f'game-godot/data/animation/combat_choreography/{fid}_{body}.json';doc=json.loads(path.read_text())
   for move in moves:
    if move['move_id']=='aura_charge':continue # Looping state, not a zero-frame attack.
    for facing in [1,-1]:doc['clips'][move['move_id']+('_left' if facing==-1 else '')]=make_clip(r,fid,move,facing)
   # Retain the existing authored neutral/gait/air/landing/victory state tracks.
   path.write_text(json.dumps(doc,separators=(',',':'))+'\n')
   p=ROOT/f'game-godot/data/animation/combat_performance/{fid}_{body}.json';performance=json.loads(p.read_text())
   for mid in ['jab_1','jab_2','heavy_attack','side_special']:
    for suffix in ['','_left']:
     name=mid+suffix;c=refine(r,fid,doc['clips'][name])
     if mid in ['jab_1','heavy_attack']:c=guard_transition(r,c,doc['clips']['idle_primary'])
     performance['clips'][name]=c
   performance['clips']['reaction_light']=reaction(r,fid)
   performance['clips']['reaction_heavy']=reaction(r,fid,True)
   performance['clips']['reaction_elemental']=reaction(r,fid,True,True)
   p.write_text(json.dumps(performance,separators=(',',':'))+'\n')


if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--bake',action='store_true');args=p.parse_args()
 author()
 if args.bake:bake()
 print('Authored two distinct24-move cosmic candidates; seven fighter manifests untouched.')

"""Explicit original key poses on the existing rig; candidate choreography, no balance edits."""
import json,hashlib,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
# hip turn, chest counterturn, strike extension, guard elbow, step, knee, recoil, grammar
DIRECTIONS={
'ember-vale':(.42,.62,-1.22,-.85,.38,.42,.27,'forward thermal drive; planted cross and substantial recoil'),
'juno-spark':(-.30,.48,-1.48,-1.05,.22,.30,.14,'charged pivot; compact guard and sharp snap'),
'rook-ironside':(.24,.32,-.92,-.74,.16,.56,.30,'wide planted base; armored shoulder and mass compression'),
'kaia-windrow':(-.52,.78,-1.12,-.62,.40,.32,.16,'sweeping counterrotation; flowing pressure release'),
'nix-calder':(.12,.20,-1.36,-1.20,.12,.18,.10,'precise straight line; measured structure and crystalline stop'),
'orion-vell':(.64,-.46,-1.02,-.80,.32,.40,.23,'orbital hip pivot; opposing chest vector and compression'),
'vesper-nyx':(-.48,-.28,-1.30,-.56,-.18,.26,.20,'withdrawn feint; crossed angle then decisive return'),
'yin':(-.18,-.52,-.80,-1.26,-.12,.24,.34,'inward subtraction; folded preparation and absorbent recovery'),
'yang':(.18,.54,-1.42,-.48,.24,.20,.12,'constructed symmetry; open structured radiance')}
ALIAS=json.loads((ROOT/'game-godot/data/runtime/move_clip_alias_map.json').read_text())['move_id_to_clip']
def pose(spec,phase,family='strike',side='R'):
 hip,chest,extend,guard,step,knee,recoil,_=spec
 wind=phase=='anticipation';hit=phase=='contact';follow=phase=='follow';idle=phase=='stance'
 factor= -.62 if wind else 1 if hit else .74 if follow else 0
 other='L' if side=='R' else 'R'; sidefactor=1 if side=='R' else -1
 p={'Hips':[.06,hip*factor,.05*factor],'Spine':[-.05,.12*factor,0], 'Chest':[(-recoil if wind else recoil*.5 if follow else -.12 if hit else .02),chest*factor,0], 'Neck':[.03,-chest*factor*.22,0],'Head':[-.03,-hip*factor*.3,0],
 'UpperArm_'+side:[extend if hit else extend*.75 if follow else -.32 if wind else -.35,.12*factor,.16*sidefactor],
 'LowerArm_'+side:[-.12 if hit else -.40 if follow else -1.20,0,0], 'Hand_'+side:[.12*factor,0,-.1*sidefactor],
 'UpperArm_'+other:[-.35,-.10*factor,-.14*sidefactor],'LowerArm_'+other:[guard,0,0],'Hand_'+other:[-.08,0,0],
 'UpperLeg_L':[step*factor,.08*factor,-.10], 'LowerLeg_L':[knee,0,0],'Foot_L':[-knee-step*factor,0,.08],
 'UpperLeg_R':[-step*factor,-.08*factor,.10],'LowerLeg_R':[knee*.7,0,0],'Foot_R':[-knee*.7+step*factor,0,-.08]}
 if family=='heavy':p['Chest'][0]-=.16*factor;p['Hips'][1]*=1.5;p['UpperArm_'+side][0]*=.85
 if family=='projectile':
  p['UpperArm_L']=[extend*factor,.12,0];p['LowerArm_L']=[-.15 if hit else -1.0,0,0];p['Chest'][0]+=.18 if follow else 0
 if family=='aerial':p['UpperLeg_R']=[-.8*factor,0,.16];p['LowerLeg_R']=[.65,0,0];p['Foot_R']=[-.35,0,0]
 if family=='up':p['UpperArm_'+side][0]=-2.5 if hit else -.7;p['Chest'][0]=-.22*factor
 if family=='down':p['Chest'][0]=.4*factor;p['UpperArm_'+side][0]=-.65 if hit else -1.1
 return p
rows=[]
for fid,spec in DIRECTIONS.items():
 clips={};moves=json.loads((ROOT/f'game-godot/data/moves/{fid}.json').read_text())['moves']
 for move in moves:
  mid=move['move_id'];start=move['startup_frames'];active=move['active_frames'];total=start+active+move['recovery_frames']
  family='projectile' if move.get('move_type')=='projectile' or mid=='aura_burst' else 'heavy' if 'heavy' in mid or 'signature' in mid else 'aerial' if '_air' in mid else 'up' if mid.startswith('up_') else 'down' if mid.startswith('down_') else 'strike'
  side='L' if mid in ('jab_2','back_air','throw_back') else 'R'
  frames=[(0,'stance'),(max(1,start-1),'anticipation'),(start+1,'contact'),(start+max(2,active),'follow'),(total,'stance')]
  tracks={}
  for frame,phase in frames:
   for bone,rotation in pose(spec,phase,family,side).items():tracks.setdefault(bone,[]).append({'time_s':frame/60,'rotation_rad':rotation})
  clip={'duration_frames':total,'contact_frame':start+1,'bone_tracks':tracks,'relative_to_rest':True,'family':family,'loop':False}
  clips[mid]=clip
  if mid in ALIAS:clips[ALIAS[mid]]=clip
  if mid=='neutral_special_projectile':
   for name in ('projectile_tap','projectile_medium','projectile_full'):clips[name]=clip
  rows.append({'fighter_id':fid,'move_id':mid,'family':family,'first_contact_frame':start+1,'total_frames':total,'status':'EXPLICIT_KEY_POSE_CANDIDATE_RUNTIME','foot_plant':'counter-rotated feet; final IK/foot-slip review pending','final_authored_animation_approved':False,'hash':hashlib.sha256(json.dumps(tracks,sort_keys=True).encode()).hexdigest()})
 for name in ('idle','idle_primary','idle_secondary','walk','walk_loop','run','run_loop','shield','shield_hold','aura_charge','aura_ready','charged_idle','hurt_light','hurt_heavy','hitstun_ground','launch','launched','victory','defeat','dodge','air_dodge','recovery','fall','story_dialogue_neutral','story_dialogue_intense'):
  tracks={};length=40 if 'run' in name else 60
  for i,phase in enumerate(('stance','anticipation','stance','follow','stance')):
   p=pose(spec,phase)
   if 'run' in name or 'walk' in name:
    stride=math.sin(i*math.pi/2)*(.6 if 'run' in name else .28)
    for side,sgn in [('L',1),('R',-1)]:p['UpperLeg_'+side][0]=stride*sgn;p['LowerLeg_'+side][0]=max(0,-stride*sgn)*.65;p['Foot_'+side][0]=-stride*sgn*.45;p['UpperArm_'+side][0]=-.3-stride*sgn*.7
   elif 'shield' in name or 'aura' in name or name=='charged_idle':
    p['LowerArm_L'][0]=-1.4;p['LowerArm_R'][0]=-1.4;p['UpperArm_L'][0]=-.7;p['UpperArm_R'][0]=-.7
   elif 'hurt' in name or name in ('launch','launched','defeat','hitstun_ground'):
    p['Chest'][0]=-.45*(i%2);p['Head'][0]=-.18;p['UpperLeg_L'][0]=-.4;p['UpperLeg_R'][0]=.4
   for bone,rotation in p.items():tracks.setdefault(bone,[]).append({'time_s':i*length/240,'rotation_rad':rotation})
  clips[name]={'duration_frames':length,'bone_tracks':tracks,'relative_to_rest':True,'loop':name not in ('victory','defeat','dodge','air_dodge','hurt_light','hurt_heavy','launch','launched','recovery')}
 path=ROOT/f'game-godot/data/animation/authored_studies/{fid}.json';path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps({'status':'ORIGINAL_EXPLICIT_KEY_POSE_STUDY_NOT_FINAL','direction':spec[-1],'clips':clips},indent=2)+'\n')
report=ROOT/'artifacts/v1_closure/dialogue_performance/choreography_matrix.json';report.write_text(json.dumps({'moves':len(rows),'fighters':9,'authoring':'Explicit original pose directions, deterministic timeline assembly; candidate studies, final actor/keyframe polish not claimed.','rows':rows,'secondary_motion':'Existing accessories deform with canonical rig; separate hair/cloth simulation pending','cosmic_boss_grammar':'Distinct inward Yin / constructed Yang pose grammar; separate scale-aware boss choreography pending','human_pass':False},indent=2)+'\n')
print(json.dumps({'moves':len(rows),'fighters':9}))

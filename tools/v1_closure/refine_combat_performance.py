"""Original keyed performance refinements, retargeted onto the preserved 18 rigs.
No external motion, root motion, combat frame-data or model changes.
"""
import argparse, json, math
import numpy as np
from build_combat_choreography import ROOT, DIRECTION, AIR, rig, fk, solve, matrix, quat, euler, blend

# Hip lead, ribcage delay and striking-arm delay in authored frames. The active
# interval remains byte-identical in time/pose; this is preparation/follow-through.
CHAIN={
 'ember-vale':(1.5,.8,1.4), 'rook-ironside':(2.,1.2,1.8),
 'juno-spark':(.8,.35,.6), 'kaia-windrow':(1.4,.7,1.1),
 'nix-calder':(.6,.3,.45), 'orion-vell':(1.6,.9,1.3),
 'vesper-nyx':(1.1,.6,1.6), 'yin':(1.8,1.1,1.5), 'yang':(1.,.5,.8)}
# Chest break, opposite pelvis turn, head delay, arm opening, recoil compression.
HURT={
 'ember-vale':(.44,-.18,2.,.065,.025), 'rook-ironside':(.26,-.10,3.,.025,.035),
 'juno-spark':(.34,.20,1.,.085,.016), 'kaia-windrow':(.30,.24,2.,.095,.020),
 'nix-calder':(.24,-.08,1.,.030,.014), 'orion-vell':(.33,-.27,3.,.065,.023),
 'vesper-nyx':(.28,.29,2.,.105,.018), 'yin':(.40,-.20,3.,.035,.028),
 'yang':(.25,.14,1.,.080,.016)}

def sample(keys,t):
 a=keys[min(int(t),len(keys)-1)];b=keys[min(int(t)+1,len(keys)-1)];u=t-int(t)
 x=np.array(a['rotation_quat']);y=np.array(b['rotation_quat']);y*=1 if np.dot(x,y)>=0 else -1
 q=x*(1-u)+y*u;q/=np.linalg.norm(q)
 p=None
 if 'position_m' in a:p=np.array(a['position_m'])*(1-u)+np.array(b['position_m'])*u
 return matrix(q),p

def key(frame,rotation,position=None):
 d={'time_s':round(frame/60,6),'rotation_quat':[round(float(x),7) for x in quat(rotation)]}
 if position is not None:d['position_m']=[round(float(x),7) for x in position]
 return d

def guard_transition(r, clip, neutral):
 """Bake a guard-to-load and recoil-to-guard transition, not a runtime solver.

 The full collision interval and the hook are immutable. Existing pelvis lead,
 ribcage delay and limb arcs remain the authored performance between boundaries.
 Both support feet follow their original targets; no root/scale/length edits.
 """
 result=json.loads(json.dumps(clip));tracks=result['bone_tracks']
 start=clip['startup_frames'];active_end=start+clip['active_frames'];total=clip['duration_frames']
 arrival=max(1,round(start*.6));settle=active_end+max(2,round((total-active_end)*.45))
 for f in range(total+1):
  if start<=f<=active_end:continue
  weight=1-blend([(0,0.),(arrival,1.)],f) if f<start else blend([(settle,0.),(total,1.)],f)
  if weight<=0:continue
  rots={};pos={};source_rots={};source_pos={}
  for n,keys in tracks.items():
   old=clip['bone_tracks'][n][f];target=neutral['bone_tracks'][n][0]
   a=np.array(old['rotation_quat']);b=np.array(target['rotation_quat'])
   if np.dot(a,b)<0:b=-b
   dot=np.clip(np.dot(a,b),-1.,1.)
   if dot>.9995:q=a+(b-a)*weight;q/=np.linalg.norm(q)
   else:
    angle=math.acos(dot);q=(math.sin((1-weight)*angle)*a+math.sin(weight*angle)*b)/math.sin(angle)
   source_rots[n]=matrix(a);rots[n]=matrix(q)
   if 'position_m' in old:
    source_pos[n]=np.array(old['position_m'])
    pos[n]=source_pos[n]*(1-weight)+np.array(target['position_m'])*weight
  original=fk(r,source_rots,source_pos)
  for side in ['L','R']:
   foot='Foot_'+side;target=original[foot]
   g=solve(r,rots,pos,'UpperLeg_'+side,'LowerLeg_'+side,foot,target[1],np.array([0,0,-1.]))
   rots[foot]=g[r[foot]['parent']][0].T@target[0]
  for n in tracks:tracks[n][f]=key(f,rots[n],pos.get(n))
 # Boundary keys are the actual authored neutral, not an approximate new stance.
 # All existing strike support targets already equal neutral at those endpoints.
 for n in tracks:
  for f in [0,total]:
   tracks[n][f]=json.loads(json.dumps(neutral['bone_tracks'][n][0]));tracks[n][f]['time_s']=round(f/60,6)
 result['guard_transition']={'entry_complete_frame':arrival,'settle_start_frame':settle,'neutral_source':'combat_choreography/idle_primary:0','contact_interval_unchanged':True,'hook_unchanged':True,'runtime_solver_added':False}
 return result

def refine(r,fid,clip):
 result=json.loads(json.dumps(clip));tracks=clip['bone_tracks'];out={n:[] for n in tracks}
 start,active,total=clip['startup_frames'],clip['active_frames'],clip['duration_frames']
 hip_lead,chest_lag,arm_lag=CHAIN[fid]
 for f in range(total+1):
  if start<=f<=start+active:
   for n in tracks:out[n].append(json.loads(json.dumps(tracks[n][f])))
   continue
  rots={};pos={};times={}
  # Preserve the collision interval exactly. Ease offsets to zero before entry.
  envelope=math.sin(math.pi*f/max(start,1)) if f<start else math.sin(math.pi*(f-start-active)/max(total-start-active,1))*.6 if f>start+active else 0
  for n,keys in tracks.items():
   shift=hip_lead if n=='Hips' else -chest_lag if n in ['Spine','Chest'] else -arm_lag if 'Arm' in n or 'Hand' in n else -arm_lag*.6 if n in ['Head','Neck'] else 0
   t=max(0,min(total,f+shift*envelope));times[n]=t
   rots[n],p=sample(keys,t)
   if p is not None:pos[n]=p
  if envelope>1e-7:
   # Retain authored hand arcs and solve the changed kinetic chain without
   # lengthening bones. Supporting feet retain the original authored targets.
   for side in ['L','R']:
    hand='Hand_'+side
    source_rots={};source_pos={}
    for n,keys in tracks.items():
     source_rots[n],p=sample(keys,times[hand])
     if p is not None:source_pos[n]=p
    target=fk(r,source_rots,source_pos)[hand]
    g=solve(r,rots,pos,'UpperArm_'+side,'LowerArm_'+side,hand,target[1],np.array([-.7 if side=='L' else .7,-.5,-.12]))
    rots[hand]=g[r[hand]['parent']][0].T@target[0]
   br={};bp={}
   for n,keys in tracks.items():
    br[n],p=sample(keys,f)
    if p is not None:bp[n]=p
   original=fk(r,br,bp)
   for side in ['L','R']:
    foot='Foot_'+side;target=original[foot]
    g=solve(r,rots,pos,'UpperLeg_'+side,'LowerLeg_'+side,foot,target[1],np.array([0,0,-1.]))
    rots[foot]=g[r[foot]['parent']][0].T@target[0]
  for n in tracks:out[n].append(key(f,rots[n],pos.get(n)))
 result['bone_tracks']=out;result['performance']='authored pelvis lead / delayed ribs and arms / constrained support; active poses preserved'
 return result

def reaction(r,fid,heavy=False,elemental=False):
 hip,chest,compression,_,guard,*_=DIRECTION[fid]
 bend,twist,delay,opening,depth=HURT[fid]
 duration=30 if heavy else 18;strength=1 if heavy else .62
 rest=fk(r,{},{});scale=rest['Head'][1][1]/.85
 tracks={n:[] for n in r if n not in ['Root','Toes_L','Toes_R']}
 for f in range(duration+1):
  t=f/duration
  body=blend([(0,.72),(.12,1),(.36,.78),(.72,.28),(1,0)],t)*strength
  head=blend([(0,.18),(delay/duration+.08,1),(.48,.6),(1,0)],t)*strength
  rots={};pos={}
  # Spine breaks along +Z force while pelvis counters, neck lags then settles.
  for n,angles in {'Hips':(.07*body,twist*body,-twist*body*.18),'Spine':(-bend*body*.35,0,twist*body*.12),'Chest':(-bend*body,-twist*body*.7,twist*body*.30),'Neck':(-.12*head,0,0),'Head':(-.24*head,.08*head,0)}.items():rots[n]=r[n]['r']@euler(*angles)
  pos['Hips']=r['Hips']['p']+np.array([twist*.035*body,-compression-depth*body,-.024*body])*scale
  for side in ['L','R']:
   sign=-1 if side=='L' else 1
   extra=(.025*math.sin(math.pi*min(1,t*2))) if elemental else 0
   target=np.array([sign*(.14+opening*body),guard-.08*body+extra,.15-.07*body])*scale
   g=solve(r,rots,pos,'UpperArm_'+side,'LowerArm_'+side,'Hand_'+side,target,np.array([sign*.7,-.5,-.12]));rots['Hand_'+side]=g[r['Hand_'+side]['parent']][0].T@rest['Hand_'+side][0]
  for side in ['L','R']:
   target=rest['Foot_'+side][1].copy()
   g=solve(r,rots,pos,'UpperLeg_'+side,'LowerLeg_'+side,'Foot_'+side,target,np.array([0,0,-1.]));rots['Foot_'+side]=g[r['Foot_'+side]['parent']][0].T@rest['Foot_'+side][0]
  for n in tracks:tracks[n].append(key(f,rots.get(n,r[n]['r']),pos.get(n)))
 return {'duration_frames':duration,'loop':False,'relative_to_rest':False,'bone_tracks':tracks,'authoring':'original signed chest break, counter-pelvis, delayed head, opened guard and constrained knees; no root motion'}

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--guard-only',action='store_true',help='Amend only jab_1/heavy entry and recovery; preserve all other shipped performance clips')
 args=parser.parse_args()
 for fid in DIRECTION:
  for body in ['male','female']:
   r,h=rig(fid,body);source=ROOT/f'game-godot/data/animation/combat_choreography/{fid}_{body}.json';d=json.loads(source.read_text());clips={}
   dest=ROOT/f'game-godot/data/animation/combat_performance/{fid}_{body}.json'
   if args.guard_only:clips=json.loads(dest.read_text())['clips']
   for mid in (['jab_1','heavy_attack'] if args.guard_only else ['jab_1','jab_2','heavy_attack','side_special']):
    for suffix in ['', '_left']:
     name=mid+suffix;clips[name]=refine(r,fid,d['clips'][name])
     if mid in ['jab_1','heavy_attack']:clips[name]=guard_transition(r,clips[name],d['clips']['idle_primary'])
   if not args.guard_only:
    clips['reaction_light']=reaction(r,fid)
    clips['reaction_heavy']=reaction(r,fid,True)
    clips['reaction_elemental']=reaction(r,fid,True,True)
   dest.parent.mkdir(exist_ok=True)
   dest.write_text(json.dumps({'schema':'original_performance_refinement/v1','fighter':fid,'body':body,'rig_sha256':h,'human_approved':False,'clips':clips},separators=(',',':'))+'\n')
 print('Authored performance refinements written for nine fighters and both existing rigs')
if __name__=='__main__':main()

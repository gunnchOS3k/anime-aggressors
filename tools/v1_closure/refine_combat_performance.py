"""Original keyed performance refinements, retargeted onto the preserved 18 rigs.
No external motion, root motion, combat frame-data or model changes.
"""
import json, math
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
 for fid in DIRECTION:
  for body in ['male','female']:
   r,h=rig(fid,body);source=ROOT/f'game-godot/data/animation/combat_choreography/{fid}_{body}.json';d=json.loads(source.read_text());clips={}
   for mid in ['jab_1','jab_2','heavy_attack','side_special']:
    for suffix in ['', '_left']:
     name=mid+suffix;clips[name]=refine(r,fid,d['clips'][name])
   clips['reaction_light']=reaction(r,fid)
   clips['reaction_heavy']=reaction(r,fid,True)
   clips['reaction_elemental']=reaction(r,fid,True,True)
   dest=ROOT/f'game-godot/data/animation/combat_performance/{fid}_{body}.json';dest.parent.mkdir(exist_ok=True)
   dest.write_text(json.dumps({'schema':'original_performance_refinement/v1','fighter':fid,'body':body,'rig_sha256':h,'human_approved':False,'clips':clips},separators=(',',':'))+'\n')
 print('Authored performance refinements written for nine fighters and both existing rigs')
if __name__=='__main__':main()

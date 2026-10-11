"""Original combat blocking on existing rigs, baked FK/2-bone constraints at 60 Hz.
No model generation, external motion or gameplay edits. Human motion approval remains false.
"""
import json,struct,math,hashlib
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
# Authored identity: pelvis/chest turn, compression, follow through, guard height,
# lateral hand arc, support step and characteristic recovery timing.
DIRECTION={
'ember-vale':(.55,.72,.045,1.15,.69,.045,.10,.72,'grounded thermal cross / loaded shoulder / recoil'),
'juno-spark':(-.34,.48,.025,.70,.73,-.035,.06,.48,'compact snap / switch guard / rapid pivot settle'),
'rook-ironside':(.28,.38,.055,1.25,.65,.015,.03,.86,'wide bastion / compression / deliberate shoulder drive'),
'kaia-windrow':(-.58,.65,.03,.90,.72,.075,.09,.65,'open sweep / flowing palm arc / spiral recovery'),
'nix-calder':(.16,.24,.018,.55,.72,.008,.025,.40,'tight aligned guard / crystalline straight / held stop'),
'orion-vell':(.62,-.38,.036,.95,.70,-.07,.075,.74,'orbital opposing torso / remapped vector / compression'),
'vesper-nyx':(-.48,-.24,.026,.80,.74,.08,-.055,.56,'withdrawn feint / oblique contact / crossed return'),
'yin':(-.24,-.52,.035,1.0,.66,-.075,-.025,.82,'fold inward / absorbent palm / subtractive settle'),
'yang':(.24,.58,.018,.70,.75,.035,.035,.52,'constructed open guard / symmetric extension / definition')}

# Per-fighter footwork, in rig metres: stride/lift, lean, lateral balance,
# hand counter-swing and stance width. These are visual values only.
GAIT={
'ember-vale':(.12,.032,.18,.012,.075,1.02),
'rook-ironside':(.082,.017,.11,.020,.045,1.30),
'juno-spark':(.135,.040,.13,.008,.105,.90),
'kaia-windrow':(.13,.048,.08,.017,.10,.94),
'nix-calder':(.095,.024,.07,.004,.05,.96),
'orion-vell':(.115,.032,.04,.022,.07,1.08),
'vesper-nyx':(.12,.035,.12,.024,.085,.88),
'yin':(.065,.008,.015,.002,.015,1.04),
'yang':(.11,.028,.035,.003,.06,1.06)}

def unit(x):
 n=np.linalg.norm(x); return x/max(n,1e-10)
def matrix(q):
 x,y,z,w=q; return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
def quat(m):
 # robust rotation-matrix quaternion (xyzw)
 a=np.array([[m[0,0]-m[1,1]-m[2,2],m[1,0]+m[0,1],m[2,0]+m[0,2],m[2,1]-m[1,2]],[m[1,0]+m[0,1],m[1,1]-m[0,0]-m[2,2],m[2,1]+m[1,2],m[0,2]-m[2,0]],[m[2,0]+m[0,2],m[2,1]+m[1,2],m[2,2]-m[0,0]-m[1,1],m[1,0]-m[0,1]],[m[2,1]-m[1,2],m[0,2]-m[2,0],m[1,0]-m[0,1],m[0,0]+m[1,1]+m[2,2]]])/3
 _,v=np.linalg.eigh(a);q=v[:,-1];return q if q[3]>=0 else -q
def euler(x,y,z):
 cx,sx=math.cos(x),math.sin(x);cy,sy=math.cos(y),math.sin(y);cz,sz=math.cos(z),math.sin(z)
 return np.array([[cy,0,sy],[0,1,0],[-sy,0,cy]])@np.array([[1,0,0],[0,cx,-sx],[0,sx,cx]])@np.array([[cz,-sz,0],[sz,cz,0],[0,0,1]])
def align(a,b):
 a,b=unit(a),unit(b);v=np.cross(a,b);c=np.dot(a,b)
 if c<-.9999:
  axis=unit(np.cross(a,[1,0,0] if abs(a[0])<.9 else [0,1,0]));return 2*np.outer(axis,axis)-np.eye(3)
 vx=np.array([[0,-v[2],v[1]],[v[2],0,-v[0]],[-v[1],v[0],0]])
 return np.eye(3)+vx+vx@vx/max(1+c,1e-10)
def rig(fid,variant):
 raw=(ROOT/f'game-godot/assets/characters/collectible_v1/{fid}/{variant}/BASE.glb').read_bytes();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);nodes=doc['nodes'];indices=doc['skins'][0]['joints'];names={nodes[i]['name']:i for i in indices};parents={c:i for i,x in enumerate(nodes) for c in x.get('children',[])}
 r={}
 for name,i in names.items():
  x=nodes[i];parent=nodes[parents[i]]['name'] if parents.get(i) in indices else None
  r[name]={'p':np.array(x.get('translation',[0,0,0]),float),'r':matrix(x.get('rotation',[0,0,0,1])),'parent':parent}
 return r,hashlib.sha256(raw).hexdigest()
def fk(r,rots,pos):
 out={}
 def bone(n):
  if n in out:return out[n]
  x=r[n];R=rots.get(n,x['r']);p=pos.get(n,x['p']);parent=x['parent']
  if parent:
   pr,pp=bone(parent);out[n]=(pr@R,pp+pr@p)
  else:out[n]=(R,p)
  return out[n]
 for n in r:bone(n)
 return out
def solve(r,rots,pos,a,b,c,target,pole):
 g=fk(r,rots,pos);ar,ap=g[a];bp=g[b][1];cp=g[c][1];l1=np.linalg.norm(bp-ap);l2=np.linalg.norm(cp-bp);v=target-ap;dist=np.linalg.norm(v)
 dist=min(max(dist,abs(l1-l2)+1e-5),l1+l2-1e-5);axis=unit(v);bend=unit(pole-axis*np.dot(pole,axis));along=(l1*l1-l2*l2+dist*dist)/(2*dist);height=math.sqrt(max(0,l1*l1-along*along));knee=ap+axis*along+bend*height
 desired=align(bp-ap,knee-ap)@ar;parent=r[a]['parent'];rots[a]=g[parent][0].T@desired if parent else desired
 g=fk(r,rots,pos);desired=align(g[c][1]-g[b][1],target-g[b][1])@g[b][0];rots[b]=g[r[b]['parent']][0].T@desired
 return fk(r,rots,pos)
def smooth(t):return t*t*(3-2*t)
def blend(points,t):
 if t<=points[0][0]:return points[0][1]
 for (a,x),(b,y) in zip(points,points[1:]):
  if t<=b:return x+(y-x)*smooth((t-a)/max(b-a,1e-8))
 return points[-1][1]
def make_clip(r,fid,move):
 spec=DIRECTION[fid];hip,chest,compression,follow,guard,arc,step,settle,_=spec
 mid=move['move_id'];startup=move['startup_frames'];active=move['active_frames'];total=startup+active+move['recovery_frames'];contact=0 if move.get('move_type')=='throw' else startup+1
 rest=fk(r,{},{});scale=rest['Head'][1][1]/.85
 foot={side:rest['Foot_'+side][1].copy() for side in ['L','R']}
 # Each move is blocked as a different technique, with original cartesian limb paths.
 technique='cross';side='R';aerial='_air' in mid
 if mid=='jab_2':technique='hook';side='L'
 elif mid in ['forward_tilt','dash_attack','forward_air']:technique='drive'
 elif mid in ['up_tilt','up_air','up_special_recovery']:technique='uppercut'
 elif mid in ['down_tilt','down_air','down_special']:technique='low_sweep'
 elif mid=='back_air':technique='back_elbow';side='L'
 elif mid in ['heavy_attack','aura_burst']:technique='hammer' if fid in ['ember-vale','rook-ironside','yin'] else 'charged_palm'
 elif move.get('move_type')=='projectile':technique='projectile'
 elif move.get('move_type') in ['throw','grab']:technique='throw_'+move.get('direction',mid.removeprefix('throw_')) if mid.startswith('throw_') else 'grab'
 load=max(1,startup*.65);followframe=min(total-2,contact+max(2,active));settleframe=min(total-1,followframe+(total-followframe)*settle)
 timing=[(0,0.),(load,-.65),(max(load+.1,startup-1),-.85),(contact,1.),(followframe,follow),(settleframe,.18),(total,0.)]
 if move.get('move_type')=='throw':
  # Existing gameplay releases at frame zero; preparation belongs to grab hold.
  timing=[(0,1.),(max(2,startup),follow),(followframe,.65),(settleframe,.18),(total,0.)]
 tracks={n:[] for n in r if n not in ['Root','Toes_L','Toes_R']}
 slip=0.;clamps=0
 for frame in range(total+1):
  drive=blend(timing,frame);extension=blend([(0,0.),(load,0.),(max(load+.1,startup-1),.06),(contact,1.),(followframe,.94),(settleframe,.28),(total,0.)],frame)
  if move.get('move_type')=='throw':extension=blend([(0,1.),(followframe,.9),(settleframe,.28),(total,0.)],frame)
  rots={};pos={}
  for n,angles in {'Hips':(0,hip*drive,.035*drive),'Spine':(.07*drive,.12*drive,0),'Chest':(.09*drive,chest*drive,0),'Neck':(0,-chest*drive*.25,0),'Head':(.03,-hip*drive*.25,0)}.items():rots[n]=r[n]['r']@euler(*angles)
  pos['Hips']=r['Hips']['p']+np.array([step*drive*.28,-compression*(.5+.5*abs(drive)), step*drive*.30])*scale
  # Guard and strike targets live in rig space; elbows are deliberately outside ribs.
  for hand in ['L','R']:
   sign=-1 if hand=='L' else 1
   target=np.array([sign*.14,guard,-.15])*scale
   if hand==side:
    wind=np.array([sign*.19,guard-.035,-.07])*scale
    target=wind+(np.array([sign*.08,guard-.025,-.405])*scale-wind)*extension
    target[0]+=arc*math.sin(extension*math.pi)*scale
    if technique=='hook':target=np.array([sign*(.21-.20*extension),guard,-.10-.30*extension])*scale
    elif technique=='uppercut':target=np.array([sign*.09,guard-.15+.28*extension,-.13-.13*extension])*scale
    elif technique=='low_sweep':target=np.array([sign*.17,guard-.18*extension,-.12-.25*extension])*scale
    elif technique=='back_elbow':target=np.array([sign*.20,guard-.04,-.1+.3*extension])*scale
    elif technique=='hammer':target=np.array([sign*.07,guard+.18*(1-extension),-.1-.28*extension])*scale
    elif technique=='charged_palm':target=np.array([sign*.06,guard,-.13-.31*extension])*scale
   if technique=='projectile':target=np.array([sign*.10,guard-.02,-.16-.26*extension])*scale
   if technique.startswith('throw_'):
    target=np.array([sign*.12,guard-.08,-.14-.22*extension])*scale
    if technique.endswith('up'):target[1]+=.18*extension*scale
    elif technique.endswith('down'):target[1]-=.23*extension*scale
    elif technique.endswith('back'):target[2]+=.40*extension*scale
   target[2]*=-1 # Live FighterFacingContract models face +Z.
   g=solve(r,rots,pos,'UpperArm_'+hand,'LowerArm_'+hand,'Hand_'+hand,target,np.array([sign*.7,-.5,-.12]));rots['Hand_'+hand]=g[r['Hand_'+hand]['parent']][0].T@rest['Hand_'+hand][0]
  for leg in ['L','R']:
   goal=foot[leg].copy()
   if aerial:goal+=np.array([0,.045*extension,(-.08 if leg=='R' else .08)*extension])*scale
   elif leg=='R' and technique in ['drive','charged_palm']:goal[2]+=.055*extension*scale;goal[1]+=.012*math.sin(extension*math.pi)*scale
   g=solve(r,rots,pos,'UpperLeg_'+leg,'LowerLeg_'+leg,'Foot_'+leg,goal,np.array([0,0,-1.]));rots['Foot_'+leg]=g[r['Foot_'+leg]['parent']][0].T@rest['Foot_'+leg][0]
   if not aerial and leg=='L':slip=max(slip,float(np.linalg.norm(g['Foot_'+leg][1]-goal)))
  for n in tracks:
   tracks[n].append({'time_s':round(frame/60,6),'rotation_quat':[round(float(x),7) for x in quat(rots.get(n,r[n]['r']))],**({'position_m':[round(float(x),7) for x in pos[n]]} if n in pos else {})})
 return {'startup_frames':startup,'active_frames':active,'recovery_frames':move['recovery_frames'],'duration_frames':total,'contact_frame':contact,'loop':False,'relative_to_rest':False,'bone_tracks':tracks,'technique':technique,'support_foot':'L' if not aerial else None,'max_baked_support_slip_m':slip,'authoring':'original authored blocking + baked analytic two-bone constraints; owner quality approval pending'}
def make_state(r,fid,name):
 spec=DIRECTION[fid];hip,chest,compression,follow,guard,arc,step,settle,_=spec
 rest=fk(r,{},{});scale=rest['Head'][1][1]/.85
 stride,lift,run_lean,sway,arm_swing,width=GAIT[fid]
 length=32 if name in ['run','run_loop','dash_loop'] else 48 if name in ['walk','walk_loop'] else 24 if name.startswith('land') else 60
 loop=name in ['idle','idle_primary','idle_secondary','walk','walk_loop','run','run_loop','dash_loop','shield','shield_hold','fall','aura_charge','aura_ready','charged_idle']
 tracks={n:[] for n in r if n not in ['Root','Toes_L','Toes_R']}
 for f in range(length+1):
  t=f/length;wave=math.sin(2*math.pi*t);pulse=math.sin(math.pi*t);travel=name in ['walk','walk_loop','run','run_loop','dash_loop'];hurt=name in ['hurt_light','hurt_heavy','hitstun_ground','launch','launched','tumble','defeat']
  rots={};pos={}
  turn=.05*wave if travel else -.18*pulse if hurt else .012*wave
  lean=run_lean*(1.18 if name=='dash_loop' else 1.0) if name in ['run','run_loop','dash_loop'] else -.32*pulse if hurt else .06*pulse if name.startswith('land') else -.02
  for n,angles in {'Hips':(0,hip*turn,0),'Spine':(lean*.25,0,0),'Chest':(lean,chest*turn,0),'Neck':(lean*.15,0,0),'Head':(-lean*.22,0,0)}.items():rots[n]=r[n]['r']@euler(*angles)
  lower=compression+(.012*abs(wave) if travel else .045*pulse if name.startswith('land') else .035*pulse if hurt else .003*wave)
  pos['Hips']=r['Hips']['p']+np.array([sway*wave if travel else 0,-lower,.012 if travel else 0])*scale
  for hand in ['L','R']:
   sign=-1 if hand=='L' else 1;target=np.array([sign*.14,guard,-.15])*scale
   if travel:target+=np.array([0,-.08,(arm_swing if hand=='L' else -arm_swing)*wave])*scale
   if name in ['shield','shield_hold']:target=np.array([sign*.11,guard+.02,-.20])*scale
   if name in ['aura_charge','aura_ready','charged_idle']:target=np.array([sign*(.13+.012*wave),guard-.10,-.17])*scale
   if hurt:target+=np.array([sign*.045*pulse,-.06*pulse,.08*pulse])*scale
   if name=='victory':target+=np.array([sign*.09*pulse,.16*pulse,-.04*pulse])*scale
   target[2]*=-1 # Live FighterFacingContract models face +Z.
   g=solve(r,rots,pos,'UpperArm_'+hand,'LowerArm_'+hand,'Hand_'+hand,target,np.array([sign*.7,-.5,-.12]));rots['Hand_'+hand]=g[r['Hand_'+hand]['parent']][0].T@rest['Hand_'+hand][0]
  for leg in ['L','R']:
   goal=rest['Foot_'+leg][1].copy();phase=t+(0 if leg=='L' else .5);v=math.sin(2*math.pi*phase)
   if travel:
    phase%=1.0
    # Linear backward support travel cancels actual body displacement during
    # stance; original curved swing returns the foot with measured clearance.
    reach=stride*(.72 if name.startswith('walk') else 1.0)*scale
    if phase<.5:goal[2]+=reach*(1-4*phase)
    else:
     swing=(phase-.5)*2;goal[2]+=reach*(-1+2*smooth(swing));goal[1]+=lift*math.sin(math.pi*swing)*scale
    goal[0]*=width
   if name in ['jump','fall','launch','launched','tumble']:goal+=np.array([0,.06*pulse,(.07 if leg=='L' else -.09)*pulse])*scale
   g=solve(r,rots,pos,'UpperLeg_'+leg,'LowerLeg_'+leg,'Foot_'+leg,goal,np.array([0,0,-1.]));rots['Foot_'+leg]=g[r['Foot_'+leg]['parent']][0].T@rest['Foot_'+leg][0]
  for n in tracks:tracks[n].append({'time_s':round(f/60,6),'rotation_quat':[round(float(x),7) for x in quat(rots.get(n,r[n]['r']))],**({'position_m':[round(float(x),7) for x in pos[n]]} if n in pos else {})})
 return {'gait_half_stride_m':stride*(.72 if name.startswith('walk') else 1.0)*scale if name in ['walk','walk_loop','run','run_loop','dash_loop'] else 0,'duration_frames':length,'loop':loop,'relative_to_rest':False,'bone_tracks':tracks,'technique':'authored_'+name,'authoring':'original locomotion/reaction blocking; no root motion authority'}

rows=[]
for fid in DIRECTION:
 moves=json.loads((ROOT/f'game-godot/data/moves/{fid}.json').read_text())['moves']
 for variant in ['male','female']:
  r,h=rig(fid,variant);clips={}
  for move in moves:
   clip=make_clip(r,fid,move);clips[move['move_id']]=clip;rows.append({'fighter':fid,'body':variant,'move':move['move_id'],'technique':clip['technique'],'contact_frame':clip['contact_frame'],'support_slip_m':clip['max_baked_support_slip_m'],'status':'AUTHORED_RUNTIME_BLOCKING_NOT_HUMAN_APPROVED'})
  for name in ['idle','idle_primary','idle_secondary','walk','walk_loop','run','run_loop','dash_loop','jump','fall','land_soft','land_hard','shield','shield_hold','aura_charge','aura_ready','charged_idle','hurt_light','hurt_heavy','hitstun_ground','launch','launched','tumble','victory','defeat']:
   clips[name]=make_state(r,fid,name)
  dest=ROOT/f'game-godot/data/animation/combat_choreography/{fid}_{variant}.json';dest.parent.mkdir(exist_ok=True);dest.write_text(json.dumps({'schema':'original_combat_blocking/v1','fighter':fid,'body':variant,'rig_sha256':h,'direction':DIRECTION[fid][-1],'mesh_forward_axis':'+Z (live FighterFacingContract)','clips':clips},separators=(',',':'))+'\n')
report=ROOT/'artifacts/v1_closure/spectral_feedback/continuous_1011/CHOREOGRAPHY_MATRIX.json';report.parent.mkdir(parents=True,exist_ok=True);report.write_text(json.dumps({'rows':rows,'human_pass':False,'root_motion_authoritative':False,'foot_scope':'baked local rig-space support during stationary strikes; moving-world foot lock not claimed','locomotion':'original fighter-specific linear support/curved swing gait; runtime distance matching; authored turn/stop and complete world foot constraints pending','secondary':'bounded runtime follow-through layer pending','provenance':'Independently authored original hand/body paths; no external clips; existing rig/model retained'},indent=2)+'\n')
print(json.dumps({'clips':len(rows),'max_baked_slip_m':max(x['support_slip_m'] for x in rows)}))

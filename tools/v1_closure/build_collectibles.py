"""Original articulated collectible candidates. Run with Blender --background --python.
Procedural key-pose studies are candidates, never authored/human completion claims.
"""
import os
import bpy
import math
import json
import hashlib
import shutil
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / 'docs/anime-aggressors/creative/authority_pack_v1'
OUT = ROOT / 'game-godot/assets/characters/collectible_v1'
ART = ROOT / 'artifacts/v1_closure/review'
SRC = ROOT / 'art_source/collectible_v1'
AUTH = json.loads((PACK / 'MODEL_ROSTER_AUTHORITY.json').read_text())
INDEX = json.loads((ROOT / 'data/bibles/animation_inventory_v1.json').read_text())
SLOTS = [s['id'] for c in INDEX['categories'] for s in c['slots']]
ALIAS = json.loads((ROOT / 'game-godot/data/runtime/move_clip_alias_map.json').read_text())
SHAPE = {
 'ember-vale': dict(mass=1.0, head=.98, eye=.90, hair='flame', body='furnace', lean=.12),
 'rook-ironside': dict(mass=1.42, head=1.02, eye=.82, hair='strata', body='armor', lean=.03),
 'juno-spark': dict(mass=.77, head=.95, eye=1.04, hair='fork', body='rails', lean=.15),
 'kaia-windrow': dict(mass=.88, head=1.02, eye=1.07, hair='wave', body='airfoil', lean=.02),
 'nix-calder': dict(mass=1.08, head=.96, eye=.85, hair='crystal', body='lattice', lean=0),
 'orion-vell': dict(mass=.94, head=.97, eye=.92, hair='orbit', body='orbit', lean=0),
 'vesper-nyx': dict(mass=.83, head=.96, eye=1.02, hair='phase', body='cowl', lean=.06),
 'yin': dict(mass=.80, head=.98, eye=.78, hair='collapse', body='inward', lean=0),
 'yang': dict(mass=.85, head=.98, eye=.93, hair='radiant', body='outward', lean=0),
}
PARTS = []
ARM = None


def rgb(h):
 return tuple(int(h.lstrip('#')[i:i+2],16)/255 for i in (0,2,4))


def material(name, color, metallic=.08, emission=0):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1)
 p.inputs['Roughness'].default_value=.34; p.inputs['Metallic'].default_value=metallic
 p.inputs['Emission'].default_value=(*color,1); p.inputs['Emission Strength'].default_value=emission
 return m


def bind(ob,bone,mat):
 ob.data.materials.append(mat)
 for face in ob.data.polygons: face.use_smooth=True
 group=ob.vertex_groups.new(name=bone); group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
 mod=ob.modifiers.new('Canonical deformation','ARMATURE'); mod.object=ARM
 ob.parent=ARM; PARTS.append(ob); return ob


def ellipsoid(name,center,size,mat,bone='Chest',faceted=False):
 if faceted: bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=center)
 else: bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,location=center)
 ob=bpy.context.object; ob.name=name; ob.scale=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bind(ob,bone,mat)
 if faceted:
  for face in ob.data.polygons: face.use_smooth=False
 return ob


def capsule(name,a,b,r,mat,bone='Chest'):
 a,b=Vector(a),Vector(b); ob=ellipsoid(name,(a+b)/2,(r,r,(b-a).length/2+r*.35),mat,bone)
 ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler(); return ob


def tube(name,points,r,mat,bone='Chest'):
 curve=bpy.data.curves.new(name,'CURVE'); curve.dimensions='3D'; curve.resolution_u=3
 curve.bevel_depth=r; curve.bevel_resolution=2
 spline=curve.splines.new('BEZIER'); spline.bezier_points.add(len(points)-1)
 for p,co in zip(spline.bezier_points,points): p.co=co; p.handle_left_type='AUTO'; p.handle_right_type='AUTO'
 ob=bpy.data.objects.new(name,curve); bpy.context.collection.objects.link(ob)
 bpy.ops.object.select_all(action='DESELECT')
 bpy.context.view_layer.objects.active=ob; ob.select_set(True); bpy.ops.object.convert(target='MESH'); ob.select_set(False)
 return bind(ob,bone,mat)


def cone(name,a,b,r,mat,bone='Head',vertices=7):
 a,b=Vector(a),Vector(b); bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=.008,depth=(b-a).length,location=(a+b)/2)
 ob=bpy.context.object; ob.name=name; ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
 return bind(ob,bone,mat)


def ring(name,center,r,thick,mat,bone='Chest',tilt=0):
 pts=[(center[0]+r*math.cos(t),center[1]+r*math.sin(t)*math.sin(tilt),center[2]+r*math.sin(t)*math.cos(tilt)) for t in [i*math.tau/32 for i in range(33)]]
 return tube(name,pts,thick,mat,bone)


def skeleton(mass):
 global ARM
 bpy.ops.object.armature_add(enter_editmode=True)
 ARM=bpy.context.object; ARM.name='AA_CanonicalRig'
 bones=ARM.data.edit_bones; bones.remove(bones[0])
 positions={
 'Root':((0,0,0),(0,0,.1),None),'Hips':((0,0,.43),(0,0,.53),'Root'),
 'Spine':((0,0,.53),(0,0,.65),'Hips'),'Chest':((0,0,.65),(0,0,.78),'Spine'),
 'Neck':((0,0,.78),(0,0,.85),'Chest'),'Head':((0,0,.85),(0,0,1.2),'Neck')}
 for side,sgn in [('L',-1),('R',1)]:
  x=sgn*.20*mass
  positions.update({
   'Shoulder_'+side:((sgn*.10,0,.73),(x,0,.73),'Chest'),
   'UpperArm_'+side:((x,0,.73),(x+sgn*.09,0,.56),'Shoulder_'+side),
   'LowerArm_'+side:((x+sgn*.09,0,.56),(x+sgn*.12,-.04,.43),'UpperArm_'+side),
   'Hand_'+side:((x+sgn*.12,-.04,.43),(x+sgn*.12,-.08,.36),'LowerArm_'+side),
   'UpperLeg_'+side:((sgn*.10,0,.44),(sgn*.13,0,.27),'Hips'),
   'LowerLeg_'+side:((sgn*.13,0,.27),(sgn*.14,0,.10),'UpperLeg_'+side),
   'Foot_'+side:((sgn*.14,0,.10),(sgn*.14,-.14,.08),'LowerLeg_'+side),
   'Toes_'+side:((sgn*.14,-.14,.08),(sgn*.14,-.18,.08),'Foot_'+side)})
 for name,(head,tail,parent) in positions.items():
  b=bones.new(name); b.head=head; b.tail=tail
  if parent: b.parent=bones[parent]
 bpy.ops.object.mode_set(mode='OBJECT')
 for name,bone in [('hand_l','Hand_L'),('hand_r','Hand_R'),('foot_l','Foot_L'),('foot_r','Foot_R'),('chest','Chest'),('head','Head'),('back','Chest'),('projectile_origin','Hand_R'),('aura_root','Root')]:
  marker=bpy.data.objects.new(name,None); bpy.context.collection.objects.link(marker); marker.parent=ARM
  marker.parent_type='BONE'; marker.parent_bone=bone; marker.empty_display_size=.025
 ARM['canonical_bones']=json.dumps(AUTH['canonical_deform_bones']); ARM['sockets']=json.dumps(AUTH['sockets'])


def build_body(fid,variant,row):
 global PARTS
 bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
 # Actions have fake users; remove the prior fighter's clips so exports cannot inherit them.
 for ob in bpy.data.objects:
  if ob.animation_data: ob.animation_data_clear()
 for action in list(bpy.data.actions): bpy.data.actions.remove(action,do_unlink=True)
 for table in (bpy.data.meshes,bpy.data.curves,bpy.data.materials,bpy.data.armatures,bpy.data.actions):
  for item in list(table):
   if item.users==0: table.remove(item)
 PARTS=[]; style=SHAPE[fid]; female=variant=='female'; mass=style['mass']
 skeleton(mass)
 color=rgb(row['color']); dark=tuple(c*.20+.018 for c in color); bright=tuple(min(1,c*.35+.64) for c in color)
 if fid=='yin': bright=(.15,.17,.23); dark=(.017,.021,.033)
 if fid=='yang': dark=(.26,.30,.40); bright=(.94,.90,.77)
 mats={'body':material('Elemental porcelain',color),'dark':material('Structural costume',dark,.22),
       'face':material('Elemental face',bright),'accent':material('Power inlay',color,.35,.25),
       'eye':material('Eye outline',(.025,.03,.06)),'white':material('Eye light',(.96,.98,1)),
       'gold':material('Metal trim',(.82,.54,.14),.7)}
 waist=.145*mass; shoulder=.215*mass*(.96 if female else 1.04)
 ellipsoid('Articulated compact torso',(0,0,.64),(shoulder,.125,.185),mats['dark'])
 ellipsoid('Hip costume',(0,.012,.445),(waist,.122,.105),mats['dark'],'Hips')
 ellipsoid('Chest power plate',(0,-.098,.65),(shoulder*.84,.055,.14),mats['body'])
 for side,sgn in [('L',-1),('R',1)]:
  x=sgn*.20*mass
  capsule('Upper arm '+side,(x,0,.73),(x+sgn*.09,0,.56),.065*mass,mats['body'],'UpperArm_'+side)
  capsule('Forearm '+side,(x+sgn*.09,0,.56),(x+sgn*.12,-.04,.43),.072*mass,mats['dark'],'LowerArm_'+side)
  ellipsoid('Palm '+side,(x+sgn*.12,-.055,.4),(.09*mass,.078,.082),mats['body'],'Hand_'+side)
  for i in range(3): ellipsoid('Finger %s %d'%(side,i),(x+sgn*.12+(i-1)*.035,-.105,.375),(.019,.032,.034),mats['face'],'Hand_'+side)
  capsule('Thigh '+side,(sgn*.1,0,.43),(sgn*.13,0,.27),.082*mass,mats['body'],'UpperLeg_'+side)
  capsule('Shin '+side,(sgn*.13,0,.27),(sgn*.14,0,.10),.075*mass,mats['dark'],'LowerLeg_'+side)
  ellipsoid('Boot '+side,(sgn*.14,-.067,.087),(.108*mass,.165,.085),mats['dark'],'Foot_'+side)
  ellipsoid('Boot toe '+side,(sgn*.14,-.172,.08),(.085*mass,.053,.051),mats['accent'],'Toes_'+side)
 # Original sculpted face: almond eyes + layered iris, eyelids, brows, nose and mouth.
 headwidth=.282*style['head']*(.97 if female else 1.02)
 ellipsoid('Face',(0,-.012,1.115),(headwidth,.24,.30),mats['face'],'Head')
 ellipsoid('Hair cap',(0,.043,1.20),(headwidth*1.05,.245,.245),mats['dark'],'Head')
 for sgn in [-1,1]:
  eye=ellipsoid('Eye almond',(sgn*.112,-.231,1.135),(.080*style['eye'],.026,.053),mats['eye'],'Head')
  eye.rotation_euler[1]=sgn*(-.12 if fid in ['ember-vale','nix-calder'] else .06)
  ellipsoid('Iris',(sgn*.112,-.25,1.135),(.033,.017,.043),mats['accent'],'Head')
  ellipsoid('Pupil',(sgn*.112,-.265,1.136),(.015,.01,.030),mats['eye'],'Head')
  ellipsoid('Eye glint',(sgn*.102,-.274,1.153),(.010,.006,.012),mats['white'],'Head')
  tube('Brow',[(sgn*.046,-.218,1.205),(sgn*.10,-.233,1.223),(sgn*.17,-.215,1.211)],.012,mats['dark'],'Head')
  ellipsoid('Ear',(sgn*headwidth,-.035,1.113),(.03,.055,.075),mats['body'],'Head')
 ellipsoid('Nose plane',(0,-.257,1.076),(.025,.043,.026),mats['face'],'Head')
 mouth=[(-.049,-.225,1.007),(0,-.241,.999),(.048,-.225,1.015 if fid in ['juno-spark','vesper-nyx'] else 1.007)]
 tube('Mouth',mouth,.008,mats['dark'],'Head')
 # Hair modules and costume masses follow fighter geometry, not hue swaps.
 kind=style['hair']
 for i in range(5):
  t=(i-2)*.095; z=1.33+.025*(2-abs(i-2))
  if kind in ['flame','fork','crystal','strata','radiant']:
   tip=(t+(.045 if kind in ['flame','fork'] else 0),.01,1.49+(.10 if kind=='fork' else .04)*((i+1)%2))
   if kind=='strata': tip=(t,-.035,1.47-.025*abs(i-2))
   cone('Hair '+kind+str(i),(t,-.12,z),tip,.092 if kind=='strata' else .062,mats['accent' if kind in ['fork','crystal','radiant'] else 'dark'])
  else:
   sweep=(-.15 if kind in ['phase','collapse'] else .12)
   tube('Hair sweep '+str(i),[(t,-.20,1.29),(t+sweep,-.17,1.43),(t+sweep*1.7,.06,1.39)],.047,mats['dark'],'Head')
 if female:
  for sgn in [-1,1]:
   tube('Long hair silhouette',[(sgn*.24,.02,1.26),(sgn*.29,.12,1.0),(sgn*(.30 if kind!='strata' else .24),.11,.78)],.055,mats['dark'],'Head')
 else:
  cone('Back crest',(.06,.14,1.25),(.20,.28,1.36),.10,mats['dark'])
 body=style['body']
 if body=='furnace':
  ellipsoid('Furnace heart',(0,-.155,.66),(.08,.03,.095),mats['accent'])
  for sgn,side in [(-1,'L'),(1,'R')]:
   ring('Ignition gauntlet',(sgn*(.20*mass+.10),-.02,.49),.115,.018,mats['gold'],'LowerArm_'+side)
   for z in [.64,.69,.74]: capsule('Thermal seam',(sgn*.07,-.151,z),(sgn*.15,-.13,z+.04),.01,mats['accent'])
 elif body=='armor':
  for sgn,side in [(-1,'L'),(1,'R')]:
   for i in range(3): ellipsoid('Layered shoulder plate',(sgn*(shoulder+.035),.015,.77-i*.035),(.17,.16,.067),mats['body'],'Shoulder_'+side,True)
   ellipsoid('Bastion forearm',(sgn*(.20*mass+.10),-.01,.50),(.135,.105,.125),mats['body'],'LowerArm_'+side,True)
   ring('Tectonic joint',(sgn*(.20*mass+.10),-.115,.50),.065,.012,mats['accent'],'LowerArm_'+side)
 elif body=='rails':
  for sgn in [-1,1]:
   tube('Conductive rail',[(sgn*.07,-.154,.51),(sgn*.12,-.16,.65),(sgn*.08,-.13,.77)],.015,mats['gold'])
   cone('Polarity fin',(sgn*.18,.02,.72),(sgn*.29,.04,.91),.055,mats['accent'],'Shoulder_L' if sgn<0 else 'Shoulder_R')
 elif body=='airfoil':
  for sgn in [-1,1]:
   tube('Airfoil ribbon',[(sgn*.10,.12,.72),(sgn*.40,.16,.84),(sgn*.47,.16,.59),(sgn*.31,.12,.47)],.030,mats['body'])
   tube('Gale sash',[(sgn*.06,-.14,.77),(sgn*.19,-.14,.60),(sgn*.24,.04,.39)],.025,mats['accent'])
 elif body=='lattice':
  for sgn,side in [(-1,'L'),(1,'R')]:
   cone('Crystal mantle',(sgn*.17,.04,.68),(sgn*.28,.06,.91),.10,mats['body'],'Shoulder_'+side)
   for i in range(3): cone('Lattice planes',(sgn*.17,-.04,.53+i*.08),(sgn*.25,-.07,.60+i*.08),.04,mats['accent'])
  tube('Crystal chevron',[(-.14,-.15,.72),(0,-.17,.61),(.14,-.15,.72)],.018,mats['gold'])
 elif body=='orbit':
  ring('Sparse orbit',(0,.06,.68),.44,.012,mats['gold'],tilt=.8)
  for i in range(3):
   t=i*math.tau/3; ellipsoid('Orbital node',(.44*math.cos(t),.05,.68+.38*math.sin(t)),(.065,.065,.065),mats['accent'])
  tube('Vector chest',[(0,-.14,.49),(.06,-.16,.66),(-.04,-.14,.77)],.015,mats['gold'])
 elif body=='cowl':
  tube('Asymmetric cowl',[(-.20,.0,.84),(-.32,.12,.74),(-.27,.16,.48),(-.40,.12,.38)],.075,mats['dark'])
  tube('Split cape',[(.12,.11,.70),(.28,.18,.54),(.21,.16,.28)],.035,mats['body'])
  cone('Broken collar',(-.15,-.02,.75),(-.23,-.06,.91),.055,mats['accent'])
 elif body=='inward':
  tube('Inward collar',[(-.23,.06,.78),(-.14,-.13,.80),(0,-.17,.67),(.14,-.13,.80),(.23,.06,.78)],.025,mats['dark'])
  ring('Collapsed aperture',(0,-.15,.63),.10,.014,mats['dark'])
  ellipsoid('White seed',(0,-.182,.64),(.027,.014,.032),mats['white'])
 elif body=='outward':
  ring('Definition halo',(0,.09,1.34),.35,.014,mats['gold'],'Head')
  for sgn in [-1,1]:
   tube('Radiance costume',[(0,-.155,.55),(sgn*.18,-.13,.70),(sgn*.23,.03,.85)],.020,mats['gold'])
   cone('Radiating shoulder',(sgn*.19,0,.73),(sgn*.34,.03,.85),.045,mats['body'],'Shoulder_L' if sgn<0 else 'Shoulder_R')
  ellipsoid('Black seed',(0,-.175,.63),(.027,.015,.032),mats['eye'])
 ARM['fighter_id']=fid; ARM['presentation']=variant; ARM['art_status']='COLLECTIBLE_V1_CANDIDATE'
 return mats


def animations(fid):
 moves=json.loads((ROOT/f'game-godot/data/moves/{fid}.json').read_text())['moves']
 timing={m['move_id']:m for m in moves}
 names=set(SLOTS)|set(ALIAS['move_id_to_clip'].values())|{'idle','walk','run','dash','jump','fall','shield','hurt_light','hurt_heavy','launched','ko','victory','defeat','transform','select_confirm'}
 reverse={v:k for k,v in ALIAS['move_id_to_clip'].items()}
 style=SHAPE[fid]
 for name in sorted(names):
  action=bpy.data.actions.new(name); ARM.animation_data_create(); ARM.animation_data.action=action
  mid=name if name in timing else reverse.get(name,'')
  data=timing.get(mid,{})
  total=int(data.get('startup_frames',8))+int(data.get('active_frames',6))+int(data.get('recovery_frames',12))
  frames=[0,max(1,int(data.get('startup_frames',8))-1),int(data.get('startup_frames',8)),int(data.get('startup_frames',8))+int(data.get('active_frames',6)),total]
  attack=bool(mid) and mid not in ['aura_charge']
  for index,frame in enumerate(frames):
   for bone in ARM.pose.bones: bone.rotation_mode='XYZ'; bone.rotation_euler=(0,0,0); bone.scale=(1,1,1)
   amount=[0,-.32,1,.58,0][index]
   chest=ARM.pose.bones['Chest']; hips=ARM.pose.bones['Hips']; head=ARM.pose.bones['Head']
   arm=ARM.pose.bones['UpperArm_R']; other=ARM.pose.bones['UpperArm_L']
   if attack:
    strength=1.25 if ('heavy' in name or 'burst' in name) else .75
    chest.rotation_euler[1]=amount*strength*(.10 if fid=='rook-ironside' else .28)
    arm.rotation_euler[0]=amount*strength*(-1.1 if fid in ['ember-vale','juno-spark'] else -.75)
    arm.rotation_euler[2]=amount*(-.6 if 'up' in name else .35)
    other.rotation_euler[0]=amount*(-.75 if fid in ['kaia-windrow','yang','orion-vell'] else -.3)
    hips.rotation_euler[0]=amount*style['lean']
    if fid=='rook-ironside': hips.scale[2]=1-abs(amount)*.07; other.rotation_euler[0]=arm.rotation_euler[0]
    if fid=='nix-calder': arm.rotation_euler[2]=amount*.7; other.rotation_euler[2]=-amount*.7
    if fid=='vesper-nyx': head.rotation_euler[2]=amount*.19; other.rotation_euler[0]=-amount*.9
    if fid=='yin': arm.rotation_euler[0]=amount*.3; other.rotation_euler[0]=amount*.3
    if 'air' in name or 'throw' in name: ARM.pose.bones['UpperLeg_R'].rotation_euler[0]=amount*1.0
    if 'down' in name: chest.rotation_euler[0]=amount*.4
   elif 'run' in name or 'walk' in name or 'dash' in name:
    phase=[0,1,0,-1,0][index]; stride=.7 if fid=='juno-spark' else .25 if fid=='rook-ironside' else .4
    hips.rotation_euler[0]=style['lean']; chest.rotation_euler[1]=phase*(.08 if fid!='kaia-windrow' else .17)
    for side,sgn in [('L',-1),('R',1)]:
     ARM.pose.bones['UpperLeg_'+side].rotation_euler[0]=phase*stride*sgn
     ARM.pose.bones['UpperArm_'+side].rotation_euler[0]=-phase*stride*.65*sgn
   elif any(x in name for x in ['hurt','launch','tumble','defeat','ko']):
    chest.rotation_euler[0]=abs(amount)*.35; head.rotation_euler[0]=-abs(amount)*.2
    hips.rotation_euler[1]=amount*.15
   elif any(x in name for x in ['shield','grab','charge','transform','victory','select_confirm']):
    arm.rotation_euler[0]=-abs(amount)*(.9 if fid not in ['yin','rook-ironside'] else .4)
    other.rotation_euler[0]=-abs(amount)*(.9 if fid not in ['yin','rook-ironside'] else .4)
    head.rotation_euler[2]=amount*.07
   else:
    chest.rotation_euler[0]=math.sin(index*math.pi/2)*(.01 if fid=='yin' else .025)
    head.rotation_euler[2]=math.sin(index*math.pi/2)*(.06 if fid in ['juno-spark','vesper-nyx'] else .02)
   for bone in ARM.pose.bones:
    bone.keyframe_insert('rotation_euler',frame=frame); bone.keyframe_insert('scale',frame=frame)
  for curve in action.fcurves:
   for key in curve.keyframe_points: key.interpolation='LINEAR'
  track=ARM.animation_data.nla_tracks.new(); track.name=name; track.strips.new(name,0,action)
 ARM.animation_data.action=None
 for b in ARM.pose.bones: b.rotation_euler=(0,0,0); b.scale=(1,1,1)
 return len(names)


def select_export(path):
 bpy.ops.object.select_all(action='DESELECT'); ARM.select_set(True)
 for part in PARTS: part.select_set(True)
 for ob in bpy.data.objects:
  if ob.type=='EMPTY' and ob.parent==ARM: ob.select_set(True)
 bpy.context.view_layer.objects.active=ARM
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_skins=True,export_animations=True,export_nla_strips=True,export_force_sampling=False,export_yup=True)


def render(fid,variant,form):
 scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=16; scene.cycles.use_denoising=True
 scene.render.resolution_x=480; scene.render.resolution_y=480; scene.render.resolution_percentage=100
 scene.world.color=(.09,.10,.14); scene.view_settings.view_transform='Standard'; scene.view_settings.look='Medium High Contrast'
 bpy.ops.object.camera_add(location=(0,-3.5,1.7)); camera=bpy.context.object; camera.name='ReviewCamera'; scene.camera=camera
 camera.data.type='ORTHO'; camera.data.ortho_scale=1.95
 camera.rotation_euler=(Vector((0,0,.78))-camera.location).to_track_quat('-Z','Y').to_euler()
 lights=[]
 for loc,energy,size in [((-2,-3,4),420,3),((3,-1,2.5),260,2),((1,2,3),450,2)]:
  bpy.ops.object.light_add(type='AREA',location=loc); light=bpy.context.object; light.data.energy=energy; light.data.size=size
  light.rotation_euler=(Vector((0,0,.8))-light.location).to_track_quat('-Z','Y').to_euler(); lights.append(light)
 dest=ART/'renders'/fid/variant/form; dest.mkdir(parents=True,exist_ok=True)
 angles=[('front',0),('side',math.pi/2),('back',math.pi),('three_quarter',math.pi/5)] if form=='BASE' else [('front',0)]
 scene.frame_set(0)
 for label,angle in angles:
  ARM.rotation_euler[2]=angle; scene.render.filepath=str(dest/(label+'.png')); bpy.ops.render.render(write_still=True)
 ARM.rotation_euler[2]=0
 for ob in [camera]+lights: bpy.data.objects.remove(ob,do_unlink=True)


def main():
 if os.environ.get('AA_COLLECTIBLE_REPAIR_EXISTING') == '1':
  ledger=json.loads((ROOT/'artifacts/v1_closure/disk_cleanup.json').read_text())
  print('REPAIR_HEADROOM',shutil.disk_usage(ROOT).free/2**30,ledger.get('after_free_gib'),ledger.get('after_additional_free_gib'),flush=True)
  if max(ledger.get('after_free_gib',0),ledger.get('after_additional_free_gib',0),ledger.get('after_generation_recheck_cleanup_gib',0))<18 or shutil.disk_usage(ROOT).free/2**30<15:
   raise RuntimeError('Existing generation repair requires verified initial 18 GiB headroom and 15 GiB remaining')
 elif shutil.disk_usage(ROOT).free/2**30<18: raise RuntimeError('18 GiB free is required before Blender generation')
 ART.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True)
 manifest={'schema':'anime_v1.collectible_candidates.v1','originality':'Original parametric geometry; no third-party meshes, faces, logos or packaging.',
           'art_status':'OWNER_REVIEW_CANDIDATE','authored_animation_complete':False,'FINAL_CHARACTER_ART_PASS':False,'assets':[]}
 for row in AUTH['fighters']:
  fid=row['id']
  if os.environ.get('AA_COLLECTIBLE_FIGHTER') and fid != os.environ['AA_COLLECTIBLE_FIGHTER']: continue
  for variant in ['male','female']:
   if os.environ.get('AA_COLLECTIBLE_VARIANT') and variant != os.environ['AA_COLLECTIBLE_VARIANT']: continue
   source=SRC/fid/variant; source.mkdir(parents=True,exist_ok=True)
   if os.environ.get('AA_COLLECTIBLE_REPAIR_EXISTING') == '1':
    bpy.ops.wm.open_mainfile(filepath=str(source/'candidate.blend'))
    global ARM, PARTS
    ARM=next(ob for ob in bpy.data.objects if ob.type=='ARMATURE')
    PARTS=[ob for ob in bpy.data.objects if ob.type=='MESH']
    for ob in PARTS:
     if not any(mod.type=='ARMATURE' for mod in ob.modifiers):
      assert any(group.name in ARM.data.bones for group in ob.vertex_groups), 'Missing rigid binding: '+ob.name
      mod=ob.modifiers.new('Canonical deformation','ARMATURE'); mod.object=ARM
    mats={key:(bpy.data.materials.get(name) or material(name,(.82,.54,.14))) for key,name in {'body':'Elemental porcelain','dark':'Structural costume','face':'Elemental face','accent':'Power inlay','eye':'Eye outline','white':'Eye light','gold':'Metal trim'}.items()}
    clips=len(ARM.animation_data.nla_tracks)
   else:
    mats=build_body(fid,variant,row); clips=animations(fid)
   bpy.context.scene.render.fps=60
   bpy.ops.wm.save_as_mainfile(filepath=str(source/'candidate.blend'))
   forms=['BASE','PRISMATIC_GRAY','BLACK_PUPPET','WHITE_PUPPET'] if fid not in ['yin','yang'] else ['BASE','COSMIC_BOSS']
   original={key:tuple(mat.diffuse_color) for key,mat in mats.items()}
   variant_parts=[]
   for form in forms:
    for ob in variant_parts:
     if ob in PARTS: PARTS.remove(ob)
     bpy.data.objects.remove(ob,do_unlink=True)
    variant_parts=[]
    for key,mat in mats.items():
     mat.diffuse_color=original[key]; mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=original[key]
    before=len(PARTS)
    if form in ['BLACK_PUPPET','WHITE_PUPPET','PRISMATIC_GRAY']:
     for key in ['body','dark','face']:
      c=(.025,.028,.04) if form=='BLACK_PUPPET' else (.86,.89,.94) if form=='WHITE_PUPPET' else (.29,.32,.38)
      mats[key].diffuse_color=(*c,1); mats[key].node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*c,1)
     if 'PUPPET' in form:
      ellipsoid('Control mask',(0,-.252,1.15),(.232,.028,.135),mats['dark'],'Head')
      ellipsoid('Identity signal',(.16,-.29,1.16),(.017,.009,.025),mats['accent'],'Head')
     else:
      for i,c in enumerate(AUTH['fighters'][:7]):
       spec=material('Essence '+c['id'],rgb(c['color']),.25,.12)
       t=i*math.tau/7; ellipsoid('Spectral inlay '+c['id'],(.14*math.cos(t),-.153,.65+.1*math.sin(t)),(.019,.01,.019),spec)
    if form=='COSMIC_BOSS':
     ring('Cosmic contract field',(0,.04,.74),.62,.012,mats['accent'],tilt=.5)
    variant_parts=PARTS[before:]
    dest=OUT/fid/variant; dest.mkdir(parents=True,exist_ok=True); path=dest/(form+'.glb')
    select_export(path); render(fid,variant,form)
    manifest['assets'].append({'fighter_id':fid,'presentation':variant,'form':form,'path':str(path.relative_to(ROOT)),
                              'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source_blend':str((source/'candidate.blend').relative_to(ROOT)),
                              'canonical_bone_count':len(AUTH['canonical_deform_bones']),'clip_candidates':clips,'rig_binding':'rigid module skin weights',
                              'animation_status':'PROCEDURAL_KEYPOSE_CANDIDATE','owner_approved':False})
    (ART/'asset_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('COLLECTIBLE_DONE',fid,variant,form,flush=True)
 print('COLLECTIBLES_COMPLETE',len(manifest['assets']),flush=True)


if __name__=='__main__': main()

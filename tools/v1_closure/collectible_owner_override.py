"""Owner-scoped geometry and facial morph candidates. No third-party design assets."""
import math
from mathutils import Vector

PERSONALITY = {
 'ember-vale':(-.22,-.024,-.006), 'rook-ironside':(-.03,-.012,0),
 'juno-spark':(.09,.011,.016), 'kaia-windrow':(-.06,.004,.001),
 'nix-calder':(-.14,-.014,-.001), 'orion-vell':(-.10,-.019,.002),
 'vesper-nyx':(.12,-.009,.025), 'yin':(-.20,-.026,-.008), 'yang':(.03,.013,.005),
}
EXPRESSIONS = ['battle_intent','attack_effort','pain','shock','fear','grief','determination','victory','defeat','cinematic_closeup']


def female_hair(api,fid,m):
 tube,ellipsoid,cone,ring= [api[n] for n in ['tube','ellipsoid','cone','ring']]
 dark,accent,gold=m['dark'],m['accent'],m['gold']
 if fid=='ember-vale':
  for i in range(7):
   x=(i-3)*.067
   tube('Female pixie flame swirl %d'%i,[(x,-.17,1.34),(x+.07,-.19,1.43),(x+.11,-.09,1.46),(x+.05,.01,1.43)],.036,dark,'Head')
   tube('Living heat in pixie %d'%i,[(x,-.19,1.35),(x+.065,-.205,1.42),(x+.10,-.095,1.46)],.008,accent,'Head')
 elif fid=='rook-ironside':
  for i in range(12):
   t=(i-5.5)*.21;x=.245*math.sin(t);y=.10+.20*math.cos(t)
   points=[(x*.50,y*.2,1.41),(x,y,1.29),(x*1.16,y,1.05),(x*1.1,y*.8,.78)]
   tube('Female box braid %02d'%i,points,.036,dark,'Head')
   for j in range(8):
    z=1.26-j*.06; twist=j*2.5
    ellipsoid('Braid woven segment %d %d'%(i,j),(x*1.10+.009*math.sin(twist),y+.012*math.cos(twist),z),(.029,.031,.039),dark,'Head')
   ellipsoid('Braid binding %d'%i,(x*1.1,y*.8,.79),(.035,.035,.026),gold,'Head')
  for sgn in [-1,1]:
   pts=[(sgn*.17,-.14,1.40),(sgn*.26,-.11,1.29),(sgn*.29,-.07,1.05),(sgn*.25,-.025,.78)]
   tube('Face framing box braid',pts,.031,dark,'Head')
   for j in range(9):ellipsoid('Visible woven braid',(sgn*(.26+.025*math.sin(j*.32)),-.115+j*.01,1.28-j*.052),(.029,.032,.037),dark,'Head')
 elif fid=='juno-spark':
  ellipsoid('Female gathered electric knot',(.03,.25,1.36),(.11,.08,.085),dark,'Head')
  # Alternating corners form one unmistakable zigzag tail, rather than spikes on a cap.
  tube('Female lightning bolt ponytail',[(.03,.27,1.36),(.31,.30,1.57),(.23,.30,1.25),(.48,.27,1.30),(.33,.22,.97)],.056,accent,'Head')
  tube('Lightning tail core',[(.03,.21,1.37),(.29,.24,1.53),(.23,.24,1.25),(.46,.21,1.28),(.33,.16,.98)],.013,m['white'],'Head')
  for x in [-.12,.0,.12]:cone('Swept electric fringe',(x,-.19,1.33),(x+.09,-.15,1.45),.046,dark)
 elif fid=='kaia-windrow':
  for i in range(13):
   t=i*math.tau/13
   cx=.32*math.cos(t);cy=.11+.19*math.sin(t)
   pts=[]
   for j in range(16):
    u=j/15;angle=u*math.tau*2.2
    pts.append((cx*(1+u*.65)+.055*math.cos(angle),cy+.045*math.sin(angle),1.38-u*.68+.075*math.sin(t)))
   tube('Female storm curl %02d'%i,pts,.053,dark,'Head')
  for sgn in [-1,1]:
   tube('Storm hair lifted stream',[(sgn*.17,.02,1.39),(sgn*.40,.09,1.55),(sgn*.55,.14,1.42),(sgn*.47,.18,1.20)],.054,dark,'Head')
   tube('Storm silver flow',[(sgn*.37,.01,1.47),(sgn*.47,.07,1.49),(sgn*.53,.1,1.4)],.010,accent,'Head')
 elif fid=='nix-calder':
  for i in range(11):
   t=(i-5)*.25;x=.26*math.sin(t);y=.07+.21*math.cos(t)
   tube('Female polished straight panel %02d'%i,[(x*.45,y*.3,1.42),(x,y,1.31),(x*1.07,y*.94,1.04),(x*1.05,y*.82,.74)],.038,dark,'Head')
   tube('Silk press specular line %02d'%i,[(x,y-.025,1.30),(x*1.07,y*.94-.025,1.05),(x*1.05,y*.82-.025,.75)],.005,m['gold'],'Head')
  tube('Precise side part',[(-.03,-.16,1.42),(.16,-.23,1.34),(.26,-.07,1.22)],.034,dark,'Head')
 elif fid=='orion-vell':
  ellipsoid('Female orbital afro puff',(0,.15,1.53),(.31,.26,.28),dark,'Head')
  for i in range(36):
   t=i*2.39996;z=1-2*(i+.5)/36;r=math.sqrt(1-z*z)
   ellipsoid('Afro curl cluster %02d'%i,(.29*r*math.cos(t),.15+.245*r*math.sin(t),1.53+.255*z),(.075,.065,.067),dark,'Head')
  ring('Gravity puff binding',(0,.13,1.37),.18,.016,gold,'Head',tilt=.9)
 elif fid=='vesper-nyx':
  ghost=api['material']('Phase hair echo',(.31,.22,.54),.12,.12)
  ghost.diffuse_color=(.31,.22,.54,.26);p=ghost.node_tree.nodes['Principled BSDF'];p.inputs['Alpha'].default_value=.26
  ghost.blend_method='BLEND';ghost.use_screen_refraction=True
  for i in range(11):
   t=(i-5)*.24;x=.255*math.sin(t);y=.08+.19*math.cos(t)
   pts=[(x*.5,y*.2,1.41),(x,y,1.27),(x+(-.06 if i%2 else .08),y,1.05),(x+.04,y,.77)]
   tube('Female phase dreadlock %02d'%i,pts,.036,dark,'Head')
   if i%3==0:tube('Offset translucent dread echo %02d'%i,[(a+.065,b+.03,c+.025) for a,b,c in pts],.032,ghost,'Head')
   ellipsoid('Phase loc tie %d'%i,(x+.04,y,.79),(.039,.039,.023),accent,'Head')
 elif fid in ['yin','yang']:
  inward=fid=='yin'
  for i in range(13):
   t=(i-6)*.24;x=.245*math.sin(t);y=.09+.20*math.cos(t)
   pts=[(x*.4,y*.2,1.43),(x,y,1.31)]
   for j in range(9):
    u=j/8; spread=1-u*.35 if inward else 1+u*.8
    pts.append((x*spread+(.018 if inward else .053)*math.sin(u*math.tau*1.5),y+.018*math.cos(u*math.tau),1.26-u*.66))
   tube('Female divine descending wave' if inward else 'Female divine radiant wave',pts,.034,dark if inward else m['face'],'Head')
  if inward:
   for sgn in [-1,1]:tube('Controlled face framing cascade',[(sgn*.17,-.13,1.36),(sgn*.26,-.10,1.21),(sgn*.28,-.055,.99),(sgn*.19,-.015,.66)],.032,dark,'Head')
   tube('Original inward eclipse diadem',[(-.22,-.12,1.44),(-.17,-.19,1.52),(0,-.22,1.45),(.17,-.19,1.52),(.22,-.12,1.44)],.016,accent,'Head')
   for sgn in [-1,1]:tube('Inward crescent tip',[(sgn*.16,-.18,1.51),(sgn*.10,-.18,1.61),(sgn*.045,-.19,1.58)],.013,gold,'Head')
   ellipsoid('Eclipse diadem seed',(0,-.245,1.45),(.025,.015,.028),m['white'],'Head')
  else:
   tube('Original creation diadem',[(-.23,-.10,1.45),(-.16,-.20,1.46),(0,-.23,1.48),(.16,-.20,1.46),(.23,-.10,1.45)],.015,gold,'Head')
   for i in range(7):
    t=(i-3)*.064
    cone('Outward creation ray %d'%i,(t,-.15,1.48),(t*1.30,-.13,1.65-.15*abs(t)),.021,gold)
   for sgn in [-1,1]:tube('Radiant lifted hair',[(sgn*.20,.09,1.36),(sgn*.38,.15,1.54),(sgn*.45,.20,1.42),(sgn*.38,.24,1.17)],.046,m['face'],'Head')


def elemental_refinement(api,fid,m):
 tube,ellipsoid,cone,ring=[api[n] for n in ['tube','ellipsoid','cone','ring']]
 if fid=='ember-vale':
  for s in [-1,1]:tube('Molten pressure channel',[(s*.07,-.17,.51),(s*.14,-.16,.64),(s*.06,-.16,.77)],.009,m['accent'])
 elif fid=='rook-ironside':
  mat=m['body'];nodes=mat.node_tree.nodes;p=nodes['Principled BSDF'];p.inputs['Metallic'].default_value=.02;p.inputs['Roughness'].default_value=.67
  noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=38;noise.inputs['Detail'].default_value=2
  bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.018
  mat.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);mat.node_tree.links.new(bump.outputs['Normal'],p.inputs['Normal'])
  for s in [-1,1]:
   for i in range(4):
    tube('Geological armor stratum',[(s*.05,-.153,.55+i*.05),(s*.18,-.15,.54+i*.05),(s*.24,-.09,.57+i*.05)],.012,m['dark'])
   for i in range(3):ellipsoid('Crag armor break',(s*(.26+i*.02),-.06,.74-i*.045),(.065,.035,.048),m['accent'],'Shoulder_L' if s<0 else 'Shoulder_R',True)
 elif fid=='juno-spark':
  for s in [-1,1]:tube('Angular charge circuit',[(s*.02,-.16,.75),(s*.15,-.17,.67),(s*.09,-.17,.63),(s*.17,-.16,.56)],.009,m['accent'])
 elif fid=='kaia-windrow':
  for s in [-1,1]:tube('Gale armor flow',[(s*.10,-.16,.70),(s*.29,-.09,.66),(s*.37,.03,.48),(s*.25,.08,.37)],.018,m['gold'])
 elif fid=='nix-calder':
  for s in [-1,1]:
   for i in range(3):cone('Frost containment facet',(s*.04,-.155,.55+i*.045),(s*.13,-.16,.62+i*.045),.030,m['accent'],'Chest',4)
 elif fid=='orion-vell':
  ring('Secondary inclined gravity orbit',(0,.045,.65),.36,.008,m['accent'],tilt=-.65)
 elif fid=='vesper-nyx':
  tube('Displaced phase armor edge',[(-.23,.04,.77),(-.35,.16,.66),(-.28,.19,.41)],.018,m['accent'])
 elif fid=='yin':
  for s in [-1,1]:tube('Absorption armor curl',[(s*.18,-.13,.74),(s*.13,-.18,.61),(s*.025,-.20,.64)],.012,m['accent'])
 elif fid=='yang':
  for s in [-1,1]:
   for i in range(3):cone('Creation armor ray',(s*.08,-.13,.59+i*.045),(s*(.20+i*.028),-.11,.63+i*.08),.020,m['gold'],'Chest')


def facial_morphs(parts,fid):
 """Real GLTF morph targets on skinned face geometry, independent of skeletal clips."""
 angle,brow,mouth=PERSONALITY[fid]
 for ob in parts:
  name=ob.name.lower()
  if not any(name.startswith(k) for k in ['eye almond','iris','pupil','eye glint','brow','mouth']):continue
  if ob.data.shape_keys:continue
  # Personality rest shape. Male hair and armor are never touched here.
  sgn=-1 if sum(v.co.x for v in ob.data.vertices)/len(ob.data.vertices)+ob.location.x<0 else 1
  if name.startswith('brow'):
   for v in ob.data.vertices:v.co.z += brow + sgn*v.co.x*angle*.3
  if name=='mouth':
   seriousness={'yin':-.34,'rook-ironside':-.17,'nix-calder':-.17,'ember-vale':-.14,'orion-vell':-.12,'kaia-windrow':-.09,'yang':-.04}.get(fid,0)
   for v in ob.data.vertices:v.co.z += mouth*(v.co.x/.05) + abs(v.co.x)*seriousness
  if any(name.startswith(k) for k in ['eye almond','iris','pupil','eye glint']):
   narrow={'yin':.70,'nix-calder':.76,'ember-vale':.82,'rook-ironside':.88,'orion-vell':.84,'kaia-windrow':.94,'yang':.96}.get(fid,1)
   for v in ob.data.vertices:v.co.z *= narrow
  ob.shape_key_add(name='Basis')
  for expression in EXPRESSIONS:
   key=ob.shape_key_add(name=expression)
   for v,base in zip(key.data,ob.data.vertices):
    p=base.co.copy(); delta=Vector((0,0,0));scale_z=1.0
    if name.startswith('brow'):
     delta.z={'battle_intent':-.010,'attack_effort':-.027,'pain':-.023,'shock':.038,'fear':.025,'grief':.012,'determination':-.023,'victory':.015,'defeat':-.025,'cinematic_closeup':.008}[expression]
     if expression in ['grief','fear']:delta.z+=-abs(p.x)*.22
     if expression in ['battle_intent','determination','attack_effort']:delta.z+=abs(p.x)*.13
    elif name.startswith('mouth'):
     if name.startswith('mouth cavity'):
      scale_z={'battle_intent':1,'attack_effort':42,'pain':27,'shock':55,'fear':33,'grief':8,'determination':3,'victory':18,'defeat':11,'cinematic_closeup':8}[expression]
     else:
      delta.z=(abs(p.x)/.05)*{'battle_intent':-.010,'attack_effort':-.017,'pain':-.025,'shock':-.020,'fear':-.026,'grief':-.024,'determination':-.008,'victory':.022,'defeat':-.024,'cinematic_closeup':.003}[expression]
    else:
     scale_z={'battle_intent':.77,'attack_effort':.56,'pain':.24,'shock':1.23,'fear':1.12,'grief':.48,'determination':.63,'victory':.75,'defeat':.22,'cinematic_closeup':.96}[expression]
    p.z*=scale_z
    v.co=p+delta
 return EXPRESSIONS

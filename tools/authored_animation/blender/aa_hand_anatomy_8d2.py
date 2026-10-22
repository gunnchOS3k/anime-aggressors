"""Original connected hand cages, fitted to the preserved source palm envelope.

No imported hand asset. Reuses each actual Palm object, materials, wrist and
armature. Before geometry/weights remain as hidden editable source copies.
"""
import math
import bpy
import bmesh
from mathutils import Vector,Matrix,Quaternion
from aa_controls_8d import points,digest


def fingerprint(ob):
    return digest({'v':[list(v.co)for v in ob.data.vertices],'f':[list(p.vertices)for p in ob.data.polygons],'m':[m.name if m else ''for m in ob.data.materials],'x':[list(r)for r in ob.matrix_local],'groups':[g.name for g in ob.vertex_groups],'weights':[[(g.group,g.weight)for g in v.groups]for v in ob.data.vertices]})


def preserve_part(ob,collection):
    old=fingerprint(ob);copy=ob.copy();copy.data=ob.data.copy();copy.name='ORIGINAL_8D_'+ob.name
    collection.objects.link(copy);copy.hide_render=True;copy.hide_set(True)
    assert fingerprint(copy)==old
    return {'original':ob.name,'backup':copy.name,'before_sha256':old,'original_vertices':len(ob.data.vertices)}


def build_hand(arm,side,spec,archive):
    sign=-1 if side=='L'else 1
    palm=bpy.data.objects['Palm '+side]
    names=['Palm '+side]+['Finger %s %d'%(side,i)for i in range(3)]+['D8_Thumb_'+side,'D8_Little_'+side]
    before=[preserve_part(bpy.data.objects[n],archive)for n in names]
    for name in names[1:]:
        ob=bpy.data.objects[name];ob.hide_render=True;ob.hide_set(True);ob['8d2_legacy_only']=True
    old=points(arm,palm);w=(max(v.x for v in old)-min(v.x for v in old))*.72
    wrist=arm.data.bones['Hand_'+side].head_local.copy()
    forward=(arm.data.bones['Hand_'+side].tail_local-wrist).normalized()
    across=Vector((-sign,0,0));normal=Vector((0,forward.z,-forward.y)).normalized()
    # One source-derived envelope; no whole-character or arm scaling.
    old_digits=[p for n in names for p in points(arm,bpy.data.objects[n])]
    limit=max((p-wrist).dot(forward)for p in old_digits)
    end=max(.095,min(.16,limit*.98));base=end*.52;thick=end*.25
    frows=[-.014,base*.22,base*.62,base]
    verts=[];faces=[];materials=[];weights=[];grid={};chains=[]
    def vertex(p,wgt):
        verts.append(tuple(p));weights.append(wgt);return len(verts)-1
    def face(indices,mat=0):faces.append(tuple(indices));materials.append(mat)
    # Shared dorsal/palmar sheets, wrist and four separately extruded finger
    # roots. This is a connected webbed palm, not detached ellipsoid digits.
    for surface in [-1,1]:
        for row,f in enumerate(frows):
            for i in range(5):
                u=(-.5+i*.25)*w
                breadth=[.72,.90,1.0,.96][row]
                h=thick*.5*(.8+.2*(1-abs(u)/(w*.5)))
                thenar=.004*(i/4)**2 if row in [1,2]and surface==1 else 0
                p=wrist+across*u*breadth+forward*f+normal*(surface*h+thenar)
                grid[surface,row,i]=vertex(p,{'Hand_'+side:1.})
    for surf in [-1,1]:
        for row in range(3):
            for i in range(4):face([grid[surf,row,i],grid[surf,row,i+1],grid[surf,row+1,i+1],grid[surf,row+1,i]])
    for row in range(3):
        face([grid[-1,row,0],grid[-1,row+1,0],grid[1,row+1,0],grid[1,row,0]])
        if row!=1:face([grid[1,row,4],grid[1,row+1,4],grid[-1,row+1,4],grid[-1,row,4]])
    for i in range(4):face([grid[1,0,i],grid[1,0,i+1],grid[-1,0,i+1],grid[-1,0,i]])
    def bridge(a,b):
        # Both loops have4 corners. Subdivision supplies rounded phalanges,
        # with explicit additional rings at each joint/crease.
        for i in range(4):face([a[i],a[(i+1)%4],b[(i+1)%4],b[i]])
    def tube(root,origin,direction,width,depth,length,bones,stops,thumb=False):
        last=root
        rings=[.025,.08,stops[1]-.035,stops[1],stops[1]+.035,stops[-2]-.035,stops[-2],stops[-2]+.035,.94,.985,1.0]if not thumb else[.025,.10,.46,.50,.54,.90,.97,1.0]
        cross=normal.cross(direction).normalized()
        for t in sorted(set(rings)):
            t=max(.01,min(1,t));taper=(1-.20*t)*(max(.18,1-(max(0,t-.93)/.07)*.65))
            knuckle=1.10 if min(abs(t-s)for s in stops[1:-1])<.01 else 1.
            center=origin+direction*length*t
            joint=0 if t<=stops[1]else min(len(bones)-1,1 if len(bones)==2 or t<=stops[2]else 2)
            # Linear blends around anatomical joints; distal tip stays bound.
            wg={bones[joint]:1.}
            for j,s in enumerate(stops[1:-1]):
                if abs(t-s)<.10:
                    u=(t-s+.10)/.20;wg={bones[j]:1-u,bones[j+1]:u};break
            current=[]
            for a,b in [(-1,-1),(1,-1),(1,1),(-1,1)]:
                current.append(vertex(center+cross*(a*width*.5*taper*knuckle)+normal*(b*depth*.5*taper*knuckle),wg))
            bridge(last,current);last=current
        face(last)
    for digit,cell in enumerate([3,2,1,0]):
        u=(-.5+(cell+.5)*.25)*w*.96
        origin=wrist+across*u+forward*base
        length=(end-base)*[.96,1.0,.94,.78][digit]
        stops=[0,.43,.76,1.];bones=['D8_Finger_%s_%d_%d'%(side,digit,j)for j in range(3)]
        root=[grid[-1,3,cell],grid[-1,3,cell+1],grid[1,3,cell+1],grid[1,3,cell]]
        tube(root,origin,forward,w*.215,thick*.76,length,bones,stops)
        chains.append({'side':side,'digit':digit,'bones':bones,'start':list(origin),'axis':list(forward),'normal':list(normal),'stops':stops,'length':length,'mesh':palm.name,'kind':'finger'})
    origin=wrist+across*w*.5+forward*(frows[1]+frows[2])*.5
    direction=(across*.78+forward*.62).normalized();length=w*.40
    bones=['D8_Finger_%s_4_%d'%(side,j)for j in range(2)]
    root=[grid[1,1,4],grid[1,2,4],grid[-1,2,4],grid[-1,1,4]]
    tube(root,origin,direction,thick*.9,thick*.9,length,bones,[0,.50,1.],True)
    chains.append({'side':side,'digit':4,'bones':bones,'start':list(origin),'axis':list(direction),'normal':list(normal),'stops':[0,.50,1.],'length':length,'mesh':palm.name,'kind':'finger','across':list(across),'forward':list(forward)})
    data=bpy.data.meshes.new('8D2_OriginalConnectedPalm_'+side)
    # Vertices are authored in armature space; preserve actual Palm object transform.
    inverse=(arm.matrix_world.inverted()@palm.matrix_world).inverted()
    data.from_pydata([tuple(inverse@Vector(v))for v in verts],[],faces);data.materials.append(palm.data.materials[0]);data.update();palm.data=data
    for group in list(palm.vertex_groups):palm.vertex_groups.remove(group)
    groups={n:palm.vertex_groups.new(name=n)for n in sorted({n for wg in weights for n in wg})}
    for index,wg in enumerate(weights):
        total=sum(wg.values())
        for name,value in wg.items():groups[name].add([index],value/total,'REPLACE')
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
    bpy.ops.object.select_all(action='DESELECT');palm.select_set(True);bpy.context.view_layer.objects.active=palm
    sub=palm.modifiers.new('Authored anatomy surface','SUBSURF');sub.levels=2;sub.render_levels=2
    # Put subdivision before the skin, apply it once into editable dense quads.
    while palm.modifiers.find(sub.name)>0:bpy.ops.object.modifier_move_up(modifier=sub.name)
    bpy.ops.object.modifier_apply(modifier=sub.name)
    for poly in palm.data.polygons:poly.use_smooth=True
    palm['source_provenance']='Original source Palm rebuilt as connected wrist, webbed palm, four three-phalange digits and opposed thumb; same source wrist/material/envelope; editable WIP'
    bm=bmesh.new();bm.from_mesh(palm.data)
    pending=set(bm.verts);components=0
    while pending:
        components+=1;stack=[pending.pop()]
        while stack:
            v=stack.pop()
            for edge in v.link_edges:
                other=edge.other_vert(v)
                if other in pending:pending.remove(other);stack.append(other)
    boundary=sum(e.is_boundary for e in bm.edges);bm.free()
    assert components==1 and boundary==0,('hand cage must be continuous and closed',side,components,boundary)
    assert all(abs(sum(g.weight for g in v.groups)-1)<.00001 for v in palm.data.vertices)
    return {'connected_components':components,'boundary_edges':boundary,'side':side,'wrist':list(wrist),'width_m':w,'distal_envelope_m':end,'depth_m':thick,'chains':chains,'source_parts':before,'mesh':palm.name,'vertices':len(palm.data.vertices),'polygons':len(palm.data.polygons),'palm_contact_rest':list(wrist+forward*base*.55+normal*thick*.52)}


def fit_controls(arm,hands):
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
    for hand in hands:
        for chain in hand['chains']:
            start=Vector(chain['start']);axis=Vector(chain['axis']);stops=chain['stops']
            for i,name in enumerate(chain['bones']):
                b=arm.data.edit_bones.get(name)or arm.data.edit_bones.new(name)
                b.head=start+axis*chain['length']*stops[i];b.tail=start+axis*chain['length']*stops[i+1]
                b.parent=arm.data.edit_bones['Hand_'+hand['side']if i==0 else chain['bones'][i-1]];b.use_deform=True;b.align_roll(Vector(chain['normal']))
    bpy.ops.object.mode_set(mode='OBJECT')


def correct_cuffs(arm,fid):
    changed=[]
    for ob in list(bpy.data.objects):
        if fid=='rook-ironside'and ob.name.startswith('Bastion forearm'):
            parent=next(g.name for g in ob.vertex_groups if g.name.startswith('LowerArm_'));side=parent[-1]
            cut=arm.data.bones['Hand_'+side].head_local.copy();axis=(arm.data.bones['Hand_'+side].tail_local-cut).normalized();cut+=axis*.006
            bm=bmesh.new();bm.from_mesh(ob.data);to_arm=arm.matrix_world.inverted()@ob.matrix_world
            co=to_arm.inverted()@cut;no=(to_arm.to_3x3().transposed()@axis).normalized()
            bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=co,plane_no=no,clear_outer=True)
            # A real open cuff ends at the wrist. No render mask/hitbox edit.
            bm.to_mesh(ob.data);bm.free();ob.data.update();changed.append(ob.name)
    return changed


def author_hands(arm,hands,spec):
    clips={};all_fingers=[n for h in hands for c in h['chains']for n in c['bones']]
    secondary=[b.name for b in arm.data.bones if b.name.startswith('D8_')and not b.name.startswith('D8_Finger_')]
    for category,frames in [('grip',24),('fist',20),('release',18),('idle',spec['idle_frames']),('recoil',48)]:
        action=bpy.data.actions.new('ANI08D2_'+category);action.use_fake_user=True;action['human_approved']=False;arm.animation_data.action=action
        for frame in range(frames+1):
            t=frame/frames;s=t*t*(3-2*t)
            amount=s if category in ['grip','fist']else 1-s if category=='release'else 0.
            for hand in hands:
                for c in hand['chains']:
                    for i,name in enumerate(c['bones']):
                        p=arm.pose.bones[name];p.rotation_mode='XYZ'
                        if c['digit']<4:
                            angles=[1.15,1.45,.85]if category=='fist'else[.55,.8,.45]
                            angle=angles[i]*amount*spec['curl_strength']*(1+c['digit']*.025)
                            p.rotation_euler=(angle,0,0)
                        else:
                            axis=Vector(c['axis']);wanted=(-Vector(c['across'])*.35+Vector(c['forward'])*.68+Vector(c['normal'])*.64).normalized()
                            world=Quaternion().slerp(axis.rotation_difference(wanted),amount)
                            basis=arm.data.bones[name].matrix_local.to_quaternion()
                            q=basis.inverted()@world@basis if i==0 else Quaternion((1,0,0),.65*amount)
                            p.rotation_euler=q.to_euler('XYZ')
                        p.keyframe_insert('rotation_euler',frame=frame,group=name)
            for name in secondary:
                p=arm.pose.bones[name];p.rotation_mode='XYZ';amp=spec['secondary_angle_rad']*(.35 if 'armor'in name else.65)
                value=math.sin(t*math.tau)*amp*(.35 if category=='idle'else math.sin(t*math.pi)if category=='recoil'else 0.)
                p.rotation_euler=(value,0,0);p.keyframe_insert('rotation_euler',frame=frame,group=name)
        for curve in action.fcurves:
            for key in curve.keyframe_points:key.interpolation='LINEAR'
        clips[category]={'source_action':action.name,'frames':frames,'loop':category=='idle'}
    return clips

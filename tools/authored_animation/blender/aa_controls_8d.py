"""Versioned original hands/secondary source production on verified 8C copies.

Remote Blender4 action API only. Original vertices/materials/rest/actions survive;
only explicitly named accessory/finger weights change. New digits are additive.
No body proportions, gameplay authority or original asset path is overwritten.
"""
import hashlib
import json
import math
import os
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[3]


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''): h.update(block)
    return h.hexdigest()


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def actions(names):
    return digest({a.name: [(c.data_path,c.array_index,[(list(k.co),k.interpolation)for k in c.keyframe_points])for c in a.fcurves]for a in bpy.data.actions if a.name in names})


def geometry(names):
    return digest({o.name: {'v':[list(v.co)for v in o.data.vertices],
                           'faces':[list(p.vertices)for p in o.data.polygons],
                           'm':[m.name if m else ''for m in o.data.materials],
                           'x':[list(row)for row in o.matrix_local],
                           'shape':{k.name:[list(v.co)for v in k.data]for k in o.data.shape_keys.key_blocks}if o.data.shape_keys else {}}
                   for o in bpy.data.objects if o.name in names and o.type=='MESH'})


def weights(names):
    return digest({o.name:{'g':[g.name for g in o.vertex_groups],
                           'w':[[(g.group,g.weight)for g in v.groups]for v in o.data.vertices]}
                   for o in bpy.data.objects if o.name in names and o.type=='MESH'})


def rest(arm,names):
    return digest({n:{'rest':[list(row)for row in arm.data.bones[n].matrix_local],
                      'parent':arm.data.bones[n].parent.name if arm.data.bones[n].parent else None}
                   for n in names})


def points(arm,ob):
    transform=arm.matrix_world.inverted()@ob.matrix_world
    return [transform@v.co for v in ob.data.vertices]


def bone(arm,name,start,end,parent):
    assert name not in arm.data.edit_bones
    b=arm.data.edit_bones.new(name);b.head=start;b.tail=end;b.parent=arm.data.edit_bones[parent]
    b.use_deform=True
    return name


def bind_chain(arm,ob,names,start,end,parent):
    coords=points(arm,ob);axis=end-start;length=axis.length;axis.normalize()
    for group in list(ob.vertex_groups):ob.vertex_groups.remove(group)
    groups=[ob.vertex_groups.new(name=n)for n in [parent]+names]
    for index,p in enumerate(coords):
        t=max(0.,min(1.,(p-start).dot(axis)/length))
        # Attached roots retain the old parent. Distal weighting crosses joints
        # smoothly with at most2 influences; original vertex positions survive.
        if t<.48:
            w=t/.48;pair=(0,1)
        else:
            w=(t-.48)/.52;pair=(1,2)
        groups[pair[0]].add([index],1-w,'REPLACE');groups[pair[1]].add([index],w,'REPLACE')
    assert any(m.type=='ARMATURE'and m.object==arm for m in ob.modifiers)


def digit_mesh(arm,name,start,end,radius,material,parent):
    axis=end-start;side=axis.cross(Vector((1,0,0)))
    if side.length<.001:side=axis.cross(Vector((0,1,0)))
    side.normalize();other=axis.normalized().cross(side)
    verts=[];rings=12;sides=10
    for row in range(rings+1):
        t=row/rings
        # Original rounded digit with tapered tip and restrained knuckle pads.
        r=radius*(.30+.70*math.sin(math.pi*max(.04,min(.96,t)))**.28)*(1-.16*t)
        for i in range(sides):
            a=i*math.tau/sides;verts.append(tuple(start+axis*t+r*(side*math.cos(a)+other*math.sin(a))))
    faces=[(row*sides+i,row*sides+(i+1)%sides,(row+1)*sides+(i+1)%sides,(row+1)*sides+i)for row in range(rings)for i in range(sides)]
    faces += [tuple(reversed(range(sides))),tuple(rings*sides+i for i in range(sides))]
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.materials.append(material);data.update()
    ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);ob.parent=arm
    mod=ob.modifiers.new('Original8D digit skin','ARMATURE');mod.object=arm
    for p in data.polygons:p.use_smooth=True
    ob['provenance']='Original8D additive digit, fitted to measured source palm; WIP'
    return ob


def edit_roundtrip_reference(arm,canonical):
    # A no-op control isolates Blender's own single-precision edit-mode
    # orthonormalisation. The actual canonical rest must match this EXACTLY;
    # no tolerance is enlarged to conceal an authored skeleton change.
    data=arm.data.copy();control=bpy.data.objects.new('D8_noop_rest_control',data)
    bpy.context.collection.objects.link(control)
    bpy.ops.object.select_all(action='DESELECT');control.select_set(True)
    bpy.context.view_layer.objects.active=control
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.object.mode_set(mode='OBJECT')
    result=rest(control,canonical)
    bpy.data.objects.remove(control,do_unlink=True);bpy.data.armatures.remove(data)
    return result


def deformed_points(arm,meshes):
    graph=bpy.context.evaluated_depsgraph_get();result=[]
    for name in meshes:
        ob=bpy.data.objects[name];evaluated=ob.evaluated_get(graph)
        mesh=evaluated.to_mesh()
        result.extend(tuple(evaluated.matrix_world@v.co)for v in mesh.vertices)
        evaluated.to_mesh_clear()
    return result


def verify_deformation(arm,chains):
    results={}
    for category,kind,phase in [('grip','finger',24),('fist','finger',20),('idle','hair',None),('recoil','hair',12)]:
        action=bpy.data.actions['ANI08D_WIP_'+category];arm.animation_data.action=action
        meshes=[c['mesh']for c in chains if c['kind']==kind]if kind=='finger'else[n for c in chains if c['kind']==kind for n in c['meshes']]
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update();before=deformed_points(arm,meshes)
        bpy.context.scene.frame_set(phase if phase is not None else int(action.frame_range[1]/4));bpy.context.view_layer.update();after=deformed_points(arm,meshes)
        assert len(before)==len(after)>0
        delta=max((Vector(a)-Vector(b)).length for a,b in zip(before,after))
        assert delta>.00001,(category,'actual source mesh did not deform',delta)
        results[category]={'sampled_vertices':len(before),'max_actual_mesh_displacement_m':delta,'method':'evaluated Blender armature skin before/after, same canonical body action'}
    return results


def prepare(arm,fid,body,spec):
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm
    bpy.ops.object.mode_set(mode='EDIT')
    chains=[];new_objects=[]
    for side,sign in [('L',-1),('R',1)]:
        parent='Hand_'+side;palm=bpy.data.objects['Palm '+side]
        palm_pts=points(arm,palm);center=sum(palm_pts,Vector())/len(palm_pts)
        radius=(max(v.x for v in palm_pts)-min(v.x for v in palm_pts))*.5
        forward=(arm.data.edit_bones[parent].tail-arm.data.edit_bones[parent].head).normalized()
        for i in range(5):
            if i<3:
                ob=bpy.data.objects['Finger %s %d'%(side,i)];coords=points(arm,ob);c=sum(coords,Vector())/len(coords)
                lo=min(v.dot(forward)for v in coords);hi=max(v.dot(forward)for v in coords)
                start=c+forward*(lo-c.dot(forward));end=c+forward*(hi-c.dot(forward))
            elif i==3:
                start=center+Vector((sign*radius*.73,-.034,-.005));end=start+forward*.052
                ob=None
            else:
                start=center+Vector((-sign*radius*.70,-.015,.006))
                end=start+Vector((-sign*radius*.42,-.048,-.019));ob=None
            names=[]
            for part in range(2):
                n='D8_Finger_%s_%d_%d'%(side,i,part)
                names.append(bone(arm,n,start+(end-start)*part*.5,start+(end-start)*(part+1)*.5,parent if part==0 else names[0]))
            chains.append({'kind':'finger','parent':parent,'bones':names,'mesh':ob.name if ob else 'D8_'+('Little'if i==3 else'Thumb')+'_'+side,'start':list(start),'end':list(end),'side':side,'digit':i,'new_mesh':ob is None,'radius':radius*(.15 if i==3 else .22)})
    # Explicit original hairstyles, not a cap/face classifier. All segments of
    # each side share one measured chain so braids/trim remain together.
    hair=[];cloth=[];armor=[]
    for ob in bpy.data.objects:
        if ob.type!='MESH' or ob.name.startswith('ANI08C_'):continue
        name=ob.name
        if (body=='male'and(name.startswith('Hair ')and name!='Hair cap'or name.startswith('Back crest')))or(body=='female'and any(name.startswith(s)for s in spec['female_hair_prefixes'])):hair.append(ob)
        elif any(name.startswith(s)for s in spec['cloth_prefixes']):cloth.append(ob)
        elif any(name.startswith(s)for s in spec['armor_prefixes']):armor.append(ob)
    assert hair,(fid,body,'no actual hairstyle selected')
    for kind,objects,parent in [('hair',hair,'Head'),('cloth',cloth,'Chest'),('armor',armor,'Chest')]:
        for region in [-1,0,1]:
            selected=[o for o in objects if (-1 if sum(p.x for p in points(arm,o))/len(o.data.vertices)<-.07 else 1 if sum(p.x for p in points(arm,o))/len(o.data.vertices)>.07 else 0)==region]
            if not selected:continue
            coords=[p for o in selected for p in points(arm,o)];cx=sum(p.x for p in coords)/len(coords);cy=sum(p.y for p in coords)/len(coords)
            up=body=='male'or fid in ['ember-vale','orion-vell']
            lo=min(p.z for p in coords);hi=max(p.z for p in coords)
            root_z=min(hi-.025,max(lo+.025,1.34 if up else 1.37))if kind=='hair' else hi
            start=Vector((cx,cy,root_z));end=Vector((cx,cy,max(hi,root_z+.04)if up and kind=='hair'else min(lo,root_z-.04)))
            parents={g.name for o in selected for g in o.vertex_groups if g.name in arm.data.edit_bones}
            assert len(parents)==1,(fid,kind,region,'mixed original attachment parents',parents)
            actual_parent=next(iter(parents))
            names=[]
            for part in range(2):
                n='D8_%s_%s_%d'%(kind,region,part)
                names.append(bone(arm,n,start+(end-start)*part*.5,start+(end-start)*(part+1)*.5,actual_parent if part==0 else names[0]))
            chains.append({'kind':kind,'parent':actual_parent,'bones':names,'meshes':[o.name for o in selected],'start':list(start),'end':list(end)})
    bpy.ops.object.mode_set(mode='OBJECT')
    modified=[]
    for chain in chains:
        if chain['kind']=='finger':
            ob=bpy.data.objects.get(chain['mesh'])
            if chain['new_mesh']:
                mat=bpy.data.objects['Finger '+chain['side']+' 0'].data.materials[0]
                ob=digit_mesh(arm,chain['mesh'],Vector(chain['start']),Vector(chain['end']),chain['radius'],mat,chain['parent']);new_objects.append(ob.name)
            bind_chain(arm,ob,chain['bones'],Vector(chain['start']),Vector(chain['end']),chain['parent']);modified.append(ob.name)
        else:
            for name in chain['meshes']:
                ob=bpy.data.objects[name]
                bind_chain(arm,ob,chain['bones'],Vector(chain['start']),Vector(chain['end']),chain['parent'])
                if chain['kind']=='armor':
                    # Plates articulate as rigid original parts, rather than
                    # bending forged surfaces as if they were hair or cloth.
                    for group in list(ob.vertex_groups):ob.vertex_groups.remove(group)
                    group=ob.vertex_groups.new(name=chain['bones'][0]);group.add(list(range(len(ob.data.vertices))),1.,'REPLACE')
                modified.append(name)
    return chains,modified,new_objects


def author(arm,spec,chains):
    clips={};names=[n for c in chains for n in c['bones']]
    for kind,frames in [('grip',24),('fist',20),('recoil',48),('idle',spec['idle_frames'])]:
        name='ANI08D_WIP_'+kind;assert name not in bpy.data.actions
        action=bpy.data.actions.new(name);action.use_fake_user=True;action['human_approved']=False;action['source_score']='art_source/animation/controls_8d/score_v1.json'
        arm.animation_data.action=action
        for frame in range(frames+1):
            t=frame/frames
            for chain in chains:
                for joint,n in enumerate(chain['bones']):
                    p=arm.pose.bones[n];p.rotation_mode='XYZ';value=0.
                    if chain['kind']=='finger':
                        if kind in ('grip','fist'):
                            u=max(0,min(1,t*1.25-chain['digit']*.045));u=u*u*(3-2*u)
                            value=u*spec['grip_scale']*((.65 if kind=='grip'else .82)if joint==0 else(.88 if kind=='grip'else 1.02))
                            if chain['digit']==4:value*=.62
                    else:
                        amplitude=spec['secondary_angle_rad']*(.35 if chain['kind']=='armor'else .8 if chain['kind']=='cloth'else 1.)*(1. if joint==0 else .65)
                        if kind=='idle':value=math.sin(t*math.tau)*amplitude*.35
                        elif kind=='recoil':value=math.sin(t*math.tau)*math.sin(t*math.pi)*amplitude
                    p.rotation_euler=(value,0,0);p.keyframe_insert('rotation_euler',frame=frame,group=n)
        for curve in action.fcurves:
            for key in curve.keyframe_points:key.interpolation='LINEAR'
        clips[kind]={'source_action':name,'frames':frames,'loop':kind=='idle','tracks':{n:[]for n in names}}
        for frame in range(frames+1):
            bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
            for n in names:
                q=arm.pose.bones[n].matrix_basis.to_quaternion()
                clips[kind]['tracks'][n].append([q.x,q.y,q.z,q.w])
    return clips


def run():
    assert os.environ.get('GITHUB_ACTIONS')=='true' and sys.platform=='linux','Compatible remote producer required'
    assert (4,0)<=bpy.app.version[:2]<(4,4),'Preserved4.0source/action compatibility required'
    args=sys.argv[sys.argv.index('--')+1:];inputs=Path(args[args.index('--input')+1]);out=Path(args[args.index('--output')+1]);out.mkdir(parents=True,exist_ok=False)
    prior=json.loads((ROOT/'artifacts/v1_closure/production_8c/remote_39790037341/PRODUCTION_MANIFEST.json').read_text())
    score=json.loads((ROOT/'art_source/animation/controls_8d/score_v1.json').read_text())
    assert shutil.disk_usage(out).free>4*1024**3
    manifest={'schema':'original_controls_production_8d.v1','source_sha':os.environ['GITHUB_SHA'],'run_id':os.environ['GITHUB_RUN_ID'],'blender_version':bpy.app.version_string,'rows':[],'complete':False,'human_approved':False}
    for row in prior['rows']:
        fid=row['fighter'];body=row['body'];src=inputs/row['saved_source'];assert sha(src)==row['saved_source_sha256']
        bpy.ops.wm.open_mainfile(filepath=str(src));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        canonical=[b.name for b in arm.data.bones];assert len(canonical)==22
        old_objects={o.name for o in bpy.data.objects};old_actions={a.name for a in bpy.data.actions}
        assert sum(n.startswith('ANI08B_WIP_')for n in old_actions)==30 and sum(n.startswith('ANI08C_WIP_')for n in old_actions)==8
        old_geo=geometry(old_objects);old_rest=rest(arm,canonical);old_curve=actions(old_actions)
        old_object_hashes={n:geometry([n])for n in old_objects if bpy.data.objects[n].type=='MESH'}
        old_bone_matrices={n:[list(r)for r in arm.data.bones[n].matrix_local]for n in canonical}
        before_weights={n:weights([n])for n in old_objects if bpy.data.objects[n].type=='MESH'}
        roundtrip_rest=edit_roundtrip_reference(arm,canonical)
        nla=[t.mute for t in arm.animation_data.nla_tracks];previous=arm.animation_data.action;previous_frame=bpy.context.scene.frame_current
        for t in arm.animation_data.nla_tracks:t.mute=True
        chains,modified,new_objects=prepare(arm,fid,body,score['fighters'][fid]);clips=author(arm,score['fighters'][fid],chains)
        deformation=verify_deformation(arm,chains)
        # Compare at the ORIGINAL action/frame: authoring sampled a different
        # action, which can change evaluated object-local transforms.
        arm.animation_data.action=previous
        for t,value in zip(arm.animation_data.nla_tracks,nla):t.mute=value
        bpy.context.scene.frame_set(previous_frame);bpy.context.view_layer.update()
        preservation={'fighter':fid,'body':body,'geometry_exact':geometry(old_objects)==old_geo,'rest_exact':rest(arm,canonical)==old_rest,'rest_matches_noop_control':rest(arm,canonical)==roundtrip_rest,'actions_exact':actions(old_actions)==old_curve,'changed_meshes':[n for n,h in old_object_hashes.items()if geometry([n])!=h],'rest_component_differences':{n:max(abs(arm.data.bones[n].matrix_local[i][j]-old_bone_matrices[n][i][j])for i in range(4)for j in range(4))for n in canonical if rest(arm,[n])!=digest({n:{'rest':old_bone_matrices[n],'parent':arm.data.bones[n].parent.name if arm.data.bones[n].parent else None}})}}
        (out/'runtime').mkdir(exist_ok=True)
        (out/'runtime/PRESERVATION_DIAGNOSTIC.json').write_text(json.dumps(preservation,indent=2)+'\n')
        assert preservation['geometry_exact']and preservation['rest_matches_noop_control']and preservation['actions_exact'],preservation
        assert all(weights([n])==w for n,w in before_weights.items()if n not in modified)
        # Save the complete editable library FIRST. Export from a reopened
        # disposable in-memory copy, never save the action-filtered export view.
        arm.animation_data.action=previous
        for t,value in zip(arm.animation_data.nla_tracks,nla):t.mute=value
        bpy.context.scene.frame_set(previous_frame)
        saved=out/f'saved_sources/{fid}/{body}/candidate_controls_8d.blend';saved.parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(saved));bpy.ops.wm.open_mainfile(filepath=str(saved));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        assert geometry(old_objects)==old_geo and rest(arm,canonical)==roundtrip_rest and actions(old_actions)==old_curve
        new_names={v['source_action']for v in clips.values()}
        for track in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(track)
        arm.animation_data.action=None
        for action in list(bpy.data.actions):
            if action.name not in new_names:bpy.data.actions.remove(action,do_unlink=True)
        for pose in arm.pose.bones:pose.matrix_basis=Matrix.Identity(4)
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
        bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
        for ob in bpy.data.objects:
            if ob.type=='MESH'and(ob.name in old_objects or ob.name in new_objects)and not ob.name.startswith('ANI08C_'):
                ob.hide_set(False);ob.select_set(True)
        resource=out/f'runtime/game-godot/assets/characters/controls_8d/{fid}/{body}/BASE.glb';resource.parent.mkdir(parents=True,exist_ok=True)
        # Official glTF animation transport performs the bone-basis conversion;
        # runtime will play ONLY D8 tracks alongside existing22-bone acting.
        bpy.ops.export_scene.gltf(filepath=str(resource),export_format='GLB',use_selection=True,export_animations=True,export_force_sampling=True,export_skins=True,export_morph=True,export_yup=True)
        assert resource.stat().st_size<8*1024**2
        doc={'schema':'saved_original_controls_8d.v1','fighter':fid,'body':body,'source_sha256':sha(saved),'input_8c_sha256':row['saved_source_sha256'],'resource':'res://'+str(resource.relative_to(out/'runtime/game-godot')),'resource_sha256':sha(resource),'canonical_bones':canonical,'chains':chains,'clips':clips,'human_approved':False}
        data=out/f'runtime/game-godot/data/animation/controls_8d/{fid}_{body}.json';data.parent.mkdir(parents=True,exist_ok=True);data.write_text(json.dumps(doc,separators=(',',':'))+'\n')
        record={'fighter':fid,'body':body,'saved_source':str(saved.relative_to(out)),'saved_source_sha256':sha(saved),'input_8c_sha256':row['saved_source_sha256'],'resource':str(resource.relative_to(out/'runtime')),'resource_sha256':sha(resource),'runtime':str(data.relative_to(out/'runtime')),'runtime_sha256':sha(data),'original_geometry_sha256':old_geo,'original_rest_sha256':old_rest,'edit_roundtrip_rest_sha256':roundtrip_rest,'rest_preservation':preservation,'source_deformation':deformation,'original_actions_sha256':old_curve,'preserved_actions':len(old_actions),'preserved_8b':30,'preserved_8c':8,'new_actions':list(clips),'new_bones':len(arm.data.bones)-22,'modified_weight_meshes':modified,'new_digit_meshes':new_objects,'canonical_bones_preserved':True,'original_geometry_materials_morphs_preserved':True,'unmodified_weights_preserved':True,'human_approved':False}
        manifest['rows'].append(record);(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n');print('CONTROLS_8D_SAVED',fid,body,flush=True)
    manifest['complete']=True;(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')


if __name__=='__main__':run()

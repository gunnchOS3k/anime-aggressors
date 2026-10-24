"""Remote-only original transformation actions and additive form structures.

Consumes verified 8B source copies, preserving their 30 saved actions and original
geometry. New source copies remain editable. Small attachment GLBs contain only
new meshes; no whole-body replacement, new anatomy, collision or gameplay data.
"""
import hashlib
import json
import math
import os
import shutil
import sys
from pathlib import Path
import bpy
from mathutils import Matrix,Vector

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools/authored_animation'))
sys.path.insert(0,str(ROOT/'tools/authored_animation/blender'))
from build_form_acting_8c import make_pack
from aa_directed_performance import reference,write_actions,verify_actions,export_runtime,C


def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()


def source_digest(arm,names):
    meshes={}
    for ob in bpy.data.objects:
        if ob.name not in names or ob.type!='MESH':continue
        meshes[ob.name]={'vertices':[list(v.co) for v in ob.data.vertices],
            'weights':[[(g.group,g.weight) for g in v.groups] for v in ob.data.vertices],
            'groups':[g.name for g in ob.vertex_groups],'transform':[list(row) for row in ob.matrix_local]}
    bones={b.name:[list(row) for row in b.matrix_local] for b in arm.data.bones}
    return hashlib.sha256(json.dumps({'meshes':meshes,'bones':bones},sort_keys=True).encode()).hexdigest()


def actions_digest(names):
    data={a.name:[(c.data_path,c.array_index,[(list(k.co),k.interpolation) for k in c.keyframe_points])for c in a.fcurves]for a in bpy.data.actions if a.name in names}
    return hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()


def material(fid,stage,color):
    m=bpy.data.materials.new(f'ANI08C_{fid}_{stage}_original');m.use_nodes=True
    m.diffuse_color=(*color,1);node=m.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value=(*color,1)
    node.inputs['Roughness'].default_value=.42;node.inputs['Metallic'].default_value=.15
    emission=node.inputs.get('Emission Color') or node.inputs.get('Emission')
    assert emission is not None,'Principled emission socket unavailable'
    emission.default_value=(*color,1);node.inputs['Emission Strength'].default_value=.28 if stage==1 else .48
    return m


def mesh(name,verts,faces,mat):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);data.materials.append(mat)
    ob['original_candidate']='8C independent canon-derived power structure; not final character art'
    return ob


def panel(name,points,width,mat):
    # Original thin faceted ribbon follows explicit source points; the side edge
    # preserves a solid silhouette under Compatibility without alpha overdraw.
    verts=[]
    for p in points:verts.extend([(p[0]-width,p[1],p[2]),(p[0]+width,p[1],p[2])])
    faces=[(i*2,i*2+1,i*2+3,i*2+2)for i in range(len(points)-1)]
    return mesh(name,verts,faces,mat)


def crystal(name,base,tip,radius,mat,sides=5):
    b,t=Vector(base),Vector(tip);axis=(t-b).normalized();side=axis.cross(Vector((0,1,0)))
    if side.length<.001:side=axis.cross(Vector((1,0,0)))
    side.normalize();other=axis.cross(side)
    verts=[tuple(b+radius*(math.cos(i*math.tau/sides)*side+math.sin(i*math.tau/sides)*other))for i in range(sides)]+[tuple(t)]
    faces=[tuple(reversed(range(sides)))]+[(i,(i+1)%sides,sides)for i in range(sides)]
    return mesh(name,verts,faces,mat)


def arc(name,center,radius,start,end,width,mat,segments=18,tilt=0):
    verts=[]
    for i in range(segments+1):
        a=start+(end-start)*i/segments
        for rr in (radius-width,radius+width):
            verts.append((center[0]+rr*math.cos(a),center[1]+rr*math.sin(a)*math.sin(tilt),center[2]+rr*math.sin(a)*math.cos(tilt)))
    faces=[(i*2,i*2+1,i*2+3,i*2+2)for i in range(segments)]
    return mesh(name,verts,faces,mat)


def attachment_stage(arm,fid,body,form_id,stage,entry):
    color=tuple(int(entry['presentation']['element_accent'].lstrip('#')[i:i+2],16)/255 for i in (0,2,4))
    if fid=='yin':color=(.08,.085,.12) # Preserve negative-space contrast; white seed stays original.
    if fid=='yang':color=(.85,.79,.58) # Warm edge geometry preserves the original black seed.
    mat=material(fid,stage,color);groups={};objects=[];parts=[]
    scale=1.0 if stage==1 else 1.28
    def bind(ob,bone):
        if bone not in groups:
            group=bpy.data.objects.new(f'Socket_{bone}',None);bpy.context.collection.objects.link(group)
            group.matrix_world=arm.matrix_world@arm.data.bones[bone].matrix_local
            group['canonical_bone']=bone;group['form_id']=form_id;group['source_stage']='8C_WIP';groups[bone]=group
        world=ob.matrix_world.copy();ob.parent=groups[bone];ob.matrix_world=world
        ob['canonical_bone']=bone;ob['form_id']=form_id;objects.append(ob);return ob
    name=lambda n:f'ANI08C_{fid}_{stage}_{n}'
    if fid=='ember-vale':
        for sign,side in ((-1,'L'),(1,'R')):
            for i in range(2+stage):
                x=sign*(.11+i*.036);z=.61+i*.039
                bind(crystal(name(f'vent_{side}{i}'),(x,-.17,z),(x+sign*.04,-.21,z+.075*scale),.018,mat), 'Chest')
        if stage==2:
            for i in range(5):
                x=(i-2)*.072;bind(crystal(name(f'heat_crown{i}'),(x,.01,1.34),(x*1.12,-.015,1.48+.018*(2-abs(i-2))),.025,mat),'Head')
    elif fid=='rook-ironside':
        for sign,side in ((-1,'L'),(1,'R')):
            shoulder=abs(arm.data.bones['Shoulder_'+side].tail.x)
            for i in range(2+stage):
                x=sign*(shoulder+.05+i*.015);z=.78-i*.032
                bind(panel(name(f'stratum_{side}{i}'),[(x,-.11,z),(x+sign*.07,-.10,z+.018),(x+sign*.085,.08,z-.018)],.028*scale,mat),'Shoulder_'+side)
            bind(arc(name(f'joint_{side}'),(sign*(shoulder+.1),-.13,.51),.075*scale,0,math.tau,.011,mat,20),'LowerArm_'+side)
    elif fid=='juno-spark':
        for sign,side in ((-1,'L'),(1,'R')):
            for i in range(stage+1):
                z=.57+i*.055
                bind(panel(name(f'rail_{side}{i}'),[(sign*.06,-.182,z),(sign*.13,-.185,z+.045),(sign*.10,-.18,z+.08)],.009,mat),'Chest')
            if stage==2:
                bind(panel(name(f'fork_{side}'),[(sign*.16,.01,.76),(sign*.25,.04,.90),(sign*.21,.04,.87),(sign*.28,.05,.96)],.012,mat),'Shoulder_'+side)
    elif fid=='kaia-windrow':
        for sign,side in ((-1,'L'),(1,'R')):
            for i in range(stage):
                off=i*.06
                bind(panel(name(f'pressure_airfoil_{side}{i}'),[(sign*.11,.12,.73),(sign*(.28+off),.16,.86+off),(sign*(.41+off),.18,.70),(sign*(.32+off),.14,.52-off)],.015 if stage==1 else .02,mat),'Chest')
            bind(arc(name(f'pressure_crescent_{side}'),(sign*.14,-.10,.56),.10*scale,-.5,1.9,.009,mat,16,sign*.4),'Hips')
    elif fid=='nix-calder':
        for sign,side in ((-1,'L'),(1,'R')):
            for i in range(2+stage):
                bind(crystal(name(f'mantle_facet_{side}{i}'),(sign*(.14+i*.018),.04,.68+i*.025),(sign*(.23+i*.035),.07,.86+i*.035*scale),.036,mat,5),'Shoulder_'+side)
        if stage==2:bind(crystal(name('central_crystal'),(0,.10,.68),(0,.15,1.01),.065,mat,6),'Chest')
    elif fid=='orion-vell':
        for i in range(stage+1):
            bind(arc(name(f'orbit{i}'),(0,.075,.68),.32+i*.065,.25,math.tau-.25,.009,mat,24,(-1 if i%2 else 1)*(.35+i*.2)),'Chest')
        for i in range(3+stage):
            a=i*math.tau/(3+stage);p=(.39*math.cos(a),.08,.68+.32*math.sin(a))
            bind(crystal(name(f'orbital_node{i}'),p,(p[0],p[1],p[2]+.055),.027,mat,6),'Chest')
    elif fid=='vesper-nyx':
        for i in range(3+stage):
            sign=-1 if i%2 else 1;x=sign*(.18+i*.012);z=.78-i*.065
            bind(panel(name(f'dislocation{i}'),[(x,.12,z),(x+sign*.07,.14,z-.045),(x+sign*.095,.15,z-.12)],.018,mat),'Chest')
        if stage==2:
            bind(arc(name('broken_phase_frame'),(.03,.12,.76),.33,.35,2.4,.013,mat,18,.15),'Chest')
    elif fid=='yin':
        for i in range(stage+1):
            radius=.17+i*.055
            bind(arc(name(f'collapsed_aperture{i}'),(0,.12,.72),radius,.35+i*.2,math.tau-.55-i*.1,.018,mat,24,-.15*i),'Chest')
        if stage==2:
            for sign in (-1,1):
                bind(panel(name(f'inward_edge{sign}'),[(sign*.37,.11,.86),(sign*.26,.10,.76),(sign*.17,.09,.70)],.014,mat),'Chest')
    elif fid=='yang':
        for i in range(stage+1):
            bind(arc(name(f'definition_halo{i}'),(0,.13,.84),.25+i*.07,0,math.tau,.009,mat,24,.1*i),'Chest')
        for i in range(4+stage*2):
            a=i*math.tau/(4+stage*2);p=(.23*math.cos(a),.12,.84+.23*math.sin(a));t=(.43*math.cos(a),.12,.84+.43*math.sin(a))
            bind(crystal(name(f'construct_ray{i}'),p,t,.012,mat,4),'Chest')
    else:raise AssertionError(fid)
    for bone,group in groups.items():
        rest=C@arm.data.bones[bone].matrix_local@C.inverted()
        parts.append(dict(node=group.name,canonical_bone=bone,source_rest_transform_godot=[list(row)for row in rest],children=[ob.name for ob in objects if ob.parent==group]))
    vertices=sum(len(ob.data.vertices)for ob in objects);triangles=sum(len(p.vertices)-2 for ob in objects for p in ob.data.polygons)
    assert vertices<=2048 and triangles<=3000 and len(groups)<=8
    return dict(form_id=form_id,ladder_step=entry['ladder_step'],parts=parts,mesh_objects=len(objects),vertices=vertices,triangles=triangles,rigid_bone_follow=True,independent_hair_cloth=False,human_approved=False),list(groups.values()),objects


def export_attachment(path,groups,objects):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in groups+objects:ob.hide_viewport=False;ob.hide_render=False;ob.hide_set(False);ob.select_set(True)
    path.parent.mkdir(parents=True,exist_ok=True)
    bpy.context.view_layer.objects.active=groups[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_extras=True,export_animations=False,export_skins=False,export_yup=True,export_apply=False)
    assert path.stat().st_size<1024**2,'Bounded attachment resource exceeded1MiB'
    for ob in groups+objects:ob.hide_set(True);ob.hide_render=True


def run():
    assert os.environ.get('GITHUB_ACTIONS')=='true' and sys.platform=='linux','Remote production only; retain internal18GiB reserve'
    assert (3,3)<=bpy.app.version[:2]<(4,4),'Preserved action API required'
    args=sys.argv[sys.argv.index('--')+1:];out=Path(args[args.index('--output')+1]).resolve();inputs=Path(args[args.index('--input-8b')+1]).resolve()
    out.mkdir(parents=True,exist_ok=True)
    prior=json.loads((ROOT/'artifacts/v1_closure/elemental_grab_throw_8b/PRODUCTION_MANIFEST_39733087497.json').read_text())
    source_bytes=sum((inputs/r['saved_source']).stat().st_size for r in prior['rows'])
    peak=source_bytes*4+1024**3;assert shutil.disk_usage(out).free>peak+1024**3,'Runner capacity'
    manifest=dict(schema='form_production_8c.v1',runtime_input_sha=os.environ.get('GITHUB_SHA',''),remote_run_id=os.environ.get('GITHUB_RUN_ID',''),rows=[],complete=False,human_approved=False,blender_version=bpy.app.version_string,storage=dict(remote_expected_peak_extra_bytes=peak,owner_internal_binary_allocation_bytes=0))
    for prior_row in prior['rows']:
        fid=prior_row['fighter'];body=prior_row['body'];source=inputs/prior_row['saved_source'];assert sha(source)==prior_row['saved_source_sha256'],'8B input receipt mismatch'
        bpy.ops.wm.open_mainfile(filepath=str(source));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        original_objects=set(o.name for o in bpy.data.objects);names=set(a.name for a in bpy.data.actions)
        assert len([n for n in names if n.startswith('ANI08B_WIP_')])==30,'Preserve all30saved8Bactions'
        original_geometry=source_digest(arm,original_objects);original_actions=actions_digest(names)
        assert original_geometry==prior_row['source_geometry_rest_weights_sha256'],'Original body changed since8B'
        tracks=[t.mute for t in arm.animation_data.nla_tracks];old_action=arm.animation_data.action;old_frame=bpy.context.scene.frame_current
        doc=make_pack(fid,body,reference(arm,fid,body));actions=write_actions(arm,fid,body,doc);check=verify_actions(arm,fid,body,doc);assert check['PASS'],check
        forms=json.loads((ROOT/f'game-godot/data/forms/{fid}.json').read_text());attachments={};new_objects=[]
        for number,(form_id,stage) in enumerate(doc['stages'].items(),1):
            report,groups,objects=attachment_stage(arm,fid,body,form_id,number,forms['forms'][form_id]);new_objects+=groups+objects
            resource=out/f'runtime/game-godot/assets/characters/form_acting_8c/{fid}/{body}/{form_id}.glb'
            export_attachment(resource,groups,objects)
            report.update(path='res://'+str(resource.relative_to(out/'runtime/game-godot')),sha256=sha(resource),bytes=resource.stat().st_size)
            attachments[form_id]=report
        arm.animation_data.action=old_action
        for track,mute in zip(arm.animation_data.nla_tracks,tracks):track.mute=mute
        bpy.context.scene.frame_set(old_frame)
        for bone in arm.pose.bones:bone.matrix_basis=Matrix.Identity(4)
        assert source_digest(arm,original_objects)==original_geometry and actions_digest(names)==original_actions
        target=out/f'saved_sources/{fid}/{body}/candidate_8c.blend';target.parent.mkdir(parents=True,exist_ok=True)
        bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(target));saved_hash=sha(target)
        bpy.ops.wm.open_mainfile(filepath=str(target));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        assert source_digest(arm,original_objects)==original_geometry and actions_digest(names)==original_actions,'Preserved8Bsource/actionchanged'
        doc=export_runtime(arm,fid,body,doc);check=verify_actions(arm,fid,body,doc);assert check['PASS'],check
        for clip in doc['clips'].values():clip.update(source_blend=str(target.relative_to(out)),source_blend_sha256=saved_hash,original_source_blend=prior_row['original_source'])
        doc.update(source_actions_saved=True,source_runtime_verified=True,source_base_blend_sha256=prior_row['original_source_sha256'],source_input_8b_sha256=prior_row['saved_source_sha256'],source_saved_blend_sha256=saved_hash,remote_run_id=os.environ.get('GITHUB_RUN_ID',''),status='SAVED_ORIGINAL_FORM_WIP_NATIVE_AND_HUMAN_PENDING',attachments=attachments)
        output=out/f'runtime/game-godot/data/animation/form_acting_8c/{fid}_{body}.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(doc,separators=(',',':'))+'\n')
        assert sha(source)==prior_row['saved_source_sha256'],'8Binputoverwritten'
        row=dict(fighter=fid,body=body,input_8b_source=str(source.relative_to(inputs)),input_8b_sha256=sha(source),original_source=prior_row['original_source'],original_source_sha256=prior_row['original_source_sha256'],saved_source=str(target.relative_to(out)),saved_source_sha256=saved_hash,source_geometry_rest_weights_sha256=original_geometry,original_actions_preserved=len(names),preserved_8b_actions=30,original_actions_sha256=original_actions,new_saved_actions=actions,source_runtime_verification=check,rig_bones=[b.name for b in arm.data.bones],runtime_file=str(output.relative_to(out)),runtime_sha256=sha(output),attachments=attachments,human_approved=False,native_visual_verified=False)
        manifest['rows'].append(row);(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n');print('SAVED_8C',fid,body,len(actions),check,flush=True)
    assert len(manifest['rows'])==18;manifest['complete']=True;(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')


if __name__=='__main__':run()

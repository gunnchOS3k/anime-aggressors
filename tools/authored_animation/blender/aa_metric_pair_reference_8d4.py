"""Reference pairs on exact saved8D3 rigs; not18-rig bulk production.

Requires an explicitly selected offline calibration. Root placement is frozen
before arm constraints. The shipping renderer remains independently unverified.
Original source files are only read; combined editable scenes are versioned.
"""
import copy
import hashlib
import json
import math
import os
import shutil
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import intersect_ray_tri
from aa_controls_8d import sha,geometry,weights,rest,actions
from aa_paired_surface_8d2 import contact_vertex,sample_vertex,solve_arm
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools/authored_animation'))
from metric_art_stage_8d4 import make_stage,feasibility
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))


def import_actor(source,role,observation,stage_actor):
    with bpy.data.libraries.load(str(source),link=False) as (available,loaded):
        source_names=list(available.objects);action_names=list(available.actions)
        loaded.objects=source_names;loaded.actions=action_names
    collection=bpy.data.collections.new(role+'_SOURCE_ACTOR');bpy.context.scene.collection.children.link(collection)
    objects={name:ob for name,ob in zip(source_names,loaded.objects) if ob is not None}
    curves={name:action for name,action in zip(action_names,loaded.actions) if action is not None}
    assert len(objects)==len(source_names) and len(curves)==len(action_names)
    for name,ob in objects.items():
        collection.objects.link(ob);ob.name=role+'__'+name
    for name,action in curves.items():action.name=role+'__'+name
    arm=next(o for o in objects.values() if o.type=='ARMATURE')
    assert max(abs(s-1) for s in arm.matrix_world.to_scale())<1e-6
    assert not any(b.name.startswith('CTRL_') for b in arm.data.bones),'Do not substitute a different source skeleton'
    anchor=bpy.data.objects.new(role+'_MEASURED_STAGE_PLACEMENT',None);collection.objects.link(anchor)
    placement=C.inverted()@Matrix(stage_actor['rig_godot_metres_to_stage'])@C
    for ob in objects.values():
        if ob.parent is None:ob.parent=anchor;ob.matrix_parent_inverse=Matrix.Identity(4)
    anchor.matrix_world=placement
    bpy.context.view_layer.update()
    # Freeze the actual Blender object transform after its own decomposition,
    # then require it unchanged through solving/save/reopen. No actor offset
    # is chosen from a contact residual.
    actual_placement=anchor.matrix_world.copy()
    assert max(abs(actual_placement[i][j]-placement[i][j])for i in range(4)for j in range(4))<1e-6
    for track in arm.animation_data.nla_tracks:track.mute=True
    mutable_names={o.name for o in objects.values()}
    visible=[o for n,o in objects.items() if o.type=='MESH' and not n.startswith(('ORIGINAL_8D_','ANI08C_')) and not o.get('8d2_legacy_only',False)]
    return {'role':role,'arm':arm,'anchor':anchor,'placement':actual_placement,'objects':objects,'visible':visible,'actions':curves,
            'names':mutable_names,'geometry_hash':geometry(mutable_names),'weights_hash':weights(mutable_names),
            'bone_names':[b.name for b in arm.data.bones],'rest_hash':rest(arm,[b.name for b in arm.data.bones]),
            'action_names':{a.name for a in curves.values()},'action_hash':actions({a.name for a in curves.values()}),
            'observation':observation}


def assert_preserved(actor):
    arm=actor['arm'];names=actor['names']
    assert geometry(names)==actor['geometry_hash'] and weights(names)==actor['weights_hash']
    assert rest(arm,actor['bone_names'])==actor['rest_hash'] and actions(actor['action_names'])==actor['action_hash']
    assert actor['anchor'].matrix_world==actor['placement'],'A contact solve moved a stage actor root'


def sample_action(actor,action,frame):
    arm=actor['arm'];arm.animation_data.action=None
    for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4);p.rotation_mode='XYZ'
    for curve in action.fcurves:
        if not curve.data_path.startswith('pose.bones['):continue
        bone=curve.data_path.split('"')[1];prop=curve.data_path.split('].')[1]
        if prop not in ('rotation_euler','location','scale'):raise ValueError(('Unsupported original channel',prop))
        getattr(arm.pose.bones[bone],prop)[curve.array_index]=curve.evaluate(frame)


def fingers(actor,doc,category,phase):
    action=actor['actions'][doc['clips'][category]['source_action']]
    for curve in action.fcurves:
        if curve.data_path.startswith('pose.bones["D8_Finger_'):
            name=curve.data_path.split('"')[1]
            actor['arm'].pose.bones[name].rotation_euler[curve.array_index]=curve.evaluate(phase*doc['clips'][category]['frames'])


def evaluated_tree(objects):
    graph=bpy.context.evaluated_depsgraph_get();verts=[];faces=[];parts=[]
    for ob in objects:
        evaluated=ob.evaluated_get(graph);mesh=evaluated.to_mesh();mesh.calc_loop_triangles();start=len(verts)
        verts.extend(evaluated.matrix_world@v.co for v in mesh.vertices)
        faces.extend(tuple(start+i for i in t.vertices) for t in mesh.loop_triangles)
        parts.append({'mesh':ob.name,'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles)})
        evaluated.to_mesh_clear()
    assert verts and faces
    return BVHTree.FromPolygons(verts,faces,all_triangles=True),parts,[(verts[a],verts[b],verts[c])for a,b,c in faces]


def triangle_crossings(hand_objects,target_tree,target_triangles):
    tree,parts,triangles=evaluated_tree(hand_objects);crossings=0;candidates=tree.overlap(target_tree)
    for i,j in candidates:
        crossed=False
        for tri,face in [(triangles[i],target_triangles[j]),(target_triangles[j],triangles[i])]:
            normal=(face[1]-face[0]).cross(face[2]-face[0]);normal.normalize()
            for k in range(3):
                a,b=tri[k],tri[(k+1)%3];da=(a-face[0]).dot(normal);db=(b-face[0]).dot(normal)
                if da*db>=0:continue # Tangency is not penetrating crossing.
                direction=b-a;extent=direction.length
                if extent<1e-8:continue
                hit=intersect_ray_tri(*face,a,direction.normalized(),True)
                if hit is not None and 1e-7<(hit-a).length<extent-1e-7:crossed=True;break
            if crossed:break
        crossings+=int(crossed)
    return {'bvh_candidate_triangle_pairs':len(candidates),'strict_surface_crossings':crossings,
            'scope':'Actual evaluated triangle segment/face crossings. Tangency excluded; not penetration volume or pressure.'}


def grip(actor,victim,hand,side):
    # Source indices/bones are preserved; use the actual edited palm pad.
    h=copy.deepcopy(hand);h['mesh']=actor['objects'][hand['mesh']].name
    witness=contact_vertex(actor['arm'],h)
    other='R' if side=='L' else 'L'
    target=[victim['objects'][n] for n in ['Upper arm '+other,'Forearm '+other]]
    if victim['observation']['fighter']=='rook-ironside':
        target += [o for n,o in victim['objects'].items() if n.startswith('Bastion forearm') and any(g.name=='LowerArm_'+other for g in o.vertex_groups)]
    tree,parts,triangles=evaluated_tree(target)
    pad=sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
    surface,normal,index,distance=tree.find_nearest(pad)
    assert surface is not None and normal.length>.99
    arm=actor['arm'];inv=arm.matrix_world.inverted();hand_bone=arm.pose.bones['Hand_'+side]
    n=arm.matrix_world.to_3x3().transposed()@normal;n.normalize()
    q=hand_bone.matrix.to_quaternion();palmar=q@Vector(witness['normal_hand_local'])
    desired=palmar.rotation_difference(-n)@q
    wrist=inv@surface-desired@Vector(witness['hand_local'])
    poses=[arm.pose.bones[n].matrix.translation for n in ['UpperArm_'+side,'LowerArm_'+side,'Hand_'+side]]
    reach=feasibility(*[list(p) for p in poses],list(wrist))
    axis=wrist-poses[0];pole=poses[1]-poses[0]
    pole= pole-axis.normalized()*pole.dot(axis.normalized()) if axis.length else Vector()
    if reach['reachable'] and pole.length<1e-6:reach.update(reachable=False,reason='Preferred source elbow pole degenerate; no arbitrary fallback')
    before_q=hand_bone.matrix.to_quaternion()
    if reach['reachable']:reach.update(solve_arm(arm,side,wrist,desired))
    actual=sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
    nearest,norm,triangle,gap=tree.find_nearest(actual)
    # Signed nearest-normal samples are reported honestly. They are not a
    # watertight-union pressure-volume proof, especially on open armor cuffs.
    evaluated=bpy.data.objects[witness['mesh']].evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
    signed=[]
    for v in mesh.vertices:
        p=evaluated.matrix_world@v.co;near,n,_,dist=tree.find_nearest(p);signed.append((p-near).dot(n))
    evaluated.to_mesh_clear()
    intersections=triangle_crossings([bpy.data.objects[witness['mesh']]],tree,triangles)
    own_cuff=None
    cuffs=[o for name,o in actor['objects'].items()if name.startswith('Bastion forearm') and any(g.name=='LowerArm_'+side for g in o.vertex_groups)]
    if cuffs:
        cuff_tree,cuff_parts,cuff_triangles=evaluated_tree(cuffs)
        own_cuff={'meshes':cuff_parts,'pad_to_armor_m':cuff_tree.find_nearest(actual)[3],
                  'surface_intersections':triangle_crossings([bpy.data.objects[witness['mesh']]],cuff_tree,cuff_triangles)}
    reach.update(side=side,pad_vertex=witness['index'],hand_mesh=witness['mesh'],target_meshes=parts,
                 before_pad_gap_m=distance,after_pad_gap_m=gap,world_pad=list(C@actual),world_surface=list(C@nearest),
                 minimum_signed_nearest_normal_m=min(signed),negative_signed_samples=sum(v<0 for v in signed),
                 signed_method='Per-triangle nearest outward normal, not validated penetration volume',
                 wrist_orientation_change_rad=before_q.rotation_difference(hand_bone.matrix.to_quaternion()).angle,
                 surface_intersections=intersections,
                 own_cuff_diagnostics=own_cuff,
                 source_root_changed=False,source_scale_changed=False)
    return reach


def apply_body(actor,frame):
    obs=actor['observation'];key='ANI08B_WIP_'+obs['source_action_clip'];action=actor['actions'][key]
    offset=obs['source_animation_time_s']*60
    duration=max(1.,float(action.frame_range[1]));sample_action(actor,action,(offset+frame)%duration)


def source_reference_performance(actors,docs,hands):
    actions_out=[];reports=[]
    for actor in actors:
        name='ANI08D4_REFERENCE_HOLD_'+actor['role']
        assert name not in bpy.data.actions
        action=bpy.data.actions.new(name);action.use_fake_user=True;actions_out.append(action)
    for frame in range(25):
        for actor,doc in zip(actors,docs):apply_body(actor,frame);fingers(actor,doc,'grip',1.)
        bpy.context.view_layer.update()
        before={a['role']:a['anchor'].matrix_world.copy() for a in actors}
        measured=[grip(actors[0],actors[1],hand,hand['side']) for hand in hands]
        for actor,action in zip(actors,actions_out):
            # Both actual actor performances are editable. Original individual
            #8B torso/legs/restraint, plus the attacker's measured arm contact.
            arm=actor['arm']
            for p in arm.pose.bones:
                for prop in ['rotation_euler']+(['location'] if p.name=='Hips' else []):
                    for index,value in enumerate(getattr(p,prop)):
                        path=p.path_from_id(prop);curve=action.fcurves.find(path,index=index)
                        if curve is None:curve=action.fcurves.new(path,index=index,action_group=p.name)
                        curve.keyframe_points.insert(frame,value)
            assert actor['anchor'].matrix_world==before[actor['role']]
        reports.append({'frame':frame,'hands':measured})
    for action in actions_out:
        for curve in action.fcurves:
            for key in curve.keyframe_points:key.interpolation='LINEAR'
    for actor,action in zip(actors,actions_out):actor['arm'].animation_data.action=action
    return actions_out,reports


def static_snapshot(actors,path):
    """Actual evaluated surfaces, labelled static native diagnostic export."""
    graph=bpy.context.evaluated_depsgraph_get();temporary=[];bounds=[]
    collection=bpy.data.collections.new('8D4_DISPOSABLE_EVALUATED_EXPORT');bpy.context.scene.collection.children.link(collection)
    bpy.ops.object.select_all(action='DESELECT')
    for actor in actors:
        for source in actor['visible']:
            evaluated=source.evaluated_get(graph);mesh=bpy.data.meshes.new_from_object(evaluated,preserve_all_data_layers=True,depsgraph=graph)
            mesh.transform(evaluated.matrix_world)
            ob=bpy.data.objects.new(actor['role']+'__SNAPSHOT__'+source.name,mesh);collection.objects.link(ob);ob.select_set(True);temporary.append(ob)
            points=[C@v.co for v in mesh.vertices]
            bounds.append({'mesh':ob.name,'minimum_m':[min(p[i] for p in points)for i in range(3)],'maximum_m':[max(p[i]for p in points)for i in range(3)],'samples_m':[list(p)for p in points[::max(1,len(points)//16)]]})
    path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
    for ob in temporary:bpy.data.objects.remove(ob,do_unlink=True)
    bpy.data.collections.remove(collection)
    return bounds


def run():
    assert os.environ.get('GITHUB_ACTIONS')=='true' and sys.platform=='linux' and (4,0)<=bpy.app.version[:2]<(4,4)
    args=sys.argv[sys.argv.index('--')+1:];inputs=Path(args[args.index('--input')+1]);out=Path(args[args.index('--output')+1])
    assert not out.exists() and shutil.disk_usage(out.parent).free>8*1024**3
    pack=json.loads((ROOT/'art_source/staging/metric_8d4/inputs_v1.json').read_text())
    prior=json.loads((inputs/'runtime/PRODUCTION_MANIFEST.json').read_text())
    retained=json.loads((ROOT/'artifacts/v1_closure/production_8d/hand_integration_remote_39910149332/PRODUCTION_MANIFEST.json').read_text())
    assert prior==retained and prior['source_sha']=='42baaab8cc5167798aea7f3aebb22edae9f21007' and prior['complete']
    lookup={(r['fighter'],r['body']):r for r in prior['rows']}
    hand_manifest=json.loads((ROOT/'artifacts/v1_closure/production_8d/hands_remote_39886629245/PRODUCTION_MANIFEST.json').read_text())
    hand_lookup={(r['fighter'],r['body']):r['hands']for r in hand_manifest['rows']}
    # Crucially fail BEFORE creating a stage or saving any scene if calibration
    # authority has not actually been selected by the owner.
    stages=[make_stage(pack['policy'],case['actors'],pack['source_hashes'])for case in pack['reference_cases']]
    out.mkdir();(out/'runtime').mkdir()
    manifest={'schema':'metric_pair_reference_sources_8d4.v1','producer_sha':os.environ['GITHUB_SHA'],
              'run_id':os.environ['GITHUB_RUN_ID'],'input_run':39910149332,'blender_version':bpy.app.version_string,
              'scope':'Eight offline reference scenes; not18-rig production or native shipping contact authority',
              'rows':[],'complete':False,'shipping_alignment_verified':False,'human_approved':False}
    for case,stage in zip(pack['reference_cases'],stages):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1.;scene.render.fps=60
        actors=[];docs=[]
        for role,observation,binding in zip(['A','B'],case['actors'],stage['actors']):
            row=lookup[observation['fighter'],observation['body']];source=inputs/row['saved_source'];assert sha(source)==row['saved_source_sha256']
            actors.append(import_actor(source,role,observation,binding))
            path=inputs/'runtime'/row['runtime'];assert sha(path)==row['runtime_sha256'];docs.append(json.loads(path.read_text()))
        bpy.context.view_layer.update()
        action_pair,contact=source_reference_performance(actors,docs,hand_lookup[case['actors'][0]['fighter'],case['actors'][0]['body']])
        for actor in actors:assert_preserved(actor)
        scene.frame_start=0;scene.frame_end=24;scene.frame_set(12);bpy.context.view_layer.update()
        saved=out/'saved_stages'/(case['case']+'.blend');saved.parent.mkdir(exist_ok=True)
        scene['8D4_stage_contract']=json.dumps(stage,separators=(',',':'))
        scene['8D4_limit']='Offline owner-calibrated art stage; static GLB snapshots are not installable animated fighter exports or shipping alignment proof'
        bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(saved))
        actor_names=[{'arm':a['arm'].name,'anchor':a['anchor'].name,'visible_names':[o.name for o in a['visible']],'new_action':action.name,'geometry':a['geometry_hash'],'weights':a['weights_hash'],'rest':a['rest_hash'],'old_actions':a['action_hash']}for a,action in zip(actors,action_pair)]
        # Reopen actual saved paired source. This does not regenerate either
        # input rig or rewrite the completed8D3 files.
        bpy.ops.wm.open_mainfile(filepath=str(saved))
        for actor,names in zip(actors,actor_names):
            actor['arm']=bpy.data.objects[names['arm']];actor['anchor']=bpy.data.objects[names['anchor']]
            actor['visible']=[bpy.data.objects[name]for name in names['visible_names']]
            assert_preserved(actor)
        bpy.context.scene.frame_set(12);bpy.context.view_layer.update()
        asset=out/'runtime/stage_snapshots'/(case['case']+'_held.glb');bounds=static_snapshot(actors,asset)
        # Preserve source-floor and runtime-collision planes as distinct data.
        feet=[]
        for actor in actors:
            graph=bpy.context.evaluated_depsgraph_get()
            for side in ['L','R']:
                ob=bpy.data.objects[actor['role']+'__Boot '+side];ev=ob.evaluated_get(graph);mesh=ev.to_mesh()
                bottom=min((C@ev.matrix_world@v.co).y for v in mesh.vertices);ev.to_mesh_clear()
                feet.append({'actor':actor['role'],'side':side,'evaluated_sole_stage_y_m':bottom,'source_floor_y_m':0.,'scope':'Actual skin surface, no root shift/foot-lock correction; source and runtime floor differ'})
        record={'case':case['case'],'saved_source':str(saved.relative_to(out)),'saved_source_sha256':sha(saved),'stage':stage,
                'input_sources':[{'fighter':a['fighter'],'body':a['body'],'sha256':a['source_sha256']}for a in case['actors']],
                'source_actions':[a['new_action']for a in actor_names],'source_preservation':actor_names,
                'contact_frames':contact,'static_snapshot':str(asset.relative_to(out/'runtime')),'snapshot_sha256':sha(asset),
                'snapshot_bounds':bounds,'floor_observations':feet,'grip_accepted':False,'shipping_alignment_verified':False,'human_approved':False}
        manifest['rows'].append(record)
        (out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
        print('SAVED_8D4_REFERENCE_STAGE',case['case'],flush=True)
    manifest['complete']=True;(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')


if __name__=='__main__':run()

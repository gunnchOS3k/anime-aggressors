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
from aa_controls_8d import sha,digest,weights,rest,actions
from aa_paired_surface_8d2 import contact_vertex,sample_vertex,solve_arm
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools/authored_animation'))
from metric_art_stage_8d4 import make_stage,feasibility,art_rotation
from private_production_8d4 import current_context
from metric_reference_scope_8d4 import select_cases
from paired_animation_8d4 import CLIP, FRAME_COUNT, FPS, inspect_paired_export
C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))


def geometry(names):
    """Exact asset data and stored bind transforms, independent of stage pose.

    Object.matrix_local is derived from evaluated parent/world matrices. Moving
    the offline anchor changes its float roundoff even with byte-identical mesh
    and stored object transforms. Preserve the actual basis, parent inverse and
    parent binding instead; do not round vertices, weights or rest transforms.
    """
    return digest({o.name:{'v':[list(v.co)for v in o.data.vertices],
                          'faces':[list(p.vertices)for p in o.data.polygons],
                          'm':[m.name if m else ''for m in o.data.materials],
                          'basis':[list(row)for row in o.matrix_basis],
                          'parent_inverse':[list(row)for row in o.matrix_parent_inverse],
                          'parent':o.parent.name if o.parent else None,
                          'parent_type':o.parent_type,'parent_bone':o.parent_bone,
                          'shape':{k.name:[list(v.co)for v in k.data]for k in o.data.shape_keys.key_blocks}if o.data.shape_keys else {}}
                   for o in bpy.data.objects if o.name in names and o.type=='MESH'})


def material_signature(objects):
    values={}
    for ob in objects:
        if ob.type!='MESH':continue
        for mat in ob.data.materials:
            if mat is None or mat.name in values:continue
            nodes=[]
            if mat.node_tree:
                for n in mat.node_tree.nodes:
                    sockets=[]
                    for socket in n.inputs:
                        if not hasattr(socket,'default_value'):continue
                        value=socket.default_value
                        if isinstance(value,(int,float,bool,str)):encoded=value
                        elif hasattr(value,'__iter__'):encoded=list(value)
                        elif value is None:encoded=None
                        else:encoded=getattr(value,'name',str(type(value)))
                        sockets.append([socket.identifier,encoded])
                    nodes.append([n.name,n.bl_idname,sockets])
            values[mat.name]={'diffuse':list(mat.diffuse_color),'roughness':mat.roughness,'metallic':mat.metallic,'nodes':nodes,
                              'links':[(l.from_node.name,l.from_socket.identifier,l.to_node.name,l.to_socket.identifier)for l in mat.node_tree.links]if mat.node_tree else []}
    return digest(values)


def import_actor(source,role,observation,stage_actor):
    with bpy.data.libraries.load(str(source),link=False) as (available,loaded):
        source_names=list(available.objects);action_names=list(available.actions)
        # Blender replaces requested lists with datablocks on context exit.
        # Retain string IDs for the original source-preservation mappings.
        loaded.objects=list(source_names);loaded.actions=list(action_names);loaded.scenes=list(available.scenes)
    units=[{'scene':s.name,'system':s.unit_settings.system,'scale_length':s.unit_settings.scale_length}for s in loaded.scenes]
    assert units and all(abs(u['scale_length']-1.)<1e-8 for u in units),'Source scene metre scale changed'
    collection=bpy.data.collections.new(role+'_SOURCE_ACTOR');bpy.context.scene.collection.children.link(collection)
    objects={name:ob for name,ob in zip(source_names,loaded.objects) if ob is not None}
    curves={name:action for name,action in zip(action_names,loaded.actions) if action is not None}
    assert len(objects)==len(source_names) and len(curves)==len(action_names)
    for name,ob in objects.items():
        collection.objects.link(ob);ob.name=role+'__'+name
    for name,action in curves.items():
        action.name=role+'__'+name
        # Removing the imported source scene can leave original actions with
        # zero users. Retain their editable curves through save/reopen.
        action.use_fake_user=True
    arm=next(o for o in objects.values() if o.type=='ARMATURE')
    assert max(abs(arm.matrix_world[i][j]-float(i==j))for i in range(4)for j in range(4))<1e-6,'Uncalibrated original armature object transform'
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
    assert arm.animation_data is not None
    for track in arm.animation_data.nla_tracks:track.mute=True
    for old_scene in loaded.scenes:bpy.data.scenes.remove(old_scene)
    mutable_names={o.name for o in objects.values()}
    visible=[o for n,o in objects.items() if o.type=='MESH' and not n.startswith(('ORIGINAL_8D_','ANI08C_')) and not o.get('8d2_legacy_only',False)]
    return {'role':role,'arm':arm,'anchor':anchor,'placement':actual_placement,'objects':objects,'visible':visible,'actions':curves,
            'names':mutable_names,'geometry_hash':geometry(mutable_names),'weights_hash':weights(mutable_names),'material_hash':material_signature(objects.values()),
            'bone_names':[b.name for b in arm.data.bones],'rest_hash':rest(arm,[b.name for b in arm.data.bones]),
            'action_names':{a.name for a in curves.values()},'action_hash':actions({a.name for a in curves.values()}),
            'observation':observation,'original_units':units}


def assert_preserved(actor):
    arm=actor['arm'];names=actor['names']
    assert geometry(names)==actor['geometry_hash'] and weights(names)==actor['weights_hash']
    assert material_signature([bpy.data.objects[n]for n in names])==actor['material_hash']
    assert rest(arm,actor['bone_names'])==actor['rest_hash'],('Original rest changed',actor['role'])
    assert actions(actor['action_names'])==actor['action_hash'],('Original action curves changed or omitted',actor['role'])
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
                hit=intersect_ray_tri(*face,direction.normalized(),a,True)
                if hit is not None and 1e-7<(hit-a).length<extent-1e-7:crossed=True;break
            if crossed:break
        crossings+=int(crossed)
    return {'bvh_candidate_triangle_pairs':len(candidates),'strict_surface_crossings':crossings,
            'scope':'Actual evaluated triangle segment/face crossings. Tangency excluded; not penetration volume or pressure.'}


def barycentric(p,tri):
    a,b,c=tri;v0=b-a;v1=c-a;v2=p-a
    d00=v0.dot(v0);d01=v0.dot(v1);d11=v1.dot(v1);d20=v2.dot(v0);d21=v2.dot(v1)
    denominator=d00*d11-d01*d01
    assert abs(denominator)>1e-16,'Degenerate contact material triangle'
    v=(d11*d20-d01*d21)/denominator;w=(d00*d21-d01*d20)/denominator
    weights=[1-v-w,v,w];assert min(weights)>-1e-4 and max(weights)<1.0001
    return weights


def grip(actor,victim,hand,side,bindings):
    # Source indices/bones are preserved; use the actual edited palm pad.
    h=copy.deepcopy(hand);h['mesh']=actor['objects'][hand['mesh']].name
    witness=contact_vertex(actor['arm'],h)
    other='R' if side=='L' else 'L'
    target=[victim['objects'][n] for n in ['Upper arm '+other,'Forearm '+other]]
    if victim['observation']['fighter']=='rook-ironside':
        target += [o for n,o in victim['objects'].items() if n.startswith('Bastion forearm') and any(g.name=='LowerArm_'+other for g in o.vertex_groups)]
    tree,parts,triangles=evaluated_tree(target)
    pad=sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
    nearest_start,normal,index,distance=tree.find_nearest(pad)
    assert nearest_start is not None and normal.length>.99
    if side not in bindings:
        bindings[side]={'triangle_index':index,'barycentric':barycentric(nearest_start,triangles[index]),
                        'target_meshes':[p['mesh']for p in parts],'scope':'Fixed evaluated victim material triangle across the held reference'}
    binding=bindings[side];assert binding['target_meshes']==[p['mesh']for p in parts]
    tri=triangles[binding['triangle_index']]
    surface=sum((p*w for p,w in zip(tri,binding['barycentric'])),Vector())
    normal=(tri[1]-tri[0]).cross(tri[2]-tri[0]).normalized()
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
    before_q=hand_bone.matrix.to_quaternion();before_pole=pole.normalized() if pole.length else None
    if reach['reachable']:reach.update(solve_arm(arm,side,wrist,desired))
    after_u,after_e,after_w=[arm.pose.bones[n].matrix.translation for n in ['UpperArm_'+side,'LowerArm_'+side,'Hand_'+side]]
    after_axis=(after_w-after_u).normalized();after_pole=after_e-after_u;after_pole-=after_axis*after_pole.dot(after_axis)
    pole_cosine=before_pole.dot(after_pole.normalized())if before_pole is not None and after_pole.length else None
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
                 before_pad_gap_m=distance,after_pad_gap_m=gap,material_binding=copy.deepcopy(binding),
                 pad_to_bound_material_point_m=(actual-surface).length,bound_material_point_stage_m=list(C@surface),
                 local_wrist_euler_rad=list(hand_bone.rotation_euler),world_pad=list(C@actual),world_surface=list(C@nearest),
                 minimum_signed_nearest_normal_m=min(signed),negative_signed_samples=sum(v<0 for v in signed),
                 signed_method='Per-triangle nearest outward normal, not validated penetration volume',
                 preferred_elbow_half_plane_cosine=pole_cosine,
                 wrist_orientation_change_rad=before_q.rotation_difference(hand_bone.matrix.to_quaternion()).angle,
                 surface_intersections=intersections,
                 own_cuff_diagnostics=own_cuff,
                 source_root_changed=False,source_scale_changed=False)
    return reach


def apply_body(actor,frame):
    obs=actor['observation'];key='ANI08B_WIP_'+obs['source_action_clip'];action=actor['actions'][key]
    offset=obs['source_animation_time_s']*60
    duration=max(1.,float(action.frame_range[1]));sample_action(actor,action,(offset+frame)%duration)


def source_placement(actors):
    """Authored art spacing from actual source surfaces, never native pixels.

    Torso support planes meet along the chosen offline fight axis. This is an
    editable initial art composition, not inferred gameplay/collision spacing.
    Its roots are frozen before the subsequent paired hand constraints.
    """
    for actor in actors:apply_body(actor,12)
    bpy.context.view_layer.update()
    extents=[];evidence=[]
    for actor in actors:
        names=['Articulated compact torso','Chest power plate','Hip costume']
        meshes=[actor['objects'][name]for name in names]
        _,parts,triangles=evaluated_tree(meshes)
        pts=[C@p for tri in triangles for p in tri]
        extents.append([min(p.x for p in pts),max(p.x for p in pts)])
        evidence.append({'role':actor['role'],'meshes':parts,'source_units':actor['original_units'],
                         'pose_frame':12,'basis':'Original per-character8B hold/restraint; evaluated original torso surfaces before paired solve'})
    return {'method':'authored_opposed_axes_evaluated_torso_support_planes',
            'scope':'Offline authored composition only; NOT authoritative gameplay spacing',
            'source_hashes':[a['observation']['source_sha256']for a in actors],
            'torso_axis_extents_m':extents,'source_geometry_evidence':evidence,
            'native_px_offsets_used_for_physical_placement':False,'solver_may_change_roots':False}


def surface_sensitivity(actors,hand):
    """Actual evaluated source surfaces, measured without moving saved actors."""
    a,b=actors;h=copy.deepcopy(hand);h['mesh']=a['objects'][hand['mesh']].name
    witness=contact_vertex(a['arm'],h);pad=sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
    side='R' if hand['side']=='L' else 'L'
    tree,parts,triangles=evaluated_tree([b['objects'][n]for n in ['Upper arm '+side,'Forearm '+side]])
    points=[p for t in triangles for p in t];span=max(max(p[i]for p in points)-min(p[i]for p in points)for i in range(3))
    # Twice the evaluated target's maximum span is a source-derived diagnostic
    # displacement, not an authored gameplay or rig offset.
    extent=2*span;depth=C.inverted()@Vector((0,0,extent));horizontal=C.inverted()@Vector((extent,0,0))
    base=tree.find_nearest(pad)[3]
    tests=[]
    for name,shift in [('depth_same_projection',depth),('opponent_translation',horizontal)]:
        near,normal,tri,distance=tree.find_nearest(pad-shift)
        tests.append({'probe':name,'target_translation_stage_m':list(C@shift),'baseline_surface_gap_m':base,
                      'displaced_surface_gap_m':distance,'distance_changed':abs(distance-base)>1e-6,
                      'projected_target_delta_reference_px':[0.,0.]if name=='depth_same_projection'else None})
    poses=[a['arm'].pose.bones[n].matrix.translation for n in ['UpperArm_'+hand['side'],'LowerArm_'+hand['side'],'Hand_'+hand['side']]]
    lengths=[(poses[1]-poses[0]).length,(poses[2]-poses[1]).length]
    impossible=poses[0]+Vector((sum(lengths)+max(lengths),0,0))
    rejection=feasibility(*[list(p)for p in poses],list(impossible))
    assert not rejection['reachable'] and all(t['distance_changed']for t in tests)
    return {'scope':'Actual evaluated held surfaces, diagnostic translations only; saved roots untouched',
            'target_meshes':parts,'probes':tests,'impossible_reach':rejection}


def source_reference_performance(actors,docs,hands):
    actions_out=[];reports=[];bindings={}
    for actor in actors:
        name='ANI08D4_REFERENCE_HOLD_'+actor['role']
        assert name not in bpy.data.actions
        action=bpy.data.actions.new(name);action.use_fake_user=True;actions_out.append(action)
    for frame in range(25):
        for actor,doc in zip(actors,docs):apply_body(actor,frame);fingers(actor,doc,'grip',1.)
        bpy.context.view_layer.update()
        before={a['role']:a['anchor'].matrix_world.copy() for a in actors}
        measured=[grip(actors[0],actors[1],hand,hand['side'],bindings) for hand in hands]
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


def animated_reference(actors,path):
    """Export the two REAL active hold actions, never static copies or all old actions.

    ACTIVE_ACTIONS and export_anim_single_armature=False are explicit4.0 API
    options for a synchronized multi-armature clip. No new release acting is
    invented by this export. Original input rigs/actions remain unchanged.
    """
    scene=bpy.context.scene
    assert scene.render.fps==FPS and scene.frame_start==0 and scene.frame_end==FRAME_COUNT-1
    records=[{'role':a['role'],'anchor':a['anchor'].name,'bone_names':list(a['bone_names']),
              'source_action':a['arm'].animation_data.action.name}for a in actors]
    frames=[]
    for frame in range(FRAME_COUNT):
        scene.frame_set(frame);bpy.context.view_layer.update()
        samples=[]
        for actor in actors:
            assert_preserved(actor)
            matrix=C@actor['anchor'].matrix_world@C.inverted()
            samples.append({'role':actor['role'],
                            'anchor_transform_stage_m':[[matrix[i][j]for j in range(4)]for i in range(4)],
                            'bones_stage_m':{b.name:list(C@actor['arm'].matrix_world@b.matrix.translation)for b in actor['arm'].pose.bones}})
        frames.append({'frame':frame,'actors':samples})
    bpy.ops.object.select_all(action='DESELECT')
    for actor in actors:
        for ob in [actor['anchor'],actor['arm'],*actor['visible']]:ob.select_set(True)
    path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
                              export_yup=True,export_apply=False,export_skins=True,
                              export_animations=True,export_animation_mode='ACTIVE_ACTIONS',
                              export_anim_single_armature=False,
                              export_nla_strips_merged_animation_name=CLIP,
                              export_frame_range=True,export_frame_step=1,
                              export_force_sampling=True,export_optimize_animation_size=False,
                              export_def_bones=False)
    for actor in actors:assert_preserved(actor)
    inspection=inspect_paired_export(path,records)
    return {'resource':str(path.relative_to(path.parents[1])), 'sha256':sha(path),
            'clip':CLIP,'FPS':FPS,'source_frame_count':FRAME_COUNT,
            'actors':records,'pose_frames':frames,'binary_inspection':inspection,
            'scope':'Original two-actor25-frame hold/restraint source only; release/locomotion/recovery acting still required',
            'gameplay_movement_authority':False,'native_playback_verified':False,'human_approved':False}


def run():
    execution=current_context(ROOT,producer_binary=bpy.app.binary_path) # Fail before source loads or output.
    assert (4,0)<=bpy.app.version[:2]<(4,4),'Preserved Blender4 sources require a compatible4.0–4.3 producer'
    local=execution.get('execution_environment')in ('OWNER_LOCAL_OFFLINE','OWNER_ENCRYPTED_EXTERNAL')
    if local:assert bpy.app.version[:3]==(4,0,2),'Exact audited4.0.2 source producer required locally'
    if not local:assert os.environ.get('GITHUB_ACTIONS')=='true' and sys.platform=='linux'
    args=sys.argv[sys.argv.index('--')+1:];inputs=Path(args[args.index('--input')+1]);out=Path(args[args.index('--output')+1])
    assert not out.exists() and shutil.disk_usage(out.parent).free>8*1024**3
    if local:assert out.resolve()==Path(execution['output_path']).resolve(),'Offline output escaped its private workspace'
    pack=json.loads((ROOT/'art_source/staging/metric_8d4/inputs_v1.json').read_text())
    case_id=args[args.index('--case-id')+1] if '--case-id' in args else None
    cases=select_cases(pack,case_id)
    if local:assert case_id is not None,'Local production requires one explicit pilot before any batch'
    prior=json.loads((inputs/'runtime/PRODUCTION_MANIFEST.json').read_text())
    retained=json.loads((ROOT/'artifacts/v1_closure/production_8d/hand_integration_remote_39910149332/PRODUCTION_MANIFEST.json').read_text())
    assert prior==retained and prior['source_sha']=='42baaab8cc5167798aea7f3aebb22edae9f21007' and prior['complete']
    lookup={(r['fighter'],r['body']):r for r in prior['rows']}
    hand_manifest=json.loads((ROOT/'artifacts/v1_closure/production_8d/hands_remote_39886629245/PRODUCTION_MANIFEST.json').read_text())
    hand_lookup={(r['fighter'],r['body']):r['hands']for r in hand_manifest['rows']}
    # Crucially fail BEFORE creating a stage or saving any scene if calibration
    # authority has not actually been selected by the owner.
    assert pack['policy']['status']=='OWNER_SELECTED_OFFLINE_REFERENCE'
    assert pack['policy']['camera_role']=='OFFLINE_FRAMING_ONLY_NEVER_METRIC_SPACING'
    selection=ROOT/pack['policy']['owner_selection_receipt'];assert selection.is_file()
    owner_selection=json.loads(selection.read_text())
    assert not owner_selection['gameplay_px_to_metre_authority_granted'] and not owner_selection['public_modified_art_upload_authorized']
    out.mkdir();(out/'runtime').mkdir()
    shutil.copy2(ROOT/'art_source/staging/metric_8d4/inputs_v1.json',out/'runtime/STAGE_INPUTS.json')
    shutil.copy2(selection,out/'runtime/OWNER_CALIBRATION_SELECTION.json')
    manifest={'schema':'metric_pair_reference_sources_8d4.v1','producer_sha':execution['producer_sha'],'private_execution':execution,
              'run_id':None if local else os.environ['GITHUB_RUN_ID'],'input_run':39910149332,'blender_version':bpy.app.version_string,
              'reference_camera_size_m':pack['policy']['reference_observation']['projection']['camera_size'],
              'all_18_native_camera_scales':pack['measured_body_scales'],'owner_selection_sha256':sha(selection),
              'scope':'Offline reference source; not18-rig production or native shipping contact authority',
              'reference_scope':'SINGLE_CASE_PILOT' if case_id else 'FULL_REFERENCE_BATCH',
              'selected_cases':[case['case']for case in cases],'full_reference_batch_complete':False,
              'rows':[],'complete':False,'shipping_alignment_verified':False,'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False}
    for case in cases:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1.;scene.render.fps=60
        actors=[];docs=[]
        for role,observation in zip(['A','B'],case['actors']):
            binding={'rig_godot_metres_to_stage':art_rotation(observation['facing'])}
            row=lookup[observation['fighter'],observation['body']];source=inputs/row['saved_source'];assert sha(source)==row['saved_source_sha256']
            actors.append(import_actor(source,role,observation,binding))
            path=inputs/'runtime'/row['runtime'];assert sha(path)==row['runtime_sha256'];docs.append(json.loads(path.read_text()))
        bpy.context.view_layer.update()
        placement=source_placement(actors)
        stage=make_stage(pack['policy'],case['actors'],pack['source_hashes'],placement)
        for actor,binding in zip(actors,stage['actors']):
            actor['anchor'].matrix_world=C.inverted()@Matrix(binding['rig_godot_metres_to_stage'])@C
            bpy.context.view_layer.update();actor['placement']=actor['anchor'].matrix_world.copy()
            requested=C.inverted()@Matrix(binding['rig_godot_metres_to_stage'])@C
            assert max(abs(actor['placement'][i][j]-requested[i][j])for i in range(4)for j in range(4))<1e-6
        action_pair,contact=source_reference_performance(actors,docs,hand_lookup[case['actors'][0]['fighter'],case['actors'][0]['body']])
        for actor in actors:assert_preserved(actor)
        scene.frame_start=0;scene.frame_end=24;scene.frame_set(12);bpy.context.view_layer.update()
        sensitivity=surface_sensitivity(actors,hand_lookup[case['actors'][0]['fighter'],case['actors'][0]['body']][0])
        saved=out/'saved_stages'/(case['case']+'.blend');saved.parent.mkdir(exist_ok=True)
        scene['8D4_stage_contract']=json.dumps(stage,separators=(',',':'))
        scene['8D4_limit']='Offline owner-calibrated art stage; static GLB snapshots are not installable animated fighter exports or shipping alignment proof'
        bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(saved))
        actor_names=[{'arm':a['arm'].name,'anchor':a['anchor'].name,'visible_names':[o.name for o in a['visible']],'new_action':action.name,'geometry':a['geometry_hash'],'weights':a['weights_hash'],'rest':a['rest_hash'],'materials':a['material_hash'],'old_actions':a['action_hash']}for a,action in zip(actors,action_pair)]
        (saved.parent/(case['case']+'_preservation.json')).write_text(json.dumps(actor_names,indent=2)+'\n')
        # Reopen actual saved paired source. This does not regenerate either
        # input rig or rewrite the completed8D3 files.
        bpy.ops.wm.open_mainfile(filepath=str(saved))
        for actor,names in zip(actors,actor_names):
            actor['arm']=bpy.data.objects[names['arm']];actor['anchor']=bpy.data.objects[names['anchor']]
            actor['visible']=[bpy.data.objects[name]for name in names['visible_names']]
            assert_preserved(actor)
        # Verify actual saved/reopened animation, not only pre-save solver
        # coordinates. Tolerance is float32 FK serialization, not art approval.
        reopened=[]
        input_hands=hand_lookup[case['actors'][0]['fighter'],case['actors'][0]['body']]
        for frame_record in contact:
            bpy.context.scene.frame_set(frame_record['frame']);bpy.context.view_layer.update()
            samples=[]
            for h,expected in zip(input_hands,frame_record['hands']):
                copy_hand=copy.deepcopy(h)
                # Old object handles were invalidated by reopen; use names.
                copy_hand['mesh']=actors[0]['role']+'__'+h['mesh']
                witness=contact_vertex(actors[0]['arm'],copy_hand)
                actual=C@sample_vertex(bpy.data.objects[witness['mesh']],witness['index'])
                error=(actual-Vector(expected['world_pad'])).length
                assert error<.00005,('Saved source paired FK differs',case['case'],frame_record['frame'],h['side'],error)
                samples.append({'side':h['side'],'saved_pad_stage_m':list(actual),'pre_save_pad_error_m':error})
            reopened.append({'frame':frame_record['frame'],'hands':samples})
        bpy.context.scene.frame_set(12);bpy.context.view_layer.update()
        snapshots=[]
        for state in ['open','closed','held']:
            for actor,doc,names in zip(actors,docs,actor_names):
                action=bpy.data.actions[names['new_action']];sample_action(actor,action,12)
                fingers(actor,doc,'fist' if state=='closed' else 'grip',0. if state=='open' else 1.)
            bpy.context.view_layer.update()
            asset=out/'runtime/stage_snapshots'/(case['case']+'_'+state+'.glb');bounds=static_snapshot(actors,asset)
            snapshots.append({'state':state,'resource':str(asset.relative_to(out/'runtime')),
                              'sha256':sha(asset),'bounds':bounds,'scope':'Static actual evaluated source surfaces; NOT an animated fighter export'})
        # Restore the saved paired held action for floor/source diagnostics.
        for actor,names in zip(actors,actor_names):actor['arm'].animation_data.action=bpy.data.actions[names['new_action']]
        bpy.context.scene.frame_set(12);bpy.context.view_layer.update()
        # Preserve source-floor and runtime-collision planes as distinct data.
        feet=[]
        for actor in actors:
            graph=bpy.context.evaluated_depsgraph_get()
            for side in ['L','R']:
                ob=bpy.data.objects[actor['role']+'__Boot '+side];ev=ob.evaluated_get(graph);mesh=ev.to_mesh()
                bottom=min((C@ev.matrix_world@v.co).y for v in mesh.vertices);ev.to_mesh_clear()
                feet.append({'actor':actor['role'],'side':side,'evaluated_sole_stage_y_m':bottom,'common_art_floor_y_m':0.,'local_source_floor_stage_y_m':float((C@actor['anchor'].matrix_world@Vector((0,0,0,1))).y),'native_floor_observations':actor['observation']['floor_observations'],'scope':'Actual skin surface, no root shift/foot-lock correction; source and runtime floor differ'})
        record={'case':case['case'],'saved_source':str(saved.relative_to(out)),'saved_source_sha256':sha(saved),'stage':stage,
                'input_sources':[{'fighter':a['fighter'],'body':a['body'],'sha256':a['source_sha256']}for a in case['actors']],
                'source_actions':[a['new_action']for a in actor_names],'source_preservation':actor_names,
                'contact_frames':contact,'saved_reopened_pose_samples':reopened,'surface_sensitivity':sensitivity,'snapshots':snapshots,'floor_observations':feet,'grip_accepted':False,'shipping_alignment_verified':False,'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False}
        if local:
            record['animated_reference']=animated_reference(actors,out/'runtime/paired_animation'/(case['case']+'.glb'))
        manifest['rows'].append(record)
        (out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
        print('SAVED_8D4_REFERENCE_STAGE',case['case'],flush=True)
    manifest['complete']=True;manifest['full_reference_batch_complete']=case_id is None
    (out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')


if __name__=='__main__':run()

"""Paired source acting on verified saved8D2 hands; all18 original rigs.

Keep the original fighter-specific 8B lower body, torso, reaction and timing.
Bake arm/hand surface contact into new, separately named editable actions.
"""
import copy,json,math,os,sys,shutil
from pathlib import Path
# Blender --python does not add the entry file directory to sys.path.
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector,Matrix
from aa_controls_8d import sha,geometry,weights,rest,actions
from aa_paired_surface_8d2 import contact_vertex,constrain_hand
from aa_directed_performance import export_runtime
ROOT=Path(__file__).resolve().parents[3]


def victim(source,collection):
    with bpy.data.libraries.load(str(source),link=False)as(data,result):
        names=[n for n in data.objects if not n.startswith(('ORIGINAL_8D_','ANI08C_','Finger ','D8_Thumb_','D8_Little_'))]
        result.objects=names
        result.actions=['ANI08B_WIP_grab_hold_victim','ANI08B_WIP_grab_hold_victim_left']
    objects={n:o for n,o in zip(names,result.objects)if o is not None}
    # The dict must use actual source identity, not Blender's collision suffix.
    arm=next(o for o in result.objects if o is not None and o.type=='ARMATURE')
    for ob in result.objects:
        if ob is None:continue
        collection.objects.link(ob);ob.name='8D2_VICTIM_'+ob.name
    anchor=bpy.data.objects.new('8D2_Paired_Victim_Root',None);collection.objects.link(anchor)
    for ob in result.objects:
        if ob is not None and ob.parent is None:ob.parent=anchor
    # Declared source-stage conversion of existing grab root offset24,-8px.
    # Runtime two-viewport projection must still be measured independently.
    units=320/2.9*.68
    anchor.matrix_world=Matrix.Translation((0,-24/units,8/units))@Matrix.Rotation(math.pi,4,'Z')
    holds={}
    for facing,action in zip([1,-1],result.actions):action.name='8D2_VICTIM_HOLD_'+str(facing);holds[facing]=action
    for t in arm.animation_data.nla_tracks:t.mute=True
    return arm,objects,holds,anchor


def finger_pose(arm,clip,frame):
    for bone in arm.pose.bones:
        if not bone.name.startswith('D8_Finger_'):continue
        path=bone.path_from_id('rotation_euler');bone.rotation_mode='XYZ'
        bone.rotation_euler=tuple(clip.fcurves.find(path,index=i).evaluate(frame)for i in range(3))


def target_meshes(objects,side,opponent):
    other='L'if side=='R'else'R'
    if opponent=='rook-ironside':
        # Bastion is the visible outer surface; gripping hidden arm skin would
        # numerically pass while clipping the armored opponent.
        found=[o for o in objects.values()if o.type=='MESH'and o.name.startswith('8D2_VICTIM_Bastion forearm')and any(g.name=='LowerArm_'+other for g in o.vertex_groups)]
        assert len(found)==1
        return found
    return [objects['Upper arm '+other],objects['Forearm '+other]]


def action_pack(arm,opponent,victims,victim_arm,holds,hands,fid,body):
    original=json.loads((ROOT/f'game-godot/data/animation/grab_acting_8b/{fid}_{body}.json').read_text())
    canonical=[b.name for b in arm.data.bones if not b.name.startswith('D8_')and b.name!='Root']
    doc=copy.deepcopy(original);doc['schema']='paired_mesh_grab_acting_8d2.v1';doc['clips']={}
    witness={h['side']:contact_vertex(arm,h)for h in hands};reports=[]
    for name,template in original['clips'].items():
        base=name.removesuffix('_left')
        if base not in ['grab_hold_attacker','grab','grab_recovery','throw_forward','throw_back','throw_up','throw_down']:continue
        old=bpy.data.actions[template['source_action']];new=old.copy();new.name='ANI08D2_PAIRED_'+name;new.use_fake_user=True
        selected=['UpperArm_'+s for s in ['L','R']]+['LowerArm_'+s for s in ['L','R']]+['Hand_'+s for s in ['L','R']]
        for curve in list(new.fcurves):
            if any(curve.data_path.startswith('pose.bones["'+n+'"]')for n in selected):new.fcurves.remove(curve)
        facing=-1 if name.endswith('_left')else 1
        total=template['duration_frames'];victim_arm.animation_data.action=holds[-facing]
        samples=[];blocked=0
        for frame in range(total+1):
            arm.animation_data.action=old;bpy.context.scene.frame_set(frame)
            # Victim loop uses its own original regional restraint, not a rigid
            # training dummy. It is paused at the release for throw follow-through.
            vf=0 if base.startswith('throw_')else frame/max(1,total)*holds[-facing].frame_range[1]
            victim_arm.animation_data.action=None
            for curve in holds[-facing].fcurves:
                if curve.data_path.startswith('pose.bones['):
                    n=curve.data_path.split('"')[1];prop=curve.data_path.split('].')[1]
                    getattr(victim_arm.pose.bones[n],prop)[curve.array_index]=curve.evaluate(vf)
            bpy.context.view_layer.update()
            start={n:arm.pose.bones[n].matrix_basis.to_quaternion()for n in selected}
            amount=1.
            if base.startswith('throw_'):amount=max(0.,1-frame/max(1,template['startup_frames']))
            elif base=='grab':
                contact=template['contact_frame'];amount=frame/max(1,contact)if frame<=contact else max(0.,(total-frame)/max(1,total-contact))
            elif base=='grab_recovery':amount=max(0.,1-2*frame/max(1,total))
            frame_report=[]
            if amount>0:
                for side in ['L','R']:
                    report=constrain_hand(arm,side,witness[side],target_meshes(victims,side,opponent));report.update(side=side,frame=frame)
                    if not report['reachable']:blocked+=1
                    frame_report.append(report)
            solved={n:arm.pose.bones[n].matrix_basis.to_quaternion()for n in selected}
            # Finite authored support-exchange fade into the original release.
            # No additional hold time or gameplay cancellation is introduced.
            arm.animation_data.action=new
            for n in selected:
                p=arm.pose.bones[n];p.rotation_mode='XYZ';p.rotation_euler=start[n].slerp(solved[n],amount).to_euler('XYZ')
                p.keyframe_insert('rotation_euler',frame=frame,group=n)
            finger= bpy.data.actions['ANI08D2_release'if base.startswith('throw_')or base=='grab_recovery'else'ANI08D2_grip']
            ff=min(float(finger.frame_range[1]),frame)if base.startswith('throw_')or base=='grab_recovery'else float(finger.frame_range[1])*amount
            finger_pose(arm,finger,ff)
            for p in arm.pose.bones:
                if p.name.startswith('D8_Finger_'):p.keyframe_insert('rotation_euler',frame=frame,group=p.name)
            if frame_report and (frame in [0,total//2,total,template.get('contact_frame',-1)]):samples.extend(frame_report)
        for curve in new.fcurves:
            for key in curve.keyframe_points:key.interpolation='LINEAR'
        clip=copy.deepcopy(template);clip['source_action']=new.name;clip['bone_tracks']={n:[]for n in canonical};clip['directed_source']='8D2_actual_victim_mesh_surface';doc['clips'][name]=clip
        reports.append({'clip':name,'source_action':new.name,'opponent':opponent,'blocked_arm_frames':blocked,'samples':samples,'lower_body_and_regional_curves':'original8B retained exactly; no root or limb-length changes','throw_release_authority':'unchanged frame0'})
    assert len(doc['clips'])==14
    return doc,reports


def verify_canonical_export(arm,fid,body,doc):
    # Independent FK from exported runtime keys back to saved source matrices.
    # Aux fingers have their own GLTF boundary; this proof owns canonical22 only.
    sys.path.insert(0,str(ROOT/'tools/v1_closure'))
    from build_combat_choreography import rig,fk,matrix
    from aa_directed_performance import transform
    import numpy as np
    skeleton,_=rig(fid,body);maximum=0.;frames=0
    for name,clip in doc['clips'].items():
        arm.animation_data.action=bpy.data.actions[clip['source_action']]
        for frame in range(clip['duration_frames']+1):
            bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
            rotations={};positions={}
            for bone,keys in clip['bone_tracks'].items():
                key=keys[frame];rotations[bone]=matrix(key['rotation_quat'])
                if 'position_m'in key:positions[bone]=np.array(key['position_m'])
            expected=fk(skeleton,rotations,positions)
            for bone in skeleton:
                target=transform(expected[bone]);actual=arm.pose.bones[bone].matrix
                maximum=max(maximum,max(abs(actual[i][j]-target[i][j])for i in range(4)for j in range(4)))
            frames+=1
    assert maximum<.0002,('Saved paired pose differs from runtime FK',fid,body,maximum)
    return {'PASS':True,'frames_evaluated':frames,'max_matrix_component_error':maximum,'scope':'Saved/reopened canonical22 source versus exported runtime FK; no visual/human acceptance'}


def export_glb(arm,objects,doc,out):
    keep={c['source_action']for c in doc['clips'].values()}
    for t in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(t)
    arm.animation_data.action=None
    for a in list(bpy.data.actions):
        if a.name not in keep:bpy.data.actions.remove(a,do_unlink=True)
    for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(0);bpy.context.view_layer.update();bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
    for name in objects:
        o=bpy.data.objects[name]
        if o.type=='MESH'and not o.name.startswith(('ANI08C_','ORIGINAL_8D_'))and not o.get('8d2_legacy_only',False):o.hide_set(False);o.select_set(True)
    resource=out/'runtime/game-godot'/doc['resource'].removeprefix('res://');resource.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(resource),export_format='GLB',use_selection=True,export_animations=True,export_force_sampling=True,export_skins=True,export_morph=True,export_yup=True)
    return resource


def run():
    assert os.environ.get('GITHUB_ACTIONS')=='true'and sys.platform=='linux'and (4,0)<=bpy.app.version[:2]<(4,4)
    args=sys.argv[sys.argv.index('--')+1:];inputs=Path(args[args.index('--input')+1]);out=Path(args[args.index('--output')+1]);out.mkdir(parents=True,exist_ok=False)
    assert shutil.disk_usage(out).free>8*1024**3
    prior=json.loads((inputs/'runtime/PRODUCTION_MANIFEST.json').read_text());assert prior['schema']=='original_hand_anatomy_production_8d2.v1'and prior['complete']and not prior['human_approved']
    manifest=copy.deepcopy(prior);manifest.update(source_sha=os.environ['GITHUB_SHA'],run_id=os.environ['GITHUB_RUN_ID'],hand_anatomy_input_run=prior['run_id'],schema='paired_hand_production_8d2.v1',rows=[],complete=False)
    ids=list(dict.fromkeys(r['fighter']for r in prior['rows']));lookup={(r['fighter'],r['body']):r for r in prior['rows']}
    for row in prior['rows']:
        fid=row['fighter'];body=row['body'];opponent=ids[(ids.index(fid)+1)%9];input_file=inputs/row['saved_source'];assert sha(input_file)==row['saved_source_sha256']
        bpy.ops.wm.open_mainfile(filepath=str(input_file));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');arm_name=arm.name
        original_objects={o.name for o in bpy.data.objects};geom=geometry(original_objects);skin=weights(original_objects);bones=rest(arm,[b.name for b in arm.data.bones]);old_names={a.name for a in bpy.data.actions};old_curves=actions(old_names)
        for t in arm.animation_data.nla_tracks:t.mute=True
        collection=bpy.data.collections.new('8D2_Actual_Victim_Mesh_Review');bpy.context.scene.collection.children.link(collection)
        other=lookup[opponent,body];vf=inputs/other['saved_source'];assert sha(vf)==other['saved_source_sha256']
        v_arm,v_objects,holds,anchor=victim(vf,collection)
        doc,reports=action_pack(arm,opponent,v_objects,v_arm,holds,row['hands'],fid,body)
        assert geometry(original_objects)==geom and weights(original_objects)==skin and rest(arm,[b.name for b in arm.data.bones])==bones and actions(old_names)==old_curves
        arm.animation_data.action=bpy.data.actions['ANI08D2_PAIRED_grab_hold_attacker'];v_arm.animation_data.action=holds[-1];bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
        saved=out/f'saved_sources/{fid}/{body}/candidate_paired_hands_8d2.blend';saved.parent.mkdir(parents=True,exist_ok=True)
        bpy.context.scene['8D2_review_scope']='Actual editable paired source meshes; not runtime contact, earned play, floor or human approval'
        bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(saved));bpy.ops.wm.open_mainfile(filepath=str(saved));arm=bpy.data.objects[arm_name]
        assert geometry(original_objects)==geom and weights(original_objects)==skin and actions(old_names)==old_curves and rest(arm,[b.name for b in arm.data.bones])==bones
        doc=export_runtime(arm,fid,body,doc);verification=verify_canonical_export(arm,fid,body,doc)
        for clip in doc['clips'].values():clip['source_blend']=str(saved.relative_to(out));clip['source_blend_sha256']=sha(saved)
        doc.update(source_actions_saved=True,source_runtime_verified=True,source_base_blend_sha256=row['saved_source_sha256'],source_saved_blend_sha256=sha(saved),human_approved=False,paired_opponent=opponent,fixture_only=False)
        data=out/f'runtime/game-godot/data/animation/paired_grip_8d2/{fid}_{body}.json';data.parent.mkdir(parents=True,exist_ok=True);data.write_text(json.dumps(doc,separators=(',',':'))+'\n')
        hand_doc=json.loads((inputs/'runtime'/row['runtime']).read_text());hand_doc['source_sha256']=sha(saved)
        resource=export_glb(arm,original_objects,hand_doc,out);hand_doc['resource_sha256']=sha(resource)
        hd=out/'runtime'/row['runtime'];hd.parent.mkdir(parents=True,exist_ok=True);hd.write_text(json.dumps(hand_doc,separators=(',',':'))+'\n')
        record=copy.deepcopy(row);record.update(saved_source=str(saved.relative_to(out)),saved_source_sha256=sha(saved),input_hands_sha256=row['saved_source_sha256'],input_victim_sha256=other['saved_source_sha256'],resource_sha256=sha(resource),runtime_sha256=sha(hd),paired_runtime=str(data.relative_to(out/'runtime')),paired_runtime_sha256=sha(data),paired_reports=reports,paired_opponent=opponent,new_paired_actions=[c['source_action']for c in doc['clips'].values()],source_stage='PAIRED_SOURCE_NATIVE_CONTACT_PENDING',all_geometry_weights_rest_preserved=True,all_previous_curves_preserved=True,source_runtime_verification=verification)
        manifest['rows'].append(record);(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n');print('PAIRED_SOURCE_SAVED',fid,body,flush=True)
    manifest['complete']=True;(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':run()

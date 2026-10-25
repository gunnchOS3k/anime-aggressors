"""Correct folded original8D2 hand surfaces on the exact saved18 candidates.

Reuse original dimensions, all bones/rest/weights outside the palms, cuffs,
materials and every prior action. No BASE/8D regeneration or new acting claims.
"""
import json,os,sys,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Matrix,Vector
from aa_controls_8d import sha,geometry,weights,rest,actions,deformed_points
from aa_hand_anatomy_8d2 import build_hand,fingerprint
ROOT=Path(__file__).resolve().parents[3]


def run():
    assert os.environ.get('GITHUB_ACTIONS')=='true'and sys.platform=='linux'and (4,0)<=bpy.app.version[:2]<(4,4)
    args=sys.argv[sys.argv.index('--')+1:];inputs=Path(args[args.index('--input')+1]);out=Path(args[args.index('--output')+1]);out.mkdir(parents=True,exist_ok=False)
    assert shutil.disk_usage(out).free>6*1024**3
    prior=json.loads((inputs/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert prior['source_sha']=='195194c70cdd70f3930eb5d5082e1cfc159730e5'and int(prior['run_id'])==39882654215 and prior['complete']and len(prior['rows'])==18
    score=json.loads((ROOT/'art_source/animation/hands_8d2/score_v1.json').read_text())
    manifest={**prior,'source_sha':os.environ['GITHUB_SHA'],'run_id':os.environ['GITHUB_RUN_ID'],'surface_input_run':39882654215,'input_classification':'EXACT_SAVED_CHECKPOINT_WITH_KNOWN_ROOT_FOLD','blender_version':bpy.app.version_string,'created_actions_this_run':0,'rows':[],'complete':False}
    for row in prior['rows']:
        fid=row['fighter'];body=row['body'];src=inputs/row['saved_source'];assert sha(src)==row['saved_source_sha256']
        hd=inputs/'runtime'/row['runtime'];assert sha(hd)==row['runtime_sha256'];doc=json.loads(hd.read_text());assert sha(inputs/'runtime'/row['resource'])==row['resource_sha256']
        bpy.ops.wm.open_mainfile(filepath=str(src));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        original_objects={o.name for o in bpy.data.objects};immutable=original_objects-{'Palm L','Palm R'};geom=geometry(immutable);skin=weights(immutable);bone_names=[b.name for b in arm.data.bones];bones=rest(arm,bone_names);old_names={a.name for a in bpy.data.actions};curves=actions(old_names)
        object_geometry={n:geometry({n})for n in immutable if bpy.data.objects[n].type=='MESH'}
        object_matrices={n:[list(v)for v in bpy.data.objects[n].matrix_local]for n in object_geometry}
        def preserved(stage):
            checks={'geometry':geometry(immutable)==geom,'weights':weights(immutable)==skin,'all_bone_rest':rest(arm,bone_names)==bones,'all_action_curves':actions(old_names)==curves}
            if not all(checks.values()):
                failure={'fighter':fid,'body':body,'stage':stage,'checks':checks,'changed_geometry':[{'mesh':n,'matrix_before':object_matrices[n],'matrix_now':[list(v)for v in bpy.data.objects[n].matrix_local]}for n,h in object_geometry.items()if geometry({n})!=h]}
                diagnostic=out/'runtime/SOURCE_PRESERVATION_FAILURE.json';diagnostic.parent.mkdir(parents=True,exist_ok=True);diagnostic.write_text(json.dumps(failure,indent=2)+'\n')
                raise AssertionError(('Exact source preservation failed',failure))
        assert len([n for n in old_names if n.startswith('ANI08D2_')])==5
        old_action=arm.animation_data.action;frame=bpy.context.scene.frame_current;muted=[t.mute for t in arm.animation_data.nla_tracks]
        for t in arm.animation_data.nla_tracks:t.mute=True
        archive=bpy.data.collections.new('8D2_Protected_First_Surface');bpy.context.scene.collection.children.link(archive);archive.hide_render=True
        dimensions={h['side']:h for h in row['hands']}
        hands=[build_hand(arm,s,score['fighters'][fid],archive,dimensions[s])for s in ['L','R']]
        preserved('after_surface_edit_before_deformation_sample')
        # No edit mode/rest fitting, no cuff cut and no new action generation.
        for h in hands:
            for key in ['width_m','distal_envelope_m','depth_m']:assert h[key]==dimensions[h['side']][key]
        pose_before={p.name:p.matrix_basis.copy()for p in arm.pose.bones}
        arm.animation_data.action=bpy.data.actions[doc['clips']['fist']['source_action']]
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update();before=deformed_points(arm,['Palm L','Palm R'])
        bpy.context.scene.frame_set(doc['clips']['fist']['frames']);bpy.context.view_layer.update();after=deformed_points(arm,['Palm L','Palm R'])
        displacement=max((Vector(a)-Vector(b)).length for a,b in zip(before,after));assert displacement>.005
        arm.animation_data.action=old_action
        for t,value in zip(arm.animation_data.nla_tracks,muted):t.mute=value
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        # An old action need not key every new finger/secondary channel. Restore
        # the exact original pose after the disposable deformation measurement.
        for name,value in pose_before.items():arm.pose.bones[name].matrix_basis=value
        bpy.context.view_layer.update();preserved('after_deformation_sample_restored')
        for h in hands:
            for part in h['source_parts']:assert fingerprint(bpy.data.objects[part['backup']])==part['before_sha256']
        saved=out/row['saved_source'];saved.parent.mkdir(parents=True,exist_ok=True);bpy.context.preferences.filepaths.save_version=0
        bpy.ops.wm.save_as_mainfile(filepath=str(saved));bpy.ops.wm.open_mainfile(filepath=str(saved));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        preserved('saved_and_reopened')
        keep={c['source_action']for c in doc['clips'].values()}
        for t in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(t)
        arm.animation_data.action=None
        for a in list(bpy.data.actions):
            if a.name not in keep:bpy.data.actions.remove(a,do_unlink=True)
        for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4)
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update();bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
        for ob in bpy.data.objects:
            if ob.type=='MESH'and ob.name in original_objects and not ob.name.startswith(('ANI08C_','ORIGINAL_8D_'))and not ob.get('8d2_legacy_only',False):ob.hide_set(False);ob.select_set(True)
        resource=out/'runtime'/row['resource'];resource.parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=str(resource),export_format='GLB',use_selection=True,export_animations=True,export_force_sampling=True,export_skins=True,export_morph=True,export_yup=True)
        doc.update(source_sha256=sha(saved),resource_sha256=sha(resource),surface_input_sha256=row['saved_source_sha256'])
        data=out/'runtime'/row['runtime'];data.parent.mkdir(parents=True,exist_ok=True);data.write_text(json.dumps(doc,separators=(',',':'))+'\n')
        record={**row,'saved_source_sha256':sha(saved),'surface_input_sha256':row['saved_source_sha256'],'resource_sha256':sha(resource),'runtime_sha256':sha(data),'hands':hands,'surface_only_repair':True,'all_bone_rest_preserved_exactly':True,'inherited_8d2_actions':5,'created_actions_this_run':0,'preserved_actions':len(old_names),'old_action_curves_sha256':curves,'finger_rest_changed_this_increment':False,'all_previous_action_curves_sha256':curves,'max_actual_fist_mesh_motion_m':displacement,'changed_cuffs_this_run':[],'human_approved':False}
        manifest['rows'].append(record);(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n');print('SAVED_HAND_SURFACE_REPAIR',fid,body,flush=True)
    manifest['complete']=True;(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':run()

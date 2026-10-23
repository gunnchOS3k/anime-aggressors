"""Remote original anatomy pass on exact saved8D candidates, never BASE rebuild."""
import json,os,sys,shutil
from pathlib import Path
# Blender --python does not add the entry file directory to sys.path.
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Matrix
from aa_controls_8d import sha,geometry,weights,rest,actions,edit_roundtrip_reference,deformed_points
from aa_hand_anatomy_8d2 import build_hand,fit_controls,correct_cuffs,author_hands,fingerprint
ROOT=Path(__file__).resolve().parents[3]


def run():
    assert os.environ.get('GITHUB_ACTIONS')=='true'and sys.platform=='linux'
    assert (4,0)<=bpy.app.version[:2]<(4,4)
    args=sys.argv[sys.argv.index('--')+1:];inputs=Path(args[args.index('--input')+1]);out=Path(args[args.index('--output')+1]);out.mkdir(parents=True,exist_ok=False)
    assert shutil.disk_usage(out).free>6*1024**3
    prior=json.loads((ROOT/'artifacts/v1_closure/production_8d/controls_remote_39852459469/PRODUCTION_MANIFEST.json').read_text())
    score=json.loads((ROOT/'art_source/animation/hands_8d2/score_v1.json').read_text())
    manifest={'schema':'original_hand_anatomy_production_8d2.v1','source_sha':os.environ['GITHUB_SHA'],'run_id':os.environ['GITHUB_RUN_ID'],'input_run':39852459469,'blender_version':bpy.app.version_string,'rows':[],'complete':False,'human_approved':False}
    for row in prior['rows']:
        fid=row['fighter'];body=row['body'];src=inputs/row['saved_source'];assert sha(src)==row['saved_source_sha256']
        bpy.ops.wm.open_mainfile(filepath=str(src));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        canonical=[b.name for b in arm.data.bones if not b.name.startswith('D8_')];assert len(canonical)==22
        original_objects={o.name for o in bpy.data.objects};old_actions={a.name for a in bpy.data.actions};old_curves=actions(old_actions)
        assert sum(n.startswith('ANI08B_WIP_')for n in old_actions)==30 and sum(n.startswith('ANI08C_WIP_')for n in old_actions)==8 and sum(n.startswith('ANI08D_WIP_')for n in old_actions)==4
        mutable={'Palm L','Palm R'}|{o.name for o in bpy.data.objects if fid=='rook-ironside'and o.name.startswith('Bastion forearm')}
        immutable=original_objects-mutable;original_geometry=geometry(immutable);original_weights=weights(immutable)
        preserved_bones=[b.name for b in arm.data.bones if not b.name.startswith('D8_Finger_')];roundtrip=edit_roundtrip_reference(arm,preserved_bones)
        original_rest=rest(arm,[b.name for b in arm.data.bones]);previous=arm.animation_data.action;frame=bpy.context.scene.frame_current;nla=[t.mute for t in arm.animation_data.nla_tracks]
        for t in arm.animation_data.nla_tracks:t.mute=True
        archive=bpy.data.collections.new('8D2_Protected_Before_Hands');bpy.context.scene.collection.children.link(archive);archive.hide_render=True
        hands=[build_hand(arm,s,score['fighters'][fid],archive)for s in ['L','R']]
        fit_controls(arm,hands);cuffs=correct_cuffs(arm,fid);clips=author_hands(arm,hands,score['fighters'][fid])
        # Real evaluated connected surface change, not just named finger bones.
        arm.animation_data.action=bpy.data.actions[clips['fist']['source_action']]
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update();before=deformed_points(arm,['Palm L','Palm R'])
        bpy.context.scene.frame_set(clips['fist']['frames']);bpy.context.view_layer.update();after=deformed_points(arm,['Palm L','Palm R'])
        from mathutils import Vector
        displacement=max((Vector(a)-Vector(b)).length for a,b in zip(before,after));assert displacement>.005
        arm.animation_data.action=previous
        for t,value in zip(arm.animation_data.nla_tracks,nla):t.mute=value
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        assert geometry(immutable)==original_geometry and weights(immutable)==original_weights,'Non-hand source changed'
        assert rest(arm,preserved_bones)==roundtrip,'Canonical/secondary rest differs from unmodified edit control'
        assert actions(old_actions)==old_curves,'Old action library changed'
        for hand in hands:
            for part in hand['source_parts']:assert fingerprint(bpy.data.objects[part['backup']])==part['before_sha256']
        saved=out/f'saved_sources/{fid}/{body}/candidate_hands_8d2.blend';saved.parent.mkdir(parents=True,exist_ok=True)
        bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(saved));bpy.ops.wm.open_mainfile(filepath=str(saved));arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        assert geometry(immutable)==original_geometry and weights(immutable)==original_weights and actions(old_actions)==old_curves and rest(arm,preserved_bones)==roundtrip
        aux_names={c['source_action']for c in clips.values()}
        for t in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(t)
        arm.animation_data.action=None
        for a in list(bpy.data.actions):
            if a.name not in aux_names:bpy.data.actions.remove(a,do_unlink=True)
        for p in arm.pose.bones:p.matrix_basis=Matrix.Identity(4)
        bpy.context.scene.frame_set(0);bpy.context.view_layer.update();bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
        for o in bpy.data.objects:
            if o.type=='MESH'and o.name in original_objects and not o.name.startswith('ANI08C_')and not o.get('8d2_legacy_only',False):o.hide_set(False);o.select_set(True)
        resource=out/f'runtime/game-godot/assets/characters/hands_8d2/{fid}/{body}/BASE.glb';resource.parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=str(resource),export_format='GLB',use_selection=True,export_animations=True,export_force_sampling=True,export_skins=True,export_morph=True,export_yup=True)
        chains=[c for h in hands for c in h['chains']]
        secondary=[b.name for b in arm.data.bones if b.name.startswith('D8_')and not b.name.startswith('D8_Finger_')]
        for name in secondary:chains.append({'kind':'secondary','bones':[name],'source_preserved':True})
        doc={'schema':'saved_original_hands_8d2.v1','fighter':fid,'body':body,'source_sha256':sha(saved),'input_8d_sha256':row['saved_source_sha256'],'resource':'res://'+str(resource.relative_to(out/'runtime/game-godot')),'resource_sha256':sha(resource),'canonical_bones':canonical,'chains':chains,'clips':clips,'expected_finger_joints':28,'human_approved':False,'art_quality_pass':False}
        data=out/f'runtime/game-godot/data/animation/hands_8d2/{fid}_{body}.json';data.parent.mkdir(parents=True,exist_ok=True);data.write_text(json.dumps(doc,separators=(',',':'))+'\n')
        record={'fighter':fid,'body':body,'saved_source':str(saved.relative_to(out)),'saved_source_sha256':sha(saved),'input_8d_sha256':row['saved_source_sha256'],'resource':str(resource.relative_to(out/'runtime')),'resource_sha256':sha(resource),'runtime':str(data.relative_to(out/'runtime')),'runtime_sha256':sha(data),'preserved_actions':len(old_actions),'preserved_8b':30,'preserved_8c':8,'preserved_8d':4,'old_action_curves_sha256':old_curves,'new_actions':[c['source_action']for c in clips.values()],'original_nonhand_geometry_sha256':original_geometry,'original_nonhand_weights_sha256':original_weights,'preserved_rest_noop_sha256':roundtrip,'input_rest_sha256':original_rest,'finger_rest_changed':True,'canonical22_unchanged':True,'hands':hands,'changed_cuffs':cuffs,'max_actual_fist_mesh_motion_m':displacement,'source_stage':'ANATOMY_ONLY_PAIRED_CONTACT_NEXT','human_approved':False}
        manifest['rows'].append(record);(out/'runtime').mkdir(exist_ok=True);(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n');print('SAVED_ORIGINAL_HAND_8D2',fid,body,flush=True)
    manifest['complete']=True;(out/'runtime/PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':run()

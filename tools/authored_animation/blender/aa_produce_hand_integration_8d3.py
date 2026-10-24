"""Versioned editable source production; existing compatible remote Blender only."""
import copy
import json
import os
import shutil
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Matrix, Vector
from aa_controls_8d import sha, geometry, weights, rest, actions, deformed_points
from aa_hand_anatomy_8d2 import fingerprint
from aa_hand_integration_8d3 import sculpt_palm, forearm_interface, author_auxiliary
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT/'tools/authored_animation'))
from projection_contact_8d3 import ledger_report, SOURCE_RUN, SOURCE_SHA


def main():
    assert os.environ.get('GITHUB_ACTIONS') == 'true' and sys.platform == 'linux'
    assert (4, 0) <= bpy.app.version[:2] < (4, 4), 'Use verified compatible Blender, never downgrade protected sources'
    args = sys.argv[sys.argv.index('--')+1:]
    inputs = Path(args[args.index('--input')+1]); out = Path(args[args.index('--output')+1])
    assert not out.exists() and shutil.disk_usage(out.parent).free > 8*1024**3
    prior = json.loads((inputs/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert prior['source_sha'] == SOURCE_SHA and int(prior['run_id']) == SOURCE_RUN
    retained = json.loads((ROOT/'artifacts/v1_closure/production_8d/hands_remote_39886629245/PRODUCTION_MANIFEST.json').read_text())
    assert prior == retained, 'Downloaded manifest differs from verified corrected source'
    ledger = json.loads((ROOT/'artifacts/v1_closure/production_8d/hands_engine_39887494881/PUBLIC_CASE_LEDGER.json').read_text())
    readiness = ledger_report(ledger, prior)
    score_path = ROOT/'art_source/animation/hands_8d3/score_v1.json'
    score = json.loads(score_path.read_text()); assert not score['human_approved']
    assert len(score['fighters']) == 9
    out.mkdir(); runtime = out/'runtime'; runtime.mkdir()
    (runtime/'PAIRED_PROJECTION_READINESS.json').write_text(json.dumps(readiness, indent=2)+'\n')
    manifest = {'schema': 'hand_interface_production_8d3.v1', 'source_sha': os.environ['GITHUB_SHA'],
                'run_id': os.environ['GITHUB_RUN_ID'], 'input_run': SOURCE_RUN, 'input_sha': SOURCE_SHA,
                'blender_version': bpy.app.version_string, 'score_sha256': sha(score_path), 'rows': [],
                'complete': False, 'paired_3d_verified': False, 'human_approved': False}
    def checkpoint():
        (runtime/'PRODUCTION_MANIFEST.json').write_text(json.dumps(manifest, indent=2)+'\n')
    checkpoint()
    for row in prior['rows']:
        fid, body = row['fighter'], row['body']; profile = score['fighters'][fid]
        for reference, expected in profile['references'].items():
            assert sha(ROOT/reference) == expected, ('Source art authority changed', reference)
        src = inputs/row['saved_source']; assert sha(src) == row['saved_source_sha256']
        doc_path = inputs/'runtime'/row['runtime']; asset = inputs/'runtime'/row['resource']
        assert sha(doc_path) == row['runtime_sha256'] and sha(asset) == row['resource_sha256']
        doc = json.loads(doc_path.read_text()); assert doc['source_sha256'] == sha(src)
        bpy.ops.wm.open_mainfile(filepath=str(src))
        arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE'); arm_name = arm.name
        original = {o.name for o in bpy.data.objects}; old_actions = {a.name for a in bpy.data.actions}
        old_curves = actions(old_actions); bone_names = [b.name for b in arm.data.bones]; original_rest = rest(arm, bone_names)
        assert [sum(n.startswith(prefix) for n in old_actions) for prefix in ('ANI08B_WIP_', 'ANI08C_WIP_', 'ANI08D_WIP_', 'ANI08D2_')] == [30, 8, 4, 5]
        mutable = {'Palm L', 'Palm R', 'Forearm L', 'Forearm R'}
        if fid == 'rook-ironside':
            mutable |= {n for n in original if n.startswith('Bastion forearm')}
            assert len(mutable) == 6
        assert mutable <= original
        immutable = original-mutable; geom = geometry(immutable); skin = weights(immutable)
        local_matrices = {n: [list(v) for v in bpy.data.objects[n].matrix_local] for n in original}
        source_topology = {n: [list(p.vertices) for p in bpy.data.objects[n].data.polygons] for n in mutable}
        source_materials = {n: [m.name if m else None for m in bpy.data.objects[n].data.materials] for n in mutable}
        def preserved(stage):
            checks = {'immutable_geometry': geometry(immutable) == geom, 'immutable_weights': weights(immutable) == skin,
                      'all_original_actions': actions(old_actions) == old_curves,
                      'all_rest_bones': [b.name for b in arm.data.bones] == bone_names and rest(arm, bone_names) == original_rest,
                      'all_object_transforms': all([list(v) for v in bpy.data.objects[n].matrix_local] == x for n, x in local_matrices.items()),
                      'edited_topology': all([list(p.vertices) for p in bpy.data.objects[n].data.polygons] == x for n, x in source_topology.items()),
                      'edited_materials': all([m.name if m else None for m in bpy.data.objects[n].data.materials] == x for n, x in source_materials.items())}
            if not all(checks.values()):
                failure = {'fighter': fid, 'body': body, 'stage': stage, 'checks': checks}
                (runtime/'SOURCE_PRESERVATION_FAILURE.json').write_text(json.dumps(failure, indent=2)+'\n')
                raise AssertionError(failure)
            return checks
        for track in arm.animation_data.nla_tracks: track.mute = True
        archive = bpy.data.collections.new('8D3_Protected_Original_Interfaces'); bpy.context.scene.collection.children.link(archive)
        archive.hide_render = True
        edits = []
        for hand in row['hands']:
            edits.append(sculpt_palm(arm, hand, profile, archive))
            edits.append(forearm_interface(arm, hand, profile, archive))
            if fid == 'rook-ironside': edits.append(forearm_interface(arm, hand, profile, archive, armor=True))
        clips = author_auxiliary(arm, doc, profile)
        preserved('edited_source')
        for edit in edits:
            assert fingerprint(bpy.data.objects[edit['before']['backup']]) == edit['before']['before_sha256']
        # Real weighted deformation; retain before/after numerical witnesses.
        arm.animation_data.action = bpy.data.actions[clips['fist']['source_action']]
        bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
        opened = deformed_points(arm, ['Palm L', 'Palm R'])
        bpy.context.scene.frame_set(clips['fist']['frames']); bpy.context.view_layer.update()
        closed = deformed_points(arm, ['Palm L', 'Palm R'])
        motion = max((Vector(a)-Vector(b)).length for a, b in zip(opened, closed)); assert motion > .005
        saved = out/f'saved_sources/{fid}/{body}/candidate_hand_interface_8d3.blend'; saved.parent.mkdir(parents=True)
        bpy.context.scene['8D3_scope'] = 'Editable source wrist/palm/cuff and hand acting candidate; paired3D/native/human acceptance pending'
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(saved)); bpy.ops.wm.open_mainfile(filepath=str(saved)); arm = bpy.data.objects[arm_name]
        checks = preserved('saved_and_reopened')
        new_names = set(a.name for a in bpy.data.actions)-old_actions
        assert new_names == {clips[c]['source_action'] for c in ('grip', 'fist', 'release')} and len(new_names) == 3
        # Export a disposable in-memory selection AFTER the complete library is
        # saved/reopened. The editable file retains every original action.
        for track in list(arm.animation_data.nla_tracks): arm.animation_data.nla_tracks.remove(track)
        arm.animation_data.action = None
        export_names = {c['source_action'] for c in clips.values()}
        for action in list(bpy.data.actions):
            if action.name not in export_names: bpy.data.actions.remove(action, do_unlink=True)
        for bone in arm.pose.bones: bone.matrix_basis = Matrix.Identity(4)
        bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
        bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True)
        for name in original:
            ob = bpy.data.objects[name]
            if ob.type == 'MESH' and not name.startswith(('ANI08C_', 'ORIGINAL_8D_')) and not ob.get('8d2_legacy_only', False):
                ob.hide_set(False); ob.select_set(True)
        resource = runtime/f'game-godot/assets/characters/hands_8d3/{fid}/{body}/BASE.glb'; resource.parent.mkdir(parents=True)
        bpy.ops.export_scene.gltf(filepath=str(resource), export_format='GLB', use_selection=True, export_animations=True,
                                  export_force_sampling=True, export_skins=True, export_morph=True, export_yup=True)
        doc = copy.deepcopy(doc)
        doc.update(schema='saved_original_hands_8d3.v1', source_sha256=sha(saved), input_8d2_sha256=row['saved_source_sha256'],
                   resource='res://'+str(resource.relative_to(runtime/'game-godot')), resource_sha256=sha(resource), clips=clips,
                   art_quality_pass=False, paired_3d_verified=False, human_approved=False)
        data = runtime/f'game-godot/data/animation/hands_8d3/{fid}_{body}.json'; data.parent.mkdir(parents=True, exist_ok=True)
        data.write_text(json.dumps(doc, separators=(',', ':'))+'\n')
        record = {'fighter': fid, 'body': body, 'input_source_sha256': row['saved_source_sha256'],
                  'saved_source': str(saved.relative_to(out)), 'saved_source_sha256': sha(saved),
                  'runtime': str(data.relative_to(runtime)), 'runtime_sha256': sha(data),
                  'resource': str(resource.relative_to(runtime)), 'resource_sha256': sha(resource),
                  'source_preservation': checks, 'old_action_curves_sha256': old_curves, 'preserved_actions': len(old_actions),
                  'new_actions': sorted(new_names), 'edits': edits, 'max_actual_fist_mesh_motion_m': motion,
                  'source_art_intent': profile['intent'], 'paired_3d_verified': False, 'human_approved': False}
        manifest['rows'].append(record); checkpoint(); print('SAVED_HAND_INTERFACE_8D3', fid, body, flush=True)
    manifest['complete'] = True; checkpoint()


if __name__ == '__main__':
    main()

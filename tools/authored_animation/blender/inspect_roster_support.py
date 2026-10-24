"""Read all 18 original rigs; exercise authoring tools in memory. Never save.

Use Blender --background --python this_file -- --output=<small JSON receipt>.
No render, export, remesh, reweight, source save or backup deletion is performed.
"""
import hashlib
import json
import sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector
sys.path.insert(0,str(Path(__file__).parent))
from aa_support_controls import ROOT,C,install,roll_foot,replant,accessory_offset
from aa_directed_performance import digest_source,original_actions_digest

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    output=Path(next(a.split('=',1)[1] for a in sys.argv if a.startswith('--output=')))
    roster=json.loads((ROOT/'game-godot/data/fighters/roster.json').read_text())['fighters']
    ids=[x if isinstance(x,str) else x['id'] for x in roster]
    rows=[]
    for fid in ids:
        for body in ('male','female'):
            source=ROOT/f'art_source/collectible_v1/{fid}/{body}/candidate.blend'
            before_sha=sha(source)
            bpy.ops.wm.open_mainfile(filepath=str(source))
            arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
            geometry=digest_source(arm);actions=original_actions_digest()
            all_actions={a.name:len(a.fcurves) for a in bpy.data.actions}
            # Evaluate controls in a neutral source pose without changing any action.
            arm.animation_data.action=None
            for track in arm.animation_data.nla_tracks:track.mute=True
            for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
            bpy.context.view_layer.update()
            rests={b.name:b.matrix.copy() for b in arm.pose.bones}
            installed=install(arm,fid,body)
            assert digest_source(arm)==geometry and original_actions_digest()==actions
            errors=[]
            for side in ('L','R'):
                for pivot,degrees in [('ball',8.),('heel',-5.)]:
                    for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
                    bpy.context.view_layer.update()
                    # Heel roll from a fully straight leg can demand more than
                    # anatomical reach. Author the supporting knee/hip load
                    # first; do not stretch the leg or loosen the error check.
                    replant(arm,fid,body,{s:rests['Foot_'+s] for s in ('L','R')},(0,-.02,0))
                    target=roll_foot(arm,fid,body,installed,side,degrees,pivot)
                    error=max(abs(arm.pose.bones['Foot_'+side].matrix[i][j]-target[i][j]) for i in range(4) for j in range(4))
                    assert error<.0002,(fid,body,side,pivot,error)
                    errors.append(error)
            for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
            bpy.context.view_layer.update()
            targets={s:rests['Foot_'+s] for s in ('L','R')}
            replant(arm,fid,body,targets,(0,-.015,.002))
            support=max((arm.pose.bones['Foot_'+s].matrix.translation-targets[s].translation).length for s in targets)
            assert support<.0002,(fid,body,'support',support)
            # Independent rigid accessory offset then restore; not a hair-weight fix.
            for name in installed['accessories']:
                ob=bpy.data.objects[name];m=ob.matrix_world.copy()
                accessory_offset(arm,installed,name,1.0);assert ob.matrix_world!=m
                ob.matrix_world=m
            assert digest_source(arm)==geometry and original_actions_digest()==actions
            assert all_actions=={a.name:len(a.fcurves) for a in bpy.data.actions}
            assert before_sha==sha(source),'Original source file changed'
            row={'fighter':fid,'body':body,'source':str(source.relative_to(ROOT)),'source_sha256':before_sha,
                 'deform_geometry_rest_weights_sha256':geometry,'deform_bones':len(arm.data.bones),
                 'actions_preserved':len(all_actions),'original_actions_sha256':actions,
                 'controls_tested':sorted(installed['controls']),'sole_references':installed['soles'],
                 'foot_roll_max_matrix_error':max(errors),'support_exchange_error_m':support,
                 'accessory_offset_objects':installed['accessories'],'source_binary_modified':False,
                 'control_status':'IMPLEMENTED_AND_EXERCISED_IN_MEMORY; source install/save deferred',
                 'hair_weighting':'unchanged; independent deforming hair/cloth controls and export still required',
                 'VISUAL_VERIFICATION_PENDING':True,'OWNER_APPROVED':False}
            rows.append(row);print('ROSTER_SUPPORT',fid,body,'PASS',flush=True)
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps({'PASS':True,'rows':rows,'scope':'Original Blender in-memory control operations on 18 source rigs; no file/model saves or runtime/native visual acceptance'},indent=2)+'\n')

if __name__=='__main__':main()

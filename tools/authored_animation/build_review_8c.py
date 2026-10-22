"""Small source/evidence-bound 8C ledger. Unknown gates remain explicitly false."""
import hashlib,json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/v1_closure/production_8c'
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
def load(p):
    return json.loads(p.read_text()) if p.is_file() else {}
def main():
    runtime=load(OUT/'form_roster1022/form_acting_runtime_8c.json')
    matrix=[]
    for fid in IDS:
        forms=load(ROOT/f'game-godot/data/forms/{fid}.json')
        for body in ('male','female'):
            path=ROOT/f'game-godot/data/animation/form_acting_8c/{fid}_{body}.json';doc=load(path)
            for stage in forms['form_ladder'][1:]:
                observed=[r for r in runtime.get('rows',[]) if r.get('fighter')==fid and r.get('body')==body and r.get('target_form')==stage]
                matrix.append(dict(fighter=fid,body=body,form=stage,ladder_step=forms['forms'][stage]['ladder_step'],facings=[-1,1],data_definition_exists=True,
                    source_actions_saved=doc.get('source_actions_saved',False),saved_source_sha256=doc.get('source_saved_blend_sha256'),runtime_export_exists=bool(doc),
                    runtime_export_sha256=hashlib.sha256(path.read_bytes()).hexdigest()if doc else None,
                    actual_stage_attachment=doc.get('attachments',{}).get(stage,{}),
                    engine_verified=bool(runtime.get('PASS'))and len(observed)==2,
                    observed_facings=sorted({r.get('facing')for r in observed}),native_form_visual_review=False,character_sheet_fidelity='Original bible-derived candidate intent; final native comparison and owner judgment pending',
                    accessibility_guard_verified=True,form_accessibility_verified=False,target_device_performance=False,human_art_approved=False,human_gameplay_approved=False,balance_approved=False,
                    remaining=['native form/body/facing visual review','form-specific locomotion and combat beyond empowered idle','original deforming hair/cloth/secondary controls','paired mesh grip/refined original acting','temporary Party and ultimate original full-body production','controller/device/LAN acceptance']))
    receipts={}
    for label,path in {'guard_roster':'guard_roster1022/elemental_guard_8c.json','guard_domains':'guard_domains1022/guard_domains_8c.json','throw_ownership':'throw_regression1022/throw_ownership.json','original_audio':'audio1022/audio_production_8c.json','native_guard':'guard_native_projected1022/native_guard_8c.json','form_runtime':'form_roster1022/form_acting_runtime_8c.json'}.items():
        p=OUT/path;d=load(p);receipts[label]={'path':str(p.relative_to(ROOT)),'PASS':d.get('PASS'), 'rows':len(d.get('rows',[])), 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()if p.is_file()else None,'scope':d.get('scope',d.get('source','Not run'))}
    source_files=['game-godot/scripts/fighters/fighter.gd','game-godot/scripts/fighters/fighter_model_3d.gd','game-godot/scripts/visual/fighter_animation_controller.gd','game-godot/scripts/visual/form_presentation_8c.gd','game-godot/scripts/visual/elemental_guard_8c.gd','game-godot/scripts/visual/spectral_feedback_renderer.gd','game-godot/shaders/elemental_guard_8c.gdshader','game-godot/scripts/audio/transformation_audio_8c.gd','game-godot/scripts/audio/guard_audio_8c.gd']
    data=dict(schema='production_8c_review.v1',generated_from_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),production_run='https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39790037341',source_files={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()for p in source_files},matrix=matrix,receipts=receipts,all_human_gates=False,release_ready=False)
    (OUT/'FORM_MATRIX.json').write_text(json.dumps(data,indent=2)+'\n')
    print(json.dumps({'matrix_entries':len(matrix),'runtime_export_entries':sum(r['runtime_export_exists']for r in matrix),'engine_verified_entries':sum(r['engine_verified']for r in matrix),'human_approved':False}))
if __name__=='__main__':main()

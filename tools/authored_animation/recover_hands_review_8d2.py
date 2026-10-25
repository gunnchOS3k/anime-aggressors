"""Archive the exact remote hand review without installing/rendering on the Mac."""
import argparse,json,plistlib,shutil
from pathlib import Path
from recover_form_production_8c import api,sha,extract,download,ROOT,VOLUME,UUID


def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=int,required=True);p.add_argument('--runtime-sha',required=True);p.add_argument('--source-run',type=int,required=True);p.add_argument('--allow-failed',action='store_true');p.add_argument('--compact-ledger',action='store_true',help='Keep complete immutable JSON externally; commit a small source-bound case ledger');a=p.parse_args()
    run=api(f'actions/runs/{a.run}');assert run['event']=='workflow_dispatch'and run['head_sha']==a.runtime_sha and run['status']=='completed'
    assert run['conclusion']=='success'or a.allow_failed,'Inspect failed review only with explicit diagnostic flag'
    artifacts=api(f'actions/runs/{a.run}/artifacts')['artifacts']
    artifact=next(r for r in artifacts if r['name']=='hands-8d2-engine-review-'+a.runtime_sha and not r['expired']);assert artifact['size_in_bytes']<32*1024**2
    source=ROOT/f'artifacts/v1_closure/production_8d/hands_remote_{a.source_run}'
    prior=json.loads((source/'RECOVERY_RECEIPT.json').read_text());manifest=json.loads((source/'PRODUCTION_MANIFEST.json').read_text())
    assert prior['validation']['PASS']and int(manifest['run_id'])==a.source_run
    import subprocess
    volume=plistlib.loads(subprocess.check_output(['diskutil','info','-plist',str(VOLUME)]));assert volume.get('VolumeUUID')==UUID and volume.get('FilesystemType')=='apfs'and volume.get('MountPoint')==str(VOLUME)
    assert shutil.disk_usage(VOLUME).free>128*1024**2+artifact['size_in_bytes']
    dest=Path(prior['archive_root'])/f'engine_review_{a.run}'
    if (dest/'REVIEW_RECEIPT.json').exists():
        old=json.loads((dest/'REVIEW_RECEIPT.json').read_text());assert old['runtime_source_sha']==a.runtime_sha
        for row in old['images']:assert sha(Path(row['path']))==row['sha256']
        print(json.dumps({'reused_verified_receipt':str(dest/'REVIEW_RECEIPT.json'),'PASS':old['PASS']}));return
    dest.mkdir(exist_ok=False);archive=dest/f'artifact_{artifact["id"]}.zip';digest=download(artifact,archive);extract(archive,dest/'evidence',96*1024**2)
    source_result=dest/'evidence/source_controls_runtime_8d.json';comparison_result=dest/'evidence/hands_comparison_8d2.json'
    result=json.loads(source_result.read_text())if source_result.exists()else{}
    comparison=json.loads(comparison_result.read_text())if comparison_result.exists()else{}
    passed=run['conclusion']=='success'and result.get('PASS',False)and comparison.get('PASS',False)
    if passed:
        assert result['lane']=='hands_8d2'and result['native_rendered']and not result['human_approved']and not comparison['human_approved']
        expected={(r['fighter'],r['body'],f)for r in manifest['rows']for f in [1,-1]};sources={(r['fighter'],r['body']):r for r in manifest['rows']}
        assert len(result['rows'])==36 and {(r['fighter'],r['body'],r['facing'])for r in result['rows']}==expected
        assert len(comparison['rows'])==18
        for row in result['rows']:assert row['source']['source_sha256']==sources[row['fighter'],row['body']]['saved_source_sha256']
        baseline=json.loads((ROOT/'artifacts/v1_closure/production_8d/controls_remote_39852459469/PRODUCTION_MANIFEST.json').read_text());before={(r['fighter'],r['body']):r for r in baseline['rows']}
        for row in comparison['rows']:
            assert len(row['versions'])==2
            assert row['versions'][0]['source']['source_sha256']==before[row['fighter'],row['body']]['saved_source_sha256']
            assert row['versions'][1]['source']['source_sha256']==sources[row['fighter'],row['body']]['saved_source_sha256']
        grab=json.loads((dest/'evidence/grab_acting_runtime_8b.json').read_text());assert grab['PASS']and grab['complete']and len(grab['rows'])==180 and not grab['failures']
        for row in grab['rows']:
            report=row['hold']if row['kind']=='public_throw'else row['before']
            if 'holder_hand_source'in report:
                for role in ['holder','victim']:
                    actor=report[role];proof=report[role+'_hand_source']
                    assert proof['source_sha256']==sources[actor['fighter'],actor['body']]['saved_source_sha256']and not proof['human_approved']
                    assert report[role+'_projection']['projection_version']==2
        for name in ['godot.log','comparison.log','grab.log']:assert 'SCRIPT ERROR:'not in (dest/'evidence'/name).read_text()
    images=[]
    for image in sorted((dest/'evidence').glob('*.png')):
        images.append({'path':str(image),'bytes':image.stat().st_size,'sha256':sha(image),'scope':'Actual Linux Compatibility staged saved-mesh hand comparison; no ordinary play/CPU/mesh-pair/device/art approval'})
    if passed:assert len(images)==4
    out=ROOT/f'artifacts/v1_closure/production_8d/hands_engine_{a.run}';out.mkdir(exist_ok=False)
    raw_files=[]
    for name in ['source_controls_runtime_8d.json','hands_comparison_8d2.json','grab_acting_runtime_8b.json','godot.log','comparison.log','grab.log']:
        f=dest/'evidence'/name
        if f.exists():
            raw_files.append({'path':str(f),'bytes':f.stat().st_size,'sha256':sha(f)})
            if not(a.compact_ledger and name=='grab_acting_runtime_8b.json'):shutil.copy2(f,out/name)
    if a.compact_ledger:
        grab=json.loads((dest/'evidence/grab_acting_runtime_8b.json').read_text());compact=[]
        for row in grab['rows']:
            phases={}
            for name in ['hold','sustained_hold','before']:
                if name not in row:continue
                report=row[name]
                phases[name]={k:report[k]for k in ['floor_observations','holder_projection','victim_projection']}
                phases[name]['hand_arm_convex_gap_px']={s:v['nearest_arm_silhouette_gap_px']for s,v in report['actual_mesh_projection'].items()}
                phases[name]['hand_sources']={role:report.get(role+'_hand_source',{}).get('source_sha256')for role in ['holder','victim']}
            compact.append({**{k:row[k]for k in ['case','kind','fighter','body','facing','direction','damage_applications','control_return_observed','airborne_observed']if k in row},'contact_count':len(row.get('contacts',[])),'landing_observed':bool(row.get('landing')),'measurements':phases})
        (out/'PUBLIC_CASE_LEDGER.json').write_text(json.dumps({'PASS':grab['PASS'],'complete':grab['complete'],'rows':compact,'failures':grab['failures'],'raw_results':str(dest/'evidence/grab_acting_runtime_8b.json'),'raw_sha256':sha(dest/'evidence/grab_acting_runtime_8b.json'),'scope':grab['scope'],'human_approved':False},indent=2)+'\n')
    receipt={'PASS':bool(passed),'workflow_conclusion':run['conclusion'],'run_id':a.run,'run_url':run['html_url'],'runtime_source_sha':a.runtime_sha,'blender_producer_sha':manifest['source_sha'],'blender_producer_run':a.source_run,'artifact_id':artifact['id'],'archive_bytes':artifact['size_in_bytes'],'archive_sha256':digest,'archive':str(dest),'images':images,'renderer':result.get('renderer'),'native_rows':len(result.get('rows',[])),'comparison_rows':len(comparison.get('rows',[])),'source_installed_on_owner_mac':False,'ordinary_gameplay':False,'human_approved':False,'originals_deleted':False}
    receipt.update(raw_files=raw_files,compact_ledger=a.compact_ledger)
    text=json.dumps(receipt,indent=2)+'\n';(out/'REVIEW_RECEIPT.json').write_text(text);(dest/'REVIEW_RECEIPT.json').write_text(text);(VOLUME/f'00-Catalog/manifests/anime-8d2-hands-review-{a.run}.json').write_text(text);print(text)
if __name__=='__main__':main()

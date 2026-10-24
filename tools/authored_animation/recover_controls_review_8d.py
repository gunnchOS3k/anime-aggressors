"""Archive one exact-head native verification artifact; no local render/import."""
import argparse,json,plistlib,shutil,subprocess
from pathlib import Path
from recover_form_production_8c import api,sha,extract,download,ROOT,VOLUME,UUID

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=int,required=True);p.add_argument('--runtime-sha',required=True);a=p.parse_args()
    run=api(f'actions/runs/{a.run}');assert run['event']=='workflow_dispatch'and run['head_sha']==a.runtime_sha
    assert run['status']=='completed'and run['conclusion']=='success','Preserve failure separately; no failed native pass accepted'
    jobs=api(f'actions/runs/{a.run}/jobs')['jobs'];job=next(j for j in jobs if j['name']=='controls-8d-engine-review');assert job['conclusion']=='success'
    artifact=next(r for r in api(f'actions/runs/{a.run}/artifacts')['artifacts']if r['name']=='controls-8d-engine-review-'+a.runtime_sha and not r['expired'])
    assert artifact['size_in_bytes']<32*1024**2
    source=ROOT/'artifacts/v1_closure/production_8d/controls_remote_39852459469'
    prior=json.loads((source/'RECOVERY_RECEIPT.json').read_text());manifest=json.loads((source/'PRODUCTION_MANIFEST.json').read_text())
    volume=plistlib.loads(subprocess.check_output(['diskutil','info','-plist',str(VOLUME)]));assert volume.get('VolumeUUID')==UUID and volume.get('FilesystemType')=='apfs'
    dest=Path(prior['archive_root'])/f'engine_review_{a.run}';dest.mkdir(exist_ok=False)
    archive=dest/f'artifact_{artifact["id"]}.zip';digest=download(artifact,archive);extract(archive,dest/'evidence',64*1024**2)
    result=json.loads((dest/'evidence/source_controls_runtime_8d.json').read_text())
    assert result['PASS']and result['native_rendered']and not result['human_approved']and not result['failures']
    expected={(r['fighter'],r['body'],face)for r in manifest['rows']for face in [1,-1]}
    assert len(result['rows'])==36 and {(r['fighter'],r['body'],r['facing'])for r in result['rows']}==expected
    sources={(r['fighter'],r['body']):r for r in manifest['rows']}
    for row in result['rows']:
        assert row['source']['status']=='actual_saved_GLTF_tracks'
        assert row['source']['source_sha256']==sources[row['fighter'],row['body']]['saved_source_sha256']
    assert 'SCRIPT ERROR:'not in (dest/'evidence/godot.log').read_text()
    images=[]
    for body in ['male','female']:
        image=dest/f'evidence/controls_{body}_open_closed.png';assert image.stat().st_size>1000
        images.append({'body':body,'path':str(image),'bytes':image.stat().st_size,'sha256':sha(image),'scope':'Actual Linux Godot Compatibility staged hand/hair samples; no CPU/device/human art pass'})
    out=ROOT/f'artifacts/v1_closure/production_8d/controls_engine_{a.run}';out.mkdir(exist_ok=False)
    shutil.copy2(dest/'evidence/source_controls_runtime_8d.json',out/'source_controls_runtime_8d.json')
    shutil.copy2(dest/'evidence/godot.log',out/'godot.log')
    receipt={'PASS':True,'run_url':run['html_url'],'run_id':a.run,'runtime_source_sha':a.runtime_sha,'blender_producer_sha':manifest['source_sha'],'blender_producer_run':int(manifest['run_id']),'artifact_id':artifact['id'],'archive_sha256':digest,'archive_bytes':artifact['size_in_bytes'],'archive':str(dest),'rows':36,'images':images,'renderer':result['renderer'],'source_installed_on_owner_mac':False,'Mac_native_verified':False,'human_approved':False,'originals_deleted':False}
    text=json.dumps(receipt,indent=2)+'\n';(out/'REVIEW_RECEIPT.json').write_text(text);(dest/'REVIEW_RECEIPT.json').write_text(text);(VOLUME/f'00-Catalog/manifests/anime-8d-controls-review-{a.run}.json').write_text(text)
    print(text)
if __name__=='__main__':main()

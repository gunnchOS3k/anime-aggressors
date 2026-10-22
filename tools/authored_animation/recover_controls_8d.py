"""Verify remote18-rig source candidates; archive immutable copies, optional guarded install.

No local Blender/export, no original deletion, no active worktree/source relocation.
Archive-only is safe when internal heavy-operation reserve is unavailable.
"""
import argparse,datetime,json,plistlib,shutil,subprocess
from pathlib import Path
from recover_form_production_8c import api,sha,extract,download,ROOT,UUID,VOLUME
from validate_controls_8d import validate
GIB=1024**3
FORECAST=800*1024**2  # ZIP+expanded+installed+Godot import margin, bounded below.

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=int,required=True);p.add_argument('--source-sha',required=True);p.add_argument('--install',action='store_true');a=p.parse_args()
    run=api(f'actions/runs/{a.run}');jobs=api(f'actions/runs/{a.run}/jobs')['jobs']
    assert run['head_sha']==a.source_sha and run['event']=='workflow_dispatch'
    assert run['status']=='completed'and run['conclusion']=='success','No unfinished/failed source run accepted'
    job=next(j for j in jobs if j['name']=='controls-8d')
    assert job['status']=='completed'and job['conclusion']=='success'
    assert all(j['status']=='completed'and j['conclusion']in ['success','skipped']for j in jobs)
    named={r['name']:r for r in api(f'actions/runs/{a.run}/artifacts')['artifacts']if not r['expired']}
    source=named['controls-8d-saved-sources-'+a.source_sha];runtime=named['controls-8d-runtime-'+a.source_sha]
    assert runtime['size_in_bytes']<=128*1024**2
    volume=plistlib.loads(subprocess.check_output(['diskutil','info','-plist',str(VOLUME)]))
    assert volume.get('VolumeUUID')==UUID and volume.get('FilesystemType')=='apfs'and volume.get('MountPoint')==str(VOLUME)
    internal=shutil.disk_usage(ROOT).free
    if a.install:assert internal-FORECAST>=18*GIB,'18GiB AFTER forecast reserve unmet; use archive-only'
    assert shutil.disk_usage(VOLUME).free>4*GIB+source['size_in_bytes']+runtime['size_in_bytes']
    out=ROOT/f'artifacts/v1_closure/production_8d/controls_remote_{a.run}';out.mkdir(exist_ok=True)
    snapshot=VOLUME/f'10-Anime-Aggressors/art-source-snapshots/2026-10-22_8d_controls_{a.source_sha[:8]}_{a.run}'
    if (snapshot/'DURABLE_SOURCE_RECEIPT.json').exists():
        previous=json.loads((snapshot/'DURABLE_SOURCE_RECEIPT.json').read_text())
        assert previous['production_source_sha']==a.source_sha
        for r in previous['source_rows']:assert sha(Path(r['path']))==r['sha256']
        source_hash=previous['source_archive_sha256'];runtime_hash=previous['runtime_archive_sha256']
    else:
        snapshot.mkdir(exist_ok=False)
        source_zip=snapshot/f'source_artifact_{source["id"]}.zip';source_hash=download(source,source_zip)
        extract(source_zip,snapshot/'saved_sources',1536*1024**2)
        runtime_zip=snapshot/f'runtime_artifact_{runtime["id"]}.zip';runtime_hash=download(runtime,runtime_zip)
        extract(runtime_zip,snapshot/'runtime',256*1024**2)
    m=json.loads((snapshot/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert m['source_sha']==a.source_sha and int(m['run_id'])==a.run
    checked=validate(snapshot,True)
    rows=[]
    for r in m['rows']:
        path=snapshot/r['saved_source'];assert sha(path)==r['saved_source_sha256']
        rows.append({'fighter':r['fighter'],'body':r['body'],'path':str(path),'bytes':path.stat().st_size,'sha256':sha(path),'new_actions':r['new_actions'],'original_actions_preserved':r['preserved_actions'],'new_bones':r['new_bones'],'weighted_meshes':r['modified_weight_meshes']})
    installed=[]
    if a.install:
        files=sorted(p for p in (snapshot/'runtime/game-godot').rglob('*')if p.is_file())
        assert len(files)==36 and sum(p.stat().st_size for p in files)<128*1024**2
        for path in files:
            rel=path.relative_to(snapshot/'runtime');dest=ROOT/rel
            assert dest.suffix in ['.json','.glb']and'controls_8d'in rel.parts
            if dest.exists():assert sha(dest)==sha(path),'Refuse replacement of different candidate'
            else:dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
            installed.append({'path':str(rel),'bytes':dest.stat().st_size,'sha256':sha(dest)})
        assert shutil.disk_usage(ROOT).free>=18*GIB
    shutil.copy2(snapshot/'runtime/PRODUCTION_MANIFEST.json',out/'PRODUCTION_MANIFEST.json')
    reproduction=snapshot/'reproduction_source'
    for rel in ['tools/authored_animation/blender/aa_controls_8d.py','tools/authored_animation/validate_controls_8d.py','art_source/animation/controls_8d/score_v1.json','.github/workflows/authored-animation-production.yml']:
        target=reproduction/rel;target.parent.mkdir(parents=True,exist_ok=True)
        content=subprocess.check_output(['git','show',a.source_sha+':'+rel],cwd=ROOT)
        if target.exists():assert target.read_bytes()==content
        else:target.write_bytes(content)
    log=out/'PRODUCTION.log'
    if not log.exists():
        with log.open('xb')as f:subprocess.run(['gh','run','view',str(a.run),'--repo','gunnchOS3k/anime-aggressors','--log'],stdout=f,check=True)
    shutil.copy2(log,snapshot/'PRODUCTION.log')
    receipt={'schema':'durable_controls_8d_recovery.v1','verified_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'production_run':run['html_url'],'production_source_sha':a.source_sha,'production_job':job['id'],'workflow_conclusion':run['conclusion'],'archive_root':str(snapshot),'archive_volume_uuid':UUID,'source_artifact_id':source['id'],'source_archive_bytes':source['size_in_bytes'],'source_archive_sha256':source_hash,'runtime_artifact_id':runtime['id'],'runtime_archive_bytes':runtime['size_in_bytes'],'runtime_archive_sha256':runtime_hash,'source_rows':rows,'source_bytes':sum(r['bytes']for r in rows),'validation':checked,'installed_files':installed,'internal_before_bytes':internal,'internal_after_bytes':shutil.disk_usage(ROOT).free,'install_forecast_bytes':FORECAST,'reserve_bytes':18*GIB,'native_verified':False,'human_approved':False,'originals_deleted':False}
    filename='INSTALL_RECEIPT.json'if a.install else'RECOVERY_RECEIPT.json'
    text=json.dumps(receipt,indent=2)+'\n'
    if not (snapshot/'DURABLE_SOURCE_RECEIPT.json').exists():
        (snapshot/'DURABLE_SOURCE_RECEIPT.json').write_text(text)
        (VOLUME/f'00-Catalog/manifests/anime-8d-controls-{a.run}.json').write_text(text)
    (out/filename).write_text(text)
    print(json.dumps({'PASS':True,'archive':str(snapshot),'source_rigs':18,'new_actions':72,'installed':len(installed),'source_bytes':receipt['source_bytes'],'internal_free_GiB':receipt['internal_after_bytes']/GIB}))
if __name__=='__main__':main()

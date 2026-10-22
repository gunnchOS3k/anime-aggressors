"""Recover exact successful8C artifacts, strict validate, immutable archive/install.

No Blender processing, source replacement, deletes or owner-save access. Network
and external archive writes require the existing owner authorization. A running
or failed job is deliberately not accepted as successful source production.
"""
import argparse,datetime,hashlib,json,os,plistlib,shutil,subprocess,tempfile,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
REPO='gunnchOS3k/anime-aggressors'
UUID='9C4EB36E-2864-42F8-BD0B-A4F67EBC7852'
VOLUME=Path('/Volumes/gunnchOS-Archives')
def api(path):return json.loads(subprocess.check_output(['gh','api',f'repos/{REPO}/'+path],text=True))
def sha(p):
    h=hashlib.sha256()
    with p.open('rb')as f:
        for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()
def extract(zip_path,dest,limit):
    with zipfile.ZipFile(zip_path)as z:
        assert sum(i.file_size for i in z.infolist())<=limit,'Expanded allocation cap exceeded'
        for i in z.infolist():
            p=Path(i.filename)
            assert not p.is_absolute()and '..'not in p.parts and '\\'not in i.filename and ((i.external_attr>>16)&0o170000)!=0o120000,'Unsafe zip member'
        z.extractall(dest)
def download(artifact,path):
    assert not path.exists(),'Immutable artifact already exists; inspect retained receipt'
    with path.open('xb')as f:
        child=subprocess.Popen(['gh','api',f'repos/{REPO}/actions/artifacts/{artifact["id"]}/zip'],stdout=subprocess.PIPE)
        count=0
        try:
            for block in iter(lambda:child.stdout.read(1024*1024),b''):
                count+=len(block)
                assert count<=artifact['size_in_bytes'],'Artifact stream allocation exceeded recorded size'
                f.write(block)
            assert child.wait()==0,'Artifact download failed'
        except BaseException:
            child.kill();child.wait();raise
    digest=sha(path)
    expected=artifact.get('digest','').removeprefix('sha256:')
    if expected:assert digest==expected,'GitHub archive digest mismatch'
    assert path.stat().st_size==artifact['size_in_bytes'],'Archive byte count mismatch'
    return digest

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=int,required=True);p.add_argument('--source-sha',required=True);p.add_argument('--install',action='store_true');a=p.parse_args()
    run=api(f'actions/runs/{a.run}')
    assert run['head_sha']==a.source_sha,'Unexpected production source'
    assert run['event']=='workflow_dispatch'and run['status']=='completed'and run['conclusion']=='success',f'Production not accepted: {run["status"]}/{run["conclusion"]}'
    artifacts=api(f'actions/runs/{a.run}/artifacts')['artifacts'];named={r['name']:r for r in artifacts if not r['expired']}
    runtime=named[f'form-acting-8c-runtime-{a.source_sha}'];source=named[f'form-acting-8c-saved-sources-{a.source_sha}']
    assert runtime['size_in_bytes']<=32*1024**2,'Not a bounded runtime artifact'
    volume=plistlib.loads(subprocess.check_output(['diskutil','info','-plist',str(VOLUME)]))
    assert volume.get('VolumeUUID')==UUID and volume.get('FilesystemType')=='apfs'and volume.get('MountPoint')==str(VOLUME),'Wrong archive volume'
    assert shutil.disk_usage(VOLUME).free>2*1024**3+source['size_in_bytes']*12,'Archive allocation reserve'
    # This is a bounded source/resource install, not a native/Blender export.
    # No source binary touches internal SSD. Bound text/smallGLB allocation and
    # record actual free space rather than claiming the18GiB export gate passed.
    internal_before=shutil.disk_usage(ROOT).free
    assert internal_before>256*1024**2+runtime['size_in_bytes']*3,'Bounded install allocation margin'
    out=ROOT/f'artifacts/v1_closure/production_8c/remote_{a.run}';out.mkdir(exist_ok=True)
    assert not(out/'RECOVERY_RECEIPT.json').exists(),'Already recovered; reuse the verified receipt'
    temp=Path(tempfile.mkdtemp(prefix='aa8c-runtime-'))
    runtime_zip=temp/'runtime.zip';runtime_hash=download(runtime,runtime_zip)
    extract(runtime_zip,temp/'runtime',64*1024**2)
    import sys
    sys.path.insert(0,str(ROOT/'tools/authored_animation'))
    from validate_form_acting_8c import validate
    validation=validate(temp,False)
    manifest=json.loads((temp/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert manifest['runtime_input_sha']==a.source_sha and int(manifest['remote_run_id'])==a.run
    snapshot=VOLUME/f'10-Anime-Aggressors/art-source-snapshots/2026-10-22_8c_{a.source_sha[:8]}_{a.run}'
    snapshot.mkdir(exist_ok=False)
    source_zip=snapshot/f'source_artifact_{source["id"]}.zip';source_hash=download(source,source_zip)
    extract(source_zip,snapshot/'saved_sources',1024**3)
    rows=[]
    for row in manifest['rows']:
        rel=Path(row['saved_source']);path=snapshot/rel
        assert path.is_file()and sha(path)==row['saved_source_sha256'],'Saved editable source mismatch'
        rows.append({'fighter':row['fighter'],'body':row['body'],'path':str(path),'bytes':path.stat().st_size,'sha256':row['saved_source_sha256'],'new_action_ids':row['new_saved_actions'],'preserved_8b_actions':row['preserved_8b_actions']})
    assert len(rows)==18 and sum(len(r['new_action_ids'])for r in rows)==144
    for name in ['PRODUCTION_MANIFEST.json']:
        shutil.copy2(temp/'runtime'/name,snapshot/name);shutil.copy2(temp/'runtime'/name,out/name)
    reproduction=snapshot/'reproduction_source'
    for rel in ['tools/authored_animation/blender/aa_form_acting_8c.py','tools/authored_animation/blender/aa_directed_performance.py','tools/authored_animation/build_form_acting_8c.py','tools/authored_animation/validate_form_acting_8c.py','art_source/animation/form_acting_8c/score_v1.json']:
        target=reproduction/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(subprocess.check_output(["git","show",a.source_sha+":"+rel],cwd=ROOT))
    installed=[]
    if a.install:
        for path in sorted((temp/'runtime/game-godot').rglob('*')):
            if not path.is_file():continue
            rel=path.relative_to(temp/'runtime');dest=ROOT/rel
            assert dest.suffix in ['.json','.glb']and'form_acting_8c'in str(rel),'Unexpected runtime path'
            if dest.exists():assert sha(dest)==sha(path),'Refuse to replace an existing different candidate'
            else:dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
            installed.append({'path':str(rel),'bytes':dest.stat().st_size,'sha256':sha(dest)})
        assert len(installed)==54
    receipt={'schema':'durable_8c_source_recovery.v1','verified_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'production_run':run['html_url'],'production_source_sha':a.source_sha,'archive_volume_uuid':UUID,'archive_root':str(snapshot),'source_artifact_id':source['id'],'source_archive_bytes':source['size_in_bytes'],'source_archive_sha256':source_hash,'runtime_artifact_id':runtime['id'],'runtime_archive_bytes':runtime['size_in_bytes'],'runtime_archive_sha256':runtime_hash,'runtime_temporary_root':str(temp),'source_rows':rows,'validation':validation,'installed_files':installed,'internal_free_before_bytes':internal_before,'internal_free_after_bytes':shutil.disk_usage(ROOT).free,'owner_internal_source_binary_bytes':0,'originals_deleted':False,'human_approved':False}
    text=json.dumps(receipt,indent=2)+'\n';(out/'RECOVERY_RECEIPT.json').write_text(text);(snapshot/'DURABLE_SOURCE_RECEIPT.json').write_text(text)
    catalog=VOLUME/f'00-Catalog/manifests/anime-8c-source-{a.run}.json';assert not catalog.exists();catalog.write_text(text)
    print(json.dumps({'PASS':True,'archive':str(snapshot),'new_saved_actions':144,'preserved_8b_actions':540,'rigs':18,'attachments':36,'installed':len(installed),'receipt':str(out/'RECOVERY_RECEIPT.json')}))
if __name__=='__main__':main()

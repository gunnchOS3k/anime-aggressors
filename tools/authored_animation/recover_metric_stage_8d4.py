"""Immutable archive-only recovery; never install/import binaries on the Mac.

Keep partial/failed outputs as diagnostics, never promote them to source/native
acceptance. Reuse verified archive receipts; no deletion or duplicate archives.
"""
import argparse
import datetime
import json
import plistlib
import shutil
import subprocess
from pathlib import Path
from recover_form_production_8c import api, sha, extract, download, ROOT, VOLUME, UUID
from validate_metric_stage_8d4 import validate


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', type=int, required=True)
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--allow-failed', action='store_true')
    args = parser.parse_args()
    run = api(f'actions/runs/{args.run}')
    assert run['head_sha'] == args.source_sha and run['event'] == 'workflow_dispatch'
    assert run['status'] == 'completed', 'Wait for terminal job, never accept unfinished output'
    jobs = api(f'actions/runs/{args.run}/jobs')['jobs']
    job = next(j for j in jobs if j['name'] == 'metric-stage-8d4')
    assert all(j['status'] == 'completed' for j in jobs)
    success = run['conclusion'] == 'success' and job['conclusion'] == 'success'
    assert success or args.allow_failed, 'Failed production requires explicit diagnostic recovery'
    volume = plistlib.loads(subprocess.check_output(['diskutil', 'info', '-plist', str(VOLUME)]))
    assert volume.get('VolumeUUID') == UUID and volume.get('FilesystemType') == 'apfs' and volume.get('MountPoint') == str(VOLUME)
    named = {a['name']: a for a in api(f'actions/runs/{args.run}/artifacts')['artifacts'] if not a['expired']}
    classes = {'saved_stages': ('saved-scenes', 2*1024**3), 'runtime': ('static-runtime', 256*1024**2), 'engine_review': ('engine-review', 64*1024**2)}
    artifacts = {}
    for folder, (suffix, cap) in classes.items():
        name = f'metric-stage-8d4-{suffix}-{args.source_sha}'
        if name in named:
            artifacts[folder] = (named[name], cap)
        else:
            assert not success, ('Missing successful artifact', name)
    assert shutil.disk_usage(VOLUME).free > 3*1024**3+sum(a['size_in_bytes'] for a, cap in artifacts.values())
    # External is immutable archival, not a production work directory.
    snapshot = VOLUME/f'10-Anime-Aggressors/art-source-snapshots/2026-10-23_8d4_metric_{args.source_sha[:8]}_{args.run}'
    snapshot.mkdir(exist_ok=True)
    receipt_path = snapshot/'DURABLE_SOURCE_RECEIPT.json'
    if receipt_path.exists():
        previous = json.loads(receipt_path.read_text())
        assert previous['producer_sha'] == args.source_sha and previous['run_id'] == args.run
        for row in previous['files']:
            path = Path(row['path']); assert path.stat().st_size == row['bytes'] and sha(path) == row['sha256']
        print(json.dumps({'reused_verified_receipt': str(receipt_path), 'PASS': previous['PASS']}, indent=2))
        return
    copies = []
    for folder, (artifact, cap) in artifacts.items():
        zip_path = snapshot/f'{folder}_artifact_{artifact["id"]}.zip'
        if zip_path.exists():
            assert zip_path.stat().st_size == artifact['size_in_bytes'], 'Retain partial copy; do not overwrite it'
            expected = artifact.get('digest', '').removeprefix('sha256:')
            assert expected and sha(zip_path) == expected
            archive_hash = expected
        else:
            archive_hash = download(artifact, zip_path)
        destination = snapshot/folder
        if not destination.exists(): extract(zip_path, destination, cap)
        copies.append({'artifact_id': artifact['id'], 'class': folder, 'path': str(zip_path),
                       'bytes': zip_path.stat().st_size, 'sha256': archive_hash})
    # Preserve full job logs in the same archive even on a failed source edit.
    log = snapshot/'PRODUCTION.log'
    if not log.exists():
        with log.open('xb') as stream:
            subprocess.run(['gh', 'run', 'view', str(args.run), '--repo', 'gunnchOS3k/anime-aggressors', '--log'], stdout=stream, check=True)
    validation = validate(snapshot) if success else {'PASS': False, 'scope': 'Failed job diagnostic; no acceptance'}
    native = {}
    if success:
        review = snapshot/'engine_review'
        result=json.loads((review/'metric_stage_native_8d4.json').read_text())
        manifest=json.loads((snapshot/'runtime/PRODUCTION_MANIFEST.json').read_text())
        assert result['PASS'] and len(result['rows'])==8 and result['observer_sha']==args.source_sha
        assert not result['RUNTIME_PAIRED_CONTACT_VERIFIED'] and not result['human_approved']
        assert manifest['producer_sha']==args.source_sha and int(manifest['run_id'])==args.run
        assert 'SCRIPT ERROR:'not in (review/'godot.log').read_text()
        assert len(list(review.glob('*.png')))==8
        expected={r['case']:r for r in manifest['rows']}
        for row in result['rows']:
            assert row['source_sha256']==expected[row['case']]['saved_source_sha256']and len(row['panels'])==6
            assert (review/row['sheet']).is_file()
        native={'static_imported_snapshots':24,'images':8,'views':['side','three_quarter'],
                'scope':'Static evaluated offline art surfaces, not BattleScene or gameplay',
                'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False}
    files = [{'path': str(p), 'bytes': p.stat().st_size, 'sha256': sha(p)} for p in sorted(snapshot.rglob('*')) if p.is_file()]
    receipt = {'PASS': success, 'run_id': args.run, 'producer_sha': args.source_sha,
               'run_url': run['html_url'], 'workflow_conclusion': run['conclusion'], 'archive_uuid': UUID,
               'snapshot': str(snapshot), 'recovered_at_UTC': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'internal_free_bytes': shutil.disk_usage(ROOT).free, 'external_free_bytes': shutil.disk_usage(VOLUME).free,
               'validation': validation, 'native': native, 'artifacts': copies, 'files': files,
               'installed_on_owner_Mac': False, 'originals_deleted': False, 'human_approved': False}
    receipt_path.write_text(json.dumps(receipt, indent=2)+'\n')
    catalog = VOLUME/f'00-Catalog/manifests/anime-8d4-metric-stage-{args.run}.json'
    catalog_record = {'run_id': args.run, 'producer_sha': args.source_sha, 'PASS': success,
                      'receipt': str(receipt_path), 'receipt_sha256': sha(receipt_path),
                      'source_bytes': sum(r['bytes'] for r in files if r['path'].endswith('.blend')),
                      'artifacts': copies, 'human_approved': False, 'originals_deleted': False}
    if catalog.exists():
        assert json.loads(catalog.read_text()) == catalog_record, 'Do not overwrite different archive catalog entry'
    else:
        catalog.parent.mkdir(parents=True, exist_ok=True)
        catalog.write_text(json.dumps(catalog_record, indent=2)+'\n')
    out = ROOT/f'artifacts/v1_closure/production_8d/metric_stage_remote_{args.run}'
    out.mkdir(exist_ok=True)
    # Only bounded text evidence internally. Full raw poses/media/binaries stay
    # in the verified archive, not a disposable internal temporary directory.
    for name in ('DURABLE_SOURCE_RECEIPT.json',): shutil.copy2(snapshot/name, out/name)
    if success:
        # Retain full per-frame mesh metrics only in the immutable archive.
        # Commit a compact source-bound index, not a duplicate large bundle.
        compact=[]
        for row in manifest['rows']:
            measures=[h for f in row['contact_frames']for h in f['hands']]
            compact.append({'case':row['case'],'saved_source':str(snapshot/row['saved_source']),
                            'saved_source_sha256':row['saved_source_sha256'],'actions':row['source_actions'],
                            'snapshots':[{k:s[k]for k in ['state','resource','sha256']}for s in row['snapshots']],
                            'max_pad_to_material_m':max(h['pad_to_bound_material_point_m']for h in measures),
                            'unreachable_held_hands':sum(not h['reachable']for h in measures),
                            'surface_crossings':sum(h['surface_intersections']['strict_surface_crossings']for h in measures),
                            'floor':row['floor_observations'],'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False})
        (out/'SOURCE_INDEX.json').write_text(json.dumps({'producer_sha':args.source_sha,'run_id':args.run,
            'raw_manifest':str(snapshot/'runtime/PRODUCTION_MANIFEST.json'),
            'raw_manifest_sha256':sha(snapshot/'runtime/PRODUCTION_MANIFEST.json'),'rows':compact,
            'scope':'Verified source/static import evidence; no visual, gameplay or production grip acceptance'},indent=2)+'\n')
    for source in [snapshot/'runtime/SOURCE_VALIDATION.json',snapshot/'engine_review/metric_stage_native_8d4.json']:
        if source.exists():
            assert source.stat().st_size<2*1024**2
            shutil.copy2(source,out/source.name)
    print(json.dumps({'PASS': success, 'receipt': str(receipt_path), 'native': native, 'validation': validation}, indent=2))


if __name__ == '__main__': main()

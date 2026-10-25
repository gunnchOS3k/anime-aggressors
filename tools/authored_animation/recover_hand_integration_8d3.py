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
from validate_hand_integration_8d3 import validate


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
    job = next(j for j in jobs if j['name'] == 'hand-integration-8d3')
    assert all(j['status'] == 'completed' for j in jobs)
    success = run['conclusion'] == 'success' and job['conclusion'] == 'success'
    assert success or args.allow_failed, 'Failed production requires explicit diagnostic recovery'
    volume = plistlib.loads(subprocess.check_output(['diskutil', 'info', '-plist', str(VOLUME)]))
    assert volume.get('VolumeUUID') == UUID and volume.get('FilesystemType') == 'apfs' and volume.get('MountPoint') == str(VOLUME)
    named = {a['name']: a for a in api(f'actions/runs/{args.run}/artifacts')['artifacts'] if not a['expired']}
    classes = {'saved_sources': ('saved-sources', 2*1024**3), 'runtime': ('runtime', 256*1024**2), 'engine_review': ('engine-review', 256*1024**2)}
    artifacts = {}
    for folder, (suffix, cap) in classes.items():
        name = f'hand-integration-8d3-{suffix}-{args.source_sha}'
        if name in named:
            artifacts[folder] = (named[name], cap)
        else:
            assert not success, ('Missing successful artifact', name)
    assert shutil.disk_usage(VOLUME).free > 3*1024**3+sum(a['size_in_bytes'] for a, cap in artifacts.values())
    # External is immutable archival, not a production work directory.
    snapshot = VOLUME/f'10-Anime-Aggressors/art-source-snapshots/2026-10-23_8d3_hands_{args.source_sha[:8]}_{args.run}'
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
    validation = validate(snapshot, True) if success else {'PASS': False, 'scope': 'Failed job diagnostic; no acceptance'}
    native = {}
    if success:
        review = snapshot/'engine_review'
        controls = json.loads((review/'source_controls_runtime_8d.json').read_text())
        comparison = json.loads((review/'hand_interface_comparison_8d3.json').read_text())
        public = json.loads((review/'grab_acting_runtime_8b.json').read_text())
        assert controls['PASS'] and len(controls['rows']) == 36 and controls['lane'] == 'hands_8d3'
        assert comparison['PASS'] and len(comparison['rows']) == 18
        assert public['PASS'] and public['complete'] and len(public['rows']) == 180 and not public['failures']
        assert len(list(review.glob('*.png'))) == 4
        for name in ('godot.log', 'comparison.log', 'grab.log', 'import.log'):
            assert 'SCRIPT ERROR:' not in (review/name).read_text()
        manifest = json.loads((snapshot/'runtime/PRODUCTION_MANIFEST.json').read_text())
        sources = {r['saved_source_sha256'] for r in manifest['rows']}
        assert all(r['source']['source_sha256'] in sources for r in controls['rows'])
        native = {'imports_body_facing': 36, 'staged_before_after_bodies': 18,
                  'public_throws': sum(r['kind'] == 'public_throw' for r in public['rows']),
                  'public_escapes': sum(r['kind'] != 'public_throw' for r in public['rows']),
                  'images': 4, 'ordinary_CPU': False, 'paired_3d_verified': False, 'human_approved': False}
    files = [{'path': str(p), 'bytes': p.stat().st_size, 'sha256': sha(p)} for p in sorted(snapshot.rglob('*')) if p.is_file()]
    receipt = {'PASS': success, 'run_id': args.run, 'producer_sha': args.source_sha,
               'run_url': run['html_url'], 'workflow_conclusion': run['conclusion'], 'archive_uuid': UUID,
               'snapshot': str(snapshot), 'recovered_at_UTC': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'internal_free_bytes': shutil.disk_usage(ROOT).free, 'external_free_bytes': shutil.disk_usage(VOLUME).free,
               'validation': validation, 'native': native, 'artifacts': copies, 'files': files,
               'installed_on_owner_Mac': False, 'originals_deleted': False, 'human_approved': False}
    receipt_path.write_text(json.dumps(receipt, indent=2)+'\n')
    catalog = VOLUME/f'00-Catalog/manifests/anime-8d3-hand-integration-{args.run}.json'
    catalog_record = {'run_id': args.run, 'producer_sha': args.source_sha, 'PASS': success,
                      'receipt': str(receipt_path), 'receipt_sha256': sha(receipt_path),
                      'source_bytes': sum(r['bytes'] for r in files if r['path'].endswith('.blend')),
                      'artifacts': copies, 'human_approved': False, 'originals_deleted': False}
    if catalog.exists():
        assert json.loads(catalog.read_text()) == catalog_record, 'Do not overwrite different archive catalog entry'
    else:
        catalog.parent.mkdir(parents=True, exist_ok=True)
        catalog.write_text(json.dumps(catalog_record, indent=2)+'\n')
    out = ROOT/f'artifacts/v1_closure/production_8d/hand_integration_remote_{args.run}'
    out.mkdir(exist_ok=True)
    # Only bounded text evidence internally. Full raw poses/media/binaries stay
    # in the verified archive, not a disposable internal temporary directory.
    for name in ('DURABLE_SOURCE_RECEIPT.json',): shutil.copy2(snapshot/name, out/name)
    for name in ('PRODUCTION_MANIFEST.json', 'SOURCE_VALIDATION.json', 'SOURCE_PRESERVATION_FAILURE.json', 'PAIRED_PROJECTION_READINESS.json'):
        source = snapshot/'runtime'/name
        if source.exists():
            assert source.stat().st_size < 2*1024**2
            shutil.copy2(source, out/name)
    print(json.dumps({'PASS': success, 'receipt': str(receipt_path), 'native': native, 'validation': validation}, indent=2))


if __name__ == '__main__': main()

#!/usr/bin/env python3
"""Zero-service-cost local execution of the preserved 8D-4 reference producer.

Default: read-only preflight. No downloads, installs, Actions calls, uploads,
archive writes or deletion. --execute uses only compatible existing binaries,
immutable archived inputs and a new owner-only internal working directory.
"""
import argparse
import datetime
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path
from private_production_8d4 import LOCAL_SCOPE, LOCAL_RESERVE_BYTES, LOCAL_PEAK_ALLOCATION_BYTES
from metric_reference_scope_8d4 import select_cases
from audit_blender_402 import verify_audit

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE_VOLUME = Path('/Volumes/gunnchOS-Archives')
ARCHIVE_UUID = '9C4EB36E-2864-42F8-BD0B-A4F67EBC7852'
INPUT_SOURCE_SHA = '42baaab8cc5167798aea7f3aebb22edae9f21007'


def version(binary):
    if not binary or not Path(binary).is_file():
        return None
    result = subprocess.run([str(binary), '--version'], capture_output=True, text=True, timeout=15)
    return result.stdout.splitlines()[0] if result.returncode == 0 and result.stdout else None


def preflight(archive, workspace, blender, godot, case_id, blender_audit=None):
    reasons = []
    inputs=json.loads((ROOT/'art_source/staging/metric_8d4/inputs_v1.json').read_text())
    selected=select_cases(inputs,case_id)
    archive = archive.resolve()
    workspace = workspace.resolve()
    volume = Path('/System/Volumes/Data') if Path('/System/Volumes/Data').is_dir() else ROOT
    free = shutil.disk_usage(volume).free
    if free < LOCAL_RESERVE_BYTES + LOCAL_PEAK_ALLOCATION_BYTES:
        reasons.append('Internal space must be at least22GiB:18GiB reserve plus4GiB peak forecast')
    if workspace.exists() or workspace.is_relative_to(ROOT) or workspace.is_relative_to(Path('/Volumes')):
        reasons.append('Use a NEW private internal workspace outside Git/worktrees and immutable archives')
    parent = workspace.parent
    if not parent.is_dir():
        reasons.append('Private workspace parent must already exist')
    elif subprocess.run(['git', '-C', str(parent), 'rev-parse', '--show-toplevel'], capture_output=True).returncode == 0:
        reasons.append('Private workspace cannot be inside any Git checkout')
    archive_verified = False
    if ARCHIVE_VOLUME.is_mount() and archive.is_relative_to(ARCHIVE_VOLUME):
        result = subprocess.run(['/usr/sbin/diskutil', 'info', '-plist', str(ARCHIVE_VOLUME)], capture_output=True)
        if result.returncode == 0:
            info = plistlib.loads(result.stdout)
            archive_verified = info.get('VolumeUUID') == ARCHIVE_UUID and info.get('FilesystemType') == 'apfs'
    if not archive_verified:
        reasons.append('Expected immutable APFS input archive not verified; no alternate source or download is substituted')
    manifest_path = archive / 'runtime/PRODUCTION_MANIFEST.json'
    retained = json.loads((ROOT / 'artifacts/v1_closure/production_8d/hand_integration_remote_39910149332/PRODUCTION_MANIFEST.json').read_text())
    input_matches = manifest_path.is_file() and json.loads(manifest_path.read_text()) == retained
    input_matches = input_matches and retained['source_sha'] == INPUT_SOURCE_SHA and retained['complete'] is True
    if not input_matches:
        reasons.append('Archived completed8D3 manifest is missing or differs from the retained exact source')
    producer_audit=None
    if blender_audit:
        try:producer_audit=verify_audit(blender_audit,blender)
        except (ValueError,OSError,KeyError)as error:reasons.append('Official Blender package/app audit failed: '+str(error))
    else:
        reasons.append('Official Blender package/app audit required: full manifest, DMG SHA, app identity/signature and ARM64')
    # Never execute an unaudited new producer. The existing3.3.1 version probe
    # is retained for diagnostics only; it cannot authorize production.
    bv=producer_audit['exact_version']if producer_audit else version(blender)if blender.resolve()==Path('/Applications/Blender.app/Contents/MacOS/Blender').resolve()else None
    if not re.match(r'^Blender 4\.0\.2(?:\s|$)', bv or ''):
        reasons.append('Blender4.0.2 required: exact version in the preserved8D3 source manifest;3.3 must remain untouched')
    gv = version(godot)
    if not gv or not gv.startswith('4.7.1.'):
        reasons.append('Existing verified Godot4.7.1 required for the native reference viewer')
    if os.environ.get('GITHUB_ACTIONS') == 'true':
        reasons.append('This recipe cannot run on a GitHub Actions runner')
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    scoped = ['tools/authored_animation', 'art_source/staging/metric_8d4',
              'game-godot/tests/v1_closure/MetricArtStage8D4.gd',
              'game-godot/tests/v1_closure/PairedAnimationPlayback8D4.gd']
    changed = subprocess.check_output(['git', 'diff', 'HEAD', '--name-only', '--', *scoped], cwd=ROOT, text=True).splitlines()
    untracked = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--', *scoped], cwd=ROOT, text=True).splitlines()
    if changed or untracked:
        reasons.append('Checkpoint scoped producer changes before executing; unrelated untracked evidence is preserved')
    listing = subprocess.run(['ps', '-axo', 'pid=,comm='], text=True, capture_output=True)
    active = []
    if listing.returncode != 0:
        reasons.append('Could not verify serial Blender/Godot ownership')
    else:
        for line in listing.stdout.splitlines():
            fields = line.strip().split(None, 1)
            if len(fields) == 2 and Path(fields[1]).name.lower().startswith(('blender', 'godot')):
                active.append({'pid': int(fields[0]), 'program': Path(fields[1]).name})
        if active:
            reasons.append('Existing Blender/Godot process preserved; no competing local production')
    return {'schema': 'zero_cost_local_8d4_preflight.v1', 'PASS': not reasons, 'reasons': reasons,
            'source_sha': head, 'execution_environment': 'OWNER_LOCAL_OFFLINE',
            'reference_scope':'SINGLE_CASE_PILOT','selected_cases':[c['case']for c in selected],
            'full_reference_batch_complete':False,
            'private_workspace': str(workspace), 'immutable_input_archive': str(archive),
            'archive_volume_identity_verified': archive_verified, 'archived_input_manifest_matches': input_matches,
            'internal_free_bytes': free, 'internal_free_GiB': round(free / 1024**3, 3),
            'required_reserve_bytes': LOCAL_RESERVE_BYTES, 'peak_internal_allocation_bytes': LOCAL_PEAK_ALLOCATION_BYTES,
            'additional_free_bytes_required': max(0, LOCAL_RESERVE_BYTES + LOCAL_PEAK_ALLOCATION_BYTES - free),
            'blender_version': bv, 'godot_version': gv, 'active_media_processes': active,
            'official_blender_package_verified':producer_audit is not None,
            'blender_audit_path':str(blender_audit.resolve())if blender_audit else None,
            'network_services_used': False, 'paid_usage_authorized': False,
            'github_dispatch_authorized': False, 'public_upload_authorized': False}


def execute(report, archive, workspace, blender, godot):
    if not report['PASS']:
        raise ValueError('Preflight failed; no private workspace or production output created')
    os.umask(0o077)
    workspace.mkdir(mode=0o700)
    output = workspace / 'metric-stage-8d4'
    receipt = {'scope': LOCAL_SCOPE, 'execution_environment': 'OWNER_LOCAL_OFFLINE',
               'producer_sha': report['source_sha'], 'execution_recipe_sha': report['source_sha'],
               'private_workspace': str(workspace), 'output_path': str(output),
               'peak_internal_allocation_bytes': LOCAL_PEAK_ALLOCATION_BYTES,
               'blender_audit_path':report['blender_audit_path'],'blender_binary':str(blender.resolve()),
               'paid_usage_authorized': False, 'network_artifact_uploads': False}
    context_path = workspace / 'LOCAL_EXECUTION_CONTEXT.json'
    context_path.write_text(json.dumps(receipt, indent=2) + '\n')
    (workspace / 'PREFLIGHT.json').write_text(json.dumps(report, indent=2) + '\n')
    env = os.environ.copy()
    for key in ['GH_TOKEN', 'ANIME_SOURCE_ARTIFACTS_READ'] + [name for name in env if name.startswith('GITHUB_')]:
        env.pop(key, None)
    env['AA_8D4_LOCAL_CONTEXT'] = str(context_path)
    env['AA_8D4_SOURCE_SHA'] = report['source_sha']
    stages = [
        ('source', [str(blender), '--background', '--factory-startup', '--python-exit-code', '1', '--python',
                    str(ROOT / 'tools/authored_animation/blender/aa_metric_pair_reference_8d4.py'),
                    '--', '--input', str(archive), '--output', str(output), '--case-id',report['selected_cases'][0]], 22 * 60),
        ('source_validation', [sys.executable, str(ROOT / 'tools/authored_animation/validate_metric_stage_8d4.py'), str(output),
                               '--case-id',report['selected_cases'][0]], 180),
    ]
    # Every command is serial, locally installed and bounded; no download,
    # package install, runner registration, repository sharing or art upload.
    status = {'source_sha': report['source_sha'], 'stages': [], 'PASS': False,
              'reference_scope':'SINGLE_CASE_PILOT','selected_cases':report['selected_cases'],
              'full_reference_batch_complete':False,'reference_art_accepted':False,
              'animated_export_verified':False,'release_acting_verified':False,
              'remaining_batch_ready':False,
              'started_UTC': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'RUNTIME_PAIRED_CONTACT_VERIFIED': False, 'human_approved': False}
    try:
        for name, command, timeout in stages:
            with (workspace / (name + '.log')).open('w') as log:
                result = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
            status['stages'].append({'stage': name, 'exit_code': result.returncode})
            if result.returncode:
                raise RuntimeError('Actual local ' + name + ' failed; retain outputs/logs without automatic retry')
            volume = Path('/System/Volumes/Data') if Path('/System/Volumes/Data').is_dir() else workspace
            if shutil.disk_usage(volume).free < LOCAL_RESERVE_BYTES:
                raise RuntimeError('Protected internal reserve breached; stop without deleting outputs')
            if sum(p.stat().st_size for p in output.rglob('*') if p.is_file()) > 3 * 1024**3:
                raise RuntimeError('Actual reference output exceeds3GiB forecast cap; stop and retain evidence')
        viewer = workspace / 'native_viewer'
        viewer.mkdir()
        shutil.copyfile(ROOT / 'game-godot/tests/v1_closure/MetricArtStage8D4.gd', viewer / 'review.gd')
        shutil.copyfile(ROOT / 'game-godot/tests/v1_closure/PairedAnimationPlayback8D4.gd', viewer / 'paired_animation.gd')
        (viewer / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Private offline metric reference"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        review = output / 'engine_review'
        review.mkdir()
        with (workspace / 'native_review.log').open('w') as log:
            result = subprocess.run([str(godot), '--path', str(viewer), '--rendering-method', 'gl_compatibility',
                                     '--audio-driver', 'Dummy', '--log-file', str(review / 'godot.log'), '--script', 'res://review.gd',
                                     '--', '--stage-runtime=' + str(output / 'runtime'), '--ordinary-output=' + str(review),
                                     '--reference-case=' + report['selected_cases'][0]],
                                    cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=10 * 60)
        status['stages'].append({'stage': 'native_review', 'exit_code': result.returncode})
        if result.returncode:
            raise RuntimeError('Native viewer failed; retain actual source and logs')
        native = json.loads((review / 'metric_stage_native_8d4.json').read_text())
        if not native['PASS'] or [r['case']for r in native['rows']] != report['selected_cases'] or len(list(review.glob('*.png'))) != 1:
            raise RuntimeError('Incomplete actual native reference evidence')
        if 'SCRIPT ERROR:' in (review / 'godot.log').read_text(errors='replace'):
            raise RuntimeError('Native viewer reported script errors despite process exit')
        with (workspace/'native_animation.log').open('w')as log:
            result=subprocess.run([str(godot),'--headless','--path',str(viewer),'--audio-driver','Dummy',
                                   '--script','res://paired_animation.gd','--',
                                   '--animation-manifest='+str(output/'runtime/PRODUCTION_MANIFEST.json'),
                                   '--test-output='+str(review)],
                                  cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
        status['stages'].append({'stage':'native_skeletal_animation','exit_code':result.returncode})
        if result.returncode or 'SCRIPT ERROR:'in(workspace/'native_animation.log').read_text(errors='replace'):
            raise RuntimeError('Actual paired skeletal import/playback failed; retain all outputs')
        animation=json.loads((review/'paired_animation_playback.json').read_text())
        source=json.loads((output/'runtime/PRODUCTION_MANIFEST.json').read_text())['rows'][0]['animated_reference']
        if not animation['PASS']or animation['synthetic_fixture']is not False or animation['actors']!=2 or animation['source_frames']!=25 or animation['joint_samples']<=0 or animation['source_export_sha256']!=source['sha256']:
            raise RuntimeError('Incomplete or mismatched real-source skeletal equivalence evidence')
        status['animated_export_verified']=True
        status['skeletal_pose_equivalence_verified']=True
        status['skinned_surface_equivalence_verified']=False
        # These export/import checks cannot approve release/locomotion acting,
        # sole contact, penetration, silhouettes or the remaining batch.
        if shutil.disk_usage('/System/Volumes/Data').free < LOCAL_RESERVE_BYTES:
            raise RuntimeError('Stop after native review: protected internal reserve breached; retain evidence')
        status['PASS'] = True
    except (Exception, KeyboardInterrupt) as error:
        status['error'] = str(error)
    finally:
        status['finished_UTC'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        (workspace / 'EXECUTION_STATUS.json').write_text(json.dumps(status, indent=2) + '\n')
    return status['PASS']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', required=True, type=Path)
    parser.add_argument('--workspace', required=True, type=Path)
    parser.add_argument('--blender', type=Path, default=Path('/Applications/Blender.app/Contents/MacOS/Blender'))
    parser.add_argument('--godot', type=Path, default=Path('/Applications/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--blender-audit',type=Path,help='Private verified official4.0.2package/app audit; no self-attestation switch')
    parser.add_argument('--case-id',default='ember-vale__juno-spark__male__1',
                        help='Exactly one existing pilot; no local full-batch mode before real reference acceptance')
    args = parser.parse_args()
    archive, workspace = args.archive.resolve(), args.workspace.resolve()
    report = preflight(archive, workspace, args.blender, args.godot,args.case_id,args.blender_audit)
    print(json.dumps(report, indent=2))
    if args.execute:
        if not report['PASS']:
            print('Production NOT started; preserve current inputs, capacity guard and compatible-source requirement.')
            return 2
        return 0 if execute(report, archive, workspace, args.blender, args.godot) else 1
    return 0 if report['PASS'] else 2


if __name__ == '__main__':
    raise SystemExit(main())

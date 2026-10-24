"""Fail-closed private execution/provenance boundary for new 8D-4 art.

This prevents accidental public production. It does not grant infrastructure,
billing, token or artistic approval. No secrets are read or returned.
"""
import json
import os
import plistlib
import re
import shutil
import stat
import subprocess
from pathlib import Path

PUBLIC_REPOSITORY='gunnchOS3k/anime-aggressors'
SPENDING_CLEARANCE='OWNER_CONFIRMED_INCLUDED_USAGE_AND_ZERO_OVERAGE'
LOCAL_SCOPE='OWNER_AUTHORIZED_ZERO_COST_LOCAL_ONLY'
LOCAL_RESERVE_BYTES=18*1024**3
LOCAL_PEAK_ALLOCATION_BYTES=4*1024**3
# Opt-in encrypted external mode. These constants do not replace the legacy
# 18 GiB + 4 GiB internal guard above.
EXTERNAL_SCOPE='OWNER_AUTHORIZED_ENCRYPTED_EXTERNAL_ONLY'
EXTERNAL_VOLUME_NAME='gunnchos-private-art'
ARCHIVE_VOLUME_UUID='9C4EB36E-2864-42F8-BD0B-A4F67EBC7852'
ARCHIVE_MOUNT=Path('/Volumes/gunnchOS-Archives')
ARCHIVE_DEVICE_NODE='/dev/disk5s1'
# Internal residue that still happens when private temp is on the encrypted
# volume: macOS, Blender, and Godot can write crash reports, font/shader
# caches, and small system files on the Data volume. A factory-startup probe
# moved internal available space by 36864 bytes with TMPDIR already external.
# That figure is not a measured production peak. Until a real one-case run
# measures internal growth, keep this overhead explicit and nonzero. External
# free space never substitutes for the 18 GiB internal reserve.
EXTERNAL_INTERNAL_OVERHEAD_BYTES=1*1024**3
EXTERNAL_PEAK_ALLOCATION_BYTES=4*1024**3
EXTERNAL_SAFETY_MARGIN_BYTES=8*1024**3
PROTECTED_VOLUME_DIRS=('source','output','scratch','tmp')


def verify_context(event, live_repository, *, execution_repository, source_sha,
                   checkout_sha, workflow_sha, spending_clearance, approved_repository):
    source=event.get('repository',{})
    if not approved_repository or approved_repository!=execution_repository:
        raise ValueError('Explicit owner-approved private repository is required')
    if not execution_repository or execution_repository==PUBLIC_REPOSITORY:
        raise ValueError('New proprietary8D4 art may not run in the public repository')
    if source.get('full_name')!=execution_repository or live_repository.get('full_name')!=execution_repository:
        raise ValueError('Execution repository identity mismatch')
    if not execution_repository.startswith('gunnchOS3k/'):
        raise ValueError('Unapproved repository owner')
    if source.get('private')is not True or live_repository.get('private')is not True or live_repository.get('visibility')!='private':
        raise ValueError('Private repository required in both event and live API metadata')
    if live_repository.get('archived')or live_repository.get('disabled'):
        raise ValueError('Inactive private repository')
    if not re.fullmatch(r'[0-9a-f]{40}',source_sha or '')or source_sha!=checkout_sha:
        raise ValueError('Exact public code checkout SHA required')
    if not re.fullmatch(r'[0-9a-f]{40}',workflow_sha or ''):
        raise ValueError('Private workflow SHA required separately from art producer SHA')
    if spending_clearance!=SPENDING_CLEARANCE:
        raise ValueError('Private-run spending clearance has not been supplied by owner')
    return {'schema':'private_art_execution_8d4.v1','execution_repository':execution_repository,
            'repository_private_verified':True,'producer_sha':source_sha,
            'execution_workflow_sha':workflow_sha,'artifact_retention_days':3,
            'billing_scope':'Owner attestation, not a machine measurement of remaining allowance',
            'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False}


def verify_local_context(record, *, checkout_sha, workspace, directory_mode,
                         directory_owned, internal_free_bytes, github_actions):
    """Local source execution is not a GitHub run or a spending attestation."""
    if github_actions:
        raise ValueError('Local offline context cannot authorize a GitHub runner')
    if record.get('scope')!=LOCAL_SCOPE or record.get('execution_environment')!='OWNER_LOCAL_OFFLINE':
        raise ValueError('Explicit owner-authorized local-only scope required')
    if record.get('paid_usage_authorized')is not False or record.get('network_artifact_uploads')is not False:
        raise ValueError('Local production may not enable paid services or network uploads')
    if not re.fullmatch('[0-9a-f]{40}',checkout_sha or '')or record.get('producer_sha')!=checkout_sha or record.get('execution_recipe_sha')!=checkout_sha:
        raise ValueError('Exact local producer and recipe checkout SHA required')
    if record.get('private_workspace')!=str(workspace) or not directory_owned or directory_mode&0o077:
        raise ValueError('Owner-only private local workspace required')
    forecast=record.get('peak_internal_allocation_bytes')
    if type(forecast)is not int or forecast<LOCAL_PEAK_ALLOCATION_BYTES or internal_free_bytes<LOCAL_RESERVE_BYTES+forecast:
        raise ValueError('Local production requires18GiB AFTER at least4GiB forecast allocation')
    output=Path(record.get('output_path',''))
    if output.parent!=workspace or output.name!='metric-stage-8d4':
        raise ValueError('Local output must be bound to its private workspace')
    return {'schema':'private_art_execution_8d4.v2','execution_environment':'OWNER_LOCAL_OFFLINE',
            'producer_sha':checkout_sha,'execution_recipe_sha':checkout_sha,
            'execution_repository':None,'execution_workflow_sha':None,'artifact_retention_days':None,
            'local_filesystem_private_verified':True,'network_artifact_uploads':False,
            'paid_usage_authorized':False,'internal_reserve_bytes':LOCAL_RESERVE_BYTES,
            'peak_internal_allocation_bytes':forecast,'private_workspace':str(workspace),
            'output_path':str(output),'RUNTIME_PAIRED_CONTACT_VERIFIED':False,'human_approved':False}


def current_context(root, *, producer_binary=None):
    local=os.environ.get('AA_8D4_LOCAL_CONTEXT')
    if local:
        path=Path(local)
        if path.is_symlink()or stat.S_IMODE(path.stat().st_mode)&0o077 or path.stat().st_uid!=os.geteuid():
            raise ValueError('Local context receipt must be owner-only, not a symlink')
        record=json.loads(path.read_text());workspace=Path(record['private_workspace']).resolve()
        if path.resolve().parent!=workspace or workspace.is_relative_to(Path(root).resolve())or workspace.is_relative_to(Path('/Volumes')):
            raise ValueError('Local production must be outside source checkout and immutable archives')
        if subprocess.run(['git','-C',str(workspace),'rev-parse','--show-toplevel'],capture_output=True).returncode==0:
            raise ValueError('Private production output cannot be inside a Git checkout')
        info=workspace.stat()
        checkout=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
        volume=Path('/System/Volumes/Data')if Path('/System/Volumes/Data').is_dir()else workspace
        context=verify_local_context(record,checkout_sha=checkout,workspace=workspace,
            directory_mode=stat.S_IMODE(info.st_mode),directory_owned=info.st_uid==os.geteuid(),
            internal_free_bytes=shutil.disk_usage(volume).free,github_actions=os.environ.get('GITHUB_ACTIONS')=='true')
        if not producer_binary or Path(record.get('blender_binary','')).resolve()!=Path(producer_binary).resolve():
            raise ValueError('Actual Blender executable must match the official producer audit')
        from audit_blender_402 import verify_audit
        audit=verify_audit(Path(record['blender_audit_path']),Path(producer_binary),probe_version=False)
        context.update(official_blender_package_verified=True,official_package_sha256=audit['package_sha256'],
                       blender_binary_sha256=audit['binary_sha256'])
        return context
    if os.environ.get('GITHUB_ACTIONS')!='true'or os.environ.get('GITHUB_EVENT_NAME')!='workflow_dispatch':
        raise ValueError('Explicit private manual production only')
    event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    live_path=Path(os.environ['AA_8D4_PRIVATE_REPOSITORY_METADATA'])
    live=json.loads(live_path.read_text())
    checkout=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
    return verify_context(event,live,execution_repository=os.environ.get('GITHUB_REPOSITORY'),
        source_sha=os.environ.get('AA_8D4_SOURCE_SHA'),checkout_sha=checkout,
        workflow_sha=os.environ.get('GITHUB_SHA'),spending_clearance=os.environ.get('AA_8D4_SPENDING_CLEARANCE'),
        approved_repository=os.environ.get('AA_8D4_APPROVED_PRIVATE_REPOSITORY'))


def validate_manifest_context(manifest):
    """Require the recorded private boundary on saved/exported art evidence.

    This is provenance validation, not an independent live-API privacy check;
    production and recovery perform those checks separately.
    """
    context=manifest.get('private_execution',{})
    if context.get('execution_environment')=='OWNER_LOCAL_OFFLINE':
        source=context.get('producer_sha','')
        if not re.fullmatch('[0-9a-f]{40}',source)or source!=manifest.get('producer_sha')or context.get('execution_recipe_sha')!=source:
            raise ValueError('Local source/recipe SHA mismatch')
        if context.get('execution_repository')is not None or context.get('execution_workflow_sha')is not None or context.get('artifact_retention_days')is not None:
            raise ValueError('Offline execution cannot claim GitHub provenance or artifact retention')
        if context.get('local_filesystem_private_verified')is not True or context.get('network_artifact_uploads')is not False or context.get('paid_usage_authorized')is not False:
            raise ValueError('Missing private zero-cost offline provenance')
        if context.get('internal_reserve_bytes',0)<LOCAL_RESERVE_BYTES or context.get('peak_internal_allocation_bytes',0)<LOCAL_PEAK_ALLOCATION_BYTES:
            raise ValueError('Offline storage guard provenance missing')
        return context
    repo=context.get('execution_repository','')
    if not isinstance(repo,str)or repo==PUBLIC_REPOSITORY or not repo.startswith('gunnchOS3k/')or context.get('repository_private_verified')is not True:
        raise ValueError('Missing verified private execution provenance')
    if context.get('producer_sha')!=manifest.get('producer_sha')or not re.fullmatch(r'[0-9a-f]{40}',manifest.get('producer_sha','')):
        raise ValueError('Source producer SHA is not bound to private execution')
    if not re.fullmatch(r'[0-9a-f]{40}',context.get('execution_workflow_sha',''))or context.get('artifact_retention_days')!=3:
        raise ValueError('Private workflow or retention provenance mismatch')
    return context


def live_volume_probe(path):
    """Live diskutil identity for the volume that holds path. No secrets."""
    target=Path(path)
    if not target.exists():
        raise OSError('Encrypted volume is not mounted')
    result=subprocess.run(['/usr/sbin/diskutil','info','-plist',str(target)],capture_output=True)
    if result.returncode!=0 or not result.stdout:
        raise OSError('Encrypted volume is not mounted')
    info=plistlib.loads(result.stdout)
    mount=info.get('MountPoint') or ''
    if not mount:
        raise OSError('Encrypted volume is not mounted')
    encrypted=bool(info.get('Encryption') or info.get('EncryptionThisVolumeProper') or info.get('FileVault'))
    return {'volume_uuid':info.get('VolumeUUID'),'filesystem':info.get('FilesystemType'),
            'encrypted':encrypted,'owners_enabled':info.get('GlobalPermissionsEnabled') is True,
            'volume_name':info.get('VolumeName'),'mount_point':mount,
            'device_node':info.get('DeviceNode'),'parent_whole_disk':info.get('ParentWholeDisk')}


def _resolved(path):
    return Path(path).resolve(strict=False)


def _inside(path, root):
    try:
        _resolved(path).relative_to(_resolved(root))
        return True
    except ValueError:
        return False


def _symlink_escapes(path, root):
    """True when a symlink at or below the mount resolves outside that mount.

    Ancestor symlinks such as /var -> /private/var are path normalization, not an escape.
    """
    root_r=_resolved(root)
    raw=Path(path)
    if not raw.is_absolute():
        return True
    try:
        _resolved(raw).relative_to(root_r)
    except ValueError:
        return True
    try:
        parts=raw.relative_to(Path(root)).parts
    except ValueError:
        return False
    cursor=Path(root)
    for part in parts:
        cursor=cursor/part
        if cursor.is_symlink() and not _inside(cursor, root_r):
            return True
    return False


def external_production_report(workspace, *, identity, internal_free_bytes, external_free_bytes, tmpdir, probe, output_path=None):
    """Opt-in encrypted-volume gate. Does not alter verify_local_context.

    Blender, Godot, and macOS still allocate some internal files (crash logs,
    font and shader caches) even when TMPDIR is inside the encrypted volume.
    TMPDIR outside that volume is refused so private temp cannot land on the
    internal Data volume or the unencrypted archive. The 4 GiB production peak
    and the external safety margin are checked against the encrypted volume's
    free space. The 18 GiB internal reserve stays, plus EXTERNAL_INTERNAL_OVERHEAD_BYTES.
    """
    checks=[]
    def add(name, ok, detail):
        checks.append({'check':name,'pass':bool(ok),'detail':detail})
    workspace=Path(workspace)
    recorded=identity if isinstance(identity, dict) else {}
    uuid=str(recorded.get('volume_uuid') or '')
    add('encrypted_volume_identity_recorded',
        re.fullmatch(r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}', uuid) is not None
        and recorded.get('volume_name')==EXTERNAL_VOLUME_NAME,
        'Recorded encrypted volume identity must name gunnchos-private-art and its volume UUID')
    info=None
    try:
        info=probe(workspace if workspace.exists() else workspace.parent)
    except (OSError, ValueError, subprocess.SubprocessError):
        info=None
    add('encrypted_volume_mounted', info is not None and bool(info.get('mount_point')),
        'Encrypted volume is not mounted' if info is None else 'Encrypted volume is mounted')
    mount=Path(info['mount_point']) if info and info.get('mount_point') else None
    add('filesystem_apfs', bool(info) and info.get('filesystem')=='apfs',
        'Protected workspace filesystem must be APFS')
    add('encryption_on', bool(info) and info.get('encrypted') is True,
        'Protected workspace volume must be encrypted')
    add('owners_on', bool(info) and info.get('owners_enabled') is True,
        'Protected workspace volume must have owners enabled')
    add('volume_name', bool(info) and info.get('volume_name')==EXTERNAL_VOLUME_NAME,
        'Protected workspace volume name must be gunnchos-private-art')
    add('volume_uuid_matches_recorded', bool(info) and str(info.get('volume_uuid') or '').lower()==uuid.lower() and bool(uuid),
        'Live volume UUID must match the recorded encrypted image')
    archive_hit=bool(info) and (
        str(info.get('volume_uuid') or '').lower()==ARCHIVE_VOLUME_UUID.lower()
        or str(info.get('mount_point') or '')==str(ARCHIVE_MOUNT)
        or str(info.get('device_node') or '')==ARCHIVE_DEVICE_NODE
        or str(info.get('parent_whole_disk') or '') in {'disk5','disk4','disk4s2'})
    path_on_archive=_inside(workspace, ARCHIVE_MOUNT) or (mount is not None and _inside(mount, ARCHIVE_MOUNT))
    if info is None:
        add('not_archive_volume', False, 'Archive rejection was not evaluated because the encrypted volume is not mounted')
        add('not_archive_device', False, 'Archive device check was not evaluated because the encrypted volume is not mounted')
    else:
        add('not_archive_volume', not archive_hit and not path_on_archive,
            'Unencrypted archive mount and immutable archive directories are rejected')
        add('not_archive_device', info.get('device_node')!=ARCHIVE_DEVICE_NODE and info.get('parent_whole_disk')!='disk5',
            'Archive device must not host the protected workspace')
    confined=bool(mount) and workspace.is_absolute() and _inside(workspace, mount) and not path_on_archive
    add('workspace_confined', confined, 'Workspace realpath must stay inside the mounted encrypted volume')
    escaped=_symlink_escapes(workspace, mount) if mount else True
    add('no_symlink_escape', bool(mount) and not escaped, 'Symlink escape outside the encrypted volume is rejected')
    dirs_ok=False
    mode_ok=False
    if mount and not escaped:
        missing=[]
        loose=[]
        for name in PROTECTED_VOLUME_DIRS:
            directory=mount/name
            if not directory.is_dir() or directory.is_symlink():
                missing.append(name)
            elif stat.S_IMODE(directory.stat().st_mode)&0o077:
                loose.append(name)
        dirs_ok=not missing
        mode_ok=dirs_ok and not loose
        add('protected_directories', dirs_ok,
            'Protected source/output/scratch/tmp directories must exist inside the encrypted volume'
            if missing else 'Protected directories exist')
        add('owner_only_mode', mode_ok, 'Protected directories must be owner-only (mode 0700)')
    else:
        add('protected_directories', False, 'Protected directories were not checked because the encrypted volume is not mounted')
        add('owner_only_mode', False, 'Owner-only mode was not checked because the encrypted volume is not mounted')
    tmp_ok=bool(mount) and tmpdir and _inside(tmpdir, mount) and not _symlink_escapes(tmpdir, mount)
    add('tmpdir_inside_encrypted_volume', bool(tmp_ok),
        'TMPDIR must be inside the encrypted volume; otherwise Blender, Godot, and macOS temp stay internal or on the unencrypted archive')
    internal_need=LOCAL_RESERVE_BYTES+EXTERNAL_INTERNAL_OVERHEAD_BYTES
    add('internal_reserve_plus_overhead',
        type(internal_free_bytes) is int and internal_free_bytes>=internal_need,
        'Internal reserve requires 18GiB plus explicit overhead; external capacity does not replace the internal reserve')
    external_need=EXTERNAL_PEAK_ALLOCATION_BYTES+EXTERNAL_SAFETY_MARGIN_BYTES
    if external_free_bytes is None and mount:
        try:external_free_bytes=shutil.disk_usage(mount).free
        except OSError:external_free_bytes=None
    add('external_peak_plus_margin',
        type(external_free_bytes) is int and external_free_bytes>=external_need,
        'External free space is below the peak allocation plus safety margin' if type(external_free_bytes) is int
        else 'External free space could not be measured')
    if output_path is None:
        output_ok=bool(mount) and confined and not escaped and _inside(workspace, mount/'output')
        output_detail='Run workspace is inside the encrypted output directory' if output_ok else 'Unexpected output location outside the encrypted volume'
    else:
        output_ok=bool(mount) and _inside(output_path, mount/'output') and not _symlink_escapes(output_path, mount)
        output_detail='Output path is inside the encrypted output directory' if output_ok else 'Unexpected output location outside the encrypted volume'
    add('output_location', output_ok, output_detail)
    reasons=[item['detail'] for item in checks if not item['pass']]
    return {'schema':'encrypted_external_production_8d4.v1','PASS':not reasons,'checks':checks,'reasons':reasons,
            'internal_requirement_bytes':internal_need,'external_requirement_bytes':external_need,
            'internal_reserve_bytes':LOCAL_RESERVE_BYTES,'internal_overhead_bytes':EXTERNAL_INTERNAL_OVERHEAD_BYTES,
            'external_peak_allocation_bytes':EXTERNAL_PEAK_ALLOCATION_BYTES,
            'external_safety_margin_bytes':EXTERNAL_SAFETY_MARGIN_BYTES,
            'scope':EXTERNAL_SCOPE}


def recheck_external_production(workspace, identity, *, internal_free_bytes, external_free_bytes, tmpdir, probe, output_path=None):
    """Call again before execution and during a run. Raises; does not delete partial output."""
    report=external_production_report(workspace, identity=identity, internal_free_bytes=internal_free_bytes,
        external_free_bytes=external_free_bytes, tmpdir=tmpdir, probe=probe, output_path=output_path)
    if not report['PASS']:
        raise ValueError('External production stopped: '+'; '.join(report['reasons']))
    return report


def sanitized_summary(source_result, native_result):
    """Only counts/booleans may leave restricted source/native evidence.

    Never copy private source hashes, paths, repository names, artifact URLs,
    contact coordinates, animation curves or images into the public repo.
    """
    passed=source_result.get('PASS')is True and native_result.get('PASS')is True
    scenes=source_result.get('saved_reference_scenes',0)
    snapshots=source_result.get('static_snapshots',0)
    if type(scenes)is not int or type(snapshots)is not int:raise ValueError('Invalid evidence counts')
    return {'schema':'sanitized_private_reference_summary_8d4.v1','technical_artifact_validation_passed':passed,
            'saved_reference_scenes':scenes,'static_snapshots':snapshots,
            'native_review_sheets':len(native_result.get('rows',[])),
            'private_measurements_retained':True,'RUNTIME_PAIRED_CONTACT_VERIFIED':False,
            'human_approved':False}

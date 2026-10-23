"""Fail-closed private execution/provenance boundary for new 8D-4 art.

This prevents accidental public production. It does not grant infrastructure,
billing, token or artistic approval. No secrets are read or returned.
"""
import json
import os
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


def current_context(root):
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
        return verify_local_context(record,checkout_sha=checkout,workspace=workspace,
            directory_mode=stat.S_IMODE(info.st_mode),directory_owned=info.st_uid==os.geteuid(),
            internal_free_bytes=shutil.disk_usage(volume).free,github_actions=os.environ.get('GITHUB_ACTIONS')=='true')
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

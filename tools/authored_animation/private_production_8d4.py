"""Fail-closed private execution/provenance boundary for new 8D-4 art.

This prevents accidental public production. It does not grant infrastructure,
billing, token or artistic approval. No secrets are read or returned.
"""
import json
import os
import re
import subprocess
from pathlib import Path

PUBLIC_REPOSITORY='gunnchOS3k/anime-aggressors'
SPENDING_CLEARANCE='OWNER_CONFIRMED_INCLUDED_USAGE_AND_ZERO_OVERAGE'


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


def current_context(root):
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

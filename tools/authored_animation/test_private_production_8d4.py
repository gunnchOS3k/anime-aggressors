"""Disclosure-boundary tests; no real private repository or art is created."""
import copy
import re
import unittest
from pathlib import Path
from private_production_8d4 import verify_context, validate_manifest_context, sanitized_summary, SPENDING_CLEARANCE
from private_production_8d4 import verify_local_context, LOCAL_SCOPE, LOCAL_RESERVE_BYTES, LOCAL_PEAK_ALLOCATION_BYTES


def fixture():
    repo={'full_name':'gunnchOS3k/FIXTURE_PRIVATE_ONLY','private':True,'visibility':'private','archived':False,'disabled':False}
    kw={'execution_repository':repo['full_name'],'source_sha':'a'*40,'checkout_sha':'a'*40,
        'workflow_sha':'b'*40,'spending_clearance':SPENDING_CLEARANCE,'approved_repository':repo['full_name']}
    return {'repository':copy.deepcopy(repo)},repo,kw


class PrivateBoundary(unittest.TestCase):
    def test_separate_code_and_private_workflow_provenance(self):
        event,repo,kw=fixture();r=verify_context(event,repo,**kw)
        self.assertEqual(r['producer_sha'],'a'*40)
        self.assertEqual(r['execution_workflow_sha'],'b'*40)
        self.assertEqual(r['artifact_retention_days'],3)
        self.assertFalse(r['human_approved'])

    def test_public_source_repository_rejected_even_with_forged_private_flag(self):
        event,repo,kw=fixture();kw['execution_repository']='gunnchOS3k/anime-aggressors'
        kw['approved_repository']=kw['execution_repository']
        repo['full_name']=kw['execution_repository'];event['repository']['full_name']=kw['execution_repository']
        with self.assertRaisesRegex(ValueError,'public repository'):verify_context(event,repo,**kw)

    def test_public_internal_and_unknown_visibility_rejected(self):
        for visibility in ['public','internal',None]:
            event,repo,kw=fixture();repo['visibility']=visibility
            with self.assertRaisesRegex(ValueError,'Private repository'):verify_context(event,repo,**kw)

    def test_visibility_flip_since_dispatch_rejected(self):
        event,repo,kw=fixture();repo['private']=False
        with self.assertRaisesRegex(ValueError,'Private repository'):verify_context(event,repo,**kw)
        event,repo,kw=fixture();event['repository']['private']=False
        with self.assertRaisesRegex(ValueError,'Private repository'):verify_context(event,repo,**kw)

    def test_wrong_execution_identity_or_owner_rejected(self):
        event,repo,kw=fixture();repo['full_name']='other/repo'
        with self.assertRaisesRegex(ValueError,'identity mismatch'):verify_context(event,repo,**kw)
        event,repo,kw=fixture();kw['execution_repository']='other/private'
        kw['approved_repository']=kw['execution_repository']
        event['repository']['full_name']=repo['full_name']=kw['execution_repository']
        with self.assertRaisesRegex(ValueError,'owner'):verify_context(event,repo,**kw)

    def test_unapproved_private_repository_is_not_an_execution_target(self):
        for approved in ['',None,'gunnchOS3k/DIFFERENT_PRIVATE_FIXTURE']:
            event,repo,kw=fixture();kw['approved_repository']=approved
            with self.assertRaisesRegex(ValueError,'owner-approved'):verify_context(event,repo,**kw)

    def test_spending_unknown_blocks_execution(self):
        for clearance in ['',None,'approved','free']:
            event,repo,kw=fixture();kw['spending_clearance']=clearance
            with self.assertRaisesRegex(ValueError,'spending clearance'):verify_context(event,repo,**kw)

    def test_wrong_or_nonexact_code_sha_rejected(self):
        for sha in ['a'*8,'b'*40,'HEAD','$(echo a)']:
            event,repo,kw=fixture();kw['source_sha']=sha
            with self.assertRaisesRegex(ValueError,'checkout SHA'):verify_context(event,repo,**kw)

    def test_private_measurements_and_locations_cannot_enter_public_summary(self):
        source={'PASS':True,'saved_reference_scenes':8,'static_snapshots':24,'private_hash':'CONFIDENTIAL','contact':[1,2,3]}
        native={'PASS':True,'rows':[{'image':'PRIVATE_URI'}]*8,'token':'SECRET'}
        summary=sanitized_summary(source,native)
        self.assertEqual(summary['saved_reference_scenes'],8)
        self.assertEqual(summary['native_review_sheets'],8)
        text=str(summary)
        for value in ['CONFIDENTIAL','PRIVATE_URI','SECRET','contact','private_hash']:self.assertNotIn(value,text)
        self.assertFalse(summary['RUNTIME_PAIRED_CONTACT_VERIFIED'])

    def test_artifact_manifest_binds_producer_and_private_execution(self):
        event,repo,kw=fixture();context=verify_context(event,repo,**kw)
        manifest={'producer_sha':'a'*40,'private_execution':context}
        self.assertEqual(validate_manifest_context(manifest),context)
        manifest['producer_sha']='c'*40
        with self.assertRaisesRegex(ValueError,'producer SHA'):validate_manifest_context(manifest)

    def test_old_public_evidence_cannot_be_relabelled_private(self):
        for field,value in [('execution_repository','gunnchOS3k/anime-aggressors'),('repository_private_verified',False),('artifact_retention_days',90)]:
            event,repo,kw=fixture();context=verify_context(event,repo,**kw)
            context[field]=value
            with self.assertRaises(ValueError):validate_manifest_context({'producer_sha':'a'*40,'private_execution':context})


class PreparedWorkflowBoundary(unittest.TestCase):
    root=Path(__file__).resolve().parents[2]

    def test_current_public_job_cannot_run_even_when_production_input_true(self):
        text=(self.root/'.github/workflows/authored-animation-production.yml').read_text()
        block=text.split('  metric-stage-8d4:',1)[1].split('  controls-8d-engine-review:',1)[0]
        condition=next(line.strip()for line in block.splitlines()if line.strip().startswith('if:'))
        self.assertEqual(condition,"if: github.event_name == 'workflow_dispatch' && inputs.metric_stage_8d4 && github.event.repository.private == true")
        self.assertEqual(block.count('retention-days: 3'),3)
        self.assertNotIn('retention-days: 90',block)

    def test_private_template_has_no_automatic_trigger_or_unguarded_upload(self):
        template=self.root/'tools/authored_animation/private/metric-stage-8d4.yml'
        text=template.read_text()
        self.assertNotIn(template,self.root.glob('.github/workflows/*.yml'))
        trigger=text.split('on:',1)[1].split('permissions:',1)[0]
        self.assertIn('workflow_dispatch:',trigger)
        self.assertNotIn('pull_request:',trigger);self.assertNotIn('push:',trigger)
        self.assertEqual(text.count("if: always() && steps.private_upload.outcome == 'success'"),3)
        self.assertEqual(text.count('retention-days: 3'),3)
        self.assertIn('ART_PRODUCTION_APPROVED_REPOSITORY',text)
        self.assertIn('included_usage_and_zero_overage_confirmed == true',text)
        self.assertIn('persist-credentials: false',text)
        self.assertNotIn('actions/cache',text)

    def test_private_job_configuration_uses_available_contexts_and_separate_gates(self):
        text=(self.root/'tools/authored_animation/private/metric-stage-8d4.yml').read_text()
        job=text.split('  metric-stage-8d4:',1)[1]
        job_env=job.split('    env:\n',1)[1].split('    steps:',1)[0]
        # GitHub resolves job configuration before a runner exists. An invalid
        # context fails workflow validation even when the job would be gated off.
        allowed={'github','needs','strategy','matrix','vars','secrets','inputs'}
        for expression in re.findall(r'\$\{\{(.*?)\}\}',job_env):
            roots=set(re.findall(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\.',expression))
            self.assertTrue(roots <= allowed,expression)
        condition=next(line.strip()for line in job.splitlines()if line.strip().startswith('if:'))
        for gate in ['ART_PRODUCTION_DISPATCH_AUTHORIZED','ART_PRODUCTION_APP_ACCESS_REVIEWED']:
            self.assertIn("vars."+gate+" == 'true'",condition)
        permissions=job.split('    permissions:\n',1)[1].split('    defaults:',1)[0]
        self.assertEqual(permissions.strip(),'contents: read')
        for action in re.findall(r'uses: (\S+)',text):
            self.assertRegex(action,r'^actions/(checkout|download-artifact|upload-artifact)@[0-9a-f]{40}$')

    def test_recovery_does_not_use_public_download_or_copy_private_evidence_to_repo(self):
        text=(self.root/'tools/authored_animation/recover_metric_stage_8d4.py').read_text()
        imports=next(line for line in text.splitlines()if line.startswith('from recover_form_production_8c import'))
        self.assertNotIn(' api',imports);self.assertNotIn(' download',imports)
        self.assertIn("info['visibility']=='private'",text)
        self.assertIn('sanitized_summary(validation,result)',text)
        self.assertNotIn('shutil.copy2',text)


class LocalOfflineBoundary(unittest.TestCase):
    def fixture(self):
        workspace=Path('/SYNTHETIC_PRIVATE_FIXTURE')
        record={'scope':LOCAL_SCOPE,'execution_environment':'OWNER_LOCAL_OFFLINE','producer_sha':'a'*40,
                'execution_recipe_sha':'a'*40,'private_workspace':str(workspace),
                'output_path':str(workspace/'metric-stage-8d4'),
                'peak_internal_allocation_bytes':LOCAL_PEAK_ALLOCATION_BYTES,
                'paid_usage_authorized':False,'network_artifact_uploads':False}
        args={'checkout_sha':'a'*40,'workspace':workspace,'directory_mode':0o700,
              'directory_owned':True,'internal_free_bytes':LOCAL_RESERVE_BYTES+LOCAL_PEAK_ALLOCATION_BYTES,
              'github_actions':False}
        return record,args

    def test_local_source_has_no_forged_github_run_or_spending_attestation(self):
        record,args=self.fixture();context=verify_local_context(record,**args)
        self.assertIsNone(context['execution_repository'])
        self.assertIsNone(context['execution_workflow_sha'])
        self.assertIsNone(context['artifact_retention_days'])
        self.assertFalse(context['paid_usage_authorized'])
        self.assertFalse(context['network_artifact_uploads'])
        self.assertEqual(validate_manifest_context({'producer_sha':'a'*40,'private_execution':context}),context)

    def test_local_storage_guard_cannot_use_bare18gib_or_lower_forecast(self):
        for free in [LOCAL_RESERVE_BYTES,LOCAL_RESERVE_BYTES+LOCAL_PEAK_ALLOCATION_BYTES-1]:
            record,args=self.fixture();args['internal_free_bytes']=free
            with self.assertRaisesRegex(ValueError,'18GiB AFTER'):verify_local_context(record,**args)
        record,args=self.fixture();record['peak_internal_allocation_bytes']=1024
        with self.assertRaisesRegex(ValueError,'18GiB AFTER'):verify_local_context(record,**args)

    def test_local_context_cannot_enable_github_runner(self):
        record,args=self.fixture();args['github_actions']=True
        with self.assertRaisesRegex(ValueError,'GitHub runner'):verify_local_context(record,**args)

    def test_nonprivate_workspace_or_escaped_output_fails_closed(self):
        for change in [{'directory_mode':0o755},{'directory_owned':False}]:
            record,args=self.fixture();args.update(change)
            with self.assertRaisesRegex(ValueError,'Owner-only'):verify_local_context(record,**args)
        record,args=self.fixture();record['output_path']='/ELSEWHERE/metric-stage-8d4'
        with self.assertRaisesRegex(ValueError,'bound'):verify_local_context(record,**args)

    def test_local_context_rejects_stale_source_or_paid_uploads(self):
        for field,value in [('producer_sha','b'*40),('execution_recipe_sha','b'*40),('paid_usage_authorized',True),('network_artifact_uploads',True)]:
            record,args=self.fixture();record[field]=value
            with self.assertRaises(ValueError):verify_local_context(record,**args)

    def test_offline_manifest_cannot_claim_cloud_artifact_provenance(self):
        record,args=self.fixture();context=verify_local_context(record,**args)
        context['execution_workflow_sha']='b'*40
        with self.assertRaisesRegex(ValueError,'GitHub provenance'):validate_manifest_context({'producer_sha':'a'*40,'private_execution':context})


if __name__=='__main__':unittest.main()

"""Disclosure-boundary tests; no real private repository or art is created."""
import copy
import unittest
from pathlib import Path
from private_production_8d4 import verify_context, sanitized_summary, SPENDING_CLEARANCE


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

    def test_recovery_does_not_use_public_download_or_copy_private_evidence_to_repo(self):
        text=(self.root/'tools/authored_animation/recover_metric_stage_8d4.py').read_text()
        imports=next(line for line in text.splitlines()if line.startswith('from recover_form_production_8c import'))
        self.assertNotIn(' api',imports);self.assertNotIn(' download',imports)
        self.assertIn("info['visibility']=='private'",text)
        self.assertIn('sanitized_summary(validation,result)',text)
        self.assertNotIn('shutil.copy2',text)


if __name__=='__main__':unittest.main()

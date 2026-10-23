"""Scope and negative acceptance tests. No Blender, assets or production outputs."""
import copy
import json
from pathlib import Path
import unittest
from metric_reference_scope_8d4 import select_cases, validate_scope

ROOT = Path(__file__).resolve().parents[2]


class ReferencePilotScope(unittest.TestCase):
    def setUp(self):
        self.inputs=json.loads((ROOT/'art_source/staging/metric_8d4/inputs_v1.json').read_text())
        self.case=self.inputs['reference_cases'][0]['case']

    def pilot(self):
        return {'rows':[{'case':self.case}],'selected_cases':[self.case],
                'reference_scope':'SINGLE_CASE_PILOT','complete':True,'full_reference_batch_complete':False}

    def test_all_eight_individual_cases_are_selectable_without_mutation(self):
        original=copy.deepcopy(self.inputs)
        for case in self.inputs['reference_cases']:
            self.assertEqual(select_cases(self.inputs,case['case']),[case])
        self.assertEqual(self.inputs,original)

    def test_unknown_or_duplicate_case_is_rejected(self):
        with self.assertRaises(ValueError):select_cases(self.inputs,'INVENTED')
        self.inputs['reference_cases'][1]=self.inputs['reference_cases'][0]
        with self.assertRaises(ValueError):select_cases(self.inputs,self.case)

    def test_pilot_requires_explicit_validator_selection(self):
        pilot=self.pilot()
        self.assertEqual(list(validate_scope(pilot,self.inputs,self.case)),[self.case])
        with self.assertRaises(ValueError):validate_scope(pilot,self.inputs)

    def test_renamed_or_missing_scope_cannot_claim_pilot_provenance(self):
        for key,value in [('selected_cases',[]),('reference_scope','FULL_REFERENCE_BATCH'),('full_reference_batch_complete',True)]:
            pilot=self.pilot();pilot[key]=value
            with self.assertRaises(ValueError):validate_scope(pilot,self.inputs,self.case)

    def test_partial_duplicate_or_extra_rows_cannot_pass(self):
        for rows in [[],[{'case':self.case}]*2,[{'case':self.inputs['reference_cases'][1]['case']}]]:
            pilot=self.pilot();pilot['rows']=rows
            with self.assertRaises(ValueError):validate_scope(pilot,self.inputs,self.case)

    def test_original_full_batch_contract_is_preserved(self):
        old={'rows':[{'case':c['case']}for c in self.inputs['reference_cases']],'complete':True}
        self.assertEqual(len(validate_scope(old,self.inputs)),8)
        with self.assertRaises(ValueError):validate_scope(old,self.inputs,self.case)

    def test_local_recipe_has_no_batch_mode_or_automatic_quality_promotion(self):
        source=(ROOT/'tools/authored_animation/run_metric_stage_8d4_local.py').read_text()
        self.assertIn("'remaining_batch_ready':False",source)
        self.assertIn("'release_acting_verified':False",source)
        self.assertIn("'animated_export_verified':False",source)
        self.assertNotIn("add_argument('--batch",source)


if __name__=='__main__':unittest.main()

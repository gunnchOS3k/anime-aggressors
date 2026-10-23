"""Explicit pilot scope; partial output must never masquerade as the eight-case batch."""


def select_cases(inputs, case_id=None):
    cases = inputs['reference_cases']
    ids = [case['case'] for case in cases]
    if len(ids) != 8 or len(set(ids)) != 8:
        raise ValueError('Expected the preserved eight distinct reference cases')
    if case_id is None:
        return cases
    if case_id not in ids:
        raise ValueError('Pilot must select an existing canonical reference case')
    return [cases[ids.index(case_id)]]


def validate_scope(manifest, inputs, case_id=None):
    expected = select_cases(inputs, case_id)
    ids = [case['case'] for case in expected]
    actual = [row['case'] for row in manifest['rows']]
    if actual != ids:
        raise ValueError('Reference output differs from the explicitly requested scope/order')
    # Old complete batch manifests remain valid. A partial manifest requires
    # explicit pilot selection by both producer AND validator.
    if case_id is not None or 'selected_cases' in manifest:
        scope = 'SINGLE_CASE_PILOT' if case_id is not None else 'FULL_REFERENCE_BATCH'
        if manifest.get('selected_cases') != ids or manifest.get('reference_scope') != scope:
            raise ValueError('Missing or inconsistent reference scope provenance')
        if manifest.get('full_reference_batch_complete') is not (case_id is None and manifest['complete']):
            raise ValueError('Pilot cannot claim completed full-batch production')
    return {case['case']: case for case in expected}

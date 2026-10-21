"""Preservation and source-contract check, not animation/art acceptance."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'artifacts/v1_closure/parity_foundation'

def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()

def main():
    protection=json.loads((BASE/'PRESERVED_SOURCE.json').read_text())
    failures=[]
    for path,expected in protection['protected_sha256'].items():
        if digest(ROOT/path)!=expected:failures.append('protected source changed: '+path)
    ledger=json.loads((BASE/'ROSTER_PARITY_ACCEPTANCE.json').read_text())
    assert len(ledger['rows'])==9
    assert sum(len(x['move_ids']) for x in ledger['rows'])==216
    assert not ledger['ROSTER_PARITY_ACCEPTANCE'] and ledger['VISUAL_VERIFICATION_PENDING']
    for source in ledger['original_audit_provenance']:
        path=Path(source['path'])
        if path.exists():assert digest(path)==source['sha256'],'Original audit mutated'
    profiles=json.loads((ROOT/'game-godot/data/animation/support_exchanges.json').read_text())['fighters']
    assert set(profiles)=={x['fighter'] for x in ledger['rows']}
    fingerprints=[]
    for fid,p in profiles.items():
        assert (ROOT/f'docs/bibles/fighters/{fid}.md').exists()
        assert 10<=p['stop_frames']<=30
        for name in ['swing','support']:
            curve=p[name]
            assert curve[0]==[0,0,0] and curve[-1]==[1,1,0]
            assert all(a[0]<b[0] and a[1]<=b[1] for a,b in zip(curve,curve[1:]))
            assert all(0<=k[1]<=1 and 0<=k[2]<=.015 for k in curve)
        fingerprints.append(json.dumps({k:p[k] for k in ['swing','support','stop_frames']},sort_keys=True))
    assert len(set(fingerprints))==9,'A shared copied exchange is not original roster acting'
    rigs=json.loads((BASE/'rig_controls_in_memory.json').read_text())
    assert rigs['PASS'] and len(rigs['rows'])==18
    assert len({(r['fighter'],r['body']) for r in rigs['rows']})==18
    assert all(r['deform_bones']==22 and not r['source_binary_modified'] for r in rigs['rows'])
    assert all(r['actions_preserved']==(197 if r['fighter'] in ['kaia-windrow','juno-spark'] else 147) for r in rigs['rows'])
    assert all(r['foot_roll_max_matrix_error']<.0002 and r['support_exchange_error_m']<.0002 for r in rigs['rows'])
    # Every existing authored patch must address a gameplay ID, not a clip alias.
    for p in (ROOT/'game-godot/data/forms').glob('*.json'):
        if p.stem not in profiles:continue
        data=json.loads(p.read_text())
        manifest=json.loads((ROOT/f'game-godot/data/moves/{p.stem}.json').read_text())
        ids={m['move_id'] for m in manifest['moves']}
        for state in data['forms'].values():assert set(state.get('move_overrides',{}))<=ids
    gates=json.loads((ROOT/'artifacts/v1_closure/spectral_feedback/ACCEPTANCE_GATES.json').read_text())
    assert not any(gates.values()),'No human/device/release gate may be promoted'
    result={'PASS':not failures,'failures':failures,'protected_source_files':len(protection['protected_sha256']),
            'rigs_exercised_in_memory':18,'distinct_finite_support_scores':9,'moves_preserved':216,
            'VISUAL_VERIFICATION_PENDING':True,'scope':'hash/source/data/control-operation contracts; not authored acting quality, earned progression, balance acceptance or device/native performance'}
    (BASE/'SOURCE_VALIDATION.json').write_text(json.dumps(result,indent=2)+'\n')
    assert result['PASS'],failures
    print(json.dumps(result))

if __name__=='__main__':main()

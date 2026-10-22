"""Strict saved source/export checks. Never implies native or human acceptance."""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


def sha(p):
    h=hashlib.sha256()
    with p.open('rb')as f:
        for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()


def validate(folder, sources=True):
    m=json.loads((folder/'runtime/PRODUCTION_MANIFEST.json').read_text())
    assert m['schema']=='original_controls_production_8d.v1'and m['complete']and not m['human_approved']
    old=json.loads((ROOT/'artifacts/v1_closure/production_8c/remote_39790037341/PRODUCTION_MANIFEST.json').read_text())
    expected={(r['fighter'],r['body']):r for r in old['rows']}
    assert len(m['rows'])==18 and {(r['fighter'],r['body'])for r in m['rows']}==set(expected)
    for r in m['rows']:
        prior=expected[r['fighter'],r['body']]
        assert r['input_8c_sha256']==prior['saved_source_sha256']
        assert r['preserved_8b']==30 and r['preserved_8c']==8 and r['preserved_actions']>=185
        assert r['canonical_bones_preserved']and r['original_geometry_materials_morphs_preserved']and r['unmodified_weights_preserved']
        assert len(r['new_digit_meshes'])==4 and 20<r['new_bones']<=64
        if sources:assert sha(folder/r['saved_source'])==r['saved_source_sha256']
        data=folder/'runtime'/r['runtime'];resource=folder/'runtime'/r['resource']
        assert sha(data)==r['runtime_sha256'] and sha(resource)==r['resource_sha256']
        d=json.loads(data.read_text());assert d['source_sha256']==r['saved_source_sha256']and d['input_8c_sha256']==r['input_8c_sha256']
        assert len(d['canonical_bones'])==22 and set(d['clips'])=={'grip','fist','recoil','idle'}
        for clip in d['clips'].values():
            assert all(n.startswith('D8_')for n in clip['tracks'])
            assert len(clip['tracks'])==r['new_bones']
            for keys in clip['tracks'].values():
                assert len(keys)==clip['frames']+1
                assert all(len(q)==4 and all(math.isfinite(x)for x in q)and abs(sum(x*x for x in q)-1)<.00002 for q in keys)
        raw=resource.read_bytes();assert raw[:4]==b'glTF'
        g=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
        names={n.get('name','')for n in g['nodes']}
        assert set(d['canonical_bones']).issubset(names)
        assert all(n in names for c in d['chains']for n in c['bones'])
        assert {c['digit']for c in d['chains']if c['kind']=='finger'}==set(range(5))
        assert len([c for c in d['chains']if c['kind']=='finger'])==10
        animations={a.get('name','')for a in g.get('animations',[])}
        assert {c['source_action']for c in d['clips'].values()}.issubset(animations),animations
        assert not any(n.startswith(('ANI08B_','ANI08C_'))for n in animations),'Do not export all old action libraries'
        assert sum(bool(mesh.get('extras',{}).get('targetNames'))for mesh in g['meshes'])>=12
    return {'PASS':True,'rigs':18,'preserved_8b_actions':540,'preserved_8c_actions':144,'new_source_actions':72,'new_original_digits':72,'runtime_exports':18,'editable_sources_checked':sources,'native_verified':False,'human_approved':False}


if __name__=='__main__':print(json.dumps(validate(Path(sys.argv[1]),'--runtime-only'not in sys.argv),indent=2))

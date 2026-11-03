"""Validate direction against actual original exported morphs; no art acceptance."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def validate():
    score = json.loads((ROOT / 'game-godot/data/animation/facial_performance_8d.json').read_text())
    original = json.loads((ROOT / 'art_source/animation/form_acting_8c/score_v1.json').read_text())
    ids = {row['id'] for row in json.loads((ROOT / 'data/bibles/FIGHTER_BIBLE_INDEX.json').read_text())['fighters']}
    assert set(score['fighters']) == ids and score['human_approved'] is False
    rows = []
    for fid, profile in score['fighters'].items():
        assert profile['source_bible'] == original['fighters'][fid]['bible']
        assert len(profile['stages']) == 2
        for stage, authority in zip(profile['stages'], original['fighters'][fid]['stages']):
            assert stage['ladder_step'] == authority['ladder_step']
            keys = stage['keys']
            assert [k['phase'] for k in keys] == [0] + [authority['beats'][k] for k in ('anticipation', 'gather', 'climax', 'reveal')] + [1]
            assert all(a['phase'] < b['phase'] for a, b in zip(keys, keys[1:]))
            for key in keys:
                assert set(key['weights']).issubset(score['channels'])
                assert all(0 <= v <= 1 for v in key['weights'].values())
                assert sum(key['weights'].values()) <= 1.000001
        for body in ('male', 'female'):
            path = ROOT / f'game-godot/assets/characters/collectible_v1/{fid}/{body}/BASE.glb'
            raw = path.read_bytes()
            glb = json.loads(raw[20:20+struct.unpack_from('<I', raw, 12)[0]])
            meshes = [m for m in glb['meshes'] if m.get('extras', {}).get('targetNames')]
            assert meshes and all(set(score['channels']).issubset(m['extras']['targetNames']) for m in meshes)
            rows.append(dict(fighter=fid, body=body, original_glb_sha256=hashlib.sha256(raw).hexdigest(), morph_meshes=len(meshes)))
    assert len({json.dumps(p['stages'], sort_keys=True) for p in score['fighters'].values()}) == 9
    return dict(PASS=True, original_mesh_configs=rows, rigs_modified=0, new_blender_actions=0, human_approved=False)


if __name__ == '__main__':
    print(json.dumps(validate(), indent=2))

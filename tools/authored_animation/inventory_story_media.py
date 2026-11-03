#!/usr/bin/env python3
"""Bind canonical OVA sequences to actual media without promoting previews.

Read-only inputs; detailed output must remain outside the public checkout.
No footage, source rigs, audio or private camera data is copied or rendered.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DIRECTOR = ROOT / 'docs/anime-aggressors/v1_closure/dialogue_production/source/ANIME_V1_OVA_VARIATIONS_DIRECTOR_SCRIPT.md'
GRAPH = ROOT / 'game-godot/data/story/v1_campaign.json'


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1048576), b''):
            digest.update(block)
    return digest.hexdigest()


def canonical_sequences(graph, director):
    routes = {r['id']: r for r in graph['routes']}
    rows = []
    kaia = director.split('## Kaia —', 1)[1].split('### Kaia direction notes', 1)[0]
    for line in kaia.splitlines():
        if not re.match(r'^\| \d{2}\.', line):
            continue
        fields = [x.strip() for x in line.strip('|').split('|')]
        rows.append({'film': 'kaia-primary', 'sequence': fields[0],
                     'source_nodes': re.findall(r'`([^`]+)`', fields[1]),
                     'proposed_duration': fields[2], 'direction': fields[3]})
    assert len(rows) == 12, 'Canonical Kaia sequence table changed; review explicitly'
    acts = [
        ('Opening contradiction', lambda s: s == 'prologue'),
        ('Relationships', lambda s: s.startswith('recruit:')),
        ('Accord/breach', lambda s: s in ['accord', 'catastrophe', 'impossible_battle_1']),
        ('First Loss', lambda s: s == 'first_loss'),
        ('Puppet/release/grief', lambda s: s in ['puppet_imbalance', 'first_release', 'equilibrium', 'dual_release_1', 'dual_release_2']),
        ('Gray and quiet ending', lambda s: s in ['prismatic_gray', 'impossible_battle_2', 'epilogue', 'unlock']),
    ]
    for route in graph['routes']:
        if route['id'] in ['kaia-windrow', 'sevenfold-convergence']:
            continue
        for index, (name, includes) in enumerate(acts, 1):
            rows.append({'film': route['id'] + '-variation', 'sequence': f'{index:02d}. {name}',
                         'source_nodes': [n['id'] for n in route['nodes'] if includes(n['id'].split(':', 1)[1])],
                         'proposed_duration': 'Editorial proposal only; see canonical director script'})
    for index, node in enumerate(routes['sevenfold-convergence']['nodes'], 1):
        rows.append({'film': 'sevenfold-separate-finale', 'sequence': f'{index:02d}. {node["title"]}',
                     'source_nodes': [node['id']], 'proposed_duration': 'Editorial proposal only'})
    expected = {n['id'] for r in graph['routes'] for n in r['nodes']}
    actual = [n for row in rows for n in row['source_nodes']]
    assert len(rows) == 53 and len(actual) == len(set(actual)) == len(expected) == 145
    assert set(actual) == expected, 'Every canonical node must belong to exactly one editorial sequence'
    for row in rows:
        row.update(final_acting_complete=False, final_render_complete=False,
                   final_dialogue_music_mix_complete=False, human_approved=False,
                   status='UNFINISHED_FINAL_SEQUENCE')
    return rows


def inspect_media(path, *, source_sha, scope, audio_policy, expected_sha=None):
    row = {'path': str(path), 'source_sha': source_sha, 'scope': scope,
           'disclosure_policy': audio_policy, 'final_sequence': False,
           'public_shipping_approved': False, 'exists': path.is_file()}
    if not row['exists']:
        row['verification'] = 'MISSING'
        return row
    row['bytes'] = path.stat().st_size
    row['sha256'] = sha(path)
    row['matches_recorded_hash'] = None if expected_sha is None else row['sha256'] == expected_sha
    probe = subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                            'format=duration,size:stream=codec_type,codec_name,avg_frame_rate,duration',
                            '-of', 'json', str(path)], text=True, capture_output=True, timeout=20)
    row['verification'] = 'VERIFIED_TECHNICAL_REVIEW_ONLY' if probe.returncode == 0 and row['matches_recorded_hash'] is not False else 'FAILED'
    row['streams'] = json.loads(probe.stdout) if probe.returncode == 0 else {'probe_error': probe.stderr}
    return row


def inventory(private_cameras=None):
    graph = json.loads(GRAPH.read_text())
    rows = canonical_sequences(graph, DIRECTOR.read_text())
    captures = ROOT / 'artifacts/v1_closure/review/owner_override/capture_manifest.json'
    legacy = json.loads(captures.read_text())
    media = [inspect_media(ROOT / 'artifacts/v1_closure/review/owner_override/ova/kaia_preview.mp4',
                           source_sha=legacy['source_sha'], scope=legacy['ova_scope'],
                           audio_policy='PRIVATE_REVIEW_ONLY; legacy reconstructed event mix, not final dialogue/music/native soundtrack')]
    index = ROOT / 'artifacts/v1_closure/dialogue_performance/capture_index.json'
    for entry in json.loads(index.read_text())['movies']:
        if entry.get('local_only_audio'):
            media.append(inspect_media(ROOT / entry['path'], source_sha=entry['source_sha'], scope=entry['scope'],
                                       audio_policy='PRIVATE_ONLY_UNCLEARED_TEMPORARY_VOICES; no public embedding/transcoding/upload',
                                       expected_sha=entry['sha256']))
    camera_nodes = set()
    if private_cameras is not None:
        camera = json.loads(private_cameras.read_text())
        assert camera['candidate_only'] and camera['public_disclosure_authorized'] is False
        assert camera['canonical_cues_sha256'] == sha(ROOT / 'game-godot/data/story/dialogue/v1/cues.json')
        for node, entry in camera['nodes'].items():
            assert sha(private_cameras.parent / entry['path']) == entry['sha256']
            camera_nodes.add(node)
    for row in rows:
        row['editable_camera_source_nodes'] = [n for n in row['source_nodes'] if n in camera_nodes]
        row['camera_source_only_not_rendered'] = bool(row['editable_camera_source_nodes'])
    prior = ROOT / 'artifacts/v1_closure/production_8d/hand_integration_8d3/SOURCE_NATIVE_MATRIX.json'
    hand_rows = json.loads(prior.read_text())['rows']
    roster = []
    for fid in [r['id'] for r in graph['routes'] if r['id'] != 'sevenfold-convergence'] + ['yin', 'yang']:
        bodies = [r for r in hand_rows if r['fighter'] == fid]
        assert {b['body'] for b in bodies} == {'male', 'female'}
        roster.append({'fighter': fid, 'bodies': [{
            'body': b['body'], 'prior_source_verified': b['source_validated'],
            'prior_native_facings': b['runtime_body_facings'],
            'prior_public_throw_fixtures': b['public_throws'],
            'prior_public_escape_fixtures': b['public_escapes'],
            'current_source_glb_sha256': b['resource_sha256'],
            'paired_3d_verified': b['paired_3d_verified'],
            'normal_speed_current_art_verified': b['normal_speed_gameplay_verified'],
            'visual_observation': b['visual_observation'],
            'new_8d4_art_produced': False, 'human_approved': False,
        } for b in bodies], 'premium_body_forms_ultimate_acting_complete': False,
                       'public_client_asset_disclosure_authorized': False})
    return {'schema': 'anime.story_media_completion_inventory.v1',
            'director_script_sha256': sha(DIRECTOR), 'campaign_graph_sha256': sha(GRAPH),
            'source_code_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            'structure': {'continuous_kaia_primary': 1, 'shorter_route_variations': 6, 'separate_convergence_finale': 1},
            'canonical_sequences': rows, 'canonical_sequence_count': len(rows), 'canonical_node_count': 145,
            'finished_final_sequences': 0, 'finished_films': 0, 'technical_review_media': media,
            'legacy_negative_findings': ['Legacy ce2775f1 First Loss still is labeled Rook but visibly shows yellow Juno beside Kaia. Do not use it as canonical casting/contact acceptance. Current graph correctly maps Kaia first_loss opponent to Rook.'],
            'roster': roster, 'roster_source_evidence': str(prior),
            'shipping_asset_build': None, 'new_shipping_package_created': False,
            'HUMAN_ART_APPROVAL': False, 'OVA_PUBLICATION_AUTHORIZED': False, 'V1_RELEASE_AUTHORIZED': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path, help='New private JSON path outside public checkout')
    parser.add_argument('--private-cameras', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.is_relative_to(ROOT) or output.exists():
        parser.error('Use a new private output path outside the public checkout; preserve earlier evidence')
    data = inventory(args.private_cameras)
    output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with output.open('x') as stream:
        output.chmod(0o600)
        json.dump(data, stream, indent=2)
        stream.write('\n')
    failed = [r for r in data['technical_review_media'] if r['verification'] in ['FAILED', 'MISSING']]
    print(json.dumps({'canonical_sequences': data['canonical_sequence_count'], 'canonical_nodes': 145,
                      'finished_final_sequences': 0, 'finished_films': 0,
                      'technical_review_movies': len(data['technical_review_media']),
                      'failed_or_missing_media': len(failed), 'roster_fighters': len(data['roster'])}))
    return bool(failed)


if __name__ == '__main__':
    raise SystemExit(main())

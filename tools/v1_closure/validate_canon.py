#!/usr/bin/env python3
"""Verify explicit owner authority, uniqueness, reproducible graph and provenance."""
import hashlib,json
from pathlib import Path
from build_campaign import build
ROOT=Path(__file__).resolve().parents[2]
def read(p):return json.loads((ROOT/p).read_text())
def validate():
 expected={'kaia-windrow':'rook-ironside','ember-vale':'nix-calder','rook-ironside':'juno-spark','juno-spark':'orion-vell','nix-calder':'vesper-nyx','orion-vell':'kaia-windrow','vesper-nyx':'ember-vale'}
 d=read('artifacts/v1_closure/first_loss_owner_decision_2026-10-09.json'); m=read('docs/anime-aggressors/creative/authority_pack_v1/STORY_CAMPAIGN_MANIFEST.json'); c=read('game-godot/data/story/v1_campaign.json');o=read('artifacts/v1_closure/first_loss_owner_options.json')
 assert d['selected']==m['first_loss_selected']==c['first_loss_selected']==o['selected']==expected
 assert len(set(expected.values()))==7 and set(expected)==set(expected.values())
 assert d['approval_date']=='2026-10-09' and d['status']=='APPROVED_WORKING_V1_NARRATIVE_CANON'
 assert hashlib.sha256((ROOT/d['source']).read_bytes()).hexdigest()==d['source_sha256']
 assert c==build(), 'Campaign compiler output drift'
 assert sum(len(r['nodes']) for r in c['routes'])==145
 for r in c['routes'][:7]:
  loss=[n for n in r['nodes'] if 'first_loss' in n];assert len(loss)==1 and loss[0]['first_loss']==r['first_loss']['fighter']==expected[r['id']]
  assert r['consequence']==m['route_consequences'][r['id']]==d['route_consequences'][r['id']]
  assert r['consequence']['dialogue_status']=='DRAFT_OWNER_REVIEW'
 assert len({p['interaction'] for p in d['route_consequences'].values()})==7
 assert d['route_consequences']['juno-spark']['ultimate_fate']=='UNRESOLVED_OWNER_REVIEW'
 for item in read('artifacts/v1_closure/authority_lock.json')['files']:
  assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256'],item['path']
 return {'ok':True,'mapping':expected,'unique_lost_identities':7,'duplicate_identities':0,'dialogue_status':'DRAFT_OWNER_REVIEW'}
if __name__=='__main__':print(json.dumps(validate(),indent=2))

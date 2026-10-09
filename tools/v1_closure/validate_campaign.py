#!/usr/bin/env python3
"""Validate route membership, objectives, handler bindings and source authority."""
import json
from pathlib import Path
from validate_canon import validate,ROOT

def validate_graph():
 validate()
 c=json.loads((ROOT/'game-godot/data/story/v1_campaign.json').read_text())
 handlers=(ROOT/'game-godot/scripts/story/v1_story_encounter.gd').read_text()
 runtime=(ROOT/'game-godot/scripts/story/v1_campaign_runtime.gd').read_text()
 ids=[]; rows=[]
 for route in c['routes']:
  nodes=route['nodes'];assert len(nodes)==(5 if route['id']=='sevenfold-convergence' else 20)
  for n in nodes:
   assert n['kind'] in ['STORY_BATTLE','INTERACTIVE_DIALOGUE'] and n['implemented']
   ids.append(n['id'])
   if n['kind']=='STORY_BATTLE':
    contract=n.get('objective_contract','STOCK_WIN')
    assert contract in runtime,contract
    if contract not in ['STOCK_WIN','COSMIC_SURVIVAL']: assert '"'+contract+'"' in handlers,contract
    assert n['opponent'] and (ROOT/('game-godot/data/stages/'+n['stage']+'.json')).exists()
  if route['id']=='sevenfold-convergence':assert set(route['requires'])==set(c['spectral_order']);continue
  loss=route['first_loss']['fighter'];puppets=next(n['puppets'] for n in nodes if n.get('objective_contract')=='PUPPET_IMBALANCE')
  assert len(puppets['yin'])==3 and len(puppets['yang'])==2
  assert set(puppets['yin']+puppets['yang'])==set(c['spectral_order'])-{route['id'],loss}
  assert [n['essence_after'] for n in nodes if 'essence_after' in n]==[1,2,4,6]
  rows.append({'route':route['id'],'declared_nodes':len(nodes),'battle_nodes':sum(n['kind']=='STORY_BATTLE' for n in nodes)})
 assert len(ids)==len(set(ids))==145
 return {'ok':True,'nodes':145,'routes':rows,'presentation_complete':False,'V1_AUTOMATED_READY':False}
if __name__=='__main__':print(json.dumps(validate_graph(),indent=2))

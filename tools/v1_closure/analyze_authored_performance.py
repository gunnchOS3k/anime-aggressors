"""Narrow strict analysis of this increment; historical 108-cell corpus is untouched."""
import argparse, json, hashlib, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('captures',nargs='+',type=Path);a=p.parse_args()
rows=[]
for folder in a.captures:
 folder=folder.resolve()
 d=json.loads((folder/'combat_capture.json').read_text());launch=json.loads((folder/'launch_manifest.json').read_text())
 fid=d['moves'][0]['fighter'] if d['moves'] else ''
 # Slot ownership, never filename or a recipe name, determines the player.
 player_moves=[m for m in d['moves'] if m['slot']==1];fid=player_moves[0]['fighter'] if player_moves else fid
 contacts=[c for c in d['contacts'] if c['attacker_slot']==1];pairs=[]
 for i,first in enumerate(contacts):
  if first['result']!='hit':continue
  second=next((c for c in contacts[i+1:] if c['movie_frame']>first['movie_frame']),None)
  if second is None:continue
  start,end=first['movie_frame'],second['movie_frame']
  samples=[s for s in d['samples'] if start<s['movie_frame']<end]
  actionable=[s['movie_frame'] for s in samples if s['p2_can_attack']]
  control=[s['movie_frame'] for s in d['state_transitions'] if s['fighter']==first['defender'] and start<s['movie_frame']<end and s['to'] in ['idle','walk','run','dash','fall','jump','fast_fall','aura_ready']]
  distinct=first['attack_activation_id']!=second['attack_activation_id'] and min(first['attack_activation_id'],second['attack_activation_id'])>=0
  strict=distinct and second['result']=='hit' and second['follow_up_before_control'] and not actionable and not control and not first['move'].startswith('throw_') and not second['move'].startswith('throw_')
  status='STRICT_COMBO_VERIFIED' if strict else 'SHIELDED_FOLLOWUP' if second['result']=='shield' else 'ESCAPABLE_AFTER_CONTROL' if actionable or control else 'ISOLATED_OR_UNVERIFIED_CONTACT'
  pairs.append(dict(first_move=first['move'],second_move=second['move'],first_contact=start,second_contact=end,first_activation=first['attack_activation_id'],second_activation=second['attack_activation_id'],defender_control_frames=sorted(set(actionable+control)),first_damage_before=first['damage_before'],status=status))
 stage=[x for x in d['presentation_events'] if x['kind']==18]
 synced=[]
 for effect in stage:
  event=effect['event_id'].removesuffix(':stage');contact=next((c for c in d['contacts'] if c['event_id']==event),None)
  synced.append(bool(contact and effect['physics_frame']==contact['frame']))
 rows.append(dict(path=str(folder.relative_to(ROOT)),source_sha=launch['runtime_source_sha'],source_diff_sha256=launch['source_diff_sha256'],fighter=fid,active_CPU=d['opponent_cpu'] and d['controls_enabled'],cpu_moves=sum(m['slot']==2 for m in d['moves']),authored_cancels=d.get('authored_cancels',[]),body_hits=sum(c['result']=='hit' for c in contacts),blocks=sum(c['result']=='shield' for c in contacts),strict_pairs=sum(c['status']=='STRICT_COMBO_VERIFIED' for c in pairs),pairs=pairs,stage_events=len(stage),stage_events_same_physics_frame=all(synced),trace_sha256=hashlib.sha256((folder/'combat_capture.json').read_bytes()).hexdigest(),rules='existing explicit targeted manifest cancels now connected; no damage/frame/hitstun/AI/collision values changed',owner_approved=False))
legacy=json.loads((ROOT/'game/godot/data/combos/combo_catalog.json').read_text())
report=dict(catalogs=[dict(path='game/godot/data/combos/combo_catalog.json',authored_routes=sum(len(x) for x in legacy.values()),shipping_Godot_consumer=False,consumer='legacy game/godot/scripts/combat/ComboCatalog.gd'),dict(path='packages/game-core/src/moves/comboRoutes.ts',authored_routes=len(re.findall(r'\{\s*id:\s*"[^"]+"',(ROOT/'packages/game-core/src/moves/comboRoutes.ts').read_text())),reported_historical_count=48,shipping_Godot_consumer=False,consumer='web ComboGuideScreen and App.ts')],shipping_authority='game-godot move manifests → public command resolution → MoveRunner → confirmed collision ledger',status_scope={'AUTHORED_ROUTE':'Existing catalogs retained; current explicit jab links are authored in shipping move manifests','INPUT_RECOGNIZED':'Public presses recorded, resolved move activation observed','LEGAL_CANCEL':'Explicit target, resolved frame window and same-activation body-hit required; whiffs/shields/stale emissions rejected','STRICT_COMBO_VERIFIED':'Only pairs listed with no observed defender control between distinct contact owners','PLAYER_EXECUTABLE':'Automated ordinary public controls versus active CPUs; not manual-owner acceptance','VISUALLY_ACCEPTED':False},captures=rows,full_legacy_or_web_routes_certified=False,historical_contact_matrix_changed=False)
a.output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps([dict(fighter=r['fighter'],strict_pairs=r['strict_pairs'],body_hits=r['body_hits'],blocks=r['blocks'],cancels=len(r['authored_cancels']),stage_events=r['stage_events'],stage_same_frame=r['stage_events_same_physics_frame']) for r in rows]))

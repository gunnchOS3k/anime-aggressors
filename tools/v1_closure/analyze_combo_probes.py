"""Correlate real public inputs, move activation, collision, hitstop and defender recovery."""
import json,csv
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
index=json.loads((OUT/'combo_probe_index.json').read_text());interactions=[];matrix=[]
def band(value):return 'low' if value<40 else 'medium' if value<90 else 'high'
def category(move):
 if '_air' in move:return 'aerial'
 if move=='heavy_attack':return 'heavy'
 if move=='neutral_special_projectile':return 'projectile'
 if move in ['jab_1','jab_2','jab_finisher','forward_tilt','up_tilt','down_tilt','dash_attack']:return 'light'
 return 'other'
for row in index['attempts']:
 d=json.loads((OUT/'combo_probes'/row['label']/'combat_capture.json').read_text());fid=row['fighter']
 body=[c for c in d['contacts'] if c['attacker']==fid and c['result']=='hit'];cases=[]
 for first in body:
  f=first['movie_frame'];next_c=next((c for c in d['contacts'] if c['attacker']==fid and c['movie_frame']>f),None)
  end=min(f+120,next_c['movie_frame'] if next_c else f+120)
  samples=[s for s in d['samples'] if f<=s['movie_frame']<end]
  locked=next((s for s in samples if not s['p2_can_attack']),None)
  recovery=next((s for s in samples if locked and s['movie_frame']>locked['movie_frame'] and s['p2_can_attack']),None)
  state_changes=[s for s in d['state_transitions'] if s['fighter']==first['defender'] and f<=s['movie_frame']<=end]
  land=next((s for s in state_changes if s['to']=='land'),None)
  control_transition=next((s for s in state_changes if s['movie_frame']>f and s['to'] in ['idle','walk','run','dash','fall','jump','fast_fall','aura_ready']),None)
  activation=next((s for s in d['move_phases'] if s['fighter']==fid and s['phase']=='active' and s['movie_frame']>f),None)
  next_start=next((m for m in d['moves'] if m['fighter']==fid and m['movie_frame']>f),None)
  excluded=row.get('acceptance_status','').startswith('DEFECT_AFFECTED') or first['move'].startswith('throw_') or bool(next_c and next_c['move'].startswith('throw_'))
  recovered_before_next=bool(next_c and any(x and x['movie_frame']<next_c['movie_frame'] for x in [recovery,control_transition]))
  genuine=bool(not excluded and not recovered_before_next and next_c and next_c['result']=='hit' and next_c['follow_up_before_control'])
  status='DEFECT_AFFECTED_NOT_COMBO_ACCEPTANCE' if excluded else 'TRUE_COMBO_CONFIRMED' if genuine else 'DEFENDER_BLOCKED' if next_c and next_c['result']=='shield' else 'RECOVERY_BEFORE_NEXT_CONTACT' if next_c else 'NO_SUBSEQUENT_CONTACT'
  case={'capture':row['label'],'source_sha':row['source_sha'],'native_movie':row['native_movie'],'fighter':fid,'input_recipe':row['pattern'],
        'first_contact_frame':f,'first_move':first['move'],'first_move_class':category(first['move']),'actual_damage_band':band(first['damage_before']),
        'first_contact':first,'observed_hitstop_frames':[s['movie_frame'] for s in samples if s['p2_hitstop']>0],
        'landing_frame':land['movie_frame'] if land else None,'defender_first_actionable_frame':min([x['movie_frame'] for x in [recovery,control_transition] if x]) if recovery or control_transition else None,
        'next_move_start':next_start,'next_move_active':activation,'next_contact':next_c,'next_move_class':category(next_c['move']) if next_c else None,
        'true_followup_before_control':genuine,'exclusion_reason':row.get('exclusion_reason','throw contacts excluded') if excluded else None,'recovered_before_next':recovered_before_next,'status':status,'defender_state_changes':state_changes,
        'scope':'observed physics/process frame trace; active CPU and unchanged game rules; a repeated hit after recovery is not a true combo'}
  cases.append(case);interactions.append(case)
 matrix.append({**row,'genuine_pairs':sum(c['true_followup_before_control'] for c in cases),'blocked_pairs':sum(c['status']=='DEFENDER_BLOCKED' for c in cases),
                'recovery_before_next_pairs':sum(c['status']=='RECOVERY_BEFORE_NEXT_CONTACT' for c in cases),'unverified_no_next_contact':sum(c['status']=='NO_SUBSEQUENT_CONTACT' for c in cases),
                'actual_first_move_classes':sorted({c['first_move_class'] for c in cases}),
                'status':'DEFECT_AFFECTED_NOT_ACCEPTANCE' if row.get('acceptance_status','').startswith('DEFECT_AFFECTED') else 'TRUE_COMBO_OBSERVED_WITH_DEFENSIVE_ESCAPES' if any(c['true_followup_before_control'] for c in cases) else 'NO_TRUE_COMBO_OBSERVED' if cases else 'NO_BODY_CONTACT_OBSERVED'})
(OUT/'COMBO_INTERACTIONS.json').write_text(json.dumps({'interactions':interactions,'rules_changed':False,'tuning_configuration':'none','AI_disabled':False},indent=2)+'\n')
(OUT/'COMBO_PROBE_MATRIX.json').write_text(json.dumps(matrix,indent=2)+'\n')
keys=['label','fighter','band','pattern','native_movie','hits','shield_contacts','genuine_pairs','blocked_pairs','recovery_before_next_pairs','unverified_no_next_contact','status','source_sha']
with (OUT/'COMBO_PROBE_MATRIX.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows({k:r[k] for k in keys} for r in matrix)
print(json.dumps({'probes':len(matrix),'real_body_contacts':sum(r['hits'] for r in matrix),'true_pairs':sum(r['genuine_pairs'] for r in matrix),'blocked_pairs':sum(r['blocked_pairs'] for r in matrix),'no_true_combo_probes':sum(r['genuine_pairs']==0 for r in matrix)}))

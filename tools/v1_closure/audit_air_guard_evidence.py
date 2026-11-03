"""Audit preserved traces for the reproduced upward guard; never alter footage."""
import json,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';INC=OUT/'continuous_1011'
def read(p):return json.loads(p.read_text())
def write(p,d):p.write_text(json.dumps(d,indent=2)+'\n')
index=read(OUT/'combo_probe_index.json')
backup=INC/'COMBO_INDEX_PRE_EXTENDED_GUARD_AUDIT.json'
if not backup.exists():write(backup,index)
rows=[]
for kind,items,directory in [('public_cpu_probe',index['attempts'],'combo_probes'),('native_capture',read(OUT/'capture_index.json')['movies'],'captures')]:
 for row in items:
  path=OUT/directory/row['label']/'combat_capture.json'
  if not path.exists():continue
  d=read(path)
  if not d.get('opponent_cpu') or d.get('idle_fixture_not_combo_evidence'):continue
  invalid=[s['movie_frame'] for s in d.get('samples',[]) if s.get('p2_state') in ['shield_start','shield_hold'] and s.get('p2_velocity',[0,0])[1]<0]
  entry={'kind':kind,'label':row['label'],'source_sha':row['source_sha'],'trace_path':str(path.relative_to(ROOT)),'trace_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'sampled_upward_guard_frames':invalid,'competitive_acceptance':'EXCLUDED_GUARD_DEFECT_AFFECTED' if invalid else 'NO_UPWARD_GUARD_IN_SAMPLED_TRACE','scope':'Any sampled upward shield state violates grounded guard ownership. Conservative whole-attempt exclusion; trace absence alone does not certify every competitive mechanic.'}
  rows.append(entry)
  if kind=='public_cpu_probe' and invalid:
   row.setdefault('historical_acceptance_status',row.get('acceptance_status','UNAUDITED'))
   row['acceptance_status']='DEFECT_AFFECTED_UPWARD_GUARD'
   row['exclusion_reason']='Sampled upward shield state on pre-fix source; all whole-attempt combo/competitive acceptance excluded; contacts and audiovisual observations retained.'
write(OUT/'combo_probe_index.json',index)
write(INC/'COMPETITIVE_GUARD_AUDIT.json',{'rows':rows,'excluded_probes':sum(r['kind']=='public_cpu_probe' and bool(r['sampled_upward_guard_frames']) for r in rows),'excluded_native_sequences':sum(r['kind']=='native_capture' and bool(r['sampled_upward_guard_frames']) for r in rows),'prior_six_stock_loss_exclusions_preserved':True,'no_artifacts_deleted':True,'rules_changed':False})
print(json.dumps({'audited':len(rows),'excluded_probes':sum(r['kind']=='public_cpu_probe' and bool(r['sampled_upward_guard_frames']) for r in rows),'excluded_native_sequences':sum(r['kind']=='native_capture' and bool(r['sampled_upward_guard_frames']) for r in rows)}))

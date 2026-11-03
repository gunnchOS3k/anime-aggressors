"""Conservatively quarantine legacy pre-release projectile contacts; retain raw data."""
import json,hashlib,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/v1_closure/spectral_feedback';INC=OUT/'continuous_1011'
FIX='d5eb2f14'
rows=[]
for filename,key,folder in [('combo_probe_index.json','attempts','combo_probes'),('capture_index.json','movies','captures')]:
 path=OUT/filename;index=json.loads(path.read_text())
 backup=INC/'combo_ownership_audit1012'/('prior_'+filename)
 if not backup.exists():backup.write_bytes(path.read_bytes())
 for entry in index[key]:
  source=entry['source_sha']
  if subprocess.run(['git','merge-base','--is-ancestor',FIX,source],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0:continue
  trace=OUT/folder/entry['label']/'combat_capture.json'
  if not trace.exists():continue
  data=json.loads(trace.read_text());evidence=[]
  for contact in data['contacts']:
   if contact['attacker']!=entry['fighter'] or contact['move']!='neutral_special_projectile':continue
   visual=next((v for v in data.get('visual_contacts',[]) if v['event_id']==contact['event_id']),None)
   if not visual or visual['move_phase']!='active' or visual['phase_frame']!=0:continue
   casts=[m for m in data['moves'] if m['fighter']==entry['fighter'] and m['move']=='neutral_special_projectile' and m['movie_frame']<=contact['movie_frame']]
   evidence.append({'event_id':contact['event_id'],'contact_frame':contact['movie_frame'],'damage':contact['damage'],'result':contact['result'],'phase_frame':0,'move_frame':visual['move_frame'],'runtime_startup':visual['runtime_timing']['startup'],'prior_cast_count':max(0,len(casts)-1),'interpretation':'CONTACT_BEFORE_FIRST_EMITTER_RELEASE' if len(casts)==1 else 'OWNER_UNRECORDED_BEFORE_CURRENT_RELEASE; earlier emitter cannot be distinguished from stale melee shape'})
  if not evidence:continue
  entry.setdefault('prior_acceptance_status_before_projectile_audit',entry.get('acceptance_status',''))
  entry.setdefault('prior_exclusion_reason_before_projectile_audit',entry.get('exclusion_reason',''))
  entry['projectile_ownership_acceptance']='EXCLUDED_LEGACY_PRE_RELEASE_OWNERSHIP; rerun on repaired source'
  if not entry.get('acceptance_status','').startswith('DEFECT_AFFECTED'):
   entry['acceptance_status']='DEFECT_AFFECTED_PROJECTILE_OWNERSHIP_NOT_ACCEPTANCE'
   entry['exclusion_reason']='Legacy contact at cast active-phase zero, before current emitter release; independently reproduced stale-melee defect. Whole attempt conservatively excluded, including ambiguous older projectiles; raw audiovisual/contact evidence retained.'
  rows.append({'label':entry['label'],'index':filename,'source_sha':source,'trace_sha256':hashlib.sha256(trace.read_bytes()).hexdigest(),'acceptance_status':entry['acceptance_status'],'first_emitter_contacts':sum(e['prior_cast_count']==0 for e in evidence),'evidence':evidence})
 path.write_text(json.dumps(index,indent=2)+'\n')
report={'fix_source_prefix':FIX,'rows':rows,'excluded_probe_labels':[r['label'] for r in rows if r['index']=='combo_probe_index.json'],'excluded_native_labels':[r['label'] for r in rows if r['index']=='capture_index.json'],'scope':'All legacy pre-release owner-unrecorded contacts conservatively excluded from competitive/combo acceptance. Does not assert every repeated projectile was defective. Raw traces/videos never deleted or re-recorded. Separate attack activation required for a player follow-up.','human_gates_false':True}
(INC/'PROJECTILE_OWNERSHIP_AUDIT.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'excluded_probes':len(report['excluded_probe_labels']),'excluded_native_sequences':len(report['excluded_native_labels']),'unambiguous_first_emitter_contacts':sum(r['first_emitter_contacts'] for r in rows)}))

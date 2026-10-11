"""Explicit serial source suites with immutable per-label evidence and prior-report backups."""
import argparse,json,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--label',required=True);p.add_argument('suites',nargs='+');a=p.parse_args()
allowed=['RosterContactAlignment','RosterFootwork','ThrowOwnership','CombatChoreography','CombatActivation','InterruptedMove','SpectralFeedback','ChargeContinuity','FullCampaign','ShippingRosterPath','CampaignRestart','ElementalPerformance','DialogueProduction','OwnerOverrideFaces']
assert all(x in allowed for x in a.suites)
out=ROOT/'artifacts/v1_closure/spectral_feedback/continuous_1011'/a.label
assert not out.exists(),'Preserve previous evidence; use a new run label'
out.mkdir();rows=[]
for suite in a.suites:
 dest=out/suite;dest.mkdir();sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 args=['python3','tools/v1_closure/launch_ordinary_review.py','--profile',('ani03_'+a.label+'_'+suite.lower())[:64],'--headless','--test-script','res://tests/v1_closure/'+suite+'.gd','--output',str(dest)]
 if suite=='RosterContactAlignment':args+=['--driver-arg=--geometry-baseline=/private/tmp/ani03_alignment_baseline_0ab']
 if suite=='ShippingRosterPath':args+=['--driver-arg=--roster-staged-unlocks=/private/tmp/anime-full-campaign-v2.json']
 candidates=[ROOT/'artifacts/v1_closure'/n for n in ['full_campaign_runtime_evidence.json','shipping_roster_evidence.json','campaign_restart_evidence.json','dialogue_performance/elemental_runtime_test.json']]
 prior={x:x.read_bytes() for x in candidates if x.exists()}
 for path,data in prior.items():(dest/('prior_'+path.name)).write_bytes(data)
 start=time.monotonic();print('START',suite,flush=True)
 with (dest/'stdout.log').open('w') as f:r=subprocess.run(args,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=600)
 log=(dest/'stdout.log').read_text();passed=r.returncode==0 and 'SCRIPT ERROR' not in log
 changed=[]
 for path,old in prior.items():
  if path.exists() and path.read_bytes()!=old:
   target=dest/('report_'+path.name);target.write_bytes(path.read_bytes());changed.append(str(target.relative_to(ROOT)))
 row=dict(suite=suite,source_sha=sha,passed=passed,exit_code=r.returncode,seconds=round(time.monotonic()-start,2),reports=changed,stdout=str((dest/'stdout.log').relative_to(ROOT)),scope='isolated source fixture; no human/device/competitive acceptance')
 launch=json.loads((dest/'launch_manifest.json').read_text());row.update(source_diff_sha256=launch['source_diff_sha256'],source_changes=launch['source_changes'])
 rows.append(row);(out/'results.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not passed:raise SystemExit(1)

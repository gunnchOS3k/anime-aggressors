"""Serial targeted source regressions; preserve old reports separately."""
import json,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/dialogue_performance/regressions';OUT.mkdir(parents=True,exist_ok=True)
existing=json.loads((OUT/"results.json").read_text()) if (OUT/"results.json").exists() else {"rows":[]}
rows=existing["rows"]
import sys
selected=sys.argv[1:] or ['DialogueProduction','ElementalPerformance','CombatActivation','OwnerOverrideFaces','FullCampaign','ShippingRosterPath','FirstLossFraming','CampaignRestart']
for name in selected:
 print('RUN '+name,flush=True);start=time.monotonic()
 dest=OUT/name;dest.mkdir(exist_ok=True)
 args=['python3',str(ROOT/'tools/v1_closure/launch_ordinary_review.py'),'--profile','production_'+name.lower()+'_20261010','--headless','--test-script','res://tests/v1_closure/'+name+'.gd','--output',str(dest)]
 if name=='ShippingRosterPath':args+=['--driver-arg=--roster-staged-unlocks=/private/tmp/anime-full-campaign-v2.json']
 with (dest/'stdout.log').open('w') as stream:
  p=subprocess.run(args,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=600)
 log=(dest/'stdout.log').read_text();errors=[l for l in log.splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
 rows=[r for r in rows if r['test']!=name]
 rows.append({'test':name,'exit_code':p.returncode,'script_errors':errors,'seconds':round(time.monotonic()-start,2),'scope':'source regression; staged fixtures when declared by test','passed':p.returncode==0 and not errors})
 (OUT/'results.json').write_text(json.dumps({'source_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'rows':rows,'exports_run':False},indent=2)+'\n')
 print(json.dumps(rows[-1]),flush=True)
 if p.returncode or errors:break

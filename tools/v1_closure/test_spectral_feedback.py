"""Serial source regressions with earlier evidence preserved byte-for-byte."""
import json,subprocess,time,hashlib,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';DEST=OUT/'regressions';DEST.mkdir(exist_ok=True)
rows=[]
sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
diff=hashlib.sha256(subprocess.check_output(['git','diff'],cwd=ROOT)).hexdigest()
for name in sys.argv[1:] or ['SpectralFeedback','CombatActivation','ElementalPerformance','OwnerOverrideFaces','DialogueProduction','FullCampaign','ShippingRosterPath','CampaignRestart']:
 dest=DEST/name;dest.mkdir(exist_ok=True)
 # Older tests have fixed output paths. Preserve all tracked evidence, then copy new evidence under this package.
 tracked=subprocess.check_output(['git','ls-files','artifacts/v1_closure'],cwd=ROOT,text=True).splitlines()
 saved={s:(ROOT/s).read_bytes() for s in tracked if (ROOT/s).exists() and not s.startswith('artifacts/v1_closure/spectral_feedback/')}
 args=['python3',str(ROOT/'tools/v1_closure/launch_ordinary_review.py'),'--profile','spectral_regression_'+name.lower()+'_20261010','--headless','--test-script','res://tests/v1_closure/'+name+'.gd','--output',str(dest)]
 if name=='ShippingRosterPath':args+=['--driver-arg=--roster-staged-unlocks=/private/tmp/anime-full-campaign-v2.json']
 print('TEST '+name,flush=True);start=time.monotonic()
 try:
  with (dest/'stdout.log').open('w') as stream:p=subprocess.run(args,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=600)
  changed=[]
  for path,data in saved.items():
   current=ROOT/path
   if current.read_bytes()!=data:
    new=dest/'legacy_report_outputs'/Path(path).relative_to('artifacts/v1_closure');new.parent.mkdir(parents=True,exist_ok=True);new.write_bytes(current.read_bytes());changed.append(path)
  log=(dest/'stdout.log').read_text();errors=[x for x in log.splitlines() if 'SCRIPT ERROR' in x]
  rows.append({'test':name,'passed':p.returncode==0 and not errors,'exit_code':p.returncode,'script_errors':errors,'seconds':round(time.monotonic()-start,2),'source_sha':sha,'source_diff_sha256':diff,'scope':'source fixture regression; does not grant human/platform/Story approval','new_reports':changed})
 finally:
  for path,data in saved.items():
   if (ROOT/path).read_bytes()!=data:(ROOT/path).write_bytes(data)
 (DEST/'results.json').write_text(json.dumps({'rows':rows,'exports_run':False},indent=2)+'\n');print(json.dumps(rows[-1]),flush=True)
 if not rows[-1]['passed']:raise SystemExit(1)

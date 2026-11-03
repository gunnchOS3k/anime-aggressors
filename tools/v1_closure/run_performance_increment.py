"""Explicit finite review jobs using the existing launcher/guard; never repeat labels."""
import argparse,json,re,subprocess,sys,time,os
from native_recording_guard import active_media_jobs
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'artifacts/v1_closure/spectral_feedback'
p=argparse.ArgumentParser();p.add_argument('mode',choices=['public-roster','native']);p.add_argument('--fighter',choices=['kaia-windrow','juno-spark']);p.add_argument('--label',required=True);a=p.parse_args()
assert re.fullmatch('[a-zA-Z0-9_]{1,30}',a.label)
assert a.mode!='native' or a.fighter
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
fighters=['ember-vale','rook-ironside','nix-calder','orion-vell','vesper-nyx','yin','yang'] if a.mode=='public-roster' else [a.fighter]
state=BASE/'continuous_1019'/(a.label+'_'+a.mode+'_JOB_STATE.json')
assert not state.exists(),'Preserve previous execution state; inspect it and use a missing unique label'
rows=[]
for fid in fighters:
 assert not active_media_jobs(),'Existing game/media process preserved'
 assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==source,'Source checkpoint changed; stop serial jobs'
 dest=(BASE/'local_media'/(a.label+'_roster')/fid) if a.mode=='public-roster' else BASE/'continuous_1019'/(a.label+'_native_'+fid)
 assert not dest.exists(),'Existing evidence preserved: '+str(dest)
 dest.mkdir(parents=True)
 opponent='kaia-windrow' if fid=='juno-spark' else 'juno-spark'
 args=['python3','tools/v1_closure/launch_ordinary_review.py','--profile',(a.label+'_'+fid.replace('-','_'))[:64],'--test-script','res://tests/v1_closure/SpectralCapture.gd','--output',str(dest),'--driver-arg=--performance-fighter='+fid,'--driver-arg=--performance-opponent='+opponent,'--driver-arg=--combo-probe=authored-review','--driver-arg=--exact-trace','--driver-arg=--capture-frames='+('1300' if a.mode=='native' else '450')]
 if a.mode=='native':
  raw=BASE/'local_media'/(a.label+'_'+fid+'.avi');movie=BASE/'rendered'/(a.label+'_'+fid+'.mp4')
  assert not raw.exists() and not movie.exists(),'Existing native original preserved'
  args+=['--movie',str(raw),'--movie-fps','60','--movie-frames','1600','--driver-arg=--frame-barcode','--driver-arg=--review-vfx-mode=Full']
 else:args+=['--headless']
 job=dict(owner_pid=os.getpid(),source_sha=source,mode=a.mode,fighter=fid,output=str(dest),command=args,status='RUNNING',completed=rows)
 state.write_text(json.dumps(job,indent=2)+'\n');print('START',a.mode,fid,flush=True)
 log=dest/('native_console.log' if a.mode=='native' else 'stdout.log')
 with log.open('w') as f:r=subprocess.run(args,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=600)
 text=log.read_text();ok=r.returncode==0 and 'SCRIPT ERROR' not in text and 'SHADER ERROR' not in text
 row=dict(fighter=fid,exit_code=r.returncode,PASS=ok,output=str(dest.relative_to(ROOT)),source_sha=source,raw_local_only=a.mode=='native',trace_local_only=a.mode=='public-roster')
 rows.append(row);job.update(status='VERIFYING' if ok else 'FAILED_PRESERVED',completed=rows);state.write_text(json.dumps(job,indent=2)+'\n')
 assert ok,'Preserve failed diagnostic: '+str(log)
 if a.mode=='native':
  raster=Path.home()/'.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3'
  subprocess.run([str(raster),'tools/v1_closure/verify_combat_performance_movie.py','--output',str(dest),'--raw',str(raw),'--movie',str(movie)],cwd=ROOT,check=True)
 print(json.dumps(row),flush=True)
job.update(status='COMPLETE',completed=rows);state.write_text(json.dumps(job,indent=2)+'\n')

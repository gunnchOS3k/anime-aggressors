"""Serial public-input combo attempts; fixed combat rules, active CPUs, exact traces."""
import argparse,json,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
p=argparse.ArgumentParser();p.add_argument('labels',nargs='*');p.add_argument('--movie',action='store_true');a=p.parse_args()
patterns=['light-light','light-heavy','heavy-light','aerial-light','projectile-light']
index_path=OUT/'combo_probe_index.json'
index=json.loads(index_path.read_text()) if index_path.exists() else {'attempts':[]}
for fid in ['ember-vale','juno-spark']:
 for band in ['low','medium','high']:
  for pattern in patterns:
   label=f'{fid}_{pattern}_{band}'+('_movie' if a.movie else '')
   if a.labels and label not in a.labels:continue
   dest=OUT/'combo_probes'/label
   if dest.exists():raise SystemExit('Existing evidence preserved; choose a missing label: '+label)
   dest.mkdir(parents=True)
   args=['python3',str(ROOT/'tools/v1_closure/launch_ordinary_review.py'),'--profile','combo_'+label.replace('-','_')+'_1010','--test-script','res://tests/v1_closure/SpectralCapture.gd','--output',str(dest),
         '--driver-arg=--capture-frames=900','--driver-arg=--exact-trace','--driver-arg=--combo-probe='+pattern,'--driver-arg=--damage-band='+band,'--driver-arg=--performance-fighter='+fid]
   raw=OUT/'local_media'/(label+'.avi')
   if a.movie:args+=['--movie',str(raw),'--movie-fps','60','--movie-frames','1200']
   else:args.append('--headless')
   print('PROBE '+label,flush=True);start=time.monotonic()
   with (dest/'stdout.log').open('w') as f:r=subprocess.run(args,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=240)
   log=(dest/'stdout.log').read_text()
   assert r.returncode==0 and 'SCRIPT ERROR' not in log,(label,r.returncode,log[-2500:])
   data=json.loads((dest/'combat_capture.json').read_text())
   assert data['opponent_cpu'] and data['controls_enabled'] and not data['forced_moves'] and not data['forced_ko'] and not data['frozen_opponent']
   assert any(m['fighter']!=fid for m in data['moves']),label+': opponent did not act'
   row={'label':label,'fighter':fid,'band':band,'pattern':pattern,'source_sha':data['source_sha'],'seconds':round(time.monotonic()-start,2),'native_movie':a.movie,
        'hits':sum(c['attacker']==fid and c['result']=='hit' for c in data['contacts']),
        'shield_contacts':sum(c['attacker']==fid and c['result']=='shield' for c in data['contacts']),
        'true_followups':sum(c['attacker']==fid and c['result']=='hit' and c['follow_up_before_control'] for c in data['contacts']),
        'scope':'adaptive public controls versus active CPU; 0/50/110 starting opponent percent fixture only; no balance overrides or forced results'}
   if a.movie:
    target=OUT/'rendered'/(label+'.mp4')
    subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(raw),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(target)],check=True)
    row['path']=str(target.relative_to(ROOT))
   index['attempts'].append(row);index_path.write_text(json.dumps(index,indent=2)+'\n');print(json.dumps(row),flush=True)

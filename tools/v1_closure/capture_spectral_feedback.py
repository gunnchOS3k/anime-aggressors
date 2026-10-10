"""Serial 60 fps native MovieWriter recordings; no platform export, no dubbing."""
import json,subprocess,hashlib,shutil,time,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/v1_closure/spectral_feedback'
MEDIA=OUT/'local_media';MEDIA.mkdir(exist_ok=True)
SOURCE=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
IDS=['ember-vale','juno-spark','rook-ironside','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
plan=[(f,'active','low') for f in IDS]+[(f,'charge','low') for f in IDS]+[(f,'active',b) for f in IDS[:2] for b in ['medium','high']]+[(f,'before','low') for f in IDS[:2]]
selected=sys.argv[1:]
index=json.loads((OUT/'capture_index.json').read_text()) if (OUT/'capture_index.json').exists() else {'movies':[]}
for fid,mode,band in plan:
 label=f'{fid}_{mode}_{band}'
 if selected and label not in selected:continue
 dest=OUT/'captures'/label;dest.mkdir(parents=True,exist_ok=True)
 raw=MEDIA/(label+'.avi');target=OUT/'rendered'/(label+'.mp4');target.parent.mkdir(exist_ok=True)
 if raw.exists() or target.exists():raise SystemExit('Existing evidence preserved; use a new label instead of overwriting '+label)
 assert shutil.disk_usage(ROOT).free>2*1024**3+1550*262144,'Bounded recording reserve exhausted; platform exports require 18 GiB'
 # Charge has room for public full-charge projectile release and signature; active captures cover an entire input cycle.
 frames=1150 if mode=='charge' else 1550
 args=['python3',str(ROOT/'tools/v1_closure/launch_ordinary_review.py'),'--profile','spectral_'+label.replace('-','_')+'_20261010','--test-script','res://tests/v1_closure/SpectralCapture.gd','--movie',str(raw),'--movie-fps','60','--movie-frames',str(frames),'--output',str(dest),'--driver-arg=--performance-fighter='+fid,'--driver-arg=--damage-band='+band]
 if mode=='charge':args+=['--driver-arg=--performance-opponent=idle']
 if mode=='before':args+=['--baseline-ref','5a04f1ff9978182f1587d3d9e2e6d8a205097082']
 start=time.monotonic();print('RECORD '+label,flush=True)
 with (dest/'stdout.log').open('w') as stream:
  p=subprocess.run(args,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=600)
 log=(dest/'stdout.log').read_text()
 assert p.returncode==0 and 'SCRIPT ERROR' not in log,(label,p.returncode,log[-3000:])
 subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(raw),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(target)],check=True)
 probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,codec_name,duration,r_frame_rate,nb_frames','-of','json',str(target)],text=True))
 assert {s['codec_type'] for s in probe['streams']}=={'video','audio'}
 assert abs(float(probe['streams'][0]['duration'])-float(probe['streams'][1]['duration']))<.05
 assert probe['streams'][0]['r_frame_rate']=='60/1'
 volume=subprocess.run(['ffmpeg','-hide_banner','-i',str(target),'-af','volumedetect','-vn','-f','null','-'],capture_output=True,text=True).stderr
 assert 'mean_volume: -inf' not in volume
 evidence=json.loads((dest/'combat_capture.json').read_text())
 if mode!='charge':assert evidence['opponent_cpu'] and evidence['controls_enabled'] and any(m['fighter']!=fid for m in evidence['moves']),label+': active CPU required'
 row={'label':label,'fighter':fid,'mode':mode,'band':band,'path':str(target.relative_to(ROOT)),'source_sha':evidence['source_sha'],'native_format':'Godot AVI MJPEG + mixed PCM -> H264/AAC; no dubbing','streams':probe['streams'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'record_seconds':round(time.monotonic()-start,2),'mean_and_peak':volume[volume.find('mean_volume'):],
 'confirmed_contacts':len(evidence['contacts']),'followups_before_control':sum(c['follow_up_before_control'] and c['attacker']==fid and c['result']=='hit' for c in evidence['contacts']),'ko_count':len(evidence['ko_events']),'pool':{k:v for k,v in evidence['pool'].items() if k!='cpu_update_us'},'scope':'uninterrupted charge fixture; P2 idle, never combo evidence' if mode=='charge' else 'automated public inputs vs active CPU; explicit starting damage band; no forced moves, damage after start or KOs'}
 index['movies'].append(row);(OUT/'capture_index.json').write_text(json.dumps(index,indent=2)+'\n');print(json.dumps(row),flush=True)

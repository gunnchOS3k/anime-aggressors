"""Serial bounded renderer reviews, with native synchronized mixed audio."""
import json,subprocess,hashlib,time,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/dialogue_performance';MEDIA=OUT/'local_media';MEDIA.mkdir(exist_ok=True)
SOURCE=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
BASE='c5f3be23bf7376f2a0b71a8aabc1396415ef8186'
plan=[('ember-vale',False),('juno-spark',False),('ember-vale',True),('juno-spark',True)]+[(f,False) for f in ['rook-ironside','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']]+[('dialogue_kaia-windrow',False),('dialogue_juno-spark',False)]
if sys.argv[1:]:plan=[x for x in plan if ('before_' if x[1] else '')+x[0] in sys.argv[1:]]
index=[]
for fid,before in plan:
 label=('before_' if before else '')+fid;dest=OUT/('capture_'+label);dest.mkdir(exist_ok=True)
 story=fid.startswith('dialogue_');route=fid.removeprefix('dialogue_')
 native=MEDIA/(label+'.ogv')
 args=['python3',str(ROOT/'tools/v1_closure/launch_ordinary_review.py'),'--profile','review_'+label.replace('-','_')+'_20261010','--test-script','res://tests/v1_closure/'+('DialogueCapture' if story else 'PerformanceCapture')+'.gd','--driver-arg='+('--dialogue-route=' if story else '--performance-fighter=')+route,'--movie',str(native),'--movie-frames',str(5400 if story else 900),'--output',str(dest)]
 if before:args+=['--baseline-ref',BASE]
 # These are bounded source recordings, not heavy platform exports.
 assert shutil.disk_usage(ROOT).free>2*1024**3,'Safety reserve for bounded recording exhausted; heavy exports require 18 GiB'
 print('CAPTURE '+label,flush=True);start=time.monotonic()
 with (dest/'stdout.log').open('w') as stream:p=subprocess.run(args,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=900)
 assert p.returncode==0,(label,p.returncode)
 log=(dest/'stdout.log').read_text();assert 'SCRIPT ERROR' not in log,(label,log[-3000:])
 target=MEDIA/(label+'.mp4') if story else OUT/'rendered'/(label+'.mp4');target.parent.mkdir(exist_ok=True)
 subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(native),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(target)],check=True)
 probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_name,codec_type,duration','-of','json',str(target)],text=True))
 assert {s['codec_type'] for s in probe['streams']}=={'video','audio'},'Missing native audio stream'
 volume=subprocess.run(['ffmpeg','-hide_banner','-i',str(target),'-af','volumedetect','-vn','-f','null','-'],capture_output=True,text=True).stderr
 assert 'mean_volume: -inf' not in volume,'Silent movie'
 poster=OUT/'rendered'/(label+'.png');poster.parent.mkdir(exist_ok=True)
 subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-ss','8','-i',str(target),'-frames:v','1',str(poster)],check=True)
 row={'label':label,'path':str(target.relative_to(ROOT)),'source_sha':BASE if before else SOURCE,'native_audio':True,'streams':probe['streams'],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'scope':'read-only staged dialogue' if story else 'automated normal input in explicit versus fixture against active CPU','local_only_audio':story,'seconds_to_record':round(time.monotonic()-start,2),'volume_evidence':volume[volume.find('mean_volume:'):]}
 index.append(row);(OUT/'capture_index.json').write_text(json.dumps({'source_sha':SOURCE,'movies':index,'human_playthrough':False,'final_authored_cinematics':False},indent=2)+'\n');print(json.dumps(row),flush=True)

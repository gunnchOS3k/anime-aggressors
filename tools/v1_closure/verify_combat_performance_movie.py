"""Verify native root-render frame stamps, mixed audio and actual contact frames."""
import argparse,hashlib,json,subprocess,re,tempfile
from collections import Counter
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--raw',type=Path,required=True);p.add_argument('--movie',type=Path,required=True);a=p.parse_args()
out=a.output.resolve();raw=a.raw.resolve();movie=a.movie.resolve()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rel(p):return str(p.relative_to(ROOT))
d=json.loads((out/'combat_capture.json').read_text());launch=json.loads((out/'launch_manifest.json').read_text())
assert d['opponent_cpu'] and d['controls_enabled'] and not d['forced_moves'] and not d['forced_ko'] and not d['frozen_opponent']
frames=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(raw),'-vf','crop=240:24:20:190,format=gray','-f','rawvideo','-']),dtype=np.uint8).reshape(-1,24,240)
bits=np.array([frames[:,8:16,i*12+2:i*12+8].mean(axis=(1,2))>127 for i in range(20)]).T
codes=(bits*2**np.arange(20)).sum(axis=1);lookup={}
for frame,code in enumerate(codes):lookup.setdefault(int(code),[]).append(frame)
checks=[];offsets=Counter();mapping={}
for row in d['frame_stamps']:
 expected=(row['identity']<<16)|(row['expected_process_frame']&65535)
 found=lookup.get(expected,[]);matched=min(found,key=lambda f:abs(f-row['expected_process_frame'])) if found else None
 if matched is not None:offsets[matched-row['expected_process_frame']]+=1;mapping[row['expected_process_frame']]=matched
 checks.append(dict(trace_frame=row['expected_process_frame'],native_frame=matched,PASS=matched is not None))
receipt=dict(PASS=bool(checks) and all(c['PASS'] for c in checks),samples=len(checks),matched=sum(c['PASS'] for c in checks),offset_counts=dict(offsets),container_frames=len(codes),source_sha=launch['runtime_source_sha'],raw_sha256=sha(raw),trace_sha256=sha(out/'combat_capture.json'),checks=checks)
(out/'BARCODE_VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n');assert receipt['PASS'],'Preserve failed recording; no frame-synchronized claim'
assert not movie.exists(),'Preserve existing media'
subprocess.run(['ffmpeg','-v','error','-n','-i',str(raw),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)],check=True)
streams=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames','-show_entries','stream=codec_type,codec_name,duration,r_frame_rate,nb_read_frames','-of','json',str(movie)],text=True))['streams']
assert {s['codec_type'] for s in streams}=={'video','audio'} and streams[0]['r_frame_rate']=='60/1'
audio=subprocess.run(['ffmpeg','-hide_banner','-i',str(movie),'-af','volumedetect','-f','null','-'],capture_output=True,text=True,check=True).stderr
(out/'audio_verification.log').write_text(audio);volume={k:float(v) for k,v in re.findall(r'(mean_volume|max_volume):\s*(-?\d+(?:\.\d+)?) dB',audio)};assert volume.get('max_volume',-100)>-80
contacts=[c for c in d['contacts'] if c['attacker_slot']==1]
first=next(c for c in contacts if c['result']=='hit');second=next((c for c in contacts if c['movie_frame']>first['movie_frame'] and c['result']=='hit'),first)
shield=next((c for c in contacts if c['result']=='shield'),second)
selected=[first['movie_frame']-2,first['movie_frame'],first['movie_frame']+2,second['movie_frame'],second['movie_frame']+4,shield['movie_frame']]
captions=['before contact','confirmed contact','hurt / stage response','subsequent contact (strict analysis separate)','recovery / follow-through','shield' if shield['result']=='shield' else 'no shield selected']
with tempfile.TemporaryDirectory(prefix='aa-combat-review-') as scratch:
 sheet=Image.new('RGB',(1920,800),(18,22,31));draw=ImageDraw.Draw(sheet);exact=[]
 for i,(trace_frame,caption) in enumerate(zip(selected,captions)):
  native=mapping[trace_frame];exact.append(native);png=Path(scratch)/(str(i)+'.png')
  subprocess.run(['ffmpeg','-v','error','-n','-i',str(movie),'-vf',f'select=eq(n\\,{native}),scale=640:360','-frames:v','1',str(png)],check=True)
  x,y=(i%3)*640,(i//3)*400;sheet.paste(Image.open(png),(x,y));draw.text((x+8,y+364),f'{caption} | trace {trace_frame} / native {native}',fill='white');draw.text((x+8,y+382),launch['runtime_source_sha'][:12]+' | active CPU / public controls',fill='white')
 target=out/'contact_review.png';assert not target.exists();sheet.save(target)
log=(out/'native_console.log').read_text();timing={k:float(v) for k,v in re.findall(r'(CPU render time|Encoding time):.*?average: ([0-9.]+) ms/frame',log)}
report=dict(path=rel(movie),source_sha=launch['runtime_source_sha'],sha256=sha(movie),streams=streams,native_audio_volume_db=volume,frame_checks=receipt['samples'],frame_checks_passed=receipt['matched'],body_presentations=d['body_presentations'],opponent_active=True,script_errors=log.count('SCRIPT ERROR'),shader_errors=log.count('SHADER ERROR'),recording_measurements=timing,GPU_or_sustained_device_FPS_verified=False,sheets=[dict(path=rel(target),sha256=sha(target),source_sha=launch['runtime_source_sha'],native_frames=exact,verification_status='VERIFIED_ROOT_FRAME_BARCODES_AND_TRACE')],verification_status='VERIFIED_NATIVE60_AUDIO_FRAME_SOURCE',redistribution='Original project/synthesized combat assets; owner development review only, no public release authorization',owner_approved=False)
(out/'NATIVE_MOVIE.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

state_path=out/"RECORDING_STATE.json"
if state_path.exists():
 state=json.loads(state_path.read_text());state["process_status_at_verification"]=state["status"];state.update(status=report["verification_status"],native_verification=report["verification_status"],verification_report=rel(out/"NATIVE_MOVIE.json"));state_path.write_text(json.dumps(state,indent=2)+"\n")

"""Verify every visible native frame marker before labeling all18 aura images."""
import argparse,hashlib,json,subprocess,re,tempfile
from pathlib import Path
from collections import Counter
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--raw',type=Path,required=True);p.add_argument('--movie',type=Path,required=True);a=p.parse_args()
out=a.output.resolve();raw=a.raw.resolve();movie=a.movie.resolve()
def read(path):return json.loads(path.read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def rel(path):return str(path.relative_to(ROOT))
launch=read(out/'launch_manifest.json');source=launch['runtime_source_sha'];trace=read(out/'native_empowerment.json');assert trace['PASS']
images=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(raw),'-vf','crop=240:24:20:190,format=gray','-f','rawvideo','-']),dtype=np.uint8).reshape(-1,24,240)
bits=np.array([images[:,8:16,i*12+2:i*12+8].mean(axis=(1,2))>127 for i in range(20)]).T
codes=(bits*2**np.arange(20)).sum(axis=1);lookup={}
for frame,code in enumerate(codes):lookup.setdefault(int(code),[]).append(frame)
checks=[];offsets=Counter()
for row in trace['rows']:
 expected=(row['identity']<<16)|(row['expected_process_frame']&65535);found=lookup.get(expected,[])
 matched=min(found,key=lambda f:abs(f-row['expected_process_frame'])) if found else None
 if matched is not None:offsets[matched-row['expected_process_frame']]+=1
 checks.append(dict(fighter=row['fighter'],phase=row['phase'],trace_frame=row['expected_process_frame'],native_frame=matched,PASS=matched is not None))
receipt=dict(PASS=all(c['PASS'] for c in checks),samples=len(checks),matched=sum(c['PASS'] for c in checks),offset_counts=dict(offsets),container_frames=len(codes),source_sha=source,raw_sha256=sha(raw),trace_sha256=sha(out/'native_empowerment.json'),checks=checks,scope='Visible root frame/paired fighter identity, not final body art approval or CPU/contact evidence')
(out/'BARCODE_VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n');assert receipt['PASS'],'Keep diagnostic recording; no mislabeled sheets'
assert not movie.exists(),'Preserve old movie'
subprocess.run(['ffmpeg','-v','error','-n','-i',str(raw),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)],check=True)
streams=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames','-show_entries','stream=codec_type,codec_name,duration,r_frame_rate,nb_read_frames','-of','json',str(movie)],text=True))['streams']
assert {s['codec_type'] for s in streams}=={'video','audio'} and streams[0]['r_frame_rate']=='60/1'
audio=subprocess.run(['ffmpeg','-hide_banner','-i',str(movie),'-af','volumedetect','-f','null','-'],capture_output=True,text=True,check=True).stderr
(out/'audio_verification.log').write_text(audio);volume={k:float(v) for k,v in re.findall(r'(mean_volume|max_volume):\s*(-?\d+(?:\.\d+)?) dB',audio)};assert volume.get('max_volume',-100)>-80
sheets=[]
with tempfile.TemporaryDirectory(prefix='aa-aura-sheet-') as scratch:
 for fid in dict.fromkeys(c['fighter'] for c in checks):
  selected=[]
  for phase in ['maximum','released_idle','airborne']:
   matches=[c for c in checks if c['fighter']==fid and c['phase']==phase];selected.append(matches[len(matches)//2])
  sheet=Image.new('RGB',(1920,398),(18,22,31));draw=ImageDraw.Draw(sheet)
  for i,c in enumerate(selected):
   png=Path(scratch)/(fid+'_'+c['phase']+'.png')
   subprocess.run(['ffmpeg','-v','error','-n','-i',str(movie),'-vf',f'select=eq(n\\,{c["native_frame"]}),scale=640:360','-frames:v','1',str(png)],check=True)
   sheet.paste(Image.open(png),(i*640,0));draw.text((i*640+8,363),f'{fid} · {c["phase"]} · native {c["native_frame"]}',fill='white');draw.text((i*640+8,381),'Male left / female right · '+source[:12]+' · public energy fixture',fill='white')
  target=out/(fid+'_aura.png');assert not target.exists();sheet.save(target)
  sheets.append(dict(path=rel(target),sha256=sha(target),source_sha=source,verification_status='VERIFIED_NATIVE_FRAME_AND_PAIRED_IDENTITY',frames=[c['native_frame'] for c in selected],redistribution='Original development owner review; no public release authorization'))
log=(out/'native_console.log').read_text();timing={k:float(v) for k,v in re.findall(r'(CPU render time|Encoding time):.*?average: ([0-9.]+) ms/frame',log)}
report=dict(path=rel(movie),sha256=sha(movie),source_sha=source,streams=streams,sheets=sheets,verification_status='VERIFIED_NATIVE_FRAME_BARCODES_AND_NINE_PAIRED_IDENTITIES',native_audio_volume_db=volume,recording_measurements=timing,material_null_errors=log.count('Parameter "material" is null'),script_errors=log.count('SCRIPT ERROR'),professional_quality_approved=False,GPU_measurement_available=False,scope='All18model energy/movement/jump at native60fps with original sound. No active CPU, combo, contact or device-FPS acceptance.',redistribution='Original procedural/project assets; owner development review, no public release authorization')
(out/'NATIVE_MOVIE.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='sheets'}))
state_path=out/'RECORDING_STATE.json'
if state_path.exists():
 state=read(state_path)
 assert state['status']=='PROCESS_COMPLETED_PENDING_MEDIA_VERIFICATION'
 assert report['script_errors']==0 and report['material_null_errors']==0
 state.update(status='VERIFIED_NATIVE_FRAME_IDENTITY_AUDIO_AND_SOURCE',verification=rel(out/'NATIVE_MOVIE.json'),source_sha=source)
 state_path.write_text(json.dumps(state,indent=2)+'\n')

"""Decode actual root-render frame/body barcodes before producing roster sheets."""
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
def relative(path):return str(path.relative_to(ROOT))
launch=read(out/'launch_manifest.json');source=launch['runtime_source_sha'];trace=read(out/'roster_transitions.json');assert trace['PASS'] and len(trace['rows'])==18
image_data=subprocess.check_output(['ffmpeg','-v','error','-i',str(raw),'-vf','crop=252:24:20:190,format=gray','-f','rawvideo','-'])
images=np.frombuffer(image_data,dtype=np.uint8).reshape(-1,24,252)
bits=np.array([images[:,8:16,i*12+2:i*12+8].mean(axis=(1,2))>127 for i in range(21)]).T
codes=(bits*2**np.arange(21)).sum(axis=1)
lookup={}
for frame,code in enumerate(codes):lookup.setdefault(int(code),[]).append(frame)
checks=[];offsets=Counter()
for identity,row in enumerate(trace['rows']):
 for sample in row['samples']:
  expected=(int(identity)<<16)|(sample['movie_frame']&65535);found=lookup.get(expected,[])
  matched=min(found,key=lambda f:abs(f-sample['movie_frame'])) if found else None
  if matched is not None:offsets[matched-sample['movie_frame']]+=1
  checks.append({'fighter':row['fighter'],'body':row['body'],'sample_frame':sample['frame'],'trace_frame':sample['movie_frame'],'native_frame':matched,'encoded_identity':identity,'PASS':matched is not None})
receipt={'PASS':all(c['PASS'] for c in checks),'samples':len(checks),'matched':sum(c['PASS'] for c in checks),'measured_trace_to_native_frame_offset_counts':dict(offsets),'decoded_container_frames':len(codes),'source_sha':source,'raw_sha256':sha(raw),'trace_sha256':sha(out/'roster_transitions.json'),'checks':checks,'scope':'Every public movement sample checked against visible native root-render barcode and body identity. This does not approve acting, floor/contact geometry, competitive combos or real-device FPS.'}
(out/'BARCODE_VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n')
assert receipt['PASS'],'Preserve failed root-frame evidence; do not create falsely labeled sheets'
assert not movie.exists(),'Preserve every earlier movie; use a new label'
subprocess.run(['ffmpeg','-v','error','-n','-i',str(raw),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)],check=True)
meta=read_json=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames','-show_entries','stream=codec_type,codec_name,duration,r_frame_rate,nb_read_frames','-of','json',str(movie)],text=True))
assert {s['codec_type'] for s in meta['streams']}=={'video','audio'} and meta['streams'][0]['r_frame_rate']=='60/1'
assert int(meta['streams'][0]['nb_read_frames'])==len(codes)
audio=subprocess.run(['ffmpeg','-hide_banner','-i',str(movie),'-af','volumedetect','-f','null','-'],capture_output=True,text=True,check=True).stderr
(out/'audio_verification.log').write_text(audio)
volume={k:float(v) for k,v in re.findall(r'(mean_volume|max_volume):\s*(-?\d+(?:\.\d+)?) dB',audio)}
assert volume.get('max_volume',-100)>-80,'Audio stream exists but is not measurable native sound'
sheets=[]
with tempfile.TemporaryDirectory(prefix='aa-transition-sheet-') as scratch:
 for row in trace['rows']:
  selected=[next(c for c in checks if c['fighter']==row['fighter'] and c['body']==row['body'] and c['sample_frame']==f) for f in [4,33,59]]
  label=row['fighter']+'_'+row['body'];target=out/(label+'_movement.png');assert not target.exists()
  sheet=Image.new('RGB',(1920,398),(18,22,31));draw=ImageDraw.Draw(sheet)
  for i,(check,phase) in enumerate(zip(selected,['start load','held reversal','stop load'])):
   frame=check['native_frame'];png=Path(scratch)/(label+'_'+str(frame)+'.png')
   subprocess.run(['ffmpeg','-v','error','-n','-i',str(movie),'-vf',f'select=eq(n\\,{frame}),scale=640:360','-frames:v','1',str(png)],check=True)
   sheet.paste(Image.open(png),(i*640,0));draw.text((i*640+8,363),f'{label} · {phase} · native frame {frame}',fill='white');draw.text((i*640+8,381),source[:12]+' · barcode verified · idle target, not combo proof',fill='white')
  sheet.save(target)
  sheets.append({'path':relative(target),'sha256':sha(target),'source_sha':source,'source_movie':relative(movie),'verification_status':'VERIFIED_NATIVE_BARCODE_FRAME_AND_BODY_IDENTITY','frames':[c['native_frame'] for c in selected],'scope':'actual start/reversal/stop root-render images, body identity verified; unapproved choreography/floor placement'})
log=(out/'native_console.log').read_text();measurements={k:float(v) for k,v in re.findall(r'(CPU render time|Encoding time):.*?average: ([0-9.]+) ms/frame',log)}
report={'path':relative(movie),'source_sha':source,'sha256':sha(movie),'streams':meta['streams'],'sheets':sheets,'fixture_sha256':sha(ROOT/'game-godot/tests/v1_closure/RosterTransitions.gd'),'verification_status':'VERIFIED_1530_NATIVE_ROOT_FRAMES_AND_ALL_18_BODY_IDENTITIES','current_motion_frame_verification':True,'professional_quality_approved':False,'native_audio_volume_db':volume,'native_material_null_errors':log.count('Parameter "material" is null'),'script_errors':log.count('SCRIPT ERROR'),'recording_measurements':measurements,'GPU_measurement_available':False,'scope':'18public movement/attack-transition fixtures with idle target. Native60fps original mixed audio; no CPU/competitive/whole-match acceptance. MovieWriter offline timings are not physical-device FPS. Floor penetration/corrective footwork and authored acting remain open.','redistribution':'Original source audiovisual development review; no public release authorization'}
(out/'NATIVE_MOVIE.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='sheets'}))

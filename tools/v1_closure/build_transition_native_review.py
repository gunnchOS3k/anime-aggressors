"""Verify a bounded native movement movie and frame-indexed original review sheets."""
import json,subprocess,hashlib,tempfile,re
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';DEST=OUT/'continuous_1011/transitions_native_1012';RAW=OUT/'local_media/roster_transitions_1012.avi';MOVIE=OUT/'rendered/roster_transitions_4cee67a1.mp4'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
data=json.loads((DEST/'roster_transitions.json').read_text());assert data['PASS'] and len(data['rows'])==18
launch=json.loads((DEST/'launch_manifest.json').read_text());source=launch['runtime_source_sha']
if not MOVIE.exists():subprocess.run(['ffmpeg','-n','-hide_banner','-loglevel','error','-i',str(RAW),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(MOVIE)],check=True)
streams=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,codec_name,r_frame_rate,nb_frames,duration','-of','json',str(MOVIE)],text=True))['streams'];v=next(x for x in streams if x['codec_type']=='video');a=next(x for x in streams if x['codec_type']=='audio');assert v['r_frame_rate']=='60/1' and abs(float(v['duration'])-float(a['duration']))<.025
volume=subprocess.run(['ffmpeg','-hide_banner','-i',str(MOVIE),'-vn','-af','volumedetect','-f','null','-'],capture_output=True,text=True,check=True).stderr
peak=float(re.search(r'max_volume: ([-.\d]+) dB',volume).group(1));assert peak>-80
sheets=[];folder=DEST/'sheets';folder.mkdir(exist_ok=True)
for row in data['rows']:
 file=folder/(row['fighter']+'_'+row['body']+'.png');assert not file.exists(),'Preserve existing sheet'
 sheet=Image.new('RGB',(1280,860),'#101726');draw=ImageDraw.Draw(sheet);draw.text((14,10),f'{row["fighter"]} · {row["body"]} · {source[:12]} · original movement fixture, no CPU/competitive acceptance',fill='white');indices=[]
 with tempfile.TemporaryDirectory(prefix='aa-transition-sheet-') as temp:
  for i,kind in enumerate(['start','pivot','stop']):
   selected=[s for s in row['samples'] if s['pose'].get('kind')==kind];assert selected
   peak_frame=max(selected,key=lambda s:s['pose']['load'])['movie_frame']
   # Before onset / loaded pose / settled return, not a claim about real contact.
   chosen=[selected[0]['movie_frame']-1,peak_frame,selected[-1]['movie_frame']+1]
   for j,index in enumerate(chosen):
    assert 0<=index<int(v['nb_frames']);p=Path(temp)/(str(index)+'.png')
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-i',str(MOVIE),'-vf',f'select=eq(n\\,{index})','-frames:v','1',str(p)],check=True)
    frame=Image.open(p).convert('RGB').resize((426,239));x=j*426;y=75+i*260;sheet.paste(frame,(x,y));draw.text((x+7,y-19),f'{kind} · {"before" if j==0 else "load" if j==1 else "settle"} · frame {index}',fill='white');indices.append(index)
 sheet.save(file);sheets.append({'path':str(file.relative_to(ROOT)),'source_sha':source,'sha256':digest(file),'fighter':row['fighter'],'body':row['body'],'movie_frames':indices,'verification_status':'ENGINE_PROCESS_INDEXED_SHEETS; sampled native visual review separate','redistribution_restriction':'Original game development owner review; release authorization pending'})
log=(DEST/'stdout.log').read_text();assert 'SCRIPT ERROR' not in log and 'Parameter "material" is null' not in log
meta={'path':str(MOVIE.relative_to(ROOT)),'source_sha':source,'runtime_bytes_equivalent_to':'9ce9e15272813266a693f3474b074342c9d89412','sha256':digest(MOVIE),'bytes':MOVIE.stat().st_size,'streams':streams,'frames':int(v['nb_frames']),'fps':60,'duration_s':float(v['duration']),'native_audio_peak_db':peak,'original_native_audio':True,'scope':'18public start/reverse/stop and input-attack sequences, all18models, oneinitialfacing each; idle opponent movement fixture, NOTCPU/competitive/comboproof. Original audio. Gameplay physics unchanged; floor/contact mismatch remains.','engine_diagnostics':sorted({s for s in log.splitlines() if s.startswith('ERROR:')}),'script_errors':0,'material_cleanup_errors':0,'raw_local_only_path':str(RAW.relative_to(ROOT)),'raw_sha256':digest(RAW),'human_quality_approved':False,'physical_device_performance_pass':False,'redistribution_restriction':'Original game development owner review; no release authorization','sheets':sheets,'recording_summary':[s for s in log.splitlines() if 'Recorded ' in s or 'rendering' in s.lower() or 'encoding' in s.lower()]}
(DEST/'NATIVE_MOVIE.json').write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps({'frames':meta['frames'],'native_audio_peak_db':peak,'sheets':len(sheets),'material_cleanup_errors':0}))

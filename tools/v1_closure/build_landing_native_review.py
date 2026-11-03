"""Verify native streams and build18body landing sheets without recapturing."""
import json,hashlib,subprocess,tempfile
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';DEST=OUT/'continuous_1011/landing_native_1012';MOVIE=OUT/'rendered/roster_landings_26cf7c81.mp4';RAW=OUT/'local_media/roster_landings_1012.avi'
data=json.loads((DEST/'roster_landing.json').read_text());assert data['PASS'] and len(data['rows'])==36
source=json.loads((DEST/'launch_manifest.json').read_text())['runtime_source_sha']
streams=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,codec_name,r_frame_rate,nb_frames,duration','-show_entries','format=duration','-of','json',str(MOVIE)],text=True))
video=next(x for x in streams['streams'] if x['codec_type']=='video');audio=next(x for x in streams['streams'] if x['codec_type']=='audio');assert video['r_frame_rate']=='60/1' and int(video['nb_frames'])==4447
assert abs(float(video['duration'])-float(audio['duration']))<.025
sheets=[];path=DEST/'sheets';path.mkdir(exist_ok=True)
for fid in dict.fromkeys(r['fighter'] for r in data['rows']):
 for body in ['male','female']:
  selected=[r for r in data['rows'] if r['fighter']==fid and r['body']==body];assert len(selected)==2
  file=path/(fid+'_'+body+'.png');assert not file.exists(),'Preserve prior sheet'
  sheet=Image.new('RGB',(1280,800),'#101726');draw=ImageDraw.Draw(sheet);draw.text((14,10),f'{fid} · {body} · native60fps · {source[:12]} · idle movement fixture, no combo acceptance',fill='white')
  frames=[]
  with tempfile.TemporaryDirectory(prefix='aa-landing-sheet-') as temp:
   for i,r in enumerate(selected):
    f=int(r['contact']['movie_frame']);assert 2<=f<int(video['nb_frames'])-4
    for j,offset in enumerate([-2,0,3]):
     n=f+offset;image=Path(temp)/f'{n}.png';subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-i',str(MOVIE),'-vf',f'select=eq(n\\,{n})','-frames:v','1',str(image)],check=True)
     # Three columns ×two types: retain fullframe, avoid inferred mesh crop.
     frame=Image.open(image).convert('RGB').resize((426,239));x=j*426;y=65+i*350;sheet.paste(frame,(x,y));draw.text((x+7,y-20),f'{"fast-fall" if r["public_fast_fall"] else "normal"} · frame {n} · {offset:+d}',fill='white');frames.append(n)
  sheet.save(file)
  sheets.append({'path':str(file.relative_to(ROOT)),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'source_sha':source,'fighter':fid,'body':body,'movie_frames':frames,'verification_status':'ENGINE_PROCESS_FRAME_INDEXED; full-frame images generated; representative visual inspection separately recorded','redistribution_restriction':'Original game development owner review; release authorization pending'})
log=(DEST/'stdout.log').read_text();metadata={'path':str(MOVIE.relative_to(ROOT)),'source_sha':source,'sha256':hashlib.sha256(MOVIE.read_bytes()).hexdigest(),'bytes':MOVIE.stat().st_size,'streams':streams['streams'],'frames':4447,'fps':60,'duration_s':float(video['duration']),'original_native_audio':True,'raw_local_only_path':str(RAW.relative_to(ROOT)),'raw_sha256':hashlib.sha256(RAW.read_bytes()).hexdigest(),'recording_wall_s':351,'reported_realtime_percent':21,'reported_cpu_render_ms_per_frame':.58,'reported_encoding_ms_per_frame':6.70,'gpu_frame_time_available':False,'physical_device_performance_pass':False,'scope':'36public normal/fast-fall landings; all18P1models visible; idle target,NOTactiveCPU/comboproof; updatedinengineHUD/bodylabels; unchangedphysics; existingfloor/contactoriginproblem remains','engine_diagnostics':sorted({x for x in log.splitlines() if x.startswith('ERROR:')}),'script_errors':log.count('SCRIPT ERROR'),'redistribution_restriction':'Original sourcegame assets/audio, ownerdevelopmentreview only; no releaseapproval','sheets':sheets}
assert not metadata['script_errors'];(DEST/'NATIVE_MOVIE.json').write_text(json.dumps(metadata,indent=2)+'\n');print(json.dumps({'frames':4447,'fps':60,'body_sheets':len(sheets),'native_audio':True,'diagnostics':metadata['engine_diagnostics']}))

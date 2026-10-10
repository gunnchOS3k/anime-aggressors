"""Retain the native OGV repeated-frame tail when decoding to MP4.

Godot/Theora may represent static final frames without decoded video pictures.
This repeats that last decoded image to the native audio endpoint, without
inventing motion or replacing/mixing/re-encoding the native AAC audio track.
"""
import json,subprocess,hashlib,shutil,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/dialogue_performance'
def probe(path):
 return json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_name,codec_type,duration','-of','json',str(path)],text=True))['streams']
index=json.loads((OUT/'capture_index.json').read_text())
for row in index['movies']:
 target=ROOT/row['path'];streams=probe(target)
 video=float(next(s['duration'] for s in streams if s['codec_type']=='video'))
 audio=float(next(s['duration'] for s in streams if s['codec_type']=='audio'))
 original_video=float(next(s['duration'] for s in row['streams'] if s['codec_type']=='video'))
 if audio-original_video>.05 and 'encoding_note' not in row:
  row['encoding_note']=f'Retained {audio-original_video:.3f}s native static/repeated-frame tail; no invented motion; native AAC audio copied unchanged.'
 if audio-video>.05:
  archive=OUT/'local_media'/'previous_recordings'/row['label']/str(time.time_ns())
  archive.mkdir(parents=True);shutil.copy2(target,archive/target.name)
  temp=target.with_name('normalized_'+target.name)
  native=OUT/'local_media'/(row['label']+'.ogv')
  subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(native),'-i',str(target),'-map','0:v:0','-map','1:a:0','-vf',f'fps=30,tpad=stop_mode=clone:stop_duration={audio:.6f}','-t',str(audio),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','copy','-movflags','+faststart',str(temp)],check=True)
  temp.replace(target)
  row['encoding_note']=f'Retained {audio-video:.3f}s native static/repeated-frame tail; no invented motion; native AAC audio copied unchanged.'
 row['streams']=probe(target);row['sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
 video=float(next(s['duration'] for s in row['streams'] if s['codec_type']=='video'))
 audio=float(next(s['duration'] for s in row['streams'] if s['codec_type']=='audio'))
 assert abs(video-audio)<.05,(row['label'],video,audio)
 print(row['label'],video,audio,flush=True)
(OUT/'capture_index.json').write_text(json.dumps(index,indent=2)+'\n')

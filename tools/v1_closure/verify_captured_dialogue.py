"""Match native recorded speech onsets to stable cue WAVs and caption clock.

Requires NumPy from the bundled runtime. This verifies recorded audio identity
and temporal alignment, not expressive acting or lip sync.
"""
import hashlib,json,subprocess,wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/dialogue_performance'
SR=22050
def samples(path):
 with wave.open(str(path)) as w:
  assert w.getframerate()==SR and w.getnchannels()==1 and w.getsampwidth()==2
  return np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768
cues=json.loads((ROOT/'game-godot/data/story/dialogue/v1/cues.json').read_text())['cues']
index=json.loads((OUT/'capture_index.json').read_text())['movies']
rows=[]
for fid in ['kaia-windrow','juno-spark']:
 movie=next(r for r in index if r['label']=='dialogue_'+fid)
 assert movie.get('native_capture_format','').startswith('AVI'),'OGV timing is not accepted'
 data=json.loads((OUT/('capture_dialogue_'+fid)/'dialogue_capture_events.json').read_text())
 pcm=OUT/'local_media'/('dialogue_'+fid+'_decoded.wav')
 subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(ROOT/movie['path']),'-vn','-ac','1','-ar',str(SR),str(pcm)],check=True)
 audio=samples(pcm);n=1<<((len(audio)+SR*20-1).bit_length());spectrum=np.fft.rfft(audio,n=n)
 found=[]
 for cid,event in sorted(data['events'].items()):
  voice=samples(ROOT/'game-godot'/cues[cid]['voice_asset'].removeprefix('res://'))
  correlation=np.fft.irfft(spectrum*np.conj(np.fft.rfft(voice,n=n)),n=n)[:len(audio)-len(voice)+1]
  start=int(np.argmax(correlation));coefficient=float(correlation[start]/max(1e-9,np.linalg.norm(voice)*np.linalg.norm(audio[start:start+len(voice)])))
  found.append({'cue_id':cid,'speaker':cues[cid]['speaker'],'caption_clock_s':event['shown_at_s'],'recorded_voice_start_s':start/SR,'correlation':coefficient})
 offset=float(np.median([r['recorded_voice_start_s']-r['caption_clock_s'] for r in found]))
 for row in found:
  row['clock_residual_s']=row['recorded_voice_start_s']-row['caption_clock_s']-offset
  row['passed']=row['correlation']>.4 and abs(row['clock_residual_s'])<.1
  row['route_id']=fid;rows.append(row)
 print(fid,len(found),'movie prefix/mixer offset',round(offset,4),'max residual',round(max(abs(r['clock_residual_s']) for r in found),4),flush=True)
result={'ok':len(rows)==36 and all(r['passed'] for r in rows),'cue_count':len(rows),'rows':rows,'scope':'Native AVI/MJPEG/PCM renderer recordings encoded to MP4; waveform identity matched against 36 supplied local formant cue files and their in-engine caption clock. 100ms tolerance includes frame/mixer latency. No acting, lip-sync or human approval claim.','human_pass':False}
(OUT/'dialogue_audio_sync_test.json').write_text(json.dumps(result,indent=2)+'\n')
raise SystemExit(0 if result['ok'] else 1)

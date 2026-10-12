"""Match recorded native hit audio to the actual original impact waveform near contact frames."""
import json,subprocess,wave,statistics,argparse
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';MEDIA=OUT/'local_media'
def samples(path):
 with wave.open(str(path)) as w:
  assert w.getsampwidth()==2
  data=np.frombuffer(w.readframes(w.getnframes()),dtype=np.int16).astype(np.float64).reshape(-1,w.getnchannels()).mean(axis=1)
  return data,w.getframerate()
parser=argparse.ArgumentParser();parser.add_argument('labels',nargs='*');parser.add_argument('--output',type=Path,default=OUT/'AUDIO_FRAME_SYNC.json');args=parser.parse_args()
rows=[]
movies=[{**m,'folder':'captures'} for m in json.loads((OUT/'capture_index.json').read_text())['movies']]
if (OUT/'combo_probe_index.json').exists():movies.extend({**m,'mode':'active','folder':'combo_probes'} for m in json.loads((OUT/'combo_probe_index.json').read_text())['attempts'] if m['native_movie'])
for movie in movies:
 if args.labels:
  if movie['label'] not in args.labels:continue
 elif movie['mode'] not in ['active','charge_continuous'] or movie['fighter'] not in ['ember-vale','juno-spark']:continue
 data=json.loads((OUT/movie['folder']/movie['label']/'combat_capture.json').read_text())
 decoded=MEDIA/(movie['label']+'_analysis.wav')
 subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(ROOT/movie['path']),'-vn','-ac','1','-ar','48000','-c:a','pcm_s16le',str(decoded)],check=True)
 audio,sr=samples(decoded);matches=[]
 for c in [c for c in data['contacts'] if c['attacker']==movie['fighter'] and c.get('attacker_slot',1)==1 and c['result']=='hit' and c.get('audio_path')][:10]:
  source=ROOT/'game-godot'/c['audio_path'].removeprefix('res://')
  template_file=MEDIA/(movie['label']+'_impact_template.wav')
  subprocess.run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(source),'-ac','1','-ar',str(sr),'-c:a','pcm_s16le',str(template_file)],check=True)
  template,_=samples(template_file);template=template[:min(len(template),int(.16*sr))];template-=template.mean()
  expected=c['movie_frame']/60
  start=max(0,int((expected-.10)*sr));stop=min(len(audio),int((expected+.12)*sr)+len(template));window=audio[start:stop]
  n=len(window)+len(template)-1;size=1<<(n-1).bit_length()
  corr=np.fft.irfft(np.fft.rfft(window,size)*np.fft.rfft(template[::-1],size),size)[len(template)-1:len(window)]
  running=np.concatenate(([0.0],np.cumsum(window*window)))
  energy=running[len(template):]-running[:-len(template)]
  coeff=corr/np.sqrt(np.maximum(1.0,energy*np.dot(template,template)))
  best=int(np.argmax(coeff));onset=(start+best)/sr
  matches.append({'movie_frame':c['movie_frame'],'contact_s':expected,'detected_audio_s':round(onset,6),'offset_s':round(onset-expected,6),'correlation':round(float(coeff[best]),4),'asset':c['audio_path'],'event_id':c['event_id']})
 offsets=[m['offset_s'] for m in matches if m['correlation']>.35]
 median=statistics.median(offsets) if offsets else None
 rows.append({'capture':movie['label'],'source_sha':movie['source_sha'],'matches':matches,'matched':len(offsets),'median_audio_minus_trace_s':median,'maximum_residual_from_median_s':max(abs(x-median) for x in offsets) if offsets else None,'scope':'waveform match on native recorded mixed audio; trace is pre-render resolution time; constant recording/mixer latency reported rather than concealed'})
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps({'rows':rows,'no_dubbing':True,'fps':60},indent=2)+'\n');print(json.dumps([{k:v for k,v in r.items() if k!='matches'} for r in rows]))

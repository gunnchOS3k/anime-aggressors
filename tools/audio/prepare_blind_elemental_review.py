"""Matched-loudness A/B: preserved candidate impact versus actual new layered impact."""
import json,wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/dialogue_performance/audio_ab';SR=22050
rows={}
def load(p):
 with wave.open(str(p)) as w:
  rate=w.getframerate();n=w.getnchannels();x=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768
  if n>1:x=x.reshape(-1,n).mean(axis=1)
  return np.interp(np.arange(round(len(x)*SR/rate))*rate/SR,np.arange(len(x)),x)
def write(p,x):
 with wave.open(str(p),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((x*32767).astype('<i2').tobytes())
for fid in ('ember-vale','juno-spark'):
 old=load(ROOT/f'game-godot/assets/audio/collectible_v1/{fid}/special.wav')
 new=load(ROOT/f'game-godot/assets/audio/elemental_v1/{fid}/projectile_impact.wav')
 length=max(len(old),len(new));old=np.pad(old,(0,length-len(old)))*10**(-6/20);new=old+np.pad(new,(0,length-len(new)))*.65*10**(-7/20)
 a=np.sqrt(np.mean(old**2));b=np.sqrt(np.mean(new**2));target=min(.1,.8*a/max(abs(old)),.8*b/max(abs(new)))
 for label,x,rms in [('A',old,a),('B',new,b)]:
  x=x*(target/rms);name=fid+'_'+label+'.wav';write(OUT/name,x)
  rows[name]={'kind':'preserved candidate impact' if label=='A' else 'retained candidate impact plus original elemental layer','rms_dbfs':round(20*np.log10(np.sqrt(np.mean(x**2))),3),'peak_dbfs':round(20*np.log10(max(abs(x))),3),'sample_rate':SR,'duration_seconds':length/SR,'third_party_samples':False}
(OUT/'KEY.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows,indent=2))

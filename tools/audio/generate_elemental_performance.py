"""Original deterministic layered synthesis; no samples, models or third-party audio."""
import json,hashlib,wave,shutil
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2]; SR=22050
OUT=ROOT/'game-godot/assets/audio/elemental_v1'; STEM=ROOT/'art_source/audio/elemental_v1'; REPORT=ROOT/'artifacts/v1_closure/dialogue_performance'
FAMILIES={'ember-vale':'combustion','juno-spark':'electricity','rook-ironside':'stone','kaia-windrow':'wind','nix-calder':'crystal','orion-vell':'gravity','vesper-nyx':'phase','yin':'subtraction','yang':'construction'}
EVENTS={'charge_start':.6,'charge_loop':2.0,'charge_ready':.8,'charge_release':.5,'charge_cancel':.3,'projectile_launch':.55,'projectile_travel':1.4,'projectile_impact':.8,'projectile_dissipate':.45,'heavy':.9,'signature':1.5,'signature_release':1.2,'block':.28}
def low(x,width): return np.convolve(x,np.ones(width)/width,mode='same')
def save(p,x):
 p.parent.mkdir(parents=True,exist_ok=True)
 with wave.open(str(p),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((np.clip(x,-.95,.95)*32767).astype('<i2').tobytes())
def build(fid,event,duration):
 seed=int(hashlib.sha256((fid+event).encode()).hexdigest()[:8],16);rng=np.random.default_rng(seed)
 t=np.arange(int(duration*SR))/SR;n=rng.normal(0,1,len(t));smooth=low(n,80);mid=low(n,9);hi=n-low(n,6)
 loop=event.endswith('loop') or event.endswith('travel');charge=event=='charge_loop'
 env=np.ones(len(t)) if loop else (1-np.exp(-t*350))*np.exp(-t/(duration*.27))
 if charge:env=.5+.5*t/duration
 fam=FAMILIES[fid]
 if fam=='combustion':
  # Turbulent burning air, granular fuel crackle, resonant furnace pressure.
  body=smooth*4 + .16*np.sin(2*np.pi*58*t)*(1+.5*np.sin(2*np.pi*8*t))
  texture=mid*.9*(.5+.5*np.sin(2*np.pi*13*t+.8*np.sin(2*np.pi*3*t)))
  transient=np.where(rng.random(len(t))<.003,hi*2.6,0);transient=low(transient,3)
 elif fam=='electricity':
  # Irregular arcs with rapid ringing decay, alternating current and low thunder.
  body=low(n,180)*3 + .08*np.sin(2*np.pi*120*t)*(.3+.7*np.sin(2*np.pi*19*t)**2)
  pulses=np.zeros(len(t))
  for at in rng.uniform(0,duration,round(duration*38)+4):
   local=t-at;pulses+=np.where(local>=0,np.exp(-np.maximum(local,0)*260)*np.sin(2*np.pi*(1500+at*700)*local),0)
  texture=pulses*.25; transient=hi*.16*(np.sin(2*np.pi*(28*t+15*t*t))>.8)
 elif fam=='stone':
  body=smooth*5+.18*np.sin(2*np.pi*42*t)*np.exp(-t*6);texture=low(n,30)*.8;transient=mid*.5*np.exp(-t*38)
 elif fam=='wind':
  body=low(n,100)*2;texture=mid*(.4+.3*np.sin(2*np.pi*4*t));transient=low(n,4)*.2*np.exp(-t*40)
 elif fam=='crystal':
  body=smooth*1.6;texture=sum(.10*np.sin(2*np.pi*f*t)*np.exp(-t*(4+i)) for i,f in enumerate([1370,2183,3217,4771]));transient=hi*.12*(rng.random(len(t))<.03)
 elif fam=='gravity':
  body=.22*np.sin(2*np.pi*(48*t-8*t*t)) +smooth*3;texture=.10*np.sin(2*np.pi*173*t)*np.sin(2*np.pi*3*t);transient=mid*.35*np.exp(-t*17)
 elif fam=='phase':
  body=smooth*2*np.sin(2*np.pi*2*t);texture=mid*.3*(np.sin(2*np.pi*9*t)>0);transient=hi*.08*np.exp(-((t-duration*.44)/.025)**2)
 elif fam=='subtraction':
  body=.2*np.sin(2*np.pi*35*t)*np.sin(np.pi*t/duration);texture=low(n,22)*.4*(t<duration*.25);transient=-mid*.35*np.exp(-t*65)
 else:
  body=smooth*1.5+.14*np.sin(2*np.pi*110*t);texture=sum(.06*np.sin(2*np.pi*f*t) for f in [220,330,440,660]);transient=mid*.3*np.exp(-t*40)
 if event in ('heavy','signature','projectile_impact'):
  body*=1.3; transient+=mid*.7*np.exp(-t*45)
 if event=='signature_release':
  # A pressure onset, second release and textured tail, distinct from contact.
  body*=1.4
  texture*=.65+np.exp(-((t-.18)/.07)**2)*1.3
  transient+=mid*.8*(np.exp(-t*55)+.6*np.exp(-((t-.13)/.035)**2))
 if event=='charge_ready':texture*=1.4
 if event=='block':body*=.45
 if loop:
  # Crossfade circular seam; no click or accumulation on sustained charge.
  fade=int(SR*.05);ramp=np.linspace(0,1,fade)
  for x in (body,texture,transient):x[:fade]*=ramp;x[-fade:]*=ramp[::-1]
 else:env*=np.minimum(1,(duration-t)/.04)
 layers=[x*env for x in (body,texture,transient)]
 mix=sum(layers);scale=.70/max(.70,np.max(np.abs(mix)));layers=[x*scale for x in layers]
 return layers
rows=[]
for fid,fam in FAMILIES.items():
 for event,duration in EVENTS.items():
  layers=build(fid,event,duration);mix=sum(layers);path=OUT/fid/(event+'.wav');save(path,mix)
  sources=[]
  for name,x in zip(('body','texture','transient'),layers):
   p=STEM/fid/event/(name+'.wav');save(p,x);sources.append(str(p.relative_to(ROOT)))
  rows.append({'fighter_id':fid,'family':fam,'event':event,'path':'res://'+str(path.relative_to(ROOT/'game-godot')),'stems':sources,'peak_dbfs':round(20*np.log10(max(1e-9,np.max(abs(mix)))),2),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'license':'Original project synthesis; no third-party samples','seed':'sha256(fighter_id+event)','loop':event in ('charge_loop','projectile_travel')})
REPORT.mkdir(parents=True,exist_ok=True)
(REPORT/'elemental_sound_catalog.json').write_text(json.dumps({'schema':'original_elemental_v1','sample_rate':SR,'source_script':str(Path(__file__).relative_to(ROOT)),'human_mix_approved':False,'assets':rows},indent=2)+'\n')
# Blind review: labels assigned in a separate key, levels normalized for comparison.
review=REPORT/'audio_ab';review.mkdir(exist_ok=True)
key={}
for fid in ('ember-vale','juno-spark'):
 for label,source in [('A',ROOT/'game-godot/assets/audio/collectible_v1'/fid/'special.wav'),('B',OUT/fid/'projectile_impact.wav')]:
  dest=review/(fid+'_'+label+'.wav');shutil.copyfile(source,dest);key[dest.name]='preserved candidate' if label=='A' else 'layered original elemental impact'
 with wave.open(str(OUT/fid/'charge_start.wav')) as w:a=w.readframes(w.getnframes())
 with wave.open(str(OUT/fid/'charge_loop.wav')) as w:b=w.readframes(w.getnframes())
 with wave.open(str(OUT/fid/'charge_ready.wav')) as w:c=w.readframes(w.getnframes())
 with wave.open(str(review/(fid+'_charge.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(a+b+b+c)
(review/'KEY.json').write_text(json.dumps(key,indent=2)+'\n')
print(json.dumps({'mixes':len(rows),'source_stems':len(rows)*3}))

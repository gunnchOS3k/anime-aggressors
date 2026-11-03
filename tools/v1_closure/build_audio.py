"""Deterministic original layered SFX candidates; owner mix approval stays false."""
import array, hashlib, json, math, random, wave
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
FIGHTERS = ['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
EVENTS = {'whiff':.22,'light':.22,'heavy':.48,'signature':.55,'special':.65,'super_startup':1.1,'super_impact':1.15,'block':.24,'launch':.55,'ko':.9,'select':.25,'transform':1.35,'black_puppet':1.0,'white_puppet':1.0,'prismatic':1.4}
RATE=24000
# Low-pass noise body, metallic delay lattice, high-pass texture, pressure envelope.
GRAMMAR=[(.12,[41,127,269],.68),(.025,[113,347,631],.90),(.55,[17,53,101],.28),(.018,[199,431,787],.18),(.44,[61,137,223],.48),(.035,[233,467,937],.72),(.06,[307,619,1237],.25),(.018,[139,277,557],.82),(.32,[79,157,313],.38)]
manifest={'schema':'anime_v1.original_sfx_candidates.v1','sample_rate':RATE,'SFX_MIX_HUMAN_PASS':False,'approved_procedural_final':False,'method':'seeded filtered noise, physical impulse resonators, delay lattices, layered pressure envelopes; no third party recordings','assets':[]}
for fi,fid in enumerate(FIGHTERS):
    alpha,delays,weight=GRAMMAR[fi]
    for event,dur in EVENTS.items():
        seed=int.from_bytes(hashlib.sha256((fid+event).encode()).digest()[:8],'big'); rng=random.Random(seed)
        n=int(dur*RATE); samples=[0.0]*n; low=prev=0.0
        severity=2.1 if event in ['heavy','super_impact','ko'] else 1.0
        rising=event in ['super_startup','transform','prismatic']
        for i in range(n):
            t=i/RATE; phase=i/max(1,n-1); noise=rng.uniform(-1,1)
            low+=alpha*(noise-low); high=noise-low
            pulse=max(0.0,1-t/.018)*rng.uniform(-1,1)
            env=(phase**.7 * (1-phase)**.25) if rising else math.exp(-t/(dur*.24))
            if fi==2: env*=.35+.65*(1 if (i//720)%3==0 else .1)
            if fi==7: env*=1-phase # inward reduction
            if fi==8: env*=.4+phase # expanding radiance
            resonant=sum(samples[i-d]*.21 for d in delays if i>=d)
            texture=high*(.10 if fi in [1,5,7] else .40)
            samples[i]=((low*weight+texture+pulse*.7)*env*severity+resonant)*min(1,i/120)*min(1,(n-i)/240)
        peak=max(abs(x) for x in samples) or 1; gain=.63 if event=='whiff' else .84
        pcm=array.array('h',(int(max(-1,min(1,x/peak*gain))*32767) for x in samples))
        folder=ROOT/'game-godot/assets/audio/collectible_v1'/fid; folder.mkdir(parents=True,exist_ok=True); path=folder/(event+'.wav')
        with wave.open(str(path),'wb') as w: w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
        manifest['assets'].append({'fighter_id':fid,'event':event,'path':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'duration_s':dur,'peak_dbfs':round(20*math.log10(gain),2),'owner_approved':False})
(ROOT/'artifacts/v1_closure/audio_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('SFX_CANDIDATES',len(manifest['assets']))

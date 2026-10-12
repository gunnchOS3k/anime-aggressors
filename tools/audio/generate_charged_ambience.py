"""Quiet persistent loops from the repository's original procedural stems.

No external recordings/models/providers. Existing audio is never overwritten.
"""
import hashlib,json,wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
def read(path):
    with wave.open(str(path)) as f:
        assert f.getsampwidth()==2 and f.getnchannels()==1
        return np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768,f.getframerate()
rows=[]
for fid in IDS:
    sources=[ROOT/'art_source/audio/elemental_v1'/fid/'charge_loop'/name for name in ['body.wav','texture.wav']]
    body,rate=read(sources[0]);texture,tr=read(sources[1]);assert rate==tr
    signal=body+.12*np.resize(texture,len(body))
    # Five-tap low-pass limits harsh texture; circular filtering preserves seam.
    signal=sum(np.roll(signal,i)*weight for i,weight in zip(range(-2,3),[1,2,3,2,1]))/9
    signal-=signal.mean()
    n=min(int(rate*.08),len(signal)//8)
    cross=signal[:n]*np.linspace(0,1,n)+signal[-n:]*np.linspace(1,0,n)
    signal=np.concatenate([cross,signal[n:-n]])
    # Equalize the actual final/first boundary without inserting silence.
    signal[-n:]+=np.linspace(0,signal[0]-signal[-1],n)
    signal*=.22/max(.001,np.max(np.abs(signal)))
    destination=ROOT/'game-godot/assets/audio/elemental_v1'/fid/'charged_ambience.wav'
    if destination.exists():raise SystemExit('Refusing to overwrite '+str(destination))
    with wave.open(str(destination),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes((signal*32767).astype('<i2').tobytes())
    rows.append(dict(fighter=fid,path=str(destination.relative_to(ROOT)),sha256=hashlib.sha256(destination.read_bytes()).hexdigest(),sources=[dict(path=str(p.relative_to(ROOT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in sources],seconds=len(signal)/rate,peak=float(np.max(np.abs(signal))),seam_delta=float(abs(signal[0]-signal[-1]))))
(ROOT/'art_source/audio/elemental_v1/CHARGED_AMBIENCE_PROVENANCE.json').write_text(json.dumps(dict(generator='tools/audio/generate_charged_ambience.py',origin='Derivative of repository-owned original procedural synthesis; no sampled third-party audio, TTS or paid provider',license='Project original source; same owner rights as elemental_v1 stems. Human mix approval remains false.',runtime='One quiet owned loop after release; existing charge and impact sounds retained',rows=rows),indent=2)+'\n')

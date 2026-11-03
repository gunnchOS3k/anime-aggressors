"""Free, local formant preview. Assets intentionally excluded from distribution."""
import hashlib,json,re,subprocess,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game-godot/assets/audio/story_temp'; OUT.mkdir(parents=True,exist_ok=True)
PROFILES={
'ember-vale':('en-us+f3',174,59,1,'Forward, warm and decisive; controlled heat.'),
'juno-spark':('en-us+f4',195,65,1,'Fast precision; clear snaps, space after decisions.'),
'kaia-windrow':('en-us+f2',154,53,5,'Fluid, reflective breath and purposeful resolve.'),
'nix-calder':('en-gb+f1',150,51,4,'Measured, precise and restrained.'),
'vesper-nyx':('en-gb+f5',165,45,4,'Quiet, deliberate misdirection with honest grief.'),
'rook-ironside':('en-us+m3',135,32,6,'Grounded weight, short commitments; never caricature.'),
'orion-vell':('en-gb+m2',140,41,5,'Patient, spatial clarity; Last Vector is unresolved fate.'),
'yin':('en-gb+m1',116,25,6,'Subtraction, space and deep controlled silence.'),
'yang':('en-us+m4',154,52,3,'Structured definition and exact harmonic conviction.')}
PRON={'Kaia':'Kai ah','Juno':'Joo no','Nix':'Nicks','Orion':'Oh rye un','Vesper':'Ves per','Yin':'Yin','Yang':'Yang'}
engine='/opt/homebrew/bin/espeak-ng'
version=subprocess.check_output([engine,'--version'],text=True).strip()
cues=json.loads((ROOT/'game-godot/data/story/dialogue/v1/cues.json').read_text())['cues']
rows=[]
for cid,cue in cues.items():
    voice,speed,pitch,gap,direction=PROFILES[cue['speaker_id']]
    emotion=cue['performance']
    if emotion in ('grief','soft'): speed=round(speed*.86); gap+=3
    if emotion=='strained': speed=round(speed*.94); pitch+=3
    spoken=cue['subtitle']
    for term,sound in PRON.items(): spoken=re.sub(r'\b'+term+r'\b',sound,spoken)
    target=OUT/(cid+'.wav')
    subprocess.run([engine,'--stdin','-v',voice,'-s',str(speed),'-p',str(pitch),'-g',str(gap),'-a','65','-w',str(target)],input=spoken,text=True,check=True)
    with wave.open(str(target)) as wav: seconds=wav.getnframes()/wav.getframerate()
    rows.append({'cue_id':cid,'speaker_id':cue['speaker_id'],'subtitle':cue['subtitle'],'spoken_text':spoken,'emotion':emotion,'words_per_minute':speed,'pitch':pitch,'word_gap':gap,'voice':voice,'path':cue['voice_asset'],'seconds':round(seconds,3),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'status':'LOCAL_DEVELOPMENT_ONLY','public_distribution_authorized':False})
metadata={'engine':version,'license':'GPL-3.0-or-later','source':'https://github.com/espeak-ng/espeak-ng','license_url':'https://raw.githubusercontent.com/espeak-ng/espeak-ng/master/COPYING','scope':'Unmodified local execution; output redistribution clearance deferred. Never included in source PR or exported builds.','paid_api_cost':0,'recognizable_performance_imitation':False,'human_voice_models':False,'presentation_variants_share_profile':True,'profiles':{k:dict(zip(('voice','speed','pitch','gap','direction'),v)) for k,v in PROFILES.items()},'pronunciation':PRON,'assets':rows}
report=ROOT/'artifacts/v1_closure/dialogue_performance/temporary_voice_manifest.json';report.write_text(json.dumps(metadata,indent=2)+'\n')
docs=ROOT/'docs/anime-aggressors/v1_closure/dialogue_production/VOICE_DIRECTION.md'
docs.write_text('# Temporary voice direction\n\nDevelopment previews only. Formant synthesis is intentionally temporary; emotional intent is metadata, not completed acting. Each character retains one profile across presentation variants. Stable cue IDs and subtitle text remain unchanged when actors replace these files.\n\n'+ '\n'.join(f'## {k}\n\n{v[4]}\n\nGeneric formant {v[0]}; {v[1]} wpm, pitch {v[2]}, gap {v[3]}. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.\n' for k,v in PROFILES.items())+'\nPronunciations: '+json.dumps(PRON)+'.\n\nLicense: eSpeak NG GPL-3.0-or-later, unmodified local execution. Generated audio remains local and is excluded from public distribution pending explicit output clearance. See the per-cue provenance manifest. Cost: zero.\n')
print(json.dumps({'generated':len(rows),'bytes':sum(p.stat().st_size for p in OUT.glob('*.wav')),'voices':len(PROFILES)}))

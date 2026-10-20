"""Verify/derive a bounded native two-public-controller movie; never relabel as CPU play."""
import argparse, hashlib, json, re, subprocess, tempfile
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--output', type=Path, required=True)
p.add_argument('--raw', type=Path, required=True)
p.add_argument('--movie', type=Path, required=True)
a = p.parse_args()
out, raw, movie = a.output.resolve(), a.raw.resolve(), a.movie.resolve()
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
d = json.loads((out/'projectile_public_inputs.json').read_text())
launch = json.loads((out/'launch_manifest.json').read_text())
assert d['controls_enabled'] == [True, True] and len(d['history']) >= 2
assert not movie.exists(), 'Existing evidence preserved'
pixels = np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(raw),'-vf','crop=240:24:20:190,format=gray','-f','rawvideo','-']), dtype=np.uint8).reshape(-1,24,240)
bits = np.array([pixels[:,8:16,i*12+2:i*12+8].mean(axis=(1,2)) > 127 for i in range(20)]).T
codes = (bits * 2**np.arange(20)).sum(axis=1)
lookup = {}
for frame, code in enumerate(codes): lookup.setdefault(int(code), []).append(frame)
mapping = {}; checks = []
for stamp in d['frame_stamps']:
    observed = stamp['trace_frame']; found = lookup.get(observed, [])
    native = min(found, key=lambda f:abs(f-observed)) if found else None
    checks.append({'trace_frame':observed,'native_frame':native,'PASS':native is not None})
    if native is not None: mapping[observed] = native
assert checks and all(c['PASS'] for c in checks), 'Preserve failed frame verification'
subprocess.run(['ffmpeg','-v','error','-n','-i',str(raw),'-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)], check=True)
streams = json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_type,r_frame_rate,duration','-of','json',str(movie)], text=True))['streams']
assert {s['codec_type'] for s in streams} == {'video','audio'} and streams[0]['r_frame_rate'] == '60/1'
audio = subprocess.run(['ffmpeg','-hide_banner','-i',str(movie),'-af','volumedetect','-f','null','-'], capture_output=True, text=True, check=True).stderr
volume = {k:float(v) for k,v in re.findall(r'(mean_volume|max_volume):\s*(-?\d+(?:\.\d+)?) dB',audio)}
assert volume.get('max_volume',-100) > -80
(out/'AUDIO_VERIFICATION.log').write_text(audio)
sheet = Image.new('RGB',(1920,800),(16,20,29)); draw = ImageDraw.Draw(sheet)
selected = []
with tempfile.TemporaryDirectory(prefix='aa-clash-frames-') as scratch:
    for row, event in enumerate(d['history'][:2]):
        emission = next(e for e in d['presentation_history'] if e['event_id'].startswith(event['event_id']) and e['kind'] not in [18,19])
        trace = emission['process_frame'] - 1
        nearest = min(mapping, key=lambda x:abs(x-trace)); center = mapping[nearest]
        for col, delta in enumerate([-2,1,7]):
            frame = max(0,min(len(pixels)-1,center+delta)); png = Path(scratch)/f'{row}_{col}.png'
            subprocess.run(['ffmpeg','-v','error','-n','-i',str(movie),'-vf',f'select=eq(n\\,{frame}),scale=640:360','-frames:v','1',str(png)], check=True)
            x,y = col*640,row*400; sheet.paste(Image.open(png),(x,y))
            draw.text((x+8,y+364),f"{event['result']} | native {frame} | contact physics {event['physics_frame']}",fill='white')
            draw.text((x+8,y+382),launch['runtime_source_sha'][:12]+' | ordinary two-player inputs / native audio',fill='white')
            selected.append({'event_id':event['event_id'],'native_frame':frame,'physics_frame':event['physics_frame'],'emission_process_frame':emission['process_frame']})
target = out/'CONTACT_SHEET.png'; assert not target.exists(); sheet.save(target)
log = (out/'native_console.log').read_text()
assert 'SCRIPT ERROR' not in log and 'SHADER ERROR' not in log
report = {'verification_status':'VERIFIED_NATIVE60_AUDIO_FRAME_SOURCE','source_sha':launch['runtime_source_sha'],'movie':str(movie.relative_to(ROOT)),'raw_local_only':str(raw.relative_to(ROOT)),'raw_sha256':sha(raw),'movie_sha256':sha(movie),'trace_sha256':sha(out/'projectile_public_inputs.json'),'matched_frames':len(checks),'container_frames':len(pixels),'checks':checks,'audio_volume_db':volume,'streams':streams,'contact_sheet':str(target.relative_to(ROOT)),'contact_sheet_sha256':sha(target),'selected_frames':selected,'scope':'two automated public-input controllers; earned aura, real native collisions; no CPU/human visual acceptance or sustained-device FPS claim','redistribution':'Original project assets/audio, owner development review only; no release authorization'}
(out/'NATIVE_MOVIE.json').write_text(json.dumps(report,indent=2)+'\n')
state = json.loads((out/'RECORDING_STATE.json').read_text()); state['process_status_at_verification'] = state['status']; state['status'] = report['verification_status']; state['native_verification'] = report['verification_status']; (out/'RECORDING_STATE.json').write_text(json.dumps(state,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['verification_status','source_sha','movie','matched_frames','container_frames','audio_volume_db','contact_sheet']}))

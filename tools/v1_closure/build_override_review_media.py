"""Assemble original rendered evidence and actual runtime SFX receipts for owner review."""
import json,math,wave,struct,subprocess
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[2];V=R/'artifacts/v1_closure/review';O=V/'owner_override'
FIDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
EXP=['neutral','battle_intent','attack_effort','pain','shock','fear','grief','determination','victory','defeat','cinematic_closeup']
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',20)
headfont=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',26)
def sheet(kind,variants,before=False):
 canvas=Image.new('RGB',(1440,1080),(16,19,28));draw=ImageDraw.Draw(canvas)
 for i,fid in enumerate(FIDS):
  x=i%3*480;y=i//3*360;draw.text((x+12,y+10),fid.replace('-',' ').title(),font=headfont,fill=(236,241,255))
  for j,v in enumerate(variants):
   if kind=='silhouettes':p=O/'silhouettes'/fid/v/'front.png'
   else:p=(O/'before' if before and j==0 else V)/'renders'/fid/v/'BASE'/'three_quarter.png'
   im=Image.open(p).convert('RGBA').resize((225,260))
   if kind=='silhouettes':bg=Image.new('RGBA',im.size,(215,224,238,255));bg.alpha_composite(im);im=bg
   canvas.paste(im.convert('RGB'),(x+12+j*237,y+52))
   draw.text((x+16+j*237,y+320),('Before' if j==0 else 'After') if before else v,font=font,fill=(187,199,222))
 return canvas
sheet('hair',['female','female'],True).save(O/'female_hair_before_after.png')
sheet('elemental',['male','male'],True).save(O/'elemental_before_after.png')
sheet('silhouettes',['male','female']).save(O/'silhouette_sheet.png')
for fid in FIDS:
 for variant in ['male','female']:
  paths=[O/'expressions'/fid/variant/(e+'.png') for e in EXP]
  if not all(p.exists() for p in paths):continue
  canvas=Image.new('RGB',(1536,760),(16,19,28));draw=ImageDraw.Draw(canvas)
  draw.text((15,12),f'{fid.replace("-"," ").title()} / {variant} — real Godot facial morph candidates',font=headfont,fill=(236,241,255))
  for i,p in enumerate(paths):
   x=i%6*256;y=55+i//6*345;im=Image.open(p).convert('RGBA')
   bg=Image.new('RGBA',im.size,(38,46,66,255));bg.alpha_composite(im);canvas.paste(bg.convert('RGB'),(x,y))
   draw.text((x+8,y+320),EXP[i].replace('_',' '),font=font,fill=(187,199,222))
  canvas.save(O/'expressions'/fid/(variant+'_sheet.png'))
manifest=O/'capture_manifest.json'
if manifest.exists():
 capture=json.loads(manifest.read_text());frames=sorted((O/'ova/frames').glob('*.png'));fps=capture['video_capture_fps']
 rate=44100;mix=[0.]*(int((len(frames)/fps+2)*rate))
 for cue in capture['audio_events']:
  p=R/'game-godot/assets/audio/collectible_v1'/cue['fighter_id']/(cue['event']+'.wav')
  with wave.open(str(p),'rb') as w:
   assert w.getnchannels()==1 and w.getsampwidth()==2
   source_rate=w.getframerate();raw=w.readframes(w.getnframes());samples=struct.unpack('<'+'h'*(len(raw)//2),raw)
  start=int(cue['frame']/fps*rate)
  for i in range(int(len(samples)*rate/source_rate)):
   offset=start+i
   if offset<len(mix):mix[offset]+=samples[min(len(samples)-1,int(i*source_rate/rate))]/32768*.50
 pcm=bytearray()
 for value in mix:pcm.extend(struct.pack('<h',int(math.tanh(value)*.82*32767)))
 audio=O/'ova/candidate_event_mix.wav'
 with wave.open(str(audio),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(pcm)
 dest=O/'ova/kaia_preview.mp4'
 subprocess.run(['/opt/homebrew/bin/ffmpeg','-y','-framerate',str(fps),'-i',str(O/'ova/frames/%04d.png'),'-i',str(audio),'-vf','scale=960:540','-c:v','libx264','-pix_fmt','yuv420p','-crf','23','-c:a','aac','-b:a','160k','-shortest','-movflags','+faststart',str(dest)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 capture['assembled_movie']='owner_override/ova/kaia_preview.mp4';capture['captured_frames']=len(frames);capture['event_mix_cues']=len(capture['audio_events']);manifest.write_text(json.dumps(capture,indent=2)+'\n')
print('Override review sheets assembled; movie uses actual runtime event receipts if capture exists.')

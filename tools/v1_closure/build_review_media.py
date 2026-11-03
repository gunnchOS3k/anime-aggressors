"""Assemble existing Blender and real-Godot review frames; no invented runtime proof."""
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];REVIEW=ROOT/'artifacts/v1_closure/review'
ids=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',24)
sheet=Image.new('RGB',(1440,990),(16,19,28));draw=ImageDraw.Draw(sheet)
for i,fid in enumerate(ids):
 x=(i%3)*480;y=(i//3)*330
 draw.text((x+15,y+10),fid.replace('-',' ').title(),fill=(237,241,255),font=font)
 for j,variant in enumerate(['male','female']):
  im=Image.open(REVIEW/f'renders/{fid}/{variant}/BASE/front.png').convert('RGB').resize((225,225))
  sheet.paste(im,(x+12+j*237,y+52));draw.text((x+20+j*237,y+283),variant,fill=(177,190,213),font=font)
sheet.save(REVIEW/'roster_sheet.png')
animations=[]
for fid in ids:
 for clip in ['turntable','jab_1','heavy_attack','side_special','aura_burst']:
  directory=REVIEW/'runtime'/fid/clip;paths=sorted(directory.glob('*.png'))
  expected=16 if clip=='turntable' else 12
  if len(paths)!=expected:continue
  images=[Image.open(p).convert('RGB').resize((768,432)).quantize(colors=128) for p in paths]
  destination=directory.parent/(clip+'.gif');images[0].save(destination,save_all=True,append_images=images[1:],duration=110 if clip=='turntable' else 80,loop=0,optimize=True)
  animations.append({'fighter_id':fid,'clip':clip,'frames':len(paths),'path':str(destination.relative_to(ROOT)),'scope':'Candidate/staged shipping-scene capture; not complete form lifecycle or human taste.'})
(REVIEW/'media_manifest.json').write_text(json.dumps({'animations':animations,'roster_sheet':'roster_sheet.png','owner_approved':False},indent=2)+'\n')
print('REVIEW_MEDIA',len(animations))

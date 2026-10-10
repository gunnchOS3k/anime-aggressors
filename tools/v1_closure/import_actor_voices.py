"""Validate explicitly cleared owner-provided replacement assets by stable cue ID."""
import argparse,json,hashlib,shutil,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--manifest',type=Path,required=True);a=p.parse_args()
cues=json.loads((ROOT/'game-godot/data/story/dialogue/v1/cues.json').read_text())['cues']
metadata=json.loads(a.manifest.read_text());assets={}
for row in metadata['assets']:
 cid=row['cue_id'];assert cid in cues and cid not in assets,cid
 assert row.get('distribution_cleared') is True and row.get('owner_asset_authorized') is True,'Explicit asset authorization and license clearance required'
 assert row.get('license_provenance') and row.get('performer_consent') and row.get('rights_holder'),'Missing rights evidence'
 assert row['subtitle']==cues[cid]['subtitle'],'Subtitle mismatch'
 source=(a.manifest.parent/row['file']).resolve();assert source.suffix.lower()=='.wav'
 with wave.open(str(source)) as w:assert w.getsampwidth()==2 and w.getnchannels() in (1,2);seconds=w.getnframes()/w.getframerate()
 target=ROOT/'game-godot/assets/audio/story_production'/(cid+'.wav')
 assets[cid]={**row,'path':'res://assets/audio/story_production/'+cid+'.wav','sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'duration_seconds':seconds,'speaker_id':cues[cid]['speaker_id'],'emotion':cues[cid]['performance']}
# Validate the entire manifest before any source mutation.
for cid,row in assets.items():
 source=(a.manifest.parent/row['file']).resolve();target=ROOT/'game-godot/assets/audio/story_production'/(cid+'.wav');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
path=ROOT/'game-godot/data/story/dialogue/v1/voice_assets.json'
existing=json.loads(path.read_text());existing['assets'].update(assets);path.write_text(json.dumps(existing,indent=2)+'\n')
print(json.dumps({'imported':len(assets),'campaign_logic_changed':False,'final_dialogue_approved':False}))

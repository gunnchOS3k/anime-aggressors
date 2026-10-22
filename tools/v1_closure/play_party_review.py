"""Isolated item/ultimate/PerfectGuard review. No recording/export or owner saves."""
import argparse,os,sys,json,hashlib
from datetime import datetime,timezone
from pathlib import Path
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
p=argparse.ArgumentParser()
p.add_argument('fighter',choices=IDS,nargs='?',default='kaia-windrow')
p.add_argument('--opponent',choices=IDS,default='juno-spark')
p.add_argument('--body',choices=['male','female'],default='female')
p.add_argument('--item',choices=['prism_heart','black_seal','white_seal'],default='prism_heart')
p.add_argument('--shield-break-candidate',action='store_true',help='Opt into isolated 66-frame/45% shield-break tuning candidate; no saved/global changes')
p.add_argument('--local',action='store_true');p.add_argument('--smoke',action='store_true',help=argparse.SUPPRESS)
p.add_argument('--source-controls-8d',action='store_true',help='Review verified saved18-rig hand/secondary-control candidates; no regular save changes')
p.add_argument("--source-hands-8d2",action="store_true",help="Opt into separately verified original connected-hand candidates")
a=p.parse_args();root=Path(__file__).resolve().parents[2]
if a.source_controls_8d and a.source_hands_8d2:p.error("Choose one source-art review lane")
if a.source_controls_8d or a.source_hands_8d2:
 lane="hands_8d2"if a.source_hands_8d2 else"controls_8d"
 for fighter_id in {a.fighter,a.opponent}:
  data=root/f'game-godot/data/animation/{lane}/{fighter_id}_{a.body}.json'
  if not data.is_file():p.error('8D exports are not installed; baseline review remains available without --source-controls-8d')
  doc=json.loads(data.read_text());asset=root/'game-godot'/doc['resource'].removeprefix('res://')
  if not asset.is_file()or hashlib.sha256(asset.read_bytes()).hexdigest()!=doc['resource_sha256']:p.error('8D candidate export verification failed; refusing silent fallback')
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+str(os.getpid())
out=root/'artifacts/v1_closure/spectral_feedback/local_media/party_owner_review'/stamp
cmd=[sys.executable,str(root/'tools/v1_closure/launch_ordinary_review.py'),'--profile','party_candidate_'+a.fighter,'--output',str(out),'--test-script','res://tests/v1_closure/PartyPlayableReview.gd','--driver-arg=--party-fighter='+a.fighter,'--driver-arg=--party-opponent='+a.opponent,'--driver-arg=--party-body='+a.body,'--driver-arg=--party-item='+a.item]
if a.shield_break_candidate:cmd+=['--driver-arg=--shield-break-candidate']
if a.local:cmd+=['--driver-arg=--party-local']
if a.source_controls_8d:cmd+=['--driver-arg=--source-controls-8d']
if a.source_hands_8d2:cmd+=['--driver-arg=--source-hands-8d2']
if a.smoke:cmd+=['--headless','--driver-arg=--party-smoke']
os.chdir(root);os.execv(sys.executable,cmd)

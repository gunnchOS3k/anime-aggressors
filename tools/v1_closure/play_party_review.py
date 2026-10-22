"""Isolated item/ultimate/PerfectGuard review. No recording/export or owner saves."""
import argparse,os,sys
from datetime import datetime,timezone
from pathlib import Path
IDS=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
p=argparse.ArgumentParser()
p.add_argument('fighter',choices=IDS,nargs='?',default='kaia-windrow')
p.add_argument('--opponent',choices=IDS,default='juno-spark')
p.add_argument('--body',choices=['male','female'],default='female')
p.add_argument('--item',choices=['prism_heart','black_seal','white_seal'],default='prism_heart')
p.add_argument('--local',action='store_true');p.add_argument('--smoke',action='store_true',help=argparse.SUPPRESS)
a=p.parse_args();root=Path(__file__).resolve().parents[2]
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+str(os.getpid())
out=root/'artifacts/v1_closure/spectral_feedback/local_media/party_owner_review'/stamp
cmd=[sys.executable,str(root/'tools/v1_closure/launch_ordinary_review.py'),'--profile','party_candidate_'+a.fighter,'--output',str(out),'--test-script','res://tests/v1_closure/PartyPlayableReview.gd','--driver-arg=--party-fighter='+a.fighter,'--driver-arg=--party-opponent='+a.opponent,'--driver-arg=--party-body='+a.body,'--driver-arg=--party-item='+a.item]
if a.local:cmd+=['--driver-arg=--party-local']
if a.smoke:cmd+=['--headless','--driver-arg=--party-smoke']
os.chdir(root);os.execv(sys.executable,cmd)

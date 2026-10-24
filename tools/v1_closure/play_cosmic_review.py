"""Owner-playable isolated candidate selection, preserving campaign unlocks/saves."""
import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('fighter',choices=['yin','yang'],nargs='?',default='yin')
p.add_argument('--opponent',default='juno-spark',choices=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang'])
p.add_argument('--body',choices=['male','female'],default='female')
p.add_argument('--local',action='store_true')
p.add_argument('--smoke',action='store_true',help=argparse.SUPPRESS)
a=p.parse_args();root=Path(__file__).resolve().parents[2]
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+str(os.getpid())
out=root/'artifacts/v1_closure/spectral_feedback/local_media/cosmic_owner_review'/stamp
cmd=[sys.executable,str(root/'tools/v1_closure/launch_ordinary_review.py'),'--profile','cosmic_candidate_'+a.fighter,'--output',str(out),'--test-script','res://tests/v1_closure/CosmicPlayableReview.gd','--driver-arg=--cosmic-fighter='+a.fighter,'--driver-arg=--cosmic-opponent='+a.opponent,'--driver-arg=--cosmic-body='+a.body]
if a.local:cmd+=['--driver-arg=--cosmic-local']
if a.smoke:cmd+=['--headless','--driver-arg=--cosmic-smoke']
os.chdir(root);os.execv(sys.executable,cmd)

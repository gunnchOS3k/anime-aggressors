"""Manual isolated native review. Each launch preserves its own logs; no save seeding."""
import argparse
import os
from pathlib import Path
import sys
from datetime import datetime, timezone

p = argparse.ArgumentParser()
p.add_argument('--local', action='store_true', help='Two ordinary local players instead of active CPU')
p.add_argument('--male', action='store_true', help='Use the existing male models')
p.add_argument('--clash-indicators', action='store_true', help='Opt-in confirmed interception counter and outcome; no gameplay changes')
p.add_argument('--melee', action='store_true', help='Show compact-strike review controls in a separate isolated profile')
p.add_argument('--smoke', action='store_true', help=argparse.SUPPRESS)
a = p.parse_args()
root = Path(__file__).resolve().parents[2]
output = root / ('artifacts/v1_closure/spectral_feedback/local_media/melee_owner_review' if a.melee else 'artifacts/v1_closure/spectral_feedback/local_media/projectile_owner_review') / (datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '_' + str(os.getpid()))
cmd = [sys.executable, str(root / 'tools/v1_closure/launch_ordinary_review.py'), '--profile', 'ani03_melee_manual1020' if a.melee else 'ani03_projectile_manual1020', '--output', str(output), '--test-script', 'res://tests/v1_closure/ProjectilePlayableReview.gd']
if a.melee: cmd += ['--driver-arg=--melee-owner-review']
if a.local: cmd += ['--driver-arg=--projectile-review-local']
if a.male: cmd += ['--driver-arg=--projectile-review-male']
if a.clash_indicators: cmd += ['--driver-arg=--clash-indicators']
if a.smoke: cmd += ['--headless', '--driver-arg=--projectile-review-smoke']
os.chdir(root)
os.execv(sys.executable, cmd)

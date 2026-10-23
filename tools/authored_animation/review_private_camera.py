#!/usr/bin/env python3
"""Review private camera source using the existing isolated watch launcher.

Default is validation/command inspection only. --launch still requires the
18 GiB reserve AFTER an 800 MiB import forecast; no recording/export option.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GIB = 1024 ** 3


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--library', required=True, type=Path)
    parser.add_argument('--route', default='kaia-windrow')
    parser.add_argument('--body', choices=['male', 'female'], default='female')
    parser.add_argument('--launch', action='store_true')
    parser.add_argument('--smoke',action='store_true',help='Bounded native watch controls and two PRIVATE stills; never earned gameplay')
    args = parser.parse_args()
    path = args.library.resolve()
    if path.is_relative_to(ROOT):
        parser.error('Keep authored camera source outside the public checkout')
    library = json.loads(path.read_text())
    nodes = json.loads((ROOT / 'game-godot/data/story/dialogue/v1/nodes.json').read_text())['nodes']
    cue_hash = hashlib.sha256((ROOT / 'game-godot/data/story/dialogue/v1/cues.json').read_bytes()).hexdigest()
    if library.get('schema') != 'anime.private_camera_library.v1' or library.get('public_disclosure_authorized') is not False or library.get('candidate_only') is not True or library.get('canonical_cues_sha256') != cue_hash:
        parser.error('Private source/canonical authority mismatch')
    node = args.route + ':first_loss'
    if node not in library['nodes'] or node not in nodes:
        parser.error('No authored canonical First Loss take for this route')
    entry = library['nodes'][node]
    resource = (path.parent / entry['path']).resolve()
    if not resource.is_relative_to(path.parent) or entry['ordered_cues'] != nodes[node]['ordered_cues'] or hashlib.sha256(resource.read_bytes()).hexdigest() != entry['sha256']:
        parser.error('Camera resource path/hash/cue order mismatch')
    volume = '/System/Volumes/Data' if Path('/System/Volumes/Data').is_dir() else ROOT
    free = shutil.disk_usage(volume).free
    forecast = (800+16*int(args.smoke)) * 1024 ** 2
    allowed = free >= 18 * GIB + forecast
    suffix=('_smoke_'+subprocess.check_output(['git','rev-parse','--short=8','HEAD'],cwd=ROOT,text=True).strip())if args.smoke else ''
    output = path.parent / 'owner_play_sessions' / (args.route + '_' + args.body+suffix)
    command = [sys.executable, str(ROOT / 'tools/v1_closure/launch_ordinary_review.py'),
               '--profile', 'private_camera_' + args.route.replace('-', '_') + '_' + args.body+suffix,
               '--output', str(output), '--test-script', 'res://tests/v1_closure/PrivateCameraPlayableReview.gd',
               '--driver-arg=--private-cinematic-camera=' + str(path),
               '--driver-arg=--camera-review-route=' + args.route,
               '--driver-arg=--camera-review-body=' + args.body]
    if args.smoke:command.append('--driver-arg=--camera-review-smoke')
    print(json.dumps({'camera_source_verified': True, 'watch_only': True, 'recording': False,
                      'free_internal_GiB': round(free / GIB, 3), 'required_reserve_GiB': 18,
                      'import_forecast_bytes': forecast, 'launch_allowed': allowed, 'command': command}))
    if args.launch:
        if not allowed:
            raise SystemExit('Review not launched: 18 GiB plus 800 MiB import forecast required. No files or saves changed.')
        if args.smoke and output.exists():raise SystemExit('Existing native review preserved; use a new source checkpoint rather than overwriting it')
        listing=subprocess.run(['ps','-axo','comm='],capture_output=True,text=True)
        if listing.returncode or any(Path(name.strip()).name.lower().startswith(('godot','blender','ffmpeg'))for name in listing.stdout.splitlines()):
            raise SystemExit('Cannot establish serial native review ownership; existing media processes preserved')
        return subprocess.call(command, cwd=ROOT)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

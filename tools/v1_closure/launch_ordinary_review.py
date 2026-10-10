"""Launch the actual main scene with a separate user:// identity, never owner saves.

Only the project name and optional observation/input autoload differ. All resources
are symlinks to the current source; no exported build or gameplay overrides.
"""
import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--profile', required=True, help='Stable isolated identity; reuse to resume')
p.add_argument('--automate', action='store_true')
p.add_argument('--headless', action='store_true')
p.add_argument('--output', type=Path, default=ROOT/'artifacts/v1_closure/ordinary_review')
p.add_argument('--resume', action='store_true')
p.add_argument('--max-nodes', type=int, default=20)
p.add_argument('--route', default='kaia-windrow')
p.add_argument('--replay', default='', help='Comma-separated already earned chapter IDs')
p.add_argument('--video-frames', action='store_true', help='Capture a bounded 12-second renderer sequence per chapter')
p.add_argument('--prepare-only', action='store_true')
a = p.parse_args()
if not re.fullmatch(r'[a-zA-Z0-9_-]{1,64}', a.profile):
    p.error('Profile must be 1–64 letters, numbers, underscores or hyphens')
project = Path(tempfile.mkdtemp(prefix='aa-ordinary-review-'))
source = ROOT/'game-godot'
for child in source.iterdir():
    if child.name not in ('project.godot', 'override.cfg'):
        (project/child.name).symlink_to(child, target_is_directory=child.is_dir())
config = (source/'project.godot').read_text()
config = config.replace('config/name="Anime Aggressors"', 'config/name="Anime Aggressors Review '+a.profile+'"')
if a.automate:
    config = config.replace('[autoload]\n', '[autoload]\nOrdinaryInputReview="*res://tests/v1_closure/OrdinaryInputReview.gd"\n')
(project/'project.godot').write_text(config)
a.output.mkdir(parents=True, exist_ok=True)
cmd = ['/opt/homebrew/bin/godot', '--path', str(project), '--log-file', str((a.output/'godot.log').resolve())]
if a.headless:
    cmd += ['--headless', '--fixed-fps', '60']
else:
    cmd += ['--rendering-method', 'gl_compatibility', '--windowed', '--resolution', '1280x720']
    if a.automate: cmd += ['--fixed-fps', '60', '--disable-vsync']
cmd += ['--', '--ordinary-output='+str(a.output.resolve())]
cmd += ['--ordinary-max-nodes='+str(a.max_nodes)]
cmd += ['--ordinary-route='+a.route]
if a.replay: cmd += ['--ordinary-replay='+a.replay]
if a.video_frames: cmd += ['--ordinary-video-frames']
if a.resume: cmd += ['--ordinary-resume']
print(json.dumps({'project':str(project), 'profile':a.profile, 'isolated_project_name':'Anime Aggressors Review '+a.profile, 'command':cmd}), flush=True)
if not a.prepare_only:
    raise SystemExit(subprocess.call(cmd))

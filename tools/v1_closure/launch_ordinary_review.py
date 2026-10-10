"""Launch the actual main scene with a separate user:// identity, never owner saves.

Only the project name and optional observation/input autoload differ. All resources
are symlinks to the current source; no exported build or gameplay overrides.
"""
import argparse
import json
import re
import subprocess
import tempfile
import hashlib
import hmac
import shutil
from datetime import datetime, timezone
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
p.add_argument('--seed-convergence-from', type=Path, help='EXPLICIT seeded-prerequisite test only; verified staged save, never owner data')
p.add_argument('--seeded-prerequisites', action='store_true', help='Keep seeded evidence labeled on subsequent resumes/replays')
p.add_argument('--prepare-only', action='store_true')
p.add_argument('--test-script', help='Run a targeted source regression with the same isolated user:// identity')
p.add_argument("--baseline-ref",help="Read-only source overlay for before/after capture; creates no worktree")
p.add_argument("--movie",type=Path,help="Bounded native Godot MovieWriter with real mixed audio")
p.add_argument("--movie-fps",type=int,choices=[30,60],default=30)
p.add_argument("--movie-frames",type=int,default=1800)
p.add_argument("--driver-arg",action="append",default=[])
a = p.parse_args()
if not re.fullmatch(r'[a-zA-Z0-9_-]{1,64}', a.profile):
    p.error('Profile must be 1–64 letters, numbers, underscores or hyphens')
wrapper = Path(tempfile.mkdtemp(prefix='aa-ordinary-review-'))
project = wrapper/'game-godot'
project.mkdir()
(wrapper/'artifacts').symlink_to(ROOT/'artifacts',target_is_directory=True)
source = ROOT/'game-godot'
for child in source.iterdir():
    if child.name not in ('project.godot', 'override.cfg'):
        (project/child.name).symlink_to(child, target_is_directory=child.is_dir())
if a.baseline_ref:
    # Copy small script files; preserve every real checkout and historical worktree.
    (project/'scripts').unlink()
    shutil.copytree(source/'scripts',project/'scripts')
    tracked=subprocess.check_output(['git','ls-tree','-r','--name-only',a.baseline_ref,'game-godot/scripts'],cwd=ROOT,text=True).splitlines()
    for path in tracked:
        target=project/Path(path).relative_to('game-godot')
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(subprocess.check_output(['git','show',a.baseline_ref+':'+path],cwd=ROOT))
    config=subprocess.check_output(['git','show',a.baseline_ref+':game-godot/project.godot'],cwd=ROOT,text=True)
else:
    config = (source/'project.godot').read_text()
config = config.replace('config/name="Anime Aggressors"', 'config/name="Anime Aggressors Review '+a.profile+'"')
if a.automate:
    config = config.replace('[autoload]\n', '[autoload]\nOrdinaryInputReview="*res://tests/v1_closure/OrdinaryInputReview.gd"\n')
# Source-review watermark is isolated from the preserved owner/export identity.
(project/'data').unlink()
(project/'data').mkdir()
for child in (source/'data').iterdir():
    if child.name != 'runtime': (project/'data'/child.name).symlink_to(child,target_is_directory=child.is_dir())
(project/'data/runtime').mkdir()
for child in (source/'data/runtime').iterdir():
    if child.name != 'build_identity.json': (project/'data/runtime'/child.name).symlink_to(child,target_is_directory=child.is_dir())
review_sha=subprocess.check_output(['git','rev-parse',a.baseline_ref or 'HEAD'],cwd=ROOT,text=True).strip()
identity=json.loads((source/'data/runtime/build_identity.json').read_text()) if (source/'data/runtime/build_identity.json').exists() else {}
identity.update(git_sha=review_sha,git_sha_short=review_sha[:12],git_short_sha=review_sha[:12],watermark='AA '+review_sha[:12],build_flavor='source-review-not-release',build_timestamp=datetime.now(timezone.utc).isoformat())
(project/'data/runtime/build_identity.json').write_text(json.dumps(identity,indent=2)+'\n')
(project/'project.godot').write_text(config)
a.output.mkdir(parents=True, exist_ok=True)
if a.seed_convergence_from:
    # This operation is excluded from ordinary earned play. It retains the seven
    # staged Gray routes, clears only Convergence, and labels every subsequent row.
    save = a.seed_convergence_from.resolve()
    envelope = json.loads(save.read_text())
    key = Path(str(save)+'.key').read_bytes()
    if not hmac.compare_digest(hmac.new(key,envelope['payload'].encode(),hashlib.sha256).hexdigest(),envelope['hmac_sha256']):
        raise SystemExit('Seed source authentication failed')
    progress = json.loads(envelope['payload'])
    if len(progress.get('gray_routes',[])) != 7:
        raise SystemExit('Seed source must contain seven staged Gray completions')
    target = Path.home()/'Library/Application Support/Godot/app_userdata'/('Anime Aggressors Review '+a.profile)
    if (target/'anime_v1_campaign.json').exists():
        raise SystemExit('Refusing to overwrite an existing profile')
    entry = progress['routes']['sevenfold-convergence']
    entry.update(cursor='sevenfold:reunion',completed=[],receipts={},recruited=[],essence=0,essence_fighters=[],released=[],form='BASE',complete=False,earned=False)
    progress.update(selected_route='sevenfold-convergence',yin_unlocked=False,yang_unlocked=False)
    payload = json.dumps(progress,separators=(',',':'),sort_keys=True)
    target.mkdir(parents=True,exist_ok=True)
    (target/'anime_v1_campaign.json.key').write_bytes(key)
    (target/'anime_v1_campaign.json').write_text(json.dumps({'payload':payload,'hmac_sha256':hmac.new(key,payload.encode(),hashlib.sha256).hexdigest()}))
    (a.output/'seed_provenance.json').write_text(json.dumps({'evidence_type':'SEEDED_PREREQUISITES','source':str(save),'source_sha256':hashlib.sha256(save.read_bytes()).hexdigest(),'seven_gray_routes':'STAGED_SOURCE_TEST','convergence_reset_for_normal_input_test':True,'ordinary_earned_campaign':False,'owner_data_used':False},indent=2)+'\n')
    a.resume = True
cmd = ['/opt/homebrew/bin/godot', '--path', str(project), '--log-file', str((a.output/'godot.log').resolve())]
if a.headless:
    cmd += ['--headless', '--fixed-fps', '60']
else:
    cmd += ['--rendering-method', 'gl_compatibility', '--windowed', '--resolution', '1280x720']
    if a.automate: cmd += ['--fixed-fps', '60', '--disable-vsync']
if a.movie:
    a.movie.parent.mkdir(parents=True,exist_ok=True)
    cmd += ['--write-movie',str(a.movie.resolve()),'--fixed-fps',str(a.movie_fps),'--quit-after',str(a.movie_frames)]
cmd += ['--', '--ordinary-output='+str(a.output.resolve())]
cmd += a.driver_arg
cmd += ["--source-sha="+subprocess.check_output(["git","rev-parse",a.baseline_ref or "HEAD"],cwd=ROOT,text=True).strip()]
if a.test_script:
    cmd[cmd.index('--'):cmd.index('--')] = ['--script',a.test_script]
cmd += ['--ordinary-max-nodes='+str(a.max_nodes)]
cmd += ['--ordinary-route='+a.route]
if a.replay: cmd += ['--ordinary-replay='+a.replay]
if a.video_frames: cmd += ['--ordinary-video-frames']
if a.seed_convergence_from or a.seeded_prerequisites: cmd += ['--ordinary-seeded-prerequisites']
if a.resume: cmd += ['--ordinary-resume']
print(json.dumps({'project':str(project), 'profile':a.profile, 'isolated_project_name':'Anime Aggressors Review '+a.profile, 'command':cmd}), flush=True)
(a.output/'launch_manifest.json').write_text(json.dumps({'project':str(project),'profile':a.profile,'command':cmd,'git_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'source_changes':subprocess.check_output(['git','diff','--name-only'],cwd=ROOT,text=True).splitlines(),'source_diff_sha256':hashlib.sha256(subprocess.check_output(['git','diff'],cwd=ROOT)).hexdigest(),'human_playthrough':False,'baseline_ref':a.baseline_ref,'runtime_source_sha':subprocess.check_output(['git','rev-parse',a.baseline_ref or 'HEAD'],cwd=ROOT,text=True).strip(),'seeded_prerequisites':bool(a.seed_convergence_from or a.seeded_prerequisites)},indent=2)+'\n')
if not a.prepare_only:
    raise SystemExit(subprocess.call(cmd))

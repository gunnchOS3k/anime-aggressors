#!/usr/bin/env python3
"""Encode locally retained current-renderer sequences; no game/art edits."""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--review-root', type=Path, default=Path('artifacts/v1_closure/ordinary_review'))
a = parser.parse_args()
root = a.review_root.resolve()
ffmpeg = shutil.which('ffmpeg')
ffprobe = shutil.which('ffprobe')
if not ffmpeg or not ffprobe:
    raise SystemExit('ffmpeg and ffprobe are required')
media = []
for folder in sorted(root.glob('render_83_*')):
    report_file = folder / 'ordinary_input_evidence.json'
    if not report_file.exists():
        report_file = folder / 'capture_excerpt_manifest.json'
    report = json.loads(report_file.read_text())
    identity = json.loads((folder / 'launch_manifest.json').read_text())
    if not report['ok'] and not report.get('capture_sample_available', False):
        raise SystemExit(f'Capture run failed: {folder.name}')
    for frames in sorted(folder.glob('frames_*')):
        files = sorted(frames.glob('frame_*.png'))
        if not files:
            continue
        output = folder / (frames.name.removeprefix('frames_') + '.mp4')
        cmd = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-framerate', '10', '-i', str(frames / 'frame_%04d.png'), '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(output)]
        subprocess.run(cmd, check=True)
        probe = json.loads(subprocess.check_output([ffprobe, '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(output)]))
        stream = probe['streams'][0]
        if stream['width'] != 1280 or stream['height'] != 720 or int(stream['nb_frames']) != len(files):
            raise SystemExit(f'Unexpected encoded frame metadata: {output.name}')
        media.append({'file': str(output.relative_to(root)), 'bytes': output.stat().st_size, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(), 'frame_count': len(files), 'duration_seconds': float(probe['format']['duration']), 'fps': '10', 'resolution': [1280,720], 'audio': False, 'raw_frames': str(frames.relative_to(root)), 'raw_disposition': 'Locally retained; ignored by Git, no deletion', 'raw_frame_hashes': {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in files}, 'evidence_type': report['evidence_type'], 'capture_identity': identity, 'normal_rules_gameplay_overrides': report['gameplay_overrides'], 'capture_run_state':report.get('capture_run_state','COMPLETED_REPLAY'), 'gameplay_completion_claimed':report.get('gameplay_completion_claimed',True)})
screenshots = [{'file':str(f.relative_to(root)), 'bytes':f.stat().st_size, 'sha256':hashlib.sha256(f.read_bytes()).hexdigest(), 'source_sha':'83bab0825230154761b39e1a7ff63eeacf66de8d', 'evidence_type':json.loads((f.parent / ('ordinary_input_evidence.json' if (f.parent / 'ordinary_input_evidence.json').exists() else 'capture_excerpt_manifest.json')).read_text())['evidence_type']} for f in sorted(root.glob('render_83_*/*.png'))]
manifest = {'screenshots':screenshots, 'media': media, 'scope': 'Actual Godot root-viewport renderer output sampled every six 60Hz frames, bounded to first 12 simulated seconds per encounter. Separate earned chapter replays, not a continuous campaign movie. Silent visual review only.', 'V1_AUTOMATED_READY': False, 'all_human_gates': False}
(root / 'media_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps({'clips':len(media), 'total_bytes':sum(m['bytes'] for m in media)}))

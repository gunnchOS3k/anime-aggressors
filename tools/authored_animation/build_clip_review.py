"""Build a private, versioned review of existing movies; never render or encode.

The movie manifest supplies exact paths and source clocks. No character data is
embedded in this template or uploaded. Preserve all original gallery/media files.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path


def build(manifest, output):
    data = json.loads(manifest.read_text())
    if not data.get('rows') or len({r['id'] for r in data['rows']}) != len(data['rows']):
        raise ValueError('Unique actual review selections required')
    if output.exists():
        raise ValueError('Preserve the existing review; select a new version')
    for row in data['rows']:
        for key in ('video', 'poster'):
            path = (output.parent / row[key]).resolve(strict=True)
            if not path.is_relative_to(Path('/Volumes/gunnchos-private-art')):
                raise ValueError('Private review cannot reference artwork outside the encrypted workspace')
        previous = 0.0
        for chapter in row['chapters']:
            if chapter['start'] < previous or chapter['end'] <= chapter['start']:
                raise ValueError('Invalid source-bound chapter intervals')
            previous = chapter['end']
    template = Path(__file__).with_name('clip_review.html').read_text()
    payload = json.dumps(data, ensure_ascii=False).replace('<', '\\u003c')
    os.umask(0o077)
    output.write_text(template.replace('__REVIEW_DATA__', payload))
    return {'review': str(output), 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
            'selections': len(data['rows']), 'media_reencoded': False, 'human_approved': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    print(json.dumps(build(args.manifest, args.output), indent=2))

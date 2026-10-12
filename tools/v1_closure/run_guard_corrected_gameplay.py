"""Bounded replacements for the guard-defect cohort and one rotating roster pass."""
import argparse,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--suffix',required=True);a=p.parse_args()
assert a.suffix.replace('_','').isalnum()
ids=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
labels=[f'{fid}_aerial-light_high_{a.suffix}' for fid in ids]
labels += [f'{fid}_{recipe}_{band}_{a.suffix}' for fid,recipe,band in [('rook-ironside','light-heavy','high'),('yin','aerial-light','medium'),('yang','aerial-light','medium'),('yang','light-heavy','high'),('ember-vale','edgeguard-throw','high')]]
subprocess.run(['python3','tools/v1_closure/probe_spectral_combos.py',*labels,'--suffix',a.suffix],cwd=ROOT,check=True)
subprocess.run(['python3','tools/v1_closure/analyze_combo_probes.py'],cwd=ROOT,check=True)

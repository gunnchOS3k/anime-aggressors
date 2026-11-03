"""Bounded serial full-roster public-input pass, followed by affected integration checks."""
import argparse,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--suffix',required=True);p.add_argument('--integration-label',required=True);a=p.parse_args()
assert a.suffix.replace('_','').isalnum()
roster=['ember-vale','rook-ironside','juno-spark','kaia-windrow','nix-calder','orion-vell','vesper-nyx','yin','yang']
labels=[f'{fid}_{recipe}_{band}_{a.suffix}' for fid in roster for band in ['medium','high'] for recipe in ['light-heavy','aerial-light']]
subprocess.run(['python3','tools/v1_closure/probe_spectral_combos.py',*labels,'--suffix',a.suffix],cwd=ROOT,check=True)
subprocess.run(['python3','tools/v1_closure/analyze_combo_probes.py'],cwd=ROOT,check=True)
subprocess.run(['python3','tools/v1_closure/validate_continuous_combat.py','--label',a.integration_label,'RosterFootwork','SpectralFeedback','ChargeContinuity','ElementalPerformance','FullCampaign','ShippingRosterPath','CampaignRestart','DialogueProduction','OwnerOverrideFaces'],cwd=ROOT,check=True)

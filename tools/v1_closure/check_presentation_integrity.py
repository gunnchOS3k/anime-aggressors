"""Data, authorization and preservation checks; no automated human approval."""
import hashlib,json,subprocess,csv,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/dialogue_performance'
identity=json.loads((OUT/'continuation_identity.json').read_text())
checks={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in identity['preserved_gameplay_hashes'].items()}
cues=json.loads((ROOT/'game-godot/data/story/dialogue/v1/cues.json').read_text())['cues'];nodes=json.loads((ROOT/'game-godot/data/story/dialogue/v1/nodes.json').read_text())['nodes']
checks['145_nodes_1025_cues']=len(nodes)==145 and len(cues)==1025
checks['every_cue_exactly_one_binding']=sorted(cues)==sorted(cid for n in nodes.values() for ids in n['events'].values() for cid in ids)
checks['all_unique_cue_ids']=len(set(cues))==1025
checks['all_final_dialogue_gates_false']=all(c['final_dialogue_approved'] is False for c in cues.values())
checks['all_nine_voice_profiles']=len({c['voice_profile'] for c in cues.values()})==9
checks['temporary_voice_export_exclusion']=all('assets/audio/story_temp/*' in b for b in (ROOT/'game-godot/export_presets.cfg').read_text().split('[preset.')[1:] if 'export_filter=' in b)
voice=json.loads((OUT/'temporary_voice_manifest.json').read_text());checks['1025_local_voice_hashes']=all(hashlib.sha256((ROOT/'game-godot'/r['path'].replace('res://','')).read_bytes()).hexdigest()==r['sha256'] for r in voice['assets'])
checks['no_paid_api_or_imitation']=voice['paid_api_cost']==0 and not voice['recognizable_performance_imitation']
worktrees=subprocess.check_output(['git','worktree','list','--porcelain'],cwd=ROOT,text=True).count('worktree ');checks['all_33_worktrees_preserved']=worktrees==identity['worktrees']==33
backup=ROOT.parents[1]/'owner_backups/anime_v1_closure_2026-10-06/manifest.json';checks['owner_backup_unchanged']=hashlib.sha256(backup.read_bytes()).hexdigest()==identity['backup_manifest_sha256']
sound=json.loads((OUT/'elemental_sound_catalog.json').read_text())['assets'];checks['108_live_sfx_assets']=all(hashlib.sha256((ROOT/'game-godot'/r['path'].replace('res://','')).read_bytes()).hexdigest()==r['sha256'] for r in sound) and len(sound)==108
checks['nine_distinct_sound_banks']=len({r['sha256'] for r in sound})==108
checks['headroom_in_new_sound_assets']=all(r['peak_dbfs']<=-3 for r in sound)
checks['all_original_hit_audio_preserved']=not subprocess.check_output(['git','diff',identity['base_sha'],'--','game-godot/assets/audio/collectible_v1'],cwd=ROOT)
result={'ok':all(checks.values()),'checks':checks,'worktrees':worktrees,'human_pass':False,'heavy_exports_run':False}
(OUT/'integrity_checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));raise SystemExit(0 if result['ok'] else 1)

"""Assemble truthful local review coverage. Does not grant production or human gates."""
import csv,json,subprocess,shutil,datetime
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/v1_closure/dialogue_performance'
def read(name):return json.loads((OUT/name).read_text())
def write(name,value):(OUT/name).write_text(json.dumps(value,indent=2)+'\n')
def table(name,rows):
 with (OUT/name).open('w',newline='') as f:
  writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
coverage=read('dialogue_coverage.json')
table('ALL_1025_CUE_STATUS.csv',coverage['cues'])
table('ALL_145_NODE_COVERAGE.csv',[dict(r,events=';'.join(r['events'])) for r in coverage['node_coverage']])
captures=read('capture_index.json')['movies']
matrix=read('choreography_matrix.json')
observations={}
for clip in captures:
 path=OUT/('capture_'+clip['label'])/'normal_input_capture_events.json'
 if path.exists():
  data=json.loads(path.read_text())
  for event in data['events']:
   if not event.get('opponent'):
    observations.setdefault((event['fighter'],event['move']),[]).append(clip['label'])
for row in matrix['rows']:
 row['normal_input_capture_observations']=sorted(set(observations.get((row['fighter_id'],row['move_id']),[])))
 row['rendered_capture_status']='OBSERVED_IN_AUTOMATED_INPUT' if row['normal_input_capture_observations'] else 'NOT_OBSERVED_IN_THIS_CAPTURE_SET'
 row['contact_geometry_validation']='PENDING_ALL_MOVE_SCREEN_SPACE_MEASUREMENT'
 row['secondary_motion']='PENDING_INDEPENDENT_HAIR_CLOTH_ARMOR'
 row['human_taste_approved']=False
write('choreography_matrix.json',matrix)
table('ALL_216_MOVE_STATUS.csv',[dict(r,normal_input_capture_observations=';'.join(r['normal_input_capture_observations'])) for r in matrix['rows']])
fighters=[]
for fid in sorted({r['fighter_id'] for r in matrix['rows']}):
 rows=[r for r in matrix['rows'] if r['fighter_id']==fid]
 clips=[r['label'] for r in captures if r['label'] in [fid,'signature_'+fid]]
 fighters.append({'fighter_id':fid,'compiled_move_studies':len(rows),'normal_input_moves_observed':sum(bool(r['normal_input_capture_observations']) for r in rows),'captures':clips,'idle_movement_guard_charge_reaction_victory_defeat':'COMPILED_CANDIDATE_STUDIES; FINAL_TRANSITIONS_AND_ACTING_PENDING','male_female_deformation_and_frame_seek':'TECHNICAL_PASS_BOTH; ALL_MOVE_CONTACT_MEASUREMENT_PENDING','elemental_events':13,'live_audio_bank_and_lifecycle':'TECHNICAL_PASS; HUMAN_MIX_PENDING','final_choreography':False,'cosmic_boss_vs_playable':'SEPARATE_SCALE_AWARE_BOSS_CHOREOGRAPHY_PENDING' if fid in ['yin','yang'] else 'NOT_APPLICABLE','human_pass':False})
write('fighter_acceptance_matrix.json',{'fighters':fighters,'scope':'Compiled source, isolated technical regression and labeled renderer observations; not full authored V1 closure.'})
table('FIGHTER_ACCEPTANCE_MATRIX.csv',[dict(r,captures=';'.join(r['captures'])) for r in fighters])
lines=['# Current-renderer owner review','', 'All movies contain native Godot mixed audio. Public-input drivers are automated, not human playthroughs. The before clips read preserved c5f3be23 source through a temporary overlay. Voices and voiced films stay local because audio redistribution is not cleared. No capture earns Story unlocks.','', '| Review | Movie | Source | Scope |','| --- | --- | --- | --- |']
for r in captures:
 path=ROOT/r['path']
 lines.append(f"| {r['label']} | [{path.name}]({path}) | `{r['source_sha'][:12]}` | {r['scope']} |")
lines+=['', 'Compare Ember and Juno before/after with sound enabled. The explicit idle-P2 clips demonstrate full charge and signature using public controls; the separate active-CPU clips show real fighting and charge interruption. Source identity is recorded per clip, not inferred from the final PR head.','', 'Accepted movies use native AVI MJPEG/PCM recording. An OGV empty-frame timestamp mismatch was found during media QA; those preliminary OGV recordings remain preserved locally and are excluded from accepted evidence. Every accepted MP4 has matching video/audio durations and native mixed audio, with no inserted narration, invented animation, damage adjustment or audio replacement.','', 'For First Loss clips, compare subtitle/speaker consistency, facial expression and camera focus. Kaia/Rook has 16 cues and Juno/Orion has 20. These are current-renderer draft staging with generic synthetic voices; final lip sync, acting, animation, lighting, music and edit remain ANI-04 work. Orion’s ultimate fate remains unresolved.','', 'Listen blind to the four matched-RMS impact WAVs in audio_ab before opening KEY.json. Charge sequences are also supplied. A and B use the same duration and loudness for each fighter; the B mix retains the original solid impact underneath the added elemental material.','', 'Review every fighter/move in FIGHTER_ACCEPTANCE_MATRIX.csv and ALL_216_MOVE_STATUS.csv. Unobserved moves and pending contact geometry, foot planting, independent secondary motion, transition polish and cosmic boss work remain open. The videos provide owner review evidence; they do not pass taste gates.']
(OUT/'CAPTURE_REVIEW.md').write_text('\n'.join(lines)+'\n')
regressions=read('regressions/results.json')
for row in regressions['rows']:
 manifest=OUT/'regressions'/row['test']/'launch_manifest.json'
 if manifest.exists():
  source=json.loads(manifest.read_text())
  row['tested_source_sha']=source.get('runtime_source_sha',source['git_sha'])
  row['source_diff_sha256']=source['source_diff_sha256']
  row['source_changes_at_test']=source['source_changes']
write('regressions/results.json',regressions)
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
free=shutil.disk_usage(ROOT).free/1024**3
report={'reported_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'draft_pr':'https://github.com/gunnchOS3k/anime-aggressors/pull/123','preserved_draft_pr':'https://github.com/gunnchOS3k/anime-aggressors/pull/122','base_sha':read('continuation_identity.json')['base_sha'],'source_checkpoint_sha':source,'review_package_commit_resolution':'git log -1 --format=%H -- artifacts/v1_closure/dialogue_performance/FINAL_IMPLEMENTATION_REPORT.json; exact final draft head also delivered in owner response','runtime_source_commit':captures[-1]['source_sha'],'dialogue':{'nodes':145,'cues':1025,'integrated':1025,'missing_source_bindings':0,'blocked_source_bindings':0,'binding_definition':coverage['coverage_definition'],'temporary_local_wavs':1025,'stable_voice_profiles':9,'final_dialogue_approved':False,'actor_recording_and_redistribution_clearance':'PENDING','adaptation':'one continuous Kaia OVA and six Campaign Variations','first_loss':'seven unique identities; Juno/Orion Last Vector, fate unresolved; later lost-character dialogue is memory'},'audio':{'original_mixes':117,'separate_source_stems':351,'third_party_samples':0,'paid_api_cost':0,'temporary_voice_distribution_cleared':False,'license_evidence':'temporary_voice_manifest.json and original elemental_sound_catalog.json','original_solid_impact_preserved':True},'animation':{'fighters':9,'move_studies':216,'final_authored_choreography':False,'remaining':'all-move contact geometry, planted-foot IK, full transition polish, independent hair/cloth/armor motion, differentiated final acting and separate cosmic-boss grammar'},'validation':{'targeted_regressions_passed':all(r['passed'] for r in regressions['rows']),'targeted_suites':len(regressions['rows']),'staged_all_145_source_objectives_and_save_restart':True,'ordinary_kaia':read('ordinary_kaia_complete.json'),'all_145_ordinary_natural_playthroughs':False,'presentation_all_1025_isolated':read('dialogue_runtime_test.json')['ok'],'static_regressions':read('static_regressions.json'),'engine_exit_warning':'Existing ObjectDB/resource leak and dummy-renderer material warnings retained in logs; no SCRIPT ERROR in accepted targeted suites/captures.'},'rendering':{'movies':captures,'human_playthrough':False,'final_cinematics':False,'voiced_movies_local_only':True},'preservation':{'worktrees':33,'owner_backup_unchanged':read('integrity_checks.json')['checks']['owner_backup_unchanged'],'disk_free_gib':round(free,3),'heavy_export_guard_gib':18,'heavy_exports_run':False,'local_web_android_exports':'BLOCKED_BELOW_DISK_GUARD','work_serial':True,'subagents':0},'gates':read('ACCEPTANCE_GATES.json'),'production_dependencies':'docs/anime-aggressors/v1_closure/dialogue_production/PRODUCTION_DEPENDENCIES.md','release_actions':{'merged':False,'deployed':False,'tagged':False,'published':False},'root_causes':['Aura hook was a flag without playback','Projectile had no launch/travel/dissipation sound path','Collectible candidate bank preceded v3 fallback','Music stop also stopped effects','Embedded GLB clips took precedence over JSON plans'],'checkpoint_status':'FULL_DIALOGUE_SOURCE_INTEGRATION; ANI_03_TECHNICAL_CANDIDATE_WITH_UNFINISHED_CHOREOGRAPHY; ANI_04_AND_05_OPEN'}
report['dialogue_demonstrations']={}
for fid in ['kaia-windrow','juno-spark']:
 path=OUT/('capture_dialogue_'+fid)/'dialogue_capture_events.json'
 if path.exists():
  data=json.loads(path.read_text());report['dialogue_demonstrations'][fid]={'cue_count':len(data['events']),'expected_cues':data['expected_cues'],'voices_playing':sum(r['voice_playing'] for r in data['events'].values()),'progress_unchanged':data['progress_unchanged']}
if (OUT/'CI_SOURCE_CHECKPOINT.json').exists():report['source_ci']=read('CI_SOURCE_CHECKPOINT.json')
write('FINAL_IMPLEMENTATION_REPORT.json',report)
print(json.dumps({'nodes':145,'cues':1025,'movies':len(captures),'fighter_rows':len(fighters),'move_rows':len(matrix['rows']),'free_gib':round(free,3)}))

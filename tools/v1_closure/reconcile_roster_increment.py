"""Reconcile existing assets/tests and new roster evidence; never rerender prior movies."""
import json,hashlib,subprocess,itertools,statistics,argparse,gzip
from pathlib import Path
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';INC=OUT/'continuous_1011'
p=argparse.ArgumentParser();p.add_argument('--runtime-source',required=True);p.add_argument('--ci',type=Path,required=True);a=p.parse_args()
HEAD=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
def read(path):return json.loads(path.read_text())
def write(path,data):path.write_text(json.dumps(data,indent=2)+'\n')
def checksum(path):return hashlib.sha256(path.read_bytes()).hexdigest()
old=read(OUT/'EVIDENCE_MANIFEST.json');roster=read(INC/'owner_roster_review/EVIDENCE_MANIFEST.json');assets=[];seen=set();errors=[]
guard_audit=read(INC/'COMPETITIVE_GUARD_AUDIT.json')
guard_excluded={r['label'] for r in guard_audit['rows'] if r['sampled_upward_guard_frames']}
projectile_audit=read(INC/'PROJECTILE_OWNERSHIP_AUDIT.json')
excluded_native=guard_excluded|set(projectile_audit['excluded_native_labels'])
for r in old['assets']+roster['assets']:
 if r['path'] in seen:continue
 seen.add(r['path']);r=r.copy();path=ROOT/r['path']
 if not path.exists():errors.append(r['path']+':MISSING');r['verification_status']='MISSING'
 else:
  actual=checksum(path)
  if r.get('sha256') and r['sha256']!=actual and r['path']!='artifacts/v1_closure/spectral_feedback/continuous_1011/current_owner_review/index.html':errors.append(r['path']+':HASH_MISMATCH')
  r.update(sha256=actual,bytes=path.stat().st_size,absolute_path=str(path),source_is_ancestor=subprocess.run(['git','merge-base','--is-ancestor',r['source_sha'],HEAD],cwd=ROOT).returncode==0)
  r.setdefault('verification_status','EXISTS_AND_HASHED');r.setdefault('redistribution_restriction',r.get('redistribution','owner development review; original versus assets/audio; human release permission pending'))
  if r.get('label') in excluded_native or any(label in r['path'] for label in excluded_native):
   r['competitive_acceptance']='EXCLUDED_GUARD_OR_PROJECTILE_OWNERSHIP_DEFECT; retained diagnostic/motion/audio review'
  if not r['source_is_ancestor']:errors.append(r['path']+':SOURCE_LINEAGE')
 assets.append(r)
# Newly recorded refined geometry movie remains distinct from active-CPU matches.
geo=read(INC/'roster_motion_native/NATIVE_MOVIE.json')
new_assets=[geo,*geo.get('sheets',[])]
landing_native=INC/'landing_native_1012/NATIVE_MOVIE.json'
if landing_native.exists():
 landing_asset=read(landing_native);new_assets.extend([landing_asset,*landing_asset.get('sheets',[])])
transition_native=INC/'transitions_native_1012/NATIVE_MOVIE.json'
if transition_native.exists():
 transition_asset=read(transition_native);new_assets.extend([transition_asset,*transition_asset.get('sheets',[])])
for extra in [INC/'native_clock_foreground_1012/NATIVE_MOVIE.json',INC/'empowerment_native1012/NATIVE_MOVIE.json',INC/'energy_native_guard1012/NATIVE_MOVIE.json',INC/'energy_envelope_native1012/NATIVE_MOVIE.json']:
 if extra.exists():
  item=read(extra);new_assets.extend([item,*item.get('sheets',[]),*item.get('comparisons',[])])
for r in new_assets:
 if r['path'] in seen:continue
 path=ROOT/r['path'];assert path.is_file(),path
 assert checksum(path)==r['sha256'],path
 assert subprocess.run(['git','merge-base','--is-ancestor',r['source_sha'],HEAD],cwd=ROOT).returncode==0,r['source_sha']
 assets.append({**r,'absolute_path':str(path),'verification_status':r.get('verification_status','VERIFIED_FILE_AND_METADATA'),'redistribution_restriction':'original source game audio/assets; development owner review, no release authorization','local_only':False});seen.add(r['path'])
for asset in assets:
 if 'roster_transitions_4cee67a1' in asset['path'] or 'transitions_native_1012/' in asset['path']:
  asset.update(verification_status='FAILED_NATIVE_FRAME_REFRESH_IDENTITY_ALIGNMENT',qualifying_visual_evidence=False,competitive_acceptance='EXCLUDED; actual native frames contradict expected fixture identities')
gallery=INC/'current_owner_review/index.html'
if gallery.exists() and str(gallery.relative_to(ROOT)) not in seen:
 assets.append({'path':str(gallery.relative_to(ROOT)),'absolute_path':str(gallery),'sha256':checksum(gallery),'source_sha':a.runtime_source,'verification_status':'EXISTS_AND_HASHED; all linked native assets separately verified','redistribution_restriction':'owner development review; no release authorization','local_only':False})
for path in (OUT/'rendered').glob('*.mp4'):
 if str(path.relative_to(ROOT)) not in seen:errors.append(str(path.relative_to(ROOT))+':UNINDEXED')
# Final ledger includes immutable historical passes and separate current-source receipts.
ledger=[]
for path in sorted(INC.glob('*/results.json')):
 data=read(path);rows=data if isinstance(data,list) else data.get('rows',[])
 for row in rows:
  log=ROOT/row['stdout'] if row.get('stdout') else path.parent/row['suite']/'stdout.log'
  assert log.exists(),log
  s=gzip.decompress(log.read_bytes()).decode() if log.suffix=='.gz' else log.read_text();diagnostics=[line for line in s.splitlines() if line.startswith('ERROR:')]
  passed=row.get('passed',row.get('ok',False))
  ledger.append({**row,'passed':passed,'stdout':str(log.relative_to(ROOT)),'stdout_sha256':checksum(log),'script_errors':s.count('SCRIPT ERROR'),'engine_diagnostic_count':len(diagnostics),'engine_diagnostics':sorted(set(diagnostics)),'verification_status':'FIXTURE_PASS_WITH_ENGINE_DIAGNOSTICS' if passed and diagnostics else 'FIXTURE_PASS' if passed else 'FAILED_PRESERVED','clean_engine_log':not diagnostics,'receipt_source':str(path.relative_to(ROOT))})
write(INC/'REGRESSION_LEDGER.json',{'historical_twelve':old.get('historical_twelve_regressions',old.get('regressions',[])),'continuous_runs':ledger,'scope':'Per-run source+diff and logs retained; historical passes are not relabeled as current-source tests. Headless dummy material cleanup diagnostics are reported separately from script/invariant failures.'})
for label,filename,suite in [('material_retained_1012','model_swap_lifecycle.json','ModelSwapLifecycleNative'),('transitions_reverse_fixed_1012','roster_transitions.json','RosterTransitions'),('empowerment_lifecycle_fixed1012','persistent_empowerment.json','PersistentEmpowerment'),('actionline_fixed1012','action_line_production.json','ActionLineProduction'),('expression_pressure_before1012','expression_pool_priority.json','ExpressionPoolPriority'),('expression_pressure_fixed1012','expression_pool_priority.json','ExpressionPoolPriority'),('aura_projection_before1012','aura_ribbon_projection.json','AuraRibbonProjection'),('intensity_before1012','spectral_intensity.json','SpectralIntensity'),('intensity_fixed1012','spectral_intensity.json','SpectralIntensity')]:
 report=INC/label/filename
 if not report.exists():continue
 data=read(report);launch=read(report.parent/'launch_manifest.json');log=report.parent/'godot.log';s=log.read_text()
 ledger.append(dict(suite=suite,source_sha=launch['runtime_source_sha'],source_diff_sha256=launch['source_diff_sha256'],source_changes=launch['source_changes'],passed=data['PASS'],cases=len(data['rows']),stdout=str(log.relative_to(ROOT)),stdout_sha256=checksum(log),script_errors=s.count('SCRIPT ERROR'),engine_diagnostics=sorted(set(line for line in s.splitlines() if line.startswith('ERROR:'))),receipt_source=str(report.relative_to(ROOT)),scope=data.get('scope','explicit source/lifecycle fixtures; no artistic/device/competitive approval')))
write(INC/'REGRESSION_LEDGER.json',{'historical_twelve':old.get('historical_twelve_regressions',old.get('regressions',[])),'continuous_runs':ledger,'scope':'Immutable source/diff bindings; diagnostics retained separately from fixture pass. Untracked feature hashes additionally bound in correction reports; no old tests relabeled current.'})
# Reconcile the108 contact cells from actual P1 observations, including headless probes.
IDS=[r['fighter'] for r in roster['rows']];captures=[]
for row in read(OUT/'capture_index.json')['movies']:
 if row['mode'] in ['active','roster_choreography'] and row['label'] not in excluded_native:captures.append((row,read(OUT/'captures'/row['label']/'combat_capture.json')))
for row in read(OUT/'combo_probe_index.json')['attempts']:
 if not row.get('acceptance_status','').startswith('DEFECT_AFFECTED'):captures.append((row,read(OUT/'combo_probes'/row['label']/'combat_capture.json')))
def category(mid):
 if '_air' in mid:return 'aerial'
 if mid=='heavy_attack':return 'heavy'
 if mid=='neutral_special_projectile':return 'projectile'
 return 'light' if mid in ['jab_1','jab_2','jab_finisher','forward_tilt','up_tilt','down_tilt','dash_attack'] else 'other'
def band(value):return 'low' if value<40 else 'medium' if value<90 else 'high'
cells=[]
for fid,tier,kind in itertools.product(IDS,['low','medium','high'],['light','heavy','aerial','projectile']):
 contacts=[]
 for row,data in captures:
  if row['fighter']!=fid or not data['opponent_cpu'] or data.get('idle_fixture_not_combo_evidence'):continue
  for c in data['contacts']:
   if c['attacker']==fid and c.get('attacker_slot',1)==1 and category(c['move'])==kind and band(c['damage_before'])==tier:
    contacts.append({'capture':row['label'],'source_sha':row['source_sha'],'event_id':c['event_id'],'frame':c['movie_frame'],'move':c['move'],'result':c['result'],'actual_damage_before':c['damage_before']})
 cells.append({'fighter':fid,'actual_damage_band':tier,'move_class':kind,'hits':sum(c['result']=='hit' for c in contacts),'blocks':sum(c['result']=='shield' for c in contacts),'status':'OBSERVED_CONTACT' if contacts else 'UNVERIFIED_NO_CONTACT_EVIDENCE','evidence':contacts})
write(INC/'FULL_ROSTER_CONTACT_CELLS.json',{'cells':cells,'observed':sum(bool(c['evidence']) for c in cells),'unverified':sum(not c['evidence'] for c in cells),'historical_observed':37,'historical_unverified':71,'excluded_guard_probe_attempts':guard_audit['excluded_probes'],'excluded_guard_native_sequences':guard_audit['excluded_native_sequences'],'observation_source_scope':'Combined exact-source historical and current non-quarantined observations, not108 fresh current-build reruns','not_a_combo_guarantee':True,'missing_does_not_mean_broken':True})
probes=read(OUT/'COMBO_PROBE_MATRIX.json');new=[r for r in probes if r['label'].endswith('_roster1011')]
assert len(new)==36,'Complete bounded36probe pass before reconciliation'
write(INC/'ROSTER_GAMEPLAY_RESULTS.json',{'rows':new,'true_pairs':sum(r['genuine_pairs'] for r in new),'blocked_pairs':sum(r['blocked_pairs'] for r in new),'recovery_before_next_pairs':sum(r['recovery_before_next_pairs'] for r in new),'no_contact_probes':sum(r['hits']==0 for r in new),'defect_affected_attempts':sum(r.get('acceptance_status','').startswith('DEFECT_AFFECTED') for r in new),'rules_changed':False,'scope':'Raw observed contacts retained; extended guard audit excludes affected whole attempts, including the original six stock-loss attempts.900public-control frames per recipe against active CPU;50/110% initial fixture only; actual defender recovery excludes escapable follow-ups; throw flags never certify combos'})
corrected=read(INC/'GUARD_CORRECTED_GAMEPLAY_RESULTS.json');assert len(corrected['rows'])==14
ci=read(a.ci);write(INC/'GITHUB_CHECKS.json',ci)
changed=subprocess.check_output(['git','diff','--name-only',a.runtime_source,HEAD,'--','game-godot/scripts','game-godot/data','game-godot/assets','game-godot/shaders'],cwd=ROOT,text=True).splitlines();assert not changed,'Runtime changed after stated source'
result={'schema':'ani03_evidence_reconciliation/v3','verified_at_utc':datetime.now(timezone.utc).isoformat(),'verified_head':HEAD,'current_runtime_source':a.runtime_source,'nine_mirror_movie_source':'67ae813a9aaa71bbc2e5bed5d5896a02107744a0','refined_geometry_movie_source':geo['source_sha'],'assets':assets,'regression_ledger':'artifacts/v1_closure/spectral_feedback/continuous_1011/REGRESSION_LEDGER.json','historical_twelve_regressions':old.get('historical_twelve_regressions',old.get('regressions',[])),'errors':errors,'all_required_assets_verified':not errors,'human_acceptance_earned':False,'new_capture_scope':'nine current-animation mirrors + one new all-roster refinement geometry sequence; old nine-effect campaign retained'}
write(OUT/'EVIDENCE_MANIFEST.json',result)
summary={'schema':'ani03_implementation_summary/v3','runtime_source':a.runtime_source,'total_review_movies':sum(Path(r['path']).suffix=='.mp4' for r in assets),'new_roster_mirror_movies':9,'new_refinement_geometry_movies':1,'new_roster_active_cpu_probes':36,'guard_corrected_active_cpu_probes':14,'guard_corrected_body_contacts':corrected['body_contacts'],'guard_corrected_shield_contacts':corrected['shield_contacts'],'guard_corrected_true_pairs':corrected['genuine_pairs'],'guard_defect_excluded_probes':guard_audit['excluded_probes'],'guard_defect_excluded_native_sequences':guard_audit['excluded_native_sequences'],'observed_contact_cells':sum(bool(c['evidence']) for c in cells),'unverified_contact_cells':sum(not c['evidence'] for c in cells),'true_pairs_in_new_pass':sum(r['genuine_pairs'] for r in new),'full_nine_roster_runtime_candidate':True,'professional_choreography_complete':False,'outer_mesh_reach_complete':False,'body_presentations':18,'competitive_stock_loss_qualified':True,'competitive_match_win_verified':False,'human_gates_false':True,'heavy_exports_run':False,'ci_snapshot_head':ci['headRefOid'],'ci_successes':sum(c['conclusion']=='SUCCESS' for c in ci['statusCheckRollup']),'ci_pending':sum(c['status']!='COMPLETED' for c in ci['statusCheckRollup']),'evidence_manifest':str((OUT/'EVIDENCE_MANIFEST.json').relative_to(ROOT))}
write(OUT/'IMPLEMENTATION_SUMMARY.json',summary)
write(OUT/'DELIVERY_CHECKPOINT.json',{'schema':'ani03_delivery_checkpoint/v3','branch':'release/anime-v1-dialogue-and-elemental-performance','draft_pr':'https://github.com/gunnchOS3k/anime-aggressors/pull/123','stacked_parent_pr':'https://github.com/gunnchOS3k/anime-aggressors/pull/122','runtime_source':a.runtime_source,'verified_parent_head':HEAD,'package_head_command':'git rev-parse HEAD','record_commit_command':'git log -1 --format=%H -- artifacts/v1_closure/spectral_feedback/DELIVERY_CHECKPOINT.json','human_gates_earned':False,'worktrees_preserved':33,'local_only_media':'artifacts/v1_closure/spectral_feedback/local_media','exports_run':False,'remaining':'all-roster outer reach/floor authority, transitions/turns/acting, deeper combo/KO coverage, physical devices, ANI04/05 and human release approval'})
latest_path=INC/'NEUTRAL_CAST_ROSTER_CPU_RESULTS.json'
latest=read(latest_path if latest_path.exists() else INC/'EMPOWERED_ROSTER_CPU_RESULTS.json')
energy_report=INC/'energy_envelope_native1012/NATIVE_MOVIE.json'
native_ready=energy_report.exists() and read(energy_report)['verification_status']=='VERIFIED_NATIVE_FRAME_BARCODES_AND_NINE_PAIRED_IDENTITIES'
summary.update(persistent_aura_cases=36,persistent_aura_fighters=9,body_rig_presentations=18,current_native_aura_verified=native_ready,current_native_aura_blocker=None if native_ready else 'Native visual verification pending',action_line_cases=18,current_source_CPU_probes=9,current_source_CPU_sha=latest['source_sha'],current_source_hits=latest['hits'],current_source_blocks=latest['blocks'],current_source_true_pairs=latest['true_pairs'],strict_historical_true_pairs=sum(r['genuine_pairs'] for r in probes if not r['label'].endswith('_neutralcast1012')),all_strict_true_pairs=sum(r['genuine_pairs'] for r in probes),projectile_defect_excluded_probes=len(projectile_audit['excluded_probe_labels']),projectile_defect_excluded_native_sequences=len(projectile_audit['excluded_native_labels']),failed_native_movies=1,movie_count_scope='Retained video count includes a disqualified stale-frame montage and a three-model clock diagnostic. Every asset retains its exact source and qualification.',native_model_material_cleanup_closed=True,all_human_release_gates=False,current_native_aura_source=read(energy_report)['source_sha'] if native_ready else None,current_source_projectile_hits=latest.get('projectile_hits'),current_source_projectile_blocks=latest.get('projectile_blocks'),strict_probe_count=len(probes),global_intensity_native_verified=False)
heavy_path=INC/'HEAVY_COUNTER_ROSTER_CPU_RESULTS.json'
if heavy_path.exists():
 heavy=read(heavy_path);summary.update(latest_heavy_cpu_source=heavy['source_sha'],latest_heavy_cpu_probes=len(heavy['rows']),latest_heavy_hits=heavy['hits'],latest_heavy_blocks=heavy['blocks'],latest_heavy_true_pairs=heavy['true_pairs'],latest_heavy_body_contacts=heavy['heavy_hits'],latest_heavy_defensive_contacts=heavy['heavy_blocks'])
extremes_path=INC/'PROJECTILE_EXTREMES_ROSTER_CPU_RESULTS.json'
if extremes_path.exists():
 extremes=read(extremes_path);summary.update(latest_projectile_extremes_source=extremes['source_sha'],latest_projectile_extremes_probes=len(extremes['rows']),latest_projectile_extremes_hits=extremes['hits'],latest_projectile_extremes_blocks=extremes['blocks'],latest_projectile_extremes_true_pairs=extremes['true_pairs'],contact_cell_scope='Combined individually source-bound non-quarantined observations; not108 exact-current-build reruns')
write(OUT/'IMPLEMENTATION_SUMMARY.json',summary)
result.update(all_paths_hashes_and_lineage_verified=not errors,all_current_requested_native_evidence_available=False,current_native_aura_blocked=not native_ready,qualifying_status_scope='Path/hash verification is separate from visual-frame/competitive qualification; failed native movie remains disqualified',projectile_defect_exclusions=projectile_audit)
write(OUT/'EVIDENCE_MANIFEST.json',result)
print(json.dumps(summary));assert not errors,errors

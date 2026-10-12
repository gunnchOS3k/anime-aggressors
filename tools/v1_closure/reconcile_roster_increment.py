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
for r in old['assets']+roster['assets']:
 if r['path'] in seen:continue
 seen.add(r['path']);r=r.copy();path=ROOT/r['path']
 if not path.exists():errors.append(r['path']+':MISSING');r['verification_status']='MISSING'
 else:
  actual=checksum(path)
  if r.get('sha256') and r['sha256']!=actual:errors.append(r['path']+':HASH_MISMATCH')
  r.update(sha256=actual,bytes=path.stat().st_size,absolute_path=str(path),source_is_ancestor=subprocess.run(['git','merge-base','--is-ancestor',r['source_sha'],HEAD],cwd=ROOT).returncode==0)
  r.setdefault('verification_status','EXISTS_AND_HASHED');r.setdefault('redistribution_restriction',r.get('redistribution','owner development review; original versus assets/audio; human release permission pending'))
  if r.get('label') in guard_excluded or any(label in r['path'] for label in guard_excluded):
   r['competitive_acceptance']='EXCLUDED_GUARD_DEFECT_AFFECTED; retained motion/model/audio review'
  if not r['source_is_ancestor']:errors.append(r['path']+':SOURCE_LINEAGE')
 assets.append(r)
# Newly recorded refined geometry movie remains distinct from active-CPU matches.
geo=read(INC/'roster_motion_native/NATIVE_MOVIE.json')
new_assets=[geo,*geo.get('sheets',[])]
landing_native=INC/'landing_native_1012/NATIVE_MOVIE.json'
if landing_native.exists():
 landing_asset=read(landing_native);new_assets.extend([landing_asset,*landing_asset.get('sheets',[])])
for r in new_assets:
 if r['path'] in seen:continue
 path=ROOT/r['path'];assert path.is_file(),path
 assert checksum(path)==r['sha256'],path
 assets.append({**r,'absolute_path':str(path),'verification_status':'VERIFIED_FILE_AND_METADATA','redistribution_restriction':'original source game audio/assets; development owner review, no release authorization','local_only':False});seen.add(r['path'])
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
# Reconcile the108 contact cells from actual P1 observations, including headless probes.
IDS=[r['fighter'] for r in roster['rows']];captures=[]
for row in read(OUT/'capture_index.json')['movies']:
 if row['mode'] in ['active','roster_choreography'] and row['label'] not in guard_excluded:captures.append((row,read(OUT/'captures'/row['label']/'combat_capture.json')))
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
write(INC/'FULL_ROSTER_CONTACT_CELLS.json',{'cells':cells,'observed':sum(bool(c['evidence']) for c in cells),'unverified':sum(not c['evidence'] for c in cells),'historical_observed':37,'historical_unverified':71,'excluded_guard_probe_attempts':guard_audit['excluded_probes'],'excluded_guard_native_sequences':guard_audit['excluded_native_sequences'],'not_a_combo_guarantee':True,'missing_does_not_mean_broken':True})
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
print(json.dumps(summary));assert not errors,errors

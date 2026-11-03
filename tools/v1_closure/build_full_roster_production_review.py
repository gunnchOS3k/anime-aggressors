"""Build current production statuses from immutable roster/geometry/gameplay receipts."""
import csv,json,statistics,subprocess,argparse
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';INC=OUT/'continuous_1011'
parser=argparse.ArgumentParser();parser.add_argument('--runtime-source',required=True);args=parser.parse_args()
def read(path):return json.loads(path.read_text())
def write(path,data):path.write_text(json.dumps(data,indent=2)+'\n')
roster=read(INC/'owner_roster_review/EVIDENCE_MANIFEST.json')
geometry=read(INC/'heavy_air_reactions/RosterContactRange/roster_contact_range.json')
floor=read(INC/'FLOOR_CONTACT_AUTHORITY.json')
probes=read(INC/'ROSTER_GAMEPLAY_RESULTS.json')
corrected=read(INC/'GUARD_CORRECTED_GAMEPLAY_RESULTS.json')
guard=read(INC/'COMPETITIVE_GUARD_AUDIT.json')
landing=read(INC/'LANDING_COMPARISON.json')
capsule=read(INC/'CAPSULE_FRAMING_PROPOSAL.json')
assert geometry['PASS'] and len(geometry['rows'])==396
floor_by={r['fighter']:r for r in floor['rows']}
styles={
'ember-vale':('Committed combustion; heavy compression and drive; airborne explosive curl','Hammer release, recoil/settle and starts/stops still need authored acting'),
'rook-ironside':('Rooted support and compressed mass; balanced airborne tuck','Massful pivot, armor follow-through and deliberate recovery remain incomplete'),
'juno-spark':('Compact directional snap and asymmetric airborne limbs','Charged pivots, foot switches and clean snap recovery need polish'),
'kaia-windrow':('Open spiral and flowing wind-supported arcs','Starts, landings and ribbon lag need continuous authored transitions'),
'nix-calder':('Precise compact holds and crystalline extension','Abrupt stops, stance placement and release recovery need refinement'),
'orion-vell':('Orbital counterturn and opposing torso/pelvis paths','Vector handoff and gravitational settling need authored continuity'),
'vesper-nyx':('Skewed withdrawal and oblique phase paths','Feint/pivot and grounded phase return remain generic in transitions'),
'yin':('Inward fold and economical reduction','Cosmic gait and absorption acting still use shared locomotion/recovery structure'),
'yang':('Ordered outward extension and structured release','Construction cadence and landing stabilization need distinct acting')}
transition=read(INC/'LOCOMOTION_TRANSITION_CORRECTION.json')
cleanup=read(INC/'MODEL_SWAP_CORRECTION.json')
movement_native=read(INC/'transitions_native_1012/NATIVE_MOVIE.json') if (INC/'transitions_native_1012/NATIVE_MOVIE.json').exists() else None
empowerment=read(INC/'empowerment_lifecycle_fixed1012/persistent_empowerment.json')
expression=read(INC/'actionline_fixed1012/action_line_production.json')
energy_native=read(INC/'energy_envelope_native1012/NATIVE_MOVIE.json')
aura_refinement=read(INC/'AURA_ENVELOPE_REFINEMENT.json')
neutral=read(INC/'NEUTRAL_CAST_ROSTER_CPU_RESULTS.json')
rows=[]
for native in roster['rows']:
 fid=native['fighter'];g=[r for r in geometry['rows'] if r['fighter']==fid];f=floor_by[fid]
 outer={kind:max(r['hand_mesh_to_overlap_px'] for r in g if r['case']==kind and r['range']=='outer') for kind in ['light','heavy','signature']}
 regular=max(r['hand_mesh_to_overlap_px'] for r in g if r['range'] in ['typical','close'])
 air=max(r['hand_mesh_to_overlap_px'] for r in g if r['case']=='aerial')
 q=[r for r in probes['rows'] if r['fighter']==fid];assert len(q)==4
 fixed=[r for r in corrected['rows'] if r['fighter']==fid]
 legacy_guard=next(r for r in guard['rows'] if r['label']==fid+'_roster_choreography_low')
 missing=[name for name,observed in native['qualifying_categories'].items() if not observed]
 if not native['signature_observed']:missing.append('signature')
 rows.append({'fighter':fid,'runtime_source':args.runtime_source,'offensive_heavy_aerial_source':'b5f2af11a61f912c78dfb198a33b872e351fd4ae','landing_data_source':'26cf7c8153affdde6bebc0bac9185ce1af8591f7',
 'IMPLEMENTED':'ORIGINAL_RUNTIME_CHOREOGRAPHY_CANDIDATE; production incomplete',
 'AUTOMATED_VERIFIED':'864 roster configurations; per-fighter44 geometry contacts,8 public landing cases,4 guard cases; scope-limited',
 'RUNTIME_VERIFIED':'native mirror femaleP1/maleCPU at67ae (guard limitations audited); refined geometry maleP1/femaleP2 atb5f2; landing refinement separately verified on latest source',
 'OWNER_REVIEW_READY':False,'OWNER_APPROVED':False,
 'BLOCKED':['shared floor/contact origin discrepancy','outer-range visible reach remains outside collision surface'],
 'candidate_review_material_available':True,'professional_quality_claimed':False,
 'start_stop_pivot_implementation':'9distinct authored body-chain/load/rhythm profiles; existing gait support preserved; complete corrective steps/professional acting still open',
 'start_stop_pivot_source':'9ce9e15272813266a693f3474b074342c9d89412',
 'start_stop_pivot_public_cases':4,
 'start_stop_pivot_physics_identical':all(x['public_physics_state_identical_to_baseline'] for x in transition['rows'] if x['fighter']==fid),
 'start_stop_pivot_support_solver_error_max_m':max(x['maximum_support_error_m'] for x in transition['rows'] if x['fighter']==fid),
 'native_model_swap_errors_corrected':0,
 'native_model_swap_cases':6,
 'native_warmed_resource_growth':0,
 'movement_native_movie':movement_native['path'] if movement_native else None,
 'movement_native_source':movement_native['source_sha'] if movement_native else None,
 'movement_native_qualifying':False,
 'movement_native_failure':'FAILED_NATIVE_FRAME_REFRESH_IDENTITY_ALIGNMENT; retained diagnostic only',
 'persistent_aura_implemented':True,'persistent_aura_cases':4,
 'persistent_aura_grammar':next(r['full']['grammar'] for r in empowerment['rows'] if r['fighter']==fid),
 'persistent_aura_native_verified':True,'persistent_aura_review_blocker':None,'persistent_aura_native_movie':energy_native['path'],'persistent_aura_native_source':energy_native['source_sha'],'persistent_aura_native_scope':energy_native['scope'],'persistent_aura_visual_findings':aura_refinement['after_findings'][fid],'latest_neutral_cast_probe':next(r for r in neutral['rows'] if r['fighter']==fid),'global_intensity_source_verified':True,'global_intensity_native_verified':False,
 'action_line_cases':2,'action_lines_implemented':['velocity movement','resolved anticipation','actual striking-limb paths','confirmed heavy accent','full meter arrival'],
 'new_expression_source':args.runtime_source,
 'body_presentations':['male','female'],'facings':[-1,1],
 'native_body_presentation_visibility_verified':True,'latest_landing_movie':'artifacts/v1_closure/spectral_feedback/rendered/roster_landings_26cf7c81.mp4','native_landing_source':'26cf7c8153affdde6bebc0bac9185ce1af8591f7',
 'close_typical_hand_mesh_to_overlap_max_px':regular,'neutral_air_ascending_descending_hand_mesh_to_overlap_max_px':air,
 'outer_hand_mesh_gap_px':outer,'boot_below_physical_floor_max_px':f['baseline_boot_below_physical_floor_max_px'],
 'isolated_floor_candidate_hand_gap_px':f['candidate_typical_hand_gap_max_px'],'floor_candidate_shipped':False,
 'mean_linear_support_drift_px_per_frame_at67ae':native['mean_support_slip_px_per_frame'],
 'support_metric_does_not_certify_floor_placement':True,
 'movie':native['movie'],'movie_source_sha':native['source_sha'],'native_hits':native['p1_hits'],'native_blocks':native['p1_shields'],'active_cpu_moves':native['cpu_moves'],
 'native_unobserved_categories':missing,'signature_native_observed':native['signature_observed'],
 'new_medium_high_public_cpu_probes':4,'new_true_pairs':sum(r['genuine_pairs'] for r in q),'new_blocked_pairs':sum(r['blocked_pairs'] for r in q),
 'new_recovery_before_next_pairs':sum(r['recovery_before_next_pairs'] for r in q),
 'historical_medium_high_attempts_excluded':sum(r.get('acceptance_status','').startswith('DEFECT_AFFECTED') for r in q),
 'legacy_mirror_guard_samples':legacy_guard['sampled_upward_guard_frames'],
 'latest_guard_corrected_cpu_probes':len(fixed),'latest_guard_corrected_hits':sum(r['hits'] for r in fixed),
 'latest_guard_corrected_blocks':sum(r['shield_contacts'] for r in fixed),'latest_guard_corrected_true_pairs':sum(r['genuine_pairs'] for r in fixed),
 'latest_guard_corrected_recovery_pairs':sum(r['recovery_before_next_pairs'] for r in fixed),
 'landing_cases_verified':8,'landing_clock_error_s':max(r['after_max_clock_error_s'] for r in landing['rows'] if r['fighter']==fid),
 'landing_lag_unchanged':True,'new_landing_profiles':'first-impact absorption, pelvis/chest counterbalance, grounded catches, fast-fall hard landing and authoritative recovery clock',
 'capsule_framing_candidate': [r for r in capsule['rows'] if r['fighter']==fid],
 'motion_authority':styles[fid][0],'next_authored_work':styles[fid][1],
 'remaining_categories':['visible polish of implemented starts/stops/pivots','native actualfight/expression/global-intensity review','directional aerial contact beyond neutral_air','move-specific anticipation/follow-through/recovery','grab/throw/defense acting','hair/cloth/armor/ribbon production','broader combo and competitive KO acceptance','owner normal-speed play review'],
 'per_category_production_status':{'shared_timing_orientation':'TECHNICALLY_VERIFIED','movement_footwork':'PARTIAL; floor origin unresolved','offensive_choreography':'BLOCKING_AND_WEIGHT_TRANSFER_IMPLEMENTED; outer reach unresolved','defensive_reactive':'IMMEDIATE_CONTACT_POSE_VERIFIED; acting incomplete','elemental_secondary':'NINE_ORIGINAL_IDENTITIES_IMPLEMENTED; production accessories incomplete','competitive_acceptance':'PARTIAL_ACTIVE_CPU_EVIDENCE; no all-roster KO/match-win claim'}})
write(INC/'FULL_ROSTER_PRODUCTION_MATRIX.json',{'runtime_source':args.runtime_source,'source_scope':'Each asset/test retains exact source or parent+diff. Offensive/heavy/air data b5f2, latest guard/modal/landing refinements separately source-bound; no final visual approval. Native mirroring proves model selection/visibility, not complete variant art quality. Convex projected skin hull intersection is not a3D anatomy/occlusion judgment.','rows':rows,'human_gates':roster['human_gates']})
keys=['fighter','IMPLEMENTED','AUTOMATED_VERIFIED','RUNTIME_VERIFIED','OWNER_REVIEW_READY','OWNER_APPROVED','BLOCKED','close_typical_hand_mesh_to_overlap_max_px','neutral_air_ascending_descending_hand_mesh_to_overlap_max_px','outer_hand_mesh_gap_px','boot_below_physical_floor_max_px','new_true_pairs','new_blocked_pairs','new_recovery_before_next_pairs','native_unobserved_categories','motion_authority','next_authored_work']
with (INC/'FULL_ROSTER_PRODUCTION_MATRIX.csv').open('w') as out:
 w=csv.DictWriter(out,fieldnames=keys);w.writeheader();w.writerows({k:r[k] for k in keys} for r in rows)
print(json.dumps({'rows':len(rows),'review_material_available':9,'professional_review_ready':0,'owner_approved':0}))

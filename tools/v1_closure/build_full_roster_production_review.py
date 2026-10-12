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
rows=[]
for native in roster['rows']:
 fid=native['fighter'];g=[r for r in geometry['rows'] if r['fighter']==fid];f=floor_by[fid]
 outer={kind:max(r['hand_mesh_to_overlap_px'] for r in g if r['case']==kind and r['range']=='outer') for kind in ['light','heavy','signature']}
 regular=max(r['hand_mesh_to_overlap_px'] for r in g if r['range'] in ['typical','close'])
 air=max(r['hand_mesh_to_overlap_px'] for r in g if r['case']=='aerial')
 q=[r for r in probes['rows'] if r['fighter']==fid];assert len(q)==4
 missing=[name for name,observed in native['qualifying_categories'].items() if not observed]
 if not native['signature_observed']:missing.append('signature')
 rows.append({'fighter':fid,'runtime_source':args.runtime_source,'animation_data_source':'b5f2af11a61f912c78dfb198a33b872e351fd4ae',
 'IMPLEMENTED':'ORIGINAL_RUNTIME_CHOREOGRAPHY_CANDIDATE; production incomplete',
 'AUTOMATED_VERIFIED':'864 roster configurations; per-fighter44 geometry contacts,4 active-CPU attempts; scope-limited',
 'RUNTIME_VERIFIED':'native mirror femaleP1/maleCPU at67ae; refined geometry maleP1/femaleP2 atb5f2',
 'OWNER_REVIEW_READY':False,'OWNER_APPROVED':False,
 'BLOCKED':['shared floor/contact origin discrepancy','outer-range visible reach remains outside collision surface'],
 'candidate_review_material_available':True,'professional_quality_claimed':False,
 'body_presentations':['male','female'],'facings':[-1,1],
 'close_typical_hand_mesh_to_overlap_max_px':regular,'neutral_air_ascending_descending_hand_mesh_to_overlap_max_px':air,
 'outer_hand_mesh_gap_px':outer,'boot_below_physical_floor_max_px':f['baseline_boot_below_physical_floor_max_px'],
 'isolated_floor_candidate_hand_gap_px':f['candidate_typical_hand_gap_max_px'],'floor_candidate_shipped':False,
 'mean_linear_support_drift_px_per_frame_at67ae':native['mean_support_slip_px_per_frame'],
 'support_metric_does_not_certify_floor_placement':True,
 'movie':native['movie'],'movie_source_sha':native['source_sha'],'native_hits':native['p1_hits'],'native_blocks':native['p1_shields'],'active_cpu_moves':native['cpu_moves'],
 'native_unobserved_categories':missing,'signature_native_observed':native['signature_observed'],
 'new_medium_high_public_cpu_probes':4,'new_true_pairs':sum(r['genuine_pairs'] for r in q),'new_blocked_pairs':sum(r['blocked_pairs'] for r in q),
 'new_recovery_before_next_pairs':sum(r['recovery_before_next_pairs'] for r in q),
 'motion_authority':styles[fid][0],'next_authored_work':styles[fid][1],
 'remaining_categories':['authored starts/stops/pivots','directional aerial contact beyond neutral_air','move-specific anticipation/follow-through/recovery','grab/throw/defense acting','hair/cloth/armor/ribbon production','broader combo and competitive KO acceptance','owner normal-speed play review'],
 'per_category_production_status':{'shared_timing_orientation':'TECHNICALLY_VERIFIED','movement_footwork':'PARTIAL; floor origin unresolved','offensive_choreography':'BLOCKING_AND_WEIGHT_TRANSFER_IMPLEMENTED; outer reach unresolved','defensive_reactive':'IMMEDIATE_CONTACT_POSE_VERIFIED; acting incomplete','elemental_secondary':'NINE_ORIGINAL_IDENTITIES_IMPLEMENTED; production accessories incomplete','competitive_acceptance':'PARTIAL_ACTIVE_CPU_EVIDENCE; no all-roster KO/match-win claim'}})
write(INC/'FULL_ROSTER_PRODUCTION_MATRIX.json',{'source_scope':'Each asset/test retains exact source or parent+diff. Latest scripts/data same asb5f2; no final visual approval. Native mirroring proves model selection/visibility, not complete variant art quality. Convex projected skin hull intersection is not a3D anatomy/occlusion judgment.','rows':rows,'human_gates':roster['human_gates']})
keys=['fighter','IMPLEMENTED','AUTOMATED_VERIFIED','RUNTIME_VERIFIED','OWNER_REVIEW_READY','OWNER_APPROVED','BLOCKED','close_typical_hand_mesh_to_overlap_max_px','neutral_air_ascending_descending_hand_mesh_to_overlap_max_px','outer_hand_mesh_gap_px','boot_below_physical_floor_max_px','new_true_pairs','new_blocked_pairs','new_recovery_before_next_pairs','native_unobserved_categories','motion_authority','next_authored_work']
with (INC/'FULL_ROSTER_PRODUCTION_MATRIX.csv').open('w') as out:
 w=csv.DictWriter(out,fieldnames=keys);w.writeheader();w.writerows({k:r[k] for k in keys} for r in rows)
print(json.dumps({'rows':len(rows),'review_material_available':9,'professional_review_ready':0,'owner_approved':0}))

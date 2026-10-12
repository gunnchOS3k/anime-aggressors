"""Current all-roster owner package from evidence; no inferred artistic approval."""
import argparse,json,html,hashlib,statistics,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';INC=OUT/'continuous_1011'
p=argparse.ArgumentParser();p.add_argument('--runtime-source',required=True);a=p.parse_args()
def read(path):return json.loads(path.read_text())
def link(path,label):return f'[{label}]({ROOT/path})'
matrix=read(INC/'FULL_ROSTER_PRODUCTION_MATRIX.json');cells=read(INC/'FULL_ROSTER_CONTACT_CELLS.json');manifest=read(OUT/'EVIDENCE_MANIFEST.json');cpu=read(INC/'EMPOWERED_ROSTER_CPU_RESULTS.json');ci=read(INC/'GITHUB_CHECKS.json')
final=INC/'aura_integrity_final1012/results.json';tests=read(final) if final.exists() else []
passed=[r['suite'] for r in tests if r['passed']];failed=[r['suite'] for r in tests if not r['passed']]
complete=len(tests)==15 and not failed
status='15/15 PASS' if complete else f'{len(passed)}/15 passed; remaining or failed checks are pending'
grammars=json.loads((ROOT/'game-godot/scripts/visual/elemental_body_aura.gd').read_text().split('const GRAMMARS = ',1)[1].split('\n',1)[0])
rows=[];table=[];cards=[]
for i,row in enumerate(matrix['rows']):
 fid=row['fighter'];observed=next(x for x in cpu['rows'] if x['fighter']==fid)
 entry={**row,'runtime_source':a.runtime_source,'persistent_aura_grammar':grammars[i],'IMPLEMENTED':'Body-attached persistent aura, original ambience and action-line observer; original movement/choreography candidate retained','AUTOMATED_VERIFIED':'4aura lifecycle/body/facing cases +2action-line body cases; integer tier hashes unchanged across 216 moves','RUNTIME_VERIFIED':'Actual BattleScene source fixtures and activeCPU traces; current GPU/visual aura acceptance pending','OWNER_REVIEW_READY':False,'OWNER_APPROVED':False,'BLOCKED':['Current aura/expression native review: recording reserve','Visible sole/floor coordinate mismatch','Outer heavy/signature reach and directional aerial quality','Production acting/secondary motion and owner taste'],'latest_CPU_probe':observed,'new_shader_native_verified':False}
 rows.append(entry);table.append(f'| {fid} | {grammars[i]} | 4 / 2 | {observed["hits"]} / {observed["shield_contacts"]} | Pending | False |')
 cards.append(f'<article><h2>{html.escape(fid)}</h2><p>{html.escape(grammars[i])}. Both body presentations; four aura lifecycle and two action-line checks.</p><p>Active CPU: {observed["hits"]} hits, {observed["shield_contacts"]} blocks. Source {observed["source_sha"][:12]}; zero new true combos.</p><p class="pending">Current aura GPU/visual review pending storage. Owner approval false.</p><details><summary>Earlier source gameplay, {row["movie_source_sha"][:12]}</summary><video controls preload="none" src="{os.path.relpath(ROOT/row["movie"],INC/"current_owner_review")}"></video><p>Historical source footage; does not demonstrate this increment\u2019s persistent aura or action lines.</p></details></article>')
(INC/'FULL_ROSTER_EMPOWERMENT_MATRIX.json').write_text(json.dumps(dict(runtime_source=a.runtime_source,rows=rows,current_native_ready=False,all_human_release_gates_false=True),indent=2)+'\n')
text=f'''# ANI-03 all-roster owner review — October12,2026

Current shipping source `{a.runtime_source}` on `release/anime-v1-dialogue-and-elemental-performance`. [Draft PR123](https://github.com/gunnchOS3k/anime-aggressors/pull/123) remains stacked on draft122. Resolve package HEAD with `git rev-parse HEAD`; later report commits do not change shipping source. This is an implemented development candidate, with professional choreography and human acceptance unfinished.

## Implemented during this continuation

Native model replacement was independently reproduced and repaired: all 54 swap fixtures across 18 models pass with zero native null-material errors and no warmed node/resource growth. All nine now have authored start/stop/pivot load/counterbalance profiles; 36 public cases preserve all 3,060 physics samples exactly. Held reversals retain pivot ownership. Supporting-joint precision does not establish floor contact or finished acting.

Stale melee ownership during a projectile cast was independently reproduced across 18 body/fighter cases and corrected. Exactly one emitter-owned damage/contact/feedback/primary impact remains. Direct throws retain their previous 39 passing integrity/policy cases. The historical failing throws/projectiles and affected attempts remain excluded.

Persistent energy now follows the real existing meter on all 18 visible rigs, even after charging is released and during movement/jumps. Nine original depth-tested mesh grammars attach to actual rig anchors. A real 100% is required for maximum/super presentation; 75% begins ascension readiness. Full/Balanced/Reduced intensity, reduced flash/density and high contrast are available. Pausing freezes presentation; depletion, KO and model replacement retire the owned effects/audio. Nine quiet original synthesis loops have source hashes and provenance; punch impact and charging audio remain intact.

Action lines use actual displacement, resolved startup frames and the authored striking limb's projected path. Heavy-hit accents require a confirmed collision; misses, shield/armor and duplicate events retain distinct ownership. Short-startup presentation boundary failures were reproduced and corrected without altering move timing. Fullscreen tunnels, true mesh squash and finished acting remain unimplemented.

Fractional meter values previously fell through integer range endpoints, e.g. 99.2→base level 0. The correction selects the existing integer bin. 153 boundary samples pass; all 21,816 integer-scaled move dictionaries across 216 moves match their pre-fix hashes. No threshold, charge/decay/gain rate, scaling table or approved integer-tier combat value changed. See {link('artifacts/v1_closure/spectral_feedback/continuous_1011/AURA_FRACTIONAL_BOUNDARY_CORRECTION.json','tier integrity evidence')}.

## Nine-fighter production matrix

The full roster advances together. The following counts are per fighter and include both bodies. Native visual readiness and every owner approval remain false.

| Fighter | Original body aura grammar | Aura / action-line cases | Recent CPU hits / blocks | Current native aura review | Owner approved |
|---|---|---|---|---|---|
'''+ '\n'.join(table)+f'''

{link('artifacts/v1_closure/spectral_feedback/continuous_1011/FULL_ROSTER_PRODUCTION_MATRIX.json','Motion, range, floor and body matrix')} · {link('artifacts/v1_closure/spectral_feedback/continuous_1011/FULL_ROSTER_EMPOWERMENT_MATRIX.json','Current aura/expression matrix')}.

## Validation and authentic gameplay

Final affected serial integration: **{status}**. Logs bind exact source or parent+diff; engine/resource-exit diagnostics remain visible and are separate from fixture pass. The staged 145-node test does not claim a human ordinary playthrough of all 145 nodes. Preserved ordinary Kaia 20 nodes/16 qualifying receipts, save/restart and the 1,025 dialogue structure retain their original evidence.

Nine fresh public-control activeCPU attempts at `{cpu['source_sha']}` recorded {cpu['hits']} hits and {cpu['blocks']} blocks, with persistent aura observed for every fighter. This pass produced **zero true combos**. Historical strict analysis retains 16 qualifying pairs; emitter identity and actual defender control/recovery are required. {cells['observed']}/108 actual-damage contact cells are observed;{cells['unverified']} remain unverified. Missing cells are not automatically defects. Current-tier post-fix probes, when available, are reported separately; older results are not relabeled as the latest source.

Qualified native stock-loss footage and corrected headless replication remain preserved: one actual stock loss against an activeCPU, not a match win or all-roster KO approval. Guard-affected 19 headless/11 native attempts and projectile-ownership-affected 5 headless/1 native attempts remain conservatively excluded; overlap is not counted as extra tests.

CI snapshot binds `{ci['headRefOid']}`: {sum(c['conclusion']=='SUCCESS' for c in ci['statusCheckRollup'])} successful jobs, {sum(c['status']!='COMPLETED' for c in ci['statusCheckRollup'])} pending. Later commits trigger separate jobs; this does not establish current HEAD completion. Local Mac source fixtures do not establish Android/Pixel/Windows/Web device acceptance.

## Owner assets and instructions

{link('artifacts/v1_closure/spectral_feedback/continuous_1011/current_owner_review/index.html','Nine-fighter review gallery')} contains earlier source-labeled normal-speed original-audio footage. {link('artifacts/v1_closure/spectral_feedback/EVIDENCE_MANIFEST.json','Evidence manifest')} verifies {len(manifest['assets'])} paths/hashes/lineage and separately records acceptance restrictions. 33 retained video files include a failed stale-frame montage and a three-model foreground-clock diagnostic; they are not 33 current-source acceptance videos.

The failed `roster_transitions_4cee67a1.mp4` is **disqualified**: actual native frames contradict expected fighter labels. Its files remain diagnostic. Foreground/frame-identity barcodes separately verified 240 samples across three models with an empirical +1 frame mapping. The new all 18 aura fixture/verifier use this method, but the 3,400-frame native recording did not start because volatile free space fell below the protected 2 GiB + 256 KiB/frame reserve. No new aura video or visual approval is claimed. No heavy export ran below 18 GiB, and no worktree/backup/evidence was removed.

For current source play, use an isolated review profile with `python3 tools/v1_closure/launch_ordinary_review.py --profile ani03_owner_energy_review1012`. Select and play every fighter/body presentation, charge with Special+Shield, release into movement, attack, defend and observe depletion. At normal speed assess body force, support feet, contact/whiff/shield distinction, recovery, silhouette clarity and each element's identity. Use presentation settings to compare Full/Balanced/Reduced and element volume. This is owner review, not release approval.

## Remaining work and boundaries

Every fighter still needs visible refinement of authored movement, move-specific anticipation/contact/follow-through/recovery, directional aerials, defense/throw acting and appropriate hair/cloth/armor/ribbon motion. Boots project33–38 pixels below the physical floor; standalone anchor/capsule experiments worsen strike alignment and remain disabled. Outer heavy/signature gaps remain5–35 pixels. Coordinate model/camera/strike authority together; do not hide these gaps with ground particles or distort anatomy. Ground-contact accents remain blocked until this is resolved. Parry/clash and projectile-terrain rules remain separate game-design decisions.

ANI-03 remains partial technical implementation and unfinished production choreography/native review. ANI-04 acting/OVA/professional voices/rights and ANI-05 physical devices/platform/release acceptance remain open. Temporary restricted Story voices remain local-only. All 33 worktrees/backups, 145 Story nodes and 1,025 cue IDs are preserved. No merge/deploy/tag/release/publication; every game-feel/VFX/animation/SFX/V1/release gate remains false.

{link('artifacts/v1_closure/spectral_feedback/ENGINEERING_BACKLOG.md','Reproducible backlog')} · {link('ANI03_RESUME_STATE.md','Exact continuation checkpoint')} · {link('artifacts/v1_closure/spectral_feedback/NEXT_INCREMENT_PROMPT.md','Next increment prompt')}.
'''
(OUT/'OWNER_REVIEW.md').write_text(text)
gallery=INC/'current_owner_review/index.html';gallery.parent.mkdir(exist_ok=True)
gallery.write_text('<!doctype html><meta charset="utf-8"><title>ANI03 full roster review</title><style>body{background:#111725;color:#eef2fa;font:16px system-ui;max-width:1250px;margin:36px auto;padding:16px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(350px,1fr));gap:16px}article{background:#1b2638;padding:20px;border-radius:12px}video{width:100%}.pending{color:#f5c775}a{color:#97cafa}</style><h1>All nine fighters · development review</h1><p>Shipping source '+a.runtime_source+'; current aura/expression renderer review is pending storage. All owner and release gates false.</p><p>Source fixtures verify36aura lifecycle and18action-line cases. Current native aura footage has not been recorded. Historical media below retains its exact source and limitations.</p><main>'+''.join(cards)+'</main>')
print(json.dumps(dict(rows=len(rows),runtime_source=a.runtime_source,final_integration=status,current_native_aura_ready=False)))

"""Build the source-bound full-roster review; never infer human approval."""
import argparse,json,html,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/v1_closure/spectral_feedback';INC=OUT/'continuous_1011'
p=argparse.ArgumentParser();p.add_argument('--runtime-source',required=True);a=p.parse_args()
def read(path):return json.loads(path.read_text())
def link(path,label):return f'[{label}]({ROOT/path})'
matrix=read(INC/'FULL_ROSTER_PRODUCTION_MATRIX.json');cells=read(INC/'FULL_ROSTER_CONTACT_CELLS.json');manifest=read(OUT/'EVIDENCE_MANIFEST.json');cpu=read(INC/'NEUTRAL_CAST_ROSTER_CPU_RESULTS.json');ci=read(INC/'GITHUB_CHECKS.json')
energy=read(INC/'energy_envelope_native1012/NATIVE_MOVIE.json');before=read(INC/'energy_native_guard1012/NATIVE_MOVIE.json');refinement=read(INC/'AURA_ENVELOPE_REFINEMENT.json')
extremes=read(INC/'PROJECTILE_EXTREMES_ROSTER_CPU_RESULTS.json') if (INC/'PROJECTILE_EXTREMES_ROSTER_CPU_RESULTS.json').exists() else None
all_probes=read(OUT/'COMBO_PROBE_MATRIX.json');heavy=read(INC/'HEAVY_COUNTER_ROSTER_CPU_RESULTS.json') if (INC/'HEAVY_COUNTER_ROSTER_CPU_RESULTS.json').exists() else None;integration=read(INC/'intensity_integration1012/results.json');prior=read(INC/'aura_integrity_final1012/results.json')
assert len(matrix['rows'])==9 and len(integration)==5 and all(r['passed'] for r in integration)
grammars=json.loads((ROOT/'game-godot/scripts/visual/elemental_body_aura.gd').read_text().split('const GRAMMARS = ',1)[1].split('\n',1)[0])
rows=[];table=[];cards=[]
gallery=INC/'current_owner_review/index.html'
for i,row in enumerate(matrix['rows']):
 fid=row['fighter'];observed=next(x for x in cpu['rows'] if x['fighter']==fid);sheet=next(x for x in energy['sheets'] if fid+'_aura.png' in x['path'])
 entry={**row,'runtime_source':a.runtime_source,'persistent_aura_grammar':grammars[i],
 'IMPLEMENTED':'Persistent body aura, owned original ambience, resolved action lines and original authored motion candidates; production acting incomplete',
 'AUTOMATED_VERIFIED':'4aura/body/facing lifecycle cases;2action-line body cases;6intensity and6pool-pressure cases; source/diff-bound receipts',
 'RUNTIME_VERIFIED':'Bothmodel identities and energy/movement/jump native frames verified atc7; activeCPU neutral casts atc7+testdiff. Latest globaldensity fix source-tested, native visual review pending.',
 'OWNER_REVIEW_READY':False,'candidate_visual_review_ready':True,'OWNER_APPROVED':False,
 'BLOCKED':['Visible sole/floor coordinate contract','Outer heavy/signature reach and directional aerial quality','Production acting and secondary motion','Latest global-density normal-speed native review'],
 'projectile_extreme_probes':[r for r in extremes['rows'] if r['fighter']==fid] if extremes else [],'latest_CPU_probe':observed,'latest_heavy_probe':next((r for r in heavy['rows'] if r['fighter']==fid),None) if heavy else None,'persistent_aura_native_verified':True,'new_shader_native_verified':False,'native_energy_sheet':sheet}
 rows.append(entry)
 table.append(f'| {fid} | {grammars[i]} | {observed["projectile_hits"]} / {observed["projectile_blocks"]} | {observed["genuine_pairs"]} | Both visible; candidate | False |')
 rel=os.path.relpath(ROOT/sheet['path'],gallery.parent);oldmovie=os.path.relpath(ROOT/row['movie'],gallery.parent)
 cards.append(f'<article><h2>{html.escape(fid)}</h2><p>{html.escape(grammars[i])}</p><img loading="lazy" src="{rel}" alt="{html.escape(fid)} verified male and female native energy frames"><p>{html.escape(refinement["after_findings"][fid])}</p><p>Neutral-cast probe: {observed["projectile_hits"]} projectile hits / {observed["projectile_blocks"]} projectile blocks; {observed["genuine_pairs"]} strict follow-up pairs. Active CPU. Source {observed["source_sha"][:12]} + driver diff.</p><p class="pending">Production choreography unfinished. Owner approval false.</p><details><summary>Earlier source activeCPU gameplay {row["movie_source_sha"][:12]}</summary><video controls preload="none" src="{oldmovie}"></video><p>Historical footage, guard exclusions retained; does not prove newest aura or density treatment.</p></details></article>')
(INC/'FULL_ROSTER_EMPOWERMENT_MATRIX.json').write_text(json.dumps(dict(runtime_source=a.runtime_source,rows=rows,current_native_energy_source=energy['source_sha'],current_native_ready=True,latest_global_intensity_native_verified=False,professional_choreography_complete=False,all_human_release_gates_false=True),indent=2)+'\n')
true_total=sum(r['genuine_pairs'] for r in all_probes);blocked_total=sum(r['blocked_pairs'] for r in all_probes)
text=f'''# ANI-03 full-roster owner review — October 12, 2026

Shipping source `{a.runtime_source}`; branch `release/anime-v1-dialogue-and-elemental-performance`. [Draft PR123](https://github.com/gunnchOS3k/anime-aggressors/pull/123) remains stacked on draft122. Later evidence commits retain exact media/test source bindings. The entire nine-fighter roster is the development unit. This is a technical development candidate; production choreography and human acceptance remain unfinished.

## Implemented and preserved

Shared +Z orientation, resolved gameplay-phase animation sampling, state-owned clip selection and manual crossfade corrections are retained. Nine original body-chain motion profiles cover start/stop/pivot, attack blocking and landing response. 864 configuration checks and 216 live interactions retain their original source evidence; generated tracks and solver precision do not establish professional fighting technique.

Native model replacement now retains owned materials:54 swap cases across18models, zero native null-material errors, no warmed resource growth. Starts/stops/pivots preserve3,060 public physics samples; held reversal keeps pivot ownership. Both body presentations visibly appear in the latest paired native energy sequence.

Direct throws retain39 integrity/policy cases. Projectile casts retire stale melee ownership:18body/fighter cases now resolve one emitter-owned damage/contact/feedback/primary impact. Historical failing throw/projectile attempts remain excluded from competitive acceptance. Existing punch impacts, facial responses, active CPUs, Story and save authority are preserved.

Persistent energy remains body-attached after release and during movement/jump. Full meter is100; readiness begins75. Nine independently authored depth-tested mesh grammars and quiet original synthesis ambience have lifecycle and provenance receipts. Fractional aura-bin correction passes153 boundaries, preserving all21,816 integer-scaled dictionaries across216moves. Charge/decay/gain rates, scaling tables and accepted integer combat values are unchanged.

This increment widened the nine existing aura envelopes around their actual rig anchors without adding meshes, vertices, materials, models or hitboxes. Ember flame waves now rise; Yin rim contrast is improved. A hypothesized camera-width collapse was not reproduced in36 projection fixtures, so no fictitious camera fix is claimed.

Confirmed primary hit sparks previously disappeared when short expression decorations filled the pool. The independently failing54-case pressure fixture now passes:smears/anticipation/movement accents yield to collision/hurt/defense/KO results; persistent emitter owners remain protected. Heavy accents still require genuine collision; whiffs never prove a hit.

The overall VFX intensity setting previously affected body aura but not shared spectral density. The54-case live-settings fixture reproduced108 failures; the correction passes54 cases. Full/Balanced/Reduced drive shader density1/.6/.2. Reduced permits32 new effects; Full/Balanced retain96. Live changes trim short decorations while keeping charge/projectile/confirmation owners. If those owners alone exceed32, they keep their natural lifecycle. Independent flash/contrast/density controls remain effective. No gameplay values changed.

## Native all-roster review

{link(energy['path'],'Refined all18 energy/movement/jump video')} — **2,747 frames,60fps,45.783s**, H264/AAC with original native game audio. Exact source `{energy['source_sha']}`. All2,566 checked frame/paired-model identity samples match; zero script/null-material errors. The before video at `{before['source_sha']}` is retained: {link(before['path'],'Before comparison')}. Each fighter has verified maximum/released/airborne sheets. Three exact before/after crops are linked in {link('artifacts/v1_closure/spectral_feedback/continuous_1011/AURA_ENVELOPE_REFINEMENT.json','Aura comparison findings')}.

These energy fixtures use public charge/movement/jump input with maleP1/femaleP2 visible. They have **no active CPU**, and certify neither contact nor combo success. The latest global-density correction follows this video and has source-fixture verification; fresh normal-speed native density/expression review remains pending. OriginalAVIs are protected local-only masters; derived MP4s/sheets are development owner review with no release authorization.

CPUrender averaged0.58ms/frame and encoding6.04ms/frame in the offline recording; it ran27% of realtime. GPU timing was unavailable. Native60fps output is not sustained hardware60fps acceptance. No Mac source result establishes Android/Pixel/Windows/Web device performance.

| Fighter | Original energy grammar | New projectile hits / blocks | New strict follow-up pairs | Native bodies | Owner approved |
|---|---|---|---|---|---|
'''+ '\n'.join(table)+f'''

The nine rows remain implemented development candidates, automatically/source verified within stated scope, and runtime-visible. Candidate review material is available; professional `OWNER_REVIEW_READY` and `OWNER_APPROVED` remain false. Rook/Yin energy is still subdued, Vesper/Nix subtle, and no fighter is declared finished. See {link('artifacts/v1_closure/spectral_feedback/continuous_1011/FULL_ROSTER_PRODUCTION_MATRIX.json','Full production/contact/body matrix')} and {link('artifacts/v1_closure/spectral_feedback/continuous_1011/EXPRESSIVE_COMBAT_GAP_MATRIX.json','Expressive feature gaps')}.

## Authentic gameplay and regressions

Nine fresh900-frame public-input neutral-cast probes, active CPU for every fighter, recorded**{cpu['hits']} body hits/{cpu['blocks']} blocks**, including**{cpu['projectile_hits']} projectile hits/{cpu['projectile_blocks']} projectile blocks**. The old recipe sometimes selected sideSpecial while moving. The corrected driver approaches legitimate range, releases directional input on its cast tick, and uses unchanged game authority. No opponent freezing, forced contact/KO or damage/hitstun override.

**Two new strict pairs**:Orion projectile→forward_tilt at trace437→444; Vesper forward_tilt→an earlier projectile arriving at375→380. Distinct attack owners and absence of defender control before second contact establish these observations. Neither is a blanket guaranteed-combo/balance promise.36other follow-ups were shielded and84arrived after recovery. The preceding nine aura probes retain90hits/146blocks and one Kaia forward_tilt→forward_tilt pair510→530; its aerial recipe label does not make it an aerial combo.

Across all{len(all_probes)} retained probes, strict analysis records**{true_total} qualifying pairs/{blocked_total} blocked follow-ups**; defect-affected throws/guards/projectiles remain excluded. Actual contact coverage is**{cells['observed']}/108**, with**{cells['unverified']} unverified cells**, combined across individually source-bound non-quarantined historical/current observations. This is not108 fresh exact-current-build reruns. Missing evidence does not imply a broken mechanic. Actual damage bands and move classes determine coverage, not recipe names. {link('artifacts/v1_closure/spectral_feedback/continuous_1011/NEUTRAL_CAST_ROSTER_CPU_RESULTS.json','Newest roster CPU receipts')} · {link('artifacts/v1_closure/spectral_feedback/COMBO_INTERACTIONS.json','Exact contact/recovery/ownership traces')}.

Two subsequent allnine low/high projectile passes at`{extremes["source_sha"]}` recorded{extremes["hits"]}bodyhits/{extremes["blocks"]}blocks, including{extremes["projectile_hits"]}projectilehits/{extremes["projectile_blocks"]}projectileblocks. TwoOrion projectile→tilt pairs409→422 and436→442 occurredbeforedefendercontrol.92follow-upsblocked,146afterrecovery. Oversizedprofile attempt stoppedbeforeGodot andremainsfailed; newunusedlabels completed. No gameplaytuning.\n\nCurrent presentation integration:**5/5 PASS** (SpectralIntensity54,ExpressionPoolPriority54,SpectralFeedback,ActionLineProduction18,PersistentEmpowerment36), parent+diff bindings retained. The prior**15/15 integration PASS** at9e0d13ae remains exact-source historical evidence, reused for unchanged combat/Story/save dependencies; it is not relabeled as a new full-suite run. It includes145 staged campaign nodes,18 shipping roster presentations and CampaignRestart. Ordinary Kaia20nodes/16qualifying receipts across restart and1,025cue structure retain their separate receipts. Logs preserve resource-exit diagnostics separately from fixture pass.

A subsequent allnine low-heavy publicCPU pass at`{heavy['source_sha']}` recorded{heavy['hits']}body hits/{heavy['blocks']}blocks, includingone heavybodyhit per fighter and{heavy['heavy_blocks']}heavyblocks. It adds{heavy['true_pairs']}strictpairs (Juno jab1→jab2→forward_tilt, two links, not heavy→light),{heavy['blocked_pairs']}blocked and{heavy['recovery_before_next_pairs']}after-recovery follow-ups. Actualheavycontact atlowdamage is verified for allnine; this doesnotdeclare everyheavy acombo starter.

Qualified competitive native stock-loss footage and repaired headless replication remain preserved:one authentic stock loss against an activeCPU, not a match win or all-roster KO proof. Guard-affected19headless/11native attempts and projectile-ownership-affected5headless/1native attempts remain conservatively excluded; overlapping exclusions are not summed as extra tests.

GitHub snapshot source `{ci['headRefOid']}`: {sum(c['conclusion']=='SUCCESS' for c in ci['statusCheckRollup'])} successful jobs/{sum(c['status']!='COMPLETED' for c in ci['statusCheckRollup'])} pending. Later source/evidence commits trigger distinct checks. {link('artifacts/v1_closure/spectral_feedback/continuous_1011/REGRESSION_LEDGER.json','Regression ledger')} · {link('artifacts/v1_closure/spectral_feedback/EVIDENCE_MANIFEST.json','Evidence paths/hashes/source/restrictions')} ({len(manifest['assets'])} verified assets; count includes a disqualified stale-frame movie and a three-model diagnostic). The stale `roster_transitions_4cee67a1` remains failed; native-frame identity disagreement was never promoted to acceptance.

## Storage, remaining production and owner action

{link('STORAGE_RECOVERY_REPORT.md','Safe storage audit')} found only6.016MiB of verifiedGREEN disposable Godot documentation caches; actual immediate free-space gain5.414MiB. The5–10GiB target was not safely achievable. All33worktrees/backups/source/native originals remain preserved. Both bounded native jobs retained the2GiB reserve. Heavy exports remain prohibited below18GiB. Volatile free space is measured at launch and during owned recording; partial outputs are retained on interruption.

Every fighter needs move-specific full-body anticipation/kinetic-chain/contact/follow-through/recovery, directional aerials, defensive/throw acting and restrained authored hair/cloth/armor/ribbons. Boots still project33–38px below the physical floor; standalone anchor/capsule changes worsen strike alignment and remain unshipped. Outer heavy/signature gaps5–35px require coordinated model/camera/strike authority. No hitbox/anatomy distortion or ground particles conceal that problem. Ground-contact accents remain blocked. Parry/clash and projectile-terrain competitive rules require separate design authority.

Review allnine at normal speed, then play each fighter/body in an isolated profile: `python3 tools/v1_closure/launch_ordinary_review.py --profile ani03_owner_energy_review1012`. Charge withSpecial+Shield, release, move/jump/attack/defend, compare depletion and Full/Balanced/Reduced, flash/density/contrast settings. Judge body force, footwork, contact/miss/block distinction, recovery, silhouette and elemental identity. Candidate feedback does not authorize release.

ANI-03 remains partial production. ANI-04 authored acting/OVA/professional voices/rights and ANI-05 physical-device/platform/release acceptance remain separate unfinished dependencies. Restricted temporary Story voices remain local-only. No merge/deploy/tag/release/publication. `GAME_FEEL_HUMAN_PASS`, `VFX_TASTE_HUMAN_PASS`, `ANIMATION_TASTE_HUMAN_PASS`, `SFX_MIX_HUMAN_PASS`, `V1_ANIME_HUMAN_PASS` and `FINAL_RELEASE_AUTHORIZED` all remain false.

{link('artifacts/v1_closure/spectral_feedback/ENGINEERING_BACKLOG.md','Reproducible backlog')} · {link('ANI03_RESUME_STATE.md','Exact checkpoint')} · {link('artifacts/v1_closure/spectral_feedback/NEXT_INCREMENT_PROMPT.md','Next engineering prompt')}.
'''
(OUT/'OWNER_REVIEW.md').write_text(text)
video=os.path.relpath(ROOT/energy['path'],gallery.parent)
gallery.parent.mkdir(exist_ok=True)
gallery.write_text('<!doctype html><meta charset="utf-8"><title>ANI03 full roster review</title><style>body{background:#111725;color:#eef2fa;font:16px system-ui;max-width:1300px;margin:32px auto;padding:16px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(350px,1fr));gap:16px}article{background:#1b2638;padding:18px;border-radius:12px}video,img{width:100%}.pending{color:#f5c775}a{color:#97cafa}</style><h1>All nine fighters · development review</h1><p>Shipping source '+a.runtime_source+'. Latest energy video source '+energy['source_sha']+'. All human/release gates false.</p><video controls preload="metadata" src="'+video+'"></video><p>All18visible model presentations, public charge/movement/jump, original native audio and60fps output. NoCPU/contact/comboproof. Latest global-density update source-tested; native review pending.</p><main>'+''.join(cards)+'</main>')
print(json.dumps(dict(rows=len(rows),runtime_source=a.runtime_source,current_native_energy_source=energy['source_sha'],latest_integration='5/5PASS',professional_ready=False)))

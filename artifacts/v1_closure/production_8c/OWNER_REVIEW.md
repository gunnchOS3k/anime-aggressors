# 8C owner review — saved full-roster candidates, final art pending

PR123 remains draft, stacked on122. Use `git rev-parse HEAD` for the delivery commit. Runtime sources, exact recorded SHAs, source diffs and asset hashes are preserved in the evidence receipts. All human art/gameplay/mix/balance/device/release gates remain false. **8C and V1 are not complete or release-ready.**

## Play

```sh
tools/v1_closure/play_party_review.command kaia-windrow --body female --opponent juno-spark
```

Choose any canonical fighter; `--body male` and `--local` are supported. This existing launcher uses isolated review saves. A/D move, J attack, K special, W jump, L guard, U grab, I dodge. Hold L+K to charge aura, then press J while holding both to attempt an eligible permanent advancement. Recharge before the next advancement when required. T activates the declared Party pickup and a fresh T executes its authorized ultimate.

The launcher displays the actual saved-form export status. Permanent advancements, temporary Party states and earned Story unlocks retain separate authority.

Optional unapproved balance experiment:

```sh
tools/v1_closure/play_party_review.command yin --body male --opponent yang --shield-break-candidate
```

Only this explicit review flag enables66-frame recovery,45% guard restoration and a release before guard re-entry. Accepted baseline remains strict0.4seconds/full restoration. Perfect Guard remains4fresh-press frames/24rearm; ordinary grabs remain valid, with no universal reflection. Existing Options provide Full/Balanced/Reduced, reduced flashes/shake/density, high contrast and elemental volume.

## Actual implementation

- **Saved original production:**18editable rig copies,144new transformation/empowered-idle WIP actions,36additive stage GLBs; all540saved8Bactions, original geometry/rest/weights and old actions preserved.12,120evaluated source frames, maximum matrix-component error0.0000037551. This is correspondence evidence, not an acting-quality score.
- **Runtime:** actual saved clips are sampled by the existing transformation clock. Powered idle yields to movement, attacks, hurt and interruption. Pause no longer advances transformation progress. New structures follow the imported body rig using the measured exported/imported rest-basis difference; no body translation/scaling, hitbox or damage edits.
- **Defense:** nine original elemental contours, normalized structural warnings, attacker/defender contact interplay and rupture. Guard bounds follow live projected head/support feet. One persistent mesh plus at most one transient uses the existing pool; no new damage or defensive resolver.
- **Audio:** two owned voices score permanent transformation and Party/ultimate events; two separate guard voices remain bounded.189original arithmetic PCM cues,27compact listening WAVs,4,339,062bytes. No imported recordings, voices or copied performances. Distinct activation, climax, recovery, cancellation and expiry use authoritative event edges. Final integrated mix/listening approval is pending.

## Full roster

Both body presentations and both facings have actual source and engine coverage. Seven fighters retain BASE→AWAKENED_BUILD→ASCENDED; Yin/Yang retain separate BASE→COSMIC_SURGE→COSMIC_ASCENDANT.

| Fighter | Original WIP advancement language | Source/engine status | Artistic gap |
|---|---|---|---|
| Ember | Braced ignition, pressure, furnace vents/heat crown | Both stages/bodies saved, exported and imported | Costume/hair evolution and full combustion body performance |
| Rook | Supported compression, armored expansion/strata | Same | Convincing mass, armor follow-through and full acting |
| Juno | Routed gathering, snap reveal, conduction rails | Same | Stronger staged silhouette and full electrical choreography |
| Kaia | Supported compression, outward flow/airfoils | Same | Original cloth/air acting and full aerodynamic performance |
| Nix | Precision formation/locking, mantle facets | Same | Final crystal/material deformation and full acting |
| Orion | Orbital gathering, compressed center/nodes | Same | Refined orbital composition and full gravitational acting |
| Vesper | Controlled displacement, split surfaces | Same | Phase readability, source secondary control and full acting |
| Yin | Inward gathering, stillness/apertures | Separate cosmic stages saved/exported/imported | Final cosmic silhouette, subtraction acting and True Aspect art |
| Yang | Ordered gathering, outward hard-light construction | Separate cosmic stages saved/exported/imported | Final cosmic silhouette, construction acting and True Aspect art |

`FORM_MATRIX.json` contains all36body/stage entries and separate source, import, native-still, device and human gates. Original anatomy/costume/hair are retained; these small rigid structures are **not finished transformed models, deforming secondary motion or complete form-specific combat/ultimate animation**. All nine need further original art production. `SOURCE_ART_REQUIREMENTS.json` identifies exact18sources and limitations, including the22-bone rig's missing finger controls, independent hair/cloth weights, paired mesh grip and dedicated KO/break/ultimate acting.

## Review media

- [Female BASE/first/second form comparison](form_native_rest1022/forms_female_staged_actual_renderer.png)
- [Male BASE/first/second form comparison](form_native_rest1022/forms_male_staged_actual_renderer.png)

Each sheet shows BASE/first/second forms for nine fighters, rendered by actual Godot Compatibility. These54views use explicit form/idle fixtures, not earned advancement, cinematic acting or active-CPU acceptance. Earlier misplaced-attachment sheets are retained in `form_native1022/`; imported-rest correspondence is corrected in the current sheets.

- `guard_native_projected1022/`:18body active-CPU guard observations,42real contacts, two compact native montages. The initial set in `guard_native1022/` retains40contacts and stale fixture HUD names; its manifest identities remain authoritative.
- `guard_visible_final1022/`: targeted actual Rook close view after contour contrast correction. Earlier on/off pixel deltas are diagnostic because independent rendering was not fully isolated; they are not a strict visibility acceptance metric.
- `shader_review1022/` and `guard_mesh1022/`: separately labeled analytical shader rasters on AppleM2/OpenGL4.1 Compatibility.
- `audio_final1022/listening/`: per-fighter guard, transformation and Party event sequences. Standalone peaks/RMS/endpoints were measured; full mix loudness, listening taste and physical-device acceptance were not.

No new large movies or platform exports were made. Native stills, fixed60 headless simulation and sustained real-device FPS are different evidence categories. Sustained target-device performance remains unmeasured. Largest new stage resource:190vertices,194triangles,4socket groups,18,344bytes.

## Tests and genuine gameplay limits

-90saved-form engine rows PASS:72public-input transformations covering nine fighters/bodies/facings,18real attack interruptions; actual clip progress, idle, movement, attack and pause behavior checked.
-72actual attachment rest/body/facing/stage checks PASS after the native-discovered basis correction.
-109guard roster rows PASS;63representative form/Party/sustained-break/projectile cases PASS. After actual saved-form installation,54additional PerfectGuard form/Party checks and63guard/domain/projectile checks also PASS in `guard_forms_saved1022/` and `guard_domains_saved1022/`.
-36all-nine/both-body/facing public ultimate cases pass new owned-audio assertions;189PCM checks PASS; PartyLifecycle10PASS includes nine interruption/stock cases and an unaccelerated600tick expiry.
-Existing ThrowOwnership39, FormStateAuthority90, PerfectGuardForms54, GrabLifecycle15 and PartyGrabInterruption9 pass. Shutdown warnings are retained: Party10objects/5resources reproduces identically on pre8C4d197580; grab/form suites have additional recorded exit warnings. No warning-free cleanup claim.
-Nine bounded activeCPU observations completed from declared initial aura100for both actors. Each fighter completed one first advancement;16real contacts total. Ember/Kaia had no contact in this recipe. Second advancements, guaranteed combos, wins and earned Story progress were not demonstrated. All real outcomes remain unchanged.

Original parse/observer failures, the pause failure, initial attachment-basis defect and intermediate unsuccessful correction remain preserved. The isolated launcher now rejects unhandled Godot script errors even when Godot returns process exit0.

## Source preservation and CI

[Manual production run39790037341](https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39790037341), exact source `1e06532c4775129f81aed13b1ff9eab940683220`: every dedicated production, validation, upload and CompleteJob step reports SUCCESS. Final verification now reports the workflow and production job SUCCESS. Earlier pending job/run metadata is retained in the recovery receipt; `WORKFLOW_COMPLETION.json` records the resolved terminal status.

Verified artifacts: runtime12433391219(3,098,967bytes), source12431779789(83,965,145bytes). Strict receipt, hashes and complete production log: `remote_39790037341/`. Actual18editable8CBlenders(609,148,736bytes) plus zip and reproduction code are durably verified at:

`/Volumes/gunnchOS-Archives/10-Anime-Aggressors/art-source-snapshots/2026-10-22_8c_1e06532c_39790037341`

The earlier verified8Barchive remains unchanged. Existing33worktrees, owner saves, original rigs/BASE GLBs,216BASE moves, Story and established form data are preserved. Internal SSD is below18GiB plus allocations; heavy local production/export/recording remains blocked. See current storage/CI evidence receipts, not historical free-space estimates.

## Exact next production work

Use the preserved18editable candidates to author real paired grip/support exchanges, independently weighted hair/cloth/armor and original full form/ultimate/guard-break body acting across all nine. Preserve canonical anatomy, balance and frame-zero throw ownership. The ordinary cosmic stages do not finish Yin/Yang's large True Aspect art. Native cinematic motion review, full second-stage CPU/body/facing coverage, seven earned Story routes, Convergence, final continuous OVA/variants, genuine LAN, physical controllers/devices and platform acceptance remain open.

No merge, tag, deployment, release or human approval has occurred.

# Anime Aggressors V1 coordinated closure — continuation checkpoint

This is an implementation checkpoint, not completed V1. Do not publish. Work serially; do not spawn subagents.

## Exact checkout and preservation

- Repository origin: `https://github.com/gunnchOS3k/anime-aggressors.git`.
- Fetched origin/main baseline: `887e100114c9741ebc7a449b46116bcb6eef5072`.
- Branch: `codex/anime-v1-closure-2026-10-06`.
- Worktree: `/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure`.
- Preserved dirty Cursor checkout: `repos/_v4_identity_rebuild_worktrees/anime-aggressors`; its source was not reconciled or modified.
- Preservation: workspace `owner_backups/anime_v1_closure_2026-10-06/manifest.json`, 3,287 file states / 795 content objects plus staged/working patches and refs. Verified every compressed object against its SHA256 after cleanup. Manifest SHA256: `1d0cf84125d2dbcb82ef9ba79aeb6852829415e20c5dba2951f886c98880147d`.
- `artifacts/v1_closure/disk_cleanup.json` records every removed path, Git tracking/ignore check, category and capacity measurements. 69 safe paths: four old dependency trees, ten import caches, fifteen Android compiled intermediates, ten duplicate Android libraries, five compressed build caches, fifteen old web dist trees, six Rust output paths and four Rust object/library files. Initial free 11.111 GiB after checkout; cleanup achieved 18.043, additional cleanup 18.768, generation recheck cleanup 18.125 GiB. Working generation consumes headroom; recheck before another heavy phase.

## Authority and canon

`artifacts/v1_closure/authority_lock.json` locks 48 source hashes, including the copied owner tasks in `docs/anime-aggressors/v1_closure/owner_tasks/`. The complete authority set is the repository Creative Authority Pack, fighter bibles, movement/animation bible, Story campaign bible, VFX/audio authorities the two owner V1 tasks and the newer scoped female/hair/OVA override. Do not infer newer owner canon from old engineering reports or generated manifests.

The owner V1 collectible proportions supersede older proportion recommendations. Original articulated collectible geometry must preserve fighter lore/identity. No third-party trade dress. The older Awakened/Ascended gameplay ladder is not Prismatic Gray.

Kaia → Rook First Loss remains canon. Six other First Losses remain OPEN. `artifacts/v1_closure/first_loss_owner_options.json` gives three proposed candidates and rationale per protagonist, with loss identity, core-flaw challenge, emotional consequence, dialogue implications and Prismatic-resolution impact; no choice selected or approved.

## Implemented runtime/assets/pipeline

- Exact initial census: 64 presentation/form rows, 216 declared move rows and 999 semantic animation slots in `artifacts/v1_closure/baseline.json` / `BASELINE.md`. Static declarations do not count as runtime passes.
- New Story autoload/controller, atomic save/resume and contiguous-prefix save validation; route picker, male/female presentation, new game confirmation, replay, loss/retry, result receipt, navigation and return. BattleScene outcomes advance encounters, never a menu button. All 49 opening battles, seven Accord and catastrophe scenes, and seven two-boss cosmic survival encounters have runtime code. Kaia’s canonical Rook loss saves/resumes Essence 1. Other routes stop at OPEN First Loss; Kaia stops at the unfinished Puppet chapter.
- Seven routes are source-derived recruitment pair order plus Convergence graph. Dialogue/opening adaptations are marked DRAFT. Normal access starts with Kaia; `AA_V1_ROUTE_REVIEW=1` in a debug build opens other route beginnings for review without granting Gray or cosmic completion.
- Yin/Yang selection is locked until actual Story unlock, with debug route review bypass for testing. The preexisting Yin/Yang moves still clone Ember and remain TUNING_CANDIDATE.
- Original Blender collectible candidate pipeline for nine identities, male/female, spectrum BASE/PRISMATIC_GRAY/BLACK_PUPPET/WHITE_PUPPET and cosmic BASE/COSMIC_BOSS: 64 exported presentations. Source `.blend` files retained in `art_source/collectible_v1/`. Canonical 22-bone rig, rigid module weights, sockets, 111 semantic key-pose candidates plus runtime aliases. Procedural clips are not complete authored animation.
- Actual FighterModel3D uses these candidate GLBs, preserves sculpted face/costume/form materials and embedded clips, and keeps gameplay root motion in physics. Model source is COLLECTIBLE_V1_CANDIDATE; all final human art/motion flags remain false.
- Pipeline fixes: isolate curve conversion selection (conversion previously removed modifiers from the last selected mesh); restore existing source modifiers and re-export; purge previous armature action users; retain sparse linear keys instead of redundant frame sampling. Existing-source repair mode is for the generation already begun with verified 18 GiB headroom, and has a 15 GiB remaining guard. New generation still requires 18 GiB. Never delete preserved source or worktrees to make room.
- Heavy input: simultaneous Attack + Special on ground below full aura. Full-aura Attack remains super. In-app and written control hints added. Existing moves/canon/timing retained.
- Active movement impulses and projectile cast emission now occur once per activation, instead of every active frame. This prevents Kaia's recovery from accumulating unintended upward speed.
- Confirmed block classification happens before feedback; block gets block audio, shield flash, short hitstop and zero launch, rather than super/hit/launch feedback. Web shield-hit audio is tied to confirmed shield stun/break increase, not raising shield. Projectile impact fallback uses the confirmed move ID.
- Original layered filtered-noise / impulse-resonator / delay-lattice SFX: 135 WAV candidates, nine fighters × 15 events. Startup, impacts, blocks, KO, select and existing transformations wired. Dedicated signature/launch/state mix integration still pending; none approved procedural-final.
- Battle framing's zero occupancy target corrected; collectible material recoloring bypassed; versus portraits carry the selected body presentation. Captures must be regenerated after these fixes.
- Export presets explicitly include JSON needed by FileAccess-driven runtime data.

## Validation and review

Tools: Godot 4.7.1, Blender 3.3.1. Give Godot an explicit `/private/tmp/...` log file; default user log creation is denied in the shell sandbox. Visible Godot requires escalated execution because macOS app-service access stalls in the sandbox. Do not repurpose HOME.

- `CampaignCheckpoint.gd`: 49 real BattleScene movement + scripted blast-zone KO + Results/Story transitions, atomic save/resume, loss/replay/idempotent receipt and malformed/forged-save checks. Passed. Does not prove later chapters or a human playthrough.
- `ShippingRosterPath.gd`: 18 BASE presentations through real select/lock/stage/versus/countdown, move/jump, light/heavy/special/super input, resolved hit/block, recovery input, staged blast KOs, victory/defeat/rematch/return. Passed. Scripted contacts/KO setup is explicitly recorded; all non-base form lifecycles remain unproved.
- `CombatActivation.gd`: real Fighter callbacks across all active frames; one recovery impulse, one projectile, confirmed block audio/hitstop/no launch and no contact feedback from raising shield. Passed.
- `CollectibleRuntime.gd`: 64 model configure/22-bone imports/embedded clip playback and all 135 WAV loads. Repeat after repaired asset import, recording the final hashes.
- `validate_assets.py`: checks current GLB hashes, all 111 semantic candidate clips, 22-joint skins, every mesh skinned, and no inherited suffixed semantic clips. Must pass after final repair.
- Dummy-renderer texture capture is guarded. Shutdown resource-leak warnings and sandbox CA/editor-save/achievement-write warnings remain visible in logs; do not equate them with artwork or runtime completion.
- Review index: `artifacts/v1_closure/review/index.html`. Roster/form renders, SFX comparison, route map, evidence scopes, canon choices and missing deliverables are assembled by `tools/v1_closure/build_review.py`. `CaptureReview.gd` supplies real Godot battle-camera/turntable/staged move frames; convert them into GIFs with bundled Pillow. Regenerate visible captures after framing/material/skin fixes and after the build SHA is stamped.

## Precise unfinished V1 work

1. Full Kaia campaign beyond the canonical Rook loss: 3v2 Puppet imbalance, releases, equilibrium 2v2, dual releases, Essence 1→2→4→6, the second impossible Yin/Yang encounter, Prismatic Gray transformation, route ending, unlock and next-route navigation.
2. All six other full campaigns beyond the first cosmic survival encounter. Only six First Loss choices require owner canon approval; the remaining objectives, teams, progression, transitions, cinematics and save/resume implementation are technical work that can proceed independently.
3. 7/7 Gray completion, Sevenfold Convergence, declared cosmic story/boss contracts and actual Yin/Yang unlock. Current saves correctly keep these false/locked.
4. Distinct Yin/Yang competitive moves/tuning; every non-base form's actual selection/transformation/combat/KO/results lifecycle and presentation. Generated GLBs are not form gameplay.
5. Complete fighter-specific authored locomotion, combat strings, aerials, throws, reactions, selection, victory/defeat and story motion, with expressive faces and exact move/hitbox/VFX/SFX/hitstop/camera synchronization. Current 111 slots are procedural candidates, not completion.
6. Captivating fighter-specific VFX behavior/shape, original approved procedural-final or authored SFX, severity/state/whiff/signature/launch/menu mix and dedicated transformation cues; human game-feel/taste review.
7. Full required owner package: final turntables, signature/impact and elemental montages, transformed gameplay/unlock evidence, completed campaign matrix, exact exported artifact SHA. Current package is a checkpoint, not acceptance.
8. Complete the continuous Kaia OVA and six Campaign Variations beyond the current previews; shared graph, route-specific chemistry/reactions, approved First Loss dialogue, Prismatic emphasis/endings, transitions, voices/music/cinematic mix.
9. Exercise exported shipping artifact, Web and Android full runtime paths. Keep source-scene tests separate from exported build proof.

## Owner gates — always false until owner review

FINAL_CHARACTER_ART_PASS=false
ANIMATION_TASTE_HUMAN_PASS=false
GAME_FEEL_HUMAN_PASS=false
VFX_TASTE_HUMAN_PASS=false
SFX_MIX_HUMAN_PASS=false
STORY_HUMAN_PASS=false
V1_ANIME_HUMAN_PASS=false
V1_AUTOMATED_READY=false

Commit/push this branch at each safe logical checkpoint before the usage window is low. Do not start another large phase until this checkpoint is validated, committed and pushed. Record exact source build SHA and artifact hashes separately from evidence-only commits.

## Previous checkpoint artifact and evidence (superseded by override export below)

- Exact exported source SHA: `cd70c9277d215997c1893133b68d29410cd44eb4`.
- Local owner-review PCK: `/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/build/v1-owner-review/anime-v1-review.pck` (59753728 bytes).
- PCK SHA256: `0ec708b8054a28dda348adb7f2c0ba48850f610dcb999024bf04ad4b3705ea77`.
- Repaired 64 GLBs passed all skin/hash/111 semantic candidate checks; final Godot model/clip/WAV import checks passed 64/64.
- Final visible captures were regenerated from this source SHA after framing, skin, material and placeholder-overlay corrections. Review GIFs and full roster sheet are assembled from those actual frames.
- The exported PCK has a separate limited runtime probe; consult `packed_runtime_evidence.json` for its exact outcome/scope. Web and Android exported full lifecycles remain unproved.
- Recheck capacity before more heavy generation. No preservation/source/worktree registrations were deleted.

- Exported PCK limited probe: PASS, 9/9 BASE model/move loads and attack-input paths with exact embedded source SHA. Eval-mode CPU inputs were explicitly cleared and landing completed before human-input probes; no full exported lifecycle claim.
- Owner review contains 45 real-renderer GIFs (9 turntables + 36 move demonstrations), 18-view roster sheet, form comparisons, 135 SFX candidates, Story route map and unresolved canon options. Narrow local preview serves only the review directory, never the worktree; PCK downloads are local and ignored by Git.


## New owner override implementation — 2026-10-06

- Continue from checkpoint `9279e71f44eeae9f3e7340be20c3a0c187f38b99`; do not restart audit/preservation/authority ingestion. New owner document copied into `owner_tasks/CODEX_ANIME_OWNER_OVERRIDE_FEMALE_VARIANTS_HAIR_OVA.md`; SHA256 `c7c28327bbb0ba2b42074b1ab4a7576a75cc24f23be881e7ae8ffc686103ce25`. It supersedes earlier generic variant/hair directions only in its declared scope.
- `owner_override_matrix.json` records exact female hair directions, male checkpoint hair preservation and owner-open male redesign. `review/owner_override/before` retains all 18 BASE view sets. `male_hair_preservation.json` verifies identical mesh vertices/local transforms before/after for all nine male hairstyles.
- All nine female sources rebuilt with tailored full armor, compact torso/shoulders, tapered limbs, smaller hands/boots, sculpted face and owner-specific hairstyles. Rook has visible box-braid framing; Kaia has large storm curls; Orion has an afro puff; Vesper has transparent phase loc echoes. Female Yin/Yang have original descending eclipse / ascending creation diadems and formal flowing hair. Existing armored body/identity foundation retained.
- All 64 presentations have ten skinned facial morph candidates and personality rest faces. The expression controller connects combat intent/effort/pain and victory/defeat; cinematic expressions persist through idle transitions and clear when combat resumes. Puppet masks now have visible rewritten eye morphs and inward/outward control seams with constrained facial strength. Gray remains achromatic dominant.
- Elemental armor additions reinforce per-fighter geometry; Rook gets rough geological material and runtime procedural normal detail. Existing male hair geometry remains intact, while facial and armor refinement intentionally changes model hashes.
- One main `Anime Aggressors OVA — Kaia Route`, six named `Campaign Variations`; all share `v1_campaign.json` and real BattleScene actors/moves/contact/VFX/candidate audio. Pause/chapter seek/return exist; seeking cannot skip the first unimplemented/open-canon node. Watch progress is separate and never writes Story or grants unlocks. Current continuous previews stop at unfinished production; no full OVA completion claim.
- First cosmic encounter is a 24-second survival objective with real Yin + Yang actors. Their Story-only metadata rejects normal damage/grabs; competitive models do not carry this contract. Survival receipt requires elapsed objective evidence; stock-win receipts cannot forge it. Kaia’s canonical loss scene saves Essence 1; all six other First Loss identities remain null/blocked.
- Additional headroom cleanup: 13.2187 → 19.2604 GiB; exactly historical `scaly-wings/node_modules`, `android/app/build/intermediates/merged_native_libs`, and `.../stripped_native_libs`. All checked untracked/ignored, reproducible, unused, no protected descendants. Other dependency trees with env/key/signing fixtures were skipped. Snapshot still verifies 3,287 states / 795 objects. See `owner_override_disk_cleanup.json`; recheck capacity before another large generation phase.
- Checks: `OwnerOverrideFaces.gd` 64 configure/morph/acting cases; `OwnerOverrideRuntime.gd` seven real two-boss elapsed survival paths plus seven watch modes, save/resume/Kaia Essence/open canon/navigation. Survival test freezes an invulnerable player after real movement; it proves plumbing, not a human playthrough. Existing 18 BASE shipping lifecycles, 49 opening campaign paths and activation/block checks rerun. All 64 structural hashes/22-joint skins/111 semantic slots/ten morph names checked.
- Review generators: `CaptureOverrideReview.gd` supplies 198 real-renderer facial images and continuous OVA preview/contact audio receipts; `build_override_review_media.py` assembles expression/before-after/silhouette sheets and event-aligned candidate SFX movie. Raw movie frames are ignored regenerable output; keep assembled review evidence. `CaptureReview.gd` regenerates current battle/turntable/move GIFs.
- Owner-only gates and automated-ready remain FALSE. Source/build stamp, final capture/export/probe and exact artifact hash are recorded in the next evidence checkpoint. Keep earlier source SHA/artifact explicitly historical.


## Final owner-override review artifact and exact boundary

- Runtime/art source SHA: `ce2775f1fddc725c4cad639ef03d87666ec6d003` (main implementation `06112578bc8a10dadc589e173456060d689c6a4e` plus capture-projectile filtering). The subsequent review evidence/helper commit does not alter gameplay or art source. Its capture helper uses `look_at_from_position` to avoid a nonfatal deferred-camera warning; the exported runtime path is unchanged.
- PCK: `build/v1-owner-review/anime-v1-owner-override-review.pck`, 93,426,580 bytes; SHA256 `a62f4458506dc66d5fcd7eaf088148a1e8edc9e57d696e83e2e123a14c3435dc`. Prior `anime-v1-review.pck` and the intermediate `...06112578.pck` retained. No publication.
- Exported PCK limited probes PASS: nine BASE BattleScene model/move/attack-input paths; all seven two-boss survival paths, Kaia first-Essence save/resume, six unresolved loss stops and seven watch preview pause/seek/return paths. `packed_owner_override_probe.gd` reproduces the new packed check with `AA_V1_ROUTE_REVIEW=1` and `AA_EXPECTED_BUILD_SHA=ce2775f1fddc725c4cad639ef03d87666ec6d003`. It uses an isolated temporary save and a staged invulnerable/physics-frozen survivor after real movement; no human playthrough claim.
- Current renderer package: 198 facial images / 18 expression sheets, all 18 male/female geometry silhouettes, nine before/after female hair comparisons, elemental and cosmic crown comparisons; 45 current-source battle/turntable/move GIFs and all nine light/heavy/special/super impact/VFX comparisons. One 131.6-second Kaia preview has 987 captured frames and 295 actual move-start/contact SFX receipts mixed from existing original WAV candidates. Final OVA pacing, screenplay acting, voice/music and mix are still unfinished.
- Campaign matrix: **71/145 nodes implemented, 0/7 Gray routes complete**. Seven routes reach the first two-boss encounter; Kaia additionally reaches canonical Rook loss and saved/resumed Essence 1. Kaia stops at `kaia-windrow:puppet_imbalance`. Six other routes stop at their `:first_loss` with null identity. Convergence remains 0/5; Yin/Yang playable unlocks remain false.
- Exact next technical work: actual five-Puppet 3v2 encounters and player release choice/state; first release and equilibrium 2v2; opposite-force paired releases and Essence 2→4→6; Gray transformation gameplay/cinematic and original-identity integration; second impossible confrontation/objectives; endings/unlocks/next-route navigation; Convergence and cosmic playable unlock. Build route systems downstream of open choices parametrically; do not select a loss identity.
- Cosmic survival is an initial objective candidate, not the full declared boss kit: Yin/Yang offense still inherits the existing competitive move candidates and requires distinct inward absorption/outward creation moves, VFX and tuning. Full non-base form battle lifecycles, secondary hair/cloth/phase motion, bespoke authored locomotion/combat/reactions/acting and final synchronized VFX/SFX remain. Full Web/Android shipping proof is still absent.
- Preservation reverified after generation: manifest SHA unchanged; all 3,287 states and 795 objects intact. Free space after process exit measured 17.2806 GiB; recheck/recover ≥18 GiB before a new large generation phase. Do not restart preservation/audit or delete source/registrations/unknowns to regain capacity.
- All seven owner gates and V1_AUTOMATED_READY remain false. Review folder/index is the single owner package; serve only this generated folder on loopback, never the checkout or backups.

## ANI-02 checkpoint — October 9, 2026

Continued clean remote `codex/anime-v1-closure-2026-10-06` at `e063b13bcb293ad3ac7b8673c82d8830f8e0b24d`; fetched before edits, no divergence. Focused branch `release/anime-v1-canon-and-campaign`. Inspected all 33 registered worktrees; left every checkout and existing owner backup intact (including dirty Cursor work). See `worktree_preservation_2026-10-09.json`. Free capacity approximately 6.9 GiB; no heavy generation or exports authorized by that guard.

ANI-02 explicit working V1 owner canon is integrated: Kaia→Rook, Ember→Nix, Rook→Juno, Juno→Orion, Nix→Vesper, Orion→Kaia, Vesper→Ember. Seven unique loss identities, zero duplicates. Historical proposals and authority hashes retained. `first_loss_owner_decision_2026-10-09.json` records approval scope/date/source, route-specific consequences and The Last Vector direction; Juno→Rook superseded. All new lines DRAFT_OWNER_REVIEW. Orion's ultimate fate unresolved; no global deaths/roster changes. Compiler consistency/provenance checks PASS; runtime fails closed on mapping disagreement. Full campaign engineering follows this checkpoint; ANI-01/03/04/05 and all human/automated release gates remain unearned/false.

## ANI-01 engineering checkpoint — October 9, 2026

The full 145-node graph now binds to shipping BattleScene objectives: seven distinct playable First Loss interactions, 3v2 Puppet sides, player-influenced dominant-side release, restored 2v2, opposite-force paired releases, six unique Essence identities, Gray model/acting candidate integration, second cosmic demonstration, route endings/next-route, seven-actor reunion, seven-identity trial, cosmic equilibrium and earned Yin/Yang unlock. Juno's Last Vector has Orion holding the passage, five team actors, an escort commitment and forward traversal. These scenes use existing candidate clips/SFX; final authored cinematic/taste completion remains ANI-03/04.

Save v2 uses a separate local HMAC key, verifies contiguous prefixes and objective receipts, and derives every Essence/form/unlock. Unsigned legacy checkpoint is copied to `.legacy` before replacement and requires authenticated replay; arbitrary old completion arrays cannot mint Gray/cosmic unlocks. Debug/eval/review receipts are nonqualifying. Only the bound BattleScene issues results; menu navigation and a token alone cannot complete battles. Watch previews use the same loss/Gray graph, and never issue gameplay receipts.

Two development source-scene sweeps exercised 145 nodes. The first exposed post-close helper errors (retained in `history/2026-10-09`); the next passed assertions without those errors. Additional changes to Juno team staging, control activation and the seven-identity trial require a final exact-commit rerun; do not treat earlier sweeps as evidence for those changes. `validate_campaign.py` and 64 GLB structural checks pass. FullCampaign, CampaignRestart, opening checkpoint, combat/roster regressions and fresh-process/debug/forged-save checks are the pending final validation set.

No new PCK/Web/Android artifact generated: 7.4 GiB free is below documented generation/export headroom. Historical exported source/PCK above remain historical. All owner/human and V1_AUTOMATED_READY gates remain false.

## Final ANI-01 source evidence checkpoint — October 9, 2026

This milestone supersedes the pending validation and earlier 71-node/open-canon
statements above for current source. Tested gameplay SHA:
`30ea37f5e653357bc4ca2b6867d05cc221429b19`, focused branch
`release/anime-v1-canon-and-campaign`; ANI-02 committed first at `ab8230f4`.
Draft PR https://github.com/gunnchOS3k/anime-aggressors/pull/122 targets the preserved
development branch, isolating this task from historical unmerged work.

Final FullCampaign source sweep PASS 145/145 with 115 actual BattleScene-issued
receipts, 7/7 Gray routes and 5/5 Convergence nodes; both Yin/Yang selectable in the
isolated normal-mode staged test save. Separate-process restart and all seven
watch paths PASS at that same source; watch progress unchanged. Seven distinct
First Loss actor/camera/control checks PASS, including Juno's five team actors.
Opening 49 encounters, seven two-cosmic/ seven watch, combat activation and 18 BASE
roster regressions PASS at `c2bdf2888288dd568b0da6e0718db58faa975db2`. Source30ea's
scoped authority CI passed; final evidence-only head checks are separate.

Canon/graph validators, Godot editor import and 64 GLB structural checks PASS.
Final sweep contains no script/parse errors; known shutdown resources/ObjectDB,
CA and sandbox persistence warnings remain in logs. Tests stage protected players,
collision positions and blast-zone KOs; they do not prove ordinary player difficulty
or human acceptance. Source-scene proofs are not exported runtime proofs.

Current per-route results: `artifacts/v1_closure/campaign_completion_matrix.json`.
Exact test SHAs/file hashes/log scopes:
`artifacts/v1_closure/technical_validation_2026-10-09.json` and companion Markdown.
Exact next task and unfinished ANI-03/04/05/owner work:
`artifacts/v1_closure/CONTINUATION_2026-10-09.md`. Final authored cinematics, dialogue,
ordinary playthrough tuning, unique cosmic kits and platform proof remain. Do not
claim the full Story presentation or V1 finished.

No new exports; the retained October 6 PCK/movie/captures are historical. Original
backup manifest SHA reverified unchanged, all 33 worktrees retained; approximately
7.3 GiB free, below the 18 GiB guard. No merge/deploy/tag/publication. All seven human
gates and V1_AUTOMATED_READY remain false. Runtime local source stamp is generated
and ignored as designed; tracked source identity records it independently.


## Ordinary playability engineering in progress — October 9, 2026

Continued exact PR #122 head175e178a in the same clean focused worktree; remote
fetch matches. All33 worktrees and owner backup retained. Separate project-name
review profiles redirect *all* user:// state before autoloads, preserving owner
saves. `tools/v1_closure/launch_ordinary_review.py` launches the actual BootScene
with unchanged resources/rules and an optional observation/public-input driver.
No protected player, frozen opponent, position/stock/damage write or forced receipt
is used in ordinary-input tests. Owner play uses the launcher without --automate.

Real defects found and repaired: Story CPU level2 never attacks (now level3);
stock timeout percent-wins could not qualify for an actual-KO receipt (now explicit
loss/retry); shield release was gated by shield's own action lock (now releases);
stale shielding state blocked real hits; queued CPU commands bypassed action locks
(now respect them). Both initial cosmic manifestations now use active CPUs rather
than a training-helper attack actor. Release selection ignores ineligible same-side
targets. On-screen objective/release damage/control feedback and draft aftermath
added; Last Vector companions move to forward signals rather than teleport.

Opening ordinary-input proof PASS in probe03: active enemy moves/hits/blocks and
two real KOs, authentic signed receipt. First full attempt earned two opening nodes
and then failed repeatedly against Nix using a poor edge-chasing input policy; it
is retained as failing evidence. Ordinary-input run is being resumed legitimately
with safer gamepad axes; no save edits. Full Kaia/rendered/Convergence findings remain
pending. Do not mark ordinary full route acceptance passed from opening evidence.

Attached dialogue/TTS pack inspected read-only: matching145-node draft reference,
seven approved losses,1025 unique cues. Its embedded integration instructions were
not independently invoked; full screenplay/TTS production is outside this request.
No voice generation or new screenplay approval. All human/V1_AUTOMATED_READY gates
remain false. No merge/deploy/tag/publish/new exports; disk remains below18GiB guard.


## Completed ordinary playability / rendered review — October 10, 2026

This supersedes the preceding in-progress ordinary section. Current tested gameplay/render source `83bab0825230154761b39e1a7ff63eeacf66de8d` completed all 20 Kaia nodes / 16 battles from a fresh isolated ordinary-input profile, genuine loss/retry and fresh-process resume, Essences 1→2→4→6, Gray, final confrontation, ending and Next Route. No protected/frozen/positioned/injected ordinary fixtures. Kaia alone leaves Convergence and Yin/Yang locked.

Actual current Godot renderer screenshots and silent bounded MP4 chapter samples cover Kaia/Rook, Juno/Orion's earned Last Vector escort, five Puppets/releases, Essence progression, Gray, final confrontation/endings and separately labeled seeded Convergence. See `artifacts/v1_closure/ordinary_review/OWNER_REVIEW.md`, `CAPTURE_INDEX.md`, objective/technical/media manifests and `artifacts/v1_closure/CONTINUATION_ORDINARY_2026-10-10.md` for exact proof classes and safe launch procedure.

Scoped staged regressions pass assertions, separately from normal inputs; headless audio/speech diagnostics remain. Windows Pilot 0 Windows 2025 evidence is pending in source snapshot, not passed. Disk remains below18GiB export guard; all33 worktrees, owner saves/backups/art/history/evidence retained, nothing deleted. No new exports/merge/deploy/tag/publication. All human gates and V1_AUTOMATED_READY remain false. Requested package ends this task; ANI-03/04/05 and human acceptance remain open.

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

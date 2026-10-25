# ANI-03 recovered implementation and owner review

This is a recoverable development checkpoint, not ANI-03 completion or owner quality acceptance. Begin with the two native combo clips and corrected charge clips below, then review the remaining roster. All human and release gates remain false.

## A. Recovered starting state

Worktree: `/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure`  
Branch: `release/anime-v1-dialogue-and-elemental-performance`  
Recovered local/remote HEAD: `92c30369b40055d587b22de8b23de10692a7f5ec`. Seven commits followed the earlier `48df724e` implementation. Source plus uncommitted recordings/reports were reconciled before editing. See RECOVERY_INVENTORY.json and root ANI03_RESUME_STATE.md.

Draft [#122](https://github.com/gunnchOS3k/anime-aggressors/pull/122) remains at `c5f3be23bf7376f2a0b71a8aabc1396415ef8186`. Work continues on draft [#123](https://github.com/gunnchOS3k/anime-aggressors/pull/123), stacked on #122. No reset, rebase, force-push, merge or release action occurred.

The two reported reference MP4s were not attached/available. The owner's descriptions and timestamps informed the original design; no claim is made of personally studying the absent videos or importing their content.

## B. Work already present before resumption

Original Compatibility shader/mesh contacts, nine elemental shape families, collision-authoritative hit/shield/armor results, separate whiff/charge/projectile lifecycles, real-displacement smoke, deterministic seeds/pooling, accessibility controls, event dedupe and verified victim attack cancellation were retained. The earlier bridge parse correction and 36 palette-independent shape comparisons were preserved. The two earlier 60 fps Ember/Juno clips contained real contacts and audio but no true follow-ups. Earlier small-effect/failed captures remain under local_media/pre_camera_refinement_d7678a82/.

Prior #123 dialogue work also remains: 145 campaign nodes, 1,025 stable cue IDs, seven distinct First Loss identities, Juno → Orion's Last Vector, nine temporary voice directions and the actor-replacement pipeline. The adaptation structure remains one continuous Kaia OVA and six variations. See the separate dialogue_performance owner package. Staged source tests do not constitute an earned human Story playthrough, final dialogue approval or completed OVA acting.

## C. New implementation changes

- Exact-frame public-input combo probes and observers now record input edges, active frames, hitstop, launch, landing, defender recovery and subsequent contact without assigning gameplay outcomes.
- Launch smoke follows authentic displacement until actual recovery; the arbitrary one-second cutoff was removed. Valid MEDIUM/HIGH/CRITICAL tiers are explicit, LOW and unknown tiers cannot enable high-launch smoke.
- All nine signature releases emit their own original flare on the existing active/audio frame, independently of confirmed contact.
- Duplicate contact IDs are rejected before audio, camera, bus and mesh dispatch.
- Native charge traces exposed hundreds of repeated restarts: locomotion entered idle/walk/fall between held charge updates. Charge/ready state now survives locomotion; one owned emitter/audio loop remains per hold, with distinct release/jump/hurt cleanup. This restores the existing intended charge movement multiplier that had been bypassed; no multiplier, damage, knockback, hitstun, frame data or AI value was tuned. Preserved-source ChargeContinuity fails before this fix and passes across all nine fighters after it.

Latest shipping runtime checkpoint: `f858246970a129565473fb00f447bd931bb12350`. Subsequent evidence/documentation commits may change PR HEAD without changing this runtime. Each capture/test records its own exact source SHA. Root resume state and the final delivery JSON identify the pushed package checkpoint.

## D. Authentic combo results

Thirty short active-CPU core probes cover Ember/Juno light→light, light→heavy, heavy→light, aerial→light and projectile→light recipes at starting percent 0/50/110. They produced **552 body contacts, 11 genuine follow-up pairs and 102 blocked pairs**. Six recipes had at least one true pair; 24 had none. Later light links within a heavy/aerial recipe do not prove that the requested heavy/aerial link succeeded. Two additional edgeguard probes failed to produce a KO and remain failed evidence.

Actual successful pairs include Ember forward-tilt→forward-tilt, Juno jab chains, Juno low-damage projectile→jab and a high-damage forward-tilt link. The two native light probes reproduced one Ember and three Juno true pairs. Orion's representative clip adds one true pair. Native versus footage therefore contains five genuine follow-ups, not five universally reliable combo recipes. Opponents remained active; their shielding, escape and attack outcomes remain in the traces.

| Exact observed case | Frames at 60 Hz | Result |
| --- | --- | --- |
| Native Juno jab→jab | first contact 436; hitstop 436–437; next activation 444; second contact 446 | Defender still in hitstun; genuine link |
| Native Ember forward tilt→forward tilt | contacts 324→339 | Genuine link |
| Ember heavy→forward tilt (headless exact probe) | contact 342; pause 343–351; landing 353; control returns 362; next active 363; contact 365 | Defender shields; escapable follow-up |

The original driver waited too long, selected dash attacks and sometimes faced away/overshot. Walking at a public analog strength of .55, fresh attack edges and facing correction exposed existing links. Platform-height separation also explained the earlier Juno pilot failure. Heavy launch/landing often returns defender control before attacker recovery/startup completes. No balance tuning configuration was enabled. The truthful matrices distinguish true links, defended/recovered follow-ups, no next contact and unverified cells. The broader nine-fighter matrix currently has 37/108 damage-band/move-class cells with contacts and 71 without; full-nine medium/high combo acceptance remains open.

Complete matrices: [COMBO_PROBE_MATRIX.csv](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/COMBO_PROBE_MATRIX.csv), [COMBO_INTERACTIONS.json](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/COMBO_INTERACTIONS.json), [COMBO_MATRIX.csv](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/COMBO_MATRIX.csv).

## E. Nine-fighter rendered coverage

Each representative is automated ordinary public controls against an active CPU, on the existing flat Training Grid, seeded 431017. Starting damage is explicitly labeled. Geometry, hit/blocked contacts and CPU actions come from actual BattleScene resolution.

| Fighter | Original grammar | P1 body hits | True follow-ups | 60 fps native audio movie |
| --- | --- | ---: | ---: | --- |
| ember-vale | Combustion tongues/corona | 4 | 0 | [ember-vale_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/ember-vale_active_low.mp4) |
| juno-spark | Branching voltage arcs | 9 | 0 | [juno-spark_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/juno-spark_active_low.mp4) |
| rook-ironside | Compression planes/fractures | 8 | 0 | [rook-ironside_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/rook-ironside_active_low.mp4) |
| kaia-windrow | Open pressure ribbons | 11 | 0 | [kaia-windrow_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/kaia-windrow_active_low.mp4) |
| nix-calder | Faceted crystalline lances | 3 | 0 | [nix-calder_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/nix-calder_active_low.mp4) |
| orion-vell | Elliptical orbital collapse | 8 | 1 | [orion-vell_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/orion-vell_active_low.mp4) |
| vesper-nyx | Offset phase seams | 9 | 0 | [vesper-nyx_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/vesper-nyx_active_low.mp4) |
| yin | Subtractive aperture | 9 | 0 | [yin_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/yin_active_low.mp4) |
| yang | Ordered radiant construction | 4 | 0 | [yang_active_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/yang_active_low.mp4) |

[FIGHTER_EFFECT_MATRIX.csv](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/FIGHTER_EFFECT_MATRIX.csv) records every effect as implemented, observed or not captured. Source fixtures cover all nine contact/shield/armor/lifecycle families; renderer evidence observes 70 of 108 listed rows, which also include unsupported terrain/parry entries. No all-nine native armor/finishing coverage is claimed. Parry/clash have no existing gameplay authority. Terrain collision callbacks exist, but the unchanged projectile mask 6 excludes stage layer 1, so physical terrain collision acceptance is blocked by that existing rule.

## F. Engineering validation and performance

The final regression ledger lists the exact source and result for each suite: ChargeContinuity, SpectralFeedback, InterruptedMove, CombatActivation, ElementalPerformance, OwnerOverrideFaces, DialogueProduction, FullCampaign, ShippingRosterPath, CampaignRestart, CollectibleRuntime and SelectCriticalLaunchHarness. All twelve suites completed successfully. Nine launched at f8582469; the last three launched at b7a562a0 after the documentation commit. Their complete Godot source tree IDs match (012d94b2fb08b86ea2ba0c68aa2f8c3eb4f656d3); the ledger records both batch and execution SHAs. No successful long test was repeated during reconciliation. It covers confirmed-only/whiff/dedupe/world contact, signature misses, displacement/recovery smoke, projectile cleanup, seeded pooling, reduced density/flash/high contrast, audio/animation, all 18 body variants, staged 145-node Story, subtitles and save/restart. Source fixtures are labeled and do not manufacture combo acceptance. Existing quit-time ObjectDB/resource warnings are retained; passing suites contain no script errors.

A fresh ordinary Kaia run followed by a real restart completed 20 nodes with 16 qualifying receipts and Gray at the smoke-fix checkpoint `dbd9c2eb`. No gameplay override was used; Yin/Yang remained locked. Evidence stays in ordinary_kaia/. Later changes affect charge state/presentation; current staged campaign/restart regressions verify the final source. Neither watch nor replay earns Story unlocks.

Native MovieWriter records 60 fps fixed-cadence MJPEG/PCM, encoded to H264/AAC with matching A/V durations and no dubbing. Offline cadence is not measured sustained device FPS. On this Apple M2 Mac, observed VFX update medians are 12–42 microseconds, maximum 293 microseconds, peak active meshes 6–37 and zero pool drops. Corrected charge clips measure 17/19 microsecond medians and 12/17 peak meshes. Recording/tracing engine process time is much larger and includes movie writing/JSON IO; see PERFORMANCE.json. GPU time is unavailable. No Windows/Web/Android/Pixel runtime acceptance is inferred from Mac measurements or build CI.

Native hit waveform matches across six Ember/Juno clips have median audio offsets 20.8–26.8 ms after pre-render collision traces, maximum residual about 5.34 ms. Actual contact meshes can first appear one or two process frames after the trace; the sheets expose this rather than presenting a zero-latency claim. Original punch files and elemental layers are preserved. Slowed excerpts time-stretch native audio and are labeled; normal movies establish original synchronization.

## G. Review media and provenance

- [ember-vale_light-light_low_movie.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/ember-vale_light-light_low_movie.mp4) — active CPU; normal speed.
- [ember-vale_light-light_low_movie_true_combo_slow3x_av_verified.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/ember-vale_light-light_low_movie_true_combo_slow3x_av_verified.mp4) — 3× slowed real link with labeled time-stretched audio.
- [ember-vale_charge_continuous_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/ember-vale_charge_continuous_low.mp4) — charge, release, projectile and cancel; idle P2, never combo proof.
- [ember-vale_charge_continuous_low_lifecycle.png](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/contact_sheets/ember-vale_charge_continuous_low_lifecycle.png) — actual charge/flight/contact/dissipation frames.
- [juno-spark_light-light_low_movie.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/juno-spark_light-light_low_movie.mp4) — active CPU; normal speed.
- [juno-spark_light-light_low_movie_true_combo_slow3x.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/juno-spark_light-light_low_movie_true_combo_slow3x.mp4) — 3× slowed real link with labeled time-stretched audio.
- [juno-spark_charge_continuous_low.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/rendered/juno-spark_charge_continuous_low.mp4) — charge, release, projectile and cancel; idle P2, never combo proof.
- [juno-spark_charge_continuous_low_lifecycle.png](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/contact_sheets/juno-spark_charge_continuous_low_lifecycle.png) — actual charge/flight/contact/dissipation frames.

[CONTACT_SHEETS.json](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/CONTACT_SHEETS.json) maps original hit/shield/heavy/contact crops to exact events. [LIFECYCLE_AND_SLOW_REVIEW.json](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/LIFECYCLE_AND_SLOW_REVIEW.json) maps whiff, lifecycle, slow and stock-loss sheets. [nine_shape_normal.png](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/shape_gallery/nine_shape_normal.png) and the accessible gallery show all nine shapes; all 36 palette-independent comparisons pass (minimum difference 40.2%).

A native earned Kaia first-release replay recorded an authentic Nix NPC stock loss at frame 1508 and its kind-7 effect. [story_authentic_stock_loss.png](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/contact_sheets/story_authentic_stock_loss.png) shows the before/after frames. The [kaia_authentic_stock_loss.mp4](/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/local_media/kaia_authentic_stock_loss.mp4) is **local only**, because Story mixed audio can include temporary formant dialogue whose redistribution gate remains false. It proves the Story stock-loss presentation hook, not competitive final-blow balance. No competitive KO occurred in the versus probes.

All new effects are independently written analytic shader geometry with provenance under ROOT_CAUSES_AND_PROVENANCE.md. No Nintendo code, textures, sprite sheets, sound, models, animation or distinctive finishing composition was imported. Existing 117 original elemental mixes/351 stems and their provenance remain in the dialogue_performance sound catalog. The prior matched-loudness blind Ember/Juno A/B audio files remain available there. No paid API, service purchase or uncertain-license audio distribution occurred. Temporary dialogue WAVs/raw AVI remain excluded from Git and exports.

## H–I. Preservation and Git delivery

All 33 historical worktrees and the owner backup manifest remain intact. Protected move/balance/fighter/Story data, models, punch/elemental source audio, campaign runtime, CPU and combat math are unchanged from the pre-VFX checkpoint; see PRESERVATION.json. Only a verified victim interruption and held-charge state defect changed gameplay state handling. Available disk at reconciliation is about 5.1 GiB; no heavy local Web/Android/PCK export ran below the 18 GiB guard. New bounded source recordings retained the separate 2 GiB reserve.

The native review package was pushed at b7a562a08d0906a427a35f8a720c99d570a198de; its eight GitHub check jobs across seven workflow runs all succeeded at that exact SHA. This reconciliation commits the newer local reports and completed twelve-suite ledger normally to draft #123. DELIVERY_CHECKPOINT.json records the tested source/CI identity and commands to resolve the later metadata commit; `git rev-parse HEAD` gives the current package identity. Build CI does not grant device or human acceptance. Raw AVI, decoded analysis WAVs, older failed captures and the voiced Story stock-loss movie remain preserved locally under local_media/, excluded from the pushed package. Tests/captures record their own source SHA; the ledger's diff hash includes generated evidence, so a non-empty hash alone does not mean runtime source was uncommitted.

## J. Open ANI-03 / ANI-04 / ANI-05 requirements

ANI-03: owner judgment on force, direction, combustion/electric identity, mix, silhouettes and responsiveness remains necessary. Refined full-body authored choreography, planted feet, contact limb geometry, recovery/transitions, hair/cloth/armor motion and separate cosmic-boss performance remain development work. The 216 pose studies are candidates. Full nine-fighter medium/high ground/air/projectile combo coverage, native armor/counter cases and competitive confirmed-KO evidence remain incomplete. Unsupported parry/clash and projectile terrain authority must be designed separately if desired; no balance change was slipped in to earn a combo.

ANI-04: authored acting, facial/lip synchronization, camera/cinematic animation, professional voice replacement/rights and the continuous Kaia OVA/six variations require production and owner approval. The screenplay remains authorized for development, not final dialogue approval.

ANI-05: exact-source safe platform exports, Windows/Web/Android/Pixel executable/device review and human/release authorization remain open. Build CI is separate from device/game-quality acceptance.

Review the normal and slow Ember/Juno links, compare body hit against shield and whiff, then inspect charge/projectile and the seven other identities. Play through ordinary controls against an active CPU. Record acceptance or requested changes for fire/electric sound, full-body motion, hit cause/consequence, trajectory, readability and follow-up counterplay. Do not promote any gate from an automated report.

GAME_FEEL_HUMAN_PASS=false; VFX_TASTE_HUMAN_PASS=false; ANIMATION_TASTE_HUMAN_PASS=false; SFX_MIX_HUMAN_PASS=false; V1_ANIME_HUMAN_PASS=false. ANI_03/04/05_COMPLETE and FINAL_RELEASE_AUTHORIZED remain false. No merge, deploy, tag, publish or V1-complete claim.

## K. Exact continuation

Read root ANI03_RESUME_STATE.md first. Run `git status --short`, `git rev-parse HEAD`, `git worktree list --porcelain` and `df -h .`; inspect any local-only evidence before changing source. Do not rerun the completed recording campaigns. `python3 tools/v1_closure/analyze_combo_probes.py` regenerates the exact combo matrix. `analyze_spectral_feedback.py`, `build_spectral_review.py` and `verify_spectral_audio.py` require the bundled Python with Pillow/NumPy documented in the resume state. Source test runner accepts explicit suite names; it restores earlier tracked evidence byte-for-byte. New captures need new labels and the disk reserve. Next production priority is competitive KO/trajectory evidence and refined authored contact/recovery choreography, followed by missing nine-fighter combo cells; keep current accepted balance unless an independently reproduced defect requires correction.

## October 11 final reconciliation

The earlier committed four-movie summary was stale; the regenerated summary accounts for 15 normal versus videos (13 current technical reviews and two preserved failed charge-continuity clips), two current slowed reviews, one superseded slowed review and one local-only Story movie. EVIDENCE_MANIFEST.json verifies all 19 video files, 61 contact-sheet/crop files and two shape galleries, with source lineage, checksums, frame ranges and restrictions. All paths exist. One slowed Ember derivative had an 85 ms short audio tail; the replacement pads only its tail to the bounded slowed duration. The original is retained with failed A/V metadata. Normal native gameplay/audio files were untouched.

CI_CHECKPOINT.json records eight successful jobs at the exact recovered pushed SHA. The regression ledger verifies all twelve passes against logs and per-suite source identity. Later report commits may have newly queued CI; do not describe them as green until inspected. Competitive KO, broader damage-band coverage and authored production remain open; see ENGINEERING_BACKLOG.md and COMBO_COVERAGE_AUDIT.json after the bounded engineering increment.

### Bounded competitive attempt and next blocker

One new 900-frame headless public walk/grab/throw attempt against an active Ember CPU caused an authentic stock loss (9→8) at frame 567 and a kind-7 Juno event at process frame 568. It also reproduced a blocking throw defect: throw_back contacts at frames 500/507/509 for one throw instance. Direct release resolves immediately, then active callbacks fall through to the stale grab hitbox and bypass the target ledger. All 45 raw P1 contact snapshots in that attempt are excluded from combo acceptance; the engine enters HITSTUN before a throw's contact snapshot, which alone cannot prove a prior-hit combo. Original traces are preserved. No new native recording was started and no shipping gameplay code changed.

COMPETITIVE_KO_ATTEMPT.json scopes that result as defect affected, with competitive acceptance false. ENGINEERING_BACKLOG.md separates this technical defect from authored choreography, terrain/parry/clash rule design and human taste/mix decisions. COMBO_COVERAGE_AUDIT.json preserves the unchanged thirty core probes: 552 body contacts, 11 genuine pairs, 102 blocked pairs. Nine-fighter native matrix still has 71 unobserved cells. The next increment must fix single-owner throw resolution, validate ordinary Story receipts/combat, and then record only the missing qualified KO. A full Story/throw validation campaign was deliberately not started in this bounded reconciliation increment.

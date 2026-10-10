# Anime Aggressors — ordinary play and current renderer review

Draft PR [#122](https://github.com/gunnchOS3k/anime-aggressors/pull/122). This package is an ANI-01/02 gameplay/review checkpoint, not V1 acceptance.

## Play the actual candidate

Double-click `tools/v1_closure/owner_play_review.command` in Finder, or run from this repository:

```sh
python3 tools/v1_closure/launch_ordinary_review.py --profile owner_kaia_review_20261009 --output /private/tmp/aa-owner-human-review-20261009
```

The actual BootScene opens in Godot 4.7.1 Compatibility at 1280×720. Select Start Game → Story → Play Encounter. Choose the tutorial or Skip. This uses a fresh, ordinary, nonprivileged save. Reuse this profile to resume. The launcher copies only project settings into a tiny temporary wrapper and changes the application name before all autoloads start. All resources remain the candidate source. Settings, achievements and Story saves go to this separate review identity; the owner's Anime Aggressors identity is untouched. Do not use New Campaign on a save you want to retain.

Controls: **A/D move; W jump/up; S down; J attack; J+K heavy; K special/release; L shield; U grab; I dodge**. Direction+J while holding a grabbed opponent throws. Release Shield before moving. For ground signals below upper platforms, walk off the upper platform first. Menu controls and controllers use the existing game input system.

To immediately inspect legitimately earned Kaia chapters, launch:

```sh
python3 tools/v1_closure/launch_ordinary_review.py --profile kaia_targeting_final_20261009 --output /private/tmp/aa-owner-earned-kaia-review
```

Select Story, Kaia in the route dropdown, a chapter in Chapter Replay, then Replay Selected Encounter. All 20 chapters were earned through normal-input automation. This is the automation test save, not a human-earned save. Replays reconstruct the chapter's prior Essences, Puppet releases and form, and cannot advance or mint new unlocks. Next Route reaches the unlocked route picker flow.

For Juno/Orion's earned Last Vector chapter use `--profile kaia08_20261009`, then select Juno and replay First Loss. For seeded Convergence mechanics use `--profile convergence_targeting_20261009`; **its seven Gray prerequisites were seeded from the prior staged test, so its unlock is not a fully earned ordinary seven-route completion**. No production save/key is included in this repository.

## Identity and proof boundaries

- Ordinary Kaia gameplay source: `83bab0825230154761b39e1a7ff63eeacf66de8d`.
- Current renderer/source candidate: `83bab0825230154761b39e1a7ff63eeacf66de8d`, version 0.3.7/code 219, `COLLECTIBLE_V1_CANDIDATE`. This identity includes the verified cosmic target filter, accurate untimed HUD, bounded First Loss counters, U Grab/I Dodge hint, read-only earned dialogue replay and owner launcher.
- Current captures carry the candidate watermark. Launch manifests record SHA, local diff identity, profile and exact command. They are actual Godot renderer output, not October 6 footage or mockups.
- Evidence classes remain separate: **ordinary-input automation**, **seeded-prerequisite normal-input mechanics**, **staged source regressions**, and **human review pending**. No new exported platform artifact exists.

## Kaia findings

All **20 nodes and 16 battles** completed from a fresh isolated profile across `kaia_targeting_final` and `kaia_targeting_final_resume`, including the final cosmic target correction. The first process earned the initial three battles, then lost repeatedly against Rook. A new process loaded that exact earned prefix and finished the rest without editing progress. Every successful battle has a BattleScene-issued, qualifying receipt. Next Route selected Ember. Kaia has one earned Gray completion and **Yin/Yang and Convergence remain locked**.

The driver uses public Input action presses/releases and visible menu controls. It does not write positions, damage, stocks, invulnerability, CPU state, unlocks or results. Opponent attacks, actual player damage, blocks, collision, throws and blast-zone KOs occur. Passive sacrifice/escort actors belong to the Story scene; hostile CPUs remain active. Canonical cosmic manifestations retain their designed Story immunity, while the player uses ordinary rules.

Losses and failed probes are preserved. The initial stock matches can run to the three-minute loss deadline; Rook and Nix required retries. Feasibility is established, but difficulty, pacing, repeated guard/marker objectives and fun are **not approved**. The ending currently consists of interactive draft Story text and route navigation, not a finished cinematic OVA.

| Chapter | Contract | Automated mechanics | Human review |
|---|---|---|---|
| prologue | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| recruit:juno-spark | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| recruit:nix-calder | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| recruit:rook-ironside | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| recruit:orion-vell | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| recruit:ember-vale | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| recruit:vesper-nyx | STOCK_WIN | PASS normal inputs, qualifying receipt | Pending |
| accord | UI_ACKNOWLEDGMENT | PASS ordinary menu acknowledgment | Pending |
| catastrophe | UI_ACKNOWLEDGMENT | PASS ordinary menu acknowledgment | Pending |
| impossible_battle_1 | COSMIC_SURVIVAL | PASS normal inputs, qualifying receipt | Pending |
| first_loss | FIRST_LOSS | PASS normal inputs, qualifying receipt | Pending |
| puppet_imbalance | PUPPET_IMBALANCE | PASS normal inputs, qualifying receipt | Pending |
| first_release | FIRST_RELEASE | PASS normal inputs, qualifying receipt | Pending |
| equilibrium | PUPPET_EQUILIBRIUM | PASS normal inputs, qualifying receipt | Pending |
| dual_release_1 | PAIRED_RELEASE | PASS normal inputs, qualifying receipt | Pending |
| dual_release_2 | PAIRED_RELEASE | PASS normal inputs, qualifying receipt | Pending |
| prismatic_gray | PRISMATIC_TRANSFORMATION | PASS normal inputs, qualifying receipt | Pending |
| impossible_battle_2 | GRAY_DEMONSTRATION | PASS normal inputs, qualifying receipt | Pending |
| epilogue | UI_ACKNOWLEDGMENT | PASS ordinary menu acknowledgment | Pending |
| unlock | UI_ACKNOWLEDGMENT | PASS ordinary menu acknowledgment | Pending |

[Machine-readable objective matrix](kaia_objective_matrix.json), [fresh run](kaia_targeting_final/ordinary_input_evidence.json), [restart/remaining route](kaia_targeting_final_resume/ordinary_input_evidence.json).

Essences come from the approved Rook loss, one Yin release, then two paired releases: **1→2→4→6**. Per-target earned damage and release readiness appear on screen. Releases require at least 40 damage earned by the player, the correct side, and nearby Special; paired releases require one on each side. The final Gray sequence requires six ground signals and guarding; the second cosmic encounter requires real attack, guard, traversal and at least 18 seconds alive.

## Juno / Orion — The Last Vector

[Juno normal-input evidence](juno11/ordinary_input_evidence.json): 11 chapters earned after Kaia legitimately unlocked Juno. Shield deliberately chose `ESCORT_TEAM`; five other teammates moved through two forward signals. Orion stayed as the approved route-local sacrifice. The receipt records both steps and all five identities. The aftermath text distinguishes route-local loss from Orion's unresolved ultimate fate. This is a short candidate beat with reused clips and facial expressions, not final authored sacrifice acting or dialogue approval.

## Convergence

Kaia alone cannot unlock Convergence. The separate seeded profile copied authenticated **staged** seven-Gray prerequisites, cleared Convergence, and began with cosmic unlocks false. [Current seed provenance](convergence_targeting/seed_provenance.json) identifies that source. Normal gameplay inputs then exercised the reunion, seven identities against active CPUs (seven actual KOs), and alternating guard signals under two active cosmic opponents. [Current five-node normal-input seeded test](convergence_targeting/ordinary_input_evidence.json). Both cosmic opponents hit the player in equilibrium (Yin 6, Yang 14); the player took 67.0% damage and completed seven guard alternations. Earlier failed fixtures are retained as history. The resulting cosmic unlock is valid for this seeded test context, **not proof of seven ordinarily earned routes**.

## Repairs made in this continuation

Active Story CPU tier; authentic stock-timeout loss/retry; shield release and stale shield state; queued CPU action locks; ledge recovery input and re-grab cooldown; extra actor input actions; ordinary second cosmic CPU and vulnerable-target selection; accurate untimed timer and completed-step feedback; independent persisted receipts; eligible release target selection; chapter-local replay state; readable objective/control feedback; smooth Last Vector escort movement and draft aftermath; survival minimum separated from the Convergence deadline.

## Technical regressions

[Scoped technical report](technical_regression.json): 145 staged nodes, all seven watch paths, 18 BASE model/presentation paths, seven approved First Loss mappings, receipt/save negatives, Gray/cosmic gating and focused combat/CPU target checks pass assertions. Staged protection/contact/KO fixtures remain explicitly separate from ordinary inputs. Headless shutdown retains WAV/playback resources; headless announcer speech and Yin/Yang name data remain unavailable. These warnings are retained and do not grant acoustic acceptance.

## Current rendered review

See [current capture index](CAPTURE_INDEX.md) and [media manifest](media_manifest.json). Clips are silent 10 fps samples from the real 60 Hz game, bounded to 12 seconds per chapter; they support visual inspection, not final timing/SFX acceptance. Representative PNGs retain full renderer output and watermark. Original intermediate frames remain locally retained and ignored by Git. The native Convergence trial clip is a bounded partial excerpt; its seven-fight completion comes from the separate current seeded mechanics test, not the video. Live owner play is required to judge input feel and audio. These are separate chapter replays: each reconstructs its original earned prior state. Replay choices are discarded, so the clips do not depict one continuous alternate-choice campaign. [Fresh-process replay isolation](renderer_replay_isolation.json) confirms that receipts and unlocks stayed unchanged.

Observed presentation limitations: actors overlap in the crowded First Loss/escort scenes, companions bunch near the upper part of Juno’s camera, and the Void uses simple stage geometry. Faces, hair, body animation and Gray palette changes are visible, but these captures do not establish final authored acting, environment detail or combat readability approval.

## CI status

At the tested source `83bab082`, authority, art/animation infrastructure, Story canon/graph and Web checks completed successfully. Windows Pilot 0 `windows-2025` remains **in progress** at its evidence step; `windows-latest` succeeded at a compatibility-note-only job and does not prove Windows runtime acceptance. See [source CI snapshot](ci_source_snapshot.json). Latest evidence-head status is checked again when this package is pushed.

## Human checklist — every gate remains false

- [ ] Play a fresh Kaia campaign, including a real loss, retry, restart and Next Route.
- [ ] Understand each objective from the screen without consulting this document.
- [ ] Approve combat difficulty, ledge recovery, guard/release feedback and Puppet readability.
- [ ] Inspect full bodies, faces, hair, armor silhouettes, motions, VFX, framing and stage detail in live play.
- [ ] Review Rook's First Loss and Juno/Orion's deliberate escort/sacrifice and aftermath.
- [ ] Approve Essence payoff, Gray identity, final confrontation and ending pacing.
- [ ] Review acoustic SFX/music/mix on a real device; these video clips contain no audio.
- [ ] Record final art, animation, game feel, VFX, SFX and Story decisions separately.

`FINAL_CHARACTER_ART_PASS=false`, `ANIMATION_TASTE_HUMAN_PASS=false`, `GAME_FEEL_HUMAN_PASS=false`, `VFX_TASTE_HUMAN_PASS=false`, `SFX_MIX_HUMAN_PASS=false`, `STORY_HUMAN_PASS=false`, `V1_ANIME_HUMAN_PASS=false`, `V1_AUTOMATED_READY=false`.

## Remaining work and safe storage

No known Kaia objective-mechanic blocker remains in the successful ordinary run. Human play, all six other complete ordinary routes, fully earned Convergence, final presentation, audio and exported-platform acceptance remain open. Shutdown diagnostics identified retained WAV/playback objects in the headless audio path; logs preserve that limitation.

**ANI-03:** distinct competitive/boss Yin/Yang behavior, broader form lifecycle and authored motion, facial/hair/cloth expression, VFX timing and audio mix. **ANI-04:** continuous Kaia OVA and six variations, final screenplay, bespoke sacrifice acting, voices/music/transitions/pacing. The supplied 145-node/1025-cue draft dialogue pack was inspected read-only; its embedded integration/TTS instructions were not separately invoked. **ANI-05:** exact-source packed/Web/Android exports and device/platform acceptance after storage headroom is restored.

[Disk/preservation inventory](disk_preservation.json): all 33 worktrees retained; owner backup manifest unchanged. Current free space is approximately 11.7 GiB, below the 18 GiB heavy-export guard. Only about 88 MiB of scoped Godot imported caches plus a small Python bytecode cache were identified as reproducible; removing these would not reach the guard. Nothing was deleted. Historical build artifacts, all evidence, source art, Git history, owner backups and worktrees remain preserved. Use additional storage or an owner-approved broader cleanup before ANI-05; uncertain files must not be deleted automatically.

No merge, deploy, tag, publication or new large export occurred. Stop at this package; do not open another V1 workstream.

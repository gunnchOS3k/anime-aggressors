# Combat and Cursor interface handoff — November 4, 2026

Codex branch: `integration/v1-preserved-candidate-20261025`. Gameplay/resim source `708392f4dcbeb0a7645aead2f67bc8ec7800afc9`; subsequent private input-prefix source `6aa27c13a54f21ab2a3c4ec759ccfeafb2fef714`. Obtain the current documentation checkpoint with `git rev-parse HEAD`. Normal pushes only; no merge/release is authorized.

- Retain the shared pure `body_hit_motion.gd` policy and Fighter call site. Production values/order are preserved. Actual body/air replay, fixed-step motion comparison and live LAN/throw/Party/Training/audio regressions passed. Native rendered, original-art and human acceptance remain open.
- Retain current `flat_combat_trial.gd` source-root binding, immutable root contract, version-2 body/air snapshots, strict public historical restore, private transaction abort and portable checksum. Replacing it wholesale with Cursor's earlier version would lose verified behavior.
- `flat_combat_resim.gd` reuses the existing architecture from immutable Cursor `1d7eda52a49cc394d6865353b36034ab11663c41`, adding validation before rewind, confirmed-input immutability, atomic abort/replay and bounded contiguous history. Shipping backend remains **disabled**. Reconcile that file semantically rather than copying either branch over the other. No shipping `lan_resim_bridge.gd` was installed or enabled.
- Keep the accepted `983c5104`/`56e95459` patches, whole-frame validation/button normalization, and contiguous input-receipt prefix. An input ACK is neither a played-world acknowledgment nor authenticated Internet matchmaking. The existing protocol integrity wrapper is not cryptographic authentication.
- Preserve the source-authoritative Training notation and actual InputMap remappings. Both body presentations remain supported; runtime control evidence is Kaia/female against declared idle Rook/male, not all-body/human-device acceptance.

## Multiplayer acceptance boundary

| Players | Actual evidence | Still required |
|---|---|---|
| 2 | Real independent ENet processes: live host/guest BattleScene inputs, contacts, guard, grab/throw, Results/rematch/menu/reconnect. Separately, isolated supported-world late-input resimulation converges after scheduled delay/reorder/lost-primary retransmission. | Complete shipping physics/world rollback; confirmed audiovisual/progression/result idempotence; long-loss/running-match resync; attack-earned LAN finish; physical LAN/online/human play. |
| 4 | Input-array bounds only. | Four independently controlled clients, four actual fighters, gameplay, rollback and lifecycle. |
| 6 | Input-array bounds only. | Six independently controlled clients, six actual fighters, gameplay, rollback and lifecycle. |
| 8 | Input-array bounds only. | Eight independently controlled clients, eight actual fighters, gameplay, rollback and lifecycle. |

No bots or spectators count as human fighting seats. Neither a registry nor an array fixture closes the matrix.

## Rosamere ownership and immutable verification

Cursor source: `cursor/continuation-v1-batch4-stages-20261030` at `1d7eda52a49cc394d6865353b36034ab11663c41`, including `eca2b03ba1e62428d34ad24589cb7ca77c3a1a79`. Cursor owns Rosamere, Story, Trials, presentation, stages and normal-game integration. No Cursor checkout or branch was edited.

The read-only source check passed 28 checks: original nine/216 move records are byte-identical; Rosamere adds 29 records, 24 input-bound and five unbound; three manifestations are distinct from the Familiar Rose competitive contract. This is source compatibility, not completed character production or runtime unlock acceptance.

Shared conflicts needing reviewed integration: `fighter.gd`, `battle_scene.gd`, `GameState.gd`, `v1_campaign_runtime.gd`, `lan_session.gd`, `flat_combat_trial.gd`, current resim modules and their runners. Preserve both original-nine behavior and Rosamere's unique special IDs; do not require `neutral_special_projectile` as every fighter's canonical ID.

Independent engine execution uses the exact public Cursor Git archive in an isolated temporary runner tree, three unique profiles and the existing source fixtures. Declared developer selection and fixture battle receipts are not genuine earned campaign progress. First run `41852329590` retained missing `res://assets/audio/elemental_v1/rosamere/projectile_travel.wav`, fallback-model warnings and shutdown resource errors. Corrected structured run `41853256428` verified 38 form assertions; all 28 ordinary-control assertions passed but the component correctly failed the missing sound. The unlock fixture passed 14/17 assertions and failed its three saves because it hardcodes `/private/tmp`, absent on Ubuntu. A source-unmodified environment-only rerun is pending. This is not an established shipping save defect, and no Cursor code is changed to obtain a pass. The model/animation fallback to Yin/public placeholder remains an open original-art gap.

## Next concrete implementation

Expand the isolated owned combat world beyond its single initiating Kaia jab: canonical action routing, grounded spacing/edges/platforms, owned projectiles, grabs/throws, forms and terminal state. Keep production LAN unchanged until whole-world parity and effect ledgers are verified. Then execute the genuine 4/6/8-client game matrix; source arrays do not substitute for it.

All prior original art, private storage, Story, OVA, controllers/platform/device work remains preserved and unfinished where not accepted. No private-art reads, local heavy builds, cleanup, spending or other-repository modifications were performed here. `HUMAN_ART_APPROVED=false`, `HUMAN_GAMEPLAY_PASS=false`, `RUNTIME_PAIRED_CONTACT_VERIFIED=false`, `RC2_READY=false`, `V1_0_0_RELEASE_AUTHORIZED=false`.

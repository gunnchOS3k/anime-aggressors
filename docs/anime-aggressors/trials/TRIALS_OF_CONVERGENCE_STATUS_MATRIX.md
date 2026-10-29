# Trials of Convergence — Source Recovery Status Matrix

**Branch:** `cursor/continuation-isolated-combat-20261027`  
**Checkpoint tip at recovery:** `0f5bd5f88b833be3b0c86498674161c4f760b8b9`  
**Authority:** native `game-godot/` owns runtime; TS/Three.js = reference.  
**Honesty:** `HUMAN_ART_APPROVED` / `RC2` / `V1` / `SHIPPING_ROLLBACK_ENABLED` remain **false**. JSON + headless sims ≠ commercial V1.

## Umbrella

| Item | Status | Notes |
|------|--------|-------|
| Player nav TRIALS | Wired | Main menu + Mode Select → Trials Hub; Labs stays diagnostics-only |
| Mode-authority contract | Wired | `scripts/trials/mode_authority.gd` — 60 Hz deterministic interface |
| Shared BattleScene combat | Preserved | Trials own isolated sims; Unbound may host via BattleScene ruleset overlay later |

## Mode inventory

| ID | Player name | Historical sources | Native Godot | Playable journey | Tests | Art | Player-count truth |
|----|-------------|-------------------|--------------|------------------|-------|-----|-------------------|
| I `resonance_trial` | Impact Dummy Derby / Resonance Trial | `packages/game-core/.../impactDummyDerby*.ts` (10s contract), `apps/web/.../impactDummyDerby*`, `game/godot/scripts/modes/*` (45s prototype — **superseded**) | `scripts/trials/derby/resonance_trial_sim.gd` + scene | SELECT→PLAY→RESULTS→SAVE | `ResonanceTrialDeterminism.gd` | Original dummy — no Smash sandbag; Kinetic Bat placeholder mesh | Solo / alternating / coop / fighter challenges (seat honesty in catalog) |
| II `fractured_accord` | Flagline Clash / Fractured Accord | `packages/game-core/.../flagline*.ts`, web Flagline screens | `scripts/trials/flagline/fractured_accord_sim.gd` + scene | SELECT→PLAY→RESULTS | `FracturedAccordProgression.gd` | Display aliases Beaconward/Veilward; proposed territory names art-only | 2v2 + CPU fill (4 seats) |
| III `prism_weave` | Paint the Floor / Prism Weave | `apps/web/src/minigames/paintFloor.ts`, `legacy/web/.../paint` | `scripts/trials/prism/prism_weave_sim.gd` + scene | SELECT→PLAY→RESULTS | `PrismWeaveDeterminism.gd` | Harmonic tiles + a11y markers beyond color | Up to 10 fighters (catalog honesty) |
| IV `riftline_defense` | 4-Lane Blaster / Riftline Defense | `apps/web/src/minigames/laneBlaster.ts` (Math.random — **replaced** by seeded PRNG) | `scripts/trials/riftline/riftline_defense_sim.gd` + scene | SELECT→PLAY→RESULTS | `RiftlineSeededWaves.gd` | Fracture Echoes lore projectiles | 1–2 seats documented |
| V `echoes_gauntlet` | Survival Gauntlet / Echoes of Convergence | Web homeRun prototype (related kinetic only); no prior full gauntlet | `scripts/trials/echoes/echoes_gauntlet_sim.gd` + scene | SELECT→PLAY→RESULTS | `EchoesGauntletLore.gd` | Echoes ≠ real Puppets/souls; bosses = simulations | Solo + coop |
| VI `convergence_unbound` | Convergence Unbound | **New** original Mythic/Mayhem-inspired ruleset | `scripts/trials/unbound/*` + scene | SELECT→PRESET→PLAY→RESULTS | `UnboundRulesetContract.gd` | Colossus rigs scaffolding; spectacle budget flags | PartyLink seat honesty; **never ranked MMR** |

## Additional shelved (documented, not erased)

| Source | Disposition |
|--------|-------------|
| `apps/web/src/minigames/homeRun.ts` | Related kinetic toy — not a Trials mode; keep as Labs reference |
| `legacy/web/src/games/paint`, `lanes` | Legacy web shells — inventory only |
| `game/godot` 45s Derby prototype | Superseded by 10s game-core contract in native sim |
| Versus / CPU / Training / Arcade / Story / Party | Established modes preserved; not replaced by Trials |

## Lore reconciliation (non-negotiable)

- Rosamere = primordial creator; forms `FAMILIAR_ROSE` / `FIRST_BLOOM` / `EVERLASTING_ORIGIN`; `COMPETITIVE_SELF_LIMITED` = contract not form.
- Everlasting Origin only Story + opted-in Mythic / Convergence Unbound; never invincible ranked.
- Yin ≠ evil; Yang ≠ simple-good; Kaia philosophical victory preserved.
- Flagline internal IDs remain `solar`/`lunar`; display aliases Beaconward/Veilward.
- Echoes / Fracture Echoes are simulations — not enslaved fighters or real Puppet souls.
- Black/White Puppet echoes in Unbound are **not** Yin/Yang/Rosamere puppets without separate approval.
- Cosmic Colossus Yin/Yang + Rosamere Everlasting Origin controllable in opt-in Mythic only; KO of avatar ≠ true Rosamere defeat.

## Shipping honesty

Do not claim V1/commercial from JSON placeholders, procedural meshes, or headless suite passes alone.

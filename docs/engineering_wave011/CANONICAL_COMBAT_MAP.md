# Wave011 Canonical Combat Map

Pinned start: `ANIME_AGGRESSORS_ACCEPTED_MAIN_START_SHA=0afe3079db474fcfd75cd8a40659e96a5867b8fc`  
Field-kit gate: `#116 MERGED` → `FIELD_KIT_ACCEPTED_MAIN_SHA=47eb41ffd47e0143798436f088c9e9371339f5de`

Doctrine: deepen accepted `game-godot/` systems only. No Wave011 parallel combat engine, TypeScript oracle, `packages/game-core`, `game/godot`, `legacy/`, or web preview as gameplay proof.

## System inventory (accepted main)

| System | Path | Role |
|--------|------|------|
| AuraScaler | `game-godot/scripts/combat/aura_scaler.gd` | Charge/decay + per-level move scaling |
| AuraIdentity | `game-godot/scripts/combat/aura_identity.gd` | Seven-fighter combat fingerprints |
| AuraSpecialRuntime | `game-godot/scripts/combat/aura_special_runtime.gd` | Armor / identity on-confirm hooks |
| CombatMath | `game-godot/scripts/combat/combat_math.gd` | Frames, DI, stale, shield, grab |
| MoveRunner | `game-godot/scripts/combat/move_runner.gd` | Startup / active / recovery |
| HitResolver | `game-godot/scripts/combat/hit_resolver.gd` | Confirm path (melee + projectile) |
| Projectile / Spawner | `game-godot/scripts/combat/projectile.gd` | Aura-scaled Area2D routed through HitResolver |
| ThrowResolver | `game-godot/scripts/combat/throw_resolver.gd` | Directional throws from move defs |
| CombatFeedback | `game-godot/scripts/combat/combat_feedback.gd` | Hitstop, sparks, SFX, camera |
| FrameDataTable | `game-godot/scripts/combat/frame_data_table.gd` | Derived from canonical move JSON |
| CompetitiveRules | `game-godot/scripts/combat/competitive_rules.gd` | Stock-3 / 180s / no items / clean HUD |
| Fighter + SM | `game-godot/scripts/fighters/fighter.gd` | Body, charge, mash, tech, movement |
| CpuController | `game-godot/scripts/fighters/cpu_controller.gd` | Observation-only; legal inputs |
| BattleScene | `game-godot/scripts/battle/battle_scene.gd` | Canonical versus runtime |
| TrainingBattleScene | `game-godot/scripts/training/training_battle_scene.gd` | Debug HUD + frame overlay |
| BattleHudPanel | `game-godot/scripts/ui/battle_hud_panel.gd` | Clean competitive meters |
| GameState | `game-godot/scripts/core/GameState.gd` | Versus / training / eval flags |
| Move / fighter data | `game-godot/data/{fighters,moves}/*.json` | Original-IP defs |

## GAME-AA classification at Wave011 start (origin/main `0afe307`)

| Req | Title | Classification | Notes |
|-----|-------|----------------|-------|
| GAME-AA-001 | Aura charging | SHALLOW | Charge state existed; first-frame lock + `AURA_READY` forge blocked accumulation |
| GAME-AA-002 | Aura-scaled H2H | PRESENT_SUBSTANTIAL | AuraScaler on melee; identity post-process thin in movement |
| GAME-AA-003 | Charge-scaled projectiles | SHALLOW | Spawned, but HitResolver property check + mask missed hurtboxes |
| GAME-AA-004 | Directional throws | PRESENT_SUBSTANTIAL | Four throw defs; mash/escape thin |
| GAME-AA-005 | Fighter-specific movement | SHALLOW | Run/weight/jump distinct; air accel / traction / charge-move not runtime |
| GAME-AA-006 | Defense and recovery | SHALLOW | Shield hold regenerated (net regen vs data decay); tech missing |
| GAME-AA-007 | Original power identities | PRESENT_SUBSTANTIAL | Seven tags in data + AuraIdentity; fingerprints incomplete |
| GAME-AA-008 | Readable impact | SHALLOW | Feedback tiers exist; sparks not always on HitResolver confirm |
| GAME-AA-009 | Competitive frame behavior | SHALLOW | Startup/active/recovery in JSON; stale/combo/ruleset not wired |
| GAME-AA-010 | Training and debug tools | SHALLOW | Training scene exists; versus debug HUD leaked in debug builds |

## Hard rules for this wave

- Canonical Godot production runtime only (`game-godot/`).
- Do not use ProductionGateHarness / `battle_eval_mode` as Wave011 gameplay proof.
- Competitive modes: `HIDDEN_RUBBER_BANDING=false`, `FORCED_FINISH_ORDER=false`.
- Original IP only. No copyrighted anime characters, moves, or likenesses.
- CPU may observe public state and own aura; never write `opponent.aura`.

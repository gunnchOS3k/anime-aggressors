# Wave011 maintainability

Deepen accepted `game-godot/` combat — do not fork a Wave011 engine.

## Canonical ownership

| Concern | Owner |
|---------|-------|
| Charge / decay / stale / shield / grab math | `scripts/combat/combat_math.gd` |
| Aura levels + projectile tables | `scripts/combat/aura_scaler.gd` |
| Seven-fighter fingerprints | `scripts/combat/aura_identity.gd` |
| Confirm path (melee + projectile) | `scripts/combat/hit_resolver.gd` |
| Hitbox size/offset | `fighter.gd` `_update_hitbox_from_move` from move JSON |
| Competitive HUD split | `competitive_rules.gd` + BattleScene / TrainingBattleScene |
| Frame overlay | `frame_data_table.gd` (derived, not duplicated constants) |

## HUD

Versus instantiates DebugHud only when `CompetitiveRules.show_debug_hud` is true (training / explicit debug). Competitive meters stay on `BattleHudPanel`.

## Mutation strings

`tools/engineering_wave011/run_mutation_campaign.py` exact-matches production constants. If those constants move, update the campaign in the same change.

## Non-goals

No TypeScript combat oracle, no `packages/game-core` gameplay proof, no Wave011* duplicate fighter/resolver types.

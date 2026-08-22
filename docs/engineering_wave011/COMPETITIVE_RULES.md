# Competitive rules vs training HUD

Implemented in `game-godot/scripts/combat/competitive_rules.gd` and applied by `GameState.apply_competitive_ruleset()` / `begin_local_versus()`.

| Rule | Competitive | Training |
|------|-------------|----------|
| Stocks | 3 | 99 |
| Timer | 180s | off |
| Items / hazards | off | off |
| Hidden rubber-banding | false | n/a |
| Forced finish order | false | n/a |
| Debug HUD | off (`debug_combat_hud=false`) | on |
| Frame-data overlay | off | on (`FrameDataOverlay`) |
| Battle HUD | stocks / % / aura meters only | same + debug + overlay |

Versus `BattleScene` instantiates `DebugHud` only when `CompetitiveRules.show_debug_hud(GameState)` is true (training or explicit debug flag). Clean competitive HUD is `BattleHudPanel` only.

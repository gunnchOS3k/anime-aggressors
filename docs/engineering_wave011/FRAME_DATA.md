# Frame data (derived from canonical move defs)

Source: `game-godot/data/moves/*.json` via `FrameDataTable` (`game-godot/scripts/combat/frame_data_table.gd`).

Not a second engine. Startup / active / recovery / damage / angle / hitstop are read from the same dictionaries `MoveRunner` consumes.

## Core set per fighter

`jab_1`, `jab_2`, `jab_finisher`, tilts, dash/heavy, aerials, `neutral_special_projectile`, `side_special`, `up_special_recovery`, `down_special`, `grab`, four throws, `aura_burst`.

## Ember Vale jab_1 (example)

| Field | Value |
|-------|-------|
| startup | 3 |
| active | 2 |
| recovery | 7 |
| damage | 2.5 |
| angle | 42 |

Training overlay: `FrameDataTable.overlay_line(move, move_runner)` on `TrainingBattleScene`.

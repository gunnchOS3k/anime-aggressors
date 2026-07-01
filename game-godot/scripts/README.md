# scripts/

Godot production code by domain:

- `core/` — autoloads, boot, scene router
- `data/` — JSON loaders
- `fighters/` — fighter entity, state machine, states
- `combat/` — move runner, hit resolver, combat math
- `movement/` — (ground/air helpers — extend here)
- `menus/` — menu scene controllers
- `training/` — training menu + battle
- `battle/` — versus battle scene
- `ai/` — CPU (extend `fighter.gd` cpu_tick → here)
- `debug/` — debug HUD, overlays
- `input/` — (input profiles — extend here)
- `hud/` — battle HUD widgets
- `camera/` — combat camera (future)

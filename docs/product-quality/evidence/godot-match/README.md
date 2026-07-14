# Godot match-loop evidence — Anime Aggressors

Date: 2026-07-13 (local)

## Automated

| Check | Result | Evidence |
|-------|--------|----------|
| smoke_runner (incl. match_loop route graph) | PASS | `/tmp/aa-smoke2.log` + `tests/smoke_runner.gd` |
| accept_match_loop (battle spawn, P1 control, CPU, stock end, rematch, menu, training, settings) | PASS | `accept-match-loop.log` |
| Fighter data smoke (7 fighters schema moves) | PASS (prior + reconfirmed via data_load) | smoke_runner |

## Manual interactive still recommended

GUI playthrough with video of intro → countdown → fight → rematch remains desirable for Pixel/PR packaging; headless harness does not replace controller feel.

## Code deltas this pass

- Touch-friendly pause panel (Resume / Rematch / Return to Menu) in `scripts/battle/battle_scene.gd`
- `tests/accept_match_loop.gd`, `tests/smoke_match_loop.gd`

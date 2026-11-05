# Cursor P1 joypad finding — October 22, 2026

Official V1 and RC2 remain NOT READY. This note does not accept art, gameplay feel, balance, device, or a release gate. B02 stays CRITICAL. No animation, combat timing, VFX, audio, or mesh file changed.

## Classification

Player 1's Godot InputMap was missing the joypad events that player 2 already had for the same actions. A device-0 pad could not hold up or down, and could not grab. Keyboard bindings were already present and are unchanged.

`fighter.gd` reads `p1_up` and `p1_down` for directional attacks and specials. `throw_resolver.gd` reads the same actions for throw direction. Grab is `p1_grab`. Player 2 already bound those three to device 1.

## Sources

- Base at branch creation: `bda5b5a57fec99fc2d0821ae8819248c1baf7f74` (`origin/release/anime-v1-dialogue-and-elemental-performance`, also the Codex checkout at `/Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure`).
- Map file: `game-godot/project.godot`, section `[input]`.
- Godot button index 10 is `JOY_BUTTON_RIGHT_SHOULDER`. Player 1 dodge was already button 9 (`JOY_BUTTON_LEFT_SHOULDER`) on device 0. This is the Godot index, not the browser Gamepad API index.

## Reproduction

No Godot process. The checker only reads the project file.

```sh
python3 tools/input/check_p1_joypad_parity.py
```

Before, exit 1:

```
P1 device 0 is missing joypad events that P2 device 1 already has:
  p1_up: ['NONE']
  p2_up: ['motion axis=1 value=-1.0']
  p1_down: ['NONE']
  p2_down: ['motion axis=1 value=1.0']
  p1_grab: ['NONE']
  p2_grab: ['button index=10']
mismatch_count 3
```

The other seven compared actions (left, right, jump, attack, special, shield, dodge) already matched after shifting P2's device 1 to P1's device 0.

## Fix

Three events added on device 0, copied from the existing player 2 events:

- `p1_up`: stick axis 1, value -1.0. Key W (`physical_keycode` 87) kept.
- `p1_down`: stick axis 1, value 1.0. Key S (`physical_keycode` 83) kept.
- `p1_grab`: joypad button 10. Key U (`physical_keycode` 85) kept.

After, the same command prints `p1_joypad_matches_p2 mismatch_count 0` and exits 0.

`InputPersistenceService` keeps non-keyboard events when it reapplies a keyboard profile, so a later keyboard remap does not drop these joypad events. Dodge, up, and down are still outside that keyboard profile. This change does not add them there.

## Not this defect

PartyLink `lanHost.ts` still sets `grab: false` when it builds a host frame, and the browser pad has no grab button. The host sim only steps left and right. That path was not changed.

Saved `rules.stocks`, `rules.cpu_level`, and `rules.timer` are written by `GameState._persist_save` and are not read back in `ensure_save_loaded`. That was not run and was not changed.

## Not run

No local Godot import, export, or headless scene. Internal free space stayed about 17 GiB, under the 18 GiB reserve. The worktree is a sparse checkout of `game-godot/project.godot` plus this note and the checker.

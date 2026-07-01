# Godot smoke tests — `game-godot/tests/`

Headless sanity checks for autoloads, data, and core scene load/instantiate paths.

## Suites

| Script | Checks |
|--------|--------|
| `smoke_boot.gd` | GameState/SceneRouter autoloads, BootScene, main scene |
| `smoke_data_load.gd` | 7-fighter roster + move manifests |
| `smoke_fighter_scene.gd` | Fighter.tscn nodes (Body, Hitbox, Hurtbox, debug rects, AuraVfx) |
| `smoke_training_scene.gd` | Training scenes + DebugHud |
| `smoke_battle_scene.gd` | Battle, MainMenu, Results scenes |

## Run (Godot CLI required)

From repo root:

```bash
node scripts/aa-verify-project.mjs
```

Or manually:

```bash
godot4 --path game-godot --headless --quit-after 1
godot4 --path game-godot --headless -s res://tests/smoke_runner.gd
```

On macOS with `.app` install:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game-godot --headless -s res://tests/smoke_runner.gd
```

## Editor manual run

1. Open `game-godot/project.godot` in Godot 4.2+
2. Project → Run (temporarily set main scene to a test scene) **or** use **Run Script** on `smoke_runner.gd` if your Godot build supports `-s`
3. Check Output panel for `[smoke] OK` lines

If headless `-s` is unavailable, run each suite from the Godot **Script** editor:

```gdscript
SmokeAssert.reset()
print(SmokeBoot.run())
```

## Evidence

Automated results are recorded in `tmp/aa-verify-project-report.json` and `docs/PR48_VERIFICATION_REPORT.md` by `scripts/aa-verify-project.mjs`.

Manual editor playtest signoff: `docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md` + `docs/MANUAL_PLAYTEST_SIGNOFF_TEMPLATE.md`.

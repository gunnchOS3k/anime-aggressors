# Godot smoke tests

Run from Godot editor **Scene → Run Tests** after installing GUT, or validate manually:

1. `godot --headless --path game/godot --check-only`
2. Open `scenes/Main.tscn` and confirm no script errors in Output

## Expected project files

- `project.godot`
- `scenes/Main.tscn`
- `scripts/fighter/FighterController.gd`
- `scripts/BattleScene.gd`

See `docs/GODOT_MANUAL_QA.md` for gameplay validation.

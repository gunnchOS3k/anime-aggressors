# Anime Aggressors — Digital RC Clean Install

1. Install Godot 4.5+ (matching `game-godot/project.godot`).
2. This package includes Path A procedural assets (fighters/stages/audio) under `game-godot/assets/`.
3. From the package root (or full repo root with matching trees):
   ```bash
   GODOT_BIN=/path/to/Godot
   "$GODOT_BIN" --headless --path game-godot --import
   "$GODOT_BIN" --headless --path game-godot --quit-after 2
   "$GODOT_BIN" --headless --path game-godot -s res://tests/smoke_runner.gd
   "$GODOT_BIN" --headless --path game-godot -s res://tests/rc_validation_runner.gd
   node scripts/validate-anime-digital-rc.mjs
   ```
4. Confirm `playtest-evidence/digital_rc_validation.json` reports `ok: true`.
5. Scope: **private/dev digital RC only** — not a public deploy / store build.

Painted remasters remain optional; Path A procedural digital art/audio are included.

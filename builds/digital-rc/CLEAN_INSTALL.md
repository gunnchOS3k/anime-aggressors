# Anime Aggressors — Digital RC Clean Install

1. Install Godot 4.5+ (matching `game-godot/project.godot`).
2. Copy this package tree beside a full checkout OR use the full repo.
3. From repo root:
   ```bash
   GODOT_BIN=/path/to/Godot
   "$GODOT_BIN" --headless --path game-godot --quit-after 2
   "$GODOT_BIN" --headless --path game-godot -s res://tests/smoke_runner.gd
   "$GODOT_BIN" --headless --path game-godot -s res://tests/rc_validation_runner.gd
   node scripts/validate-anime-digital-rc.mjs
   ```
4. Confirm `playtest-evidence/digital_rc_validation.json` reports `ok: true`.
5. Scope: **private/dev digital RC only** — not a public deploy / store build.

Painted character/stage art and final audio stems may still be listed in `content/missing_assets.json`.

# Known Limitations — Anime Aggressors

- Main menu lacks web Three.js liveliness (parity matrix open items)
- Godot 4.3 Android builds trigger 16 KB page-size compatibility warning
- Disk space below 15 GB gate prevents fresh release export when free space dips under limit
- Concept-art visual treatment for fighters/arena incomplete
- Pixel device acceptance still **NOT TESTED** while ADB empty

## Closed this pass

- Fighter move data smoke: aligned to `move_schema.json` required IDs (`jab_1`…, `throw_forward`…). All seven fighters already had schema-complete moves; legacy smoke looked for non-schema `jab`/`throw` IDs. Headless `smoke_runner` → **all suites passed** (2026-07-13).

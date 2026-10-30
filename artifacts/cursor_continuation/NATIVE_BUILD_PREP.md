# Native build prep (honest — Cursor digital)

**Status:** prep documentation only. Does **not** claim export templates installed, desktop export green, device matrix, RC2, V1, or `CURSOR_COMPLETE`.

## Primary feel target

- Godot **native desktop editor** playtest (`game-godot/project.godot`, Godot 4.7.x)
- Export presets / templates are **optional for editor playtest** — do not block digital RTM work on missing exports

## Explicit non-claims

| Claim | Value |
|-------|-------|
| `native_export_claimed_green` | **false** |
| `device_matrix_pass` | **false** |
| Console platforms (Switch/PS/Xbox) | **not supported** |
| Web WASM | **secondary** only — never reimplement combat in TypeScript |
| `SHIPPING_ROLLBACK_ENABLED` | **false** |
| `HUMAN_ART_APPROVED` | **false** |
| `CURSOR_COMPLETE` | **false** |

## Prep checklist (operators)

1. Open `game-godot` in Godot 4.7.x; verify editor playtest still boots.
2. Before any release export: confirm export templates + `export_presets.cfg` reviewed — this tip does **not** mark that done.
3. PartyLink seats: connected humans only; BattleScene fighter slots remain **2** (AA-RTM-008).
4. Ten-fighter roster digital presentation files present ≠ HUMAN_ART / frame-data owner audit.
5. Preserve Codex `_anime_v1_integrated_20261025` / HitResolver — Cursor presentation honesty only.

## Related

- `docs/BUILD_TARGETS.md` — supported targets table
- `game-godot/scripts/rc/partylink_roster_native_honesty.gd` — automated honesty contract
- `game-godot/scripts/trials/partylink_seat_enforcement.gd` — six-mode seat matrix

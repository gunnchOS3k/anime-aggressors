# Acceptance Checklist — Anime Aggressors

**Branch:** `cursor/product-quality-mobile-pass`  
**Date:** 2026-07-13

## Gates

| Gate | Status | Evidence |
|------|--------|----------|
| Visible cold boot / title | **PASS** | `docs/product-quality/evidence/visible-gui/01-boot.png` |
| Main menu | **PASS** | `02-main-menu.png` |
| Fighter / stage select | **PASS** | `03-fighter-select.png`, `04-stage-select.png` |
| Visible match (attack/special/grab) | **PASS** | `05`–`08` |
| Stock loss / results / rematch | **PASS** | `09`–`11` |
| Headless match harness | **PASS** | `game-godot/tests/accept_match_loop.gd` |
| Signed Android RC + 16 KB | **NOT STARTED** | gated until Pedestrian visible cup + migration pass |
| Pixel acceptance | **NOT TESTED** | USB Pixel absent after reconnect storm; signed RC ready |
| PR ready | **No** | awaiting Android gates + verifier |

## Driver

```bash
/Applications/Godot-4.3.app/Contents/MacOS/Godot --path game-godot -s res://tests/accept_visible_match.gd
```

Screenshots also land in Godot userdata `visible_gui/` and are copied into `docs/product-quality/evidence/visible-gui/`.


## Godot 4.5 / 16 KB (2026-07-13)

- Editor 4.5.stable + matching templates: PASS
- Headless smoke_runner: PASS
- accept_match_loop: PASS
- Signed internal RC 0.3.0 (202): built; 16 KB ELF align PASS
- Pixel install: blocked on physical USB reconnect

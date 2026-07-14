# Acceptance Checklist — Anime Aggressors

**Branch:** `cursor/product-quality-mobile-pass`  
**Date:** 2026-07-14

## Gates

| Gate | Status | Evidence |
|------|--------|----------|
| **Visible GUI journey (Godot 4.5, non-headless)** | **PARTIAL** | Functional flow **PASS** (`visible-runner.log` `failed=0`, shots `01`–`26`); release art **PARTIAL** (proxy fighters + greybox stages) — see `visible-anime/NOTES.md` |
| Visible cold boot / title (Godot 4.5) | **PASS** | `docs/product-quality/evidence/visible-anime/01-boot.png` |
| Main menu / Start Game surface | **PASS** | `02-main-menu.png` |
| Ruleset → fighter → stage | **PASS** | `03`–`05` |
| Intro / countdown / combat inputs | **PASS** | `06`–`14` |
| Damage / knockback / stock / pause | **PASS** | `15`–`18` (forced hit used when scripted jab misses) |
| Results / rematch / training / settings persist | **PASS** | `19`–`26` |
| Seven fighters unique combat data | **PASS** | `visible-runner.log` + move JSON hashes |
| Release presentation (no debug HUD / watermarks) | **PARTIAL** | Debug HUD off; identical proxy models + floating name labels + greybox stages remain |
| Headless match harness | **PASS** | `game-godot/tests/accept_match_loop.gd` |
| Signed Android RC + 16 KB | **PASS** | APK SHA `d2d39717…b8d0`; ZIP+ELF 16 KB PASS; `debuggable=false`; evidence `android-release/VERIFY_16KB.txt` |
| Pixel acceptance | **PARTIAL** | Signed RC cold launch without debug/16 KB warning; full touch menu→match not completed via ADB |
| PR ready | **No** | awaiting Android gates + verifier + art presentation |

## Driver

```bash
~/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot --path game-godot -s res://tests/accept_visible_match.gd
```

Screenshots land in Godot userdata `visible_anime/` and are copied to `docs/product-quality/evidence/visible-anime/`.

## Godot 4.5 / 16 KB (2026-07-13)

- Editor 4.5.stable + matching templates: PASS
- Headless smoke_runner: PASS
- accept_match_loop: PASS
- Signed internal RC 0.3.0 (202): built; 16 KB ELF align PASS
- Pixel install: blocked on physical USB reconnect

## Visible anime pass (2026-07-14)

- Godot **4.5.stable** visible window driver: `RESULT failed=0`
- See `docs/product-quality/evidence/visible-anime/NOTES.md`

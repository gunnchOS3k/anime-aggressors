# Web → Godot Parity Matrix

**Reference:** GitHub Pages screen recordings (2026-07-12) + `apps/web/` source  
**Target:** `game-godot/` Android primary runtime  
**Date:** 2026-07-13

| Feature | Web (Pages) | Godot | Status | Notes |
|---------|-------------|-------|--------|-------|
| Animated startup background | Three.js / CSS arena hub | ColorRect tween + accent lines | **Needs to be ported** | Boot scene updated this pass; concept-art energy still partial |
| Title “Anime Aggressors” | Large hub title | Label + tween | **Partially implemented** | |
| “Create Your Legend” tagline | Present in recordings | Subtitle label | **Partially implemented** | |
| Start Game CTA | Primary button | Dynamic Button | **Partially implemented** | Haptics/audio hooks pending |
| Skip cold-start on return | Implicit in SPA | `SceneRouter.skip_boot_title` | **Partially implemented** | |
| Lively main menu background | `MainMenuSceneRenderer` Three.js | Static ColorRect | **Needs to be ported** | |
| Start Battle flow | Hash routes → match setup | `main_menu` → `mode_select` → `ruleset` → fighters → stage → battle | **Already present in Godot** | Needs device verification |
| Training flow | Web training route | `training` → `training_battle` | **Already present in Godot** | |
| Rulesets | Web rules screens | `RulesetScene` | **Already present in Godot** | |
| Fighter Vault / Select | Web fighter select + portraits | `FighterSelectScene` + JSON data | **Needs to be ported** | Portraits/silhouettes lack concept-art treatment |
| Stage Vault / Select | Web stage select | `StageSelectScene` | **Needs to be ported** | Arena visuals improved; not full concept art |
| Controls screen | Web controls | `ControlsScene` | **Already present in Godot** | Mobile copy needs polish |
| Settings + persistence | localStorage | `GameState` autoload | **Partially implemented** | Relaunch persistence not device-verified |
| Labs / Experimental | Web labs panel | `LabsScene` | **Already present in Godot** | |
| Mobile Playtest shortcut | Web path | `MobilePlaytestScene` | **Already present in Godot** | No longer auto-skipped from boot |
| Fighter preview | Web 3D/preview | Godot fighter scene | **Partially implemented** | |
| Match intro / countdown | Web battle loader | `BattleScene` countdown | **Already present in Godot** | |
| Playable battle | Web canvas battle | `BattleScene` sim | **Already present in Godot** | |
| Results + rematch | Web results | `ResultsScene` | **Already present in Godot** | |
| Seven canonical fighters | Shared JSON / oracle | `data/fighters.json` | **Already present in Godot** | Single source via generator |
| Jab / throw / grab / aura move sets | Web move tables | `data/moves/*.json` + `move_schema.json` | **Verified** | Smoke asserts full `required_move_ids` (2026-07-13); not legacy bare `jab`/`throw` aliases |
| Stage / ruleset data | Shared packages | `data/*.json` | **Already present in Godot** | |
| Pages hub navigation | Home + labs routes · `apps/web/` | N/A (web) | **Verified on Pages** | 2026-07-13: Training `#/training`, Stage Select `#/stage-select`, Fighter Select, battle mount |
| Pages battle mount | `#/battle` canvas | N/A | **Verified on Pages** | Diagnostics: fighters 2, stage skyline-arena |
| Pages stage select | Stage vault UI | `StageSelectScene` · `scripts/menus/` | **Verified on Pages** | Skyline / Training Grid / Neon Rooftops listed |
| Pages training | Training route | `training_menu_scene.gd` / `training_battle_scene.gd` | **Verified on Pages** | `#/training` opens |
| Move data smoke | Web tables / packages | `tests/smoke_data_load.gd` + `data/moves/*.json` | **PASS** | All suites passed headless 2026-07-13 |
| Godot boot / menu | Pages hub energy | `boot_scene.gd`, `main_menu_scene.gd` | **PARTIAL** | Ambient pulse + press feedback; audio still light |
| Touch input | Web touch abstractions | `TouchInputManager` | **Partially implemented** | |
| Controller / keyboard | Web + Godot | Godot input map | **Already present in Godot** | |
| Android back button | N/A web | Menu `ui_cancel` | **Partially implemented** | Not verified on Pixel |
| Release-mode debug HUD off | N/A | `OS.is_debug_build()` gate | **Partially implemented** | `smoke_release_mode` added |
| Audio / SFX on menu | Web audio hooks | Limited | **Needs to be ported** | |
| Button press FX | Web CSS/JS | Default Godot theme | **Needs to be redesigned for Godot** | |
| Haptic feedback | Optional web | Not wired | **Needs to be ported** | |
| GitHub Pages deploy | `apps/web/dist` | N/A | **Web-only experimental feature** | Preserved; not replaced |
| Runtime banner “Godot primary” | Current web home | Hidden in Godot | **Intentionally removed** | Product build must not show dev banners |
| Proxy / debug labels | Dev web only | Must stay off in release | **Partially implemented** | |

## Critical gaps (block “parity complete”)

1. Main menu visual liveliness (Three.js → Godot VFX/particles)
2. Fighter/stage select presentation vs concept art
3. Menu audio, focus enlargement, haptics
4. Full Pixel acceptance flow with screen recording
5. 16 KB page-size compatibility (Godot toolchain migration)

## Source of truth policy

- **Fighters, stages, rulesets:** `game-godot/data/` generated from `packages/game-core` — do not fork web-only databases.
- **Web:** Reference UX only; GitHub Pages functionality preserved in `apps/web/`.

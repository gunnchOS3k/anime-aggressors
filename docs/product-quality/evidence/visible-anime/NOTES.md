# Visible Anime Acceptance Notes — 2026-07-14

**Runtime:** Godot 4.5.stable (`~/Applications/Godot/Godot-4.5.app`) — **visible window** (not headless)  
**Branch tip:** `cursor/product-quality-mobile-pass` (local acceptance fixes, pre-commit)  
**Driver:** `game-godot/tests/accept_visible_match.gd`  
**Log:** `visible-runner.log` → `RESULT failed=0` (re-run 2026-07-14 ~16:36 local)  
**Screenshots:** `01-boot.png` … `26-menu-final.png` (copied from Godot userdata into this folder)

## Overall status: **PARTIAL**

Functional visible GUI journey **PASS** — cold boot through settings persistence, 26 screenshots, harness `failed=0`.  
Release presentation **PARTIAL** — fighters still render as shared geometric proxy GLBs with floating name tags; stages remain greybox ColorRect platforms. Proxy geometry is acceptable for playtest; distinct combat data is verified separately.

## Shot index

| Shot | Scene |
|------|--------|
| 01 | Cold boot / title |
| 02 | Main menu |
| 03 | Ruleset |
| 04 | Fighter select (all 7 named) |
| 05 | Stage select |
| 06 | Countdown |
| 07 | Match intro |
| 08–14 | Move/jump, jab, ground, aerial, projectile/special, aura, grab-throw |
| 15 | Damage/knockback (Rook **18%** after forced hit once grab/shield state cleared) |
| 16 | Stock loss / respawn |
| 17–18 | Pause panel + resume |
| 19–20 | Results + rematch |
| 21–23 | Menu → training menu → training battle |
| 24–25 | Settings + ConfigFile touch_mode persistence |
| 26 | Final menu |

## Fighter combat data

All seven roster fighters load with unique profiles (23-move manifests, distinct weight/run/archetype/damage samples):

Ember Vale, Rook Ironside, Juno Spark, Kaia Windrow, Nix Calder, Orion Vell, Vesper Nyx — **PASS (data)** / **PARTIAL (visual identity)**.

## Presentation gates

| Check | Result |
|-------|--------|
| Debug HUD auto-on | **Cleared** (debug build keeps F1 toggle, starts hidden) |
| Hitbox overlays | Hidden |
| `ORIGINAL 3D PROXY` watermark | Hidden |
| Stick/blocky identical GLB proxies | **Still present** |
| Floating name labels over bodies | **Still present** |
| Stages art | Greybox platforms only |

## Settings persistence

`TouchInputManager` now saves `user://aa_settings.cfg` (`touch_mode`). Reload verification: **PASS**.

## Known harness notes

- Natural scripted jab often misses while opponent is in grab/shield leftover state; harness clears state and applies one `receive_hit` for damage % evidence when needed.
- CombatFeedback impact events observed during the move sequence in `visible-runner.log`.

## Pedestrian Pursuit (spot check only)

`docs/product-quality/evidence/visible-cup/` present with cup start, 4 course + results pairs, final standings, log.  
`ACCEPTANCE_TEST_DURATION.md`: acceptance 1 lap / production typically 3 laps. **Not re-run.**

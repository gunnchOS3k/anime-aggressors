# Anime Aggressors Pixel Status — 0.3.6 (209)

**Device:** Pixel 6a `27211JEGR06194` (landscape forced)

**APK:** `build/android/anime-aggressors-release.apk`  
**SHA-256:** `8d4222a7edc03ad386ebcdd5435c22166141f7b30da504013545c1b7c66a7def`  
**Commit tip:** `fa8f661`

## Proven on Pixel

| Step | Result | Evidence |
|------|--------|----------|
| Install 0.3.6 over 0.3.5 | Success | `v036-install.txt` |
| Cold launch title | Partial (cameos); Start via DPAD | `v036-01-boot.png`, `v036-nav-1.png` |
| Main menu | Pass; no combat overlay | `v036-nav-1.png` |
| Ruleset → Confirm | Pass | `v036-04` → `v036-06` |
| Fighter Select (7 roster tiles) | Pass | `v036-06.png` |
| Select preview enlarged + face | Pass (Ember) | `v036-06-preview.png` |
| Next/Confirm by touch | Pass → Stage Select | `v036-08-after-next2.png` |
| Enter battle | Pass | `v036-14-versus-or-battle.png` |
| Combat touch HUD only in battle | Pass | `v036-14` bot controls present; absent on menus |
| Combat taps exercised | Attempted | `v036-15-combat.png` |

## Not yet PASS

- Full 7-fighter focused large-preview cycle (automation taps drifted after Stage/Battle)
- Full match end → results → rematch
- Training / Settings persistence
- Android Back → Pause contract visual confirmation in this pass (`v036-16` still shows battle HUD text in crop)
- FPS / thermal performance report
- Independent verifier rerun

## Navigation / overlay notes

- Soft Back no longer quit from Ruleset earlier (0.3.5 evidence).
- Overlay hard-gated off menus; Start Game still more reliable via `keyevent 23` than ADB taps.

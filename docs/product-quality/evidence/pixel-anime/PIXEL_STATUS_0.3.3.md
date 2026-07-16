# Anime Aggressors Pixel Status — 0.3.3 (2026-07-15)

## Package
- package: com.gunnchos.animeaggressors
- versionName: 0.3.3
- versionCode: 205
- APK: build/android/anime-aggressors-release.apk
- SHA-256: b73a8b06ebb7cd2721b6d48ba4a6f73c4aec39cb56b39aad4dc56f5d5103fda6
- signer cert SHA-256: 08609ad3d868c8fbcbe662c1fd5b0ab7b424a56b3329522948bbe4a64e3f4058
- zipalign 16 KB: Verification successful
- debuggable: false (no android:debuggable attr)

## Pixel connection
- serial 27211JEGR06194 present as `device`

## Navigated & captured
- Cold launch / living title (overlay hidden) — PASS
- Main menu — PASS
- Ruleset → Fighter Select (all 7 fighters) — PASS
- Stage Select → Versus countdown → FIGHT — PASS
- Touch overlay appears in battle only (menu blocking fixed in 0.3.3) — PASS
- Training Mode entry — PASS
- Recordings: anime-pixel-match.mp4, anime-pixel-match2.mp4, anime-damage.mp4

## Not yet proven on Pixel
- Visible damage % change / stock loss / results screen under automated touch
- Aura charge visibly > 0 in HUD
- Rematch / settings persistence on device this session
- gfxinfo FPS (Godot GL path reports 0 Android UI frames — need in-engine FPS)

## Character art honesty
- Rendered roster evidence present (170 PNGs under docs/character-design/anime-character-review/rendered/)
- Models remain stylized procedural capsules with distinct hair/color/silhouette — NOT hand-authored production GLBs
- Title cameos still use simplified silhouette cards

## Code fix in 0.3.3
- Touch overlay AUTO mode limited to BattleScene / TrainingBattleScene so menu Confirm taps work

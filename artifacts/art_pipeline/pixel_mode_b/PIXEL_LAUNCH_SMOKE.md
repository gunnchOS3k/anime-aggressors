# Mode B Pixel candidate review smoke

Device: `PIXEL_REVIEW_DEVICE`  
Package: `com.gunnchos.animeaggressors`  
Activity: `com.godot.game.GodotApp`  
Method: `adb install -r` then `am start` (no uninstall, no `pm clear`)

APK: `builds/android/anime-aggressors-full-roster-human-candidates-review.apk`  
SHA-256: `6fc10d7c86a7df954a55d17f8ed089b3b7c7bf6cd3573ea57e59506a6be57e13`

## Result

```text
MODE_B_PIXEL_INSTALL_PASS=true
MODE_B_PIXEL_REVIEW_ROUTE_PASS=true
MODE_B_GAMEPLAY_SMOKE_PASS=true
ART_SOURCE=HUMAN_CANDIDATE
overlay=Candidate 7/7  Validated 7/7  Owner approved 0/7
process_started=true
immediate_crash=false
```

Route taken:

1. Boot title → Start Game → Main Menu
2. Labs (dev) → Full roster art review
3. Cycled all seven fighters; overlay stayed HUMAN_CANDIDATE 7/7
4. Walk action button changed `Action: walk`
5. Escape from review → Fighter Select (seven distinct KayKit cards + Ember showcase)
6. Lock P1 Ember / P2 CPU → Stage Select → Confirm → Battle

Battle showed two KayKit mage bodies on Training Grid with a live clock (`3:00` → `2:56`). Process stayed alive.

## Honest notes

- Existing task was brought forward on first `am start`; boot title was already the current scene. No force-stop / uninstall / `pm clear`.
- Review-scene 3D preview is cropped at the top. Select cards and battle show full bodies.
- Battle HUD labeled both sides Ember Vale after the lock path. Gameplay still loaded sourced meshes.
- `KEYCODE_BACK` was not used.
- Serial redacted. No `HUMAN_*` quality gate and no `HUMAN_APPROVED`.

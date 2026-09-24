# Mode A Pixel launch smoke

Device: `PIXEL_REVIEW_DEVICE`  
Package: `com.gunnchos.animeaggressors`  
Activity: `com.godot.game.GodotApp`  
Method: `adb install -r` then `am start` (no uninstall, no `pm clear`)

## Result

```text
MODE_A_PIXEL_LAUNCH_PASS=true
process_started=true
immediate_crash=false
initial_scene=boot title (ANIME AGGRESSORS / Start Game)
inputs_respond=true
full_roster_review_route=available via Main Menu → Labs (dev) → Full roster art review
return_paths=pause menu present (Resume / Rematch / Move List / Return to Menu); gamepad B did not leave Credits
```

Process stayed alive across boot, review walkthrough, versus match, and a ~5 minute sustained combat loop.

Filtered logcat around the app PID found no `AndroidRuntime` / `FATAL` / `DEBUG` crash lines. Unrelated device logs were not dumped.

## Honest notes

- First `am start` after install brought an existing task forward; a later force-stop + start produced a clean boot title.
- `KEYCODE_BACK` was not used (prior Pixel sessions exit the app).
- `com.gunnchos.pedestrianpursuit` was force-stopped only when it could steal focus. That package was not uninstalled or cleared.
- Godot Android `dumpsys gfxinfo` after a reset returned the empty/sentinel 4950 ms series. Launch-time gfxinfo before reset is the only usable frame sample.

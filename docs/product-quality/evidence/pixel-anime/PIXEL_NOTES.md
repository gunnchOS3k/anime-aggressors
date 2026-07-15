# Anime Pixel notes — signed RC 0.3.0 (202)

**Installed after uninstalling debug/non-16KB prior build** (signature mismatch; local data reset).

| Check | Result |
| --- | --- |
| Cold launch title | PASS — `01-cold-launch.png` ANIME AGGRESSORS / Start Game |
| Debug / 16 KB system warning | PASS — no Android App Compatibility dialog on signed RC |
| `pkgFlags` DEBUGGABLE | PASS — absent |
| Artifact 16 KB ZIP+ELF | PASS — `../android-release/VERIFY_16KB.txt` |
| Full touch menu → match journey | PARTIAL — ADB taps did not advance past Start Game reliably |

Recording: `anime-pixel.mp4` · Logcat: `anime-logcat.txt`

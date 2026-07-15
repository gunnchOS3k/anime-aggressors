# Anime Aggressors — Android release build

| Item | Value |
|------|-------|
| Editor | Godot **4.5.stable.official** (`876b29033`) at `~/Applications/Godot/Godot-4.5.app` |
| Export templates | `~/Library/Application Support/Godot/export_templates/4.5.stable/` |
| Android Gradle template | `game-godot/android/` with `.build_version` = `4.5.stable` |
| JDK | Corretto **17** |
| Package | `com.gunnchos.animeaggressors` |
| Version | **0.3.0** (versionCode **202**) |
| APK | `build/android/anime-aggressors-release.apk` (not committed) |
| Signing | `~/.android/gunnchos-internal-keys/anime-internal-release.jks` — inject password at export time from `passwords.env` (`ANIME_*`). Do not commit passwords. |
| 16 KB | Native ELF `PT_LOAD` align **16384**; `.so` STORE uncompressed — see `evidence/android-release/elf-page-alignment.txt` |

## Export

```bash
# Source passwords.env (not committed), patch export_presets keystore password ephemerally, then:
Godot-4.5 --path game-godot --headless --export-release Android build/android/anime-aggressors-release.apk
```

Restore empty `keystore/release_password` after export.

# Android Signing Setup (Internal RC)

Keep secrets and keystores **outside** every repository.

## Canonical internal keystore layout (local machine only)

```text
~/.android/gunnchos-internal-keys/
  anime-internal-release.jks
  pedestrian-internal-release.jks
  beatlink-internal-release.jks
  archive-internal-release.jks
  passwords.env          # never commit
```

`passwords.env` example (do not commit real values):

```bash
export GUNNCHOS_KEYSTORE_DIR="$HOME/.android/gunnchos-internal-keys"
export ANIME_KEYSTORE_PASS='…'
export ANIME_KEY_ALIAS='anime_internal'
export ANIME_KEY_PASS='…'
export PEDESTRIAN_KEYSTORE_PASS='…'
export PEDESTRIAN_KEY_ALIAS='pedestrian_internal'
export PEDESTRIAN_KEY_PASS='…'
```

## Required environment

| Variable | Purpose |
| --- | --- |
| `GODOT_BIN` | Path to Godot 4.5 CLI |
| `JAVA_HOME` | JDK **17** (Corretto recommended) |
| `ANDROID_SDK_ROOT` / `ANDROID_HOME` | Android SDK |
| `GUNNCHOS_KEYSTORE_DIR` | Directory containing `*.jks` |
| Per-app `*_KEYSTORE_PASS` / `*_KEY_ALIAS` / `*_KEY_PASS` | Signing |

## Workflow

1. `source ~/.android/gunnchos-internal-keys/passwords.env`
2. Run the prepare script (patches `export_presets.cfg` **ephemerally** with keystore path + password).
3. Export release APK.
4. Prepare script restores empty passwords / clears absolute paths after export.

```bash
# Anime
node scripts/android/prepare-release-signing.mjs --app anime --apply
# … export …
node scripts/android/prepare-release-signing.mjs --app anime --restore

# Pedestrian
bash tools/android/prepare_release_signing.sh apply
# … export …
bash tools/android/prepare_release_signing.sh restore
```

## Committed presets

`export_presets.cfg` may store:

- `package/unique_name`
- `keystore/release_user` (alias name is not a secret)
- empty `keystore/release` and empty `keystore/release_password`

It must **not** store:

- passwords
- machine-specific home directories in committed form after restore

## Validation errors (expected)

| Error | Fix |
| --- | --- |
| `GUNNCHOS_KEYSTORE_DIR unset` | Export `GUNNCHOS_KEYSTORE_DIR` |
| `keystore file missing` | Place the correct `.jks` in that directory |
| `*_KEYSTORE_PASS unset` | Source `passwords.env` |
| `JAVA_HOME is not JDK 17` | Point `JAVA_HOME` at Corretto 17 |
| Godot: “Release Keystore, User AND Password…” | Run prepare `--apply` before export; do not leave only one of the three fields filled |

## Packages

| App | Package ID | Alias (default) |
| --- | --- | --- |
| Anime Aggressors | `com.gunnchos.animeaggressors` | `anime_internal` |
| Pedestrian Pursuit | `com.gunnchos.pedestrianpursuit` | `pedestrian_internal` |

## Verification after APK

- `aapt dump badging` → package + version
- `apksigner verify --print-certs`
- `debuggable=false`
- 16 KB ELF alignment check used in prior product-quality pass

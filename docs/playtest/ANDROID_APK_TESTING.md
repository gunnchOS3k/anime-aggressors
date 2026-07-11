# Android APK Testing

Direct APK sideloading lets friends test on Android without Google Play Console.

## Prerequisites

- Godot 4.3+ with export templates installed
- Android Studio (for SDK) or standalone Android SDK
- Java JDK 17+

If Godot is not installed as an app, install a matching local binary and templates:

```bash
export GODOT_BIN="$(./scripts/install-godot-ci.sh)"
./scripts/install-godot-templates.sh
```

## Install Godot Export Templates

1. Open Godot → **Editor → Manage Export Templates**.
2. Install templates matching your Godot version, or run:

```bash
./scripts/install-godot-templates.sh
```

## Configure Android SDK in Godot

1. Open `game-godot/` in Godot Editor.
2. Go to **Editor → Editor Settings**.
3. Set **Export → Android → Java SDK Path** (e.g. Android Studio embedded JDK).
4. Set **Export → Android → Android SDK Path** (e.g. `~/Library/Android/sdk` on macOS).
5. Open **Project → Export** and select the **Android** preset.
6. Confirm package name: `com.gunnchos.animeaggressors`.
7. Confirm export path: `builds/android/anime-aggressors-debug.apk`.

## Export Debug APK

### From Godot Editor

1. **Project → Export → Android**
2. Choose **Export Debug** (Godot signs it with the local debug key).
3. Save to `builds/android/anime-aggressors-debug.apk`.

### From CLI

```bash
npm run godot:export:android
```

## Install on a Local Android Device

1. Enable **Developer options** and **USB debugging** on the device.
2. Connect via USB or transfer the APK file.
3. Install:

```bash
adb install -r builds/android/anime-aggressors-debug.apk
```

4. Launch **Anime Aggressors** from the app drawer.
5. Touch controls auto-enable on Android.

## Collect Feedback

Use `docs/playtest/MOBILE_PLAYTEST_CHECKLIST.md`.

## Optional: Google Play Internal Testing (Later)

When ready for wider Android distribution:

1. Create a Google Play Console app entry.
2. Upload an **AAB** release build (requires signing keystore).
3. Add testers via **Internal testing** track email list.
4. Testers install via Play Store link.

Direct APK sideloading remains sufficient for early friend testing and does not require Play Console.

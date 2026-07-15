# Release APK milestone — stylized roster build

**Date:** 2026-07-15  
**Branch:** `cursor/character-life-and-final-product-pass`  
**Version:** `0.3.1` (code `203`)

## Built

- Signed release APK via `scripts/android/export-release-apk.sh` (`.import` watchdog).
- Package: `com.gunnchos.animeaggressors`
- SHA-256: `0828c6b003145bff38789be10f376ff6ed0b64bf065e1528ba844c4a30033768`
- Signature: Internal RC `anime_internal` (v2)
- `debuggable`: not set (release)
- 16 KB arm64 ELF LOAD align: PASS
- Headless: `smoke_runner` + `smoke_stylized_fighters` PASS

## Character presentation (this build)

Seven procedural stylized fighters with faces, clothing, accessories, distinct proportions. Not unique hand-authored GLB art; visibly not proxy cubes/grey GLB mannequins.

## Still required for reviewer package / Pixel PASS

- Pixel install + full touch match evidence (device offline this session)
- 3-second silent clips and live recordings from device
- Performance numbers on Low/Medium/High

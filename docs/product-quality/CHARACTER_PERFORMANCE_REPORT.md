# Character Performance Report — Anime Aggressors

**Build:** `0.3.1` / versionCode `203`  
**APK:** `build/android/anime-aggressors-release.apk`  
**SHA-256:** `0828c6b003145bff38789be10f376ff6ed0b64bf065e1528ba844c4a30033768`  
**Device:** Pixel expected serial `27211JEGR06194` — **not attached** at measurement time (2026-07-15).

## Status

| Signal | Result |
| --- | --- |
| Signed non-debug APK produced from character-life branch | PASS |
| Package `com.gunnchos.animeaggressors` | PASS |
| 16 KB ELF LOAD alignment (arm64) | PASS |
| Pixel FPS / thermal / memory capture | **BLOCKED** — no device |
| Low / Medium / High quality presets exercised on device | **BLOCKED** — no device |

## Quality tiers (implemented / intended)

| Tier | Reductions | Preserved |
| --- | --- | --- |
| Low | Fewer particles, shadows off/soft, fewer dynamic lights, reduced secondary motion, lighter post | Silhouette, face readability, core anims, identity colors/accessories |
| Medium | Balanced particles + one key light | Full identity read |
| High | Full aura/VFX budget | Full identity + polish |

Wire to Settings → Graphics when Pixel validation is available. Until device numbers exist, do not claim FPS targets.

## Headless / workstation notes

- Stylized fighters are procedural meshes (capsules/spheres/cylinders) — cost should remain mobile-friendly vs unique high-poly GLBs.
- Full Pixel match profiling remains required before performance PASS.

## Next measurement checklist (when Pixel reconnects)

1. Install current SHA APK; confirm no compatibility / debuggable warnings.
2. 60s idle title, 60s fighter select, full touch match.
3. Record avg/min FPS, frame-time spikes, memory, load time, thermal, draw calls if available.
4. Repeat on Low / Medium / High.
5. Attach captures under `docs/product-quality/evidence/pixel-performance/`.

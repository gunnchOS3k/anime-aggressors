# Acceptance Checklist — Anime Aggressors

**Device:** Pixel 6a `27211JEGR06194`  
**Branch:** `cursor/product-quality-mobile-pass`  
**Date:** 2026-07-13

## Gates

| Gate | Status |
|------|--------|
| Startup / title screen | **Partial** — boot scene updated; not device-recorded |
| Full menu navigation | **Not verified on Pixel** |
| Match flow end-to-end | **Not verified this pass** |
| WEB_TO_GODOT_PARITY_MATRIX | **Created** — critical gaps remain |
| Release APK on disk | **Missing** — prior APKs cleaned; rebuild blocked by disk |
| 16 KB compatibility | **Not passed** — Godot 4.3 warning expected |
| Screen recording | **Not captured** |
| PR ready | **No** |

## Automated tests run

- Godot `smoke_runner.gd`: boot, release_mode, fighter_scene, training_scene, battle_scene **OK**; data_load **FAIL** (pre-existing move list gaps)

## Evidence paths

- Matrix: `docs/product-quality/WEB_TO_GODOT_PARITY_MATRIX.md`
- Plan: `../PRODUCT_QUALITY_COMPLETION_PLAN.md`

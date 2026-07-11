# Production Readiness Report

**Branch:** `cursor/continue-codex-production-hardening`  
**Date:** 2026-07-11  
**Status:** Playable vertical slice (web + Godot); Android blocked

## Before continuation

- Godot shipping tree at `game-godot/` with 2D platform fighter combat
- Web shell and TypeScript simulation packages
- Unity spike and deprecated trees documented

## Codex additions (uncommitted on main)

- Seven Blender blockout GLBs + manifest (proxy tier)
- `fighter_model_3d.gd` SubViewport 3D presentation path
- Character validation pipeline, mobile-check, Android export scripts
- Fighter data and production spec updates

## Verified

- `npm test` — character assets + aa-verify-project
- `npm build` — web + packages
- `npm run mobile:check` — after Cursor relaxed Gradle-only SDK assertion
- Seven fighters × 19 clips in manifest

## Cursor changes

- GDScript: `_fighter` rename (avoid Node.owner conflict), type annotations
- `docs/CODEX_CONTINUATION_AUDIT.md`, `CHARACTER_ORIGINALITY_MATRIX.md`
- `npm run verify` script
- Export preset `package/signed=false` for debug path

## Device test

- Android APK not produced — Godot export configuration errors
- Pixel 6a unauthorized / disconnected during session

## Remaining blockers

- Godot Android export validation (empty error list)
- USB device authorization
- Proxy 3D art tier — not production character models
- Full combat aura differentiation needs playtesting

## Honest classification

**Playable vertical slice** — web and Godot desktop paths; mobile install blocked.

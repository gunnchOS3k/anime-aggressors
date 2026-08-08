# PR #48 Verification Report

**Generated:** 2026-08-08T00:18:21.277Z

**Commit:** `7a3789264c0a45215d2d38446654313bd87ab18b`

## Verification tiers

| Tier | Status |
|------|--------|
| Automated npm | verified |
| Godot CLI | verified |
| Godot editor playtest | manual_signoff_required |
| Proxy functional | partial |
| Final art | blocked |

## NPM gates

| Step | Status |
|------|--------|
| validate:full-scope-production | pass |
| typecheck | pass |
| test:workspaces | pass |
| build | pass |

## Godot CLI

| Field | Value |
|-------|-------|
| Detected | true |
| Binary | /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot |
| Version | 4.5.stable.official.876b29033 |
| Headless import | pass |
| Smoke runner | pass |



## Manual signoff required

**Yes** — complete `docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md` and save a filled copy under `docs/manual-playtests/`.

## Remaining blockers

- P1: Signed Godot editor playtest (docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md)
- P1: Final authored .glb fighter art
- P1: Final authored animation clips
- P2: Final SFX/VFX polish
- P2: CPU balance/tuning
- P2: Export hardening
- P3: Full ledge grab, rollback/netplay

## JSON report

`tmp/aa-verify-project-report.json`

## No full-completion claim

Ship-ready status requires signed editor playtest evidence and final authored assets.

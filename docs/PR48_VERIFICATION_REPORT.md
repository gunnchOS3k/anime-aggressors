# PR #48 Verification Report

**Generated:** 2026-07-11T19:16:48.927Z

**Commit:** `668eabf06b0b13632851467ba8d62ecbcfaaa95a`

## Verification tiers

| Tier | Status |
|------|--------|
| Automated npm | verified |
| Godot CLI | failed |
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
| Binary | /tmp/godot/4.3/Godot.app/Contents/MacOS/Godot |
| Version | 4.3.stable.official.77dcf97d8 |
| Headless import | pass |
| Smoke runner | fail |



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

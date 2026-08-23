# Pixel 6a Owner Visual Review — Anime Aggressors Wave015

**Status:** Pending Edmund review. Cursor does **not** approve visual quality or fun.

**Device:** Pixel 6a (physical USB, not emulator)  
**Baseline SHA:** `706aba63274c9b563dfc34e76502d78a7cac19a9` (accepted main after PR #84)  
**Evidence:** `artifacts/engineering_wave015/`

---

## Owner checklist (Edmund only — leave unchecked until reviewed)

- [ ] Procedural roster models read as distinct fighters on-device (not flat placeholders)
- [ ] Toon shading / materials acceptable for Digital RC on Pixel 6a display
- [ ] Animation playback smooth enough for engineering acceptance (not final art sign-off)
- [ ] BattleScene layout readable at 1080×2400 with touch controls
- [ ] RosterArtLab and AnimationLab reflect canonical runtime (not a second runtime)
- [ ] No blocking visual defects (missing models, T-pose lock, shader pink, invisible fighters)
- [ ] Install / launch / resume behavior acceptable for field-kit calibration handoff
- [ ] Screenshot packet (`artifacts/engineering_wave015/device_screenshots/`) reviewed
- [ ] Willing to mark `HUMAN_ART_DIRECTION_APPROVAL` separately (not part of Wave015 objective gate)

---

## What Cursor validated (objective only)

- Authorized Pixel 6a via `adb` (model `Pixel 6a`, not emulator)
- Debug APK built from `game-godot/` export preset
- Clean install, launch, 30s process survival, logcat fatal scan
- Roster model matrix (7 fighters) and action matrix (16×7 observations) via on-device harness
- Performance / thermal / battery / input / lifecycle / accessibility baselines captured

## What Cursor did **not** validate

- Art direction quality, fun, or play balance
- Human playtest completeness
- RF / field-kit calibration (separate field-kit wave)

---

## Notes for reviewer

Screenshots are device-captured (`PHYSICAL_PIXEL6A_SCREENSHOT`). Serial numbers are redacted in JSON artifacts. Merge authority: Edmund only.

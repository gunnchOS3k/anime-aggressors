# WAVE020 Visible Progress Checkpoints

Edmund sole merge authority. Shell ≠ working. Desktop evidence below; Pixel early gate requires authorized `adb`.

## CHECKPOINT 0 — Fighter Select restored

- **Status:** COMPLETE (desktop)
- **Source SHA:** `4d42466` on `eng/wave020-stop-the-line-fighter-select` (PR #93 tip; also on `origin/main` via merge `b8c4ada`)
- **What visibly changed:** Fighter Select script attaches again; 7 roster tiles, P1/P2 names, detail text, and preview bodies populate (no longer static `.tscn` shell only)
- **Canonical path tested:** `make wave020-fighter-select-diagnostic` (`WAVE020_SLICE_MODE=baseline`)
- **Evidence:** `artifacts/engineering_wave020/OWNER_REG_009_DIAGNOSTIC_RESULT.json`, `FIGHTER_SELECT_FIRST_FAILURE.json`, `FIGHTER_SELECT_REGRESSION_DIFF_AUDIT.json`
- **Regressions run:** OWNER-REG-009 PASS
- **Known remaining debt:** Pixel physical seal blocked on USB authorization (see Pixel early gate)

## CHECKPOINT 1 — Seven-selection bug fixed

- **Status:** COMPLETE (desktop)
- **Canonical path:** fresh model host → fighters 1–7 → reverse → wrap → random → battle handoff
- **Evidence:** `OWNER_REG_008_DIAGNOSTIC_RESULT.json` (`OWNER_REG_008=PASS`, ghosts=0)
- **Distinct from REG-009:** REG-009 was parse/unload of entire select script; REG-008 is browse/cliff visibility on a live preview host

## CHECKPOINT 2 — Dynamic framing active

- **Status:** HOLD — not advanced this continuation (Pixel early gate not green)
- **Prior desktop Slice A:** COMPLETE on prior tip; retest deferred until Pixel early Fighter Select PASS

## CHECKPOINT 3 — Showcase flourish active

- **Status:** HOLD — not advanced this continuation
- **Repair note retained:** Motion shake uses `Input.get_accelerometer()` — Godot 4 has no `InputEventAccelerometer`
- **OWNER-REG-010:** optional sensor invariant PASS (poll + ZERO short-circuit; does not block init)

## CHECKPOINT 4 — Pause + Move List active

- **Status:** HOLD — not advanced this continuation

## CHECKPOINT 5 — Elemental audio active

- **Status:** HOLD — not advanced this continuation

## Pixel early physical gate

- **Status:** BLOCKED_OWNER_USB_AUTHORIZATION
- **PIXEL_UNBLOCK_STATUS:** BLOCKED_OWNER_USB_AUTHORIZATION
- **ADB:** `/opt/homebrew/bin/adb` — Android Debug Bridge 1.0.41 (37.0.1-15733141)
- **Device:** `27211JEGR06194` Pixel 6a — observed briefly as `device`, then `unauthorized` after kill/start and during install
- **APK rebuilt:** `builds/android/anime-aggressors-debug.apk` SHA256 `957209eac6d33f055ae60ac86c119cc7383e786bfb42f4e405471365c962a172`
- **Required owner action:** Unlock Pixel, accept **Allow USB debugging** (Always allow from this computer), then:
  `WAVE020_FORCE_APK_REBUILD=0 python3 tools/engineering_wave020/run_pixel_early_fighter_select_gate.py`
- **STOP rule:** Do not claim Pixel PASS; do not run framing/flourish/pause/audio/acceptance/soak until early gate is green
- **Evidence:** `artifacts/engineering_wave020/PIXEL_EARLY_FIGHTER_SELECT_GATE.json`, `CONTINUATION_WORKTREE_SNAPSHOT.txt`

# WAVE020 Visible Progress Checkpoints

Edmund sole merge authority. Shell ≠ working. Desktop evidence below; Pixel early gate requires authorized `adb`.

## CHECKPOINT 0 — Fighter Select restored

- **Status:** COMPLETE (desktop)
- **Source SHA (repair tip, uncommitted until Edmund confirms):** local working tree on `eng/wave020-revised-showcase-framing-flourish` @ `c80befd` + STOP_THE_LINE edits
- **What visibly changed:** Fighter Select script attaches again; 7 roster tiles, P1/P2 names, detail text, and preview bodies populate (no longer static `.tscn` shell only)
- **Canonical path tested:** `make wave020-fighter-select-diagnostic` (`WAVE020_SLICE_MODE=baseline`)
- **Evidence:** `artifacts/engineering_wave020/OWNER_REG_009_DIAGNOSTIC_RESULT.json`, `FIGHTER_SELECT_FIRST_FAILURE.json`, `FIGHTER_SELECT_REGRESSION_DIFF_AUDIT.json`
- **Regressions run:** OWNER-REG-009 PASS
- **Known remaining debt:** Headless GPU cannot emit PNG captures; Pixel early gate blocked on `adb unauthorized`

## CHECKPOINT 1 — Seven-selection bug fixed

- **Status:** COMPLETE (desktop)
- **Canonical path:** fresh model host → fighters 1–7 → reverse → wrap → random → battle handoff
- **Evidence:** `OWNER_REG_008_DIAGNOSTIC_RESULT.json` (`OWNER_REG_008=PASS`, ghosts=0)
- **Distinct from REG-009:** REG-009 was parse/unload of entire select script; REG-008 is browse/cliff visibility on a live preview host

## CHECKPOINT 2 — Dynamic framing active

- **Status:** COMPLETE (desktop Slice A)
- **Gate:** `Wave020PresentationGates.dynamic_framing_enabled=true` after Slice A retest
- **Retests:** OWNER-REG-009 + OWNER-REG-008 PASS with `WAVE020_SLICE_MODE=a`
- **Debt:** Owner framing taste still PENDING; uncommitted head/feet refit retained

## CHECKPOINT 3 — Showcase flourish active

- **Status:** COMPLETE (desktop Slice B)
- **Gate:** `showcase_flourish_enabled=true`
- **Retests:** REG-009/008 PASS; `make wave020-select-flourish-diagnostic` PASS (7 fighters, 0 visibility regressions)
- **Repair note:** Motion shake uses `Input.get_accelerometer()` — Godot 4 has no `InputEventAccelerometer`

## CHECKPOINT 4 — Pause + Move List active

- **Status:** COMPLETE (desktop Slice C)
- **Evidence:** `make wave020-pause-diagnostic` PASS (42 move previews / 7 fighters)

## CHECKPOINT 5 — Elemental audio active

- **Status:** COMPLETE (desktop Slice D)
- **Evidence:** `make wave020-audio-diagnostic` PASS (7 elemental identities, 0 collisions)
- **Debt:** `PIXEL_AUDIO_RUNTIME_PASS` not re-proven on this tip (Pixel unauthorized)

## Pixel early physical gate

- **Status:** BLOCKED — device `27211JEGR06194` reports `unauthorized` after APK rebuild
- **APK rebuilt:** `builds/android/anime-aggressors-debug.apk` (post-repair)
- **Required owner action:** Accept RSA authorization dialog on Pixel 6a, then re-run `python3 tools/engineering_wave020/run_pixel_early_fighter_select_gate.py`
- **STOP rule:** Do not claim Pixel PASS until early gate is green

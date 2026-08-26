# WAVE020 Visible Progress Checkpoints

Edmund sole merge authority. Shell ≠ working. Desktop + Pixel early gate evidence below.

## CHECKPOINT 0 — Fighter Select restored

- **Status:** COMPLETE (desktop + Pixel early gate)
- **Source SHA:** `4d42466` APK tip (PR #93 / merge `b8c4ada` lineage); Pixel gate tooling on continuation tip
- **What visibly changed:** Fighter Select script attaches again; 7 roster tiles, P1/P2 names, detail text, and preview bodies populate (no longer static `.tscn` shell only)
- **Canonical path tested:** `make wave020-fighter-select-diagnostic` (`WAVE020_SLICE_MODE=baseline`); Pixel `run_pixel_early_fighter_select_gate.py`
- **Evidence:** `artifacts/engineering_wave020/OWNER_REG_009_DIAGNOSTIC_RESULT.json`, `PIXEL_EARLY_FIGHTER_SELECT_GATE.json`, `pixel/early_01_fighter_select.png`
- **Regressions run:** OWNER-REG-009 PASS (desktop + Pixel early)
- **Known remaining debt:** Full 49-capture campaign / soak / CP2–5 still HOLD until ordered continuation

## CHECKPOINT 1 — Seven-selection bug fixed

- **Status:** COMPLETE (desktop + Pixel early gate)
- **Canonical path:** fresh model host → fighters 1–7 → reverse → wrap → random → battle handoff (desktop); Pixel early: roster taps 0–6 + OCR focus + leave-select into battle
- **Evidence:** `OWNER_REG_008_DIAGNOSTIC_RESULT.json`; Pixel `PIXEL_EARLY_FIGHTER_SELECT_GATE.json` (`PIXEL_OWNER_REG_008=PASS`, ghosts=0, `BROWSE_DISTINCT_FOCUS=6`, battle left Fighter Select)
- **Distinct from REG-009:** REG-009 was parse/unload of entire select script; REG-008 is browse/cliff visibility on a live preview host

## CHECKPOINT 2 — Dynamic framing active

- **Status:** HOLD — advance only after this Pixel early seal is on a draft PR tip
- **Prior desktop Slice A:** COMPLETE on prior tip; retest after CP0/1 Pixel seal

## CHECKPOINT 3 — Showcase flourish active

- **Status:** HOLD — not advanced this continuation
- **Repair note retained:** Motion shake uses `Input.get_accelerometer()` — Godot 4 has no `InputEventAccelerometer`
- **OWNER-REG-010:** optional sensor invariant PASS (poll + ZERO short-circuit; does not block init)

## CHECKPOINT 4 — Pause + Move List active

- **Status:** HOLD — not advanced this continuation

## CHECKPOINT 5 — Elemental audio active

- **Status:** HOLD — not advanced this continuation

## Pixel early physical gate

- **Status:** PASS (honest OCR gate)
- **PIXEL_UNBLOCK_STATUS:** UNBLOCKED — owner accepted USB debugging; serial `27211JEGR06194` Pixel 6a `device`
- **ADB:** `/opt/homebrew/bin/adb` — Android Debug Bridge 1.0.41 (do **not** `adb kill-server` unless necessary)
- **APK:** `builds/android/anime-aggressors-debug.apk` SHA256 `957209eac6d33f055ae60ac86c119cc7383e786bfb42f4e405471365c962a172`
- **PIXEL_SOURCE_SHA:** `4d42466`
- **PIXEL_EARLY_GATE / REG-009 / REG-008:** PASS / PASS / PASS
- **Nav lessons sealed in tooling:** Rulesets needs DPAD_DOWN→Confirm (ENTER alone stays on Stocks -); landscape 2400×1080 taps; OCR-locate **Next / Confirm** (not footer `[A] Confirm`); battle HUD may be under 55KB
- **False-green avoided:** byte-size-only and Rulesets-stuck captures no longer PASS
- **Evidence:** `artifacts/engineering_wave020/PIXEL_EARLY_FIGHTER_SELECT_GATE.json`, `pixel/early_01_fighter_select.png`, `pixel/early_A_select_*.png`, `pixel/early_C_battle.png`
- **Next:** draft Wave020 continuation PR with this seal → then CP2 framing only (no Wave021; Edmund merges)

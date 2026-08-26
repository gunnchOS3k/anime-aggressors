# WAVE020 Visible Progress Checkpoints

Edmund sole merge authority. Shell ≠ working. Desktop + Pixel early gate evidence below.

## CHECKPOINT 0 — Fighter Select restored

- **Status:** COMPLETE (desktop + Pixel early gate)
- **Source SHA:** `4d42466` APK tip (PR #93 / merge `b8c4ada` lineage); Pixel gate tooling on continuation tip
- **What visibly changed:** Fighter Select script attaches again; 7 roster tiles, P1/P2 names, detail text, and preview bodies populate (no longer static `.tscn` shell only)
- **Canonical path tested:** `make wave020-fighter-select-diagnostic` (`WAVE020_SLICE_MODE=baseline`); Pixel `run_pixel_early_fighter_select_gate.py`
- **Evidence:** `artifacts/engineering_wave020/OWNER_REG_009_DIAGNOSTIC_RESULT.json`, `PIXEL_EARLY_FIGHTER_SELECT_GATE.json`, `pixel/early_01_fighter_select.png`
- **Regressions run:** OWNER-REG-009 PASS (desktop + Pixel early)

## CHECKPOINT 1 — Seven-selection bug fixed

- **Status:** COMPLETE (desktop + Pixel early gate)
- **Canonical path:** fresh model host → fighters 1–7 → reverse → wrap → random → battle handoff (desktop); Pixel early: roster taps 0–6 + OCR focus + leave-select into battle
- **Evidence:** `OWNER_REG_008_DIAGNOSTIC_RESULT.json`; Pixel `PIXEL_EARLY_FIGHTER_SELECT_GATE.json` (`PIXEL_OWNER_REG_008=PASS`, ghosts=0, `BROWSE_DISTINCT_FOCUS=6`, battle left Fighter Select)
- **Distinct from REG-009:** REG-009 was parse/unload of entire select script; REG-008 is browse/cliff visibility on a live preview host

## CHECKPOINT 2 — Canonical fighter presentation + reliable battle bodies + responsive Pause/Move List

- **Status:** REOPENED — owner-visible Pixel contradiction (battle bodies + move preview)
- **CP2_SEALED:** false
- **SAFE_TO_START_CP3_FLOURISH:** false
- **SAFE_TO_START_CP5_ELEMENTAL_AUDIO:** false
- **Owner contradiction:** Vesper vs Kaia — HUD/labels/stage/timer visible, fighter bodies absent; Move Preview pane visible without clearly visible fighter
- **False-green root:** prior Pixel seal used `SCENE_TREE_VISIBLE` (`is_visible_renderable_body`) as body pass — not `FINAL_SCREEN_VISIBLE` framebuffer witness
- **OWNER-REG-014:** Render telemetry visible / final screen body absent
- **OWNER-REG-015:** Move Preview pane exists / preview visually empty
- **Repair in progress:** SubViewportContainer final compositor + final-screen opaque-pixel witness
- **Human approvals:** remain PENDING
- **Hold:** CP3 flourish / CP5 audio remain HOLD until CP2 re-sealed with owner-visible proof

## CHECKPOINT 3 — Showcase flourish active

- **Status:** HOLD — blocked until CP2 sealed
- **Repair note retained:** Motion shake uses `Input.get_accelerometer()` — Godot 4 has no `InputEventAccelerometer`
- **OWNER-REG-010:** optional sensor invariant PASS (poll + ZERO short-circuit; does not block init)

## CHECKPOINT 4 — Pause + Move List active

- **Status:** SUPERSEDED by CP2 layout integrity (desktop PASS; Pixel pending)

## CHECKPOINT 5 — Elemental audio active

- **Status:** HOLD — blocked until CP2 sealed

## Pixel early physical gate (CP0/CP1)

- **Status:** PASS (honest OCR gate) on tip `4d42466` APK; CP2 Pixel physical seal **reopened** on PR #94
- **PIXEL_UNBLOCK_STATUS:** UNBLOCKED — serial `27211JEGR06194` Pixel 6a
- **Evidence:** `artifacts/engineering_wave020/PIXEL_EARLY_FIGHTER_SELECT_GATE.json`; CP2 screen-witness reopen under `CP2_*SCREEN_WITNESS*` / `CP2_VESPER_KAIA_FIRST_FAILURE.json`
- **CP2 note:** Do not claim FINAL_SCREEN from SCENE_TREE-only. Prior `PIXEL_BATTLE_BODY_ZERO_SAMPLES=0` contradicted by owner-visible Pixel capture.

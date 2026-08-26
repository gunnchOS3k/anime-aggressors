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

- **Status:** PARTIAL (desktop repairs + diagnostics green; Pixel CP2 quick gates not yet re-run on rebuilt APK)
- **OWNER-REG-011:** Select cards now bake canonical `FighterModel3D` portraits (`fighter_card_portrait.gd`); resolver rejects `procedural_final` / proxy paths for player builds
- **OWNER-REG-012:** Battle prefers Model3D heal/reconfigure; ColorRect counted as `LEGACY_FALLBACK_USES`; `make wave020-battle-body-diagnostic` PASS (28/28 samples, zero/legacy/wrong=0)
- **OWNER-REG-013:** Move List + Pause centered via `CenterContainer` + viewport-relative size; `make wave020-pause-layout-diagnostic` PASS (`MOVELIST_CLIPPED_CASES=0`)
- **Canonical authority:** `FighterAssetResolver.resolve_presentation(fighter_id, context)`
- **Evidence:** `FIGHTER_REPRESENTATION_PATH_AUDIT.json`, `BATTLE_BODY_DIAGNOSTIC_RESULT.json`, `PAUSE_LAYOUT_DIAGNOSTIC_RESULT.json`, `CP2_VISIBLE_PRODUCT_REPAIR_SNAPSHOT.txt`
- **Hold:** Pixel Gates 1–3 + owner visual approval; CP3 flourish / CP5 audio remain HOLD until CP2 sealed

## CHECKPOINT 3 — Showcase flourish active

- **Status:** HOLD — blocked until CP2 sealed
- **Repair note retained:** Motion shake uses `Input.get_accelerometer()` — Godot 4 has no `InputEventAccelerometer`
- **OWNER-REG-010:** optional sensor invariant PASS (poll + ZERO short-circuit; does not block init)

## CHECKPOINT 4 — Pause + Move List active

- **Status:** SUPERSEDED by CP2 layout integrity (desktop PASS; Pixel pending)

## CHECKPOINT 5 — Elemental audio active

- **Status:** HOLD — blocked until CP2 sealed

## Pixel early physical gate (CP0/CP1)

- **Status:** PASS (honest OCR gate) on tip `4d42466` APK
- **PIXEL_UNBLOCK_STATUS:** UNBLOCKED — serial `27211JEGR06194` Pixel 6a
- **Evidence:** `artifacts/engineering_wave020/PIXEL_EARLY_FIGHTER_SELECT_GATE.json`
- **CP2 note:** Re-run Pixel Gates 1–3 after APK rebuild containing card/portrait + pause layout changes before claiming CP2_SEALED

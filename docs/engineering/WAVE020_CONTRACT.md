# WAVE020 Engineering Contract — Visibility + Showcase Flourish + Dynamic Framing + Pause + Audio

**Wave:** WAVE020 REVISED  
**Branch:** `eng/wave020-revised-showcase-framing-flourish`  
**Accepted-main prerequisite:** PR #91 MERGED (`c80aae11c07126e0f0e81f660e6608ca6925fdd4`)  
**Merge authority:** Edmund only — Cursor never merges  
**Do not start:** Wave021  
**Do not claim:** final art / final animation / human taste approval from automation  

---

## 1. OWNER OUTCOME

A) **OWNER-REG-008 seven-selection visibility cliff (P0)** — Fresh select → browse fighters 1–7; each shows exactly one visible preview body; confirm fighter 7 → battle shows both bodies visible. Ghost = `expected_visible && active && visible_renderable_mesh_count==0`.

B) **Dynamic preview framing** — Per-fighter camera from model bounds + padding + VFX envelope; head/feet readable; no systematic midsection crop.

C) **Character-select showcase flourish** — Fighter-specific flourish on motion (Pixel shake, controller motion where supported) with universal keyboard/controller-button/touch fallback; `Motion Gestures: ON/OFF` setting.

D) **Universal pause + move list** — Mid-match pause on Pixel touch (II affordance), keyboard, controller; Move List SIMPLE/ADVANCED; training unified.

E) **Elemental audio identity** — 7/7 distinct charge/projectile/signature procedural audio; flourish uses fighter sound grammar.

Preserve Wave016–019 roster identity uplift. Do not revert to generic placeholders.

---

## 2. CANONICAL PLAYER PATHS

### Path A — OWNER-REG-008 fast regression
Fresh select → fighters 1–7 preview visible → confirm #7 → battle both bodies visible. Also reverse, wraparound, random, select/back/select.

### Path B — Dynamic framing
Each fighter preview shows head, silhouette, feet where appropriate; framing differs by proportion (Rook ≠ Juno crop).

### Path C — Showcase flourish
Hover → subtle idle/aura → trigger (shake/controller/keyboard/touch) → fighter-specific VFX+audio → idle. Motion OFF disables shake only; fallback always available.

### Path D — Pause + move list
Versus + training: pause → Move List → preview → resume without corruption.

### Path E — Elemental audio
Per fighter: charge, projectile, signature mapped to fighter WAV bank.

### Path F — Pixel physical (AA-only)
Phases A (OWNER-REG-008) → B (adversarial) → C (acceptance 7 fighters) → D (soak ≥10 min). Target 49 owner-review captures (7×7 states).

---

## 3. FAILURE CONDITIONS

1. PR #91 baseline reverted or Wave016–019 regressions broken.
2. OWNER-REG-008 fails in diagnostic mode.
3. Select or battle render ghosts > 0 at merge gate.
4. Systematic head/feet clip or midsection-only crop on any fighter.
5. Flourish wrong-fighter, stuck state, visibility regression, or battle-handoff regression > 0.
6. Motion-only flourish path (no fallback).
7. Pause relies on BACK-only on mobile.
8. Generic audio shared across fighters without identity.
9. Pixel unavailable and merge-ready claimed.
10. Pixel ghosts/deaths/fatal/ANR/OOM > 0.
11. Long campaign run after known diagnostic failure.
12. Cursor merges the PR.

---

## 4. FORBIDDEN PROOFS

| Shortcut | Why forbidden |
|----------|----------------|
| Asset file exists | Not runtime visibility |
| Harness-only heal | Not player path |
| Desktop-only for Pixel gate | BLOCKED_PIXEL6A |
| Single screenshot | Not 7-fighter sweep |
| taste-gate green alone | Not Edmund taste |
| Silent fallback masking ghost | Must count invariant violation |

---

## 5. PRE-MORTEM

| # | False-PASS | Adversarial catch |
|---|------------|-------------------|
| 1 | Preview OK for 6, fails on 7 | OWNER-REG-008 sequential 1–7 |
| 2 | Heal hides ghost | Fail if recovery after ghost without fix |
| 3 | Shared camera crop | Per-fighter framing artifact |
| 4 | One flourish VFX for all | Per-fighter flourish counters |
| 5 | Shake-only flourish | Fallback input required |
| 6 | BACK-only pause | Touch II + controller pass |
| 7 | Shared audio hash | Identity collision check |
| 8 | Long soak finds P0 | Diagnostic fail-fast first |
| 9 | Launcher tap in Pixel | AA-only foreground guards |
| 10 | Mid-flourish select corrupts battle | Handoff regression test |

---

## 6. OWNER REGRESSION MEMORY

Wave020 adds **OWNER-REG-008** (seven-selection visibility cliff). Preserves OWNER-REG-001–007. See `docs/quality/OWNER_REGRESSION_MEMORY.md`.

---

## 7. DIAGNOSTIC TESTS

Repo-native fail-fast commands (non-zero on failure):

```text
make wave020-visibility-diagnostic
make wave020-select-flourish-diagnostic
make wave020-pause-diagnostic
make wave020-audio-diagnostic
```

Diagnostic: short, verbose, stop on first failure, capture transition index + preview telemetry.

---

## 8. ADVERSARIAL REPAIR TESTS

After fix: 50–100 hostile transitions — rapid forward/reverse/wraparound/random, confirm/back mid-transition, select→battle after stress, battle→select→battle, flourish mid-switch.

If failure: STOP, fix, repeat. Do not run acceptance until green.

---

## 9. ACCEPTANCE CAMPAIGN

Only after diagnostic + adversarial green. Minimums:

- ≥500 select transitions
- ≥100 roster sweeps
- ≥100 random reselections
- ≥50 confirm/back cycles
- ≥100 select→battle launches

---

## 10. PIXEL GATE

Pixel 6a required for merge-ready. AA-only: `com.gunnchos.animeaggressors` via `am start -n`; no monkey; no Settings UI; `pm grant` permissions; foreground check before input.

Phases: A diagnostic OWNER-REG-008 → B adversarial → C acceptance (7 fighters) → D soak ≥10 min.

If unavailable: `WAVE020=BLOCKED_PIXEL6A`, `READY_FOR_OWNER_MERGE=false`.

---

## 11. SOAK GATE

≥10 minute mixed-roster soak LAST. Tracks process death, ANR, OOM, fatal, long-lived corruption.

---

## 12. HUMAN TASTE GATE

`docs/quality/WAVE020_OWNER_REVIEW_PACKET.md` — blank ratings per fighter and category. Cursor must not self-score. `OWNER_TASTE_REVIEW=PENDING`.

---

## 13. CLAIM BOUNDARY

**Must remain false:** `FINAL_CHARACTER_ART_PASS`, `FINAL_HUMAN_AUTHORED_ANIMATION_PASS`, `FINAL_SOUND_DESIGN_PASS`, `HUMAN_ART_DIRECTION_APPROVAL`, `HUMAN_PLAYTEST_COMPLETE`, `HUMAN_Q3_ROSTER_APPROVAL`, `SHIPPING_PRODUCT`, `STORE_APPROVED`, `CONSOLE_CERTIFIED`.

**May report:** diagnostic/adversarial/acceptance PASS, Pixel physical PASS, `AUTOMATED_READINESS`. `CURSOR_MERGED_NOTHING=true`.

---

## 14. STOP CONDITIONS

1. ONE draft PR on `eng/wave020-revised-showcase-framing-flourish`.
2. STOP after draft PR — wait for Edmund.
3. Do not start Wave021.
4. Do not merge.
5. Do not continue long campaigns after diagnostic failure.
6. Contract written before production code (this file).

---

*Contract written before production implementation per Wave020 REVISED critical order.*

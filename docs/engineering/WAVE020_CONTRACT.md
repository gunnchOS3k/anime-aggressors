# WAVE020 Engineering Contract — Character Visibility + Pause Move List + Elemental Audio

**Wave:** WAVE020  
**Branch:** `eng/wave020-character-visibility-pause-movelist-and-elemental-audio`  
**Accepted-main prerequisite:** PR #90 MERGED (`c59211282b17630d4c1345650fe2f76c69e321ba`)  
**Merge authority:** Edmund only — Cursor never merges  
**Do not start:** Wave021  
**Do not claim:** final art / final animation / human approval from automation  

---

## 1. OWNER OUTCOME (P0)

A) **Character visibility** — After browsing all seven fighters, select preview and battle body remain visible. Ghost = `expected_visible && active && visible_renderable_mesh_count==0`.

B) **Universal pause + move list** — Mid-match pause works on Pixel touch, keyboard, controller/Android back. Move list reachable from pause in versus and training.

C) **Elemental audio identity** — All seven fighters have distinct procedural charge, projectile, and signature audio aligned to element (fire/electric/wind/frost/gravity/shadow/earth).

Preserve Wave016–019 roster identity uplift. Do not revert to generic placeholders.

---

## 2. CANONICAL PATHS

### Path A — Select preview visibility stress
Cycle fighters 1→7 repeatedly; confirm preview body every browse; no ghost after 6+ browses.

### Path B — Select → battle continuity
Each fighter launches battle with visible body (not nameplate-only).

### Path C — Pause + move list
Versus + training: pause (Esc/back/touch II) → Move List → SIMPLE/ADVANCED → resume without corruption.

### Path D — Elemental audio smoke
Per fighter: charge/aura, projectile, signature/burst mapped to fighter WAV bank (not shared generic).

---

## 3. ARTIFACTS

| Artifact | Purpose |
|----------|---------|
| `artifacts/engineering_wave020/WAVE020_RESULT.json` | Aggregate gate |
| `artifacts/engineering_wave020/VISIBILITY_ROOT_CAUSE_ANALYSIS.json` | RCA |
| `artifacts/engineering_wave020/ELEMENTAL_AUDIO_IDENTITY_RESULT.json` | Audio identity |
| `artifacts/engineering_wave020/PIXEL_CAMPAIGN.json` | Pixel evidence |
| `docs/quality/WAVE020_OWNER_REVIEW_PACKET.md` | Blank owner ratings |

---

## 4. REGRESSIONS

Wave016–019 harnesses must remain green on final head. `NEW_S0=0`, `NEW_S1=0`. CI reported SUCCESS only when GitHub checks green on exact final head.

### Pixel AA-only guard policy

All Wave020 Pixel tooling MUST:
- Launch only `com.gunnchos.animeaggressors` via `am start -n <component>` (no `monkey`).
- Refuse `input tap` / `keyevent` unless AA is foreground (dumpsys window focus).
- If BACK lands on launcher, relaunch AA before any further input — never tap launcher icons.
- Force-stop sibling packages if they steal focus (Pedestrian Pursuit, Beatlink, etc.).

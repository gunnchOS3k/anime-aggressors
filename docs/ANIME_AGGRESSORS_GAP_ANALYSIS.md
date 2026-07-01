# Anime Aggressors — Gap Analysis

**Status:** Post–PR #36 baseline  
**Last updated:** 2026-06-24  
**Related:** [Platform fighter requirements](./PLATFORM_FIGHTER_REQUIREMENTS.md) · [MVP DoD](./MVP_DEFINITION_OF_DONE.md) · [Playable vertical slice audit](./PLAYABLE_VERTICAL_SLICE_AUDIT.md)

---

## 1. Current status after PR #36

PR [#36](https://github.com/gunnchOS3k/anime-aggressors/pull/36) (`fix/playable-vertical-slice`) improves the project but **does not** make it a full platform fighter.

### Improved

| Area | Evidence |
|------|----------|
| Quick Match path | `quickMatch.ts`, home primary CTA → `#/battle` |
| Consistent controls | `inputProfiles.ts`, `controlReference.ts`, H overlay |
| Fullscreen battle | `.app-root--battle`, responsive viewport |
| Platform landing | `stageCollision.ts`, side/main platforms |
| Single-hit-per-move | `hitVictimsThisMove`, `hitResolution.ts` |
| Playtest checklist | `docs/PLAYTEST_CHECKLIST.md` |
| Regression tests | `stageCollision.test.ts`, `singleHitPerMove.test.ts`, `playerInputMapping.test.ts` |

### Still not product-grade

- No frozen requirement set (addressed by Milestone 0 docs)
- No complete fighter controller spec
- No real move taxonomy (Smash-style grammar)
- No finished character design → gameplay pipeline
- No polished animation system
- No complete movement vocabulary (ledges, drop-through, landing lag, etc.)
- No DI, SDI, parry, shield break, stale moves, grab/throw loop
- No CPU suitable for normal solo play
- No complete training lab
- No polished stage select / legal variants
- No item system
- No production audio/VFX pass
- No balance sheet
- No accessibility pass
- **No recorded manual playtest evidence** that combat feels good

---

## 2. Gap scorecard

| Area | Current status | Gap severity |
|------|----------------|--------------|
| Quick playable path | Partial | Medium |
| Core match rules | Partial | Medium |
| Movement feel | Early | **Critical** |
| Platform collision | Early partial | High |
| Ledges / recovery | Missing | **Critical** |
| Combat grammar | Early partial | **Critical** |
| Fighter roster | Early / prototype | **Critical** |
| Stage select / polish | Partial | High |
| Camera | Partial | High |
| CPU opponents | Missing / unclear | High |
| Training mode | Partial | Medium-high |
| Controller support | Partial / unclear | High |
| UI hierarchy | Partial | High |
| Audio / VFX feel | Partial | Medium-high |
| Online / netplay | Future | Medium |
| Manual playtest evidence | Missing | **Critical** |

---

## 3. Recommended roadmap

### Milestone 0 — Requirements freeze ✅ (this pass)

**Deliver:**

- `docs/PLATFORM_FIGHTER_REQUIREMENTS.md`
- `docs/ANIME_AGGRESSORS_GAP_ANALYSIS.md` (this file)
- `docs/MVP_DEFINITION_OF_DONE.md`
- `docs/ENGINE_ARCHITECTURE.md`

**No new features.**

### Milestone 1 — Core engine truth

- Deterministic movement  
- Full platform collision (landing + drop-through)  
- Blast zones, respawn, match end  
- **Manual playtest proof** recorded in `docs/playtest/`

### Milestone 2 — Real fighter controller

- Dash, jump, double jump, fast fall, air drift  
- Ledge grab, recovery, landing lag  
- Input buffer (extend existing coyote/buffer)

### Milestone 3 — Combat grammar

- Complete move taxonomy  
- Frame data per move  
- Hitlag, hitstun, knockback, shields, grabs, throws, dodges, DI  
- Multi-hit support (flag on frame data)

### Milestone 4 — Four-fighter vertical slice

- 4 unique fighters (all-rounder, bruiser, rushdown, zoner)  
- 3 complete stages  
- Training mode  
- CPU levels 1–3  
- Local two-player gamepad

### Milestone 5 — Public demo

- Polished UI, audio/VFX pass  
- Web build on GitHub Pages  
- Playtest report, known issues, trailer checklist  

---

## 4. Risk register

| Risk | Mitigation |
|------|------------|
| Too many experimental modes confuse players | Labs panel; Quick Match as only hero CTA |
| Godot / Unreal / C++ tracks dilute web sim | `ENGINE_ARCHITECTURE.md` production boundary |
| Combat feels mushy without playtest proof | Block Milestone 1 merge on recorded playtest |
| Roster breadth without depth | Milestone 4 caps at 4 fighters until feel is proven |
| Docs drift from code | Link requirements to files + tests in each milestone PR |

---

## 5. What changed vs. older gap docs

`docs/GENRE_GAP_ANALYSIS.md` (2026-06) optimistically listed many systems as “present.” This document is **stricter**: it scores against an indie Smash-like **operational** bar, not feature checklist presence. Use this file for sprint planning; use `GENRE_GAP_ANALYSIS.md` for genre positioning only.

---

## 6. Next actions

1. Merge PR #36 (playable vertical slice).  
2. Merge Milestone 0 docs.  
3. Run `docs/PLAYTEST_CHECKLIST.md` on a fresh build; file results under `docs/playtest/`.  
4. Open Milestone 1 epic: movement + platform truth + playtest evidence.

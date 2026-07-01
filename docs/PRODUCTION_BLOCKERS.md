# Production Blockers — Anime Aggressors

**Status:** Living blocker registry  
**Last updated:** 2026-07-01  
**Audit branch:** `product/full-scope-godot-consolidation`  
**Primary runtime:** Godot 4 — `game-godot/`  
**Policy:** [RUNTIME_SOURCE_OF_TRUTH.md](./RUNTIME_SOURCE_OF_TRUTH.md)

---

## Full-scope implementation pass — open blockers (2026-07-01)

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BLK-FS001 | Godot editor playtest unsigned | P1 | Open |
| BLK-FS002 | Authored `.glb` / final animation clips not integrated | P1 | Open |
| BLK-FS003 | Final SFX/VFX polish | P2 | Open |
| BLK-FS004 | Tournament CPU/balance tuning | P2 | Open |
| BLK-FS005 | Web Godot export may lag editor build | P2 | Open |
| BLK-FS006 | Online/rollback/netplay | P3 | Open |
| BLK-FS007 | Full ledge grab (teeter baseline implemented) | P3 | Open |

**Resolved in PR #46:** grab/throw gameplay, 60 Hz move runner, CPU tiers, training tools, aura burst, edge teeter, validation hard gates.

**Resolved in PR #47:** hit resolution double-gate, aura charge ordering, hurt recovery, P2 inputs, debug overlay toggles.

**Completion claim:** Not allowed until BLK-FS001–FS002 resolved and full-scope manual playtest signed.

---

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BLK-G001 | Godot editor playtest not signed | P1 | Open |
| BLK-G002 | ~~Grab/throw loop placeholder only~~ | — | **Closed (PR #46)** |
| BLK-G003 | Hitbox uses Area2D overlap — needs hurtbox polish | P1 | Open |
| BLK-G004 | ~~CPU AI is minimal~~ | — | **Closed (PR #46 tiers)** |
| BLK-G005 | Authored fighter/stage art not integrated | P2 | Open |
| BLK-G006 | Web Godot export may lag `game-godot/` editor build | P2 | Open |
| BLK-G007 | Pause menu reloads battle scene (legacy route; in-battle pause in PR #46) | P2 | Open |
| BLK-G008 | PR #46 runtime bugs (hits/aura/hurt/P2/debug) | P0 | **Closed (PR #47)** |

### BLK-G001 — Godot manual playtest checklist unsigned

| Field | Value |
|-------|-------|
| **Severity** | P1 |
| **Discipline** | QA |
| **Status** | Open |

**Reproduction:** Open `docs/playtest/2026-07-01-godot-runtime-pivot-check.md` — all boxes unchecked.

**Expected:** Editor verification of boot → battle → results on target platform.

**Actual:** Automated validation only; no signed manual pass in this PR.

**Fix plan:** Run Godot 4 editor playtest; check boxes with evidence.

**Acceptance test:** Playtest doc signed; P0/P1 Godot blockers closed.

---

### BLK-G003 — Combat hit detection foundation incomplete

| Field | Value |
|-------|-------|
| **Severity** | P1 |
| **Discipline** | Engineering (Godot combat) |
| **Status** | Open |

**Reproduction:** Enter battle; attack overlapping opponent inconsistently.

**Expected:** Reliable hit confirmation, hitstun, knockback scaling with damage%.

**Actual:** Simplified Area2D overlap; no move frame data; shield blocks all damage.

**Fix plan:** Port move catalog hitboxes; hurtbox i-frames; hit freeze.

**Acceptance test:** 10 consecutive intentional hits land in training mode.

---

## Summary (legacy web — prior pass)

| Status | P0 | P1 | P2 | P3 | P4 |
|--------|----|----|----|----|-----|
| **Open (web)** | 0 | 0 | 6 | 8 | 5 |
| **Open (Godot)** | 0 | 2 | 5 | 0 | 0 |
| **Fixed (web pass)** | 3 | 0 | 0 | 0 | 0 |

**Completion claim:** Godot foundation PR — not full game complete. Allowed when Godot menu + battle loop verified and open Godot P0/P1 = 0.

---

## Fixed in this production pass

### BLK-001 — Movement scale too low (fighters barely move)

| Field | Value |
|-------|-------|
| **Severity** | P0 |
| **Discipline** | Engineering (gameplay feel) |
| **Status** | **Fixed** — 2026-07-01 |

**Affected files:**
- `packages/game-core/src/movement/movementTuning.ts`
- `packages/game-core/src/constants.ts` (legacy `RUN_SPEED` alias)
- `packages/game-core/src/movement/groundMovement.ts`
- `packages/game-core/src/movement/jumpSystem.ts`
- `packages/game-core/src/movement/airControl.ts`
- `packages/game-core/test/platformFighterMovementFeel.test.ts`
- `packages/game-core/test/productionCompletion.test.ts`

**Reproduction (before fix):**
1. Launch battle with default spawn (P1 ≈ x=800, P2 ≈ x=1600 display units).
2. Hold right on P1 for 60 seconds.
3. Observe crawl — ~12 u/s run speed; ~60+ s to cross 800 u gap.

**Expected:** Fighters move immediately; P1 reaches P2 in 2–4 seconds.

**Actual (before fix):** Run speed ~12 display units/sec; movement imperceptible relative to stage width (2400 u) and mesh scale.

**Root cause:** `MOVEMENT_BASE.runSpeed` was `(10.2 × FP_SCALE) / 60` ≈ 10.2 u/s — ~20× too slow for spawn geometry. Renderer `fpToWorld` was correct; sim tuning was wrong.

**Fix plan (executed):**
- Raised `MOVEMENT_BASE.runSpeed` to `(220 × FP_SCALE) / 60` (~220 u/s before size multipliers).
- Scaled dash, air drift, jump velocity proportionally.
- Documented unit contract in `movementTuning.ts` header.

**Acceptance test:**
- `platformFighterMovementFeel.test.ts` — 60 frames ≥ 100 display units; P1→P2 in 120–240 frames.
- `productionCompletion.test.ts` — movement feel suite passes.
- Manual: hold direction → visible motion within 0.25 s.

---

### BLK-002 — Navigation and product flow confusing / fragile

| Field | Value |
|-------|-------|
| **Severity** | P0 |
| **Discipline** | Engineering (UI/UX) |
| **Status** | **Fixed** — 2026-07-01 |

**Affected files:**
- `apps/web/src/screens/homeScreenMarkup.ts`
- `apps/web/src/navigation/modeRouteMap.ts`
- `apps/web/src/navigation/modeFlow.ts`
- `apps/web/src/match/quickMatch.ts` (`resetGameState`)
- `apps/web/src/match/matchSetupSession.ts`
- `apps/web/src/routes.ts`
- `apps/web/src/main.ts`
- `apps/web/test/productionNavigation.test.ts`

**Reproduction (before fix):**
1. Corrupt `localStorage` key `anime-aggressors.activeMatchSetup` with invalid JSON.
2. Attempt Quick Play or Start Game.
3. Observe broken battle launch or dead-end.

Alternatively: Labs entries mixed with main carousel; unclear path Home → Fighter → Stage → Battle.

**Expected:**
- Home shows Start Game, Quick Play, Training, Controls, About.
- Start Game: Fighter Select → Stage Select → Ready → Battle.
- Labs clearly separated from main carousel.
- Corrupt setup recovers via Reset Game State.

**Actual (before fix):** Stale localStorage could break launch; Labs mixed with core path; multiple overlapping entry points.

**Fix plan (executed):**
- Canonical `MODE_ROUTE_MAP.startMatch` flow enforced.
- `resetGameState()` clears bad localStorage and restores valid default setup.
- Labs moved to `menu-labs` section, not main carousel.
- Route tests for Home, training, controls, about.

**Acceptance test:**
- `productionNavigation.test.ts` — all navigation assertions green.
- Manual: fresh load → Start Game → complete match → Home; corrupt localStorage → Reset → battle works.

---

### BLK-003 — CPU levels not discoverable in UI

| Field | Value |
|-------|-------|
| **Severity** | P0 |
| **Discipline** | Engineering (UI) + Gameplay design |
| **Status** | **Fixed** — 2026-07-01 |

**Affected files:**
- `apps/web/src/screens/MatchSetupControlsScreen.ts`
- `apps/web/src/match/matchSetupSession.ts`
- `apps/web/src/game/App.ts` (HUD CPU label, `cpuOpponents` wiring)
- `packages/game-core/src/bots/versusCpu.ts`
- `packages/game-core/test/productionCompletion.test.ts`

**Reproduction (before fix):**
1. Attempt to start 1v1 vs CPU level 2 or 3 from match setup.
2. Observe no CPU toggle/level picker; only Training dummy mode 4 exposed Lv1.

**Expected:** CPU toggle on P2 slot; levels 1–3 selectable; HUD shows `CPU Lv{N}`.

**Actual (before fix):** `cpuLevel` and `isBot` existed in session types but UI never set them; engine Lv2–3 unreachable without code injection.

**Fix plan (executed):**
- Added P2 Human/CPU radio and level dropdown (1–3) in `MatchSetupControlsScreen.ts`.
- Wired `cpuOpponents` from setup to `GameConfig` in `App.ts`.
- HUD displays CPU level when bot active.

**Acceptance test:**
- Manual: Match setup → P2 CPU Lv2 → battle → HUD shows `CPU Lv2`; CPU damages player within 20 s.
- `productionCompletion.test.ts` — CPU approaches and hits idle target.

---

### BLK-004 — Combat unreliable at point-blank (audit finding)

| Field | Value |
|-------|-------|
| **Severity** | P0 |
| **Discipline** | Engineering (combat) |
| **Status** | **Fixed** — 2026-07-01 (verified by test suite; movement fix also enabled approach hits) |

**Affected files:**
- `packages/game-core/src/combat/hitResolution.ts`
- `packages/game-core/src/moves/combatMoveData.ts`
- `packages/game-core/src/collision.ts`
- `packages/game-core/test/productionCompletion.test.ts`
- `packages/game-core/test/milestone3CombatGrammar.test.ts`

**Reproduction (before fix):**
1. Spawn fighters adjacent (35 u spacing in tests).
2. Execute neutral attack at active frame.
3. Sometimes no damage due to spacing + slow approach making live play feel whiff-heavy.

**Expected:** Point-blank neutral connects; approach + attack within 5 s; shield blocks; KO/rematch work.

**Actual (before fix):** Tests passed at forced spacing but live play failed due to movement scale + spacing; perceived as combat broken.

**Fix plan (executed):**
- Movement scale fix (BLK-001) enabled approach scripts.
- `productionCompletion.test.ts` added: point-blank hit, approach hit, shield block, KO/rematch.

**Acceptance test:**
- `productionCompletion.test.ts` — combat reliability suite green.
- Manual: close-range jab increases damage % on HUD.

---

## Open blockers — P2 (serious)

### BLK-101 — Mobile / touch controls not implemented

| Field | Value |
|-------|-------|
| **Severity** | P2 |
| **Discipline** | Engineering (input) + UI/UX |
| **Status** | **Open** |

**Affected files:**
- `apps/web/src/input/` (no touch module)
- `docs/KNOWN_ISSUES.md`
- `docs/DEPLOYMENT.md`

**Reproduction:**
1. Open game on iOS/Android browser.
2. Attempt to move/attack without external keyboard.

**Expected:** On-screen controls or responsive touch layout for casual mobile play.

**Actual:** Keyboard + gamepad only; mobile browsers untested for production quality.

**Fix plan:**
- Design touch layout (virtual stick + action buttons).
- Implement touch → `InputFrame` mapper.
- Add mobile playtest checklist section.

**Acceptance test:** Complete training match on mobile Safari/Chrome without hardware keyboard.

---

### BLK-102 — 4-player couch blocked (P3/P4)

| Field | Value |
|-------|-------|
| **Severity** | P2 |
| **Discipline** | Engineering + Level design + UI/UX |
| **Status** | **Open** (documented out of scope for local 2P completion) |

**Affected files:**
- `apps/web/src/screens/ControlsScreen.ts` (ship-blocked message)
- `apps/web/src/input/deviceAssignment.ts` (`pollAllInputs` returns 2 frames)
- Camera/HUD in `apps/web/src/renderer-three/`

**Reproduction:**
1. Open Controls screen.
2. Attempt to assign P3/P4.

**Expected:** 4 players fight on one screen with readable camera/HUD.

**Actual:** P3/P4 slots locked; `pollAllInputs` max 2 players.

**Fix plan:**
- Spawn/camera/HUD pass for 3–4 fighters.
- Extend input polling to 4 `InputFrame`s.
- Unlock Controls slots after sim verification.

**Acceptance test:** 4P stock match completable with 4 gamepads; no off-screen unreadable fighters.

---

### BLK-103 — Preview fighters balance-pending

| Field | Value |
|-------|-------|
| **Severity** | P2 |
| **Discipline** | Gameplay design |
| **Status** | **Open** |

**Affected files:**
- `packages/game-core/src/fighterGameplayProfiles.ts` (`PREVIEW_FIGHTER_IDS`)
- `packages/game-core/src/moves/fighterMoveTuning.ts`
- `docs/fighters/nix-calder/`, `orion-vell/`, `vesper-nyx/`
- `apps/web/src/screens/DemoFighterSelectScreen.ts` (preview badges)

**Reproduction:**
1. Match production fighter vs Nix Calder, Orion Vell, or Vesper Nyx.
2. Compare neutral damage, recovery, projectile pressure.

**Expected:** All 7 fighters competitively viable for casual local play.

**Actual:** Preview trio mechanically valid but uneven vs production 4; Vesper projectile tuning flagged preview.

**Fix plan:**
- Balance pass on preview trio frame data and knockback.
- Update fighter specs with balance notes.
- Keep preview labels until sign-off.

**Acceptance test:** Design lead sign-off; win rate within ±15% across 20 casual matches vs production roster.

---

### BLK-104 — Procedural audio/VFX below production bar

| Field | Value |
|-------|-------|
| **Severity** | P2 |
| **Discipline** | Sound design + Art/VFX |
| **Status** | **Open** (acceptable for local functional game with documentation) |

**Affected files:**
- `apps/web/src/audio/AudioManager.ts`, `sfxCatalog.ts`, `CombatAudioEvents.ts`
- `apps/web/src/renderer-three/` VFX modules
- `docs/fighters/*/AUDIO_LIST.md`, `VFX_LIST.md`

**Reproduction:**
1. Play full match with audio enabled.
2. Compare feedback to `docs/fighters/*/VFX_LIST.md` spec.

**Expected:** Authored SFX/VFX per move and element.

**Actual:** Web Audio oscillators and geometry particles; dual audio paths (`globalAudio` + `combatAudioBus`).

**Fix plan:**
- Import minimum real SFX for hit/shield/KO/menu.
- Unify audio bus.
- Replace particle placeholders per art direction (post-web or engine spike).

**Acceptance test:** `apps/web/src/audio/README.md` ship gate passes; no oscillator-only combat in release build (v1.0 target).

---

### BLK-105 — Manual playtest not signed off

| Field | Value |
|-------|-------|
| **Severity** | P2 |
| **Discipline** | QA + Product |
| **Status** | **Open** |

**Affected files:**
- `docs/playtest/2026-07-01-full-game-completion-check.md` (if created)
- `docs/playtest/2026-07-01-m5-public-demo-readiness.md`

**Reproduction:**
1. Review playtest record.
2. Observe unchecked boxes and empty tester sign-off.

**Expected:** Named product owner completes full-game checklist on build artifact.

**Actual:** *Manual browser verification required by product owner.*

**Fix plan:**
- Product owner executes checklist on Pages deploy.
- File results; link from `PRODUCTION_COMPLETION_PLAN.md`.

**Acceptance test:** Signed playtest record with date, URL, pass/fail per section.

---

### BLK-106 — Keyboard P1/P2 overlap on single keyboard

| Field | Value |
|-------|-------|
| **Severity** | P2 |
| **Discipline** | Engineering (input) + UX |
| **Status** | **Open** (mitigated: gamepads recommended) |

**Affected files:**
- `apps/web/src/input/inputProfiles.ts`
- `apps/web/src/input/keyboard.ts`
- `docs/KNOWN_ISSUES.md`

**Reproduction:**
1. Two players share one keyboard.
2. Press overlapping keys (e.g. shared modifiers).

**Expected:** Clean 2P keyboard separation without ghost inputs.

**Actual:** Both profiles read same key state; some overlap possible.

**Fix plan:**
- Document gamepad recommendation (done).
- Optional: split keyboard mode with non-overlapping compact layouts.

**Acceptance test:** 2P keyboard match completable on standard QWERTY without stuck inputs; or gamepad path documented as primary.

---

## Open blockers — P3 (polish)

### BLK-201 — Training move list shows subset only

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | UI/UX + Gameplay design |
| **Status** | **Open** |

**Affected files:** `apps/web/src/game/App.ts` (`.slice(0, 6)`), `packages/game-core/src/training/trainingMode.ts` (`getFighterMoveList`)

**Reproduction:** Launch training → open move overlay → count moves shown.

**Expected:** Full fighter-specific move list (15+).

**Actual:** First 6 generic moves; `fighterId` ignored in move list helper.

**Fix plan:** Remove slice; wire `getFighterMoveList(fighterId)` per fighter.

**Acceptance test:** Ember Vale overlay lists all documented neutral/special/aerial entries.

---

### BLK-202 — Shield SFX fires on shield start, not only on block

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | Sound design |
| **Status** | **Open** |

**Affected files:** `apps/web/src/audio/`, combat event adapters

**Reproduction:** Hold shield without being hit → hear shield audio.

**Expected:** Shield audio only on successful block.

**Actual:** Audio may trigger on shield activation.

**Fix plan:** Gate `shield_hit` SFX on `resolveCombatHits` block event only.

**Acceptance test:** Shield hold silent; block produces SFX.

---

### BLK-203 — CPU not tournament-grade

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | Gameplay design + Engineering |
| **Status** | **Open** |

**Affected files:** `packages/game-core/src/bots/versusCpu.ts`

**Reproduction:** Play 10 matches vs CPU Lv3; observe repetitive patterns, edge-guard gaps.

**Expected:** Challenging casual opponent with recovery and mixups.

**Actual:** Functional approach/attack/recover; deterministic but shallow.

**Fix plan:** Expand decision tree, DI, edge-guard, spacing per difficulty.

**Acceptance test:** External playtester rates CPU Lv3 ≥ 3/5 challenge for casual player.

---

### BLK-204 — Gamepad requires button press before registration

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | Engineering (input) |
| **Status** | **Open** |

**Affected files:** `apps/web/src/input/gamepad.ts`, browser Gamepad API

**Reproduction:** Connect gamepad; load battle without pressing any button.

**Expected:** Gamepad active on connect.

**Actual:** Browser may not expose pad until first input (platform limitation).

**Fix plan:** On-screen “Press any button” prompt on Controls/battle entry when pad detected but unactivated.

**Acceptance test:** New user with gamepad reaches battle without reading docs.

---

### BLK-205 — Career / replay vault unpolished on core path

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | UI/UX |
| **Status** | **Open** |

**Affected files:** `apps/web/src/career/`, replay vault screens

**Reproduction:** Navigate to career or replay from menu.

**Expected:** Polished secondary modes or hidden from core path.

**Actual:** Reachable but not polished; not on golden path.

**Fix plan:** Move to Labs or complete UX pass.

**Acceptance test:** Core path has no dead-ends; secondary modes labeled beta.

---

### BLK-206 — Training dummy mode keys undocumented on mobile

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | UI/UX + Community |
| **Status** | **Open** |

**Affected files:** `apps/web/src/game/App.ts`, onboarding copy

**Reproduction:** Launch training without reading docs; press keys 1–4.

**Expected:** On-screen dummy mode selector.

**Actual:** Keyboard number keys only; not shown in onboarding.

**Fix plan:** Add training toolbar UI for dummy modes D/P/1–4.

**Acceptance test:** New user switches dummy modes without external docs.

---

### BLK-207 — Lab modes lack back-navigation polish

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | UI/UX |
| **Status** | **Open** |

**Affected files:** Labs screens under `apps/web/src/screens/`

**Reproduction:** Enter Godot/Flagline/Derby lab → attempt return to Home.

**Expected:** Consistent Back/Home on all lab screens.

**Actual:** Some labs lack polish (`KNOWN_ISSUES.md`).

**Fix plan:** Standardize lab chrome component with Home escape hatch.

**Acceptance test:** Any lab → Home in ≤ 2 clicks.

---

### BLK-208 — Low-end GPU frame drops with debug overlay

| Field | Value |
|-------|-------|
| **Severity** | P3 |
| **Discipline** | Engineering (rendering) |
| **Status** | **Open** |

**Affected files:** `apps/web/src/game/debugPanel.ts`, `ThreeGameRenderer`

**Reproduction:** Enable debug overlay on integrated GPU; play 3-minute match.

**Expected:** Stable 60 FPS with debug on.

**Actual:** Frame drops possible on low-end hardware.

**Fix plan:** Throttle debug draw; default off in production path.

**Acceptance test:** ≥ 55 FPS avg on i5-8250U with debug off.

---

## Open blockers — P4 (future)

| ID | Title | Discipline | Notes |
|----|-------|------------|-------|
| BLK-301 | No PWA / offline install | Engineering | Future mobile/desktop wrapper |
| BLK-302 | Online rollback netplay not in client | Engineering | Track B — after local complete |
| BLK-303 | Engine migration not started | Engineering | `ENGINE_MIGRATION_DECISION.md` — deferred |
| BLK-304 | Final GLB fighter assets | Art | Godot path; web uses procedural |
| BLK-305 | Edge-IO wearable not required path | Hardware | Optional track F |

---

## Blocker index

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BLK-001 | Movement scale too low | P0 | Fixed |
| BLK-002 | Navigation / product flow | P0 | Fixed |
| BLK-003 | CPU levels not in UI | P0 | Fixed |
| BLK-004 | Combat unreliable (spacing + feel) | P0 | Fixed |
| BLK-101 | Mobile / touch controls | P2 | Open |
| BLK-102 | 4-player blocked | P2 | Open |
| BLK-103 | Preview fighter balance | P2 | Open |
| BLK-104 | Procedural audio/VFX | P2 | Open |
| BLK-105 | Manual playtest unsigned | P2 | Open |
| BLK-106 | Keyboard P1/P2 overlap | P2 | Open |
| BLK-201 | Training move list subset | P3 | Open |
| BLK-202 | Shield SFX timing | P3 | Open |
| BLK-203 | CPU not tournament-grade | P3 | Open |
| BLK-204 | Gamepad activation prompt | P3 | Open |
| BLK-205 | Career/replay polish | P3 | Open |
| BLK-206 | Training keys undocumented | P3 | Open |
| BLK-207 | Lab back-navigation | P3 | Open |
| BLK-208 | Debug overlay perf | P3 | Open |
| BLK-301–305 | Future enhancements | P4 | Open |

---

*Update this file when blockers are opened, fixed, or reclassified. Cross-reference `docs/KNOWN_ISSUES.md` for player-facing summaries.*

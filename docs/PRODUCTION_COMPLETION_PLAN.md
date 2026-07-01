# Production Completion Plan — Anime Aggressors

**Status:** Canonical top-level truth document  
**Last updated:** 2026-07-01  
**Branch:** `production/complete-functional-game`  
**Audience:** Engineering, design, art, QA, production, marketing

> **This document defines the full local platform fighter — not a demo, vertical slice, prototype, or milestone scaffold.**  
> Completion means a player can launch the game, navigate menus, fight a complete match (human vs human, human vs CPU, or training), and return to menus without broken core systems.

---

## 1. What “fully functional” means

Anime Aggressors is **fully functional** when it behaves as a **real, offline/local platform fighter** from end to end:

| Dimension | Fully functional means |
|-----------|------------------------|
| **Launch** | Fresh browser load reaches Home with no console errors; primary actions are obvious |
| **Navigation** | Start Game, Quick Play, Training, Controls, Settings, and About all route correctly; Labs are separated from the core product; no dead-end screens |
| **Movement** | Fighters move immediately on input; P1 reaches P2 from default spawn in 2–4 seconds; platform-fighter movement options (walk, dash, hops, air drift, fast fall, ledge, recovery) work |
| **Combat** | Attacks connect at correct spacing; shield, grab, knockback, stocks, KO, respawn, and rematch work reliably |
| **Roster** | All 7 `DEFAULT_FIGHTERS` are selectable, distinguishable, and can complete a match |
| **Stages** | All 3 production stages are selectable with valid spawns, platforms, ledges, blast zones, and readable camera |
| **CPU** | Levels 1–3 are selectable; CPU approaches, attacks, recovers, and can finish a match |
| **Training** | Launches from Home; damage/position reset, dummy modes, move list, and hitbox toggle work |
| **Input** | Keyboard P1/P2, gamepad(s), and mixed keyboard+controller work; controls overlay matches actual bindings |
| **Feedback** | Hit, shield, KO, respawn, and menu audio/VFX provide readable feedback; volume/mute available |
| **Quality** | `npm run typecheck`, `npm test`, and `npm run build` pass; no open P0/P1 blockers |

**Fully functional does not mean:** final AAA art, online ranked netplay, 4-player couch, mobile touch controls, or shipped retail hardware. Those are tracked separately (see §5 Out of scope).

---

## 2. What is currently broken or incomplete

Audit date: **2026-07-01**. See `docs/PRODUCTION_BLOCKERS.md` for full blocker records.

### Fixed in this production pass (P0 → resolved)

| Area | Was broken | Resolution |
|------|------------|------------|
| **Movement scale** | Run speed ~12 u/s on 800 u spawn gap — fighters barely moved | `MOVEMENT_BASE` tuned in `movementTuning.ts`; tests in `platformFighterMovementFeel.test.ts`, `productionCompletion.test.ts` |
| **Navigation / product flow** | Confusing launch path; stale localStorage could break battle; Labs mixed with main menu | Start Game → Fighter → Stage → Ready → Battle flow; `resetGameState()`; Labs separated; tests in `productionNavigation.test.ts` |
| **CPU discoverability** | Engine had Lv1–3 but UI exposed only Training dummy Lv1 | CPU toggle + level picker in `MatchSetupControlsScreen.ts`; HUD `CPU Lv{N}` label |

### Remaining issues (P2 and below — game is playable but not “polished ship”)

| Area | Severity | Summary |
|------|----------|---------|
| Mobile / touch controls | P2 | Not implemented; keyboard + gamepad only |
| 4-player couch (P3/P4) | P2 | UI ship-blocked; spawn/camera/HUD pass needed |
| Preview fighter balance | P2 | Nix Calder, Orion Vell, Vesper Nyx marked balance-pending vs production 4 |
| Procedural audio/VFX | P2 | Web Audio placeholders; not final art direction |
| Manual playtest sign-off | P2 | Product-owner browser verification pending |
| Training move list | P3 | Overlay shows subset of moves (first 6) |
| Shield SFX timing | P3 | May fire on shield start, not only on block |
| CPU AI quality | P3 | Functional but not tournament-grade |
| Career / replay vault | P3 | Reachable but not polished for core product path |
| Gamepad registration | P3 | May require button press before browser registers pad |
| PWA / offline install | P4 | Not implemented |

---

## 3. What must be completed before calling the game finished

All items in `docs/FULL_GAME_ACCEPTANCE_CRITERIA.md` must pass **automated gates** and **manual playtest** (`docs/playtest/2026-07-01-full-game-completion-check.md`).

### Automated gates (required)

- [ ] `npm run typecheck` — zero errors
- [ ] `npm test` — all unit and web tests green (including `productionCompletion.test.ts`, `platformFighterMovementFeel.test.ts`, `productionNavigation.test.ts`)
- [ ] `npm run build` — `apps/web/dist` artifact loads Home and `#/battle`

### Manual gates (required)

- [ ] Fresh-load playtest: no console errors on golden path
- [ ] Movement, combat, CPU, training verified by named tester
- [ ] All 7 fighters and 3 production stages verified selectable
- [ ] Zero open P0/P1 blockers in `docs/PRODUCTION_BLOCKERS.md`

### Content gates (required for “finished” local game)

- [ ] Every fighter can move, attack, special, shield, recover, be KO’d, and respawn
- [ ] Every production stage loads with valid spawns and blast zones
- [ ] CPU Lv1–3 selectable and labeled in HUD
- [ ] Known issues documented in `docs/KNOWN_ISSUES.md` by severity

### Not required for “finished” local game (deferred)

- Final GLB rigs, shipped SFX libraries, or cinematic VFX
- Online rollback netplay
- Engine migration (see `docs/ENGINE_MIGRATION_DECISION.md`)
- 4-player couch
- Mobile touch UI

---

## 4. Completion checklist by discipline

### Programmers

- [ ] Movement constants tuned; visible distance per 60 frames ≥ 100 display units
- [ ] Combat hit resolution reliable at point-blank and approach spacing
- [ ] Navigation routes and localStorage recovery hardened
- [ ] CPU input generation wired from match setup to `simulateFrame`
- [ ] Training mode uses production `game-core` ruleset
- [ ] Input profiles match controls overlay (P1 WASD, P2 arrows/numpad)
- [ ] HUD shows names, damage %, stocks, CPU label, combat state
- [ ] Pause, rematch, change fighters/stage, return home work
- [ ] CI quality gates green
- [ ] Blockers tracked in `PRODUCTION_BLOCKERS.md`

### Gameplay designers

- [ ] 4 production fighters feel distinct in weight, speed, and neutral tools
- [ ] 3 preview fighters labeled balance-pending; no hidden broken moves
- [ ] CPU Lv1–3 difficulty curve observable (aggression, shield/dodge frequency)
- [ ] Training dummy behaviors (idle, shield, jump, CPU) support labbing
- [ ] Match rules (stocks, timer, blast zones) readable and fair
- [ ] Move lists documented per fighter under `docs/fighters/`
- [ ] Balance notes for preview trio updated or flagged

### Level / stage designers

- [ ] Training Grid, Skyline Arena, Neon Rooftops selectable in main flow
- [ ] Spawn points validated (`validateSpawnPoints` — zero warnings)
- [ ] Platform collision, ledges, blast zones functional per stage
- [ ] Stage layouts visually distinguishable
- [ ] Lab/experimental stages (flagline, impact-platform) remain in Labs/custom setup only
- [ ] Camera bounds readable for 2P; document 4P camera gap

### QA testers

- [ ] Execute `docs/playtest/2026-07-01-full-game-completion-check.md`
- [ ] Execute `docs/PLAYTEST_CHECKLIST.md` regression
- [ ] File blockers with severity per `docs/BUG_SEVERITY_RUBRIC.md`
- [ ] Verify build artifact on GitHub Pages hash routes
- [ ] Regression: M1 platform, M2 movement/ledge, M3 combat, M4 roster/stage/CPU/training
- [ ] Sign-off only when P0/P1 = 0

### Artists

- [ ] Procedural fighter silhouettes distinguishable by color/element
- [ ] Production/preview badges visible in fighter select
- [ ] Stage identity readable (Training Grid vs Skyline vs Neon)
- [ ] DEBUG FALLBACK never presented as final without label
- [ ] Per-fighter production specs (`docs/fighters/*_PRODUCTION_SPEC.md`) updated when visuals change
- [ ] Final GLB/asset pipeline tracked separately — not a local-game blocker

### Animators

- [ ] Locomotion states visible (idle, walk, jump, fall, attack, hitstun)
- [ ] Attack animations align with hitbox active frames (within tolerance)
- [ ] Recovery specials visually distinct
- [ ] Animation lists in `docs/fighters/*/ANIMATION_LIST.md` reflect shipped procedural poses
- [ ] Choreography pipeline docs current for post-web art pass

### Sound designers

- [ ] Hit, shield, KO, respawn SFX hooks fire on correct events
- [ ] Menu confirm/cancel feedback present
- [ ] Volume/mute in Controls/Settings
- [ ] Shield-on-start audio bug triaged (P3)
- [ ] Placeholder procedural audio clearly documented; final asset list per `docs/fighters/*/AUDIO_LIST.md`

### Composers

- [ ] Stage music loop or documented placeholder toggle
- [ ] Music does not block on user-gesture audio context (document iOS caveat)
- [ ] Menu music optional for local-game completion

### UI/UX designers

- [ ] Home: Start Game, Quick Play, Training, Controls, About, Labs separation
- [ ] Match setup: Fighter → Stage → Ready → Battle
- [ ] Onboarding overlay (first match); H for controls
- [ ] Results: winner, rematch, change fighters, change stage, home
- [ ] No dead-end screens; corrupt setup recovers via Reset Game State
- [ ] CPU mode and level visible in match setup and HUD

### Community managers

- [ ] Player-facing controls doc (`docs/CONTROLS.md` or Controls screen) accurate
- [ ] Known limitations published (`docs/KNOWN_ISSUES.md`)
- [ ] No “demo” or “vertical slice” language in player-facing copy — frame as playable game
- [ ] Playtest feedback channel defined for post-completion tuning

### Business analysts

- [ ] Acceptance criteria traceable to `docs/FULL_GAME_ACCEPTANCE_CRITERIA.md`
- [ ] Completion status honest in README and release notes
- [ ] Out-of-scope items (online, hardware, engine migration) documented to prevent scope creep claims
- [ ] Risk register updated for preview fighters and mobile gap

### Marketers

- [ ] Trailer/playtest scaffolding (`docs/TRAILER_CAPTURE_CHECKLIST.md`) reflects actual features
- [ ] No oversell: procedural art, preview fighters, no mobile touch
- [ ] Deploy URL and hash routes documented (`docs/DEPLOYMENT.md`)
- [ ] Release messaging distinguishes “playable local game” from “commercial v1.0”

---

## 5. Feature tiers

### Must-have (local game completion)

- Home → Start Game / Quick Play / Training golden paths
- 7 selectable fighters (4 production + 3 labeled preview)
- 3 production stages
- 2P local: keyboard and gamepad
- CPU Lv1–3 in match setup
- Full platform-fighter movement and combat grammar (per M1–M3 milestones)
- Training mode with reset and dummy behaviors
- HUD, pause, results, rematch
- Minimum audio/VFX feedback + volume/mute
- Automated tests + manual playtest checklist
- Labs separated from core product

### Nice-to-have (post-completion polish)

- Fighter-specific move lists in training overlay (full 15+ moves)
- Quick Play with CPU option
- Career mode polish
- Replay vault polish
- Gamepad hot-plug without initial button press
- Improved CPU tournament-grade AI
- Real audio assets (replace oscillators)
- Stage hazards and legal variants
- PWA / offline install

### Explicitly out of scope (this completion program)

- Engine migration (Godot, Unity, C++ rewrite) — see `docs/ENGINE_MIGRATION_DECISION.md`
- Online / ranked rollback netplay
- 4-player couch (P3/P4) until spawn/camera/HUD pass
- New fighters beyond existing 7
- New experimental modes (Derby, Flagline, Godot) on main path
- Edge-IO / wearable hardware as required input
- Mobile touch on-screen controls (tracked as P2 gap, not completion blocker for desktop local game)
- Fake manual playtest sign-off
- Claiming AAA production art completion

---

## 6. Acceptance gates

| Gate | Owner | Pass condition |
|------|-------|----------------|
| **G1 — Build** | Engineering | typecheck + test + build green |
| **G2 — Simulation** | Engineering | `productionCompletion.test.ts` + movement feel tests pass |
| **G3 — Navigation** | Engineering | `productionNavigation.test.ts` + manual Home → Battle path |
| **G4 — Roster** | Design + QA | All 7 fighters complete a match |
| **G5 — Stages** | Design + QA | All 3 production stages valid spawns/ledges |
| **G6 — CPU** | Design + QA | Lv1–3 selectable; idle target hit within 20 s (automated) |
| **G7 — Training** | Design + QA | Reset + dummy modes functional |
| **G8 — Input** | Engineering | P1/P2 profiles match overlay; 2 gamepads map correctly |
| **G9 — AV** | Art + Audio | Hit/shield/KO/respawn feedback present; mute works |
| **G10 — Manual** | QA + Product | `docs/playtest/2026-07-01-full-game-completion-check.md` signed |
| **G11 — Blockers** | Production | Zero open P0/P1 in `PRODUCTION_BLOCKERS.md` |

---

## 7. Manual playtest requirements

1. **Tester:** Named product owner or delegated QA — not automated or faked.
2. **Environment:** Fresh browser profile; production build artifact or Pages deploy.
3. **Checklist:** `docs/playtest/2026-07-01-full-game-completion-check.md` (primary); `docs/PLAYTEST_CHECKLIST.md` (5-minute regression).
4. **Minimum sessions:**
   - 1× Start Game full setup → match → results → rematch
   - 1× Quick Play → battle
   - 1× Training with dummy modes 1–4
   - 1× CPU Lv2 or Lv3 match via match setup
   - 1× 2P keyboard; 1× gamepad if hardware available
5. **Record:** Date, build commit/URL, browser, pass/fail per section, blockers filed.
6. **If browser manual test cannot be run:** Leave checklist unchecked; state: *Manual browser verification required by product owner.*

---

## 8. Definition of done

### Feature-level done

A feature is done when:

1. It maps to a criterion in `docs/FULL_GAME_ACCEPTANCE_CRITERIA.md`
2. Code is merged with automated test or documented manual repro ≤ 15 minutes
3. Severity-appropriate bugs filed or resolved per `docs/BUG_SEVERITY_RUBRIC.md`
4. `docs/KNOWN_ISSUES.md` updated if user-visible limitation remains
5. No false “complete” claims in README or player-facing UI

### Program-level done (local functional platform fighter)

The codebase may be called **complete for offline/local play** when **all** are true:

- [ ] All must-have features (§5) implemented
- [ ] All acceptance gates G1–G11 pass
- [ ] Manual playtest signed (or explicitly pending with unchecked boxes)
- [ ] **Zero P0/P1 blockers** in `docs/PRODUCTION_BLOCKERS.md`
- [ ] Remaining issues are P2+ and tracked in `docs/KNOWN_ISSUES.md`

**Completion statement (PR/release):**

> This release completes the local functional platform fighter codebase for offline/local play. Remaining issues are P2 or lower and tracked in `docs/KNOWN_ISSUES.md` and `docs/PRODUCTION_BLOCKERS.md`.

If any P0/P1 blocker remains:

> This release does **not** claim completion. Remaining P0/P1 blockers are listed in `docs/PRODUCTION_BLOCKERS.md`.

---

## 9. Related documents

| Document | Purpose |
|----------|---------|
| [FULL_GAME_ACCEPTANCE_CRITERIA.md](./FULL_GAME_ACCEPTANCE_CRITERIA.md) | Measurable pass/fail targets |
| [PRODUCTION_BLOCKERS.md](./PRODUCTION_BLOCKERS.md) | Active and resolved blockers |
| [BUG_SEVERITY_RUBRIC.md](./BUG_SEVERITY_RUBRIC.md) | P0–P4 definitions |
| [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) | User-visible limitations |
| [PLATFORM_FIGHTER_REQUIREMENTS.md](./PLATFORM_FIGHTER_REQUIREMENTS.md) | Genre requirements baseline |
| [ENGINE_MIGRATION_DECISION.md](./ENGINE_MIGRATION_DECISION.md) | Engine path (deferred) |
| [QUALITY_BAR.md](./QUALITY_BAR.md) | Performance and hygiene metrics |
| [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) | Full program PRD (tracks A–H) |

---

*This plan supersedes milestone-scaffold framing for completion status. Milestone docs (M1–M5) remain historical evidence of incremental delivery but are not substitutes for the gates above.*

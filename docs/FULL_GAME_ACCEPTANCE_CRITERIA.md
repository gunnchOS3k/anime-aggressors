# Full Game Acceptance Criteria — Anime Aggressors

**Status:** Canonical measurable completion bar  
**Last updated:** 2026-07-01  
**Scope:** Local functional platform fighter (offline play)  
**Parent:** [PRODUCTION_COMPLETION_PLAN.md](./PRODUCTION_COMPLETION_PLAN.md)

> Every criterion below must pass before the codebase is declared **complete for offline/local play**.  
> Verification = **Automated** (CI test or script), **Manual** (playtest checklist), or **Both**.

---

## How to use this document

| Column | Meaning |
|--------|---------|
| **ID** | Traceable criterion ID |
| **Target** | Measurable pass condition |
| **Verification** | How to prove it |
| **Automated test / file** | Existing test or code anchor (if any) |

---

## 1. Launch and navigation

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| NAV-01 | Fresh browser load reaches Home with **no console errors** | Manual + build smoke | `apps/web/dist` preview |
| NAV-02 | **Start Game** reaches Fighter Select | Automated + Manual | `productionNavigation.test.ts` — `MODE_ROUTE_MAP.startMatch` |
| NAV-03 | **Quick Play** reaches Battle in **under 3 clicks** from Home | Manual | `docs/PLAYTEST_CHECKLIST.md` §Quick Match |
| NAV-04 | **Fighter Select** routes correctly (`#/fighter-select`) | Automated | `APP_ROUTES`, `productionNavigation.test.ts` |
| NAV-05 | **Stage Select** routes correctly (`#/stage-select`) | Automated | `MODE_ROUTE_MAP.startMatch` |
| NAV-06 | **Training** launches (`#/training`) | Automated + Manual | `productionNavigation.test.ts` |
| NAV-07 | **Controls** routes correctly (`#/controls`) | Automated | `productionNavigation.test.ts` |
| NAV-08 | **Settings** (volume/mute) accessible from Controls or equivalent | Manual | `audioSettings.ts`, Controls screen |
| NAV-09 | **About / Credits** routes correctly (`#/about`) | Automated | `productionNavigation.test.ts` |
| NAV-10 | **No dead-end screens** on main play path | Manual | Full-game playtest checklist |
| NAV-11 | **Labs separated** from main game carousel | Automated | `productionNavigation.test.ts` — `menu-labs` |
| NAV-12 | Corrupt `localStorage` setup **recovers gracefully** (Reset Game State) | Automated | `resetGameState()` in `quickMatch.ts` |
| NAV-13 | Route errors show useful screen, not blank failure | Manual | Invalid hash handling in `routes.ts` |
| NAV-14 | Match flow: Fighter → Stage → Ready → Battle → Results | Automated | `MODE_ROUTE_MAP.startMatch` |

---

## 2. Movement

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| MOV-01 | Holding direction moves fighter **within 0.25 s** (15 frames @ 60 Hz) | Automated | `platformFighterMovementFeel.test.ts` |
| MOV-02 | **P1 reaches P2** from default spawn in **2–4 seconds** (120–240 frames) | Automated | `platformFighterMovementFeel.test.ts`, `movementTuning.ts` |
| MOV-03 | **60 frames** of right input moves **≥ 100 display units** | Automated | `platformFighterMovementFeel.test.ts` |
| MOV-04 | **Walk / run** — horizontal displacement on ground | Automated + Manual | `groundMovement.ts`, movement feel tests |
| MOV-05 | **Dash** covers meaningful distance (≥ 200 u in 12 frames) | Automated | `platformFighterMovementFeel.test.ts` |
| MOV-06 | **Crouch** — down input on ground produces crouch or equivalent | Manual | M2 playtest checklist |
| MOV-07 | **Short hop** apex lower than **full hop** | Automated | `productionCompletion.test.ts` |
| MOV-08 | **Full hop** — useful apex height | Automated | `productionCompletion.test.ts` |
| MOV-09 | **Double jump** (or per-fighter jump count) | Manual + Automated | `jumpSystem.ts` |
| MOV-10 | **Air drift** changes X while airborne | Automated | `platformFighterMovementFeel.test.ts` |
| MOV-11 | **Fast fall** increases descent rate | Automated | `productionCompletion.test.ts` |
| MOV-12 | **Platform landing** on main and side platforms | Manual | M1 playtest regression |
| MOV-13 | **Drop-through** (down + jump) where stage supports it | Manual | M1 playtest regression |
| MOV-14 | **Ledge grab** when offstage and in range | Manual | M2 playtest regression |
| MOV-15 | **Ledge getup / jump / release** | Manual | M2 playtest regression |
| MOV-16 | **Recovery special** changes position meaningfully | Automated | `productionCompletion.test.ts` |
| MOV-17 | Movement feels responsive with **keyboard** | Manual | `PLAYTEST_CHECKLIST.md` |
| MOV-18 | Movement feels responsive with **controller** | Manual | Gamepad playtest if hardware available |
| MOV-19 | Size classes differ: small > medium > large speed over 60 frames | Automated | `platformFighterMovementFeel.test.ts` |

**Unit contract:** Display units = fixed-point value / `FP_SCALE` (256). Stage width = 2400 display units. Default spawn gap ≈ 800 display units.

---

## 3. Combat

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| COM-01 | **Neutral attack** hits at point-blank | Automated | `productionCompletion.test.ts` |
| COM-02 | **Approach + attack** connects within **5 seconds** (300 frames) | Automated | `productionCompletion.test.ts` |
| COM-03 | **Directional attacks** select correctly (forward/up/down) | Manual | M3 playtest checklist |
| COM-04 | **Directional attacks** connect at correct spacing | Manual + Automated | `milestone3CombatGrammar.test.ts` |
| COM-05 | **Aerials** select correctly | Manual | M3 playtest checklist |
| COM-06 | **Aerials** connect at correct spacing | Manual | M3 playtest |
| COM-07 | **Specials** select correctly | Manual | M3 playtest checklist |
| COM-08 | **Specials** connect at correct spacing | Manual | M3 playtest |
| COM-09 | **Shield** blocks point-blank attack | Automated | `productionCompletion.test.ts` |
| COM-10 | **Dodge** grants i-frames / evades (ground) | Manual | M3 playtest |
| COM-11 | **Roll / air dodge** where implemented | Manual | M3 playtest |
| COM-12 | **Grab** catches opponent | Manual + Automated | `milestone3CombatGrammar.test.ts` |
| COM-13 | **Throws** apply damage/knockback | Manual + Automated | combat grammar tests |
| COM-14 | **Hitlag** observable on connect | Manual | `PLAYTEST_CHECKLIST.md` §Combat |
| COM-15 | **Hitstun** prevents immediate retaliation | Manual | M3 playtest |
| COM-16 | **Knockback** scales with damage % | Manual | `PLAYTEST_CHECKLIST.md` |
| COM-17 | **DI** (directional influence) observable where implemented | Manual | M3 regression |
| COM-18 | **Stale move decay** observable where implemented | Manual | M3 regression |
| COM-19 | **Damage %** updates on HUD | Manual | Battle playtest |
| COM-20 | **Stocks** decrement on KO | Automated + Manual | `productionCompletion.test.ts` |
| COM-21 | **KO** from blast zone | Automated + Manual | blast zone tests |
| COM-22 | **Respawn** with invulnerability frames | Manual | HUD invuln cue |
| COM-23 | **Match end** → results phase | Automated | `productionCompletion.test.ts` |
| COM-24 | **Rematch** resets damage and returns to countdown | Automated | `productionCompletion.test.ts` |
| COM-25 | **Every fighter** can damage every other fighter | Manual | Full roster playtest |
| COM-26 | **Every fighter** can KO every other fighter | Manual | Full roster playtest |
| COM-27 | Same attack does **not** multi-tick damage per swing (unless multi-hit) | Manual | `PLAYTEST_CHECKLIST.md` §19 |

---

## 4. Roster

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| ROST-01 | All **7** `DEFAULT_FIGHTERS` selectable | Manual | Fighter select screen |
| ROST-02 | Fighters: Ember Vale, Rook Ironside, Juno Spark, Kaia Windrow, Nix Calder, Orion Vell, Vesper Nyx | Automated | `defaultFighters.test.ts` |
| ROST-03 | **4 production** fighters labeled production | Automated | `fighterGameplayProfiles.ts`, `PRODUCTION_FIGHTER_IDS` |
| ROST-04 | **3 preview** fighters labeled balance-pending | Automated + Manual | `PREVIEW_FIGHTER_IDS`, fighter select badges |
| ROST-05 | All fighters **visually distinguishable** (color/element/silhouette) | Manual | `defaultFighterAppearances.ts` |
| ROST-06 | Readable **names** and **archetypes** in select/HUD | Manual | Fighter select + HUD |
| ROST-07 | **Move lists** exist per fighter in `docs/fighters/` | Automated | Doc existence tests / manual audit |
| ROST-08 | Every fighter **can spawn** | Automated | `productionCompletion.test.ts` |
| ROST-09 | Every fighter **can move** | Automated | `productionCompletion.test.ts` |
| ROST-10 | Every fighter **can attack** | Manual + Automated | roster integration tests |
| ROST-11 | Every fighter **can special** | Manual | Per-fighter playtest |
| ROST-12 | Every fighter **can recover** | Manual | Offstage recovery test |
| ROST-13 | Every fighter **can finish a match** (KO or timer) | Manual | Full-game playtest |
| ROST-14 | **No fighter** selectable if it cannot move, attack, recover, and finish a match | Manual | Block broken fighters from select |
| ROST-15 | Stats differ by archetype (weight, speed, size class) | Automated | `fighterGameplayProfiles.ts`, size class tests |

---

## 5. Stages

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| STG-01 | All **3 production stages** selectable in main flow | Manual | `DemoStageSelectScreen.ts` |
| STG-02 | **training-grid** — flat training stage | Automated | `productionStages.ts` |
| STG-03 | **skyline-arena** — three-platform layout | Automated | `stageLayouts.ts` |
| STG-04 | **neon-rooftops** — casual identity layout | Automated | `stageLayouts.ts` |
| STG-05 | **Spawn points valid** (zero warnings) | Automated | `productionCompletion.test.ts`, `validateSpawnPoints` |
| STG-06 | **Platforms** collide correctly | Automated | `stageCollision.test.ts` |
| STG-07 | **Ledges** present and functional where defined | Automated + Manual | stage layout + M2 playtest |
| STG-08 | **Blast zones** remove stocks | Manual | Battle playtest |
| STG-09 | **Camera** remains readable (2P) | Manual | Stage playtest |
| STG-10 | Stage layouts **visually distinguishable** | Manual | Compare 3 production stages |
| STG-11 | Lab/experimental stages **not** on main public path | Automated | `mainMenuConfig.ts` labs tier |
| STG-12 | No broken stage in production select | Automated | `listProductionStageIds()` |

---

## 6. CPU

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| CPU-01 | **Levels 1–3** exist in engine | Automated | `versusCpu.ts`, `CpuDifficulty` type |
| CPU-02 | **Levels 1–3 selectable** in match setup UI | Manual + Automated | `MatchSetupControlsScreen.ts` |
| CPU-03 | CPU **approaches** idle target within **5 seconds** (300 frames) | Automated | `productionCompletion.test.ts` |
| CPU-04 | CPU **attacks** (attempts offensive input) within **8 seconds** (480 frames) | Manual + Automated | versus CPU behavior observation |
| CPU-05 | CPU **hits idle opponent** within **20 seconds** (1200 frames) | Automated | `productionCompletion.test.ts` |
| CPU-06 | CPU **attempts recovery** when offstage | Manual | Lv2+ recovery behavior in `versusCpu.ts` |
| CPU-07 | CPU **shields/dodges sometimes** (Lv2+) | Manual | Difficulty scaling |
| CPU-08 | CPU **does not stand still forever** | Automated | approach test |
| CPU-09 | CPU can **complete a match** (stock removal) | Manual | Full CPU match playtest |
| CPU-10 | **HUD shows `CPU Lv{N}`** when CPU active | Manual | `App.ts` HUD |
| CPU-11 | Lv3 more aggressive than Lv1 over fixed window | Automated | `milestone4FourFighterVerticalSlice.test.ts` |
| CPU-12 | CPU input is **deterministic** given seed | Automated | versus CPU tests |

---

## 7. Training

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| TRN-01 | **Training launches** from Home (`#/training`) | Manual | Training route |
| TRN-02 | Player and dummy **spawn** on training-grid | Automated | `trainingSetup.ts`, ruleset |
| TRN-03 | **Damage reset** clears damage % | Automated | `productionCompletion.test.ts` |
| TRN-04 | **Position reset** restores spawn positions | Automated | `productionCompletion.test.ts` |
| TRN-05 | Dummy **idle** behavior | Manual | Key `1` or UI |
| TRN-06 | Dummy **shield** behavior | Automated | `productionCompletion.test.ts` |
| TRN-07 | Dummy **jump** behavior | Automated | `productionCompletion.test.ts` |
| TRN-08 | Dummy **CPU** behavior (mode 4) | Manual | `trainingMode.ts` cpu1 delegate |
| TRN-09 | **Move list** visible in training | Manual | Training overlay |
| TRN-10 | **Hitbox / debug toggle** works | Manual | Debug overlay / F1 |
| TRN-11 | Player can practice **production moves** | Manual | Training session |
| TRN-12 | Training uses **production game-core** (not legacy prototype) | Automated | `PlatformFighterApp` + ruleset |
| TRN-13 | Frame pause/step if pause infrastructure supports it | Manual | Training starts paused |

---

## 8. Input

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| INP-01 | **Keyboard P1** (WASD + J/K/L) works | Manual | `controlReference.ts`, `PLAYTEST_CHECKLIST.md` |
| INP-02 | **Keyboard P2** (arrows + numpad) works | Manual | `playerInputMapping.test.ts` |
| INP-03 | **One controller** works | Manual | Gamepad playtest |
| INP-04 | **Two controllers** work when both connected | Manual | `deviceAssignment.ts` |
| INP-05 | **Keyboard + controller mixed** mode works | Manual | M4 playtest |
| INP-06 | **Controls overlay (H)** matches actual input bindings | Manual | Overlay vs battle |
| INP-07 | **Input focus** issues handled (blur clears keys) | Manual | Alt-tab test |
| INP-08 | Overlays do **not swallow** gameplay input when dismissed | Manual | H toggle during fight |
| INP-09 | **Controller assignment** visible and stable | Manual | Controls screen |
| INP-10 | **Debug input overlay** behind F1 only (not default) | Manual | `debugPanel.ts` |
| INP-11 | P1/P2 keyboard separation documented; overlap acknowledged | Manual | `KNOWN_ISSUES.md` |
| INP-12 | Gamepad maps to `InputFrame` correctly | Automated | `gamepad.ts` tests |

---

## 9. Audio and VFX

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| AV-01 | **Hits** have visible feedback (particles/spark) | Manual | `CombatVfxOrchestrator.ts` |
| AV-02 | **Hits** have audible feedback | Manual | `AudioManager.ts`, `globalAudio` |
| AV-03 | **Shield blocks** have visible feedback | Manual | Shield VFX |
| AV-04 | **Shield blocks** have audible feedback | Manual | shield_hit SFX |
| AV-05 | **KO** has visible feedback | Manual | KO flash/VFX |
| AV-06 | **KO** has audible feedback | Manual | ko SFX |
| AV-07 | **Respawn / invulnerability** has visible cue | Manual | invuln VFX |
| AV-08 | **Jump/landing** feedback present | Manual | dust/land VFX |
| AV-09 | **Menu confirm/cancel** feedback | Manual | Menu SFX |
| AV-10 | **Music loop** exists OR documented placeholder toggle | Manual | Stage/menu audio |
| AV-11 | **Mute** works | Manual | `audioSettings.ts` |
| AV-12 | **Volume** control works | Manual | Controls/Settings |
| AV-13 | Placeholder assets clearly documented (not mislabeled as final) | Doc review | `apps/web/src/audio/README.md` |

---

## 10. QA and release

| ID | Target | Verification | Automated test / file |
|----|--------|--------------|----------------------|
| QA-01 | `npm run typecheck` passes | Automated | CI / local |
| QA-02 | `npm test` passes | Automated | CI / local |
| QA-03 | `npm run build` passes | Automated | CI / local |
| QA-04 | Golden-path **browser tests** exist where infrastructure supports | Automated | `productionNavigation.test.ts`, `battleSceneBoot.test.ts` |
| QA-05 | **Manual playtest checklist** exists | Doc | `docs/playtest/2026-07-01-full-game-completion-check.md` |
| QA-06 | **Known issues** documented and categorized by severity | Doc | `KNOWN_ISSUES.md`, `PRODUCTION_BLOCKERS.md` |
| QA-07 | **No P0 issues** remain before “complete” status | Doc + triage | `BUG_SEVERITY_RUBRIC.md` |
| QA-08 | **No P1 issues** remain before “complete” status | Doc + triage | `PRODUCTION_BLOCKERS.md` |
| QA-09 | Build artifact loads `#/` and `#/battle` without module errors | Manual | Pages deploy / local preview |
| QA-10 | Hash routes work when pasted directly | Manual | `DEPLOYMENT.md` |
| QA-11 | Determinism: same inputs → same state hash | Automated | determinism tests |
| QA-12 | Sim tick rate 60 Hz fixed | Automated | `SIM_HZ` constant |

---

## 11. Performance targets (reference — from PRODUCT_REQUIREMENTS / QUALITY_BAR)

| ID | Target | Gate |
|----|--------|------|
| PERF-01 | Sim tick rate 60 Hz | Required |
| PERF-02 | Render FPS ≥ 55 avg on 2020 laptop @ 1080p | Manual (recommended) |
| PERF-03 | Sim CPU < 3 ms/frame (2P) in JS | Profiling (recommended) |
| PERF-04 | Input-to-action p50 ≤ 50 ms (local) | Manual (v1.0 target; best effort for local completion) |
| PERF-05 | Main bundle gzip < 800 KB full demo | `vite build` analyze (recommended) |

---

## 12. Completion sign-off matrix

| Category | Criteria count | All must pass |
|----------|----------------|---------------|
| Launch/navigation | NAV-01 – NAV-14 | Yes |
| Movement | MOV-01 – MOV-19 | Yes |
| Combat | COM-01 – COM-27 | Yes |
| Roster | ROST-01 – ROST-15 | Yes |
| Stages | STG-01 – STG-12 | Yes |
| CPU | CPU-01 – CPU-12 | Yes |
| Training | TRN-01 – TRN-13 | Yes |
| Input | INP-01 – INP-12 | Yes (INP-03/04 if hardware unavailable: document N/A) |
| Audio/VFX | AV-01 – AV-13 | Yes (placeholders acceptable if documented) |
| QA/release | QA-01 – QA-12 | Yes |

**Sign-off:** Product owner + QA lead, date, build URL/commit, linked playtest record.

---

*Criteria sourced from production completion program requirements, `docs/PRODUCT_REQUIREMENTS.md`, `docs/MVP_DEFINITION_OF_DONE.md`, `docs/QUALITY_BAR.md`, and 2026-07-01 codebase audit.*

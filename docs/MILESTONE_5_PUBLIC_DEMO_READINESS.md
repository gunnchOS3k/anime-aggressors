# Milestone 5 — Public Demo Readiness

**Status:** Complete (pending manual playtest)  
**Branch:** `feat/milestone-5-public-demo-readiness`  
**Last updated:** 2026-07-01

---

## Goal

Make Anime Aggressors **presentable as a public web demo** while documenting the serious engine migration decision separately.

**Milestone 5 is about making the current web demo presentable and deployable. It does not migrate the engine.** Engine migration is documented in [ENGINE_MIGRATION_DECISION.md](./ENGINE_MIGRATION_DECISION.md) and becomes a later implementation milestone if approved.

---

## In scope

### Track A — Public Demo Readiness
- Main menu / product path clarity (Play Demo, fighter/stage select, training, controls, about)
- Labs clearly separated from main demo path
- First-load onboarding overlay (dismissible, localStorage)
- HUD readability (names, CPU label, stocks, damage %, combat state chips)
- Results screen actions (rematch, change fighters, change stage, home)
- Lightweight audio/VFX polish (hit, shield, KO, respawn cue, menu blips)
- Volume/mute settings
- Deployment and release documentation
- Trailer/playtest scaffolding

### Track B — Engine Direction Decision
- [ENGINE_MIGRATION_DECISION.md](./ENGINE_MIGRATION_DECISION.md) — compare TS/Web/Three.js vs Godot/C#/C++/Unity/custom C++
- Recommendation and revisit date — **documentation only**

---

## Out of scope

- Engine migration (Godot, Unity, C++, rewrite)
- Online / ranked / netplay
- Story / career expansion
- Hardware, Edge-IO, wearable, cloud runtime changes
- Roster expansion beyond 7 `DEFAULT_FIGHTERS`
- Items (unless already implemented and off by default)
- Fake manual playtest verification
- Milestone 6+ systems

---

## Current public demo audit (pre-M5 → post-M5)

| Area | Pre-M5 | Post-M5 |
|------|--------|---------|
| Home CTA | "Quick Match" | **Play Demo** + clearer tagline |
| Fighter/Stage select | Buried in custom setup | **Direct home entries** |
| About | Missing | **About / Credits** screen |
| Onboarding | None | **First-match help overlay** |
| HUD | Names + damage | **CPU label, status chips, larger stats** |
| Results | Rematch + fighters | **+ Change Stage, Home** |
| Audio | Procedural hits only | **+ mute/volume, menu/KO/result hooks** |
| VFX | Hit/KO/dust | **+ respawn invuln cue** |
| Labs | Present | **Create Fighter moved to Labs** |

---

## Main play path

```
Home → Play Demo → Battle → Results → Rematch / Change Fighters / Change Stage / Home
```

Alternate paths:
- Home → Fighter Select → Battle
- Home → Stage Select → Battle
- Home → Training
- Home → Custom Match Setup (full rules flow)
- Home → Controls / About

---

## Known UX risks

- Touch/mobile controls incomplete — keyboard + gamepad only for demo
- Career/replay vault reachable but not part of public demo path
- Preview fighters (3) marked balance-pending — may feel uneven vs production 4
- Procedural audio/VFX are placeholders, not final art direction
- GitHub Pages `build:pages` includes Godot export steps — web-only deploy documented in DEPLOYMENT.md

---

## Files touched

**Web:** `mainMenuConfig.ts`, `homeScreenMarkup.ts`, `routes.ts`, `router.ts`, `main.ts`, `App.ts`, `ControlsScreen.ts`, `AboutScreen.ts`, `DemoFighterSelectScreen.ts`, `DemoStageSelectScreen.ts`, `demoOnboarding.ts`, `audioSettings.ts`, `AudioManager.ts`, `WinnerHero.ts`, `MatchResultsScreen.ts`, `CombatVfxOrchestrator.ts`, `styles.css`

**Docs:** M5 tracker, engine decision, deployment, checklists, known issues, release notes, trailer checklist, playtest record

**Tests:** `milestone5PublicDemoReadiness.test.ts`, updated home/menu/results tests

---

## Acceptance tests

- `npm run typecheck` passes
- `npm test` passes (M1–M4 regression + M5 web tests)
- `npm run build` produces playable `apps/web/dist`
- Hash routes: `#/`, `#/battle`, `#/training`, `#/fighter-select`, `#/stage-select`, `#/about`
- Onboarding dismisses and does not reappear until reset
- Production/preview badges visible in fighter select

---

## Manual playtest requirements

See [docs/playtest/2026-07-01-m5-public-demo-readiness.md](./playtest/2026-07-01-m5-public-demo-readiness.md).

Manual browser verification required by product owner.

---

## Deployment requirements

- `npm run build` artifact loads Home
- Documented in [DEPLOYMENT.md](./DEPLOYMENT.md) and [PUBLIC_DEMO_CHECKLIST.md](./PUBLIC_DEMO_CHECKLIST.md)
- GitHub Pages workflow status noted in PR body

---

## Definition of done

- [x] Public demo path hardened
- [x] Onboarding + HUD + results improvements
- [x] Lightweight audio/VFX polish
- [x] All M5 docs created
- [x] ENGINE_MIGRATION_DECISION.md (no code migration)
- [x] Tests + quality gates pass
- [ ] Manual playtest signed off by product owner

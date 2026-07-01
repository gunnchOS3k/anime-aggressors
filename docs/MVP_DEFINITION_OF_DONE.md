# MVP Definition of Done — Indie Platform Fighter

**Status:** Canonical acceptance bar  
**Last updated:** 2026-06-24  
**Related:** [Platform fighter requirements](./PLATFORM_FIGHTER_REQUIREMENTS.md) · [Gap analysis](./ANIME_AGGRESSORS_GAP_ANALYSIS.md) · [Playtest checklist](./PLAYTEST_CHECKLIST.md)

---

## When is Anime Aggressors “fully operational”?

Anime Aggressors meets **indie Smash-like MVP** when **all** of the following are true on a **production web build** (GitHub Pages artifact), verified by a named playtester and recorded in `docs/playtest/`.

### 1. Onboarding

- [ ] A new player can launch the game and start a match **without instructions** (Home → Quick Match ≤ 2 clicks).
- [ ] Controls are viewable in-app (H overlay + Controls screen).
- [ ] No dead-end menus on the main path.

### 2. Local multiplayer

- [ ] Two local players can fight using **keyboard** (P1 WASD + P2 arrows/numpad per `controlReference.ts`).
- [ ] Two local players can fight using **gamepads** (P1 + P2 assigned, reconnect handled gracefully).
- [ ] Pause, restart/rematch, and return to menu work without console errors.

### 3. Roster

- [ ] At least **four fighters** feel **meaningfully different** in movement, weight, and neutral tools (not palette swaps).
- [ ] Each has: select portrait, readable silhouette, complete move list in training, and distinct recovery option.

### 4. Stages

- [ ] At least **three stages** are fully playable: spawns, platforms, blast zones, camera, stage select preview.
- [ ] One flat stage, one three-platform stage, one identity/casual stage.

### 5. Combat readability

- [ ] Damage % increases visibly on hit.
- [ ] Knockback scales with damage (observable launch distance).
- [ ] Hitlag / brief hitstop on connect.
- [ ] Hitstun prevents immediate retaliation.
- [ ] KOs remove stocks; respawn invuln visible.
- [ ] Same attack does not multi-tick damage per swing (unless labeled multi-hit).

### 6. Movement

- [ ] Walk, run/dash, jump, double jump (or per-fighter equivalent), air drift, fast fall.
- [ ] Land on main and side platforms; drop-through on down + jump (when implemented).
- [ ] Ledge grab and recovery sufficient to return from offstage (Milestone 2+).

### 7. CPU

- [ ] CPU opponent available in versus or Quick Match with **at least 3 difficulty levels**.
- [ ] CPU can attack, shield or dodge sometimes, and attempt recovery.

### 8. Training mode

- [ ] Damage reset, position reset, hitbox toggle, frame step or pause-step.
- [ ] Move list overlay and combo/damage readout for labbing.

### 9. Quality gates (CI)

- [ ] `npm run typecheck` passes.
- [ ] `npm test` passes.
- [ ] `npm run build` passes.
- [ ] Pages deploy artifact loads `#/` and `#/battle` without module errors.

### 10. Release hygiene

- [ ] Build deployable and playable from browser URL.
- [ ] Manual playtests **recorded** (date, build, tester, pass/fail per section).
- [ ] Known issues tracked by requirement category (A–L in requirements doc).
- [ ] Experimental modes (Godot, Derby, Flagline, Edge-IO) **not** on main play path.

---

## Milestone mapping

| MVP section | Minimum milestone |
|-------------|-------------------|
| §1 Onboarding | M0 + PR #36 |
| §2 Local MP | M1–M2 (keyboard); M4 (gamepad polish) |
| §3 Roster | M4 |
| §4 Stages | M4 |
| §5 Combat | M3 |
| §6 Movement | M2 |
| §7 CPU | M4 |
| §8 Training | M4 |
| §9 CI | Continuous |
| §10 Release | M5 |

---

## Not required for MVP (explicit)

- Online ranked / rollback netplay in shipped client  
- 4-player couch (P3/P4 ship blocked until spawn/camera/HUD pass)  
- Items / assist trophies  
- Story / career mode as gate for versus play  
- Godot runtime as primary battle path  
- Wearable / Edge-IO required input  

---

## Playtest record template

Create `docs/playtest/YYYY-MM-DD-mvp-check.md`:

```markdown
# MVP playtest — YYYY-MM-DD

- **Build:** commit / Pages URL
- **Tester:**
- **Browser:**

## Results
- Onboarding: pass / fail — notes
- Local MP: pass / fail — notes
- …

## Blockers
- …
```

---

## Sign-off

Product owner sign-off requires **all checkboxes** in sections 1–10 plus a linked playtest record. Partial credit does not ship as “fully operational.”

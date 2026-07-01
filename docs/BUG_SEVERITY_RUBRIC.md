# Bug Severity Rubric — Anime Aggressors

**Status:** Canonical triage standard  
**Last updated:** 2026-07-01  
**Used by:** Engineering, QA, production, community support

All bugs, blockers, and known issues must be classified using this rubric before merge, release, or completion sign-off.

---

## Severity levels

### P0 — Blocker (ship stop)

**Definition:** Prevents game launch, match start, movement, combat, input, or build.

| Examples | Not P0 |
|----------|--------|
| Build fails (`typecheck`, `test`, `build`) | Cosmetic HUD misalignment |
| Home or battle route crashes / blank screen | Preview fighter feels weak |
| Fighters do not move on input | Missing final SFX file |
| Combat never connects at point-blank | Training shows 6 of 15 moves |
| Keyboard/gamepad produces no `InputFrame` | CPU Lv3 too easy |
| Match cannot start (countdown stuck) | Mobile touch absent |
| Data corruption prevents any recovery | Shield SFX on shield start |

**Response:** Fix before any completion claim. No merge to completion branch with open P0.

**Tracking:** `docs/PRODUCTION_BLOCKERS.md` — status `open` until resolved.

---

### P1 — Critical (core gameplay broken, workaround exists)

**Definition:** Breaks core gameplay but a workaround exists.

| Examples | Not P1 |
|----------|--------|
| Quick Play broken but Start Game path works | Minor results screen layout issue |
| P2 keyboard broken but gamepad works | Preview fighter imbalance |
| One fighter cannot attack; others work | Procedural VFX not final art |
| CPU completely idle but human vs human works | Gamepad needs first button press |
| Training damage reset broken; restart match works | Career mode unpolished |
| Rematch broken; return to menu and restart works | 4-player blocked (documented out of scope → P2) |

**Response:** Fix before “complete” sign-off. May ship hotfix path only with documented workaround and owner approval.

**Tracking:** `docs/PRODUCTION_BLOCKERS.md` — must be `open` or `mitigated` with explicit workaround.

---

### P2 — Serious (UX / combat / readability)

**Definition:** Serious UX, combat, or readability problem that does not fully block play.

| Examples |
|----------|
| Mobile / touch controls not implemented |
| 4-player modes blocked in UI |
| Preview fighters noticeably uneven vs production 4 |
| Procedural audio/VFX clearly below production bar |
| Navigation confusion on secondary paths (career, replay vault) |
| Custom match setup easy to misconfigure |
| Manual playtest not yet signed off |
| CPU discoverability poor (if partial UI exists) |
| Keyboard P1/P2 overlap on single keyboard (documented) |

**Response:** Track in `docs/KNOWN_ISSUES.md` and `docs/PRODUCTION_BLOCKERS.md`. Acceptable for “local game complete” only if product owner explicitly waives with sign-off.

---

### P3 — Polish

**Definition:** Polish issue; game remains fully playable.

| Examples |
|----------|
| Training move list shows subset only |
| Shield block audio fires on shield start, not only on block |
| Some lab modes lack back-navigation polish |
| CPU functional but not tournament-grade |
| Gamepad requires button press before browser registers |
| Low-end GPU frame drops with debug overlay enabled |
| iOS Safari audio context needs extra tap |
| Lab/experimental UI density |

**Response:** Fix in polish sprint or post-completion backlog. Does not block local functional completion.

---

### P4 — Future enhancement

**Definition:** Future enhancement; not required for local functional platform fighter.

| Examples |
|----------|
| PWA / offline install flow |
| Online ranked / rollback netplay in shipped client |
| Engine migration (Godot, Unity, native) |
| Edge-IO / wearable required features |
| Final GLB rigs and DCC animation pipeline |
| Story / career expansion as core gate |
| Items / assist trophies |
| WCAG 2.1 AA full audit |
| Tournament matchmaking |

**Response:** Backlog only (`docs/BACKLOG.md`). Do not file as release blockers.

---

## Triage workflow

```
New issue reported
       │
       ▼
 Can user launch and play a match?
       │
   No ─┴─ Yes
   │         │
   ▼         ▼
 P0?      Core loop broken?
 (build,     │
  move,   No ─┴─ Yes
  combat,  │         │
  input)   ▼         ▼
       │  P1?    Readable/UX pain?
       │  (work-     │
       │   around)  ▼
       │         P2 vs P3
       │         (serious vs polish)
       ▼
 Assign ID in PRODUCTION_BLOCKERS.md
 Update KNOWN_ISSUES.md if user-visible
```

---

## Discipline ownership (default)

| Severity | Primary owner | Escalation |
|----------|---------------|------------|
| P0 | Engineering lead | Product owner same day |
| P1 | Engineering + QA | Product owner within 48 h |
| P2 | Discipline lead (UX, design, art) | Sprint planning |
| P3 | Owning discipline | Backlog grooming |
| P4 | Product | Roadmap review |

---

## Completion gate rule

| Status | Allowed open severities |
|--------|-------------------------|
| **Complete — local functional game** | P2+ only (with sign-off); **zero P0/P1** |
| **Playable alpha** | P0 = 0; P1 documented with workaround |
| **Internal dev** | Any; must be labeled honestly |

---

## Blocker record format

Every P0–P2 issue in `docs/PRODUCTION_BLOCKERS.md` must include:

1. **ID** — e.g. `BLK-###`
2. **Title**
3. **Severity** — P0–P4
4. **Discipline**
5. **Affected files**
6. **Reproduction steps**
7. **Expected behavior**
8. **Actual behavior**
9. **Fix plan**
10. **Acceptance test**
11. **Status** — `open` | `fixed` | `mitigated` | `wontfix`

---

## Related documents

- [PRODUCTION_BLOCKERS.md](./PRODUCTION_BLOCKERS.md) — active blocker registry
- [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) — user-facing limitations
- [PRODUCTION_COMPLETION_PLAN.md](./PRODUCTION_COMPLETION_PLAN.md) — completion gates
- [QUALITY_BAR.md](./QUALITY_BAR.md) — “Known P0 bugs open = 0” release rule

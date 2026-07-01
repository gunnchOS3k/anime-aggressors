# Known Issues — Production Completion

**Last updated:** 2026-07-01  
**Severity rubric:** `docs/BUG_SEVERITY_RUBRIC.md`  
**Blockers:** `docs/PRODUCTION_BLOCKERS.md`

---

## P0 / P1 (release blockers)

_None open after production completion pass._

Fixed in this pass:

- Movement scale too slow for stage size (BLK-001)
- Combat attacks interrupted by movement state overwrites (BLK-004)
- Navigation bypassed setup / stale localStorage (BLK-002)
- CPU levels 2–3 not exposed in UI (BLK-003)

---

## P2 — serious UX / readability

| ID | Issue |
|----|--------|
| P2-001 | No touch / on-screen mobile controls |
| P2-002 | Preview fighters (Nix, Orion, Vesper) balance-pending vs production four |
| P2-003 | Keyboard P1/P2 overlap on single keyboard |
| P2-004 | Training move list shows subset only (6 moves in overlay) |
| P2-005 | Manual browser playtest not signed off (see `docs/playtest/2026-07-01-full-game-completion-check.md`) |
| P2-006 | P3/P4 couch play blocked in UI |

---

## P3 — polish

| ID | Issue |
|----|--------|
| P3-001 | Procedural Web Audio placeholders — not final SFX |
| P3-002 | Simple geometry VFX — not final art direction |
| P3-003 | Shield audio may fire on shield start, not only on block |
| P3-004 | Career / replay vault not polished for casual players |
| P3-005 | CPU not tournament-grade (functional Lv1–3) |
| P3-006 | iOS Safari audio may need extra tap |
| P3-007 | Low-end GPU frame drops with debug overlays |

---

## P4 — future

| ID | Issue |
|----|--------|
| P4-001 | Online ranked / rollback netplay |
| P4-002 | Godot runtime as alternate engine (labs only) |
| P4-003 | Native desktop shell |
| P4-004 | PWA / offline install |
| P4-005 | Final GLB fighter assets pipeline |

---

## Engine note

TypeScript web runtime remains the production path. See `docs/ENGINE_MIGRATION_DECISION.md` for limits and future options.

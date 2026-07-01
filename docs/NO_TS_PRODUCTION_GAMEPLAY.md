# No TypeScript Production Gameplay

**Status:** Engineering policy  
**Related:** [RUNTIME_SOURCE_OF_TRUTH.md](./RUNTIME_SOURCE_OF_TRUTH.md)

---

## Rule

**Do not add new production gameplay features to:**

- `apps/web/src/game/`
- `apps/web/src/renderer-three/`
- `packages/game-core/src/` (except tests, data specs, validation helpers)

Production gameplay belongs in **`game-godot/`** only.

---

## What TypeScript may still do

| Allowed | Examples |
|---------|----------|
| Unit/regression tests | Movement feel, combat math, roster rules |
| Data generation | `scripts/generate-godot-full-scope-data.mjs` |
| CI validation | `scripts/validate-full-scope-production.mjs` |
| Web shell | Home, routing, Godot embed, runtime banners |
| Career/meta (web) | Stats, replays in localStorage |
| Documentation | Specs, acceptance criteria |

---

## What TypeScript must not do (going forward)

- New attack timelines rendered in Three.js
- New fighter mechanics only in `game-core` without Godot port
- New menu flows that imply TS battle is the primary path
- Unlabeled legacy battle as default home CTA

---

## Enforcement

1. **Code review** — reject PRs that add production combat/menu logic only in TS
2. **CI** — `npm run validate:full-scope-production` checks docs + data gates
3. **UI labels** — Legacy routes show: *"Legacy Web Runtime — reference only, not final gameplay."*
4. **`packages/game-core/README.md`** — contributor warning at package root

---

## Porting workflow

1. Define behavior in Godot (`game-godot/scripts/`)
2. Optionally add/update `game-core` test as oracle
3. Update Godot data manifests
4. Run `node scripts/generate-godot-full-scope-data.mjs` if using generator
5. Run `npm run validate:full-scope-production`

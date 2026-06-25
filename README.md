# Anime Aggressors

Original shōnen-inspired **2-player platform fighter** built around a **deterministic simulation core** and **rollback-first architecture**. Optional **Edge-IO** wearables map gestures into the same input model as keyboard and gamepad — hardware is never required to play.

**Current milestone:** v0.1 deterministic web vertical slice  
**Branch:** `revive-product-rollback-vertical-slice`

---

## What this is

- Couch multiplayer platform fighter (Smash-style stocks and blast zones) with **original characters** — no third-party anime IP.
- Fixed **60 Hz** simulation in TypeScript (`packages/game-core`).
- **Rollback session** (`packages/rollback`) used even for local play so online, replay, and debug share one code path.
- Web demo via Vite + Canvas (`apps/web`).
- Edge-IO protocol defined in binary (`packages/edgeio`) for future rings/wristbands.

---

## What works today

| Feature | Location |
|---------|----------|
| 2P local match (keyboard + gamepad) | `apps/web` vertical slice |
| Characters: Ember Vale, Tide Kuro | `packages/game-core/src/characters.ts` |
| Stage: Skyline Arena | `packages/game-core/src/stages.ts` |
| Stocks, percent damage, blast zones, timer | `packages/game-core` |
| Character select → countdown → fight → results → rematch | `apps/web/src/game/` |
| Debug overlay (frame, hash, inputs, rollback count) | `debugOverlay.ts` |
| Determinism + replay tests | `packages/game-core/test/` |
| Rollback harness tests | `packages/rollback/test/` |
| Edge-IO binary parser tests | `packages/edgeio/test/` |
| Training Lab mini-games (prototype) | `apps/web/src/minigames/` |

See **[docs/STATUS.md](docs/STATUS.md)** for the full honest matrix.

---

## What does not work yet

- **Online multiplayer** — transport not implemented.
- **Real BLE hardware loop** — firmware sends JSON today, not canonical binary protocol; compile on nRF52840 unverified in CI.
- **Production art/audio** — placeholder canvas rendering only.
- **Mobile app, desktop app, Godot engine** — not part of active vertical slice (legacy README claims removed).
- **Fabrication-ready hardware** — no KiCad/Gerber package; see hardware plan docs.
- **3–4 player**, remapping UI, touch controls — planned v0.5.

---

## Quick start

**Requirements:** Node.js ≥ 20, npm

```bash
git clone https://github.com/gunnchOS3k/anime-aggressors.git
cd anime-aggressors
npm install
npm run dev
```

Open the URL Vite prints (typically `http://localhost:5173`), then click **Play Anime Aggressors Vertical Slice**.

### Controls

| Player | Movement | Jump | Attack | Special | Shield | Dodge | Grab |
|--------|----------|------|--------|---------|--------|-------|------|
| P1 | Arrows | ↑ / Space | Z | X | C | V | B |
| P2 | WASD | W | 1 | 2 | 3 | 4 | 5 |

Gamepads auto-assign: pad 0 → P1, pad 1 → P2 when connected.

---

## Tests and quality

```bash
npm run typecheck          # all workspaces
npm run test               # game-core, rollback, edgeio
npm run build:web          # production web build
npm run quality            # typecheck + test + build:web
```

Package-specific:

```bash
npm run test -w packages/game-core
npm run test -w packages/rollback
npm run test -w packages/edgeio
```

---

## Rollback (introduction)

All gameplay authority lives in `packages/game-core`. Each frame, inputs are normalized to `InputFrame` objects, then fed to `RollbackSession.advanceFrame()`.

For local couch play today, both players' inputs are treated as confirmed immediately. The same session will **predict** remote inputs when online latency is introduced, **rollback** if predictions were wrong, and **resimulate** to the current frame — verified by hash against an authoritative input replay.

Read more: **[docs/ROLLBACK_DESIGN.md](docs/ROLLBACK_DESIGN.md)**

---

## Edge-IO (intent)

Edge-IO wearables (ring/wristband) send compact binary packets:

- **SensorNotify** (22 B) — IMU stream + battery
- **GestureNotify** (12 B) — tap, swipes, thrust, etc.
- **HapticWrite** (4 B) — host → device feedback (optional, never required for fairness)

TypeScript parser: `packages/edgeio`. Gestures map to normal actions (dodge, attack, shield) via the same `InputFrame` path as keyboard.

**Prototype path:** nRF52840 dev-board mule first, wristband EVT second, custom ring later. No fake manufacturing files in repo.

Read more: **[docs/EDGE_IO_PROTOCOL.md](docs/EDGE_IO_PROTOCOL.md)** · **[docs/HARDWARE_PROTOTYPE_PLAN.md](docs/HARDWARE_PROTOTYPE_PLAN.md)**

---

## Repository structure

```text
apps/web/              Playable web vertical slice + Training Lab
packages/game-core/    Deterministic 60 Hz simulation
packages/rollback/     Snapshot / prediction / rollback harness
packages/edgeio/       Binary BLE protocol + gesture mapping
firmware/ring/         Wearable firmware (work in progress)
hardware/ring/         Ring EVT documentation path (no Gerbers yet)
hardware/wristband/    Dev-board mule BOM path (recommended first)
docs/                  PRD, architecture, STATUS, backlog, ADRs
```

Legacy `web/` React tree may still exist — canonical app is **`apps/web`**.

---

## Documentation index

| Document | Purpose |
|----------|---------|
| [docs/STATUS.md](docs/STATUS.md) | Honest capability matrix |
| [docs/PRODUCT_REQUIREMENTS.md](docs/PRODUCT_REQUIREMENTS.md) | Canonical PRD (37 sections) |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 90-day system structure |
| [docs/ROLLBACK_DESIGN.md](docs/ROLLBACK_DESIGN.md) | Rollback architecture |
| [docs/INPUT_SYSTEM.md](docs/INPUT_SYSTEM.md) | Keyboard, gamepad, wearable mapping |
| [docs/EDGE_IO_PROTOCOL.md](docs/EDGE_IO_PROTOCOL.md) | Binary packet spec |
| [docs/HARDWARE_PROTOTYPE_PLAN.md](docs/HARDWARE_PROTOTYPE_PLAN.md) | Mule → EVT → ring path |
| [docs/QUALITY_BAR.md](docs/QUALITY_BAR.md) | AAA-inspired measurable standards |
| [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | Milestone gates |
| [docs/BACKLOG.md](docs/BACKLOG.md) | Prioritized work |
| [docs/AUDIT_ACTION_PLAN.md](docs/AUDIT_ACTION_PLAN.md) | Phased recovery plan |
| [docs/decisions/ADR-0001-firmware-stack.md](docs/decisions/ADR-0001-firmware-stack.md) | Firmware stack decision |

---

## Contributing

1. Read [docs/PRODUCT_REQUIREMENTS.md](docs/PRODUCT_REQUIREMENTS.md) and [docs/STATUS.md](docs/STATUS.md) before large changes.
2. Follow [docs/PULL_REQUEST_CHECKLIST.md](docs/PULL_REQUEST_CHECKLIST.md) — **CI must be green**.
3. Run `npm ci && npm run quality` before opening a PR.
4. Keep simulation deterministic — no DOM/BLE in `game-core`.
5. Do not add copyrighted characters or oversell hardware readiness.

---

## License

MIT — see [LICENSE](LICENSE).

---

**Built as a rollback-first platform fighter vertical slice — honest prototype toward v0.5 public demo and optional Edge-IO hardware.**

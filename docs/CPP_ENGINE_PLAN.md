# C++ Engine Plan (Track C)

**Last updated:** 2026-06-24  
**Status:** Skeleton compiles in CI; not authoritative for shipping gameplay  
**Authoritative sim (today):** `packages/game-core` (TypeScript)

---

## Purpose

Build a **deterministic native simulation library** (`native/engine/`) that can eventually:

- Power performance-sensitive simulation (benchmarking, server-side validation).
- Compile to WebAssembly for optional hot-path acceleration in the browser.
- Integrate with desktop (Track E) or mobile (Track D) shells without replacing the TS rollback stack overnight.

The C++ engine **does not** replace `game-core` until parity is proven by shared test vectors and cross-language hash agreement.

---

## Current state (honest)

| Component | Status |
|-----------|--------|
| `native/engine/include/aa/simulation.hpp` | `InputFrame`, `PlayerState`, `GameState`, `GameConfig` |
| `native/engine/src/simulation.cpp` | Minimal `simulate_frame`, `hash_state` |
| `native/engine/tests/determinism_test.cpp` | Same-input → same-hash test |
| Root `CMakeLists.txt` | Delegates to `native/engine` |
| CI `native-engine` job | Configure, build, `ctest` on Ubuntu |
| Combat, stages, rollback | **Not ported** — skeleton only |
| WASM build | **Not started** (C3/C4) |
| Graphics / audio / AI | **Out of scope** until sim parity |

**Do not claim** the C++ engine is feature-complete or used by `apps/web` today.

---

## Relationship to `packages/game-core`

```text
                    ┌─────────────────────────┐
                    │   apps/web (renderer)   │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  packages/rollback      │
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
    ┌─────────▼─────────┐             ┌──────────▼──────────┐
    │ packages/game-core │             │  native/engine (C++) │
    │  (authoritative)   │             │  (experimental)      │
    └────────────────────┘             └─────────────────────┘
```

| Concern | `game-core` (TS) | `native/engine` (C++) |
|---------|------------------|------------------------|
| Shipping gameplay | **Yes** | No |
| Rollback integration | **Yes** | Future optional |
| Determinism tests | **Yes** (CI required) | Yes (CI `native-engine` job) |
| Combat / stages | Implemented | Not ported |
| Fixed-point (`FP_SCALE=256`) | Yes | Header constant; partial use |
| State serialization | JSON stringify (known risk) | String hash stub |

### Parity strategy (C3+)

1. **Shared test vectors:** JSON files with `GameConfig`, input log, expected hash — run in both TS and C++.
2. **Field alignment:** `InputFrame` and `PlayerState` fields must match `packages/game-core/src/types.ts` naming and scale.
3. **No silent drift:** CI fails if C++ hash diverges from TS on shared vectors (future gate).
4. **Rollback stays in TS** until online path is stable; native sim is a drop-in `simulateFrame` only when parity proven.

---

## Directory layout

```text
native/engine/
├── CMakeLists.txt
├── include/aa/
│   └── simulation.hpp      # Public API
├── src/
│   └── simulation.cpp      # Implementation
└── tests/
    └── determinism_test.cpp
```

Legacy `legacy/game-prototype/performance_engine.cpp` is **archived** — do not extend it.

---

## WASM boundary (C3/C4 — planned)

### Design goals

- Expose a **narrow C ABI** (or `extern "C"` wrappers) for: `create_initial_state`, `simulate_frame`, `hash_state`, `free_state` (if heap-allocated).
- No C++ exceptions across the WASM boundary.
- Linear memory owned by WASM module; TS copies in/out via `Uint8Array`.

### Proposed boundary (draft)

```c
// Future: native/engine/include/aa/abi.h
typedef struct aa_game_state_opaque aa_game_state_t;

aa_game_state_t* aa_create_initial_state(const aa_game_config_t* config);
void aa_simulate_frame(aa_game_state_t* state, const aa_input_frame_t* inputs, int count);
uint64_t aa_hash_state(const aa_game_state_t* state);
void aa_destroy_state(aa_game_state_t* state);
```

### Integration options

| Option | Pros | Cons |
|--------|------|------|
| WASM in web worker | Off main thread; near-native speed | Build pipeline complexity |
| WASM on main thread | Simpler glue | Jank risk if sim heavy |
| Native only (desktop) | Best perf | No web benefit |

**Decision:** Defer C4 until C2 parity vectors pass. Web shipping continues on TS `game-core`.

### Emscripten spike checklist (C4)

- [ ] `emcmake cmake` target `aa_engine_wasm`
- [ ] Export `_aa_*` functions
- [ ] Load from `apps/web` behind feature flag `USE_NATIVE_SIM=0` default off
- [ ] Benchmark: 10k frames TS vs WASM on same input log

---

## CI integration

`.github/workflows/quality.yml` includes job `native-engine`:

```yaml
- cmake -S native/engine -B build/native-engine -DCMAKE_BUILD_TYPE=Release
- cmake --build build/native-engine --config Release
- ctest --test-dir build/native-engine --output-on-failure
```

| Policy | Detail |
|--------|--------|
| Blocking | Yes — C++ must compile on PR |
| WASM | Not in CI until C4 spike lands |
| Firmware | Separate non-blocking `firmware-audit` job |

Local:

```bash
cmake -S native/engine -B build/native-engine -DCMAKE_BUILD_TYPE=Release
cmake --build build/native-engine
ctest --test-dir build/native-engine --output-on-failure
```

---

## Milestones (Track C cross-reference)

| ID | Deliverable | Status |
|----|-------------|--------|
| C0 | CMake only real files | Done |
| C1 | Native sim skeleton | Done |
| C2 | Determinism test | Done |
| C3 | ABI / WASM boundary doc | This file |
| C4 | Emscripten spike | Not started |
| C5 | Desktop native link | Not started |
| C6 | Benchmark suite | Not started |

---

## Non-goals (explicit)

- Full game engine (rendering, physics broadphase, animation) in C++ v1.
- Replacing TypeScript rollback session in C++ before B6 online playtest.
- Placeholder AI, audio engines, or networking in `native/engine/`.
- Breaking `npm run quality` if native build fails on a platform — Linux CI is the gate.

---

## Related documents

- [ROADMAP_FULL_COMPLETION.md](./ROADMAP_FULL_COMPLETION.md) — Track C milestones
- [ARCHITECTURE.md](./ARCHITECTURE.md) — Parallel tracks
- [ROLLBACK_DESIGN.md](./ROLLBACK_DESIGN.md) — Rollback stays TS-first
- `legacy/game-prototype/README.md` — Archived predecessor

# Engine Migration Decision — Anime Aggressors

**Status:** Decision proposal (documentation only)  
**Last updated:** 2026-07-01  
**Revisit date:** 2026-09-01 (after public demo + engine spike)

> **This document does not authorize or perform engine migration.** Milestone 5 ships the TypeScript + Three.js web demo. Migration becomes its own milestone only if this proposal is approved and a spike proves value.

---

## Current state of Anime Aggressors

| Layer | Technology | Maturity |
|-------|------------|----------|
| Simulation | TypeScript `packages/game-core` | M1–M4 proven (platform, movement, combat, roster) |
| Rollback harness | TypeScript `packages/rollback` | Local/replay tested |
| Web client | Vite + hash routes | GitHub Pages deployable |
| Rendering | Three.js procedural | Playable, not final art |
| Labs | Godot export, Edge-IO, derby, flagline | Experimental, separated from demo |

---

## What TypeScript has proven so far

- Deterministic 60 Hz fixed-point simulation with extensive unit tests
- Platform-fighter movement feel (M2), combat grammar (M3), 7-fighter roster slice (M4)
- Rollback-friendly state hashing and input frames
- Rapid iteration for designers/engineers in a monorepo
- Browser-playable vertical slice without native install

---

## What TypeScript should not be trusted to solve forever

- Console-grade frame pacing and GPU skinning at scale
- Native controller latency on all platforms
- Mobile thermal/battery performance with rich VFX
- AAA animation blending, IK, and cinematic pipelines
- Shipping on Switch/console without a native runtime wrapper
- Long-term art team workflow (DCC → engine) at production scale

---

## What must be preserved in any migration

1. **game-core rules as spec/oracle** — hitboxes, movement constants, combat grammar, roster data
2. **Deterministic simulation contract** — 60 Hz, `InputFrame`, reproducible tests
3. **Rollback design assumptions** — serializable state, frame inputs
4. **Existing 7 fighters + 3 production stages** as content baseline
5. **Playable web path** until native demo replaces it

---

## Option comparisons

### 1. Keep TypeScript + Three.js (web)

| | |
|--|--|
| **Summary** | Continue shipping browser MVP on current stack |
| **Strengths** | Fastest path to public demo; tests already green; no rewrite |
| **Weaknesses** | Performance ceiling; procedural art limits; mobile weak |
| **Performance risks** | Medium on desktop; high on mobile |
| **Browser/mobile** | Desktop OK; mobile touch not production-ready |
| **Controller** | Gamepad API works; not as tight as native |
| **Animation** | Procedural poses; limited choreography |
| **Rollback/netplay** | Best fit — same language as sim |
| **Deterministic portability** | Already authoritative |
| **Asset pipeline** | Code-first; weak for DCC |
| **Dev speed** | Highest |
| **Testing** | Excellent (unit + web smoke) |
| **Hiring** | Web/TS talent plentiful |
| **Risk** | Low short-term, medium long-term |
| **Use case** | Public demo, playtests, design iteration |

### 2. Godot 4 + GDScript

| | |
|--|--|
| **Summary** | Migrate presentation + eventually sim to Godot |
| **Strengths** | Fast prototyping; good 2.5D; export targets |
| **Weaknesses** | GDScript perf; team may prefer TS/C# |
| **Performance** | Good for indie 2.5D |
| **Browser** | Web export usable but heavier than Vite SPA |
| **Controller** | Strong native; web export variable |
| **Animation** | Strong with proper rigs |
| **Rollback** | Must re-port sim or FFI to TS core |
| **Determinism** | Needs careful fixed-point port |
| **Assets** | Blender → Godot pipeline exists in repo docs |
| **Dev speed** | Medium |
| **Testing** | Weaker than TS unit suite unless hybrid |
| **Hiring** | Godot community growing |
| **Risk** | Medium |
| **Use case** | Native desktop/mobile demo after spike |

### 3. Godot 4 + C#

| | |
|--|--|
| **Summary** | Godot with C# for sim-heavy code |
| **Strengths** | Stronger typing; closer to enterprise patterns |
| **Weaknesses** | C# support varies by export target; heavier builds |
| **Performance** | Better than GDScript for sim |
| **Browser** | Web export with C# is limited |
| **Controller** | Good on desktop/console exports |
| **Animation** | Same as Godot |
| **Rollback** | Port sim to C# or bind TS |
| **Determinism** | Achievable with fixed-point discipline |
| **Assets** | Same Godot pipeline |
| **Dev speed** | Medium-slow |
| **Testing** | xUnit-style possible |
| **Hiring** | Unity refugees |
| **Risk** | Medium-high |
| **Use case** | Desktop-first if team is C#-heavy |

### 4. Godot 4 + C++ GDExtension

| | |
|--|--|
| **Summary** | Hot sim in C++; Godot for presentation |
| **Strengths** | Best Godot perf; rollback-friendly sim |
| **Weaknesses** | Build complexity; FFI boundary |
| **Performance** | High |
| **Browser** | Web export still constrained |
| **Controller** | Native excellent |
| **Animation** | Godot side |
| **Rollback** | Ideal if sim is C++ |
| **Determinism** | Excellent in C++ |
| **Assets** | Godot presentation |
| **Dev speed** | Slow |
| **Testing** | C++ test harness needed |
| **Hiring** | Specialized |
| **Risk** | High |
| **Use case** | Competitive netplay-native path |

### 5. Unity + C#

| | |
|--|--|
| **Summary** | Industry-standard 3D/2.5D toolchain |
| **Strengths** | Mature animation, VFX, hiring pool |
| **Weaknesses** | License/runtime cost; web export weak |
| **Performance** | Good on target platforms |
| **Browser** | Poor for fighter web demo |
| **Controller** | Excellent |
| **Animation** | Best-in-class for indie AAA |
| **Rollback** | Custom sim layer required |
| **Determinism** | Harder — floating point defaults |
| **Assets** | Strong DCC pipeline |
| **Dev speed** | Medium (rewrite cost high) |
| **Testing** | PlayMode tests |
| **Hiring** | Large pool |
| **Risk** | High for this repo's web-first proof |
| **Use case** | Console SKU later |

### 6. Custom C++ engine (later)

| | |
|--|--|
| **Summary** | Own runtime after product proof |
| **Strengths** | Maximum control; rollback/netplay |
| **Weaknesses** | Years of tooling work |
| **Performance** | Highest |
| **Browser** | Requires WASM port for web |
| **Controller** | Full control |
| **Animation** | Build or license |
| **Rollback** | Native design |
| **Determinism** | Native design |
| **Assets** | Custom |
| **Dev speed** | Very slow |
| **Testing** | Custom |
| **Hiring** | Expensive |
| **Risk** | Very high early |
| **Use case** | Post-PMF commercial product |

---

## Candidate architecture after migration (if approved)

```
┌─────────────────────────────────────┐
│  Presentation (Godot / native UI)   │
├─────────────────────────────────────┤
│  Ported sim OR GDExtension/C++ core  │  ← ported from game-core spec
├─────────────────────────────────────┤
│  game-core TS tests as oracle       │  ← kept until parity proven
└─────────────────────────────────────┘
```

Hybrid interim: **TS game-core in WASM** + Godot/native shell (spike option).

---

## Minimum migration proof-of-concept

1. One production fighter (Ember Vale) + Skyline Arena
2. Movement + one attack + shield + KO
3. Gamepad feel comparison vs web build
4. Frame time budget on target hardware
5. Determinism check: same inputs → same KO frame (±0)

---

## Recommendation

**Ship the public MVP/demo on the current TypeScript + Three.js path.**

- Keep `game-core` as the authoritative design/spec/test oracle.
- After M5 public demo traction, run a **dedicated engine spike** (4–6 weeks):
  - Godot 4 GDScript or C# prototype with one fighter
  - Optional C++ GDExtension deterministic sim prototype
  - Compare feel, performance, controller latency, export targets
- **Do not rewrite** until the spike proves measurable value over web demo limits.

---

## Decision

| Field | Value |
|-------|-------|
| **Proposal** | Stay on TypeScript + Three.js for public demo; defer migration |
| **Approved by** | _Pending product/engineering review_ |
| **Effective** | After M5 merge |
| **Next action** | Schedule engine spike milestone if demo KPIs met |

---

## Revisit date

**2026-09-01** — Re-evaluate after:
- Public demo deploy + playtest feedback
- Engine spike results (if started)
- Performance issues on target browsers/devices

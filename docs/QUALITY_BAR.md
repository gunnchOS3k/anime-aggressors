# Quality Bar — AAA-Inspired Measurable Standards

**Status:** Active quality contract for Anime Aggressors  
**Last updated:** 2026-06-24

> We use **AAA-inspired** standards: the ambition of commercial fighters, with honest milestone gates. We do **not** claim AAA production completion until v1.0 release checklist is signed.

---

## How to read this document

| Column | Meaning |
|--------|---------|
| **Metric** | What we measure |
| **v0.1 target** | Vertical slice gate |
| **v0.5 target** | Public demo gate |
| **v1.0 target** | Commercial-quality gate |
| **Verification** | How we prove it |

---

## Simulation & netcode

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Sim tick rate | 60 Hz fixed | 60 Hz | 60 Hz | `SIM_HZ` constant; frame counter |
| Deterministic replay hash match | 100% CI tests | 100% | 100% | `determinism.test.ts`, `rollback.test.ts` |
| Cross-browser hash match (2P, 600 frames) | Not required | ≥ 99% sessions | 100% | Automated Playwright + input log |
| Rollback recovery (100 ms RTT) | Unit test only | Visible rollback ≤ 3 frames jitter | ≤ 2 frames | Online soak test |
| Desync rate (online) | N/A | < 1 per 10 matches | < 1 per 50 | Telemetry opt-in |
| Input log replay fidelity | Manual | Export/import JSON | Signed replay format | Round-trip test |

---

## Gameplay feel

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Input-to-action latency (local) | Best effort | p50 ≤ 50 ms | p50 ≤ 40 ms | High-speed cam / timestamp |
| Jump startup frames | Documented | ≤ 4 frames | Tuned per char | Frame data sheet |
| Hitstop on connect | Optional | 2–4 frames | Consistent | Slow-mo capture |
| KO readability | Blast zone + stock UI | KO flash + SFX | Full VFX | Playtest survey ≥ 4/5 |
| Match length (2P casual) | 3–8 min typical | Same | Same | Analytics median |
| Rematch flow | ≤ 2 clicks | ≤ 1 click | Instant queue | Timed UX test |

---

## Performance (web vertical slice)

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Render FPS (1080p canvas) | ≥ 55 FPS avg | ≥ 60 FPS | ≥ 60 FPS | Chrome perf overlay |
| Sim CPU per frame (2P) | < 3 ms | < 2 ms | < 2 ms | `performance.now()` probe |
| Main bundle gzip | < 500 KB slice | < 800 KB full demo | Budget TBD | `vite build` analyze |
| Time to interactive (landing) | < 3 s | < 2 s | < 2 s | Lighthouse |
| Memory stable 30 min | No leak > 50 MB | Same | Same | DevTools heap |

**Reference hardware:** 2020 laptop (i5-8250U / 8 GB RAM) or M1 MacBook Air.

---

## Input quality

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Keyboard listener duplication | 0 extra pairs | 0 | 0 | DevTools audit |
| Gamepad hot-plug | Next frame assign | Same | Same | Manual test |
| Stuck input on blur | Keys cleared | Same | Same | Alt-tab test |
| Remapping coverage | Defaults only | 100% actions | Presets + custom | Settings test |
| Input buffer (optional) | Off | 1–3 frames | Configurable | Frame-perfect test |

---

## Edge-IO & hardware

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Protocol parser tests | 100% pass | Same | Same | CI |
| Gesture → InputFrame mapping | Unit tested | Live mule | Retail SKU optional | Integration test |
| Gesture latency p50 | N/A (software) | < 50 ms | < 40 ms | HW validation matrix |
| BLE notify drop rate | N/A | < 1% / 1 h | Same | Soak test |
| Battery active life | N/A | ≥ 3 h | ≥ 4 h | Discharge test |
| Game playable without wearable | Required | Required | Required | Keyboard-only match |

---

## Content & IP

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Original character names | 100% | 100% | 100% | Legal review |
| No third-party fighter move clones | Best effort | Reviewed | Signed off | Design audit |
| Placeholder art acceptable | Yes | Readable silhouettes | Production art | Art director sign-off |

---

## Accessibility

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| Keyboard-complete match | Yes | Yes | Yes | Manual |
| WCAG 2.1 AA (web UI) | Partial | Major flows | Full audit | axe / manual |
| Color-only damage cues | Avoid | Avoid | Avoid | Colorblind sim |
| Reduce motion option | No | Basic | Full | Settings test |

---

## Engineering hygiene

| Metric | v0.1 | v0.5 | v1.0 | Verification |
|--------|------|------|------|--------------|
| `npm run quality` green | Required | CI required | CI required | GitHub Actions |
| Unit test count (core packages) | ≥ 10 tests | ≥ 25 | Growing | `npm test` |
| Typecheck strict | Workspace | Same | Same | `npm run typecheck` |
| PRD traceability | Major features cite PRD § | All features | All | Review checklist |
| STATUS.md accuracy | Updated each milestone | Same | Same | Doc review |
| No secrets in repo | Always | Always | Always | Secret scan |

---

## Release confidence

| Gate | v0.1 | v0.5 | v1.0 |
|------|------|------|------|
| Manual playtest script | 3 matches | 10 external testers | Beta cohort |
| Crash on match complete | 0 | 0 | < 0.1% sessions |
| Known P0 bugs open | 0 for slice scope | 0 | 0 |
| VALIDATION_REPORT.md | Required | Updated | Updated |

---

## Anti-patterns (explicitly forbidden)

- Claiming "AAA complete" or "shipping" without gate sign-off
- Adding non-deterministic RNG to sim without seeded PRNG
- BLE raw bytes in `game-core`
- Fake KiCad/Gerber files in repo
- Copyrighted character or move implementation

---

## Related documents

- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) §7
- [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md)
- [STATUS.md](./STATUS.md)

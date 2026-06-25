# Anime Aggressors — Product Requirements Document

**Version:** 0.1  
**Status:** Canonical product compass  
**Last updated:** 2026-06-24  
**Milestone focus:** v0.1 deterministic web vertical slice

---

## 1. Product title and one-line promise

**Anime Aggressors** — an original shōnen-inspired platform fighter where couch multiplayer, rollback netcode, and optional Edge-IO wearables share one deterministic simulation path.

**Promise:** Fast, readable, competitive 2–4 player platform fighting that feels great on keyboard and controller, with wearables as an optional superpower—not a requirement.

---

## 2. Product vision

Build a platform fighter with:

- Local couch multiplayer as the emotional core (Smash-style sessions, original IP).
- Rollback netcode for online and as the **same** simulation driver locally (replays, debug, tournaments).
- Optional Edge-IO rings/wristbands mapping into standard `InputFrame` actions.
- Cross-platform delivery starting with web; mobile/desktop later.
- Original characters, stages, mechanics—no third-party anime or fighter IP.

---

## 3. Target audience

| Segment | Needs | Success signal |
|---------|-------|----------------|
| Couch party players | Easy pick-up, readable UI, 2P on one screen | Friends finish a match without tutorial |
| Platform fighter enthusiasts | Movement options, stocks, percent, rollback fairness | Positive feedback on feel vs. genre expectations |
| Hardware early adopters | Gesture input + haptics that map to real actions | Wearable dodge/attack usable in casual play |
| Developers / modders | Deterministic sim, data-driven characters | Can add character JSON without forking renderer |
| Investors / advisors | Honest milestone docs, measurable gates | STATUS.md matches demo |

**Primary v0.1 audience:** Developers and playtesters validating deterministic couch slice.

---

## 4. Competitive positioning

| Dimension | Anime Aggressors | Typical platform fighter |
|-----------|------------------|---------------------------|
| Netcode model | Rollback-first from day one | Often delay-based or added late |
| Hardware | Optional wearables with binary protocol | Controller-only |
| Engine | TS deterministic core, web-first | Native engine (Unity, custom C++) |
| IP | 100% original roster | Licensed or established franchises |
| Scope v0.1 | Vertical slice honesty | Often silent on missing features |

**Positioning statement:** "Rollback-native platform fighter with optional motion wearables—honest prototype to commercial path."

---

## 5. What makes Anime Aggressors distinct

1. **Single sim path:** Couch, online, replay, and debug all consume `InputFrame[]` → `simulateFrame`.
2. **Edge-IO as input layer:** Gestures map to dodge/attack/shield—not a parallel game mode.
3. **Fixed 60 Hz integer-friendly physics** in `packages/game-core` for lockstep readiness.
4. **Transparent docs:** STATUS, PRD, and README do not oversell Godot/mobile/hardware fabrication.
5. **Original shōnen identity:** Ember Vale, Tide Kuro, and future roster without derivative names/moves.

---

## 6. Player experience pillars

| Pillar | Requirement | Measurement |
|--------|-------------|-------------|
| **Responsive** | Input-to-action ≤ 50 ms (standard controllers, local) | High-speed camera or input timestamp test, p50 |
| **Readable** | Hitboxes, damage, stocks visible | Usability test: 8/10 players identify leader |
| **Fair** | No pay-to-win; wearables not required | Full match completable keyboard-only |
| **Social** | Quick rematch, character select < 30 s | Timed playtest flow |
| **Expressive** | Movement + attack + special + shield + dodge | All actions reachable in tutorial match |

---

## 7. AAA-inspired quality bar

See `docs/QUALITY_BAR.md` for full metrics. Summary:

- Simulation: fixed 60 Hz; determinism tests pass 100% in CI.
- Performance: stable 60 FPS render on 2020-era laptop (1080p canvas).
- Input: no dropped keyboard state on blur; gamepad hot-plug within 1 frame.
- Online (v0.5+): rollback recovery without visible freeze > 3 frames at 100 ms RTT.
- Content: no placeholder text in shipping UI (v1.0).

**We do not claim AAA production completion in v0.1.**

---

## 8. MVP / v0.1 vertical slice scope

**In scope:**

- 2 players, 1 stage, 2 characters
- Stocks (default 3), blast zones, match timer (default 180 s)
- Attack, special, shield, dodge, grab, jump, double jump
- Character select → countdown → fight → results → rematch
- `packages/game-core`, `packages/rollback`, `apps/web` vertical slice
- Keyboard + gamepad; Edge-IO protocol in software only

**Out of scope for v0.1:** Online, touch, production art, real BLE hardware, 3+ players.

**Acceptance:** All v0.1 exit criteria in `docs/STATUS.md` checked.

---

## 9. v0.5 public demo scope

- Public web deploy with polish pass on UI
- Simulated or real online 2P rollback match
- Web Bluetooth Edge-IO dev-board demo
- 3+ characters, 2+ stages
- Input remapping UI
- Replay export (JSON input log minimum)
- CI `quality` gate green

**Acceptance:** External playtester completes online match without desync; README demo link works.

---

## 10. v1.0 commercial-quality scope

- 4+ characters, 4+ stages, training mode
- Ranked/casual online with matchmaking stub
- Mobile-friendly touch layout
- Optional Edge-IO retail SKU (wristband first)
- Full art/audio pass, accessibility WCAG 2.1 AA for web UI
- Store-ready builds (TBD platform: Steam and/or console web wrapper)

**Acceptance:** RELEASE_CHECKLIST v1.0 section signed; crash rate < 0.1% per session (instrumented).

---

## 11. Core game loop

```
Character Select → Stage Load → Countdown (3 s)
  → Fighting (stock/percent combat)
  → Results (winner, stats)
  → Rematch or Return to Select
```

**Frame budget:** 1 simulation frame = 16.67 ms; rendering may interpolate visually but must not affect sim.

---

## 12. Match flow

| Phase | Sim phase | Duration | Requirements |
|-------|-----------|----------|--------------|
| Character select | UI only (non-authoritative) | User-driven | 2P confirm; original chars only |
| Countdown | `countdown` | 3 s (180 frames) | No damage; inputs ignored or buffered per design |
| Fighting | `fighting` | Until win condition | Timer decrements each frame |
| Results | `results` | Until user action | Show winner, stocks, damage |
| Rematch | Reset state | Instant | Same config unless user returns to select |

**Win conditions:** Last stock standing; or highest stocks at timer; tie-breaker lowest damage %.

---

## 13. Combat requirements

| Req ID | Requirement | Target | v0.1 |
|--------|-------------|--------|------|
| COM-01 | Light attack with hitbox/hurtbox | 8–12% damage (char-dependent) | Yes |
| COM-02 | Special attack, longer startup | 14–18% damage | Yes |
| COM-03 | Shield with depleting resource | SHIELD_MAX = 100 | Yes |
| COM-04 | Dodge with i-frames | DODGE_FRAMES = 12 | Yes |
| COM-05 | Grab action | State transition | Yes (basic) |
| COM-06 | Hitstun on connect | HITSTUN_BASE + scaling | Yes |
| COM-07 | Knockback scales with damage | Measurable displacement | Yes |
| COM-08 | Blast zone KO | Stock decrement | Yes |
| COM-09 | Invulnerability after respawn | invulnFrames > 0 | Partial |
| COM-10 | No same-frame double-hit exploit | Single hit per attack window | Test required |

---

## 14. Movement requirements

| Req ID | Requirement | Constant / note |
|--------|-------------|-----------------|
| MOV-01 | Fixed 60 Hz integration | SIM_HZ = 60 |
| MOV-02 | Run speed | RUN_SPEED (fixed-point) |
| MOV-03 | Jump + double jump | maxJumps per character (2 default) |
| MOV-04 | Air control | AIR_CONTROL |
| MOV-05 | Gravity cap | MAX_FALL_SPEED |
| MOV-06 | Stage floor collision | floorY from stage def |
| MOV-07 | Facing flip on direction change | facing: 1 \| -1 |

---

## 15. Input requirements

| Req ID | Requirement | Measurement |
|--------|-------------|-------------|
| INP-01 | Sim consumes only `InputFrame` | No DOM/BLE in game-core |
| INP-02 | 11 digital actions + optional gesture | Type match in types.ts |
| INP-03 | P1 keyboard always available | Default mapping documented |
| INP-04 | Gamepad 0/1 auto-assign | Hot-plug without refresh |
| INP-05 | Keyboard singleton listeners | 1 keydown + 1 keyup for life of page |
| INP-06 | Edge-IO maps to same actions | mapGestureToInput tests |
| INP-07 | Input buffering | 0–3 frames (v0.5) |
| INP-08 | Remapping | Persistent localStorage (v0.5) |

Default mappings: see `docs/INPUT_SYSTEM.md`.

---

## 16. Rollback requirements

| Req ID | Requirement | v0.1 |
|--------|-------------|------|
| RB-01 | State snapshot ring buffer | maxRollbackFrames configurable (default 120) |
| RB-02 | Predict unconfirmed inputs | Default empty input |
| RB-03 | Rollback on mismatch | confirmInputs triggers resim |
| RB-04 | Resimulate to current frame | Loop in RollbackSession |
| RB-05 | State hash per snapshot | FNV-1a on serialize |
| RB-06 | verifyAgainstReplay | desyncDetected flag |
| RB-07 | Expose rollbackCount | Debug overlay |
| RB-08 | Online transport | v0.5 — not v0.1 |

**Test:** Predicted wrong attack at frame 10 → rollback → final hash matches authoritative replay.

---

## 17. Local couch multiplayer requirements

| Req ID | Requirement | v0.1 |
|--------|-------------|------|
| LOC-01 | 2 players same screen | Yes |
| LOC-02 | Split input devices | Keyboard + keyboard or gamepads |
| LOC-03 | RollbackSession drives sim | Yes |
| LOC-04 | 3–4 players | v0.5 |
| LOC-05 | Same sim as online | Architecture enforced |

---

## 18. Online multiplayer requirements

| Req ID | Requirement | Milestone |
|--------|-------------|-----------|
| ONL-01 | Input frame exchange | v0.5 |
| ONL-02 | Delay-based input delay + rollback | v0.5 |
| ONL-03 | Desync detection + disconnect UI | v0.5 |
| ONL-04 | Matchmaking | v1.0 |
| ONL-05 | Anti-cheat | v1.0+ (input validation + hash spot checks) |

---

## 19. Training/debug requirements

| Req ID | Requirement | v0.1 |
|--------|-------------|------|
| DBG-01 | Toggle debug overlay | Frame, hash, inputs, rollback count |
| DBG-02 | Toggle hitboxes/hurtboxes | Visual overlay |
| DBG-03 | Training mode (dummy, frame step) | v0.5 |
| DBG-04 | Input display per player | Debug overlay |

---

## 20. Wearable Edge-IO requirements

| Req ID | Requirement | Measurement |
|--------|-------------|-------------|
| EDGE-01 | Binary SensorNotify 22 bytes | Parser unit tests |
| EDGE-02 | Binary GestureNotify 12 bytes | seq, timestamp, gesture_id, confidence, device_id |
| EDGE-03 | HapticWrite 4 bytes | Host → device only |
| EDGE-04 | Gesture enum normalized | 9 gesture names |
| EDGE-05 | Optional — full game keyboard-only | Complete match without device |
| EDGE-06 | Latency target gesture → host | p50 < 50 ms (hardware validated) |
| EDGE-07 | Battery in sensor packet | battery_pct 0–100 |

---

## 21. Haptic feedback requirements

| Req ID | Requirement | Note |
|--------|-------------|------|
| HAP-01 | Output-only; never required for fairness | PRD non-negotiable |
| HAP-02 | effect_id, intensity 0–255, duration_ms | HapticWrite packet |
| HAP-03 | Acknowledge gesture on device | Firmware optional pattern |
| HAP-04 | Configurable intensity cap | Accessibility |

---

## 22. Accessibility requirements

| Req ID | Requirement | Milestone |
|--------|-------------|-----------|
| A11Y-01 | Full keyboard playability | v0.1 |
| A11Y-02 | Remapping all actions | v0.5 |
| A11Y-03 | Color-blind safe UI (not color-only cues) | v0.5 |
| A11Y-04 | Screen reader labels on menus | v0.5 |
| A11Y-05 | Reduce motion / flash options | v1.0 |
| A11Y-06 | Wearable alternatives for every mapped gesture | v0.5 |

---

## 23. Performance requirements

| Req ID | Requirement | Target |
|--------|-------------|--------|
| PERF-01 | Sim tick rate | 60 Hz fixed |
| PERF-02 | Render FPS (vertical slice) | ≥ 60 FPS on M1 / i5-8250U class laptop |
| PERF-03 | Frame sim CPU | < 2 ms per frame (2P) in JS |
| PERF-04 | Input poll | < 0.5 ms |
| PERF-05 | Web bundle size (gzip) | < 500 KB for v0.1 slice (excluding mini-games) |

---

## 24. Art/audio/UI direction

- **Visual:** Toon-shaded anime-inspired readability; high contrast silhouettes; v0.1 uses geometric placeholders with character colors (Ember `#ff6b35`, Tide `#4ecdc4`).
- **UI:** Dark arena backdrop; large touch-friendly buttons on landing; debug monospace overlay.
- **VFX:** Hit flash, knockback trails (v0.5+); no seizure-inducing full-screen flash > 3 Hz.
- **Audio:** Punchy hit SFX, UI confirm, stage music loops (v0.5+); v0.1 silent acceptable.

---

## 25. Content requirements

| Content | v0.1 | v0.5 | v1.0 |
|---------|------|------|------|
| Playable characters | 2 | 4 | 8+ |
| Stages | 1 | 2 | 4+ |
| Original names only | Required | Required | Required |
| Move definitions | Code constants | JSON-driven | JSON + tools |

**Legal:** No copyrighted character names, moves, or stage layouts from existing franchises.

---

## 26. Hardware prototype requirements

- **First prototype:** Wristband/dev-board mule (nRF52840 DK + IMU + DRV2605L), not custom ring PCB.
- **BOM:** CSV with category, reference, part_name, MPN, quantity, purpose, status, notes; `TBD` where unverified.
- **No fake Gerbers:** fab/ directory holds checklists until real outputs exist.
- **EVT gates:** Latency, battery runtime 3–6 h active, BLE reconnect < 5 s.

See `docs/HARDWARE_PROTOTYPE_PLAN.md`.

---

## 27. Firmware requirements

- Target: nRF52840 (PlatformIO nordicnrf52 Arduino for mule).
- Canonical binary protocol per `docs/EDGE_IO_PROTOCOL.md`.
- IMU sample 100 Hz; gesture notify 10–20 Hz effective.
- Connection interval 7.5–15 ms.
- DFU path documented (Nordic DFU preferred).
- **v0.1:** Stack decision in ADR-0001; compile status honestly reported.

---

## 28. Security/privacy requirements

| Req ID | Requirement |
|--------|-------------|
| SEC-01 | BLE pairing user-initiated; no silent recording |
| SEC-02 | No PII in telemetry without consent |
| SEC-03 | Input logs for replay stored locally unless opted in |
| SEC-04 | Dependency audit before v0.5 public deploy |
| SEC-05 | HTTPS only for hosted demo |

---

## 29. Release requirements

| Stage | Artifact | Gate |
|-------|----------|------|
| v0.1 | Internal vertical slice | STATUS exit criteria |
| v0.5 | GitHub Pages / static host | RELEASE_CHECKLIST v0.5 |
| v1.0 | Store/package | RELEASE_CHECKLIST v1.0 |

---

## 30. QA requirements

- Unit tests: game-core determinism, combat, rollback, edgeio protocol.
- Integration: manual 2P playtest script (3 matches, rematch).
- Regression: `npm run quality` before merge.
- Hardware QA matrix when mule exists (latency, drop rate < 1% notify).

---

## 31. Analytics/telemetry requirements

| Req ID | Requirement | Milestone |
|--------|-------------|-----------|
| TEL-01 | Opt-in only | v0.5 |
| TEL-02 | Match duration, character picks, desync count | v0.5 |
| TEL-03 | No raw IMU stream upload without consent | Always |
| TEL-04 | Cloudflare worker stub | Existing; not wired v0.1 |

---

## 32. Documentation requirements

| Document | Required |
|----------|----------|
| README.md | Honest run/test instructions |
| docs/STATUS.md | Capability matrix |
| docs/PRODUCT_REQUIREMENTS.md | This file |
| docs/ARCHITECTURE.md | 90-day structure |
| docs/ROLLBACK_DESIGN.md | Rollback rationale |
| docs/INPUT_SYSTEM.md | Mappings |
| docs/EDGE_IO_PROTOCOL.md | Binary spec |
| docs/BACKLOG.md | Prioritized work |
| ADR for firmware stack | ADR-0001 |

---

## 33. Non-goals

- Licensed anime characters or moves
- Godot/C++ engine as v0.1 authority (may exist as experiment only)
- Requiring wearables to play
- Fake hardware fabrication files
- Claiming "AAA complete" or "shipping" before gates pass
- Blockchain/NFT integration
- Pay-to-win monetization

---

## 34. Acceptance criteria

### v0.1 (current)

- [ ] `npm run quality` passes locally
- [x] Determinism: same inputs → same hash (automated test)
- [x] Rollback test: wrong prediction recoverable
- [x] 2P vertical slice playable in browser
- [x] Character select → results → rematch
- [x] PRD + STATUS + honest README
- [ ] CI runs full quality workflow
- [ ] VALIDATION_REPORT.md recorded

### v0.5

- [ ] Online 2P rollback match between two browsers
- [ ] Edge-IO dev board demo OR documented blocker
- [ ] 3+ characters, remapping UI

### v1.0

- [ ] RELEASE_CHECKLIST complete
- [ ] WCAG AA UI audit
- [ ] Crash-free sessions > 99.9% in beta

---

## 35. Open risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| JS number determinism across browsers | Online desync | Medium | Fixed-point sim; binary serialize later |
| Firmware BLE stack mismatch | No wearable demo | High | ADR-0001; mule time-box |
| Scope creep to 4 platforms | Delay v0.1 | Medium | Web-first mandate |
| Art debt blocks public demo | Low engagement | Medium | Readable placeholders OK for v0.5 |
| Two web app trees | Confusion | Medium | Consolidation issue in backlog |

---

## 36. Milestone roadmap

| Milestone | Target | Deliverables |
|-----------|--------|--------------|
| **v0.1** | 2026 Q2 | Deterministic web vertical slice, docs, tests |
| **v0.5** | 2026 Q3 | Public demo, online rollback, Edge-IO mule |
| **v1.0** | 2027 Q1 | Content complete, accessibility, optional hardware SKU |
| **Future** | TBD | 4P couch, tournaments, mod tools |

---

## 37. Definition of done

A feature is **done** when:

1. It maps to a PRD requirement ID (e.g. COM-03, RB-05).
2. Code merged with tests or documented manual test steps.
3. `docs/STATUS.md` updated if user-visible.
4. No new false claims in README.
5. Debug/telemetry hooks exist for rollback-affecting changes.
6. Reviewer can reproduce acceptance criterion in < 15 minutes.

**Milestone done** when all acceptance criteria for that milestone are checked and VALIDATION_REPORT.md is updated.

---

*This PRD is the canonical reference. Implementation details live in ARCHITECTURE.md, ROLLBACK_DESIGN.md, and package READMEs.*
